import fs from 'node:fs';
import {execute,first} from '../treeworld-v12/cloud.mjs';
const read=name=>fs.readFileSync(`treeworld-v13/${name}.luau`,'utf8');
const quote=text=>{if(text.includes(']====]'))throw new Error('Source delimiter collision');return '[====['+text+']====]';};
const install=(parent,name,type,file)=>`install(${parent},${JSON.stringify(name)},${JSON.stringify(type)},${quote(read(file))})`;
const verify=read('verify');
const patch=`
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local sourceVersion=game.PlaceVersion
local runtime=assert(game.ReplicatedStorage:FindFirstChild('LivingForest'))
local sps=game.StarterPlayer.StarterPlayerScripts
local function install(parent,name,class,source)
 local old=parent:FindFirstChild(name);if old then old:Destroy() end
 local item=Instance.new(class);item.Name=name;item.Source=source;item:SetAttribute('Revision','voice-touch-v13');item.Parent=parent
end
${install('runtime','CaioVoicePlayer','ModuleScript','voice-player')}
${install('runtime','ForestInterface','ModuleScript','interface')}
${install('sps','CaioDialogueClient','LocalScript','dialogue-client')}
${install('sps','ForestInventoryClient','LocalScript','inventory-client')}
local legacy=game.StarterGui:FindFirstChild('Custom Inventory');if legacy then legacy:Destroy() end
workspace:SetAttribute('VoiceTouchRevision','voice-touch-v13')
local function verify()
${verify}
end
local checks=verify()
assert(checks.ok,'Validation failed before save')
game:GetService('AssetService'):SavePlaceAsync()
return {ok=true,sourceVersion=sourceVersion,checks=checks}
`;
const applied=first(await execute(patch));
if(!applied?.ok)throw new Error('Hotfix not applied');
console.log(JSON.stringify({stage:'validated-and-saved',...applied}));
let persisted,last;
for(let i=0;i<8;i++){
 if(i)await new Promise(r=>setTimeout(r,3500));
 try{
  persisted=first(await execute(verify));
  if(!persisted?.ok||persisted.placeVersion<=applied.sourceVersion)throw new Error('Saved version not visible');
  last=null;break;
 }catch(e){last=e;}
}
if(last)throw last;
console.log(JSON.stringify({stage:'verified-persisted',...persisted}));
const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:persisted.placeVersion,releaseId:'voice-touch-v13-'+persisted.placeVersion,kind:'game-update'});
const broadcast=first(await execute(`local ok,err=pcall(function()game:GetService('MessagingService'):PublishAsync('Overyard_Update_v1',${quote(payload)})end)return {ok=ok,error=ok and nil or tostring(err)}`));
console.log(JSON.stringify({stage:'update-migration',...broadcast}));
if(!broadcast?.ok)throw new Error('Server update broadcast failed');
