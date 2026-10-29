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
const verifyOnly=process.argv[1].endsWith('asset-probe.mjs') && (await fs.readFile(new URL('./asset-probe.trigger',import.meta.url),'utf8')).trim().startsWith('native-grass-verify');
if(!verifyOnly)await download('/tmp/still-here-source.rbxl');
const binary=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');
if(!binary.ok)throw new Error('Lune download failed');
const zip=Buffer.from(await binary.arrayBuffer());
if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw new Error('Lune checksum mismatch');
await fs.writeFile('/tmp/still-here-lune.zip',zip);
execFileSync('unzip',['-o','/tmp/still-here-lune.zip','-d','/tmp/still-here-lune'],{stdio:'inherit'});
await fs.chmod('/tmp/still-here-lune/lune',0o755);
const cwd=new URL('.',import.meta.url);
let finalized={verificationOnly:true};
if(!verifyOnly){
execFileSync('/tmp/still-here-lune/lune',['run','native-grass-file.luau'],{cwd,stdio:'inherit',env:{PATH:process.env.PATH}});
const data=await fs.readFile('/tmp/still-here-native.rbxl');
const uploaded=await api('https://apis.roblox.com/universes/v1/9421311218/places/118064584465155/versions?versionType=Published',{method:'POST',type:'application/octet-stream',body:data});
console.log(JSON.stringify({uploaded}));
await pause(5000);
finalized=await execute(await fs.readFile(new URL('./native-grass-finalize.luau',import.meta.url),'utf8'));
await pause(5000);
}
const verified=await execute(`local W=workspace;local map=W.OvergrownAtrium;local n=0;for _,m in ipairs(map.MeadowUnderstory:GetChildren()) do if m:GetAttribute('FoliageType')=='Grass' then n+=1 end end;assert(n==0,'Grass models remain');assert(game:GetService('ServerScriptService').AtriumRuntime.ForestWeatherServer.Enabled==true,'Weather server disabled');assert(type(W:GetAttribute('ForestWeather'))=='string','Weather cycle not running');assert(game:GetService('StarterPlayer').StarterPlayerScripts:FindFirstChild('ForestWindClient'),'Wind client missing');assert(game:GetService('StarterPlayer').StarterPlayerScripts:FindFirstChild('ForestWeatherClient'),'Rain client missing');assert(W:GetAttribute('ForestSurfaceMaterial')=='Grass','Terrain not converted');assert(W:GetAttribute('DeadSignalBuildId')=='still-here-light-weather-v8','Wrong build');return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,grassModels=n,trees=#map.Pines:GetChildren(),flowers=#map.MeadowUnderstory:GetChildren(),weather=W:GetAttribute('ForestWeather'),windAsset=W:GetAttribute('ForestWindAsset'),build=W:GetAttribute('DeadSignalBuildId')})`);
console.log(JSON.stringify({engineVerified:verified}));
await download('/tmp/still-here-verified.rbxl',verified.version);
execFileSync('/tmp/still-here-lune/lune',['run','native-grass-file-verify.luau'],{cwd,stdio:'inherit',env:{PATH:process.env.PATH}});
await api('https://apis.roblox.com/cloud/v2/universes/9421311218:restartServers',{method:'POST',body:'{}'});
export const nativeGrassResult={stage:'native-grass-published',finalized,verified,nativeGrass:true,grassLength:.85,streamingMin:64,streamingTarget:192,windAsset:11946229834,rain:true,restarted:true};
console.log(JSON.stringify(nativeGrassResult));
