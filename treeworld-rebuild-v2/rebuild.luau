local AssetService = game:GetService("AssetService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155, "Wrong Roblox target")
assert(game.PlaceVersion >= 102, "Expected published v102 or newer")

local VERSION = "2026-10-15-forest-rebuild-v1"
local Terrain = Workspace.Terrain
local rng = Random.new(15102026)

local function lower(s)
	return string.lower(tostring(s or ""))
end

local function hasAny(text, words)
	text = lower(text)
	for _, word in ipairs(words) do
		if string.find(text, word, 1, true) then
			return true
		end
	end
	return false
end

local function stripScripts(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
end

local function cloneCandidates()
	local lampTemplate = nil
	local ruinsTemplate = nil

	local forestWorld = Workspace:FindFirstChild("ForestWorld")
	if forestWorld then
		local amenities = forestWorld:FindFirstChild("Amenities")
		if amenities then
			for _, obj in ipairs(amenities:GetDescendants()) do
				if not lampTemplate and obj:IsA("Model") then
					local n = lower(obj.Name)
					local lightInside = obj:FindFirstChildWhichIsA("PointLight", true)
						or obj:FindFirstChildWhichIsA("SpotLight", true)
						or obj:FindFirstChildWhichIsA("SurfaceLight", true)
					if lightInside and hasAny(n, {"lamp", "lantern", "post", "poste"}) then
						lampTemplate = obj:Clone()
						stripScripts(lampTemplate)
					end
				end
			end

			local preferred = amenities:FindFirstChild("ForestRuins")
			if preferred and (preferred:IsA("Model") or preferred:IsA("Folder")) then
				ruinsTemplate = preferred:Clone()
				stripScripts(ruinsTemplate)
			else
				for _, obj in ipairs(amenities:GetChildren()) do
					local n = lower(obj.Name)
					if (obj:IsA("Model") or obj:IsA("Folder"))
						and hasAny(n, {"ruin", "ruína", "ruina", "tomb", "crypt", "grave"})
						and not hasAny(n, {"mansion", "mansão", "mansao"}) then
						ruinsTemplate = obj:Clone()
						stripScripts(ruinsTemplate)
						break
					end
				end
			end
		end
	end

	return lampTemplate, ruinsTemplate
end

local lampTemplate, ruinsTemplate = cloneCandidates()

-- Remove o mundo antigo de verdade.
for _, child in ipairs(Workspace:GetChildren()) do
	if child ~= Terrain and not child:IsA("Camera") then
		child:Destroy()
	end
end
Terrain:Clear()

-- Limpa sistemas antigos relacionados ao TreeWorld/Overyard.
for _, name in ipairs({
	"TreeWorldZoneConfig", "PlaceCampfire", "OveryardRemotes",
	"TreeWorldConfig", "CampfireRemote"
}) do
	local old = ReplicatedStorage:FindFirstChild(name)
	if old then old:Destroy() end
end

local sps = StarterPlayer:WaitForChild("StarterPlayerScripts")
for _, name in ipairs({"TreeWorldUI", "TreeWorldWeatherClient", "TreeWorldCampfireClient"}) do
	local old = sps:FindFirstChild(name)
	if old then old:Destroy() end
end

for _, name in ipairs({
	"MansionSpawnGuard", "TreeWorldWeatherServer", "TreeWorldCampfireServer",
	"WorldBootstrap", "WeatherController", "AmbientAudioController",
	"VegetationCleaner", "CampfireService", "FireTouchHandler"
}) do
	local old = ServerScriptService:FindFirstChild(name)
	if old then old:Destroy() end
end

for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
		child:Destroy()
	end
end

for _, child in ipairs(SoundService:GetChildren()) do
	if hasAny(child.Name, {"treeworld", "forest", "rain", "ambient"}) then
		child:Destroy()
	end
end

-- Performance/mobile.
pcall(function() Workspace.StreamingEnabled = true end)
pcall(function() Workspace.StreamingMinRadius = 96 end)
pcall(function() Workspace.StreamingTargetRadius = 320 end)
pcall(function() Terrain.Decoration = true end)
pcall(function() Terrain.GrassLength = 0.42 end)
pcall(function() Workspace.GlobalWind = Vector3.new(7.5, 0, 3.5) end)

-- Mundo organizado.
local world = Instance.new("Folder")
world.Name = "ForestWorld"
world.Parent = Workspace

local folders = {}
for _, name in ipairs({
	"TerrainFeatures", "WaterFeatures", "Bridges", "LampPosts",
	"Ruins", "Vegetation", "Flowers", "Campfires", "Ambient"
}) do
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = world
	folders[name] = f
end

local function makePart(parent, name, size, cframe, material, color, canCollide, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.Material = material
	p.Color = color
	p.CanCollide = canCollide
	p.CanTouch = canCollide
	p.CanQuery = true
	p.CastShadow = true
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

local function terrainGroundAt(x, z)
	local origin = Vector3.new(x, 180, z)
	local result = Workspace:Raycast(origin, Vector3.new(0, -360, 0))
	if result and result.Instance == Terrain and result.Material ~= Enum.Material.Water then
		return result.Position, result.Normal, result.Material
	end
	return nil
end

local function clearGrassBox(center, sx, sz)
	local region = Region3.new(
		center - Vector3.new(sx * 0.5, 5, sz * 0.5),
		center + Vector3.new(sx * 0.5, 5, sz * 0.5)
	):ExpandToGrid(4)
	pcall(function()
		Terrain:ReplaceMaterial(region, 4, Enum.Material.Grass, Enum.Material.Ground)
	end)
end

-- =====================================================================
-- TERRENO BASE: amplo, mais plano, com poucas elevações.
-- =====================================================================
local HALF = 1152
local CHUNK = 256
for x = -HALF + CHUNK/2, HALF - CHUNK/2, CHUNK do
	for z = -HALF + CHUNK/2, HALF - CHUNK/2, CHUNK do
		Terrain:FillBlock(
			CFrame.new(x, 0, z),
			Vector3.new(CHUNK + 8, 48, CHUNK + 8),
			Enum.Material.Grass
		)
	end
end

-- Fundação rochosa escondida para bordas e paredões naturais.
Terrain:FillBlock(CFrame.new(0, -34, 0), Vector3.new(2320, 36, 2320), Enum.Material.Rock)

-- Áreas levemente elevadas nas bordas, sem montanhas exageradas.
local terraces = {
	{Vector3.new(-840, 26, -790), Vector3.new(430, 10, 360)},
	{Vector3.new(850, 27, 760), Vector3.new(380, 12, 420)},
	{Vector3.new(-830, 26, 820), Vector3.new(330, 9, 330)},
}
for _, item in ipairs(terraces) do
	Terrain:FillBlock(CFrame.new(item[1]), item[2], Enum.Material.Grass)
end

-- Caminhos discretos que também impedem grama de atravessar áreas de passagem.
local function paintPath(a, b, width)
	local mid = (a + b) * 0.5
	local len = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude
	local cf = CFrame.lookAt(Vector3.new(mid.X, 23.3, mid.Z), Vector3.new(b.X, 23.3, b.Z))
	Terrain:FillBlock(cf, Vector3.new(width, 2.4, len + 6), Enum.Material.Ground)
end

paintPath(Vector3.new(-70, 0, 680), Vector3.new(-70, 0, 330), 14)
paintPath(Vector3.new(-70, 0, 330), Vector3.new(-360, 0, 160), 12)
paintPath(Vector3.new(-70, 0, 330), Vector3.new(300, 0, 140), 12)

-- =====================================================================
-- RIOS
-- =====================================================================
local riverPoints = {
	Vector3.new(-1080, 0, -570),
	Vector3.new(-860, 0, -500),
	Vector3.new(-650, 0, -380),
	Vector3.new(-470, 0, -300),
	Vector3.new(-260, 0, -225),
	Vector3.new(-40, 0, -110),
	Vector3.new(210, 0, 10),
	Vector3.new(450, 0, 120),
	Vector3.new(690, 0, 255),
	Vector3.new(940, 0, 370),
	Vector3.new(1110, 0, 445),
}

local function channel(points, width, waterY)
	for i = 1, #points - 1 do
		local a = points[i]
		local b = points[i+1]
		local mid = (a + b) * 0.5
		local len = (b - a).Magnitude
		local look = CFrame.lookAt(Vector3.new(mid.X, 25, mid.Z), Vector3.new(b.X, 25, b.Z))
		Terrain:FillBlock(look, Vector3.new(width, 22, len + 12), Enum.Material.Air)
		local waterCF = CFrame.lookAt(Vector3.new(mid.X, waterY - 2, mid.Z), Vector3.new(b.X, waterY - 2, b.Z))
		Terrain:FillBlock(waterCF, Vector3.new(width - 8, 7, len + 10), Enum.Material.Water)
	end
end
channel(riverPoints, 54, 18)

local tributary = {
	Vector3.new(640, 0, -590),
	Vector3.new(565, 0, -450),
	Vector3.new(470, 0, -300),
	Vector3.new(360, 0, -155),
	Vector3.new(210, 0, 10),
}
channel(tributary, 42, 18)

-- Lago principal: bacia arredondada + água enterrada fora da bacia.
local lakeCenter = Vector3.new(-540, 23, 430)
for _, offset in ipairs({
	Vector3.new(0,0,0), Vector3.new(70,0,20), Vector3.new(-65,0,-15),
	Vector3.new(20,0,70), Vector3.new(-20,0,-70)
}) do
	Terrain:FillBall(lakeCenter + offset, 120, Enum.Material.Air)
end
Terrain:FillBlock(CFrame.new(-540, 14, 430), Vector3.new(300, 10, 300), Enum.Material.Water)

-- Pequeno lago secundário.
local pondCenter = Vector3.new(600, 23, 510)
Terrain:FillBall(pondCenter, 92, Enum.Material.Air)
Terrain:FillBlock(CFrame.new(600, 14, 510), Vector3.new(190, 10, 190), Enum.Material.Water)

-- =====================================================================
-- CACHOEIRA E PAREDÃO DE PEDRA/TERRA
-- =====================================================================
local cliffCenter = Vector3.new(650, 52, -690)
Terrain:FillBlock(CFrame.new(cliffCenter), Vector3.new(330, 82, 118), Enum.Material.Rock)
Terrain:FillBlock(CFrame.new(650, 91, -720), Vector3.new(320, 8, 170), Enum.Material.Ground)
Terrain:FillBlock(CFrame.new(650, 96, -750), Vector3.new(300, 8, 150), Enum.Material.Grass)

-- Rebaixo central para a queda.
Terrain:FillBlock(CFrame.new(650, 66, -632), Vector3.new(54, 56, 30), Enum.Material.Air)

-- Lago superior.
Terrain:FillBall(Vector3.new(650, 94, -770), 82, Enum.Material.Air)
Terrain:FillBlock(CFrame.new(650, 87, -770), Vector3.new(150, 12, 150), Enum.Material.Water)

-- Bacia inferior.
Terrain:FillBall(Vector3.new(650, 28, -570), 88, Enum.Material.Air)
Terrain:FillBlock(CFrame.new(650, 14, -570), Vector3.new(170, 10, 170), Enum.Material.Water)

local waterfallModel = Instance.new("Model")
waterfallModel.Name = "StoneCliffWaterfall"
waterfallModel.Parent = folders.WaterFeatures

for i = -1, 1 do
	local sheet = makePart(
		waterfallModel,
		"WaterSheet",
		Vector3.new(17, 62, 2),
		CFrame.new(650 + i*17, 55, -627),
		Enum.Material.Glass,
		Color3.fromRGB(168, 213, 221),
		false,
		0.32
	)
	sheet.CastShadow = false
end

local mistBase = makePart(
	waterfallModel, "WaterfallMistEmitter",
	Vector3.new(58, 2, 18),
	CFrame.new(650, 24, -615),
	Enum.Material.SmoothPlastic,
	Color3.new(1,1,1),
	false, 1
)
mistBase.CanQuery = false
local mist = Instance.new("ParticleEmitter")
mist.Name = "WaterMist"
mist.Rate = 34
mist.Lifetime = NumberRange.new(1.1, 2.2)
mist.Speed = NumberRange.new(4, 9)
mist.SpreadAngle = Vector2.new(55, 25)
mist.Acceleration = Vector3.new(0, 2.5, 0)
mist.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1.4),
	NumberSequenceKeypoint.new(1, 5.5),
})
mist.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.5),
	NumberSequenceKeypoint.new(1, 1),
})
mist.Color = ColorSequence.new(Color3.fromRGB(220, 239, 241))
mist.Parent = mistBase

local waterfallSound = Instance.new("Sound")
waterfallSound.Name = "WaterfallAmbience"
waterfallSound.SoundId = "rbxassetid://9120550180"
waterfallSound.Looped = true
waterfallSound.Volume = 0.48
waterfallSound.RollOffMinDistance = 25
waterfallSound.RollOffMaxDistance = 180
waterfallSound.Parent = mistBase

-- =====================================================================
-- PONTES BONITAS
-- =====================================================================
local bridgeCenters = {}

local function orientedSegment(parent, name, a, b, thickness, material, color)
	local mid = (a + b) * 0.5
	local len = (b - a).Magnitude
	local p = makePart(
		parent, name,
		Vector3.new(thickness, thickness, len),
		CFrame.lookAt(mid, b),
		material, color, true, 0
	)
	return p
end

local function createBridge(name, center, riverDir, span, width, stone)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = folders.Bridges
	table.insert(bridgeCenters, center)

	local cross = Vector3.new(-riverDir.Z, 0, riverDir.X).Unit
	local along = riverDir.Unit
	local wood = stone and Enum.Material.Slate or Enum.Material.WoodPlanks
	local deckColor = stone and Color3.fromRGB(109, 104, 96) or Color3.fromRGB(101, 72, 49)
	local railColor = stone and Color3.fromRGB(86, 83, 77) or Color3.fromRGB(73, 50, 35)

	local plankCount = 24
	for i = 0, plankCount do
		local t = i / plankCount
		local offset = (t - 0.5) * span
		local rise = math.sin(t * math.pi) * 3.4
		local pos = center + cross * offset + Vector3.new(0, rise, 0)
		local plank = makePart(
			model, "Deck",
			Vector3.new(width, 0.9, span/plankCount + 0.8),
			CFrame.lookAt(pos, pos + cross),
			wood, deckColor, true, 0
		)
		plank.CFrame = CFrame.lookAt(pos, pos + cross)
	end

	for side = -1, 1, 2 do
		local previous = nil
		for i = 0, 12 do
			local t = i / 12
			local offset = (t - 0.5) * span
			local rise = math.sin(t * math.pi) * 3.4
			local pos = center + cross * offset + along * (side * (width/2 - 0.8)) + Vector3.new(0, rise + 3.1, 0)
			local post = makePart(
				model, "RailingPost",
				Vector3.new(0.7, 5.2, 0.7),
				CFrame.new(pos - Vector3.new(0, 0.6, 0)),
				stone and Enum.Material.Slate or Enum.Material.Wood,
				railColor, false, 0
			)
			if previous then
				orientedSegment(model, "HandRail", previous, pos, 0.55, stone and Enum.Material.Slate or Enum.Material.Wood, railColor)
			end
			previous = pos
		end
	end

	for _, side in ipairs({-1, 1}) do
		local p = center + cross * side * (span/2 + 3)
		Terrain:FillBlock(CFrame.new(p.X, 22.8, p.Z), Vector3.new(width + 10, 5, 14), Enum.Material.Ground)
	end

	return model
end

createBridge("OakRiverBridge", Vector3.new(-520, 26, -320), Vector3.new(1,0,0.48), 76, 13, false)
createBridge("StoneRiverBridge", Vector3.new(-35, 26, -110), Vector3.new(1,0,0.48), 72, 15, true)
createBridge("WillowRiverBridge", Vector3.new(520, 26, 160), Vector3.new(1,0,0.52), 74, 13, false)

-- =====================================================================
-- RUÍNAS ATUAIS: mantém apenas a estrutura, sem chá/bancos/NPC antigo.
-- =====================================================================
local ruinsCount = 0
if ruinsTemplate then
	local function sanitizeRuins(root)
		for _, d in ipairs(root:GetDescendants()) do
			local n = lower(d.Name)
			local remove =
				d:IsA("Seat") or d:IsA("VehicleSeat") or d:IsA("Humanoid")
				or hasAny(n, {
					"tea", "teapot", "cup", "mug", "chair", "bench", "seat",
					"armor", "armour", "knight", "npc", "guard", "table"
				})
			if remove then
				d:Destroy()
			elseif d:IsA("LuaSourceContainer") then
				d:Destroy()
			end
		end
	end
	sanitizeRuins(ruinsTemplate)
	ruinsTemplate.Name = "PreservedForestRuins"
	ruinsTemplate.Parent = folders.Ruins
	pcall(function()
		ruinsTemplate:PivotTo(CFrame.new(-760, 27, 690) * CFrame.Angles(0, math.rad(18), 0))
	end)
	ruinsCount = 1

	local _, size = ruinsTemplate:GetBoundingBox()
	clearGrassBox(Vector3.new(-760, 24, 690), math.max(120, size.X + 28), math.max(120, size.Z + 28))

	-- Mofo discreto em algumas pedras.
	for i = 1, 18 do
		local x = -760 + rng:NextNumber(-55, 55)
		local z = 690 + rng:NextNumber(-42, 42)
		local p = terrainGroundAt(x, z)
		if p then
			local moss = makePart(
				folders.Ruins, "MossPatch",
				Vector3.new(rng:NextNumber(2.2, 5), 0.12, rng:NextNumber(2.2, 5)),
				CFrame.new(p + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
				Enum.Material.Grass,
				Color3.fromRGB(67, 92, 56),
				false, 0.05
			)
			moss.CanQuery = false
		end
	end
end

-- =====================================================================
-- POSTES ATUAIS: duplica o template preservado.
-- =====================================================================
local lampPositions = {
	Vector3.new(-70,0,610), Vector3.new(-70,0,520), Vector3.new(-70,0,430),
	Vector3.new(-70,0,340), Vector3.new(-155,0,280), Vector3.new(-250,0,225),
	Vector3.new(-345,0,170), Vector3.new(70,0,265), Vector3.new(180,0,210),
	Vector3.new(285,0,155), Vector3.new(-755,0,615), Vector3.new(-700,0,650),
}
local lampCount = 0

local function fallbackLamp(pos, index)
	local model = Instance.new("Model")
	model.Name = "ForestLamp_" .. index
	model.Parent = folders.LampPosts
	local post = makePart(model, "Post", Vector3.new(0.8, 11, 0.8), CFrame.new(pos + Vector3.new(0,5.5,0)), Enum.Material.Metal, Color3.fromRGB(55,54,50), true, 0)
	local cap = makePart(model, "Lamp", Vector3.new(2.2, 2.8, 2.2), CFrame.new(pos + Vector3.new(0,11.3,0)), Enum.Material.Glass, Color3.fromRGB(255,224,166), false, 0.25)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 218, 157)
	light.Brightness = 1.6
	light.Range = 24
	light.Shadows = true
	light.Parent = cap
end

for i, desired in ipairs(lampPositions) do
	local hit = terrainGroundAt(desired.X, desired.Z)
	if hit then
		clearGrassBox(hit, 6, 6)
		if lampTemplate then
			local clone = lampTemplate:Clone()
			stripScripts(clone)
			clone.Name = "PreservedLampPost_" .. i
			clone.Parent = folders.LampPosts
			pcall(function()
				clone:PivotTo(CFrame.new(hit + Vector3.new(0,0.2,0)))
			end)
		else
			fallbackLamp(hit, i)
		end
		lampCount += 1
	end
end

-- =====================================================================
-- VEGETAÇÃO PROCEDURAL COM ZONAS DE EXCLUSÃO.
-- =====================================================================
local exclusions = {
	{c=Vector2.new(-70, 600), r=135},
	{c=Vector2.new(-540, 430), r=190},
	{c=Vector2.new(600, 510), r=125},
	{c=Vector2.new(650, -650), r=205},
	{c=Vector2.new(-760, 690), r=125},
}
for _, c in ipairs(bridgeCenters) do
	table.insert(exclusions, {c=Vector2.new(c.X, c.Z), r=58})
end
for _, p in ipairs(lampPositions) do
	table.insert(exclusions, {c=Vector2.new(p.X, p.Z), r=10})
end

local function pointSegmentDistance2D(p, a, b)
	local ap = p - a
	local ab = b - a
	local denom = ab:Dot(ab)
	local t = denom > 0 and math.clamp(ap:Dot(ab) / denom, 0, 1) or 0
	return (p - (a + ab * t)).Magnitude
end

local function nearRiver(x, z, margin)
	local p = Vector2.new(x, z)
	for i = 1, #riverPoints - 1 do
		local a = Vector2.new(riverPoints[i].X, riverPoints[i].Z)
		local b = Vector2.new(riverPoints[i+1].X, riverPoints[i+1].Z)
		if pointSegmentDistance2D(p, a, b) < 35 + margin then return true end
	end
	for i = 1, #tributary - 1 do
		local a = Vector2.new(tributary[i].X, tributary[i].Z)
		local b = Vector2.new(tributary[i+1].X, tributary[i+1].Z)
		if pointSegmentDistance2D(p, a, b) < 30 + margin then return true end
	end
	return false
end

local function excluded(x, z, margin)
	local p = Vector2.new(x,z)
	for _, zone in ipairs(exclusions) do
		if (p - zone.c).Magnitude < zone.r + margin then return true end
	end
	if nearRiver(x,z,margin) then return true end
	return false
end

local treeColors = {
	Color3.fromRGB(62, 93, 58),
	Color3.fromRGB(72, 105, 65),
	Color3.fromRGB(83, 112, 70),
	Color3.fromRGB(54, 85, 52),
}
local trunkColors = {
	Color3.fromRGB(83, 65, 49),
	Color3.fromRGB(93, 70, 52),
	Color3.fromRGB(72, 58, 46),
}

local function createTree(pos, scale)
	local model = Instance.new("Model")
	model.Name = "ForestTree"
	model.Parent = folders.Vegetation

	local h = 9 * scale + rng:NextNumber(0, 5)
	local trunk = makePart(
		model, "Trunk",
		Vector3.new(h, 1.45*scale, 1.45*scale),
		CFrame.new(pos + Vector3.new(0, h/2, 0)) * CFrame.Angles(0,0,math.rad(90)),
		Enum.Material.Wood,
		trunkColors[rng:NextInteger(1,#trunkColors)],
		true, 0
	)
	trunk.Shape = Enum.PartType.Cylinder

	local canopyColor = treeColors[rng:NextInteger(1,#treeColors)]
	local crownY = pos.Y + h + 1.5*scale
	for _, off in ipairs({
		Vector3.new(0,0,0),
		Vector3.new(2.8*scale,-0.6*scale,0),
		Vector3.new(-2.5*scale,-0.4*scale,1.2*scale),
	}) do
		local crown = makePart(
			model, "Leaves",
			Vector3.new(7.6*scale, 6.3*scale, 7.6*scale),
			CFrame.new(Vector3.new(pos.X,crownY,pos.Z) + off),
			Enum.Material.SmoothPlastic,
			canopyColor,
			false, 0
		)
		crown.Shape = Enum.PartType.Ball
		crown.CanTouch = false
	end
end

local treeTarget = 300
local treeCount = 0
local attempts = 0
while treeCount < treeTarget and attempts < 2500 do
	attempts += 1
	local x = rng:NextNumber(-1080,1080)
	local z = rng:NextNumber(-1080,1080)
	if not excluded(x,z,9) then
		local p, normal, mat = terrainGroundAt(x,z)
		if p and normal.Y > 0.78 and mat == Enum.Material.Grass then
			createTree(p, rng:NextNumber(0.78,1.32))
			treeCount += 1
		end
	end
end

-- Arbustos e plantas baixas.
local plantCount = 0
attempts = 0
while plantCount < 360 and attempts < 2600 do
	attempts += 1
	local x = rng:NextNumber(-1060,1060)
	local z = rng:NextNumber(-1060,1060)
	if not excluded(x,z,3) then
		local p, normal, mat = terrainGroundAt(x,z)
		if p and normal.Y > 0.84 and mat == Enum.Material.Grass then
			local leaf = makePart(
				folders.Vegetation, "LowPlant",
				Vector3.new(rng:NextNumber(1.4,2.8), rng:NextNumber(0.45,0.9), rng:NextNumber(1.4,2.8)),
				CFrame.new(p + Vector3.new(0,0.35,0)) * CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0),
				Enum.Material.Grass,
				Color3.fromRGB(rng:NextInteger(55,85), rng:NextInteger(90,125), rng:NextInteger(50,75)),
				false, 0
			)
			leaf.Shape = Enum.PartType.Ball
			leaf.CanQuery = false
			plantCount += 1
		end
	end
end

-- Flores pequenas sem collision.
local flowerColors = {
	Color3.fromRGB(244,238,218),
	Color3.fromRGB(235,201,92),
	Color3.fromRGB(183,154,210),
	Color3.fromRGB(218,143,151),
}
local flowerCount = 0
attempts = 0
while flowerCount < 260 and attempts < 2200 do
	attempts += 1
	local x = rng:NextNumber(-990,990)
	local z = rng:NextNumber(-990,990)
	if not excluded(x,z,2) then
		local p, normal, mat = terrainGroundAt(x,z)
		if p and normal.Y > 0.86 and mat == Enum.Material.Grass then
			local flower = makePart(
				folders.Flowers, "WildFlower",
				Vector3.new(0.55,0.55,0.55),
				CFrame.new(p + Vector3.new(0,0.45,0)),
				Enum.Material.SmoothPlastic,
				flowerColors[rng:NextInteger(1,#flowerColors)],
				false, 0
			)
			flower.Shape = Enum.PartType.Ball
			flower.CanQuery = false
			flower.CanTouch = false
			flowerCount += 1
		end
	end
end

-- =====================================================================
-- SPAWN
-- =====================================================================
local spawnPos = Vector3.new(-70, 27.5, 680)
clearGrassBox(spawnPos, 32, 32)
local spawnPad = makePart(
	world, "SpawnSafetyPad",
	Vector3.new(20,1,20),
	CFrame.new(spawnPos.X,24.5,spawnPos.Z),
	Enum.Material.Ground,
	Color3.fromRGB(93,85,71),
	true, 1
)
spawnPad.CastShadow = false

local spawn = Instance.new("SpawnLocation")
spawn.Name = "ForestSpawn"
spawn.Size = Vector3.new(8,0.2,8)
spawn.Position = spawnPos
spawn.Anchored = true
spawn.Enabled = true
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Duration = 0
spawn.Parent = world

-- =====================================================================
-- LIGHTING / SHADERS LEVES
-- =====================================================================
Lighting.ClockTime = 16.6
Lighting.Brightness = 2.15
Lighting.ExposureCompensation = -0.05
Lighting.Ambient = Color3.fromRGB(95, 103, 94)
Lighting.OutdoorAmbient = Color3.fromRGB(128, 133, 121)
Lighting.EnvironmentDiffuseScale = 0.38
Lighting.EnvironmentSpecularScale = 0.55
Lighting.ShadowSoftness = 0.28
pcall(function() Lighting.Technology = Enum.Technology.Future end)

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "ForestAtmosphere"
atmosphere.Density = 0.28
atmosphere.Offset = 0.12
atmosphere.Color = Color3.fromRGB(208, 220, 205)
atmosphere.Decay = Color3.fromRGB(116, 132, 119)
atmosphere.Glare = 0.08
atmosphere.Haze = 1.4
atmosphere.Parent = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "ForestColor"
cc.Brightness = 0.015
cc.Contrast = 0.08
cc.Saturation = -0.035
cc.TintColor = Color3.fromRGB(244, 247, 238)
cc.Parent = Lighting

local rays = Instance.new("SunRaysEffect")
rays.Name = "ForestSunRays"
rays.Intensity = 0.045
rays.Spread = 0.72
rays.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Name = "ForestBloom"
bloom.Intensity = 0.08
bloom.Size = 18
bloom.Threshold = 1.35
bloom.Parent = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "ForestDepth"
dof.FarIntensity = 0.04
dof.FocusDistance = 80
dof.InFocusRadius = 55
dof.NearIntensity = 0
dof.Parent = Lighting

-- =====================================================================
-- ÁUDIO AMBIENTE
-- =====================================================================
local forestSound = Instance.new("Sound")
forestSound.Name = "TreeWorldForestAmbience"
forestSound.SoundId = "rbxassetid://9113047896"
forestSound.Looped = true
forestSound.Volume = 0.12
forestSound.Parent = SoundService

local rainSound = Instance.new("Sound")
rainSound.Name = "TreeWorldRainAmbience"
rainSound.SoundId = "rbxassetid://1516791621"
rainSound.Looped = true
rainSound.Volume = 0
rainSound.Parent = SoundService

-- =====================================================================
-- CHUVA / VENTO CLIENT
-- =====================================================================
local weatherClient = Instance.new("LocalScript")
weatherClient.Name = "TreeWorldWeatherClient"
weatherClient.Source = [=[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local rainSound = SoundService:WaitForChild("TreeWorldRainAmbience")
local forestSound = SoundService:WaitForChild("TreeWorldForestAmbience")

if not forestSound.IsPlaying then forestSound:Play() end
if not rainSound.IsPlaying then rainSound:Play() end

local rig = Instance.new("Part")
rig.Name = "_LocalRainRig"
rig.Size = Vector3.new(88,1,88)
rig.Anchored = true
rig.CanCollide = false
rig.CanTouch = false
rig.CanQuery = false
rig.Transparency = 1
rig.Parent = Workspace

local emitter = Instance.new("ParticleEmitter")
emitter.Name = "Rain"
emitter.Texture = "rbxasset://textures/particles/rain_main.dds"
emitter.Rate = 0
emitter.Lifetime = NumberRange.new(0.65,0.95)
emitter.Speed = NumberRange.new(62,78)
emitter.SpreadAngle = Vector2.new(8,8)
emitter.Acceleration = Vector3.new(7, -24, 3)
emitter.Size = NumberSequence.new(0.09)
emitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0,0.2),
	NumberSequenceKeypoint.new(1,0.65)
})
emitter.Parent = rig

local function updateWeather()
	local rainy = Workspace:GetAttribute("Weather") == "Rain"
	emitter.Rate = rainy and 360 or 0
	TweenService:Create(rainSound,TweenInfo.new(1.2),{Volume=rainy and 0.28 or 0}):Play()
	TweenService:Create(forestSound,TweenInfo.new(1.2),{Volume=rainy and 0.07 or 0.12}):Play()
end
Workspace:GetAttributeChangedSignal("Weather"):Connect(updateWeather)
updateWeather()

RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if camera then
		rig.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0,35,0))
	end
end)
]=]
weatherClient.Parent = sps

local weatherServer = Instance.new("Script")
weatherServer.Name = "TreeWorldWeatherServer"
weatherServer.Source = [=[
local Workspace = game:GetService("Workspace")
Workspace:SetAttribute("Weather","Rain")
Workspace.GlobalWind = Vector3.new(7.5,0,3.5)

task.spawn(function()
	while true do
		task.wait(105)
		Workspace:SetAttribute("Weather","Clear")
		Workspace.GlobalWind = Vector3.new(4.5,0,2)
		task.wait(165)
		Workspace:SetAttribute("Weather","Rain")
		Workspace.GlobalWind = Vector3.new(8,0,4)
	end
end)
]=]
weatherServer.Parent = ServerScriptService

-- =====================================================================
-- FOGUEIRA COLOCÁVEL + 8 TRONCOS
-- =====================================================================
local campfireRemote = Instance.new("RemoteEvent")
campfireRemote.Name = "PlaceCampfire"
campfireRemote.Parent = ReplicatedStorage

local campfireServer = Instance.new("Script")
campfireServer.Name = "TreeWorldCampfireServer"
campfireServer.Source = [=[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remote = ReplicatedStorage:WaitForChild("PlaceCampfire")
local world = Workspace:WaitForChild("ForestWorld")
local campfires = world:WaitForChild("Campfires")
local Terrain = Workspace.Terrain
local active = {}
local cooldown = {}

local function terrainPoint(origin)
	local result = Workspace:Raycast(origin + Vector3.new(0,40,0), Vector3.new(0,-100,0))
	if result and result.Instance == Terrain and result.Material ~= Enum.Material.Water and result.Normal.Y > 0.78 then
		return result.Position
	end
	return nil
end

local function part(parent,name,size,cf,material,color,collide,transparency)
	local p=Instance.new("Part")
	p.Name=name
	p.Size=size
	p.CFrame=cf
	p.Anchored=true
	p.Material=material
	p.Color=color
	p.CanCollide=collide
	p.Transparency=transparency or 0
	p.Parent=parent
	return p
end

local function clearGrass(pos)
	local region=Region3.new(pos-Vector3.new(12,5,12),pos+Vector3.new(12,5,12)):ExpandToGrid(4)
	pcall(function()
		Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.Ground)
	end)
end

local function buildCampfire(player,pos)
	if active[player] then active[player]:Destroy() end
	clearGrass(pos)

	local model=Instance.new("Model")
	model.Name="Campfire_"..player.UserId
	model.Parent=campfires
	active[player]=model

	local ground=part(model,"BareGround",Vector3.new(22,0.22,22),CFrame.new(pos+Vector3.new(0,0.08,0)),Enum.Material.Ground,Color3.fromRGB(91,78,61),false,0.12)
	ground.Shape=Enum.PartType.Cylinder
	ground.CFrame=CFrame.new(pos+Vector3.new(0,0.08,0))*CFrame.Angles(0,0,math.rad(90))

	for i=1,12 do
		local a=(i/12)*math.pi*2
		local stonePos=pos+Vector3.new(math.cos(a)*3.4,0.55,math.sin(a)*3.4)
		part(model,"FireRingStone",Vector3.new(1.6,1,1.2),CFrame.new(stonePos)*CFrame.Angles(0,-a,0),Enum.Material.Slate,Color3.fromRGB(91,87,81),true,0)
	end

	local coal=part(model,"CoalBed",Vector3.new(5.2,0.45,5.2),CFrame.new(pos+Vector3.new(0,0.35,0)),Enum.Material.Slate,Color3.fromRGB(37,31,28),true,0)
	coal.Shape=Enum.PartType.Cylinder
	coal.CFrame=CFrame.new(pos+Vector3.new(0,0.35,0))*CFrame.Angles(0,0,math.rad(90))

	local fireHolder=part(model,"FireCore",Vector3.new(2,1,2),CFrame.new(pos+Vector3.new(0,1,0)),Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1)
	local fire=Instance.new("Fire")
	fire.Size=7
	fire.Heat=4
	fire.Color=Color3.fromRGB(255,170,74)
	fire.SecondaryColor=Color3.fromRGB(255,95,42)
	fire.Parent=fireHolder
	local light=Instance.new("PointLight")
	light.Color=Color3.fromRGB(255,177,91)
	light.Brightness=2.2
	light.Range=23
	light.Shadows=true
	light.Parent=fireHolder
	local sound=Instance.new("Sound")
	sound.SoundId="rbxasset://sounds/fire.mp3"
	sound.Looped=true
	sound.Volume=0.35
	sound.RollOffMaxDistance=55
	sound.Parent=fireHolder
	sound:Play()

	for i=1,8 do
		local a=(i/8)*math.pi*2
		local center=pos+Vector3.new(math.cos(a)*9.2,1.1,math.sin(a)*9.2)
		local log=part(model,"LogBench",Vector3.new(5.8,1.3,1.6),CFrame.new(center)*CFrame.Angles(0,-a+math.pi/2,0),Enum.Material.Wood,Color3.fromRGB(96,66,45),true,0)
		local seat=Instance.new("Seat")
		seat.Name="InvisibleSeat"
		seat.Size=Vector3.new(4.6,0.5,1.4)
		seat.CFrame=log.CFrame*CFrame.new(0,0.9,0)
		seat.Anchored=true
		seat.Transparency=1
		seat.CanCollide=false
		seat.Parent=model
	end

	local hazard=part(model,"FireHazard",Vector3.new(4.8,3.2,4.8),CFrame.new(pos+Vector3.new(0,1.6,0)),Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1)
	hazard.CanQuery=false
	local recently={}
	hazard.Touched:Connect(function(hit)
		local character=hit:FindFirstAncestorOfClass("Model")
		local hum=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if hum and root and not recently[hum] then
			recently[hum]=true
			local fx=Instance.new("Fire")
			fx.Name="TemporaryCampfireEffect"
			fx.Size=4.2
			fx.Heat=2
			fx.Parent=root
			hum:TakeDamage(4)
			task.delay(2.4,function()
				if fx.Parent then fx:Destroy() end
				recently[hum]=nil
			end)
		end
	end)
end

remote.OnServerEvent:Connect(function(player)
	local now=os.clock()
	if cooldown[player] and now-cooldown[player] < 2 then return end
	cooldown[player]=now
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local target=root.Position + root.CFrame.LookVector*9
	local ground=terrainPoint(target)
	if not ground then return end
	buildCampfire(player,ground)
end)

Players.PlayerRemoving:Connect(function(player)
	if active[player] then active[player]:Destroy() end
	active[player]=nil
	cooldown[player]=nil
end)
]=]
campfireServer.Parent = ServerScriptService

local campfireClient = Instance.new("LocalScript")
campfireClient.Name = "TreeWorldCampfireClient"
campfireClient.Source = [=[
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local Players=game:GetService("Players")

local remote=ReplicatedStorage:WaitForChild("PlaceCampfire")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="TreeWorldCampfireUI"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")

local button=Instance.new("TextButton")
button.Name="CampfireButton"
button.AnchorPoint=Vector2.new(0.5,1)
button.Size=UDim2.fromOffset(112,34)
button.Position=UDim2.new(0.5,0,1,-18)
button.BackgroundColor3=Color3.fromRGB(36,34,31)
button.BackgroundTransparency=0.18
button.BorderSizePixel=0
button.Font=Enum.Font.GothamMedium
button.TextSize=12
button.TextColor3=Color3.fromRGB(245,241,231)
button.Text="Fogueira"
button.Parent=gui
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,9)
corner.Parent=button
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(245,241,231)
stroke.Transparency=0.82
stroke.Thickness=1
stroke.Parent=button

local busy=false
local function place()
	if busy then return end
	busy=true
	remote:FireServer()
	button.Text="Colocando..."
	task.delay(1.2,function()
		button.Text="Fogueira"
		busy=false
	end)
end
button.Activated:Connect(place)
UserInputService.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode==Enum.KeyCode.C then place() end
end)
]=]
campfireClient.Parent = sps

-- Inicializa clima.
Workspace:SetAttribute("Weather", "Rain")
Workspace:SetAttribute("WorldRebuildVersion", VERSION)
Workspace:SetAttribute("WorldRebuildComplete", true)
Workspace:SetAttribute("GeneratedTreeCount", treeCount)
Workspace:SetAttribute("GeneratedPlantCount", plantCount)
Workspace:SetAttribute("GeneratedFlowerCount", flowerCount)
Workspace:SetAttribute("GeneratedBridgeCount", #bridgeCenters)
Workspace:SetAttribute("GeneratedLampCount", lampCount)
Workspace:SetAttribute("PreservedRuinsCount", ruinsCount)
Workspace:SetAttribute("MansionSpawnFixed", nil)
Workspace:SetAttribute("CozyUIInstalled", nil)
Workspace:SetAttribute("CozyUIVersion", nil)

local sourceVersion = game.PlaceVersion
AssetService:SavePlaceAsync()

return {
	ok = true,
	sourceVersion = sourceVersion,
	version = VERSION,
	trees = treeCount,
	plants = plantCount,
	flowers = flowerCount,
	bridges = #bridgeCenters,
	lamps = lampCount,
	ruins = ruinsCount,
	spawn = {x=spawn.Position.X,y=spawn.Position.Y,z=spawn.Position.Z},
}
