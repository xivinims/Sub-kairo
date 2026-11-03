-- Seat access, a permanently unlocked front entrance, and a weapon-free loadout.
local Players=game:GetService('Players')
local SSS=game:GetService('ServerScriptService')
local CollectionService=game:GetService('CollectionService')
while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local content=workspace:WaitForChild('Content',30)
if not content then warn('[MysteryWorld] Map did not load');return end
local doorManager=require(SSS:WaitForChild('DoorManager'))
local front=content:FindFirstChild('Exterior') and content.Exterior:FindFirstChild('House')
front=front and front:FindFirstChild('Front')
front=front and front:FindFirstChild('FrontDoor')
local function findEntranceDoor(leaf)
 if not leaf then return nil end
 for _,candidate in ipairs(leaf:GetDescendants()) do
  if candidate:IsA('Model') and candidate.Name:match('^Door_Interior_Frame_[AB]$') then return candidate end
 end
 return leaf:FindFirstChildWhichIsA('Model')
end
for _,name in ipairs({'EntranceDoorA','EntranceDoorB'}) do
 local leaf=front and front:FindFirstChild(name)
 local door=findEntranceDoor(leaf)
 if door then
  CollectionService:RemoveTag(door,'DoorLocked')
  for _,d in ipairs(door:GetDescendants()) do
   CollectionService:RemoveTag(d,'DoorLocked')
   if d:IsA('ProximityPrompt') then
    local promptName=string.lower(d.Name..' '..d.ActionText..' '..d.ObjectText)
    if promptName:find('key',1,true) or promptName:find('chave',1,true) or promptName:find('lock',1,true) then d.Enabled=false end
   end
  end
  door:SetAttribute('KeyRequired',false)
  door:SetAttribute('Unlocked',true)
  if type(doorManager.EnableDoor)=='function' then
   local ok,err=pcall(function() doorManager.EnableDoor(door) end)
   if not ok then warn('[MysteryDoor] Could not unlock '..name..': '..tostring(err)) end
  end
  local host=door.PrimaryPart
  if not host then
   for _,part in ipairs(door:GetDescendants()) do
    if part:IsA('BasePart') and part.Transparency<1 and not string.lower(part.Name):find('trigger',1,true) then host=part;break end
   end
  end
  if not host then host=door:FindFirstChildWhichIsA('BasePart',true) end
  if host then
   local prompt=host:FindFirstChild('MainDoorPrompt')
   if not prompt then
    prompt=Instance.new('ProximityPrompt')
    prompt.Name='MainDoorPrompt'
    prompt.ActionText='Abrir'
    prompt.ObjectText='Porta principal'
    prompt.KeyboardKeyCode=Enum.KeyCode.E
    prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
    prompt.HoldDuration=0
    prompt.MaxActivationDistance=9
    prompt.RequiresLineOfSight=false
    prompt.Exclusivity=Enum.ProximityPromptExclusivity.OnePerButton
    prompt.Parent=host
    prompt.Triggered:Connect(function()
     CollectionService:RemoveTag(door,'DoorLocked')
     if type(doorManager.EnableDoor)=='function' then pcall(function() doorManager.EnableDoor(door) end) end
    end)
   end
  end
 end
end
workspace:SetAttribute('MainDoorKeyRequired',false)
workspace:SetAttribute('MainDoorOpenMode','permanently-unlocked')
workspace:SetAttribute('SeatPromptVersion','portuguese-v1')
local function installSeatPrompt(seat)
 if not seat:IsA('Seat') then return end
 seat.Disabled=false
 local prompt=seat:FindFirstChild('PortugueseSitPrompt')
 if not prompt then
  prompt=Instance.new('ProximityPrompt')
  prompt.Name='PortugueseSitPrompt'
  prompt.ActionText='Sentar'
  prompt.ObjectText='Cadeira'
  prompt.KeyboardKeyCode=Enum.KeyCode.E
  prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
  prompt.HoldDuration=0
  prompt.MaxActivationDistance=8
  prompt.RequiresLineOfSight=false
  prompt.Exclusivity=Enum.ProximityPromptExclusivity.OnePerButton
  prompt.Parent=seat
  prompt.Triggered:Connect(function(player)
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass('Humanoid')
   if humanoid and humanoid.Health>0 and (not seat.Occupant or seat.Occupant==humanoid) then seat:Sit(humanoid) end
  end)
 end
end
for _,d in ipairs(content:GetDescendants()) do installSeatPrompt(d) end
-- There are no weapon pickups, and any remaining tool is removed from a player immediately.
local function removeTools(container)
 if not container then return end
 for _,d in ipairs(container:GetChildren()) do if d:IsA('Tool') then d:Destroy() end end
 container.ChildAdded:Connect(function(d) if d:IsA('Tool') then d:Destroy() end end)
end
local function setupPlayer(player)
 removeTools(player:FindFirstChildOfClass('Backpack'))
 removeTools(player:FindFirstChild('StarterGear'))
 player.CharacterAdded:Connect(function(character)
  removeTools(character)
 end)
 if player.Character then removeTools(player.Character) end
end
Players.PlayerAdded:Connect(setupPlayer)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(setupPlayer,player) end
workspace:SetAttribute('MysteryWeaponFree',true)
