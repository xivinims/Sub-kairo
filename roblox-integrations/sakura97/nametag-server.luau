local Players=game:GetService("Players")
local template=script:WaitForChild("Nametag")
local function cantor(player,head)
 local old=head:FindFirstChild("CantorBadge") if old then old:Destroy() end
 if player:GetAttribute("Cantor")~=true then return end
 local badge=Instance.new("BillboardGui") badge.Name="CantorBadge" badge.Adornee=head badge.Size=UDim2.fromOffset(110,24) badge.StudsOffset=Vector3.new(0,3.15,0) badge.MaxDistance=65 badge.AlwaysOnTop=false badge.Parent=head
 local label=Instance.new("TextLabel") label.BackgroundColor3=Color3.fromRGB(22,17,21) label.BackgroundTransparency=.2 label.Size=UDim2.fromScale(1,1) label.Text="♫ CANTOR" label.Font=Enum.Font.GothamBold label.TextSize=12 label.TextColor3=Color3.fromRGB(235,207,210) label.Parent=badge
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,8) corner.Parent=label
 local stroke=Instance.new("UIStroke") stroke.Color=Color3.fromRGB(146,42,49) stroke.Transparency=.3 stroke.Thickness=1 stroke.Parent=label
end
local function add(player,char)
 local head=char:WaitForChild("Head",10) local humanoid=char:WaitForChild("Humanoid",10)
 if not head or not humanoid or player.Character~=char then return end
 local old=head:FindFirstChild("SweanNametag") if old then old:Destroy() end
 humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 local tag=template:Clone() tag.Name="SweanNametag" tag.Adornee=head tag.MaxDistance=90 tag.AlwaysOnTop=false
 tag.Username.Text=player.DisplayName tag.Username.TextColor3=Color3.new(1,1,1) tag.Username.TextStrokeColor3=Color3.new(0,0,0)
 tag:SetAttribute("SourceAssetId",123212555736117) tag.Parent=head
 cantor(player,head)
end
local function hook(player)
 player.CharacterAdded:Connect(function(char) add(player,char) end)
 player:GetAttributeChangedSignal("Cantor"):Connect(function() local head=player.Character and player.Character:FindFirstChild("Head") if head then cantor(player,head) end end)
 if player.Character then task.spawn(add,player,player.Character) end
end
Players.PlayerAdded:Connect(hook)
for _,player in ipairs(Players:GetPlayers()) do hook(player) end
