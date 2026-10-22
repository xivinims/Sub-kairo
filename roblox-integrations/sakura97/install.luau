-- Swean Island v100 — clean Mirkwood rebuild
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local AssetService=game:GetService("AssetService")
local CollectionService=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain
local StarterPlayer=game:GetService("StarterPlayer")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")

local MIRKWOOD_ID=12489980589
local WIND_ID=11946229834
local HALLOWEEN_ID=12489961338

local function loadAsset(id)
	local ok,res=pcall(AssetService.LoadAssetAsync,AssetService,id)
	if not ok or not res then error("Asset "..id.." failed: "..tostring(res)) end
	return res
end

-- APAGA A VERSÃO ATUAL INTEIRA
for _,child in ipairs(workspace:GetChildren()) do
	if child~=Terrain and not child:IsA("Camera") then child:Destroy() end
end
Terrain:Clear()

for _,container in ipairs({
	ServerScriptService,
	StarterPlayer.StarterPlayerScripts,
	ReplicatedFirst,
	game:GetService("StarterGui")
}) do
	for _,child in ipairs(container:GetChildren()) do child:Destroy() end
end

for _,child in ipairs(ReplicatedStorage:GetChildren()) do
	if child.Name=="SakuraRuntime" or child.Name=="ForestRuntime" or child.Name=="SweanRuntime" then
		child:Destroy()
	end
end

for _,child in ipairs(Lighting:GetChildren()) do child:Destroy() end

local runtime=Instance.new("Folder")
runtime.Name="SweanRuntime"
runtime.Parent=ReplicatedStorage
runtime:SetAttribute("Version",100)
runtime:SetAttribute("MapAssetId",MIRKWOOD_ID)
runtime:SetAttribute("MapName","Mirkwood")
runtime:SetAttribute("Theme","MirkwoodWindPumpkinsOnly")

pcall(function()
	workspace.StreamingEnabled=true
	workspace.StreamingMinRadius=128
	workspace.StreamingTargetRadius=420
end)

workspace.FallenPartsDestroyHeight=-350

-- MIKRWOOD EXATO
local mapAsset=loadAsset(MIRKWOOD_ID)
local source=mapAsset:FindFirstChild("Mirkwood",true)
assert(source and source:IsA("Model"),"Mirkwood model missing")

local map=source:Clone()
map.Name="Mirkwood"
map:SetAttribute("AssetId",MIRKWOOD_ID)
map.Parent=workspace

local partCount=0
local forestCount=0
local windFoliage=0

for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("LuaSourceContainer") then
		d:Destroy()
	elseif d:IsA("BasePart") then
		partCount+=1
		d.Anchored=true
		d.CanTouch=false
	end
end
assert(partCount==172,"Mirkwood part count changed: "..tostring(partCount))

-- Centraliza o asset inteiro sem deformar nem reescalar.
local cf,size=map:GetBoundingBox()
local delta=Vector3.new(-cf.Position.X,size.Y/2-cf.Position.Y,-cf.Position.Z)
map:PivotTo(map:GetPivot()+delta)

-- Fog é visual, nunca chão/colisão.
for _,m in ipairs(map:GetDescendants()) do
	if m:IsA("Model") and m.Name=="Fog" then
		for _,d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanCollide=false
				d.CanTouch=false
				d.CanQuery=false
			end
		end
	end
end

-- Marca somente a folhagem dos modelos Forrest para o WindShake.
for _,m in ipairs(map:GetDescendants()) do
	if m:IsA("Model") and m.Name=="Forrest" then
		forestCount+=1
		for _,d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") and d.Material~=Enum.Material.Wood and d.Material~=Enum.Material.WoodPlanks then
				CollectionService:AddTag(d,"WindShake")
				d:SetAttribute("WindPower",.42)
				d:SetAttribute("WindSpeed",16)
				windFoliage+=1
			end
		end
	end
end

runtime:SetAttribute("MirkwoodParts",partCount)
runtime:SetAttribute("ForestModels",forestCount)
runtime:SetAttribute("WindFoliageParts",windFoliage)
runtime:SetAttribute("MapSizeX",size.X)
runtime:SetAttribute("MapSizeY",size.Y)
runtime:SetAttribute("MapSizeZ",size.Z)
mapAsset:Destroy()

-- ILUMINAÇÃO LIMPA E SOMBRIA, SEM HERDAR NADA DO MAPA ANTIGO
Lighting.ClockTime=16.5
Lighting.Brightness=2
Lighting.ExposureCompensation=-.08
Lighting.Ambient=Color3.fromRGB(82,88,78)
Lighting.OutdoorAmbient=Color3.fromRGB(115,119,105)
Lighting.GlobalShadows=true
Lighting.EnvironmentDiffuseScale=.45
Lighting.EnvironmentSpecularScale=.35

local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="MirkwoodAtmosphere"
atmosphere.Density=.28
atmosphere.Offset=.08
atmosphere.Color=Color3.fromRGB(179,190,169)
atmosphere.Decay=Color3.fromRGB(88,93,80)
atmosphere.Haze=1.35
atmosphere.Glare=.02
atmosphere.Parent=Lighting

local cc=Instance.new("ColorCorrectionEffect")
cc.Name="MirkwoodColor"
cc.Brightness=-.02
cc.Contrast=.08
cc.Saturation=-.08
cc.TintColor=Color3.fromRGB(222,228,211)
cc.Parent=Lighting

-- VENTO EXATO
workspace.GlobalWind=Vector3.new(15,0,5)

local windAsset=loadAsset(WIND_ID)
local windController=windAsset:FindFirstChild("WindController",true)
assert(windController and windController:IsA("LocalScript"),"WindController missing")
assert(windController:FindFirstChild("WindLines"),"WindLines missing")
assert(windController:FindFirstChild("WindShake"),"WindShake missing")

local windClone=windController:Clone()
windClone.Name="WindController"
windClone:SetAttribute("AssetId",WIND_ID)
windClone:SetAttribute("ExactCreatorStoreController",true)
windClone.Parent=StarterPlayer.StarterPlayerScripts
windAsset:Destroy()

-- ABÓBORAS REAIS DO EERIE TOMB, SÓ ELAS
local halloweenAsset=loadAsset(HALLOWEEN_ID)
local pumpkinTemplates={}
for _,d in ipairs(halloweenAsset:GetDescendants()) do
	if d:IsA("BasePart") and d.Name=="Pumpkin" then
		local p=d:Clone()
		p.Anchored=true
		p.CanCollide=false
		p.CanTouch=false
		p.CanQuery=false
		table.insert(pumpkinTemplates,p)
	end
end
assert(#pumpkinTemplates>=1,"Pumpkins missing from Eerie Tomb")
halloweenAsset:Destroy()

local pumpkins=Instance.new("Folder")
pumpkins.Name="PumpkinDecor"
pumpkins:SetAttribute("AssetId",HALLOWEEN_ID)
pumpkins:SetAttribute("OnlyPumpkins",true)
pumpkins:SetAttribute("ClusterCount",8)
pumpkins.Parent=workspace

local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances={map}
rayParams.IgnoreWater=true

local rng=Random.new(100124)
local _,mapSize=map:GetBoundingBox()
local safeCenters={}

local function safeGroundAt(x,z)
	local hit=workspace:Raycast(
		Vector3.new(x,mapSize.Y+180,z),
		Vector3.new(0,-(mapSize.Y+400),0),
		rayParams
	)
	if not hit then return nil end
	if hit.Normal.Y<.72 then return nil end
	local n=hit.Instance.Name:lower()
	if n:find("pillar",1,true) or n:find("fog",1,true) then return nil end
	return hit.Position
end

local function pickClusterCenter()
	for _=1,900 do
		local x=rng:NextNumber(-mapSize.X*.39,mapSize.X*.39)
		local z=rng:NextNumber(-mapSize.Z*.39,mapSize.Z*.39)
		local p=safeGroundAt(x,z)
		if p then
			local far=true
			for _,q in ipairs(safeCenters) do
				if (Vector2.new(p.X,p.Z)-Vector2.new(q.X,q.Z)).Magnitude<170 then
					far=false
					break
				end
			end
			if far then return p end
		end
	end
end

local pumpkinCount=0
local offsets={
	Vector2.new(-3.8,-2.2),
	Vector2.new(0,0),
	Vector2.new(3.4,-1.8)
}

for cluster=1,8 do
	local center=pickClusterCenter()
	if center then
		table.insert(safeCenters,center)
		local folder=Instance.new("Folder")
		folder.Name=string.format("PumpkinCluster_%02d",cluster)
		folder.Parent=pumpkins

		for j,off in ipairs(offsets) do
			local ground=safeGroundAt(center.X+off.X,center.Z+off.Y)
			if ground then
				local src=pumpkinTemplates[((pumpkinCount)%#pumpkinTemplates)+1]
				local p=src:Clone()
				p.Name=string.format("Pumpkin_%02d",pumpkinCount+1)
				local scale=.58+rng:NextNumber(-.08,.12)
				p.Size=p.Size*scale
				p.CFrame=CFrame.new(ground+Vector3.new(0,p.Size.Y*.48,0))
					*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0)
				p.Parent=folder
				pumpkinCount+=1
			end
		end
	end
end

for _,p in ipairs(pumpkinTemplates) do p:Destroy() end

assert(#safeCenters==8,"Could not place 8 pumpkin clusters: "..tostring(#safeCenters))
assert(pumpkinCount>=20,"Too few pumpkins: "..tostring(pumpkinCount))
pumpkins:SetAttribute("PumpkinCount",pumpkinCount)
runtime:SetAttribute("PumpkinCount",pumpkinCount)

-- SPAWN MÍNIMO EM CHÃO SÓLIDO DO MIKRWOOD
local spawnPos=nil
for radius=0,600,60 do
	for step=1,20 do
		local a=(step/20)*math.pi*2
		local p=safeGroundAt(math.cos(a)*radius,math.sin(a)*radius)
		if p then spawnPos=p break end
	end
	if spawnPos then break end
end
assert(spawnPos,"No safe spawn point found")

local spawn=Instance.new("SpawnLocation")
spawn.Name="MirkwoodSpawn"
spawn.Size=Vector3.new(8,.5,8)
spawn.Anchored=true
spawn.CanCollide=false
spawn.CanTouch=false
spawn.Transparency=1
spawn.Neutral=true
spawn.Enabled=true
spawn.Duration=0
spawn.CFrame=CFrame.new(spawnPos+Vector3.new(0,.25,0))
spawn.Parent=workspace

-- Proteção simples contra void, sem trazer sistemas antigos.
local server=Instance.new("Script")
server.Name="MirkwoodServer"
server.Source=[[
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("MirkwoodSpawn")
local function protect(character)
	task.spawn(function()
		while character.Parent do
			local root=character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y<-300 then
				character:PivotTo(spawn.CFrame*CFrame.new(0,4,0))
			end
			task.wait(.5)
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

print("[Swean] Clean Mirkwood rebuild complete")
return{
	version=100,
	map="Mirkwood",
	parts=partCount,
	forests=forestCount,
	windFoliage=windFoliage,
	pumpkins=pumpkinCount,
	pumpkinClusters=#safeCenters
}
