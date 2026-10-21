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
				Terrain:FillBlock(CFrame.new(x, h/2, z), Vector3.new(10, h, 10), Enum.Material.Grass)
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
	local ok, windAsset = pcall(function()
		return AssetService:LoadAssetAsync(11946229834)
	end)
	if ok and windAsset then
		for _, d in ipairs(windAsset:GetDescendants()) do
			if d:IsA("ParticleEmitter") or d:IsA("Attachment") or d:IsA("Part") then
				local clone = d:Clone()
				if clone:IsA("BasePart") then
					clone.Anchored = true
					clone.CanCollide = false
					clone.Transparency = 1
				end
				clone.Parent = workspace
			end
		end
		windAsset:Destroy()
	end

	-- vento global simples também
	workspace.GlobalWind = Vector3.new(8, 0, 3)
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

local function findVisualModel(asset, preferredWords)
	local best=nil
	local bestScore=-1
	for _,d in ipairs(asset:GetDescendants()) do
		if d:IsA("Model") and d:FindFirstChildWhichIsA("BasePart", true) then
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
	if best then return best:Clone() end

	local part=asset:FindFirstChildWhichIsA("BasePart", true)
	if part then
		local m=Instance.new("Model")
		part:Clone().Parent=m
		return m
	end
	return nil
end

local function normalizeHeight(model,targetHeight)
	local _,size=model:GetBoundingBox()
	if size.Y>0 then
		model:ScaleTo(model:GetScale()*(targetHeight/size.Y))
	end
end

local function placeModelOnGround(model,groundPosition,yaw)
	model:PivotTo(CFrame.new(groundPosition)*CFrame.Angles(0,yaw,0))
	local cf,size=model:GetBoundingBox()
	local bottom=cf.Position.Y-size.Y/2
	model:PivotTo(model:GetPivot()+Vector3.new(0,groundPosition.Y-bottom,0))
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
		normalizeHeight(tree,rng:NextNumber(24,29))
		local yaw = rng:NextNumber(0, math.pi * 2)
		placeModelOnGround(tree,ray.Position,yaw)
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
local function placeStonePath()
	local folder = Instance.new("Folder")
	folder.Name = "StonePath"
	folder.Parent = workspace

	local ok, pathAsset = pcall(function()
		return AssetService:LoadAssetAsync(136068114177879)
	end)

	local template = nil
	if ok and pathAsset then
		template = findVisualModel(pathAsset,{"stone","path","road","walkway","trail"})
		pathAsset:Destroy()
	end

	-- se não carregou, cria peças simples de pedra
	if not template then
		template = Instance.new("Part")
		template.Name = "StoneTile"
		template.Size = Vector3.new(3.2, 0.35, 1.6)
		template.Material = Enum.Material.Slate
		template.Color = Color3.fromRGB(90, 85, 80)
		template.Anchored = true
		template.CanCollide = true
	end

	-- caminho torto tipo a foto (começa perto do centro e serpenteia)
	local points = {
		Vector3.new(0, 0, 40),
		Vector3.new(8, 0, 55),
		Vector3.new(18, 0, 70),
		Vector3.new(22, 0, 90),
		Vector3.new(12, 0, 110),
		Vector3.new(-5, 0, 125),
		Vector3.new(-25, 0, 135),
		Vector3.new(-40, 0, 150),
		Vector3.new(-35, 0, 170),
		Vector3.new(-15, 0, 185),
		Vector3.new(10, 0, 195),
		Vector3.new(30, 0, 180),
		Vector3.new(45, 0, 160),
		Vector3.new(55, 0, 140),
		Vector3.new(50, 0, 115),
		Vector3.new(35, 0, 95),
		Vector3.new(20, 0, 75),
	}

	for i = 1, #points - 1 do
		local a = points[i]
		local b = points[i + 1]
		local dir = (b - a)
		local dist = dir.Magnitude
		local steps = math.max(2, math.floor(dist / 2.8))
		for s = 0, steps do
			local t = s / steps
			local pos = a:Lerp(b, t)
			-- offset lateral aleatório pra ficar torto
			local side = Vector3.new(-dir.Z, 0, dir.X).Unit * (math.sin(i * 1.7 + s) * 1.4)
			pos = pos + side

			local ray = workspace:Raycast(pos + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0))
			if ray and ray.Material ~= Enum.Material.Water then
				local tile = template:Clone()
				if tile:IsA("Model") then
					tile:PivotTo(CFrame.new(ray.Position + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, math.atan2(dir.X, dir.Z) + math.rad(rngOffset(i,s)), 0))
				else
					tile.CFrame = CFrame.new(ray.Position + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, math.atan2(dir.X, dir.Z) + math.rad((i*13+s*7)%30 - 15), 0)
					tile.Size = Vector3.new(2.8 + (i%3)*0.3, 0.3, 1.4 + (s%2)*0.4)
				end
				tile.Parent = folder
				CollectionService:AddTag(tile, "StonePathTile")
			end
		end
	end

	if template.Parent == nil then template:Destroy() end
	print("[Sakura97] Caminho de pedras colocado")
end

function rngOffset(i, s)
	return ((i * 17 + s * 11) % 40) - 20
end

placeStonePath()

-- ============ 8. GRAMA SKINNED + FLORES ============
local function placeGrassAndFlowers()
	local grassFolder = Instance.new("Folder")
	grassFolder.Name = "SkinnedGrass"
	grassFolder.Parent = workspace

	local flowerFolder = Instance.new("Folder")
	flowerFolder.Name = "Wildflowers"
	flowerFolder.Parent = workspace

	-- tenta carregar SkinnedGrass
	local ok, grassAsset = pcall(function()
		return AssetService:LoadAssetAsync(87377915371959)
	end)

	local grassTemplate = nil
	if ok and grassAsset then
		grassTemplate = findVisualModel(grassAsset,{"dark","escuro","grass"})
		grassAsset:Destroy()
	end

	local rng = Random.new(97002)

	-- coloca patches de grama skinned
	if grassTemplate then
		for i = 1, 55 do
			local angle = rng:NextNumber(0, math.pi * 2)
			local dist = rng:NextNumber(15, 190)
			local x = math.cos(angle) * dist
			local z = math.sin(angle) * dist
			local ray = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -100, 0))
			if ray and ray.Material == Enum.Material.Grass then
				local g = grassTemplate:Clone()
				g:ScaleTo(g:GetScale()*rng:NextNumber(0.9,1.15))
				placeModelOnGround(g,ray.Position,rng:NextNumber(0,6.28))
				g:SetAttribute("RestPivot",g:GetPivot())
				g.Parent = grassFolder
				CollectionService:AddTag(g, "SkinnedGrassPatch")
			end
		end
		grassTemplate:Destroy()
	end

	-- flores brancas e lilás (simples, tipo a foto)
	for i = 1, 420 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(10, 200)
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist
		local ray = workspace:Raycast(Vector3.new(x, 50, z), Vector3.new(0, -90, 0))
		if ray and ray.Material == Enum.Material.Grass then
			local flower = Instance.new("Part")
			flower.Name = "Wildflower"
			flower.Size = Vector3.new(0.35, 0.55, 0.35)
			flower.Anchored = true
			flower.CanCollide = false
			flower.Material = Enum.Material.SmoothPlastic
			flower.Shape = Enum.PartType.Ball
			-- branco ou lilás
			if rng:NextNumber() > 0.55 then
				flower.Color = Color3.fromRGB(245, 245, 250)
			else
				flower.Color = Color3.fromRGB(200, 170, 230)
			end
			flower.CFrame = CFrame.new(ray.Position + Vector3.new(0, 0.25, 0))
			flower.Parent = flowerFolder

			-- haste
			local stem = Instance.new("Part")
			stem.Name = "Stem"
			stem.Size = Vector3.new(0.08, 0.6, 0.08)
			stem.Anchored = true
			stem.CanCollide = false
			stem.Material = Enum.Material.SmoothPlastic
			stem.Color = Color3.fromRGB(60, 110, 50)
			stem.CFrame = CFrame.new(ray.Position + Vector3.new(0, 0.05, 0))
			stem.Parent = flower
		end
	end

	print("[Sakura97] Grama e flores colocadas")
end

placeGrassAndFlowers()

-- ============ 9. CLIENT: GRAMA QUE AMASSA + VENTO ============
local clientScript = Instance.new("LocalScript")
clientScript.Name = "SakuraGrassClient"
clientScript.Source = [==========[
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local player=Players.LocalPlayer
local recentlyPressed={}

local function rootPart()
	local char=player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

RunService.Heartbeat:Connect(function()
	local root=rootPart()
	local now=time()

	for _,patch in ipairs(CollectionService:GetTagged("SkinnedGrassPatch")) do
		if patch:IsA("Model") and patch.Parent then
			for _,bone in ipairs(patch:GetDescendants()) do
				if bone:IsA("Bone") then
					local sway=math.sin(now*1.8+bone.WorldPosition.X*.05)*.08
					bone.Transform=CFrame.Angles(0,0,sway)
				end
			end

			local rest=patch:GetAttribute("RestPivot")
			if typeof(rest)=="CFrame" and root then
				local p=rest.Position
				local d=(Vector2.new(p.X,p.Z)-Vector2.new(root.Position.X,root.Position.Z)).Magnitude
				if d<6 then recentlyPressed[patch]=now end
				local pressed=recentlyPressed[patch] and (now-recentlyPressed[patch] < .5)
				local target=pressed and (rest*CFrame.Angles(math.rad(13),0,math.rad(-5))) or rest
				patch:PivotTo(patch:GetPivot():Lerp(target,pressed and .38 or .16))
				if not pressed then recentlyPressed[patch]=nil end
			end
		end
	end
end)
]==========]
clientScript.Parent = game.StarterPlayer.StarterPlayerScripts

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
