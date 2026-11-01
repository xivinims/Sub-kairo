assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong experience')
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1','Wrong game')
local Players=game:GetService('Players')
local C=require(game.ReplicatedStorage.FalloutConfig)
local desc=Players:GetHumanoidDescriptionFromUserIdAsync(C.OwnerUserId)
local function describe(d)
 local result={properties={},colors={},accessories=d:GetAccessories(true)}
 for _,key in ipairs({'Shirt','Pants','GraphicTShirt','Face','Head','Torso','LeftArm','RightArm','LeftLeg','RightLeg','BodyTypeScale','DepthScale','HeadScale','HeightScale','ProportionScale','WidthScale','ClimbAnimation','FallAnimation','IdleAnimation','JumpAnimation','RunAnimation','SwimAnimation','WalkAnimation','MoodAnimation'}) do local ok,v=pcall(function()return d[key]end);if ok then result.properties[key]=v end end
 for _,key in ipairs({'HeadColor','TorsoColor','LeftArmColor','RightArmColor','LeftLegColor','RightLegColor'}) do local c=d[key];result.colors[key]={c.R,c.G,c.B} end
 for _,accessory in ipairs(result.accessories) do accessory.AccessoryType=accessory.AccessoryType.Name end
 return result
end
local old=workspace.Shopkeeper.Humanoid:GetAppliedDescription()
local result={version=game.PlaceVersion,userId=C.OwnerUserId,capturedAt=os.date('!%Y-%m-%dT%H:%M:%SZ'),current=describe(desc),npc=describe(old)}
desc:Destroy();old:Destroy()
return game:GetService('HttpService'):JSONEncode(result)
