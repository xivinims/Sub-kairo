-- Jason perception/chase is server-owned.
-- Direct LOS uses continuous predictive pursuit; pathfinding is only a fallback around obstacles.
local PF=game:GetService("PathfindingService")
local Run=game:GetService("RunService")
local AI={}

function AI.start(model,map,spec,ctx)
 local h=model:FindFirstChildOfClass("Humanoid")
 local r=model.PrimaryPart
 local alive=true
 local target=nil
 local lastSeen=nil
 local seenAt=-100
 local heard=nil
 local goal=nil
 local waypoints={}
 local wi=1
 local path=nil
 local blocked=nil
 local computing=false
 local nextPath=0
 local pathGoal=nil
 local patrolUntil=0
 local searchUntil=0
 local attackAt=0
 local clock=0
 local sum=0
 local lastPosition=r.Position
 local stuck=0
 local directChasing=false local smoothedGoal=nil local lastTargetVelocity=Vector3.zero
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={model}
 local pts=map.SafePoints:GetChildren()

 local function targetRoot(p)
  return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 end

 local function visible(p)
  local pr=targetRoot(p)
  if not pr or not ctx.vulnerable(p) then return false,nil end
  local origin=r.Position+Vector3.new(0,1.5,0)
  local aim=pr.Position+Vector3.new(0,1,0)
  local delta=aim-origin
  local distance=delta.Magnitude
  if distance>spec.vision then return false,pr end
  if distance>14 and distance>.01 and r.CFrame.LookVector:Dot(delta.Unit)<-.05 then return false,pr end
  local hit=workspace:Raycast(origin,delta,params)
  return (not hit or hit.Instance:IsDescendantOf(p.Character)),pr
 end

 local function clearPath()
  if blocked then blocked:Disconnect() blocked=nil end
  if path then path:Destroy() path=nil end
  waypoints={} wi=1 pathGoal=nil
 end

 local function buildRoute(pos,urgent)
  local moved=not pathGoal or (pathGoal-pos).Magnitude>5
  if computing or (not urgent and clock<nextPath and not moved) then return end
  computing=true
  nextPath=clock+(urgent and .22 or .38)
  local origin=r.Position
  local requested=pos
  task.spawn(function()
   local p=PF:CreatePath({
    AgentRadius=2.2,
    AgentHeight=5,
    AgentCanJump=true,
    AgentCanClimb=true,
    WaypointSpacing=3,
   })
   local ok=pcall(function() p:ComputeAsync(origin,requested) end)
   if not alive then p:Destroy() computing=false return end
   if ok and p.Status==Enum.PathStatus.Success then
    clearPath()
    path=p
    pathGoal=requested
    waypoints=p:GetWaypoints()
    wi=math.min(2,#waypoints)
    blocked=p.Blocked:Connect(function(index)
     if index>=wi then nextPath=0 pathGoal=nil end
    end)
   else
    p:Destroy()
    waypoints={}
    pathGoal=nil
   end
   computing=false
  end)
 end

 local function predicted(pr)
  local velocity=pr.AssemblyLinearVelocity
  local horizontal=Vector3.new(velocity.X,0,velocity.Z)
  local distance=(pr.Position-r.Position).Magnitude
  local lead=math.clamp(distance/math.max(spec.speed+10,1),.08,.42)
  local ahead=horizontal*lead
  if ahead.Magnitude>8 then ahead=ahead.Unit*8 end
  lastTargetVelocity=horizontal
  return pr.Position+ahead
 end

 local function chooseVisible()
  local chosen=nil
  local nearest=math.huge
  for _,p in ipairs(ctx.players()) do
   local canSee,pr=visible(p)
   if canSee and pr then
    local d=(pr.Position-r.Position).Magnitude
    if p==target then d-=10 end
    if d<nearest then nearest=d chosen=p end
   end
  end
  return chosen
 end

 local conn
 conn=Run.Heartbeat:Connect(function(dt)
  sum+=dt
  if sum<.10 then return end
  local step=sum
  sum=0
  clock+=step
  if not alive or not model.Parent or h.Health<=0 then return end

  local chosen=chooseVisible()
  if chosen then
   target=chosen
   local pr=targetRoot(chosen)
   lastSeen=pr and pr.Position or lastSeen
   seenAt=clock
   searchUntil=clock+7
  end

  local state="Patrol"
  local targetVisible=false
  local targetPr=nil
  if target then
   targetVisible,targetPr=visible(target)
  end

  if target and targetVisible and targetPr then
   state="Chase"
   local raw=predicted(targetPr)
   smoothedGoal=smoothedGoal and smoothedGoal:Lerp(raw,math.clamp(step*8,0,1)) or raw
   goal=smoothedGoal
   lastSeen=targetPr.Position
   seenAt=clock
  elseif target and targetPr and lastSeen and clock-seenAt<.7 then
   -- Keep pressure through very brief doorframe/corner occlusion without wall vision.
   state="Chase"
   goal=lastSeen+lastTargetVelocity*.12
  elseif lastSeen and clock-seenAt<4.5 then
   state="Search"
   goal=lastSeen
   target=nil
  elseif heard and clock-heard.time<5.5 then
   state="Investigate"
   goal=heard.position
   target=nil
  elseif lastSeen and clock<searchUntil then
   state="Search"
   target=nil
   if not goal or (r.Position-goal).Magnitude<4 then
    goal=lastSeen+Vector3.new(math.random(-10,10),0,math.random(-10,10))
   end
  else
   target=nil lastSeen=nil
   if not goal or clock>=patrolUntil or (r.Position-goal).Magnitude<4 then
    goal=pts[math.random(#pts)].Value
    patrolUntil=clock+12
    nextPath=0
   end
  end

  model:SetAttribute("AIState",state)
  model:SetAttribute("TargetUserId",target and target.UserId or 0)
  model:SetAttribute("DirectChase",state=="Chase" and targetVisible)
  model:SetAttribute("OcclusionGrace",state=="Chase" and not targetVisible)
  h.WalkSpeed=state=="Chase" and spec.speed or state=="Patrol" and 11 or 15

  if target and targetPr and clock>=attackAt and (targetPr.Position-r.Position).Magnitude<=spec.range then
   attackAt=clock+1.8
   ctx.catch(target)
  end

  if (model:GetAttribute("AttackUntil") or 0)>workspace:GetServerTimeNow() then
   h:MoveTo(r.Position)
   return
  end

  if state=="Chase" and targetVisible and targetPr then
   -- Never follow stale waypoints while the survivor is actually visible.
   if not directChasing then clearPath() directChasing=true end
   local raw=predicted(targetPr)
   smoothedGoal=smoothedGoal and smoothedGoal:Lerp(raw,math.clamp(step*9,0,1)) or raw
   goal=smoothedGoal
   h:MoveTo(goal)
  else
   directChasing=false
   if goal then
    buildRoute(goal,state=="Search" or state=="Investigate")
    local waypoint=waypoints[wi]
    if waypoint and (r.Position-waypoint.Position).Magnitude<2.6 then
     wi+=1
     waypoint=waypoints[wi]
    end
    if waypoint then
     if waypoint.Action==Enum.PathWaypointAction.Jump then h.Jump=true end
     h:MoveTo(waypoint.Position)
    else
     h:MoveTo(goal)
    end
   end
  end

  local moved=(r.Position-lastPosition).Magnitude
  if goal and (r.Position-goal).Magnitude>4 and moved<.12 then stuck+=step else stuck=0 end
  lastPosition=r.Position
  if stuck>.85 then
   nextPath=0
   pathGoal=nil
   if state~="Chase" then clearPath() end
   h.Jump=true
   -- Small recovery sidestep prevents getting pinned on doorframes/corners.
   local side=r.CFrame.RightVector*((math.random(0,1)==0) and -3.5 or 3.5)
   h:MoveTo(r.Position+side+r.CFrame.LookVector*2)
   stuck=0
  end
 end)

 return {
  noise=function(pos,radius)
   if alive and (r.Position-pos).Magnitude<=radius then heard={position=pos,time=clock} end
  end,
  stop=function()
   alive=false
   conn:Disconnect()
   clearPath()
  end
 }
end

return AI