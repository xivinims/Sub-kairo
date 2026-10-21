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

const read=(name)=>fs.readFileSync(`roblox-integrations/sakura97/${name}.luau`,'utf8');

let installBody=read('install');
installBody=installBody.replace(/\nreturn\s*\{[\s\S]*\}\s*$/,'\n-- install finished');
const verifySource=read('verify');

const patch=`
assert(game.GameId == ${UNIVERSE_ID} and game.PlaceId == ${PLACE_ID}, "Wrong target place")
local sourceVersion=game.PlaceVersion
print("[Sakura97] Starting repaired install from version "..tostring(sourceVersion))

do
${installBody}
end

local function runVerify()
${verifySource}
end
local checks=runVerify()
assert(checks and checks.ok,"Verify failed")

game:GetService("AssetService"):SavePlaceAsync()
return {
  ok=true,
  sourceVersion=sourceVersion,
  trees=checks.trees,
  message="Sakura island v97 repaired and published"
}
`;

console.log("[Sakura97] Dispatching repaired Luau install to NEW place...");
const applied=first(await execute(patch));
if(!applied?.ok) throw new Error("Sakura97 install failed");
console.log(JSON.stringify({stage:"installed-and-saved",...applied}));

let persisted,last;
for(let i=0;i<12;i++){
  if(i) await sleep(4500);
  try{
    const check=first(await execute(`
      assert(game.GameId==${UNIVERSE_ID} and game.PlaceId==${PLACE_ID})
      local runtime=game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
      local trees=workspace:FindFirstChild("SakuraTrees")
      return {
        ok=runtime~=nil and trees~=nil,
        placeVersion=game.PlaceVersion,
        trees=trees and #trees:GetChildren() or 0,
        version=runtime and runtime:GetAttribute("Version")
      }
    `));
    if(!check?.ok || check.placeVersion<=applied.sourceVersion){
      throw new Error("Saved version not visible yet, got "+(check&&check.placeVersion));
    }
    persisted=check; last=null; break;
  }catch(e){
    last=e;
    console.log(JSON.stringify({waiting:true,attempt:i+1,error:String(e)}));
  }
}
if(last) throw last;
console.log(JSON.stringify({stage:"verified-persisted",...persisted}));
console.log("[Sakura97] Done.");
