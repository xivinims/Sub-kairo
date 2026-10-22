-- Swean Island v99 — Pristine Park island + Sakura + Halloween
assert(game.GameId == 9419478735 and game.PlaceId == 79738710219521, "Place errado")

local AssetService=game:GetService("AssetService")
local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain
local CollectionService=game:GetService("CollectionService")
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")

local PARK_ID=13366955960
local TREE_ID=9626366517
local GRASS_ID=87377915371959
local WIND_ID=11946229834
local HALLOWEEN_ID=12489961338
local NAMETAG_ID=123212555736117
local LOADING_ID=73186563008540
local SKY_ID=137401994501544

local function loadAsset(id)
	local ok,res=pcall(AssetService.LoadAssetAsync,AssetService,id)
	if not ok or not res then error("Asset "..id.." failed: "..tostring(res)) end
	return res
end

local function clearOld()
	for _,child in ipairs(workspace:GetChildren()) do
		if child~=Terrain and not child:IsA("Camera") then child:Destroy() end
	end
	Terrain:Clear()

	for _,name in ipairs({"SakuraServer","NametagService"}) do
		local x=game.ServerScriptService:FindFirstChild(name)
		if x then x:Destroy() end
	end
	for _,name in ipairs({"WindController","TerrainGrassBend"}) do
		local x=game.StarterPlayer.StarterPlayerScripts:FindFirstChild(name)
		if x then x:Destroy() end
	end
	local oldLoading=ReplicatedFirst:FindFirstChild("LoadingScreen")
	if oldLoading then oldLoading:Destroy() end
	local oldRuntime=game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
	if oldRuntime then oldRuntime:Destroy() end
end

clearOld()

local runtime=Instance.new("Folder")
runtime.Name="SakuraRuntime"
runtime.Parent=game.ReplicatedStorage
runtime:SetAttribute("Version",99)
runtime:SetAttribute("MapType","PristineParkIslandHalloween")
runtime:SetAttribute("ParkAssetId",PARK_ID)
runtime:SetAttribute("HalloweenAssetId",HALLOWEEN_ID)

pcall(function()
	workspace.StreamingEnabled=true
	workspace.StreamingMinRadius=96
	workspace.StreamingTargetRadius=280
end)

local function sanitizeVisual(root,removeScripts)
	for _,d in ipairs(root:GetDescendants()) do
		if removeScripts and d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("Camera") or d:IsA("SpawnLocation") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored=true
			d.CanTouch=false
		end
	end
end

local function visualPartCount(inst)
	local n=0
	if inst:IsA("BasePart") then n+=1 end
	for _,d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end
	return n
end

local function validBounds(model)
	local ok,cf,size=pcall(function() return model:GetBoundingBox() end)
	if not ok or not size or size.X<=0 or size.Y<=0 or size.Z<=0 then return nil end
	return cf,size
end

local function asModel(inst)
	if inst:IsA("Model") then return inst end
	local m=Instance.new("Model")
	inst.Parent=m
	return m
end

local function findVisualModel(asset,words)
	local best,bestScore=nil,-1
	for _,d in ipairs(asset:GetDescendants()) do
		if d:IsA("Model") and d:FindFirstChildWhichIsA("BasePart",true) then
			local _,size=validBounds(d)
			if size then
				local score=visualPartCount(d)
				local name=d.Name:lower()
				for _,word in ipairs(words or {}) do
					if name:find(word,1,true) then score+=10000 end
				end
				if score>bestScore then best,bestScore=d,score end
			end
		end
	end
	return best
end

local function scaleModelToHeight(model,targetHeight)
	local _,size=validBounds(model)
	if not size then return false end
	return pcall(function()
		model:ScaleTo(model:GetScale()*(targetHeight/size.Y))
	end)
end

local function scaleModelToFootprint(model,target)
	local _,size=validBounds(model)
	if not size then return false end
	local current=math.max(size.X,size.Z)
	if current<=0 then return false end
	return pcall(function()
		model:ScaleTo(model:GetScale()*(target/current))
	end)
end

local function placeModelBottom(model,pos,yaw,sink)
	model:PivotTo(CFrame.new(pos.X,0,pos.Z)*CFrame.Angles(0,yaw or 0,0))
	local cf,size=validBounds(model)
	if not size then return false end
	local bottom=cf.Position.Y-size.Y/2
	model:PivotTo(model:GetPivot()+Vector3.new(0,pos.Y-bottom-(sink or 0),0))
	return true
end

local function rayDown(x,z,exclude)
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances=exclude or {}
	return workspace:Raycast(Vector3.new(x,130,z),Vector3.new(0,-220,0),params)
end

-- ============ OCEANO + BASE DA ILHA ============
Terrain.WaterColor=Color3.fromRGB(69,112,124)
Terrain.WaterTransparency=.2
Terrain.WaterReflectance=.3
Terrain.WaterWaveSize=.11
Terrain.WaterWaveSpeed=7
pcall(function()
	Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(80,108,60))
	Terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(173,158,118))
end)

Terrain:FillBlock(CFrame.new(0,-18,0),Vector3.new(1900,10,1900),Enum.Material.Sand)
Terrain:FillBlock(CFrame.new(0,-7,0),Vector3.new(1800,12,1800),Enum.Material.Water)

for x=-245,245,14 do
	for z=-180,180,14 do
		local e=(x/245)^2+(z/180)^2
		if e<1 then
			local edge=math.clamp((e-.72)/.28,0,1)
			local top=7-edge*4
			local mat=e>.83 and Enum.Material.Sand or Enum.Material.Grass
			Terrain:FillBall(Vector3.new(x,top-12,z),16,mat)
		end
	end
end

local safety=Instance.new("Part")
safety.Name="WorldSafetyFloor"
safety.Size=Vector3.new(1900,2,1900)
safety.CFrame=CFrame.new(0,-48,0)
safety.Anchored=true
safety.CanCollide=true
safety.CanTouch=false
safety.Transparency=1
safety.Parent=workspace
workspace.FallenPartsDestroyHeight=-220

-- ============ PRISTINE PARK REAL ============
local parkAsset=loadAsset(PARK_ID)
local parkSource=parkAsset:FindFirstChild("Park",true) or findVisualModel(parkAsset,{"park"})
assert(parkSource and parkSource:IsA("Model"),"Pristine Park model not found")
local park=parkSource:Clone()
park.Name="PristineParkIsland"
park:SetAttribute("AssetId",PARK_ID)
park.Parent=workspace
sanitizeVisual(park,true)
park:PivotTo(CFrame.new(0,0,0))
local pcf,psize=park:GetBoundingBox()
local pbottom=pcf.Position.Y-psize.Y/2
park:PivotTo(park:GetPivot()+Vector3.new(0,7.1-pbottom,0))
parkAsset:Destroy()

-- Grama/cores do próprio parque e pedras Brown Stone em cinza.
local grayStone=Color3.fromRGB(118,121,128)
local brownStoneCount=0
local parkGrassParts=0
for _,d in ipairs(park:GetDescendants()) do
	if d:IsA("BasePart") then
		local lower=d.Name:lower()
		if lower=="brown stone" then
			d.Color=grayStone
			brownStoneCount+=1
		end
		if d.Material==Enum.Material.Grass or lower:find("grass",1,true) then
			d.Material=Enum.Material.Grass
			d.Color=Color3.fromRGB(78,105,58)
			parkGrassParts+=1
		end
	end
end
runtime:SetAttribute("GrayStoneCount",brownStoneCount)

-- ============ REMOVE AS ÁRVORES ORIGINAIS ============
local function greenish(c)
	return c.G>c.R*.9 and c.G>c.B*.75 and c.G>.22
end

local function treeLikeModel(m)
	local name=m.Name:lower()
	if name:find("streetlight",1,true) or name:find("light",1,true) then return false end
	if name:find("tree",1,true) then return true end
	local wood,foliage=false,false
	for _,d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			local n=d.Name:lower()
			if d.Material==Enum.Material.Wood or d.Material==Enum.Material.WoodPlanks or n:find("trunk",1,true) then wood=true end
			if n:find("leaf",1,true) or n:find("foliage",1,true) or (greenish(d.Color) and (d.Material==Enum.Material.Grass or d.Material==Enum.Material.Fabric or d:IsA("MeshPart"))) then foliage=true end
		end
	end
	if wood and foliage then
		local _,size=validBounds(m)
		return size and size.Y>10 and size.X<80 and size.Z<80
	end
	return false
end

local candidates={}
for _,d in ipairs(park:GetDescendants()) do
	if d:IsA("Model") and treeLikeModel(d) then table.insert(candidates,d) end
end
local set={}
for _,m in ipairs(candidates) do set[m]=true end
local treePositions={}
for _,m in ipairs(candidates) do
	local ancestor=m.Parent
	local nested=false
	while ancestor and ancestor~=park do
		if set[ancestor] then nested=true break end
		ancestor=ancestor.Parent
	end
	if not nested and m.Parent then
		local cf=select(1,m:GetBoundingBox())
		table.insert(treePositions,cf.Position)
		m:Destroy()
	end
end
for _,d in ipairs(park:GetDescendants()) do
	if d:IsA("BasePart") then
		local n=d.Name:lower()
		if (n=="tree" or n:find("tree trunk",1,true)) and d.Parent then
			table.insert(treePositions,d.Position)
			d:Destroy()
		end
	end
end
runtime:SetAttribute("OriginalTreesRemoved",#treePositions)

-- ============ SKY + TARDE ============
for _,d in ipairs(Lighting:GetChildren()) do d:Destroy() end
local skyAsset=loadAsset(SKY_ID)
local sky=skyAsset:FindFirstChildWhichIsA("Sky",true)
if sky then sky:Clone().Parent=Lighting end
skyAsset:Destroy()
Lighting.ClockTime=16.35
Lighting.Brightness=2.45
Lighting.ExposureCompensation=.06
Lighting.Ambient=Color3.fromRGB(137,135,130)
Lighting.OutdoorAmbient=Color3.fromRGB(172,166,153)
Lighting.GlobalShadows=true
Lighting.EnvironmentDiffuseScale=.6
Lighting.EnvironmentSpecularScale=.55
local atmosphere=Instance.new("Atmosphere")
atmosphere.Density=.19
atmosphere.Offset=.06
atmosphere.Color=Color3.fromRGB(222,211,196)
atmosphere.Decay=Color3.fromRGB(147,137,132)
atmosphere.Haze=.7
atmosphere.Glare=.05
atmosphere.Parent=Lighting
local cc=Instance.new("ColorCorrectionEffect")
cc.Brightness=.02
cc.Contrast=.025
cc.Saturation=.04
cc.TintColor=Color3.fromRGB(255,239,222)
cc.Parent=Lighting

-- ============ VENTO REAL ============
workspace.GlobalWind=Vector3.new(14,0,5)
local windAsset=loadAsset(WIND_ID)
local windSource=windAsset:FindFirstChild("WindController",true)
assert(windSource and windSource:IsA("LocalScript"),"WindController missing")
local sourceLines=windSource:FindFirstChild("WindLines")
local sourceShake=windSource:FindFirstChild("WindShake")
assert(sourceLines and sourceShake,"Wind modules missing")
local windController=Instance.new("LocalScript")
windController.Name="WindController"
windController:SetAttribute("AssetId",WIND_ID)
windController.Source=[==========[
local WindLines=require(script:WaitForChild("WindLines"))
local WindShake=require(script:WaitForChild("WindShake"))
local direction=Vector3.new(1,0,.32).Unit
local speed=16
WindLines:Init({Direction=direction;Speed=speed;Lifetime=1.9;SpawnRate=17;})
WindShake:SetDefaultSettings({WindSpeed=speed;WindDirection=direction;WindPower=.42;})
WindShake:Init()
]==========]
local wl=Instance.new("ModuleScript")
wl.Name="WindLines"
wl.Source=sourceLines.Source
wl.Parent=windController
local ws=Instance.new("ModuleScript")
ws.Name="WindShake"
ws.Source=sourceShake.Source
ws.Parent=windController
windController.Parent=game.StarterPlayer.StarterPlayerScripts
windAsset:Destroy()

-- ============ CEREJEIRAS NO LUGAR DAS ÁRVORES ============
local treeAsset=loadAsset(TREE_ID)
local treeTemplate=findVisualModel(treeAsset,{"sakura","cherry","tree"})
assert(treeTemplate,"Sakura template missing")
treeTemplate=treeTemplate:Clone()
sanitizeVisual(treeTemplate,true)
treeAsset:Destroy()

local sakuraFolder=Instance.new("Folder")
sakuraFolder.Name="SakuraTrees"
sakuraFolder.Parent=workspace

local rng=Random.new(99001)
local filtered={}
for _,pos in ipairs(treePositions) do
	local good=true
	for _,q in ipairs(filtered) do
		if (Vector2.new(pos.X,pos.Z)-Vector2.new(q.X,q.Z)).Magnitude<18 then good=false break end
	end
	if good then table.insert(filtered,pos) end
	if #filtered>=28 then break end
end

local function grassPoint()
	for _=1,350 do
		local x=rng:NextNumber(-185,185)
		local z=rng:NextNumber(-125,125)
		local hit=rayDown(x,z,{sakuraFolder,safety})
		if hit and hit.Material~=Enum.Material.Water then
			local inst=hit.Instance
			if hit.Material==Enum.Material.Grass or (inst and inst:IsDescendantOf(park) and inst.Material==Enum.Material.Grass) then
				return hit.Position
			end
		end
	end
end

while #filtered<20 do
	local p=grassPoint()
	if not p then break end
	local good=true
	for _,q in ipairs(filtered) do
		if (Vector2.new(p.X,p.Z)-Vector2.new(q.X,q.Z)).Magnitude<22 then good=false break end
	end
	if good then table.insert(filtered,p) end
end

local function trunkBottom(tree)
	local trunk=nil
	for _,d in ipairs(tree:GetDescendants()) do
		if d:IsA("BasePart") and d.Name~="Leaves" then trunk=d break end
	end
	if not trunk then return nil end
	local minY=math.huge
	for _,sx in ipairs({-1,1}) do
		for _,sy in ipairs({-1,1}) do
			for _,sz in ipairs({-1,1}) do
				local p=trunk.CFrame:PointToWorldSpace(Vector3.new(trunk.Size.X*.5*sx,trunk.Size.Y*.5*sy,trunk.Size.Z*.5*sz))
				minY=math.min(minY,p.Y)
			end
		end
	end
	return minY
end

for i,pos in ipairs(filtered) do
	local hit=rayDown(pos.X,pos.Z,{sakuraFolder,safety})
	if hit and hit.Material~=Enum.Material.Water then
		local tree=treeTemplate:Clone()
		tree.Name=string.format("Sakura_%02d",i)
		tree.Parent=sakuraFolder
		scaleModelToHeight(tree,rng:NextNumber(19,23))
		tree:PivotTo(CFrame.new(hit.Position.X,0,hit.Position.Z)*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0))
		local bottom=trunkBottom(tree)
		if bottom then tree:PivotTo(tree:GetPivot()+Vector3.new(0,hit.Position.Y-bottom-.7,0)) end
		CollectionService:AddTag(tree,"SakuraTree")
		for _,leaf in ipairs(tree:GetDescendants()) do
			if leaf:IsA("BasePart") and leaf.Name=="Leaves" then
				CollectionService:AddTag(leaf,"WindShake")
				leaf:SetAttribute("WindPower",.32)
				leaf:SetAttribute("WindSpeed",16)
				local petals=Instance.new("ParticleEmitter")
				petals.Name="SakuraPetals"
				petals.Texture="rbxassetid://14302399641"
				petals.Color=ColorSequence.new(Color3.fromRGB(249,193,218),Color3.fromRGB(255,231,240))
				petals.Transparency=NumberSequence.new({
					NumberSequenceKeypoint.new(0,1),
					NumberSequenceKeypoint.new(.08,.15),
					NumberSequenceKeypoint.new(.8,.2),
					NumberSequenceKeypoint.new(1,1)
				})
				petals.Size=NumberSequence.new(.24)
				petals.Rate=.7
				petals.Lifetime=NumberRange.new(4,6.5)
				petals.Speed=NumberRange.new(.15,.65)
				petals.Acceleration=Vector3.new(0,-1.2,0)
				petals.Drag=1.25
				petals.WindAffectsDrag=true
				petals.Rotation=NumberRange.new(0,360)
				petals.RotSpeed=NumberRange.new(-45,45)
				petals.EmissionDirection=Enum.NormalId.Bottom
				petals.SpreadAngle=Vector2.new(55,55)
				petals.Parent=leaf
			end
		end
	end
end
treeTemplate:Destroy()
runtime:SetAttribute("SakuraCount",#sakuraFolder:GetChildren())

-- ============ GRAMA ESTÁTICA (NÃO SEGUE JOGADOR) ============
local grassFolder=Instance.new("Folder")
grassFolder.Name="ParkGrass"
grassFolder.Parent=workspace
local grassAsset=loadAsset(GRASS_ID)
sanitizeVisual(grassAsset,true)
local grassCandidates={}
for _,c in ipairs(grassAsset:GetChildren()) do
	if (c:IsA("Model") or c:IsA("BasePart")) and visualPartCount(c)>0 then table.insert(grassCandidates,c) end
end
if #grassCandidates==0 then
	local g=findVisualModel(grassAsset,{"grass","dark"})
	if g then table.insert(grassCandidates,g) end
end
local function lum(inst)
	local sum,n=0,0
	if inst:IsA("BasePart") then sum+=(inst.Color.R+inst.Color.G+inst.Color.B)/3 n+=1 end
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then sum+=(d.Color.R+d.Color.G+d.Color.B)/3 n+=1 end
	end
	return n>0 and sum/n or 2
end
table.sort(grassCandidates,function(a,b) return lum(a)<lum(b) end)
local grassTemplate=grassCandidates[1] and grassCandidates[1]:Clone() or nil
grassAsset:Destroy()

local grassPlaced=0
if grassTemplate then
	for _=1,1600 do
		if grassPlaced>=110 then break end
		local x=rng:NextNumber(-188,188)
		local z=rng:NextNumber(-128,128)
		local hit=rayDown(x,z,{grassFolder,sakuraFolder,safety})
		if hit and hit.Material~=Enum.Material.Water then
			local inst=hit.Instance
			local okay=hit.Material==Enum.Material.Grass or (inst and inst:IsDescendantOf(park) and inst.Material==Enum.Material.Grass)
			if okay then
				local clone=asModel(grassTemplate:Clone())
				clone.Name=string.format("Grass_%03d",grassPlaced+1)
				clone.Parent=grassFolder
				scaleModelToFootprint(clone,rng:NextNumber(5.5,8))
				placeModelBottom(clone,hit.Position,rng:NextNumber(0,math.pi*2),.04)
				grassPlaced+=1
			end
		end
	end
	grassTemplate:Destroy()
end
runtime:SetAttribute("StaticGrassCount",grassPlaced)

-- ============ HALLOWEEN: EERIE TOMB + ABÓBORAS ============
local halloween=Instance.new("Folder")
halloween.Name="HalloweenDecor"
halloween.Parent=workspace
halloween:SetAttribute("AssetId",HALLOWEEN_ID)

local eerieAsset=loadAsset(HALLOWEEN_ID)
local eerieOuter=eerieAsset:FindFirstChild("Eerie Tomb",true)
assert(eerieOuter and eerieOuter:IsA("Model"),"Eerie Tomb model missing")
local inner=eerieOuter:FindFirstChildWhichIsA("Model") or eerieOuter
local tombTemplate=inner:Clone()
sanitizeVisual(tombTemplate,true)
for _,d in ipairs(tombTemplate:GetDescendants()) do
	if d:IsA("BasePart") then
		local n=d.Name:lower()
		if n=="tree" or n=="hitbox" or d.Material==Enum.Material.Grass then d:Destroy() end
	end
end

local pumpkinTemplates={}
for _,d in ipairs(eerieAsset:GetDescendants()) do
	if d:IsA("BasePart") and d.Name=="Pumpkin" then table.insert(pumpkinTemplates,d:Clone()) end
end
assert(#pumpkinTemplates>=1,"Pumpkins missing from Eerie Tomb")

local function randomOpenGrass(minRadius)
	for _=1,500 do
		local x=rng:NextNumber(-180,180)
		local z=rng:NextNumber(-120,120)
		if Vector2.new(x,z).Magnitude>minRadius then
			local hit=rayDown(x,z,{halloween,sakuraFolder,grassFolder,safety})
			if hit and hit.Material~=Enum.Material.Water then
				local inst=hit.Instance
				if hit.Material==Enum.Material.Grass or (inst and inst:IsDescendantOf(park) and inst.Material==Enum.Material.Grass) then
					return hit.Position
				end
			end
		end
	end
end

local tombCount=0
for i=1,4 do
	local pos=randomOpenGrass(70)
	if pos then
		local tomb=tombTemplate:Clone()
		tomb.Name=string.format("EerieTomb_%02d",i)
		tomb.Parent=halloween
		pcall(function() tomb:ScaleTo(tomb:GetScale()*rng:NextNumber(.34,.43)) end)
		if placeModelBottom(tomb,pos,rng:NextNumber(0,math.pi*2),.15) then tombCount+=1 else tomb:Destroy() end
	end
end
tombTemplate:Destroy()

local pumpkinCount=0
for i=1,14 do
	local pos=randomOpenGrass(20)
	if pos then
		local p=pumpkinTemplates[((i-1)%#pumpkinTemplates)+1]:Clone()
		p.Name=string.format("Pumpkin_%02d",i)
		p.Anchored=true
		p.CanCollide=false
		p.CanTouch=false
		local sc=rng:NextNumber(.42,.68)
		p.Size=p.Size*sc
		p.CFrame=CFrame.new(pos+Vector3.new(0,p.Size.Y*.45,0))*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0)
		p.Parent=halloween
		pumpkinCount+=1
	end
end
for _,p in ipairs(pumpkinTemplates) do p:Destroy() end
eerieAsset:Destroy()

-- ============ CABEÇAS DE ESQUELETO ESTILIZADAS ============
local skullCount=0
local function createSkull(pos,yaw,index)
	local m=Instance.new("Model")
	m.Name=string.format("SkullHead_%02d",index)
	m.Parent=halloween

	local head=Instance.new("Part")
	head.Name="Skull"
	head.Shape=Enum.PartType.Ball
	head.Size=Vector3.new(1.35,1.15,1.15)
	head.Color=Color3.fromRGB(220,216,198)
	head.Material=Enum.Material.SmoothPlastic
	head.Anchored=true
	head.CanCollide=false
	head.CanTouch=false
	head.CFrame=CFrame.new(pos+Vector3.new(0,.48,0))*CFrame.Angles(0,yaw,0)
	head.Parent=m

	for _,sx in ipairs({-.27,.27}) do
		local eye=Instance.new("Part")
		eye.Name="EyeSocket"
		eye.Shape=Enum.PartType.Ball
		eye.Size=Vector3.new(.25,.25,.18)
		eye.Color=Color3.fromRGB(45,43,42)
		eye.Material=Enum.Material.SmoothPlastic
		eye.Anchored=true
		eye.CanCollide=false
		eye.CanTouch=false
		eye.CFrame=head.CFrame*CFrame.new(sx,.1,-.52)
		eye.Parent=m
	end

	local jaw=Instance.new("Part")
	jaw.Name="Jaw"
	jaw.Size=Vector3.new(.72,.28,.52)
	jaw.Color=head.Color
	jaw.Material=head.Material
	jaw.Anchored=true
	jaw.CanCollide=false
	jaw.CanTouch=false
	jaw.CFrame=head.CFrame*CFrame.new(0,-.48,-.05)
	jaw.Parent=m
end

for i=1,10 do
	local pos=randomOpenGrass(35)
	if pos then
		createSkull(pos,rng:NextNumber(0,math.pi*2),i)
		skullCount+=1
	end
end

halloween:SetAttribute("TombCount",tombCount)
halloween:SetAttribute("PumpkinCount",pumpkinCount)
halloween:SetAttribute("SkullCount",skullCount)

-- ============ SPAWN ============
local spawnPos=grassPoint()
if not spawnPos then spawnPos=Vector3.new(0,10,0) end
local spawn=Instance.new("SpawnLocation")
spawn.Name="IslandSpawn"
spawn.Size=Vector3.new(7,.4,7)
spawn.Anchored=true
spawn.CanCollide=false
spawn.CanTouch=false
spawn.Transparency=1
spawn.Neutral=true
spawn.Enabled=true
spawn.Duration=0
spawn.CFrame=CFrame.new(spawnPos+Vector3.new(0,.2,0))
spawn.Parent=workspace

-- ============ NAMETAG ============
local nametagAsset=loadAsset(NAMETAG_ID)
local nametagSource=nametagAsset:FindFirstChild("NametagService",true)
assert(nametagSource and nametagSource:IsA("Script"),"NametagService missing")
local nametag=nametagSource:Clone()
nametag.Name="NametagService"
nametag:SetAttribute("AssetId",NAMETAG_ID)
local nsrc=nametag.Source
nsrc=nsrc:gsub(
	'local head = character:WaitForChild%("Head"%)',
	'local head = character:WaitForChild("Head")\n\tlocal humanoid=character:FindFirstChildWhichIsA("Humanoid")\n\tif humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None humanoid.HealthDisplayDistance=0 end\n\tlocal old=head:FindFirstChild("Nametag") if old then old:Destroy() end',
	1
)
nametag.Source=nsrc
nametag.Parent=game.ServerScriptService
nametagAsset:Destroy()

-- ============ LOADING SCREEN ============
local loadingAsset=loadAsset(LOADING_ID)
local loadingSource=loadingAsset:FindFirstChild("LoadingScreen",true)
assert(loadingSource and loadingSource:IsA("LocalScript"),"LoadingScreen missing")
local loading=loadingSource:Clone()
loading.Name="LoadingScreen"
loading:SetAttribute("AssetId",LOADING_ID)
loading:SetAttribute("GameName","Swean Island")
loading:SetAttribute("FontName","BuilderSansBold")
local lsrc=loading.Source
lsrc=lsrc:gsub('GAME_NAME = ""','GAME_NAME = "Swean Island"',1)
lsrc=lsrc:gsub('Enum.Font.FredokaOne','Enum.Font.BuilderSansBold')
loading.Source=lsrc
loading.Parent=ReplicatedFirst
loadingAsset:Destroy()

-- ============ SERVER + ANTI VOID ============
local server=Instance.new("Script")
server.Name="SakuraServer"
server.Source=[[
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("IslandSpawn")
local function protect(character)
	task.spawn(function()
		while character.Parent do
			local root=character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y<-42 then
				character:PivotTo(spawn.CFrame*CFrame.new(0,4,0))
			end
			task.wait(.4)
		end
	end)
end
local function hook(player)
	player.RespawnLocation=spawn
	player.CharacterAdded:Connect(protect)
	if player.Character then protect(player.Character) end
end
Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
print("[Swean Island] Pristine Park island loaded")
]]
server.Parent=game.ServerScriptService

runtime:SetAttribute("TombCount",tombCount)
runtime:SetAttribute("PumpkinCount",pumpkinCount)
runtime:SetAttribute("SkullCount",skullCount)
runtime:SetAttribute("GrassPatchCount",grassPlaced)

print("[Swean Island] Pristine Park island complete")
return{
	version=99,
	trees=#sakuraFolder:GetChildren(),
	grayStones=brownStoneCount,
	grass=grassPlaced,
	tombs=tombCount,
	pumpkins=pumpkinCount,
	skulls=skullCount
}
