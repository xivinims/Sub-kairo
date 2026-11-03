import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const universe=9421311218,place=118064584465155,cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;if(!key)throw Error('Missing ROBLOX_API_KEY');
const read=file=>fs.readFile(new URL(file,import.meta.url),'utf8');
async function api(url,{method='GET',body}={}){
 const r=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body,signal:AbortSignal.timeout(240000)});
 const raw=await r.text();let result;try{result=JSON.parse(raw)}catch{result={message:raw.slice(0,1500)}}
 if(!r.ok)throw Error('HTTP '+r.status+' '+JSON.stringify(result));return result;
}
async function execute(script,version){
 let task=await api(cloud+'universes/'+universe+'/places/'+place+'/'+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script})});
 const end=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)&&Date.now()<end){await new Promise(r=>setTimeout(r,1500));task=await api(cloud+task.path)}
 if(task.state!=='COMPLETE'||task.error){let logs;try{logs=await api(cloud+task.path+'/logs?view=FLAT')}catch{};throw Error(JSON.stringify({task,logs}));}
 let v=task.output?.results?.[0];return typeof v==='string'?JSON.parse(v):v;
}
function literal(value){let equals='====';while(value.includes(']'+equals+']'))equals+='=';return '['+equals+'[\n'+value+']'+equals+']'}
function hash(value){let result=0;for(const byte of Buffer.from(value))result=(result*31+byte)>>>0;return result}
const mode=(await read('asset-probe.trigger')).trim();if(!/^viewport-(preview|publish)-/.test(mode))throw Error('Unsupported operation');
const response=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip',{signal:AbortSignal.timeout(120000)});
if(!response.ok)throw Error('Lune download failed');const zip=Buffer.from(await response.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/viewport-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/viewport-lune.zip','-d','/tmp/viewport-lune']);await fs.chmod('/tmp/viewport-lune/lune',0o755);
execFileSync('/tmp/viewport-lune/lune',['run','viewport-compile.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
const invariants=await read('viewport-invariants.luau'),verify=await read('viewport-verify.luau');
const client=await read('fallout-client.luau'),ui=await read('fallout-ui.luau');
const baseline=await execute(invariants+"\nreturn game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion,build=workspace:GetAttribute('DeadSignalBuildId'),preserved=protectedSnapshot(),clientHash=sourceHash(game.StarterPlayer.StarterPlayerScripts.FalloutClient.Source),uiHash=sourceHash(game.ReplicatedStorage.FalloutUI.Source)})");
if(baseline.build!=='fallout-5v5-v1')throw Error('Unexpected base game');
if(![1069324272,hash(client)].includes(baseline.clientHash)||![2963093383,hash(ui)].includes(baseline.uiHash))throw Error('Shop scripts changed since the inspected version');
console.log('VIEWPORT_BASELINE '+JSON.stringify(baseline));
const install=`
assert(game.GameId==${universe} and game.PlaceId==${place},'Wrong experience')
assert(protectedSnapshot()==${literal(baseline.preserved)},'Base content changed')
local client=game.StarterPlayer.StarterPlayerScripts.FalloutClient
local ui=game.ReplicatedStorage.FalloutUI
assert(sourceHash(client.Source)==${baseline.clientHash} and sourceHash(ui.Source)==${baseline.uiHash},'Shop changed')
client.Source=${literal(client)}
ui.Source=${literal(ui)}
game.ReplicatedStorage.FalloutItemVisuals:SetAttribute('UseReliableIcons',nil)
workspace:SetAttribute('FalloutViewportRevision','weapon-clones-v1')
assert(protectedSnapshot()==${literal(baseline.preserved)},'Unrelated content changed')
`;
const patch=invariants+'\n'+install+'\n';
const preflight=await execute(patch+verify,baseline.version);
if(!preflight?.ok||preflight.preserved!==baseline.preserved)throw Error('Native preflight failed');
console.log('VIEWPORT_PREFLIGHT '+JSON.stringify(preflight));
if(mode.startsWith('viewport-preview-'))console.log('VIEWPORT_PREVIEW_COMPLETE '+JSON.stringify({published:false,verified:true}));
else{
 const current=await execute("return game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion})");
 if(current.version!==baseline.version)throw Error('Place changed while preparing release');
 let saved=false;
 try{
  const save=patch+'local checked=(function()\n'+verify+'\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked';
  console.log('VIEWPORT_NATIVE_SAVE '+JSON.stringify(await execute(save,baseline.version)));saved=true;
  const live=await execute(invariants+'\n'+verify);
  if(!live?.ok||live.version<=baseline.version||live.preserved!==baseline.preserved)throw Error('Live verification failed');
  const config=await api(cloud+'universes/'+universe+'/places/'+place);if(config.serverSize!==10)throw Error('Server size changed');
  await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
  console.log('VIEWPORT_RELEASE_COMPLETE '+JSON.stringify({...live,serverSize:config.serverSize,rollbackVersion:baseline.version,restarted:true}));
 }catch(error){
  if(saved){try{console.error('VIEWPORT_ROLLBACK '+JSON.stringify(await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restoredFromVersion=game.PlaceVersion})',baseline.version)))}catch(rollback){console.error('VIEWPORT_ROLLBACK_FAILED '+String(rollback))}}
  throw error;
 }
}
