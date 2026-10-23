-- Jason perception is server owned. A sound gives a position, never wall vision.
local PF=game:GetService("PathfindingService")
local Run=game:GetService("RunService")
local AI={}
function AI.start(model,map,spec,ctx)
 local h=model:FindFirstChildOfClass("Humanoid") local r=model.PrimaryPart
 local alive=true local target=nil local lastSeen=nil local seenAt=-100 local heard=nil
 local goal=nil local waypoints={} local wi=1 local path=nil local blocked=nil local computing=false
 local generation=0 local nextPath=0 local patrolUntil=0 local searchUntil=0 local attackAt=0
 local lastPosition=r.Position local stuck=0 local sum=0 local clock=0
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={model}
 local pts=map.SafePoints:GetChildren()
 local function see(p)
  local pr=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if not pr or not ctx.vulnerable(p) then return false end
  local delta=pr.Position-r.Position local distance=delta.Magnitude
  if distance>spec.vision then return false end
  if distance>12 and distance>.01 and r.CFrame.LookVector:Dot(delta.Unit)<.15 then return false end
  local hit=workspace:Raycast(r.Position+Vector3.new(0,1.4,0),delta,params)
  return not hit or hit.Instance:IsDescendantOf(p.Character)
 end
 local function clearPath()
  if blocked then blocked:Disconnect() blocked=nil end
  if path then path:Destroy() path=nil end
  waypoints={} wi=1
 end
 local function route(pos)
  if computing or clock<nextPath then return end
  computing=true nextPath=clock+.8 generation+=1 local id=generation local origin=r.Position
  task.spawn(function()
   local p=PF:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=4})
   local ok=pcall(function() p:ComputeAsync(origin,pos) end)
   if not alive or id~=generation then p:Destroy() computing=false return end
   if ok and p.Status==Enum.PathStatus.Success then
    clearPath() path=p waypoints=p:GetWaypoints() wi=math.min(2,#waypoints)
    blocked=p.Blocked:Connect(function(i) if i>=wi then nextPath=0 waypoints={} end end)
   else p:Destroy() waypoints={} patrolUntil=0 end
   computing=false
  end)
 end
 local conn
 conn=Run.Heartbeat:Connect(function(dt)
  sum+=dt if sum<.15 then return end local step=sum sum=0 clock+=step
  if not alive or not model.Parent or h.Health<=0 then return end
  local chosen=nil local nearest=math.huge
  for _,p in ipairs(ctx.players()) do if see(p) then
   local d=(p.Character.HumanoidRootPart.Position-r.Position).Magnitude
   if p==target then d-=8 end
   if d<nearest then nearest=d chosen=p end
  end end
  if chosen then target=chosen lastSeen=chosen.Character.HumanoidRootPart.Position seenAt=clock searchUntil=clock+8 end
  local state="Patrol"
  if target and chosen==target then goal=lastSeen state="Chase"
  elseif lastSeen and clock-seenAt<4 then goal=lastSeen state="Search" target=nil
  elseif heard and clock-heard.time<6 then goal=heard.position state="Investigate" target=nil
  elseif lastSeen and clock<searchUntil then
   state="Search" target=nil
   if not goal or (r.Position-goal).Magnitude<5 then goal=lastSeen+Vector3.new(math.random(-12,12),0,math.random(-12,12)) end
  else
   target=nil lastSeen=nil
   if not goal or clock>=patrolUntil or (r.Position-goal).Magnitude<5 then
    goal=pts[math.random(#pts)].Value patrolUntil=clock+14 nextPath=0
   end
  end
  model:SetAttribute("AIState",state) model:SetAttribute("TargetUserId",target and target.UserId or 0)
  h.WalkSpeed=state=="Chase" and spec.speed or state=="Patrol" and 11 or 15
  if target and clock>=attackAt and (target.Character.HumanoidRootPart.Position-r.Position).Magnitude<=spec.range then
   attackAt=clock+1.8 ctx.catch(target)
  end
  if (model:GetAttribute("AttackUntil") or 0)>workspace:GetServerTimeNow() then h:MoveTo(r.Position) return end
  if goal then
   route(goal)
   local waypoint=waypoints[wi]
   if waypoint then
    if (r.Position-waypoint.Position).Magnitude<3 then wi+=1 waypoint=waypoints[wi] end
    if waypoint then if waypoint.Action==Enum.PathWaypointAction.Jump then h.Jump=true end h:MoveTo(waypoint.Position) end
   elseif chosen and see(chosen) then h:MoveTo(goal) end
  end
  if (r.Position-lastPosition).Magnitude<.15 and goal and (r.Position-goal).Magnitude>5 then stuck+=step else stuck=0 end
  lastPosition=r.Position
  if stuck>1.8 then nextPath=0 clearPath() h.Jump=true stuck=0 if state=="Patrol" then patrolUntil=0 end end
 end)
 return {noise=function(pos,radius)
  if alive and (r.Position-pos).Magnitude<=radius then heard={position=pos,time=clock} end
 end,stop=function() alive=false generation+=1 conn:Disconnect() clearPath() end}
end
return AI
