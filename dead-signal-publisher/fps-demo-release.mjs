import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const universe=9421311218,place=118064584465155,sourceId=15864801103;
const expectedSourceSha='6cd1bc3e7a71505b38965acc3e8219bc84bda1b8ac4ca64ae0ca4151800a2d02';
const cloud='https://apis.roblox.com/cloud/v2/';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw Error('Missing ROBLOX_API_KEY');
async function api(url,{method='GET',body,type='application/json'}={}){
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':type},body,signal:AbortSignal.timeout(240000)});
 const raw=await response.text();let data;try{data=JSON.parse(raw)}catch{data={raw:raw.slice(0,1200)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+': '+JSON.stringify(data));
 return data;
}
async function fetchLocation(url){const response=await fetch(url,{signal:AbortSignal.timeout(240000)});if(!response.ok)throw Error('Roblox asset download HTTP '+response.status);return Buffer.from(await response.arrayBuffer())}
async function sourceBytes(){
 const mr=await fetch('https://economy.roblox.com/v2/assets/'+sourceId+'/details',{signal:AbortSignal.timeout(60000)});
 const meta=await mr.json().catch(()=>({}));
 if(!mr.ok||meta.Name!=='FPS System Demo (uncopylocked)'||meta.AssetTypeId!==9)throw Error('Source metadata no longer matches the requested complete Roblox place');
 const delivery=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+sourceId);
 const location=delivery.location||delivery.locations?.[0]?.location;if(!location)throw Error('Source place download URL missing');
 const bytes=await fetchLocation(location),digest=createHash('sha256').update(bytes).digest('hex');
 if(digest!==expectedSourceSha)throw Error('Downloaded place hash differs from the audited exact asset');
 await fs.writeFile('/tmp/fps-system-demo-source',bytes);
 return {bytes,digest,metadata:{name:meta.Name,assetTypeId:meta.AssetTypeId,creator:meta.Creator,description:meta.Description}};
}
async function setupLune(){
 const response=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip',{signal:AbortSignal.timeout(120000)});
 if(!response.ok)throw Error('Lune download HTTP '+response.status);
 const zip=Buffer.from(await response.arrayBuffer());
 if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
 await fs.writeFile('/tmp/fps-demo-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/fps-demo-lune.zip','-d','/tmp/fps-demo-lune']);await fs.chmod('/tmp/fps-demo-lune/lune',0o755);
}
function verifyFile(){
 const out=execFileSync('/tmp/fps-demo-lune/lune',['run','fps-demo-verify.luau'],{cwd:new URL('.',import.meta.url),encoding:'utf8',stdio:['ignore','pipe','inherit']});
 return JSON.parse(out.trim().split('\n').at(-1));
}
function stable(value){if(Array.isArray(value))return '['+value.map(stable).join(',')+']';if(value&&typeof value==='object')return '{'+Object.keys(value).sort().map(k=>JSON.stringify(k)+':'+stable(value[k])).join(',')+'}';return JSON.stringify(value)}
async function downloadPlace(version){
 const p=version?'/version/'+version:'';
 const meta=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+place+p);
 const location=meta.location||meta.locations?.[0]?.location;if(!location)throw Error('Place download URL missing for '+(version||'current'));
 const bytes=await fetchLocation(location);if(bytes.length<100000)throw Error('Place backup is unexpectedly small');return bytes;
}
async function publish(bytes){return api('https://apis.roblox.com/universes/v1/'+universe+'/places/'+place+'/versions?versionType=Published',{method:'POST',type:'application/octet-stream',body:bytes})}
async function restart(){await api(cloud+'universes/'+universe+':restartServers',{method:'POST',body:'{}'})}
export async function runFpsDemo(mode){
 const source=await sourceBytes();await setupLune();
 const inspected=verifyFile();
 if(inspected.containerType!=='Place'||inspected.descendantCount!==198476||inspected.scriptCount!==236||inspected.suspiciousPatterns.length)throw Error('Exact source place did not pass preflight');
 console.log('FPS_SOURCE_VERIFIED '+JSON.stringify({...source.metadata,sha256:source.digest,bytes:source.bytes.length,instances:inspected.descendantCount,scripts:inspected.scriptCount,scriptBytes:inspected.scriptBytes,suspiciousPatterns:inspected.suspiciousPatterns,topLevel:inspected.topLevel}));
 if(mode.startsWith('fps-demo-validate')){console.log('FPS_SOURCE_PREFLIGHT_COMPLETE '+JSON.stringify({published:false,verified:true}));return}
 if(!mode.startsWith('fps-demo-publish'))throw Error('Unknown FPS demo operation '+mode);
 const rollbackBytes=await downloadPlace();
 const rollbackSha=createHash('sha256').update(rollbackBytes).digest('hex');
 if(rollbackSha===source.digest)throw Error('Target already has the requested source content');
 let attempted=false;
 try{
  attempted=true;
  const result=await publish(source.bytes);
  if(!result.versionNumber)throw Error('Place publish did not return a version number');
  console.log('FPS_DEMO_PUBLISHED '+JSON.stringify({versionNumber:result.versionNumber,sourceSha:source.digest,bytes:source.bytes.length}));
  const targetBytes=await downloadPlace(result.versionNumber);
  const targetSha=createHash('sha256').update(targetBytes).digest('hex');
  await fs.writeFile('/tmp/fps-system-demo-source',targetBytes);
  const after=verifyFile();
  if(stable(after)!==stable(inspected))throw Error('Published place structure or scripts differ from exact source');
  if(targetSha!==source.digest)console.log('FPS_DEMO_ROBLOX_NORMALIZED_FILE '+JSON.stringify({sourceSha:source.digest,publishedSha:targetSha,verifiedStructure:true}));
  await restart();
  console.log('FPS_DEMO_REPLACEMENT_COMPLETE '+JSON.stringify({sourceId,place,universe,versionNumber:result.versionNumber,sha256:targetSha,instances:after.descendantCount,scripts:after.scriptCount,restarted:true}));
 }catch(error){
  if(attempted){const recovered=await publish(rollbackBytes);await restart();console.error('FPS_DEMO_ROLLBACK '+JSON.stringify({restoredFromOriginalBytes:true,restoredVersion:recovered.versionNumber,oldSha:rollbackSha}));}
  throw error;
 }
}
