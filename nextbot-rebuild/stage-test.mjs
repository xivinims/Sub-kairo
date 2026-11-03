import fs from 'node:fs/promises';import {createHash} from 'node:crypto';
const base='https://apis.roblox.com',universe='9421311218',place='118064584465155';const key=process.env.ROBLOX_API_KEY;const hash=b=>createHash('sha256').update(b).digest('hex');
const api=async(path,options={})=>{const r=await fetch(base+path,{...options,headers:{'x-api-key':key,...options.headers},signal:AbortSignal.timeout(90000)});if(!r.ok)throw Error(`HTTP ${r.status} ${path}: ${(await r.text()).slice(0,400)}`);return r.json()};
const delivery=async version=>{const r=await api('/asset-delivery-api/v1/assetId/'+place+(version?'/version/'+version:''));const url=r.location||r.locations?.[0]?.location;if(!url)throw Error('No delivery URL');const response=await fetch(url);if(!response.ok)throw Error('Delivery failed');return Buffer.from(await response.arrayBuffer());};
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
