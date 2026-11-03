-- Adapted from Bconggs' Custom Nametags System (72094860266497).
-- Uses the original BillboardGui, labels, fonts and strokes; progress is server-owned.
local Players=game:GetService('Players')
local ServerStorage=game:GetService('ServerStorage')
local Profiles=require(script.Parent.Profiles)
local Progress=require(script.Parent.Progress)
local Nametags={}
local started=false
local records={}
function Nametags.update(tag,displayName,seconds,xp,ready)
 local name=tag:FindFirstChild('DisplayName')
 local title=tag:FindFirstChild('TenureTitle')
 local level=tag:FindFirstChild('Level')
 name.Text=displayName
 local text=ready and Progress.title(seconds) or ''
 title.Text=text;title.Visible=text~=''
 title.TextColor3=text=='Veterano' and Color3.fromRGB(237,198,115) or Color3.fromRGB(166,217,179)
 level.Text=ready and ('Nível '..Progress.level(xp)) or 'Nível —'
 level.Position=UDim2.fromScale(0,title.Visible and .67 or .47)
end
function Nametags.create(player,character)
 local head=character:WaitForChild('Head',10)
 local humanoid=character:WaitForChild('Humanoid',10)
 if not head or not humanoid or player.Character~=character or not character.Parent then return end
 local old=head:FindFirstChild('FalloutNametag');if old then old:Destroy() end
 humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 local tag=ServerStorage:WaitForChild('FalloutNametagTemplate'):Clone()
 tag.Name='FalloutNametag';tag.Adornee=head;tag.PlayerToHideFrom=player
 Nametags.update(tag,player.DisplayName,player:GetAttribute('PlayTimeSeconds'),player:GetAttribute('XP'),player:GetAttribute('ProfileReady')==true)
 tag.Enabled=humanoid.Health>0;tag.Parent=head
 return tag,humanoid
end
local function updatePlayer(player,record)
 Profiles.Refresh(player)
 local tag=record.tag
 if tag and tag.Parent then
  Nametags.update(tag,player.DisplayName,player:GetAttribute('PlayTimeSeconds'),player:GetAttribute('XP'),player:GetAttribute('ProfileReady')==true)
 end
end
local function remove(player)
 local record=records[player];if not record then return end
 if record.characterConnection then record.characterConnection:Disconnect() end
 if record.deathConnection then record.deathConnection:Disconnect() end
 records[player]=nil
end
local function add(player)
 if records[player] then return end
 local record={};records[player]=record
 local function attach(character)
  local tag,humanoid=Nametags.create(player,character)
  if not tag then return end
  if records[player]~=record or player.Character~=character then tag:Destroy();return end
  if record.deathConnection then record.deathConnection:Disconnect() end
  record.tag=tag
  record.deathConnection=humanoid.Died:Connect(function()tag.Enabled=false end)
 end
 record.characterConnection=player.CharacterAdded:Connect(attach)
 if player.Character then task.spawn(attach,player.Character) end
 updatePlayer(player,record)
end
function Nametags.start()
 if started then return end;started=true
 Players.PlayerAdded:Connect(add);Players.PlayerRemoving:Connect(remove)
 for _,player in ipairs(Players:GetPlayers()) do add(player) end
 task.spawn(function()
  while true do
   task.wait(1)
   for player,record in pairs(records) do updatePlayer(player,record) end
  end
 end)
end
return Nametags
