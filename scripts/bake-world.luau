-- Executes the SAME World builder with Lune's Roblox data model, then serializes it.
-- This verifies construction/properties; it does not simulate Humanoid, networking or physics.
local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local luau=require("@lune/luau")
local serde=require("@lune/serde")
local place=roblox.deserializePlace(fs.readFile("dist/Brambles-Sprout.rbxlx"))
local workspace=place:GetService("Workspace")
local old=workspace:FindFirstChild("BrambleWorld");if old then old:Destroy() end
local shared=place:GetService("ReplicatedStorage").Shared
local Config=luau.load(fs.readFile("src/shared/Config.luau"))()
local Maze=luau.load(fs.readFile("src/shared/Maze.luau"))()
local env={game=place,workspace=workspace,Instance=roblox.Instance,Vector3=roblox.Vector3,Vector2=roblox.Vector2,CFrame=roblox.CFrame,Color3=roblox.Color3,UDim2=roblox.UDim2,Enum=roblox.Enum}
env.require=function(instance)
 if instance==shared.Config then return Config end
 if instance==shared.Maze then return Maze end
 error("Unmapped require "..tostring(instance))
end
local World=luau.load(fs.readFile("src/server/World.luau"),{environment=env})()
World.build()
local world=workspace.BrambleWorld
world:SetAttribute("Prebuilt",true)
local targets,parts,unique=0,0,{}
for _,item in ipairs(world:GetDescendants()) do
 if item:IsA("BasePart") then parts+=1 end
 local id=item:GetAttribute("TargetId")
 if id then assert(not unique[id],"duplicate target "..id);unique[id]=true;targets+=1 end
end
assert(targets>=65,"missing campaign targets")
for sector=1,7 do assert(World.Targets[sector..":exit"],"missing exit");assert(World.Targets[sector..":protocol"],"missing protocol") end
fs.writeDir("assets/world")
fs.writeFile("assets/world/BramblesWorld.rbxmx",roblox.serializeModel({world},true))
fs.writeFile("dist/world-audit.json",serde.encode("json",{parts=parts,targets=targets,sectors=7,construction=true,studioPlaytest=false},true))
print("PASS: baked "..parts.." parts and "..targets.." unique interaction targets")
