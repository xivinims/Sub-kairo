-- trigger v102 final publish
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:FindFirstChild("SweanRuntime")
assert(runtime and runtime:GetAttribute("Version")==105,"SweanRuntime v102 ausente")
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
assert(math.abs((island:GetAttribute("ScaleMultiplier") or 0)-82)<.01,"Ilha nao esta 50x maior que a versao anterior")
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
assert(grass:GetAttribute("Rule")=="SeamlessTiledGreenSkinnedGrass","Regra da grama incorreta")
assert((grass:GetAttribute("TileOverlap") or 0)>=1.03,"Tiles de grama sem sobreposicao anti-fresta")
assert((grass:GetAttribute("VisualScaleX") or 0)>=7 and (grass:GetAttribute("VisualScaleZ") or 0)>=7,"Correcao de footprint visual nao aplicada")
assert((grass:GetAttribute("GroundOffset") or 99)<=0.7,"Offset de contato com o chao alto demais")
assert(grass:GetAttribute("SingleMeshOnly")==true,"Mais de uma variante de grama foi usada")
assert((grass:GetAttribute("SourceBones") or 0)==100,"A grama escolhida deve ter 100 Bones")
assert(type(grass:GetAttribute("SourceMeshId"))=="string","SourceMeshId da grama ausente")
local patches=#grass:GetChildren()
assert(patches>=#green,"Pouca SkinnedGrass: "..tostring(patches))
assert(patches==(runtime:GetAttribute("GrassPatchCount") or -1),"Contagem SkinnedGrass inconsistente")
assert((runtime:GetAttribute("GrassCoveredSurfaces") or 0)==#green,"Nem toda area verde recebeu SkinnedGrass")
assert((runtime:GetAttribute("GrassVisualOverlap") or 0)>=1.24,"Grama sem sobreposicao suficiente")
assert((runtime:GetAttribute("GrassTileSpacing") or 999)<=84,"Espacamento da grama grande demais")
assert(math.abs((runtime:GetAttribute("GrassCenterOffset") or 99)-(-0.08))<.01,"Grama ainda nao esta no nivel do chao")

local checked=0
local covered={}
for _,patch in ipairs(grass:GetChildren()) do
	assert(patch:IsA("Model"),"GrassTile deve ser Model")
	assert(patch:GetAttribute("SingleMesh")==true,"GrassTile contem configuracao invalida")
	local idx=patch:GetAttribute("GroundSurfaceIndex")
	assert(type(idx)=="number" and idx>=1 and idx<=#green,"GrassTile sem superficie verde valida")
	covered[idx]=true

	local cellX=patch:GetAttribute("CellX")
	local cellZ=patch:GetAttribute("CellZ")
	assert(type(cellX)=="number" and type(cellZ)=="number","GrassTile sem tamanho de celula")
	local groundRef=patch:FindFirstChild("GroundSurface")
	assert(groundRef and groundRef:IsA("ObjectValue") and groundRef.Value and groundRef.Value:IsA("BasePart"),"GrassTile sem referencia do chao")
	local ground=groundRef.Value

	local meshCount=0
	local boneCount=0
	for _,d in ipairs(patch:GetDescendants()) do
		if d:IsA("MeshPart") then
			meshCount+=1
			assert(d.Material==Enum.Material.Neon,"Foi usada a variante cinza da grama")
			local sx=grass:GetAttribute("VisualScaleX")
			local sz=grass:GetAttribute("VisualScaleZ")
			local visualX=d.Size.X/sx
			local visualZ=d.Size.Z/sz
			assert(visualX>=cellX*1.24 and visualZ>=cellZ*1.24,"Cobertura VISUAL da grama ainda deixa fresta")
			local expectedRootY=(ground.CFrame*Vector3.new(0,ground.Size.Y*.5-0.08,0)).Y
			assert(math.abs(d.Position.Y-expectedRootY)<.35,"Grama ainda flutuando acima do chao")
		end
		if d:IsA("Bone") then boneCount+=1 end
	end
	assert(meshCount==1,"Cada tile deve usar UMA unica MeshPart de grama")
	assert(boneCount==100,"Cada tile deve preservar os 100 Bones: "..tostring(boneCount))
	checked+=1
end
assert(checked==patches,"Nem todos os tiles foram validados")
local coveredCount=0
for i=1,#green do if covered[i] then coveredCount+=1 end end
assert(coveredCount==#green,"Nem toda superficie verde recebeu tiles de grama")

local grassRunner=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SkinnedGrassRunner")
assert(grassRunner and grassRunner:IsA("LocalScript"),"Runner original/adaptado da SkinnedGrass ausente")
local grassModule=game.ReplicatedStorage:FindFirstChild("SkinnedGrassRuntimeModule")
assert(grassModule and grassModule:IsA("ModuleScript"),"Modulo original SkinnedGrass ausente")

local tree=workspace:FindFirstChild("BigCenterTree")
assert(tree and tree:IsA("Model"),"BigCenterTree ausente")
assert(tree:GetAttribute("AssetId")==86013526879602,"Arvore nao veio do asset pedido")
local treeCF,treeSize=tree:GetBoundingBox()
assert(treeSize.Y>=106 and treeSize.Y<=124,"Arvore fora do novo tamanho: "..tostring(treeSize.Y))
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

local spawn=workspace:FindFirstChild("IslandSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"IslandSpawn ausente")
local safety=workspace:FindFirstChild("VoidSafety")
assert(safety and safety:IsA("BasePart") and safety.CanCollide,"VoidSafety ausente")

return{
	ok=true,
	version=105,
	mapParts=islandParts,
	greenSurfaces=#green,
	grass=patches,
	treeFoliage=tagged,
	leaves=true,
	wind=true
}
