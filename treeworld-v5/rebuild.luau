local AssetService=game:GetService("AssetService")
local Debris=game:GetService("Debris")
local InsertService=game:GetService("InsertService")
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local SoundService=game:GetService("SoundService")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")

local HOUSE_ASSET_ID=__HOUSE_ASSET_ID__
local PORTAL_ASSET_ID=__PORTAL_ASSET_ID__
local VERSION="2026-10-19-torii-forest-v5"
local Terrain=Workspace.Terrain
local rng=Random.new(1910202605)

local function lower(v) return string.lower(tostring(v or "")) end
local function hasAny(text,words)
	text=lower(text)
	for _,w in ipairs(words) do
		if string.find(text,w,1,true) then return true end
	end
	return false
end

local function stripScripts(root)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then d:Destroy() end
	end
end

local function anchorModel(root)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored=true
			d.CanTouch=false
		end
	end
end

local function loadModel(assetId,name)
	local container=InsertService:LoadAsset(assetId)
	stripScripts(container)
	local children=container:GetChildren()
	local model=nil
	if #children==1 and children[1]:IsA("Model") then
		model=children[1]
		model.Parent=nil
	else
		model=Instance.new("Model")
		for _,child in ipairs(children) do
			child.Parent=model
		end
	end
	container:Destroy()
	model.Name=name
	anchorModel(model)
	return model
end

local function scaleModelToMax(model,targetMax)
	local _,size=model:GetBoundingBox()
	local current=math.max(size.X,size.Y,size.Z)
	if current>0 then
		pcall(function() model:ScaleTo(targetMax/current) end)
	end
end

local function makePart(parent,name,size,cf,material,color,collide,transparency)
	local p=Instance.new("Part")
	p.Name=name
	p.Size=size
	p.CFrame=cf
	p.Anchored=true
	p.Material=material
	p.Color=color
	p.CanCollide=collide
	p.CanTouch=collide
	p.CanQuery=true
	p.CastShadow=true
	p.Transparency=transparency or 0
	p.Parent=parent
	return p
end

local function terrainHit(x,z)
	local result=Workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-500,0))
	if result and result.Instance==Terrain and result.Material~=Enum.Material.Water then
		return result.Position,result.Normal,result.Material
	end
	return nil
end

local function clearGrass(center,sx,sz)
	local region=Region3.new(
		center-Vector3.new(sx*.5,7,sz*.5),
		center+Vector3.new(sx*.5,7,sz*.5)
	):ExpandToGrid(4)
	pcall(function()
		Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.Ground)
	end)
end

local function placeOnGround(model,x,z,yaw,targetMax)
	if targetMax then scaleModelToMax(model,targetMax) end
	anchorModel(model)
	local ground=terrainHit(x,z)
	assert(ground,"No terrain below model")
	local boxCF,size=model:GetBoundingBox()
	local pivot=model:GetPivot()
	local bottom=boxCF.Position.Y-size.Y/2
	local pivotOffset=pivot.Position.Y-bottom
	model:PivotTo(CFrame.new(x,ground.Y+pivotOffset,z)*CFrame.Angles(0,yaw or 0,0))
	return ground,size
end

-- Full reset.
for _,child in ipairs(Workspace:GetChildren()) do
	if child~=Terrain and not child:IsA("Camera") then child:Destroy() end
end
Terrain:Clear()

for _,child in ipairs(ServerScriptService:GetChildren()) do
	if hasAny(child.Name,{"treeworld","overyard","portal","weather","campfire","world"}) then
		child:Destroy()
	end
end
for _,child in ipairs(ReplicatedStorage:GetChildren()) do
	if hasAny(child.Name,{"treeworld","overyard","portal","weather","campfire"}) then
		child:Destroy()
	end
end
local sps=StarterPlayer:WaitForChild("StarterPlayerScripts")
for _,child in ipairs(sps:GetChildren()) do
	if hasAny(child.Name,{"treeworld","overyard","portal","weather","campfire"}) then
		child:Destroy()
	end
end
for _,child in ipairs(Lighting:GetChildren()) do
	if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then child:Destroy() end
end
for _,child in ipairs(SoundService:GetChildren()) do
	if hasAny(child.Name,{"treeworld","forest","ambient","rain","portal"}) then child:Destroy() end
end

pcall(function() Workspace.StreamingEnabled=true end)
pcall(function() Workspace.StreamingMinRadius=96 end)
pcall(function() Workspace.StreamingTargetRadius=340 end)
pcall(function() Workspace.GlobalWind=Vector3.new(4.3,0,1.8) end)
pcall(function() Terrain.Decoration=true end)
pcall(function() Terrain.GrassLength=.32 end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(65,100,70)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(77,78,67)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(69,77,79)) end)

local world=Instance.new("Folder")
world.Name="ToriiForest"
world.Parent=Workspace

local folders={}
for _,name in ipairs({"Trees","DistantForest","StonePath","Torii","House","Portals","Details","Spawn"}) do
	local f=Instance.new("Folder")
	f.Name=name
	f.Parent=world
	folders[name]=f
end

-- Giant mostly-flat forest terrain.
local HALF=1536
local CHUNK=256
for x=-HALF+CHUNK/2,HALF-CHUNK/2,CHUNK do
	for z=-HALF+CHUNK/2,HALF-CHUNK/2,CHUNK do
		Terrain:FillBlock(CFrame.new(x,-6,z),Vector3.new(CHUNK+6,52,CHUNK+6),Enum.Material.Grass)
	end
end
Terrain:FillBlock(CFrame.new(0,-38,0),Vector3.new(3100,30,3100),Enum.Material.Rock)

-- Very broad, subtle elevation only; no ugly hills.
for _,h in ipairs({
	{Vector3.new(-980,-215,-890),245},
	{Vector3.new(970,-218,-950),248},
	{Vector3.new(-1030,-220,890),245},
	{Vector3.new(1040,-218,930),248},
}) do
	Terrain:FillBall(h[1],h[2],Enum.Material.Grass)
end

-- Main stone path from spawn through torii to house.
local pathStartZ=1100
local pathEndZ=90
local stoneColor=Color3.fromRGB(61,70,72)
local edgeColor=Color3.fromRGB(52,60,63)

local slabCount=0
for z=pathStartZ,pathEndZ,-22 do
	local wobble=math.sin(z*.019)*1.7+rng:NextNumber(-1.1,1.1)
	local width=rng:NextNumber(8.5,12.5)
	local length=rng:NextNumber(11,17)
	local ground=terrainHit(wobble,z)
	if ground then
		clearGrass(ground,width+4,length+4)
		local slab=makePart(
			folders.StonePath,"StoneSlab",
			Vector3.new(width,.75,length),
			CFrame.new(wobble,ground.Y+.25,z)*CFrame.Angles(0,math.rad(rng:NextNumber(-4,4)),math.rad(rng:NextNumber(-1.2,1.2))),
			Enum.Material.Slate,
			(rng:NextNumber()<.25) and edgeColor or stoneColor,
			true,0
		)
		slabCount+=1
	end
end

-- Side scattered stepping stones like the reference.
for i=1,32 do
	local z=rng:NextNumber(430,930)
	local side=(i%2==0) and -1 or 1
	local x=side*rng:NextNumber(13,34)
	local ground=terrainHit(x,z)
	if ground then
		clearGrass(ground,9,8)
		makePart(
			folders.StonePath,"ScatteredSlab",
			Vector3.new(rng:NextNumber(5,9),.6,rng:NextNumber(6,11)),
			CFrame.new(x,ground.Y+.22,z)*CFrame.Angles(0,rng:NextNumber(-.25,.25),rng:NextNumber(-.03,.03)),
			Enum.Material.Slate,edgeColor,true,0
		)
	end
end

-- Torii closely matching the large dark stone gate in the screenshot.
local function createTorii(center,scale,name)
	local model=Instance.new("Model")
	model.Name=name
	model.Parent=folders.Torii
	local dark=Color3.fromRGB(48,56,58)
	local dark2=Color3.fromRGB(57,64,65)
	local postH=31*scale
	local postR=2.2*scale
	for _,sx in ipairs({-1,1}) do
		local x=sx*14*scale
		local foot=makePart(model,"StoneFoot",Vector3.new(7*scale,1.5*scale,7*scale),CFrame.new(center+Vector3.new(x,.75*scale,0)),Enum.Material.Slate,dark2,true,0)
		local post=makePart(model,"RoundPost",Vector3.new(postH,postR*2,postR*2),CFrame.new(center+Vector3.new(x,1.5*scale+postH/2,0))*CFrame.Angles(0,0,math.rad(90)),Enum.Material.Slate,dark,true,0)
		post.Shape=Enum.PartType.Cylinder
		local collar=makePart(model,"PostCollar",Vector3.new(5.2*scale,2.1*scale,5.2*scale),CFrame.new(center+Vector3.new(x,postH-2.5*scale,0)),Enum.Material.Slate,dark2,true,0)
	end
	makePart(model,"LowerBeam",Vector3.new(36*scale,3*scale,4*scale),CFrame.new(center+Vector3.new(0,25.5*scale,0)),Enum.Material.Slate,dark,true,0)
	makePart(model,"TopBeam",Vector3.new(44*scale,3.4*scale,4.5*scale),CFrame.new(center+Vector3.new(0,32*scale,0))*CFrame.Angles(0,0,math.rad(-1.2)),Enum.Material.Slate,dark,true,0)
	makePart(model,"TopCapLeft",Vector3.new(8*scale,2.6*scale,4.9*scale),CFrame.new(center+Vector3.new(-21*scale,33.1*scale,0))*CFrame.Angles(0,0,math.rad(8)),Enum.Material.Slate,dark,true,0)
	makePart(model,"TopCapRight",Vector3.new(8*scale,2.6*scale,4.9*scale),CFrame.new(center+Vector3.new(21*scale,33.1*scale,0))*CFrame.Angles(0,0,math.rad(-8)),Enum.Material.Slate,dark,true,0)
	makePart(model,"CenterBrace",Vector3.new(8*scale,5.5*scale,3.2*scale),CFrame.new(center+Vector3.new(0,28.6*scale,0)),Enum.Material.Slate,dark2,true,0)

	-- Shimenawa rope.
	local a=makePart(model,"RopeAnchorA",Vector3.new(.2,.2,.2),CFrame.new(center+Vector3.new(-11*scale,23.3*scale,2.5*scale)),Enum.Material.SmoothPlastic,dark,false,1)
	local b=makePart(model,"RopeAnchorB",Vector3.new(.2,.2,.2),CFrame.new(center+Vector3.new(11*scale,23.3*scale,2.5*scale)),Enum.Material.SmoothPlastic,dark,false,1)
	local aa=Instance.new("Attachment");aa.Parent=a
	local bb=Instance.new("Attachment");bb.Parent=b
	local rope=Instance.new("Beam")
	rope.Attachment0=aa;rope.Attachment1=bb
	rope.Width0=.75*scale;rope.Width1=.75*scale
	rope.Color=ColorSequence.new(Color3.fromRGB(126,101,69))
	rope.CurveSize0=-5*scale;rope.CurveSize1=5*scale
	rope.Segments=24;rope.FaceCamera=true;rope.Parent=model
	for _,x in ipairs({-6,0,6}) do
		local top=makePart(model,"TasselTop",Vector3.new(.15,.15,.15),CFrame.new(center+Vector3.new(x*scale,20.5*scale,2.5*scale)),Enum.Material.SmoothPlastic,dark,false,1)
		local bottom=makePart(model,"TasselBottom",Vector3.new(.15,.15,.15),CFrame.new(center+Vector3.new(x*scale,16.8*scale,2.5*scale)),Enum.Material.SmoothPlastic,dark,false,1)
		local at=Instance.new("Attachment");at.Parent=top
		local ab=Instance.new("Attachment");ab.Parent=bottom
		local strand=Instance.new("Beam")
		strand.Attachment0=at;strand.Attachment1=ab;strand.Width0=.35*scale;strand.Width1=.16*scale
		strand.Color=ColorSequence.new(Color3.fromRGB(126,101,69));strand.FaceCamera=true;strand.Parent=model
		makePart(model,"Tassel",Vector3.new(.9*scale,1.4*scale,.9*scale),CFrame.new(center+Vector3.new(x*scale,16.1*scale,2.5*scale)),Enum.Material.Wood,Color3.fromRGB(122,96,65),false,0)
	end
	clearGrass(center,58*scale,28*scale)
	return model
end

local toriiGround=terrainHit(0,620)
assert(toriiGround,"No torii ground")
createTorii(Vector3.new(0,toriiGround.Y,620),1,"MainTorii")

-- Smaller second gate deeper toward the house, matching the layered perspective.
local torii2Ground=terrainHit(0,365)
if torii2Ground then
	createTorii(Vector3.new(0,torii2Ground.Y,365),.62,"DistantTorii")
end

-- One uploaded Japanese house, exactly one copy, physically touching the terrain.
local house=loadModel(HOUSE_ASSET_ID,"JapaneseHouse")
house.Parent=folders.House
local houseGround,houseSize=placeOnGround(house,0,110,math.rad(180),118)
local houseCF,houseFinalSize=house:GetBoundingBox()
local houseBottom=houseCF.Position.Y-houseFinalSize.Y/2
clearGrass(Vector3.new(0,houseGround.Y,110),houseFinalSize.X+16,houseFinalSize.Z+16)

-- A dark stone apron in front of the house so grass never clips into it.
makePart(
	folders.Details,"HouseApron",
	Vector3.new(math.clamp(houseFinalSize.X*.7,38,80),.45,18),
	CFrame.new(0,houseGround.Y+.12,175),
	Enum.Material.Slate,Color3.fromRGB(54,61,62),true,0
)

-- Real Roblox Forest Pack for depth.
local forestContainer=InsertService:LoadAsset(6432306802)
stripScripts(forestContainer)
local treePool={}
for _,obj in ipairs(forestContainer:GetDescendants()) do
	if obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart",true) then
		local ok,_,size=pcall(function() return obj:GetBoundingBox() end)
		if ok and size.Y>10 and size.Y<90 and size.X<65 and size.Z<65 then
			local nested=false
			for _,c in ipairs(obj:GetChildren()) do
				if c:IsA("Model") and c:FindFirstChildWhichIsA("BasePart",true) then nested=true break end
			end
			if not nested then table.insert(treePool,obj) end
		end
	end
end
assert(#treePool>0,"No usable trees in Roblox Forest Pack")

local exclusions={
	{Vector2.new(0,620),75},
	{Vector2.new(0,365),50},
	{Vector2.new(0,110),math.max(90,houseFinalSize.X*.75)},
	{Vector2.new(0,780),72},
	{Vector2.new(-720,160),65},
	{Vector2.new(780,-620),65},
}

local function excluded(x,z,margin)
	local p=Vector2.new(x,z)
	for _,e in ipairs(exclusions) do
		if (p-e[1]).Magnitude<e[2]+margin then return true end
	end
	-- keep the central shrine path open
	if math.abs(x)<48+margin and z>45 and z<1160 then return true end
	return false
end

local function cloneForestTree(pos,scale,yaw,parent)
	local src=treePool[rng:NextInteger(1,#treePool)]
	local clone=src:Clone()
	clone.Name="ForestTree"
	stripScripts(clone)
	anchorModel(clone)
	clone.Parent=parent
	pcall(function() clone:ScaleTo(scale) end)
	local boxCF,size=clone:GetBoundingBox()
	local pivot=clone:GetPivot()
	local bottom=boxCF.Position.Y-size.Y/2
	local offset=pivot.Position.Y-bottom
	clone:PivotTo(CFrame.new(pos+Vector3.new(0,offset,0))*CFrame.Angles(0,yaw,0))
	for _,p in ipairs(clone:GetDescendants()) do
		if p:IsA("BasePart") and hasAny(p.Name,{"leaf","leaves","foliage"}) then
			p.CanCollide=false
		end
	end
	return clone
end

-- Extra blocky trees near the path to mirror the reference silhouette.
local function blockTree(pos,scale,index)
	local model=Instance.new("Model")
	model.Name="ReferenceBlockTree_"..index
	model.Parent=folders.Trees
	local trunkColor=Color3.fromRGB(35,45,45)
	local leafPalette={
		Color3.fromRGB(52,82,65),
		Color3.fromRGB(59,91,72),
		Color3.fromRGB(47,75,62),
	}
	local h=rng:NextNumber(18,28)*scale
	makePart(model,"Trunk",Vector3.new(3.6*scale,h,3.6*scale),CFrame.new(pos+Vector3.new(0,h/2,0)),Enum.Material.Wood,trunkColor,true,0)
	for b=1,2 do
		local side=(b==1) and -1 or 1
		makePart(model,"Branch",Vector3.new(2.1*scale,11*scale,2.1*scale),CFrame.new(pos+Vector3.new(side*3*scale,h*.67,0))*CFrame.Angles(0,0,math.rad(side*28)),Enum.Material.Wood,trunkColor,false,0)
	end
	local crownY=pos.Y+h+2*scale
	for i=1,7 do
		local ox=rng:NextNumber(-7,7)*scale
		local oy=rng:NextNumber(-2,7)*scale
		local oz=rng:NextNumber(-6,6)*scale
		local leaf=makePart(
			model,"BlockCanopy",
			Vector3.new(rng:NextNumber(8,14)*scale,rng:NextNumber(7,12)*scale,rng:NextNumber(8,14)*scale),
			CFrame.new(pos.X+ox,crownY+oy,pos.Z+oz)*CFrame.Angles(rng:NextNumber(-.08,.08),rng:NextNumber(-.25,.25),rng:NextNumber(-.08,.08)),
			Enum.Material.SmoothPlastic,
			leafPalette[rng:NextInteger(1,#leafPalette)],
			false,0
		)
		leaf.CanQuery=false
	end
	return model
end

local centralBlockTrees=0
for z=250,1080,70 do
	for _,side in ipairs({-1,1}) do
		if rng:NextNumber()<.86 then
			local x=side*rng:NextNumber(60,115)
			if not excluded(x,z,8) then
				local ground,normal,mat=terrainHit(x,z)
				if ground and normal.Y>.8 and mat==Enum.Material.Grass then
					blockTree(ground,rng:NextNumber(.85,1.2),centralBlockTrees+1)
					centralBlockTrees+=1
				end
			end
		end
	end
end

-- Dense large forest extending nearly to map edges.
local meshTrees=0
local attempts=0
while meshTrees<360 and attempts<6000 do
	attempts+=1
	local x=rng:NextNumber(-1420,1420)
	local z=rng:NextNumber(-1420,1420)
	if not excluded(x,z,12) then
		local ground,normal,mat=terrainHit(x,z)
		if ground and normal.Y>.77 and mat==Enum.Material.Grass then
			local distance=Vector2.new(x,z).Magnitude
			local scale=(distance>900) and rng:NextNumber(1.15,1.65) or rng:NextNumber(.9,1.45)
			cloneForestTree(ground,scale,rng:NextNumber(0,math.pi*2),distance>900 and folders.DistantForest or folders.Trees)
			meshTrees+=1
		end
	end
end

-- Dense boundary ring makes the fogged forest feel endless.
for i=1,96 do
	local a=(i/96)*math.pi*2+rng:NextNumber(-.02,.02)
	local radius=rng:NextNumber(1300,1460)
	local x=math.cos(a)*radius
	local z=math.sin(a)*radius
	local ground=terrainHit(x,z)
	if ground then
		cloneForestTree(ground,rng:NextNumber(1.25,1.8),rng:NextNumber(0,math.pi*2),folders.DistantForest)
		meshTrees+=1
	end
end
forestContainer:Destroy()

-- Small shrine lanterns along the center path.
for i,z in ipairs({520,455,300,235}) do
	for _,side in ipairs({-1,1}) do
		local x=side*24
		local ground=terrainHit(x,z)
		if ground then
			clearGrass(ground,7,7)
			local base=makePart(folders.Details,"StoneLanternBase",Vector3.new(4.4,.9,4.4),CFrame.new(x,ground.Y+.45,z),Enum.Material.Slate,Color3.fromRGB(64,71,72),true,0)
			makePart(folders.Details,"StoneLanternStem",Vector3.new(1.3,6,1.3),CFrame.new(x,ground.Y+3.8,z),Enum.Material.Slate,Color3.fromRGB(64,71,72),true,0)
			local lamp=makePart(folders.Details,"StoneLanternLight",Vector3.new(3.3,2.4,3.3),CFrame.new(x,ground.Y+7.2,z),Enum.Material.Glass,Color3.fromRGB(195,184,150),false,.45)
			local light=Instance.new("PointLight")
			light.Color=Color3.fromRGB(199,182,140);light.Brightness=.45;light.Range=12;light.Shadows=true;light.Parent=lamp
			makePart(folders.Details,"StoneLanternRoof",Vector3.new(5,1,5),CFrame.new(x,ground.Y+8.9,z),Enum.Material.Slate,Color3.fromRGB(58,65,66),true,0)
		end
	end
end

-- Uploaded portal model: exactly two copies, each grounded.
local portalTemplate=loadModel(PORTAL_ASSET_ID,"PortalTemplate")
scaleModelToMax(portalTemplate,38)

local function createPortal(name,x,z,yaw)
	local model=portalTemplate:Clone()
	model.Name=name
	model.Parent=folders.Portals
	local ground=terrainHit(x,z)
	assert(ground,"No terrain for "..name)
	anchorModel(model)
	local boxCF,size=model:GetBoundingBox()
	local pivot=model:GetPivot()
	local bottom=boxCF.Position.Y-size.Y/2
	local offset=pivot.Position.Y-bottom
	model:PivotTo(CFrame.new(x,ground.Y+offset,z)*CFrame.Angles(0,yaw,0))
	local newCF,newSize=model:GetBoundingBox()
	clearGrass(Vector3.new(x,ground.Y,z),math.max(18,newSize.X+10),math.max(18,newSize.Z+10))
	local trigger=makePart(
		model,"Trigger",
		Vector3.new(
			math.clamp(newSize.X*.52,7,16),
			math.clamp(newSize.Y*.68,10,22),
			math.clamp(newSize.Z*.35,5,10)
		),
		newCF,
		Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1
	)
	trigger.CanQuery=false
	trigger.CanTouch=false
	model:SetAttribute("PortalName",name)
	return model,trigger,ground
end

local portalA,triggerA,portalGroundA=createPortal("PortalA",-720,160,math.rad(90))
local portalB,triggerB,portalGroundB=createPortal("PortalB",780,-620,math.rad(-90))
portalTemplate:Destroy()

-- Portal remotes and detailed local VFX.
local portalRemote=Instance.new("RemoteEvent")
portalRemote.Name="ToriiPortalVFX"
portalRemote.Parent=ReplicatedStorage

local portalClient=Instance.new("LocalScript")
portalClient.Name="ToriiPortalVFXClient"
portalClient.Source=[=[
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("ToriiPortalVFX")

local function cube(parent,size,color,material)
	local p=Instance.new("Part")
	p.Size=size
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=false
	p.Material=material or Enum.Material.Neon
	p.Color=color
	p.CastShadow=false
	p.Parent=parent
	return p
end

local function ringBurst(center,duration)
	local folder=Instance.new("Folder")
	folder.Name="_PortalRings"
	folder.Parent=workspace
	local rings={}
	for r=1,3 do
		for i=1,28 do
			local a=(i/28)*math.pi*2
			local p=cube(folder,Vector3.new(.18,.18,.55),Color3.fromRGB(137,190,210))
			table.insert(rings,{part=p,angle=a,ring=r})
		end
	end
	local start=os.clock()
	local conn
	conn=RunService.RenderStepped:Connect(function()
		local t=os.clock()-start
		if t>duration then conn:Disconnect();folder:Destroy();return end
		for _,item in ipairs(rings) do
			local radius=3.1+item.ring*.7
			local a=item.angle+t*(3.2+item.ring*.7)
			local y=(item.ring-2)*1.8+math.sin(a*2+t*3)*.35
			item.part.CFrame=CFrame.new(center+Vector3.new(math.cos(a)*radius,y,math.sin(a)*radius))*CFrame.Angles(0,-a,0)
			item.part.Transparency=math.clamp(t/duration*.35,0,.55)
		end
	end)
end

local function bodyDust(character,origin)
	local folder=Instance.new("Folder")
	folder.Name="_PortalDust"
	folder.Parent=workspace
	local parts={}
	for _,body in ipairs(character:GetDescendants()) do
		if body:IsA("BasePart") and body.Name~="HumanoidRootPart" then
			for i=1,math.clamp(math.floor(body.Size.Magnitude*6),5,24) do
				local p=cube(folder,Vector3.new(.11,.11,.11)*math.random(1,3),body.Color,Enum.Material.SmoothPlastic)
				local localPos=Vector3.new(
					(math.random()-.5)*body.Size.X,
					(math.random()-.5)*body.Size.Y,
					(math.random()-.5)*body.Size.Z
				)
				p.CFrame=body.CFrame*CFrame.new(localPos)
				local goal=p.Position+Vector3.new((math.random()-.5)*8,math.random(3,10),(math.random()-.5)*8)
				table.insert(parts,p)
				TweenService:Create(p,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
					Position=goal,Transparency=1,Size=Vector3.new(.04,.04,.04)
				}):Play()
			end
		end
	end
	Debris:AddItem(folder,.8)
end

local function arrivalOrb(center)
	local folder=Instance.new("Folder")
	folder.Name="_PortalArrival"
	folder.Parent=workspace
	local orb=cube(folder,Vector3.new(.6,.6,.6),Color3.fromRGB(143,204,224))
	orb.Shape=Enum.PartType.Ball
	orb.CFrame=CFrame.new(center)
	orb.Transparency=.18
	TweenService:Create(orb,TweenInfo.new(.36,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
		Size=Vector3.new(5.5,5.5,5.5),Transparency=.38
	}):Play()

	for i=1,120 do
		local a=math.random()*math.pi*2
		local u=math.random()*2-1
		local rr=math.sqrt(1-u*u)
		local dir=Vector3.new(rr*math.cos(a),u,rr*math.sin(a))
		local start=center+dir*math.random(4,9)
		local p=cube(folder,Vector3.new(.1,.1,.1)*math.random(1,3),Color3.fromRGB(142,196,211))
		p.CFrame=CFrame.new(start)
		TweenService:Create(p,TweenInfo.new(.34,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
			Position=center,Transparency=.15
		}):Play()
		task.delay(.37,function()
			if not p.Parent then return end
			local out=center+dir*math.random(5,12)
			TweenService:Create(p,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
				Position=out,Transparency=1,Size=Vector3.new(.04,.04,.04)
			}):Play()
		end)
	end
	task.delay(.38,function()
		if orb.Parent then
			TweenService:Create(orb,TweenInfo.new(.16),{Size=Vector3.new(8,8,8),Transparency=1}):Play()
		end
	end)
	Debris:AddItem(folder,.85)
end

remote.OnClientEvent:Connect(function(action,position)
	local character=player.Character
	if action=="Depart" and character then
		ringBurst(position,.82)
		task.delay(.28,function()
			if character.Parent then bodyDust(character,position) end
		end)
	elseif action=="Arrive" then
		arrivalOrb(position+Vector3.new(0,2.5,0))
	end
end)
]=]
portalClient.Parent=sps

local portalServer=Instance.new("Script")
portalServer.Name="ToriiPortalServer"
portalServer.Source=[=[
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")

local remote=ReplicatedStorage:WaitForChild("ToriiPortalVFX")
local rootFolder=Workspace:WaitForChild("ToriiForest")
local portals=rootFolder:WaitForChild("Portals")
local portalA=portals:WaitForChild("PortalA")
local portalB=portals:WaitForChild("PortalB")
local triggerA=portalA:WaitForChild("Trigger")
local triggerB=portalB:WaitForChild("Trigger")

local dwell={}
local busy={}

local function inside(trigger,position)
	local p=trigger.CFrame:PointToObjectSpace(position)
	local h=trigger.Size*.5
	return math.abs(p.X)<=h.X and math.abs(p.Y)<=h.Y and math.abs(p.Z)<=h.Z
end

local function hideCharacter(character)
	local original={}
	for _,d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			original[d]=d.Transparency
			d.Transparency=1
		end
	end
	return original
end

local function restoreCharacter(original)
	for obj,value in pairs(original) do
		if obj and obj.Parent then obj.Transparency=value end
	end
end

local function teleport(player,fromTrigger,toTrigger)
	if busy[player] then return end
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end
	busy[player]=true
	dwell[player]=nil

	local oldWalk=humanoid.WalkSpeed
	local oldJump=humanoid.JumpPower
	local oldAuto=humanoid.AutoRotate
	humanoid.WalkSpeed=0
	humanoid.JumpPower=0
	humanoid.AutoRotate=false
	root.Anchored=true

	remote:FireClient(player,"Depart",root.Position)
	task.wait(.76)
	local original=hideCharacter(character)
	task.wait(.18)

	local exitCF=toTrigger.CFrame*CFrame.new(0,0,-(toTrigger.Size.Z*.5+5))
	root.CFrame=exitCF+Vector3.new(0,2,0)
	remote:FireClient(player,"Arrive",root.Position)
	task.wait(.42)

	restoreCharacter(original)
	root.Anchored=false
	humanoid.WalkSpeed=oldWalk
	humanoid.JumpPower=oldJump
	humanoid.AutoRotate=oldAuto

	task.wait(2.2)
	busy[player]=nil
end

task.spawn(function()
	while true do
		task.wait(.1)
		local now=os.clock()
		for _,player in ipairs(Players:GetPlayers()) do
			if not busy[player] then
				local character=player.Character
				local root=character and character:FindFirstChild("HumanoidRootPart")
				if root then
					local inA=inside(triggerA,root.Position)
					local inB=inside(triggerB,root.Position)
					local key=inA and "A" or (inB and "B" or nil)
					local state=dwell[player]
					if key then
						if not state or state.key~=key then
							dwell[player]={key=key,start=now}
						elseif now-state.start>=1 then
							task.spawn(teleport,player,key=="A" and triggerA or triggerB,key=="A" and triggerB or triggerA)
						end
					else
						dwell[player]=nil
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	dwell[player]=nil
	busy[player]=nil
end)
]=]
portalServer.Parent=ServerScriptService

-- Calm blue forest lighting like the reference screenshot.
Lighting.ClockTime=14.4
Lighting.Brightness=1.75
Lighting.ExposureCompensation=-.08
Lighting.Ambient=Color3.fromRGB(69,84,88)
Lighting.OutdoorAmbient=Color3.fromRGB(89,108,111)
Lighting.EnvironmentDiffuseScale=.38
Lighting.EnvironmentSpecularScale=.35
Lighting.ShadowSoftness=.45
pcall(function() Lighting.Technology=Enum.Technology.Future end)

local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="ToriiBlueFog"
atmosphere.Density=.39
atmosphere.Offset=.12
atmosphere.Color=Color3.fromRGB(126,158,171)
atmosphere.Decay=Color3.fromRGB(52,76,80)
atmosphere.Glare=.02
atmosphere.Haze=1.45
atmosphere.Parent=Lighting

local cc=Instance.new("ColorCorrectionEffect")
cc.Name="ToriiReferenceColor"
cc.Brightness=-.02
cc.Contrast=.06
cc.Saturation=-.17
cc.TintColor=Color3.fromRGB(195,218,222)
cc.Parent=Lighting

local rays=Instance.new("SunRaysEffect")
rays.Name="ToriiSoftRays"
rays.Intensity=.025
rays.Spread=.7
rays.Parent=Lighting

local bloom=Instance.new("BloomEffect")
bloom.Name="ToriiSoftBloom"
bloom.Intensity=.055
bloom.Size=16
bloom.Threshold=1.4
bloom.Parent=Lighting

local ambient=Instance.new("Sound")
ambient.Name="ToriiForestAmbience"
ambient.SoundId="rbxassetid://9113047896"
ambient.Looped=true
ambient.Volume=.08
ambient.Parent=SoundService

local ambienceClient=Instance.new("LocalScript")
ambienceClient.Name="ToriiForestAmbienceClient"
ambienceClient.Source=[=[
local SoundService=game:GetService("SoundService")
local sound=SoundService:WaitForChild("ToriiForestAmbience")
if not sound.IsPlaying then sound:Play() end
]=]
ambienceClient.Parent=sps

-- Spawn on the center stone path, facing the main torii.
local spawnGround=terrainHit(0,1060)
assert(spawnGround,"No spawn ground")
clearGrass(spawnGround,24,24)
local spawn=Instance.new("SpawnLocation")
spawn.Name="ForestSpawn"
spawn.Size=Vector3.new(7,.2,7)
spawn.Position=spawnGround+Vector3.new(0,3.2,0)
spawn.Anchored=true
spawn.Enabled=true
spawn.Neutral=true
spawn.Transparency=1
spawn.CanCollide=false
spawn.Duration=0
spawn.Parent=folders.Spawn

Workspace:SetAttribute("WorldRebuildComplete",true)
Workspace:SetAttribute("WorldRebuildVersion",VERSION)
Workspace:SetAttribute("HouseAssetId",HOUSE_ASSET_ID)
Workspace:SetAttribute("PortalAssetId",PORTAL_ASSET_ID)
Workspace:SetAttribute("JapaneseHouseCount",1)
Workspace:SetAttribute("PortalCount",2)
Workspace:SetAttribute("MeshTreeCount",meshTrees)
Workspace:SetAttribute("BlockTreeCount",centralBlockTrees)
Workspace:SetAttribute("StoneSlabCount",slabCount)
Workspace:SetAttribute("MainToriiPresent",true)
Workspace:SetAttribute("HouseBottomY",houseBottom)
Workspace:SetAttribute("HouseGroundY",houseGround.Y)

local sourceVersion=game.PlaceVersion
AssetService:SavePlaceAsync()

return {
	ok=true,
	sourceVersion=sourceVersion,
	version=VERSION,
	houseAssetId=HOUSE_ASSET_ID,
	portalAssetId=PORTAL_ASSET_ID,
	houseBottomY=houseBottom,
	houseGroundY=houseGround.Y,
	meshTrees=meshTrees,
	blockTrees=centralBlockTrees,
	stoneSlabs=slabCount,
	portals=2,
}
