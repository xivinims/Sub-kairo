assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==86,"Published base changed")
local function factory(code)
 local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage
 local v=require(m)m:Destroy()return v
end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)
 local old=parent:FindFirstChild(name)
 if old then old.Source=code return old end
 local s=Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s
end
local Scene=factory([============[local Scene = {Minimum = -512, Maximum = 512, Spacing = 8, RiverY = 6, SeaY = -8, Seed = 20261013}
local function smooth(a, b, x)
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end
local function gaussian(x, z, cx, cz, radius)
	return math.exp(-((x - cx)^2 + (z - cz)^2) / radius^2)
end
function Scene.riverX(z)
	return 38 * math.sin(z / 115) + 22 * math.sin(z / 57 + 0.7)
end
function Scene.riverWidth(z)
	return 13 + 3 * math.sin(z / 92)^2 + 7 * gaussian(0, z, 0, 150, 64)
end
function Scene.pathX(z)
	return -110 + 47 * math.sin((z + 140) / 140) + 16 * math.sin(z / 62)
end
function Scene.pathDistance(x, z)
	local main = math.abs(x - Scene.pathX(z))
	local east = math.abs(x - (145 + 30 * math.sin(z / 100)))
	local crossing = math.min(math.abs(z + 108), math.abs(z - 176))
	if x > -170 and x < 210 then main = math.min(main, crossing) end
	return math.min(main, east)
end
function Scene.sample(x, z)
	local r = math.sqrt((x / 442)^2 + (z / 405)^2)
	local shore = r + math.noise(x / 95, z / 95, 7) * 0.045
	local interior = 1 - smooth(0.75, 1.05, shore)
	local hill = 70 * gaussian(x, z, 220, 228, 114) + 43 * gaussian(x, z, -256, -174, 128)
		+ 31 * gaussian(x, z, -275, 177, 110) + 24 * gaussian(x, z, 274, -184, 116)
	local detail = 3.1 * math.noise(x / 75, z / 75, 3.17) + 1.5 * math.noise(x / 23, z / 23, 12.47)
	local height = Scene.SeaY - 4 + interior * (29 + hill + detail)
	local rd = math.abs(x - Scene.riverX(z))
	local rw = Scene.riverWidth(z)
	local riverInfluence = (1 - smooth(rw, rw + 34, rd)) * (1 - smooth(337, 401, math.abs(z)))
	local bed = Scene.RiverY - 5 + math.noise(x / 25, z / 45, 2) * 0.5
	height = height * (1 - riverInfluence) + bed * riverInfluence
	local lake = math.sqrt(((x - 39) / 61)^2 + ((z - 157) / 62)^2)
	local lakeInfluence = 1 - smooth(0.65, 1.25, lake)
	height = height * (1 - lakeInfluence) + (Scene.RiverY - 7) * lakeInfluence
	local path = Scene.pathDistance(x, z)
	local material = Enum.Material.Grass
	if shore > 0.94 then material = Enum.Material.Sand
	elseif height > 57 and hill > 45 then material = Enum.Material.Rock
	elseif rd < rw + 7 or lake < 1.25 then material = Enum.Material.Mud
	elseif path < 4.5 and shore < 0.91 then material = Enum.Material.Ground
	elseif math.noise(x / 45, z / 45, 40) > 0.1 then material = Enum.Material.LeafyGrass end
	local water = Scene.SeaY
	if riverInfluence > 0.2 or lakeInfluence > 0.1 then water = Scene.RiverY end
	return height, material, water, shore, path, rd
end
function Scene.isGreen(x, z)
	local y, material, water, shore = Scene.sample(x, z)
	return shore < 0.96 and y > water + 0.5 and (material == Enum.Material.Grass or material == Enum.Material.LeafyGrass)
end
function Scene.cell(ix, iz)
	local count = (Scene.Maximum - Scene.Minimum) / Scene.Spacing + 1
	if ix < 0 or iz < 0 or ix >= count or iz >= count then return nil end
	local x, z = Scene.Minimum + ix * Scene.Spacing, Scene.Minimum + iz * Scene.Spacing
	-- Include the edges of green patches; roots are checked individually against native Terrain.
	local green = Scene.isGreen(x, z)
	if not green then
		for _, offset in ipairs({Vector2.new(-10, -10), Vector2.new(10, -10), Vector2.new(-10, 10), Vector2.new(10, 10)}) do
			if Scene.isGreen(x + offset.X, z + offset.Y) then green = true break end
		end
	end
	if not green then return nil end
	local y = Scene.sample(x, z)
	return {key = ix * count + iz + 1, center = Vector3.new(x, y, z), ix = ix, iz = iz}
end
function Scene.around(point, radius)
	local ix = math.floor((point.X - Scene.Minimum) / Scene.Spacing + 0.5)
	local iz = math.floor((point.Z - Scene.Minimum) / Scene.Spacing + 0.5)
	local steps, cells = math.ceil(radius / Scene.Spacing) + 1, {}
	for x = ix - steps, ix + steps do for z = iz - steps, iz + steps do
		local cell = Scene.cell(x, z)
		if cell and (Vector2.new(cell.center.X - point.X, cell.center.Z - point.Z)).Magnitude <= radius then cells[#cells + 1] = cell end
	end end
	table.sort(cells, function(a, b)
		return (Vector2.new(a.center.X - point.X, a.center.Z - point.Z)).Magnitude < (Vector2.new(b.center.X - point.X, b.center.Z - point.Z)).Magnitude
	end)
	return cells
end
return Scene
]============])
local Terrain=factory([============[local TerrainBuilder = {}
function TerrainBuilder.build(Scene)
	local terrain = workspace.Terrain
	terrain:Clear()
	for _, d in ipairs(terrain:GetChildren()) do d:Destroy() end
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(88, 120, 68))
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(83, 113, 63))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(104, 86, 66))
	terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(84, 75, 58))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(103, 107, 105))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(159, 150, 119))
	local bottom, top, resolution = -64, 152, 4
	local ny = (top - bottom) / resolution
	local chunks, greenColumns, waterColumns, minHeight, maxHeight = 0, 0, 0, math.huge, -math.huge
	for bx = Scene.Minimum, Scene.Maximum - 1, 128 do
		for bz = Scene.Minimum, Scene.Maximum - 1, 128 do
			local materials, occupancy = {}, {}
			for ix = 1, 32 do
				materials[ix], occupancy[ix] = {}, {}
				for iy = 1, ny do materials[ix][iy], occupancy[ix][iy] = {}, {} end
				for iz = 1, 32 do
					local x, z = bx + (ix - 0.5) * resolution, bz + (iz - 0.5) * resolution
					local height, surface, water = Scene.sample(x, z)
					-- Full lower cells keep water continuous with the bed in the single-material voxel API.
					if water > height then height = math.floor(height / resolution) * resolution end
					minHeight, maxHeight = math.min(minHeight, height), math.max(maxHeight, height)
					if Scene.isGreen(x, z) then greenColumns += 1 end
					if water > height then waterColumns += 1 end
					for iy = 1, ny do
						local low = bottom + (iy - 1) * resolution
						local solid = math.clamp((height - low) / resolution, 0, 1)
						if solid > 0 then
							materials[ix][iy][iz] = low > height - 8 and surface or Enum.Material.Rock
							occupancy[ix][iy][iz] = solid
						elseif water > low then
							materials[ix][iy][iz] = Enum.Material.Water
							occupancy[ix][iy][iz] = math.clamp((water - low) / resolution, 0, 1)
						else materials[ix][iy][iz], occupancy[ix][iy][iz] = Enum.Material.Air, 0 end
					end
				end
			end
			terrain:WriteVoxels(Region3.new(Vector3.new(bx, bottom, bz), Vector3.new(bx + 128, top, bz + 128)), resolution, materials, occupancy)
			chunks += 1 task.wait()
		end
	end
	terrain.WaterColor = Color3.fromRGB(65, 116, 120)
	terrain.WaterTransparency = 0.47 terrain.WaterReflectance = 0.42 terrain.WaterWaveSize = 0.08 terrain.WaterWaveSpeed = 6
	pcall(function() terrain.Decoration = true end)
	local clouds = Instance.new("Clouds") clouds.Name = "ForestClouds"
	clouds.Cover = 0.35 clouds.Density = 0.30 clouds.Color = Color3.fromRGB(241, 244, 247) clouds.Parent = terrain
	return {chunks = chunks, greenColumns = greenColumns, waterColumns = waterColumns, minHeight = minHeight, maxHeight = maxHeight,
		size = {1024, top - bottom, 1024}, riverSurface = Scene.RiverY}
end
return TerrainBuilder
]============])
local geometry=factory([============[local Builder = {}
local Asset = game:GetService("AssetService")
local Collection = game:GetService("CollectionService")
local function clear(parent, keep)
	for _, d in ipairs(parent:GetChildren()) do if not keep or not keep[d.Name] then d:Destroy() end end
end
local function strip(model)
	local count = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then count += 1 d:Destroy()
		elseif d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("Camera") then d:Destroy() end
	end
	return count
end
local function bounds(model, filter)
	local lo, hi = Vector3.one * math.huge, Vector3.one * -math.huge
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") and (not filter or filter(p)) then
		for _, x in ipairs({-1, 1}) do for _, y in ipairs({-1, 1}) do for _, z in ipairs({-1, 1}) do
			local v = p.CFrame:PointToWorldSpace(p.Size * Vector3.new(x, y, z) * 0.5)
			lo, hi = lo:Min(v), hi:Max(v)
		end end end
	end end
	return lo, hi
end
function Builder.install(Scene, TerrainBuilder)
	assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155 and game.PlaceVersion == 86, "Wrong forest source place")
	local raw = Asset:LoadAssetAsync(6432306802)
	local pack = assert(raw:FindFirstChild("Forest Pack"), "Official Forest Pack missing")
	local rawGrass = Asset:LoadAssetAsync(87377915371959)
	local grassRoot = assert(rawGrass:FindFirstChild("SkinnedGrass"), "Selected SkinnedGrass missing")
	local skin = grassRoot:FindFirstChild("SkinnedGrass"):Clone()
	local card = grassRoot.GrassCard.Models:FindFirstChildOfClass("Model"):Clone()
	local removed = strip(pack) + strip(card)
	local oldRuntime = assert(game.ReplicatedStorage:FindFirstChild("MonCalamariRuntime"), "Previous wind source missing")
	local wind = oldRuntime.WindEffects:Clone()
	local oldSky = game.Lighting:FindFirstChildOfClass("Sky")
	local sky = oldSky and oldSky:Clone() or Instance.new("Sky")
	for _, d in ipairs(workspace:GetChildren()) do if not d:IsA("Terrain") and not d:IsA("Camera") then d:Destroy() end end
	clear(game.ServerScriptService) clear(game.ServerStorage) clear(game.ReplicatedStorage) clear(game.ReplicatedFirst)
	clear(game.StarterGui) clear(game.StarterPack) clear(game.StarterPlayer.StarterCharacterScripts)
	clear(game.StarterPlayer.StarterPlayerScripts, {PlayerModule = true, RbxCharacterSounds = true, PlayerScriptsLoader = true})
	clear(game.Lighting)
	local runtime = Instance.new("Folder") runtime.Name = "ForestRuntime" runtime.Parent = game.ReplicatedStorage
	wind.Name = "WindEffects" wind:SetAttribute("SourceAssetId", 11946229834) wind.Parent = runtime
	skin.Name = "SkinnedGrass" skin:SetAttribute("SourceAssetId", 87377915371959) skin.Parent = runtime
	local templates = Instance.new("Folder") templates.Name = "SkinnedGrassTemplates" templates.Parent = runtime
	card.Name = "GrassCard"
	local mesh = assert(card:FindFirstChildOfClass("MeshPart"))
	assert(mesh.MeshId == "rbxassetid://117152506140384", "GrassCard asset changed")
	mesh.CFrame = CFrame.identity card.PrimaryPart = nil card.WorldPivot = CFrame.identity card:ScaleTo(0.28)
	mesh.Anchored = true mesh.CanCollide = false mesh.CanQuery = false mesh.CanTouch = false mesh.CastShadow = false
	mesh.Material = Enum.Material.Plastic mesh.Color = Color3.fromRGB(88, 120, 68)
	local appearance = assert(mesh:FindFirstChildOfClass("SurfaceAppearance"), "Native grass appearance missing")
	appearance.Color = mesh.Color
	card:SetAttribute("SourceAssetId", 87377915371959) card:SetAttribute("SourceVariant", "GrassCard") card.Parent = templates
	rawGrass:Destroy()
	sky.Name = "ForestSky" sky.SunAngularSize = 11 sky.Parent = game.Lighting
	for class, name in pairs({Atmosphere = "ForestAtmosphere", ColorCorrectionEffect = "ForestColor", BloomEffect = "ForestBloom", SunRaysEffect = "ForestSunRays"}) do
		local effect = Instance.new(class) effect.Name = name effect.Parent = game.Lighting
	end
	local terrainReport = TerrainBuilder.build(Scene)
	local world = Instance.new("Model") world.Name = "ForestWorld" world.Parent = workspace
	world:SetAttribute("UpgradeVersion", 87) world:SetAttribute("ForestAssetId", 6432306802)
	world:SetAttribute("GrassAssetId", 87377915371959) world:SetAttribute("WindAssetId", 11946229834)
	world:SetAttribute("ForestOnly", true) world:SetAttribute("GrassSpacing", Scene.Spacing)
	world:SetAttribute("RiverSurfaceY", Scene.RiverY)
	local decor = Instance.new("Folder") decor.Name = "Decor" decor.Parent = world
	local trees = Instance.new("Folder") trees.Name = "Trees" trees.Parent = decor
	local plants = Instance.new("Folder") plants.Name = "Plants" plants.Parent = decor
	local rocks = Instance.new("Folder") rocks.Name = "RocksAndLogs" rocks.Parent = decor
	local wildlife = Instance.new("Folder") wildlife.Name = "Wildlife" wildlife.Parent = world
	local animals = Instance.new("Folder") animals.Name = "WildlifeTemplates" animals.Parent = runtime
	for _, name in ipairs({"Butterfly_FlightPath01", "Butterfly_FlightPath02", "Dragonfly_IdleFlight01", "Fish_IdleSwim01"}) do
		local original = assert(pack:FindFirstChild(name)) local copy = original:Clone()
		copy:SetAttribute("SourceAssetId", 6432306802)
		local ids = {Butterfly_FlightPath01 = 6409133522, Butterfly_FlightPath02 = 6409138208, Dragonfly_IdleFlight01 = 6409174269, Fish_IdleSwim01 = 6409186398}
		copy:SetAttribute("AnimationId", ids[name]) copy.Parent = animals
		for _, p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false end end
	end
	local ray = RaycastParams.new() ray.FilterType = Enum.RaycastFilterType.Include ray.FilterDescendantsInstances = {workspace.Terrain}
	ray.RespectCanCollide = true
	local function ground(x, z)
		return workspace:Raycast(Vector3.new(x, 210, z), Vector3.new(0, -310, 0), ray)
	end
	local cache = {}
	local function template(name, tree)
		if cache[name] then return cache[name] end
		local original = assert(pack:FindFirstChild(name), "Missing official template: " .. name)
		local copy = original:Clone()
		for _, d in ipairs(copy:GetDescendants()) do
			if d:IsA("BasePart") and d.Name:lower():find("soil", 1, true) then d:Destroy() end
		end
		local lo, hi = bounds(copy, tree and function(p) return p.Name:lower():find("trunk", 1, true) ~= nil end or nil)
		assert(lo.Y < math.huge, "Template has no ground geometry")
		local base = Vector3.new((lo.X + hi.X) * 0.5, lo.Y, (lo.Z + hi.Z) * 0.5)
		copy:PivotTo(copy:GetPivot() - base)
		copy.PrimaryPart = nil copy.WorldPivot = CFrame.identity
		local allLo, allHi = bounds(copy)
		cache[name] = {model = copy, height = allHi.Y - math.min(0, allLo.Y), width = allHi.X - allLo.X}
		return cache[name]
	end
	local rng = Random.new(Scene.Seed)
	local stats = {trees = 0, plants = 0, rocks = 0, logs = 0, flowers = 0, varieties = {}}
	local occupied = {}
	local function place(name, x, z, targetHeight, parent, kind, yaw)
		local hit = ground(x, z)
		if not hit or hit.Material == Enum.Material.Water or hit.Normal.Y < 0.45 then return nil end
		local src = template(name, kind == "trees")
		local copy = src.model:Clone()
		copy:ScaleTo(math.clamp(targetHeight / src.height, 0.05, 2))
		local rootY = hit.Position.Y
		if kind == "trees" then
			for _, offset in ipairs({Vector2.new(-1.3, 0), Vector2.new(1.3, 0), Vector2.new(0, -1.3), Vector2.new(0, 1.3)}) do
				local h = ground(x + offset.X, z + offset.Y) if h and h.Material ~= Enum.Material.Water then rootY = math.min(rootY, h.Position.Y) end
			end
		end
		local depth = kind == "rocks" and 0.5 or (kind == "trees" and 0.22 or 0.05)
		local pivot = CFrame.new(x, rootY - depth, z) * CFrame.Angles(0, yaw or rng:NextNumber(0, math.pi * 2), 0)
		copy:PivotTo(pivot) copy.Name = name copy.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		copy:SetAttribute("SourceAssetId", 6432306802) copy:SetAttribute("GroundPoint", hit.Position)
		copy:SetAttribute("PlantingPoint", pivot.Position) copy:SetAttribute("Kind", kind) copy.Parent = parent
		for _, p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then
			p.Anchored = true p.CanTouch = false p.CastShadow = true
			p.CanCollide = kind == "rocks" or kind == "logs" p.CanQuery = p.CanCollide
			local lower = p.Name:lower()
			if lower:find("leaf", 1, true) or lower:find("leaves", 1, true) or lower:find("flower", 1, true) or lower:find("fern", 1, true) then
				p:SetAttribute("ForestRestCF", p.CFrame)
				p:SetAttribute("WindPower", kind == "trees" and 0.055 or 0.11)
				Collection:AddTag(p, "ForestWindFoliage")
			end
		end end
		if kind == "trees" then
			local _, box = copy:GetBoundingBox()
			local collider = Instance.new("Part") collider.Name = "TrunkCollision" collider.Shape = Enum.PartType.Cylinder
			collider.Size = Vector3.new(math.clamp(box.Y * 0.28, 6, 16), 2.4, 2.4)
			collider.CFrame = CFrame.new(x, rootY + collider.Size.X / 2, z) * CFrame.Angles(0, 0, math.pi / 2)
			collider.Transparency = 1 collider.Anchored = true collider.CanTouch = false collider.CanCollide = true collider.CanQuery = true collider.Parent = copy
		end
		stats[kind] += 1 stats.varieties[name] = (stats.varieties[name] or 0) + 1
		return copy
	end
	local treeNames = {"RedwoodTree-Var01", "BeechwoodTree_Var03", "BroadLeafTree_Var01", "BeechwoodTree_Var02", "DogwoodTree_Var01", "MapleLeafTreeVar01", "BeechwoodTree_Var01"}
	for attempt = 1, 5200 do
		if stats.trees >= 490 then break end
		local x, z = rng:NextNumber(-408, 408), rng:NextNumber(-376, 376)
		local y, material, water, shore, path, river = Scene.sample(x, z)
		if shore > 0.88 or y < water + 3 or path < 10 or river < Scene.riverWidth(z) + 10 then continue end
		if (Vector2.new(x - Scene.pathX(-250), z + 250)).Magnitude < 15 then continue end
		local near = false
		for _, p in ipairs(occupied) do if (p - Vector2.new(x, z)).Magnitude < 16 then near = true break end end
		if near then continue end
		local name = treeNames[rng:NextInteger(1, #treeNames)]
		if x > 100 and z > 100 and rng:NextNumber() < 0.55 then name = "RedwoodTree-Var01" end
		local height = name == "RedwoodTree-Var01" and rng:NextNumber(43, 76) or rng:NextNumber(23, 53)
		if place(name, x, z, height, trees, "trees") then occupied[#occupied + 1] = Vector2.new(x, z) end
	end
	local plantNames = {"Fern_Var01", "FernTallVar01", "MountainLaurelBush_Var01", "RhododendronVar01", "RhododendronVar02", "CloverPatch", "DenseLeafPatch", "BeechwoodSapling_Var01", "WildFlower01", "Wildflower02", "WildFlower03", "WildFlower04"}
	for attempt = 1, 3400 do
		if stats.plants >= 1650 then break end
		local x, z = rng:NextNumber(-394, 394), rng:NextNumber(-360, 360)
		local y, material, water, shore, path = Scene.sample(x, z)
		if shore > 0.91 or y < water + 0.9 or path < 5.5 or material == Enum.Material.Rock then continue end
		local name = plantNames[rng:NextInteger(1, #plantNames)]
		local h = name:find("Sapling", 1, true) and rng:NextNumber(5, 11) or (name:find("Tall", 1, true) and rng:NextNumber(4, 7) or rng:NextNumber(1.2, 4))
		if name == "DenseLeafPatch" then h = 0.20 elseif name == "CloverPatch" then h = 0.65 end
		local p = place(name, x, z, h, plants, "plants")
		if p and (name:find("Flower", 1, true) or name:find("flower", 1, true) or name:find("Rhododendron", 1, true)) then stats.flowers += 1 end
	end
	for _, point in ipairs({Vector2.new(-130, -240), Vector2.new(-80, -155), Vector2.new(-112, 60), Vector2.new(148, 25), Vector2.new(110, 170)}) do
		for i = 1, 24 do
			local x, z = point.X + rng:NextNumber(-20, 20), point.Y + rng:NextNumber(-20, 20)
			if Scene.pathDistance(x, z) > 5.5 then
				local names = {"RhododendronVar01", "RhododendronVar02", "Fern_Var01", "WildFlower01", "CloverPatch"}
				local name = names[(i - 1) % #names + 1]
				if place(name, x, z, name == "CloverPatch" and 0.6 or rng:NextNumber(1.8, 4.0), plants, "plants") then stats.flowers += 1 end
			end
		end
	end
	local rockNames = {"LargeBoulder_Var01", "MediumBoulderVar01", "MediumMossBoulder01", "SmallRockGroupVar02", "SmallRockVar04"}
	for i = 1, 230 do
		local z = rng:NextNumber(-320, 320)
		local x = i % 2 == 0 and Scene.riverX(z) + rng:NextNumber(18, 38) * (rng:NextNumber() > 0.5 and 1 or -1) or rng:NextNumber(-360, 360)
		if Scene.pathDistance(x, z) > 7 then place(rockNames[(i - 1) % #rockNames + 1], x, z, rng:NextNumber(2, i % 5 == 0 and 14 or 7), rocks, "rocks") end
	end
	for i = 1, 48 do
		local x, z = rng:NextNumber(-350, 350), rng:NextNumber(-315, 315)
		if Scene.pathDistance(x, z) > 9 then
			local names = {"FallenTree", "FallenTreeMossyVar01", "TreeStump", "BranchVar01", "StickVar01", "StickVar04"}
			local name = names[(i - 1) % #names + 1]
			place(name, x, z, name:find("Stick", 1, true) and 0.20 or rng:NextNumber(1.2, 3.8), rocks, "logs")
		end
	end
	local crossings = 0
	for _, z in ipairs({-108, 176}) do
		local x, width = Scene.riverX(z), Scene.riverWidth(z) * 2 + 8
		for _, side in ipairs({-1, 1}) do
			local src = template("FallenTree", false)
			local log = src.model:Clone() log:ScaleTo(width / src.width)
			log:PivotTo(CFrame.new(x, Scene.RiverY - 1, z + side * 2.3)) log.Name = "RiverCrossingLog" log.Parent = rocks
			log:SetAttribute("SourceAssetId", 6432306802) log:SetAttribute("Kind", "crossing") log.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
			for _, p in ipairs(log:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false end end
		end
		local logHeight = template("FallenTree", false).height * width / template("FallenTree", false).width
		local floor = Instance.new("Part") floor.Name = "CrossingCollision" floor.Transparency = 1
		floor.Size = Vector3.new(width + 4, 0.4, 6.8) floor.CFrame = CFrame.new(x, Scene.RiverY - 1 + logHeight - 0.3, z)
		floor.Anchored = true floor.CanCollide = true floor.CanQuery = true floor.CanTouch = false floor.Parent = rocks
		crossings += 1
	end
	for i = 1, 16 do
		local p = Instance.new("Part") p.Name = "WildlifeAnchor" p.Size = Vector3.one p.Transparency = 1
		local z = -270 + (i - 1) * 36 local x = i % 3 == 0 and Scene.riverX(z) or Scene.pathX(z) + 13
		local hit = assert(ground(x, z))
		p.CFrame = CFrame.new(x, i % 3 == 0 and Scene.RiverY + 1 or hit.Position.Y + 3.4, z)
		p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Parent = wildlife
		p:SetAttribute("WildlifeType", i % 3 == 0 and "Dragonfly_IdleFlight01" or (i % 2 == 0 and "Butterfly_FlightPath01" or "Butterfly_FlightPath02"))
		Collection:AddTag(p, "ForestWildlifeAnchor")
	end
	local spawnHit = assert(ground(Scene.pathX(-250), -250), "Forest entry floor missing")
	assert(spawnHit.Material ~= Enum.Material.Water and spawnHit.Normal.Y > 0.65, "Forest entry too steep")
	local spawnCF = CFrame.lookAt(spawnHit.Position + Vector3.new(0, 3.5, 0), spawnHit.Position + Vector3.new(0, 3.5, 12))
	world:SetAttribute("MainSpawnCF", spawnCF) runtime:SetAttribute("MainSpawnCF", spawnCF)
	local spawn = Instance.new("SpawnLocation") spawn.Name = "ForestSpawn" spawn.Size = Vector3.new(6, 0.2, 6)
	spawn.CFrame = CFrame.new(spawnHit.Position) spawn.Transparency = 1 spawn.Anchored = true spawn.CanCollide = false
	spawn.CanQuery = false spawn.CanTouch = false spawn.Neutral = true spawn.Duration = 0 spawn.Parent = world
	world:SetAttribute("TreeCount", stats.trees) world:SetAttribute("PlantCount", stats.plants)
	world:SetAttribute("FlowerCount", stats.flowers) world:SetAttribute("RockCount", stats.rocks) world:SetAttribute("Crossings", crossings)
	workspace.GlobalWind = Vector3.new(7.5, 0, 2.0)
	assert(workspace.StreamingEnabled, "Existing streaming must remain enabled")
	game.Players.CharacterAutoLoads = true game.StarterPlayer.CharacterWalkSpeed = 16 game.StarterPlayer.CharacterJumpPower = 50
	for _, v in pairs(cache) do v.model:Destroy() end raw:Destroy()
	return {forestAsset = 6432306802, grassAsset = 87377915371959, windAsset = 11946229834, removedForeignScripts = removed,
		terrain = terrainReport, vegetation = stats, crossings = crossings, wildlifeAnchors = 16, entry = {spawnCF.X, spawnCF.Y, spawnCF.Z}}
end
return Builder
]============]).install(Scene,Terrain)
local runtime=game.ReplicatedStorage.ForestRuntime
source(runtime,"ModuleScript","Scene",[============[local Scene = {Minimum = -512, Maximum = 512, Spacing = 8, RiverY = 6, SeaY = -8, Seed = 20261013}
local function smooth(a, b, x)
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end
local function gaussian(x, z, cx, cz, radius)
	return math.exp(-((x - cx)^2 + (z - cz)^2) / radius^2)
end
function Scene.riverX(z)
	return 38 * math.sin(z / 115) + 22 * math.sin(z / 57 + 0.7)
end
function Scene.riverWidth(z)
	return 13 + 3 * math.sin(z / 92)^2 + 7 * gaussian(0, z, 0, 150, 64)
end
function Scene.pathX(z)
	return -110 + 47 * math.sin((z + 140) / 140) + 16 * math.sin(z / 62)
end
function Scene.pathDistance(x, z)
	local main = math.abs(x - Scene.pathX(z))
	local east = math.abs(x - (145 + 30 * math.sin(z / 100)))
	local crossing = math.min(math.abs(z + 108), math.abs(z - 176))
	if x > -170 and x < 210 then main = math.min(main, crossing) end
	return math.min(main, east)
end
function Scene.sample(x, z)
	local r = math.sqrt((x / 442)^2 + (z / 405)^2)
	local shore = r + math.noise(x / 95, z / 95, 7) * 0.045
	local interior = 1 - smooth(0.75, 1.05, shore)
	local hill = 70 * gaussian(x, z, 220, 228, 114) + 43 * gaussian(x, z, -256, -174, 128)
		+ 31 * gaussian(x, z, -275, 177, 110) + 24 * gaussian(x, z, 274, -184, 116)
	local detail = 3.1 * math.noise(x / 75, z / 75, 3.17) + 1.5 * math.noise(x / 23, z / 23, 12.47)
	local height = Scene.SeaY - 4 + interior * (29 + hill + detail)
	local rd = math.abs(x - Scene.riverX(z))
	local rw = Scene.riverWidth(z)
	local riverInfluence = (1 - smooth(rw, rw + 34, rd)) * (1 - smooth(337, 401, math.abs(z)))
	local bed = Scene.RiverY - 5 + math.noise(x / 25, z / 45, 2) * 0.5
	height = height * (1 - riverInfluence) + bed * riverInfluence
	local lake = math.sqrt(((x - 39) / 61)^2 + ((z - 157) / 62)^2)
	local lakeInfluence = 1 - smooth(0.65, 1.25, lake)
	height = height * (1 - lakeInfluence) + (Scene.RiverY - 7) * lakeInfluence
	local path = Scene.pathDistance(x, z)
	local material = Enum.Material.Grass
	if shore > 0.94 then material = Enum.Material.Sand
	elseif height > 57 and hill > 45 then material = Enum.Material.Rock
	elseif rd < rw + 7 or lake < 1.25 then material = Enum.Material.Mud
	elseif path < 4.5 and shore < 0.91 then material = Enum.Material.Ground
	elseif math.noise(x / 45, z / 45, 40) > 0.1 then material = Enum.Material.LeafyGrass end
	local water = Scene.SeaY
	if riverInfluence > 0.2 or lakeInfluence > 0.1 then water = Scene.RiverY end
	return height, material, water, shore, path, rd
end
function Scene.isGreen(x, z)
	local y, material, water, shore = Scene.sample(x, z)
	return shore < 0.96 and y > water + 0.5 and (material == Enum.Material.Grass or material == Enum.Material.LeafyGrass)
end
function Scene.cell(ix, iz)
	local count = (Scene.Maximum - Scene.Minimum) / Scene.Spacing + 1
	if ix < 0 or iz < 0 or ix >= count or iz >= count then return nil end
	local x, z = Scene.Minimum + ix * Scene.Spacing, Scene.Minimum + iz * Scene.Spacing
	-- Include the edges of green patches; roots are checked individually against native Terrain.
	local green = Scene.isGreen(x, z)
	if not green then
		for _, offset in ipairs({Vector2.new(-10, -10), Vector2.new(10, -10), Vector2.new(-10, 10), Vector2.new(10, 10)}) do
			if Scene.isGreen(x + offset.X, z + offset.Y) then green = true break end
		end
	end
	if not green then return nil end
	local y = Scene.sample(x, z)
	return {key = ix * count + iz + 1, center = Vector3.new(x, y, z), ix = ix, iz = iz}
end
function Scene.around(point, radius)
	local ix = math.floor((point.X - Scene.Minimum) / Scene.Spacing + 0.5)
	local iz = math.floor((point.Z - Scene.Minimum) / Scene.Spacing + 0.5)
	local steps, cells = math.ceil(radius / Scene.Spacing) + 1, {}
	for x = ix - steps, ix + steps do for z = iz - steps, iz + steps do
		local cell = Scene.cell(x, z)
		if cell and (Vector2.new(cell.center.X - point.X, cell.center.Z - point.Z)).Magnitude <= radius then cells[#cells + 1] = cell end
	end end
	table.sort(cells, function(a, b)
		return (Vector2.new(a.center.X - point.X, a.center.Z - point.Z)).Magnitude < (Vector2.new(b.center.X - point.X, b.center.Z - point.Z)).Magnitude
	end)
	return cells
end
return Scene
]============])
source(runtime,"ModuleScript","Visuals",[============[local Lighting = game:GetService("Lighting")
local Visuals = {}
function Visuals.apply()
	Lighting.LightingStyle = Enum.LightingStyle.Realistic Lighting.PrioritizeLightingQuality = true
	Lighting.GlobalShadows = true Lighting.ShadowSoftness = 0.25
	Lighting.EnvironmentDiffuseScale = 1 Lighting.EnvironmentSpecularScale = 1
	Lighting.Brightness = 2.7 Lighting.ClockTime = 10.2 Lighting.GeographicLatitude = 28
	Lighting.ExposureCompensation = -0.10
	Lighting.Ambient = Color3.fromRGB(47, 56, 57) Lighting.OutdoorAmbient = Color3.fromRGB(99, 119, 121)
	Lighting.ColorShift_Top = Color3.fromRGB(12, 9, 3) Lighting.ColorShift_Bottom = Color3.new()
	Lighting.FogColor = Color3.fromRGB(178, 199, 203) Lighting.FogStart = 200 Lighting.FogEnd = 1800
	local color = Lighting:FindFirstChild("ForestColor")
	if color then color.Enabled = true color.Brightness = 0.01 color.Contrast = 0.13 color.Saturation = 0.10 color.TintColor = Color3.fromRGB(255, 253, 242) end
	local rays = Lighting:FindFirstChild("ForestSunRays")
	if rays then rays.Enabled = true rays.Intensity = 0.075 rays.Spread = 0.77 end
	local bloom = Lighting:FindFirstChild("ForestBloom")
	if bloom then bloom.Enabled = true bloom.Intensity = 0.12 bloom.Size = 18 bloom.Threshold = 1.55 end
	local air = Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Density = 0.27 air.Offset = 0.18 air.Color = Color3.fromRGB(196, 215, 221) air.Decay = Color3.fromRGB(105, 137, 134) air.Haze = 1.1 air.Glare = 0.16 end
end
return Visuals
]============])
source(runtime,"ModuleScript","GrassSampler",[============[local Sampler = {}
function Sampler.new(world)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include params.FilterDescendantsInstances = {workspace.Terrain, world.Decor}
	params.RespectCanCollide = true
	local self = {}
	function self:sample(cell, offsets)
		local heights, sum, valid = {}, 0, 0
		for i, offset in ipairs(offsets) do
			local x, z = cell.center.X + offset.X, cell.center.Z + offset.Z
			local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -300, 0), params)
			if hit and hit.Instance == workspace.Terrain and (hit.Material == Enum.Material.Grass or hit.Material == Enum.Material.LeafyGrass) and hit.Normal.Y > 0.25 then
				heights[i] = hit.Position.Y valid += 1 sum += hit.Position.Y
			end
		end
		return heights, valid > 0 and sum / valid or nil, valid
	end
	return self
end
return Sampler
]============])
source(runtime,"ModuleScript","SkinnedGrass",[============[--[[
	An interactive grass module utilizing skinned meshes
	Made by xander22 (youtube.com/@xand3r22, x.com/x4nder22)
	
	CREDITS:
	
	Octree by Quenty
]]

-- Modules
local Octree = require(script.Octree)  
local utils = require(script.SkinnedGrassUtils)

-- Services
local TweenService = game:GetService("TweenService")

-- default settings, can be overriden at runtime with UpdateSettings()
local DEFAULT_SETTINGS = {
	RenderDistanceEnabled = true, -- If grass should be rendered in/out
	RenderDistance = 100, -- Distance at which grass is fully rendered out --150
	RenderInAnimation = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- TweenInfo to apply to bones rendering in. Set to nil for no animation (more performant)
	RenderOutAnimation = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), -- TweenInfo to apply to bones rendering out. Set to nil for no animation (more performant)
	RenderOutOffset = CFrame.new(0, -3, 0), -- Offset for bones when rendering in/out
	MeshStorage = nil, -- Folder to store meshes that are rendered out. By default creates a folder in ReplicatedStorage

	CollisionsEnabled = true, -- If grass should be simulated with collisions. To disable collisions, set this bool to false rather than setting collision distance to 0
	CollisionDistance = 100, -- Distance at which collisions are simulated
	CollisionRadiusInner = 4, -- Radius around collision where bones are fully displaced
	CollisionRadiusOuter = 6, -- Radius around collision where the displacement effect ends
	CollisionAngle = 90, -- Angle of the displacement effect
	CollisionTranslation = Vector3.new(0, 0, 0), -- Position offset of the displacement effect
	CollisionReturnDelay = 0, -- Time that the grass stays displaced before bouncing back (begins after collision stops)
	CollisionReturnInfo = TweenInfo.new(1.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), -- TweenInfo for the return animation

	WindEnabled = true, -- If grass should be simulated with wind. To disable wind, set this to false rather than setting wind distance to 0
	WindDistanceInner = 10, -- Distance at which wind is simulated with max frame rate
	WindDistanceOuter = 50, -- Distance at which wind is simulated with min frame rate
	WindFramerateInner = 1, -- Frame rate for wind in inner range (1 = 100% frames, 0.5 = 50% frames, etc)
	WindFramerateOuter = 0.25, -- Frame rate for wind in outer range
	WindNoiseSize = 16, -- Size for wind noise calculations
	WindNoiseIntensity = 2, -- Intensity for wind noise calculations
	UseGlobalWind = true, -- When set to true, overrides WindDirection, WindSpeed, WindAngle and WindTranslation settings with Roblox's wind
	WindDirection = Vector3.new(1, 0, 0), -- Direction of the wind effect
	WindSpeed = 8, -- Speed of the wind effect
	WindAngleMin = 35, -- Min angle of the wind effect
	WindAngleMax = 45, -- Max angle of the wind effect
	WindTranslationMin = Vector3.new(0, 0, 0), -- Min position offset of the wind effect
	WindTranslationMax = Vector3.new(0, 0, 0), -- Max position offset of the wind effect
}

local SkinnedGrass = {}
SkinnedGrass.__index = SkinnedGrass

-- initialize new grass object
function SkinnedGrass.new(initialSettings)
	local obj = {
		Settings = {},
		SkinnedMeshesRenderedIn = {},
		MeshParents = {},
        MeshRecords = {},
		MeshTweenOuts = {},
		MeshOctree = {},
		BoneOctree = Octree.new(),
		DisplaceBones = {},
		ReturnBones = {},
		FrameCountInner = 1,
		FrameCountOuter = 1
	}
	setmetatable(obj, SkinnedGrass)
	
	obj.MeshOctree = Octree.new()
	
	obj.Settings = initialSettings or {}
	for i,v in DEFAULT_SETTINGS do
		if obj.Settings[i] == nil then
			obj.Settings[i] = v
		end
	end

	return obj
end

-- updates settings. 'settingsTable' argument should have the same format as DEFAULT_SETTINGS. Leave arguments empty to reset settings to default
function SkinnedGrass:UpdateSettings(settingsTable : {})
	if self.Settings == nil then
		self.Settings = {}
	end

	if settingsTable == nil then
		for i,v in DEFAULT_SETTINGS do
			self.Settings[i] = v
		end
		return
	end
	assert(type(settingsTable) == "table", "Expected table as parameter")

	for i,v in DEFAULT_SETTINGS do
		if settingsTable[i] ~= nil then
			self.Settings[i] = settingsTable[i]
		elseif self.Settings[i] == nil then
			self.Settings[i] = v
		end
	end
end

-- adds meshes to grass object
function SkinnedGrass:AddMeshes(skinnedMeshModels : {Model})
	if typeof(skinnedMeshModels) ~= "table" then warn("AddMeshes() parameter must be a table") return end
	
	if self.MeshFolder == nil then
		local folder = self.Settings.MeshStorage or game.ReplicatedStorage:FindFirstChild("SkinnedGrass_Storage")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "SkinnedGrass_Storage"
			folder.Parent = game.ReplicatedStorage
		end
		self.MeshFolder = folder
	end
	
	for _,model in skinnedMeshModels do
		if not model:IsA("Model") then warn(model, "is not a model") continue end
		if self.MeshParents[model] then continue end -- check if model has already been added to simulation
		local meshPart = model:FindFirstChildOfClass("MeshPart")
		if not meshPart then -- yield thread if meshpart hasn't loaded
			local timeout = 0
			while not meshPart and timeout < 5 do
				meshPart = model:FindFirstChildOfClass("MeshPart")
				timeout += task.wait()
			end
			if not meshPart then
				warn(model, "does not have a loaded mesh part. Consider setting ModelStreamingMode to atomic")
				continue
			end
		end
		-- cache the bones for looping
		local bones = meshPart:GetChildren()
        local record = { mesh = meshPart, bones = {} }
        self.MeshRecords[model] = record
		-- create origin bone for transforming bones en masse
		local originBone = Instance.new("Bone")
		originBone.Parent = meshPart
		originBone.WorldCFrame = meshPart.CFrame
		originBone.Name = "SkinnedGrass_Origin"
		-- loop through each bone and reparent to origin bone
		for _,bone in bones do
			if not bone:IsA("Bone") then continue end
			record.bones[bone] = self.BoneOctree:CreateNode(bone.TransformedWorldCFrame.Position, bone)
			bone.Parent = originBone
		end
		-- set origin bone to below skinned mesh for fade in
		originBone.Transform = self.Settings.RenderDistanceEnabled and CFrame.new(0, -3, 0) or CFrame.identity
        record.origin = originBone
		record.meshNode = self.MeshOctree:CreateNode(originBone.WorldCFrame.Position, meshPart)
		-- store mesh in replicated storage until needed (bones aren't calculated when not in workspace)
		self.MeshParents[model] = model.Parent
		if self.Settings.RenderDistanceEnabled then model.Parent = self.Settings.MeshStorage or self.MeshFolder end
	end
end

-- Proximity streaming releases every octree entry and animation record.
function SkinnedGrass:RemoveMeshes(models)
 for _,model in ipairs(models) do
  local record=self.MeshRecords[model]
  if record then
   for bone,node in pairs(record.bones) do node:Destroy() self.DisplaceBones[bone]=nil self.ReturnBones[bone]=nil end
   record.meshNode:Destroy()
   local index=table.find(self.SkinnedMeshesRenderedIn,record.mesh)
   if index then table.remove(self.SkinnedMeshesRenderedIn,index) end
   index=table.find(self.MeshTweenOuts,record.origin)
   if index then table.remove(self.MeshTweenOuts,index) end
   self.MeshRecords[model]=nil self.MeshParents[model]=nil
  end
 end
end
function SkinnedGrass:Destroy()
 local models={}for model in pairs(self.MeshRecords) do table.insert(models,model) end
 self:RemoveMeshes(models)
 table.clear(self.MeshTweenOuts) table.clear(self.SkinnedMeshesRenderedIn)
end

-- main logic of the module, called every interval. Put in RunService.RenderStepped for smoothest simulation
-- targetPos = position the simulation is based around (ie the player's position)
-- collisions = table of information for the displacement effect
-- each index of collisions should be a Vector3 or a table with the following format: {collisionPos, customSettings}
-- customSettings is a table of custom displacement settings for that collision, follows the same format as DEFAULT_SETTINGS
function SkinnedGrass:Step(deltaTime : number, collisions : {}, targetPos : Vector3)
	if targetPos == nil then -- if no target pos center simulation around player character
		local char = game.Players.LocalPlayer.Character
		if char then
			targetPos = char.PrimaryPart.Position
		else
			return
		end
	end
	local settingsTable = self.Settings
	local meshesToRemove = table.clone(self.SkinnedMeshesRenderedIn)
	if settingsTable.RenderDistanceEnabled then
		local skinnedMeshesInRenderDistance = self.MeshOctree:RadiusSearch(targetPos, settingsTable.RenderDistance)
		for _,v in skinnedMeshesInRenderDistance do
			if table.find(self.SkinnedMeshesRenderedIn, v) == nil then
				table.insert(self.SkinnedMeshesRenderedIn, v)
                local pending=table.find(self.MeshTweenOuts,v.SkinnedGrass_Origin)
                if pending then table.remove(self.MeshTweenOuts,pending)end
				--v.Parent.Parent = workspace
				local model = v:FindFirstAncestorOfClass("Model")
				if not model then continue end
				model.Parent = self.MeshParents[model]
				--print("spawn mesh", v)
				if settingsTable.RenderInAnimation then
					TweenService:Create(v.SkinnedGrass_Origin, settingsTable.RenderInAnimation, { Transform = CFrame.new(0, 0, 0) }):Play()
				else
					v.SkinnedGrass_Origin.Transform = CFrame.new(0, 0, 0)
				end		
			end
			local removeIndex=table.find(meshesToRemove,v)
            if removeIndex then table.remove(meshesToRemove,removeIndex)end
		end
		for _,v in meshesToRemove do
			table.remove(self.SkinnedMeshesRenderedIn, table.find(self.SkinnedMeshesRenderedIn, v))
			if settingsTable.RenderOutAnimation then
				TweenService:Create(v.SkinnedGrass_Origin, settingsTable.RenderOutAnimation, { Transform = settingsTable.RenderOutOffset }):Play()
				table.insert(self.MeshTweenOuts, v.SkinnedGrass_Origin)
			else
				local model = v:FindFirstAncestorOfClass("Model")
				model.Parent = settingsTable.MeshStorage
			end
		end
		for i,v in self.MeshTweenOuts do
			if (v.Transform.Position - settingsTable.RenderOutOffset.Position).Magnitude <= 0 then
				table.remove(self.MeshTweenOuts, i)
				v:FindFirstAncestorOfClass("Model").Parent = settingsTable.MeshStorage
			end
		end
	end
	
	local transformedBones = {}
	
	local windDir = game.Workspace.GlobalWind
	if not settingsTable.UseGlobalWind then
		windDir = settingsTable.WindDirection
	end
	if windDir.Magnitude == 0 then windDir = Vector3.new(0, 0, 1) end
	local windIntensity = math.min(game.Workspace.GlobalWind.Magnitude, 20) * (settingsTable.WindStrengthScale or 1)
	self.FrameCountInner += 1
	if self.FrameCountInner >= 1 / settingsTable.WindFramerateInner then self.FrameCountInner = 1 end
	self.FrameCountOuter += 1
	if self.FrameCountOuter >= 1 / settingsTable.WindFramerateOuter then self.FrameCountOuter = 1 end
	
	if self.WindAnimation == nil or self.WindAnimation >= 1 then
		self.WindAnimation = 0
	end
	local windSpeed = 1 + windIntensity / 20
	if not settingsTable.UseGlobalWind then
		windSpeed = 1 + settingsTable.WindSpeed / 20
	end
	self.WindAnimation += deltaTime * windSpeed
	local minAngle = 0
	local maxAngle = 0
	local minTranslation = Vector3.zero
	local maxTranslation = Vector3.zero
	if self.Settings.WindEnabled then
		minAngle = math.max(windIntensity * 2, -2)
		maxAngle = math.max(windIntensity * 3, 2)
		if not settingsTable.UseGlobalWind then
			minAngle = settingsTable.WindAngleMin
			maxAngle = settingsTable.WindAngleMax
			minTranslation = settingsTable.WindTranslationMin
			maxTranslation = settingsTable.WindTranslationMax
		end
		if self.FrameCountInner == 1 then
			local bonesInWindDistance = self.BoneOctree:RadiusSearch(targetPos, self.Settings.WindDistanceInner)
			for i = 1, #bonesInWindDistance do
				local bone = bonesInWindDistance[i]
				local windCFrame = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = windCFrame
			end
		end
		if self.FrameCountOuter == 1 then
			local bonesInWindDistanceOuter = self.BoneOctree:RadiusSearch(targetPos, self.Settings.WindDistanceOuter)
			for i = 1, #bonesInWindDistanceOuter do
				local bone = bonesInWindDistanceOuter[i]
				local windCFrame = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = windCFrame
			end
		end
	end

	if settingsTable.CollisionsEnabled and collisions then
		local collisionsInRange = {}
		for _,collision in collisions do
			local pos, customSettings
			if typeof(collision) == "table" then
				pos = collision[1]
				customSettings = collision[2]
			else
				pos = collision
				customSettings = {}
			end
			if (pos - targetPos).Magnitude > settingsTable.CollisionDistance then continue end -- outside of the collision sim distance
			local collisionSettings = table.clone(settingsTable)
			for key,value in customSettings do -- custom settings
				if collisionSettings[key] then
					collisionSettings[key] = value
				end
			end

			local bonesInCollisionDistance = self.BoneOctree:RadiusSearch(pos, collisionSettings.CollisionRadiusOuter - 0.1) --slight offset to prevent return starting instantly
			local displaceFadeRange : number = collisionSettings.CollisionRadiusOuter - collisionSettings.CollisionRadiusInner 
			for _,bone in bonesInCollisionDistance do
				table.insert(transformedBones, bone)

				local displaceInfo = self.DisplaceBones[bone]
				if displaceInfo == nil then --first time calculating, set target rotation and displace percent
					displaceInfo = {}
					displaceInfo[1] = collisionSettings --settings
					displaceInfo[2] = self.ReturnBones[bone] and self.ReturnBones[bone][2] or 0 --displace percent

					local offset = bone.TransformedWorldCFrame.Position - pos
                    local directionToKnock = offset.Magnitude > .001 and offset.Unit or Vector3.new(1,0,0)
					local localKnockDirection = bone.WorldCFrame:VectorToObjectSpace(directionToKnock)

					-- Preserve the current Y rotation, only affect X and Z
					local _, currentYRotation, _ = bone.Transform:ToOrientation() -- Extract the Y rotation

					local horizontal = Vector3.new(localKnockDirection.X, 0, localKnockDirection.Z)
                    local tiltDirection = horizontal.Magnitude > .001 and horizontal.Unit or Vector3.new(1,0,0)

					-- Knock the bone over by tilting it based on the knock intensity
					local tiltAngle = math.rad(settingsTable.CollisionAngle)
					local newXRotation = tiltAngle * tiltDirection.Z -- Tilt along X based on Z direction
					local newZRotation = -tiltAngle * tiltDirection.X -- Tilt along Z based on X direction
					local newTranslation = settingsTable.CollisionTranslation
					-- Set the new orientation while preserving the Y rotation
					local targetCFrame = (bone:GetAttribute("SerenaTerrainOffset") or CFrame.identity) * CFrame.new(newTranslation) * CFrame.Angles(newXRotation, currentYRotation, newZRotation)
					displaceInfo[4] = targetCFrame
				end

				-- calculate displacement percentage by checking where the bone is at between the displacement radius inner and displacement radius outer
				local distFromOrigin : number = ((bone:GetAttribute("SerenaGroundPoint") or bone.WorldCFrame.Position) - pos).Magnitude
				local range = math.min(1 - (distFromOrigin - collisionSettings.CollisionRadiusInner) / displaceFadeRange, 1)
				if range > displaceInfo[2] then --displace amount can only go up, not down (out animation handled by return table)
					displaceInfo[2] = range --percent displaced, 0 = no displacement, 1 = full displacement
				end
				displaceInfo[3] = range
				self.DisplaceBones[bone] = displaceInfo
				self.ReturnBones[bone] = nil

			end

		end

		for bone,displaceInfo in self.DisplaceBones do
			local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
			-- Keep the terrain translation fixed while blades bend. Rotating or
			-- scaling that translation lifts roots off slopes during partial contact.
			bone.Transform = windRot:Lerp(displaceInfo[4], math.clamp(displaceInfo[2], 0, 1))

			if displaceInfo[3] <= 0 or table.find(transformedBones, bone) == nil then --out of range, do return
				local returnInfo = {}
				returnInfo[1] = displaceInfo[1] --settings
				returnInfo[2] = displaceInfo[2] --percent displaced
				returnInfo[3] = tick() --time of displacement leaving range
				returnInfo[4] = bone.Transform -- cframe to lerp from
				self.ReturnBones[bone] = returnInfo
				self.DisplaceBones[bone] = nil
				continue
			end
		end

		for bone,returnInfo in self.ReturnBones do
			local collisionSettings = returnInfo[1]
			local timeSinceCollision = tick() - returnInfo[3]
			if timeSinceCollision < collisionSettings.CollisionReturnDelay then 
				local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
				bone.Transform = returnInfo[4]
				continue
			end
			local returnTweenInfo : TweenInfo = collisionSettings.CollisionReturnInfo
			if timeSinceCollision >= collisionSettings.CollisionReturnDelay + returnTweenInfo.Time then 
				self.ReturnBones[bone] = nil
				continue
			end

			local percentReturned = (timeSinceCollision - collisionSettings.CollisionReturnDelay) / returnTweenInfo.Time
			local tweenValue = TweenService:GetValue(percentReturned, returnTweenInfo.EasingStyle, returnTweenInfo.EasingDirection)
			returnInfo[2] = 1 - tweenValue
			local windRot = utils.CalculateWindAtPoint(bone, self.WindAnimation, windDir, minAngle, maxAngle, minTranslation, maxTranslation, settingsTable.WindNoiseSize, settingsTable.WindNoiseIntensity)
			local newRot = returnInfo[4]:lerp(windRot, tweenValue)
			
			bone.Transform = CFrame.new(Vector3.zero) * newRot
		end
	end

end

return SkinnedGrass
]============])
source(runtime.SkinnedGrass,"ModuleScript","SkinnedGrassUtils",[============[local module = {}

local TweenService = game:GetService("TweenService")

-- wind
local function Noise(x, y, z, size, intensity)
	size = size or 1
	intensity = intensity or 1

	local scaledX = x / size
	local scaledY = y / size
	local scaledZ = z / size

	local noiseValue = math.noise(scaledX, scaledY, scaledZ) * intensity

	return noiseValue
end
function module.CalculateWindAtPoint(bone : Bone, animationPercent : number, windDirection : Vector3, minAngle : number, maxAngle : number, minTranslation : Vector3, maxTranslation : Vector3, windSize : number, windIntensity : number)
	local noise = Noise(bone.WorldCFrame.Position.X, 0, bone.WorldCFrame.Position.Z, windSize, windIntensity)
	local windAnimationLooped = 1 - math.abs(((animationPercent + noise) % 1) * 2 - 1)
	local windIntensity = minAngle + (maxAngle - minAngle) * TweenService:GetValue(windAnimationLooped, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local parentRotation = bone.Parent.Parent.CFrame
	local modifiedWindDirection = parentRotation:VectorToObjectSpace(windDirection) -- convert wind direction to skinned mesh local space
	local localWindDirection = bone.CFrame:VectorToObjectSpace(modifiedWindDirection)
	local horizontal = Vector3.new(localWindDirection.X, 0, localWindDirection.Z)
	local tiltDirection = horizontal.Magnitude > .001 and horizontal.Unit or Vector3.new(1,0,0)

	-- Knock the bone over by tilting it based on the knock intensity
	local tiltAngle = math.rad(windIntensity)
	local newXRotation = tiltAngle * tiltDirection.Z -- Tilt along X based on Z direction
	local newZRotation = -tiltAngle * tiltDirection.X -- Tilt along Z based on X direction

	local targetOrientation = CFrame.Angles(newXRotation, 0, newZRotation)
	local targetTranslation = CFrame.new(minTranslation + (maxTranslation - minTranslation) * TweenService:GetValue(windAnimationLooped, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
	return (bone:GetAttribute("SerenaTerrainOffset") or CFrame.identity) * targetOrientation * targetTranslation
end

return module
]============])
source(game.ServerScriptService,"Script","ForestServer",[============[local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
require(runtime:WaitForChild("Visuals")).apply()
local world = workspace:WaitForChild("ForestWorld")
local spawn = world:WaitForChild("ForestSpawn")
local spawnCF = runtime:GetAttribute("MainSpawnCF")
local function character(player, model)
	local humanoid = model:WaitForChild("Humanoid", 10) local root = model:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= model then return end
	root.Anchored = false humanoid.PlatformStand = false humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16 humanoid.UseJumpPower = true humanoid.JumpPower = 50
	if (root.Position - spawnCF.Position).Magnitude > 28 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero end
end
local function playerAdded(player)
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(model) character(player, model) end)
	if player.Character then task.spawn(character, player, player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt if elapsed < 1 then return end elapsed = 0
	local time = workspace:GetServerTimeNow()
	local strength = 7.5 + math.sin(time * 0.047) * 0.6 + math.sin(time * 0.023) * 0.35
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestAmbienceClient",[============[local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Collection = game:GetService("CollectionService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
require(runtime:WaitForChild("Visuals")).apply()
while not workspace.CurrentCamera do Run.Heartbeat:Wait() end
local WindLines = require(runtime.WindEffects:WaitForChild("WindLines"))
local WindShake = require(runtime.WindEffects:WaitForChild("WindShake"))
local function foliage(part)
	if part:IsA("BasePart") then Collection:AddTag(part, "WindShake") end
end
for _, part in ipairs(Collection:GetTagged("ForestWindFoliage")) do foliage(part) end
local added = Collection:GetInstanceAddedSignal("ForestWindFoliage"):Connect(foliage)
local removed = Collection:GetInstanceRemovedSignal("ForestWindFoliage"):Connect(function(p) Collection:RemoveTag(p, "WindShake") end)
WindLines:Init({Direction = workspace.GlobalWind.Unit, Speed = 10, Lifetime = 2, SpawnRate = UIS.TouchEnabled and 5 or 8})
WindShake:SetDefaultSettings({WindDirection = workspace.GlobalWind.Unit, WindSpeed = 10, WindPower = 0.07})
WindShake:Init()
local animals = {}
local localFolder = Instance.new("Folder") localFolder.Name = "ForestLocalWildlife" localFolder.Parent = workspace
local function addAnimal(anchor)
	if not anchor:IsA("BasePart") or animals[anchor] then return end
	animals[anchor] = {anchor = anchor, model = nil, rest = anchor.CFrame}
end
local function removeAnimal(anchor)
	local entry = animals[anchor] if not entry then return end
	if entry.track then entry.track:Stop(0) end
	if entry.model then entry.model:Destroy() end animals[anchor] = nil
end
for _, a in ipairs(Collection:GetTagged("ForestWildlifeAnchor")) do addAnimal(a) end
local animalAdded = Collection:GetInstanceAddedSignal("ForestWildlifeAnchor"):Connect(addAnimal)
local animalRemoved = Collection:GetInstanceRemovedSignal("ForestWildlifeAnchor"):Connect(removeAnimal)
local function activate(entry)
	local template = runtime.WildlifeTemplates:FindFirstChild(entry.anchor:GetAttribute("WildlifeType"))
	if not template then return end
	local model = template:Clone() model:PivotTo(entry.rest) model.Parent = localFolder entry.model = model
	local controller = model:FindFirstChildOfClass("AnimationController")
	local animator = controller and controller:FindFirstChildOfClass("Animator")
	if animator then
		task.spawn(function()
			local animation = Instance.new("Animation") animation.AnimationId = "rbxassetid://" .. template:GetAttribute("AnimationId")
			local ok, track = pcall(function() return animator:LoadAnimation(animation) end) animation:Destroy()
			if ok and entry.model == model then track.Looped = true track:Play(0.3, 1, 1) entry.track = track end
		end)
	end
end
local elapsed, scan = 0, 0
local step = Run.Heartbeat:Connect(function(dt)
	elapsed += dt scan += dt
	if elapsed < 1 / 24 then return end elapsed = 0
	local camera = workspace.CurrentCamera if not camera then return end
	local now = workspace:GetServerTimeNow()
	if scan > 0.5 then
		scan = 0 local wind = workspace.GlobalWind
		if wind.Magnitude > 0.01 then WindLines.Direction = wind.Unit end
		WindLines.Speed = math.clamp(wind.Magnitude * 1.2, 6, 13)
		WindShake:SetDefaultSettings({WindDirection = wind.Unit, WindSpeed = WindLines.Speed, WindPower = 0.07})
	end
	local active = 0
	for _, entry in pairs(animals) do
		local distance = (entry.rest.Position - camera.CFrame.Position).Magnitude
		if distance < 65 and active < (UIS.TouchEnabled and 4 or 8) then
			active += 1 if not entry.model then activate(entry) end
			if entry.model then
				local phase = entry.rest.Z * 0.07
				entry.model:PivotTo(entry.rest + Vector3.new(math.sin(now * 0.4 + phase) * 1.8, math.sin(now * 0.65 + phase) * 0.45, math.cos(now * 0.45 + phase) * 1.3))
			end
		elseif entry.model then
			if entry.track then entry.track:Stop(0) entry.track = nil end
			entry.model:Destroy() entry.model = nil
		end
	end
end)
script.Destroying:Connect(function()
	step:Disconnect() added:Disconnect() removed:Disconnect() animalAdded:Disconnect() animalRemoved:Disconnect()
	WindLines:Cleanup() WindShake:Cleanup()
	for anchor in pairs(animals) do removeAnimal(anchor) end localFolder:Destroy()
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestGrassClient",[============[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")local UIS=game:GetService("UserInputService")
local runtime=RS:WaitForChild("ForestRuntime")local player=Players.LocalPlayer local world=workspace:WaitForChild("ForestWorld")
local Field=require(runtime:WaitForChild("Scene"))local Skinned=require(runtime:WaitForChild("SkinnedGrass"))
local sampler=require(runtime:WaitForChild("GrassSampler")).new(world)
local field={around=function(_,p,r)return Field.around(p,r)end,regionCount=1}
local template=runtime.SkinnedGrassTemplates.GrassCard local templateMesh=template:FindFirstChildOfClass("MeshPart")local sourceBones={}local offsets={}
for _,b in ipairs(templateMesh:GetChildren())do if b:IsA("Bone")then sourceBones[#sourceBones+1]=b end end
table.sort(sourceBones,function(a,b)return a.Name<b.Name end)
for i,b in ipairs(sourceBones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)end
local visible=Instance.new("Folder")visible.Name="ForestInteractiveGrass"visible.Parent=workspace
local storage=Instance.new("Folder")storage.Name="ForestGrassLocalStorage"storage.Parent=RS
local touch=UIS.TouchEnabled local radius=touch and 52 or 84
local maxActive=touch and 160 or 360 local keep=radius+6
local grass=Skinned.new({RenderDistanceEnabled=false,MeshStorage=storage,CollisionDistance=30,
 CollisionRadiusInner=1.2,CollisionRadiusOuter=3.2,CollisionAngle=68,CollisionReturnDelay=.08,
 CollisionReturnInfo=TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
 WindDistanceInner=touch and 12 or 18,WindDistanceOuter=touch and 28 or 42,
 WindFramerateInner=1,WindFramerateOuter=.25,UseGlobalWind=true,WindStrengthScale=.82})
local active={}local empty={}local count=0 local queue={}local cursor=1 local refresh=1 local stepTime=0 local destroyed=false
local function rootOf(p)local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")if h and h.Health>0 and r then return r,h end end
local function add(cell)
 local heights,anchor,valid=sampler:sample(cell,offsets)
 if not anchor then empty[cell.key]=os.clock()+2 return end
 local model=template:Clone()model.Name="Grass"..cell.key model:PivotTo(CFrame.new(cell.center.X,anchor,cell.center.Z))model.Parent=visible
 local mesh=model:FindFirstChildOfClass("MeshPart")local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
 for i,b in ipairs(bones)do
  local original=b.WorldCFrame.Position local height=heights[i]
  local point=height and Vector3.new(original.X,height-.045,original.Z)or(original-Vector3.new(0,240,0))
  local offset=CFrame.new(b.WorldCFrame:VectorToObjectSpace(point-original))
  b:SetAttribute("SerenaTerrainOffset",offset)b:SetAttribute("SerenaGroundPoint",point)b:SetAttribute("SerenaGreenRoot",height~=nil)b.Transform=offset
 end
 grass:AddMeshes({model})active[cell.key]={model=model,cell=cell,roots=valid}count+=1
end
local function remove(key)local entry=active[key]if not entry then return end grass:RemoveMeshes({entry.model})entry.model:Destroy()active[key]=nil count-=1 end
local stream=world.DescendantAdded:Connect(function(p)if p:IsA("BasePart")then refresh=1 table.clear(empty)end end)
player:SetAttribute("SerenaGrassCoverageRegions",field.regionCount)player:SetAttribute("SerenaWholeMapGrassReady",true)
local heartbeat=Run.Heartbeat:Connect(function(dt)
 if destroyed then return end local root=rootOf(player)if not root then return end refresh+=dt
 if refresh>=.25 then
  refresh=0
  for k,entry in pairs(active)do local dx,dz=entry.cell.center.X-root.Position.X,entry.cell.center.Z-root.Position.Z if dx*dx+dz*dz>keep*keep then remove(k)end end
  queue={}cursor=1 local now=os.clock()
  for _,cell in ipairs(field:around(root.Position,radius))do if not active[cell.key]and(not empty[cell.key]or empty[cell.key]<now)then queue[#queue+1]=cell end end
  for k,t in pairs(empty)do if now>t+4 then empty[k]=nil end end
 end
 local started=os.clock()local budget=touch and 4 or 8
 for _=1,budget do
  local cell=queue[cursor]if not cell or count>=maxActive then break end cursor+=1
  if not active[cell.key]then add(cell)end
  if os.clock()-started>(touch and .003 or .005)then break end
 end
 player:SetAttribute("SerenaGrassLoadedPatches",count)player:SetAttribute("SerenaGrassNearbyReady",cursor>#queue)
end)
local rendered=Run.RenderStepped:Connect(function(dt)
 if destroyed then return end stepTime+=dt if stepTime<(touch and 1/24 or 1/30)then return end local step=math.min(stepTime,.1)stepTime=0
 local root=rootOf(player)if not root then return end local actors={}
 for _,p in ipairs(Players:GetPlayers())do local r,h=rootOf(p)if r and(r.Position-root.Position).Magnitude<30 then
  local feet=r.Position.Y-(h.RigType==Enum.HumanoidRigType.R6 and 3 or h.HipHeight+r.Size.Y/2)actors[#actors+1]=Vector3.new(r.Position.X,feet+.1,r.Position.Z)
 end end grass:Step(step,actors,root.Position)
end)
script.Destroying:Connect(function()destroyed=true heartbeat:Disconnect()rendered:Disconnect()stream:Disconnect()grass:Destroy()visible:Destroy()storage:Destroy()table.clear(active)table.clear(empty)end)
]============])
require(runtime.Visuals).apply()
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
local baseVersion=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,baseVersion=baseVersion,expectedVersion=87,geometry=geometry,tests=tests}
