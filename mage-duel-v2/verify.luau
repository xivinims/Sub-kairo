local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local StarterPack=game:GetService("StarterPack")
local StarterGui=game:GetService("StarterGui")
local ServerScriptService=game:GetService("ServerScriptService")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(Workspace:GetAttribute("BuildVersion")=="mage-duel-v2","V2 build missing")
assert(Workspace:GetAttribute("RequestedAssetsExact")==true,"Exact asset flag missing")
assert(Workspace:GetAttribute("LoadingScreenRemoved")==true,"Loading screen removal flag missing")
assert(Workspace:GetAttribute("BossReactiveOnly")==true,"Boss must be reactive only")
assert(Workspace:GetAttribute("StandardRobloxJump")==true,"Jump must use Roblox default controls")
assert(#ReplicatedFirst:GetChildren()==0,"ReplicatedFirst must be empty: loading screen still exists")
assert(#StarterGui:GetChildren()==0,"StarterGui should not contain old UI")

local world=assert(Workspace:FindFirstChild("MageDuelWorld"),"MageDuelWorld missing")
assert(world:FindFirstChild("CleanFloor"),"Clean floor missing")
local boss=assert(world:FindFirstChild("AstraVeyra"),"Exact NPC boss missing")
local hum=assert(boss:FindFirstChildOfClass("Humanoid"),"Boss Humanoid missing")
assert(tostring(hum.RigType)=="Enum.HumanoidRigType.R6","Requested NPC asset should remain R6")
assert(hum.MaxHealth==2600,"Boss health mismatch")
assert(boss:GetAttribute("SourceAssetId")==106281505667193,"Wrong NPC asset")
assert(boss:GetAttribute("BossVersion")=="mage-duel-v2","Boss version mismatch")
assert(boss:GetAttribute("Active")==false,"Boss must start dormant")

local staff=assert(boss:FindFirstChild("FrierenStaff",true),"Exact NPC staff missing")
assert(staff:GetAttribute("SourceAssetId")==84222065610676,"Wrong NPC staff asset")
assert(boss:FindFirstChild("StaffTip",true),"Boss staff tip missing")
assert(boss:FindFirstChild("BossRobeFront",true) and boss:FindFirstChild("BossCapeBack",true),"Boss visual enhancement missing")

local tool=assert(StarterPack:FindFirstChild("AstralStaff"),"Exact player staff missing")
assert(tool:GetAttribute("SourceAssetId")==3832698706,"Wrong player staff asset")
local client=assert(tool:FindFirstChild("MageDuelClient"),"V2 staff client missing")
local csrc=client.Source
for _,token in ipairs({"Zoltraak","Barreira","Judradjim","Singularidade","Vida","Esquiva","Voo","SpellRail"})do
 assert(string.find(csrc,token,1,true),"Side spell UI missing "..token)
end
for _,ability in ipairs({"Attack","Barrier","Storm","Singularity","Heal","Dodge","Fly"})do
 assert(string.find(csrc,ability,1,true),"Client ability missing "..ability)
end
assert(not string.find(csrc,'"Pulo"',1,true),"Custom Pulo button must be removed")
assert(not string.find(csrc,'Enum.KeyCode.F then fire("Jump")',1,true),"Custom F jump binding must be removed")
assert(not string.find(csrc,'if not equipped or not ready(name) then return end',1,true),"Spell fire still blocked by equipped state")
assert(not string.find(csrc,'if gp or not equipped then return end',1,true),"Keyboard spells still blocked by equipped state")
assert(string.find(csrc,'ensureStaffEquipped()',1,true),"Auto-equip before casting missing")
assert(string.find(csrc,'player:GetMouse()',1,true),"Robust live aim missing")


local templates=assert(ReplicatedStorage:FindFirstChild("MageAssetTemplates"),"MageAssetTemplates missing")
local circles=assert(templates:FindFirstChild("MagicCircles"),"Magic circle bank missing")
local primary=assert(circles:FindFirstChild("PrimaryMagicCircle"),"Primary exact circle missing")
assert(primary:GetAttribute("SourceAssetId")==115275786272862,"Wrong primary circle asset")
local bank=assert(circles:FindFirstChild("RuneCircleCollection"),"Requested magic-circle collection missing")
assert(bank:GetAttribute("SourceAssetId")==9132974153,"Wrong magic-circle collection")
local black=assert(templates:FindFirstChild("BlackFlash"),"Black Flash VFX missing")
assert(black:GetAttribute("SourceAssetId")==102185762902096,"Wrong Black Flash VFX")
local gravity=assert(templates:FindFirstChild("GravityField"),"Gravity VFX missing")
assert(gravity:GetAttribute("SourceAssetId")==126521784338665,"Wrong Gravity VFX")

for _,root in ipairs({templates,boss,tool})do
 for _,d in ipairs(root:GetDescendants())do
  if d:IsA("LuaSourceContainer")then
   local allowed=(d==client)
   assert(allowed,"Legacy/embedded asset script survived: "..d:GetFullName())
  elseif d:IsA("RemoteEvent")or d:IsA("RemoteFunction")then
   error("Legacy asset remote survived: "..d:GetFullName())
  end
 end
end

local server=assert(ServerScriptService:FindFirstChild("MageDuelServer"),"MageDuelServer missing")
local src=server.Source
for _,token in ipairs({
 "LayeredHexBarrier","BarrierShards","ManaDust","PiercingBeam","GeometricLightning","SpatialCollapse",
 "BlackFlash","GravityField","smartMagicCircle","bossBarrier","bossStorm","bossSingularity","bossHeal","bossDodge",
 'ability=="Storm"','ability=="Singularity"',"bossShield.layers=3"
})do
 assert(string.find(src,token,1,true),"V2 magic runtime missing "..token)
end
assert(string.find(src,"local active=false",1,true),"Boss must start inactive")
assert(string.find(src,"active=true;target=plr",1,true),"Attack activation missing")

return {
 ok=true,placeVersion=game.PlaceVersion,build="mage-duel-v2",
 npcAsset=boss:GetAttribute("SourceAssetId"),
 npcStaffAsset=staff:GetAttribute("SourceAssetId"),
 playerStaffAsset=tool:GetAttribute("SourceAssetId"),
 primaryCircle=primary:GetAttribute("SourceAssetId"),
 circleCollection=bank:GetAttribute("SourceAssetId"),
 blackVFX=black:GetAttribute("SourceAssetId"),
 gravityVFX=gravity:GetAttribute("SourceAssetId"),
 loadingRemoved=#ReplicatedFirst:GetChildren()==0,
 bossRig=tostring(hum.RigType),bossHealth=hum.MaxHealth,
}
