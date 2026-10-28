local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local PathfindingService=game:GetService("PathfindingService")
local RunService=game:GetService("RunService")
local Config=require(RS.Shared.Config)
local Campaign=require(RS.Shared.Campaign)
local World=require(script.Parent.World)
local AssetModels=require(script.Parent.AssetModels)
local folder=Instance.new("Folder");folder.Name="BrambleRemotes";folder.Parent=RS
local action=Instance.new("RemoteEvent");action.Name="Action";action.Parent=folder
local update=Instance.new("RemoteEvent");update.Name="Update";update.Parent=folder
local sessions={}
local releaseHeld
local store=DataStoreService:GetDataStore(Config.SaveKey)
AssetModels.load()
World.build()
AssetModels.decorate(World)
local function snapshot(p,s,kind,message)
 update:FireClient(p,kind or "State",{state=s.state,active=s.active,scene=s.scene,dead=s.dead,stamina=s.stamina,message=message,saveStatus=s.saveStatus or "Sessão local",elapsed=s.elapsed,origin=World.Origins[s.state.sector]})
end
local function freeze(p,value)
 local c=p.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 if root then root.Anchored=value end;if h then h.WalkSpeed=if value then 0 else 14;h.JumpPower=35;h.UseJumpPower=true end
end
local function removeEnemy(s) if s.enemy then s.enemy:Destroy();s.enemy=nil end;s.path=nil;s.memory=0;s.lastSeen=nil end
local function save(p,s)
 if s.saving then s.dirty=true;return end
 if not s.loaded then return end
 s.saving=true;s.dirty=false
 local record={state=s.state,elapsed=s.elapsed,savedAt=os.time()}
 task.spawn(function()
  local ok=pcall(function() store:UpdateAsync(tostring(p.UserId),function(old)
   if type(old)=="table" and type(old.savedAt)=="number" and old.savedAt>record.savedAt then return old end;return record
  end) end)
  s.saveStatus=if ok then "Checkpoint salvo" else "Checkpoint nesta sessão; salvamento online indisponível"
  s.saving=false
  if p.Parent then snapshot(p,s) end
  if s.dirty then save(p,s) end
 end)
end
local function beginScene(p,s,ending)
 s.scene=true;s.sceneToken+=1;freeze(p,true)
 snapshot(p,s,if ending then "Ending" else "Scene")
end
local function teleport(p,s)
 local c=p.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
 if root then c:PivotTo(CFrame.new(World.Spawns[s.state.sector]));root.AssemblyLinearVelocity=Vector3.zero end
end
local function characterReady(p,c)
 local s=sessions[p];if not s then return end
 local h=c:WaitForChild("Humanoid",10);local root=c:WaitForChild("HumanoidRootPart",10);if not h or not root then return end
 task.wait(.2)
 if s.active then teleport(p,s) else c:PivotTo(CFrame.new(0,4,100)) end
 freeze(p,not s.active or s.scene or s.dead)
 h.Died:Connect(function() if sessions[p]~=s then return end;s.dead=true;s.active=false;removeEnemy(s);snapshot(p,s,"Dead","A raiz encontrou você.") end)
 snapshot(p,s)
end
local function join(p)
 local s={owner=p,state=Campaign.new(),active=false,scene=false,sceneToken=0,dead=false,stamina=100,elapsed=0,lastAction=0,lastMove=0,run=false,crouch=false,loaded=false,dirty=false,memory=0,pathClock=0}
 sessions[p]=s
 p.CharacterAdded:Connect(function(c) characterReady(p,c) end)
 if p.Character then task.spawn(characterReady,p,p.Character) end
 task.spawn(function()
  local ok,record=pcall(function() return store:GetAsync(tostring(p.UserId)) end)
  if sessions[p]~=s then return end
  if ok and type(record)=="table" then s.state=Campaign.restore(record.state);s.elapsed=math.clamp(tonumber(record.elapsed) or 0,0,60*60*100) end
  s.loaded=true;s.saveStatus=if ok then "Progresso carregado" else "Salvamento online indisponível; progresso nesta sessão"
  if p.Parent then snapshot(p,s,"Ready") end
 end)
end
Players.PlayerAdded:Connect(join);for _,p in ipairs(Players:GetPlayers()) do join(p) end
Players.PlayerRemoving:Connect(function(p) local s=sessions[p];if s then save(p,s);removeEnemy(s);if s.held then for side in pairs(s.held) do releaseHeld(s,side) end end end;sessions[p]=nil end)
local function interact(p,s,id,right,handAlreadyLaunched)
 if type(id)~="string" or #id>60 or type(right)~="boolean" then return end
 if not s.active or s.scene or s.dead or os.clock()-s.lastAction<Config.InteractionCooldown then return end
 local target=World.Targets[id];local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if not target or not root or target:GetAttribute("Sector")~=s.state.sector then return end
 local head=p.Character:FindFirstChild("Head") or root
 local distance=(head.Position-target.Position).Magnitude
 if distance>Config.MaxReach then return end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={p.Character,s.enemy}
 local hit=workspace:Raycast(head.Position,target.Position-head.Position,params)
 if hit and hit.Instance~=target and not hit.Instance:IsDescendantOf(target) then return end
 s.lastAction=os.clock()
 if not handAlreadyLaunched then update:FireClient(p,"Hand",{point=target.Position,right=right}) end
 local sector=s.state.sector
 task.delay(distance/100,function()
  if sessions[p]~=s or not s.active or s.scene or s.dead or sector~=s.state.sector or not root.Parent or (root.Position-target.Position).Magnitude>Config.MaxReach+4 then return end
  local command=target:GetAttribute("Action")
  if command=="protocol" then snapshot(p,s,"Document",Config.Sectors[sector].Protocol);return end
  local nextState,message,changed=Campaign.act(s.state,command,right)
  if changed then
   local oldSector=s.state.sector;s.state=nextState;save(p,s)
   if s.state.finished then removeEnemy(s);beginScene(p,s,true)
   elseif oldSector~=s.state.sector then removeEnemy(s);teleport(p,s);beginScene(p,s,false)
   else snapshot(p,s,"State",message) end
  else snapshot(p,s,"State",message) end
 end)
end
releaseHeld=function(s,side)
 local held=s.held and s.held[side]
 if held then
  if held.align then held.align:Destroy() end
  if held.attachment then held.attachment:Destroy() end
  if held.part and held.part.Parent then held.part:SetAttribute("HeldBy",nil);pcall(function() held.part:SetNetworkOwnershipAuto() end) end
  s.held[side]=nil
  if s.owner and s.owner.Parent then update:FireClient(s.owner,"HandRelease",{right=side==2}) end
 end
end
local function fireHand(p,s,direction,right)
 if not s.active or s.scene or s.dead or type(right)~="boolean" or typeof(direction)~="Vector3" then return end
 if direction.X~=direction.X or direction.Y~=direction.Y or direction.Z~=direction.Z or direction.Magnitude<.5 or direction.Magnitude>2 then return end
 local side=if right then 2 else 1
 s.handClocks=s.handClocks or {0,0};s.held=s.held or {}
 if os.clock()-s.handClocks[side]<.4 then return end
 s.handClocks[side]=os.clock()
 if s.held[side] then releaseHeld(s,side);return end
 local character=p.Character;local head=character and character:FindFirstChild("Head")
 if not head then return end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character}
 local hit=workspace:Raycast(head.Position,direction.Unit*Config.MaxReach,params)
 local point=if hit then hit.Position else head.Position+direction.Unit*Config.MaxReach
 update:FireClient(p,"Hand",{point=point,right=right})
 if not hit then return end
 local target=hit.Instance
 while target and target~=workspace do
  local id=target:GetAttribute("TargetId")
  if id then interact(p,s,id,right,true);return end
  target=target.Parent
 end
 local part=hit.Instance
 if part:IsA("BasePart") and part:GetAttribute("GrabMovable")==true and not part.Anchored and part.AssemblyMass<35 then
  task.delay((point-head.Position).Magnitude/100,function()
   if sessions[p]~=s or not s.active or s.scene or s.dead or not part.Parent or not head.Parent or (part.Position-head.Position).Magnitude>Config.MaxReach+4 then return end
   if part:GetAttribute("HeldBy") then return end
   part:SetAttribute("HeldBy",p.UserId)
   local attachment=Instance.new("Attachment");attachment.Parent=part
   local align=Instance.new("AlignPosition");align.Mode=Enum.PositionAlignmentMode.OneAttachment;align.Attachment0=attachment;align.MaxForce=12000;align.MaxVelocity=25;align.Responsiveness=18;align.Position=head.Position+direction.Unit*6;align.Parent=part
   pcall(function() part:SetNetworkOwner(nil) end)
   s.held[side]={part=part,attachment=attachment,align=align}
   update:FireClient(p,"HandHold",{part=part,right=right})
  end)
 end
end
for id,target in pairs(World.Targets) do target:FindFirstChildOfClass("ProximityPrompt").Triggered:Connect(function(p) local s=sessions[p];if s then interact(p,s,id,false) end end) end
-- Remote requests never accept a client-provided state, position, inventory or completion flag.
action.OnServerEvent:Connect(function(p,verb,arg,extra)
 local s=sessions[p];if not s or type(verb)~="string" then return end
 if verb=="Sync" then snapshot(p,s,if s.loaded then "Ready" else "State");return end
 if verb=="Move" then
  if os.clock()-s.lastMove<.1 then return end;s.lastMove=os.clock()
  if type(arg)=="table" then s.run=arg.run==true;s.crouch=arg.crouch==true end;return
 end
 if verb=="Interact" then interact(p,s,arg,extra);return end
 if verb=="FireHand" then fireHand(p,s,arg,extra);return end
 if verb=="SceneDone" then
  if not s.scene then return end;s.scene=false
  if s.state.finished then s.active=false;freeze(p,true);snapshot(p,s,"Won") else freeze(p,false);snapshot(p,s) end;return
 end
 if verb=="Pause" then if not s.active or s.scene then return end;s.active=false;freeze(p,true);snapshot(p,s,"Paused");return end
 if verb=="Resume" then if s.dead or s.state.finished or s.scene then return end;s.active=true;freeze(p,false);snapshot(p,s);return end
 if verb=="Quit" then p:Kick("Bramble’s Sprout — até a próxima transmissão.");return end
 if verb~="Start" or not s.loaded or os.clock()-s.lastAction<.5 then return end
 s.lastAction=os.clock();removeEnemy(s)
 if arg~=false and s.state.finished then snapshot(p,s,"Won");return end
 if arg==false then s.state=Campaign.new();s.elapsed=0 end
 s.dead=false;s.active=true;s.stamina=100;s.run=false;s.crouch=false
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 then p:LoadCharacterAsync();task.wait(.3) end
 teleport(p,s)
 if arg==false then beginScene(p,s,false) else s.scene=false;freeze(p,false);snapshot(p,s) end
 save(p,s)
end)
local tickClock=0;local saveClock=0
RunService.Heartbeat:Connect(function(dt)
 tickClock+=dt;saveClock+=dt
 local broadcast=tickClock>=.25;if broadcast then tickClock=0 end
 for p,s in pairs(sessions) do
  if s.held then
   for side,held in pairs(s.held) do
    local head=p.Character and p.Character:FindFirstChild("Head")
    if not s.active or s.scene or s.dead or not head or not held.part.Parent or (head.Position-held.part.Position).Magnitude>Config.MaxReach+5 then
     if held.part.Parent then held.part:SetAttribute("HeldBy",nil) end;releaseHeld(s,side)
    else held.align.Position=head.Position+head.CFrame.LookVector*6+head.CFrame.RightVector*(if side==1 then -1 else 1) end
   end
  end
  if s.active and not s.scene and not s.dead then
   s.elapsed+=dt
   local character=p.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid");local root=character and character:FindFirstChild("HumanoidRootPart")
   if humanoid and root then
    local running=s.run and not s.crouch and s.stamina>1 and humanoid.MoveDirection.Magnitude>.1
    s.stamina=math.clamp(s.stamina+(if running then -20 else 13)*dt,0,100)
    humanoid.WalkSpeed=if s.crouch then 7 else if running then 23 else 14
    humanoid.CameraOffset=Vector3.new(0,if s.crouch then -1.2 else 0,0)
    if Campaign.danger(s.state) then
     if not s.enemy then s.enemy=World.createEnemy(workspace,World.EnemySpawns[s.state.sector]);s.pathClock=0 end
     local pos=s.enemy:GetPivot().Position;local gap=(root.Position-pos).Magnitude
     local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={s.enemy,character}
     local sight=workspace:Raycast(pos+Vector3.new(0,2,0),root.Position-pos,params)
     if (not sight and gap<(if s.crouch then 25 else 90)) or (running and gap<55) or gap<9 then s.lastSeen=root.Position;s.memory=5.5 else s.memory=math.max(0,s.memory-dt) end
     s.pathClock-=dt
     if s.pathClock<=0 and s.memory>0 and not s.pathBusy then
      s.pathClock=1.5;s.pathBusy=true;local model=s.enemy;local goal=s.lastSeen
      task.spawn(function()
       local path=PathfindingService:CreatePath({AgentRadius=2.1,AgentHeight=9,AgentCanJump=false,WaypointSpacing=5})
       local ok=pcall(function() path:ComputeAsync(pos,goal) end)
       if s.enemy==model and ok and path.Status==Enum.PathStatus.Success then s.path=path:GetWaypoints();s.waypoint=2 end;s.pathBusy=false
      end)
     end
     if s.path and s.path[s.waypoint] and s.memory>0 then
      local point=s.path[s.waypoint].Position;local delta=Vector3.new(point.X-pos.X,0,point.Z-pos.Z)
      if delta.Magnitude<2 then s.waypoint+=1 else
       local step=delta.Unit*math.min(delta.Magnitude,16*dt)
       local obstacle=workspace:Raycast(pos,pos+step-pos,params)
       if not obstacle then local nextPos=pos+step;s.enemy:PivotTo(CFrame.lookAt(nextPos,nextPos+delta.Unit)) end
      end
     end
     if gap<5 and not sight then s.dead=true;s.active=false;freeze(p,true);removeEnemy(s);snapshot(p,s,"Dead","Ele encontrou você. Retome o checkpoint.") end
    elseif s.enemy then removeEnemy(s) end
   end
  end
  if broadcast and s.active and not s.scene then snapshot(p,s) end
  if saveClock>=30 and s.loaded and s.active then save(p,s) end
 end
 if saveClock>=30 then saveClock=0 end
end)
game:BindToClose(function() for p,s in pairs(sessions) do save(p,s) end;local deadline=os.clock()+8;repeat local pending=false;for _,s in pairs(sessions) do if s.saving then pending=true end end;if not pending then break end;task.wait(.1) until os.clock()>deadline end)
