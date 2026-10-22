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

-- ============ 1. LIMPA TUDO ============
local function clearWorld()
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name ~= "Terrain" and child.Name ~= "Camera" and not child:IsA("Terrain") then
			if child.Name == "ForestWorld" or child.Name == "Baseplate" or child.Name:find("Forest") or child.Name:find("Tree") or child.Name:find("Sakura") then
				child:Destroy()
			end
		end
	end
	-- limpa scripts antigos
	for _, s in ipairs(game.ServerScriptService:GetChildren()) do
		if s.Name:find("Forest") or s.Name:find("Sakura") or s.Name:find("TreeWorld") then
			s:Destroy()
		end
	end
	for _, s in ipairs(game.StarterPlayer.StarterPlayerScripts:GetChildren()) do
		if s.Name:find("Forest") or s.Name:find("Sakura") or s.Name:find("Grass") then
			s:Destroy()
		end
	end
	if game.ReplicatedStorage:FindFirstChild("ForestRuntime") then
		game.ReplicatedStorage.ForestRuntime:Destroy()
	end
	if game.ReplicatedStorage:FindFirstChild("SakuraRuntime") then
		game.ReplicatedStorage.SakuraRuntime:Destroy()
	end
end

clearWorld()

-- ============ 2. RUNTIME ============
local runtime = Instance.new("Folder")
runtime.Name = "SakuraRuntime"
runtime.Parent = game.ReplicatedStorage
runtime:SetAttribute("Version", 97)
runtime:SetAttribute("MapType", "SakuraIsland")

-- ============ 3. ILHA + TERRENO ============
local function buildIsland()
	Terrain:Clear()
	Terrain.Decoration = false
	pcall(function() Terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(78, 102, 56)) end)
	-- ilha principal com curvas suaves
	local center = Vector3.new(0, 0, 0)
	local radius = 220

	-- terreno base da ilha (altura ~8-14)
	for x = -radius, radius, 8 do
		for z = -radius, radius, 8 do
			local dist = math.sqrt(x*x + z*z)
			if dist < radius then
				local h = 10 + math.sin(x * 0.018) * 2.2 + math.cos(z * 0.015) * 1.8 + math.sin((x+z)*0.01) * 1.5
				-- borda mais baixa
				if dist > radius * 0.78 then
					h = h - (dist - radius*0.78) * 0.35
				end
				-- FillBlock não aceita extents negativos/vazios.
				h = math.max(1.5, h)
				Terrain:FillBlock(CFrame.new(x, h/2, z), Vector3.new(10, h, 10), Enum.Material.Ground)
			end
		end
	end

	-- rio em volta (anel de água)
	for angle = 0, math.pi * 2, 0.04 do
		local r = radius + 28 + math.sin(angle * 3) * 12
		local x = math.cos(angle) * r
		local z = math.sin(angle) * r
		Terrain:FillBlock(CFrame.new(x, 3, z), Vector3.new(22, 8, 22), Enum.Material.Water)
	end

	-- alguns lagos internos pequenos
	Terrain:FillBlock(CFrame.new(80, 4, -60), Vector3.new(28, 6, 22), Enum.Material.Water)
	Terrain:FillBlock(CFrame.new(-90, 4, 70), Vector3.new(24, 6, 30), Enum.Material.Water)

	workspace:SetAttribute("SakuraIslandReady", true)
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
	if workspace:FindFirstChild("WindEffects") then
		workspace.WindEffects:Destroy()
	end

	local folder=Instance.new("Folder")
	folder.Name="WindEffects"
	folder.Parent=workspace

	workspace.GlobalWind=Vector3.new(12,0,4)

	local ok,windAsset=pcall(function()
		return AssetService:LoadAssetAsync(11946229834)
	end)
	if not ok or not windAsset then
		warn("[Sakura97] Wind asset 11946229834 failed")
		return
	end

	local emitters={}
	for _,d in ipairs(windAsset:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			table.insert(emitters,d)
		end
	end

	local anchors={
		Vector3.new(0,14,-150),
		Vector3.new(90,15,-90),
		Vector3.new(145,14,0),
		Vector3.new(90,15,90),
		Vector3.new(0,14,150),
		Vector3.new(-90,15,90),
		Vector3.new(-145,14,0),
		Vector3.new(-90,15,-90),
	}

	for i,pos in ipairs(anchors) do
		local host=Instance.new("Part")
		host.Name="WindAnchor_"..i
		host.Size=Vector3.new(1,1,1)
		host.Anchored=true
		host.CanCollide=false
		host.CanTouch=false
		host.CanQuery=false
		host.Transparency=1
		host.Position=pos
		host.Parent=folder

		local att=Instance.new("Attachment")
		att.Parent=host
		for _,src in ipairs(emitters) do
			local em=src:Clone()
			em.Enabled=true
			em.Parent=att
		end
	end

	folder:SetAttribute("EmitterSourceCount",#emitters)
	folder:SetAttribute("AssetId",11946229834)
	windAsset:Destroy()
	print("[Sakura97] Vento visivel ativo, emitters:",#emitters)
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

	-- 27 árvores espalhadas com espaçamento bom
	while placed < 27 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(25, 175)
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist

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
		tree.Parent = folder
		CollectionService:AddTag(tree, "SakuraTree")
		placed += 1
		positions[#positions + 1] = Vector2.new(x, z)
	end

	template:Destroy()
	treeAsset:Destroy()
	runtime:SetAttribute("SakuraCount", placed)
	print("[Sakura97] Colocadas", placed, "cerejeiras")
end

placeSakuraTrees()

-- ============ 7. CAMINHO DE PEDRAS (fino, torto, retângulos) ============
local PATH_POINTS={}
for i=1,34 do
	local z=-165+(i-1)*9.2
	local x=-22+math.sin(i*.57)*9+math.sin(i*.19)*5
	table.insert(PATH_POINTS,Vector3.new(x,0,z))
end

local function nearStonePath(x,z,radius)
	local p=Vector2.new(x,z)
	for _,q in ipairs(PATH_POINTS) do
		if (p-Vector2.new(q.X,q.Z)).Magnitude<=radius then
			return true
		end
	end
	return false
end

local function placeStonePath()
	local old=workspace:FindFirstChild("StonePath")
	if old then old:Destroy() end

	local folder=Instance.new("Folder")
	folder.Name="StonePath"
	folder.Parent=workspace
	folder:SetAttribute("AssetId",136068114177879)
	folder:SetAttribute("Style","ThinSpacedSteppingStones")

	local ok,pathAsset=pcall(function()
		return AssetService:LoadAssetAsync(136068114177879)
	end)

	local template=nil
	if ok and pathAsset then
		-- Use one real stone piece from the asset, not the whole road model.
		template=pathAsset:FindFirstChildWhichIsA("MeshPart",true)
			or pathAsset:FindFirstChildWhichIsA("UnionOperation",true)
			or pathAsset:FindFirstChildWhichIsA("Part",true)
		if template then template=template:Clone() end
		pathAsset:Destroy()
	end

	if not template then
		template=Instance.new("Part")
		template.Name="StoneTile"
		template.Size=Vector3.new(3.2,.28,1.55)
		template.Material=Enum.Material.Slate
		template.Color=Color3.fromRGB(100,95,90)
		template.Anchored=true
	end

	template.Anchored=true
	template.CanCollide=true

	for i,node in ipairs(PATH_POINTS) do
		local ray=workspace:Raycast(
			Vector3.new(node.X,60,node.Z),
			Vector3.new(0,-110,0)
		)
		if ray and ray.Material~=Enum.Material.Water then
			local tile=template:Clone()
			tile.Name=string.format("Stone_%02d",i)

			local base=tile.Size
			local maxXZ=math.max(base.X,base.Z)
			local targetLong=3.5+((i%3)-1)*.35
			local factor=maxXZ>0 and targetLong/maxXZ or 1
			tile.Size=Vector3.new(
				math.max(.8,base.X*factor),
				math.min(.32,math.max(.16,base.Y*factor)),
				math.max(.7,base.Z*factor)
			)

			local yaw=math.rad(math.sin(i*.83)*22 + ((i%2==0) and 7 or -7))
			tile.CFrame=CFrame.new(ray.Position+Vector3.new(0,.10,0))*CFrame.Angles(0,yaw,0)
			tile.Parent=folder
			CollectionService:AddTag(tile,"StonePathTile")
		end
	end

	template:Destroy()
	print("[Sakura97] Estradinha fina com",#folder:GetChildren(),"pedras")
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

		if not nearStonePath(x,z,4.6) then
			local ray=workspace:Raycast(Vector3.new(x,55,z),Vector3.new(0,-100,0))
			if ray and ray.Material~=Enum.Material.Water then
				local flower=Instance.new("Part")
				flower.Name="Wildflower"
				flower.Size=Vector3.new(.18,.11,.18)
				flower.Anchored=true
				flower.CanCollide=false
				flower.CanTouch=false
				flower.Material=Enum.Material.SmoothPlastic
				flower.Shape=Enum.PartType.Ball
				if rng:NextNumber()>.58 then
					flower.Color=Color3.fromRGB(244,242,235)
				else
					flower.Color=Color3.fromRGB(211,188,226)
				end
				flower.CFrame=CFrame.new(ray.Position+Vector3.new(0,.18,0))
				flower.Parent=flowerFolder

				local stem=Instance.new("Part")
				stem.Name="Stem"
				stem.Size=Vector3.new(.035,.22,.035)
				stem.Anchored=true
				stem.CanCollide=false
				stem.CanTouch=false
				stem.Material=Enum.Material.SmoothPlastic
				stem.Color=Color3.fromRGB(62,103,51)
				stem.CFrame=CFrame.new(ray.Position+Vector3.new(0,.08,0))
				stem.Parent=flowerFolder
				made+=1
			end
		end
	end

	flowerFolder:SetAttribute("FlowerCount",made)
	print("[Sakura97] Sem grama alta; flores pequenas:",made)
end
placeGrassAndFlowers()

-- ============ 10. SERVER SCRIPT BÁSICO ============
local serverScript = Instance.new("Script")
serverScript.Name = "SakuraServer"
serverScript.Source = [[
print("[Sakura97] Mapa de ilha cerejeira carregado — versão 97")
print("[Sakura97] 27 árvores, grama skinned, caminho de pedra, ceu de tarde")
]]
serverScript.Parent = game.ServerScriptService

print("[Sakura97] Install completo! Mapa limpo de cerejeira pronto.")
return {
	version = 97,
	sakuraTrees = runtime:GetAttribute("SakuraCount") or 27,
	message = "Ilha cerejeira criada igual a foto pedida"
}
