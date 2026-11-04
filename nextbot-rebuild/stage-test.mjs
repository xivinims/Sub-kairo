import fs from 'node:fs/promises';import {createHash} from 'node:crypto';
const base='https://apis.roblox.com',universe='9421311218',place='118064584465155';const key=process.env.ROBLOX_API_KEY;const hash=b=>createHash('sha256').update(b).digest('hex');
const api=async(path,options={})=>{const r=await fetch(base+path,{...options,headers:{'x-api-key':key,...options.headers},signal:AbortSignal.timeout(90000)});if(!r.ok)throw Error(`HTTP ${r.status} ${path}: ${(await r.text()).slice(0,400)}`);return r.json()};
const delivery=async version=>{const r=await api('/asset-delivery-api/v1/assetId/'+place+(version?'/version/'+version:''));const url=r.location||r.locations?.[0]?.location;if(!url)throw Error('No delivery URL');const response=await fetch(url);if(!response.ok)throw Error('Delivery failed');return Buffer.from(await response.arrayBuffer());};
const original=await delivery(303);if(hash(original)!=='7d575a803c47b6c0443f36835d27a9c0cb4f127ed48c53fa589b6d04d60575f7')throw Error('Original backup hash mismatch');await fs.writeFile('/tmp/nb-assets/original-v303.rbxl',original);
const backup=await delivery();await fs.writeFile('/tmp/nb-assets/pre-test-backup.rbxl',backup);
const bytes=await fs.readFile('/tmp/nb-assets/NextbotSettingsPreview.rbxl');
const stage=await api(`/universes/v1/${universe}/places/${place}/versions?versionType=Saved`,{method:'POST',headers:{'content-type':'application/octet-stream'},body:bytes});
const downloaded=await delivery(stage.versionNumber);if(hash(bytes)!==hash(downloaded))throw Error('Staged file hash mismatch');
const script=await fs.readFile(new URL('engine-smoke.luau',import.meta.url),'utf8');
let task=await api(`/cloud/v2/universes/${universe}/places/${place}/versions/${stage.versionNumber}/luau-execution-session-tasks`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({script})});
for(let i=0;i<130&&task.state==='PROCESSING';i++){await new Promise(r=>setTimeout(r,2000));task=await api('/cloud/v2/'+task.path);}
let logs;try{logs=await api('/cloud/v2/'+task.path+'/logs')}catch(e){logs={error:String(e)}}
const result={stagedVersion:stage.versionNumber,sha256:hash(bytes),backupSha256:hash(backup),task,logs,published:false};
await fs.writeFile('/tmp/nb-assets/engine-test.json',JSON.stringify(result,null,2));console.log('Engine test',JSON.stringify(result));
if(task.state!=='COMPLETE')throw Error('Engine smoke test failed');
const requestPath=new URL('publish-request.json',import.meta.url);
let request=null;try{request=JSON.parse(await fs.readFile(requestPath,'utf8'))}catch(e){if(e.code!=='ENOENT')throw e}
if(request?.enabled===true){
 if(String(request.universeId)!==universe||String(request.placeId)!==place)throw Error('Publish destination mismatch');
 const report=task.output?.results?.[0];
 if(!report||report.emotePoses!==19||report.botCount<60||report.maps.length<7||!report.checks.includes('all server services initialize'))throw Error('Publish validation incomplete');
 if(report.maps.some(map=>map.spawns<2||map.paths.some(path=>!path.ok||path.status!=='Success')))throw Error('Navigation gate failed');
 // Unversioned asset delivery may return a cached file. Resolve the latest version through an engine session instead.
 let latest=await api(`/cloud/v2/universes/${universe}/places/${place}/luau-execution-session-tasks`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({script:'return game.PlaceVersion'})});
 for(let i=0;i<40&&latest.state==='PROCESSING';i++){await new Promise(r=>setTimeout(r,1500));latest=await api('/cloud/v2/'+latest.path);}
 const latestVersion=latest.output?.results?.[0];console.log('Publication version check',JSON.stringify({stagedVersion:stage.versionNumber,latestVersion,state:latest.state}));
 if(latest.state!=='COMPLETE'||latestVersion!==stage.versionNumber)throw Error('Latest engine version differs from tested version; publication stopped');
 const published=await api(`/universes/v1/${universe}/places/${place}/versions?versionType=Published`,{method:'POST',headers:{'content-type':'application/octet-stream'},body:bytes});
 const readback=await delivery(published.versionNumber);if(hash(readback)!==hash(bytes))throw Error('Published version hash mismatch');
 const publication={published:true,version:published.versionNumber,stagedVersion:stage.versionNumber,universeId:universe,placeId:place,sha256:hash(bytes),sourceCommit:process.env.GITHUB_SHA,originalBackupVersion:303,originalBackupSha256:hash(original),maps:report.maps.map(m=>({name:m.name,spawns:m.spawns})),nextbotTemplates:report.botCount,emotes:report.emotePoses,clientPlaytest:false};
 await fs.writeFile('/tmp/nb-assets/published-test.json',JSON.stringify(publication,null,2));console.log('Published test',JSON.stringify(publication));
}
