// Publish the exact already-tested Saved version; do not rebuild or redownload models.
import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
const request=JSON.parse(await fs.readFile(new URL('publish-request.json',import.meta.url),'utf8'));
const proof=JSON.parse(await fs.readFile(new URL('validation-latest.json',import.meta.url),'utf8'));
const previousRecord=JSON.parse(await fs.readFile(new URL('published-test.json',import.meta.url),'utf8'));
const universe='9421311218',place='118064584465155';
if(!request.enabled||String(request.universeId)!==universe||String(request.placeId)!==place)throw Error('Publish destination not authorized');
if(request.stagedVersion!==proof.stagedVersion||request.sha256!==proof.sha256||proof.task.state!=='COMPLETE')throw Error('Validation does not match the requested artifact');
const report=proof.task.output?.results?.[0];
const required=['two-stage loading gates and shared logo build','community movement and prone crawl poses','movement keys preserve active source poses','crouch retargets to standard avatar R6 joints','inventory filters ownership slots and unavailable items','intermission entry preserves arena on countdown end','bots appear only after countdown and clear after round','all server services initialize'];
if(!report||report.placeVersion!==proof.stagedVersion||report.emotePoses!==19||report.botCount<60||report.maps.length<8||required.some(x=>!report.checks.includes(x)))throw Error('Required validation missing');
if(proof.logs.luauExecutionSessionTaskLogs?.some(log=>log.messages?.length))throw Error('Engine validation emitted errors');
const key=process.env.ROBLOX_API_KEY;if(!key)throw Error('Roblox credential missing');
const hash=b=>createHash('sha256').update(b).digest('hex');
const api=async(path,options={})=>{const r=await fetch('https://apis.roblox.com'+path,{...options,headers:{'x-api-key':key,...options.headers},signal:AbortSignal.timeout(90000)});if(!r.ok)throw Error(`HTTP ${r.status} ${path}`);return r.json();};
const delivery=async version=>{const result=await api('/asset-delivery-api/v1/assetId/'+place+'/version/'+version);const url=result.location||result.locations?.[0]?.location;if(!url)throw Error('No delivery location');const response=await fetch(url);if(!response.ok)throw Error('Delivery failed');return Buffer.from(await response.arrayBuffer());};
await fs.mkdir('/tmp/nb-assets',{recursive:true});
const previous=await delivery(previousRecord.version);if(hash(previous)!==previousRecord.sha256)throw Error('Published backup mismatch');
await fs.writeFile(`/tmp/nb-assets/published-v${previousRecord.version}-backup.rbxl`,previous);
const bytes=await delivery(proof.stagedVersion);if(hash(bytes)!==proof.sha256)throw Error('Tested file mismatch');
await fs.writeFile('/tmp/nb-assets/tested-version.rbxl',bytes);
let latest=await api(`/cloud/v2/universes/${universe}/places/${place}/luau-execution-session-tasks`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({script:'return game.PlaceVersion'})});
for(let i=0;i<40&&latest.state==='PROCESSING';i++){await new Promise(r=>setTimeout(r,1500));latest=await api('/cloud/v2/'+latest.path);}
if(latest.state!=='COMPLETE'||latest.output?.results?.[0]!==proof.stagedVersion)throw Error('A newer Studio version exists; publication stopped');
const published=await api(`/universes/v1/${universe}/places/${place}/versions?versionType=Published`,{method:'POST',headers:{'content-type':'application/octet-stream'},body:bytes});
const readback=await delivery(published.versionNumber);if(hash(readback)!==proof.sha256)throw Error('Published readback mismatch');
const result={published:true,version:published.versionNumber,stagedVersion:proof.stagedVersion,universeId:universe,placeId:place,sha256:proof.sha256,sourceCommit:proof.sourceCommit,validationRun:proof.workflowRun,publicationCommit:process.env.GITHUB_SHA,previousPublishedVersion:previousRecord.version,previousPublishedSha256:hash(previous),checks:report.checks,motion:report.motion,admission:report.admission,maps:report.maps.map(m=>({name:m.name,spawns:m.spawns,assetId:m.assetId})),nextbotTemplates:report.botCount,emotes:report.emotePoses,clientPlaytest:false};
await fs.writeFile('/tmp/nb-assets/published-test.json',JSON.stringify(result,null,2));console.log('Published test',JSON.stringify(result));
