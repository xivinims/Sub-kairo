local BUILD_ID="dead-signal-golden-forest-v4"
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local W=workspace
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local SP=game:GetService("StarterPlayer")
local L=game:GetService("Lighting")
local Http=game:GetService("HttpService")
for _,c in ipairs(W:GetChildren()) do if not c:IsA("Camera") and c~=W.Terrain then c:Destroy() end end
W.Terrain:Clear()
for _,s in ipairs({SSS,RS,SP.StarterPlayerScripts,SP.StarterCharacterScripts,game:GetService("StarterGui"),game:GetService("ReplicatedFirst"),L,game:GetService("SoundService")}) do for _,c in ipairs(s:GetChildren()) do c:Destroy() end end
for k in pairs(W:GetAttributes()) do W:SetAttribute(k,nil) end
W.StreamingEnabled=true
local root=Instance.new("Folder");root.Name="AtriumRuntime";root.Parent=SSS
local function module(name,source)
 local m=Instance.new("ModuleScript");m.Name=name;m.Source=source;m.Parent=root;return m
end
local SafeAssetImporter=require(module("SafeAssetImporter",__SAFE_IMPORTER__))
__FOREST_WORLD__
module("DoorService",__DOOR_SERVICE__);module("MapInteractionGuard",__INTERACTION_GUARD__)
local weatherServer=Instance.new("Script");weatherServer.Name="ForestWeatherServer";weatherServer.Source=__WEATHER_SERVER__;weatherServer.Enabled=false;weatherServer.Parent=root
local weatherClient=Instance.new("LocalScript");weatherClient.Name="ForestWeatherClient";weatherClient.Source=__WEATHER_CLIENT__;weatherClient.Parent=SP.StarterPlayerScripts
local settingsModule=Instance.new("ModuleScript");settingsModule.Name="AtriumSettings";settingsModule.Source=__SETTINGS__;settingsModule.Parent=RS
local viewModule=Instance.new("ModuleScript");viewModule.Name="AtriumMenuView";viewModule.Source=__MENU_VIEW__;viewModule.Parent=RS
local remote=Instance.new("RemoteFunction");remote.Name="AtriumSession";remote.Parent=RS
local s=Instance.new("Script");s.Name="AtriumServer";s.Source=__SERVER__;s.Enabled=false;s.Parent=root
local client=Instance.new("LocalScript");client.Name="AtriumClient";client.Source=__CLIENT__;client.Parent=SP.StarterPlayerScripts
local loading=Instance.new("LocalScript");loading.Name="AurivaneLoading";loading.Source=__LOADING__;loading.Parent=game:GetService("ReplicatedFirst")
RS:SetAttribute("AurivaneLogo",__LOGO_ID__)
SP.CameraMode=Enum.CameraMode.Classic;SP.CameraMinZoomDistance=.5;SP.CameraMaxZoomDistance=32;SP.CharacterWalkSpeed=16
W:SetAttribute("DeadSignalBuildId",BUILD_ID);W:SetAttribute("MapSource","Original forest layout using audited creator assets");W:SetAttribute("StalkerPaused",true)
__PREPUBLISH_VALIDATE__
s.Enabled=true
weatherServer.Enabled=true
local prior=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return Http:JSONEncode({ok=true,published=true,build=BUILD_ID,sourceVersion=prior})
