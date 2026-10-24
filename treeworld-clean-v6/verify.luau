local Lighting=game:GetService("Lighting")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterGui=game:GetService("StarterGui")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(Workspace:GetAttribute("WorldRebuildComplete")==true,"Rebuild flag missing")
assert(Workspace:GetAttribute("WorldRebuildVersion")=="2026-10-19-reference-clean-v6","Wrong version")
assert(Workspace:GetAttribute("OldMenuRemoved")==true,"Old menu removal flag missing")
assert(Workspace:GetAttribute("LoadingScreenOnly")==true,"Loading-screen-only flag missing")

-- No old map, no old generic folders.
assert(not Workspace:FindFirstChild("ForestWorld"),"Old ForestWorld still exists")
assert(not Workspace:FindFirstChild("RuinMansion",true),"Old mansion still exists")
assert(not Workspace:FindFirstChild("OvergrownTempleRuins",true),"Old ruins still exist")
assert(not Workspace:FindFirstChild("StoneToriiGate",true),"Old v3 torii still exists")

local world=Workspace:FindFirstChild("ReferenceMap")
assert(world,"ReferenceMap missing")
for _,name in ipairs({"Forest","Path","Torii","House","Portals","Details","Spawn"}) do
	assert(world:FindFirstChild(name),name.." folder missing")
end

-- Menu/UI cleanup: StarterGui must be completely empty.
assert(#StarterGui:GetChildren()==0,"StarterGui is not empty; an old menu/UI remains")
local loader=ReplicatedFirst:FindFirstChild("MapLoadingScreen")
assert(loader and loader:IsA("LocalScript"),"MapLoadingScreen missing")
assert(#ReplicatedFirst:GetChildren()==1,"ReplicatedFirst contains more than the loading screen")

local sps=StarterPlayer.StarterPlayerScripts
for _,child in ipairs(sps:GetChildren()) do
	assert(child.Name=="PortalVFXClient","Unexpected StarterPlayerScript remains: "..child.Name)
end

-- Torii upright and complete.
local toriiFolder=world.Torii
local main=toriiFolder:FindFirstChild("MainTorii")
local distant=toriiFolder:FindFirstChild("DistantTorii")
assert(main and distant,"Main/distant torii missing")
local posts=0
for _,d in ipairs(main:GetDescendants()) do
	if d:IsA("BasePart") and d.Name=="Post" then
		posts+=1
		assert(d.Size.Y<d.Size.X,"Torii post primitive dimension unexpected before rotation")
		-- its local long axis must end up vertical after the 90-degree rotation
		local worldUp=d.CFrame.RightVector
		assert(math.abs(worldUp.Y)>.96,"Torii post is not standing upright")
	end
end
assert(posts==2,"Main torii should have exactly two posts")
assert(main:FindFirstChild("TopBeam",true),"Main torii top beam missing")
assert(main:FindFirstChild("LowerBeam",true),"Main torii lower beam missing")
assert(main:FindFirstChildWhichIsA("Beam",true),"Torii rope/tassel beams missing")

-- Exactly one uploaded house, grounded.
local houseCount=0
local house=nil
for _,c in ipairs(world.House:GetChildren()) do
	if c:IsA("Model") then houseCount+=1;house=c end
end
assert(houseCount==1,"Expected exactly one Japanese house")
assert(Workspace:GetAttribute("JapaneseHouseCount")==1,"House count attribute wrong")
local hb=Workspace:GetAttribute("HouseBottomY")
local hg=Workspace:GetAttribute("HouseGroundY")
assert(type(hb)=="number" and type(hg)=="number","House grounding data missing")
assert(math.abs(hb-hg)<1.25,"House is floating or buried")

-- Forest size and composition.
local treeCount=Workspace:GetAttribute("TreeCount") or 0
assert(treeCount>=450,"Forest is not large/dense enough")
local blockCanopies=0
for _,d in ipairs(world.Forest:GetDescendants()) do
	if d:IsA("BasePart") and d.Name=="Canopy" then blockCanopies+=1 end
end
assert(blockCanopies>=3000,"Low-poly block canopy density too low")

local stoneCount=Workspace:GetAttribute("StoneCount") or 0
assert(stoneCount>=45,"Main stone path is incomplete")

-- Portal system remains, but no portal UI/menu.
assert(Workspace:GetAttribute("PortalCount")==2,"Portal count wrong")
assert(world.Portals:FindFirstChild("PortalA") and world.Portals:FindFirstChild("PortalB"),"Portal models missing")
assert(world.Portals.PortalA:FindFirstChild("Trigger",true),"PortalA trigger missing")
assert(world.Portals.PortalB:FindFirstChild("Trigger",true),"PortalB trigger missing")
assert(ReplicatedStorage:FindFirstChild("PortalVFX"),"PortalVFX remote missing")
assert(ServerScriptService:FindFirstChild("PortalServer"),"Portal server missing")

assert(Lighting:FindFirstChild("ReferenceBlueFog"),"Blue fog missing")
assert(Lighting:FindFirstChild("ReferenceColor"),"Reference color correction missing")

local spawn=world.Spawn:FindFirstChild("ForestSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"Spawn missing")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	version=Workspace:GetAttribute("WorldRebuildVersion"),
	treeCount=treeCount,
	blockCanopies=blockCanopies,
	stoneCount=stoneCount,
	houseCount=houseCount,
	houseGroundDelta=math.abs(hb-hg),
	portals=2,
	starterGuiChildren=#StarterGui:GetChildren(),
	replicatedFirstChildren=#ReplicatedFirst:GetChildren(),
}
