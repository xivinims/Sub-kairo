-- trigger v109 packed default grass
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:FindFirstChild("SweanRuntime")
assert(runtime and runtime:GetAttribute("Version")==109,"SweanRuntime v109 ausente")
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
assert(#grass:GetChildren()==0,"A grama densa nao pode ficar salva no servidor")
assert(grass:GetAttribute("AssetId")==87377915371959,"SkinnedGrass nao veio do asset pedido")
assert(grass:GetAttribute("Rule")=="DefaultSizeFillGreen","Regra da grama incorreta")
assert(grass:GetAttribute("SpawnMode")=="ClientPackedDefaultSize","A grama nao esta sendo repetida no cliente")
assert(math.abs((grass:GetAttribute("VisualScaleX") or 99)-1)<.001,"Grama foi esticada no X")
assert(math.abs((grass:GetAttribute("VisualScaleZ") or 99)-1)<.001,"Grama foi esticada no Z")
assert(math.abs((grass:GetAttribute("GroundOffset") or 99)-(-0.08))<.01,"Offset de contato com o chao errado")
assert(math.abs((grass:GetAttribute("VisualDiv") or 0)-7.15)<.001,"Divisor visual da grama errado")
assert(math.abs((grass:GetAttribute("TileOverlap") or 0)-1.28)<.001,"Sobreposicao da grama errada")
local defaultX=grass:GetAttribute("DefaultSizeX")
local defaultY=grass:GetAttribute("DefaultSizeY")
local defaultZ=grass:GetAttribute("DefaultSizeZ")
local footX=grass:GetAttribute("FootprintX")
local footZ=grass:GetAttribute("FootprintZ")
local stepX=grass:GetAttribute("StepX")
local stepZ=grass:GetAttribute("StepZ")
assert(type(defaultX)=="number" and type(defaultY)=="number" and type(defaultZ)=="number","Tamanho padrao da grama ausente")
assert(defaultX>20 and defaultZ>20,"Tamanho padrao da grama parece esticado ou vazio")
assert(math.abs(footX-defaultX/7.15)<.05 and math.abs(footZ-defaultZ/7.15)<.05,"A cobertura nao esta usando a grama visivel")
assert(math.abs(stepX-footX/1.28)<.05 and math.abs(stepZ-footZ/1.28)<.05,"O passo nao encosta os tufos")
assert(stepX<footX and stepZ<footZ,"Passo maior que a grama visivel, vai abrir fresta")
assert(stepX<defaultX/4 and stepZ<defaultZ/4,"O passo ainda e o da caixa da mesh, a grama continua separada")
assert(grass:GetAttribute("SingleMeshOnly")==true,"Mais de uma variante de grama foi usada")
assert((grass:GetAttribute("SourceBones") or 0)==100,"A grama escolhida deve ter 100 Bones")
assert(type(grass:GetAttribute("SourceMeshId"))=="string","SourceMeshId da grama ausente")

local function tilesNeeded(length,step,foot)
	if length<=foot then return 1 end
	return math.ceil((length-foot)/step)+1
end
local planned=0
for _,ground in ipairs(green) do
	planned+=tilesNeeded(ground.Size.X,stepX,footX)*tilesNeeded(ground.Size.Z,stepZ,footZ)
end
assert(planned==(runtime:GetAttribute("GrassPatchCount") or -1),"Contagem da grama densa inconsistente")
assert(planned>=#green*20,"Pouca grama para tapar o verde: "..tostring(planned))
assert((runtime:GetAttribute("GrassCoveredSurfaces") or 0)==#green,"Nem toda area verde recebeu SkinnedGrass")
assert(math.abs((runtime:GetAttribute("GrassVisualScaleX") or 99)-1)<.001,"Escala visual da grama nao e a padrao")
assert(math.abs((runtime:GetAttribute("GrassCenterOffset") or 99)-(-0.08))<.01,"Grama ainda nao esta no nivel do chao")

local staticTemplate=game.ReplicatedStorage:FindFirstChild("GrassStaticTemplate")
assert(staticTemplate and staticTemplate:IsA("MeshPart"),"Template estatico da grama ausente")
assert(math.abs(staticTemplate.Size.X-defaultX)<.05,"Template estatico foi esticado no X")
assert(math.abs(staticTemplate.Size.Y-defaultY)<.05,"Template estatico foi esticado no Y")
assert(math.abs(staticTemplate.Size.Z-defaultZ)<.05,"Template estatico foi esticado no Z")
assert(staticTemplate.MeshId==grass:GetAttribute("SourceMeshId"),"Template estatico nao usa a mesh original")
local staticBones=0
for _,d in ipairs(staticTemplate:GetDescendants()) do
	if d:IsA("Bone") then staticBones+=1 end
end
assert(staticBones==0,"Template estatico ainda carrega Bones")

local windTemplate=game.ReplicatedStorage:FindFirstChild("GrassWindTemplate")
assert(windTemplate and windTemplate:IsA("Model"),"Template de vento da grama ausente")
local windMesh=windTemplate:FindFirstChild("SkinnedGrass")
assert(windMesh and windMesh:IsA("MeshPart"),"Mesh de vento ausente")
assert(math.abs(windMesh.Size.X-defaultX)<.05 and math.abs(windMesh.Size.Z-defaultZ)<.05,"Template de vento foi esticado")
local windBones=0
for _,d in ipairs(windMesh:GetDescendants()) do
	if d:IsA("Bone") then windBones+=1 end
end
assert(windBones==100,"Template de vento perdeu os Bones")

local grassRunner=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SkinnedGrassRunner")
assert(grassRunner and grassRunner:IsA("LocalScript"),"Runner original/adaptado da SkinnedGrass ausente")
assert(string.find(grassRunner.Source,"PACKED_DEFAULT_GRASS",1,true),"Runner nao repete a grama no tamanho padrao")
assert(string.find(grassRunner.Source,"mesh.Size=defaultSize",1,true),"Runner nao fixa o tamanho padrao")
assert(not string.find(grassRunner.Source,"ScaleTo",1,true),"Runner estica a grama")
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
	version=109,
	mapParts=islandParts,
	greenSurfaces=#green,
	grass=planned,
	treeFoliage=tagged,
	leaves=true,
	wind=true
}
