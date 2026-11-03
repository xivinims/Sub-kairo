// Targeted rollback to original FPS GUI and eight equipped guns, preserving world, shop, player saves.
import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const universe=9421311218,place=118064584465155;
const cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('ROBLOX_API_KEY missing');
const read=name=>fs.readFile(new URL(name,import.meta.url),'utf8');
const mode=(await read('fps-original-restore.trigger')).trim();
if(!/^fps-original-restore-(preview|publish)-[a-zA-Z0-9-]+$/.test(mode))throw Error('Unrecognized FPS match bot operation');
const release=JSON.parse(await read('release-state.json'));
async function api(url,{method='GET',body}={}){
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body,signal:AbortSignal.timeout(240000)});
 const raw=await response.text();
 let value;try{value=JSON.parse(raw)}catch{value={message:raw.slice(0,1500)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+' '+JSON.stringify(value));
 return value;
}
async function execute(script,input,version){
 const path=cloud+'universes/'+universe+'/places/'+place+'/'
 let task=await api(path+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput:input})});
 const expires=Date.now()+115000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)&&Date.now()<expires){
  await new Promise(resolve=>setTimeout(resolve,1400));
  task=await api(cloud+task.path);
 }
 if(task.state!=='COMPLETE'||task.error){
  let logs;try{logs=await api(cloud+task.path+'/logs?view=FLAT')}catch{}
  throw Error('Roblox native task failed '+JSON.stringify({task,logs}));
 }
 const result=task.output?.results?.[0];
 return typeof result==='string'?JSON.parse(result):result;
}
const invariants=await read('fps-bots-hud-invariants.luau');
const baseline=await execute(invariants+'\nassert(game.GameId==9421311218 and game.PlaceId==118064584465155)\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,build=workspace:GetAttribute("DeadSignalBuildId"),botBuild=workspace:GetAttribute("FalloutBotsBuild"),combatHud=workspace:GetAttribute("FalloutCombatHUDRevision"),settings=workspace:GetAttribute("FalloutOptionsVisualRevision"),preserved=protectedSnapshot()})');
if(baseline.version!==release.lastVerifiedVersion||baseline.build!=='fallout-5v5-v1'||
 baseline.botBuild!=='training-bots-match-only-v2'||baseline.combatHud!=='reference-tactical-bots-v2'||
 baseline.settings!=='fps-gear-icon-settings-v2'){
 throw Error('The live FPS version changed, refusing to restore: '+JSON.stringify(baseline));
}
console.log('FPS_ORIGINAL_RESTORE_BASELINE '+JSON.stringify(baseline));
const archiveResponse=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip',{signal:AbortSignal.timeout(90000)});
if(!archiveResponse.ok)throw Error('Cannot download headless Luau compiler');
const archive=Buffer.from(await archiveResponse.arrayBuffer());
const digest=createHash('sha256').update(archive).digest('hex');
if(digest!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Luau compiler integrity mismatch');
await fs.writeFile('/tmp/fps-original-restore-lune.zip',archive);
execFileSync('unzip',['-q','-o','/tmp/fps-original-restore-lune.zip','-d','/tmp/fps-original-restore-lune'],{stdio:'ignore'});
await fs.chmod('/tmp/fps-original-restore-lune/lune',0o755);
execFileSync('/tmp/fps-original-restore-lune/lune',['run','fps-original-restore-build.luau'],{cwd:new URL('.',import.meta.url).pathname,stdio:'inherit'});
const bundle=await fs.readFile('/tmp/fps-original-restore.rbxm');
const upload=await api(cloud+'universes/'+universe+'/luau-execution-session-task-binary-inputs',{method:'POST',body:JSON.stringify({size:bundle.length})});
const put=await fetch(upload.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bundle,signal:AbortSignal.timeout(90000)});
if(!put.ok)throw Error('Cannot upload original FPS restore bundle');
const install=await read('fps-original-restore-install.luau');
const verify=await read('fps-original-restore-verify.luau');
const installScript=invariants+'\nassert(game.PlaceVersion==' + baseline.version + ',"Live FPS changed during preflight")\nlocal beforeSnapshot='+JSON.stringify(baseline.preserved)+'\n'+install;
const candidate=await execute(installScript+'\n'+verify,upload.path);
if(!candidate?.ok||candidate.preserved!==baseline.preserved||
 candidate.originalGui!==true||candidate.gunCount!==8){
 throw Error('Original FPS restoration validation failed '+JSON.stringify(candidate));
}
console.log('FPS_ORIGINAL_RESTORE_PREFLIGHT '+JSON.stringify(candidate));
if(mode.startsWith('fps-original-restore-preview-')){
 console.log('FPS_ORIGINAL_RESTORE_PREVIEW_COMPLETE '+JSON.stringify({published:false,verified:true,version:baseline.version}));
}else{
 const fresh=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
 if(fresh.version!==baseline.version)throw Error('FPS place changed after validation');
 let saved=false;
 try{
  const script=installScript+'\nlocal checked=(function()\n'+verify+'\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked';
  const result=await execute(script,upload.path);
  saved=true;
  console.log('FPS_ORIGINAL_RESTORE_NATIVE_SAVE '+JSON.stringify(result));
  const live=await execute(invariants+'\n'+verify);
  if(!live?.ok||live.version!==baseline.version+1||live.preserved!==baseline.preserved||
   live.originalGui!==true||live.gunCount!==8){
   throw Error('Published original FPS did not match verified restoration '+JSON.stringify(live));
  }
  const config=await api(cloud+'universes/'+universe+'/places/'+place);
  if(config.serverSize!==10)throw Error('Game server size changed unexpectedly');
  await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
  console.log('FPS_ORIGINAL_RESTORE_RELEASE_COMPLETE '+JSON.stringify({...live,serverSize:config.serverSize,rollbackVersion:baseline.version,restarted:true}));
 }catch(error){
  if(saved){
   try{
    const latest=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
    if(latest.version===baseline.version+1){
     await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restored:game.PlaceVersion})',undefined,baseline.version);
     await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
     console.error('FPS_ORIGINAL_RESTORE_ROLLED_BACK '+baseline.version);
    }else console.error('FPS_ORIGINAL_RESTORE_ROLLBACK_SKIPPED: later version exists');
   }catch(rollback){console.error('FPS_ORIGINAL_RESTORE_ROLLBACK_ERROR '+String(rollback))}
  }
  throw error;
 }
}
