local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")
assert(Workspace:GetAttribute("WorldRebuildComplete")==true,"Rebuild flag missing")
assert(Workspace:GetAttribute("WorldRebuildVersion")=="2026-10-19-torii-forest-v5","Wrong rebuild version")

local world=Workspace:FindFirstChild("ToriiForest")
assert(world,"ToriiForest missing")
for _,name in ipairs({"Trees","DistantForest","StonePath","Torii","House","Portals","Details","Spawn"}) do
	assert(world:FindFirstChild(name),name.." folder missing")
end

local houseFolder=world.House
local houseCount=0
local house=nil
for _,child in ipairs(houseFolder:GetChildren()) do
	if child:IsA("Model") then houseCount+=1 house=child end
end
assert(houseCount==1,"Expected exactly one Japanese house")
assert(Workspace:GetAttribute("JapaneseHouseCount")==1,"House count attribute wrong")
assert(Workspace:GetAttribute("HouseAssetId") and Workspace:GetAttribute("HouseAssetId")>0,"House asset ID missing")

local cf,size=house:GetBoundingBox()
local bottom=cf.Position.Y-size.Y/2
local ray=Workspace:Raycast(Vector3.new(cf.Position.X,bottom+8,cf.Position.Z),Vector3.new(0,-18,0))
assert(ray and ray.Instance==Workspace.Terrain,"House is not standing over terrain")
assert(math.abs(bottom-ray.Position.Y)<1.7,"Japanese house is floating or buried")

local mainTorii=world.Torii:FindFirstChild("MainTorii")
local distantTorii=world.Torii:FindFirstChild("DistantTorii")
assert(mainTorii and mainTorii:FindFirstChild("RoundPost",true),"Main torii missing")
assert(mainTorii:FindFirstChild("TopBeam",true),"Main torii top beam missing")
assert(mainTorii:FindFirstChild("LowerBeam",true),"Main torii lower beam missing")
assert(mainTorii:FindFirstChildWhichIsA("Beam",true),"Main torii rope missing")
assert(distantTorii,"Distant torii missing")

local portals=world.Portals
local portalA=portals:FindFirstChild("PortalA")
local portalB=portals:FindFirstChild("PortalB")
assert(portalA and portalB,"Two uploaded portals missing")
assert(portalA:FindFirstChild("Trigger",true) and portalB:FindFirstChild("Trigger",true),"Portal trigger missing")
assert(Workspace:GetAttribute("PortalCount")==2,"Portal count attribute wrong")
assert(Workspace:GetAttribute("PortalAssetId") and Workspace:GetAttribute("PortalAssetId")>0,"Portal asset ID missing")
assert(ReplicatedStorage:FindFirstChild("ToriiPortalVFX"),"Portal VFX remote missing")
assert(ServerScriptService:FindFirstChild("ToriiPortalServer"),"Portal server missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("ToriiPortalVFXClient"),"Portal client VFX missing")

local meshTrees=Workspace:GetAttribute("MeshTreeCount") or 0
local blockTrees=Workspace:GetAttribute("BlockTreeCount") or 0
assert(meshTrees>=430,"Forest is not dense enough")
assert(blockTrees>=15,"Reference block trees missing")
assert(meshTrees+blockTrees>=450,"Forest total too small")

local slabCount=Workspace:GetAttribute("StoneSlabCount") or 0
assert(slabCount>=40,"Stone path is incomplete")

local meshParts=0
for _,d in ipairs(world:GetDescendants()) do
	if d:IsA("MeshPart") then meshParts+=1 end
end
assert(meshParts>100,"Uploaded/forest mesh content appears missing")

assert(Lighting:FindFirstChild("ToriiBlueFog"),"Blue fog atmosphere missing")
assert(Lighting:FindFirstChild("ToriiReferenceColor"),"Reference color correction missing")
assert(Lighting:FindFirstChild("ToriiSoftRays"),"Soft rays missing")

local spawn=world.Spawn:FindFirstChild("ForestSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"Spawn missing")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	version=Workspace:GetAttribute("WorldRebuildVersion"),
	houseAssetId=Workspace:GetAttribute("HouseAssetId"),
	portalAssetId=Workspace:GetAttribute("PortalAssetId"),
	houseCount=houseCount,
	houseGroundDelta=math.abs(bottom-ray.Position.Y),
	meshTrees=meshTrees,
	blockTrees=blockTrees,
	stoneSlabs=slabCount,
	meshParts=meshParts,
	portals=2,
	spawn={x=spawn.Position.X,y=spawn.Position.Y,z=spawn.Position.Z},
}
