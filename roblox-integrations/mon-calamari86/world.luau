local Builder = {}
local AssetService = game:GetService("AssetService")
local CollectionService = game:GetService("CollectionService")

local function bounds(model)
	local lo, hi = Vector3.one * math.huge, Vector3.one * -math.huge
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			for _, x in ipairs({-1, 1}) do for _, y in ipairs({-1, 1}) do for _, z in ipairs({-1, 1}) do
				local p = part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) * 0.5)
				lo, hi = lo:Min(p), hi:Max(p)
			end end end
		end
	end
	return lo, hi
end

local function clearChildren(container, keep)
	for _, child in ipairs(container:GetChildren()) do
		if not keep or not keep[child.Name] then child:Destroy() end
	end
end

function Builder.install()
	assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155 and game.PlaceVersion == 85, "Wrong source place")
	local raw = AssetService:LoadAssetAsync(485800451)
	local city = assert(raw:FindFirstChild("Mon Calamari"), "Original full city missing")
	local snapshots, walkway, distance, importedScripts, doors = {}, nil, math.huge, 0, 0
	for _, d in ipairs(city:GetDescendants()) do
		if d:IsA("BasePart") then
			snapshots[#snapshots + 1] = {part = d, cf = d.CFrame, size = d.Size, color = d.Color, material = d.Material,
				transparency = d.Transparency, collide = d.CanCollide}
			if d:IsA("Part") and d.Size.X > 80 and d.Size.X < 90 and d.Size.Z > 260 and d.Size.Z < 280 and d.CFrame.UpVector.Y > 0.99 then
				local delta = (Vector2.new(d.Position.X, d.Position.Z) - Vector2.new(173.56578, 56.18524)).Magnitude
				if delta < distance then walkway, distance = d, delta end
			end
		elseif d:IsA("Script") and d.Name == "OpenDoorScript" then
			local panel = d.Parent
			assert(panel:IsA("BasePart") and panel:FindFirstChildOfClass("ClickDetector"), "Unexpected original door")
			panel:SetAttribute("ClosedTransparency", panel.Transparency)
			panel:SetAttribute("ClosedCollision", panel.CanCollide)
			panel:SetAttribute("DoorOpen", false)
			CollectionService:AddTag(panel, "MonCalamariDoor")
			doors += 1
		end
	end
	assert(#snapshots == 1906 and walkway and distance < 0.1 and doors == 3, "City geometry changed")
	for _, d in ipairs(city:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then importedScripts += 1 d:Destroy()
		elseif d:IsA("Camera") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then d:Destroy()
		elseif d:IsA("TextBox") then d.TextEditable = false d.ClearTextOnFocus = false end
	end
	assert(importedScripts == 6, "Unexpected imported script inventory")
	city.Parent = nil
	raw:Destroy()

	-- Keep the reviewed Wind Effects asset, not the retired game systems.
	local previousRuntime = game.ReplicatedStorage:FindFirstChild("SerenaRuntime")
	local wind = assert(previousRuntime and previousRuntime:FindFirstChild("WindEffects"), "Selected wind asset unavailable"):Clone()
	assert(wind:FindFirstChild("WindLines") and wind:FindFirstChild("WindShake"), "Wind asset incomplete")
	wind:SetAttribute("SourceAssetId", 11946229834)
	local skyTemplate = game.Lighting:FindFirstChildOfClass("Sky")
	local sky = skyTemplate and skyTemplate:Clone() or Instance.new("Sky")
	for _, d in ipairs(workspace:GetChildren()) do
		if not d:IsA("Terrain") and not d:IsA("Camera") then d:Destroy() end
	end
	workspace.Terrain:Clear()
	clearChildren(workspace.Terrain)
	clearChildren(game.ServerScriptService)
	clearChildren(game.ServerStorage)
	clearChildren(game.ReplicatedStorage)
	clearChildren(game.ReplicatedFirst)
	clearChildren(game.StarterGui)
	clearChildren(game.StarterPack)
	clearChildren(game.StarterPlayer.StarterCharacterScripts)
	clearChildren(game.StarterPlayer.StarterPlayerScripts, {PlayerModule = true, RbxCharacterSounds = true, PlayerScriptsLoader = true})
	for _, d in ipairs(game.StarterPlayer:GetChildren()) do
		if d.Name == "StarterCharacter" or d:IsA("LuaSourceContainer") then d:Destroy() end
	end
	for _, d in ipairs(game.MaterialService:GetChildren()) do
		if d.Name:sub(1, 11) == "SerenaStud_" then d:Destroy() end
	end
	clearChildren(game.Lighting)
	sky.Name = "MonCalamariSky"
	sky.SunAngularSize = 11
	sky.MoonAngularSize = 10
	sky.CelestialBodiesShown = true
	sky.Parent = game.Lighting
	for class, name in pairs({Atmosphere = "MonCalamariAtmosphere", ColorCorrectionEffect = "MonCalamariColor",
		BloomEffect = "MonCalamariBloom", SunRaysEffect = "MonCalamariSunRays"}) do
		local effect = Instance.new(class) effect.Name = name effect.Parent = game.Lighting
	end
	local runtime = Instance.new("Folder") runtime.Name = "MonCalamariRuntime" runtime.Parent = game.ReplicatedStorage
	wind.Name = "WindEffects" wind.Parent = runtime

	local world = Instance.new("Model") world.Name = "MonCalamariWorld" world.Parent = workspace
	world:SetAttribute("UpgradeVersion", 86)
	world:SetAttribute("SourceAssetId", 485800451)
	world:SetAttribute("WindAssetId", 11946229834)
	world:SetAttribute("OriginalGeometryParts", #snapshots)
	world:SetAttribute("OriginalDoorCount", doors)
	city.Name = "MonCalamariCity"
	local entry = walkway.CFrame:PointToWorldSpace(Vector3.new(0, walkway.Size.Y * 0.5, 0))
	city:PivotTo(city:GetPivot() - entry)
	city.Parent = world
	city:SetAttribute("SourceAssetId", 485800451)
	for _, d in ipairs(city:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true d.CastShadow = true
		elseif d:IsA("Model") then d.ModelStreamingMode = Enum.ModelStreamingMode.Default end
	end
	city.ModelStreamingMode = Enum.ModelStreamingMode.Default
	local fidelity = 0
	for _, original in ipairs(snapshots) do
		local p = original.part
		assert(p:IsDescendantOf(city) and p.Size == original.size and p.Material == original.material and p.Color == original.color,
			"Original city asset was changed")
		assert(p.Transparency == original.transparency and p.CanCollide == original.collide, "Original collision/art changed")
		local target = original.cf - entry
		assert((p.Position - target.Position).Magnitude < 0.01 and p.CFrame.LookVector:Dot(target.LookVector) > 0.9999,
			"Geometry alignment changed")
		fidelity += 1
	end
	local lo, hi = bounds(city)
	world:SetAttribute("CityBoundsMin", lo) world:SetAttribute("CityBoundsMax", hi)
	world:SetAttribute("SourceTranslation", -entry)
	local ray = RaycastParams.new() ray.FilterType = Enum.RaycastFilterType.Include ray.FilterDescendantsInstances = {city} ray.RespectCanCollide = true
	local hit
	local function clearEntry(point)
		local centerHit = workspace:Raycast(point + Vector3.new(0, 15, 0), Vector3.new(0, -30, 0), ray)
		if not centerHit or centerHit.Instance ~= walkway or centerHit.Normal.Y < 0.99 then return nil end
		for _, dx in ipairs({-3, 0, 3}) do for _, dz in ipairs({-3, 0, 3}) do
			local floor = workspace:Raycast(centerHit.Position + Vector3.new(dx, 10, dz), Vector3.new(0, -20, 0), ray)
			if not floor or floor.Instance ~= walkway or floor.Normal.Y < 0.99 or math.abs(floor.Position.Y - centerHit.Position.Y) > 0.03 then return nil end
		end end
		for _, y in ipairs({1.2, 3, 5}) do
			for _, direction in ipairs({Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis}) do
				if workspace:Raycast(centerHit.Position + Vector3.new(0, y, 0), direction * 3, ray) then return nil end
			end
		end
		return centerHit
	end
	for _, z in ipairs({0, 16, -16, 32, -32, 48, -48, 72, -72, 96, -96}) do
		for _, x in ipairs({0, 12, -12, 24, -24, 30, -30}) do
			hit = clearEntry(walkway.CFrame:PointToWorldSpace(Vector3.new(x, walkway.Size.Y * 0.5, z)))
			if hit then break end
		end
		if hit then break end
	end
	assert(hit and math.abs(hit.Position.Y) < 0.03, "No unblocked entry on the original walkway")
	local forward = Vector3.new(walkway.CFrame.LookVector.X, 0, walkway.CFrame.LookVector.Z).Unit
	local spawnCF = CFrame.lookAt(hit.Position + Vector3.new(0, 3.5, 0), hit.Position + Vector3.new(0, 3.5, 0) + forward)
	world:SetAttribute("MainSpawnCF", spawnCF)
	runtime:SetAttribute("MainSpawnCF", spawnCF)
	runtime:SetAttribute("CityBoundsMin", lo) runtime:SetAttribute("CityBoundsMax", hi)
	local spawn = Instance.new("SpawnLocation") spawn.Name = "MonCalamariSpawn"
	spawn.Size = Vector3.new(6, 0.2, 6) spawn.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.05, 0))
	spawn.Transparency = 1 spawn.Anchored = true spawn.CanCollide = false spawn.CanTouch = false spawn.CanQuery = false
	spawn.Neutral = true spawn.Duration = 0 spawn.Enabled = true spawn.Parent = world
	for _, panel in ipairs(CollectionService:GetTagged("MonCalamariDoor")) do
		if panel:IsDescendantOf(city) then
			local click = panel:FindFirstChildOfClass("ClickDetector") click.MaxActivationDistance = 12
			local prompt = Instance.new("ProximityPrompt") prompt.Name = "DoorPrompt"
			prompt.ActionText = "Abrir" prompt.ObjectText = "Porta" prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false prompt.HoldDuration = 0 prompt.Parent = panel
		end
	end

	-- Mon Calamari's floating platforms sit on an ocean; the store asset supplies only the city.
	local seaY = -10
	local width = math.ceil((hi.X - lo.X + 1800) / 4) * 4
	local length = math.ceil((hi.Z - lo.Z + 1800) / 4) * 4
	local center = Vector3.new((lo.X + hi.X) * 0.5, seaY - 30, (lo.Z + hi.Z) * 0.5)
	local terrain = workspace.Terrain
	terrain:FillBlock(CFrame.new(center), Vector3.new(width, 60, length), Enum.Material.Water)
	terrain.WaterColor = Color3.fromRGB(38, 112, 145)
	terrain.WaterTransparency = 0.30 terrain.WaterReflectance = 0.72 terrain.WaterWaveSize = 0.18 terrain.WaterWaveSpeed = 10
	world:SetAttribute("OceanSurfaceY", seaY) world:SetAttribute("OceanSize", Vector3.new(width, 60, length))
	local clouds = Instance.new("Clouds") clouds.Name = "MonCalamariClouds"
	clouds.Cover = 0.36 clouds.Density = 0.30 clouds.Color = Color3.fromRGB(238, 245, 250) clouds.Parent = terrain
	workspace.GlobalWind = Vector3.new(9, 0, 2.7)
	game.Players.CharacterAutoLoads = true
	game.StarterPlayer.CharacterWalkSpeed = 16
	game.StarterPlayer.CharacterJumpPower = 50
	game.StarterPlayer.CharacterJumpHeight = 7.2
	game.StarterPlayer.CameraMode = Enum.CameraMode.Classic
	game.StarterPlayer.CameraMinZoomDistance = 0.5
	game.StarterPlayer.CameraMaxZoomDistance = 22
	game.StarterPlayer.DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice
	game.StarterPlayer.DevTouchMovementMode = Enum.DevTouchMovementMode.UserChoice
	game.StarterPlayer.DevComputerCameraMovementMode = Enum.DevComputerCameraMovementMode.Classic
	game.StarterPlayer.DevTouchCameraMovementMode = Enum.DevTouchCameraMovementMode.Classic
	-- Open Cloud edit sessions may lack Studio-only capabilities. Preserve existing streaming when so.
	local streamingChanges = {}
	for property, value in pairs({StreamingEnabled = true, StreamingMinRadius = 64, StreamingTargetRadius = 768,
		StreamingIntegrityMode = Enum.StreamingIntegrityMode.PauseOutsideLoadedArea,
		StreamOutBehavior = Enum.StreamOutBehavior.Opportunistic, ModelStreamingBehavior = Enum.ModelStreamingBehavior.Improved}) do
		local ok, actual = pcall(function() workspace[property] = value return tostring(workspace[property]) end)
		if not ok then
			local readable, current = pcall(function() return tostring(workspace[property]) end)
			actual = readable and current or "Unavailable in this edit-session engine"
		end
		streamingChanges[property] = {applied = ok, actual = actual}
	end
	assert(workspace.StreamingEnabled, "Streaming must remain enabled")
	return {assetId = 485800451, originalGeometryPreserved = fidelity, removedImportedScripts = importedScripts, originalDoors = doors,
		entry = {spawnCF.X, spawnCF.Y, spawnCF.Z}, bounds = {min = {lo.X, lo.Y, lo.Z}, max = {hi.X, hi.Y, hi.Z}},
		waterSurface = seaY, oceanSize = {width, 60, length}, windAsset = 11946229834, streaming = streamingChanges}
end

return Builder
