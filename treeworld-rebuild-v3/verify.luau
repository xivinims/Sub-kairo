local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")
local Terrain=Workspace.Terrain

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion>=104,"Reference rebuild was not saved")
assert(Workspace:GetAttribute("WorldRebuildComplete")==true,"Rebuild flag missing")
assert(Workspace:GetAttribute("WorldRebuildVersion")=="2026-10-15-reference-rebuild-v3","Wrong rebuild version")
assert(Workspace:GetAttribute("ReferenceStyleTarget")=="UserReferenceSet-2026-10-15","Reference target missing")
assert(Workspace:GetAttribute("OfficialForestPackUsed")==true,"Official forest pack was not used")

local world=Workspace:FindFirstChild("ForestWorld")
assert(world,"ForestWorld missing")

for _,name in ipairs({"Trees","Bushes","Flowers","Rocks","Water","Paths","Bridges","TempleRuins","Torii","LampPosts","Campfires"}) do
	assert(world:FindFirstChild(name),name.." folder missing")
end

local trees=Workspace:GetAttribute("TreePlacementCount") or 0
local bushes=Workspace:GetAttribute("BushPlacementCount") or 0
local flowers=Workspace:GetAttribute("FlowerPlacementCount") or 0
local rocks=Workspace:GetAttribute("RockPlacementCount") or 0
local lamps=Workspace:GetAttribute("LampPlacementCount") or 0

assert(trees>=180,"Too few real forest-pack trees")
assert(bushes>=220,"Too few bushes")
assert(flowers>=300,"Too few flowers/ground plants")
assert(rocks>=100,"Too few stylized rocks")
assert(lamps>=12,"Too few current lamp posts")

local meshTrees=0
for _,d in ipairs(world.Trees:GetDescendants()) do
	if d:IsA("MeshPart") then meshTrees+=1 end
end
assert(meshTrees>0,"Trees are not using mesh assets")

assert(not world:FindFirstChild("RuinMansion",true),"Old mansion still exists")
assert(not world:FindFirstChild("ForestTree",true),"Old generic sphere-tree model still exists")
assert(not StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldUI"),"Old cozy HUD still exists")

local bridge=world.Bridges:FindFirstChild("ReferenceWoodBridge")
assert(bridge,"Reference wooden bridge missing")
assert(bridge:FindFirstChild("BridgePlank",true),"Bridge planks missing")
assert(world.Bridges:FindFirstChild("ReferenceSteppingStones"),"River stepping stones missing")

local torii=world.Torii:FindFirstChild("StoneToriiGate")
assert(torii and torii:FindFirstChild("ToriiPillar",true),"Torii gate missing")

local ruins=world.TempleRuins:FindFirstChild("OvergrownTempleRuins")
assert(ruins,"Overgrown temple ruins missing")
assert(ruins:FindFirstChild("ArchStone",true),"Temple arches missing")
assert(ruins:FindFirstChild("ColumnShaft",true),"Temple columns missing")
assert(ruins:FindFirstChild("AncientFloorSlab",true),"Temple floor missing")

local waterfall=world.Water:FindFirstChild("ReferenceWaterfallCliff")
assert(waterfall and waterfall:FindFirstChild("WaterfallSheet",true),"Waterfall cliff missing")
assert(waterfall:FindFirstChild("WaterfallAmbience",true),"Waterfall ambience missing")

local spawn=world:FindFirstChild("ForestSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"Spawn missing")

assert(Lighting:FindFirstChild("ReferenceAtmosphere"),"Atmosphere missing")
assert(Lighting:FindFirstChild("ReferenceColor"),"Color correction missing")
assert(Lighting:FindFirstChild("ReferenceSunRays"),"Sun rays missing")
assert(Lighting:FindFirstChild("ReferenceBloom"),"Bloom missing")
assert(Terrain:FindFirstChild("ReferenceClouds"),"Clouds missing")

assert(ServerScriptService:FindFirstChild("TreeWorldWeatherServer"),"Weather system missing")
assert(ServerScriptService:FindFirstChild("TreeWorldCampfireServer"),"Campfire system missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldWeatherClient"),"Weather client missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldCampfireClient"),"Campfire client missing")
assert(ReplicatedStorage:FindFirstChild("PlaceCampfire"),"Campfire remote missing")

local function materialAt(pos)
	local region=Region3.new(pos-Vector3.new(2,2,2),pos+Vector3.new(2,2,2)):ExpandToGrid(4)
	local mats,occ=Terrain:ReadVoxels(region,4)
	return mats[1][1][1],occ[1][1][1]
end

local lakeMat=materialAt(Vector3.new(-495,8,455))
local pondMat=materialAt(Vector3.new(470,8,610))
local riverMat=materialAt(Vector3.new(-120,9,40))
local topPoolMat=materialAt(Vector3.new(-870,108,-900))
assert(lakeMat==Enum.Material.Water,"Main lake missing")
assert(pondMat==Enum.Material.Water,"Secondary pond missing")
assert(riverMat==Enum.Material.Water,"Main river missing")
assert(topPoolMat==Enum.Material.Water,"Waterfall upper pool missing")

-- Structure masks should not be Grass, preventing native grass through models.
local bridgeGround=materialAt(Vector3.new(-120,19,1))
local toriiGround=materialAt(Vector3.new(355,19,530))
local ruinGround=materialAt(Vector3.new(720,19,-560))
assert(bridgeGround~=Enum.Material.Grass,"Grass mask missing near bridge")
assert(toriiGround~=Enum.Material.Grass,"Grass mask missing near torii")
assert(ruinGround~=Enum.Material.Grass,"Grass mask missing in ruins")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	version=Workspace:GetAttribute("WorldRebuildVersion"),
	trees=trees,
	bushes=bushes,
	flowers=flowers,
	rocks=rocks,
	lamps=lamps,
	meshTrees=meshTrees,
	weather=Workspace:GetAttribute("Weather"),
	spawn={x=spawn.Position.X,y=spawn.Position.Y,z=spawn.Position.Z},
}
