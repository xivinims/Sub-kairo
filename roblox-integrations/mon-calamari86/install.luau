assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==85,"Published map changed")
local function factory(code)
 local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage
 local value=require(m)m:Destroy()return value
end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)
 local s=Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s
end
local geometry=factory([============[local Builder = {}
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
]============]).install()
local runtime=game.ReplicatedStorage.MonCalamariRuntime
source(runtime,"ModuleScript","Visuals",[============[-- Native Roblox renderer and post-processing, applied on both server and client.
local Lighting = game:GetService("Lighting")
local Visuals = {}

function Visuals.apply()
	Lighting.LightingStyle = Enum.LightingStyle.Realistic
	Lighting.PrioritizeLightingQuality = true
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.22
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.Brightness = 2.6
	Lighting.ClockTime = 15.35
	Lighting.GeographicLatitude = 22
	Lighting.ExposureCompensation = -0.12
	Lighting.Ambient = Color3.fromRGB(47, 57, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 119, 132)
	Lighting.ColorShift_Top = Color3.fromRGB(12, 7, 2)
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	Lighting.FogStart = 900
	Lighting.FogEnd = 4200
	Lighting.FogColor = Color3.fromRGB(182, 213, 225)
	local color = Lighting:FindFirstChild("MonCalamariColor")
	if color then
		color.Enabled = true
		color.Brightness = 0.015
		color.Contrast = 0.12
		color.Saturation = 0.10
		color.TintColor = Color3.fromRGB(255, 249, 239)
	end
	local bloom = Lighting:FindFirstChild("MonCalamariBloom")
	if bloom then
		bloom.Enabled = true
		bloom.Intensity = 0.18
		bloom.Size = 20
		bloom.Threshold = 1.4
	end
	local rays = Lighting:FindFirstChild("MonCalamariSunRays")
	if rays then
		rays.Enabled = true
		rays.Intensity = 0.065
		rays.Spread = 0.78
	end
	local air = Lighting:FindFirstChild("MonCalamariAtmosphere")
	if air then
		air.Density = 0.24
		air.Offset = 0.13
		air.Color = Color3.fromRGB(190, 215, 228)
		air.Decay = Color3.fromRGB(125, 148, 172)
		air.Glare = 0.18
		air.Haze = 1.10
	end
end

return Visuals
]============])
source(game.ServerScriptService,"Script","MonCalamariServer",[============[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local runtime = game.ReplicatedStorage:WaitForChild("MonCalamariRuntime")
require(runtime:WaitForChild("Visuals")).apply()
local spawnCF = runtime:GetAttribute("MainSpawnCF")
local spawn = workspace:WaitForChild("MonCalamariWorld"):WaitForChild("MonCalamariSpawn")

local function characterReady(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= character then return end
	root.Anchored = false
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 50
	-- The SpawnLocation handles placement. Only repair a spawn outside this entry.
	if (root.Position - spawnCF.Position).Magnitude > 24 then
		character:PivotTo(spawnCF)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end
local function added(player)
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(character) characterReady(player, character) end)
	if player.Character then task.spawn(characterReady, player, player.Character) end
end
Players.PlayerAdded:Connect(added)
for _, player in ipairs(Players:GetPlayers()) do added(player) end

local wired = {}
local function door(panel)
	if not panel:IsA("BasePart") or wired[panel] then return end
	wired[panel] = true
	local last = 0
	local prompt = panel:FindFirstChild("DoorPrompt")
	local function toggle(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - panel.Position).Magnitude > math.max(14, panel.Size.Magnitude * 0.5 + 10) then return end
		local now = os.clock()
		if now - last < 0.35 then return end
		last = now
		local open = not panel:GetAttribute("DoorOpen")
		panel:SetAttribute("DoorOpen", open)
		panel.Transparency = open and 0.65 or panel:GetAttribute("ClosedTransparency")
		panel.CanCollide = not open and panel:GetAttribute("ClosedCollision") or false
		if prompt then prompt.ActionText = open and "Fechar" or "Abrir" end
	end
	local click = panel:FindFirstChildOfClass("ClickDetector")
	if click then click.MouseClick:Connect(toggle) end
	if prompt then prompt.Triggered:Connect(toggle) end
end
for _, panel in ipairs(CollectionService:GetTagged("MonCalamariDoor")) do door(panel) end
CollectionService:GetInstanceAddedSignal("MonCalamariDoor"):Connect(door)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 1 then return end
	elapsed = 0
	local now = workspace:GetServerTimeNow()
	local breeze = 9 + math.sin(now * 0.055) * 0.8 + math.sin(now * 0.021) * 0.5
	workspace.GlobalWind = Vector3.new(breeze, 0, breeze * 0.3)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 and root.Position.Y < -100 then
			character:PivotTo(spawnCF)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","MonCalamariClient",[============[local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local runtime = game.ReplicatedStorage:WaitForChild("MonCalamariRuntime")
local Visuals = require(runtime:WaitForChild("Visuals"))
Visuals.apply()
while not workspace.CurrentCamera do RunService.Heartbeat:Wait() end
local WindLines = require(runtime:WaitForChild("WindEffects"):WaitForChild("WindLines"))
local wind = workspace.GlobalWind
WindLines:Init({Direction = wind.Unit, Speed = 12, Lifetime = 2, SpawnRate = UserInputService.TouchEnabled and 7 or 12})

local stopped = false
local elapsed = 0
local update = RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.5 then return end
	elapsed = 0
	local value = workspace.GlobalWind
	if value.Magnitude > 0.01 then WindLines.Direction = value.Unit end
	WindLines.Speed = math.clamp(value.Magnitude * 1.25, 5, 18)
end)

script.Destroying:Connect(function()
	if stopped then return end
	stopped = true
	update:Disconnect()
	WindLines:Cleanup()
end)
]============])
require(runtime.Visuals).apply()
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
local baseVersion=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,baseVersion=baseVersion,expectedVersion=baseVersion+1,geometry=geometry,tests=tests}
