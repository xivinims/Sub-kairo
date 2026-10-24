-- Friendship is evaluated locally: a marker never reveals someone else's connections.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local joinedSound=RS:WaitForChild("XNMedia"):WaitForChild("FriendJoined"):Clone()
joinedSound.Parent=game:GetService("SoundService")
local watched={}
local function marker(other,char)
 local head=char:WaitForChild("Head",10)
 if not head or not other.Parent or other.Character~=char then return end
 local old=head:FindFirstChild("LocalFriendMarker") if old then old:Destroy() end
 local tag=Instance.new("BillboardGui") tag.Name="LocalFriendMarker" tag.Adornee=head
 tag.Size=UDim2.fromOffset(94,22) tag.StudsOffsetWorldSpace=Vector3.new(0,3.1,0)
 tag.MaxDistance=90 tag.AlwaysOnTop=false tag.Enabled=player:GetAttribute("ShowNametags")~=false
 local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=.32
 label.BackgroundColor3=Color3.fromRGB(28,30,31) label.Text="● amizade" label.TextColor3=Color3.fromRGB(212,226,215)
 label.Font=Enum.Font.GothamMedium label.TextSize=12 label.Parent=tag
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=label
 tag.Parent=head
end
local function watch(other,notify)
 if other==player or watched[other] then return end
 local record={} watched[other]=record
 local ok,isFriend=false,false
 for attempt=1,3 do
  ok,isFriend=pcall(function() return player:IsFriendsWithAsync(other.UserId) end)
  if ok or not other.Parent then break end task.wait(attempt)
 end
 if watched[other]~=record or not other.Parent or not ok or not isFriend then return end
 record.connection=other.CharacterAdded:Connect(function(char) task.spawn(marker,other,char) end)
 if other.Character then task.spawn(marker,other,other.Character) end
 if notify and player:GetAttribute("FriendAlerts")~=false then joinedSound:Stop() joinedSound:Play() end
end
Players.PlayerAdded:Connect(function(other) task.spawn(watch,other,true) end)
Players.PlayerRemoving:Connect(function(other)
 local record=watched[other] if record and record.connection then record.connection:Disconnect() end watched[other]=nil
end)
for _,other in ipairs(Players:GetPlayers()) do task.spawn(watch,other,false) end
player:GetAttributeChangedSignal("ShowNametags"):Connect(function()
 for other in pairs(watched) do
  local head=other.Character and other.Character:FindFirstChild("Head")
  local tag=head and head:FindFirstChild("LocalFriendMarker")
  if tag then tag.Enabled=player:GetAttribute("ShowNametags")~=false end
 end
end)
