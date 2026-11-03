import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw new Error('Missing ROBLOX_API_KEY');
const target='universes/9421311218/places/118064584465155/';
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function api(url,{method='GET',body,type='application/json'}={}){
 const r=await fetch(url,{method,headers:{'x-api-key':key,'content-type':type},body,signal:AbortSignal.timeout(240000)});
 const raw=await r.text();let j;try{j=JSON.parse(raw)}catch{j={raw}};
 if(!r.ok)throw new Error('HTTP '+r.status+': '+JSON.stringify(j).slice(0,900));return j;
}
async function download(file,version){
 const suffix=version?'/version/'+version:'';
 const j=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/118064584465155'+suffix);
 const location=j.location||j.locations?.[0]?.location;
 if(!location)throw new Error('Asset download location missing');
 const r=await fetch(location);if(!r.ok)throw new Error('File download HTTP '+r.status);
 const data=Buffer.from(await r.arrayBuffer());if(data.length<10000)throw new Error('Unexpected empty place');
 await fs.writeFile(file,data);console.log(JSON.stringify({downloaded:true,version,bytes:data.length}));
}
async function execute(script){
 const base='https://apis.roblox.com/cloud/v2/';
 let t=await api(base+target+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script})});
 for(let i=0;['QUEUED','PENDING','PROCESSING'].includes(t.state);i++){
  if(i>240)throw new Error('Execution timeout');await pause(1500);t=await api(base+t.path);
 }
 if(t.state!=='COMPLETE'||t.error)throw new Error(JSON.stringify(t.error||t));
 const v=t.output?.results?.[0];return typeof v==='string'?JSON.parse(v):v;
}

async function external(id){
 const j=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+id);
 const url=j.location||j.locations?.[0]?.location;if(!url)throw Error('Missing source '+id);
 const r=await fetch(url);if(!r.ok)throw Error('Source download '+r.status);
 await fs.writeFile('/tmp/asset-'+id+'.rbxl',Buffer.from(await r.arrayBuffer()));
}
const patch=process.argv[1].endsWith('asset-probe.mjs') && (await fs.readFile(new URL('./asset-probe.trigger',import.meta.url),'utf8')).includes('patch');
await download('/tmp/still-here-source.rbxl');
for(const id of ['76722373571113','186677844','5326950832'])await external(id);
const binary=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');
const zip=Buffer.from(await binary.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum');
await fs.writeFile('/tmp/forest-lune.zip',zip);execFileSync('unzip',['-o','/tmp/forest-lune.zip','-d','/tmp/forest-lune']);await fs.chmod('/tmp/forest-lune/lune',0o755);
const cwd=new URL('.',import.meta.url);
if(patch){
 const source=await fs.readFile(new URL('./forest-spawn-client.luau',import.meta.url),'utf8');
 const script="assert(workspace:GetAttribute('ForestExpansionReady')==true,'Expansion missing');local s=game:GetService('StarterPlayer').StarterPlayerScripts.ForestSpawnClient;s.Source="+JSON.stringify(source)+";game:GetService('AssetService'):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false});return game:GetService('HttpService'):JSONEncode({patched=true})";
 console.log(JSON.stringify(await execute(script)));await pause(5000);
}else{
execFileSync('/tmp/forest-lune/lune',['run','forest-expansion-file.luau'],{cwd,stdio:'inherit'});
const uploaded=await api('https://apis.roblox.com/universes/v1/9421311218/places/118064584465155/versions?versionType=Published',{method:'POST',type:'application/octet-stream',body:await fs.readFile('/tmp/still-here-expansion.rbxl')});
console.log(JSON.stringify({uploaded}));await pause(5000);
console.log(JSON.stringify({finalized:await execute(await fs.readFile(new URL('./forest-expansion-finalize.luau',import.meta.url),'utf8'))}));await pause(5000);
}
const verified=await execute(await fs.readFile(new URL('./forest-expansion-verify.luau',import.meta.url),'utf8'));console.log(JSON.stringify({verified}));
await download('/tmp/still-here-verified.rbxl',verified.version);
execFileSync('/tmp/forest-lune/lune',['run','native-grass-file-verify.luau'],{cwd,stdio:'inherit'});
execFileSync('/tmp/forest-lune/lune',['run','forest-expansion-file-verify.luau'],{cwd,stdio:'inherit'});
await api('https://apis.roblox.com/cloud/v2/universes/9421311218:restartServers',{method:'POST',body:'{}'});
export const expansionResult={published:true,verified,restarted:true};
console.log(JSON.stringify(expansionResult));
