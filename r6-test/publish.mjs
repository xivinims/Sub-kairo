import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
const universe=9421311218,place=118064584465155;
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('ROBLOX_API_KEY missing');
const base='https://apis.roblox.com/',cloud=base+'cloud/v2/';
async function api(url,method='GET',body){
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(240000)});
 const raw=await response.text();let data;try{data=JSON.parse(raw)}catch{data={message:raw.slice(0,500)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+': '+JSON.stringify(data));return data;
}
async function privateOnly(){
 const info=await api(`https://develop.roblox.com/v1/universes/${universe}`);
 if(info.isActive!==false)throw Error('Experience is not confirmed private; patch stopped');
}
async function execute(script,version){
 let job=await api(cloud+`universes/${universe}/places/${place}/${version?'versions/'+version+'/':''}luau-execution-session-tasks`,'POST',{timeout:'300s',script});
 const until=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(job.state)){
  if(Date.now()>until)throw Error('Native task timeout');await new Promise(r=>setTimeout(r,1500));job=await api(cloud+job.path);
 }
 if(job.state!=='COMPLETE'||job.error)throw Error('Native task failed: '+JSON.stringify(job.error||job));
 const value=job.output?.results?.[0];return typeof value==='string'?JSON.parse(value):value;
}
async function publish(bytes){
 const response=await fetch(base+`universes/v1/${universe}/places/${place}/versions?versionType=Published`,{method:'POST',headers:{'x-api-key':key,'content-type':'application/octet-stream'},body:bytes,signal:AbortSignal.timeout(240000)});
 const raw=await response.text();if(!response.ok)throw Error('Place upload HTTP '+response.status+': '+raw.slice(0,500));return JSON.parse(raw);
}
async function main(){
 await privateOnly();
 const before=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
 if(before.version!==272)throw Error('Expected version 272; refusing to overwrite another change');
 const delivery=await api(base+`asset-delivery-api/v1/assetId/${place}/version/${before.version}`);
 const location=delivery.location||delivery.locations?.[0]?.location;if(!location)throw Error('Backup URL missing');
 const response=await fetch(location,{signal:AbortSignal.timeout(180000)});if(!response.ok)throw Error('Backup download failed');
 const old=Buffer.from(await response.arrayBuffer());await fs.writeFile('r6-test/backup-before-arena.rbxl',old);
 const bytes=await fs.readFile('r6-test/arena.rbxl');
 const fresh=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');
 if(fresh.version!==before.version)throw Error('Place changed during build');
 await privateOnly();let version;
 try {
  const uploaded=await publish(bytes);version=uploaded.versionNumber;if(!version)throw Error('No published version');
  const after=await execute(await fs.readFile('r6-test/verify.luau','utf8'),version);
  if(!after.ok||after.version!==version)throw Error('Saved place verification failed');
  await privateOnly();after.private=true;after.previousVersion=before.version;after.sha256=createHash('sha256').update(bytes).digest('hex');
  try {await api(cloud+`universes/${universe}:restartServers`,'POST',{});after.restarted=true;} catch(error){after.restarted=false;console.warn('Server restart unavailable: '+error.message);}
  await fs.writeFile('r6-test/publication.json',JSON.stringify(after,null,2));console.log('R6_ARENA_COMPLETE '+JSON.stringify(after));
 } catch(error) {
  if(version){const latest=await execute('return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion})');if(latest.version===version){const rollback=await publish(old);console.error('R6_ARENA_ROLLBACK '+JSON.stringify(rollback));}}
  throw error;
 }
}
main().catch(error=>{console.error(String(error.stack||error).split(key).join('[REDACTED]'));process.exitCode=1;});
