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

const read=(name)=>fs.readFileSync(`roblox-integrations/sakura97/${name}.luau`,'utf8');

let installBody=read('install');
const runtimeSource=read('nature-runtime');
installBody=installBody.replace('__RUNTIME_SOURCE__',JSON.stringify(runtimeSource));
for (const [marker,name] of Object.entries({GRASS:'grass-client',GRASS_MODULE:'grass-module',WIND:'wind-client',SERVER:'island-server',VOID:'void-client',LEAVES:'leaves-client',NAMETAG:'nametag-server',FRIENDS:'friends-client'})) {
 installBody=installBody.replace(`__${marker}_SOURCE__`,JSON.stringify(read(name)));
}
installBody=installBody.replace(/\nreturn\s*\{[\s\S]*\}\s*$/,'\n-- install finished');
const menuBody=read('install-menu').replace('__MENU_SOURCE__',JSON.stringify(read('menu-client'))).replace('__LOADING_SOURCE__',JSON.stringify(read('loading-client')));
let survivalBody=read('survival-install').replace('__RIG_INSTALL__',read('rig-install'));
for(const [marker,name] of Object.entries({CONFIG:'survival-config',RULES:'round-rules',AI:'pursuer-ai',SURVIVAL_SERVER:'survival-server',SURVIVAL_CLIENT:'survival-client',ANIMATION:'pursuer-animation'})) survivalBody=survivalBody.replace(`__${marker}_SOURCE__`,JSON.stringify(read(name)));
const survivalTests=read('survival-tests');
const survivalClientTests=read('survival-client-tests').replace('__SURVIVAL_CLIENT_TEST_SOURCE__',read('survival-client'));
const survivalServerTestSource=read('survival-server').replace(
 'local function now() return workspace:GetServerTimeNow() end',
 'local function now() return TEST_NOW() end'
);
const survivalRuntimeTests=read('survival-runtime-tests').replace('__SURVIVAL_SERVER_TEST_SOURCE__',survivalServerTestSource);
const verifySource=read('verify');
const menuVerifySource=read('verify-menu');
const contentTests=read('content-tests');
const voidTests=read('void-runtime-tests').replace('__VOID_CLIENT_TEST_SOURCE__',read('void-client'));

const patch=`
assert(game.GameId == ${UNIVERSE_ID} and game.PlaceId == ${PLACE_ID}, "Wrong target place")
local sourceVersion=game.PlaceVersion
print("[Sakura97] Starting repaired install from version "..tostring(sourceVersion))

local installOk,installErr=xpcall(function()
${installBody}
end,function(err)
  return debug.traceback(tostring(err),2)
end)
assert(installOk,"INSTALL_TRACE: "..tostring(installErr))
-- Publish map and UI atomically: no public intermediate map without its menu.
do
${menuBody}
end

do
${survivalBody}
end
local function testSurvival()
${survivalTests}
end
local survivalChecks=testSurvival()
local function testRoundController()
${survivalRuntimeTests}
end
survivalChecks.runtime=testRoundController()
local function testSurvivalClient()
${survivalClientTests}
end
survivalChecks.client=testSurvivalClient()
local function runVerify()
${verifySource}
end
local checks=runVerify()
local function verifyMenu()
${menuVerifySource}
end
checks.menu=verifyMenu()
local function verifyContent()
${contentTests}
end
checks.content=verifyContent()
local function verifyVoidController()
${voidTests}
end
checks.voidController=verifyVoidController()
assert(checks and checks.ok,"Verify failed")

-- Dry run: no save
return {
  ok=true,
  sourceVersion=sourceVersion,
  mapParts=checks.mapParts,
  survival=survivalChecks,
  menu=checks.menu,
  content=checks.content,
  voidController=checks.voidController,
  lots=checks.lots,
  grass=checks.grass,
  pumpkins=checks.pumpkins,
  pumpkinClusters=checks.pumpkinClusters,
  message="Jedi Library lobby verified"
}
`;

console.log("[Sakura97] Dispatching repaired Luau install to NEW place...");
const applied=first(await execute(patch));
if(!applied?.ok) throw new Error("Sakura97 install failed");
console.log(JSON.stringify({stage:"dry-run-verified",...applied}));

