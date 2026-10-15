local Builder = {}
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
