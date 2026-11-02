assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong experience')
assert(#game.Players:GetPlayers()==0,'Requires isolated execution')
local incoming=({...})[1]
local payload=game:GetService('SerializationService'):DeserializeInstancesAsync(incoming.BinaryInput)[1]
assert(payload and payload.Name=='WaterRPGPayload','Invalid water castle package')
for _,name in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting','MaterialService','StarterPack','Teams'}) do
 local service=game:GetService(name)
 for _,child in ipairs(service:GetChildren()) do child:Destroy() end
 if payload:FindFirstChild(name) then for _,child in ipairs(payload[name]:GetChildren()) do child.Parent=service end end
end
for _,name in ipairs({'StarterPlayerScripts','StarterCharacterScripts'}) do
 local container=game.StarterPlayer:FindFirstChildOfClass(name)
 if container then for _,child in ipairs(container:GetChildren()) do child:Destroy() end
  local f=payload.StarterPlayer:FindFirstChild(name);if f then for _,child in ipairs(f:GetChildren()) do child.Parent=container end end
 end
end
for _,child in ipairs(workspace:GetChildren()) do if not child:IsA('Terrain') and not child:IsA('Camera') then child:Destroy() end end
for name in pairs(workspace:GetAttributes()) do workspace:SetAttribute(name,nil) end
for _,child in ipairs(payload.Workspace:GetChildren()) do child.Parent=workspace end
local region=assert(game.ServerStorage:FindFirstChild('OriginalWaterCastleTerrain'),'Terrain missing')
workspace.Terrain:Clear()
workspace.Terrain:PasteRegion(region,Vector3int16.new(-2816,-192,-512),false)
region:Destroy()
workspace:SetAttribute('RPGTerrainRestored',true)
workspace.Terrain.WaterWaveSize=.12;workspace.Terrain.WaterWaveSpeed=8
workspace.Terrain.WaterTransparency=.35;workspace.Terrain.WaterReflectance=.25
workspace:SetAttribute('WaterRPGBuild','water-rpg-v1-assets')
pcall(function() workspace.StreamingEnabled=true;workspace.StreamingMinRadius=64;workspace.StreamingTargetRadius=220 end)
workspace.FallenPartsDestroyHeight=-750
game.Players.CharacterAutoLoads=false
local marker=workspace.RPGMarkers.Arrival
local terrainParams=RaycastParams.new();terrainParams.FilterType=Enum.RaycastFilterType.Include;terrainParams.FilterDescendantsInstances={workspace.Terrain,workspace.WaterCastleMap};terrainParams.IgnoreWater=false
local function groundAt(v,up,down)
 local hit=workspace:Raycast(v+Vector3.new(0,up or 20,0),Vector3.new(0,-(down or 80),0),terrainParams)
 if hit and hit.Material~=Enum.Material.Water and hit.Normal.Y>.6 then return hit end
end
local found
for _,offset in ipairs({Vector3.zero,Vector3.new(5,0,0),Vector3.new(-5,0,0),Vector3.new(0,0,8),Vector3.new(0,0,-8),Vector3.new(12,0,12)}) do
 local pos=marker.Position+offset;local hit=groundAt(pos,20,100)
 if hit then
  local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={workspace.WaterCastleMap};overlap.RespectCanCollide=true
  local probe=hit.Position+Vector3.new(0,3.4,0)
  if #workspace:GetPartBoundsInBox(CFrame.new(probe),Vector3.new(3,5,3),overlap)==0 then found=hit.Position;break end
 end
end
assert(found,'Source arrival has no safe non-water floor; refusing to publish')
marker.CFrame=CFrame.lookAt(found+Vector3.new(0,.2,0),Vector3.new(1312,found.Y,1800))
local grounded=0
for _,folder in ipairs({workspace.Residents,workspace.TrainingTargets}) do
 for _,npc in ipairs(folder:GetChildren()) do
  local hrp=npc:FindFirstChild('HumanoidRootPart')
  if hrp then
   local hit=groundAt(hrp.Position,4,20)
   if hit then
    local delta=hit.Position.Y+3-hrp.Position.Y;npc:PivotTo(npc:GetPivot()+Vector3.new(0,delta,0));grounded+=1
   end
  end
 end
end
workspace:SetAttribute('RPGGroundedResidents',grounded)
local l=game:GetService('Lighting');local preset=require(game.ReplicatedStorage.WaterRPG.PlayerAssets.LuminosPreset)
l.ClockTime=14;l.Brightness=preset.LightingBrightness;l.Ambient=preset.LightingAmbient;l.OutdoorAmbient=preset.LightingOutdoorAmbient;l.ExposureCompensation=.1
l.GlobalShadows=true;l.FogStart=400;l.FogEnd=4500
for _,v in ipairs(l:GetChildren()) do if v:IsA('BlurEffect') or v:IsA('DepthOfFieldEffect') then v.Enabled=false end end
workspace:SetAttribute('LightingPreset','Luminos / After Rain')
game.StarterPlayer.CameraMode=Enum.CameraMode.Classic;game.StarterPlayer.CameraMinZoomDistance=4;game.StarterPlayer.CameraMaxZoomDistance=22
payload:Destroy()
