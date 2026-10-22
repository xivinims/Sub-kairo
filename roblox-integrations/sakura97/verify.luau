-- Verifica a ilha Sakura no place atual
assert(game.GameId == 9419478735 and game.PlaceId == 79738710219521, "Place errado")

local runtime=game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
assert(runtime,"SakuraRuntime nao existe")
assert(runtime:GetAttribute("Version")==97,"Versao errada")

local trees=workspace:FindFirstChild("SakuraTrees")
assert(trees,"SakuraTrees ausente")
local treeCount=#trees:GetChildren()
assert(treeCount==27,"Esperava 27 cerejeiras, recebeu "..tostring(treeCount))

local path=workspace:FindFirstChild("StonePath")
assert(path,"StonePath ausente")
local stoneCount=#path:GetChildren()
assert(stoneCount>=26 and stoneCount<=40,"Estradinha deve ser fina e espacada: "..tostring(stoneCount))

local grass=workspace:FindFirstChild("SkinnedGrass")
assert(not grass,"SkinnedGrass ainda existe")

local flowers=workspace:FindFirstChild("Wildflowers")
assert(flowers,"Wildflowers ausente")
local flowerCount=flowers:GetAttribute("FlowerCount") or 0
assert(flowerCount>=180,"Flores pequenas insuficientes: "..tostring(flowerCount))

local wind=workspace:FindFirstChild("WindEffects")
assert(wind and #wind:GetChildren()>=4,"WindEffects visivel ausente")
local centerHit=workspace:Raycast(Vector3.new(0,80,0),Vector3.new(0,-120,0))
assert(centerHit and centerHit.Material==Enum.Material.Ground,"Terreno ainda nao foi trocado para Ground")

local Lighting=game:GetService("Lighting")
assert(Lighting.ClockTime>16 and Lighting.ClockTime<18.5,"Nao esta de tarde")

assert(not workspace:FindFirstChild("ForestWorld"),"ForestWorld antigo ainda existe")
assert(not game.ReplicatedStorage:FindFirstChild("ForestRuntime"),"ForestRuntime antigo ainda existe")

print("[Sakura97 Verify] OK - caminho fino, sem grama alta, flores pequenas e vento")
return {
 ok=true,
 trees=treeCount,
 stones=stoneCount,
 flowers=flowerCount,
 windAnchors=#wind:GetChildren()
}
