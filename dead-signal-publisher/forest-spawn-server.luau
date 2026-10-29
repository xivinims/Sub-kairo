while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players')
local function character(player,char)
 local hum=char:WaitForChild('Humanoid',15)
 local head=char:WaitForChild('Head',15)
 if not hum or not head then return end
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 local old=head:FindFirstChild('ForestNameTag');if old then old:Destroy() end
 local tag=Instance.new('BillboardGui')
 tag.Name='ForestNameTag';tag.Size=UDim2.fromOffset(180,42);tag.StudsOffsetWorldSpace=Vector3.new(0,2.3,0)
 tag.MaxDistance=65;tag.AlwaysOnTop=false;tag.Adornee=head;tag.Parent=head
 local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1
 text.Text=player.DisplayName;text.Font=Enum.Font.GothamMedium;text.TextSize=16
 text.TextColor3=Color3.fromRGB(245,239,211);text.TextStrokeTransparency=.55;text.Parent=tag
 local sub=Instance.new('TextLabel');sub.Size=UDim2.new(1,0,0,14);sub.Position=UDim2.fromOffset(0,27)
 sub.BackgroundTransparency=1;sub.Text='@'..player.Name;sub.Font=Enum.Font.Gotham;sub.TextSize=11
 sub.TextColor3=Color3.fromRGB(195,201,178);sub.TextStrokeTransparency=.7;sub.Parent=tag
end
local function added(p)
 p.CharacterAdded:Connect(function(c) character(p,c) end)
 if p.Character then task.spawn(character,p,p.Character) end
end
Players.PlayerAdded:Connect(added)
for _,p in ipairs(Players:GetPlayers()) do added(p) end
