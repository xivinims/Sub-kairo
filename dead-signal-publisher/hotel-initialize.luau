local W=workspace
local SS=game:GetService('ServerStorage')
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local function setWalkingSpeed(character)
 local humanoid=character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid',10)
 if humanoid then humanoid.WalkSpeed=16 end
end
local function preparePlayer(player)
 player.CharacterAdded:Connect(setWalkingSpeed)
 if player.Character then task.spawn(setWalkingSpeed,player.Character) end
end
Players.PlayerAdded:Connect(preparePlayer)
for _,player in ipairs(Players:GetPlayers()) do preparePlayer(player) end
local map=W:FindFirstChild('HotelMap') or SS:FindFirstChild('HotelMap')
assert(map,'Hotel map package missing')
map.Parent=W
local runtime=game:GetService('ServerScriptService').StillHereRuntime
local interactions=require(runtime.MapInteractions)
interactions.Initialize(map)
local receptionist=require(runtime.HotelReceptionist).Initialize(map,interactions)
require(runtime.HotelBlenderDecor).Initialize(receptionist)
W:SetAttribute('WorldReady',true)
W:SetAttribute('GameMode','Match')
if Run:IsRunning() then
 Players.CharacterAutoLoads=true
 for _,player in ipairs(Players:GetPlayers()) do
  if not player.Character then task.spawn(function() player:LoadCharacterAsync() end) end
 end
end
