local BUILD_ID="dead-signal-map-focus-v3"
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Dead Signal target")
local W=game:GetService("Workspace")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local SP=game:GetService("StarterPlayer")
local Lighting=game:GetService("Lighting")
local Http=game:GetService("HttpService")
local CollectionService=game:GetService("CollectionService")
local importerModule=Instance.new("ModuleScript"); importerModule.Source=__IMPORTER__
local Importer=require(importerModule)
local map,report=Importer.Load({id=18509954401,importMode="static",stripScripts=true})
map.Name="PoppyTestMap"
local originalParts=0
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("Sound") or d:IsA("Animation") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("PackageLink") or d:IsA("SpawnLocation") or d:IsA("Humanoid") or d:IsA("AnimationController") then d:Destroy()
 elseif d:IsA("BasePart") then
  originalParts+=1; d.Anchored=true; d.CanTouch=false
  if d.Material~=Enum.Material.Glass and d.Reflectance>0.15 then d.Reflectance=0.1 end
  local n=d.Name:lower()
  if n=="bush" or n=="leaves" or n:find("trees") and not n:find("cube") and not n:find("cylinder.003") and not n:find("cylinder.004") then d.CanCollide=false; d.CanQuery=false end
  if d:IsA("MeshPart") then d.RenderFidelity=Enum.RenderFidelity.Performance end
  if d.CanCollide and d:IsA("TriangleMeshPart") then pcall(function() d.CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition end) end
 elseif d:IsA("Light") then d.Enabled=false; d.Shadows=false; CollectionService:AddTag(d,"DeadSignalMapLight"); d:SetAttribute("SectorId","PARK")
 elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled=false end
end
map:PivotTo(CFrame.new(-Vector3.new(24.8521824,141.9106909,1.5578613))*map:GetPivot())
map:SetAttribute("SourceAssetId",18509954401); map:SetAttribute("RemovedExternalScripts",report.removedScripts)
for _,child in ipairs(W:GetChildren()) do if child~=W.Terrain and not child:IsA("Camera") then child:Destroy() end end
W.Terrain:Clear()
for _,service in ipairs({RS,SSS,game:GetService("ReplicatedFirst"),game:GetService("StarterGui"),SP.StarterPlayerScripts,SP.StarterCharacterScripts,Lighting,game:GetService("SoundService")}) do for _,d in ipairs(service:GetChildren()) do d:Destroy() end end
for key in pairs(W:GetAttributes()) do W:SetAttribute(key,nil) end
map.Parent=W; W.StreamingEnabled=true
Lighting.ClockTime=16.7; Lighting.Brightness=1.7; Lighting.GlobalShadows=true
Lighting.Ambient=Color3.fromRGB(76,83,91); Lighting.OutdoorAmbient=Color3.fromRGB(102,111,117)
Lighting.EnvironmentDiffuseScale=0.55; Lighting.EnvironmentSpecularScale=0.5
Lighting.ExposureCompensation=0.12
local grade=Instance.new("ColorCorrectionEffect"); grade.Name="MapColourGrade"; grade.Contrast=0.06; grade.Saturation=-0.1; grade.Brightness=0.015; grade.Parent=Lighting
local bloom=Instance.new("BloomEffect"); bloom.Name="RestrainedFixtureBloom"; bloom.Intensity=0.1; bloom.Size=15; bloom.Threshold=1.7; bloom.Parent=Lighting
local atmosphere=Instance.new("Atmosphere"); atmosphere.Density=0.17; atmosphere.Offset=0.1; atmosphere.Haze=1.2; atmosphere.Color=Color3.fromRGB(175,188,197); atmosphere.Decay=Color3.fromRGB(100,114,123); atmosphere.Parent=Lighting
local root=Instance.new("Folder"); root.Name="DeadSignalMap"; root.Parent=SSS
local function module(name,source,parent)
 local m=Instance.new("ModuleScript"); m.Name=name; m.Source=source; m.Parent=parent or root; return m
end
module("DoorService",__DOOR_SERVICE__)
module("PowerService",__POWER_SERVICE__)
module("DebugService",__DEBUG_SERVICE__)
local function part(parent,name,size,cf,color,material,collide)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Anchored=true; p.CanTouch=false
 p.CanCollide=collide~=false; p.CanQuery=p.CanCollide; p.Color=color or Color3.fromRGB(76,87,83); p.Material=material or Enum.Material.Metal
 p.CastShadow=p.CanCollide; p.Parent=parent; return p
end
__MAP_DRESSING__
SP.CameraMode=Enum.CameraMode.LockFirstPerson; SP.CameraMinZoomDistance=0.5; SP.CameraMaxZoomDistance=0.5; SP.CharacterWalkSpeed=18
local server=Instance.new("Script"); server.Name="MapRuntime"; server.Enabled=false; server.Source=__SERVER__; server.Parent=root
local client=Instance.new("LocalScript"); client.Name="MapEnvironment"; client.Source=__CLIENT__; client.Parent=SP.StarterPlayerScripts
W:SetAttribute("DeadSignalBuildId",BUILD_ID); W:SetAttribute("MapFocus",true); W:SetAttribute("StalkerPaused",true); W:SetAttribute("MapSourceAssetId",18509954401)
__PREPUBLISH_VALIDATE__
server.Enabled=true
local prior=game.PlaceVersion
game:GetService("AssetService"):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return Http:JSONEncode({ok=true,published=true,build=BUILD_ID,sourceVersion=prior,originalParts=originalParts,doors=#CollectionService:GetTagged("DeadSignalMapDoor"),hubs=#hubs})
