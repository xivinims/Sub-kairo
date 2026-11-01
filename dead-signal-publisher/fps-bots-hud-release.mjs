// Safe Roblox FPS release: HUD/AI only, no map or lobby rebuild.
import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const universe=9421311218,place=118064584465155;
const cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('Missing ROBLOX_API_KEY');
const read=p=>fs.readFile(new URL(p,import.meta.url),'utf8');
const mode=(await read('fps-bots-hud.trigger')).trim();
if(!/^fps-bots-hud-(preview|publish)-[a-zA-Z0-9-]+$/.test(mode))throw Error('Unexpected game release operation');
const meta=JSON.parse(await read('release-state.json'));
async function api(url,{method='GET',body}={}){
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body,signal:AbortSignal.timeout(240000)});
 const raw=await response.text();
 let data;try{data=JSON.parse(raw)}catch{data={message:raw.slice(0,1200)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+': '+JSON.stringify(data));
 return data;
}
async function execute(script,input,version){
 const target=cloud+'universes/'+universe+'/places/'+place+'/';
 let job=await api(target+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput:input})});
 const deadline=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(job.state)&&Date.now()<deadline){
  await new Promise(resolve=>setTimeout(resolve,1400));
  job=await api(cloud+job.path);
 }
 if(job.state!=='COMPLETE'||job.error){
  let logs;try{logs=await api(cloud+job.path+'/logs?view=FLAT')}catch{}
  throw Error('Roblox native execution: '+JSON.stringify({job,logs}));
 }
 const value=job.output?.results?.[0];
 return typeof value==='string'?JSON.parse(value):value;
}
const base=await read('fps-bots-hud-invariants.luau');
const baseline=await execute(base+'\nassert(game.PlaceId=='+place+' and game.GameId=='+universe+')\nreturn game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,preserved=protectedSnapshot(),revision=workspace:GetAttribute("FalloutCombatHUDRevision"),options=workspace:GetAttribute("FalloutOptionsVisualRevision"),build=workspace:GetAttribute("DeadSignalBuildId")})');
if(baseline.version!==meta.lastVerifiedVersion||baseline.revision!=='reference-tactical-v1'||baseline.options!=='fps-gear-icon-settings-v2'||baseline.build!=='fallout-5v5-v1'){
 throw Error('FPS published state differs from audited baseline '+JSON.stringify(baseline));
}
console.log('FPS_BOTS_HUD_BASELINE '+JSON.stringify(baseline));
const luneUrl='https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip';
const response=await fetch(luneUrl,{signal:AbortSignal.timeout(90000)});
if(!response.ok)throw Error('Lune not accessible');
const zip=Buffer.from(await response.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum incorrect');
await fs.writeFile('/tmp/fps-npc-lune.zip',zip);
execFileSync('unzip',['-q','-o','/tmp/fps-npc-lune.zip','-d','/tmp/fps-npc-lune'],{stdio:'ignore'});
await fs.chmod('/tmp/fps-npc-lune/lune',0o755);
execFileSync('/tmp/fps-npc-lune/lune',['run','fps-bots-hud-build.luau'],{cwd:new URL('.',import.meta.url).pathname,stdio:'inherit'});
const bundle=await fs.readFile('/tmp/fps-bots-hud-patch.rbxm');
const slot=await api(cloud+'universes/'+universe+'/luau-execution-session-task-binary-inputs',{method:'POST',body:JSON.stringify({size:bundle.length})});
const put=await fetch(slot.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bundle,signal:AbortSignal.timeout(90000)});
if(!put.ok)throw Error('Cannot upload bot/HUD patch');
const install=await read('fps-bots-hud-install.luau');
const verify=await read('fps-bots-hud-verify.luau');
const preflight=base+'\nlocal beforeSnapshot='+JSON.stringify(baseline.preserved)+'\n'+install+'\n'+verify;
const checked=await execute(preflight,slot.path,baseline.version);
if(!checked?.ok||checked.preserved!==baseline.preserved)throw Error('NPC/HUD sandbox preflight failed: '+JSON.stringify(checked));
console.log('FPS_BOTS_HUD_PREFLIGHT '+JSON.stringify(checked));
if(mode.startsWith('fps-bots-hud-preview-')){
 console.log('FPS_BOTS_HUD_PREVIEW_COMPLETE '+JSON.stringify({published:false,validated:true,version:baseline.version}));
}else{
 const latest=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
 if(latest.version!==baseline.version)throw Error('Place was modified while checking NPC release');
 let attemptedSave=false;
 try{
  const script=base+'\nlocal beforeSnapshot='+JSON.stringify(baseline.preserved)+'\n'+install+'\nlocal checked=(function()\n'+verify+'\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked';
  attemptedSave=true;
  const saved=await execute(script,slot.path,baseline.version);
  console.log('FPS_BOTS_HUD_NATIVE_SAVE '+JSON.stringify(saved));
  const live=await execute(base+'\n'+verify);
  if(!live?.ok||live.version!==baseline.version+1||live.preserved!==baseline.preserved)throw Error('Live bot/HUD verification failed: '+JSON.stringify(live));
  const config=await api(cloud+'universes/'+universe+'/places/'+place);
  if(config.serverSize!==10)throw Error('Unexpected 5v5 server capacity');
  await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
  console.log('FPS_BOTS_HUD_RELEASE_COMPLETE '+JSON.stringify({...live,serverSize:config.serverSize,previousVersion:baseline.version,restarted:true}));
 }catch(error){
  if(attemptedSave){
   try{
    const current=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
    if(current.version===baseline.version+1){
     console.error('FPS_BOTS_HUD_ROLLBACK '+JSON.stringify(await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({rollback:game.PlaceVersion})',undefined,baseline.version)));
     await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
    }else console.error('FPS_BOTS_HUD_ROLLBACK_SKIPPED other changes exist');
   }catch(rollback){console.error('FPS_BOTS_HUD_ROLLBACK_ERROR '+String(rollback))}
  }
  throw error;
 }
}
