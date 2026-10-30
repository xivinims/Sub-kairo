while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local lib=require(game.ReplicatedStorage.Library)
while not lib.Loaded do task.wait(.1) end
local physics=game:GetService('PhysicsService')
for _,group in ipairs({'Player','NonPlayer'}) do pcall(function() physics:RegisterCollisionGroup(group) end) end
physics:CollisionGroupSetCollidable('Player','NonPlayer',false)
local folder=workspace.WeaponToolsRespawn
local locations={{'M4A1',Vector3.new(-62,16,-127)},{'Deagle',Vector3.new(65,17,-100)}}
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
