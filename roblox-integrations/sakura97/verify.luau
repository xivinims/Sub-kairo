assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
assert(runtime and runtime:GetAttribute("Version")==97,"Runtime Sakura97 invalido")

local trees=workspace:FindFirstChild("SakuraTrees")
assert(trees and #trees:GetChildren()==27,"Esperava 27 cerejeiras")

local windTagged=0
for _,obj in ipairs(CollectionService:GetTagged("WindShake")) do
	if obj:IsA("BasePart") and obj.Name=="Leaves" then windTagged+=1 end
end
assert(windTagged>=27,"Folhas sem WindShake suficiente: "..tostring(windTagged))

local center=workspace:Raycast(Vector3.new(0,80,0),Vector3.new(0,-120,0))
assert(center and center.Material==Enum.Material.Grass,"Terrain principal nao esta em Grass")

local bend=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TerrainGrassBend")
assert(bend and bend:IsA("LocalScript"),"Efeito local de amassar grama ausente")

local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:IsA("LocalScript"),"WindController ausente")
assert(wind:GetAttribute("AssetId")==11946229834,"WindController nao veio do asset pedido")
assert(wind:FindFirstChild("WindLines") and wind.WindLines:IsA("ModuleScript"),"WindLines ausente")
assert(wind:FindFirstChild("WindShake") and wind.WindShake:IsA("ModuleScript"),"WindShake ausente")
assert(workspace.GlobalWind.Magnitude>=10,"GlobalWind fraco")

local path=workspace:FindFirstChild("StonePath")
assert(path and path:GetAttribute("AssetId")==136068114177879,"Stone Path asset errado")
assert(path:GetAttribute("ExactModelName")=="Stone Path (Long)","Modelo exato Stone Path (Long) nao usado")
local model=path:FindFirstChild("Stone Path (Long)")
assert(model and model:IsA("Model"),"Stone Path (Long) nao esta no Workspace")

local stoneParts=0
local visibleStoneParts=0
for _,d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then
		stoneParts+=1
		if d.Transparency<.95 then visibleStoneParts+=1 end
	end
end
assert(stoneParts==38,"Asset de pedra deveria manter 38 Parts; recebeu "..tostring(stoneParts))
assert(visibleStoneParts>=30,"Poucas pedras visiveis: "..tostring(visibleStoneParts))
assert((path:GetAttribute("VisibleParts") or 0)>=30,"Diagnostico de pedras visiveis falhou")

-- Confirma que a antiga faixa marrom de Ground nao ficou no centro do caminho.
local samplePart=model:FindFirstChildWhichIsA("BasePart",true)
if samplePart then
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={path}
	local hit=workspace:Raycast(samplePart.Position+Vector3.new(0,3,0),Vector3.new(0,-8,0),params)
	assert(not hit or hit.Material~=Enum.Material.Ground,"Ainda existe faixa de Ground embaixo das pedras")
end

local flowers=workspace:FindFirstChild("Wildflowers")
assert(flowers and (flowers:GetAttribute("FlowerCount") or 0)>=180,"Flores pequenas insuficientes")

local Lighting=game:GetService("Lighting")
assert(Lighting.ClockTime>16 and Lighting.ClockTime<18.5,"Nao esta de tarde")

return {
	ok=true,
	trees=#trees:GetChildren(),
	windTaggedLeaves=windTagged,
	stoneParts=stoneParts,
	visibleStoneParts=visibleStoneParts,
	flowers=flowers:GetAttribute("FlowerCount"),
	globalWind=workspace.GlobalWind.Magnitude,
	terrainGrass=true,
	reactiveGrass=true,
	exactWindModules=true
}
