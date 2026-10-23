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



const js=await (await fetch('https://js.rbxcdn.com/a87af30de1fff7184646dd8bd3f5df248b51543ee088ab0380823cea48a30a17-ShareLinks.js')).text();
console.log('RESOLVE_JS', [...js.matchAll(/.{0,700}(?:resolve-link|resolveLink|linkId|itemId).{0,700}/g)].map(m=>m[0]).slice(0,25));
for(const id of [125165599816440,140005809574272,9526505226,72797028676916]){
console.log('DETAIL',JSON.stringify(first(await execute(`
local a=game:GetService("AssetService"):LoadAssetAsync(${id})
local out={id=${id},sequences={},bones={},parts={},classes={}}
for _,d in ipairs(a:GetDescendants()) do
 out.classes[d.ClassName]=(out.classes[d.ClassName] or 0)+1
 if d:IsA("KeyframeSequence") then local keys=d:GetKeyframes() table.insert(out.sequences,{name=d:GetFullName(),frames=#keys,length=keys[#keys] and keys[#keys].Time}) end
 if d:IsA("Motor6D") then table.insert(out.bones,{name=d.Name,p0=d.Part0 and d.Part0.Name,p1=d.Part1 and d.Part1.Name}) end
 if d:IsA("BasePart") and ${id}==9526505226 then table.insert(out.parts,{name=d:GetFullName(),anchored=d.Anchored}) end
end
return out
`))));
}
