import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const dir=path.dirname(fileURLToPath(import.meta.url));
const key=process.env.ROBLOX_API_KEY;
const base='https://apis.roblox.com/';
const original=JSON.parse(await fs.readFile(path.join(dir,'import-result.json'),'utf8'));
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function api(url,options={}){
 const response=await fetch(base+url,{...options,headers:{'x-api-key':key,...options.headers},signal:AbortSignal.timeout(180000)});
 const text=await response.text();let result;try{result=JSON.parse(text);}catch{result={message:text.slice(0,500)}}
 if(!response.ok)throw new Error(JSON.stringify({status:response.status,endpoint:url,result}));return result;
}
async function execute(script){
 let task=await api('cloud/v2/universes/9421311218/places/118064584465155/luau-execution-session-tasks',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({timeout:'180s',script})});
 for(let i=0;i<200&&['QUEUED','PENDING','PROCESSING'].includes(task.state);i++){await pause(1000);task=await api('cloud/v2/'+task.path)}
 if(task.state!=='COMPLETE'||task.error)throw new Error(JSON.stringify(task.error||task));const value=task.output.results[0];return typeof value==='string'?JSON.parse(value):value;
}
const source=await fetch('https://raw.githubusercontent.com/SpringChunSam/PoppyPlaytime/344abbe7eb26fcd6b3510858d749584f25f4cc67/Content/Project/KHH/source/Delight.fbx');
if(!source.ok)throw new Error('Source FBX unavailable');
const sourceFile=path.join(dir,'source.fbx');await fs.writeFile(sourceFile,new Uint8Array(await source.arrayBuffer()));
if(spawnSync('python3',['-c','import numpy']).status!==0){const install=spawnSync('python3',['-m','pip','install','--quiet','numpy'],{encoding:'utf8'});if(install.status!==0)throw new Error('NumPy dependency unavailable');}
const exportRun=spawnSync('python3',[path.join(dir,'export_animations.py'),sourceFile,path.join(dir,'converted-rig.json'),path.join(dir,'animations')],{encoding:'utf8',env:{...process.env,OPENBLAS_NUM_THREADS:'1'}});
if(exportRun.status!==0)throw new Error(exportRun.stderr.slice(-1500));
const manifest=JSON.parse(await fs.readFile(path.join(dir,'animations/animation-manifest.json'),'utf8'));
const report={stage:'spring-animation-conversion',animations:[],published:false};
for(const clip of manifest){
 try{
  const bytes=await fs.readFile(path.join(dir,'animations',clip.file));const form=new FormData();
  form.set('request',JSON.stringify({assetType:'Animation',displayName:'Dead Signal - Source '+clip.name,description:'Converted source rotation animation; root motion excluded.',creationContext:{creator:{[original.creator.type==='Group'?'groupId':'userId']:String(original.creator.id)}}}));
  form.set('fileContent',new Blob([bytes],{type:'model/x-rbxm'}),clip.file);
  let op=await api('assets/v1/assets',{method:'POST',body:form});
  for(let i=0;i<120&&!op.done;i++){await pause(1200);op=await api('assets/v1/'+op.path)}
  if(op.error||!op.done)throw new Error(JSON.stringify(op.error||op));
  report.animations.push({...clip,assetId:op.response.assetId});
 }catch(error){report.error=String(error.message);break;}
}
console.log(JSON.stringify({stage:'converted-animation-assets',animations:report.animations,error:report.error}));
// Stage converted resources in ServerStorage, never replace the live map with missing Unreal geometry.
const modelId=Number(original.assets[0].assetId);
const clips=report.animations.map(x=>'['+JSON.stringify(x.name)+']='+Number(x.assetId)).join(',');
const images=original.assets.slice(1).map((x,i)=>'{name='+JSON.stringify(x.source.split('/').pop())+',id='+Number(x.assetId)+'}').join(',');
const install=`
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local SS=game:GetService("ServerStorage");local AS=game:GetService("AssetService");local Http=game:GetService("HttpService")
local folder=Instance.new("Folder");folder.Name="SpringSourceConverted"
folder:SetAttribute("BuildId","dead-signal-source-port-assets-v1");folder:SetAttribute("MissingTextures",true);folder:SetAttribute("GamePortComplete",false)
local model=AS:LoadAssetAsync(${modelId});model.Name="MissDelightSource"
for _,d in ipairs(model:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanTouch=false end end
local _,size=model:GetBoundingBox();model:ScaleTo(model:GetScale()*9/size.Y);model.Parent=folder
local animations=Instance.new("Folder");animations.Name="SourceAnimations";animations.Parent=folder
local clips={${clips}};local frameCounts={}
for name,id in pairs(clips) do
 local ok,sequence=pcall(function()return game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync("rbxassetid://"..id)end)
 assert(ok,"Converted animation not readable: "..name)
 frameCounts[name]=#sequence:GetKeyframes();assert(frameCounts[name]>=2,"Animation missing frames");sequence:Destroy()
 local animation=Instance.new("Animation");animation.Name=name;animation.AnimationId="rbxassetid://"..id;animation.Parent=animations
end
local images=Instance.new("Folder");images.Name="SourceMenuImages";images.Parent=folder
for _,image in ipairs({${images}}) do local item=Instance.new("StringValue");item.Name=image.name;item.Value="rbxassetid://"..image.id;item.Parent=images end
local bones=0;for _,d in ipairs(model:GetDescendants()) do if d:IsA("Bone") then bones+=1 end end;assert(bones==124,"Converted rig incomplete")
local old=SS:FindFirstChild(folder.Name);if old then old:Destroy() end;folder.Parent=SS
workspace:SetAttribute("SourceConversionBuildId","dead-signal-source-port-assets-v1")
AS:SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return Http:JSONEncode({ok=true,published=true,bones=bones,animations=frameCounts,build=folder:GetAttribute("BuildId")})
`;
try{
 report.install=await execute(install);
 report.verified=await execute('local f=game:GetService("ServerStorage"):FindFirstChild("SpringSourceConverted");assert(f,"Converted resources missing");return game:GetService("HttpService"):JSONEncode({version=game.PlaceVersion,build=f:GetAttribute("BuildId"),model=f:FindFirstChild("MissDelightSource")~=nil,animations=#f.SourceAnimations:GetChildren(),menuImages=#f.SourceMenuImages:GetChildren(),gamePortComplete=f:GetAttribute("GamePortComplete"),missingTextures=f:GetAttribute("MissingTextures")})');
 report.published=true;
}catch(error){report.installError=String(error.message);}
await fs.writeFile(path.join(dir,'animation-import-result.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
