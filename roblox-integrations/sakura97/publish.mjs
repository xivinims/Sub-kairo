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


console.log(JSON.stringify(first(await execute("\nlocal A=game:GetService(\"AssetService\")\nlocal function describe(root)\n local out={}\n for _,v in ipairs(root:GetDescendants()) do\n  if v:IsA(\"Model\") and v:FindFirstChildOfClass(\"Humanoid\") or v:IsA(\"SpawnLocation\") or string.find(string.lower(v.Name),\"door\") or v:IsA(\"Animation\") or v:IsA(\"KeyframeSequence\") then\n   local d={name=v:GetFullName(),class=v.ClassName}\n   if v:IsA(\"BasePart\") then d.position=tostring(v.Position); d.size=tostring(v.Size) end\n   if v:IsA(\"Model\") then local cf,sz=v:GetBoundingBox();d.position=tostring(cf.Position);d.size=tostring(sz) end\n   if v:IsA(\"Animation\") then d.id=v.AnimationId end\n   if v:IsA(\"KeyframeSequence\") then d.frames=#v:GetKeyframes() end\n   table.insert(out,d)\n  end\n end\n return out\nend\nlocal r={version=game.PlaceVersion,world=describe(workspace),children={}}\nfor _,v in ipairs(workspace:GetChildren()) do table.insert(r.children,{name=v.Name,class=v.ClassName}) end\nr.assets={}\nfor _,id in ipairs({79671648850902,125165599816440,134326820545987}) do\n local ok,v=pcall(function() return A:LoadAssetAsync(id) end)\n if ok then\n  v.Parent=game.ServerStorage\n  r.assets[tostring(id)]={items=describe(v),count=#v:GetDescendants()}\n  v:Destroy()\n else r.assets[tostring(id)]={error=tostring(v)} end\nend\nreturn r\n"))));
