assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Unexpected Roblox target')
assert(#game.Players:GetPlayers()==0,'Requires isolated execution session')
local incoming=({...})[1]
assert(incoming and incoming.BinaryInput,'Missing binary payload')
local payload=game:GetService('SerializationService'):DeserializeInstancesAsync(incoming.BinaryInput)[1]
assert(payload and payload.Name=='BREUPayload','Unexpected payload')
for _,name in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting','MaterialService','StarterPack','Teams'}) do
 local service=game:GetService(name)
 for _,child in ipairs(service:GetChildren()) do child:Destroy() end
 local incomingService=payload:FindFirstChild(name)
 if incomingService then for _,child in ipairs(incomingService:GetChildren()) do child.Parent=service end end
end
for _,name in ipairs({'StarterPlayerScripts','StarterCharacterScripts'}) do
 local container=game.StarterPlayer:FindFirstChildOfClass(name)
 if container then
  for _,child in ipairs(container:GetChildren()) do child:Destroy() end
  local folder=payload.StarterPlayer:FindFirstChild(name)
  if folder then for _,child in ipairs(folder:GetChildren()) do child.Parent=container end end
 end
end
for _,child in ipairs(workspace:GetChildren()) do
 if not child:IsA('Terrain') and not child:IsA('Camera') then child:Destroy() end
end
workspace.Terrain:Clear()
for name in pairs(workspace:GetAttributes()) do workspace:SetAttribute(name,nil) end
for _,child in ipairs(payload.Workspace:GetChildren()) do child.Parent=workspace end
workspace:SetAttribute('BreuBuild','0.1.0-playtest')
pcall(function() workspace.StreamingEnabled=true end)
pcall(function() workspace.StreamingMinRadius=64;workspace.StreamingTargetRadius=180 end)
workspace.FallenPartsDestroyHeight=-100
local starter=game.StarterPlayer
starter.CameraMode=Enum.CameraMode.Classic
starter.CameraMinZoomDistance=.5;starter.CameraMaxZoomDistance=16
starter.CharacterWalkSpeed=14
local l=game:GetService('Lighting')
l.ClockTime=19;l.Brightness=1.7;l.FogStart=25;l.FogEnd=600
l.Ambient=Color3.fromRGB(64,75,76);l.OutdoorAmbient=Color3.fromRGB(76,89,92);l.FogColor=Color3.fromRGB(37,49,52);l.GlobalShadows=true
payload:Destroy()
