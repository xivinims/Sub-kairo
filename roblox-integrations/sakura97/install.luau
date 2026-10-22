-- XN [VOICE] v102 — Brookhaven cleaned / landscaped / Halloween / wind / loading
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local AssetService=game:GetService("AssetService")
local CollectionService=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local StarterGui=game:GetService("StarterGui")

local MAP_ID=106476929993683
local WIND_ID=11946229834
local GRASS_ID=87377915371959
local HALLOWEEN_ID=12489961338
local GAME_NAME="XN [VOICE]"

local function loadAsset(id)
	local ok,res=pcall(AssetService.LoadAssetAsync,AssetService,id)
	if not ok or not res then error("Asset "..id.." failed: "..tostring(res)) end
	return res
end

local function clearContainer(container)
	for _,child in ipairs(container:GetChildren()) do child:Destroy() end
end

-- Remove toda a build anterior.
for _,child in ipairs(workspace:GetChildren()) do
	if child~=Terrain and not child:IsA("Camera") then child:Destroy() end
end
Terrain:Clear()
clearContainer(ServerScriptService)
clearContainer(StarterPlayer.StarterPlayerScripts)
clearContainer(ReplicatedFirst)
clearContainer(StarterGui)
for _,child in ipairs(ReplicatedStorage:GetChildren()) do
	if child.Name=="SakuraRuntime" or child.Name=="ForestRuntime" or child.Name=="SweanRuntime" or child.Name=="XNRuntime" then
		child:Destroy()
	end
end
clearContainer(Lighting)

local runtime=Instance.new("Folder")
runtime.Name="XNRuntime"
runtime.Parent=ReplicatedStorage
runtime:SetAttribute("Version",102)
runtime:SetAttribute("GameName",GAME_NAME)
runtime:SetAttribute("MapAssetId",MAP_ID)
runtime:SetAttribute("MapName","Brookhaven Map")
runtime:SetAttribute("Theme","HalloweenPumpkins")
runtime:SetAttribute("LoadingStyle","FullscreenGlitchAccessing")

pcall(function()
	workspace.StreamingEnabled=true
	workspace.StreamingMinRadius=96
	workspace.StreamingTargetRadius=320
end)
workspace.FallenPartsDestroyHeight=-500

local function modelPartCount(model)
	local n=0
	for _,d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end
	return n
end

local function modelBottom(model)
	local cf,size=model:GetBoundingBox()
	return cf.Position.Y-size.Y/2
end

local function placeModelBottom(model,pos,yaw,sink)
	model:PivotTo(CFrame.new(pos.X,0,pos.Z)*CFrame.Angles(0,yaw or 0,0))
	local bottom=modelBottom(model)
	model:PivotTo(model:GetPivot()+Vector3.new(0,pos.Y-bottom-(sink or 0),0))
end

local function scaleModelFootprint(model,target)
	local _,size=model:GetBoundingBox()
	local current=math.max(size.X,size.Z)
	if current>0 then pcall(function() model:ScaleTo(model:GetScale()*(target/current)) end) end
end

local function ancestorHas(inst,needle)
	needle=needle:lower()
	local p=inst.Parent
	while p and p~=workspace do
		if p.Name:lower():find(needle,1,true) then return true end
		p=p.Parent
	end
	return false
end

-- =========================================================
-- BROOKHAVEN MAP REAL, LIMPO
-- =========================================================
local asset=loadAsset(MAP_ID)
local source=asset:FindFirstChild("Brookhaven Map",true)
assert(source and source:IsA("Model"),"Brookhaven Map model missing")

local map=source:Clone()
map.Name="BrookhavenMap"
map:SetAttribute("AssetId",MAP_ID)
map.Parent=workspace

-- Captura templates visuais antes de limpar marcadores.
local originalTree=map:FindFirstChild("NewTree",true)
local treeTemplate=originalTree and originalTree:IsA("Model") and originalTree:Clone() or nil
if treeTemplate then
	for _,d in ipairs(treeTemplate:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored=true
			d.CanTouch=false
			d.CanCollide=false
		end
	end
end

local bushTemplate=nil
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("BasePart") and d.Name=="Bush" then bushTemplate=d:Clone() break end
end
if bushTemplate then
	bushTemplate.Anchored=true
	bushTemplate.CanTouch=false
	bushTemplate.CanCollide=false
end

local benchTemplate=nil
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("Model") and d.Name:lower():find("bench",1,true) and modelPartCount(d)>0 then
		benchTemplate=d:Clone()
		for _,x in ipairs(benchTemplate:GetDescendants()) do
			if x:IsA("LuaSourceContainer") then x:Destroy()
			elseif x:IsA("BasePart") then x.Anchored=true x.CanTouch=false end
		end
		break
	end
end

local scriptsRemoved=0
local partCountBefore=0
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("LuaSourceContainer") then
		scriptsRemoved+=1
	elseif d:IsA("BasePart") then
		partCountBefore+=1
	end
end

-- Marca os pontos originais das casas e usa a altura média como referência de chão.
local houseMarkerRoot=map:FindFirstChild("001_MapHouseTeleports",true)
local markerRefs={}
local avgHouseY=0
if houseMarkerRoot then
	for _,d in ipairs(houseMarkerRoot:GetDescendants()) do
		if d:IsA("BasePart") and d.Name:match("^House%d+$") then
			table.insert(markerRefs,d)
			avgHouseY+=d.Position.Y
		end
	end
end
assert(#markerRefs>=20,"Poucos marcadores de casas encontrados: "..tostring(#markerRefs))
avgHouseY/=#markerRefs

-- Centraliza X/Z e traz o nível residencial principal para perto de Y=10.
local mapCF,mapSize=map:GetBoundingBox()
map:PivotTo(map:GetPivot()+Vector3.new(-mapCF.Position.X,10-avgHouseY,-mapCF.Position.Z))

local housePositions={}
for _,marker in ipairs(markerRefs) do table.insert(housePositions,marker.Position) end

-- Remove scripts do free model e deixa tudo visual/estático.
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("LuaSourceContainer") then
		d:Destroy()
	elseif d:IsA("BasePart") then
		d.Anchored=true
		d.CanTouch=false
		pcall(function()
			if d:IsA("MeshPart") then d.RenderFidelity=Enum.RenderFidelity.Automatic end
		end)
	end
end

-- Remove teleports/placas de compra de casa, mas preserva a geometria dos morros.
if houseMarkerRoot and houseMarkerRoot.Parent then houseMarkerRoot:Destroy() end
local removeList={}
for _,d in ipairs(map:GetDescendants()) do
	local n=d.Name:lower()
	if n=="buyhouse" or n:find("housebutton",1,true) or n:find("plotofland",1,true) then
		table.insert(removeList,d)
	end
end
for _,d in ipairs(removeList) do if d.Parent then d:Destroy() end end

runtime:SetAttribute("ScriptsRemoved",scriptsRemoved)
runtime:SetAttribute("OriginalParts",partCountBefore)
runtime:SetAttribute("HouseMarkerCount",#housePositions)
asset:Destroy()

-- =========================================================
-- SUPERFÍCIES VERDES REAIS
-- =========================================================
local greenGround={}
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("BasePart") then
		local c=d.Color
		local lname=d.Name:lower()
		local green=c.G>c.R*1.12 and c.G>c.B*1.05 and c.G>.18
		local horizontal=d.CFrame.UpVector.Y>.88
		local area=d.Size.X*d.Size.Z
		local excluded=
			lname=="leaf" or lname=="leaves" or lname=="bush"
			or ancestorHas(d,"newtree") or ancestorHas(d,"sign")
		if green and horizontal and area>300 and not excluded then
			table.insert(greenGround,d)
			CollectionService:AddTag(d,"XNGreenGround")
			d.Material=Enum.Material.Grass
		end
	end
end
assert(#greenGround>=8,"Poucas superficies verdes reais: "..tostring(#greenGround))
runtime:SetAttribute("GreenGroundCount",#greenGround)

-- =========================================================
-- RAYCAST / CHÃO
-- =========================================================
local mapRay=RaycastParams.new()
mapRay.FilterType=Enum.RaycastFilterType.Include
mapRay.FilterDescendantsInstances={map}
mapRay.IgnoreWater=true

local function groundAt(x,z,startY)
	local hit=workspace:Raycast(
		Vector3.new(x,startY or (mapSize.Y+400),z),
		Vector3.new(0,-(mapSize.Y+900),0),
		mapRay
	)
	if hit and hit.Normal.Y>.62 then return hit.Position,hit.Instance end
end

-- =========================================================
-- LOTES DE CASA -> MINI PARQUES/JARDINS
-- =========================================================
local lots=Instance.new("Folder")
lots.Name="ReworkedHouseLots"
lots.Parent=workspace
lots:SetAttribute("SourceMarkers",#housePositions)

local rng=Random.new(102941)
local lotCount=0
for i,raw in ipairs(housePositions) do
	local ground=groundAt(raw.X,raw.Z,raw.Y+180)
	if ground then
		local lot=Instance.new("Folder")
		lot.Name=string.format("LotPark_%02d",i)
		lot.Parent=lots

		local lawn=Instance.new("Part")
		lawn.Name="Lawn"
		lawn.Size=Vector3.new(34,.35,30)
		lawn.CFrame=CFrame.new(ground+Vector3.new(0,.11,0))*CFrame.Angles(0,math.rad((i*23)%180),0)
		lawn.Color=Color3.fromRGB(69,112,54)
		lawn.Material=Enum.Material.Grass
		lawn.Anchored=true
		lawn.CanCollide=false
		lawn.CanTouch=false
		lawn.CanQuery=false
		lawn.Parent=lot

		if treeTemplate then
			for t=1,2 do
				local angle=(t==1 and -1 or 1)*1.05 + i*.31
				local tx=ground.X+math.cos(angle)*10
				local tz=ground.Z+math.sin(angle)*10
				local tg=groundAt(tx,tz,ground.Y+90) or ground
				local tree=treeTemplate:Clone()
				tree.Name="Tree"
				tree.Parent=lot
				pcall(function() tree:ScaleTo(tree:GetScale()*rng:NextNumber(.55,.78)) end)
				placeModelBottom(tree,tg,rng:NextNumber(0,math.pi*2),.18)
			end
		end

		if bushTemplate then
			for b=1,2 do
				local off=Vector2.new((b==1 and -7 or 7),6)
				local bg=groundAt(ground.X+off.X,ground.Z+off.Y,ground.Y+70) or ground
				local bush=bushTemplate:Clone()
				bush.Name="Bush"
				bush.Size=bush.Size*rng:NextNumber(.8,1.12)
				bush.CFrame=CFrame.new(bg+Vector3.new(0,bush.Size.Y*.45,0))*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0)
				bush.Parent=lot
			end
		end

		if benchTemplate and i%4==0 then
			local bench=benchTemplate:Clone()
			bench.Name="Bench"
			bench.Parent=lot
			pcall(function() bench:ScaleTo(bench:GetScale()*.75) end)
			placeModelBottom(bench,ground+Vector3.new(0,0,5),math.rad((i*41)%360),0)
		end

		lotCount+=1
	end
end
assert(lotCount>=18,"Poucos lotes reurbanizados: "..tostring(lotCount))
runtime:SetAttribute("ReworkedLotCount",lotCount)

-- =========================================================
-- GRAMA EXTRA: SOMENTE NAS PARTES VERDES TAGGEADAS
-- =========================================================
local grassFolder=Instance.new("Folder")
grassFolder.Name="GreenGrassDecor"
grassFolder.Parent=workspace
grassFolder:SetAttribute("PlacementRule","XNGreenGroundOnly")
grassFolder:SetAttribute("AssetId",GRASS_ID)

local grassAsset=loadAsset(GRASS_ID)
local grassTemplate=nil
for _,d in ipairs(grassAsset:GetChildren()) do
	if (d:IsA("Model") or d:IsA("BasePart")) then
		local hasPart=d:IsA("BasePart") or d:FindFirstChildWhichIsA("BasePart",true)
		if hasPart then grassTemplate=d:Clone() break end
	end
end
if not grassTemplate then
	local p=grassAsset:FindFirstChildWhichIsA("BasePart",true)
	if p then
		local m=Instance.new("Model")
		p:Clone().Parent=m
		grassTemplate=m
	end
end
assert(grassTemplate,"Grass visual template missing")
grassAsset:Destroy()

if grassTemplate:IsA("BasePart") then
	local m=Instance.new("Model")
	grassTemplate.Parent=m
	grassTemplate=m
end
for _,d in ipairs(grassTemplate:GetDescendants()) do
	if d:IsA("LuaSourceContainer") then d:Destroy()
	elseif d:IsA("BasePart") then
		d.Anchored=true d.CanCollide=false d.CanTouch=false d.CanQuery=false
	end
end
scaleModelFootprint(grassTemplate,5)

table.sort(greenGround,function(a,b) return (a.Size.X*a.Size.Z)>(b.Size.X*b.Size.Z) end)
local grassPlaced=0
local maxGrass=150
for _,surface in ipairs(greenGround) do
	if grassPlaced>=maxGrass then break end
	local area=surface.Size.X*surface.Size.Z
	local quota=math.clamp(math.floor(area/9000)+1,2,10)
	for _=1,quota do
		if grassPlaced>=maxGrass then break end
		local lx=rng:NextNumber(-surface.Size.X*.43,surface.Size.X*.43)
		local lz=rng:NextNumber(-surface.Size.Z*.43,surface.Size.Z*.43)
		local top=surface.CFrame:PointToWorldSpace(Vector3.new(lx,surface.Size.Y*.5,lz))
		local g=grassTemplate:Clone()
		g.Name=string.format("Grass_%03d",grassPlaced+1)
		g:SetAttribute("GroundTagged",true)
		g.Parent=grassFolder
		pcall(function() g:ScaleTo(g:GetScale()*rng:NextNumber(.75,1.18)) end)
		placeModelBottom(g,top,rng:NextNumber(0,math.pi*2),.03)
		grassPlaced+=1
	end
end
grassTemplate:Destroy()
assert(grassPlaced>=60,"Pouca grama extra: "..tostring(grassPlaced))
runtime:SetAttribute("GrassDecorCount",grassPlaced)

-- =========================================================
-- VENTO: SOMENTE FOLHAGEM
-- =========================================================
local windTagged=0
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("BasePart") then
		local n=d.Name:lower()
		if n=="leaf" or n=="leaves" then
			CollectionService:AddTag(d,"WindShake")
			d:SetAttribute("WindPower",.34)
			d:SetAttribute("WindSpeed",15)
			windTagged+=1
		end
	end
end
for _,d in ipairs(lots:GetDescendants()) do
	if d:IsA("BasePart") then
		local n=d.Name:lower()
		if n=="leaf" or n=="leaves" then
			CollectionService:AddTag(d,"WindShake")
			d:SetAttribute("WindPower",.34)
			d:SetAttribute("WindSpeed",15)
			windTagged+=1
		end
	end
end
assert(windTagged>0,"Nenhuma folhagem recebeu WindShake")
runtime:SetAttribute("WindTagged",windTagged)

workspace.GlobalWind=Vector3.new(14,0,5)
local windAsset=loadAsset(WIND_ID)
local sourceController=windAsset:FindFirstChild("WindController",true)
assert(sourceController and sourceController:IsA("LocalScript"),"WindController source missing")
local sourceLines=sourceController:FindFirstChild("WindLines")
local sourceShake=sourceController:FindFirstChild("WindShake")
assert(sourceLines and sourceShake,"Wind modules missing")

local controller=Instance.new("LocalScript")
controller.Name="WindController"
controller:SetAttribute("AssetId",WIND_ID)
controller.Source=[[
local WindLines=require(script:WaitForChild("WindLines"))
local WindShake=require(script:WaitForChild("WindShake"))
local wind=workspace.GlobalWind
local dir=wind.Magnitude>0 and wind.Unit or Vector3.new(1,0,.3)
local speed=math.max(wind.Magnitude,1)
WindLines:Init({
	Direction=dir;
	Speed=speed;
	Lifetime=1.8;
	SpawnRate=12;
})
WindShake:SetDefaultSettings({
	WindSpeed=speed;
	WindDirection=dir;
	WindPower=.34;
})
WindShake:Init()
]]
local lines=Instance.new("ModuleScript")
lines.Name="WindLines"
lines.Source=sourceLines.Source
lines.Parent=controller
local shake=Instance.new("ModuleScript")
shake.Name="WindShake"
shake.Source=sourceShake.Source
shake.Parent=controller
controller.Parent=StarterPlayer.StarterPlayerScripts
windAsset:Destroy()

-- =========================================================
-- HALLOWEEN: APENAS ABÓBORAS, ORGANIZADAS
-- =========================================================
local pumpkinAsset=loadAsset(HALLOWEEN_ID)
local pumpkinTemplates={}
for _,d in ipairs(pumpkinAsset:GetDescendants()) do
	if d:IsA("BasePart") and d.Name=="Pumpkin" then
		local p=d:Clone()
		p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
		table.insert(pumpkinTemplates,p)
	end
end
assert(#pumpkinTemplates>=1,"Pumpkins missing")
pumpkinAsset:Destroy()

local halloween=Instance.new("Folder")
halloween.Name="HalloweenPumpkins"
halloween.Parent=workspace
halloween:SetAttribute("AssetId",HALLOWEEN_ID)
halloween:SetAttribute("OnlyPumpkins",true)

local pumpkinCount=0
local clusterCount=0
for i,lot in ipairs(lots:GetChildren()) do
	if i%3==1 and clusterCount<8 then
		local lawn=lot:FindFirstChild("Lawn")
		if lawn and lawn:IsA("BasePart") then
			clusterCount+=1
			local cluster=Instance.new("Folder")
			cluster.Name=string.format("PumpkinCluster_%02d",clusterCount)
			cluster.Parent=halloween
			local offsets={Vector2.new(-4,-2.5),Vector2.new(0,-4),Vector2.new(4,-2.5)}
			for j,off in ipairs(offsets) do
				local p=pumpkinTemplates[((pumpkinCount)%#pumpkinTemplates)+1]:Clone()
				pumpkinCount+=1
				p.Name=string.format("Pumpkin_%02d",pumpkinCount)
				local sc=.48+rng:NextNumber(-.06,.13)
				p.Size=p.Size*sc
				local world=lawn.CFrame:PointToWorldSpace(Vector3.new(off.X,lawn.Size.Y*.5,off.Y))
				p.CFrame=CFrame.new(world+Vector3.new(0,p.Size.Y*.45,0))*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0)
				p.Parent=cluster
			end
		end
	end
end
for _,p in ipairs(pumpkinTemplates) do p:Destroy() end
assert(clusterCount==8 and pumpkinCount==24,"Halloween pumpkin layout incomplete")
halloween:SetAttribute("ClusterCount",clusterCount)
halloween:SetAttribute("PumpkinCount",pumpkinCount)
runtime:SetAttribute("PumpkinClusters",clusterCount)
runtime:SetAttribute("PumpkinCount",pumpkinCount)

-- =========================================================
-- LIGHTING / DESIGN
-- =========================================================
Lighting.ClockTime=16.8
Lighting.Brightness=2.15
Lighting.ExposureCompensation=.02
Lighting.Ambient=Color3.fromRGB(115,108,102)
Lighting.OutdoorAmbient=Color3.fromRGB(148,138,128)
Lighting.GlobalShadows=true
Lighting.EnvironmentDiffuseScale=.55
Lighting.EnvironmentSpecularScale=.42

local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="XNAtmosphere"
atmosphere.Density=.21
atmosphere.Offset=.06
atmosphere.Color=Color3.fromRGB(218,205,189)
atmosphere.Decay=Color3.fromRGB(108,102,99)
atmosphere.Haze=.85
atmosphere.Glare=.035
atmosphere.Parent=Lighting

local cc=Instance.new("ColorCorrectionEffect")
cc.Name="XNColor"
cc.Brightness=.01
cc.Contrast=.055
cc.Saturation=-.02
cc.TintColor=Color3.fromRGB(255,235,218)
cc.Parent=Lighting

local bloom=Instance.new("BloomEffect")
bloom.Name="XNBloom"
bloom.Intensity=.12
bloom.Size=20
bloom.Threshold=1.25
bloom.Parent=Lighting

-- =========================================================
-- SPAWN SEGURO
-- =========================================================
table.sort(housePositions,function(a,b)
	return Vector2.new(a.X,a.Z).Magnitude<Vector2.new(b.X,b.Z).Magnitude
end)
local spawnGround=nil
for _,p in ipairs(housePositions) do
	spawnGround=groundAt(p.X,p.Z,p.Y+180)
	if spawnGround then break end
end
if not spawnGround then
	for radius=0,800,60 do
		for step=1,24 do
			local a=(step/24)*math.pi*2
			spawnGround=groundAt(math.cos(a)*radius,math.sin(a)*radius,mapSize.Y+300)
			if spawnGround then break end
		end
		if spawnGround then break end
	end
end
assert(spawnGround,"Spawn ground missing")

local spawn=Instance.new("SpawnLocation")
spawn.Name="XNSpawn"
spawn.Size=Vector3.new(8,.45,8)
spawn.CFrame=CFrame.new(spawnGround+Vector3.new(0,.225,0))
spawn.Anchored=true
spawn.CanCollide=false
spawn.CanTouch=false
spawn.Transparency=1
spawn.Neutral=true
spawn.Enabled=true
spawn.Duration=0
spawn.Parent=workspace

-- =========================================================
-- LOADING FULLSCREEN: "acessando…" + GLITCH + ZOOM 1P -> 3P
-- =========================================================
local loading=Instance.new("LocalScript")
loading.Name="XNLoading"
loading:SetAttribute("GameName",GAME_NAME)
loading:SetAttribute("Text","acessando…")
loading:SetAttribute("Fullscreen",true)
loading:SetAttribute("CameraRotationUnlocked",true)
loading.Source=[[
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="XNLoadingUI"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=100000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")

local bg=Instance.new("Frame")
bg.Name="Background"
bg.Size=UDim2.fromScale(1,1)
bg.BackgroundColor3=Color3.fromRGB(8,8,9)
bg.BorderSizePixel=0
bg.Parent=gui

local label=Instance.new("TextLabel")
label.Name="Accessing"
label.AnchorPoint=Vector2.new(.5,.5)
label.Position=UDim2.fromScale(.5,.5)
label.Size=UDim2.new(.72,0,0,70)
label.BackgroundTransparency=1
label.Text="acessando…"
label.Font=Enum.Font.BuilderSansBold
label.TextSize=30
label.TextColor3=Color3.fromRGB(241,241,241)
label.TextTransparency=.06
label.Parent=bg

local scan=Instance.new("Frame")
scan.Name="GlitchLine"
scan.Size=UDim2.new(1,0,0,2)
scan.Position=UDim2.fromScale(0,.2)
scan.BackgroundColor3=Color3.fromRGB(255,255,255)
scan.BackgroundTransparency=.88
scan.BorderSizePixel=0
scan.Parent=bg

local running=true
task.spawn(function()
	local seed=0
	while running and gui.Parent do
		seed+=1
		if seed%3==0 then
			label.Position=UDim2.new(.5,math.random(-4,4),.5,math.random(-2,2))
			label.TextTransparency=math.random(2,18)/100
			scan.Position=UDim2.fromScale(0,math.random())
			scan.BackgroundTransparency=math.random(82,96)/100
		else
			label.Position=UDim2.fromScale(.5,.5)
		end
		task.wait(.055+math.random()*0.055)
	end
end)

if not game:IsLoaded() then game.Loaded:Wait() end
local character=player.Character or player.CharacterAdded:Wait()
local humanoid=character:WaitForChild("Humanoid")
local camera=workspace.CurrentCamera
camera.CameraType=Enum.CameraType.Custom
camera.CameraSubject=humanoid
player.CameraMode=Enum.CameraMode.Classic

-- Só o zoom fica temporariamente controlado. A rotação continua livre.
player.CameraMinZoomDistance=.55
player.CameraMaxZoomDistance=.55
task.wait(.3)

local duration=1.65
local start=os.clock()
while true do
	local a=math.clamp((os.clock()-start)/duration,0,1)
	local smooth=1-(1-a)^3
	local zoom=.55+(10-.55)*smooth
	player.CameraMinZoomDistance=zoom
	player.CameraMaxZoomDistance=zoom
	bg.BackgroundTransparency=smooth*.22
	label.TextTransparency=.06+smooth*.5
	if a>=1 then break end
	RunService.RenderStepped:Wait()
end

player.CameraMinZoomDistance=.5
player.CameraMaxZoomDistance=24
running=false

TweenService:Create(bg,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
TweenService:Create(label,TweenInfo.new(.22),{TextTransparency=1}):Play()
task.wait(.38)
gui:Destroy()
]]
loading.Parent=ReplicatedFirst

-- =========================================================
-- SERVER / VOID
-- =========================================================
local server=Instance.new("Script")
server.Name="XNServer"
server.Source=[[
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("XNSpawn")

local function protect(character)
	task.spawn(function()
		while character.Parent do
			local root=character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y<-350 then
				character:PivotTo(spawn.CFrame*CFrame.new(0,4,0))
			end
			task.wait(.45)
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
]]
server.Parent=ServerScriptService

runtime:SetAttribute("BrookhavenParts",modelPartCount(map))
runtime:SetAttribute("MapSizeX",mapSize.X)
runtime:SetAttribute("MapSizeY",mapSize.Y)
runtime:SetAttribute("MapSizeZ",mapSize.Z)

print("[XN] Brookhaven rebuild complete")
return {
	version=102,
	mapParts=modelPartCount(map),
	lots=lotCount,
	grass=grassPlaced,
	windTagged=windTagged,
	pumpkins=pumpkinCount,
	pumpkinClusters=clusterCount,
	scriptsRemoved=scriptsRemoved
}
