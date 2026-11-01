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
await fs.writeFile('/tmp/lobby-health-source.rbxm',asset);
const response=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip',{signal:AbortSignal.timeout(60000)});
if(!response.ok)throw Error('Lune download failed');const zip=Buffer.from(await response.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum mismatch');
await fs.writeFile('/tmp/lobby-hud-lune.zip',zip);execFileSync('unzip',['-q','-o','/tmp/lobby-hud-lune.zip','-d','/tmp/lobby-hud-lune']);await fs.chmod('/tmp/lobby-hud-lune/lune',0o755);
if(mode.startsWith('lobby-hud-audit-')){
 execFileSync('/tmp/lobby-hud-lune/lune',['run','lobby-hud-inspect.luau'],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
 console.log('LOBBY_HUD_AVATAR_AUDIT '+JSON.stringify(await execute(await read('lobby-hud-audit.luau'))));
}else throw Error('Publish path requires inspected health asset and frozen avatar');
