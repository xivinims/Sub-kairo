assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local runtime=game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
assert(runtime and runtime:GetAttribute("Version")==99,"Runtime v99 ausente")
assert(runtime:GetAttribute("MapType")=="PristineParkIslandHalloween","MapType errado")
assert(runtime:GetAttribute("ParkAssetId")==13366955960,"Pristine Park asset errado")
assert(runtime:GetAttribute("HalloweenAssetId")==12489961338,"Halloween asset errado")

local park=workspace:FindFirstChild("PristineParkIsland")
assert(park and park:IsA("Model"),"PristineParkIsland ausente")
assert(park:GetAttribute("AssetId")==13366955960,"Park nao veio do asset pedido")
local _,parkSize=park:GetBoundingBox()
assert(parkSize.X>340 and parkSize.Z>240,"Pristine Park foi cortado ou escalado errado")
local parkParts=0
for _,d in ipairs(park:GetDescendants()) do if d:IsA("BasePart") then parkParts+=1 end end
assert(parkParts>850,"Pristine Park perdeu muitas pecas: "..tostring(parkParts))

-- Pedras Brown Stone devem estar cinza.
local brownStones=0
local grayStones=0
for _,d in ipairs(park:GetDescendants()) do
	if d:IsA("BasePart") and d.Name:lower()=="brown stone" then
		brownStones+=1
		local c=d.Color
		if math.abs(c.R-c.G)<.08 and math.abs(c.G-c.B)<.08 and c.R>.3 and c.R<.65 then
			grayStones+=1
		end
	end
end
assert(brownStones>8,"Brown Stone nao encontrado no parque")
assert(grayStones==brownStones,"Nem todas Brown Stone ficaram cinza")
assert((runtime:GetAttribute("GrayStoneCount") or 0)==brownStones,"Contagem de pedras cinzas inconsistente")

-- Árvores antigas removidas e cerejeiras novas.
local removed=runtime:GetAttribute("OriginalTreesRemoved") or 0
assert(removed>0,"Nenhuma arvore original do Pristine Park foi detectada/removida")
local trees=workspace:FindFirstChild("SakuraTrees")
assert(trees,"SakuraTrees ausente")
local treeCount=#trees:GetChildren()
assert(treeCount>=18 and treeCount<=28,"Quantidade de cerejeiras estranha: "..tostring(treeCount))
local windLeaves=0
local petals=0
for _,tree in ipairs(trees:GetChildren()) do
	for _,d in ipairs(tree:GetDescendants()) do
		if d:IsA("BasePart") and d.Name=="Leaves" then
			if CollectionService:HasTag(d,"WindShake") then windLeaves+=1 end
			local p=d:FindFirstChild("SakuraPetals")
			if p and p:IsA("ParticleEmitter") and p.WindAffectsDrag then petals+=1 end
		end
	end
end
assert(windLeaves>=treeCount,"WindShake faltando em folhas")
assert(petals>=treeCount,"Petalas faltando nas cerejeiras")

-- Grama estática do asset exato, sem seguir jogador.
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TerrainGrassBend"),"Grama falsa seguindo jogador voltou")
local grass=workspace:FindFirstChild("ParkGrass")
assert(grass,"ParkGrass ausente")
local grassCount=#grass:GetChildren()
assert(grassCount>=55,"Pouca grama estatica: "..tostring(grassCount))
assert((runtime:GetAttribute("StaticGrassCount") or 0)==grassCount,"Contagem ParkGrass inconsistente")

-- Halloween.
local halloween=workspace:FindFirstChild("HalloweenDecor")
assert(halloween,"HalloweenDecor ausente")
assert(halloween:GetAttribute("AssetId")==12489961338,"Eerie Tomb asset errado")
local tombCount=halloween:GetAttribute("TombCount") or 0
local pumpkinCount=halloween:GetAttribute("PumpkinCount") or 0
local skullCount=halloween:GetAttribute("SkullCount") or 0
assert(tombCount==4,"Esperava 4 tumulos/criptas: "..tostring(tombCount))
assert(pumpkinCount==14,"Esperava 14 aboboras: "..tostring(pumpkinCount))
assert(skullCount==10,"Esperava 10 cabecas de esqueleto: "..tostring(skullCount))
local tombModels,pumpkins,skulls=0,0,0
for _,d in ipairs(halloween:GetChildren()) do
	if d:IsA("Model") and d.Name:find("EerieTomb",1,true) then tombModels+=1 end
	if d:IsA("BasePart") and d.Name:find("Pumpkin_",1,true) then pumpkins+=1 end
	if d:IsA("Model") and d.Name:find("SkullHead_",1,true) then skulls+=1 end
end
assert(tombModels==4 and pumpkins==14 and skulls==10,"Halloween visual count mismatch")

-- Oceano e ilha.
local outside=workspace:Raycast(Vector3.new(500,20,0),Vector3.new(0,-70,0))
assert(outside and outside.Material==Enum.Material.Water,"Oceano nao cobre o exterior")
local seabedParams=RaycastParams.new()
seabedParams.IgnoreWater=true
seabedParams.FilterType=Enum.RaycastFilterType.Exclude
seabedParams.FilterDescendantsInstances={workspace:FindFirstChild("WorldSafetyFloor")}
local seabed=workspace:Raycast(Vector3.new(500,15,0),Vector3.new(0,-90,0),seabedParams)
assert(seabed and seabed.Material==Enum.Material.Sand,"Fundo do mar ausente")
local safety=workspace:FindFirstChild("WorldSafetyFloor")
assert(safety and safety:IsA("BasePart") and safety.CanCollide,"Anti-void ausente")

-- Spawn.
local spawn=workspace:FindFirstChild("IslandSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"IslandSpawn ausente/desativado")
local sp=RaycastParams.new()
sp.FilterType=Enum.RaycastFilterType.Exclude
sp.FilterDescendantsInstances={spawn,trees,grass,halloween,safety}
local hit=workspace:Raycast(spawn.Position+Vector3.new(0,8,0),Vector3.new(0,-25,0),sp)
assert(hit and hit.Material~=Enum.Material.Water,"Spawn nao esta em terra firme")
local gap=(spawn.Position.Y-spawn.Size.Y*.5)-hit.Position.Y
assert(math.abs(gap)<.5,"Spawn flutuando: "..tostring(gap))

-- Vento.
local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:IsA("LocalScript"),"WindController ausente")
assert(wind:GetAttribute("AssetId")==11946229834,"Wind asset incorreto")
assert(wind:FindFirstChild("WindLines") and wind:FindFirstChild("WindShake"),"Modulos do vento ausentes")
assert(workspace.GlobalWind.Magnitude>=10,"GlobalWind fraco")

-- Nametag.
local nametag=game.ServerScriptService:FindFirstChild("NametagService")
assert(nametag and nametag:IsA("Script"),"NametagService ausente")
assert(nametag:GetAttribute("AssetId")==123212555736117,"Nametag asset errado")
assert(nametag:FindFirstChild("Nametag") and nametag.Nametag:IsA("BillboardGui"),"BillboardGui do nametag ausente")

-- Loading.
local loading=ReplicatedFirst:FindFirstChild("LoadingScreen")
assert(loading and loading:IsA("LocalScript"),"LoadingScreen ausente")
assert(loading:GetAttribute("AssetId")==73186563008540,"Loading asset errado")
assert(loading:GetAttribute("GameName")=="Swean Island","Nome da loading errado")
assert(string.find(loading.Source,"Swean Island",1,true),"Swean Island nao esta no script")
assert(string.find(loading.Source,"BuilderSansBold",1,true),"BuilderSansBold nao esta no loading")

assert(not workspace:FindFirstChild("StonePath"),"Estrada antiga ainda existe")

return{
	ok=true,
	trees=treeCount,
	parkParts=parkParts,
	removedOriginalTrees=removed,
	grayStones=grayStones,
	grass=grassCount,
	tombs=tombCount,
	pumpkins=pumpkinCount,
	skulls=skullCount,
	windLeaves=windLeaves,
	petals=petals,
	spawnGap=gap,
	version=99
}
