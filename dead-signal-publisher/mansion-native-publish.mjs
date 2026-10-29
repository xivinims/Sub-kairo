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
async function execute(script,version,binaryInput){
 const base='https://apis.roblox.com/cloud/v2/';
 let t=await api(base+target+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput})});
 for(let i=0;['QUEUED','PENDING','PROCESSING'].includes(t.state);i++){
  if(i>240){let logs;try{logs=await api(base+t.path+'/logs?view=FLAT')}catch(e){logs=String(e)}throw new Error('Execution timeout '+JSON.stringify({state:t.state,path:t.path,logs}));}await pause(1500);t=await api(base+t.path);
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

const releaseState=JSON.parse(await fs.readFile(new URL('./release-state.json',import.meta.url),'utf8'));
await download('/tmp/still-here-source.rbxl',177);
await download('/tmp/still-here-rollback.rbxl',releaseState.rollbackVersion);
for(const id of ['7902470429','13037825880','7208091524','186677844','15864801103','14817965191'])await external(id);
const binary=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');
const zip=Buffer.from(await binary.arrayBuffer());if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum');
await fs.writeFile('/tmp/islands-lune.zip',zip);execFileSync('unzip',['-o','/tmp/islands-lune.zip','-d','/tmp/islands-lune']);await fs.chmod('/tmp/islands-lune/lune',0o755);
const cwd=new URL('.',import.meta.url);execFileSync('/tmp/islands-lune/lune',['run','mansion-assemble.luau'],{cwd,stdio:'inherit'});
const payload=await fs.readFile('/tmp/mansion-payload.rbxm');
const input=await api('https://apis.roblox.com/cloud/v2/universes/9421311218/luau-execution-session-task-binary-inputs',{method:'POST',body:JSON.stringify({size:payload.length})});
const upload=await fetch(input.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:payload});if(!upload.ok)throw Error('Binary upload '+upload.status);
const init=await fs.readFile(new URL('./mansion-initialize.luau',import.meta.url),'utf8');const verify=await fs.readFile(new URL('./mansion-verify.luau',import.meta.url),'utf8');
const preflight=`assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local bundle=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
local W=workspace
for _,name in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService'}) do for _,c in ipairs(game:GetService(name):GetChildren()) do c:Destroy() end end
for _,c in ipairs(game:GetService('StarterPlayer').StarterPlayerScripts:GetChildren()) do c:Destroy() end
for _,c in ipairs(W:GetChildren()) do if not c:IsA('Terrain') and not c:IsA('Camera') then c:Destroy() end end
for key in pairs(W:GetAttributes()) do W:SetAttribute(key,nil) end;for key,value in pairs(bundle:GetAttributes()) do W:SetAttribute(key,value) end
W:SetAttribute('GameMode','Match');bundle.Islands.Parent=W;bundle.IslandDestinations.Parent=W
for _,name in ipairs({'MansionCatalog','MansionTerrain','OrderlyTree'}) do bundle[name].Parent=game:GetService('ServerStorage') end
local runtime=bundle.Runtime;runtime.Name='AtriumRuntime';runtime.Parent=game:GetService('ServerScriptService');runtime.MansionInitializer:Destroy()
for _,c in ipairs(bundle.ReplicatedAssets:GetChildren()) do c.Parent=game:GetService('ReplicatedStorage') end
for _,c in ipairs(bundle.Clients:GetChildren()) do c.Parent=game:GetService('StarterPlayer').StarterPlayerScripts end
for _,c in ipairs(bundle.Early:GetChildren()) do c.Parent=game:GetService('ReplicatedFirst') end
${init}
${verify}`;
console.log(JSON.stringify({mansionPreflight:await execute(preflight,releaseState.preflightVersion,input.path)}));
let published;
try{
 published=await api('https://apis.roblox.com/universes/v1/9421311218/places/118064584465155/versions?versionType=Published',{method:'POST',type:'application/octet-stream',body:await fs.readFile('/tmp/still-here-mansion.rbxl')});console.log(JSON.stringify({publishedCandidate:published}));
 const setup=`workspace:SetAttribute('GameMode','Match');local SS=game:GetService('ServerStorage');if SS:FindFirstChild('MatchWorld') then for _,c in ipairs(SS.MatchWorld:GetChildren()) do c.Parent=workspace end end
`;
 const verified=await execute(setup+init+'\n'+verify,published.versionNumber);console.log(JSON.stringify({liveVerified:verified}));
 await download('/tmp/still-here-verified.rbxl',verified.version);execFileSync('/tmp/islands-lune/lune',['run','mansion-file-verify.luau'],{cwd,stdio:'inherit'});
 await api('https://apis.roblox.com/cloud/v2/universes/9421311218:restartServers',{method:'POST',body:'{}'});console.log(JSON.stringify({published:true,verified,restarted:true}));
}catch(error){if(published){const restored=await api('https://apis.roblox.com/universes/v1/9421311218/places/118064584465155/versions?versionType=Published',{method:'POST',type:'application/octet-stream',body:await fs.readFile('/tmp/still-here-rollback.rbxl')});console.log(JSON.stringify({restoredKnownGood:restored}));await api('https://apis.roblox.com/cloud/v2/universes/9421311218:restartServers',{method:'POST',body:'{}'});}throw error;}
