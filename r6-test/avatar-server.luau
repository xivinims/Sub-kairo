-- Integration only: the uploaded animation sources are kept unchanged.
local Players = game:GetService('Players')
Players.CharacterAutoLoads = false
local busy = {}
local function spawn(player)
 if busy[player] or player.Parent ~= Players then return end
 busy[player] = true
 local description
 for attempt = 1, 3 do
  local ok, result = pcall(Players.GetHumanoidDescriptionFromUserIdAsync, Players, player.UserId)
  if ok then description = result; break end
  task.wait(attempt)
 end
 if not description then
  busy[player] = nil
  warn('Não foi possível carregar o avatar de '..player.Name..'; nova tentativa em 5s')
  task.delay(5, function() spawn(player) end)
  return
 end
 local ok, character = pcall(Players.CreateHumanoidModelFromDescriptionAsync, Players, description, Enum.HumanoidRigType.R6)
 description:Destroy()
 if not ok then
  busy[player] = nil
  warn('Falha criando avatar R6: '..tostring(character))
  task.delay(5, function() spawn(player) end)
  return
 end
 if player.Parent ~= Players then character:Destroy(); busy[player] = nil; return end
 character.Name = player.Name
 local humanoid = character:FindFirstChildOfClass('Humanoid')
 assert(humanoid.RigType == Enum.HumanoidRigType.R6)
 humanoid.DisplayName = player.DisplayName
 if not humanoid:FindFirstChildOfClass('Animator') then Instance.new('Animator', humanoid) end
 for _, child in ipairs(game.StarterPlayer.StarterCharacterScripts:GetChildren()) do
  local previous = character:FindFirstChild(child.Name)
  if previous then previous:Destroy() end
  child:Clone().Parent = character
 end
 local previous = player.Character
 character:PivotTo(workspace.TestArena.Spawn.CFrame + Vector3.new(0, 4, 0))
 player.Character = character
 character.Parent = workspace
 if previous and previous ~= character then previous:Destroy() end
 busy[player] = nil
 humanoid.Died:Once(function()
  task.delay(Players.RespawnTime, function() spawn(player) end)
 end)
end
Players.PlayerAdded:Connect(function(player) task.spawn(spawn, player) end)
Players.PlayerRemoving:Connect(function(player) busy[player] = nil end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(spawn, player) end
