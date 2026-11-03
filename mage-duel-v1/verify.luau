local Workspace=game:GetService("Workspace")
local StarterGui=game:GetService("StarterGui")
local StarterPack=game:GetService("StarterPack")
local StarterPlayer=game:GetService("StarterPlayer")
local ServerScriptService=game:GetService("ServerScriptService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(Workspace:GetAttribute("BuildVersion")=="mage-duel-v1","Build version missing")
assert(Workspace:GetAttribute("CleanRebuild")==true,"Clean rebuild flag missing")
assert(Workspace:GetAttribute("BossReactiveOnly")==true,"Reactive boss flag missing")
assert(Workspace:GetAttribute("MagicBarrierLayers")==3,"Barrier layer count wrong")

local world=assert(Workspace:FindFirstChild("MageDuelWorld"),"MageDuelWorld missing")
assert(not Workspace:FindFirstChild("OveryardPhotoWorld"),"Old world still exists")
assert(world:FindFirstChild("CleanFloor"),"Clean floor missing")
assert(world:FindFirstChild("ArenaInlay"),"Arena inlay missing")
assert(world:FindFirstChild("MageSpawn"),"Spawn missing")

local boss=assert(world:FindFirstChild("AstraVeyra"),"Boss missing")
assert(boss:GetAttribute("BossVersion")=="mage-duel-v1","Boss version mismatch")
assert(boss:GetAttribute("Active")==false,"Boss must begin dormant")
local hum=assert(boss:FindFirstChildOfClass("Humanoid"),"Boss humanoid missing")
assert(hum.MaxHealth==2200,"Boss health mismatch")
assert(boss:FindFirstChild("MageStaff",true),"Boss staff missing")
assert(boss:FindFirstChild("StaffTip",true),"Boss staff tip missing")
assert(boss:FindFirstChild("ElfEarL",true) and boss:FindFirstChild("ElfEarR",true),"Elf design missing")
assert(boss:FindFirstChild("Cape",true) and boss:FindFirstChild("RobeChest",true),"Boss robe/cape missing")

local motors=0
local required={Root=true,Waist=true,Neck=true,LeftShoulder=true,LeftElbow=true,LeftWrist=true,RightShoulder=true,RightElbow=true,RightWrist=true,LeftHip=true,LeftKnee=true,LeftAnkle=true,RightHip=true,RightKnee=true,RightAnkle=true}
for _,d in ipairs(boss:GetDescendants())do
 if d:IsA("Motor6D")then motors+=1;required[d.Name]=nil end
end
assert(motors==15,"Boss R15 must have 15 joints, got "..motors)
for name in pairs(required)do error("Missing boss joint "..name)end

local tool=assert(StarterPack:FindFirstChild("AstralStaff"),"Player staff missing")
assert(tool:IsA("Tool"),"AstralStaff is not a Tool")
assert(tool:FindFirstChild("Handle"),"Staff handle missing")
assert(tool:FindFirstChild("StaffGem"),"Staff gem missing")
local client=assert(tool:FindFirstChild("MageDuelClient"),"Staff client missing")
assert(client:IsA("LocalScript"),"MageDuelClient must be LocalScript")
for _,ability in ipairs({"Attack","Barrier","Heal","Dodge","Jump","Fly"})do
 assert(string.find(client.Source,ability,1,true),"Client missing ability "..ability)
end

local server=assert(ServerScriptService:FindFirstChild("MageDuelServer"),"MageDuelServer missing")
local src=server.Source
for _,token in ipairs({"LayeredHexBarrier","BarrierShards","ManaDust","PiercingBeam","GeometricLightning","SpatialCollapse","bossBarrier","bossStorm","bossSingularity","bossHeal","bossDodge"})do
 assert(string.find(src,token,1,true),"Server magic missing "..token)
end
assert(string.find(src,"local active=false",1,true),"Boss must start inactive")
assert(string.find(src,"active=true;target=plr",1,true),"Attack-triggered activation missing")
assert(string.find(src,"bossShield.layers=3",1,true),"Three-layer boss barrier missing")
assert(string.find(src,"playerShield[ch]={untilTime=now()+1.8,layers=3}",1,true),"Three-layer player barrier missing")

local remotes=assert(ReplicatedStorage:FindFirstChild("MageDuelRemotes"),"Magic remotes missing")
assert(remotes:FindFirstChild("Cast"),"Cast remote missing")

assert(#StarterGui:GetChildren()==0,"StarterGui must stay clean")
local allowedStarter={PlayerModule=true,RbxCharacterSounds=true,PlayerScriptsLoader=true}
for _,x in ipairs(StarterPlayer.StarterPlayerScripts:GetChildren())do
 assert(allowedStarter[x.Name],"Unexpected StarterPlayerScript remains: "..x.Name)
end
assert(#StarterPlayer.StarterCharacterScripts:GetChildren()==0,"Old StarterCharacterScripts remain")

local workspaceGameplay=0
for _,o in ipairs(Workspace:GetChildren())do
 if o.Name~="Terrain" and not o:IsA("Camera") then workspaceGameplay+=1 end
end
assert(workspaceGameplay==1,"Workspace must contain only MageDuelWorld gameplay root")

return {
 ok=true,
 placeVersion=game.PlaceVersion,
 buildVersion=Workspace:GetAttribute("BuildVersion"),
 bossMotors=motors,
 bossHealth=hum.MaxHealth,
 barrierLayers=Workspace:GetAttribute("MagicBarrierLayers"),
 staff=true,
 cleanWorkspace=true,
}
