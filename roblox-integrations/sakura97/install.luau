-- XN [VOICE] v110 — gigantic procedural nature world
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local A=game:GetService("AssetService")
local CS=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local RS=game:GetService("ReplicatedStorage")
local RF=game:GetService("ReplicatedFirst")
local SS=game:GetService("ServerStorage")
local SSS=game:GetService("ServerScriptService")
local SP=game:GetService("StarterPlayer")
local SG=game:GetService("StarterGui")
local Terrain=workspace.Terrain

local VERSION=110
local PBR_ID=13536410655
local HD_ID=18242663106
local ROCK_ID=8248445118
local BIG_TREE_ID=86013526879602
local WIND_ID=11946229834
local BUTTERFLY_ID=4639818571
local WORLD_SIZE=248000
local WORLD_HALF=WORLD_SIZE/2
local LAND_HALF=112000
local CHUNK=512
local SHALLOW_WATER_DEPTH=6

local function load(id)
	local ok,res=pcall(A.LoadAssetAsync,A,id)
	assert(ok and res,"Asset "..id.." failed: "..tostring(res))
	return res
end

local function clear(c)
	for _,x in ipairs(c:GetChildren()) do x:Destroy() end
end

-- Complete reset. Nothing from Brookhaven or older XN builds survives.
for _,x in ipairs(workspace:GetChildren()) do
	if x~=Terrain and not x:IsA("Camera") then x:Destroy() end
end
Terrain:Clear()
clear(SSS)
clear(RF)
clear(SP.StarterPlayerScripts)
clear(SG)
for _,x in ipairs(RS:GetChildren()) do x:Destroy() end
for _,x in ipairs(SS:GetChildren()) do
	if x.Name=="XNNatureTemplates" then x:Destroy() end
end
clear(Lighting)

pcall(function()
	workspace.StreamingEnabled=true
	workspace.StreamingMinRadius=64
	workspace.StreamingTargetRadius=640
	workspace.StreamOutBehavior=Enum.StreamOutBehavior.Opportunistic
end)
workspace.FallenPartsDestroyHeight=-200
workspace.GlobalWind=Vector3.new(12,0,4)

pcall(function()
	Terrain.Decoration=true
	Terrain.GrassLength=.68
end)
Terrain.WaterColor=Color3.fromRGB(43,104,105)
Terrain.WaterTransparency=.24
Terrain.WaterReflectance=.08
Terrain.WaterWaveSize=.12
Terrain.WaterWaveSpeed=7

Lighting.ClockTime=14.15
Lighting.Brightness=2.25
Lighting.ExposureCompensation=.02
Lighting.GlobalShadows=true
Lighting.Ambient=Color3.fromRGB(112,119,107)
Lighting.OutdoorAmbient=Color3.fromRGB(142,151,136)
local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="XNNaturalAtmosphere"
atmosphere.Density=.12
atmosphere.Offset=.08
atmosphere.Color=Color3.fromRGB(209,220,205)
atmosphere.Decay=Color3.fromRGB(118,132,112)
atmosphere.Haze=.65
atmosphere.Glare=.02
atmosphere.Parent=Lighting
local cc=Instance.new("ColorCorrectionEffect")
cc.Name="XNNaturalColor"
cc.Contrast=.035
cc.Saturation=.04
cc.TintColor=Color3.fromRGB(250,255,246)
cc.Parent=Lighting

local runtime=Instance.new("Folder")
runtime.Name="XNWorldRuntime"
runtime.Parent=RS
runtime:SetAttribute("Version",VERSION)
runtime:SetAttribute("GameName","XN [VOICE]")
runtime:SetAttribute("WorldSize",WORLD_SIZE)
runtime:SetAttribute("WorldHalf",WORLD_HALF)
runtime:SetAttribute("LandHalf",LAND_HALF)
runtime:SetAttribute("ChunkSize",CHUNK)
runtime:SetAttribute("WaterDepth",SHALLOW_WATER_DEPTH)
runtime:SetAttribute("Generator","ProceduralNatureChunks")
runtime:SetAttribute("Border","WaterBelt")
runtime:SetAttribute("PBRAssetId",PBR_ID)
runtime:SetAttribute("HDAssetId",HD_ID)
runtime:SetAttribute("RockAssetId",ROCK_ID)
runtime:SetAttribute("BigTreeAssetId",BIG_TREE_ID)
runtime:SetAttribute("ButterflyAssetId",BUTTERFLY_ID)

local templates=Instance.new("Folder")
templates.Name="XNNatureTemplates"
templates.Parent=SS
for _,name in ipairs({"Trees","Plants","Flowers","Rocks","BigTrees"}) do
	local f=Instance.new("Folder"); f.Name=name; f.Parent=templates
end

local clientAssets=Instance.new("Folder")
clientAssets.Name="XNNatureClientAssets"
clientAssets.Parent=RS

local function stripAndAnchor(root)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored=true
			d.CanTouch=false
			d.CanQuery=true
			local n=d.Name:lower()
			if n:find("leaf",1,true) or n:find("leaves",1,true) or n:find("foliage",1,true)
				or n:find("flower",1,true) or n:find("grass",1,true) or n:find("bush",1,true) then
				d.CanCollide=false
			end
		end
	end
	if root:IsA("BasePart") then
		root.Anchored=true
		root.CanTouch=false
	end
end

local function cloneRoot(obj)
	local c=obj:Clone()
	stripAndAnchor(c)
	return c
end

local treeTokens={"tree","oak","pine","birch","spruce","willow","palm"}
local plantTokens={"bush","fern","plant","shrub","reed","grass","cattail","mushroom"}
local flowerTokens={"flower","daisy","rose","lavender","clover","blossom","tulip","lily","sunflower"}
local rockTokens={"rock","stone","boulder","pebble"}

local function hasToken(name,tokens)
	name=name:lower()
	for _,t in ipairs(tokens) do if name:find(t,1,true) then return true end end
	return false
end

local function isCandidateRoot(d)
	if not (d:IsA("Model") or d:IsA("BasePart")) then return false end
	local p=d.Parent
	while p and p~=workspace do
		if p:IsA("Model") and (hasToken(p.Name,treeTokens) or hasToken(p.Name,plantTokens) or hasToken(p.Name,flowerTokens) or hasToken(p.Name,rockTokens)) then
			return false
		end
		p=p.Parent
	end
	return true
end

local function addCategory(asset,folder,tokens,limit)
	local added=0
	for _,d in ipairs(asset:GetDescendants()) do
		if added>=limit then break end
		if isCandidateRoot(d) and hasToken(d.Name,tokens) then
			local c=cloneRoot(d)
			c.Name=string.format("%s_%02d",folder.Name,added+1)
			c:SetAttribute("OriginalName",d.Name)
			c.Parent=folder
			added+=1
		end
	end
	return added
end

local function addFallback(asset,folder,limit,minY)
	local candidates={}
	for _,d in ipairs(asset:GetDescendants()) do
		if d:IsA("Model") then
			local ok,cf,size=pcall(function() return d:GetBoundingBox() end)
			if ok and size.Y>minY and size.X<250 and size.Z<250 then
				table.insert(candidates,{obj=d,score=size.Y+math.max(size.X,size.Z)*.2})
			end
		end
	end
	table.sort(candidates,function(a,b) return a.score>b.score end)
	local n=0
	for _,entry in ipairs(candidates) do
		if n>=limit then break end
		local c=cloneRoot(entry.obj)
		c.Name=string.format("%s_Fallback_%02d",folder.Name,n+1)
		c:SetAttribute("OriginalName",entry.obj.Name)
		c.Parent=folder
		n+=1
	end
	return n
end

local treeFolder=templates.Trees
local plantFolder=templates.Plants
local flowerFolder=templates.Flowers
local rockFolder=templates.Rocks
local bigFolder=templates.BigTrees

-- PBR + HD nature packs supply foliage/trees/flowers.
for _,id in ipairs({PBR_ID,HD_ID}) do
	local asset=load(id)
	local t=addCategory(asset,treeFolder,treeTokens,5)
	local p=addCategory(asset,plantFolder,plantTokens,6)
	local f=addCategory(asset,flowerFolder,flowerTokens,6)
	if t==0 then addFallback(asset,treeFolder,3,8) end
	if p==0 then addFallback(asset,plantFolder,3,1) end
	if f==0 then
		-- Small green/colorful models as a safe pack-native fallback for ground flora.
		local small={}
		for _,d in ipairs(asset:GetDescendants()) do
			if d:IsA("Model") then
				local ok,cf,size=pcall(function() return d:GetBoundingBox() end)
				if ok and size.Y>0.2 and size.Y<7 and math.max(size.X,size.Z)<16 then
					table.insert(small,{obj=d,score=size.Y})
				end
			end
		end
		table.sort(small,function(a,b) return a.score<b.score end)
		for i=1,math.min(4,#small) do
			local c=cloneRoot(small[i].obj); c.Name="Flowers_Fallback_"..i; c.Parent=flowerFolder
		end
	end
	asset:Destroy()
end

-- Rocks come ONLY from the exact rock pack requested.
do
	local asset=load(ROCK_ID)
	local r=addCategory(asset,rockFolder,rockTokens,10)
	if r==0 then
		for _,d in ipairs(asset:GetChildren()) do
			if #rockFolder:GetChildren()>=8 then break end
			if d:IsA("Model") or d:IsA("BasePart") then
				local c=cloneRoot(d); c.Name="Rocks_Exact_"..(#rockFolder:GetChildren()+1); c.Parent=rockFolder
			end
		end
	end
	if #rockFolder:GetChildren()==0 then
		for _,d in ipairs(asset:GetDescendants()) do
			if d:IsA("MeshPart") or d:IsA("Part") then
				local c=cloneRoot(d); c.Name="Rocks_Exact_1"; c.Parent=rockFolder; break
			end
		end
	end
	asset:Destroy()
end

-- Exact giant tree requested.
do
	local asset=load(BIG_TREE_ID)
	local best=nil
	local bestScore=-1
	for _,d in ipairs(asset:GetChildren()) do
		if d:IsA("Model") then
			local ok,cf,size=pcall(function() return d:GetBoundingBox() end)
			if ok then
				local score=size.Y*4+size.X+size.Z
				if score>bestScore then best=d; bestScore=score end
			end
		elseif d:IsA("BasePart") then
			local score=d.Size.Y*4+d.Size.X+d.Size.Z
			if score>bestScore then best=d; bestScore=score end
		end
	end
	if not best then
		for _,d in ipairs(asset:GetDescendants()) do
			if d:IsA("Model") or d:IsA("BasePart") then best=d break end
		end
	end
	assert(best,"Big tree asset had no geometry")
	local c=cloneRoot(best); c.Name="ExactBigTree"; c:SetAttribute("AssetId",BIG_TREE_ID); c.Parent=bigFolder
	asset:Destroy()
end

-- One pack-native leaf mesh/part becomes the REAL falling-leaf object.
do
	local best=nil
	local bestScore=1e9
	for _,folder in ipairs({treeFolder,plantFolder}) do
		for _,root in ipairs(folder:GetChildren()) do
			for _,d in ipairs(root:GetDescendants()) do
				if d:IsA("BasePart") then
					local n=d.Name:lower()
					local pn=(d.Parent and d.Parent.Name or ""):lower()
					local gpn=(d.Parent and d.Parent.Parent and d.Parent.Parent.Name or ""):lower()
					local c=d.Color
					local foliage=n:find("leaf",1,true) or n:find("leaves",1,true) or n:find("foliage",1,true)
						or pn:find("leaf",1,true) or pn:find("leaves",1,true) or pn:find("foliage",1,true)
						or gpn:find("leaf",1,true) or gpn:find("leaves",1,true) or gpn:find("foliage",1,true)
						or (c.G>c.R*1.12 and c.G>c.B*1.06)
					local score=d.Size.X*d.Size.Y*d.Size.Z
					if foliage and score<bestScore then best=d; bestScore=score end
				end
			end
		end
	end
	assert(best,"No pack-native leaf geometry found")
	local leaf=best:Clone()
	leaf.Name="LeafTemplate"
	for _,x in ipairs(leaf:GetDescendants()) do if x:IsA("LuaSourceContainer") then x:Destroy() end end
	leaf.Anchored=false
	leaf.CanCollide=false
	leaf.CanTouch=false
	leaf.CanQuery=false
	leaf.Massless=true
	local maxDim=math.max(leaf.Size.X,leaf.Size.Y,leaf.Size.Z)
	if maxDim>0 then leaf.Size=leaf.Size*(.48/maxDim) end
	leaf:SetAttribute("FromNaturePack",true)
	leaf.Parent=clientAssets
end

-- Lightweight actual butterfly model from Creator Store, animated client-side.
do
	local asset=load(BUTTERFLY_ID)
	local root=nil
	for _,d in ipairs(asset:GetChildren()) do if d:IsA("Model") or d:IsA("BasePart") then root=d break end end
	if not root then for _,d in ipairs(asset:GetDescendants()) do if d:IsA("Model") or d:IsA("BasePart") then root=d break end end end
	assert(root,"Butterfly asset has no geometry")
	local model
	if root:IsA("Model") then model=cloneRoot(root) else model=Instance.new("Model"); local p=cloneRoot(root); p.Parent=model end
	model.Name="ButterflyTemplate"
	model:SetAttribute("AssetId",BUTTERFLY_ID)
	for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false end end
	model.Parent=clientAssets
	asset:Destroy()
end

assert(#treeFolder:GetChildren()>0,"No tree templates")
assert(#plantFolder:GetChildren()>0,"No plant templates")
assert(#flowerFolder:GetChildren()>0,"No flower templates")
assert(#rockFolder:GetChildren()>0,"No exact rock templates")
assert(#bigFolder:GetChildren()==1,"Big tree template missing")

runtime:SetAttribute("TreeTemplates",#treeFolder:GetChildren())
runtime:SetAttribute("PlantTemplates",#plantFolder:GetChildren())
runtime:SetAttribute("FlowerTemplates",#flowerFolder:GetChildren())
runtime:SetAttribute("RockTemplates",#rockFolder:GetChildren())

-- Wind modules from the exact Wind Effects asset, without its debug/demo GUI.
do
	local asset=load(WIND_ID)
	local controller=asset:FindFirstChild("WindController",true)
	assert(controller and controller:FindFirstChild("WindLines") and controller:FindFirstChild("WindShake"),"Wind asset modules missing")
	local client=Instance.new("LocalScript")
	client.Name="XNNatureClient"
	controller.WindLines:Clone().Parent=client
	controller.WindShake:Clone().Parent=client
	client.Source=[=[
local Players=game:GetService("Players")
local CS=game:GetService("CollectionService")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Debris=game:GetService("Debris")
local Workspace=game:GetService("Workspace")

local player=Players.LocalPlayer
local assets=RS:WaitForChild("XNNatureClientAssets")
local leafTemplate=assets:WaitForChild("LeafTemplate")
local butterflyTemplate=assets:WaitForChild("ButterflyTemplate")
local WindLines=require(script:WaitForChild("WindLines"))
local WindShake=require(script:WaitForChild("WindShake"))

local wind=Workspace.GlobalWind
local dir=wind.Magnitude>0 and wind.Unit or Vector3.new(1,0,.3)
WindLines:Init({Direction=dir,Speed=14,Lifetime=2,SpawnRate=9})
WindShake:SetDefaultSettings({WindSpeed=13,WindDirection=dir,WindPower=.24})
WindShake:Init()

local rng=Random.new()
local leavesFolder=Instance.new("Folder")
leavesFolder.Name="XNClientFallingLeaves"
leavesFolder.Parent=Workspace

local function rootPos()
	local c=player.Character
	local r=c and c:FindFirstChild("HumanoidRootPart")
	return r and r.Position or Vector3.zero
end

-- Real geometry leaves fall only FROM actual generated tree canopies nearby.
task.spawn(function()
	while true do
		local pos=rootPos()
		local candidates={}
		for _,p in ipairs(CS:GetTagged("XNLeafSource")) do
			if p:IsA("BasePart") and p:IsDescendantOf(Workspace) and (p.Position-pos).Magnitude<180 then
				table.insert(candidates,p)
			end
		end
		if #candidates>0 then
			local bursts=math.min(2,#candidates)
			for _=1,bursts do
				local src=candidates[rng:NextInteger(1,#candidates)]
				local leaf=leafTemplate:Clone()
				leaf.CFrame=CFrame.new(
					src.Position+Vector3.new(
						rng:NextNumber(-src.Size.X*.35,src.Size.X*.35),
						rng:NextNumber(-src.Size.Y*.15,src.Size.Y*.35),
						rng:NextNumber(-src.Size.Z*.35,src.Size.Z*.35)
					)
				)*CFrame.Angles(rng:NextNumber(0,6.28),rng:NextNumber(0,6.28),rng:NextNumber(0,6.28))
				leaf.AssemblyLinearVelocity=Vector3.new(wind.X*.14+rng:NextNumber(-1.5,1.5),-rng:NextNumber(1.8,3.2),wind.Z*.14+rng:NextNumber(-1.5,1.5))
				leaf.AssemblyAngularVelocity=Vector3.new(rng:NextNumber(-4,4),rng:NextNumber(-6,6),rng:NextNumber(-4,4))
				leaf.Parent=leavesFolder
				Debris:AddItem(leaf,7)
			end
		end
		task.wait(.7)
	end
end)

local butterflies={}
local butterflyFolder=Instance.new("Folder")
butterflyFolder.Name="XNClientButterflies"
butterflyFolder.Parent=Workspace

local function nearestFlower(position)
	local best,bestD=nil,160
	for _,p in ipairs(CS:GetTagged("XNFlowerSource")) do
		if p:IsA("BasePart") and p:IsDescendantOf(Workspace) then
			local d=(p.Position-position).Magnitude
			if d<bestD then best=p; bestD=d end
		end
	end
	return best and best.Position or position
end

local function spawnButterfly(i)
	local m=butterflyTemplate:Clone()
	m.Name="Butterfly"
	m.Parent=butterflyFolder
	local center=nearestFlower(rootPos())
	local phase=rng:NextNumber(0,6.28)
	local radius=rng:NextNumber(5,15)
	local height=rng:NextNumber(2.4,5.5)
	local wingData={}
	local pivot=m:GetPivot()
	for _,p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local n=p.Name:lower()
			if n:find("wing",1,true) then
				table.insert(wingData,{p=p,rel=pivot:ToObjectSpace(p.CFrame),side=(p.Position.X>=pivot.Position.X) and 1 or -1})
			end
		end
	end
	butterflies[i]={m=m,center=center,phase=phase,radius=radius,height=height,wings=wingData,nextCenter=0}
end

for i=1,7 do spawnButterfly(i) end

RunService.RenderStepped:Connect(function()
	local t=os.clock()
	local playerPos=rootPos()
	for i,b in ipairs(butterflies) do
		if not b.m.Parent then spawnButterfly(i); b=butterflies[i] end
		if t>b.nextCenter then
			b.center=nearestFlower(playerPos)
			b.nextCenter=t+rng:NextNumber(5,10)
		end
		local a=t*.55+b.phase
		local pos=b.center+Vector3.new(
			math.sin(a*1.15)*b.radius,
			b.height+math.sin(a*3.1)*.65,
			math.cos(a*.87)*b.radius*.75
		)
		local nextPos=b.center+Vector3.new(
			math.sin((a+.03)*1.15)*b.radius,
			b.height+math.sin((a+.03)*3.1)*.65,
			math.cos((a+.03)*.87)*b.radius*.75
		)
		local cf=CFrame.lookAt(pos,nextPos)
		b.m:PivotTo(cf)
		local flap=math.sin(t*18+b.phase)*.48
		local pv=b.m:GetPivot()
		for _,w in ipairs(b.wings) do
			if w.p.Parent then w.p.CFrame=pv*w.rel*CFrame.Angles(0,0,flap*w.side) end
		end
	end
end)
]=]
	client:SetAttribute("WindAssetId",WIND_ID)
	client:SetAttribute("ButterflyAssetId",BUTTERFLY_ID)
	client.Parent=SP.StarterPlayerScripts
	asset:Destroy()
end

-- Saved central terrain guarantees the player never spawns in void.
Terrain:FillBlock(CFrame.new(0,-6,0),Vector3.new(1536,12,1536),Enum.Material.Grass)
local spawn=Instance.new("SpawnLocation")
spawn.Name="XNSpawn"
spawn.Size=Vector3.new(8,.5,8)
spawn.CFrame=CFrame.new(0,3,0)
spawn.Transparency=1
spawn.Anchored=true
spawn.CanCollide=false
spawn.CanTouch=false
spawn.Neutral=true
spawn.Enabled=true
spawn.Duration=0
spawn.Parent=workspace

-- Chunk generator. The map is deterministic up to the engine's terrain boundary.
local generator=Instance.new("Script")
generator.Name="XNWorldGenerator"
generator.Source=[=[
local Players=game:GetService("Players")
local Terrain=workspace.Terrain
local SS=game:GetService("ServerStorage")
local CS=game:GetService("CollectionService")

local templates=SS:WaitForChild("XNNatureTemplates")
local CHUNK=512
local WORLD_HALF=124000
local LAND_HALF=112000
local WATER_DEPTH=6
local ACTIVE_RADIUS=2
local generated={}
local propsRoot=Instance.new("Folder")
propsRoot.Name="XNWorldProps"
propsRoot.Parent=workspace

local islands={
	Vector2.new(104500,93000),Vector2.new(-101000,96500),
	Vector2.new(97000,-104000),Vector2.new(-103500,-91000),
	Vector2.new(108000,42000),Vector2.new(-107000,-38000)
}

local function key(ix,iz) return tostring(ix)..":"..tostring(iz) end
local function seed(ix,iz,salt)
	local n=(ix*73856093+iz*19349663+salt*83492791)%2147483000
	if n<0 then n=-n end
	return math.max(1,n)
end
local function rnd(ix,iz,salt) return Random.new(seed(ix,iz,salt)) end

local function placeBottom(obj,pos,yaw,scale)
	if obj:IsA("BasePart") then
		if scale then obj.Size*=scale end
		obj.CFrame=CFrame.new(pos+Vector3.new(0,obj.Size.Y*.5,0))*CFrame.Angles(0,yaw,0)
	else
		if scale then pcall(function() obj:ScaleTo(obj:GetScale()*scale) end) end
		obj:PivotTo(CFrame.new(pos)*CFrame.Angles(0,yaw,0))
		local cf,size=obj:GetBoundingBox()
		obj:PivotTo(obj:GetPivot()+Vector3.new(0,pos.Y-(cf.Position.Y-size.Y/2),0))
	end
end

local function groundAt(x,z)
	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances={Terrain}
	rp.IgnoreWater=false
	local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-360,0),rp)
	if hit and hit.Material~=Enum.Material.Water then return hit.Position,hit.Material end
end

local function carveSegment(p1,p2,width)
	local mid=(p1+p2)/2
	local len=(p2-p1).Magnitude+8
	local cf=CFrame.lookAt(Vector3.new(mid.X,-2.5,mid.Z),Vector3.new(p2.X,-2.5,p2.Z))
	Terrain:FillBlock(cf,Vector3.new(width,7,len),Enum.Material.Air)
	local waterCf=CFrame.lookAt(Vector3.new(mid.X,-3,mid.Z),Vector3.new(p2.X,-3,p2.Z))
	Terrain:FillBlock(waterCf,Vector3.new(math.max(12,width-4),WATER_DEPTH,len),Enum.Material.Water)
end

local function horizontalRiverZ(x,index)
	if index==1 then return 18500+2600*math.sin(x/8500)+650*math.sin(x/2600) end
	if index==2 then return -23500+3100*math.sin(x/11000+1.4)+500*math.sin(x/3300) end
	return 46500+2200*math.sin(x/9600+2.1)
end
local function verticalRiverX(z,index)
	if index==1 then return 33500+2300*math.sin(z/9200+.8) end
	return -42500+2700*math.sin(z/10500+2.4)
end

local function generateRivers(ix,iz,cx,cz)
	local left,right=cx-CHUNK/2,cx+CHUNK/2
	local back,front=cz-CHUNK/2,cz+CHUNK/2
	for ri=1,3 do
		local prev=nil
		for x=left-64,right+64,64 do
			local z=horizontalRiverZ(x,ri)
			local p=Vector3.new(x,0,z)
			if prev and (z>back-120 and z<front+120 or prev.Z>back-120 and prev.Z<front+120) then
				carveSegment(prev,p,ri==2 and 125 or 92)
			end
			prev=p
		end
	end
	for ri=1,2 do
		local prev=nil
		for z=back-64,front+64,64 do
			local x=verticalRiverX(z,ri)
			local p=Vector3.new(x,0,z)
			if prev and (x>left-120 and x<right+120 or prev.X>left-120 and prev.X<right+120) then
				carveSegment(prev,p,ri==1 and 105 or 86)
			end
			prev=p
		end
	end

	-- Amazon-like shallow branch zones, localized instead of covering the whole map.
	local wetZones={Vector2.new(-28000,26000),Vector2.new(41000,-30000),Vector2.new(8000,61000)}
	for zi,zone in ipairs(wetZones) do
		if (Vector2.new(cx,cz)-zone).Magnitude<7200 then
			for b=1,3 do
				local prev=nil
				for x=left-64,right+64,64 do
					local localX=x-zone.X
					local z=zone.Y+(b-2)*950+700*math.sin(localX/(1350+b*420)+b*1.3)
					local p=Vector3.new(x,0,z)
					if prev and (z>back-75 and z<front+75 or prev.Z>back-75 and prev.Z<front+75) then
						carveSegment(prev,p,42+b*7)
					end
					prev=p
				end
			end
		end
	end
end

local function generateLake(ix,iz,cx,cz)
	if Vector2.new(cx,cz).Magnitude<1800 then return end
	local r=rnd(ix,iz,71)
	if r:NextNumber()>.038 then return end
	local center=Vector2.new(cx+r:NextNumber(-CHUNK*.28,CHUNK*.28),cz+r:NextNumber(-CHUNK*.28,CHUNK*.28))
	local rx=r:NextNumber(65,155)
	local rz=r:NextNumber(48,115)
	local angle=r:NextNumber(0,math.pi)
	local strips=13
	for s=-6,6 do
		local t=s/6
		local half=rx*math.sqrt(math.max(0,1-t*t))
		local localOffset=Vector3.new(0,0,t*rz)
		local rot=CFrame.Angles(0,angle,0)
		local worldOffset=rot:VectorToWorldSpace(localOffset)
		local stripDepth=(rz*2/strips)+10
		local cf=CFrame.new(center.X+worldOffset.X,-2.6,center.Y+worldOffset.Z)*CFrame.Angles(0,angle,0)
		Terrain:FillBlock(cf,Vector3.new(math.max(16,half*2),7,stripDepth),Enum.Material.Air)
		Terrain:FillBlock(CFrame.new(cf.Position.X,-3,cf.Position.Z)*CFrame.Angles(0,angle,0),Vector3.new(math.max(12,half*2-4),WATER_DEPTH,stripDepth),Enum.Material.Water)
	end
end

local function trailZ(x,index)
	if index==1 then return 2400+480*math.sin(x/3200) end
	return -7200+420*math.sin(x/2800+1.7)
end
local function generateTrails(cx,cz)
	if math.abs(cx)>34000 then return end
	local left,right=cx-CHUNK/2,cx+CHUNK/2
	local back,front=cz-CHUNK/2,cz+CHUNK/2
	for pi=1,2 do
		local prev=nil
		for x=left-48,right+48,48 do
			local z=trailZ(x,pi)
			local p=Vector3.new(x,0,z)
			if prev and (z>back-30 and z<front+30 or prev.Z>back-30 and prev.Z<front+30) then
				local mid=(prev+p)/2
				local len=(p-prev).Magnitude+5
				local cf=CFrame.lookAt(Vector3.new(mid.X,.15,mid.Z),Vector3.new(p.X,.15,p.Z))
				Terrain:FillBlock(cf,Vector3.new(8,1.2,len),Enum.Material.Ground)
			end
			prev=p
		end
	end
end

local function islandInfluence(cx,cz)
	for _,p in ipairs(islands) do
		if (Vector2.new(cx,cz)-p).Magnitude<700 then return p end
	end
end

local function generateIsland(center,ix,iz,folder)
	local r=rnd(ix,iz,881)
	local rx=r:NextNumber(190,340)
	local rz=r:NextNumber(150,290)
	local angle=r:NextNumber(0,math.pi)
	for s=-7,7 do
		local t=s/7
		local half=rx*math.sqrt(math.max(0,1-t*t))
		local localOffset=Vector3.new(0,0,t*rz)
		local rot=CFrame.Angles(0,angle,0)
		local off=rot:VectorToWorldSpace(localOffset)
		local depth=rz*2/15+14
		Terrain:FillBlock(CFrame.new(center.X+off.X,-1.5,center.Y+off.Z)*CFrame.Angles(0,angle,0),Vector3.new(math.max(20,half*2),5,depth),Enum.Material.Grass)
	end
end

local function choose(folder,r)
	local arr=folder:GetChildren()
	return #arr>0 and arr[r:NextInteger(1,#arr)] or nil
end

local function tagTree(root)
	for _,p in ipairs(root:GetDescendants()) do
		if p:IsA("BasePart") then
			local n=p.Name:lower()
			local pn=(p.Parent and p.Parent.Name or ""):lower()
			local gpn=(p.Parent and p.Parent.Parent and p.Parent.Parent.Name or ""):lower()
			local c=p.Color
			local leaf=n:find("leaf",1,true) or n:find("leaves",1,true) or n:find("foliage",1,true)
				or pn:find("leaf",1,true) or pn:find("leaves",1,true) or pn:find("foliage",1,true)
				or gpn:find("leaf",1,true) or gpn:find("leaves",1,true) or gpn:find("foliage",1,true)
				or ((c.G>c.R*1.12 and c.G>c.B*1.06) and not n:find("trunk",1,true))
			if leaf then
				CS:AddTag(p,"WindShake")
				CS:AddTag(p,"XNLeafSource")
				p:SetAttribute("WindPower",.22)
				p:SetAttribute("WindSpeed",13)
				p.CanCollide=false
			end
		end
	end
end

local function spawnProp(template,folder,pos,r,scale,kind)
	if not template then return end
	local obj=template:Clone()
	obj.Name=kind
	obj.Parent=folder
	placeBottom(obj,pos,r:NextNumber(0,math.pi*2),scale)
	if kind=="Tree" or kind=="BigTree" then
		tagTree(obj)
	elseif kind=="Flower" then
		local bp=obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart",true)
		if bp then CS:AddTag(bp,"XNFlowerSource") end
	end
	return obj
end

local function populateLand(ix,iz,cx,cz,folder,isIsland)
	local r=rnd(ix,iz,301)
	local noise=math.noise(ix*.19,iz*.19,17)
	local treeCount=isIsland and r:NextInteger(8,15) or math.clamp(math.floor(7+noise*5+r:NextInteger(-2,3)),3,13)
	local plantCount=r:NextInteger(3,8)
	local rockCount=r:NextInteger(1,4)
	local flowerGroups=(r:NextNumber()<.68) and r:NextInteger(1,3) or 0

	for i=1,treeCount do
		local x=cx+r:NextNumber(-CHUNK*.43,CHUNK*.43)
		local z=cz+r:NextNumber(-CHUNK*.43,CHUNK*.43)
		if Vector2.new(x,z).Magnitude>500 then
			local g=groundAt(x,z)
			if g then spawnProp(choose(templates.Trees,r),folder,g,r,r:NextNumber(.72,1.2),"Tree") end
		end
	end
	for i=1,plantCount do
		local x=cx+r:NextNumber(-CHUNK*.46,CHUNK*.46); local z=cz+r:NextNumber(-CHUNK*.46,CHUNK*.46)
		local g=groundAt(x,z); if g then spawnProp(choose(templates.Plants,r),folder,g,r,r:NextNumber(.65,1.15),"Plant") end
	end
	for i=1,rockCount do
		local x=cx+r:NextNumber(-CHUNK*.46,CHUNK*.46); local z=cz+r:NextNumber(-CHUNK*.46,CHUNK*.46)
		local g=groundAt(x,z); if g then spawnProp(choose(templates.Rocks,r),folder,g,r,r:NextNumber(.65,1.35),"Rock") end
	end
	for group=1,flowerGroups do
		local gx=cx+r:NextNumber(-CHUNK*.38,CHUNK*.38); local gz=cz+r:NextNumber(-CHUNK*.38,CHUNK*.38)
		for i=1,r:NextInteger(3,8) do
			local x=gx+r:NextNumber(-7,7); local z=gz+r:NextNumber(-7,7)
			local g=groundAt(x,z); if g then spawnProp(choose(templates.Flowers,r),folder,g,r,r:NextNumber(.7,1.12),"Flower") end
		end
	end
	if r:NextNumber()<.065 then
		local x=cx+r:NextNumber(-CHUNK*.28,CHUNK*.28); local z=cz+r:NextNumber(-CHUNK*.28,CHUNK*.28)
		local g=groundAt(x,z); if g then spawnProp(choose(templates.BigTrees,r),folder,g,r,r:NextNumber(.88,1.08),"BigTree") end
	end
end

local function generateChunk(ix,iz)
	if math.abs(ix*CHUNK)>WORLD_HALF-CHUNK or math.abs(iz*CHUNK)>WORLD_HALF-CHUNK then return end
	local k=key(ix,iz)
	if generated[k] then return end
	generated[k]=true
	local cx,cz=ix*CHUNK,iz*CHUNK
	local folder=Instance.new("Folder")
	folder.Name="Chunk_"..ix.."_"..iz
	folder:SetAttribute("ChunkX",ix); folder:SetAttribute("ChunkZ",iz)
	folder.Parent=propsRoot

	local edge=math.max(math.abs(cx),math.abs(cz))
	local coastNoise=math.noise(cx/7200,cz/7200,33)*950 + math.noise(cx/2600,cz/2600,91)*260
	local localLandEdge=LAND_HALF+coastNoise
	if edge>=localLandEdge then
		Terrain:FillBlock(CFrame.new(cx,-10,cz),Vector3.new(CHUNK,8,CHUNK),Enum.Material.Sand)
		Terrain:FillBlock(CFrame.new(cx,-3,cz),Vector3.new(CHUNK,6,CHUNK),Enum.Material.Water)
		local island=islandInfluence(cx,cz)
		if island then
			generateIsland(island,ix,iz,folder)
			populateLand(ix,iz,cx,cz,folder,true)
		end
		return
	end

	Terrain:FillBlock(CFrame.new(cx,-6,cz),Vector3.new(CHUNK,12,CHUNK),Enum.Material.Grass)
	if edge>localLandEdge-650 then
		Terrain:FillBlock(CFrame.new(cx,-.7,cz),Vector3.new(CHUNK,1.4,CHUNK),Enum.Material.Sand)
	end
	local r=rnd(ix,iz,91)
	for i=1,r:NextInteger(1,3) do
		local x=cx+r:NextNumber(-CHUNK*.38,CHUNK*.38)
		local z=cz+r:NextNumber(-CHUNK*.38,CHUNK*.38)
		local radius=r:NextNumber(24,38)
		Terrain:FillBall(Vector3.new(x,-radius+r:NextNumber(1.5,5),z),radius,Enum.Material.Grass)
	end

	if Vector2.new(cx,cz).Magnitude>1200 then
		generateRivers(ix,iz,cx,cz)
		generateLake(ix,iz,cx,cz)
	else
		-- central spawn meadow stays dry and nearly flat
	end
	generateTrails(cx,cz)
	populateLand(ix,iz,cx,cz,folder,false)
end

-- Preload a small center before the first character appears.
for ix=-1,1 do for iz=-1,1 do generateChunk(ix,iz) end end

local function ensureAround(pos)
	local ix=math.floor(pos.X/CHUNK+.5)
	local iz=math.floor(pos.Z/CHUNK+.5)
	for dx=-ACTIVE_RADIUS,ACTIVE_RADIUS do
		for dz=-ACTIVE_RADIUS,ACTIVE_RADIUS do
			generateChunk(ix+dx,iz+dz)
		end
	end
end

local function watchPlayer(p)
	p.CharacterAdded:Connect(function(c)
		local root=c:WaitForChild("HumanoidRootPart")
		while c.Parent and p.Parent do
			if math.max(math.abs(root.Position.X),math.abs(root.Position.Z))>WORLD_HALF-700 then
				c:PivotTo(CFrame.new(0,5,0))
			else
				ensureAround(root.Position)
			end
			task.wait(1.2)
		end
	end)
	if p.Character then task.spawn(function()
		local root=p.Character:FindFirstChild("HumanoidRootPart")
		if root then ensureAround(root.Position) end
	end) end
end
Players.PlayerAdded:Connect(watchPlayer)
for _,p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
]=]
generator.Parent=SSS

local safety=Instance.new("Script")
safety.Name="XNSpawnSafety"
safety.Source=[=[
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("XNSpawn")
local function hook(p)
	p.RespawnLocation=spawn
	p.CharacterAdded:Connect(function(c)
		task.spawn(function()
			while c.Parent do
				local r=c:FindFirstChild("HumanoidRootPart")
				if r and r.Position.Y<-120 then c:PivotTo(spawn.CFrame*CFrame.new(0,4,0)) end
				task.wait(.6)
			end
		end)
	end)
end
Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
]=]
safety.Parent=SSS

return {
	version=VERSION,
	worldSize=WORLD_SIZE,
	landHalf=LAND_HALF,
	chunk=CHUNK,
	waterDepth=SHALLOW_WATER_DEPTH,
	trees=#treeFolder:GetChildren(),
	plants=#plantFolder:GetChildren(),
	flowers=#flowerFolder:GetChildren(),
	rocks=#rockFolder:GetChildren(),
	bigTrees=#bigFolder:GetChildren(),
	butterflyAsset=BUTTERFLY_ID
}
