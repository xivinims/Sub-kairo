assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:FindFirstChild("SweanRuntime")
assert(runtime and runtime:GetAttribute("Version")==100,"SweanRuntime v100 ausente")
assert(runtime:GetAttribute("MapAssetId")==12489980589,"Mirkwood asset errado")
assert(runtime:GetAttribute("MapName")=="Mirkwood","Mapa nao e Mirkwood")

-- Nada da versão anterior pode sobreviver.
for _,name in ipairs({
	"PristineParkIsland","SakuraTrees","ParkGrass","HalloweenDecor",
	"StonePath","Wildflowers","WorldSafetyFloor","IslandSpawn"
}) do
	assert(not workspace:FindFirstChild(name),"Sobrou objeto antigo: "..name)
end
assert(not game.ReplicatedStorage:FindFirstChild("SakuraRuntime"),"SakuraRuntime antigo ainda existe")
assert(not game.ServerScriptService:FindFirstChild("NametagService"),"Nametag antigo ainda existe")
assert(not game.ReplicatedFirst:FindFirstChild("LoadingScreen"),"LoadingScreen antiga ainda existe")
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TerrainGrassBend"),"Grama antiga ainda existe")

local map=workspace:FindFirstChild("Mirkwood")
assert(map and map:IsA("Model"),"Mirkwood ausente")
assert(map:GetAttribute("AssetId")==12489980589,"Mirkwood nao veio do asset pedido")

local _,size=map:GetBoundingBox()
assert(size.X>2000 and size.Z>2400 and size.Y>250,"Mirkwood foi deformado/escalado: "..tostring(size))
local parts=0
local forests=0
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("BasePart") then parts+=1 end
	if d:IsA("Model") and d.Name=="Forrest" then forests+=1 end
	assert(not d:IsA("LuaSourceContainer"),"Mirkwood importou script inesperado")
end
assert(parts==172,"Mirkwood deveria manter 172 Parts: "..tostring(parts))
assert(forests>0,"Modelos Forrest ausentes")

local tagged=0
for _,d in ipairs(CollectionService:GetTagged("WindShake")) do
	if d:IsDescendantOf(map) then tagged+=1 end
end
assert(tagged>0,"Folhagem do Mirkwood sem WindShake")

local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:IsA("LocalScript"),"WindController ausente")
assert(wind:GetAttribute("AssetId")==11946229834,"Wind asset errado")
assert(wind:GetAttribute("ExactCreatorStoreController")==true,"WindController nao e o original")
assert(wind:FindFirstChild("WindLines") and wind:FindFirstChild("WindShake"),"Modulos do vento ausentes")
assert(workspace.GlobalWind.Magnitude>=10,"GlobalWind fraco")

local pumpkins=workspace:FindFirstChild("PumpkinDecor")
assert(pumpkins and pumpkins:IsA("Folder"),"PumpkinDecor ausente")
assert(pumpkins:GetAttribute("AssetId")==12489961338,"Pumpkins nao vieram do Eerie Tomb")
assert(pumpkins:GetAttribute("OnlyPumpkins")==true,"Halloween contem algo alem de aboboras")
assert(pumpkins:GetAttribute("ClusterCount")==8,"Esperava 8 clusters de aboboras")
local clusters=0
local pumpkinCount=0
for _,cluster in ipairs(pumpkins:GetChildren()) do
	assert(cluster:IsA("Folder") and cluster.Name:find("PumpkinCluster_",1,true),"Decoracao inesperada em PumpkinDecor")
	clusters+=1
	for _,p in ipairs(cluster:GetChildren()) do
		assert(p:IsA("BasePart") and p.Name:find("Pumpkin_",1,true),"Objeto Halloween que nao e abobora")
		pumpkinCount+=1
	end
end
assert(clusters==8,"Numero de clusters errado: "..tostring(clusters))
assert(pumpkinCount>=20,"Poucas aboboras: "..tostring(pumpkinCount))
assert(pumpkinCount==(pumpkins:GetAttribute("PumpkinCount") or -1),"Contagem de aboboras inconsistente")

local spawn=workspace:FindFirstChild("MirkwoodSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"Spawn do Mirkwood ausente")

return{
	ok=true,
	version=100,
	mapParts=parts,
	mapSize={size.X,size.Y,size.Z},
	forests=forests,
	windTagged=tagged,
	pumpkinClusters=clusters,
	pumpkins=pumpkinCount
}
