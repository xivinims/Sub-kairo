assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==87,"Published base changed")
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
local Scene=factory([============[local Scene = {Minimum = -512, Maximum = 512, Spacing = 4, RiverY = 6, SeaY = 6, Seed = 20261013}
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
	local height = -12 + interior * (29 + hill + detail)
	local rd = math.abs(x - Scene.riverX(z))
	local rw = Scene.riverWidth(z)
	local riverInfluence = (1 - smooth(rw - 2, rw + 28, rd)) * (1 - smooth(337, 401, math.abs(z)))
	local bed = Scene.RiverY - 6.5 + math.noise(x / 45, z / 65, 2) * 0.30
	height = height * (1 - riverInfluence) + bed * riverInfluence
	local lake = math.sqrt(((x - 39) / 61)^2 + ((z - 157) / 62)^2)
	local lakeInfluence = 1 - smooth(0.65, 1.25, lake)
	height = height * (1 - lakeInfluence) + (Scene.RiverY - 7) * lakeInfluence
	local path = Scene.pathDistance(x, z)
	local material = Enum.Material.Grass
	if shore > 0.94 then material = Enum.Material.Sand
	elseif height > 57 and hill > 45 then material = Enum.Material.Rock
	elseif height < Scene.RiverY + 1.5 and (rd < rw + 10 or lake < 1.25) then material = Enum.Material.Mud
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
	-- Dense cells overlap the actual bone footprint, including both sides of material edges.
	local green = Scene.isGreen(x, z)
	if not green then
		for _, offset in ipairs({Vector2.new(-5, -5), Vector2.new(5, -5), Vector2.new(-5, 5), Vector2.new(5, 5),Vector2.new(0,-5),Vector2.new(0,5),Vector2.new(-5,0),Vector2.new(5,0)}) do
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
			local materials, occupancy, liquid = {}, {}, {}
			for ix = 1, 32 do
				materials[ix], occupancy[ix], liquid[ix] = {}, {}, {}
				for iy = 1, ny do materials[ix][iy], occupancy[ix][iy], liquid[ix][iy] = {}, {}, {} end
				for iz = 1, 32 do
					local x, z = bx + (ix - 0.5) * resolution, bz + (iz - 0.5) * resolution
					local height, surface, water = Scene.sample(x, z)
					-- Separate liquid/solid channels preserve smooth banks and avoid air gaps above partial river-bed cells.
					minHeight, maxHeight = math.min(minHeight, height), math.max(maxHeight, height)
					if Scene.isGreen(x, z) then greenColumns += 1 end
					if water > height then waterColumns += 1 end
					for iy = 1, ny do
						local low = bottom + (iy - 1) * resolution
						local solid = math.clamp((height - low) / resolution, 0, 1)
						if solid > 0 then
							materials[ix][iy][iz] = low > height - 8 and surface or Enum.Material.Rock
							occupancy[ix][iy][iz] = solid
						else materials[ix][iy][iz], occupancy[ix][iy][iz] = Enum.Material.Air, 0 end
						liquid[ix][iy][iz] = solid < 1 and math.clamp((water - low) / resolution, 0, 1) or 0
					end
				end
			end
			terrain:WriteVoxelChannels(Region3.new(Vector3.new(bx, bottom, bz), Vector3.new(bx + 128, top, bz + 128)), resolution,
				{SolidMaterial=materials,SolidOccupancy=occupancy,LiquidOccupancy=liquid})
			chunks += 1 task.wait()
		end
	end
	terrain.WaterColor = Color3.fromRGB(49, 100, 106)
	terrain.WaterTransparency = 0.34 terrain.WaterReflectance = 0.20 terrain.WaterWaveSize = 0.055 terrain.WaterWaveSpeed = 7
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
	assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155 and game.PlaceVersion == 87, "Wrong forest source place")
	local raw = Asset:LoadAssetAsync(6432306802)
	local pack = assert(raw:FindFirstChild("Forest Pack"), "Official Forest Pack missing")
	local rawGrass = Asset:LoadAssetAsync(87377915371959)
	local grassRoot = assert(rawGrass:FindFirstChild("SkinnedGrass"), "Selected SkinnedGrass missing")
	local skin = grassRoot:FindFirstChild("SkinnedGrass"):Clone()
	local card = grassRoot.GrassCard.Models:FindFirstChildOfClass("Model"):Clone()
	local removed = strip(pack) + strip(card)
	local oldRuntime = assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"), "Previous wind source missing")
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
	-- The supplied mesh is 100 studs wide but its 100 bone roots occupy only 14 studs.
	-- Fit the card to that root grid before scaling, rather than using the oversized mesh bounds as coverage.
	mesh.Size = Vector3.new(17.5, 3.5, 17.5)
	mesh.CFrame = CFrame.new(0,1.75,0) card.PrimaryPart = nil card.WorldPivot = CFrame.identity card:ScaleTo(0.40)
	mesh.Anchored = true mesh.CanCollide = false mesh.CanQuery = false mesh.CanTouch = false mesh.CastShadow = false
	mesh.Material = Enum.Material.Plastic mesh.Color = Color3.fromRGB(88, 120, 68)
	local appearance = assert(mesh:FindFirstChildOfClass("SurfaceAppearance"), "Native grass appearance missing")
	appearance.Color = mesh.Color
	card:SetAttribute("SourceAssetId", 87377915371959) card:SetAttribute("SourceVariant", "GrassCard")
	card:SetAttribute("BladeBaseOffset",0.66) card:SetAttribute("PlanarFootprint",7) card.Parent = templates
	rawGrass:Destroy()
	sky.Name = "ForestSky" sky.SunAngularSize = 11 sky.Parent = game.Lighting
	for class, name in pairs({Atmosphere = "ForestAtmosphere", ColorCorrectionEffect = "ForestColor", BloomEffect = "ForestBloom", SunRaysEffect = "ForestSunRays"}) do
		local effect = Instance.new(class) effect.Name = name effect.Parent = game.Lighting
	end
	local terrainReport = TerrainBuilder.build(Scene)
	local world = Instance.new("Model") world.Name = "ForestWorld" world.Parent = workspace
	world:SetAttribute("UpgradeVersion", 88) world:SetAttribute("ForestAssetId", 6432306802)
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
	local groundProfiles=Instance.new("Folder")groundProfiles.Name="GroundingProfiles"groundProfiles.Parent=runtime
	local importProbe = Instance.new("Folder") importProbe.Name="ForestGroundingProbe" importProbe.Parent=workspace
	local function template(name, tree)
		if cache[name] then return cache[name] end
		local original = assert(pack:FindFirstChild(name), "Missing official template: " .. name)
		local copy = original:Clone()
		for _, d in ipairs(copy:GetDescendants()) do
			if d:IsA("BasePart") and d.Name:lower():find("soil", 1, true) then d:Destroy() end
		end
		local lo, hi = bounds(copy, tree and function(p) return p.Name:lower():find("trunk", 1, true) ~= nil end or nil)
		assert(lo.Y < math.huge, "Template has no ground geometry")
		-- Find the lower contact geometry, which can be offset from the centre of a branching trunk.
		-- Artist bounds alone are insufficient on sloping terrain.
		copy.Parent=importProbe
		for _,p in ipairs(copy:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=not tree or p.Name:lower():find("trunk",1,true)~=nil p.CanTouch=false end end
		task.wait()
		local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={copy}
		local contacts={}local minimum=math.huge
		for ix=0,24 do for iz=0,24 do
			local x,z=lo.X+(hi.X-lo.X)*(ix+.5)/25,lo.Z+(hi.Z-lo.Z)*(iz+.5)/25
			local hit=workspace:Raycast(Vector3.new(x,lo.Y-2,z),Vector3.new(0,math.max(3,(hi.Y-lo.Y)*.20+3),0),params)
			if hit then contacts[#contacts+1]=hit.Position minimum=math.min(minimum,hit.Position.Y)end
		end end
		local sum,n=Vector3.zero,0
		for _,p in ipairs(contacts)do if p.Y<=minimum+.30 then sum+=p n+=1 end end
		local base = n>0 and Vector3.new(sum.X/n,minimum,sum.Z/n) or Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)
		local support={Vector3.zero}local lowContacts={}
		for _,p in ipairs(contacts)do if p.Y<=minimum+.30 then lowContacts[#lowContacts+1]=p-base end end
		local take=math.min(23,#lowContacts)
		for i=1,take do local index=take==1 and 1 or math.floor(1+(i-1)*(#lowContacts-1)/(take-1))support[#support+1]=lowContacts[index]end
		copy:PivotTo(copy:GetPivot() - base)
		copy.PrimaryPart = nil copy.WorldPivot = CFrame.identity
		copy.Parent=nil
		local allLo, allHi = bounds(copy)
		cache[name] = {model = copy, height = allHi.Y - math.min(0, allLo.Y), width = allHi.X - allLo.X,support=support,contactProbes=n}
		local profile=Instance.new("Folder")profile.Name=name profile.Parent=groundProfiles
		for i,point in ipairs(support)do local value=Instance.new("Vector3Value")value.Name=tostring(i)value.Value=point value.Parent=profile end
		return cache[name]
	end
	local rng = Random.new(Scene.Seed)
	local stats = {trees = 0, plants = 0, rocks = 0, logs = 0, flowers = 0, varieties = {}}
	local occupied = {}
	local function place(name, x, z, targetHeight, parent, kind, yaw)
		local hit = ground(x, z)
		if not hit or hit.Material == Enum.Material.Water or hit.Normal.Y < (kind=="plants" and .72 or .65) then return nil end
		local src = template(name, kind == "trees")
		local copy = src.model:Clone()
		local scale=math.clamp(targetHeight/src.height,.05,3) copy:ScaleTo(scale)
		local rotation=CFrame.Angles(0,yaw or rng:NextNumber(0,math.pi*2),0)
		if kind=="plants" or kind=="logs" then
			local up=hit.Normal local right=rotation.RightVector-up*rotation.RightVector:Dot(up)
			if right.Magnitude>.1 then right=right.Unit rotation=CFrame.fromMatrix(Vector3.zero,right,up,right:Cross(up))end
		end
		local rootY = hit.Position.Y
		local tested=0
		for _,point in ipairs(src.support)do
			local offset=rotation:VectorToWorldSpace(point*scale)
			local h=ground(x+offset.X,z+offset.Z)
			if h and h.Material~=Enum.Material.Water then rootY=math.min(rootY,h.Position.Y-offset.Y) tested+=1 end
		end
		local depth = kind == "rocks" and .65 or (kind == "trees" and .45 or .13)
		local pivot = CFrame.new(x, rootY - depth, z)*rotation
		copy:PivotTo(pivot) copy.Name = name copy.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		copy:SetAttribute("SourceAssetId", 6432306802) copy:SetAttribute("GroundPoint", hit.Position)
		copy:SetAttribute("PlantingPoint", pivot.Position) copy:SetAttribute("Kind", kind)
		copy:SetAttribute("SupportProbes",tested) copy:SetAttribute("SupportGeometryProbes",src.contactProbes)
		copy:SetAttribute("GroundingScale",scale) copy.Parent = parent
		for _, p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then
			p.Anchored = true p.CanTouch = false p.CastShadow = kind~="plants" or targetHeight>1
			p.CanCollide = kind == "rocks" or kind == "logs" p.CanQuery = p.CanCollide
			local lower = p.Name:lower()
			if lower:find("leaf", 1, true) or lower:find("leaves", 1, true) or lower:find("flower", 1, true) or lower:find("fern", 1, true) then
				p:SetAttribute("ForestRestCF", p.CFrame)
				p:SetAttribute("WindPower", kind == "trees" and 0.035 or 0.065)
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
		local height = name == "RedwoodTree-Var01" and rng:NextNumber(54, 105) or rng:NextNumber(31, 71)
		if place(name, x, z, height, trees, "trees") then occupied[#occupied + 1] = Vector2.new(x, z) end
	end
	local plantNames = {"Fern_Var01", "FernTallVar01", "MountainLaurelBush_Var01", "RhododendronVar01", "RhododendronVar02", "CloverPatch", "DenseLeafPatch", "BeechwoodSapling_Var01", "WildFlower01", "Wildflower02", "WildFlower03", "WildFlower04"}
	for attempt = 1, 3400 do
		if stats.plants >= 1650 then break end
		local x, z = rng:NextNumber(-394, 394), rng:NextNumber(-360, 360)
		local y, material, water, shore, path = Scene.sample(x, z)
		if shore > 0.91 or y < water + 0.9 or path < 5.5 or material == Enum.Material.Rock then continue end
		local name = plantNames[rng:NextInteger(1, #plantNames)]
		local h = name:find("Sapling", 1, true) and rng:NextNumber(6, 14) or (name:find("Tall", 1, true) and rng:NextNumber(4, 7) or rng:NextNumber(1.2, 4))
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
	local crossings = 2 -- Wooden bridge geometry is installed by Amenities after vegetation.
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
	for _, v in pairs(cache) do v.model:Destroy() end raw:Destroy() importProbe:Destroy()
	return {forestAsset = 6432306802, grassAsset = 87377915371959, windAsset = 11946229834, removedForeignScripts = removed,
		terrain = terrainReport, vegetation = stats, crossings = crossings, wildlifeAnchors = 16, entry = {spawnCF.X, spawnCF.Y, spawnCF.Z}}
end
return Builder
]============]).install(Scene,Terrain)
local runtime=game.ReplicatedStorage.ForestRuntime
local amenities=factory([============[local Amenities={}
local Asset=game:GetService("AssetService")
local Collection=game:GetService("CollectionService")
local function strip(model)
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("LuaSourceContainer")or p:IsA("RemoteEvent")or p:IsA("RemoteFunction")or p:IsA("Camera")then p:Destroy()end
 end
end
local function bounds(model)
 local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local point=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(point)hi=hi:Max(point)
  end end end
 end end
 return lo,hi
end
local function normalize(model,rotation)
 model:PivotTo(rotation or CFrame.identity)
 local lo,hi=bounds(model)local base=Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)
 model:PivotTo(model:GetPivot()-base)model.PrimaryPart=nil model.WorldPivot=CFrame.identity
 return hi-lo
end
local function setParts(model,collide)
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
  p.Anchored=true p.CanCollide=collide p.CanQuery=collide p.CanTouch=false
  p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 end end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
end
local function part(parent,name,size,cf,material,color,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.Material=material p.Color=color
 p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
function Amenities.install(Scene)
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime
 local folder=Instance.new("Folder")folder.Name="Amenities"folder.Parent=world
 local bridges=Instance.new("Folder")bridges.Name="WoodenBridges"bridges.Parent=folder
 local stumps=Instance.new("Folder")stumps.Name="CutTrunks"stumps.Parent=folder
 local benches=Instance.new("Folder")benches.Name="LogBenches"benches.Parent=folder
 local lanterns=Instance.new("Folder")lanterns.Name="Lanterns"lanterns.Parent=folder
 local rawBridge=Asset:LoadAssetAsync(1352279393)strip(rawBridge)
 local bridgeTemplate=assert(rawBridge:FindFirstChildOfClass("Model"))
 local bridgeSize=normalize(bridgeTemplate)
 local rawStump=Asset:LoadAssetAsync(3070634312)strip(rawStump)
 local stumpTemplate=assert(rawStump:FindFirstChildOfClass("Model"))
 local stumpSize=normalize(stumpTemplate,CFrame.Angles(0,0,math.pi/2))
 local rawLantern=Asset:LoadAssetAsync(13557849262)strip(rawLantern)
 local lanternTemplate=assert(rawLantern:FindFirstChildOfClass("Model"))
 normalize(lanternTemplate,lanternTemplate:GetPivot().Rotation)
 lanternTemplate:ScaleTo(.47)
 for _,d in ipairs(lanternTemplate:GetDescendants())do if d:IsA("Light")then d:Destroy()end end
 local rawForest=Asset:LoadAssetAsync(6432306802)strip(rawForest)
 local logTemplate=assert(rawForest["Forest Pack"]:FindFirstChild("FallenTree"))
 local logSize=normalize(logTemplate)
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={workspace.Terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),params)end
 local function clearCircle(x,z,r)
  for _,f in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do
   for _,m in ipairs(f:GetChildren())do if m:IsA("Model")and(Vector2.new(m:GetPivot().X-x,m:GetPivot().Z-z)).Magnitude<r then m:Destroy()end end
  end
 end
 local lanternCount=0
 local function lantern(position,yaw,onPost)
  lanternCount+=1 local model=lanternTemplate:Clone()model.Name="ForestLantern"..lanternCount
  setParts(model,false)model:PivotTo(CFrame.new(position)*CFrame.Angles(0,yaw or 0,0))
  model:SetAttribute("SourceAssetId",13557849262)model.Parent=lanterns
  local glow=assert(model:FindFirstChild("Light",true))
  local light=Instance.new("PointLight")light.Name="WarmLanternLight"light.Color=Color3.fromRGB(255,199,128)light.Range=20 light.Brightness=0 light.Shadows=false light.Parent=glow
  Collection:AddTag(light,"ForestNightLight")
  if onPost then
   local h=assert(ground(position.X,position.Z))
   local postHeight=position.Y-h.Position.Y+.45
   local post=part(model,"TimberPost",Vector3.new(.48,postHeight,.48),CFrame.new(position.X,h.Position.Y+postHeight*.5-.1,position.Z+.85),Enum.Material.Wood,Color3.fromRGB(91,68,51),true)
   part(model,"LanternBracket",Vector3.new(.26,.24,1.35),CFrame.new(position.X,position.Y+1.42,position.Z+.45),Enum.Material.Metal,Color3.fromRGB(65,62,54),false)
   part(model,"HangingChain",Vector3.new(.06,.35,.06),CFrame.new(position.X,position.Y+1.48,position.Z),Enum.Material.Metal,Color3.fromRGB(65,62,54),false)
   model:SetAttribute("GroundPoint",h.Position)
  end
  return model
 end
 local function stretch(model,scale)
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
   local cf=p.CFrame local rot=cf.Rotation
   local function axis(a)return Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)):Dot(scale)end
   p.Size*=Vector3.new(axis(cf.RightVector),axis(cf.UpVector),axis(cf.LookVector))
   p.CFrame=CFrame.new(cf.Position*scale)*rot
  end end
 end
 local bridgeReport={}
 for _,z in ipairs({-108,176})do
  local centre=Scene.riverX(z)
  local banks={}
  for _,side in ipairs({-1,1})do
   for distance=Scene.riverWidth(z)+2,120,2 do
    local x=centre+side*distance local h=ground(x,z)
    if h and h.Material~=Enum.Material.Water and h.Position.Y>Scene.RiverY+1.2 and h.Normal.Y>.72 then banks[#banks+1]=h.Position break end
   end
  end
  assert(#banks==2,"Both bridge banks must be dry")
  local left,right=banks[1],banks[2]
  local start=Vector3.new(left.X-4,left.Y+.55,z)local finish=Vector3.new(right.X+4,right.Y+.55,z)
  local direction=(finish-start).Unit local width=8.2 local length=(finish-start).Magnitude
  local up=(Vector3.yAxis-direction*direction:Dot(Vector3.yAxis)).Unit
  local cf=CFrame.fromMatrix((start+finish)*.5,direction,up,direction:Cross(up))
  local bridge=bridgeTemplate:Clone()bridge.Name="WoodenBridge"..(#bridgeReport+1)
  stretch(bridge,Vector3.new(length/bridgeSize.X,1,width/bridgeSize.Z))
  bridge:PivotTo(cf*CFrame.new(0,-1.05,0))setParts(bridge,false)bridge.Parent=bridges
  bridge:SetAttribute("SourceAssetId",1352279393)bridge:SetAttribute("DeckStart",start)bridge:SetAttribute("DeckEnd",finish)bridge:SetAttribute("DeckWidth",width)
  -- Add separate boards and a single floor so union collision cannot seal off the walkway.
  for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")then p.Color=Color3.fromRGB(113,79,53)end end
  local boardCount=math.ceil(length/1.6)
  for i=1,boardCount do
   local t=(i-.5)/boardCount
   part(bridge,"DeckBoard",Vector3.new(length/boardCount-.055,.28,width-.9),cf*CFrame.new((t-.5)*length,-.14,0),Enum.Material.WoodPlanks,Color3.fromRGB(131+(i%3)*3,98+(i%3)*2,69+(i%3)*2),false)
  end
  local floor=part(bridge,"WalkwayCollision",Vector3.new(length+.50,.35,width-1.0),cf*CFrame.new(0,-.185,0),Enum.Material.WoodPlanks,Color3.fromRGB(115,83,57),true)floor.Transparency=1
  for _,side in ipairs({-1,1})do
   local rail=part(bridge,"RailingCollision",Vector3.new(length,2.7,.22),cf*CFrame.new(0,1.20,side*(width*.5-.35)),Enum.Material.Wood,Color3.fromRGB(105,74,51),true)rail.Transparency=1
  end
  for _,point in ipairs({start,finish})do
   clearCircle(point.X,point.Z,6)
   lantern(point+Vector3.new(0,4.2,width*.5+1),0,true)
   local h=assert(ground(point.X,point.Z))
   assert(h.Material~=Enum.Material.Water,"Bridge entrance submerged")
  end
  for _,f in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do
   for _,m in ipairs(f:GetChildren())do if m:IsA("Model")then local q=cf:PointToObjectSpace(m:GetPivot().Position)
    if math.abs(q.X)<length*.5+4 and math.abs(q.Z)<width*.5+3 then m:Destroy()end
   end end
  end
  -- Short piers descend into the bed, not floating at water level.
  for _,t in ipairs({.24,.5,.76})do for _,side in ipairs({-1,1})do
   local point=cf:PointToWorldSpace(Vector3.new((t-.5)*length,-.5,side*(width*.5-.6)))
   local height=point.Y-Scene.RiverY+7
   part(bridge,"WoodenPier",Vector3.new(.65,height,.65),CFrame.new(point.X,point.Y-height*.5,point.Z),Enum.Material.Wood,Color3.fromRGB(91,66,49),false)
  end end
  bridgeReport[#bridgeReport+1]={length=length,width=width,boards=boardCount,start={start.X,start.Y,start.Z},finish={finish.X,finish.Y,finish.Z}}
 end
 local rng=Random.new(881307)
 local function stump(x,z,height,name)
  local h=ground(x,z)if not h or h.Material==Enum.Material.Water or h.Normal.Y<.88 then return nil end
  local model=stumpTemplate:Clone()model.Name=name or "CutTrunk"model:ScaleTo(height/stumpSize.Y)
  local yaw=rng:NextNumber(0,math.pi*2)
  local low=h.Position.Y
  for _,off in ipairs({Vector2.new(-1,0),Vector2.new(1,0),Vector2.new(0,-1),Vector2.new(0,1)})do local a=ground(x+off.X,z+off.Y)if a then low=math.min(low,a.Position.Y)end end
  model:PivotTo(CFrame.new(x,low-.15,z)*CFrame.Angles(0,yaw,0))setParts(model,true)model.Parent=stumps
  model:SetAttribute("SourceAssetId",3070634312)model:SetAttribute("GroundPoint",h.Position)
  local lo,hi=bounds(model)model:SetAttribute("SeatTop",Vector3.new(x,hi.Y,z))return model
 end
 local stumpCount=0
 for i=1,90 do if stumpCount>=24 then break end
  local z=rng:NextNumber(-285,295)local x=Scene.pathX(z)+rng:NextNumber(12,45)*(i%2==0 and 1 or -1)
  local h=ground(x,z)
  if h and h.Material~=Enum.Material.Water and h.Normal.Y>.88 then clearCircle(x,z,3.3)if stump(x,z,rng:NextNumber(1.4,2.4))then stumpCount+=1 end end
 end
 local benchCount=0
 for _,z in ipairs({-275,-225,-165,-60,15,80,235,290})do
  local x=Scene.pathX(z)+11
  local hit=ground(x,z)
  if not hit or hit.Material==Enum.Material.Water or hit.Normal.Y<.87 then continue end
  clearCircle(x,z,8)
  local bench=logTemplate:Clone()bench.Name="LogBench"..(benchCount+1)bench:ScaleTo(10/logSize.X)
  local angle=math.pi*.5 local y=hit.Position.Y-.18
  for _,off in ipairs({Vector2.new(0,-5),Vector2.new(0,5)})do local h=ground(x+off.X,z+off.Y)if h then y=math.min(y,h.Position.Y-.18)end end
  bench:PivotTo(CFrame.new(x,y,z)*CFrame.Angles(0,angle,0))setParts(bench,true)bench.Parent=benches
  bench:SetAttribute("SourceAssetId",6432306802)bench:SetAttribute("SourceModel","FallenTree")bench:SetAttribute("GroundPoint",hit.Position)
  local meshRay=RaycastParams.new()meshRay.FilterType=Enum.RaycastFilterType.Include meshRay.FilterDescendantsInstances={bench}
  for _,side in ipairs({-1,1})do
   local point=bench:GetPivot():PointToWorldSpace(Vector3.new(side*2.3,0,0))
   local contact=workspace:Raycast(Vector3.new(point.X,y+8,point.Z),Vector3.new(0,-12,0),meshRay)
   local seat=Instance.new("Seat")seat.Name="LogSeat"seat.Size=Vector3.new(2,.2,1.6)
   seat.CFrame=CFrame.new(point.X,(contact and contact.Position.Y or y+1.9)+.025,point.Z)*CFrame.Angles(0,angle,0)
   seat.Anchored=true seat.Transparency=1 seat.CanCollide=false seat.CanQuery=false seat.CanTouch=false seat.Parent=bench
   local prompt=Instance.new("ProximityPrompt")prompt.Name="SitPrompt"prompt.ActionText="Sentar"prompt.ObjectText="Banco de tronco"prompt.HoldDuration=.2 prompt.MaxActivationDistance=7 prompt.RequiresLineOfSight=false prompt.Parent=seat
  end
  benchCount+=1 lantern(Vector3.new(x+2,hit.Position.Y+4.2,z+4),0,true)
 end
 for _,z in ipairs({-300,-245,-190,-125,-45,40,115,220,285})do
  local x=Scene.pathX(z)-7 local h=ground(x,z)
  if h and h.Material~=Enum.Material.Water and h.Normal.Y>.75 then clearCircle(x,z,2.2)lantern(h.Position+Vector3.new(0,4.2,0),0,true)end
 end
 -- The owner sits beside the entrance, facing the path, with real account clothes and accessories.
 local npcZ=-232 local npcX=Scene.pathX(npcZ)+10 local npcFloor=assert(ground(npcX,npcZ))
 for off=0,18,2 do local h=ground(npcX+off,npcZ)if h and h.Material~=Enum.Material.Water and h.Normal.Y>.9 then npcX+=off npcFloor=h break end end
 clearCircle(npcX,npcZ,8)
 local ownerStump=assert(stump(npcX,npcZ,2.05,"OwnerCutTrunk"),"NPC trunk requires dry level ground")
 local top=ownerStump:GetAttribute("SeatTop")
 local description=game.Players:GetHumanoidDescriptionFromUserIdAsync(8344738123)
 local npc=game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
 npc.Name="OwnerNPC"npc:SetAttribute("AvatarUserId",8344738123)npc:SetAttribute("AvatarUsername","ch_ckz2n")npc:SetAttribute("Seated",true)
 npc:SetAttribute("ShirtAssetId",description.Shirt)npc:SetAttribute("PantsAssetId",description.Pants)
 strip(npc)description:Destroy()
 local root=assert(npc:FindFirstChild("HumanoidRootPart"))npc.PrimaryPart=root
 local aim=Vector3.new(Scene.pathX(npcZ)-3,top.Y+1.2,npcZ-5)
 local npcCF=CFrame.lookAt(top+Vector3.new(0,1.12,0),aim)
 npc:PivotTo(npcCF)npc.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 for _,p in ipairs(npc:GetDescendants())do if p:IsA("BasePart")then p.Anchored=p==root p.CanCollide=false p.CanQuery=true p.CanTouch=false p.Massless=true end end
 local hum=assert(npc:FindFirstChildOfClass("Humanoid"))hum.DisplayName="ch_ckz2n"hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.WalkSpeed=0 hum.JumpPower=0 hum.AutoRotate=false hum.BreakJointsOnDeath=false hum.MaxHealth=math.huge hum.Health=hum.MaxHealth
 for _,m in ipairs(npc:GetDescendants())do if m:IsA("Motor6D")then m:SetAttribute("OriginalC0",m.C0)end end
 npc:SetAttribute("SeatCFrame",npcCF)npc.Parent=world Collection:AddTag(npc,"ForestOwnerNPC")
 local prompt=Instance.new("ProximityPrompt")prompt.Name="TalkPrompt"prompt.ActionText="Conversar"prompt.ObjectText="ch_ckz2n"prompt.MaxActivationDistance=11 prompt.HoldDuration=0 prompt.RequiresLineOfSight=false prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=npc.Head
 local sound=Instance.new("Sound")sound.Name="HiVoice"sound.SoundId="rbxassetid://9059051593"sound.Volume=.28 sound.RollOffMinDistance=4 sound.RollOffMaxDistance=20 sound.RollOffMode=Enum.RollOffMode.InverseTapered sound.Parent=npc.Head
 local remote=Instance.new("RemoteEvent")remote.Name="OwnerDialogue"remote.Parent=runtime
 lantern(npcFloor.Position+Vector3.new(2.8,4.2,2.8),0,true)
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())
 world:SetAttribute("WoodenBridgeCount",#bridgeReport)world:SetAttribute("CutTrunkCount",stumpCount+1)world:SetAttribute("LogBenchCount",benchCount)world:SetAttribute("LanternCount",lanternCount)
 for _,raw in ipairs({rawBridge,rawStump,rawLantern,rawForest})do raw:Destroy()end
 return{bridges=bridgeReport,cutTrunks=stumpCount+1,logBenches=benchCount,lanterns=lanternCount,ownerAvatarUserId=8344738123,greetingAudio=9059051593}
end
return Amenities
]============]).install(Scene)
local shader=factory([============[local Preset={}
function Preset.install()
 local raw=game:GetService("AssetService"):LoadAssetAsync(8490242417)
 local source=assert(raw:FindFirstChildOfClass("Script"),"Extreme shaders asset changed").Source
 assert(source:find("Bloom.Intensity = 0.3",1,true)and source:find("Sky.SkyboxUp",1,true),"Inspect changed shader preset before using")
 -- Import the reviewed preset's sky/effect classes. Lighting parameters are adapted by Visuals for a moving sun.
 local lighting=game.Lighting local sky=assert(lighting:FindFirstChildOfClass("Sky"))
 for key,id in pairs({SkyboxBk=151165214,SkyboxDn=151165197,SkyboxFt=151165224,SkyboxLf=151165191,SkyboxRt=151165206,SkyboxUp=151165227})do sky[key]="rbxassetid://"..id end
 sky.SunAngularSize=10 sky.StarCount=2200 sky.CelestialBodiesShown=true sky:SetAttribute("SourceAssetId",8490242417)
 local blur=Instance.new("BlurEffect")blur.Name="ForestBlur"blur.Size=0 blur.Enabled=false blur:SetAttribute("SourceAssetId",8490242417)blur.Parent=lighting
 for _,effect in ipairs(lighting:GetChildren())do if effect:IsA("PostEffect")or effect:IsA("Atmosphere")then effect:SetAttribute("SourceAssetId",8490242417)effect:SetAttribute("AdaptedForDayNight",true)end end
 local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("ShaderPresetAssetId",8490242417)
 runtime:SetAttribute("ShaderPresetAdapted",true)runtime:SetAttribute("CycleEpoch",nil)
 raw:Destroy()return{assetId=8490242417,reviewed=true,foreignScriptExecuted=false,adaptedForDayNight=true}
end
return Preset
]============]).install()
source(runtime,"ModuleScript","Scene",[============[local Scene = {Minimum = -512, Maximum = 512, Spacing = 4, RiverY = 6, SeaY = 6, Seed = 20261013}
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
	local height = -12 + interior * (29 + hill + detail)
	local rd = math.abs(x - Scene.riverX(z))
	local rw = Scene.riverWidth(z)
	local riverInfluence = (1 - smooth(rw - 2, rw + 28, rd)) * (1 - smooth(337, 401, math.abs(z)))
	local bed = Scene.RiverY - 6.5 + math.noise(x / 45, z / 65, 2) * 0.30
	height = height * (1 - riverInfluence) + bed * riverInfluence
	local lake = math.sqrt(((x - 39) / 61)^2 + ((z - 157) / 62)^2)
	local lakeInfluence = 1 - smooth(0.65, 1.25, lake)
	height = height * (1 - lakeInfluence) + (Scene.RiverY - 7) * lakeInfluence
	local path = Scene.pathDistance(x, z)
	local material = Enum.Material.Grass
	if shore > 0.94 then material = Enum.Material.Sand
	elseif height > 57 and hill > 45 then material = Enum.Material.Rock
	elseif height < Scene.RiverY + 1.5 and (rd < rw + 10 or lake < 1.25) then material = Enum.Material.Mud
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
	-- Dense cells overlap the actual bone footprint, including both sides of material edges.
	local green = Scene.isGreen(x, z)
	if not green then
		for _, offset in ipairs({Vector2.new(-5, -5), Vector2.new(5, -5), Vector2.new(-5, 5), Vector2.new(5, 5),Vector2.new(0,-5),Vector2.new(0,5),Vector2.new(-5,0),Vector2.new(5,0)}) do
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
source(runtime,"ModuleScript","Cycle",[============[local Cycle={Duration=960,DayDuration=720,StartClock=10.4}
function Cycle.epoch(now)return now-(Cycle.StartClock-6)/12*Cycle.DayDuration end
function Cycle.clock(now,epoch)
 local phase=(now-epoch)%Cycle.Duration
 return (phase<Cycle.DayDuration and 6+phase/Cycle.DayDuration*12 or 18+(phase-Cycle.DayDuration)/(Cycle.Duration-Cycle.DayDuration)*12)%24
end
function Cycle.daylight(clock)
 return math.clamp((math.sin((clock-6)/24*math.pi*2)+.12)/.52,0,1)
end
function Cycle.night(clock)return 1-Cycle.daylight(clock)end
return Cycle
]============])
source(runtime,"ModuleScript","Visuals",[============[local Lighting = game:GetService("Lighting")
local Visuals = {}
local Cycle=require(script.Parent:WaitForChild("Cycle"))
function Visuals.apply()
	-- Some Roblox runtime versions restrict renderer selection to Studio. The rest of the world must still initialise.
	pcall(function()Lighting.LightingStyle=Enum.LightingStyle.Realistic end)
	pcall(function()Lighting.PrioritizeLightingQuality=true end)
	Lighting.GlobalShadows = true Lighting.ShadowSoftness = 0.25
	Lighting.EnvironmentDiffuseScale = 1 Lighting.EnvironmentSpecularScale = 1
	Lighting.Brightness = 2.7 Lighting.ClockTime = Cycle.StartClock Lighting.GeographicLatitude = 28
	Lighting.ExposureCompensation = -0.10
	Lighting.Ambient = Color3.fromRGB(47, 56, 57) Lighting.OutdoorAmbient = Color3.fromRGB(99, 119, 121)
	Lighting.ColorShift_Top = Color3.fromRGB(12, 9, 3) Lighting.ColorShift_Bottom = Color3.new()
	Lighting.FogColor = Color3.fromRGB(178, 199, 203) Lighting.FogStart = 200 Lighting.FogEnd = 1800
	local color = Lighting:FindFirstChild("ForestColor")
	if color then color.Enabled = true color.Brightness = 0.01 color.Contrast = 0.18 color.Saturation = 0.12 color.TintColor = Color3.fromRGB(255, 247, 230) end
	local rays = Lighting:FindFirstChild("ForestSunRays")
	if rays then rays.Enabled = true rays.Intensity = 0.075 rays.Spread = 0.727 end
	local bloom = Lighting:FindFirstChild("ForestBloom")
	if bloom then bloom.Enabled = true bloom.Intensity = 0.15 bloom.Size = 10 bloom.Threshold = 1.35 end
	local air = Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Density = 0.28 air.Offset = 0.18 air.Color = Color3.fromRGB(196, 215, 221) air.Decay = Color3.fromRGB(105, 137, 134) air.Haze = 1.15 air.Glare = 0.20 end
end
function Visuals.clock(clock)
	local day=Cycle.daylight(clock)local night=1-day
	local warm=math.max(0,1-math.min(math.abs(clock-6.8),math.abs(clock-17.4))/2.4)*day
	Lighting.ClockTime=clock Lighting.Brightness=1.0+1.65*day
	Lighting.ExposureCompensation=-.08-.08*night
	Lighting.Ambient=Color3.fromRGB(24,32,48):Lerp(Color3.fromRGB(49,57,58),day)
	Lighting.OutdoorAmbient=Color3.fromRGB(48,63,88):Lerp(Color3.fromRGB(100,120,123),day)
	local color=Lighting:FindFirstChild("ForestColor")
	if color then color.Contrast=.12+.06*day color.Saturation=.04+.08*day color.TintColor=Color3.fromRGB(201,219,255):Lerp(Color3.fromRGB(255,247,230),day):Lerp(Color3.fromRGB(255,222,181),warm*.38)end
	local rays=Lighting:FindFirstChild("ForestSunRays")if rays then rays.Intensity=(.055+.035*warm)*day end
	local air=Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Color=Color3.fromRGB(100,133,174):Lerp(Color3.fromRGB(196,215,221),day):Lerp(Color3.fromRGB(224,185,149),warm*.4)air.Glare=.20*day end
end
return Visuals
]============])
source(runtime,"ModuleScript","GrassSampler",[============[local Sampler = {}
function Sampler.new(world)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include params.FilterDescendantsInstances = {workspace.Terrain, world.Decor,world.Amenities}
	params.RespectCanCollide = true
	local self = {}
	function self:sample(cell, offsets)
		local heights, sum, valid, colorSum = {}, 0, 0, Vector3.zero
		for i, offset in ipairs(offsets) do
			local x, z = cell.center.X + offset.X, cell.center.Z + offset.Z
			local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -300, 0), params)
			if hit and hit.Instance == workspace.Terrain and (hit.Material == Enum.Material.Grass or hit.Material == Enum.Material.LeafyGrass) and hit.Normal.Y > 0.35 then
				heights[i] = hit.Position.Y valid += 1 sum += hit.Position.Y
				local c=workspace.Terrain:GetMaterialColor(hit.Material)colorSum+=Vector3.new(c.R,c.G,c.B)
			end
		end
		return heights, valid > 0 and sum / valid or nil, valid,valid>0 and Color3.new(colorSum.X/valid,colorSum.Y/valid,colorSum.Z/valid)or nil
	end
	return self
end
return Sampler
]============])
source(runtime,"ModuleScript","GrassPriority",[============[local Priority={}
function Priority.plan(active,candidates,limit,empty,now)
 local wanted,queue={},{}local accepted=0
 for _,cell in ipairs(candidates)do
  if not empty[cell.key]or empty[cell.key]<now then
   if accepted>=limit then break end accepted+=1 wanted[cell.key]=true
   if not active[cell.key]then queue[#queue+1]=cell end
  end
 end
 local remove={}
 for key in pairs(active)do if not wanted[key]then remove[#remove+1]=key end end
 return remove,queue
end
return Priority
]============])
source(runtime,"ModuleScript","NPCPose",[============[local Pose={}
local function turn(base,angles)return CFrame.new(base.Position)*angles*base.Rotation end
function Pose.seat(rig)
 local torso=rig:FindFirstChild("Torso")if not torso then return end
 for _,name in ipairs({"Right Hip","Left Hip"})do local joint=torso:FindFirstChild(name)if joint then joint.C0=turn(joint:GetAttribute("OriginalC0")or joint.C0,CFrame.Angles(math.rad(88),0,0))joint:SetAttribute("SeatedC0",joint.C0)end end
 for _,name in ipairs({"Right Shoulder","Left Shoulder"})do local joint=torso:FindFirstChild(name)if joint then joint.C0=turn(joint:GetAttribute("OriginalC0")or joint.C0,CFrame.Angles(math.rad(18),0,0))joint:SetAttribute("SeatedC0",joint.C0)end end
 local neck=torso:FindFirstChild("Neck")if neck then neck:SetAttribute("SeatedC0",neck:GetAttribute("OriginalC0")or neck.C0)end
end
function Pose.look(base,localTarget)
 local horizontal=math.sqrt(localTarget.X^2+localTarget.Z^2)
 local yaw=math.clamp(math.atan2(-localTarget.X,-localTarget.Z),math.rad(-55),math.rad(55))
 local pitch=math.clamp(math.atan2(localTarget.Y,horizontal),math.rad(-14),math.rad(18))
 return turn(base,CFrame.Angles(pitch,yaw,0))
end
function Pose.wave(base,age)
 if age<0 or age>3 then return base end
 local ease=math.min(age/.55,(3-age)/.6,1) ease=math.clamp(ease,0,1) ease=ease*ease*(3-2*ease)
 local swing=math.sin(math.max(0,age-.55)*math.pi*3)*math.rad(11)*ease
 return turn(base,CFrame.Angles(math.rad(-8)*ease,0,math.rad(145)*ease+swing))
end
return Pose
]============])
source(runtime,"ModuleScript","NPCController",[============[local Controller={}
local Players=game:GetService("Players")local Run=game:GetService("RunService")
function Controller.start(runtime,world)
 local npc=assert(world:FindFirstChild("OwnerNPC"))local root=npc.HumanoidRootPart
 require(runtime.NPCPose).seat(npc)
 local remote=runtime.OwnerDialogue local last={}local inside={}local globalVoice=-math.huge
 local phrases={"Olá!","Oiii!"}local sequence=0
 local function aliveRoot(player)
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then return r,h end
 end
 local function greet(player,conversation)
  local r=aliveRoot(player)if not r or(r.Position-root.Position).Magnitude>15 then return false end
  local now=workspace:GetServerTimeNow()
  if now-(last[player]or -math.huge)<(conversation and 1.5 or 35)then
   if conversation then remote:FireClient(player,"dialogue","Olá!")return true end
   return false
  end
  last[player]=now sequence+=1
  local line=phrases[sequence%2+1]npc:SetAttribute("WaveStarted",now)
  remote:FireClient(player,conversation and "dialogue"or "greeting",line)
  if now-globalVoice>20 and sequence%3~=0 then globalVoice=now npc.Head.HiVoice.PlaybackSpeed=sequence%2==0 and 1 or 1.025 npc.Head.HiVoice:Play()end
  return true
 end
 npc.Head.TalkPrompt.Triggered:Connect(function(player)greet(player,true)end)
 remote.OnServerEvent:Connect(function(player,choice)
  if type(choice)~="string"or#choice>12 then return end
  local r=aliveRoot(player)if not r or(r.Position-root.Position).Magnitude>16 then return end
  local now=workspace:GetServerTimeNow()if now-(last[player]or 0)<.75 then return end last[player]=now
  if choice=="hello"then npc:SetAttribute("WaveStarted",now)remote:FireClient(player,"reply","Que bom te ver por aqui! 😄")
  elseif choice=="forest"then remote:FireClient(player,"reply","Siga as trilhas, atravesse o rio pelas pontes e aproveite a floresta. À noite, as lanternas iluminam o caminho.")
  elseif choice=="bye"then remote:FireClient(player,"close","Até mais!")end
 end)
 Players.PlayerRemoving:Connect(function(player)last[player]=nil inside[player]=nil end)
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.25 then return end elapsed=0
  local closest,best=nil,17
  for _,player in ipairs(Players:GetPlayers())do
   local r=aliveRoot(player)
   local distance=r and(r.Position-root.Position).Magnitude or math.huge
   if distance<best then closest=r best=distance end
   if distance<12.5 then if not inside[player]then inside[player]=true greet(player,false)end
   elseif distance>19 then inside[player]=nil end
  end
  npc:SetAttribute("LookTarget",closest and closest.Position+Vector3.new(0,1.5,0)or nil)
 end)
 return {greet=greet,aliveRoot=aliveRoot}
end
return Controller
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
local Visuals=require(runtime:WaitForChild("Visuals"))Visuals.apply()
local Cycle=require(runtime:WaitForChild("Cycle"))
runtime:SetAttribute("CycleEpoch",Cycle.epoch(workspace:GetServerTimeNow()))
runtime:SetAttribute("CycleSeconds",Cycle.Duration)
local world = workspace:WaitForChild("ForestWorld")
local spawn = world:WaitForChild("ForestSpawn")
local spawnCF = runtime:GetAttribute("MainSpawnCF")
require(runtime:WaitForChild("NPCController")).start(runtime,world)
local Collection=game:GetService("CollectionService")
for _,seat in ipairs(world.Amenities.LogBenches:GetDescendants())do if seat:IsA("Seat")then
	local prompt=seat:FindFirstChild("SitPrompt")
	if prompt then prompt.Triggered:Connect(function(player)
		local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
		if h and h.Health>0 and r and not seat.Occupant and(r.Position-seat.Position).Magnitude<9 then seat:Sit(h)end
	end)end
end end
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
	local clock=Cycle.clock(time,runtime:GetAttribute("CycleEpoch"))Visuals.clock(clock)
	for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do light.Enabled=Cycle.night(clock)>.015 light.Brightness=Cycle.night(clock)*1.7 end
	local strength = 6.8 + math.sin(time * 0.047) * 0.45 + math.sin(time * 0.023) * 0.25
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
local Priority=require(runtime:WaitForChild("GrassPriority"))
local sampler=require(runtime:WaitForChild("GrassSampler")).new(world)
local template=runtime.SkinnedGrassTemplates.GrassCard local templateMesh=template:FindFirstChildOfClass("MeshPart")
local sourceBones,offsets={},{}
for _,b in ipairs(templateMesh:GetChildren())do if b:IsA("Bone")then sourceBones[#sourceBones+1]=b end end
table.sort(sourceBones,function(a,b)return a.Name<b.Name end)
for i,b in ipairs(sourceBones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)end
local visible=Instance.new("Folder")visible.Name="ForestInteractiveGrass"visible.Parent=workspace
local storage=Instance.new("Folder")storage.Name="ForestGrassLocalStorage"storage.Parent=RS
local touch=UIS.TouchEnabled local radius=touch and 42 or 70 local maxActive=touch and 432 or 1152
local grass=Skinned.new({RenderDistanceEnabled=false,MeshStorage=storage,CollisionDistance=22,
 CollisionRadiusInner=1.2,CollisionRadiusOuter=3.1,CollisionAngle=58,CollisionReturnDelay=.08,
 CollisionReturnInfo=TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
 WindDistanceInner=touch and 10 or 14,WindDistanceOuter=touch and 23 or 32,
 WindFramerateInner=.75,WindFramerateOuter=.2,UseGlobalWind=true,WindStrengthScale=.40})
local active,empty={},{}local count=0 local queue={}local cursor=1 local refresh=1 local stepTime=0 local destroyed=false
local function rootOf(p)local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")if h and h.Health>0 and r then return r,h end end
local function add(cell)
 local heights,anchor,valid,color=sampler:sample(cell,offsets)
 if not anchor then empty[cell.key]=os.clock()+3 return end
 local model=template:Clone()model.Name="Grass"..cell.key model:PivotTo(CFrame.new(cell.center.X,anchor,cell.center.Z))
 local mesh=model:FindFirstChildOfClass("MeshPart")local appearance=mesh:FindFirstChildOfClass("SurfaceAppearance")
 mesh.Color=color if appearance then appearance.Color=color end
 local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
 for i,b in ipairs(bones)do
  local original=b.WorldCFrame.Position local height=heights[i]
  local point=height and Vector3.new(original.X,height+template:GetAttribute("BladeBaseOffset"),original.Z)or original-Vector3.new(0,240,0)
  local offset=CFrame.new(b.WorldCFrame:VectorToObjectSpace(point-original))
  b:SetAttribute("SerenaTerrainOffset",offset)b:SetAttribute("SerenaGroundPoint",point)b:SetAttribute("SerenaGreenRoot",height~=nil)b.Transform=offset
 end
 model.Parent=visible grass:AddMeshes({model})active[cell.key]={model=model,cell=cell,roots=valid}count+=1
end
local function remove(key)local entry=active[key]if not entry then return end grass:RemoveMeshes({entry.model})entry.model:Destroy()active[key]=nil count-=1 end
local stream=world.DescendantAdded:Connect(function(p)if p:IsA("BasePart")then refresh=1 table.clear(empty)end end)
player:SetAttribute("SerenaWholeMapGrassReady",true)player:SetAttribute("ForestGrassSpacing",Field.Spacing)
local reported=-1
local heartbeat=Run.Heartbeat:Connect(function(dt)
 if destroyed then return end local root=rootOf(player)if not root then return end refresh+=dt
 if refresh>=.4 then
  refresh=0 local now=os.clock()
  local removals,newQueue=Priority.plan(active,Field.around(root.Position,radius),maxActive,empty,now)
  for _,key in ipairs(removals)do remove(key)end queue=newQueue cursor=1
  for key,time in pairs(empty)do if now>time+6 then empty[key]=nil end end
 end
 local started=os.clock()
 for _=1,touch and 3 or 6 do
  local cell=queue[cursor]if not cell or count>=maxActive then break end cursor+=1
  if not active[cell.key]then add(cell)end
  if os.clock()-started>(touch and .003 or .0045)then break end
 end
 if reported~=count then reported=count player:SetAttribute("SerenaGrassLoadedPatches",count)end
 player:SetAttribute("SerenaGrassNearbyReady",cursor>#queue)
end)
local rendered=Run.RenderStepped:Connect(function(dt)
 if destroyed then return end stepTime+=dt if stepTime<(touch and 1/24 or 1/30)then return end local step=math.min(stepTime,.1)stepTime=0
 local root=rootOf(player)if not root then return end local actors={}
 for _,p in ipairs(Players:GetPlayers())do local r,h=rootOf(p)if r and(r.Position-root.Position).Magnitude<22 then
  local feet=r.Position.Y-(h.RigType==Enum.HumanoidRigType.R6 and 3 or h.HipHeight+r.Size.Y/2)actors[#actors+1]=Vector3.new(r.Position.X,feet+.1,r.Position.Z)
 end end grass:Step(step,actors,root.Position)
end)
script.Destroying:Connect(function()destroyed=true heartbeat:Disconnect()rendered:Disconnect()stream:Disconnect()grass:Destroy()visible:Destroy()storage:Destroy()table.clear(active)table.clear(empty)end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestCycleClient",[============[local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Cycle=require(runtime:WaitForChild("Cycle"))local Visuals=require(runtime:WaitForChild("Visuals"))
Visuals.apply()
local lights={}local function added(light)if light:IsA("PointLight")then lights[light]=true end end
for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do added(light)end
local addConnection=Collection:GetInstanceAddedSignal("ForestNightLight"):Connect(added)
local removeConnection=Collection:GetInstanceRemovedSignal("ForestNightLight"):Connect(function(light)lights[light]=nil end)
local elapsed=0
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt if elapsed<1/15 then return end elapsed=0
 local epoch=runtime:GetAttribute("CycleEpoch")if not epoch then return end
 local clock=Cycle.clock(workspace:GetServerTimeNow(),epoch)Visuals.clock(clock)
 local night=Cycle.night(clock)
 for light in pairs(lights)do if light.Parent then light.Enabled=night>.015 light.Brightness=night*1.7 else lights[light]=nil end end
end)
script.Destroying:Connect(function()connection:Disconnect()addConnection:Disconnect()removeConnection:Disconnect()table.clear(lights)end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestNPCClient",[============[local Players=game:GetService("Players")local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local UIS=game:GetService("UserInputService")local player=Players.LocalPlayer
local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local remote=runtime:WaitForChild("OwnerDialogue")
local Pose=require(runtime:WaitForChild("NPCPose"))
local npc,neck,shoulder,bubble,bubbleText=nil,nil,nil,nil,nil
local bubbleUntil=0 local panelOpen=false
local gui=Instance.new("ScreenGui")gui.Name="ForestConversation"gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")panel.Name="Dialogue"panel.AnchorPoint=Vector2.new(.5,1)
panel.Position=UDim2.fromScale(.5,.76)panel.Size=UDim2.new(.88,0,0,215)panel.BackgroundColor3=Color3.fromRGB(22,35,32)panel.BackgroundTransparency=.08 panel.Visible=false panel.Parent=gui
local limit=Instance.new("UISizeConstraint")limit.MaxSize=Vector2.new(440,215)limit.Parent=panel
local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,16)corner.Parent=panel
local stroke=Instance.new("UIStroke")stroke.Color=Color3.fromRGB(130,162,127)stroke.Transparency=.50 stroke.Parent=panel
local title=Instance.new("TextLabel")title.BackgroundTransparency=1 title.Position=UDim2.new(0,18,0,12)title.Size=UDim2.new(1,-65,0,22)title.Font=Enum.Font.GothamBold title.TextSize=17 title.TextColor3=Color3.fromRGB(226,235,218)title.TextXAlignment=Enum.TextXAlignment.Left title.Text="ch_ckz2n"title.Parent=panel
local close=Instance.new("TextButton")close.Name="Close"close.BackgroundTransparency=1 close.Position=UDim2.new(1,-46,0,5)close.Size=UDim2.fromOffset(40,40)close.Text="×"close.TextSize=28 close.Font=Enum.Font.Gotham close.TextColor3=Color3.fromRGB(225,235,224)close.Parent=panel
local message=Instance.new("TextLabel")message.BackgroundTransparency=1 message.Position=UDim2.new(0,18,0,43)message.Size=UDim2.new(1,-36,0,58)message.Font=Enum.Font.Gotham message.TextSize=15 message.TextColor3=Color3.fromRGB(215,228,214)message.TextWrapped=true message.TextXAlignment=Enum.TextXAlignment.Left message.TextYAlignment=Enum.TextYAlignment.Top message.Parent=panel
local options=Instance.new("ScrollingFrame")options.Name="Replies"options.BackgroundTransparency=1 options.BorderSizePixel=0 options.Position=UDim2.new(0,14,0,108)options.Size=UDim2.new(1,-28,0,94)options.CanvasSize=UDim2.new()options.AutomaticCanvasSize=Enum.AutomaticSize.Y options.ScrollBarThickness=3 options.ScrollBarImageColor3=Color3.fromRGB(151,178,144)options.Parent=panel
local layout=Instance.new("UIListLayout")layout.Padding=UDim.new(0,7)layout.Parent=options
local function hide()panelOpen=false panel.Visible=false end
close.Activated:Connect(hide)
for i,item in ipairs({{"hello","Olá! 😄"},{"forest","O que tem na floresta?"},{"bye","Até mais!"}})do
 local button=Instance.new("TextButton")button.Name=item[1]button.Size=UDim2.new(1,-5,0,38)button.LayoutOrder=i button.BackgroundColor3=Color3.fromRGB(46,66,49)button.AutoButtonColor=true button.Text=item[2]button.TextSize=14 button.Font=Enum.Font.GothamMedium button.TextColor3=Color3.fromRGB(226,239,218)button.Parent=options
 local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,9)c.Parent=button
 button.Activated:Connect(function()if panelOpen then remote:FireServer(item[1])if item[1]=="bye"then hide()end end end)
end
local function detach()
 if bubble then bubble:Destroy()end npc=nil neck=nil shoulder=nil bubble=nil bubbleText=nil hide()
end
local function attach(model)
 if npc==model then return end detach()
 local torso=model:FindFirstChild("Torso")local head=model:FindFirstChild("Head")if not torso or not head then return end
 npc=model neck=torso:FindFirstChild("Neck")shoulder=torso:FindFirstChild("Right Shoulder")
 Pose.seat(model)
 bubble=Instance.new("BillboardGui")bubble.Name="OwnerGreeting"bubble.Adornee=head bubble.Size=UDim2.fromOffset(180,48)bubble.StudsOffsetWorldSpace=Vector3.new(0,2.2,0)bubble.MaxDistance=28 bubble.AlwaysOnTop=false bubble.Enabled=false bubble.Parent=gui
 local bg=Instance.new("Frame")bg.Size=UDim2.fromScale(1,1)bg.BackgroundColor3=Color3.fromRGB(25,40,34)bg.BackgroundTransparency=.08 bg.Parent=bubble
 local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,13)c.Parent=bg
 bubbleText=Instance.new("TextLabel")bubbleText.BackgroundTransparency=1 bubbleText.Size=UDim2.new(1,-12,1,-6)bubbleText.Position=UDim2.fromOffset(6,3)bubbleText.Font=Enum.Font.GothamMedium bubbleText.TextSize=21 bubbleText.TextColor3=Color3.fromRGB(235,244,227)bubbleText.TextWrapped=true bubbleText.Parent=bg
end
for _,model in ipairs(Collection:GetTagged("ForestOwnerNPC"))do attach(model)end
local addConnection=Collection:GetInstanceAddedSignal("ForestOwnerNPC"):Connect(attach)
local removeConnection=Collection:GetInstanceRemovedSignal("ForestOwnerNPC"):Connect(function(model)if npc==model then detach()end end)
local remoteConnection=remote.OnClientEvent:Connect(function(kind,text)
 if type(kind)~="string"or type(text)~="string"then return end
 if kind=="close"then hide()elseif kind=="dialogue"then
  message.Text=text panelOpen=true panel.Visible=true options.CanvasPosition=Vector2.zero
 elseif kind=="reply"then message.Text=text end
 if bubbleText then bubbleText.Text=text bubbleUntil=os.clock()+(kind=="reply"and 5 or 3.8)bubble.Enabled=true end
end)
local connection=Run.RenderStepped:Connect(function(dt)
 if not npc or not npc.Parent then return end
 local torso=npc:FindFirstChild("Torso")if not torso then return end
 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
 local distance=root and(root.Position-torso.Position).Magnitude or math.huge
 if panelOpen and distance>19 then hide()end
 if bubble then bubble.Enabled=os.clock()<bubbleUntil and distance<28 end
 if distance>65 then return end
 local alpha=1-math.exp(-7*dt)
 if neck then
  local base=neck:GetAttribute("SeatedC0")or neck:GetAttribute("OriginalC0")or neck.C0
  local target=npc:GetAttribute("LookTarget")local goal=base
  if target then goal=Pose.look(base,torso.CFrame:PointToObjectSpace(target)-Vector3.new(0,1.5,0))end
  neck.C0=neck.C0:Lerp(goal,alpha)
 end
 if shoulder then
  local original=shoulder:GetAttribute("OriginalC0")or shoulder.C0
  local resting=shoulder:GetAttribute("SeatedC0")or original
  local start=npc:GetAttribute("WaveStarted")local age=start and workspace:GetServerTimeNow()-start or 4
  local goal=age>=0 and age<=3 and Pose.wave(original,age)or resting
  shoulder.C0=shoulder.C0:Lerp(goal,alpha)
 end
end)
local inputConnection=UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape then hide()end end)
script.Destroying:Connect(function()connection:Disconnect()remoteConnection:Disconnect()inputConnection:Disconnect()addConnection:Disconnect()removeConnection:Disconnect()detach()gui:Destroy()end)
]============])
require(runtime.Visuals).apply()
run(game.ServerScriptService.ForestServer.Source)
local tests=run([============[local world=assert(workspace:FindFirstChild("ForestWorld"))
local runtime=assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"))
assert(world:GetAttribute("ForestOnly")and world:GetAttribute("UpgradeVersion")==88)
assert(not workspace:FindFirstChild("MonCalamariWorld")and not workspace:FindFirstChild("IlhaSerena"))
local Scene=require(runtime.Scene)
local npc=assert(world:FindFirstChild("OwnerNPC"))
local parts,meshes,pbr,foreign=0,0,0,0
for _,d in ipairs(world:GetDescendants())do
 if d:IsA("BasePart")then parts+=1 if not d:IsDescendantOf(npc)then assert(d.Anchored,d:GetFullName().." unanchored")end end
 if d:IsA("MeshPart")then meshes+=1 end
 if d:IsA("SurfaceAppearance")then pbr+=1 end
 if d:IsA("LuaSourceContainer")then foreign+=1 end
end
assert(foreign==0 and meshes>2000 and pbr>1800,"PBR forest or imported-script isolation failed")
assert(world:GetAttribute("TreeCount")>350 and world:GetAttribute("PlantCount")>1000)
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),ray)end
local treeCount,plantCount,supports,maxGap,maxBurial,tallest,shortest=0,0,0,0,0,0,math.huge
local buriedExamples={}
for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do
 for _,model in ipairs(folder:GetChildren())do
  local profile=assert(runtime.GroundingProfiles:FindFirstChild(model.Name),"Missing root profile")
  local pivot=model:GetPivot()local scale=model:GetAttribute("GroundingScale")
  assert(model:GetAttribute("SupportGeometryProbes")>0,model.Name.." has no lower geometry ray samples")
  local localBurial=0
  for _,point in ipairs(profile:GetChildren())do
   local p=pivot:PointToWorldSpace(point.Value*scale)
   local h=assert(ground(p.X,p.Z),"No terrain under lower geometry")
   if h.Material~=Enum.Material.Water then
    local gap=p.Y-h.Position.Y
    assert(gap<.035,model.Name.." floats at a lower contact: "..gap)
    supports+=1 maxGap=math.max(maxGap,gap)maxBurial=math.max(maxBurial,-gap)localBurial=math.max(localBurial,-gap)
   end
  end
  if localBurial>1 then buriedExamples[#buriedExamples+1]={kind=folder.Name,name=model.Name,burial=localBurial,position={pivot.X,pivot.Y,pivot.Z},scale=scale}end
  local p=pivot.Position local h=assert(ground(p.X,p.Z))
  assert(h.Material~=Enum.Material.Water,"Vegetation root is submerged")
  if folder==world.Decor.Trees then
   treeCount+=1 assert(model:FindFirstChild("TrunkCollision"))
   local _,size=model:GetBoundingBox()tallest=math.max(tallest,size.Y)shortest=math.min(shortest,size.Y)
  else plantCount+=1 end
 end
end
assert(supports>10000 and tallest>95 and tallest-shortest>45,"Tree size variation or contact coverage insufficient")
local probes,green,water,trail,minY,maxY=0,0,0,0,math.huge,-math.huge
for x=-360,360,24 do for z=-336,336,24 do
 local h=ground(x,z)if h then probes+=1 minY=math.min(minY,h.Position.Y)maxY=math.max(maxY,h.Position.Y)
  if h.Material==Enum.Material.Water then water+=1
  elseif h.Material==Enum.Material.Grass or h.Material==Enum.Material.LeafyGrass then green+=1
  elseif h.Material==Enum.Material.Ground then trail+=1 end
 end
end end
assert(green>300 and water>40 and trail>10 and maxY-minY>50)
local riverProbes=0
for z=-288,288,8 do
 local h=assert(ground(Scene.riverX(z),z))
 assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-Scene.RiverY)<.10,"River has a dry gap or uneven water plane at "..z)
 riverProbes+=1
end
assert(workspace.Terrain.WaterWaveSize>0 and workspace.Terrain.WaterReflectance<.3 and Scene.SeaY==Scene.RiverY)
local bridges=world.Amenities.WoodenBridges
assert(#bridges:GetChildren()==2)
local walks=0
for _,bridge in ipairs(bridges:GetChildren())do
 assert(bridge:GetAttribute("SourceAssetId")==1352279393)
 local a,b=bridge:GetAttribute("DeckStart"),bridge:GetAttribute("DeckEnd")
 local include=RaycastParams.new()include.FilterType=Enum.RaycastFilterType.Include include.FilterDescendantsInstances={bridge}include.RespectCanCollide=true
 for i=0,40 do
  local p=a:Lerp(b,i/40)
  local h=workspace:Raycast(p+Vector3.new(0,4,0),Vector3.new(0,-8,0),include)
  assert(h and h.Instance.Name=="WalkwayCollision" and math.abs(h.Position.Y-p.Y)<.05,"Wooden walkway collision: "..bridge.Name.." step "..i.." hit "..(h and h.Instance.Name or "none"))walks+=1
 end
 for _,p in ipairs({a,b})do local h=assert(ground(p.X,p.Z))assert(h.Material~=Enum.Material.Water and h.Position.Y>=p.Y-1.1,"Bridge does not reach the bank")end
end
for _,d in ipairs(world:GetDescendants())do assert(d.Name~="RiverCrossingLog"and d.Name~="CrossingCollision","Old log crossing survived")end
local seats=0
for _,d in ipairs(world.Amenities.LogBenches:GetDescendants())do if d:IsA("Seat")then seats+=1 assert(d.Anchored and d:FindFirstChild("SitPrompt")and not d.CanCollide)end end
assert(seats>=12 and world:GetAttribute("CutTrunkCount")>=18 and world:GetAttribute("LanternCount")>=15)
local lights=game:GetService("CollectionService"):GetTagged("ForestNightLight")assert(#lights==world:GetAttribute("LanternCount"))
local spawn=runtime:GetAttribute("MainSpawnCF")local floor=assert(ground(spawn.X,spawn.Z))
assert(floor.Material~=Enum.Material.Water and floor.Normal.Y>.65 and math.abs(spawn.Y-floor.Position.Y-3.5)<.06)
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template.Mesh
assert(template:GetAttribute("SourceAssetId")==87377915371959 and Scene.Spacing==4 and mesh.Size.X<8 and mesh.Size.Y>1.2)
local bones,offsets={},{}local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
assert(#bones==100)
for i,b in ipairs(bones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)lo=lo:Min(offsets[i])hi=hi:Max(offsets[i])end
assert(hi.X-lo.X>Scene.Spacing+1 and hi.Z-lo.Z>Scene.Spacing+1,"Grass root footprint does not overlap adjacent cells")
local sampler=require(runtime.GrassSampler).new(world)
local zones,roots,coveragePoints,misses=0,0,0,0
for _,centre in ipairs({Vector3.new(spawn.X-12,0,spawn.Z),Vector3.new(-220,0,50),Vector3.new(160,0,-180),Vector3.new(240,0,210)})do
 local buckets={}local zoneRoots=0
 local function key(x,z)return math.floor(x/2)..":"..math.floor(z/2)end
 for _,cell in ipairs(Scene.around(centre,25))do
  local heights,anchor,valid=sampler:sample(cell,offsets)
  if anchor then
   zoneRoots+=valid
   for i,y in pairs(heights)do
    local p=Vector3.new(cell.center.X+offsets[i].X,y,cell.center.Z+offsets[i].Z)
    local k=key(p.X,p.Z)buckets[k]=buckets[k]or{}buckets[k][#buckets[k]+1]=p
   end
  end
 end
 if zoneRoots>100 then zones+=1 roots+=zoneRoots end
 for x=centre.X-8,centre.X+8,1 do for z=centre.Z-8,centre.Z+8,1 do
  local h=ground(x,z)
  if h and(h.Material==Enum.Material.Grass or h.Material==Enum.Material.LeafyGrass)and h.Normal.Y>.35 then
   local blocked=RaycastParams.new()blocked.FilterType=Enum.RaycastFilterType.Include blocked.FilterDescendantsInstances={world.Decor,world.Amenities}blocked.RespectCanCollide=true
   if not workspace:Raycast(h.Position+Vector3.new(0,20,0),Vector3.new(0,-20,0),blocked)then
    coveragePoints+=1 local covered=false
    for dx=-1,1 do for dz=-1,1 do
     for _,p in ipairs(buckets[key(x+dx*2,z+dz*2)]or{})do if(Vector2.new(p.X-x,p.Z-z)).Magnitude<.90 then covered=true break end end
    end end
    if not covered then misses+=1 end
   end
  end
 end end
end
assert(zones>=3 and coveragePoints>400 and misses==0,"Green terrain still has gaps between grass root grids: "..misses.."/"..coveragePoints)
local Priority=require(runtime.GrassPriority)
local removals,queue=Priority.plan({[99]=true,[100]=true},{{key=1},{key=2}},2,{},0)
assert(#removals==2 and #queue==2 and queue[1].key==1,"Old distant patches prevent nearer grass")
assert(#Scene.around(spawn.Position,42)<=432 and #Scene.around(spawn.Position,70)<=1152,"Client grass budget cannot cover a complete circle")
local storage=Instance.new("Folder")storage.Parent=game.ReplicatedStorage
local Skinned=require(runtime.SkinnedGrass)local simulation=Skinned.new({MeshStorage=storage,RenderDistanceEnabled=false,WindStrengthScale=.40})
local sample=template:Clone()sample:PivotTo(CFrame.new(-210,40,30))sample.Parent=workspace
local bone=sample.Mesh:FindFirstChildWhichIsA("Bone")
bone:SetAttribute("SerenaTerrainOffset",CFrame.new(0,1.25,0))bone:SetAttribute("SerenaGroundPoint",bone.WorldPosition+Vector3.new(0,1.25,0))
simulation:AddMeshes({sample})simulation:Step(1/30,{},bone.TransformedWorldCFrame.Position)
assert(math.abs(bone.Transform.Y-1.25)<.01,"Grass wind lifts roots")
simulation:RemoveMeshes({sample})assert(next(simulation.MeshRecords)==nil)simulation:Destroy()sample:Destroy()storage:Destroy()
assert(npc:GetAttribute("AvatarUserId")==8344738123 and npc.HumanoidRootPart.Anchored and npc:GetAttribute("Seated"))
local description=npc.Humanoid:GetAppliedDescription()
assert(description.Shirt==npc:GetAttribute("ShirtAssetId")and description.Pants==npc:GetAttribute("PantsAssetId")and description.Shirt>0 and description.Pants>0,"NPC does not wear owner's actual clothes")
description:Destroy()
local Pose=require(runtime.NPCPose)local neck=npc.Torso.Neck local shoulder=npc.Torso["Right Shoulder"]
local rootCF=npc.HumanoidRootPart.CFrame
local raised=Pose.wave(shoulder:GetAttribute("OriginalC0"),1.2)
assert((raised.Position-shoulder:GetAttribute("OriginalC0").Position).Magnitude<.001)
local looked=Pose.look(neck:GetAttribute("OriginalC0"),Vector3.new(5,1,-3))
assert((looked.Position-neck.C0.Position).Magnitude<.001 and npc.HumanoidRootPart.CFrame==rootCF)
assert(runtime:FindFirstChild("OwnerDialogue")and npc.Head:FindFirstChild("TalkPrompt"))
local statuses={}
game:GetService("ContentProvider"):PreloadAsync({npc.Head.HiVoice},function(id,status)statuses[#statuses+1]=tostring(status)end)
assert(npc.Head.HiVoice.IsLoaded and npc.Head.HiVoice.TimeLength>0,"Requested greeting audio is unavailable in this experience")
local Cycle=require(runtime.Cycle)local Visuals=require(runtime.Visuals)
assert(Cycle.clock(0,0)==6 and Cycle.clock(720,0)==18 and Cycle.clock(960,0)==6)
local epsilon=.001 local before=Cycle.clock(720-epsilon,0)local after=Cycle.clock(720+epsilon,0)
assert(math.abs(before-after)<.001,"Day/night cycle jumps")
local sunDirections={}
for _,hour in ipairs({6,12,18,0})do Visuals.clock(hour)sunDirections[#sunDirections+1]={game.Lighting:GetSunDirection().X,game.Lighting:GetSunDirection().Y,game.Lighting:GetSunDirection().Z}
 assert(game.Lighting.Brightness>=1 and game.Lighting.ForestColor.Enabled and Cycle.night(hour)>=0 and Cycle.night(hour)<=1)
end
assert(Cycle.night(0)>.9 and Cycle.night(12)<.01)
Visuals.clock(Cycle.StartClock)
assert(runtime:GetAttribute("CycleEpoch")and runtime:GetAttribute("ShaderPresetAssetId")==8490242417 and game.Lighting.ForestSky:GetAttribute("SourceAssetId")==8490242417)
assert(not game.Lighting.ForestBlur.Enabled and game.Lighting.ForestSunRays.Enabled)
assert(runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834 and workspace.GlobalWind.Magnitude>6)
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do
 for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
  local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
  local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..": "..tostring(result))compiled+=1
 end end
end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,result=pcall(require,s)assert(ok,s.Name..": "..tostring(result))compiled+=1 end end
assert(workspace.StreamingEnabled and #game.ServerScriptService:GetChildren()==1)
table.sort(buriedExamples,function(a,b)return a.burial>b.burial end)
while#buriedExamples>12 do table.remove(buriedExamples)end
return{forestOnly=true,parts=parts,realMeshParts=meshes,pbrAppearances=pbr,foreignScripts=foreign,trees=treeCount,plants=plantCount,buriedExamples=buriedExamples,
 supportPoints=supports,maximumSupportGap=maxGap,maximumSupportBurial=maxBurial,treeHeightRange={shortest,tallest},
 terrainProbes=probes,greenTerrainProbes=green,waterProbes=water,trailProbes=trail,riverContinuityProbes=riverProbes,
 woodenBridges=2,continuousWalkwayProbes=walks,logSeats=seats,cutTrunks=world:GetAttribute("CutTrunkCount"),lanterns=#lights,
 grassSampledZones=zones,validGrassRoots=roots,grassCoveragePoints=coveragePoints,grassCoverageMisses=misses,grassRootOverlap=hi.X-lo.X-Scene.Spacing,
 grassPriorityCorrect=true,grassRootWindStable=true,ownerAvatarUserId=8344738123,npcSeated=true,npcWaveAndLookKeepBodyFixed=true,
 greetingAudioLoaded=true,greetingAudioLength=npc.Head.HiVoice.TimeLength,cycleSeconds=Cycle.Duration,sunDirectionSamples=sunDirections,
 shaderPresetAssetId=8490242417,compiledScriptsAndModules=compiled,streamingEnabled=true,rendering=tostring(game.Lighting.LightingStyle)}
]============])
local baseVersion=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,baseVersion=baseVersion,expectedVersion=88,geometry=geometry,amenities=amenities,shader=shader,tests=tests}
