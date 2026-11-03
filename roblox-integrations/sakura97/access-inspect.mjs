import fs from 'node:fs';
import { inflateSync, deflateSync, gunzipSync } from 'node:zlib';
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
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'90s',script});
  const deadline=Date.now()+180000;
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


console.log("ACCESS_DIAGNOSTIC",JSON.stringify(first(await execute("local lobby=workspace.JediLibrary local AS=game:GetService(\"AssetService\")\n-- Door trim must not turn its hollow opening into a solid physics hull.\nlocal house=assert(lobby:FindFirstChild(\"House\"),\"Authored lobby house missing\")\nlocal oldAccess=lobby:FindFirstChild(\"PassageColliders\") if oldAccess then oldAccess:Destroy() end\nlocal access=Instance.new(\"Folder\",lobby) access.Name=\"PassageColliders\"\nlocal repairedFrames=0 local repairedMeshes=0 local removedBlockers=0\nlocal function support(name,size,cf)\n local p=Instance.new(\"Part\") p.Name=name p.Size=size p.CFrame=cf p.Anchored=true\n p.Transparency=1 p.CanCollide=true p.CanTouch=false p.CanQuery=true p.CastShadow=false\n p:SetAttribute(\"PassageSupport\",true) p.Parent=access return p\nend\nfor _,part in ipairs(house:GetDescendants()) do\n if part:IsA(\"BasePart\") then\n  local name=part.Name:lower()\n  if part.Transparency>=.98 and not part:IsA(\"SpawnLocation\") then\n   part.CanCollide=false part.CanTouch=false part.CanQuery=false\n   part:SetAttribute(\"InteriorBlockerDisabled\",true) removedBlockers+=1\n  elseif part:IsA(\"MeshPart\") and (name==\"double_door_frame\" or name==\"front_door_frame\" or name==\"shed_doorframe\") then\n   part.CanCollide=false part.CanTouch=false part:SetAttribute(\"OpenPassage\",true)\n   local width=part.Size.X local height=part.Size.Y local depth=part.Size.Z\n   local opening=name==\"front_door_frame\" and math.min(8.1,width-1) or width-.9\n   local clearHeight=math.min(7.65,height-.35)\n   local post=(width-opening)/2\n   support(\"DoorLeft\",Vector3.new(post,height,depth),part.CFrame*CFrame.new(-(opening+post)/2,0,0))\n   support(\"DoorRight\",Vector3.new(post,height,depth),part.CFrame*CFrame.new((opening+post)/2,0,0))\n   support(\"DoorLintel\",Vector3.new(opening,height-clearHeight,depth),part.CFrame*CFrame.new(0,clearHeight/2,0))\n   part:SetAttribute(\"PassageWidth\",opening) part:SetAttribute(\"PassageHeight\",clearHeight)\n   repairedFrames+=1\n  elseif part:IsA(\"MeshPart\") and (name:find(\"stairs\",1,true) or name:find(\"side_stair\",1,true) or name==\"rail_stair\") then\n   if part:GetAttribute(\"PrecisePassageCollision\")~=true then\n    local size,cf,texture=part.Size,part.CFrame,part.TextureID\n    local rebuilt=AS:CreateMeshPartAsync(part.MeshContent,{CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition})\n    part:ApplyMesh(rebuilt) part.Size=size part.CFrame=cf part.TextureID=texture rebuilt:Destroy()\n    part:SetAttribute(\"PrecisePassageCollision\",true)\n   end\n   repairedMeshes+=1\n  end\n end\nend\nlobby:SetAttribute(\"PassageRepairRevision\",1)\nlobby:SetAttribute(\"RepairedDoorFrames\",repairedFrames)\nlobby:SetAttribute(\"RepairedStairMeshes\",repairedMeshes)\nlobby:SetAttribute(\"DisabledInteriorBlockers\",removedBlockers)\n\nlocal npc=workspace.LobbyGuide\nlocal params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={lobby} params.RespectCanCollide=true\nlocal origin=lobby:GetAttribute(\"VerifiedSpawn\")\nlocal out={origin=tostring(origin),npc=tostring(npc.Torso.Position),receptionOrigin=tostring(lobby:GetAttribute(\"ReceptionSearchOrigin\")),tabletop=npc.Tabletop.Value:GetFullName(),points={}}\nfor _,radius in ipairs({4,7,9}) do\n for i=0,7 do\n local theta=i*math.pi/4 local x=npc.Torso.Position+Vector3.new(math.cos(theta)*radius,0,math.sin(theta)*radius)\n local hit=workspace:Raycast(Vector3.new(x.X,origin.Y+3.5,x.Z),Vector3.new(0,-10,0),params)\n local v={r=radius,i=i,hit=hit and hit.Instance:GetFullName(),floor=hit and tostring(hit.Position)}\n if hit then\n local roof=workspace:Raycast(hit.Position+Vector3.new(0,.2,0),Vector3.new(0,5.2,0),params) v.roof=roof and roof.Instance:GetFullName()\n if not roof then\n local path=game:GetService(\"PathfindingService\"):CreatePath({AgentRadius=1.4,AgentHeight=5,AgentCanJump=false}) path:ComputeAsync(origin+Vector3.new(0,2,0),hit.Position+Vector3.new(0,2,0)) v.status=path.Status.Name v.steps=#path:GetWaypoints() path:Destroy()\n end end\n table.insert(out.points,v)\n end\nend\nreturn out\n"))));
