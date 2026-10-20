local Players=game:GetService('Players')
local C=require(game:GetService('ReplicatedStorage'):WaitForChild('PhotoWorldConfig'))
-- Keep a streamed landing available before releasing a newly spawned character.
local function prepare(player,character)
 local root=character:WaitForChild('HumanoidRootPart',15)
 if not root then return end
 local h=C.surface(C.Spawn.X,C.Spawn.Z)
 character:PivotTo(CFrame.new(C.Spawn.X,h+4,C.Spawn.Z))
end
Players.PlayerAdded:Connect(function(player)
 player.CharacterAdded:Connect(function(character)prepare(player,character)end)
end)
for _,player in ipairs(Players:GetPlayers())do
 player.CharacterAdded:Connect(function(character)prepare(player,character)end)
 if player.Character then prepare(player,player.Character)end
end
