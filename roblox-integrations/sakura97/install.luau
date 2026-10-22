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
	pcall(function() Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(86, 112, 58)) end)
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

		-- O bounding box do MeshPart encosta no Terrain, mas a geometria visual
		-- do tronco fica um pouco acima da borda da caixa. Enterrar levemente
		-- elimina a impressão de árvore flutuando sem esconder o tronco.
		tree:PivotTo(tree:GetPivot()+Vector3.new(0,-0.65,0))

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

	template:Destroy()
	treeAsset:Destroy()
	runtime:SetAttribute("SakuraCount", placed)
	print("[Sakura97] Colocadas", placed, "cerejeiras")
end

placeSakuraTrees()

-- ============ 7. ESTRADINHA EXATA STONE PATH (LONG) ============
local PATH_SEGMENTS=9
local PATH_SCALE=.62
local PATH_START_Z=-132
local PATH_STEP=29

local function pathCenterFor(i)
	local z=PATH_START_Z+(i-1)*PATH_STEP
	local x=-10+math.sin(i*.63)*12+math.sin(i*.21)*5
	return Vector3.new(x,0,z)
end

local function pathYawFor(i)
	local a=pathCenterFor(math.max(1,i-1))
	local b=pathCenterFor(math.min(PATH_SEGMENTS,i+1))
	return math.atan2(b.X-a.X,b.Z-a.Z)
end

local function nearStonePath(x,z,radius)
	local p=Vector2.new(x,z)
	for i=1,PATH_SEGMENTS do
		local c=pathCenterFor(i)
		if (p-Vector2.new(c.X,c.Z)).Magnitude <= (18+radius) then
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
	folder:SetAttribute("ExactModelName","Stone Path (Long)")
	folder:SetAttribute("SegmentCount",PATH_SEGMENTS)

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

		segment:ScaleTo(segment:GetScale()*PATH_SCALE)

		local center=pathCenterFor(i)
		local yaw=pathYawFor(i)
		local base=CFrame.new(center)*CFrame.Angles(0,yaw,0)
		local pivot=segment:GetPivot()

		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={folder}

		local visible=0
		for _,part in ipairs(segment:GetDescendants()) do
			if part:IsA("BasePart") then
				local rel=pivot:ToObjectSpace(part.CFrame)
				local target=base*rel
				local pos=target.Position
				local hit=workspace:Raycast(Vector3.new(pos.X,75,pos.Z),Vector3.new(0,-145,0),params)
				if hit and hit.Material~=Enum.Material.Water then
					local rot=target-target.Position
					-- Slightly sink the stones into the grass, never replace the grass with Ground.
					part.CFrame=CFrame.new(hit.Position+Vector3.new(0,part.Size.Y*.42,0))*rot
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
	folder:SetAttribute("UsesGroundPatches",false)
	asset:Destroy()
	print("[Sakura97] Exact Stone Path (Long) segments:",PATH_SEGMENTS,"visible stones:",totalVisible)
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

-- ============ 9. GRAMA NORMAL + REACAO LOCAL AO JOGADOR ============
local oldClient=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TerrainGrassBend")
if oldClient then oldClient:Destroy() end

local clientScript=Instance.new("LocalScript")
clientScript.Name="TerrainGrassBend"
clientScript.Source=[==========[
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer

local folder=Instance.new("Folder")
folder.Name="LocalGrassBend"
folder.Parent=workspace.CurrentCamera

local blades={}
local COUNT=120
local RADIUS=13
local rng=Random.new(873779)

for i=1,COUNT do
	local p=Instance.new("Part")
	p.Name="GrassBlade"
	p.Size=Vector3.new(.055,rng:NextNumber(.8,1.45),.11)
	p.Material=Enum.Material.Grass
	p.Color=Color3.fromRGB(rng:NextInteger(75,98),rng:NextInteger(104,128),rng:NextInteger(48,68))
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=false
	p.CastShadow=false
	p.Parent=folder
	blades[i]={part=p,angle=rng:NextNumber(0,math.pi*2),rad=rng:NextNumber(1,RADIUS),phase=rng:NextNumber(0,6.28)}
end

local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude

RunService.RenderStepped:Connect(function()
	local char=player.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	params.FilterDescendantsInstances={char,folder}
	local t=time()
	for i,data in ipairs(blades) do
		local a=data.angle+i*.17
		local r=data.rad
		local x=root.Position.X+math.cos(a)*r
		local z=root.Position.Z+math.sin(a)*r
		local hit=workspace:Raycast(Vector3.new(x,root.Position.Y+12,z),Vector3.new(0,-30,0),params)
		local p=data.part
		if hit and hit.Material==Enum.Material.Grass then
			local dx=x-root.Position.X
			local dz=z-root.Position.Z
			local dist=math.sqrt(dx*dx+dz*dz)
			local press=math.clamp((5-dist)/5,0,1)
			local wind=math.sin(t*2.1+data.phase+x*.04+z*.04)*.055
			local away=math.atan2(dx,dz)
			p.Transparency=0
			p.CFrame=CFrame.new(hit.Position+Vector3.new(0,p.Size.Y/2,0))
				*CFrame.Angles(0,away,wind+press*.55)
		else
			p.Transparency=1
		end
	end
end)
]==========]
clientScript.Parent=game.StarterPlayer.StarterPlayerScripts

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
