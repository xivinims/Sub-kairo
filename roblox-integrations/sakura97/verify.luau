-- trigger v102 final publish
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:FindFirstChild("SweanRuntime")
assert(runtime and runtime:GetAttribute("Version")==102,"SweanRuntime v102 ausente")
assert(runtime:GetAttribute("IslandAssetId")==10485490600,"Floating Island asset errado")
assert(runtime:GetAttribute("GrassAssetId")==87377915371959,"SkinnedGrass asset errado")
assert(runtime:GetAttribute("TreeAssetId")==86013526879602,"Big Tree asset errado")
assert(runtime:GetAttribute("WindAssetId")==11946229834,"Wind asset errado")

for _,name in ipairs({"BigMapTest","Mirkwood","PumpkinDecor","PristineParkIsland","StonePath","SakuraTrees","ParkGrass","HalloweenDecor"}) do
	assert(not workspace:FindFirstChild(name),"Sobrou mapa/sistema antigo: "..name)
end

local island=workspace:FindFirstChild("FloatingIsland")
assert(island and island:IsA("Model"),"FloatingIsland ausente")
assert(island:GetAttribute("AssetId")==10485490600,"Ilha nao veio do asset pedido")
local islandParts=0
for _,d in ipairs(island:GetDescendants()) do
	if d:IsA("BasePart") then islandParts+=1 end
	assert(not d:IsA("LuaSourceContainer"),"Script importado dentro da ilha")
end
assert(islandParts>0,"Ilha sem Parts")

local green=CollectionService:GetTagged("IslandGreenGround")
assert(#green>0,"Nenhum chao verde detectado")
assert(#green==(runtime:GetAttribute("GreenSurfaceCount") or -1),"Contagem de chao verde inconsistente")

local grass=workspace:FindFirstChild("SkinnedGrassCoverage")
assert(grass and grass:IsA("Folder"),"SkinnedGrassCoverage ausente")
assert(grass:GetAttribute("AssetId")==87377915371959,"SkinnedGrass nao veio do asset pedido")
assert(grass:GetAttribute("Rule")=="IslandGreenGroundOnly","Regra da grama incorreta")
local patches=#grass:GetChildren()
assert(patches>=#green,"Pouca SkinnedGrass: "..tostring(patches))
assert(patches==(runtime:GetAttribute("GrassPatchCount") or -1),"Contagem SkinnedGrass inconsistente")
assert((runtime:GetAttribute("GrassCoveredSurfaces") or 0)==#green,"Nem toda area verde recebeu SkinnedGrass")

local covered={}
local checked=0
for _,patch in ipairs(grass:GetChildren()) do
	if patch:IsA("Model") then
		local idx=patch:GetAttribute("GroundSurfaceIndex")
		assert(type(idx)=="number" and idx>=1 and idx<=#green,"SkinnedGrass sem superficie verde valida: "..patch.Name)
		covered[idx]=true
		checked+=1
	end
end
assert(checked==patches,"Nem toda SkinnedGrass foi validada")
local coveredCount=0
for i=1,#green do
	if covered[i] then coveredCount+=1 end
end
assert(coveredCount==#green,"SkinnedGrass nao cobre todas as areas verdes: "..tostring(coveredCount).."/"..tostring(#green))

local tree=workspace:FindFirstChild("BigCenterTree")
assert(tree and tree:IsA("Model"),"BigCenterTree ausente")
assert(tree:GetAttribute("AssetId")==86013526879602,"Arvore nao veio do asset pedido")
local treeCF,treeSize=tree:GetBoundingBox()
local centerDist=(Vector2.new(treeCF.Position.X,treeCF.Position.Z)-Vector2.new(select(1,island:GetBoundingBox()).Position.X,select(1,island:GetBoundingBox()).Position.Z)).Magnitude
assert(centerDist<math.max(12,math.min(runtime:GetAttribute("IslandSizeX") or 100,runtime:GetAttribute("IslandSizeZ") or 100)*.35),"Arvore longe demais do centro")

local emitter=tree:FindFirstChild("FallingLeavesEmitter",true)
assert(emitter and emitter:IsA("BasePart"),"FallingLeavesEmitter ausente")
local leaves=emitter:FindFirstChild("FallingLeaves")
assert(leaves and leaves:IsA("ParticleEmitter"),"FallingLeaves ausente")
assert(leaves.WindAffectsDrag==true and leaves.Drag>0 and leaves.Rate>0,"Folhas nao seguem vento corretamente")

local tagged=0
for _,p in ipairs(CollectionService:GetTagged("WindShake")) do
	if p:IsDescendantOf(tree) then tagged+=1 end
end
assert(tagged>0,"Arvore sem WindShake")

local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:IsA("LocalScript"),"WindController ausente")
assert(wind:GetAttribute("AssetId")==11946229834,"WindController asset errado")
assert(wind:FindFirstChild("WindLines") and wind:FindFirstChild("WindShake"),"Modulos do vento ausentes")
assert(workspace.GlobalWind.Magnitude>=10,"GlobalWind fraco")

local grassWind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SkinnedGrassWind")
assert(grassWind and grassWind:IsA("LocalScript"),"SkinnedGrassWind ausente")

local spawn=workspace:FindFirstChild("IslandSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"IslandSpawn ausente")
local safety=workspace:FindFirstChild("VoidSafety")
assert(safety and safety:IsA("BasePart") and safety.CanCollide,"VoidSafety ausente")

return{
	ok=true,
	version=102,
	mapParts=islandParts,
	greenSurfaces=#green,
	grass=patches,
	treeFoliage=tagged,
	leaves=true,
	wind=true
}
