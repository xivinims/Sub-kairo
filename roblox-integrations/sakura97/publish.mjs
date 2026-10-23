import fs from 'node:fs';

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



const ids=[15761692261,14101261109,119558547298374,18709122295,125165599816440,12796108766,72797028676916,14897466681,140005809574272,9526505226,13967333450,13366963505,8050959400];
for(const id of ids){
 const result=first(await execute(`
 local ok,asset=pcall(function() return game:GetService("AssetService"):LoadAssetAsync(${id}) end)
 if not ok then return {id=${id},ok=false,error=tostring(asset)} end
 local out={id=${id},ok=true,parts=0,joints=0,animations={},scripts={},rigs={},models={},spawns={}}
 for _,d in ipairs(asset:GetDescendants()) do
  if d:IsA("BasePart") then out.parts+=1 end
  if d:IsA("Motor6D") then out.joints+=1 end
  if d:IsA("Animation") then table.insert(out.animations,{name=d:GetFullName(),id=d.AnimationId}) end
  if d:IsA("LuaSourceContainer") then table.insert(out.scripts,{name=d:GetFullName(),source=d.Source:sub(1,16000)}) end
  if d:IsA("Humanoid") or d:IsA("AnimationController") then table.insert(out.rigs,{name=d.Parent:GetFullName(),class=d.ClassName,root=d.Parent:FindFirstChild("HumanoidRootPart")~=nil}) end
  if d:IsA("SpawnLocation") then table.insert(out.spawns,{name=d:GetFullName(),position=tostring(d.Position)}) end
  if d:IsA("Model") and #out.models<14 then local cf,size=d:GetBoundingBox() table.insert(out.models,{name=d:GetFullName(),size=tostring(size),center=tostring(cf.Position)}) end
 end
 asset:Destroy() return out
 `));
 console.log('ASSET_PROBE '+JSON.stringify(result));
}
const codes=['483d9089ee796746bf3bda0b3e705594','4bf7976d414aba40be4cc07a77b0b737','ad59a91ca3e44146b60861ea0cc713f3','3b5c53fcdff14a44aab007e724d540d4','2e17b7b4b3140f4c8164a45dc71e00dd','d271494e46f4444cb9b3fba077e2364d','3a5addb1e07e0e46836390d7f917c460','6be90db2444eed40975531f3c3881ead'];
for(const code of codes){
 const response=await fetch('https://www.roblox.com/share?code='+code+'&type=AvatarItemDetails');
 const html=await response.text();
 console.log('SHARE_PROBE '+JSON.stringify({code,status:response.status,url:response.url,hints:[...html.matchAll(/.{0,100}(?:catalog\/\d+|assetId|itemId|deepLink|shareLink|targetId|og:title).{0,250}/gi)].map(m=>m[0]).slice(0,25)}));
}
console.log('VOICE_PROBE '+JSON.stringify(first(await execute(`
 local v=game:GetService("VoiceChatService")
 local ok,err=pcall(function() v.UseAudioApi=Enum.AudioApiRollout.Enabled end)
 return {canSetAudioApi=ok,error=not ok and tostring(err) or nil}
`))));
