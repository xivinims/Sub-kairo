-- Humanoids may re-enable torso/head CanCollide on load. Use collision groups
-- for avatar contact while preserving Default-group cursor/raycast selection.
local Players=game:GetService('Players')
local Physics=game:GetService('PhysicsService')
local group='OveryardPlayers'
if not Physics:IsCollisionGroupRegistered(group) then Physics:RegisterCollisionGroup(group) end
if not Physics:IsCollisionGroupRegistered('CaioNonBlocking') then Physics:RegisterCollisionGroup('CaioNonBlocking') end
Physics:CollisionGroupSetCollidable(group,'CaioNonBlocking',false)
local function characterAdded(character)
 local function assign(part)
  if part:IsA('BasePart') then
   if part.CollisionGroup=='Default' then part.CollisionGroup=group
   else Physics:CollisionGroupSetCollidable(part.CollisionGroup,'CaioNonBlocking',false) end
  end
 end
 character.DescendantAdded:Connect(assign)
 for _,part in ipairs(character:GetDescendants()) do assign(part) end
end
local function playerAdded(player)
 player.CharacterAdded:Connect(characterAdded)
 if player.Character then characterAdded(player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _,player in ipairs(Players:GetPlayers()) do playerAdded(player) end
