import fs from 'node:fs';
import {execute,first} from '../treeworld-v12/cloud.mjs';
const read=name=>fs.readFileSync(`treeworld-v14/${name}.luau`,'utf8');
const quote=text=>{if(text.includes(']====]'))throw new Error('Source delimiter collision');return '[====['+text+']====]';};
const verify=read('verify');
const patch=`
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local sourceVersion=game.PlaceVersion
local function installNPC()
${read('install-npc')}
end
local build=installNPC()
local collision=game.ServerScriptService:FindFirstChild('CaioPlayerCollisions')
if collision then collision:Destroy() end
collision=Instance.new('Script');collision.Name='CaioPlayerCollisions';collision.Source=${quote(read('player-collisions'))};collision.Parent=game.ServerScriptService
local client=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild('CaioDialogueClient'))
client.Source=${quote(read('dialogue-client'))}
client:SetAttribute('Revision','slim-caio-v14')
local function verify()
${verify}
end
local checks=verify();assert(checks.ok)
game:GetService('AssetService'):SavePlaceAsync()
return {ok=true,sourceVersion=sourceVersion,build=build,checks=checks}
`;
const applied=first(await execute(patch));
if(!applied?.ok)throw new Error('NPC update not applied');
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
const payload=JSON.stringify({placeId:118064584465155,targetPlaceVersion:persisted.placeVersion,releaseId:'slim-caio-v14-'+persisted.placeVersion,kind:'game-update'});
const broadcast=first(await execute(`local ok,err=pcall(function()game:GetService('MessagingService'):PublishAsync('Overyard_Update_v1',${quote(payload)})end)return {ok=ok,error=ok and nil or tostring(err)}`));
console.log(JSON.stringify({stage:'update-migration',...broadcast}));
if(!broadcast?.ok)throw new Error('Server update broadcast failed');
