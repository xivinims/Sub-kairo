assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local runtime=game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
assert(runtime and runtime:GetAttribute("Version")==97,"Runtime Sakura97 invalido")

local PATH_SEGMENTS=20
local PATH_RADIUS_X=108
local PATH_RADIUS_Z=78
local function pathPointAt(t)
	local a=t*math.pi*2
	local rx=PATH_RADIUS_X+math.sin(a*3)*4+math.sin(a*7)*1.8
	local rz=PATH_RADIUS_Z+math.cos(a*4)*3
	return Vector3.new(math.cos(a)*rx,0,math.sin(a)*rz)
end
local function distanceToPath(x,z)
	local p=Vector2.new(x,z)
	local best=math.huge
	for j=0,95 do
		local q=pathPointAt(j/96)
		best=math.min(best,(p-Vector2.new(q.X,q.Z)).Magnitude)
	end
	return best
end

local trees=workspace:FindFirstChild("SakuraTrees")
assert(trees and #trees:GetChildren()==27,"Esperava 27 cerejeiras")

local petalEmitters=0
local windTagged=0
local minTreePath=math.huge
local maxTreeOffset=-math.huge
local minTreeOffset=math.huge

local treeParams=RaycastParams.new()
treeParams.FilterType=Enum.RaycastFilterType.Exclude
treeParams.FilterDescendantsInstances={
	trees,
	workspace:FindFirstChild("StonePath"),
	workspace:FindFirstChild("Wildflowers"),
	workspace:FindFirstChild("WorldSafetyFloor")
}

for _,tree in ipairs(trees:GetChildren()) do
	local trunk=nil
	for _,d in ipairs(tree:GetDescendants()) do
		if d:IsA("BasePart") and d.Name~="Leaves" then trunk=d break end
	end
	assert(trunk,"Tronco ausente em cerejeira")
	minTreePath=math.min(minTreePath,distanceToPath(trunk.Position.X,trunk.Position.Z))

	local minY=math.huge
	for _,sx in ipairs({-1,1}) do
		for _,sy in ipairs({-1,1}) do
			for _,sz in ipairs({-1,1}) do
				local p=trunk.CFrame:PointToWorldSpace(Vector3.new(trunk.Size.X*.5*sx,trunk.Size.Y*.5*sy,trunk.Size.Z*.5*sz))
				minY=math.min(minY,p.Y)
			end
		end
	end
	local hit=workspace:Raycast(Vector3.new(trunk.Position.X,80,trunk.Position.Z),Vector3.new(0,-150,0),treeParams)
	assert(hit,"Sem Terrain sob cerejeira")
	local offset=minY-hit.Position.Y
	maxTreeOffset=math.max(maxTreeOffset,offset)
	minTreeOffset=math.min(minTreeOffset,offset)

	for _,leaf in ipairs(tree:GetDescendants()) do
		if leaf:IsA("BasePart") and leaf.Name=="Leaves" then
			if CollectionService:HasTag(leaf,"WindShake") then windTagged+=1 end
			local petals=leaf:FindFirstChild("SakuraPetals")
			if petals and petals:IsA("ParticleEmitter") then
				assert(petals.WindAffectsDrag and petals.Drag>0,"Petalas nao seguem vento")
				petalEmitters+=1
			end
		end
	end
end

assert(maxTreeOffset<=-.8,"Cerejeira ainda alta/flutuando: "..tostring(maxTreeOffset))
assert(minTreeOffset>=-1.75,"Cerejeira enterrada demais: "..tostring(minTreeOffset))
assert(minTreePath>=18,"Cerejeira perto demais da estrada: "..tostring(minTreePath))
assert(windTagged>=27,"WindShake faltando nas folhas")
assert(petalEmitters>=27,"Petalas faltando")

local path=workspace:FindFirstChild("StonePath")
assert(path and path:GetAttribute("AssetId")==136068114177879,"Stone Path asset errado")
assert(path:GetAttribute("ExactModelName")=="Stone Path (Long)","Modelo Stone Path (Long) nao usado")
assert(path:GetAttribute("SegmentCount")==20,"Estrada nao tem 20 trechos")
assert(path:GetAttribute("Loop")==true,"Estrada nao e circular/loop")
assert(path:GetAttribute("NoGrassMaterial")=="LeafyGrass","Faixa sem grama nao configurada")

local segmentCount=0
local stoneParts=0
local visibleStoneParts=0
for _,segment in ipairs(path:GetChildren()) do
	if segment:IsA("Model") and string.find(segment.Name,"Stone Path (Long)",1,true) then
		segmentCount+=1
		local parts=0
		for _,d in ipairs(segment:GetDescendants()) do
			if d:IsA("BasePart") then
				parts+=1
				stoneParts+=1
				if d.Transparency<.95 then visibleStoneParts+=1 end
			end
		end
		assert(parts==38,"Trecho alterou as 38 pedras originais: "..tostring(parts))
	end
end
assert(segmentCount==20,"Quantidade de trechos incorreta: "..tostring(segmentCount))
assert(stoneParts==760,"Esperava 760 pedras: "..tostring(stoneParts))
assert(visibleStoneParts>=700,"Poucas pedras visiveis: "..tostring(visibleStoneParts))

-- Confirma faixa sem grama animada em vários pontos do loop.
local surfaceParams=RaycastParams.new()
surfaceParams.FilterType=Enum.RaycastFilterType.Exclude
surfaceParams.FilterDescendantsInstances={
	path,trees,workspace:FindFirstChild("Wildflowers"),workspace:FindFirstChild("WorldSafetyFloor")
}
local leafySamples=0
for i=1,20 do
	local q=pathPointAt((i-1)/20)
	local hit=workspace:Raycast(Vector3.new(q.X,60,q.Z),Vector3.new(0,-100,0),surfaceParams)
	if hit and hit.Material==Enum.Material.LeafyGrass then leafySamples+=1 end
end
assert(leafySamples>=17,"Corredor ainda tem Grass animada: "..tostring(leafySamples).."/20")

-- Oceano contínuo e fundo sólido.
local oceanHit=workspace:Raycast(Vector3.new(600,20,0),Vector3.new(0,-80,0))
assert(oceanHit and oceanHit.Material==Enum.Material.Water,"Oceano nao cobre a area externa")
local seabedParams=RaycastParams.new()
seabedParams.IgnoreWater=true
seabedParams.FilterType=Enum.RaycastFilterType.Exclude
seabedParams.FilterDescendantsInstances={workspace:FindFirstChild("WorldSafetyFloor")}
local seabed=workspace:Raycast(Vector3.new(600,20,0),Vector3.new(0,-100,0),seabedParams)
assert(seabed and seabed.Material==Enum.Material.Sand,"Fundo do mar ausente")
assert(runtime:GetAttribute("OceanSize")==1800,"Tamanho do oceano incorreto")
local safety=workspace:FindFirstChild("WorldSafetyFloor")
assert(safety and safety:IsA("BasePart") and safety.CanCollide,"Piso anti-void ausente")

-- Spawn com a base encostada no terreno.
local spawn=workspace:FindFirstChild("IslandSpawn")
assert(spawn and spawn:IsA("SpawnLocation"),"IslandSpawn ausente")
assert(spawn.Enabled and spawn.Neutral,"IslandSpawn desativado")
local spawnParams=RaycastParams.new()
spawnParams.FilterType=Enum.RaycastFilterType.Exclude
spawnParams.FilterDescendantsInstances={spawn,path,trees,workspace:FindFirstChild("Wildflowers"),safety}
local spawnGround=workspace:Raycast(spawn.Position+Vector3.new(0,8,0),Vector3.new(0,-20,0),spawnParams)
assert(spawnGround,"Chao do spawn nao encontrado")
local spawnGap=(spawn.Position.Y-spawn.Size.Y*.5)-spawnGround.Position.Y
assert(math.abs(spawnGap)<=.3,"Spawn suspenso do chao: "..tostring(spawnGap))

-- A grama falsa que seguia o jogador deve ter sumido.
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TerrainGrassBend"),"TerrainGrassBend ainda existe")

-- Vento exato continua instalado.
local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:IsA("LocalScript"),"WindController ausente")
assert(wind:GetAttribute("AssetId")==11946229834,"Wind asset incorreto")
assert(wind:FindFirstChild("WindLines") and wind:FindFirstChild("WindShake"),"Modulos de vento ausentes")
assert(workspace.GlobalWind.Magnitude>=10,"GlobalWind fraco")

-- Nametag exato e nome padrao escondido pelo servico.
local nametag=game.ServerScriptService:FindFirstChild("NametagService")
assert(nametag and nametag:IsA("Script"),"NametagService ausente")
assert(nametag:GetAttribute("AssetId")==123212555736117,"Nametag asset incorreto")
assert(nametag:FindFirstChild("Nametag") and nametag.Nametag:IsA("BillboardGui"),"BillboardGui do Nametag ausente")
assert(string.find(nametag.Source,"HumanoidDisplayDistanceType.None",1,true),"Nametag nao esconde o nome padrao")

-- LoadingScreen exata em ReplicatedFirst, customizada.
local loading=ReplicatedFirst:FindFirstChild("LoadingScreen")
assert(loading and loading:IsA("LocalScript"),"LoadingScreen ausente de ReplicatedFirst")
assert(loading:GetAttribute("AssetId")==73186563008540,"LoadingScreen asset incorreto")
assert(loading:GetAttribute("GameName")=="Swean Island","Nome da LoadingScreen errado")
assert(loading:GetAttribute("FontName")=="BuilderSansBold","Fonte da LoadingScreen errada")
assert(string.find(loading.Source,"Swean Island",1,true),"Swean Island nao esta no script")
assert(string.find(loading.Source,"BuilderSansBold",1,true),"BuilderSansBold nao esta no script")

local flowers=workspace:FindFirstChild("Wildflowers")
assert(flowers and (flowers:GetAttribute("FlowerCount") or 0)>=180,"Flores insuficientes")

local Lighting=game:GetService("Lighting")
assert(Lighting.ClockTime>16 and Lighting.ClockTime<18.5,"Nao esta de tarde")

return {
	ok=true,
	trees=#trees:GetChildren(),
	maxTreeOffset=maxTreeOffset,
	minTreeOffset=minTreeOffset,
	minTreePathClearance=minTreePath,
	petalEmitters=petalEmitters,
	stoneSegments=segmentCount,
	stoneParts=stoneParts,
	visibleStoneParts=visibleStoneParts,
	leafyPathSamples=leafySamples,
	oceanSize=runtime:GetAttribute("OceanSize"),
	spawnGap=spawnGap,
	nametag=true,
	loadingScreen=true,
	fakeFollowingGrass=false,
	globalWind=workspace.GlobalWind.Magnitude
}
