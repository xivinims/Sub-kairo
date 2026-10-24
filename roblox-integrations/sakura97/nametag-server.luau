local Players=game:GetService("Players")
local template=script:WaitForChild("Nametag")
local function add(player,char)
 local head=char:WaitForChild("Head",10) local humanoid=char:WaitForChild("Humanoid",10)
 if not head or not humanoid or player.Character~=char then return end
 local old=head:FindFirstChild("SweanNametag") if old then old:Destroy() end
 humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 local tag=template:Clone() tag.Name="SweanNametag" tag.Adornee=head tag.MaxDistance=90 tag.AlwaysOnTop=false
 tag.Username.Text=player.DisplayName tag.Username.TextColor3=Color3.new(1,1,1) tag.Username.TextStrokeColor3=Color3.new(0,0,0)
 tag:SetAttribute("SourceAssetId",123212555736117) tag.Parent=head
end
local function hook(player)
 player.CharacterAdded:Connect(function(char) add(player,char) end)
 if player.Character then task.spawn(add,player,player.Character) end
end
Players.PlayerAdded:Connect(hook)
for _,player in ipairs(Players:GetPlayers()) do hook(player) end
