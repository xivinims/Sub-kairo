local HttpService=game:GetService("HttpService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion>=102,"UI zone hotfix not published")
assert(Workspace:GetAttribute("MansionSpawnFixed")==true,"Spawn fix regressed")
assert(Workspace:GetAttribute("CozyUIVersion")=="2026-10-14-cozy-ui-v3-precise-bridges","Wrong UI version")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldUI"),"TreeWorldUI missing")

local cfg=ReplicatedStorage:FindFirstChild("TreeWorldZoneConfig")
assert(cfg and cfg:IsA("ModuleScript"),"TreeWorldZoneConfig missing")
local data=require(cfg)
assert(type(data)=="table" and type(data.Zones)=="table" and #data.Zones==9,"Zone config invalid")

local bridges=0
for _,z in ipairs(data.Zones) do
	if string.find(z.Name,"Ponte",1,true) then
		bridges+=1
		assert((z.Max.X-z.Min.X)<192,"Bridge X zone too large")
		assert((z.Max.Z-z.Min.Z)<192,"Bridge Z zone too large")
	end
end
assert(bridges==5,"Expected five precise bridge zones")

local spawn=Workspace.ForestWorld:FindFirstChild("ForestSpawn")
assert(spawn and spawn:IsA("SpawnLocation") and spawn.Enabled,"ForestSpawn invalid")
assert(spawn.Position.Z < -20,"Spawn moved inside mansion again")

return HttpService:JSONEncode({
	placeVersion=game.PlaceVersion,
	uiVersion=Workspace:GetAttribute("CozyUIVersion"),
	zoneCount=#data.Zones,
	bridgeZones=bridges,
	spawnFixStillValid=true,
	spawn={x=spawn.Position.X,y=spawn.Position.Y,z=spawn.Position.Z}
})
