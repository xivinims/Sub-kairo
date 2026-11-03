local Pathfinding=game:GetService('PathfindingService')
local Players=game:GetService('Players')
local Physics=game:GetService('PhysicsService')
local R={}
function R.start(folder,config)
 pcall(function() Physics:RegisterCollisionGroup('WaterResidents') end)
 Physics:CollisionGroupSetCollidable('WaterResidents','WaterResidents',false)
 local residents={}
 for _,npc in ipairs(folder:GetChildren()) do
  local h=npc:FindFirstChildOfClass('Humanoid');local root=npc:FindFirstChild('HumanoidRootPart')
  if h and root then
   local resident={npc=npc,h=h,root=root,home=root.Position,nextAt=os.clock()+math.random()*12,moving=false,blocked=0,roam=npc:GetAttribute('Roam')==true}
   table.insert(residents,resident)
   for _,part in ipairs(npc:GetDescendants()) do
    if part:IsA('BasePart') then
     part.Anchored=false;part.CollisionGroup='WaterResidents';part.CanTouch=false
     part.CanCollide=part.Name=='UpperTorso' or part.Name=='Torso';part.Massless=part~=root
    end
   end
   root.Anchored=not resident.roam
   if resident.roam then pcall(function() root:SetNetworkOwner(nil) end) end
   h.WalkSpeed=7;h.MaxHealth=100;h.Health=100;h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
   h:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
  end
 end
 local function nearby(r)
  for _,p in ipairs(Players:GetPlayers()) do
   local c=p.Character;local root=c and c:FindFirstChild('HumanoidRootPart')
   if root and not p:GetAttribute('InMenu') and (root.Position-r.root.Position).Magnitude<config.ResidentsDistance then return true end
  end
  return false
 end
 local function walk(r)
  r.moving=true
  local npc=r.npc
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={folder};params.IgnoreWater=false
  local goal=r.home+Vector3.new(math.random(-12,12),0,math.random(-12,12))
  local ground=workspace:Raycast(goal+Vector3.new(0,5,0),Vector3.new(0,-12,0),params)
  if not ground or ground.Material==Enum.Material.Water or math.abs(ground.Position.Y-(r.home.Y-3))>5 then r.moving=false;return end
  goal=ground.Position+Vector3.new(0,3,0)
  local path=Pathfinding:CreatePath({AgentRadius=1.7,AgentHeight=5,AgentCanJump=false,WaypointSpacing=4})
  local ok=pcall(function() path:ComputeAsync(r.root.Position,goal) end)
  if ok and path.Status==Enum.PathStatus.Success and not npc:GetAttribute('Conversing') then
   npc:SetAttribute('Activity','Caminhando')
   local blocked=false;local connection=path.Blocked:Connect(function() blocked=true end)
   for index,point in ipairs(path:GetWaypoints()) do
    if index>1 then
     if blocked or npc:GetAttribute('Conversing') or not nearby(r) then break end
     r.h:MoveTo(point.Position)
     local deadline=os.clock()+3
     repeat task.wait(.15) until (r.root.Position-point.Position).Magnitude<3 or os.clock()>deadline or npc:GetAttribute('Conversing')
     if os.clock()>deadline then break end
    end
   end
   connection:Disconnect()
  end
  npc:SetAttribute('Activity','Descansando');r.moving=false
 end
 task.spawn(function()
  while folder.Parent do
   local launched=0
   for _,r in ipairs(residents) do
    if r.roam and not r.moving and os.clock()>r.nextAt and not r.npc:GetAttribute('Conversing') and nearby(r) then
     r.nextAt=os.clock()+math.random(14,32);task.spawn(walk,r);launched=launched+1
     if launched>=2 then break end
    end
    if r.root.Position.Y < r.home.Y-15 then r.root.CFrame=CFrame.new(r.home);r.h:MoveTo(r.home) end
   end
   task.wait(1)
  end
 end)
 return residents
end
return R
