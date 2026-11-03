local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PF=game:GetService("PathfindingService")
local rig=workspace:WaitForChild("Bramble")
local map=workspace:WaitForChild("PoppyTestMap")
local root=rig.PrimaryPart
local animation=require(RS.ArenaAnimation)
local remote=RS.ArenaControl
local scare=RS.BrambleScare
local switch=workspace.TestPowerSwitch
local driver=animation.new(rig)
local mode="Idle"; local elapsed=0; local heading=root.CFrame.Rotation; local position=root.Position
local home=workspace.TestNavigation.MonsterGround.Position
local footOffset=position.Y-home.Y
local points={}
for _,p in ipairs(workspace.TestNavigation:GetChildren()) do if p.Name:find("Patrol") then table.insert(points,p.Position) end end
local patrolIndex=1; local cooldowns={}; local attack; local attackCooldown=0; local pendingTarget
local powered=false; local generation=0; local awakeAt=0; local currentSpeed=0
local route={}; local routeIndex=1; local routeBusy=false; local routeAt=0; local routeGoal
local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={map,switch,workspace.PowerSwitchBase}; params.RespectCanCollide=true
local function state(name)
 if rig:GetAttribute("State")~=name then rig:SetAttribute("State",name); rig:SetAttribute("StateSince",workspace:GetServerTimeNow()) end
end
local function visible(r)
 local eye=position+Vector3.new(0,1,0)
 return not workspace:Raycast(eye,r.Position-eye,params)
end
local function nearest()
 local best,distance=nil,math.huge
 for _,p in ipairs(Players:GetPlayers()) do
  local char=p.Character; local h=char and char:FindFirstChildOfClass("Humanoid"); local r=char and char:FindFirstChild("HumanoidRootPart")
  if h and r and h.Health>0 and not r.Anchored then
   local d=(r.Position-position).Magnitude
   if d<distance and d<95 and visible(r) then best=p; distance=d end
  end
 end
 return best,distance
end
local function release(kill)
 if not attack then return end
 local record=attack; attack=nil; driver.gripCenter=nil
 if record.root.Parent then record.root.Anchored=record.anchored; record.root.AssemblyLinearVelocity=Vector3.zero; record.root.AssemblyAngularVelocity=Vector3.zero end
 for part,collide in pairs(record.collision) do if part.Parent then part.CanCollide=collide end end
 if record.hum.Parent then
  record.hum.AutoRotate=record.autoRotate; record.hum.WalkSpeed=record.speed; record.hum.JumpPower=record.jump; record.hum.JumpHeight=record.jumpHeight
  if kill then record.hum:TakeDamage(record.hum.MaxHealth) end
 end
 if record.player.Parent then record.player:SetAttribute("BrambleCaptured",false); scare:FireClient(record.player,"End") end
 rig:SetAttribute("CapturedUserId",nil)
 attackCooldown=os.clock()+5; mode=powered and "Walk" or "Idle"; state(mode); currentSpeed=0
end
local function grab(player)
 if attack or os.clock()<attackCooldown then return end
 local char=player and player.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); local r=char and char:FindFirstChild("HumanoidRootPart")
 if not hum or not r or hum.Health<=0 or (r.Position-position).Magnitude>12 or not visible(r) then return end
 local toward=Vector3.new(r.Position.X-position.X,0,r.Position.Z-position.Z)
 if toward.Magnitude>0.01 then heading=CFrame.lookAt(Vector3.zero,toward.Unit).Rotation; rig:PivotTo(CFrame.new(position)*heading) end
 local collision={}
 for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then collision[part]=part.CanCollide; part.CanCollide=false end end
 attack={player=player,hum=hum,root=r,at=os.clock(),from=r.CFrame,anchored=r.Anchored,autoRotate=hum.AutoRotate,speed=hum.WalkSpeed,jump=hum.JumpPower,jumpHeight=hum.JumpHeight,collision=collision}
 hum.AutoRotate=false; hum.WalkSpeed=0; hum.JumpPower=0; hum.JumpHeight=0; r.Anchored=true
 player:SetAttribute("BrambleCaptured",true); rig:SetAttribute("CapturedUserId",player.UserId); state("Attack")
 scare:FireClient(player,"Begin",workspace:GetServerTimeNow())
end
local function clearRoute() route={}; routeIndex=1; routeGoal=nil end
local function plan(target)
 if routeBusy or os.clock()-routeAt<1.2 then return end
 if routeGoal and (routeGoal-target).Magnitude<7 and routeIndex<=#route then return end
 routeBusy=true; routeAt=os.clock(); routeGoal=target
 local token=generation
 task.spawn(function()
  local path=PF:CreatePath({AgentRadius=2.2,AgentHeight=16,AgentCanJump=false,WaypointSpacing=5})
  local ok=pcall(function() path:ComputeAsync(position-Vector3.new(0,footOffset-1,0),target) end)
  if generation==token then
   route=ok and path.Status==Enum.PathStatus.Success and path:GetWaypoints() or {}; routeIndex=2
   rig:SetAttribute("NavigationStatus",#route>0 and "Path" or "Blocked")
  end
  path:Destroy(); routeBusy=false
 end)
end
local function moveToward(target,speed,dt)
 local flat=Vector3.new(target.X-position.X,0,target.Z-position.Z)
 if flat.Magnitude<2 then currentSpeed=0; return true end
 local ground=position-Vector3.new(0,footOffset,0)
 local direct=not workspace:Blockcast(CFrame.new(ground+Vector3.new(0,8.5,0)),Vector3.new(3.6,15,3.6),flat,params)
 local goal=target
 if not direct then
  plan(target)
  local wp=route[routeIndex]
  if not wp then currentSpeed=0; return false end
  goal=wp.Position
  if (Vector3.new(goal.X,ground.Y,goal.Z)-ground).Magnitude<2 then routeIndex+=1; return false end
 end
 local delta=Vector3.new(goal.X-position.X,0,goal.Z-position.Z)
 if delta.Magnitude<0.01 then return false end
 currentSpeed=currentSpeed+(speed-currentSpeed)*(1-math.exp(-dt*4))
 local travel=delta.Unit*math.min(currentSpeed*dt,delta.Magnitude)
 local block=workspace:Blockcast(CFrame.new(ground+Vector3.new(0,8.5,0)),Vector3.new(3.6,15,3.6),travel,params)
 if block then clearRoute(); currentSpeed=0; return false end
 local nextPosition=position+travel
 local floor=workspace:Raycast(Vector3.new(nextPosition.X,ground.Y+3,nextPosition.Z),Vector3.new(0,-6,0),params)
 if not floor or floor.Normal.Y<0.65 or math.abs(floor.Position.Y-ground.Y)>2.5 then currentSpeed=0; return false end
 heading=heading:Lerp(CFrame.lookAt(Vector3.zero,delta.Unit).Rotation,1-math.exp(-dt*7))
 position=Vector3.new(nextPosition.X,floor.Position.Y+footOffset,nextPosition.Z)
 rig:PivotTo(CFrame.new(position)*heading)
 return false
end
local function power(on)
 generation+=1; local token=generation
 powered=on; release(false); pendingTarget=nil; clearRoute(); mode="Idle"; state("Idle"); currentSpeed=0
 workspace:SetAttribute("PowerOn",on); switch:SetAttribute("Powered",on); switch.PowerPrompt.ActionText=on and "Desligar energia" or "Ligar energia"
 workspace:SetAttribute("PowerFlickering",on); workspace:SetAttribute("PowerLampOn",false)
 if on then
  awakeAt=os.clock()+3.1
  task.spawn(function()
   for _,pulse in ipairs({{0.28,true},{0.34,false},{0.45,true},{0.48,false},{0.55,true},{0.5,false}}) do
    if token~=generation then return end
    workspace:SetAttribute("PowerLampOn",pulse[2]); task.wait(pulse[1])
   end
   if token~=generation then return end
   workspace:SetAttribute("PowerLampOn",true); workspace:SetAttribute("PowerFlickering",false)
   awakeAt=os.clock(); mode="Walk"; state("Walk")
  end)
 else workspace:SetAttribute("PowerFlickering",false) end
end
switch.PowerPrompt.Triggered:Connect(function(player)
 local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if r and (r.Position-switch.Position).Magnitude<11 and os.clock()-(cooldowns[player] or 0)>1 then cooldowns[player]=os.clock(); power(not powered) end
end)
remote.OnServerEvent:Connect(function(player,requested)
 if requested~="Idle" and requested~="Walk" and requested~="Run" and requested~="Attack" then return end
 if os.clock()-(cooldowns[player] or 0)<0.5 then return end
 cooldowns[player]=os.clock()
 local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not r or (r.Position-position).Magnitude>140 or attack then return end
 if requested~="Idle" and (not powered or workspace:GetAttribute("PowerFlickering")) then return end
 clearRoute(); pendingTarget=requested=="Attack" and player or nil; mode=requested=="Attack" and "AttackApproach" or requested; state(requested=="Attack" and "Run" or requested)
end)
Players.PlayerRemoving:Connect(function(p) cooldowns[p]=nil; if attack and attack.player==p then release(false) end; if pendingTarget==p then pendingTarget=nil; mode=powered and "Walk" or "Idle" end end)
local function setup(p)
 p.CharacterAdded:Connect(function(char)
  if attack and attack.player==p then release(false) end
  p:SetAttribute("BrambleCaptured",false); char:WaitForChild("Humanoid").WalkSpeed=18
 end)
end
Players.PlayerAdded:Connect(setup); for _,p in ipairs(Players:GetPlayers()) do setup(p) end
state("Idle"); animation.Step(driver,"Idle",0,0,true)
local budget=0
RunService.Heartbeat:Connect(function(dt)
 budget+=dt; if budget<1/30 then return end
 dt=math.min(budget,0.12); budget=0; elapsed+=dt
 if attack then
  local t=os.clock()-attack.at
  if not attack.root.Parent or attack.hum.Health<=0 then release(false)
  else
   local hold=rig:GetPivot()*animation.Hold(t)
   local blend=math.clamp((t-0.35)/0.65,0,1); blend=blend*blend*(3-2*blend)
   local desired=attack.from:Lerp(hold,blend)
   local shift=desired.Position-attack.root.Position
   local groundCheck=shift.Magnitude>0.001 and workspace:Blockcast(attack.root.CFrame,Vector3.new(2,3,1.5),shift,params)
   if groundCheck then release(false); return end
   attack.root.CFrame=desired; driver.gripCenter=desired.Position+Vector3.new(0,0.65,0)
   animation.Step(driver,"Attack",t,dt)
   if t>=2.25 then release(true) end
  end
  return
 end
 if not powered or os.clock()<awakeAt then mode="Idle" end
 if mode=="Walk" then
  local target,distance=nearest()
  if target and distance<45 and os.clock()>attackCooldown then mode="Run"; clearRoute()
  else
   local reached=moveToward(points[patrolIndex],6.5,dt)
   if reached then patrolIndex=patrolIndex%#points+1 end
   state(currentSpeed>0.3 and "Walk" or "Idle")
  end
 elseif mode=="Run" or mode=="AttackApproach" then
  local target=mode=="AttackApproach" and pendingTarget or nearest()
  local char=target and target.Character; local r=char and char:FindFirstChild("HumanoidRootPart"); local h=char and char:FindFirstChildOfClass("Humanoid")
  if r and h and h.Health>0 then
   local distance=(Vector3.new(r.Position.X,position.Y,r.Position.Z)-position).Magnitude
   if distance<6.5 then grab(target) else moveToward(r.Position,21,dt) end
   if not attack then state(currentSpeed>0.3 and "Run" or "Idle") end
  else mode=powered and "Walk" or "Idle"; clearRoute(); state("Idle") end
 else currentSpeed=0; state("Idle") end
 if not attack then animation.Step(driver,rig:GetAttribute("State"),elapsed,dt) end
end)
