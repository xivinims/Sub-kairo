import fs from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw new Error('Missing ROBLOX_API_KEY');
const target='universes/9421311218/places/118064584465155/';
const chapterTwoTarget='universes/9421505041/places/87600271104551/';
const chapterOneUniverseId=9421311218;const chapterOnePlaceId=118064584465155;
const chapterTwoUniverseId=9421505041;const chapterTwoPlaceId=87600271104551;
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function api(url,{method='GET',body,type='application/json'}={}){
 const r=await fetch(url,{method,headers:{'x-api-key':key,'content-type':type},body,signal:AbortSignal.timeout(240000)});
 const raw=await r.text();let j;try{j=JSON.parse(raw)}catch{j={raw}};
 if(!r.ok)throw new Error('HTTP '+r.status+': '+JSON.stringify(j).slice(0,900));return j;
}
async function download(file,version,placeId=chapterOnePlaceId){
 const suffix=version?'/version/'+version:'';
 const j=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+placeId+suffix);
 const location=j.location||j.locations?.[0]?.location;
 if(!location)throw new Error('Asset download location missing');
 const r=await fetch(location);if(!r.ok)throw new Error('File download HTTP '+r.status);
 const data=Buffer.from(await r.arrayBuffer());if(data.length<10000)throw new Error('Unexpected empty place');
 await fs.writeFile(file,data);console.log(JSON.stringify({downloaded:true,version,bytes:data.length}));
}
async function execute(script,version,binaryInput,executionTarget=target){
 const base='https://apis.roblox.com/cloud/v2/';
 let t=await api(base+executionTarget+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput})});
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

await download('/tmp/still-here-rollback.rbxl',undefined,chapterOnePlaceId);
await download('/tmp/still-here-chapter-two-rollback.rbxl',undefined,chapterTwoPlaceId);
for(const id of ['7902470429','7208091524','186677844','15864801103'])await external(id);
const binary=await fetch('https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip');
const zip=Buffer.from(await binary.arrayBuffer());if(createHash('sha256').update(zip).digest('hex')!=='39859282ce677fce19e6eb45c37596a90a25c324c95b4e7e02d428b6cae294a1')throw Error('Lune checksum');
await fs.writeFile('/tmp/islands-lune.zip',zip);execFileSync('unzip',['-o','/tmp/islands-lune.zip','-d','/tmp/islands-lune']);await fs.chmod('/tmp/islands-lune/lune',0o755);
const chapterTwoArtId=process.env.CHAPTER_TWO_ART_ASSET_ID||'88050012978358';
console.log(JSON.stringify({chapterTwoArtworkReused:true,assetId:chapterTwoArtId}));
const cwd=new URL('.',import.meta.url);execFileSync('/tmp/islands-lune/lune',['run','original-assemble.luau'],{cwd,stdio:'inherit'});
execFileSync('/tmp/islands-lune/lune',['run','chapter-two-place.luau'],{cwd,stdio:'inherit'});

execFileSync('/tmp/islands-lune/lune',['run','original-gameplay-test.luau'],{cwd,stdio:'inherit'});
execFileSync('/tmp/islands-lune/lune',['run','settings-test.luau'],{cwd,stdio:'inherit'});
execFileSync('/tmp/islands-lune/lune',['run','door-lock-test.luau'],{cwd,stdio:'inherit'});
execFileSync('/tmp/islands-lune/lune',['run','menu-layout-test.luau'],{cwd,stdio:'inherit'});
execFileSync('/tmp/islands-lune/lune',['run','cinematic-audio-lighting-test.luau'],{cwd,stdio:'inherit'});
execFileSync('/tmp/islands-lune/lune',['run','blackhole-layout-test.luau'],{cwd,stdio:'inherit'});
execFileSync('/tmp/islands-lune/lune',['run','original-weapon-test.luau'],{cwd,stdio:'inherit'});
await fs.copyFile('/tmp/still-here-original.rbxl','/tmp/still-here-verified.rbxl');
execFileSync('/tmp/islands-lune/lune',['run','original-file-verify.luau'],{cwd,stdio:'inherit'});
const payload=await fs.readFile('/tmp/original-payload.rbxm');
async function binaryInput(universeId,bytes){
 const input=await api('https://apis.roblox.com/cloud/v2/universes/'+universeId+'/luau-execution-session-task-binary-inputs',{method:'POST',body:JSON.stringify({size:bytes.length})});
 const upload=await fetch(input.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bytes});
 if(!upload.ok)throw Error('Binary upload '+upload.status);
 return input.path;
}
const mainBinaryInput=await binaryInput(chapterOneUniverseId,payload);
const chapterTwoBinaryInput=await binaryInput(chapterTwoUniverseId,payload);
const init=await fs.readFile(new URL('./original-initialize.luau',import.meta.url),'utf8');
const weaponPick=await fs.readFile(new URL('./original-weapon-pickups.luau',import.meta.url),'utf8');
const mainVerify=await fs.readFile(new URL('./original-verify.luau',import.meta.url),'utf8');
const chapterTwoVerify=await fs.readFile(new URL('./chapter-two-verify.luau',import.meta.url),'utf8');
function preflight(gameId,placeId,experienceChapter,verify){
 return `assert(game.GameId==${gameId} and game.PlaceId==${placeId},'Wrong target')
local b=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
for _,service in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting'}) do
 local target=game:GetService(service);for _,c in ipairs(target:GetChildren()) do c:Destroy() end;for _,c in ipairs(b[service]:GetChildren()) do c.Parent=target end
end
for _,name in ipairs({'StarterPlayerScripts','StarterCharacterScripts'}) do local target=game:GetService('StarterPlayer')[name];for _,c in ipairs(target:GetChildren()) do c:Destroy() end;for _,c in ipairs(b[name]:GetChildren()) do c.Parent=target end end
for _,c in ipairs(workspace:GetChildren()) do if not c:IsA('Terrain') and not c:IsA('Camera') then c:Destroy() end end
for key in pairs(workspace:GetAttributes()) do workspace:SetAttribute(key,nil) end;for key,value in pairs(b:GetAttributes()) do workspace:SetAttribute(key,value) end
workspace:SetAttribute('ExperienceChapter',${experienceChapter})
workspace:SetAttribute('OriginalPreflight',true)
${init}
${verify}`
}
console.log(JSON.stringify({originalPreflight:await execute(preflight(chapterOneUniverseId,chapterOnePlaceId,1,'do\n'+weaponPick+'\nend\n'+mainVerify),releaseState.preflightVersion,mainBinaryInput)}));
console.log(JSON.stringify({chapterTwoPreflight:await execute(preflight(chapterTwoUniverseId,chapterTwoPlaceId,2,chapterTwoVerify),undefined,chapterTwoBinaryInput,chapterTwoTarget)}));
const chapterOneCandidate=await fs.readFile('/tmp/still-here-original.rbxl');
const chapterTwoCandidate=await fs.readFile('/tmp/still-here-chapter-two.rbxl');
let chapterOnePublished,chapterTwoPublished;
async function publish(universeId,placeId,bytes){
 return await api('https://apis.roblox.com/universes/v1/'+universeId+'/places/'+placeId+'/versions?versionType=Published',{
  method:'POST',type:'application/octet-stream',body:bytes
 });
}
async function restore(universeId,placeId,bytes){
 return await publish(universeId,placeId,bytes);
}
async function restart(universeId){
 await api('https://apis.roblox.com/cloud/v2/universes/'+universeId+':restartServers',{method:'POST',body:'{}'});
}

try{
 chapterTwoPublished=await publish(chapterTwoUniverseId,chapterTwoPlaceId,chapterTwoCandidate);
 console.log(JSON.stringify({chapterTwoPublishedCandidate:chapterTwoPublished}));
 const chapterTwoLive=await execute("workspace:SetAttribute('OriginalPreflight',true)\n"+init+'\n'+chapterTwoVerify,chapterTwoPublished.versionNumber,chapterTwoBinaryInput,chapterTwoTarget);
 console.log(JSON.stringify({chapterTwoLiveVerified:chapterTwoLive}));
 await download('/tmp/still-here-chapter-two-verified.rbxl',chapterTwoLive.version,chapterTwoPlaceId);
 execFileSync('/tmp/islands-lune/lune',['run','chapter-two-file-verify.luau'],{cwd,stdio:'inherit'});
 chapterOnePublished=await publish(chapterOneUniverseId,chapterOnePlaceId,chapterOneCandidate);
 console.log(JSON.stringify({chapterOnePublishedCandidate:chapterOnePublished}));
 const mainLive=await execute("workspace:SetAttribute('OriginalPreflight',true)\n"+init+'\ndo\n'+weaponPick+'\nend\n'+mainVerify,chapterOnePublished.versionNumber,mainBinaryInput);
 console.log(JSON.stringify({chapterOneLiveVerified:mainLive}));
 await download('/tmp/still-here-verified.rbxl',mainLive.version,chapterOnePlaceId);
 execFileSync('/tmp/islands-lune/lune',['run','original-file-verify.luau'],{cwd,stdio:'inherit'});
 await restart(chapterTwoUniverseId);await restart(chapterOneUniverseId);
 console.log(JSON.stringify({published:true,chapterOne:mainLive,chapterTwo:chapterTwoLive,restarted:true}));
}catch(error){
 const recovery=[];
 if(chapterOnePublished)try{recovery.push({chapterOneRestored:await restore(chapterOneUniverseId,chapterOnePlaceId,await fs.readFile('/tmp/still-here-rollback.rbxl'))})}catch(restoreError){recovery.push({chapterOneRestoreError:String(restoreError)})}
 if(chapterTwoPublished)try{recovery.push({chapterTwoRestored:await restore(chapterTwoUniverseId,chapterTwoPlaceId,await fs.readFile('/tmp/still-here-chapter-two-rollback.rbxl'))})}catch(restoreError){recovery.push({chapterTwoRestoreError:String(restoreError)})}
 if(chapterOnePublished||chapterTwoPublished){
  for(const universeId of [chapterTwoUniverseId,chapterOneUniverseId])try{await restart(universeId)}catch(restartError){recovery.push({restartError:String(restartError),universeId})}
 }
 if(recovery.length)console.error(JSON.stringify({recovery}));
 throw error;
}
