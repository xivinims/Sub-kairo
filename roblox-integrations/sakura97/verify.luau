assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:FindFirstChild("XNRuntime")
assert(runtime and runtime:GetAttribute("Version")==102,"XNRuntime v102 ausente")
assert(runtime:GetAttribute("GameName")=="XN [VOICE]","Nome interno errado")
assert(runtime:GetAttribute("MapAssetId")==106476929993683,"Brookhaven asset errado")

for _,old in ipairs({"BigMapTest","Mirkwood","PumpkinDecor","PristineParkIsland","SakuraTrees","StonePath"}) do
	assert(not workspace:FindFirstChild(old),"Sobrou mapa antigo: "..old)
end

local map=workspace:FindFirstChild("BrookhavenMap")
assert(map and map:IsA("Model"),"BrookhavenMap ausente")
assert(map:GetAttribute("AssetId")==106476929993683,"BrookhavenMap asset errado")

local mapParts=0
local mapModels=0
local scriptCount=0
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("BasePart") then mapParts+=1 end
	if d:IsA("Model") then mapModels+=1 end
	if d:IsA("LuaSourceContainer") then scriptCount+=1 end
end
assert(mapParts>12000,"Brookhaven perdeu pecas demais: "..tostring(mapParts))
assert(mapModels>2000,"Brookhaven perdeu Models demais: "..tostring(mapModels))
assert(scriptCount==0,"Scripts do free model ainda existem: "..tostring(scriptCount))
assert(not map:FindFirstChild("001_MapHouseTeleports",true),"Teleports de casas ainda existem")
assert((runtime:GetAttribute("ScriptsRemoved") or 0)>20,"Poucos scripts removidos")

local _,size=map:GetBoundingBox()
assert(size.X>2800 and size.Z>2800,"Brookhaven deformado/redimensionado")

local lots=workspace:FindFirstChild("ReworkedHouseLots")
assert(lots and lots:IsA("Folder"),"ReworkedHouseLots ausente")
local lotCount=#lots:GetChildren()
assert(lotCount>=18,"Poucos lotes reurbanizados: "..tostring(lotCount))
assert(lotCount==(runtime:GetAttribute("ReworkedLotCount") or -1),"Contagem de lotes inconsistente")

local greenGround=CollectionService:GetTagged("XNGreenGround")
assert(#greenGround>=8,"Poucas superficies verdes taggeadas")
for _,p in ipairs(greenGround) do
	assert(p:IsA("BasePart") and p:IsDescendantOf(map),"XNGreenGround fora do mapa")
	local c=p.Color
	assert(c.G>c.R*1.08 and c.G>c.B,"Superficie taggeada nao parece verde")
	assert(p.CFrame.UpVector.Y>.8,"Superficie verde inclinada demais")
end

local grass=workspace:FindFirstChild("GreenGrassDecor")
assert(grass and grass:IsA("Folder"),"GreenGrassDecor ausente")
assert(grass:GetAttribute("PlacementRule")=="XNGreenGroundOnly","Regra da grama errada")
local grassCount=#grass:GetChildren()
assert(grassCount>=60 and grassCount<=160,"Quantidade de grama estranha: "..tostring(grassCount))
assert(grassCount==(runtime:GetAttribute("GrassDecorCount") or -1),"Contagem da grama inconsistente")

local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:IsA("LocalScript"),"WindController ausente")
assert(wind:GetAttribute("AssetId")==11946229834,"Wind asset errado")
assert(wind:FindFirstChild("WindLines") and wind:FindFirstChild("WindShake"),"Wind modules ausentes")
assert(workspace.GlobalWind.Magnitude>=10,"GlobalWind fraco")

local windTagged=0
for _,p in ipairs(CollectionService:GetTagged("WindShake")) do
	if p:IsDescendantOf(map) or p:IsDescendantOf(lots) then windTagged+=1 end
end
assert(windTagged>0,"Nenhuma folhagem com WindShake")

local halloween=workspace:FindFirstChild("HalloweenPumpkins")
assert(halloween and halloween:IsA("Folder"),"HalloweenPumpkins ausente")
assert(halloween:GetAttribute("OnlyPumpkins")==true,"Halloween contem decoracao alem de aboboras")
assert(halloween:GetAttribute("ClusterCount")==8,"Esperava 8 clusters")
assert(halloween:GetAttribute("PumpkinCount")==24,"Esperava 24 aboboras")
local clusters,pumpkins=0,0
for _,cluster in ipairs(halloween:GetChildren()) do
	assert(cluster:IsA("Folder") and cluster.Name:find("PumpkinCluster_",1,true),"Objeto inesperado no Halloween")
	clusters+=1
	for _,p in ipairs(cluster:GetChildren()) do
		assert(p:IsA("BasePart") and p.Name:find("Pumpkin_",1,true),"Halloween contem algo que nao e abobora")
		pumpkins+=1
	end
end
assert(clusters==8 and pumpkins==24,"Contagem visual Halloween errada")

local loading=game.ReplicatedFirst:FindFirstChild("XNLoading")
assert(loading and loading:IsA("LocalScript"),"XNLoading ausente")
assert(loading:GetAttribute("GameName")=="XN [VOICE]","Nome no loading errado")
assert(loading:GetAttribute("Text")=="acessando…","Texto do loading errado")
assert(loading:GetAttribute("Fullscreen")==true,"Loading nao e fullscreen")
assert(loading:GetAttribute("CameraRotationUnlocked")==true,"Loading deveria manter rotacao livre")
assert(string.find(loading.Source,"CameraMode=Enum.CameraMode.Classic",1,true),"Camera nao fica Classic")
assert(string.find(loading.Source,"CameraMinZoomDistance",1,true),"Transicao de zoom ausente")
assert(not string.find(loading.Source,"CameraType=Enum.CameraType.Scriptable",1,true),"Camera travada em Scriptable")

local spawn=workspace:FindFirstChild("XNSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"XNSpawn ausente")

return {
	ok=true,
	version=102,
	mapParts=mapParts,
	mapModels=mapModels,
	mapSize={size.X,size.Y,size.Z},
	scriptsRemoved=runtime:GetAttribute("ScriptsRemoved"),
	lots=lotCount,
	greenGround=#greenGround,
	grass=grassCount,
	windTagged=windTagged,
	pumpkinClusters=clusters,
	pumpkins=pumpkins,
	loading=true
}
