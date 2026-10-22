assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local CollectionService=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
assert(runtime and runtime:GetAttribute("Version")==97,"Runtime Sakura97 invalido")

local trees=workspace:FindFirstChild("SakuraTrees")
assert(trees and #trees:GetChildren()==27,"Esperava 27 cerejeiras")

local windTagged=0
local petalEmitters=0
for _,obj in ipairs(CollectionService:GetTagged("WindShake")) do
	if obj:IsA("BasePart") and obj.Name=="Leaves" then
		windTagged+=1
		local petals=obj:FindFirstChild("SakuraPetals")
		if petals and petals:IsA("ParticleEmitter") then
			assert(petals.WindAffectsDrag==true,"Petalas sem WindAffectsDrag")
			assert(petals.Drag>0,"Petalas sem Drag para reagir ao vento")
			assert(petals.Rate>0 and petals.Rate<=1.5,"Taxa de petalas fora do limite leve")
			petalEmitters+=1
		end
	end
end
assert(windTagged>=27,"Folhas sem WindShake suficiente: "..tostring(windTagged))
assert(petalEmitters>=27,"Faltam emissores de petalas: "..tostring(petalEmitters))

-- Confirma que os troncos foram levemente enterrados para não parecerem flutuar.
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={trees,workspace:FindFirstChild("StonePath"),workspace:FindFirstChild("Wildflowers")}
local maxTreeOffset=-math.huge
local minTreeOffset=math.huge
for _,tree in ipairs(trees:GetChildren()) do
	local trunk=nil
	for _,d in ipairs(tree:GetDescendants()) do
		if d:IsA("BasePart") and d.Name~="Leaves" then trunk=d break end
	end
	assert(trunk,"Tronco ausente em cerejeira")
	local minY=math.huge
	for _,sx in ipairs({-1,1}) do
		for _,sy in ipairs({-1,1}) do
			for _,sz in ipairs({-1,1}) do
				local p=trunk.CFrame:PointToWorldSpace(Vector3.new(trunk.Size.X*.5*sx,trunk.Size.Y*.5*sy,trunk.Size.Z*.5*sz))
				minY=math.min(minY,p.Y)
			end
		end
	end
	local hit=workspace:Raycast(Vector3.new(trunk.Position.X,80,trunk.Position.Z),Vector3.new(0,-150,0),params)
	assert(hit,"Sem Terrain sob cerejeira")
	local offset=minY-hit.Position.Y
	maxTreeOffset=math.max(maxTreeOffset,offset)
	minTreeOffset=math.min(minTreeOffset,offset)
end
assert(maxTreeOffset<=-.35,"Alguma cerejeira ainda parece flutuar: "..tostring(maxTreeOffset))
assert(minTreeOffset>=-1.15,"Alguma cerejeira ficou enterrada demais: "..tostring(minTreeOffset))

local center=workspace:Raycast(Vector3.new(0,80,0),Vector3.new(0,-120,0))
assert(center and center.Material==Enum.Material.Grass,"Terrain principal nao esta em Grass")

local bend=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TerrainGrassBend")
assert(bend and bend:IsA("LocalScript"),"Efeito local de amassar grama ausente")

local wind=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("WindController")
assert(wind and wind:IsA("LocalScript"),"WindController ausente")
assert(wind:GetAttribute("AssetId")==11946229834,"WindController nao veio do asset pedido")
assert(wind:GetAttribute("ExactCreatorStoreController")==true,"WindController foi reescrito em vez de clonado do asset")
assert(wind:FindFirstChild("WindLines") and wind.WindLines:IsA("ModuleScript"),"WindLines ausente")
assert(wind:FindFirstChild("WindShake") and wind.WindShake:IsA("ModuleScript"),"WindShake ausente")
assert(workspace.GlobalWind.Magnitude>=10,"GlobalWind fraco")

local path=workspace:FindFirstChild("StonePath")
assert(path and path:GetAttribute("AssetId")==136068114177879,"Stone Path asset errado")
assert(path:GetAttribute("ExactModelName")=="Stone Path (Long)","Modelo exato Stone Path (Long) nao usado")
assert(path:GetAttribute("SegmentCount")==9,"Esperava 9 trechos do Stone Path (Long)")
assert(path:GetAttribute("UsesGroundPatches")==false,"O caminho ainda esta pintando Ground/terra")

local segmentCount=0
local stoneParts=0
local visibleStoneParts=0
local samplePart=nil
for _,segment in ipairs(path:GetChildren()) do
	if segment:IsA("Model") and string.find(segment.Name,"Stone Path (Long)",1,true) then
		segmentCount+=1
		local partsInSegment=0
		for _,d in ipairs(segment:GetDescendants()) do
			if d:IsA("BasePart") then
				partsInSegment+=1
				stoneParts+=1
				if d.Transparency<.95 then
					visibleStoneParts+=1
					samplePart=samplePart or d
				end
			end
		end
		assert(partsInSegment==38,"Trecho nao preservou as 38 pedras: "..tostring(partsInSegment))
	end
end

assert(segmentCount==9,"Numero de trechos errado: "..tostring(segmentCount))
assert(stoneParts==342,"Esperava 342 pedras totais, recebeu "..tostring(stoneParts))
assert(visibleStoneParts>=250,"Poucas pedras visiveis: "..tostring(visibleStoneParts))
assert((path:GetAttribute("VisibleParts") or 0)>=250,"Diagnostico de pedras visiveis falhou")

if samplePart then
	local p=RaycastParams.new()
	p.FilterType=Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances={path}
	local hit=workspace:Raycast(samplePart.Position+Vector3.new(0,3,0),Vector3.new(0,-8,0),p)
	assert(not hit or hit.Material~=Enum.Material.Ground,"Ainda existe faixa de Ground/terra embaixo das pedras")
end

local flowers=workspace:FindFirstChild("Wildflowers")
assert(flowers and (flowers:GetAttribute("FlowerCount") or 0)>=180,"Flores pequenas insuficientes")

local Lighting=game:GetService("Lighting")
assert(Lighting.ClockTime>16 and Lighting.ClockTime<18.5,"Nao esta de tarde")

return {
	ok=true,
	trees=#trees:GetChildren(),
	windTaggedLeaves=windTagged,
	stoneSegments=segmentCount,
	stoneParts=stoneParts,
	visibleStoneParts=visibleStoneParts,
	flowers=flowers:GetAttribute("FlowerCount"),
	globalWind=workspace.GlobalWind.Magnitude,
	terrainGrass=true,
	reactiveGrass=true,
	exactWindModules=true,
	petalEmitters=petalEmitters,
	maxTreeOffset=maxTreeOffset,
	minTreeOffset=minTreeOffset
}
