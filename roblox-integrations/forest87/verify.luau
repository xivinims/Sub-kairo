assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==87,"Forest version 87 was not saved")
local runtime=assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"))
assert(game.ServerScriptService.ForestServer.Source:find('require(runtime:WaitForChild("Visuals")).apply()',1,true))
local rendererBeforeStartup=tostring(game.Lighting.LightingStyle)
require(runtime.Visuals).apply()
local function run(code)
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage
 local v=require(m)()m:Destroy()return v
end
local tests=run([============[local world = assert(workspace:FindFirstChild("ForestWorld"), "Forest world missing")
local runtime = assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"))
assert(not workspace:FindFirstChild("MonCalamariWorld") and not workspace:FindFirstChild("IlhaSerena"), "Retired maps remain")
assert(world:GetAttribute("ForestOnly") and world:GetAttribute("ForestAssetId") == 6432306802 and world:GetAttribute("UpgradeVersion") == 87)
local Scene = require(runtime.Scene)
local parts, meshes, appearances, foreign = 0, 0, 0, 0
for _, d in ipairs(world:GetDescendants()) do
	if d:IsA("BasePart") then parts += 1 assert(d.Anchored, "Forest prop unanchored") end
	if d:IsA("MeshPart") then meshes += 1 end
	if d:IsA("SurfaceAppearance") then appearances += 1 end
	if d:IsA("LuaSourceContainer") then foreign += 1 end
end
assert(foreign == 0 and meshes > 1800 and appearances > 1600, "Official PBR vegetation incomplete")
assert(world:GetAttribute("TreeCount") > 300 and world:GetAttribute("PlantCount") > 1000 and world:GetAttribute("FlowerCount") > 150)
local terrainParams = RaycastParams.new() terrainParams.FilterType = Enum.RaycastFilterType.Include terrainParams.FilterDescendantsInstances = {workspace.Terrain}
local function ground(x, z) return workspace:Raycast(Vector3.new(x, 220, z), Vector3.new(0, -340, 0), terrainParams) end
local count, heights, rivers, green, trail = 0, {}, 0, 0, 0
for x = -360, 360, 24 do for z = -336, 336, 24 do
	local hit = ground(x, z)
	if hit then
		count += 1 heights[#heights + 1] = hit.Position.Y
		if hit.Material == Enum.Material.Water then rivers += 1
		elseif hit.Material == Enum.Material.Grass or hit.Material == Enum.Material.LeafyGrass then green += 1
		elseif hit.Material == Enum.Material.Ground then trail += 1 end
	end
end end
table.sort(heights)
assert(count > 600 and green > 250 and rivers > 25 and trail > 10 and heights[#heights] - heights[1] > 45, "Terrain lacks variation, water or trails")
local roots = 0
for _, tree in ipairs(world.Decor.Trees:GetChildren()) do
	local point = tree:GetAttribute("GroundPoint") local planted = tree:GetAttribute("PlantingPoint")
	local hit = assert(ground(point.X, point.Z))
	assert(hit.Material ~= Enum.Material.Water and math.abs(hit.Position.Y - point.Y) < 0.06, "Tree ground reference wrong")
	assert(planted.Y <= point.Y + 0.02 and point.Y - planted.Y < 3.5, "Tree floats or is too buried")
	assert(tree:FindFirstChild("TrunkCollision") and tree.ModelStreamingMode == Enum.ModelStreamingMode.Atomic)
	roots += 1
end
local spawn = world:GetAttribute("MainSpawnCF")
local floor = assert(ground(spawn.X, spawn.Z))
assert(floor.Material ~= Enum.Material.Water and math.abs(spawn.Y - floor.Position.Y - 3.5) < 0.05 and floor.Normal.Y > 0.65, "Forest spawn unsafe")
local bodyRay = RaycastParams.new() bodyRay.FilterType = Enum.RaycastFilterType.Include bodyRay.FilterDescendantsInstances = {world.Decor} bodyRay.RespectCanCollide = true
for _, y in ipairs({1.4, 3.2, 5}) do for _, d in ipairs({Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis}) do
	assert(not workspace:Raycast(floor.Position + Vector3.new(0, y, 0), d * 3, bodyRay), "Forest spawn blocked by decoration")
end end
local template = runtime.SkinnedGrassTemplates.GrassCard
assert(template:GetAttribute("SourceAssetId") == 87377915371959 and template:GetAttribute("SourceVariant") == "GrassCard")
local mesh = template:FindFirstChildOfClass("MeshPart") local bones, offsets = {}, {}
for _, b in ipairs(mesh:GetChildren()) do if b:IsA("Bone") then bones[#bones + 1] = b end end
table.sort(bones, function(a, b) return a.Name < b.Name end) assert(#bones == 100)
for i, b in ipairs(bones) do offsets[i] = template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position) end
local sampler = require(runtime.GrassSampler).new(world)
local tested, validRoots = 0, 0
for _, point in ipairs({Vector3.new(spawn.X, 0, spawn.Z), Vector3.new(-220, 0, 50), Vector3.new(160, 0, -180), Vector3.new(240, 0, 210)}) do
	for _, cell in ipairs(Scene.around(point, 36)) do
		local heights, anchor, valid = sampler:sample(cell, offsets)
		if anchor and valid > 30 then
			tested += 1 validRoots += valid
			for i, y in pairs(heights) do
				local hit = ground(cell.center.X + offsets[i].X, cell.center.Z + offsets[i].Z)
				assert(hit and (hit.Material == Enum.Material.Grass or hit.Material == Enum.Material.LeafyGrass) and math.abs(hit.Position.Y - y) < 0.01, "Grass root is off Terrain")
			end
			break
		end
	end
end
assert(tested >= 3 and validRoots > 150, "Skinned grass field missing in forest zones")
local Skinned = require(runtime.SkinnedGrass)
local storage = Instance.new("Folder") storage.Parent = game.ReplicatedStorage
local grass = Skinned.new({MeshStorage = storage, RenderDistanceEnabled = false, WindEnabled = true, WindStrengthScale = 0.82})
local sample = template:Clone() sample:PivotTo(CFrame.new(-210, 40, 30)) sample.Parent = workspace
local b = sample:FindFirstChildOfClass("MeshPart"):FindFirstChildWhichIsA("Bone")
b:SetAttribute("SerenaTerrainOffset", CFrame.new(0, 1.25, 0))
b:SetAttribute("SerenaGroundPoint", b.WorldCFrame.Position + Vector3.new(0, 1.25, 0))
grass:AddMeshes({sample})
grass:Step(1/30, {}, b.TransformedWorldCFrame.Position)
assert(math.abs(b.Transform.Y - 1.25) < 0.01, "Wind displaced the grass root")
grass:RemoveMeshes({sample}) assert(next(grass.MeshRecords) == nil) grass:Destroy() sample:Destroy() storage:Destroy()
assert(runtime.WindEffects:GetAttribute("SourceAssetId") == 11946229834 and workspace.GlobalWind.Magnitude > 6)
local Wind = require(runtime.WindEffects.WindLines)
Wind:Init({Direction = workspace.GlobalWind.Unit, Speed = 10, Lifetime = 2, SpawnRate = 5})
Wind:Create({Position = spawn.Position + Vector3.new(0, 8, 0), Speed = 10, Lifetime = 2}) assert(#Wind.UpdateQueue >= 1) Wind:Cleanup()
assert(game.Lighting.LightingStyle == Enum.LightingStyle.Realistic and game.Lighting.ForestColor.Enabled and game.Lighting.ForestSunRays.Enabled)
local compiled = 0
for _, parent in ipairs({game.ServerScriptService, game.StarterPlayer.StarterPlayerScripts}) do
	for _, s in ipairs(parent:GetChildren()) do if s:IsA("Script") or s:IsA("LocalScript") then
		local m = Instance.new("ModuleScript") m.Source = "return function()\n" .. s.Source .. "\nend" m.Parent = game.ServerStorage
		local ok, result = pcall(require, m) m:Destroy() assert(ok, s.Name .. ": " .. tostring(result)) compiled += 1
	end end
end
for _, s in ipairs(runtime:GetDescendants()) do if s:IsA("ModuleScript") then local ok, result = pcall(require, s) assert(ok, s.Name .. ": " .. tostring(result)) compiled += 1 end end
assert(#game.ServerScriptService:GetChildren() == 1 and #game.StarterGui:GetChildren() == 0 and #game.StarterPack:GetChildren() == 0)
assert(workspace.StreamingEnabled and world:GetAttribute("Crossings") == 2)
return {forestOnly = true, parts = parts, realMeshParts = meshes, pbrAppearances = appearances, foreignMapScripts = foreign,
	trees = roots, plants = world:GetAttribute("PlantCount"), flowers = world:GetAttribute("FlowerCount"), terrainProbes = count,
	greenTerrainProbes = green, waterProbes = rivers, trailProbes = trail, terrainHeightRange = heights[#heights] - heights[1],
	grassSampledZones = tested, grassValidSampledRoots = validRoots, grassRootWindStable = true, safeSpawn = true,
	nativeWindWorking = true, compiledScriptsAndModules = compiled, streamingEnabled = true, realisticRendering = true}
]============])
run(game.ServerScriptService.ForestServer.Source)
return{ok=true,version=game.PlaceVersion,forestOnly=true,rendererBeforeStartup=rendererBeforeStartup,renderingBootstrapVerified=true,tests=tests}
