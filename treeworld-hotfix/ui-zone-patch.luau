local AssetService=game:GetService("AssetService")
local HttpService=game:GetService("HttpService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion>=101,"Cozy UI base not published")
assert(Workspace:GetAttribute("MansionSpawnFixed")==true,"Mansion spawn fix missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldUI"),"TreeWorldUI missing")

local cfg=ReplicatedStorage:FindFirstChild("TreeWorldZoneConfig")
if cfg then cfg:Destroy() end
cfg=Instance.new("ModuleScript")
cfg.Name="TreeWorldZoneConfig"
cfg.Source=[=[
return {
	DefaultZone="Floresta das Árvores",
	Zones={
		{Name="Mansão em Ruínas",Min=Vector3.new(-255.818634,19.966782,-27.836143),Max=Vector3.new(-111.865929,54.547256,62.479599),Priority=100},
		{Name="Entrada da Mansão",Min=Vector3.new(-200,17.694921,-50),Max=Vector3.new(-160,41.694923,-18),Priority=90},
		{Name="Ruínas Antigas",Min=Vector3.new(-220.05,19.311329,-0.05),Max=Vector3.new(-140,52.225002,60.05),Priority=80},
		{Name="Ponte da Floresta",Min=Vector3.new(-89.737244,-2.965412,-120.779648),Max=Vector3.new(-13.404615,21.653929,-95.220352),Priority=70},
		{Name="Ponte do Rio",Min=Vector3.new(-29.879688,-3.465626,163.192139),Max=Vector3.new(101.357262,23.159275,188.807861),Priority=70},
		{Name="Ponte Antiga Abandonada",Min=Vector3.new(749.894165,3.1,-1025.11853),Max=Vector3.new(770.390747,14.3,-974.482666),Priority=70},
		{Name="Ponte Antiga Abandonada",Min=Vector3.new(873.909546,3.1,636.65564),Max=Vector3.new(926.478027,14.3,661.727234),Priority=70},
		{Name="Ponte Antiga Abandonada",Min=Vector3.new(-979.1203,3.1,-772.487061),Max=Vector3.new(-940.646973,14.3,-727.858154),Priority=70},
		{Name="Margem do Rio",Min=Vector3.new(-69.465088,-0.9875,-260.050873),Max=Vector3.new(56.400085,13.195,260.174713),Priority=50},
	}
}
]=]
cfg.Parent=ReplicatedStorage

Workspace:SetAttribute("CozyUIInstalled",true)
Workspace:SetAttribute("CozyUIVersion","2026-10-14-cozy-ui-v3-precise-bridges")
Workspace:SetAttribute("CozyUIZoneCount",9)
Workspace:SetAttribute("CozyUIBridgeZoneCount",5)

local sourceVersion=game.PlaceVersion
AssetService:SavePlaceAsync()
return HttpService:JSONEncode({
	applied=true,
	sourceVersion=sourceVersion,
	uiVersion=Workspace:GetAttribute("CozyUIVersion"),
	zoneCount=9,
	bridgeZones=5
})
