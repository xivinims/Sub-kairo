import fs from 'node:fs';
const CLOUD='https://apis.roblox.com/cloud/v2/';
const TARGET='universes/9421311218/places/118064584465155/';
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
    const text=await res.text();
    let data;try{data=JSON.parse(text)}catch{data={raw:text}}
    if(res.ok)return data;
    if([429,500,502,503].includes(res.status)){
      const h=Number(res.headers.get('retry-after'));
      const waitMs=Number.isFinite(h)&&h>0?h*1000:Math.min(60000,5000*(i+1));
      console.log(JSON.stringify({retrying:true,status:res.status,attempt:i+1,waitMs}));
      last=new Error('HTTP '+res.status+': '+JSON.stringify(data));
      await sleep(waitMs);continue;
    }
    throw new Error('HTTP '+res.status+': '+JSON.stringify(data));
  }
  throw last||new Error('Retries exhausted');
}
async function execute(script){
  let task=await req(TARGET+'luau-execution-session-tasks',{timeout:'180s',script});
  const deadline=Date.now()+360000;
  while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
    if(Date.now()>deadline)throw new Error('Luau timeout');
    await sleep(1500);task=await req(task.path);
  }
  if(task.state!=='COMPLETE'||task.error)throw new Error('Luau failed: '+JSON.stringify(task));
  return task;
}
function first(task){const v=task?.output?.results?.[0];if(typeof v!=='string')return v??null;try{return JSON.parse(v)}catch{return v}}
const patch=fs.readFileSync('treeworld-v9/patch.luau','utf8');
const validation=fs.readFileSync('treeworld-v9/verify.luau','utf8');
const read=(name)=>fs.readFileSync('treeworld-v9/'+name+'.luau','utf8');
const quote=(text)=>{if(text.includes(']====]'))throw new Error('Unsafe Luau source delimiter');return '[====['+text+']====]'};
const installer=`
local first=game:GetService("ReplicatedFirst")
local sps=game:GetService("StarterPlayer").StarterPlayerScripts
local function install(parent,name,class,source)
 local old=parent:FindFirstChild(name);if old then old:Destroy()end
 local item=Instance.new(class);item.Name=name;item.Source=source;item.Parent=parent
end
install(first,"OveryardLoadingView","ModuleScript",${quote(read('loading-view'))})
install(first,"MapLoadingScreen","LocalScript",${quote(read('loading-client'))})
install(first,"OveryardUpdateMigrationClient","LocalScript",${quote(read('update-client'))})
local old=sps:FindFirstChild("DarkZoneClient");if old then old:Destroy()end
install(sps,"ReferenceEnvironmentClient","LocalScript",${quote(read('environment-client'))})
workspace:SetAttribute("LoadingFlowVersion","2026-10-20-logo-ready-v11")
workspace:SetAttribute("LoadingLogoAssetId",77442764802726)
workspace:SetAttribute("LoadingLogoTransparent",true)
workspace:SetAttribute("LoadingLogoImmediatePreload",true)
workspace:SetAttribute("LoadingGreetingSequence",true)
`;
const script=`local function apply()\n${patch}\nend\nlocal result=apply()\n${installer}\nlocal function verify()\n${validation}\nend\nlocal checks=verify()\nassert(checks.ok,"Pre-save verification failed")\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn {ok=true,patch=result,checks=checks}`;
const applied=first(await execute(script));
if(!applied?.ok)throw new Error('Patch did not return ok=true');
console.log(JSON.stringify({stage:'validated-and-saved',...applied}));
let persisted=null,last=null;
for(let i=0;i<10;i++){
 if(i)await sleep(3500);
 try{
  persisted=first(await execute(validation));
  if(!persisted?.ok||persisted.placeVersion<=applied.patch.sourceVersion)throw new Error('Saved version not visible yet');
  last=null;break;
 }catch(e){last=e}
}
if(last)throw last;
console.log(JSON.stringify({ok:true,persisted}));

// Notify the already-installed group migration system only after persistence
// checks succeed. This is an in-game update signal, not a user message.
const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:persisted.placeVersion,releaseId:'reference-v9-'+persisted.placeVersion,kind:'game-update'});
const broadcast=first(await execute(`local ok,err=pcall(function() game:GetService("MessagingService"):PublishAsync("Overyard_Update_v1",${quote(payload)}) end) return {ok=ok,error=ok and nil or tostring(err)}`));
console.log(JSON.stringify({stage:'update-migration',...broadcast}));
