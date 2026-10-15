-- The server plays the exact Cat Bath track. Proximity voice never overrides its arm or leg joints.
local Collection=game:GetService("CollectionService")
local function inspect(npc)
 for _,d in ipairs(npc:GetDescendants())do if d:IsA("ProximityPrompt")then d.Enabled=false end end
end
for _,npc in ipairs(Collection:GetTagged("ForestOwnerNPC"))do inspect(npc)end
local connection=Collection:GetInstanceAddedSignal("ForestOwnerNPC"):Connect(inspect)
script.Destroying:Connect(function()connection:Disconnect()end)
