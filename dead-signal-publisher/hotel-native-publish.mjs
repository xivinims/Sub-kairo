import fs from 'node:fs/promises';
import {prepareHotel,run} from './hotel-build.mjs';
const universe=9421311218,place=118064584465155;
const target=`universes/${universe}/places/${place}/`;
const cloud='https://apis.roblox.com/cloud/v2/';
const wait=ms=>new Promise(resolve=>setTimeout(resolve,ms));
const read=name=>fs.readFile(new URL('./'+name,import.meta.url),'utf8');
async function api(url,{method='GET',body,type='application/json'}={}){
 const key=process.env.ROBLOX_API_KEY;if(!key)throw Error('Missing ROBLOX_API_KEY');
 const response=await fetch(url,{method,headers:{'x-api-key':key,'content-type':type},body,signal:AbortSignal.timeout(240000)});
 const raw=await response.text();let data;try{data=JSON.parse(raw)}catch{data={raw:raw.slice(0,1000)}}
 if(!response.ok)throw Error('Roblox HTTP '+response.status+': '+JSON.stringify(data));
 return data;
}
async function execute(script,version,binaryInput){
 let task=await api(cloud+target+(version?'versions/'+version+'/':'')+'luau-execution-session-tasks',{method:'POST',body:JSON.stringify({timeout:'300s',script,binaryInput})});
 const deadline=Date.now()+420000;
 while(['QUEUED','PENDING','PROCESSING'].includes(task.state)){
  if(Date.now()>deadline)throw Error('Hotel verification timed out');
  await wait(1500);task=await api(cloud+task.path);
 }
 if(task.state!=='COMPLETE'||task.error)throw Error(JSON.stringify(task.error||task));
 const value=task.output?.results?.[0];return typeof value==='string'?JSON.parse(value):value;
}
async function binaryInput(bytes){
 const upload=await api(cloud+`universes/${universe}/luau-execution-session-task-binary-inputs`,{method:'POST',body:JSON.stringify({size:bytes.length})});
 const response=await fetch(upload.uploadUri,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:bytes});
 if(!response.ok)throw Error('Hotel verification upload HTTP '+response.status);
 return upload.path;
}
async function download(file,version){
 const meta=await api('https://apis.roblox.com/asset-delivery-api/v1/assetId/'+place+(version?'/version/'+version:''));
 const location=meta.location||meta.locations?.[0]?.location;
 if(!location)throw Error('Place download URL missing');
 const response=await fetch(location,{signal:AbortSignal.timeout(180000)});
 if(!response.ok)throw Error('Place download HTTP '+response.status);
 const bytes=Buffer.from(await response.arrayBuffer());
 if(bytes.length<10000)throw Error('Place download was unexpectedly empty');
 await fs.writeFile(file,bytes);
}
async function publish(bytes){
 return api(`https://apis.roblox.com/universes/v1/${universe}/places/${place}/versions?versionType=Published`,{method:'POST',type:'application/octet-stream',body:bytes});
}
async function restart(){await api(cloud+`universes/${universe}:restartServers`,{method:'POST',body:'{}'});}
async function preflightScript(verify){
 return `assert(game.GameId==${universe} and game.PlaceId==${place},'Wrong target')
local b=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
for _,name in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting','MaterialService'}) do
 local service=game:GetService(name)
 for _,child in ipairs(service:GetChildren()) do child:Destroy() end
 for _,child in ipairs(b[name]:GetChildren()) do child.Parent=service end
end
for _,name in ipairs({'StarterPlayerScripts','StarterCharacterScripts'}) do
 for _,child in ipairs(game:GetService('StarterPlayer')[name]:GetChildren()) do child:Destroy() end
end
for _,child in ipairs(workspace:GetChildren()) do if not child:IsA('Terrain') and not child:IsA('Camera') then child:Destroy() end end
workspace.Terrain:Clear()
for name in pairs(workspace:GetAttributes()) do workspace:SetAttribute(name,nil) end
for name,value in pairs(b:GetAttributes()) do workspace:SetAttribute(name,value) end
game:GetService('StarterPlayer').CameraMode=Enum.CameraMode.Classic
game:GetService('StarterPlayer').CameraMinZoomDistance=8
game:GetService('StarterPlayer').CameraMaxZoomDistance=18
${await read('hotel-initialize.luau')}
task.wait(.25)
${verify}`;
}
export async function runHotelRelease({publish:shouldPublish=false}={}){
 await prepareHotel();run('hotel-assemble.luau');
 await fs.copyFile('/tmp/still-here-hotel.rbxl','/tmp/still-here-hotel-verified.rbxl');
 run('hotel-file-verify.luau');
 const verify=await read('hotel-verify.luau');
 const input=await binaryInput(await fs.readFile('/tmp/hotel-payload.rbxm'));
 const state=JSON.parse(await read('release-state.json'));
 const checked=await execute(await preflightScript(verify),state.preflightVersion,input);
 if(!checked?.ok)throw Error('Hotel native preflight did not confirm success');
 console.log('HOTEL_PREFLIGHT '+JSON.stringify(checked));
 if(!shouldPublish){console.log('HOTEL_PREVIEW_COMPLETE '+JSON.stringify({published:false,verified:true}));return;}
 await download('/tmp/still-here-hotel-rollback.rbxl');
 let candidate;
 try{
  candidate=await publish(await fs.readFile('/tmp/still-here-hotel.rbxl'));
  if(!candidate.versionNumber)throw Error('Published version missing');
  console.log('HOTEL_PUBLISHED '+JSON.stringify(candidate));
  const result=await execute(await read('hotel-initialize.luau')+'\ntask.wait(.25)\n'+verify,candidate.versionNumber);
  if(!result?.ok||result.version!==candidate.versionNumber)throw Error('Published hotel verification mismatch');
  await download('/tmp/still-here-hotel-verified.rbxl',candidate.versionNumber);run('hotel-file-verify.luau');
  await restart();
  console.log('HOTEL_RELEASE_COMPLETE '+JSON.stringify({...result,restarted:true}));
 }catch(error){
  if(candidate){
   const recovery=await publish(await fs.readFile('/tmp/still-here-hotel-rollback.rbxl'));
   await restart();console.error('HOTEL_ROLLBACK '+JSON.stringify(recovery));
  }
  throw error;
 }
}
