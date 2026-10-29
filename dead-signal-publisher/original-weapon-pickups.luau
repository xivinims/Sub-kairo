while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local lib=require(game.ReplicatedStorage.Library)
while not lib.Loaded do task.wait(.1) end
-- Original weapon factory, original tools, original pickup remote/controller.
local locations={{'M4A1',Vector3.new(-62,16,-127)},{'Deagle',Vector3.new(65,17,-100)}}
for _,spec in ipairs(locations) do
 local tool=lib.WeaponsHandler.CreateWeapon(spec[1])
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Content};rp.RespectCanCollide=true
 local hit=workspace:Raycast(spec[2]+Vector3.new(0,8,0),Vector3.new(0,-30,0),rp)
 assert(hit,'Original weapon pickup has no surface: '..spec[1])
 tool.Weapon:PivotTo(CFrame.new(hit.Position+Vector3.new(0,1,0)));tool.Parent=workspace.WeaponToolsRespawn
 -- Touch uses the same original server pickup handler as the F key.
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Pegar';prompt.ObjectText=spec[1];prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=true;prompt.Parent=tool.Weapon.PrimaryPart
 prompt.Triggered:Connect(function(player)
  local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  if root and tool.Parent==workspace.WeaponToolsRespawn and (root.Position-tool.Weapon.PrimaryPart.Position).Magnitude<=9 then
   player.Character.Humanoid:UnequipTools();tool.Parent=player.Backpack;player.Character.Humanoid:EquipTool(tool)
  end
 end)
end
