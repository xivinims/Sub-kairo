local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterGui=game:GetService("StarterGui")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(Workspace:GetAttribute("WorldRebuildComplete")==true,"Rebuild missing")
assert(Workspace:GetAttribute("WorldRebuildVersion")=="2026-10-19-bridge-ruins-darkzone-v7","Wrong version")
assert(Workspace:GetAttribute("SingleTorii")==true,"Single torii flag missing")
assert(Workspace:GetAttribute("LoadingSeconds")==3,"Loading screen not 3 seconds")
assert(Workspace:GetAttribute("PortalNearSpawn")==true,"Portal-near-spawn flag missing")
assert(Workspace:GetAttribute("MainBridgePresent")==true,"Main bridge flag missing")
assert(Workspace:GetAttribute("RuinsPresent")==true,"Ruins flag missing")
assert(Workspace:GetAttribute("DarkZonePresent")==true,"Dark zone flag missing")

local world=Workspace:FindFirstChild("ReferenceWorld")
assert(world,"ReferenceWorld missing")
for _,n in ipairs({"Forest","Path","Torii","House","Portals","Water","MainBridge","Ruins","DarkZone","Details","Spawn"}) do
	assert(world:FindFirstChild(n),n.." missing")
end

-- no old menu
assert(#StarterGui:GetChildren()==0,"StarterGui must be empty")
local loader=ReplicatedFirst:FindFirstChild("MapLoadingScreen")
assert(loader and loader:IsA("LocalScript"),"Loading screen missing")
local forbidden={"menu","shop","inventory","join","lobby","mainui","hud"}
for _,root in ipairs({StarterPlayer.StarterPlayerScripts,StarterPlayer.StarterCharacterScripts,ServerScriptService,ReplicatedStorage}) do
	for _,d in ipairs(root:GetDescendants()) do
		local n=string.lower(d.Name)
		for _,w in ipairs(forbidden) do
			assert(not string.find(n,w,1,true),"Old menu/UI object remains: "..d:GetFullName())
		end
	end
end

-- exactly one torii
local toriiCount=0
for _,c in ipairs(world.Torii:GetChildren()) do if c:IsA("Model") then toriiCount+=1 end end
assert(toriiCount==1,"Expected exactly one torii")
local mainTorii=world.Torii:FindFirstChild("MainTorii")
assert(mainTorii and mainTorii:FindFirstChild("TopBeam",true),"Main torii incomplete")

-- few path stones
local stoneCount=Workspace:GetAttribute("PathStoneCount") or 0
assert(stoneCount>=8 and stoneCount<=16,"Path stone count should stay sparse")

-- bridge + water
local bridge=world.MainBridge:FindFirstChild("PhotoWoodBridge")
assert(bridge,"Main detailed bridge missing")
local deckPlanks,railPosts,pillars,vines=0,0,0,0
for _,d in ipairs(bridge:GetDescendants()) do
	if d.Name=="DeckPlank" then deckPlanks+=1 end
	if d.Name=="RailPost" then railPosts+=1 end
	if d.Name=="Pillar" then pillars+=1 end
	if d.Name=="HangingVine" then vines+=1 end
end
assert(deckPlanks>=20,"Bridge deck too simple")
assert(railPosts>=20,"Bridge railings too simple")
assert(pillars>=4,"Bridge pillars missing")
assert(vines>=8,"Bridge vegetation details missing")
local waterSound=world.Water:FindFirstChild("QuietWater",true)
assert(waterSound and waterSound:IsA("Sound") and waterSound.Volume<=.05,"Quiet water audio missing/too loud")

-- ruins detail
local ruins=world.Ruins:FindFirstChild("AncientWhiteRuins")
assert(ruins,"Main ruins missing")
local columns,arches,slabs,fallen,moss=0,0,0,0,0
for _,d in ipairs(ruins:GetDescendants()) do
	if d.Name=="Column" or d.Name=="BrokenColumn" then columns+=1 end
	if d.Name=="ArchBlock" then arches+=1 end
	if d.Name=="FloorSlab" then slabs+=1 end
	if d.Name=="FallenStone" then fallen+=1 end
	if d.Name=="Moss" then moss+=1 end
end
assert(columns>=10,"Not enough columns")
assert(arches>=30,"Arches not detailed enough")
assert(slabs>=70,"Ruins floor not detailed enough")
assert(fallen>=25,"Not enough fallen blocks")
assert(moss>=40,"Ruins moss details missing")

-- dark bridge zone
local dark=world.DarkZone:FindFirstChild("AbyssBridgeZone")
assert(dark,"Dark zone missing")
local lamps=0
for _,d in ipairs(dark:GetDescendants()) do if d.Name=="Lantern" then lamps+=1 end end
assert(lamps>=5,"Dark bridge lamps missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("DarkZoneClient"),"Dark-zone transition client missing")

-- first portal near spawn
local spawn=world.Spawn:FindFirstChild("ForestSpawn")
local portalA=world.Portals:FindFirstChild("PortalA")
local portalB=world.Portals:FindFirstChild("PortalB")
assert(spawn and portalA and portalB,"Spawn/portals missing")
local portalACF=portalA:GetBoundingBox()
local dist=(Vector3.new(portalACF.Position.X,0,portalACF.Position.Z)-Vector3.new(spawn.Position.X,0,spawn.Position.Z)).Magnitude
assert(dist<80,"First portal is too far from spawn")
assert(ServerScriptService:FindFirstChild("PortalServer"),"Portal server missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("PortalVFXClient"),"Portal VFX client missing")

-- exactly one house and grounded
local houseCount=0
for _,c in ipairs(world.House:GetChildren()) do if c:IsA("Model") then houseCount+=1 end end
assert(houseCount==1,"Expected exactly one house")
local hb=Workspace:GetAttribute("HouseBottomY")
local hg=Workspace:GetAttribute("HouseGroundY")
assert(type(hb)=="number" and type(hg)=="number" and math.abs(hb-hg)<1.25,"House grounding wrong")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	version=Workspace:GetAttribute("WorldRebuildVersion"),
	toriiCount=toriiCount,
	pathStones=stoneCount,
	bridge={deckPlanks=deckPlanks,railPosts=railPosts,pillars=pillars,vines=vines},
	ruins={columns=columns,arches=arches,slabs=slabs,fallen=fallen,moss=moss},
	darkLamps=lamps,
	portalDistance=dist,
	houseCount=houseCount,
	trees=Workspace:GetAttribute("TreeCount") or 0,
}
