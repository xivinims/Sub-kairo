local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155, "Wrong target")
assert(Workspace:GetAttribute("WorldRebuildComplete") == true, "World rebuild flag missing")
assert(Workspace:GetAttribute("WorldRebuildVersion") == "2026-10-15-forest-rebuild-v1", "Wrong rebuild version")

local world = Workspace:FindFirstChild("ForestWorld")
assert(world, "ForestWorld missing")
for _, name in ipairs({
	"WaterFeatures","Bridges","LampPosts","Ruins","Vegetation","Flowers","Campfires"
}) do
	assert(world:FindFirstChild(name), name .. " folder missing")
end

assert(not Workspace:FindFirstChild("RuinMansion", true), "Old mansion still exists")
assert(not StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldUI"), "Old cozy UI still exists")
assert(not ReplicatedStorage:FindFirstChild("TreeWorldZoneConfig"), "Old zone config still exists")

local spawn = world:FindFirstChild("ForestSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled, "New ForestSpawn missing")
assert(math.abs(spawn.Position.X + 70) < 2 and math.abs(spawn.Position.Z - 680) < 2, "Spawn in unexpected location")

local trees = Workspace:GetAttribute("GeneratedTreeCount") or 0
local plants = Workspace:GetAttribute("GeneratedPlantCount") or 0
local flowers = Workspace:GetAttribute("GeneratedFlowerCount") or 0
local bridges = Workspace:GetAttribute("GeneratedBridgeCount") or 0
local lamps = Workspace:GetAttribute("GeneratedLampCount") or 0
local ruins = Workspace:GetAttribute("PreservedRuinsCount") or 0

assert(trees >= 250, "Not enough generated trees")
assert(plants >= 300, "Not enough low plants")
assert(flowers >= 200, "Not enough flowers")
assert(bridges == 3, "Expected exactly 3 designed bridges")
assert(lamps >= 8, "Not enough lamp posts")
assert(ruins >= 1, "Preserved ruins missing")

local waterfall = world.WaterFeatures:FindFirstChild("StoneCliffWaterfall")
assert(waterfall, "Waterfall model missing")
assert(waterfall:FindFirstChild("WaterfallMistEmitter"), "Waterfall mist missing")
local waterfallSound = waterfall:FindFirstChild("WaterfallAmbience", true)
assert(waterfallSound and waterfallSound:IsA("Sound"), "Waterfall sound missing")

assert(SoundService:FindFirstChild("TreeWorldForestAmbience"), "Forest ambience missing")
assert(SoundService:FindFirstChild("TreeWorldRainAmbience"), "Rain ambience missing")

assert(ServerScriptService:FindFirstChild("TreeWorldWeatherServer"), "Weather server missing")
assert(ServerScriptService:FindFirstChild("TreeWorldCampfireServer"), "Campfire server missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldWeatherClient"), "Weather client missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldCampfireClient"), "Campfire client missing")
assert(ReplicatedStorage:FindFirstChild("PlaceCampfire"), "Campfire remote missing")

assert(Lighting:FindFirstChild("ForestAtmosphere"), "Atmosphere missing")
assert(Lighting:FindFirstChild("ForestColor"), "Color correction missing")
assert(Lighting:FindFirstChild("ForestSunRays"), "Sun rays missing")

-- Confirma que as ruínas preservadas foram limpas de móveis/chá/NPC antigo.
local forbidden = {"tea","teapot","cup","mug","chair","bench","armor","armour","knight","npc","guard","table"}
for _, d in ipairs(world.Ruins:GetDescendants()) do
	assert(not d:IsA("Humanoid"), "Old ruin NPC/Humanoid still present")
	assert(not d:IsA("Seat") and not d:IsA("VehicleSeat"), "Old ruin seating still present")
	local n = string.lower(d.Name)
	for _, word in ipairs(forbidden) do
		assert(not string.find(n, word, 1, true), "Forbidden old ruin object still present: " .. d.Name)
	end
end

-- Confirma água real no rio principal e lago por amostragem de voxels.
local function materialAt(pos)
	local region = Region3.new(pos - Vector3.new(2,2,2), pos + Vector3.new(2,2,2)):ExpandToGrid(4)
	local materials, occupancy = Workspace.Terrain:ReadVoxels(region, 4)
	return materials[1][1][1], occupancy[1][1][1]
end

local riverMat = materialAt(Vector3.new(-40, 16, -110))
assert(riverMat == Enum.Material.Water, "Main river sample is not water")
local lakeMat = materialAt(Vector3.new(-540, 14, 430))
assert(lakeMat == Enum.Material.Water, "Lake sample is not water")
local upperMat = materialAt(Vector3.new(650, 87, -770))
assert(upperMat == Enum.Material.Water, "Upper waterfall pool missing")

return {
	ok = true,
	placeVersion = game.PlaceVersion,
	version = Workspace:GetAttribute("WorldRebuildVersion"),
	trees = trees,
	plants = plants,
	flowers = flowers,
	bridges = bridges,
	lamps = lamps,
	ruins = ruins,
	weather = Workspace:GetAttribute("Weather"),
	spawn = {x=spawn.Position.X,y=spawn.Position.Y,z=spawn.Position.Z},
}
