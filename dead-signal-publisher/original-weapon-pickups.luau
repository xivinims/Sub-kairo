while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local lib=require(game.ReplicatedStorage.Library)
while not lib.Loaded do task.wait(.1) end
local physics=game:GetService('PhysicsService')
for _,group in ipairs({'Player','NonPlayer'}) do pcall(function() physics:RegisterCollisionGroup(group) end) end
physics:CollisionGroupSetCollidable('Player','NonPlayer',false)
local folder=workspace.WeaponToolsRespawn
local Players=game:GetService('Players')
local experienceChapter=workspace:GetAttribute('ExperienceChapter') or 1
local selectedChapter=workspace:GetAttribute('SelectedChapter') or experienceChapter
local chapterOne=experienceChapter==1 and selectedChapter==1
local STARTING_WEAPON='M4A1'

local function prepareStartingWeapon(player)
 local starterGear=player:WaitForChild('StarterGear',10)
 if not starterGear then return nil end
 local tool=starterGear:FindFirstChild(STARTING_WEAPON)
 if not tool then
  tool=lib.WeaponsHandler.CreateWeapon(STARTING_WEAPON)
  tool.Name=STARTING_WEAPON
  tool:SetAttribute('StartingLoadoutWeapon',true)
  tool.Parent=starterGear
 end
 return tool
end

local function equipStartingWeapon(player,character)
 local humanoid=character:WaitForChild('Humanoid',10)
 local backpack=player:WaitForChild('Backpack',10)
 if not humanoid or not backpack or humanoid.Health<=0 then return end
 local tool=backpack:FindFirstChild(STARTING_WEAPON) or character:FindFirstChild(STARTING_WEAPON)
 if not tool then
  local template=prepareStartingWeapon(player)
  if not template then return end
  tool=template:Clone()
  tool.Name=STARTING_WEAPON
  tool:SetAttribute('StartingLoadoutWeapon',true)
  tool.Parent=backpack
 end
 if tool.Parent==backpack then
  task.wait(.15)
  if character.Parent and humanoid.Health>0 and tool.Parent==backpack then humanoid:EquipTool(tool) end
 end
end

local function setupStartingWeapon(player)
 prepareStartingWeapon(player)
 player.CharacterAdded:Connect(function(character)
  task.spawn(equipStartingWeapon,player,character)
 end)
 if player.Character then task.spawn(equipStartingWeapon,player,player.Character) end
end
if chapterOne then
 Players.PlayerAdded:Connect(setupStartingWeapon)
 for _,player in ipairs(Players:GetPlayers()) do task.spawn(setupStartingWeapon,player) end
end

local locations={{'M4A1',Vector3.new(-62,16,-127)},{'Deagle',Vector3.new(65,17,-100)}}
if chapterOne then locations={{'Deagle',Vector3.new(65,17,-100)}} end
for index,spec in ipairs(locations) do
 local function spawnPickup()
  local marker='OriginalPickup'..index
  for _,old in ipairs(folder:GetChildren()) do if old:GetAttribute('PickupSlot')==marker then return end end
  local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Content};rp.RespectCanCollide=true
  local hit=workspace:Raycast(spec[2]+Vector3.new(0,8,0),Vector3.new(0,-30,0),rp)
  assert(hit,'Original weapon pickup has no surface: '..spec[1])
  local tool=lib.WeaponsHandler.CreateWeapon(spec[1]);tool:SetAttribute('PickupSlot',marker)
  tool.Weapon:PivotTo(CFrame.new(hit.Position+Vector3.new(0,.65,0)))
  for _,part in ipairs(tool:GetDescendants()) do if part:IsA('BasePart') then part.Anchored=true end end
  tool.Parent=folder
  local prompt=Instance.new('ProximityPrompt');prompt.Name='OriginalWeaponPickup';prompt.ActionText='Segure para pegar';prompt.ObjectText=spec[1];prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=true;prompt.HoldDuration=.45;prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX;prompt.Style=Enum.ProximityPromptStyle.Custom;prompt.Parent=tool.Weapon.PrimaryPart
  local claimed=false
  tool.AncestryChanged:Connect(function()
   if tool.Parent~=folder and not claimed then claimed=true;prompt:Destroy();task.delay(30,spawnPickup) end
  end)
  prompt.Triggered:Connect(function(player)
   local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
   if not claimed and root and hum and hum.Health>0 and tool.Parent==folder and (root.Position-tool.Weapon.PrimaryPart.Position).Magnitude<=9 then
    hum:UnequipTools();tool.Parent=player.Backpack;hum:EquipTool(tool)
   end
  end)
 end
 spawnPickup()
end
workspace:SetAttribute('OriginalWeaponPickupCount',#locations)
