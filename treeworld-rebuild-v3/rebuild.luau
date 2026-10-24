local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155, "Wrong target")
assert(game.PlaceVersion >= 103, "Expected v103+")

local VERSION = "2026-10-15-reference-rebuild-v3"
local Terrain = Workspace.Terrain
local rng = Random.new(1510202603)

local function low(v) return string.lower(tostring(v or "")) end
local function has(text, words)
	text = low(text)
	for _, w in ipairs(words) do
		if string.find(text, w, 1, true) then return true end
	end
	return false
end

local function stripScripts(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then d:Destroy() end
	end
end

local function setAnchored(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			if has(d.Name, {"leaf","leaves","foliage","particle","soil","ground"}) then
				d.CanCollide = false
			end
		end
	end
end

local function loadAsset(id)
	local ok, model = pcall(function() return InsertService:LoadAsset(id) end)
	if not ok or not model then return nil end
	stripScripts(model)
	setAnchored(model)
	return model
end

local forestAsset = loadAsset(6432306802)
assert(forestAsset, "Official Roblox Forest Pack failed to load")
local lampAsset = loadAsset(5036801877)
assert(lampAsset, "Current lamp-post asset failed to load")

-- Build candidate pools from actual Roblox forest pack models.
local treePool, bushPool, flowerPool, rockPool, detailPool = {}, {}, {}, {}, {}

local function hasBasePart(model)
	return model:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function directNestedModelWithParts(model)
	for _, c in ipairs(model:GetChildren()) do
		if c:IsA("Model") and hasBasePart(c) then return true end
	end
	return false
end

local function addCandidate(pool, model)
	if model and model:IsA("Model") and hasBasePart(model) then
		table.insert(pool, model)
	end
end

for _, obj in ipairs(forestAsset:GetDescendants()) do
	if obj:IsA("Model") and hasBasePart(obj) and not directNestedModelWithParts(obj) then
		local n = low(obj.Name)
		local ok, _, size = pcall(function() return obj:GetBoundingBox() end)
		if ok then
			if has(n, {"tree","oak","birch","pine","maple"}) or (size.Y > 12 and size.X < 45 and size.Z < 45) then
				addCandidate(treePool, obj)
			elseif has(n, {"bush","shrub","fern"}) then
				addCandidate(bushPool, obj)
			elseif has(n, {"flower","grass","plant","mushroom","clover"}) then
				addCandidate(flowerPool, obj)
			elseif has(n, {"rock","boulder","stone"}) then
				addCandidate(rockPool, obj)
			elseif size.Y < 8 and size.X < 18 and size.Z < 18 then
				addCandidate(detailPool, obj)
			end
		end
	end
end

assert(#treePool > 0, "No usable tree models found in official Forest Pack")
assert(#rockPool > 0, "No usable rock models found in official Forest Pack")
if #bushPool == 0 then bushPool = detailPool end
if #flowerPool == 0 then flowerPool = detailPool end

-- Clear old world completely.
for _, child in ipairs(Workspace:GetChildren()) do
	if child ~= Terrain and not child:IsA("Camera") then
		child:Destroy()
	end
end
Terrain:Clear()

for _, child in ipairs(ServerScriptService:GetChildren()) do
	if has(child.Name, {"treeworld","overyard","weather","campfire","worldbootstrap"}) then child:Destroy() end
end
for _, child in ipairs(ReplicatedStorage:GetChildren()) do
	if has(child.Name, {"treeworld","overyard","campfire","placecampfire"}) then child:Destroy() end
end
local sps = StarterPlayer:WaitForChild("StarterPlayerScripts")
for _, child in ipairs(sps:GetChildren()) do
	if has(child.Name, {"treeworld","overyard","weather","campfire"}) then child:Destroy() end
end
for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then child:Destroy() end
end
for _, child in ipairs(SoundService:GetChildren()) do
	if has(child.Name, {"treeworld","forest","rain","waterfall","ambient"}) then child:Destroy() end
end

pcall(function() Workspace.StreamingEnabled = true end)
pcall(function() Workspace.StreamingMinRadius = 96 end)
pcall(function() Workspace.StreamingTargetRadius = 384 end)
pcall(function() Workspace.GlobalWind = Vector3.new(5.5, 0, 2.6) end)
pcall(function() Terrain.Decoration = true end)
pcall(function() Terrain.GrassLength = 0.62 end)
pcall(function() Terrain.WaterColor = Color3.fromRGB(82, 179, 194) end)
pcall(function() Terrain.WaterTransparency = 0.23 end)
pcall(function() Terrain.WaterReflectance = 0.42 end)
pcall(function() Terrain.WaterWaveSize = 0.08 end)
pcall(function() Terrain.WaterWaveSpeed = 10 end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(91, 178, 72)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(119, 96, 70)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(222, 208, 167)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(118, 121, 113)) end)

local world = Instance.new("Folder")
world.Name = "ForestWorld"
world.Parent = Workspace

local names = {"Trees","Bushes","Flowers","Rocks","Water","Paths","Bridges","TempleRuins","Torii","LampPosts","Campfires","Details"}
local folders = {}
for _, name in ipairs(names) do
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = world
	folders[name] = f
end

local function part(parent, name, size, cf, material, color, collide, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Material = material
	p.Color = color
	p.CanCollide = collide
	p.CanTouch = collide
	p.CanQuery = true
	p.CastShadow = true
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

local function terrainHit(x, z)
	local result = Workspace:Raycast(Vector3.new(x, 180, z), Vector3.new(0,-360,0))
	if result and result.Instance == Terrain and result.Material ~= Enum.Material.Water then
		return result.Position, result.Normal, result.Material
	end
	return nil
end

local function clearGrass(center, sx, sz)
	local region = Region3.new(
		center - Vector3.new(sx*0.5, 6, sz*0.5),
		center + Vector3.new(sx*0.5, 6, sz*0.5)
	):ExpandToGrid(4)
	pcall(function()
		Terrain:ReplaceMaterial(region, 4, Enum.Material.Grass, Enum.Material.Ground)
	end)
end

local function placeModel(source, parent, groundPos, scale, yaw)
	local clone = source:Clone()
	clone.Parent = parent
	pcall(function() clone:ScaleTo(scale) end)
	setAnchored(clone)
	local ok, boxCF, boxSize = pcall(function() return clone:GetBoundingBox() end)
	if not ok then clone:Destroy(); return nil end
	local pivot = clone:GetPivot()
	local bottom = boxCF.Position.Y - boxSize.Y/2
	local offsetY = pivot.Position.Y - bottom
	local target = CFrame.new(groundPos.X, groundPos.Y + offsetY, groundPos.Z) * CFrame.Angles(0, yaw or 0, 0)
	clone:PivotTo(target)
	return clone, boxSize
end

local function randomFrom(pool)
	return pool[rng:NextInteger(1,#pool)]
end

-- =====================================================================
-- TERRAIN: broad, smooth, photo-like meadow/forest rather than noise.
-- =====================================================================
local HALF = 1320
local STEP = 264
for x=-HALF+STEP/2, HALF-STEP/2, STEP do
	for z=-HALF+STEP/2, HALF-STEP/2, STEP do
		Terrain:FillBlock(CFrame.new(x, -2, z), Vector3.new(STEP+6, 42, STEP+6), Enum.Material.Grass)
	end
end
Terrain:FillBlock(CFrame.new(0,-31,0), Vector3.new(2680,30,2680), Enum.Material.Rock)

-- gentle broad hills only
for _, h in ipairs({
	{Vector3.new(-930,-225,-770),248},
	{Vector3.new(940,-235,-760),258},
	{Vector3.new(-950,-220,780),244},
	{Vector3.new(980,-232,810),256},
	{Vector3.new(-260,-218,-1030),242},
}) do
	Terrain:FillBall(h[1], h[2], Enum.Material.Grass)
end

-- =====================================================================
-- PATHS: bright earthy/sandy path like reference photos.
-- =====================================================================
local mainPath = {
	Vector3.new(0,20,1120),
	Vector3.new(0,20,870),
	Vector3.new(-70,20,650),
	Vector3.new(-210,20,460),
	Vector3.new(-330,20,250),
	Vector3.new(-250,20,60),
	Vector3.new(-60,20,-120),
	Vector3.new(180,20,-280),
	Vector3.new(420,20,-430),
	Vector3.new(690,20,-540),
}
local shrinePath = {
	Vector3.new(-70,20,650),
	Vector3.new(170,20,620),
	Vector3.new(360,20,520),
	Vector3.new(530,20,390),
}

local function paintPolyline(points, width, material)
	for i=1,#points-1 do
		local a,b = points[i],points[i+1]
		local flatA,flatB = Vector3.new(a.X,20,a.Z),Vector3.new(b.X,20,b.Z)
		local mid=(flatA+flatB)*0.5
		local len=(flatB-flatA).Magnitude
		Terrain:FillBlock(CFrame.lookAt(mid,flatB),Vector3.new(width,2.2,len+5),material)
	end
end
paintPolyline(mainPath,15,Enum.Material.Ground)
paintPolyline(shrinePath,13,Enum.Material.Sand)

-- =====================================================================
-- WATER: lake + winding river + pond with reflective clear water.
-- =====================================================================
local river = {
	Vector3.new(-1200,0,-260),
	Vector3.new(-970,0,-235),
	Vector3.new(-760,0,-150),
	Vector3.new(-560,0,-80),
	Vector3.new(-340,0,-30),
	Vector3.new(-120,0,40),
	Vector3.new(100,0,120),
	Vector3.new(330,0,150),
	Vector3.new(570,0,120),
	Vector3.new(800,0,55),
	Vector3.new(1030,0,-20),
	Vector3.new(1240,0,-50),
}

local function carveRiver(points,width,waterY)
	for i=1,#points-1 do
		local a,b=points[i],points[i+1]
		local len=(b-a).Magnitude
		local samples=math.max(2,math.floor(len/24))
		for s=0,samples do
			local t=s/samples
			local p=a:Lerp(b,t)
			Terrain:FillBall(Vector3.new(p.X,13,p.Z),width*0.55,Enum.Material.Air)
			Terrain:FillBlock(CFrame.new(p.X,waterY-3,p.Z),Vector3.new(width-8,8,28),Enum.Material.Water)
		end
	end
end
carveRiver(river,62,12)

-- main lake composed of overlapping bowls
local lakeCenters = {
	Vector3.new(-510,15,400),
	Vector3.new(-420,15,425),
	Vector3.new(-570,15,490),
	Vector3.new(-450,15,515),
}
for _, c in ipairs(lakeCenters) do
	Terrain:FillBall(c,128,Enum.Material.Air)
end
Terrain:FillBlock(CFrame.new(-495,8,455),Vector3.new(330,12,300),Enum.Material.Water)

-- secondary pond
Terrain:FillBall(Vector3.new(470,15,610),100,Enum.Material.Air)
Terrain:FillBlock(CFrame.new(470,8,610),Vector3.new(205,12,195),Enum.Material.Water)

-- island for giant tree in main lake
Terrain:FillBall(Vector3.new(-500,-47,455),69,Enum.Material.Grass)

-- =====================================================================
-- CLIFF WATERFALL: vertical rock/earth wall, not a rounded mountain.
-- =====================================================================
local cliff = Instance.new("Model")
cliff.Name = "ReferenceWaterfallCliff"
cliff.Parent = folders.Water

Terrain:FillBlock(CFrame.new(-870,64,-820),Vector3.new(360,100,132),Enum.Material.Rock)
Terrain:FillBlock(CFrame.new(-870,116,-845),Vector3.new(350,16,180),Enum.Material.Ground)
Terrain:FillBlock(CFrame.new(-870,124,-875),Vector3.new(330,10,165),Enum.Material.Grass)
Terrain:FillBlock(CFrame.new(-870,74,-750),Vector3.new(74,72,42),Enum.Material.Air)
Terrain:FillBall(Vector3.new(-870,118,-900),95,Enum.Material.Air)
Terrain:FillBlock(CFrame.new(-870,108,-900),Vector3.new(185,14,170),Enum.Material.Water)
Terrain:FillBall(Vector3.new(-870,22,-680),98,Enum.Material.Air)
Terrain:FillBlock(CFrame.new(-870,8,-680),Vector3.new(190,12,185),Enum.Material.Water)

for i=-2,2 do
	local sheet=part(cliff,"WaterfallSheet",Vector3.new(15,78,1.7),CFrame.new(-870+i*15,70,-752),Enum.Material.Glass,Color3.fromRGB(170,224,235),false,0.27)
	sheet.CastShadow=false
end
local mistPart=part(cliff,"MistSource",Vector3.new(80,2,25),CFrame.new(-870,25,-720),Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1)
mistPart.CanQuery=false
local mist=Instance.new("ParticleEmitter")
mist.Texture="rbxasset://textures/particles/smoke_main.dds"
mist.Rate=34
mist.Lifetime=NumberRange.new(1.2,2.4)
mist.Speed=NumberRange.new(4,8)
mist.SpreadAngle=Vector2.new(50,20)
mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,7)})
mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.55),NumberSequenceKeypoint.new(1,1)})
mist.Color=ColorSequence.new(Color3.fromRGB(223,240,242))
mist.Parent=mistPart
local wfSound=Instance.new("Sound")
wfSound.Name="WaterfallAmbience"
wfSound.SoundId="rbxassetid://9120550180"
wfSound.Looped=true
wfSound.Volume=0.4
wfSound.RollOffMaxDistance=220
wfSound.Parent=mistPart

-- decorate cliff with actual forest-pack rocks
local rockPlacements=0
for i=1,34 do
	local x=-1035 + rng:NextNumber(0,330)
	local z=-770 + rng:NextNumber(-20,50)
	local y=rng:NextNumber(30,110)
	local m=placeModel(randomFrom(rockPool),folders.Rocks,Vector3.new(x,y,z),rng:NextNumber(1.2,2.4),rng:NextNumber(0,math.pi*2))
	if m then rockPlacements += 1 end
end

-- =====================================================================
-- BRIDGE: ornate wooden bridge with rope handrails.
-- =====================================================================
local function beamBetween(parent,a,b,width,color,curve0,curve1)
	local p0=part(parent,"BeamAnchor",Vector3.new(.2,.2,.2),CFrame.new(a),Enum.Material.SmoothPlastic,color,false,1)
	local p1=part(parent,"BeamAnchor",Vector3.new(.2,.2,.2),CFrame.new(b),Enum.Material.SmoothPlastic,color,false,1)
	p0.CanQuery=false p1.CanQuery=false
	local at0=Instance.new("Attachment"); at0.Parent=p0
	local at1=Instance.new("Attachment"); at1.Parent=p1
	local beam=Instance.new("Beam")
	beam.Attachment0=at0
	beam.Attachment1=at1
	beam.Width0=width
	beam.Width1=width
	beam.FaceCamera=true
	beam.Color=ColorSequence.new(color)
	beam.CurveSize0=curve0 or 0
	beam.CurveSize1=curve1 or 0
	beam.Parent=parent
	return beam
end

local function createWoodBridge(center, span, width)
	local model=Instance.new("Model")
	model.Name="ReferenceWoodBridge"
	model.Parent=folders.Bridges
	local wood=Color3.fromRGB(116,78,49)
	local dark=Color3.fromRGB(84,56,38)
	local N=30
	for i=0,N do
		local t=i/N
		local z=(t-.5)*span
		local y=math.sin(t*math.pi)*4.5
		local plank=part(model,"BridgePlank",Vector3.new(width,.75,span/N+0.45),CFrame.new(center+Vector3.new(0,y,z)),Enum.Material.WoodPlanks,wood,true,0)
		plank.CFrame=CFrame.new(center+Vector3.new(0,y,z))
	end
	for side=-1,1,2 do
		local points={}
		for i=0,10 do
			local t=i/10
			local z=(t-.5)*span
			local y=math.sin(t*math.pi)*4.5
			local pos=center+Vector3.new(side*(width/2-.65),y+3.7,z)
			part(model,"RailPost",Vector3.new(.7,5,.7),CFrame.new(pos-Vector3.new(0,1.3,0)),Enum.Material.Wood,dark,true,0)
			table.insert(points,pos)
		end
		for i=1,#points-1 do
			beamBetween(model,points[i],points[i+1],.38,Color3.fromRGB(111,82,53),-0.8,0.8)
		end
	end
	-- support piles
	for _,z in ipairs({-span*.31,0,span*.31}) do
		for side=-1,1,2 do
			part(model,"BridgeSupport",Vector3.new(1.4,9,1.4),CFrame.new(center+Vector3.new(side*(width/2-1),-2,z)),Enum.Material.Wood,dark,true,0)
		end
	end
	clearGrass(Vector3.new(center.X,20,center.Z-span/2),width+20,24)
	clearGrass(Vector3.new(center.X,20,center.Z+span/2),width+20,24)
	return model
end
createWoodBridge(Vector3.new(-120,19,40),78,15)

-- stepping-stone river crossing using actual rock models
local stepping=Instance.new("Model")
stepping.Name="ReferenceSteppingStones"
stepping.Parent=folders.Bridges
for i=-4,4 do
	local x=430+i*13
	local z=128 + math.sin(i*.9)*5
	local m=placeModel(randomFrom(rockPool),stepping,Vector3.new(x,14,z),rng:NextNumber(.85,1.35),rng:NextNumber(0,math.pi*2))
	if m then
		for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end
	end
end

-- =====================================================================
-- TORII / shrine gate like reference.
-- =====================================================================
local torii=Instance.new("Model")
torii.Name="StoneToriiGate"
torii.Parent=folders.Torii
local tc=Color3.fromRGB(67,68,64)
local base=Vector3.new(355,20,530)
for _,x in ipairs({-13,13}) do
	part(torii,"ToriiPillar",Vector3.new(3.8,25,3.8),CFrame.new(base+Vector3.new(x,12.5,0)),Enum.Material.Slate,tc,true,0)
	part(torii,"ToriiFoot",Vector3.new(7,2.2,7),CFrame.new(base+Vector3.new(x,1.1,0)),Enum.Material.Slate,Color3.fromRGB(84,84,77),true,0)
end
part(torii,"UpperBeam",Vector3.new(37,4,4.2),CFrame.new(base+Vector3.new(0,25,0)),Enum.Material.Slate,tc,true,0)
part(torii,"TopBeam",Vector3.new(43,3,4.6),CFrame.new(base+Vector3.new(0,30,0))*CFrame.Angles(0,0,math.rad(-1.5)),Enum.Material.Slate,Color3.fromRGB(61,62,58),true,0)
part(torii,"InnerBeam",Vector3.new(29,2.2,3),CFrame.new(base+Vector3.new(0,20.7,0)),Enum.Material.Slate,tc,true,0)
beamBetween(torii,base+Vector3.new(-11,18,2.5),base+Vector3.new(11,18,2.5),.55,Color3.fromRGB(128,103,71),-4,4)
clearGrass(base,55,32)

-- =====================================================================
-- OVERGROWN TEMPLE RUINS: columns, segmented arches, courtyard, vines.
-- =====================================================================
local ruins=Instance.new("Model")
ruins.Name="OvergrownTempleRuins"
ruins.Parent=folders.TempleRuins
local stone=Color3.fromRGB(177,167,139)
local stone2=Color3.fromRGB(152,148,128)
local moss=Color3.fromRGB(70,103,55)
local RBASE=Vector3.new(720,21,-560)

local function createColumn(parent,pos,height,radius)
	local baseP=part(parent,"ColumnBase",Vector3.new(radius*3,1.4,radius*3),CFrame.new(pos+Vector3.new(0,.7,0)),Enum.Material.Sandstone,stone2,true,0)
	local shaft=part(parent,"ColumnShaft",Vector3.new(height,radius*2,radius*2),CFrame.new(pos+Vector3.new(0,1.4+height/2,0))*CFrame.Angles(0,0,math.rad(90)),Enum.Material.Sandstone,stone,true,0)
	shaft.Shape=Enum.PartType.Cylinder
	part(parent,"ColumnCap",Vector3.new(radius*3.4,1.5,radius*3.4),CFrame.new(pos+Vector3.new(0,height+2.15,0)),Enum.Material.Sandstone,stone2,true,0)
	return height+2.9
end

local function createArch(parent,center,width,height,depth)
	local pillarH=height-width*.28
	local pillarW=3.3
	part(parent,"ArchPillar",Vector3.new(pillarW,pillarH,depth),CFrame.new(center+Vector3.new(-width/2+pillarW/2,pillarH/2,0)),Enum.Material.Sandstone,stone,true,0)
	part(parent,"ArchPillar",Vector3.new(pillarW,pillarH,depth),CFrame.new(center+Vector3.new(width/2-pillarW/2,pillarH/2,0)),Enum.Material.Sandstone,stone,true,0)
	local radius=width/2-pillarW/2
	local cy=pillarH
	local segments=11
	for i=0,segments-1 do
		local a0=math.pi-(i/segments)*math.pi
		local a1=math.pi-((i+1)/segments)*math.pi
		local a=(a0+a1)/2
		local x=math.cos(a)*radius
		local y=math.sin(a)*radius
		local segLen=math.max(2.2,radius*math.pi/segments*1.15)
		part(parent,"ArchStone",Vector3.new(segLen,3.5,depth),CFrame.new(center+Vector3.new(x,cy+y,0))*CFrame.Angles(0,0,a-math.pi/2),Enum.Material.Sandstone,stone,true,0)
	end
end

-- courtyard floor with broken slabs and grass-free gaps
clearGrass(RBASE,210,180)
for x=-4,4 do
	for z=-3,3 do
		if rng:NextNumber() > .16 then
			local px=RBASE.X+x*20+rng:NextNumber(-1.2,1.2)
			local pz=RBASE.Z+z*19+rng:NextNumber(-1.2,1.2)
			local slab=part(ruins,"AncientFloorSlab",Vector3.new(18,1.1,17),CFrame.new(px,21.2,pz)*CFrame.Angles(0,rng:NextNumber(-.035,.035),rng:NextNumber(-.025,.025)),Enum.Material.Sandstone,Color3.fromRGB(167,158,134),true,0)
		end
	end
end

-- gallery of arches
for i=-2,2 do
	createArch(ruins,RBASE+Vector3.new(i*27,1,-58),22,25,5)
end
-- columns toward central shrine
for side=-1,1,2 do
	for i=0,4 do
		createColumn(ruins,RBASE+Vector3.new(side*53,0,-28+i*25),22,2.1)
	end
end
-- central raised altar/temple remnant
part(ruins,"TemplePlatform",Vector3.new(70,4,48),CFrame.new(RBASE+Vector3.new(0,2,55)),Enum.Material.Sandstone,stone2,true,0)
for _,x in ipairs({-25,25}) do
	createColumn(ruins,RBASE+Vector3.new(x,4,42),28,2.4)
	createColumn(ruins,RBASE+Vector3.new(x,4,68),28,2.4)
end
part(ruins,"BrokenLintel",Vector3.new(60,5,6),CFrame.new(RBASE+Vector3.new(0,35,42))*CFrame.Angles(0,0,math.rad(2)),Enum.Material.Sandstone,stone,true,0)

-- vines around columns and arches using beams
for i=1,15 do
	local x=RBASE.X+rng:NextNumber(-60,60)
	local z=RBASE.Z+rng:NextNumber(-70,80)
	local y1=rng:NextNumber(23,32)
	local y2=y1+rng:NextNumber(8,18)
	beamBetween(ruins,Vector3.new(x,y1,z),Vector3.new(x+rng:NextNumber(-5,5),y2,z+rng:NextNumber(-3,3)),.3,moss,rng:NextNumber(-3,3),rng:NextNumber(-3,3))
end

-- actual bushes/rocks around ruins, but keep floor clear
for i=1,34 do
	local a=rng:NextNumber(0,math.pi*2)
	local r=rng:NextNumber(95,125)
	local x=RBASE.X+math.cos(a)*r
	local z=RBASE.Z+math.sin(a)*r
	local hit=terrainHit(x,z)
	if hit then
		placeModel(randomFrom((i%3==0) and rockPool or bushPool),folders.Details,hit,rng:NextNumber(.8,1.35),rng:NextNumber(0,math.pi*2))
	end
end

-- =====================================================================
-- VEGETATION FROM REAL FOREST PACK.
-- =====================================================================
local exclusions = {
	{Vector2.new(-495,455),205},
	{Vector2.new(470,610),125},
	{Vector2.new(-870,-760),220},
	{Vector2.new(-120,40),78},
	{Vector2.new(355,530),55},
	{Vector2.new(RBASE.X,RBASE.Z),120},
}

local function distanceToSegment(p,a,b)
	local ab=b-a
	local den=ab:Dot(ab)
	local t=den>0 and math.clamp((p-a):Dot(ab)/den,0,1) or 0
	return (p-(a+ab*t)).Magnitude
end

local function nearRiver(x,z,margin)
	local p=Vector2.new(x,z)
	for i=1,#river-1 do
		local a=Vector2.new(river[i].X,river[i].Z)
		local b=Vector2.new(river[i+1].X,river[i+1].Z)
		if distanceToSegment(p,a,b)<42+margin then return true end
	end
	return false
end

local function excluded(x,z,margin)
	local p=Vector2.new(x,z)
	for _,e in ipairs(exclusions) do
		if (p-e[1]).Magnitude<e[2]+margin then return true end
	end
	if nearRiver(x,z,margin) then return true end
	return false
end

local treePlacements,bushPlacements,flowerPlacements=0,0,0

-- hero tree on island
local islandHit=terrainHit(-500,455)
if islandHit then
	local m=placeModel(randomFrom(treePool),folders.Trees,islandHit,2.15,0.4)
	if m then treePlacements+=1 end
end

-- forest clusters with deliberate open meadows
local clusterCenters = {
	Vector2.new(-980,500),Vector2.new(-780,350),Vector2.new(-1000,-80),
	Vector2.new(-650,-350),Vector2.new(-320,-700),Vector2.new(120,-850),
	Vector2.new(420,-760),Vector2.new(960,-420),Vector2.new(950,320),
	Vector2.new(760,720),Vector2.new(260,900),Vector2.new(-480,930)
}

for _,c in ipairs(clusterCenters) do
	for i=1,14 do
		local a=rng:NextNumber(0,math.pi*2)
		local r=math.sqrt(rng:NextNumber())*170
		local x=c.X+math.cos(a)*r
		local z=c.Y+math.sin(a)*r
		if math.abs(x)<1240 and math.abs(z)<1240 and not excluded(x,z,12) then
			local hit,normal,mat=terrainHit(x,z)
			if hit and normal.Y>.76 and mat==Enum.Material.Grass then
				local m=placeModel(randomFrom(treePool),folders.Trees,hit,rng:NextNumber(.78,1.38),rng:NextNumber(0,math.pi*2))
				if m then treePlacements+=1 end
			end
		end
	end
end

-- scattered meadow trees
local attempts=0
while treePlacements<190 and attempts<2400 do
	attempts+=1
	local x=rng:NextNumber(-1220,1220)
	local z=rng:NextNumber(-1220,1220)
	if not excluded(x,z,14) then
		local hit,normal,mat=terrainHit(x,z)
		if hit and normal.Y>.8 and mat==Enum.Material.Grass then
			local m=placeModel(randomFrom(treePool),folders.Trees,hit,rng:NextNumber(.72,1.2),rng:NextNumber(0,math.pi*2))
			if m then treePlacements+=1 end
		end
	end
end

attempts=0
while bushPlacements<260 and attempts<2500 do
	attempts+=1
	local x=rng:NextNumber(-1220,1220)
	local z=rng:NextNumber(-1220,1220)
	if not excluded(x,z,4) then
		local hit,normal,mat=terrainHit(x,z)
		if hit and normal.Y>.82 and mat==Enum.Material.Grass then
			local m=placeModel(randomFrom(bushPool),folders.Bushes,hit,rng:NextNumber(.7,1.25),rng:NextNumber(0,math.pi*2))
			if m then
				for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
				bushPlacements+=1
			end
		end
	end
end

attempts=0
while flowerPlacements<360 and attempts<3300 do
	attempts+=1
	local x=rng:NextNumber(-1180,1180)
	local z=rng:NextNumber(-1180,1180)
	if not excluded(x,z,2) then
		local hit,normal,mat=terrainHit(x,z)
		if hit and normal.Y>.86 and mat==Enum.Material.Grass then
			local m=placeModel(randomFrom(flowerPool),folders.Flowers,hit,rng:NextNumber(.55,.95),rng:NextNumber(0,math.pi*2))
			if m then
				for _,p in ipairs(m:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide=false p.CanQuery=false end
				end
				flowerPlacements+=1
			end
		end
	end
end

-- lake/river bank rocks from official pack
for i=1,95 do
	local chooseLake=rng:NextNumber()<.55
	local center=chooseLake and Vector2.new(-495,455) or Vector2.new(470,610)
	local radius=chooseLake and rng:NextNumber(145,195) or rng:NextNumber(92,130)
	local a=rng:NextNumber(0,math.pi*2)
	local x=center.X+math.cos(a)*radius
	local z=center.Y+math.sin(a)*radius
	local hit=terrainHit(x,z)
	if hit then
		local m=placeModel(randomFrom(rockPool),folders.Rocks,hit,rng:NextNumber(.65,1.45),rng:NextNumber(0,math.pi*2))
		if m then
			clearGrass(hit,5,5)
			rockPlacements+=1
		end
	end
end

-- =====================================================================
-- LAMP POSTS: current asset, placed along paths.
-- =====================================================================
local lampTemplate
for _,c in ipairs(lampAsset:GetChildren()) do
	if c:IsA("Model") then lampTemplate=c break end
end
assert(lampTemplate,"Lamp post model missing")

local lamps={
	Vector3.new(0,0,1030),Vector3.new(0,0,900),Vector3.new(-25,0,760),
	Vector3.new(-100,0,600),Vector3.new(-210,0,450),Vector3.new(-310,0,285),
	Vector3.new(-250,0,85),Vector3.new(-90,0,-80),Vector3.new(120,0,-220),
	Vector3.new(320,0,-365),Vector3.new(540,0,-480),
	Vector3.new(145,0,625),Vector3.new(285,0,565),Vector3.new(440,0,470),
}
local lampCount=0
for i,p in ipairs(lamps) do
	local hit=terrainHit(p.X,p.Z)
	if hit then
		local clone=lampTemplate:Clone()
		clone.Name="PathLamp_"..i
		clone.Parent=folders.LampPosts
		setAnchored(clone)
		local _,size=clone:GetBoundingBox()
		local box=clone:GetBoundingBox()
		local pivot=clone:GetPivot()
		local bottom=box.Position.Y-size.Y/2
		local offset=pivot.Position.Y-bottom
		clone:PivotTo(CFrame.new(hit+Vector3.new(0,offset,0)))
		clearGrass(hit,7,7)
		lampCount+=1
	end
end

-- =====================================================================
-- LIGHTING / SKY: bright stylized anime-like daylight.
-- =====================================================================
Lighting.ClockTime=14.2
Lighting.Brightness=2.7
Lighting.ExposureCompensation=0.08
Lighting.Ambient=Color3.fromRGB(110,123,110)
Lighting.OutdoorAmbient=Color3.fromRGB(155,166,149)
Lighting.EnvironmentDiffuseScale=.55
Lighting.EnvironmentSpecularScale=.7
Lighting.ShadowSoftness=.38
pcall(function() Lighting.Technology=Enum.Technology.Future end)

local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="ReferenceAtmosphere"
atmosphere.Density=.2
atmosphere.Offset=.08
atmosphere.Color=Color3.fromRGB(210,231,236)
atmosphere.Decay=Color3.fromRGB(130,151,143)
atmosphere.Glare=.11
atmosphere.Haze=.75
atmosphere.Parent=Lighting

local cc=Instance.new("ColorCorrectionEffect")
cc.Name="ReferenceColor"
cc.Brightness=.025
cc.Contrast=.1
cc.Saturation=.12
cc.TintColor=Color3.fromRGB(244,250,239)
cc.Parent=Lighting

local rays=Instance.new("SunRaysEffect")
rays.Name="ReferenceSunRays"
rays.Intensity=.07
rays.Spread=.78
rays.Parent=Lighting

local bloom=Instance.new("BloomEffect")
bloom.Name="ReferenceBloom"
bloom.Intensity=.14
bloom.Size=18
bloom.Threshold=1.25
bloom.Parent=Lighting

local clouds=Instance.new("Clouds")
clouds.Name="ReferenceClouds"
clouds.Cover=.28
clouds.Density=.32
clouds.Color=Color3.fromRGB(250,251,248)
clouds.Parent=Terrain

-- =====================================================================
-- AMBIENCE + occasional rain, starts clear like screenshots.
-- =====================================================================
local forestSound=Instance.new("Sound")
forestSound.Name="TreeWorldForestAmbience"
forestSound.SoundId="rbxassetid://9113047896"
forestSound.Looped=true
forestSound.Volume=.1
forestSound.Parent=SoundService

local rainSound=Instance.new("Sound")
rainSound.Name="TreeWorldRainAmbience"
rainSound.SoundId="rbxassetid://1516791621"
rainSound.Looped=true
rainSound.Volume=0
rainSound.Parent=SoundService

local weatherClient=Instance.new("LocalScript")
weatherClient.Name="TreeWorldWeatherClient"
weatherClient.Source=[=[
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local TweenService=game:GetService("TweenService")
local Workspace=game:GetService("Workspace")
local forest=SoundService:WaitForChild("TreeWorldForestAmbience")
local rain=SoundService:WaitForChild("TreeWorldRainAmbience")
forest:Play()
rain:Play()

local rig=Instance.new("Part")
rig.Name="_LocalRain"
rig.Size=Vector3.new(80,1,80)
rig.Anchored=true
rig.Transparency=1
rig.CanCollide=false
rig.CanTouch=false
rig.CanQuery=false
rig.Parent=Workspace

local emitter=Instance.new("ParticleEmitter")
emitter.Texture="rbxasset://textures/particles/rain_main.dds"
emitter.Rate=0
emitter.Lifetime=NumberRange.new(.65,.95)
emitter.Speed=NumberRange.new(62,75)
emitter.Acceleration=Vector3.new(6,-22,3)
emitter.SpreadAngle=Vector2.new(7,7)
emitter.Size=NumberSequence.new(.08)
emitter.Parent=rig

local function update()
	local wet=Workspace:GetAttribute("Weather")=="Rain"
	emitter.Rate=wet and 280 or 0
	TweenService:Create(rain,TweenInfo.new(1),{Volume=wet and .22 or 0}):Play()
	TweenService:Create(forest,TweenInfo.new(1),{Volume=wet and .06 or .1}):Play()
end
Workspace:GetAttributeChangedSignal("Weather"):Connect(update)
update()
RunService.RenderStepped:Connect(function()
	local cam=Workspace.CurrentCamera
	if cam then rig.CFrame=CFrame.new(cam.CFrame.Position+Vector3.new(0,34,0)) end
end)
]=]
weatherClient.Parent=sps

local weatherServer=Instance.new("Script")
weatherServer.Name="TreeWorldWeatherServer"
weatherServer.Source=[=[
local Workspace=game:GetService("Workspace")
Workspace:SetAttribute("Weather","Clear")
Workspace.GlobalWind=Vector3.new(5.5,0,2.6)
task.spawn(function()
	while true do
		task.wait(300)
		Workspace:SetAttribute("Weather","Rain")
		Workspace.GlobalWind=Vector3.new(8,0,4)
		task.wait(85)
		Workspace:SetAttribute("Weather","Clear")
		Workspace.GlobalWind=Vector3.new(5.5,0,2.6)
	end
end)
]=]
weatherServer.Parent=ServerScriptService

-- =====================================================================
-- CAMPFIRE: placeable, clears grass, 8 log seats, temporary fire effect.
-- =====================================================================
local remote=Instance.new("RemoteEvent")
remote.Name="PlaceCampfire"
remote.Parent=ReplicatedStorage

local campServer=Instance.new("Script")
campServer.Name="TreeWorldCampfireServer"
campServer.Source=[=[
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local Terrain=Workspace.Terrain
local remote=ReplicatedStorage:WaitForChild("PlaceCampfire")
local folder=Workspace.ForestWorld:WaitForChild("Campfires")
local active={}
local cool={}

local function mk(parent,name,size,cf,material,color,collide,trans)
	local p=Instance.new("Part")
	p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true;p.Material=material;p.Color=color
	p.CanCollide=collide;p.Transparency=trans or 0;p.Parent=parent
	return p
end

local function groundAt(pos)
	local hit=Workspace:Raycast(pos+Vector3.new(0,35,0),Vector3.new(0,-80,0))
	if hit and hit.Instance==Terrain and hit.Material~=Enum.Material.Water and hit.Normal.Y>.8 then return hit.Position end
end

local function clear(pos)
	local r=Region3.new(pos-Vector3.new(13,6,13),pos+Vector3.new(13,6,13)):ExpandToGrid(4)
	pcall(function() Terrain:ReplaceMaterial(r,4,Enum.Material.Grass,Enum.Material.Ground) end)
end

local function build(player,pos)
	if active[player] then active[player]:Destroy() end
	clear(pos)
	local m=Instance.new("Model");m.Name="Campfire_"..player.UserId;m.Parent=folder;active[player]=m
	local ground=mk(m,"BareGround",Vector3.new(23,.25,23),CFrame.new(pos+Vector3.new(0,.08,0)),Enum.Material.Ground,Color3.fromRGB(100,82,62),false,.05)
	for i=1,12 do
		local a=i/12*math.pi*2
		mk(m,"RingStone",Vector3.new(1.7,1.1,1.3),CFrame.new(pos+Vector3.new(math.cos(a)*3.5,.55,math.sin(a)*3.5))*CFrame.Angles(0,-a,0),Enum.Material.Slate,Color3.fromRGB(100,98,92),true,0)
	end
	local core=mk(m,"FireCore",Vector3.new(2,1,2),CFrame.new(pos+Vector3.new(0,1,0)),Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1)
	local fire=Instance.new("Fire");fire.Size=7;fire.Heat=4;fire.Parent=core
	local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,181,95);light.Brightness=2;light.Range=24;light.Shadows=true;light.Parent=core
	local sound=Instance.new("Sound");sound.SoundId="rbxasset://sounds/fire.mp3";sound.Looped=true;sound.Volume=.3;sound.Parent=core;sound:Play()
	for i=1,8 do
		local a=i/8*math.pi*2
		local pos2=pos+Vector3.new(math.cos(a)*9.3,1,math.sin(a)*9.3)
		local log=mk(m,"LogBench",Vector3.new(5.8,1.3,1.6),CFrame.new(pos2)*CFrame.Angles(0,-a+math.pi/2,0),Enum.Material.Wood,Color3.fromRGB(103,70,47),true,0)
		local seat=Instance.new("Seat");seat.Name="LogSeat";seat.Size=Vector3.new(4.7,.5,1.4);seat.CFrame=log.CFrame*CFrame.new(0,.9,0);seat.Anchored=true;seat.Transparency=1;seat.CanCollide=false;seat.Parent=m
	end
	local hazard=mk(m,"FireHazard",Vector3.new(4.5,3,4.5),CFrame.new(pos+Vector3.new(0,1.5,0)),Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1)
	local recent={}
	hazard.Touched:Connect(function(hit)
		local character=hit:FindFirstAncestorOfClass("Model")
		local hum=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if hum and root and not recent[hum] then
			recent[hum]=true
			local fx=Instance.new("Fire");fx.Name="TemporaryCampfireEffect";fx.Size=4;fx.Heat=2;fx.Parent=root
			hum:TakeDamage(4)
			task.delay(2.2,function() if fx.Parent then fx:Destroy() end recent[hum]=nil end)
		end
	end)
end

remote.OnServerEvent:Connect(function(player)
	local now=os.clock()
	if cool[player] and now-cool[player]<2 then return end
	cool[player]=now
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local pos=groundAt(root.Position+root.CFrame.LookVector*9)
	if pos then build(player,pos) end
end)
Players.PlayerRemoving:Connect(function(p) if active[p] then active[p]:Destroy() end active[p]=nil cool[p]=nil end)
]=]
campServer.Parent=ServerScriptService

local campClient=Instance.new("LocalScript")
campClient.Name="TreeWorldCampfireClient"
campClient.Source=[=[
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("PlaceCampfire")
local gui=Instance.new("ScreenGui");gui.Name="TreeWorldCampfireUI";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local b=Instance.new("TextButton");b.AnchorPoint=Vector2.new(.5,1);b.Size=UDim2.fromOffset(108,34);b.Position=UDim2.new(.5,0,1,-18);b.BackgroundColor3=Color3.fromRGB(34,35,31);b.BackgroundTransparency=.2;b.BorderSizePixel=0;b.Font=Enum.Font.GothamMedium;b.TextSize=12;b.TextColor3=Color3.fromRGB(248,246,238);b.Text="Fogueira";b.Parent=gui
local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,9);c.Parent=b
local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(248,246,238);s.Transparency=.84;s.Parent=b
local busy=false
local function place()
	if busy then return end
	busy=true;remote:FireServer();b.Text="Colocando..."
	task.delay(1.2,function() b.Text="Fogueira";busy=false end)
end
b.Activated:Connect(place)
UserInputService.InputBegan:Connect(function(i,g) if not g and i.KeyCode==Enum.KeyCode.C then place() end end)
]=]
campClient.Parent=sps

-- =====================================================================
-- SPAWN at bright meadow entrance.
-- =====================================================================
local spawnGround=terrainHit(0,1120) or Vector3.new(0,20,1120)
clearGrass(spawnGround,32,32)
local spawn=Instance.new("SpawnLocation")
spawn.Name="ForestSpawn"
spawn.Size=Vector3.new(8,.2,8)
spawn.Position=spawnGround+Vector3.new(0,3.5,0)
spawn.Anchored=true
spawn.Enabled=true
spawn.Neutral=true
spawn.Transparency=1
spawn.CanCollide=false
spawn.Duration=0
spawn.Parent=world

-- Pack templates no longer needed after placement.
forestAsset:Destroy()
lampAsset:Destroy()

Workspace:SetAttribute("Weather","Clear")
Workspace:SetAttribute("WorldRebuildComplete",true)
Workspace:SetAttribute("WorldRebuildVersion",VERSION)
Workspace:SetAttribute("ReferenceStyleTarget","UserReferenceSet-2026-10-15")
Workspace:SetAttribute("OfficialForestPackUsed",true)
Workspace:SetAttribute("TreePlacementCount",treePlacements)
Workspace:SetAttribute("BushPlacementCount",bushPlacements)
Workspace:SetAttribute("FlowerPlacementCount",flowerPlacements)
Workspace:SetAttribute("RockPlacementCount",rockPlacements)
Workspace:SetAttribute("LampPlacementCount",lampCount)
Workspace:SetAttribute("BridgeCount",2)
Workspace:SetAttribute("TempleRuinsPresent",true)
Workspace:SetAttribute("ToriiPresent",true)

local sourceVersion=game.PlaceVersion
AssetService:SavePlaceAsync()

return {
	ok=true,
	sourceVersion=sourceVersion,
	version=VERSION,
	treeCandidates=#treePool,
	rockCandidates=#rockPool,
	trees=treePlacements,
	bushes=bushPlacements,
	flowers=flowerPlacements,
	rocks=rockPlacements,
	lamps=lampCount,
	spawn={x=spawn.Position.X,y=spawn.Position.Y,z=spawn.Position.Z},
}
