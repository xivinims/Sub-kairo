import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const universe=9421311218,place=118064584465155,cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;if(!key)throw Error('Missing ROBLOX_API_KEY');
const read=file=>fs.readFile(new URL(file,import.meta.url),'utf8');
async function api(url,{method='GET',body}={}){
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body,signal:AbortSignal.timeout(120000)});
 const raw=await response.text();let result;try{result=JSON.parse(raw)}catch{result={message:raw.slice(0,1500)}}
 if(!response.ok)throw Error('HTTP '+response.status+' '+JSON.stringify(result));return result;
}
async function execute(script,input,version){
 let task=await api(cloud+'universes/'+universe+'/places/'+place+'/'+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'180s',script,binaryInput:input})});
 const deadline=Date.now()+270000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)&&Date.now()<deadline){await new Promise(r=>setTimeout(r,1500));task=await api(cloud+task.path)}
 if(task.state!=='COMPLETE'||task.error){let logs;try{logs=await api(cloud+task.path+'/logs?view=FLAT')}catch{};throw Error(JSON.stringify({task,logs}));}
 let value=task.output?.results?.[0];return typeof value==='string'?JSON.parse(value):value;
}
const mode=(await read('asset-probe.trigger')).trim();if(!/^lobby-hud-(audit|preview|publish)-/.test(mode))throw Error('Unsupported lobby HUD operation');
const metadata=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/84860453909277');
const assetUrl=metadata.location||metadata.locations?.[0]?.location;if(!assetUrl)throw Error('Health asset is unavailable');
const assetResponse=await fetch(assetUrl,{signal:AbortSignal.timeout(60000)});if(!assetResponse.ok)throw Error('Health asset download failed');
const asset=Buffer.from(await assetResponse.arrayBuffer());
console.log('LOBBY_HEALTH_SOURCE '+JSON.stringify({assetId:'84860453909277',sha256:createHash('sha256').update(asset).digest('hex'),bytes:asset.length}));
if(createHash('sha256').update(asset).digest('hex')!=='35bbef11373c32284c354fc7102af891af85fd133c2ac4be5e3df2ec7ad2deca')throw Error('Health asset changed after inspection');
await fs.writeFile('/tmp/lobby-health-source.rbxm',asset);
const response=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip',{signal:AbortSignal.timeout(60000)});
if(!response.ok)throw Error('Lune download failed');const zip=Buffer.from(await response.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/lobby-hud-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/lobby-hud-lune.zip','-d','/tmp/lobby-hud-lune']);await fs.chmod('/tmp/lobby-hud-lune/lune',0o755);
if(mode.startsWith('lobby-hud-audit-')){
 execFileSync('/tmp/lobby-hud-lune/lune',['run','lobby-hud-inspect.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
 console.log('LOBBY_HUD_AVATAR_AUDIT '+JSON.stringify(await execute(await read('lobby-hud-audit.luau'))));
}else{
 execFileSync('/tmp/lobby-hud-lune/lune',['run','lobby-hud-build.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
 const invariants=await read('lobby-hud-invariants.luau'),verify=await read('lobby-hud-verify.luau');
 const baseline=await execute(invariants+"\nreturn game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion,build=workspace:GetAttribute('DeadSignalBuildId'),preserved=protectedSnapshot()})");
 if(baseline.build!=='fallout-5v5-v1'||baseline.version!==256)throw Error('FPS version changed since inspection: '+JSON.stringify(baseline));
 console.log('LOBBY_HUD_BASELINE '+JSON.stringify(baseline));
 const bundle=await fs.readFile('/tmp/lobby-hud-bundle.rbxm');
 const upload=await api(cloud+'universes/'+universe+'/luau-execution-session-task-binary-inputs',{method:'POST',body:JSON.stringify({size:bundle.length})});
 const put=await fetch(upload.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bundle,signal:AbortSignal.timeout(60000)});if(!put.ok)throw Error('Patch payload upload failed');
 const guard="\nassert(protectedSnapshot()=="+JSON.stringify(baseline.preserved)+",'Unrelated FPS content changed')\n";
 const patch=invariants+guard+(await read('lobby-hud-install.luau'))+'\n'+(await read('lobby-hud-radar.luau'))+guard;
 const preflight=await execute(patch+verify,upload.path,baseline.version);
 if(!preflight?.ok||preflight.preserved!==baseline.preserved)throw Error('Native preflight failed');
 console.log('LOBBY_HUD_PREFLIGHT '+JSON.stringify(preflight));
 if(mode.startsWith('lobby-hud-preview-'))console.log('LOBBY_HUD_PREVIEW_COMPLETE '+JSON.stringify({published:false,verified:true}));
 else{
  const current=await execute("return game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion})");
  if(current.version!==baseline.version)throw Error('Place changed during preparation');
  let saved=false;
  try{
   const release=process.env.GITHUB_SHA||'manual-lobby-hud';
   const save=patch+'local checked=(function()\n'+verify+'\nend)()\nworkspace:SetAttribute("FalloutLobbyHUDRelease",'+JSON.stringify(release)+')\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked';
   console.log('LOBBY_HUD_NATIVE_SAVE '+JSON.stringify(await execute(save,upload.path,baseline.version)));saved=true;
   const live=await execute(invariants+'\n'+verify);
   if(!live?.ok||live.version!==baseline.version+1||live.preserved!==baseline.preserved)throw Error('Published version verification failed');
   const config=await api(cloud+'universes/'+universe+'/places/'+place);if(config.serverSize!==10)throw Error('Unexpected server size');
   await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
   console.log('LOBBY_HUD_RELEASE_COMPLETE '+JSON.stringify({...live,serverSize:config.serverSize,rollbackVersion:baseline.version,restarted:true}));
  }catch(error){
   if(saved){
    try{
     const latest=await execute("return game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion})");
     if(latest.version===baseline.version+1){
      console.error('LOBBY_HUD_ROLLBACK '+JSON.stringify(await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restoredFromVersion=game.PlaceVersion})',undefined,baseline.version)));
      await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
     }else console.error('LOBBY_HUD_ROLLBACK_SKIPPED later publication exists');
    }catch(rollback){console.error('LOBBY_HUD_ROLLBACK_FAILED '+String(rollback))}
   }
   throw error;
  }
 }
}
