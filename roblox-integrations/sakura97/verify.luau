assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local SSS=game:GetService("ServerScriptService")
local SP=game:GetService("StarterPlayer")
local Terrain=workspace.Terrain

local rt=RS:FindFirstChild("XNWorldRuntime")
assert(rt and rt:GetAttribute("Version")==110,"XNWorldRuntime v110 missing")
assert(rt:GetAttribute("GameName")=="XN [VOICE]","game name identity wrong")
assert(rt:GetAttribute("WorldSize")==248000,"world size wrong")
assert(rt:GetAttribute("WorldHalf")==124000,"world half wrong")
assert(rt:GetAttribute("LandHalf")==112000,"land edge wrong")
assert(rt:GetAttribute("ChunkSize")==512,"chunk size wrong")
assert(rt:GetAttribute("WaterDepth")==6,"water is not shallow")
assert(rt:GetAttribute("Border")=="WaterBelt","edge is not water belt")
assert(rt:GetAttribute("PBRAssetId")==13536410655,"PBR pack wrong")
assert(rt:GetAttribute("HDAssetId")==18242663106,"HD pack wrong")
assert(rt:GetAttribute("RockAssetId")==8248445118,"rock pack wrong")
assert(rt:GetAttribute("BigTreeAssetId")==86013526879602,"big tree wrong")
assert(rt:GetAttribute("ButterflySource")=="Procedural3D","butterfly source wrong")

-- Old city/build artifacts must be fully gone.
for _,name in ipairs({
	"BrookhavenMap","XN_City","BigMapTest","Mirkwood","ReworkedHouseLots","GreenGrassDecor",
	"XN_Grass","XN_Halloween","PumpkinDecor","SakuraTrees","PristineParkIsland"
}) do
	assert(not workspace:FindFirstChild(name),name.." survived reset")
end
assert(not RS:FindFirstChild("XNRuntime"),"old XNRuntime survived")
assert(not RS:FindFirstChild("SweanRuntime"),"old SweanRuntime survived")
assert(#game:GetService("ReplicatedFirst"):GetChildren()==0,"old loading UI survived")
assert(#game:GetService("StarterGui"):GetChildren()==0,"old custom UI survived")

local templates=SS:FindFirstChild("XNNatureTemplates")
assert(templates,"nature templates missing")
assert(templates:FindFirstChild("Trees") and #templates.Trees:GetChildren()>0,"trees missing")
assert(templates:FindFirstChild("Plants") and #templates.Plants:GetChildren()>0,"plants missing")
assert(templates:FindFirstChild("Flowers") and #templates.Flowers:GetChildren()>0,"flowers missing")
assert(templates:FindFirstChild("Rocks") and #templates.Rocks:GetChildren()>0,"exact rocks missing")
assert(templates:FindFirstChild("BigTrees") and #templates.BigTrees:GetChildren()==1,"big tree missing")
assert(templates.BigTrees:GetChildren()[1]:GetAttribute("AssetId")==86013526879602,"big tree source wrong")

local clientAssets=RS:FindFirstChild("XNNatureClientAssets")
assert(clientAssets and clientAssets:FindFirstChild("LeafTemplate"),"real leaf geometry missing")
assert(clientAssets.LeafTemplate:GetAttribute("FromNaturePack")==true,"leaf not from nature pack")
local butterfly=clientAssets and clientAssets:FindFirstChild("ButterflyTemplate")
assert(butterfly and butterfly:GetAttribute("Source")=="Procedural3D" and butterfly:GetAttribute("AnimatedWings")==true,"butterfly template wrong")

local client=SP.StarterPlayerScripts:FindFirstChild("XNNatureClient")
assert(client and client:IsA("LocalScript"),"nature client missing")
assert(client:GetAttribute("WindAssetId")==11946229834,"wind asset wrong")
assert(client:FindFirstChild("WindLines") and client:FindFirstChild("WindShake"),"wind modules missing")
assert(client.Source:find("XNLeafSource",1,true),"falling leaves not tied to real tree leaves")
assert(client.Source:find("XNFlowerSource",1,true),"butterflies not tied to flowers")

local gen=SSS:FindFirstChild("XNWorldGenerator")
assert(gen and gen:IsA("Script"),"world generator missing")
assert(gen.Source:find("WORLD_HALF=124000",1,true),"world boundary wrong")
assert(gen.Source:find("LAND_HALF=112000",1,true),"water belt start wrong")
assert(gen.Source:find("WATER_DEPTH=6",1,true),"deep water generator detected")
assert(gen.Source:find("generateRivers",1,true) and gen.Source:find("generateLake",1,true),"rivers/lakes missing")
assert(gen.Source:find("generateIsland",1,true),"far islands missing")
assert(gen.Source:find("generateTrails",1,true),"trails missing")

assert(workspace:FindFirstChild("XNSpawn"),"spawn missing")
assert(workspace.GlobalWind.Magnitude>10,"global wind missing")

-- Saved center must be actual Terrain grass, not a fake baseplate.
local rp=RaycastParams.new()
rp.FilterType=Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances={Terrain}
local hit=workspace:Raycast(Vector3.new(0,40,0),Vector3.new(0,-100,0),rp)
assert(hit and hit.Material==Enum.Material.Grass,"central real grass terrain missing")

return {
	ok=true,
	version=110,
	worldSize=rt:GetAttribute("WorldSize"),
	landHalf=rt:GetAttribute("LandHalf"),
	chunk=rt:GetAttribute("ChunkSize"),
	waterDepth=rt:GetAttribute("WaterDepth"),
	treeTemplates=#templates.Trees:GetChildren(),
	plantTemplates=#templates.Plants:GetChildren(),
	flowerTemplates=#templates.Flowers:GetChildren(),
	rockTemplates=#templates.Rocks:GetChildren(),
	bigTrees=#templates.BigTrees:GetChildren(),
	wind=true,
	fallingLeaves=true,
	butterflies=true,
	border="WaterBelt"
}
