import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const universe=9421311218,place=118064584465155;
const cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('Missing ROBLOX_API_KEY');
const read=file=>fs.readFile(new URL(file,import.meta.url),'utf8');
const hashes={72094860266497:'adf4de6a1dc99460d27c8362fea8e259f61bc5ce6bfa01662e07cd1e5a481a37',8438960542:'63fe18a8206c1c03a1f1b449fccf7b8f2479677c8eacf75e6d44fb3d0faa3f0f',95512398319263:'5732010af7e03bba350c6b5be2485632411696e7ca494565bce22641a825c6fc',12987749061:'0b41c77276e18389d9a0ee96c096211925abcc3b0acf1479a6027f21daea52f4',86582491164528:'84d15dea4796973ac00984f3f6ecec55b8af8215c3362e2b5edfd105f47e1e1d',80608769509945:'c5ab30013b27e7c2404bca14a7ab40473026f346f8c09110b4a7a21b08248105',110602808776017:'a5615c0b4a8c1981a8618dfaa46976bf897e51f475d2188f811a11cc84780f29',15864801103:'6cd1bc3e7a71505b38965acc3e8219bc84bda1b8ac4ca64ae0ca4151800a2d02'};
async function api(url,{method='GET',body}={}){
 const r=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body,signal:AbortSignal.timeout(240000)});
 const raw=await r.text();let result;try{result=JSON.parse(raw)}catch{result={message:raw.slice(0,1500)}}
 if(!r.ok)throw Error('HTTP '+r.status+' '+JSON.stringify(result));return result;
}
async function download(id){
 const meta=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+id);
 const url=meta.location||meta.locations?.[0]?.location;if(!url)throw Error('Missing asset '+id);
 const r=await fetch(url,{signal:AbortSignal.timeout(240000)});if(!r.ok)throw Error('Asset download failed '+id);
 const bytes=Buffer.from(await r.arrayBuffer());
 if(hashes[id]&&createHash('sha256').update(bytes).digest('hex')!==hashes[id])throw Error('Asset changed after inspection: '+id);
 await fs.writeFile('/tmp/fallout-input-'+id,bytes);
}
async function execute(script,input,version){
 let task=await api(cloud+'universes/'+universe+'/places/'+place+'/'+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput:input})});
 const end=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)&&Date.now()<end){await new Promise(r=>setTimeout(r,1500));task=await api(cloud+task.path)}
 if(task.state!=='COMPLETE'||task.error){let logs;try{logs=await api(cloud+task.path+'/logs?view=FLAT')}catch{};throw Error(JSON.stringify({task,logs}));}
 let v=task.output?.results?.[0];return typeof v==='string'?JSON.parse(v):v;
}
const mode=(await read('asset-probe.trigger')).trim();
if(!/^fallout-(preview|publish)-/.test(mode))throw Error('Unsupported Fallout operation');
const baseline=await execute("return game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion,build=workspace:GetAttribute('DeadSignalBuildId')})");
console.log('FALLOUT_BASELINE '+JSON.stringify(baseline));
for(const id of Object.keys(hashes))await download(id);
const r=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');if(!r.ok)throw Error('Lune download failed');const zip=Buffer.from(await r.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/fallout-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/fallout-lune.zip','-d','/tmp/fallout-lune']);await fs.chmod('/tmp/fallout-lune/lune',0o755);
await fs.copyFile('/tmp/fallout-input-72094860266497','/tmp/nametag-source.rbxm');
execFileSync('/tmp/fallout-lune/lune',['run','nametag-build.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
execFileSync('/tmp/fallout-lune/lune',['run','fallout-build.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
const bundle=await fs.readFile('/tmp/fallout-bundle.rbxm');
const upload=await api(cloud+'universes/'+universe+'/luau-execution-session-task-binary-inputs',{method:'POST',body:JSON.stringify({size:bundle.length})});
const put=await fetch(upload.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bundle});if(!put.ok)throw Error('Binary input upload failed');
const install=await read('fallout-install.luau'),verify=await read('fallout-verify.luau');
const preview=await execute(install+'\n'+verify,upload.path,baseline.version);
if(!preview?.ok)throw Error('Native verification failed');
console.log('FALLOUT_PREFLIGHT '+JSON.stringify(preview));
if(mode.startsWith('fallout-preview-')){console.log('FALLOUT_PREVIEW_COMPLETE '+JSON.stringify({published:false,verified:true}));}
else{
 const current=await execute("return game:GetService('HttpService'):JSONEncode({version=game.PlaceVersion})");
 if(current.version!==baseline.version)throw Error('Place changed while preparing release');
 const save=install+'\nlocal checked=(function()\n'+verify+'\nend)()\ngame:GetService("AssetService"):SavePlaceAsync()\nreturn checked';
 let saved=false;
 try{
  console.log('FALLOUT_NATIVE_SAVE '+JSON.stringify(await execute(save,upload.path,baseline.version)));saved=true;
  const live=await execute(verify);
  if(!live?.ok||live.version<=baseline.version)throw Error('The new native place version was not published');
  const url=cloud+'universes/'+universe+'/places/'+place;
  await api(url+'?updateMask=serverSize',{method:'PATCH',body:JSON.stringify({serverSize:10})});
  const config=await api(url);if(config.serverSize!==10)throw Error('Server size was not set to 10');
  await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'});
  console.log('FALLOUT_RELEASE_COMPLETE '+JSON.stringify({...live,serverSize:config.serverSize,rollbackVersion:baseline.version,restarted:true}));
 }catch(error){
  if(saved){try{console.error('FALLOUT_ROLLBACK '+JSON.stringify(await execute('game:GetService("AssetService"):SavePlaceAsync()\nreturn game:GetService("HttpService"):JSONEncode({restoredFromVersion=game.PlaceVersion})',undefined,baseline.version)))}catch(rollback){console.error('FALLOUT_ROLLBACK_FAILED '+String(rollback))}}
  throw error;
 }
}
