local W=workspace
local SS=game:GetService('ServerStorage')
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local map=W:FindFirstChild('HotelMap') or SS:FindFirstChild('HotelMap')
assert(map,'Hotel map package missing')
map.Parent=W
require(game:GetService('ServerScriptService').StillHereRuntime.MapInteractions).Initialize(map)
W:SetAttribute('WorldReady',true)
W:SetAttribute('GameMode','Match')
if Run:IsRunning() then
 Players.CharacterAutoLoads=true
 for _,player in ipairs(Players:GetPlayers()) do
  if not player.Character then task.spawn(function() player:LoadCharacterAsync() end) end
 end
end
