local Lighting=game:GetService("Lighting")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterGui=game:GetService("StarterGui")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion>=108,"Expected saved v108+")
assert(Workspace:GetAttribute("WorldRebuildComplete")==true,"Rebuild flag missing")
assert(Workspace:GetAttribute("WorldRebuildVersion")=="2026-10-19-reference-clean-v6","Wrong version")
assert(Workspace:GetAttribute("OldMenuRemoved")==true,"Menu removal flag missing")
assert(Workspace:GetAttribute("LoadingScreenOnly")==true,"Loading screen flag missing")

local world=Workspace:FindFirstChild("ReferenceMap")
assert(world,"ReferenceMap missing")
assert(not Workspace:FindFirstChild("ForestWorld"),"Old ForestWorld still exists")
assert(not Workspace:FindFirstChild("RuinMansion",true),"Old mansion still exists")
assert(not Workspace:FindFirstChild("OvergrownTempleRuins",true),"Old ruins still exist")

-- No persistent menu/UI at all.
assert(#StarterGui:GetChildren()==0,"StarterGui still contains UI/menu")
local loader=ReplicatedFirst:FindFirstChild("MapLoadingScreen")
assert(loader and loader:IsA("LocalScript"),"MapLoadingScreen missing")
for _,child in ipairs(ReplicatedFirst:GetChildren()) do
	assert(child==loader,"Unexpected ReplicatedFirst child: "..child.Name)
end

local forbidden={"menu","shop","inventory","join","lobby","hud","mainui","mainmenu"}
for _,root in ipairs({
	StarterPlayer.StarterPlayerScripts,
	StarterPlayer.StarterCharacterScripts,
	ServerScriptService,
	ReplicatedStorage,
}) do
	for _,d in ipairs(root:GetDescendants()) do
		local n=string.lower(d.Name)
		for _,word in ipairs(forbidden) do
			assert(not string.find(n,word,1,true),"Old menu/UI script remains: "..d:GetFullName())
		end
	end
end

-- Torii reference scene.
local main=world.Torii:FindFirstChild("MainTorii")
local distant=world.Torii:FindFirstChild("DistantTorii")
assert(main and distant,"Torii pair missing")
local posts=0
for _,d in ipairs(main:GetDescendants()) do
	if d:IsA("BasePart") and d.Name=="Post" then
		posts+=1
		assert(math.abs(d.CFrame.RightVector.Y)>.96,"Torii post is not upright")
	end
end
assert(posts==2,"Main torii posts missing")
assert(main:FindFirstChild("TopBeam",true),"Top beam missing")
assert(main:FindFirstChild("LowerBeam",true),"Lower beam missing")
assert(main:FindFirstChildWhichIsA("Beam",true),"Torii rope missing")

-- Exactly one Japanese house, grounded.
local houseCount=0
for _,c in ipairs(world.House:GetChildren()) do
	if c:IsA("Model") then houseCount+=1 end
end
assert(houseCount==1,"Expected exactly one house")
local hb=Workspace:GetAttribute("HouseBottomY")
local hg=Workspace:GetAttribute("HouseGroundY")
assert(type(hb)=="number" and type(hg)=="number","House ground data missing")
assert(math.abs(hb-hg)<1.25,"House floating/buried")

-- Dense forest/path.
local trees=Workspace:GetAttribute("TreeCount") or 0
local stones=Workspace:GetAttribute("StoneCount") or 0
assert(trees>=450,"Forest too small")
assert(stones>=45,"Stone path incomplete")

local canopies=0
for _,d in ipairs(world.Forest:GetDescendants()) do
	if d:IsA("BasePart") and d.Name=="Canopy" then canopies+=1 end
end
assert(canopies>=3000,"Blocky forest canopy density too low")

-- Portals and VFX, but no portal UI.
assert(Workspace:GetAttribute("PortalCount")==2,"Portal count wrong")
assert(world.Portals:FindFirstChild("PortalA") and world.Portals:FindFirstChild("PortalB"),"Portal models missing")
assert(ServerScriptService:FindFirstChild("PortalServer"),"Portal server missing")
assert(ReplicatedStorage:FindFirstChild("PortalVFX"),"Portal remote missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("PortalVFXClient"),"Portal VFX client missing")

assert(Lighting:FindFirstChild("ReferenceBlueFog"),"Blue fog missing")
assert(Lighting:FindFirstChild("ReferenceColor"),"Reference color missing")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	version=Workspace:GetAttribute("WorldRebuildVersion"),
	trees=trees,
	canopies=canopies,
	stones=stones,
	houseCount=houseCount,
	houseGroundDelta=math.abs(hb-hg),
	portals=2,
	starterGuiChildren=#StarterGui:GetChildren(),
	replicatedFirstChildren=#ReplicatedFirst:GetChildren(),
}
