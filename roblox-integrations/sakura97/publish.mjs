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


const result=first(await execute(`
local report={placeVersion=game.PlaceVersion,assets={}}
local island=workspace:FindFirstChild("FloatingIsland")
if island then local cf,sz=island:GetBoundingBox() report.island={size=tostring(sz),center=tostring(cf.Position)} end
for _,id in ipairs({87377915371959,86563808574363,4617134997,84828163072141}) do
 local ok,a=pcall(function() return game:GetService("AssetService"):LoadAssetAsync(id) end)
 local item={id=id,ok=ok,items={}}
 if ok then
  for _,d in ipairs(a:GetDescendants()) do
   if d:IsA("LuaSourceContainer") then table.insert(item.items,{path=d:GetFullName(),class=d.ClassName,source=d.Source})
   elseif d:IsA("BasePart") or d:IsA("ScreenGui") or d:IsA("PostEffect") or d:IsA("Sky") or d:IsA("Atmosphere") then
    local e={path=d:GetFullName(),class=d.ClassName}
    if d:IsA("BasePart") then e.size=tostring(d.Size) e.position=tostring(d.Position) end
    if #item.items<150 then table.insert(item.items,e) end
   end
  end
  a:Destroy()
 else item.error=tostring(a) end
 table.insert(report.assets,item)
end
return report
`));
console.log(JSON.stringify(result));
