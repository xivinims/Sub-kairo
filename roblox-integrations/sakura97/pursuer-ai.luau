local Pathfinding=game:GetService("PathfindingService")
local RunService=game:GetService("RunService")
local AI={}
function AI.visible(kind,config,distance,speed,lineOfSight,facing,revealing)
 if speed<=.6 then return false end
 if kind=="Scarlat" and revealing and distance<100 then return true end
 return config.vision>0 and distance<config.vision and lineOfSight and (distance<12 or facing>-.1)
end
function AI.start(model,map,config,ctx)
 local root=model.PrimaryPart local hum=model:FindFirstChildOfClass("Humanoid")
 local alive=true local lastPath=0 local busy=false local waypoints={} local waypoint=1
 local goal=nil local heardUntil=0 local nextAbility=0 local restUntil=0 local attackUntil=0
 local nextPatrol=0 local target=nil local revealUntil=0 local nextShot=0 local conn
 local points=map.SafePoints:GetChildren()
 local function los(pos,char)
  local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Exclude p.FilterDescendantsInstances={model}
  local hit=workspace:Raycast(root.Position,pos-root.Position,p)
  return not hit or (char and hit.Instance:IsDescendantOf(char))
 end
 local function noise(position,radius)
  if alive and (root.Position-position).Magnitude<radius then goal=position heardUntil=os.clock()+5 end
 end
 local function path(destination)
  if busy or os.clock()-lastPath<1 then return end
  busy=true lastPath=os.clock()
  task.spawn(function()
   local p=Pathfinding:CreatePath({AgentRadius=1.5,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
   local ok=pcall(function() p:ComputeAsync(root.Position,destination) end)
   if alive and ok and p.Status==Enum.PathStatus.Success then waypoints=p:GetWaypoints() waypoint=2
   elseif alive then waypoints={} end
   p:Destroy() busy=false
  end)
 end
 local function projectile(player)
  local char=player.Character local r=char and char:FindFirstChild("HumanoidRootPart") if not r then return end
  local start=root.Position+Vector3.new(0,1,0) local delta=r.Position-start if delta.Magnitude<.1 then return end
  local dir=delta.Unit local orb=Instance.new("Part") orb.Name="ScarletProjectile" orb.Shape=Enum.PartType.Ball
  orb.Size=Vector3.new(1.3,1.3,1.3) orb.Material=Enum.Material.Neon orb.Color=Color3.fromRGB(155,25,39)
  orb.Anchored=true orb.CanCollide=false orb.CanTouch=false orb.CanQuery=false orb.Position=start orb.Parent=model
  local fx=model:FindFirstChild("SpellParticles")
  if fx then for _,d in ipairs(fx:GetChildren()) do local copy=d:Clone() copy.Parent=orb if copy:IsA("ParticleEmitter") then copy.Enabled=true end end end
  local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Exclude p.FilterDescendantsInstances={model}
  local elapsed=0 local c
  c=RunService.Heartbeat:Connect(function(dt)
   if not alive or not orb.Parent then c:Disconnect() orb:Destroy() return end
   elapsed+=dt local move=dir*42*math.min(dt,.1)
   local hit=workspace:Spherecast(orb.Position,.8,move,p)
   if hit then
    for _,pl in ipairs(ctx.players()) do if pl.Character and hit.Instance:IsDescendantOf(pl.Character) then ctx.down(pl) break end end
    c:Disconnect() orb:Destroy()
   elseif elapsed>3 then c:Disconnect() orb:Destroy() else orb.Position+=move end
  end)
 end
 local elapsed=0
 conn=RunService.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.2 then return end elapsed=0
  if not model.Parent then return end
  local now=os.clock() local best=math.huge target=nil
  if model.Name=="Scarlat" and now>=nextAbility then revealUntil=now+2 nextAbility=now+18 model:SetAttribute("Ability","Reveal") end
  if model:GetAttribute("Ability")=="Reveal" and now>revealUntil then model:SetAttribute("Ability","") end
  for _,pl in ipairs(ctx.players()) do
   local r=pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
   if r and ctx.vulnerable(pl) then
    local speed=ctx.speed(pl) local distance=(r.Position-root.Position).Magnitude
    local direction=r.Position-root.Position
    local facing=direction.Magnitude>.01 and root.CFrame.LookVector:Dot(direction.Unit) or 1
    local visible=AI.visible(model.Name,config,distance,speed,los(r.Position,pl.Character),facing,now<revealUntil)
    if visible and distance<best then target=pl best=distance end
   end
  end
  model:SetAttribute("TargetUserId",target and target.UserId or 0)
  if target then goal=target.Character.HumanoidRootPart.Position heardUntil=now+2 end
  if now>heardUntil then goal=nil end
  if not goal and now>=nextPatrol then goal=points[math.random(#points)].Value heardUntil=now+7 nextPatrol=now+7 end
  local speed=target and config.speed or 12
  if model.Name=="Freddy" and target and now>=nextAbility then nextAbility=now+12 attackUntil=now+2 restUntil=now+5 model:SetAttribute("Ability","Dash") end
  if model.Name=="Freddy" and now<restUntil then speed=now<attackUntil and 26 or 5 else if model:GetAttribute("Ability")=="Dash" then model:SetAttribute("Ability","") end end
  if model.Name=="Amanda" and target and best<25 and now>=nextAbility then
   nextAbility=now+10 attackUntil=now+.9 restUntil=now+2.2 model:SetAttribute("Ability","Leap")
  end
  if model.Name=="Amanda" and now<restUntil then speed=now<attackUntil and 0 or 25
  elseif model:GetAttribute("Ability")=="Leap" then model:SetAttribute("Ability","") end
  if model.Name=="Scarlat" and now<revealUntil then speed=0 end
  hum.WalkSpeed=speed
  if goal and speed>0 then
   path(goal)
   local w=waypoints[waypoint]
   if w then
    if (root.Position-w.Position).Magnitude<4 then waypoint+=1 w=waypoints[waypoint] end
    if w then hum:MoveTo(w.Position) if w.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end end
   elseif los(goal,nil) then hum:MoveTo(goal) else hum:MoveTo(root.Position) end
  else hum:MoveTo(root.Position) end
  if model.Name=="Scarlat" and target and best<65 and now>nextShot and now>revealUntil then nextShot=now+5 projectile(target) end
  -- Figure can collide with a quiet player, but never tracks them silently.
  for _,pl in ipairs(ctx.players()) do
   local r=pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
   if r and ctx.vulnerable(pl) and (r.Position-root.Position).Magnitude<config.range and los(r.Position,pl.Character) then
    if model.Name=="Figure" or ctx.speed(pl)>.6 or target==pl then ctx.down(pl) end
   end
  end
 end)
 return {noise=noise,stop=function() alive=false conn:Disconnect() end}
end
return AI
