import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

const key=process.env.ROBLOX_API_KEY;
if(!key)throw new Error('Missing ROBLOX_API_KEY');
const target='universes/9421311218/places/118064584465155/';
const universeId=9421311218;
const placeId=118064584465155;
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));

async function api(url,{method='GET',body,type='application/json'}={}){
 const response=await fetch(url,{
  method,headers:{'x-api-key':key,'content-type':type},body,
  signal:AbortSignal.timeout(240000)
 });
 const raw=await response.text();
 let data;try{data=JSON.parse(raw)}catch{data={raw}};
 if(!response.ok)throw new Error('HTTP '+response.status+': '+JSON.stringify(data).slice(0,900));
 return data;
}
async function download(file,version){
 const suffix=version?'/version/'+version:'';
 const metadata=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+placeId+suffix);
 const location=metadata.location||metadata.locations?.[0]?.location;
 if(!location)throw new Error('Asset download location missing');
 const response=await fetch(location);
 if(!response.ok)throw new Error('Place download HTTP '+response.status);
 const bytes=Buffer.from(await response.arrayBuffer());
 if(bytes.length<10000)throw new Error('Unexpected empty place');
 await fs.writeFile(file,bytes);
 console.log(JSON.stringify({downloaded:true,version,bytes:bytes.length}));
}
async function external(assetId){
 const metadata=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+assetId);
 const location=metadata.location||metadata.locations?.[0]?.location;
 if(!location)throw new Error('Missing source asset '+assetId);
 const response=await fetch(location);
 if(!response.ok)throw new Error('Source asset download HTTP '+response.status);
 await fs.writeFile('/tmp/asset-'+assetId+'.rbxl',Buffer.from(await response.arrayBuffer()));
}
async function execute(script,version,binaryInput){
 const base='https://apis.roblox.com/cloud/v2/';
 let task=await api(base+target+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{
  method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput})
 });
 for(let i=0;['QUEUED','PENDING','PROCESSING'].includes(task.state);i++){
  if(i>240){
   let logs;try{logs=await api(base+task.path+'/logs?view=FLAT')}catch(error){logs=String(error)}
   throw new Error('Execution timeout '+JSON.stringify({state:task.state,path:task.path,logs}));
  }
  await pause(1500);
  task=await api(base+task.path);
 }
 if(task.state!=='COMPLETE'||task.error)throw new Error(JSON.stringify(task.error||task));
 const result=task.output?.results?.[0];
 return typeof result==='string'?JSON.parse(result):result;
}
async function binaryInput(bytes){
 const upload=await api('https://apis.roblox.com/cloud/v2/universes/'+universeId+'/luau-execution-session-task-binary-inputs',{
  method:'POST',body:JSON.stringify({size:bytes.length})
 });
 const response=await fetch(upload.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bytes});
 if(!response.ok)throw new Error('Binary upload HTTP '+response.status);
 return upload.path;
}
async function publish(bytes){
 return api('https://apis.roblox.com/universes/v1/'+universeId+'/places/'+placeId+'/versions?versionType=Published',{
  method:'POST',type:'application/octet-stream',body:bytes
 });
}
async function restart(){
 await api('https://apis.roblox.com/cloud/v2/universes/'+universeId+':restartServers',{method:'POST',body:'{}'});
}
async function secondaryUniverseActive(){
 const response=await fetch('https://develop.roblox.com/v1/universes/9421505041',{signal:AbortSignal.timeout(30000)});
 const raw=await response.text();
 if(!response.ok)throw new Error('Secondary universe status HTTP '+response.status+': '+raw.slice(0,500));
 let data;try{data=JSON.parse(raw)}catch{throw new Error('Secondary universe status was not JSON')}
 if(typeof data.isActive==='boolean')return data.isActive;
 const privacy=typeof data.privacyType==='string'?data.privacyType.toLowerCase():'';
 if(privacy==='public')return true;
 if(privacy==='private')return false;
 throw new Error('Secondary universe status did not include a recognized active or privacy state');
}
async function deactivateSecondaryIfActive(){
 if(!await secondaryUniverseActive()){
  console.log(JSON.stringify({secondaryUniverse:{universeId:9421505041,active:false,changed:false}}));
  return false;
 }
 try{
  await api('https://apis.roblox.com/legacy-develop/v1/universes/9421505041/deactivate',{method:'POST',body:'{}'});
 }catch(error){
  let active;try{active=await secondaryUniverseActive()}catch{throw error}
  if(active)throw error;
 }
 let active;
 try{active=await secondaryUniverseActive()}catch(error){
  try{await api('https://apis.roblox.com/legacy-develop/v1/universes/9421505041/activate',{method:'POST',body:'{}'})}catch{}
  throw new Error('Could not verify secondary universe deactivation; attempted to restore its prior active state: '+String(error));
 }
 if(active)throw new Error('Secondary universe remained active after deactivation request');
 console.log(JSON.stringify({secondaryUniverse:{universeId:9421505041,active:false,changed:true}}));
 return true;
}
async function reactivateSecondary(){
 try{
  await api('https://apis.roblox.com/legacy-develop/v1/universes/9421505041/activate',{method:'POST',body:'{}'});
 }catch(error){
  let active;try{active=await secondaryUniverseActive()}catch{throw error}
  if(!active)throw error;
 }
 if(!await secondaryUniverseActive())throw new Error('Secondary universe reactivation could not be verified');
}
async function preflight(verify){
 return `assert(game.GameId==${universeId} and game.PlaceId==${placeId},'Wrong target')
local b=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
for _,service in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting'}) do
 local target=game:GetService(service)
 for _,child in ipairs(target:GetChildren()) do child:Destroy() end
 for _,child in ipairs(b[service]:GetChildren()) do child.Parent=target end
end
for _,name in ipairs({'StarterPlayerScripts','StarterCharacterScripts'}) do
 local target=game:GetService('StarterPlayer')[name]
 for _,child in ipairs(target:GetChildren()) do child:Destroy() end
 for _,child in ipairs(b[name]:GetChildren()) do child.Parent=target end
end
for _,child in ipairs(workspace:GetChildren()) do if not child:IsA('Terrain') and not child:IsA('Camera') then child:Destroy() end end
for key in pairs(workspace:GetAttributes()) do workspace:SetAttribute(key,nil) end
for key,value in pairs(b:GetAttributes()) do workspace:SetAttribute(key,value) end
workspace:SetAttribute('ExperienceChapter',1)
workspace:SetAttribute('OriginalPreflight',true)
${await fs.readFile(new URL('./original-initialize.luau',import.meta.url),'utf8')}
${verify}`;
}

const releaseState=JSON.parse(await fs.readFile(new URL('./release-state.json',import.meta.url),'utf8'));
await download('/tmp/still-here-rollback.rbxl',undefined);
for(const assetId of ['7902470429','7208091524','186677844','15864801103'])await external(assetId);
const luneArchive=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');
const luneZip=Buffer.from(await luneArchive.arrayBuffer());
if(createHash('sha256').update(luneZip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw new Error('Lune checksum mismatch');
await fs.writeFile('/tmp/still-here-lune.zip',luneZip);
execFileSync('unzip',['-o','/tmp/still-here-lune.zip','-d','/tmp/still-here-lune']);
await fs.chmod('/tmp/still-here-lune/lune',0o755);
const cwd=new URL('.',import.meta.url);
const lune='/tmp/still-here-lune/lune';

execFileSync(lune,['run','original-assemble.luau'],{cwd,stdio:'inherit'});
for(const test of [
 'original-gameplay-test.luau',
 'settings-test.luau',
 'door-lock-test.luau',
 'cinematic-audio-lighting-test.luau',
 'blackhole-layout-test.luau'
]){
 execFileSync(lune,['run',test],{cwd,stdio:'inherit'});
}
await fs.copyFile('/tmp/still-here-original.rbxl','/tmp/still-here-verified.rbxl');
execFileSync(lune,['run','original-file-verify.luau'],{cwd,stdio:'inherit'});
const verify=await fs.readFile(new URL('./original-verify.luau',import.meta.url),'utf8');
const payload=await fs.readFile('/tmp/original-payload.rbxm');
const input=await binaryInput(payload);
console.log(JSON.stringify({mysteryPreflight:await execute(await preflight(verify),releaseState.preflightVersion,input)}));
const candidate=await fs.readFile('/tmp/still-here-original.rbxl');
let published;
let secondaryDeactivated=false;
try{
 published=await publish(candidate);
 console.log(JSON.stringify({mysteryPublishedCandidate:published}));
 const live=await execute("workspace:SetAttribute('OriginalPreflight',true)\n"+await fs.readFile(new URL('./original-initialize.luau',import.meta.url),'utf8')+'\n'+verify,published.versionNumber,input);
 console.log(JSON.stringify({mysteryLiveVerified:live}));
 await download('/tmp/still-here-verified.rbxl',live.version);
 execFileSync(lune,['run','original-file-verify.luau'],{cwd,stdio:'inherit'});
 secondaryDeactivated=await deactivateSecondaryIfActive();
 await restart();
 console.log(JSON.stringify({published:true,mystery:live,restarted:true}));
}catch(error){
 const recovery=[];
 if(secondaryDeactivated){
  try{await reactivateSecondary();recovery.push({secondaryUniverseReactivated:true})}
  catch(restoreSecondaryError){recovery.push({secondaryUniverseRestoreError:String(restoreSecondaryError)})}
 }
 if(published){
  try{recovery.push({restored:await publish(await fs.readFile('/tmp/still-here-rollback.rbxl'))})}
  catch(restoreError){recovery.push({restoreError:String(restoreError)})}
  try{await restart()}catch(restartError){recovery.push({restartError:String(restartError)})}
  if(recovery.length)console.error(JSON.stringify({recovery}));
 }
 throw error;
}
