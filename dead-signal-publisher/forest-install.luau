local BUILD_ID="still-here-light-weather-v8"
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
local client=Instance.new("LocalScript");client.Name="ForestCamera";client.Source="local p=game:GetService('Players').LocalPlayer; p.CameraMode=Enum.CameraMode.Classic;workspace.CurrentCamera.FieldOfView=65";client.Parent=SP.StarterPlayerScripts
SP.CameraMode=Enum.CameraMode.Classic;SP.CameraMinZoomDistance=.5;SP.CameraMaxZoomDistance=32;SP.CharacterWalkSpeed=16
W:SetAttribute("DeadSignalBuildId",BUILD_ID);W:SetAttribute("MapSource","Original forest layout using audited creator assets");W:SetAttribute("StalkerPaused",true)
__PREPUBLISH_VALIDATE__
local prior=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return Http:JSONEncode({ok=true,published=true,build=BUILD_ID,sourceVersion=prior})
