local StarterPack=game:GetService("StarterPack")
local ServerScriptService=game:GetService("ServerScriptService")
local world=workspace:FindFirstChild("MageDuelWorld")
local boss=world and world:FindFirstChild("AstraVeyra")
local hum=boss and boss:FindFirstChildOfClass("Humanoid")
local motors=0
if boss then for _,d in ipairs(boss:GetDescendants())do if d:IsA("Motor6D")then motors+=1 end end end
local server=ServerScriptService:FindFirstChild("MageDuelServer")
return {
 placeVersion=game.PlaceVersion,
 buildVersion=workspace:GetAttribute("BuildVersion"),
 clean=workspace:GetAttribute("CleanRebuild"),
 reactive=workspace:GetAttribute("BossReactiveOnly"),
 barrierLayers=workspace:GetAttribute("MagicBarrierLayers"),
 world=world~=nil,
 boss=boss~=nil,
 bossActive=boss and boss:GetAttribute("Active")or nil,
 bossHealth=hum and hum.MaxHealth or nil,
 motors=motors,
 tool=StarterPack:FindFirstChild("AstralStaff")~=nil,
 server=server~=nil,
 hasBeam=server and string.find(server.Source,"PiercingBeam",1,true)~=nil or false,
 hasStorm=server and string.find(server.Source,"GeometricLightning",1,true)~=nil or false,
 hasSingularity=server and string.find(server.Source,"SpatialCollapse",1,true)~=nil or false,
 hasBarrierShards=server and string.find(server.Source,"BarrierShards",1,true)~=nil or false,
}