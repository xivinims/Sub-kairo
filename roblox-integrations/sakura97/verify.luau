assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local runtime=game.ReplicatedStorage:FindFirstChild("SweanRuntime")
assert(runtime and runtime:GetAttribute("Version")==101,"SweanRuntime v101 ausente")
assert(runtime:GetAttribute("MapAssetId")==9435523981,"Big-map asset errado")
assert(runtime:GetAttribute("MapName")=="Big map","Nome do mapa errado")
assert(runtime:GetAttribute("Mode")=="MapTestOnly","Nao esta em modo de teste puro")

for _,name in ipairs({
	"Mirkwood","PumpkinDecor","PristineParkIsland","SakuraTrees","ParkGrass",
	"HalloweenDecor","StonePath","Wildflowers","IslandSpawn"
}) do
	assert(not workspace:FindFirstChild(name),"Sobrou objeto antigo: "..name)
end

assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController"),"Vento ainda existe")
assert(not game.ReplicatedFirst:FindFirstChild("LoadingScreen"),"LoadingScreen ainda existe")
assert(not game.ServerScriptService:FindFirstChild("NametagService"),"Nametag ainda existe")

local map=workspace:FindFirstChild("BigMapTest")
assert(map and map:IsA("Model"),"BigMapTest ausente")
assert(map:GetAttribute("AssetId")==9435523981,"BigMapTest nao veio do asset correto")

local parts=0
local models=0
for _,d in ipairs(map:GetDescendants()) do
	if d:IsA("BasePart") then parts+=1 end
	if d:IsA("Model") then models+=1 end
	assert(not d:IsA("LuaSourceContainer"),"Script inesperado dentro do Big-map")
end
assert(parts==1694,"Esperava 1694 Parts: "..tostring(parts))
assert(models>=289,"Esperava pelo menos 289 Models internos: "..tostring(models))

local _,size=map:GetBoundingBox()
assert(size.X>2500 and size.Z>2600 and size.Y>1600,"Big-map foi deformado/redimensionado")

local spawn=workspace:FindFirstChild("BigMapSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"Spawn de teste ausente")

return {
	ok=true,
	version=101,
	mapParts=parts,
	mapModels=models,
	mapSize={size.X,size.Y,size.Z}
}
