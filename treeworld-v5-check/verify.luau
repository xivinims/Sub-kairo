local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion>=107,"Expected saved v107+")
assert(Workspace:GetAttribute("WorldRebuildComplete")==true,"Rebuild flag missing")
assert(Workspace:GetAttribute("WorldRebuildVersion")=="2026-10-19-torii-forest-v5","Wrong rebuild version")

local world=Workspace:FindFirstChild("ToriiForest")
assert(world,"ToriiForest missing")

local houseFolder=world:FindFirstChild("House")
assert(houseFolder,"House folder missing")
local houseCount=0
local house=nil
for _,child in ipairs(houseFolder:GetChildren()) do
	if child:IsA("Model") then houseCount+=1 house=child end
end
assert(houseCount==1,"Expected exactly one Japanese house")
assert(Workspace:GetAttribute("JapaneseHouseCount")==1,"House attribute count wrong")

local storedBottom=Workspace:GetAttribute("HouseBottomY")
local storedGround=Workspace:GetAttribute("HouseGroundY")
assert(type(storedBottom)=="number" and type(storedGround)=="number","House grounding attributes missing")
local groundDelta=math.abs(storedBottom-storedGround)
assert(groundDelta<1.7,"Japanese house is floating or buried")

local torii=world:FindFirstChild("Torii")
local main=torii and torii:FindFirstChild("MainTorii")
local distant=torii and torii:FindFirstChild("DistantTorii")
assert(main and main:FindFirstChild("RoundPost",true),"Main torii missing")
assert(main:FindFirstChild("TopBeam",true),"Torii top beam missing")
assert(main:FindFirstChildWhichIsA("Beam",true),"Torii rope missing")
assert(distant,"Distant torii missing")

local portals=world:FindFirstChild("Portals")
local a=portals and portals:FindFirstChild("PortalA")
local b=portals and portals:FindFirstChild("PortalB")
assert(a and b,"Two portals missing")
assert(a:FindFirstChild("Trigger",true) and b:FindFirstChild("Trigger",true),"Portal triggers missing")
assert(Workspace:GetAttribute("PortalCount")==2,"Portal count wrong")

assert(ReplicatedStorage:FindFirstChild("ToriiPortalVFX"),"Portal VFX remote missing")
assert(ServerScriptService:FindFirstChild("ToriiPortalServer"),"Portal server missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("ToriiPortalVFXClient"),"Portal VFX client missing")

local meshTrees=Workspace:GetAttribute("MeshTreeCount") or 0
local blockTrees=Workspace:GetAttribute("BlockTreeCount") or 0
local slabs=Workspace:GetAttribute("StoneSlabCount") or 0
assert(meshTrees>=430,"Forest mesh tree count too low")
assert(blockTrees>=15,"Block tree count too low")
assert(meshTrees+blockTrees>=450,"Forest is not dense enough")
assert(slabs>=40,"Stone path incomplete")

local meshParts=0
for _,d in ipairs(world:GetDescendants()) do
	if d:IsA("MeshPart") then meshParts+=1 end
end
assert(meshParts>100,"Mesh content missing")

assert(Lighting:FindFirstChild("ToriiBlueFog"),"Blue fog missing")
assert(Lighting:FindFirstChild("ToriiReferenceColor"),"Color correction missing")

local spawnFolder=world:FindFirstChild("Spawn")
local spawn=spawnFolder and spawnFolder:FindFirstChild("ForestSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"Spawn missing")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	version=Workspace:GetAttribute("WorldRebuildVersion"),
	houseAssetId=Workspace:GetAttribute("HouseAssetId"),
	portalAssetId=Workspace:GetAttribute("PortalAssetId"),
	houseCount=houseCount,
	houseGroundDelta=groundDelta,
	meshTrees=meshTrees,
	blockTrees=blockTrees,
	totalTrees=meshTrees+blockTrees,
	stoneSlabs=slabs,
	meshParts=meshParts,
	portals=2,
}
