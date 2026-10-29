while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Path=game:GetService('PathfindingService')
local Chunks=require(script.Parent.MansionChunks)
while workspace:GetAttribute('IslandWorldReady')~=true do task.wait(.2) end
local rig;local nextPath=0;local lastSeen=0;local goal;local lastAttack=0;local computing=false
local function spawn()
 local point=Vector3.new(-180,0,-220);Chunks.Warm(point,180)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain,workspace.Islands.mansion}
 local floor=assert(workspace:Raycast(point+Vector3.new(0,200,0),Vector3.new(0,-400,0),rp),'Forest monster floor missing')
 local model=RS.OriginalForestMonster:Clone();model.Name='ForestStalker';model:SetAttribute('AlienCombatant',true);model:SetAttribute('AlienHealth',180);model:SetAttribute('OriginalMonster','Orderly Independence Sepulchar')
 local hum=model:FindFirstChildOfClass('Humanoid');local root=model.HumanoidRootPart;hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.WalkSpeed=8;hum.MaxHealth=180;hum.Health=180
 root.Anchored=false;root.CanCollide=true;model:PivotTo(CFrame.new(floor.Position+Vector3.new(0,hum.HipHeight+root.Size.Y/2,0)));model.Parent=workspace;pcall(function() root:SetNetworkOwner(nil) end)
 return model
end
rig=spawn()
while task.wait(.3) do
 if not rig or not rig.Parent then task.wait(45);rig=spawn();computing=false end
 if rig:GetAttribute('Defeated') then continue end
 local root=rig.HumanoidRootPart;local hum=rig:FindFirstChildOfClass('Humanoid');local target
 for _,p in ipairs(Players:GetPlayers()) do
  local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if r and h and h.Health>0 and (r.Position-root.Position).Magnitude<140 then
   local locked=workspace:GetAttribute('MansionDoorLocked')~=false
   if not Chunks.Inside(r.Position) or not locked then
    local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={rig,p.Character};rp.RespectCanCollide=true
    if not workspace:Raycast(root.Position,r.Position-root.Position,rp) then target=r;lastSeen=os.clock();goal=r.Position;break end
   end
  end
 end
 if not target and os.clock()-lastSeen>8 then goal=Vector3.new(math.sin(os.clock()*.025)*230,root.Position.Y,-200+math.cos(os.clock()*.025)*100) end
 hum.WalkSpeed=target and 19 or 7;rig:SetAttribute('Walking',hum.MoveDirection.Magnitude>.1)
 if goal and os.clock()>nextPath and not computing then
  computing=true;nextPath=os.clock()+2;local current=rig;local destination=goal
  task.spawn(function()
   local ok,err=pcall(function()
    Chunks.Warm(destination,96)
    local path=Path:CreatePath({AgentRadius=2,AgentHeight=8,AgentCanJump=true});path:ComputeAsync(root.Position,destination)
    if path.Status~=Enum.PathStatus.Success then hum:MoveTo(destination);return end
    local points=path:GetWaypoints()
    for i=2,math.min(#points,5) do
     if not current.Parent or current:GetAttribute('Defeated') then break end
     if Chunks.Inside(points[i].Position) and workspace:GetAttribute('MansionDoorLocked')~=false then break end
     if points[i].Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
     hum:MoveTo(points[i].Position);local deadline=os.clock()+1.1
     repeat task.wait(.12) until not current.Parent or (root.Position-points[i].Position).Magnitude<3 or os.clock()>deadline
    end
   end)
   if not ok then warn('[OriginalForestMonster] '..tostring(err)) end;computing=false
  end)
 end
 if target and (target.Position-root.Position).Magnitude<6 and os.clock()-lastAttack>1 then lastAttack=os.clock();local h=target.Parent:FindFirstChildOfClass('Humanoid');if h then h:TakeDamage(12) end end
end
