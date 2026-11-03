// Import only actual interchange files at the pinned source revision. Never executes external project code.
import fs from 'node:fs/promises';
const ROOT='https://raw.githubusercontent.com/SpringChunSam/PoppyPlaytime/344abbe7eb26fcd6b3510858d749584f25f4cc67/';
const CLOUD='https://apis.roblox.com/';
const TARGET='universes/9421311218/places/118064584465155/';
const key=process.env.ROBLOX_API_KEY;
if(!key)throw new Error('Missing Roblox API key');
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function api(path,options={}){
 const response=await fetch(CLOUD+path,{...options,headers:{'x-api-key':key,...options.headers},signal:AbortSignal.timeout(180000)});
 const body=await response.text();let result;try{result=JSON.parse(body);}catch{result={message:body.slice(0,500)};}
 if(!response.ok)throw new Error(JSON.stringify({status:response.status,endpoint:path,result}));
 return result;
}
async function execute(script){
 let task=await api('cloud/v2/'+TARGET+'luau-execution-session-tasks',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({timeout:'90s',script})});
 for(let i=0;i<90&&['QUEUED','PENDING','PROCESSING'].includes(task.state);i++){await pause(1000);task=await api('cloud/v2/'+task.path);}
 if(task.state!=='COMPLETE'||task.error)throw new Error(JSON.stringify(task.error||task));
 const result=task.output.results[0];return typeof result==='string'?JSON.parse(result):result;
}
const creator=await execute('assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target"); return game:GetService("HttpService"):JSONEncode({id=game.CreatorId,type=game.CreatorType.Name,version=game.PlaceVersion})');
const report={stage:'spring-interchange-import',sourceCommit:'344abbe7eb26fcd6b3510858d749584f25f4cc67',creator,assets:[],published:false};
const items=[{path:'Content/Project/KHH/source/Delight.fbx',name:'Dead Signal - Source Miss Delight',type:'Model',mime:'model/fbx'},...['img2.png','img3.png','img5.png','imge4.png','start_UI.png'].map(name=>({path:'Content/Project/KHH/start_UI/imge/'+name,name:'Dead Signal - Source UI '+name,type:'Decal',mime:'image/png'}))];
for(const item of items){
 try{
  const response=await fetch(ROOT+item.path);if(!response.ok)throw new Error('Source download HTTP '+response.status);
  const bytes=await response.arrayBuffer();
  const form=new FormData();form.set('request',JSON.stringify({assetType:item.type,displayName:item.name,description:'User-requested import from SpringChunSam/PoppyPlaytime, source revision '+report.sourceCommit,creationContext:{creator:{[creator.type==='Group'?'groupId':'userId']:String(creator.id)}}}));
  form.set('fileContent',new Blob([bytes],{type:item.mime}),item.path.split('/').pop());
  let operation=await api('assets/v1/assets',{method:'POST',body:form});
  for(let i=0;i<120&&!operation.done;i++){await pause(1500);operation=await api('assets/v1/'+operation.path);}
  if(operation.error||!operation.done)throw new Error(JSON.stringify(operation.error||operation));
  report.assets.push({source:item.path,assetId:operation.response?.assetId,result:operation.response});
 }catch(error){report.error=String(error.message);break;}
}
if(report.assets[0]?.assetId){
 const assetId=Number(report.assets[0].assetId);
 report.modelInspection=await execute('local m=game:GetService("AssetService"):LoadAssetAsync('+assetId+'); local r={parts=0,bones=0,joints=0,animations={}}; for _,d in ipairs(m:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() elseif d:IsA("BasePart") then r.parts+=1 elseif d:IsA("Bone") then r.bones+=1 elseif d:IsA("Motor6D") then r.joints+=1 elseif d:IsA("Animation") then table.insert(r.animations,{name=d.Name,id=d.AnimationId}) end end; m:Destroy(); return game:GetService("HttpService"):JSONEncode(r)');
}
await fs.writeFile(new URL('./import-result.json',import.meta.url),JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
