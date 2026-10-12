
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer").StarterPlayerScripts
local RS=game:GetService("ReplicatedStorage")

local round=SSS:FindFirstChild("NextbotsRoundServer")
local ui=RS:FindFirstChild("NB_UI_TEMPLATE")
local menuClient=ui and ui:FindFirstChild("NextbotsMenuClient")
local roundSrc=round and round.Source or ""
local clientSrc=menuClient and menuClient.Source or ""

return {
 version=game.PlaceVersion,
 randomMaps=string.find(roundSrc,"Random.new",1,true)~=nil,
 skullMarkers=string.find(roundSrc,"NBSpawnMarker",1,true)~=nil,
 sameMapReuse=string.find(roundSrc,"return existing,false",1,true)~=nil,
 freeRoam=string.find(clientSrc,"setFreeRoamMenu",1,true)~=nil,
 unifiedController=SPS:FindFirstChild("NB_EvadeCharacterController")~=nil,
 animationSource=RS:FindFirstChild("NB_R6Animations") and RS.NB_R6Animations:GetAttribute("SourceAssetId"),
}
