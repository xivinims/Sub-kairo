while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
-- Replaces the source's discarded legacy weld/BodyPosition scripts.
local Tween=game:GetService('TweenService');local Players=game:GetService('Players')
local world=workspace:WaitForChild('Islands');local mounted=setmetatable({},{__mode='k'})
local function near(position,distance)
 for _,p in ipairs(Players:GetPlayers()) do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if r and (r.Position-position).Magnitude<distance then return true end end
 return false
end
local function mount(cell)
 if mounted[cell] or not (cell.Name:match('^Cell_') or cell.Name:match('^VillageHouse_')) then return end;mounted[cell]=true
 local groups={}
 for _,p in ipairs(cell:GetDescendants()) do if p:IsA('BasePart') and p:GetAttribute('IslandDoorId') then
  local id=p:GetAttribute('IslandDoorId');groups[id]=groups[id] or {};table.insert(groups[id],p)
 end end
 for id,parts in pairs(groups) do
  local pivot=parts[1]:GetAttribute('IslandDoorPivot');local anchor=parts[1]
  for _,p in ipairs(parts) do if p.Name=='middle' then anchor=p end end
  local closed={};for _,p in ipairs(parts) do closed[p]={cf=p.CFrame,collide=p.CanCollide} end
  local prompt=Instance.new('ProximityPrompt');prompt.Name='IslandDoorPrompt';prompt.ActionText='Abrir';prompt.ObjectText='Porta';prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.MaxActivationDistance=9;prompt.HoldDuration=0;prompt.RequiresLineOfSight=false;prompt.Parent=anchor
  local value=Instance.new('CFrameValue');value.Value=CFrame.identity;value.Parent=prompt
  local opened,busy=false,false;local token=0
  local conn=value.Changed:Connect(function(delta) for p,state in pairs(closed) do if p.Parent then p.CFrame=pivot*delta*pivot:Inverse()*state.cf end end end)
  cell.Destroying:Connect(function() conn:Disconnect() end)
  local function change(open)
   if busy or not cell.Parent then return end;busy=true;opened=open;token+=1;local ticket=token
   prompt.Enabled=false
   for p in pairs(closed) do if p.Parent then p.CanCollide=false end end
   local t=Tween:Create(value,TweenInfo.new(.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=open and CFrame.Angles(0,math.rad(100),0) or CFrame.identity})
   t:Play();t.Completed:Wait()
   if not cell.Parent then return end
   if not open then for p,state in pairs(closed) do if p.Parent then p.CanCollide=state.collide end end end
   prompt.ActionText=open and 'Fechar' or 'Abrir';prompt.Enabled=true;busy=false
   if open then task.spawn(function()
    task.wait(9)
    while cell.Parent and token==ticket and opened do
     if not near(pivot.Position,10) then change(false);return end
     task.wait(3)
    end
   end) end
  end
  task.spawn(function() while cell.Parent do
   local residents=workspace:FindFirstChild('IslandResidents')
   if residents and not opened and not busy then
    for _,rig in ipairs(residents:GetChildren()) do local root=rig:FindFirstChild('HumanoidRootPart')
     if root and (root.Position-pivot.Position).Magnitude<12 then change(true);break end
    end
   end
   task.wait(1)
  end end)
  prompt.Triggered:Connect(function(player)
   local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
   if root and hum and hum.Health>0 and (root.Position-anchor.Position).Magnitude<=12 then change(not opened) end
  end)
 end
end
for _,island in ipairs(world:GetChildren()) do
 for _,cell in ipairs(island:GetChildren()) do mount(cell) end
 island.ChildAdded:Connect(function(cell) task.defer(mount,cell) end)
end

world.DescendantAdded:Connect(function(model) if model:IsA('Model') and model.Name:match('^VillageHouse_') then task.defer(mount,model) end end)
