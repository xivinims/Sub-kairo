import fs from 'node:fs';
import {execute,first} from './cloud.mjs';
const read=name=>fs.readFileSync(`treeworld-v12/${name}.luau`,'utf8');
const quote=text=>{if(text.includes(']====]'))throw new Error('Unsafe source delimiter');return '[====['+text+']====]';};
const install=(parent,name,type,file)=>`install(${parent},${JSON.stringify(name)},${JSON.stringify(type)},${quote(read(file))})`;
const setup=`
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local RS=game.ReplicatedStorage
local sps=game.StarterPlayer.StarterPlayerScripts
local server=game.ServerScriptService
local function install(parent,name,class,source)
 local old=parent:FindFirstChild(name);if old then old:Destroy()end
 local item=Instance.new(class);item.Name=name;item.Source=source;item.Parent=parent;return item
end
local old=RS:FindFirstChild('LivingForest');if old then old:Destroy()end
local runtime=Instance.new('Folder');runtime.Name='LivingForest';runtime.Parent=RS
for _,name in ipairs({'NatureEvent','SafetyEvent','ReportEvent'})do local e=Instance.new('RemoteEvent');e.Name=name;e.Parent=runtime end
${install('RS','PhotoWorldConfig','ModuleScript','world-config')}
${install('RS','LivingMeshMeta','ModuleScript','mesh-meta')}
${install('runtime','FruitRules','ModuleScript','fruit-rules')}
${install('runtime','DialogueData','ModuleScript','dialogue-data')}
${install('runtime','VoiceManifest','ModuleScript','voice-manifest')}
${install('runtime','Reflection','ModuleScript','reflection')}
${install('runtime','ReportClient','ModuleScript','report-client')}
local wind=Instance.new('Folder');wind.Name='WindEffects';wind.Parent=runtime
local shake=${install('wind','WindShake','ModuleScript','vendor/WindShake')}
${install('shake','Settings','ModuleScript','vendor/Settings')}
local octree=${install('shake','Octree','ModuleScript','vendor/Octree')}
${install('octree','OctreeNode','ModuleScript','vendor/OctreeNode')}
${install('octree','OctreeRegionUtils','ModuleScript','vendor/OctreeRegionUtils')}
${install('wind','WindLines','ModuleScript','vendor/WindLines')}
`;
const clients=`
game.StarterPlayer.CameraMode=Enum.CameraMode.Classic
game.StarterPlayer.CameraMinZoomDistance=.5
game.StarterPlayer.CameraMaxZoomDistance=24
game.StarterPlayer.DevComputerCameraMovementMode=Enum.DevComputerCameraMovementMode.UserChoice
game.StarterPlayer.DevTouchCameraMovementMode=Enum.DevTouchCameraMovementMode.UserChoice
${install('sps','OveryardCameraClient','LocalScript','camera-client')}
${install('sps','PhotoEnvironmentClient','LocalScript','environment-client')}
${install('sps','LivingNatureClient','LocalScript','nature-client')}
${install('sps','ForestInventoryClient','LocalScript','inventory-client')}
${install('sps','CaioDialogueClient','LocalScript','dialogue-client')}
${install('sps','ForestSafetyClient','LocalScript','safety-client')}
${install('server','MovementRules','ModuleScript','movement-rules')}
${install('server','MovementService','ModuleScript','movement-service')}
${install('server','LivingForestServer','Script','forest-server')}
${install('server','CaioReportServer','Script','report-server')}
`;
const verify=read('verify');
const script=`${setup}
local function build()
${read('build-world')}
end
local result=build()
local function models()
${read('install-models')}
end
local modelsResult=models()
${clients}
local function verify()
${verify}
end
local checks=verify()
assert(checks.ok,'Pre-save validation failed')
game:GetService('AssetService'):SavePlaceAsync()
return {ok=true,build=result,models=modelsResult,checks=checks}
`;
const applied=first(await execute(script));
if(!applied?.ok)throw new Error('Build did not return ok');
console.log(JSON.stringify({stage:'validated-and-saved',...applied}));
let persisted,last;
for(let i=0;i<8;i++){
 if(i)await new Promise(r=>setTimeout(r,3500));
 try{persisted=first(await execute(verify));if(!persisted?.ok||persisted.placeVersion<=applied.build.sourceVersion)throw new Error('Saved version not visible');last=null;break;}catch(e){last=e;}
}
if(last)throw last;
console.log(JSON.stringify({stage:'verified-persisted',...persisted}));
const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:persisted.placeVersion,releaseId:'living-forest-v12-'+persisted.placeVersion,kind:'game-update'});
const broadcast=first(await execute(`local ok,err=pcall(function()game:GetService('MessagingService'):PublishAsync('Overyard_Update_v1',${quote(payload)})end)return {ok=ok,error=ok and nil or tostring(err)}`));
console.log(JSON.stringify({stage:'update-migration',...broadcast}));
