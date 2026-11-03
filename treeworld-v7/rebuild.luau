local AssetService=game:GetService("AssetService")
local InsertService=game:GetService("InsertService")
local Lighting=game:GetService("Lighting")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local SoundService=game:GetService("SoundService")
local StarterGui=game:GetService("StarterGui")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")

local HOUSE_ASSET_ID=115962225394318
local PORTAL_ASSET_ID=113932150476095
local VERSION="2026-10-19-bridge-ruins-darkzone-v7"
local Terrain=Workspace.Terrain
local rng=Random.new(1910202607)
local BASE_Y=20

local function low(v) return string.lower(tostring(v or "")) end
local function hasAny(text,words)
	text=low(text)
	for _,w in ipairs(words) do if string.find(text,w,1,true) then return true end end
	return false
end

local function stripScripts(root)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then d:Destroy() end
	end
end

local function anchor(root)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored=true
			d.CanTouch=false
		end
	end
end

local function loadModel(assetId,name)
	local box=InsertService:LoadAsset(assetId)
	stripScripts(box)
	local children=box:GetChildren()
	local model=nil
	if #children==1 and children[1]:IsA("Model") then
		model=children[1]
		model.Parent=nil
	else
		model=Instance.new("Model")
		for _,c in ipairs(children) do c.Parent=model end
	end
	box:Destroy()
	model.Name=name
	anchor(model)
	return model
end

local function part(parent,name,size,cf,material,color,collide,trans)
	local p=Instance.new("Part")
	p.Name=name
	p.Size=size
	p.CFrame=cf
	p.Anchored=true
	p.Material=material
	p.Color=color
	p.CanCollide=collide
	p.CanTouch=false
	p.CanQuery=true
	p.CastShadow=true
	p.Transparency=trans or 0
	p.TopSurface=Enum.SurfaceType.Smooth
	p.BottomSurface=Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end

local function folder(parent,name)
	local f=Instance.new("Folder");f.Name=name;f.Parent=parent;return f
end

local function ground(x,z)
	local r=Workspace:Raycast(Vector3.new(x,240,z),Vector3.new(0,-520,0))
	if r and r.Instance==Terrain and r.Material~=Enum.Material.Water then return r.Position end
	if math.abs(x)<=1500 and math.abs(z)<=1500 then return Vector3.new(x,BASE_Y,z) end
	return nil
end

local function clearGrass(center,sx,sz)
	local region=Region3.new(center-Vector3.new(sx/2,7,sz/2),center+Vector3.new(sx/2,7,sz/2)):ExpandToGrid(4)
	pcall(function() Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.Ground) end)
end

local function placeOnGround(model,x,z,yaw,targetMax)
	if targetMax then
		local _,s=model:GetBoundingBox()
		local mx=math.max(s.X,s.Y,s.Z)
		if mx>0 then pcall(function() model:ScaleTo(targetMax/mx) end) end
	end
	anchor(model)
	local g=ground(x,z)
	assert(g,"No ground")
	local cf,s=model:GetBoundingBox()
	local pivot=model:GetPivot()
	local bottom=cf.Position.Y-s.Y/2
	local off=pivot.Position.Y-bottom
	model:PivotTo(CFrame.new(x,g.Y+off,z)*CFrame.Angles(0,yaw or 0,0))
	local cf2,s2=model:GetBoundingBox()
	return g,s2,cf2.Position.Y-s2.Y/2
end

-- ============================================================
-- HARD RESET. NOTHING FROM OLD MAP/UI SURVIVES.
-- ============================================================
for _,c in ipairs(Workspace:GetChildren()) do
	if c~=Terrain and not c:IsA("Camera") then c:Destroy() end
end
Terrain:Clear()
for _,c in ipairs(StarterGui:GetChildren()) do c:Destroy() end
for _,c in ipairs(ReplicatedFirst:GetChildren()) do c:Destroy() end
for _,c in ipairs(ReplicatedStorage:GetChildren()) do c:Destroy() end
for _,c in ipairs(ServerScriptService:GetChildren()) do c:Destroy() end
for _,c in ipairs(SoundService:GetChildren()) do c:Destroy() end
local sps=StarterPlayer:WaitForChild("StarterPlayerScripts")
local scs=StarterPlayer:WaitForChild("StarterCharacterScripts")
for _,c in ipairs(sps:GetChildren()) do c:Destroy() end
for _,c in ipairs(scs:GetChildren()) do c:Destroy() end
for _,c in ipairs(Lighting:GetChildren()) do
	if c:IsA("PostEffect") or c:IsA("Atmosphere") or c:IsA("Sky") then c:Destroy() end
end

pcall(function() Workspace.StreamingEnabled=true end)
pcall(function() Workspace.StreamingMinRadius=96 end)
pcall(function() Workspace.StreamingTargetRadius=340 end)
pcall(function() Workspace.GlobalWind=Vector3.new(3.8,0,1.5) end)
pcall(function() Terrain.Decoration=true end)
pcall(function() Terrain.GrassLength=.24 end)
pcall(function() Terrain.WaterColor=Color3.fromRGB(55,116,148) end)
pcall(function() Terrain.WaterTransparency=.2 end)
pcall(function() Terrain.WaterReflectance=.26 end)
pcall(function() Terrain.WaterWaveSize=.035 end)
pcall(function() Terrain.WaterWaveSpeed=7 end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(69,103,70)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(82,78,66)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(93,91,88)) end)

local world=folder(Workspace,"ReferenceWorld")
local F={}
for _,n in ipairs({"Forest","Path","Torii","House","Portals","Water","MainBridge","Ruins","DarkZone","Details","Spawn"}) do
	F[n]=folder(world,n)
end

-- ============================================================
-- MAP BASE: LARGE, FLAT, BUT NOT EMPTY.
-- ============================================================
local HALF=1450
local CHUNK=250
for x=-HALF+CHUNK/2,HALF-CHUNK/2,CHUNK do
	for z=-HALF+CHUNK/2,HALF-CHUNK/2,CHUNK do
		Terrain:FillBlock(CFrame.new(x,-6,z),Vector3.new(CHUNK+6,52,CHUNK+6),Enum.Material.Grass)
	end
end
Terrain:FillBlock(CFrame.new(0,-38,0),Vector3.new(2950,32,2950),Enum.Material.Rock)

-- Gentle shallow wave-lines sunk into the otherwise flat floor.
for lane=-5,5 do
	local z=1100-lane*125
	for s=0,10 do
		local x=-420+s*84
		local y=19.15
		local zz=z+math.sin((s+lane)*.75)*8
		local groove=part(F.Details,"GroundGroove",Vector3.new(72,.7,2.4),CFrame.new(x,y,zz)*CFrame.Angles(0,math.rad(math.sin(s*.8)*6),0),Enum.Material.Ground,Color3.fromRGB(67,65,58),false,.04)
		groove.CanQuery=false
	end
end

-- ============================================================
-- SPAWN + ONE TORII. NOT FAR.
-- ============================================================
local spawnPos=Vector3.new(0,23.2,760)
local spawn=Instance.new("SpawnLocation")
spawn.Name="ForestSpawn";spawn.Size=Vector3.new(7,.2,7);spawn.Position=spawnPos
spawn.Anchored=true;spawn.Enabled=true;spawn.Neutral=true;spawn.Transparency=1;spawn.CanCollide=false;spawn.Duration=0;spawn.Parent=F.Spawn

local function torii(center)
	local m=Instance.new("Model");m.Name="MainTorii";m.Parent=F.Torii
	local dark=Color3.fromRGB(48,54,56)
	local d2=Color3.fromRGB(59,64,64)
	for _,side in ipairs({-1,1}) do
		local px=side*14.5
		part(m,"Foot",Vector3.new(7.2,1.4,7.2),CFrame.new(center+Vector3.new(px,.7,0)),Enum.Material.Slate,d2,true,0)
		local p=part(m,"Post",Vector3.new(31,4.4,4.4),CFrame.new(center+Vector3.new(px,17,0))*CFrame.Angles(0,0,math.rad(90)),Enum.Material.Slate,dark,true,0)
		p.Shape=Enum.PartType.Cylinder
		part(m,"Collar",Vector3.new(5.6,2,5.6),CFrame.new(center+Vector3.new(px,30,0)),Enum.Material.Slate,d2,true,0)
	end
	part(m,"LowerBeam",Vector3.new(38,3.2,4.2),CFrame.new(center+Vector3.new(0,27,0)),Enum.Material.Slate,dark,true,0)
	part(m,"TopBeam",Vector3.new(46,3.4,4.7),CFrame.new(center+Vector3.new(0,34,0)),Enum.Material.Slate,dark,true,0)
	part(m,"TopLeft",Vector3.new(8.5,2.6,4.9),CFrame.new(center+Vector3.new(-22.5,35,0))*CFrame.Angles(0,0,math.rad(8)),Enum.Material.Slate,dark,true,0)
	part(m,"TopRight",Vector3.new(8.5,2.6,4.9),CFrame.new(center+Vector3.new(22.5,35,0))*CFrame.Angles(0,0,math.rad(-8)),Enum.Material.Slate,dark,true,0)
	local a=part(m,"RopeA",Vector3.new(.1,.1,.1),CFrame.new(center+Vector3.new(-11,23,2.3)),Enum.Material.SmoothPlastic,dark,false,1)
	local b=part(m,"RopeB",Vector3.new(.1,.1,.1),CFrame.new(center+Vector3.new(11,23,2.3)),Enum.Material.SmoothPlastic,dark,false,1)
	local aa=Instance.new("Attachment");aa.Parent=a
	local bb=Instance.new("Attachment");bb.Parent=b
	local beam=Instance.new("Beam");beam.Attachment0=aa;beam.Attachment1=bb;beam.Width0=.72;beam.Width1=.72;beam.CurveSize0=-5;beam.CurveSize1=5;beam.Segments=24;beam.FaceCamera=true;beam.Color=ColorSequence.new(Color3.fromRGB(125,97,66));beam.Parent=m
	for _,x in ipairs({-6,0,6}) do
		local t=part(m,"Tassel",Vector3.new(.7,4,.7),CFrame.new(center+Vector3.new(x,19,2.3)),Enum.Material.Wood,Color3.fromRGB(120,90,60),false,0)
	end
	clearGrass(center,60,32)
end

torii(Vector3.new(0,20,620))

-- ============================================================
-- FEW PATH STONES ONLY ON PATH. SMALL + SOME LARGE.
-- ============================================================
local stones=0
local pathZ={730,690,652,610,565,525,485,446,408,370,332,294}
for i,z in ipairs(pathZ) do
	local x=math.sin(i*.85)*4+rng:NextNumber(-2.5,2.5)
	local g=ground(x,z)
	local big=(i%4==0)
	local sx=big and rng:NextNumber(8,12) or rng:NextNumber(4,7)
	local sz=big and rng:NextNumber(10,15) or rng:NextNumber(5,9)
	clearGrass(g,sx+4,sz+4)
	part(F.Path,"PathStone",Vector3.new(sx,.55,sz),CFrame.new(x,g.Y+.18,z)*CFrame.Angles(0,math.rad(rng:NextNumber(-12,12)),math.rad(rng:NextNumber(-1,1))),Enum.Material.Slate,Color3.fromRGB(102,102,97),true,0)
	stones+=1
end

-- ============================================================
-- STRAIGHT WATER CHANNEL + DETAILED BRIDGE FROM PHOTO 1.
-- ============================================================
Terrain:FillBlock(CFrame.new(0,8,155),Vector3.new(250,22,82),Enum.Material.Air)
Terrain:FillBlock(CFrame.new(0,7,155),Vector3.new(250,12,82),Enum.Material.Water)

-- Blocky cliff banks on both sides of the straight water.
for _,side in ipairs({-1,1}) do
	local x=side*88
	Terrain:FillBlock(CFrame.new(x,14,155),Vector3.new(75,40,110),Enum.Material.Rock)
	Terrain:FillBlock(CFrame.new(x,35,155),Vector3.new(78,5,112),Enum.Material.Grass)
	for i=1,7 do
		local bx=x+side*rng:NextNumber(-22,22)
		local bz=155+rng:NextNumber(-40,40)
		part(F.Details,"BankBlock",Vector3.new(rng:NextNumber(8,18),rng:NextNumber(6,16),rng:NextNumber(8,18)),CFrame.new(bx,28+rng:NextNumber(-6,6),bz)*CFrame.Angles(0,rng:NextNumber(-.25,.25),0),Enum.Material.Rock,Color3.fromRGB(88,86,82),true,0)
	end
end

local bridge=Instance.new("Model");bridge.Name="PhotoWoodBridge";bridge.Parent=F.MainBridge
local wood=Color3.fromRGB(78,54,40)
local wood2=Color3.fromRGB(96,66,48)
local deckY=30

-- deck planks
for i=-10,10 do
	part(bridge,"DeckPlank",Vector3.new(6.2,.9,31),CFrame.new(i*5.1,deckY,155)*CFrame.Angles(0,0,math.rad(rng:NextNumber(-.8,.8))),Enum.Material.WoodPlanks,wood2,true,0)
end

-- heavy under-structure / pillars
for _,x in ipairs({-42,-14,14,42}) do
	part(bridge,"StoneFoot",Vector3.new(8,3,8),CFrame.new(x,10,155),Enum.Material.Slate,Color3.fromRGB(79,79,75),true,0)
	part(bridge,"Pillar",Vector3.new(5,39,5),CFrame.new(x,20,155),Enum.Material.Wood,wood,true,0)
	part(bridge,"CrossBrace",Vector3.new(21,3,3),CFrame.new(x,18,155)*CFrame.Angles(0,0,math.rad(35)),Enum.Material.Wood,wood,true,0)
end

-- ornate railings
for _,side in ipairs({-1,1}) do
	local z=155+side*14
	for _,x in ipairs({-50,-40,-30,-20,-10,0,10,20,30,40,50}) do
		part(bridge,"RailPost",Vector3.new(2.1,10,2.1),CFrame.new(x,35,z),Enum.Material.Wood,wood,true,0)
		part(bridge,"PostCap",Vector3.new(3.2,2,3.2),CFrame.new(x,40.3,z),Enum.Material.Wood,wood2,true,0)
	end
	part(bridge,"RailTop",Vector3.new(104,1.7,1.7),CFrame.new(0,40,z),Enum.Material.Wood,wood,true,0)
	part(bridge,"RailMid",Vector3.new(104,1.5,1.5),CFrame.new(0,35.7,z),Enum.Material.Wood,wood,true,0)
end

-- hanging vines/greenery on bridge
for i=1,12 do
	local x=rng:NextNumber(-46,46)
	local z=155+((i%2==0) and 14 or -14)
	part(bridge,"HangingVine",Vector3.new(.55,rng:NextNumber(7,16),.55),CFrame.new(x,29-rng:NextNumber(1,5),z),Enum.Material.Grass,Color3.fromRGB(72,105,58),false,0)
end

-- very low water sound close to water only
local soundAnchor=part(F.Water,"WaterSoundAnchor",Vector3.new(1,1,1),CFrame.new(0,10,155),Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1)
local waterSound=Instance.new("Sound")
waterSound.Name="QuietWater"
waterSound.SoundId="rbxassetid://9120550180"
waterSound.Looped=true
waterSound.Volume=.035
waterSound.RollOffMinDistance=7
waterSound.RollOffMaxDistance=70
waterSound.Parent=soundAnchor

-- ============================================================
-- ONE HOUSE, SUBTLE, IN BACKGROUND.
-- ============================================================
local house=loadModel(HOUSE_ASSET_ID,"JapaneseHouse")
house.Parent=F.House
local hg,hs,hb=placeOnGround(house,0,-70,math.rad(180),105)
clearGrass(hg,hs.X+12,hs.Z+12)

-- ============================================================
-- MAIN RUINS: LARGE, ANCIENT, DETAILED.
-- ============================================================
local ruins=Instance.new("Model");ruins.Name="AncientWhiteRuins";ruins.Parent=F.Ruins
local base=Vector3.new(0,20,-360)
local stone=Color3.fromRGB(208,202,190)
local stone2=Color3.fromRGB(178,174,165)
local moss=Color3.fromRGB(79,111,65)

-- broken tiled courtyard
for ix=-6,6 do
	for iz=-4,4 do
		if rng:NextNumber()>.13 then
			local px=base.X+ix*16+rng:NextNumber(-1.3,1.3)
			local pz=base.Z+iz*16+rng:NextNumber(-1.3,1.3)
			part(ruins,"FloorSlab",Vector3.new(rng:NextNumber(13,16),1,rng:NextNumber(13,16)),CFrame.new(px,20.4,pz)*CFrame.Angles(0,rng:NextNumber(-.05,.05),rng:NextNumber(-.02,.02)),Enum.Material.Limestone,(rng:NextNumber()<.25 and stone2 or stone),true,0)
		end
	end
end
clearGrass(base,235,175)

local function column(pos,height,radius,broken)
	part(ruins,"ColumnBase",Vector3.new(radius*3,1.3,radius*3),CFrame.new(pos+Vector3.new(0,.65,0)),Enum.Material.Marble,stone2,true,0)
	local h=broken and height*rng:NextNumber(.42,.72) or height
	local shaft=part(ruins,broken and "BrokenColumn" or "Column",Vector3.new(h,radius*2,radius*2),CFrame.new(pos+Vector3.new(0,1.3+h/2,0))*CFrame.Angles(0,0,math.rad(90)),Enum.Material.Marble,stone,true,0)
	shaft.Shape=Enum.PartType.Cylinder
	part(ruins,"ColumnCap",Vector3.new(radius*3.4,1.5,radius*3.4),CFrame.new(pos+Vector3.new(0,1.3+h+.75,0)),Enum.Material.Marble,stone2,true,0)
end

for _,x in ipairs({-86,-54,-22,22,54,86}) do
	column(base+Vector3.new(x,0,-52),54,2.7,false)
end
for _,x in ipairs({-96,-64,-30,30,64,96}) do
	column(base+Vector3.new(x,0,48),50,2.5,(x==-64 or x==30))
end

-- large ruined wall faces and arches
local function arch(center,width,height,depth)
	local w=4.5
	local ph=height-width*.3
	part(ruins,"ArchPillar",Vector3.new(w,ph,depth),CFrame.new(center+Vector3.new(-width/2+w/2,ph/2,0)),Enum.Material.Limestone,stone,true,0)
	part(ruins,"ArchPillar",Vector3.new(w,ph,depth),CFrame.new(center+Vector3.new(width/2-w/2,ph/2,0)),Enum.Material.Limestone,stone,true,0)
	local radius=width/2-w/2
	for i=0,12 do
		local a=math.pi-(i/12)*math.pi
		local x=math.cos(a)*radius
		local y=math.sin(a)*radius
		part(ruins,"ArchBlock",Vector3.new(4.8,4.8,depth),CFrame.new(center+Vector3.new(x,ph+y,0))*CFrame.Angles(0,0,a-math.pi/2),Enum.Material.Limestone,stone,true,0)
	end
end

for _,x in ipairs({-68,0,68}) do
	arch(base+Vector3.new(x,0,-92),34,46,8)
end

-- side walls, broken towers, ledges
for _,side in ipairs({-1,1}) do
	local x=side*120
	part(ruins,"SideWall",Vector3.new(18,60,150),CFrame.new(x,30,-360),Enum.Material.Limestone,stone2,true,0)
	for i=1,4 do
		part(ruins,"WallBreak",Vector3.new(20,rng:NextNumber(8,18),rng:NextNumber(18,30)),CFrame.new(x+side*rng:NextNumber(-3,3),rng:NextNumber(18,52),-415+i*30),Enum.Material.Rock,Color3.fromRGB(145,141,133),true,0)
	end
end

-- moss strips, ivy patches, fallen blocks
for i=1,46 do
	local x=rng:NextNumber(-125,125)
	local z=rng:NextNumber(-450,-270)
	local g=ground(x,z)
	part(ruins,"Moss",Vector3.new(rng:NextNumber(4,14),.18,rng:NextNumber(4,14)),CFrame.new(x,g.Y+.12,z),Enum.Material.Grass,moss,false,0)
end
for i=1,32 do
	local x=rng:NextNumber(-115,115)
	local z=rng:NextNumber(-445,-275)
	local g=ground(x,z)
	part(ruins,"FallenStone",Vector3.new(rng:NextNumber(4,10),rng:NextNumber(3,7),rng:NextNumber(5,12)),CFrame.new(x,g.Y+rng:NextNumber(1.5,3),z)*CFrame.Angles(rng:NextNumber(-.25,.25),rng:NextNumber(-.5,.5),rng:NextNumber(-.2,.2)),Enum.Material.Limestone,stone2,true,0)
end

-- ============================================================
-- DARK ZONE NOT TOO FAR: cliff bridge + lamps + local darkness.
-- ============================================================
local darkCenter=Vector3.new(0,20,-850)
local dark=Instance.new("Model");dark.Name="AbyssBridgeZone";dark.Parent=F.DarkZone

-- deep ravine and vertical rock walls
Terrain:FillBlock(CFrame.new(0,10,-850),Vector3.new(290,80,130),Enum.Material.Air)
for _,side in ipairs({-1,1}) do
	Terrain:FillBlock(CFrame.new(side*120,46,-850),Vector3.new(95,110,160),Enum.Material.Rock)
	Terrain:FillBlock(CFrame.new(side*120,102,-850),Vector3.new(100,8,165),Enum.Material.Grass)
	for i=1,10 do
		part(dark,"CliffDetail",Vector3.new(rng:NextNumber(10,24),rng:NextNumber(12,32),rng:NextNumber(8,20)),CFrame.new(side*(88+rng:NextNumber(0,62)),rng:NextNumber(24,94),-850+rng:NextNumber(-68,68))*CFrame.Angles(0,rng:NextNumber(-.4,.4),0),Enum.Material.Rock,Color3.fromRGB(61,59,55),true,0)
	end
end

local darkWood=Color3.fromRGB(43,32,27)
local lampColor=Color3.fromRGB(244,169,78)
-- narrow segmented bridge over abyss
for i=-13,13 do
	part(dark,"DarkDeck",Vector3.new(8,1.5,22),CFrame.new(i*8,76,-850)*CFrame.Angles(0,0,math.rad(rng:NextNumber(-.6,.6))),Enum.Material.WoodPlanks,darkWood,true,0)
end
for _,side in ipairs({-1,1}) do
	local z=-850+side*10
	part(dark,"RailTop",Vector3.new(215,1.1,1.1),CFrame.new(0,84,z),Enum.Material.Metal,Color3.fromRGB(49,46,42),true,0)
	for x=-104,104,16 do
		part(dark,"RailPost",Vector3.new(1,11,1),CFrame.new(x,80,z),Enum.Material.Metal,Color3.fromRGB(49,46,42),true,0)
	end
end
for _,x in ipairs({-96,-48,0,48,96}) do
	part(dark,"LampPost",Vector3.new(2,14,2),CFrame.new(x,83,-838),Enum.Material.Metal,Color3.fromRGB(53,48,42),true,0)
	local lamp=part(dark,"Lantern",Vector3.new(3.2,4.2,3.2),CFrame.new(x,91,-838),Enum.Material.Glass,lampColor,false,.25)
	local light=Instance.new("PointLight");light.Color=lampColor;light.Brightness=1.45;light.Range=22;light.Shadows=true;light.Parent=lamp
end

-- giant hanging chain silhouette
local chainFolder=folder(F.DarkZone,"Chain")
for i=0,22 do
	local x=-135+i*4.5
	local y=150-i*4.1+math.sin(i*.35)*2
	part(chainFolder,"ChainLink",Vector3.new(4.5,9,1.2),CFrame.new(x,y,-855)*CFrame.Angles(0,0,(i%2==0) and 0 or math.rad(90)),Enum.Material.Metal,Color3.fromRGB(40,38,34),false,0)
end

-- Local darkening begins as player approaches.
local darkClient=Instance.new("LocalScript")
darkClient.Name="DarkZoneClient"
darkClient.Source=[=[
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local cc=Instance.new("ColorCorrectionEffect")
cc.Name="_DarkZoneColor"
cc.Brightness=0
cc.Contrast=0
cc.Saturation=0
cc.TintColor=Color3.new(1,1,1)
cc.Parent=Lighting
local blur=Instance.new("BlurEffect")
blur.Name="_DarkZoneBlur"
blur.Size=0
blur.Parent=Lighting
local center=Vector3.new(0,76,-850)
RunService.RenderStepped:Connect(function(dt)
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local d=(Vector3.new(root.Position.X,76,root.Position.Z)-center).Magnitude
	local t=math.clamp(1-(d-110)/280,0,1)
	cc.Brightness=-.26*t
	cc.Contrast=.16*t
	cc.Saturation=-.38*t
	cc.TintColor=Color3.new(1-.32*t,1-.38*t,1-.47*t)
	blur.Size=3*t
end)
]=]
darkClient.Parent=sps

-- ============================================================
-- HOUSE + PORTALS. FIRST PORTAL VERY CLOSE TO SPAWN.
-- ============================================================
local portalTemplate=loadModel(PORTAL_ASSET_ID,"PortalTemplate")
local _,psz=portalTemplate:GetBoundingBox()
local pmax=math.max(psz.X,psz.Y,psz.Z)
if pmax>0 then pcall(function() portalTemplate:ScaleTo(30/pmax) end) end

local function portal(name,x,z,yaw)
	local m=portalTemplate:Clone();m.Name=name;m.Parent=F.Portals
	local g,s,b=placeOnGround(m,x,z,yaw,nil)
	clearGrass(g,math.max(15,s.X+8),math.max(15,s.Z+8))
	local cf,sz=m:GetBoundingBox()
	local trigger=part(m,"Trigger",Vector3.new(math.clamp(sz.X*.5,7,13),math.clamp(sz.Y*.65,10,18),math.clamp(sz.Z*.4,5,9)),cf,Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1)
	trigger.CanQuery=false
	return m,trigger
end
local portalA,triggerA=portal("PortalA",36,720,math.rad(90))
local portalB,triggerB=portal("PortalB",0,-760,0)
portalTemplate:Destroy()

-- detailed portal VFX system
local remote=Instance.new("RemoteEvent");remote.Name="PortalVFX";remote.Parent=ReplicatedStorage
local portalClient=Instance.new("LocalScript");portalClient.Name="PortalVFXClient"
portalClient.Source=[=[
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("PortalVFX")

local function cube(parent,size,color,material)
	local p=Instance.new("Part")
	p.Size=size;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
	p.Material=material or Enum.Material.SmoothPlastic;p.Color=color;p.CastShadow=false;p.Parent=parent
	return p
end

local function depart(pos,char)
	local f=Instance.new("Folder");f.Name="_PortalDepart";f.Parent=workspace
	local rings={}
	for r=1,3 do
		for i=1,32 do
			local a=i/32*math.pi*2
			local p=cube(f,Vector3.new(.1,.1,.42),Color3.fromRGB(139,187,203))
			table.insert(rings,{p=p,a=a,r=r})
		end
	end
	local start=os.clock()
	local conn
	conn=RunService.RenderStepped:Connect(function()
		local t=os.clock()-start
		if t>.8 then conn:Disconnect();return end
		for _,v in ipairs(rings) do
			local rr=2.8+v.r*.75
			local a=v.a+t*(3.8+v.r*.55)
			v.p.CFrame=CFrame.new(pos+Vector3.new(math.cos(a)*rr,(v.r-2)*1.6,math.sin(a)*rr))*CFrame.Angles(0,-a,0)
			v.p.Transparency=t*.7
		end
	end)
	task.delay(.24,function()
		if not char.Parent then return end
		for _,bp in ipairs(char:GetDescendants()) do
			if bp:IsA("BasePart") and bp.Name~="HumanoidRootPart" then
				local n=math.clamp(math.floor(bp.Size.Magnitude*9),8,30)
				for i=1,n do
					local p=cube(f,Vector3.new(.08,.08,.08)*math.random(1,3),bp.Color)
					p.CFrame=bp.CFrame*CFrame.new((math.random()-.5)*bp.Size.X,(math.random()-.5)*bp.Size.Y,(math.random()-.5)*bp.Size.Z)
					TweenService:Create(p,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=p.Position+Vector3.new((math.random()-.5)*9,math.random(3,11),(math.random()-.5)*9),Transparency=1,Size=Vector3.new(.03,.03,.03)}):Play()
				end
			end
		end
	end)
	Debris:AddItem(f,.95)
end

local function arrive(pos)
	local f=Instance.new("Folder");f.Name="_PortalArrive";f.Parent=workspace
	local orb=cube(f,Vector3.new(.5,.5,.5),Color3.fromRGB(145,198,216),Enum.Material.Neon)
	orb.Shape=Enum.PartType.Ball;orb.Position=pos;orb.Transparency=.16
	TweenService:Create(orb,TweenInfo.new(.34),{Size=Vector3.new(5.8,5.8,5.8),Transparency=.32}):Play()
	for i=1,140 do
		local a=math.random()*math.pi*2
		local u=math.random()*2-1
		local rr=math.sqrt(1-u*u)
		local dir=Vector3.new(rr*math.cos(a),u,rr*math.sin(a))
		local p=cube(f,Vector3.new(.08,.08,.08)*math.random(1,3),Color3.fromRGB(140,191,207))
		p.Position=pos+dir*math.random(4,9)
		TweenService:Create(p,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=pos,Transparency=.08}):Play()
		task.delay(.34,function()
			if p.Parent then TweenService:Create(p,TweenInfo.new(.28),{Position=pos+dir*math.random(5,12),Transparency=1,Size=Vector3.new(.03,.03,.03)}):Play() end
		end)
	end
	task.delay(.36,function() if orb.Parent then TweenService:Create(orb,TweenInfo.new(.14),{Size=Vector3.new(8,8,8),Transparency=1}):Play() end end)
	Debris:AddItem(f,.8)
end

remote.OnClientEvent:Connect(function(action,pos)
	if action=="Depart" and player.Character then depart(pos,player.Character) end
	if action=="Arrive" then arrive(pos+Vector3.new(0,2.5,0)) end
end)
]=]
portalClient.Parent=sps

local portalServer=Instance.new("Script");portalServer.Name="PortalServer"
portalServer.Source=[=[
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local remote=ReplicatedStorage:WaitForChild("PortalVFX")
local A=Workspace.ReferenceWorld.Portals.PortalA.Trigger
local B=Workspace.ReferenceWorld.Portals.PortalB.Trigger
local dwell,busy={},{}
local function inside(t,p)
	local q=t.CFrame:PointToObjectSpace(p);local h=t.Size*.5
	return math.abs(q.X)<=h.X and math.abs(q.Y)<=h.Y and math.abs(q.Z)<=h.Z
end
local function hide(c)
	local map={}
	for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") or d:IsA("Decal") then map[d]=d.Transparency;d.Transparency=1 end end
	return map
end
local function restore(map)
	for o,v in pairs(map) do if o and o.Parent then o.Transparency=v end end
end
local function tp(player,from,to)
	if busy[player] then return end
	local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
	if not h or not root then return end
	busy[player]=true;dwell[player]=nil
	local walk,jump,auto=h.WalkSpeed,h.JumpPower,h.AutoRotate
	h.WalkSpeed=0;h.JumpPower=0;h.AutoRotate=false;root.Anchored=true
	remote:FireClient(player,"Depart",root.Position)
	task.wait(.78)
	local map=hide(c);task.wait(.15)
	root.CFrame=to.CFrame*CFrame.new(0,0,-(to.Size.Z/2+5))+Vector3.new(0,2,0)
	remote:FireClient(player,"Arrive",root.Position);task.wait(.4)
	restore(map);root.Anchored=false;h.WalkSpeed=walk;h.JumpPower=jump;h.AutoRotate=auto
	task.wait(2);busy[player]=nil
end
task.spawn(function()
	while true do
		task.wait(.1);local now=os.clock()
		for _,p in ipairs(Players:GetPlayers()) do
			if not busy[p] then
				local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local key=inside(A,root.Position) and "A" or (inside(B,root.Position) and "B" or nil)
					local s=dwell[p]
					if key then
						if not s or s.key~=key then dwell[p]={key=key,start=now}
						elseif now-s.start>=1 then task.spawn(tp,p,key=="A" and A or B,key=="A" and B or A) end
					else dwell[p]=nil end
				end
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p)dwell[p]=nil;busy[p]=nil end)
]=]
portalServer.Parent=ServerScriptService

-- ============================================================
-- FOREST: DENSE, BUT KEEP KEY AREAS OPEN.
-- ============================================================
local function blockTree(pos,scale,index)
	local m=Instance.new("Model");m.Name="ForestTree_"..index;m.Parent=F.Forest
	local trunk=Color3.fromRGB(39,47,45)
	local leaves={Color3.fromRGB(49,75,59),Color3.fromRGB(55,83,64),Color3.fromRGB(45,70,56)}
	local h=rng:NextNumber(20,30)*scale
	part(m,"Trunk",Vector3.new(3.6*scale,h,3.6*scale),CFrame.new(pos+Vector3.new(0,h/2,0)),Enum.Material.Wood,trunk,true,0)
	for i=1,7 do
		local ox=rng:NextNumber(-6.5,6.5)*scale;local oy=rng:NextNumber(-2,6)*scale;local oz=rng:NextNumber(-6,6)*scale
		local leaf=part(m,"Canopy",Vector3.new(rng:NextNumber(8,14)*scale,rng:NextNumber(7,11)*scale,rng:NextNumber(8,14)*scale),CFrame.new(pos.X+ox,pos.Y+h+2*scale+oy,pos.Z+oz)*CFrame.Angles(rng:NextNumber(-.08,.08),rng:NextNumber(-.18,.18),rng:NextNumber(-.08,.08)),Enum.Material.SmoothPlastic,leaves[rng:NextInteger(1,#leaves)],false,0)
		leaf.CanQuery=false
	end
end

local exclusion={
	{Vector2.new(0,620),80},
	{Vector2.new(0,155),170},
	{Vector2.new(0,-360),190},
	{Vector2.new(0,-850),230},
	{Vector2.new(36,720),50},
	{Vector2.new(0,-70),90},
}
local function excluded(x,z,r)
	local p=Vector2.new(x,z)
	if math.abs(x)<38+r and z>250 and z<790 then return true end
	for _,e in ipairs(exclusion) do if (p-e[1]).Magnitude<e[2]+r then return true end end
	return false
end
local trees=0
local tries=0
while trees<280 and tries<5000 do
	tries+=1
	local x=rng:NextNumber(-1320,1320);local z=rng:NextNumber(-1320,1320)
	if not excluded(x,z,8) then
		local g=ground(x,z)
		blockTree(g,rng:NextNumber(.82,1.25),trees+1);trees+=1
	end
end

-- ============================================================
-- ONLY UI = 3 SECOND LOADING SCREEN.
-- ============================================================
local loader=Instance.new("LocalScript");loader.Name="MapLoadingScreen"
loader.Source=[=[
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local TweenService=game:GetService("TweenService")
ReplicatedFirst:RemoveDefaultLoadingScreen()
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="MapLoadingScreen";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=10000;gui.Parent=player:WaitForChild("PlayerGui")
local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromRGB(22,28,29);bg.BorderSizePixel=0;bg.Parent=gui
local g=Instance.new("UIGradient");g.Rotation=90;g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(62,78,82)),ColorSequenceKeypoint.new(1,Color3.fromRGB(18,22,23))});g.Parent=bg
local t=Instance.new("TextLabel");t.AnchorPoint=Vector2.new(.5,.5);t.Position=UDim2.fromScale(.5,.49);t.Size=UDim2.fromOffset(260,38);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.Text="Carregando mapa";t.TextSize=18;t.TextColor3=Color3.fromRGB(230,232,229);t.Parent=bg
local d=Instance.new("TextLabel");d.AnchorPoint=Vector2.new(.5,.5);d.Position=UDim2.fromScale(.5,.545);d.Size=UDim2.fromOffset(80,24);d.BackgroundTransparency=1;d.Font=Enum.Font.Gotham;d.Text="•";d.TextSize=20;d.TextColor3=Color3.fromRGB(168,181,181);d.Parent=bg
task.spawn(function() for i=1,9 do d.Text=string.rep("•",((i-1)%3)+1);task.wait(.33) end end)
task.wait(3)
TweenService:Create(bg,TweenInfo.new(.45),{BackgroundTransparency=1}):Play()
TweenService:Create(t,TweenInfo.new(.35),{TextTransparency=1}):Play()
TweenService:Create(d,TweenInfo.new(.35),{TextTransparency=1}):Play()
task.wait(.5);gui:Destroy()
]=]
loader.Parent=ReplicatedFirst

-- ============================================================
-- BASE LIGHTING + subtle ambient.
-- ============================================================
Lighting.ClockTime=14
Lighting.Brightness=1.7
Lighting.ExposureCompensation=-.06
Lighting.Ambient=Color3.fromRGB(74,84,85)
Lighting.OutdoorAmbient=Color3.fromRGB(103,111,108)
Lighting.EnvironmentDiffuseScale=.34
Lighting.EnvironmentSpecularScale=.3
Lighting.ShadowSoftness=.46
pcall(function() Lighting.Technology=Enum.Technology.Future end)
local atm=Instance.new("Atmosphere");atm.Name="BaseFog";atm.Density=.27;atm.Offset=.08;atm.Color=Color3.fromRGB(171,188,191);atm.Decay=Color3.fromRGB(82,91,88);atm.Haze=1.1;atm.Glare=.02;atm.Parent=Lighting
local cc=Instance.new("ColorCorrectionEffect");cc.Name="BaseColor";cc.Brightness=-.01;cc.Contrast=.05;cc.Saturation=-.07;cc.TintColor=Color3.fromRGB(224,229,222);cc.Parent=Lighting

Workspace:SetAttribute("WorldRebuildComplete",true)
Workspace:SetAttribute("WorldRebuildVersion",VERSION)
Workspace:SetAttribute("SingleTorii",true)
Workspace:SetAttribute("PathStoneCount",stones)
Workspace:SetAttribute("LoadingSeconds",3)
Workspace:SetAttribute("PortalNearSpawn",true)
Workspace:SetAttribute("MainBridgePresent",true)
Workspace:SetAttribute("RuinsPresent",true)
Workspace:SetAttribute("DarkZonePresent",true)
Workspace:SetAttribute("HouseCount",1)
Workspace:SetAttribute("HouseBottomY",hb)
Workspace:SetAttribute("HouseGroundY",hg.Y)
Workspace:SetAttribute("TreeCount",trees)

local sourceVersion=game.PlaceVersion
AssetService:SavePlaceAsync()
return {
	ok=true,
	sourceVersion=sourceVersion,
	version=VERSION,
	stones=stones,
	trees=trees,
	houseGroundDelta=math.abs(hb-hg.Y),
}
