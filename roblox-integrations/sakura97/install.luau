-- Swean Island v101 — Big-map test only
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local AssetService=game:GetService("AssetService")
local Terrain=workspace.Terrain
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local ReplicatedFirst=game:GetService("ReplicatedFirst")

local BIG_MAP_ID=9435523981

local function loadAsset(id)
	local ok,res=pcall(AssetService.LoadAssetAsync,AssetService,id)
	if not ok or not res then error("Asset "..id.." failed: "..tostring(res)) end
	return res
end

-- Remove tudo da versão atual.
for _,child in ipairs(workspace:GetChildren()) do
	if child~=Terrain and not child:IsA("Camera") then child:Destroy() end
end
Terrain:Clear()

for _,container in ipairs({
	ServerScriptService,
	StarterPlayer.StarterPlayerScripts,
	ReplicatedFirst,
	game:GetService("StarterGui")
}) do
	for _,child in ipairs(container:GetChildren()) do child:Destroy() end
end

for _,child in ipairs(ReplicatedStorage:GetChildren()) do
	if child.Name=="SakuraRuntime" or child.Name=="ForestRuntime" or child.Name=="SweanRuntime" then
		child:Destroy()
	end
end

local runtime=Instance.new("Folder")
runtime.Name="SweanRuntime"
runtime.Parent=ReplicatedStorage
runtime:SetAttribute("Version",101)
runtime:SetAttribute("MapAssetId",BIG_MAP_ID)
runtime:SetAttribute("MapName","Big map")
runtime:SetAttribute("Mode","MapTestOnly")

pcall(function()
	workspace.StreamingEnabled=true
	workspace.StreamingMinRadius=128
	workspace.StreamingTargetRadius=420
end)

workspace.FallenPartsDestroyHeight=-600

local asset=loadAsset(BIG_MAP_ID)
local source=asset:FindFirstChild("Big map",true)
assert(source and source:IsA("Model"),"Big map model missing")

local map=source:Clone()
map.Name="BigMapTest"
map:SetAttribute("AssetId",BIG_MAP_ID)
map.Parent=workspace

local partCount=0
local modelCount=0
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("LuaSourceContainer") then
		d:Destroy()
	elseif d:IsA("BasePart") then
		partCount+=1
		d.Anchored=true
	elseif d:IsA("Model") then
		modelCount+=1
	end
end

assert(partCount==1694,"Big map part count changed: "..tostring(partCount))
assert(modelCount>=289,"Big map model count changed: "..tostring(modelCount))

-- Centraliza sem redimensionar.
local cf,size=map:GetBoundingBox()
local delta=Vector3.new(-cf.Position.X,size.Y/2-cf.Position.Y,-cf.Position.Z)
map:PivotTo(map:GetPivot()+delta)

runtime:SetAttribute("Parts",partCount)
runtime:SetAttribute("Models",modelCount)
runtime:SetAttribute("SizeX",size.X)
runtime:SetAttribute("SizeY",size.Y)
runtime:SetAttribute("SizeZ",size.Z)
asset:Destroy()

-- Procura um chão razoavelmente horizontal perto do centro para spawn.
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={map}
params.IgnoreWater=true

local function groundAt(x,z)
	local hit=workspace:Raycast(
		Vector3.new(x,size.Y+250,z),
		Vector3.new(0,-(size.Y+700),0),
		params
	)
	if hit and hit.Normal.Y>.72 then return hit.Position end
end

local spawnPos=nil
for radius=0,900,60 do
	for step=1,28 do
		local a=(step/28)*math.pi*2
		local p=groundAt(math.cos(a)*radius,math.sin(a)*radius)
		if p then spawnPos=p break end
	end
	if spawnPos then break end
end
assert(spawnPos,"No safe spawn found")

local spawn=Instance.new("SpawnLocation")
spawn.Name="BigMapSpawn"
spawn.Size=Vector3.new(8,.5,8)
spawn.Anchored=true
spawn.CanCollide=false
spawn.CanTouch=false
spawn.Transparency=1
spawn.Neutral=true
spawn.Enabled=true
spawn.Duration=0
spawn.CFrame=CFrame.new(spawnPos+Vector3.new(0,.25,0))
spawn.Parent=workspace

local server=Instance.new("Script")
server.Name="BigMapTestServer"
server.Source=[[
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("BigMapSpawn")

local function protect(character)
	task.spawn(function()
		while character.Parent do
			local root=character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y<-550 then
				character:PivotTo(spawn.CFrame*CFrame.new(0,4,0))
			end
			task.wait(.5)
		end
	end)
end

local function hook(player)
	player.RespawnLocation=spawn
	player.CharacterAdded:Connect(protect)
	if player.Character then protect(player.Character) end
end

Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
]]
server.Parent=ServerScriptService

return {
	version=101,
	map="Big map",
	parts=partCount,
	models=modelCount
}
