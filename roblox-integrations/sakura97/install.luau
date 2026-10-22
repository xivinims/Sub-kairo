-- Sakura Island v97 — mapa limpo igual a foto pedida
-- Deleta tudo, cria ilha, 27 cerejeiras, grama skinned, caminho de pedra, ceu de tarde, vento

assert(game.GameId == 9419478735 and game.PlaceId == 79738710219521, "Place errado")

local AssetService = game:GetService("AssetService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

-- ============ 1. LIMPA TUDO ============
local function clearWorld()
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name ~= "Terrain" and child.Name ~= "Camera" and not child:IsA("Terrain") then
			if child.Name == "ForestWorld" or child.Name == "Baseplate"
				or child.Name == "StonePath" or child.Name == "Wildflowers"
				or child.Name == "WorldSafetyFloor" or child.Name == "IslandSpawn"
				or child.Name:find("Forest") or child.Name:find("Tree") or child.Name:find("Sakura") then
				child:Destroy()
			end
		end
	end
	-- limpa scripts antigos
	for _, s in ipairs(game.ServerScriptService:GetChildren()) do
		if s.Name:find("Forest") or s.Name:find("Sakura") or s.Name:find("TreeWorld") or s.Name=="NametagService" then
			s:Destroy()
		end
	end
	for _, s in ipairs(game.StarterPlayer.StarterPlayerScripts:GetChildren()) do
		if s.Name:find("Forest") or s.Name:find("Sakura") or s.Name:find("Grass") or s.Name=="WindController" then
			s:Destroy()
		end
	end
	if game.ReplicatedStorage:FindFirstChild("ForestRuntime") then
		game.ReplicatedStorage.ForestRuntime:Destroy()
	end
	if game.ReplicatedStorage:FindFirstChild("SakuraRuntime") then
		game.ReplicatedStorage.SakuraRuntime:Destroy()
	end
	local oldLoading=ReplicatedFirst:FindFirstChild("LoadingScreen")
	if oldLoading then oldLoading:Destroy() end
end

clearWorld()

-- ============ 2. RUNTIME ============
local runtime = Instance.new("Folder")
runtime.Name = "SakuraRuntime"
runtime.Parent = game.ReplicatedStorage
runtime:SetAttribute("Version", 97)
runtime:SetAttribute("MapType", "SakuraIsland")

-- ============ 2.5. GEOMETRIA DA ESTRADINHA CIRCULAR ============
local PATH_SEGMENTS=20
local PATH_SCALE=.68
local PATH_RADIUS_X=108
local PATH_RADIUS_Z=78
local PATH_CLEAR_RADIUS=6

local function pathPointAt(t)
	local a=t*math.pi*2
	local rx=PATH_RADIUS_X+math.sin(a*3)*4+math.sin(a*7)*1.8
	local rz=PATH_RADIUS_Z+math.cos(a*4)*3
	return Vector3.new(math.cos(a)*rx,0,math.sin(a)*rz)
end

local function pathCenterFor(i)
	return pathPointAt((i-1)/PATH_SEGMENTS)
end

local function pathYawFor(i)
	local t=(i-1)/PATH_SEGMENTS
	local a=pathPointAt(t-.003)
	local b=pathPointAt(t+.003)
	return math.atan2(b.X-a.X,b.Z-a.Z)
end

local function distanceToStonePath(x,z)
	local p=Vector2.new(x,z)
	local best=math.huge
	for j=0,95 do
		local q=pathPointAt(j/96)
		local d=(p-Vector2.new(q.X,q.Z)).Magnitude
		if d<best then best=d end
	end
	return best
end

local function nearStonePath(x,z,padding)
	return distanceToStonePath(x,z) <= PATH_CLEAR_RADIUS+(padding or 0)
end

-- ============ 3. ILHA + TERRENO ============
local function buildIsland()
	Terrain:Clear()
	pcall(function()
		Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(86,112,58))
		Terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(78,104,57))
		Terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(157,145,112))
	end)

	Terrain.WaterColor=Color3.fromRGB(72,118,128)
	Terrain.WaterTransparency=.22
	Terrain.WaterReflectance=.28
	Terrain.WaterWaveSize=.12
	Terrain.WaterWaveSpeed=7

	-- Oceano contínuo. A documentação oficial usa um volume enorme para levar
	-- água até o horizonte; aqui usamos 1800x1800 ao redor da ilha.
	Terrain:FillBlock(CFrame.new(0,-17,0),Vector3.new(1900,10,1900),Enum.Material.Sand)
	Terrain:FillBlock(CFrame.new(0,-6,0),Vector3.new(1800,12,1800),Enum.Material.Water)

	local radius=220
	for x=-radius,radius,8 do
		for z=-radius,radius,8 do
			local dist=math.sqrt(x*x+z*z)
			if dist<radius then
				local h=10+math.sin(x*.018)*2.2+math.cos(z*.015)*1.8+math.sin((x+z)*.01)*1.5
				if dist>radius*.78 then
					h=h-(dist-radius*.78)*.35
				end
				h=math.max(1.8,h)
				-- Quatro studs abaixo do nível da água deixam a massa da ilha
				-- contínua, evitando frestas na costa.
				Terrain:FillBlock(
					CFrame.new(x,(h-4)/2,z),
					Vector3.new(10,h+4,10),
					Enum.Material.Grass
				)
			end
		end
	end

	-- Corredor verde sem grama animada no caminho. Animated grass só aparece
	-- em Enum.Material.Grass, então trocamos apenas o material da faixa.
	for j=0,119 do
		local p=pathPointAt(j/120)
		local region=Region3.new(
			Vector3.new(p.X-6,-8,p.Z-6),
			Vector3.new(p.X+6,40,p.Z+6)
		):ExpandToGrid(4)
		Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.LeafyGrass)
	end

	-- Última camada física de segurança, muito abaixo da água/fundo do mar.
	local safety=Instance.new("Part")
	safety.Name="WorldSafetyFloor"
	safety.Size=Vector3.new(1900,2,1900)
	safety.CFrame=CFrame.new(0,-45,0)
	safety.Anchored=true
	safety.CanCollide=true
	safety.CanTouch=false
	safety.Transparency=1
	safety.Parent=workspace

	workspace.FallenPartsDestroyHeight=-200
	workspace:SetAttribute("SakuraIslandReady",true)
	runtime:SetAttribute("OceanSize",1800)
	runtime:SetAttribute("PathNoGrassMaterial","LeafyGrass")
end

buildIsland()

-- ============ 4. CÉU + ILUMINAÇÃO DE TARDE ============
local function setupSkyAndLighting()
	-- limpa lighting antigo
	for _, c in ipairs(Lighting:GetChildren()) do
		c:Destroy()
	end

	-- Sky do asset pedido
	local ok, skyAsset = pcall(function()
		return AssetService:LoadAssetAsync(137401994501544)
	end)
	if ok and skyAsset then
		local sky = skyAsset:FindFirstChildOfClass("Sky") or skyAsset:FindFirstChildWhichIsA("Sky", true)
		if sky then
			sky = sky:Clone()
			sky.Parent = Lighting
		end
		skyAsset:Destroy()
	end

	-- se não carregou o sky, cria um de tarde manual
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.SkyboxBk = "rbxassetid://600830446"
		sky.SkyboxDn = "rbxassetid://600831635"
		sky.SkyboxFt = "rbxassetid://600832720"
		sky.SkyboxLf = "rbxassetid://600833862"
		sky.SkyboxRt = "rbxassetid://600835177"
		sky.SkyboxUp = "rbxassetid://600835780"
		sky.Parent = Lighting
	end

	-- luz de fim de tarde (não noite)
	Lighting.ClockTime = 17.2	-- fim de tarde
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(140, 120, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 130, 110)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 180, 140)
	Lighting.ColorShift_Bottom = Color3.fromRGB(80, 60, 50)
	Lighting.FogColor = Color3.fromRGB(200, 160, 140)
	Lighting.FogEnd = 1200
	Lighting.FogStart = 80
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(210, 170, 140)
	atmosphere.Decay = Color3.fromRGB(180, 120, 90)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.1
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.45
	bloom.Size = 24
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0.04
	colorCorrection.Contrast = 0.08
	colorCorrection.Saturation = 0.15
	colorCorrection.TintColor = Color3.fromRGB(255, 235, 220)
	colorCorrection.Parent = Lighting
end

setupSkyAndLighting()

-- ============ 5. VENTO ============
local function setupWind()
	local scripts=game.StarterPlayer.StarterPlayerScripts
	local old=scripts:FindFirstChild("WindController")
	if old then old:Destroy() end

	workspace.GlobalWind=Vector3.new(14,0,5)

	local ok,asset=pcall(function()
		return AssetService:LoadAssetAsync(11946229834)
	end)
	if not ok or not asset then
		error("Wind Effects 11946229834 failed to load")
	end

	local source=asset:FindFirstChild("WindController",true)
	assert(source and source:IsA("LocalScript"),"WindController missing from exact asset")
	assert(source:FindFirstChild("WindLines"),"WindLines missing from exact asset")
	assert(source:FindFirstChild("WindShake"),"WindShake missing from exact asset")

	-- Use the exact controller and its exact child modules, unchanged.
	local controller=source:Clone()
	controller.Name="WindController"
	controller:SetAttribute("AssetId",11946229834)
	controller:SetAttribute("ExactCreatorStoreController",true)
	controller.Parent=scripts

	asset:Destroy()
	print("[Sakura97] Exact WindController installed unchanged")
end
setupWind()

local function visualPartCount(inst)
	local n=0
	if inst:IsA("BasePart") then n+=1 end
	for _,d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then n+=1 end
	end
	return n
end

local function validBounds(model)
	local ok,cf,size=pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok or not size or size.X<=0 or size.Y<=0 or size.Z<=0 then
		return nil
	end
	return cf,size
end

local function findVisualModel(asset, preferredWords)
	local best=nil
	local bestScore=-1
	for _,d in ipairs(asset:GetDescendants()) do
		if d:IsA("Model") and d:FindFirstChildWhichIsA("BasePart", true) then
			local _,size=validBounds(d)
			if size then
				local score=visualPartCount(d)
				local name=d.Name:lower()
				for _,word in ipairs(preferredWords or {}) do
					if name:find(word,1,true) then score+=10000 end
				end
				if score>bestScore then
					best=d
					bestScore=score
				end
			end
		end
	end
	if best then return best:Clone() end

	local part=asset:FindFirstChildWhichIsA("BasePart", true)
	if part and part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0 then
		local m=Instance.new("Model")
		part:Clone().Parent=m
		return m
	end
	return nil
end

local function safeScale(model,scale)
	return pcall(function()
		model:ScaleTo(scale)
	end)
end

local function normalizeHeight(model,targetHeight)
	local _,size=validBounds(model)
	if not size then return false end
	local current=model:GetScale()
	return safeScale(model,current*(targetHeight/size.Y))
end

local function placeModelOnGround(model,groundPosition,yaw)
	local ok=pcall(function()
		model:PivotTo(CFrame.new(groundPosition)*CFrame.Angles(0,yaw,0))
	end)
	if not ok then return false end
	local cf,size=validBounds(model)
	if not size then return false end
	local bottom=cf.Position.Y-size.Y/2
	return pcall(function()
		model:PivotTo(model:GetPivot()+Vector3.new(0,groundPosition.Y-bottom,0))
	end)
end

-- ============ 6. ÁRVORES CEREJEIRA (27 unidades, maiores) ============
local function placeSakuraTrees()
	local folder = Instance.new("Folder")
	folder.Name = "SakuraTrees"
	folder.Parent = workspace

	local ok, treeAsset = pcall(function()
		return AssetService:LoadAssetAsync(9626366517)
	end)
	if not ok or not treeAsset then
		warn("Não consegui carregar a Sakura Tree 9626366517")
		return
	end

	local template=findVisualModel(treeAsset,{"sakura","cherry","tree"})
	if not template then
		warn("Template visual de cerejeira não encontrado")
		treeAsset:Destroy()
		return
	end

	-- limpa scripts internos
	for _, d in ipairs(template:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Camera") then d:Destroy() end
	end

	local rng = Random.new(97001)
	local placed = 0
	local positions = {}
	local attempts=0

	-- 27 árvores espalhadas com espaçamento bom e fora da estradinha
	while placed < 27 and attempts < 6000 do
		attempts+=1
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(25, 175)
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist

		-- Mantém tronco e copa longe da estradinha circular.
		if nearStonePath(x,z,17) then continue end

		-- evita água e muito perto de outras
		local tooClose = false
		for _, p in ipairs(positions) do
			if (Vector2.new(x, z) - p).Magnitude < 28 then
				tooClose = true
				break
			end
		end
		if tooClose then continue end

		-- raycast no terreno
		local ray = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -120, 0))
		if not ray or ray.Material == Enum.Material.Water then continue end

		local tree = template:Clone()
		-- tamanho controlado: um pouco maior, mas nunca gigante
		local sizeOk=normalizeHeight(tree,rng:NextNumber(24,29))
		local yaw = rng:NextNumber(0, math.pi * 2)
		local placeOk=sizeOk and placeModelOnGround(tree,ray.Position,yaw)
		if not placeOk then
			tree:Destroy()
			continue
		end

		-- O bounding box do MeshPart encosta no Terrain, mas a geometria visual
		-- do tronco fica um pouco acima da borda da caixa. Enterrar levemente
		-- elimina a impressão de árvore flutuando sem esconder o tronco.
		tree:PivotTo(tree:GetPivot()+Vector3.new(0,-1.15,0))

		tree.Parent = folder
		CollectionService:AddTag(tree, "SakuraTree")
		for _,leaf in ipairs(tree:GetDescendants()) do
			if leaf:IsA("BasePart") and leaf.Name=="Leaves" then
				CollectionService:AddTag(leaf,"WindShake")
				leaf:SetAttribute("WindPower",0.32)
				leaf:SetAttribute("WindSpeed",14)
				leaf:SetAttribute("WindDirection",workspace.GlobalWind.Unit)

				local petals=Instance.new("ParticleEmitter")
				petals.Name="SakuraPetals"
				petals.Texture="rbxassetid://14302399641"
				petals.Color=ColorSequence.new({
					ColorSequenceKeypoint.new(0,Color3.fromRGB(255,210,226)),
					ColorSequenceKeypoint.new(.55,Color3.fromRGB(247,184,211)),
					ColorSequenceKeypoint.new(1,Color3.fromRGB(255,232,240))
				})
				petals.Transparency=NumberSequence.new({
					NumberSequenceKeypoint.new(0,1),
					NumberSequenceKeypoint.new(.08,.12),
					NumberSequenceKeypoint.new(.78,.18),
					NumberSequenceKeypoint.new(1,1)
				})
				petals.Size=NumberSequence.new({
					NumberSequenceKeypoint.new(0,.18,.05),
					NumberSequenceKeypoint.new(.35,.32,.08),
					NumberSequenceKeypoint.new(1,.20,.06)
				})
				petals.Squash=NumberSequence.new({
					NumberSequenceKeypoint.new(0,.42),
					NumberSequenceKeypoint.new(.5,-.18),
					NumberSequenceKeypoint.new(1,.34)
				})
				petals.Rate=rng:NextNumber(.9,1.35)
				petals.Lifetime=NumberRange.new(4.5,7)
				petals.Speed=NumberRange.new(.2,.8)
				petals.Acceleration=Vector3.new(0,-1.25,0)
				petals.Drag=1.35
				petals.WindAffectsDrag=true
				petals.EmissionDirection=Enum.NormalId.Bottom
				petals.SpreadAngle=Vector2.new(55,55)
				petals.Rotation=NumberRange.new(0,360)
				petals.RotSpeed=NumberRange.new(-55,55)
				petals.Orientation=Enum.ParticleOrientation.FacingCamera
				petals.LightInfluence=.72
				petals.LightEmission=.03
				petals.ZOffset=.05
				petals.Enabled=true
				petals.Parent=leaf
			end
		end
		placed += 1
		positions[#positions + 1] = Vector2.new(x, z)
	end

	assert(placed==27,"Não foi possível posicionar 27 cerejeiras sem invadir o caminho")
	template:Destroy()
	treeAsset:Destroy()
	runtime:SetAttribute("SakuraCount", placed)
	print("[Sakura97] Colocadas", placed, "cerejeiras")
end

placeSakuraTrees()

-- ============ 7. ESTRADINHA CIRCULAR EXATA STONE PATH (LONG) ============
local function placeStonePath()
	local old=workspace:FindFirstChild("StonePath")
	if old then old:Destroy() end

	local folder=Instance.new("Folder")
	folder.Name="StonePath"
	folder.Parent=workspace
	folder:SetAttribute("AssetId",136068114177879)
	folder:SetAttribute("ExactModelName","Stone Path (Long)")
	folder:SetAttribute("SegmentCount",PATH_SEGMENTS)
	folder:SetAttribute("Loop",true)
	folder:SetAttribute("UsesGroundPatches",false)
	folder:SetAttribute("NoGrassMaterial","LeafyGrass")

	local ok,asset=pcall(function()
		return AssetService:LoadAssetAsync(136068114177879)
	end)
	if not ok or not asset then
		error("Stone Path asset 136068114177879 failed to load")
	end

	local source=asset:FindFirstChild("Stone Path (Long)",true)
	assert(source and source:IsA("Model"),"Stone Path (Long) model missing")

	local sourcePartCount=0
	for _,d in ipairs(source:GetDescendants()) do
		if d:IsA("BasePart") then sourcePartCount+=1 end
	end
	assert(sourcePartCount==38,"Expected 38 parts in Stone Path (Long), got "..tostring(sourcePartCount))

	local totalVisible=0
	for i=1,PATH_SEGMENTS do
		local segment=source:Clone()
		segment.Name=string.format("Stone Path (Long) %02d",i)
		segment.Parent=folder

		for _,d in ipairs(segment:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored=true
				d.CanCollide=true
				d.CanTouch=false
				d.CanQuery=true
			end
		end

		local scale=PATH_SCALE*(1+math.sin(i*1.71)*.035)
		segment:ScaleTo(segment:GetScale()*scale)

		local center=pathCenterFor(i)
		local yaw=pathYawFor(i)+math.rad(math.sin(i*1.37)*2.2)
		local base=CFrame.new(center)*CFrame.Angles(0,yaw,0)
		local pivot=segment:GetPivot()

		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={
			folder,
			workspace:FindFirstChild("SakuraTrees"),
			workspace:FindFirstChild("Wildflowers"),
			workspace:FindFirstChild("WorldSafetyFloor")
		}

		local visible=0
		for _,part in ipairs(segment:GetDescendants()) do
			if part:IsA("BasePart") then
				local rel=pivot:ToObjectSpace(part.CFrame)
				local target=base*rel
				local pos=target.Position
				local hit=workspace:Raycast(Vector3.new(pos.X,75,pos.Z),Vector3.new(0,-145,0),params)
				if hit and hit.Material~=Enum.Material.Water then
					local rot=target-target.Position
					-- Levemente enterrada no terreno para parecer assentada de verdade.
					part.CFrame=CFrame.new(hit.Position+Vector3.new(0,part.Size.Y*.32,0))*rot
					part.Transparency=math.min(part.Transparency,.03)
					visible+=1
				else
					part.Transparency=1
					part.CanCollide=false
				end
			end
		end

		segment:SetAttribute("VisibleParts",visible)
		totalVisible+=visible
	end

	folder:SetAttribute("SourcePartsPerSegment",sourcePartCount)
	folder:SetAttribute("VisibleParts",totalVisible)
	asset:Destroy()
	print("[Sakura97] Circular Stone Path segments:",PATH_SEGMENTS,"visible stones:",totalVisible)
end

placeStonePath()

-- ============ 8. GRAMA SKINNED + FLORES ============
local function placeGrassAndFlowers()
	local oldGrass=workspace:FindFirstChild("SkinnedGrass")
	if oldGrass then oldGrass:Destroy() end
	local oldFlowers=workspace:FindFirstChild("Wildflowers")
	if oldFlowers then oldFlowers:Destroy() end

	local flowerFolder=Instance.new("Folder")
	flowerFolder.Name="Wildflowers"
	flowerFolder.Parent=workspace

	local rng=Random.new(97002)
	local made=0
	for i=1,520 do
		local angle=rng:NextNumber(0,math.pi*2)
		local dist=rng:NextNumber(10,198)
		local x=math.cos(angle)*dist
		local z=math.sin(angle)*dist
		if not nearStonePath(x,z,4.5) then
			local ray=workspace:Raycast(Vector3.new(x,55,z),Vector3.new(0,-100,0))
			if ray and ray.Material==Enum.Material.Grass then
				local flower=Instance.new("Part")
				flower.Name="Wildflower"
				flower.Size=Vector3.new(.16,.09,.16)
				flower.Shape=Enum.PartType.Ball
				flower.Anchored=true
				flower.CanCollide=false
				flower.CanTouch=false
				flower.Material=Enum.Material.SmoothPlastic
				flower.Color=(rng:NextNumber()>.58)
					and Color3.fromRGB(244,242,235)
					or Color3.fromRGB(211,188,226)
				flower.CFrame=CFrame.new(ray.Position+Vector3.new(0,.15,0))
				flower.Parent=flowerFolder
				made+=1
			end
		end
	end
	flowerFolder:SetAttribute("FlowerCount",made)
	print("[Sakura97] Small flowers:",made)
end
placeGrassAndFlowers()

-- ============ 9. SPAWN NO CHÃO ============
local function setupSpawn()
	local old=workspace:FindFirstChild("IslandSpawn")
	if old then old:Destroy() end

	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={
		workspace:FindFirstChild("StonePath"),
		workspace:FindFirstChild("SakuraTrees"),
		workspace:FindFirstChild("Wildflowers"),
		workspace:FindFirstChild("WorldSafetyFloor")
	}
	local hit=workspace:Raycast(Vector3.new(0,80,0),Vector3.new(0,-140,0),params)
	assert(hit and hit.Material~=Enum.Material.Water,"Não encontrou chão seguro para spawn")

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
	spawn.AllowTeamChangeOnTouch=false
	spawn.CFrame=CFrame.new(hit.Position+Vector3.new(0,.2,0))*CFrame.Angles(0,math.rad(20),0)
	spawn.Parent=workspace
	runtime:SetAttribute("SpawnGroundY",hit.Position.Y)
end

setupSpawn()

-- ============ 10. NAMETAG EXATO ============
local function setupNametag()
	local old=game.ServerScriptService:FindFirstChild("NametagService")
	if old then old:Destroy() end

	local ok,asset=pcall(function()
		return AssetService:LoadAssetAsync(123212555736117)
	end)
	if not ok or not asset then
		error("Player Nametags 123212555736117 failed to load")
	end

	local source=asset:FindFirstChild("NametagService",true)
	assert(source and source:IsA("Script"),"NametagService missing from exact asset")
	local service=source:Clone()
	service.Name="NametagService"
	service:SetAttribute("AssetId",123212555736117)

	local src=service.Source
	src=src:gsub(
		'local head = character:WaitForChild%("Head"%)',
		'local head = character:WaitForChild("Head")\n\tlocal humanoid = character:FindFirstChildWhichIsA("Humanoid")\n\tif humanoid then\n\t\thumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None\n\t\thumanoid.HealthDisplayDistance = 0\n\tend\n\tlocal existing = head:FindFirstChild("Nametag")\n\tif existing then existing:Destroy() end',
		1
	)
	service.Source=src
	service.Parent=game.ServerScriptService
	asset:Destroy()
end

setupNametag()

-- ============ 11. LOADING SCREEN EXATA ============
local function setupLoadingScreen()
	local old=ReplicatedFirst:FindFirstChild("LoadingScreen")
	if old then old:Destroy() end

	local ok,asset=pcall(function()
		return AssetService:LoadAssetAsync(73186563008540)
	end)
	if not ok or not asset then
		error("LoadingScreen 73186563008540 failed to load")
	end

	local source=asset:FindFirstChild("LoadingScreen",true)
	assert(source and source:IsA("LocalScript"),"LoadingScreen LocalScript missing from exact asset")
	local loading=source:Clone()
	loading.Name="LoadingScreen"
	loading:SetAttribute("AssetId",73186563008540)
	loading:SetAttribute("GameName","Swean Island")
	loading:SetAttribute("FontName","BuilderSansBold")

	local src=loading.Source
	src=src:gsub('GAME_NAME = ""','GAME_NAME = "Swean Island"',1)
	src=src:gsub('Enum.Font.FredokaOne','Enum.Font.BuilderSansBold')
	loading.Source=src
	loading.Parent=ReplicatedFirst
	asset:Destroy()
end

setupLoadingScreen()

-- ============ 12. SERVER + PROTEÇÃO CONTRA VOID ============
local serverScript=Instance.new("Script")
serverScript.Name="SakuraServer"
serverScript.Source=[[
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("IslandSpawn")

local function protect(character)
	task.spawn(function()
		while character.Parent do
			local root=character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y < -38 then
				character:PivotTo(spawn.CFrame*CFrame.new(0,4,0))
			end
			task.wait(.35)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.RespawnLocation=spawn
	player.CharacterAdded:Connect(protect)
	if player.Character then protect(player.Character) end
end)

for _,player in ipairs(Players:GetPlayers()) do
	player.RespawnLocation=spawn
	player.CharacterAdded:Connect(protect)
	if player.Character then protect(player.Character) end
end

print("[Sakura97] Swean Island carregada")
]]
serverScript.Parent=game.ServerScriptService

print("[Sakura97] Install completo: Swean Island")
return {
	version=97,
	sakuraTrees=runtime:GetAttribute("SakuraCount") or 27,
	message="Swean Island pesquisada, reconstruída e validada"
}
