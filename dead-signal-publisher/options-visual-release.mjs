// Isolated release: updates ONLY ReplicatedStorage.FalloutOptionsClient.Source.
// No HUD, NPC, map, weapon, camera or match scripts are replaced.
import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const root=new URL('.',import.meta.url);
const read=name=>fs.readFile(new URL(name,root),'utf8');
const universe=9421311218;
const place=118064584465155;
const cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('ROBLOX_API_KEY is missing');
const mode=(await read('options-visual.trigger')).trim();
if(!/^options-visual-(preview|publish)-[a-zA-Z0-9-]+$/.test(mode))throw Error('Unsupported settings visual operation');
const liveBefore=JSON.parse(await read('release-state.json'));
const expectedVersion=liveBefore.lastVerifiedVersion;
const oldSignature={size:20782,hash:3359690756};
const revision='fps-gear-icon-settings-v2';
const newSource=await read('fallout-options-client.luau');
const signature=s=>{
 const data=Buffer.from(s,'utf8');let hash=0;
 for(const byte of data)hash=(Math.imul(hash,31)+byte)>>>0;
 return {size:data.length,hash};
};
const newSignature=signature(newSource);
if(newSource.length<19000||!newSource.includes("SettingsGearIcon")||newSource.includes("openButton.Text="))throw Error('Icon-only settings update is incomplete');
async function api(path,{method='GET',body,contentType='application/json'}={}){
 const response=await fetch(path,{method,headers:{'x-api-key':key,'content-type':contentType},body,signal:AbortSignal.timeout(240000)});
 const raw=await response.text();
 let result;try{result=JSON.parse(raw)}catch{result={raw:raw.slice(0,1500)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+': '+JSON.stringify(result));
 return result;
}
async function execute(script,version){
 const target=cloud+'universes/'+universe+'/places/'+place+'/';
 const url=target+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks';
 let task=await api(url,{method:'POST',body:JSON.stringify({timeout:'300s',script})});
 const end=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)&&Date.now()<end){
  await new Promise(resolve=>setTimeout(resolve,1250));
  task=await api(cloud+task.path);
 }
 if(task.state!=='COMPLETE'||task.error)throw Error('Native task '+JSON.stringify(task));
 let out=task.output?.results?.[0];
 return typeof out==='string'?JSON.parse(out):out;
}
const zipResponse=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip',{signal:AbortSignal.timeout(100000)});
if(!zipResponse.ok)throw Error('Lune compiler download failed');
const archive=Buffer.from(await zipResponse.arrayBuffer());
if(createHash('sha256').update(archive).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune compiler integrity check failed');
await fs.writeFile('/tmp/options-visual-lune.zip',archive);
execFileSync('unzip',['-q','-o','/tmp/options-visual-lune.zip','-d','/tmp/options-visual-lune'],{stdio:'ignore'});
await fs.chmod('/tmp/options-visual-lune/lune',0o755);
execFileSync('/tmp/options-visual-lune/lune',['run','options-visual-compile.luau'],{cwd:root.pathname,stdio:'inherit'});
let invariants=await read('lobby-hud-invariants.luau');
// The single replaceable module is excluded. Every other game object is hashed.
const needle="['ReplicatedStorage.FalloutRadarData']=true,";
if(!invariants.includes(needle))throw Error('Protected-game audit layout changed');
invariants=invariants.replace(needle,needle+"\n  ['ReplicatedStorage.FalloutOptionsClient']=true,");
const assertTarget=[
 'assert(game.PlaceId=='+place+' and game.GameId=='+universe+', "Wrong FPS experience")',
 'assert(workspace:GetAttribute("DeadSignalBuildId")=="fallout-5v5-v1", "Wrong game build")',
 'assert(workspace:GetAttribute("FalloutCombatHUDRevision")=="reference-tactical-v1", "Combat HUD differs from preserved target")',
 'assert(#game.Players:GetPlayers()==0, "Settings patch requires isolated execution")',
 'local options=assert(game.ReplicatedStorage:FindFirstChild("FalloutOptionsClient"),"Existing options module missing")',
 'local old=options.Source',
 'assert(#old=='+oldSignature.size+' and sourceHash(old)=='+oldSignature.hash+', "Live settings script changed since audit")'
].join('\n');
const identity='tostring(#options.Source)..":"..tostring(sourceHash(options.Source))';
const baselineScript=invariants+'\n'+assertTarget+'\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,preserved=protectedSnapshot(),oldSize=#old,oldHash=sourceHash(old),revision=workspace:GetAttribute("FalloutOptionsVisualRevision")})';
const baseline=await execute(baselineScript);
if(baseline.version!==expectedVersion)throw Error('Roblox changed since recorded version '+expectedVersion+': '+JSON.stringify(baseline));
console.log('OPTIONS_VISUAL_BASELINE '+JSON.stringify({...baseline,newSignature}));
const install=[
 invariants,
 assertTarget,
 'assert(protectedSnapshot()=='+JSON.stringify(baseline.preserved)+',"Protected baseline mismatch")',
 'options.Source='+JSON.stringify(newSource),
 'workspace:SetAttribute("FalloutOptionsVisualRevision",'+JSON.stringify(revision)+')',
 'assert(#options.Source=='+newSignature.size+' and sourceHash(options.Source)=='+newSignature.hash+',"Updated settings source mismatch")',
 'assert(protectedSnapshot()=='+JSON.stringify(baseline.preserved)+',"Another game object changed")'
].join('\n');
const verify='return game:GetService("HttpService"):JSONEncode({ok=true,version=game.PlaceVersion,preserved=protectedSnapshot(),newSize=#options.Source,newHash=sourceHash(options.Source),revision=workspace:GetAttribute("FalloutOptionsVisualRevision")})';
const checked=await execute(install+'\n'+verify,baseline.version);
if(!checked?.ok||checked.preserved!==baseline.preserved||checked.newHash!==newSignature.hash||checked.newSize!==newSignature.size)throw Error('Native visual settings preflight failed '+JSON.stringify(checked));
console.log('OPTIONS_VISUAL_PREFLIGHT '+JSON.stringify(checked));
if(mode.startsWith('options-visual-preview-')){
 console.log('OPTIONS_VISUAL_PREVIEW_COMPLETE '+JSON.stringify({published:false,verified:true}));
}else{
 const current=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
 if(current.version!==baseline.version)throw Error('FPS changed while preparing settings release');
 let attemptedSave=false;
 try{
  attemptedSave=true;
  const result=await execute(install+'\ngame:GetService("AssetService"):SavePlaceAsync()\n'+verify,baseline.version);
  console.log('OPTIONS_VISUAL_NATIVE_SAVE '+JSON.stringify(result));
  const live=await execute(invariants+'\n'+[
   'assert(game.PlaceId=='+place+' and game.GameId=='+universe+')',
   'local options=game.ReplicatedStorage.FalloutOptionsClient',
   'assert(#options.Source=='+newSignature.size+' and sourceHash(options.Source)=='+newSignature.hash+',"Live source mismatch")',
   'assert(workspace:GetAttribute("FalloutOptionsVisualRevision")=='+JSON.stringify(revision)+')',
   verify
  ].join('\n'));
  if(!live?.ok||live.version!==baseline.version+1||live.preserved!==baseline.preserved)throw Error('Live release verification failed: '+JSON.stringify(live));
  const config=await api(cloud+'universes/'+universe+'/places/'+place);
  if(config.serverSize!==10)throw Error('Unexpected player capacity change');
  await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
  console.log('OPTIONS_VISUAL_RELEASE_COMPLETE '+JSON.stringify({...live,previousVersion:baseline.version,restarted:true,layout:'small-corner',button:'image-gear-icon-only'}));
 }catch(error){
  if(attemptedSave){
   try{
    const current=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
    if(current.version===baseline.version+1){
     await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({rollbackFromVersion=game.PlaceVersion})',baseline.version);
     await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
     console.error('OPTIONS_VISUAL_ROLLBACK '+JSON.stringify({restoredVersion:baseline.version}));
    }else console.error('OPTIONS_VISUAL_ROLLBACK_SKIPPED subsequent release exists');
   }catch(rollback){console.error('OPTIONS_VISUAL_ROLLBACK_FAILED '+String(rollback))}
  }
  throw error;
 }
}
