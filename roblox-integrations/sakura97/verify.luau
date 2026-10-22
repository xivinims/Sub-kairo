assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local runtime=game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
assert(runtime and runtime:GetAttribute("Version")==97,"Runtime Sakura97 invalido")

local trees=workspace:FindFirstChild("SakuraTrees")
assert(trees and #trees:GetChildren()==27,"Esperava 27 cerejeiras")

local center=workspace:Raycast(Vector3.new(0,80,0),Vector3.new(0,-120,0))
assert(center and center.Material==Enum.Material.Grass,"Grama normal do Terrain nao esta ativa")

local reactive=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TerrainGrassBend")
assert(reactive,"Efeito local de amassar a grama ausente")

local grass=workspace:FindFirstChild("SkinnedGrass")
assert(not grass,"SkinnedGrass antiga ainda existe")

local path=workspace:FindFirstChild("StonePath")
assert(path and path:GetAttribute("AssetId")==136068114177879,"Stone Path asset errado")
local stones=#path:GetChildren()
assert(stones>=24 and stones<=36,"Quantidade de pedras fora do estilo fino: "..tostring(stones))
assert((path:GetAttribute("SourceParts") or 0)>0,"Pedras nao vieram do asset exato")

local flowers=workspace:FindFirstChild("Wildflowers")
assert(flowers and (flowers:GetAttribute("FlowerCount") or 0)>=180,"Flores pequenas insuficientes")

local wind=workspace:FindFirstChild("WindEffects")
assert(wind and wind:GetAttribute("AssetId")==11946229834,"Wind Effects asset errado")
assert((wind:GetAttribute("Copies") or 0)>=3,"Wind Effects nao foi espalhado pelo mapa")
assert(workspace.GlobalWind.Magnitude>=10,"GlobalWind fraco ou ausente")

local Lighting=game:GetService("Lighting")
assert(Lighting.ClockTime>16 and Lighting.ClockTime<18.5,"Nao esta de tarde")

return {
 ok=true,
 trees=#trees:GetChildren(),
 stones=stones,
 stoneSourceParts=path:GetAttribute("SourceParts"),
 flowers=flowers:GetAttribute("FlowerCount"),
 windCopies=wind:GetAttribute("Copies"),
 globalWind=workspace.GlobalWind.Magnitude,
 terrainGrass=true,
 reactiveGrass=true
}
