assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==86,"Expected published city version 86")
local runtime=assert(game.ReplicatedStorage:FindFirstChild("MonCalamariRuntime"))
assert(game.ServerScriptService.MonCalamariServer.Source:find('require(runtime:WaitForChild("Visuals")).apply()',1,true),"Server rendering bootstrap missing")
assert(game.StarterPlayer.StarterPlayerScripts.MonCalamariClient.Source:find("Visuals.apply()",1,true),"Client rendering bootstrap missing")
local rendererBeforeStartup=tostring(game.Lighting.LightingStyle)
require(runtime.Visuals).apply()
local function run(code)
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage
 local result=require(m)()m:Destroy()return result
end
local tests=run([============[local world = assert(workspace:FindFirstChild("MonCalamariWorld"), "City world missing")
local city = assert(world:FindFirstChild("MonCalamariCity"), "Full city missing")
local runtime = assert(game.ReplicatedStorage:FindFirstChild("MonCalamariRuntime"), "City runtime missing")
assert(world:GetAttribute("SourceAssetId") == 485800451 and city:GetAttribute("SourceAssetId") == 485800451)
assert(world:GetAttribute("UpgradeVersion") == 86 and not workspace:FindFirstChild("IlhaSerena"))
local parts, unions, wedges, scripts, materials = 0, 0, 0, 0, {}
for _, d in ipairs(city:GetDescendants()) do
	if d:IsA("BasePart") then
		parts += 1 assert(d.Anchored, "Unanchored imported map")
		materials[d.Material.Name] = (materials[d.Material.Name] or 0) + 1
		assert(d.MaterialVariant:sub(1, 11) ~= "SerenaStud_", "Retired theme altered the map")
		if d:IsA("UnionOperation") then unions += 1 elseif d:IsA("WedgePart") then wedges += 1 end
	elseif d:IsA("LuaSourceContainer") then scripts += 1 end
end
assert(parts == 1906 and unions == 542 and wedges == 331 and scripts == 0, "Original map incomplete")
local lo, hi = world:GetAttribute("CityBoundsMin"), world:GetAttribute("CityBoundsMax")
assert(hi.X - lo.X > 2300 and hi.Z - lo.Z > 3000 and hi.Y - lo.Y > 430, "City extent incomplete")
local spawnCF = world:GetAttribute("MainSpawnCF")
assert((spawnCF.Position - runtime:GetAttribute("MainSpawnCF").Position).Magnitude < 0.001)
local ray = RaycastParams.new() ray.FilterType = Enum.RaycastFilterType.Include
ray.FilterDescendantsInstances = {city} ray.RespectCanCollide = true
local checkedFloors = 0
for _, x in ipairs({-3, 0, 3}) do for _, z in ipairs({-3, 0, 3}) do
	local floor = assert(workspace:Raycast(Vector3.new(spawnCF.X + x, 10, spawnCF.Z + z), Vector3.new(0, -20, 0), ray), "Spawn floor missing")
	assert(floor.Normal.Y > 0.99 and math.abs(floor.Position.Y) < 0.03 and floor.Material ~= Enum.Material.Water,
		"Spawn floor uneven or underwater")
	checkedFloors += 1
end end
for _, y in ipairs({1.2, 3, 5}) do
	for _, direction in ipairs({Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis}) do
		assert(not workspace:Raycast(Vector3.new(spawnCF.X, y, spawnCF.Z), direction * 3, ray), "Spawn body blocked")
	end
end
assert(math.abs(spawnCF.Y - 3.5) < 0.03 and world.MonCalamariSpawn.Enabled and world.MonCalamariSpawn.Neutral)
assert(game.Players.CharacterAutoLoads and game.StarterPlayer.CharacterWalkSpeed == 16 and #game.StarterGui:GetChildren() == 0)
local sea = world:GetAttribute("OceanSurfaceY")
assert(sea == -10 and spawnCF.Y - sea > 10 and workspace.Terrain.WaterWaveSize > 0 and workspace.Terrain.WaterWaveSpeed > 0)
local oceanPoint = Vector3.new(hi.X + 80, -24, (lo.Z + hi.Z) * 0.5)
local region = Region3.new(oceanPoint - Vector3.one * 4, oceanPoint + Vector3.one * 4):ExpandToGrid(4)
local waterMaterials, occupancy = workspace.Terrain:ReadVoxels(region, 4)
local water = 0
for x = 1, #waterMaterials do for y = 1, #waterMaterials[x] do for z = 1, #waterMaterials[x][y] do
	if waterMaterials[x][y][z] == Enum.Material.Water and occupancy[x][y][z] > 0 then water += 1 end
end end end
assert(water > 0, "Ocean was not saved as native Terrain water")
assert(workspace.Terrain.MonCalamariClouds and workspace.GlobalWind.Magnitude > 7)

local doors = 0
for _, panel in ipairs(game:GetService("CollectionService"):GetTagged("MonCalamariDoor")) do
	if panel:IsDescendantOf(city) then
		doors += 1 assert(panel:GetAttribute("ClosedTransparency") ~= nil and panel:FindFirstChild("DoorPrompt"))
	end
end
assert(doors == 3, "Original doors missing")
local lighting = game.Lighting
assert(lighting.LightingStyle == Enum.LightingStyle.Realistic and lighting.PrioritizeLightingQuality and lighting.GlobalShadows)
assert(lighting.EnvironmentDiffuseScale == 1 and lighting.EnvironmentSpecularScale == 1)
assert(lighting.MonCalamariColor.Enabled and lighting.MonCalamariBloom.Enabled and lighting.MonCalamariSunRays.Enabled)
assert(lighting.MonCalamariAtmosphere.Density > 0 and lighting.MonCalamariSky)
assert(runtime.WindEffects:GetAttribute("SourceAssetId") == 11946229834)
local WindLines = require(runtime.WindEffects.WindLines)
WindLines:Init({Speed = 12, Lifetime = 2, SpawnRate = 7, Direction = workspace.GlobalWind.Unit})
WindLines:Create({Position = spawnCF.Position + Vector3.new(0, 10, 0), Lifetime = 2, Speed = 12})
assert(#WindLines.UpdateQueue >= 1 and WindLines.UpdateQueue[1].Attachment0.Parent == workspace.Terrain,
	"Wind asset failed to create its real Trail effect")
WindLines:Cleanup()
assert(#WindLines.UpdateQueue == 0 and WindLines.UpdateConnection == nil, "Wind asset did not clean up")
local compiled = 0
for _, parent in ipairs({game.ServerScriptService, game.StarterPlayer.StarterPlayerScripts}) do
	for _, scriptObject in ipairs(parent:GetChildren()) do
		assert(scriptObject.Name:sub(1, 6) ~= "Serena", "Retired gameplay still runs")
		if scriptObject:IsA("Script") or scriptObject:IsA("LocalScript") then
			local m = Instance.new("ModuleScript") m.Source = "return function()\n" .. scriptObject.Source .. "\nend" m.Parent = game.ServerStorage
			local ok, result = pcall(require, m) m:Destroy()
			assert(ok, scriptObject.Name .. ": " .. tostring(result)) compiled += 1
		end
	end
end
for _, d in ipairs(runtime:GetDescendants()) do if d:IsA("ModuleScript") then
	local ok, result = pcall(require, d) assert(ok, d.Name .. ": " .. tostring(result)) compiled += 1
end end
assert(#game.ServerScriptService:GetChildren() == 1 and #game.StarterPack:GetChildren() == 0)
assert(#game.ReplicatedStorage:GetChildren() == 1 and not game.ReplicatedStorage:FindFirstChild("SerenaRuntime"))
assert(workspace.StreamingEnabled and city.ModelStreamingMode == Enum.ModelStreamingMode.Default)
local function optionalProperty(property)
	local ok, value = pcall(function() return workspace[property] end)
	return ok and value or "Unavailable in this edit-session engine"
end
return {parts = parts, originalUnions = unions, originalWedges = wedges, importedScripts = scripts, materials = materials,
	safeSpawnFloorChecks = checkedFloors, spawnBodyClear = true, originalDoors = doors, nativeOceanSamples = water,
	nativeWindTrail = true, compiledScriptsAndModules = compiled, retiredGameplayRemoved = true,
	realisticRendering = true, nativePostProcessing = true, streamingEnabled = workspace.StreamingEnabled,
	streamingMinRadius = optionalProperty("StreamingMinRadius"), streamingTargetRadius = optionalProperty("StreamingTargetRadius")}
]============])
run(game.ServerScriptService.MonCalamariServer.Source)
return{ok=true,version=game.PlaceVersion,assetId=workspace.MonCalamariWorld:GetAttribute("SourceAssetId"),rendererBeforeStartup=rendererBeforeStartup,renderingBootstrapVerified=true,tests=tests}
