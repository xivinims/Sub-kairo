import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const universe=9421311218,place=118064584465155;
const cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('Missing ROBLOX_API_KEY');
const read=file=>fs.readFile(new URL(file,import.meta.url),'utf8');
async function api(url,{method='GET',body}={}){
 const r=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body,signal:AbortSignal.timeout(240000)});
 const raw=await r.text();let result;try{result=JSON.parse(raw)}catch{result={message:raw.slice(0,1500)}}
 if(!r.ok)throw Error('HTTP '+r.status+' '+JSON.stringify(result));return result;
}
async function execute(script,input,version){
 let task=await api(cloud+'universes/'+universe+'/places/'+place+'/'+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput:input})});
 const end=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)&&Date.now()<end){await new Promise(r=>setTimeout(r,1500));task=await api(cloud+task.path)}
 if(task.state!=='COMPLETE'||task.error){let logs;try{logs=await api(cloud+task.path+'/logs?view=FLAT')}catch{};throw Error(JSON.stringify({task,logs}));}
 let v=task.output?.results?.[0];return typeof v==='string'?JSON.parse(v):v;
}
const mode=(await read('asset-probe.trigger')).trim();
if(!/^nametag-(preview|publish)-/.test(mode))throw Error('Unsupported nametag operation');
const invariants=await read('nametag-invariants.luau');
const baseline=await execute(invariants+"\nreturn game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion,build=workspace:GetAttribute('DeadSignalBuildId'),preserved=protectedSnapshot()})");
if(baseline.build!=='fallout-5v5-v1')throw Error('Unexpected live base');
console.log('NAMETAG_BASELINE '+JSON.stringify(baseline));
const delivery=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/72094860266497');
const url=delivery.location||delivery.locations?.[0]?.location;if(!url)throw Error('Source model unavailable');
const response=await fetch(url,{signal:AbortSignal.timeout(120000)});if(!response.ok)throw Error('Asset download failed');const bytes=Buffer.from(await response.arrayBuffer());
if(createHash('sha256').update(bytes).digest('hex')!=='adf4de6a1dc99460d27c8362fea8e259f61bc5ce6bfa01662e07cd1e5a481a37')throw Error('Nametag model changed since audit');
await fs.writeFile('/tmp/nametag-source.rbxm',bytes);
const r=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');if(!r.ok)throw Error('Lune download failed');const zip=Buffer.from(await r.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/nametag-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/nametag-lune.zip','-d','/tmp/nametag-lune']);await fs.chmod('/tmp/nametag-lune/lune',0o755);
execFileSync('/tmp/nametag-lune/lune',['run','nametag-build.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
const bundle=await fs.readFile('/tmp/nametag-bundle.rbxm');
const upload=await api(cloud+'universes/'+universe+'/luau-execution-session-task-binary-inputs',{method:'POST',body:JSON.stringify({size:bundle.length})});
const put=await fetch(upload.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bundle});if(!put.ok)throw Error('Input upload failed');
const install=await read('nametag-install.luau'),verify=await read('nametag-verify.luau');
const script=invariants+'\n'+install+'\n';
const preview=await execute(script+verify,upload.path,baseline.version);
if(!preview?.ok||preview.preserved!==baseline.preserved)throw Error('Native preflight failed or unrelated content changed');
console.log('NAMETAG_PREFLIGHT '+JSON.stringify(preview));
if(mode.startsWith('nametag-preview-'))console.log('NAMETAG_PREVIEW_COMPLETE '+JSON.stringify({published:false,verified:true}));
else{
 const current=await execute("return game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion})");
 if(current.version!==baseline.version)throw Error('Place changed while preparing nametags');
 let saved=false;
 try{
  const save=script+'local checked=(function()\n'+verify+'\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked';
  console.log('NAMETAG_NATIVE_SAVE '+JSON.stringify(await execute(save,upload.path,baseline.version)));saved=true;
  const live=await execute(invariants+'\n'+verify);
  if(!live?.ok||live.version<=baseline.version||live.preserved!==baseline.preserved)throw Error('Live nametag verification failed');
  const config=await api(cloud+'universes/'+universe+'/places/'+place);if(config.serverSize!==10)throw Error('Server size changed');
  await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
  console.log('NAMETAG_RELEASE_COMPLETE '+JSON.stringify({...live,serverSize:config.serverSize,rollbackVersion:baseline.version,restarted:true}));
 }catch(error){
  if(saved){try{console.error('NAMETAG_ROLLBACK '+JSON.stringify(await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restoredFromVersion=game.PlaceVersion})',undefined,baseline.version)))}catch(rollback){console.error('NAMETAG_ROLLBACK_FAILED '+String(rollback))}}
  throw error;
 }
}
