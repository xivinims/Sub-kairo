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
local VERSION="2026-10-19-reference-clean-v6"
local Terrain=Workspace.Terrain
local rng=Random.new(1910202606)

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
	local model=nil
	local children=box:GetChildren()
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

local function part(parent,name,size,cf,material,color,collide,transparency)
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
	p.Transparency=transparency or 0
	p.Parent=parent
	return p
end

local BASE_Y=20

local function ground(x,z)
	local r=Workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-500,0))
	if r and r.Instance==Terrain and r.Material~=Enum.Material.Water then
		return r.Position
	end
	return Vector3.new(x,BASE_Y,z)
end

local function clearGrass(center,sx,sz)
	local region=Region3.new(center-Vector3.new(sx/2,6,sz/2),center+Vector3.new(sx/2,6,sz/2)):ExpandToGrid(4)
	pcall(function()
		Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.Ground)
	end)
end

local function placeOnGround(model,x,z,yaw,targetMax)
	if targetMax then
		local _,s=model:GetBoundingBox()
		local max=math.max(s.X,s.Y,s.Z)
		if max>0 then pcall(function() model:ScaleTo(targetMax/max) end) end
	end
	anchor(model)
	local g=ground(x,z)
	local cf,size=model:GetBoundingBox()
	local pivot=model:GetPivot()
	local bottom=cf.Position.Y-size.Y/2
	local offset=pivot.Position.Y-bottom
	model:PivotTo(CFrame.new(x,g.Y+offset,z)*CFrame.Angles(0,yaw or 0,0))
	local cf2,size2=model:GetBoundingBox()
	return g,size2,cf2.Position.Y-size2.Y/2
end

-- ============================================================
-- HARD RESET: no old map, no old menu, no old UI.
-- ============================================================
for _,child in ipairs(Workspace:GetChildren()) do
	if child~=Terrain and not child:IsA("Camera") then child:Destroy() end
end
Terrain:Clear()

for _,child in ipairs(StarterGui:GetChildren()) do child:Destroy() end
for _,child in ipairs(ReplicatedFirst:GetChildren()) do child:Destroy() end

local sps=StarterPlayer:WaitForChild("StarterPlayerScripts")
for _,child in ipairs(sps:GetChildren()) do child:Destroy() end
local scs=StarterPlayer:WaitForChild("StarterCharacterScripts")
for _,child in ipairs(scs:GetChildren()) do child:Destroy() end

for _,child in ipairs(ServerScriptService:GetChildren()) do child:Destroy() end
for _,child in ipairs(ReplicatedStorage:GetChildren()) do child:Destroy() end

for _,child in ipairs(Lighting:GetChildren()) do
	if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then child:Destroy() end
end
for _,child in ipairs(SoundService:GetChildren()) do child:Destroy() end

pcall(function() Workspace.StreamingEnabled=true end)
pcall(function() Workspace.StreamingMinRadius=96 end)
pcall(function() Workspace.StreamingTargetRadius=300 end)
pcall(function() Workspace.GlobalWind=Vector3.new(3.5,0,1.2) end)
pcall(function() Terrain.Decoration=true end)
pcall(function() Terrain.GrassLength=.22 end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(55,86,64)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(67,70,62)) end)
pcall(function() Terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(64,70,71)) end)

local world=Instance.new("Folder")
world.Name="ReferenceMap"
world.Parent=Workspace

local folders={}
for _,n in ipairs({"Forest","Path","Torii","House","Portals","Details","Spawn"}) do
	local f=Instance.new("Folder")
	f.Name=n
	f.Parent=world
	folders[n]=f
end

-- ============================================================
-- HUGE, ALMOST-FLAT FOREST BASE.
-- ============================================================
local HALF=1800
local CHUNK=300
for x=-HALF+CHUNK/2,HALF-CHUNK/2,CHUNK do
	for z=-HALF+CHUNK/2,HALF-CHUNK/2,CHUNK do
		Terrain:FillBlock(CFrame.new(x,-6,z),Vector3.new(CHUNK+8,52,CHUNK+8),Enum.Material.Grass)
	end
end
Terrain:FillBlock(CFrame.new(0,-40,0),Vector3.new(3650,32,3650),Enum.Material.Rock)

-- only very broad, subtle landscape variation
for _,h in ipairs({
	{Vector3.new(-1450,-245,-1200),275},
	{Vector3.new(1400,-245,-1150),275},
	{Vector3.new(-1450,-245,1200),275},
	{Vector3.new(1400,-245,1250),275},
}) do
	Terrain:FillBall(h[1],h[2],Enum.Material.Grass)
end

-- ============================================================
-- PATH: square dark slate pieces, reference composition.
-- ============================================================
local stoneCount=0
for z=1230,130,-23 do
	local x=math.sin(z*.019)*2.4+rng:NextNumber(-1.1,1.1)
	local g=ground(x,z)
	clearGrass(g,17,20)
	part(
		folders.Path,"StoneSlab",
		Vector3.new(rng:NextNumber(9,13),.7,rng:NextNumber(12,18)),
		CFrame.new(x,g.Y+.2,z)*CFrame.Angles(0,math.rad(rng:NextNumber(-5,5)),math.rad(rng:NextNumber(-1,1))),
		Enum.Material.Slate,
		Color3.fromRGB(rng:NextInteger(54,64),rng:NextInteger(61,71),rng:NextInteger(62,72)),
		true,0
	)
	stoneCount+=1
end

-- small broken side slabs like the photo
for i=1,40 do
	local z=rng:NextNumber(520,1080)
	local side=(i%2==0) and -1 or 1
	local x=side*rng:NextNumber(17,40)
	local g=ground(x,z)
	clearGrass(g,10,10)
	part(
		folders.Path,"BrokenSlab",
		Vector3.new(rng:NextNumber(5,9),.55,rng:NextNumber(6,11)),
		CFrame.new(x,g.Y+.16,z)*CFrame.Angles(0,rng:NextNumber(-.28,.28),rng:NextNumber(-.03,.03)),
		Enum.Material.Slate,Color3.fromRGB(51,59,60),true,0
	)
end

-- ============================================================
-- TORII: upright, large, centered, dark stone, rope.
-- ============================================================
local function createTorii(parent,center,scale,name)
	local m=Instance.new("Model")
	m.Name=name
	m.Parent=parent
	local c1=Color3.fromRGB(47,54,56)
	local c2=Color3.fromRGB(58,64,65)
	local postH=34*scale
	for _,side in ipairs({-1,1}) do
		local px=side*15*scale
		part(m,"Foot",Vector3.new(7.4*scale,1.6*scale,7.4*scale),CFrame.new(center+Vector3.new(px,.8*scale,0)),Enum.Material.Slate,c2,true,0)
		local post=part(m,"Post",Vector3.new(postH,4.4*scale,4.4*scale),CFrame.new(center+Vector3.new(px,1.6*scale+postH/2,0))*CFrame.Angles(0,0,math.rad(90)),Enum.Material.Slate,c1,true,0)
		post.Shape=Enum.PartType.Cylinder
		part(m,"Collar",Vector3.new(5.6*scale,2.1*scale,5.6*scale),CFrame.new(center+Vector3.new(px,postH-2.2*scale,0)),Enum.Material.Slate,c2,true,0)
	end
	part(m,"LowerBeam",Vector3.new(39*scale,3.2*scale,4.2*scale),CFrame.new(center+Vector3.new(0,27*scale,0)),Enum.Material.Slate,c1,true,0)
	part(m,"TopBeam",Vector3.new(47*scale,3.6*scale,4.8*scale),CFrame.new(center+Vector3.new(0,34*scale,0)),Enum.Material.Slate,c1,true,0)
	part(m,"TopLeft",Vector3.new(9*scale,2.7*scale,5*scale),CFrame.new(center+Vector3.new(-23*scale,35.2*scale,0))*CFrame.Angles(0,0,math.rad(8)),Enum.Material.Slate,c1,true,0)
	part(m,"TopRight",Vector3.new(9*scale,2.7*scale,5*scale),CFrame.new(center+Vector3.new(23*scale,35.2*scale,0))*CFrame.Angles(0,0,math.rad(-8)),Enum.Material.Slate,c1,true,0)
	part(m,"CenterBrace",Vector3.new(9*scale,5.8*scale,3.4*scale),CFrame.new(center+Vector3.new(0,30.2*scale,0)),Enum.Material.Slate,c2,true,0)

	local pa=part(m,"RopeA",Vector3.new(.15,.15,.15),CFrame.new(center+Vector3.new(-12*scale,24.5*scale,2.5*scale)),Enum.Material.SmoothPlastic,c1,false,1)
	local pb=part(m,"RopeB",Vector3.new(.15,.15,.15),CFrame.new(center+Vector3.new(12*scale,24.5*scale,2.5*scale)),Enum.Material.SmoothPlastic,c1,false,1)
	local aa=Instance.new("Attachment");aa.Parent=pa
	local ab=Instance.new("Attachment");ab.Parent=pb
	local rope=Instance.new("Beam")
	rope.Attachment0=aa;rope.Attachment1=ab
	rope.Width0=.8*scale;rope.Width1=.8*scale
	rope.Color=ColorSequence.new(Color3.fromRGB(129,102,69))
	rope.CurveSize0=-5.5*scale;rope.CurveSize1=5.5*scale
	rope.Segments=28;rope.FaceCamera=true;rope.Parent=m

	for _,tx in ipairs({-6,0,6}) do
		local t1=part(m,"TasselTop",Vector3.new(.12,.12,.12),CFrame.new(center+Vector3.new(tx*scale,21.7*scale,2.5*scale)),Enum.Material.SmoothPlastic,c1,false,1)
		local t2=part(m,"TasselBottom",Vector3.new(.12,.12,.12),CFrame.new(center+Vector3.new(tx*scale,17.5*scale,2.5*scale)),Enum.Material.SmoothPlastic,c1,false,1)
		local a1=Instance.new("Attachment");a1.Parent=t1
		local a2=Instance.new("Attachment");a2.Parent=t2
		local b=Instance.new("Beam");b.Attachment0=a1;b.Attachment1=a2;b.Width0=.32*scale;b.Width1=.16*scale;b.FaceCamera=true;b.Color=ColorSequence.new(Color3.fromRGB(129,102,69));b.Parent=m
		part(m,"Tassel",Vector3.new(.9*scale,1.5*scale,.9*scale),CFrame.new(center+Vector3.new(tx*scale,16.7*scale,2.5*scale)),Enum.Material.Wood,Color3.fromRGB(119,91,62),false,0)
	end
	clearGrass(center,62*scale,34*scale)
	return m
end

local tg=ground(0,655)
createTorii(folders.Torii,tg,1,"MainTorii")
local tg2=ground(0,405)
createTorii(folders.Torii,tg2,.62,"DistantTorii")

-- ============================================================
-- EXACT uploaded Japanese house: ONE, grounded, centered in background.
-- ============================================================
local house=loadModel(HOUSE_ASSET_ID,"JapaneseHouse")
house.Parent=folders.House
local houseGround,houseSize,houseBottom=placeOnGround(house,0,120,math.rad(180),125)
clearGrass(houseGround,houseSize.X+18,houseSize.Z+18)

-- ============================================================
-- FOREST: blocky low-poly silhouettes like reference.
-- ============================================================
local function blockTree(pos,scale,index,distant)
	local m=Instance.new("Model")
	m.Name=(distant and "DistantTree_" or "BlockTree_")..index
	m.Parent=folders.Forest

	local trunk=Color3.fromRGB(36,45,46)
	local leaves={
		Color3.fromRGB(46,72,60),
		Color3.fromRGB(52,80,64),
		Color3.fromRGB(57,86,67),
		Color3.fromRGB(43,68,57),
	}

	local h=rng:NextNumber(22,34)*scale
	part(m,"Trunk",Vector3.new(4.1*scale,h,4.1*scale),CFrame.new(pos+Vector3.new(0,h/2,0)),Enum.Material.Wood,trunk,true,0)

	for branch=1,3 do
		local a=(branch/3)*math.pi*2+rng:NextNumber(-.2,.2)
		local ox=math.cos(a)*3.2*scale
		local oz=math.sin(a)*3.2*scale
		part(m,"Branch",Vector3.new(2.2*scale,10*scale,2.2*scale),CFrame.new(pos+Vector3.new(ox,h*.68,oz))*CFrame.Angles(math.rad(rng:NextNumber(-22,22)),0,math.rad(rng:NextNumber(-28,28))),Enum.Material.Wood,trunk,false,0)
	end

	local crownY=pos.Y+h+2*scale
	for i=1,8 do
		local ox=rng:NextNumber(-7.5,7.5)*scale
		local oy=rng:NextNumber(-2.5,7)*scale
		local oz=rng:NextNumber(-7,7)*scale
		local leaf=part(
			m,"Canopy",
			Vector3.new(rng:NextNumber(9,15)*scale,rng:NextNumber(7,12)*scale,rng:NextNumber(9,15)*scale),
			CFrame.new(pos.X+ox,crownY+oy,pos.Z+oz)*CFrame.Angles(rng:NextNumber(-.08,.08),rng:NextNumber(-.18,.18),rng:NextNumber(-.08,.08)),
			Enum.Material.SmoothPlastic,
			leaves[rng:NextInteger(1,#leaves)],
			false,0
		)
		leaf.CanQuery=false
	end
end

local treeCount=0

-- Hero trees near path, matching screenshot framing.
for z=310,1160,58 do
	for _,side in ipairs({-1,1}) do
		if rng:NextNumber()<.9 then
			local x=side*rng:NextNumber(62,125)
			local g=ground(x,z)
			blockTree(g,rng:NextNumber(.95,1.35),treeCount+1,false)
			treeCount+=1
		end
	end
end

-- Dense mid forest.
local attempts=0
while treeCount<330 and attempts<5000 do
	attempts+=1
	local x=rng:NextNumber(-1150,1150)
	local z=rng:NextNumber(-1150,1500)
	if not (math.abs(x)<52 and z>70 and z<1280) then
		local g=ground(x,z)
		blockTree(g,rng:NextNumber(.82,1.22),treeCount+1,false)
		treeCount+=1
	end
end

-- Outer ring: oversized dark silhouettes, makes forest look endless in fog.
for i=1,140 do
	local a=(i/140)*math.pi*2+rng:NextNumber(-.015,.015)
	local r=rng:NextNumber(1450,1720)
	local x=math.cos(a)*r
	local z=math.sin(a)*r
	local g=ground(x,z)
	blockTree(g,rng:NextNumber(1.15,1.7),treeCount+1,true)
	treeCount+=1
end

-- ============================================================
-- Uploaded portal model: two quiet map portals, no menu/UI.
-- ============================================================
local portalTemplate=loadModel(PORTAL_ASSET_ID,"PortalTemplate")
local _,ps=portalTemplate:GetBoundingBox()
local pmax=math.max(ps.X,ps.Y,ps.Z)
if pmax>0 then pcall(function() portalTemplate:ScaleTo(34/pmax) end) end

local function placePortal(name,x,z,yaw)
	local m=portalTemplate:Clone()
	m.Name=name
	m.Parent=folders.Portals
	local g,size,bottom=placeOnGround(m,x,z,yaw,nil)
	clearGrass(g,math.max(18,size.X+8),math.max(18,size.Z+8))
	local cf,sz=m:GetBoundingBox()
	local trigger=part(m,"Trigger",Vector3.new(math.clamp(sz.X*.5,7,14),math.clamp(sz.Y*.65,10,20),math.clamp(sz.Z*.4,5,10)),cf,Enum.Material.SmoothPlastic,Color3.new(1,1,1),false,1)
	trigger.CanQuery=false
	trigger.CanTouch=false
	return m,trigger
end

local portalA,triggerA=placePortal("PortalA",-760,260,math.rad(90))
local portalB,triggerB=placePortal("PortalB",760,-640,math.rad(-90))
portalTemplate:Destroy()

-- ============================================================
-- Portal teleport VFX only; no menu.
-- ============================================================
local remote=Instance.new("RemoteEvent")
remote.Name="PortalVFX"
remote.Parent=ReplicatedStorage

local client=Instance.new("LocalScript")
client.Name="PortalVFXClient"
client.Source=[=[
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("PortalVFX")

local function cube(parent,size,color)
	local p=Instance.new("Part")
	p.Size=size;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
	p.Material=Enum.Material.SmoothPlastic;p.Color=color;p.CastShadow=false;p.Parent=parent
	return p
end

local function departing(center,character)
	local folder=Instance.new("Folder");folder.Name="_PortalDepart";folder.Parent=workspace
	local rings={}
	for r=1,3 do
		for i=1,34 do
			local a=(i/34)*math.pi*2
			local p=cube(folder,Vector3.new(.12,.12,.46),Color3.fromRGB(137,185,202))
			table.insert(rings,{p=p,a=a,r=r})
		end
	end
	local start=os.clock()
	local conn
	conn=RunService.RenderStepped:Connect(function()
		local t=os.clock()-start
		if t>.78 then conn:Disconnect();return end
		for _,v in ipairs(rings) do
			local rr=3+v.r*.72
			local a=v.a+t*(3.6+v.r*.6)
			v.p.CFrame=CFrame.new(center+Vector3.new(math.cos(a)*rr,(v.r-2)*1.6,math.sin(a)*rr))*CFrame.Angles(0,-a,0)
			v.p.Transparency=t*.7
		end
	end)

	task.delay(.24,function()
		if not character.Parent then return end
		for _,body in ipairs(character:GetDescendants()) do
			if body:IsA("BasePart") and body.Name~="HumanoidRootPart" then
				local amount=math.clamp(math.floor(body.Size.Magnitude*8),8,28)
				for i=1,amount do
					local p=cube(folder,Vector3.new(.1,.1,.1)*math.random(1,3),body.Color)
					local localPos=Vector3.new((math.random()-.5)*body.Size.X,(math.random()-.5)*body.Size.Y,(math.random()-.5)*body.Size.Z)
					p.CFrame=body.CFrame*CFrame.new(localPos)
					local out=p.Position+Vector3.new((math.random()-.5)*10,math.random(3,10),(math.random()-.5)*10)
					TweenService:Create(p,TweenInfo.new(.52,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=out,Transparency=1,Size=Vector3.new(.03,.03,.03)}):Play()
				end
			end
		end
	end)
	Debris:AddItem(folder,.9)
end

local function arriving(center)
	local folder=Instance.new("Folder");folder.Name="_PortalArrive";folder.Parent=workspace
	local orb=cube(folder,Vector3.new(.4,.4,.4),Color3.fromRGB(143,197,215))
	orb.Shape=Enum.PartType.Ball;orb.Position=center;orb.Transparency=.18
	TweenService:Create(orb,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(5,5,5),Transparency=.35}):Play()
	for i=1,140 do
		local a=math.random()*math.pi*2
		local u=math.random()*2-1
		local rr=math.sqrt(1-u*u)
		local dir=Vector3.new(rr*math.cos(a),u,rr*math.sin(a))
		local p=cube(folder,Vector3.new(.09,.09,.09)*math.random(1,3),Color3.fromRGB(135,188,204))
		p.Position=center+dir*math.random(4,9)
		TweenService:Create(p,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=center,Transparency=.1}):Play()
		task.delay(.34,function()
			if p.Parent then TweenService:Create(p,TweenInfo.new(.26),{Position=center+dir*math.random(5,12),Transparency=1,Size=Vector3.new(.03,.03,.03)}):Play() end
		end)
	end
	task.delay(.36,function()
		if orb.Parent then TweenService:Create(orb,TweenInfo.new(.14),{Size=Vector3.new(8,8,8),Transparency=1}):Play() end
	end)
	Debris:AddItem(folder,.75)
end

remote.OnClientEvent:Connect(function(action,pos)
	local char=player.Character
	if action=="Depart" and char then departing(pos,char) end
	if action=="Arrive" then arriving(pos+Vector3.new(0,2.5,0)) end
end)
]=]
client.Parent=sps

local server=Instance.new("Script")
server.Name="PortalServer"
server.Source=[=[
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local remote=ReplicatedStorage:WaitForChild("PortalVFX")
local portals=Workspace.ReferenceMap.Portals
local A=portals.PortalA.Trigger
local B=portals.PortalB.Trigger
local dwell={}
local busy={}

local function inside(trigger,pos)
	local p=trigger.CFrame:PointToObjectSpace(pos)
	local h=trigger.Size*.5
	return math.abs(p.X)<=h.X and math.abs(p.Y)<=h.Y and math.abs(p.Z)<=h.Z
end

local function hide(character)
	local map={}
	for _,d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then map[d]=d.Transparency;d.Transparency=1 end
	end
	return map
end

local function restore(map)
	for obj,v in pairs(map) do if obj and obj.Parent then obj.Transparency=v end end
end

local function teleport(player,from,to)
	if busy[player] then return end
	local c=player.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if not h or not root then return end
	busy[player]=true;dwell[player]=nil
	local walk,jump,auto=h.WalkSpeed,h.JumpPower,h.AutoRotate
	h.WalkSpeed=0;h.JumpPower=0;h.AutoRotate=false;root.Anchored=true
	remote:FireClient(player,"Depart",root.Position)
	task.wait(.75)
	local map=hide(c)
	task.wait(.14)
	root.CFrame=to.CFrame*CFrame.new(0,0,-(to.Size.Z/2+5))+Vector3.new(0,2,0)
	remote:FireClient(player,"Arrive",root.Position)
	task.wait(.38)
	restore(map)
	root.Anchored=false;h.WalkSpeed=walk;h.JumpPower=jump;h.AutoRotate=auto
	task.wait(2);busy[player]=nil
end

task.spawn(function()
	while true do
		task.wait(.1)
		local now=os.clock()
		for _,p in ipairs(Players:GetPlayers()) do
			if not busy[p] then
				local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local key=inside(A,root.Position) and "A" or (inside(B,root.Position) and "B" or nil)
					local s=dwell[p]
					if key then
						if not s or s.key~=key then dwell[p]={key=key,start=now}
						elseif now-s.start>=1 then
							task.spawn(teleport,p,key=="A" and A or B,key=="A" and B or A)
						end
					else dwell[p]=nil end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(p) dwell[p]=nil;busy[p]=nil end)
]=]
server.Parent=ServerScriptService

-- ============================================================
-- ONLY UI: loading screen. No menu at all.
-- ============================================================
local loader=Instance.new("LocalScript")
loader.Name="MapLoadingScreen"
loader.Source=[=[
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()
local player=Players.LocalPlayer

local gui=Instance.new("ScreenGui")
gui.Name="MapLoadingScreen"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=10000
gui.Parent=player:WaitForChild("PlayerGui")

local bg=Instance.new("Frame")
bg.Size=UDim2.fromScale(1,1)
bg.BackgroundColor3=Color3.fromRGB(25,35,38)
bg.BorderSizePixel=0
bg.Parent=gui

local haze=Instance.new("UIGradient")
haze.Rotation=90
haze.Color=ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.fromRGB(69,95,102)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(22,31,34))
})
haze.Parent=bg

local title=Instance.new("TextLabel")
title.AnchorPoint=Vector2.new(.5,.5)
title.Position=UDim2.fromScale(.5,.48)
title.Size=UDim2.fromOffset(260,40)
title.BackgroundTransparency=1
title.Font=Enum.Font.GothamMedium
title.Text="Carregando floresta"
title.TextColor3=Color3.fromRGB(221,230,230)
title.TextSize=18
title.Parent=bg

local dots=Instance.new("TextLabel")
dots.AnchorPoint=Vector2.new(.5,.5)
dots.Position=UDim2.fromScale(.5,.54)
dots.Size=UDim2.fromOffset(100,30)
dots.BackgroundTransparency=1
dots.Font=Enum.Font.Gotham
dots.TextColor3=Color3.fromRGB(171,191,195)
dots.TextSize=18
dots.Parent=bg

local alive=true
task.spawn(function()
	local i=0
	while alive do
		i=(i%3)+1
		dots.Text=string.rep("•",i)
		task.wait(.35)
	end
end)

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(.7)
alive=false
TweenService:Create(bg,TweenInfo.new(.55),{BackgroundTransparency=1}):Play()
for _,d in ipairs(bg:GetDescendants()) do
	if d:IsA("TextLabel") then TweenService:Create(d,TweenInfo.new(.45),{TextTransparency=1}):Play() end
end
task.wait(.6)
gui:Destroy()
]=]
loader.Parent=ReplicatedFirst

-- ============================================================
-- Lighting: reference blue mist.
-- ============================================================
Lighting.ClockTime=14.1
Lighting.Brightness=1.55
Lighting.ExposureCompensation=-.12
Lighting.Ambient=Color3.fromRGB(64,77,81)
Lighting.OutdoorAmbient=Color3.fromRGB(85,101,105)
Lighting.EnvironmentDiffuseScale=.32
Lighting.EnvironmentSpecularScale=.28
Lighting.ShadowSoftness=.48
pcall(function() Lighting.Technology=Enum.Technology.Future end)

local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="ReferenceBlueFog"
atmosphere.Density=.42
atmosphere.Offset=.1
atmosphere.Color=Color3.fromRGB(119,149,163)
atmosphere.Decay=Color3.fromRGB(48,67,72)
atmosphere.Glare=.015
atmosphere.Haze=1.65
atmosphere.Parent=Lighting

local cc=Instance.new("ColorCorrectionEffect")
cc.Name="ReferenceColor"
cc.Brightness=-.03
cc.Contrast=.07
cc.Saturation=-.2
cc.TintColor=Color3.fromRGB(188,211,216)
cc.Parent=Lighting

local bloom=Instance.new("BloomEffect")
bloom.Name="ReferenceBloom"
bloom.Intensity=.035
bloom.Size=14
bloom.Threshold=1.45
bloom.Parent=Lighting

-- Spawn at the front of the path looking toward torii.
local sg=ground(0,1210)
clearGrass(sg,24,24)
local spawn=Instance.new("SpawnLocation")
spawn.Name="ForestSpawn"
spawn.Size=Vector3.new(7,.2,7)
spawn.Position=sg+Vector3.new(0,3.2,0)
spawn.Anchored=true
spawn.Enabled=true
spawn.Neutral=true
spawn.Transparency=1
spawn.CanCollide=false
spawn.Duration=0
spawn.Parent=folders.Spawn

Workspace:SetAttribute("WorldRebuildComplete",true)
Workspace:SetAttribute("WorldRebuildVersion",VERSION)
Workspace:SetAttribute("JapaneseHouseCount",1)
Workspace:SetAttribute("HouseBottomY",houseBottom)
Workspace:SetAttribute("HouseGroundY",houseGround.Y)
Workspace:SetAttribute("PortalCount",2)
Workspace:SetAttribute("TreeCount",treeCount)
Workspace:SetAttribute("StoneCount",stoneCount)
Workspace:SetAttribute("OldMenuRemoved",true)
Workspace:SetAttribute("LoadingScreenOnly",true)

local sourceVersion=game.PlaceVersion
AssetService:SavePlaceAsync()

return {
	ok=true,
	sourceVersion=sourceVersion,
	version=VERSION,
	trees=treeCount,
	stones=stoneCount,
	houseBottom=houseBottom,
	houseGround=houseGround.Y,
	portals=2,
}
