import fs from 'node:fs';
import { inflateSync, deflateSync } from 'node:zlib';
import { createHash } from 'node:crypto';

function crc32(buf){
  let crc=0xffffffff;
  for(const byte of buf){
    crc^=byte;
    for(let k=0;k<8;k++) crc=(crc>>>1)^((crc&1)?0xedb88320:0);
  }
  return (crc^0xffffffff)>>>0;
}
function pngChunk(type,data=Buffer.alloc(0)){
  const t=Buffer.from(type,'ascii');
  const len=Buffer.alloc(4); len.writeUInt32BE(data.length);
  const sum=Buffer.alloc(4); sum.writeUInt32BE(crc32(Buffer.concat([t,data])));
  return Buffer.concat([len,t,data,sum]);
}
function paeth(a,b,c){
  const p=a+b-c, pa=Math.abs(p-a), pb=Math.abs(p-b), pc=Math.abs(p-c);
  return pa<=pb&&pa<=pc?a:pb<=pc?b:c;
}
function normalizeLogoPng(input){
  const sig=Buffer.from([137,80,78,71,13,10,26,10]);
  if(input.length<33 || !input.subarray(0,8).equals(sig)) throw new Error('Logo is not PNG');
  let off=8, ihdr=null, palette=null, alpha=null;
  const idats=[];
  while(off+12<=input.length){
    const n=input.readUInt32BE(off); const type=input.subarray(off+4,off+8).toString('ascii');
    const data=input.subarray(off+8,off+8+n); off+=12+n;
    if(type==='IHDR') ihdr=Buffer.from(data);
    else if(type==='PLTE') palette=Buffer.from(data);
    else if(type==='tRNS') alpha=Buffer.from(data);
    else if(type==='IDAT') idats.push(Buffer.from(data));
    else if(type==='IEND') break;
  }
  if(!ihdr) throw new Error('Logo PNG has no IHDR');
  const w=ihdr.readUInt32BE(0), h=ihdr.readUInt32BE(4), depth=ihdr[8], color=ihdr[9], interlace=ihdr[12];
  if(depth===8 && color===6) return input;
  if(depth!==8 || color!==3 || interlace!==0 || !palette || !idats.length){
    throw new Error(`Unsupported logo PNG format depth=${depth} color=${color} interlace=${interlace}`);
  }
  const packed=inflateSync(Buffer.concat(idats));
  const stride=w, rows=Buffer.alloc(stride*h);
  let src=0;
  for(let y=0;y<h;y++){
    const filter=packed[src++], row=rows.subarray(y*stride,(y+1)*stride), prev=y?rows.subarray((y-1)*stride,y*stride):null;
    for(let x=0;x<stride;x++){
      const raw=packed[src++], left=x?row[x-1]:0, up=prev?prev[x]:0, ul=prev&&x?prev[x-1]:0;
      let val;
      if(filter===0) val=raw;
      else if(filter===1) val=(raw+left)&255;
      else if(filter===2) val=(raw+up)&255;
      else if(filter===3) val=(raw+Math.floor((left+up)/2))&255;
      else if(filter===4) val=(raw+paeth(left,up,ul))&255;
      else throw new Error('Unsupported PNG filter '+filter);
      row[x]=val;
    }
  }
  const rgba=Buffer.alloc((w*4+1)*h);
  for(let y=0;y<h;y++){
    let out=y*(w*4+1); rgba[out++]=0;
    for(let x=0;x<w;x++){
      const idx=rows[y*w+x], pi=idx*3;
      rgba[out++]=palette[pi]??0; rgba[out++]=palette[pi+1]??0; rgba[out++]=palette[pi+2]??0;
      rgba[out++]=alpha&&idx<alpha.length?alpha[idx]:255;
    }
  }
  const next=Buffer.alloc(13); ihdr.copy(next); next[8]=8; next[9]=6; next[10]=0; next[11]=0; next[12]=0;
  return Buffer.concat([sig,pngChunk('IHDR',next),pngChunk('IDAT',deflateSync(rgba,{level:9})),pngChunk('IEND')]);
}

const CLOUD='https://apis.roblox.com/cloud/v2/';
const UNIVERSE_ID='9419478735';
const PLACE_ID='79738710219521';
const TARGET=`universes/${UNIVERSE_ID}/places/${PLACE_ID}/`;
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));

async function req(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  let last=null;
  for(let i=0;i<12;i++){
    const res=await fetch(CLOUD+path,{
      method:body?'POST':'GET',
      headers:{'x-api-key':key,'content-type':'application/json'},
      body:body?JSON.stringify(body):undefined,
      signal:AbortSignal.timeout(60000)
    });
    const raw=await res.text();
    let data; try{data=JSON.parse(raw)}catch{data={raw}}
    if(res.ok) return data;
    if([429,500,502,503].includes(res.status)){
      const retry=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(retry)&&retry>0?retry*1000:Math.min(60000,5000*(i+1));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);
      continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}

async function patchCloud(path,body){
  const key=process.env.ROBLOX_API_KEY;
  if(!key) throw new Error('Missing ROBLOX_API_KEY');
  const res=await fetch(CLOUD+path,{
    method:'PATCH',
    headers:{'x-api-key':key,'content-type':'application/json'},
    body:JSON.stringify(body),
    signal:AbortSignal.timeout(60000)
  });
  const raw=await res.text();
  let data; try{data=JSON.parse(raw)}catch{data={raw}}
  if(!res.ok) throw new Error('PATCH '+path+' HTTP '+res.status+': '+JSON.stringify(data));
  return data;
}

async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline) throw new Error('Luau timeout');
    await sleep(1500);
    task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error) throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}

function first(task){
  const v=task?.output?.results?.[0];
  if(typeof v!=='string') return v??null;
  try{return JSON.parse(v)}catch{return v}
}

async function uploadSurviversLogo(){
  const fallback=0;
  try{
    const key=process.env.ROBLOX_API_KEY;
    const creatorId=process.env.ROBLOX_CREATOR_USER_ID||'8344738123';
    const bytes=fs.readFileSync('roblox-integrations/sakura97/branding/survivers-original.png');
    const logoHash=createHash('sha256').update(bytes).digest('hex');
    if(logoHash!=='286b7e57276a5d593b38c10c3a4cd41518d027c0e9346dfa6db3daf36521897e') throw new Error('Exact logo checksum mismatch');
    console.log('[Survivers] logo reconstructed:',bytes.length,'bytes sha256='+logoHash);
    const form=new FormData();
    form.append('request',JSON.stringify({
      assetType:'Decal',
      displayName:'Survivers Logo',
      description:'Survivers menu logo',
      creationContext:{creator:{userId:String(creatorId)}}
    }));
    form.append('fileContent',new Blob([bytes],{type:'image/png'}),'survivers-logo.png');
    const created=await fetch('https://apis.roblox.com/assets/v1/assets',{method:'POST',headers:{'x-api-key':key},body:form,signal:AbortSignal.timeout(60000)});
    const raw=await created.text();
    if(!created.ok){ console.warn('[Survivers] logo upload unavailable:',created.status,raw); return fallback; }
    const op=JSON.parse(raw);
    const directId=Number(op?.assetId||op?.response?.assetId||0);
    if(directId>0){ console.log('[Survivers] logo asset:',directId); return directId; }
    const opId=String(op.path||op.operationPath||'').replace(/^operations\//,'');
    if(!opId){ console.warn('[Survivers] logo upload returned no operation:',raw); return fallback; }
    console.log('[Survivers] logo operation:',opId);
    for(let i=0;i<90;i++){
      await sleep(2000);
      const res=await fetch('https://apis.roblox.com/assets/v1/operations/'+opId,{headers:{'x-api-key':key},signal:AbortSignal.timeout(30000)});
      const txt=await res.text();
      if(!res.ok) continue;
      const status=JSON.parse(txt);
      if(status.done){
        const id=Number(status?.response?.assetId||String(status?.response?.path||'').split('/').pop()||0);
        if(id>0){ console.log('[Survivers] logo asset:',id); return id; }
        console.warn('[Survivers] logo operation completed without asset:',txt);
        break;
      }
      if(status.error){ console.warn('[Survivers] logo operation error:',txt); break; }
    }
    console.warn('[Survivers] logo operation ended without usable asset id:',opId);
  }catch(err){ console.warn('[Survivers] logo upload failed:',String(err)); }
  return fallback;
}
const surviversLogoId=await uploadSurviversLogo();


console.log(JSON.stringify({logo:surviversLogoId,probe:first(await execute("\nlocal lobby=workspace.JediLibrary local door=lobby.Door local cf,sz=door:GetBoundingBox()\nlocal out={door={},floors={},rays={}}\nfor _,v in ipairs(door:GetDescendants()) do if v:IsA(\"BasePart\") then table.insert(out.door,{name=v.Name,cf={v.CFrame:GetComponents()},size=tostring(v.Size),collide=v.CanCollide}) end end\nlocal params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={lobby} params.RespectCanCollide=true\nfor _,dx in ipairs({-12,-6,0,6,12}) do\n local pos=cf.Position+Vector3.new(dx,0,0)\n local r=workspace:Raycast(pos,Vector3.new(0,-30,0),params)\n table.insert(out.rays,{x=dx,hit=r and r.Instance:GetFullName(),pos=r and tostring(r.Position)})\nend\nlocal a=game:GetService(\"AssetService\"):LoadAssetAsync(79671648850902)\na.Parent=workspace local c,z=a:GetBoundingBox();out.mapBounds={position=tostring(c.Position),size=tostring(z)}\nfor _,p in ipairs(a:GetDescendants()) do if p:IsA(\"BasePart\") and p.CanCollide and p.Size.X>10 and p.Size.Z>10 and p.CFrame.UpVector.Y>.9 then table.insert(out.floors,{name=p.Name,size=tostring(p.Size),position=tostring(p.Position),material=p.Material.Name}) end end\nreturn out\n"))}));
