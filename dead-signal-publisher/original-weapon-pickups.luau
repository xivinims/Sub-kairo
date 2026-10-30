while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end

local RS=game:GetService('ReplicatedStorage')
local lib=require(RS.Library)
while not lib.Loaded do task.wait(.1) end
local physics=game:GetService('PhysicsService')
for _,group in ipairs({'Player','NonPlayer'}) do
 pcall(function() physics:RegisterCollisionGroup(group) end)
end
physics:CollisionGroupSetCollidable('Player','NonPlayer',false)

local request=RS:WaitForChild('PickupWeaponRequest')
local folder=workspace:WaitForChild('WeaponToolsRespawn')
local locations={{'M4A1',Vector3.new(-62,16,-127)},{'Deagle',Vector3.new(65,17,-100)}}
local active={} -- Only server-created, unclaimed weapon Tools are accepted from the client.

local function claim(player,tool)
 if typeof(tool)~='Instance' or not tool:IsA('Tool') then return end
 if not active[tool] or tool.Parent~=folder then return end
 local weapon=tool:FindFirstChild('Weapon')
 local part=weapon and weapon.PrimaryPart
 local prompt=part and part:FindFirstChild('OriginalWeaponPickup')
 local char=player.Character
 local root=char and char:FindFirstChild('HumanoidRootPart')
 local hum=char and char:FindFirstChildOfClass('Humanoid')
 if not prompt or not prompt.Enabled or not root or not hum or hum.Health<=0 then return end
 if (root.Position-part.Position).Magnitude>9 then return end

 -- Consume first, before parenting the Tool, to reject repeated taps/remote spam.
 active[tool]=nil
 prompt.Enabled=false
 for _,part in ipairs(tool:GetDescendants()) do
  if part:IsA('BasePart') then part.Anchored=false end
 end
 hum:UnequipTools()
 tool.Parent=player:WaitForChild('Backpack')
 hum:EquipTool(tool)
end

request.OnServerEvent:Connect(claim)
for index,spec in ipairs(locations) do
 local function spawnPickup()
  local marker='OriginalPickup'..index
  for _,existing in ipairs(folder:GetChildren()) do
   if existing:GetAttribute('PickupSlot')==marker then return end
  end
  local rp=RaycastParams.new()
  rp.FilterType=Enum.RaycastFilterType.Include
  rp.FilterDescendantsInstances={workspace.Content}
  rp.RespectCanCollide=true
  local hit=workspace:Raycast(spec[2]+Vector3.new(0,8,0),Vector3.new(0,-30,0),rp)
  assert(hit,'Original weapon pickup has no surface: '..spec[1])
  local tool=lib.WeaponsHandler.CreateWeapon(spec[1])
  tool:SetAttribute('PickupSlot',marker)
  tool:SetAttribute('PickupName',spec[1])
  tool.Weapon:PivotTo(CFrame.new(hit.Position+Vector3.new(0,.65,0)))
  for _,part in ipairs(tool:GetDescendants()) do
   if part:IsA('BasePart') then part.Anchored=true end
  end
  tool.Parent=folder
  local prompt=Instance.new('ProximityPrompt')
  prompt.Name='OriginalWeaponPickup'
  prompt.Style=Enum.ProximityPromptStyle.Custom -- Our own PEGAR button, no duplicate native overlay.
  prompt.ActionText='PEGAR'
  prompt.ObjectText=spec[1]
  prompt.HoldDuration=0
  prompt.KeyboardKeyCode=Enum.KeyCode.E
  prompt.ClickablePrompt=true
  prompt.MaxActivationDistance=8
  prompt.RequiresLineOfSight=true
  prompt.Parent=tool.Weapon.PrimaryPart
  active[tool]=true
  local queued=false
  tool.AncestryChanged:Connect(function()
   if tool.Parent~=folder and not queued then
    queued=true
    active[tool]=nil
    prompt.Enabled=false
    task.delay(30,spawnPickup)
   end
  end)
  prompt.Triggered:Connect(function(player) claim(player,tool) end)
 end
 spawnPickup()
end
workspace:SetAttribute('OriginalWeaponPickupCount',#locations)
