while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Path=game:GetService('PathfindingService')
local D=require(script.Parent.DisasterService);local Chunks=require(script.Parent.IslandChunks)
while workspace:GetAttribute('IslandWorldReady')~=true do task.wait(.2) end
local Profile=require(script.Parent.SessionProfile)
local center=workspace:GetAttribute('VillageCenter');local event=RS:WaitForChild('AdventureEvent');local quests={};local sneaking={};local cooldown={}
local objectives={'Fale com Helena na vila.','Busque os remédios na estação da floresta.','Entregue os remédios a Helena.','Encontre Lia perto das pedras antigas.','Leve Lia de volta à vila.','Fale com Irene sobre a luz no céu.'}
local function update(p,index)
 local changed=quests[p]~=index;quests[p]=index;if changed then Profile.SaveAdventure(p,index) end;local target=(index==2 and center+Vector3.new(780,0,950)) or (index==4 and center+Vector3.new(760,0,680)) or center
 event:FireClient(p,'mission',index,objectives[index] or 'Você ajudou a vila. Explore com cuidado.',target)
 p:SetAttribute('AdventureMission',index)
end
local function setup(p)
 local data=Profile.Cache[p] or Profile.Load(p);local index=data and data.adventureMission or 1;if index==5 then index=4 end;update(p,index)
 p.CharacterAdded:Connect(function() sneaking[p]=nil end)
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerRemoving:Connect(function(p) quests[p]=nil;sneaking[p]=nil;cooldown[p]=nil end)
event.OnServerEvent:Connect(function(p,action,value)
 if action=='state' then update(p,quests[p] or 1);return end
 if action=='sneak' and typeof(value)=='boolean' then
  sneaking[p]=value;local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if h then h.WalkSpeed=value and 5 or 14 end
 end
end)
local medicine=center+Vector3.new(780,0,950);Chunks.Warm('forestCurrent',medicine,64)
local box=Instance.new('Part');box.Name='MedicineSupplies';box.Size=Vector3.new(3,2,2);box.Color=Color3.fromRGB(154,153,117);box.Material=Enum.Material.Wood;box.Anchored=true;local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain};local ground=assert(workspace:Raycast(medicine+Vector3.new(0,150,0),Vector3.new(0,-350,0),rp),'Medicine floor missing');box.Position=ground.Position+Vector3.new(0,1,0);box.Parent=workspace.Islands.forestCurrent
local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Pegar remédios';prompt.ObjectText='Suprimentos';prompt.MaxActivationDistance=9;prompt.Parent=box
prompt.Triggered:Connect(function(p) local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if r and (r.Position-box.Position).Magnitude<12 and quests[p]==2 then update(p,3) end end)
-- Dialogue actions originate from the server-validated resident prompt.
local signal=script.Parent:FindFirstChild('AdventureTalk') or Instance.new('BindableEvent');signal.Name='AdventureTalk';signal.Parent=script.Parent
signal.Event:Connect(function(p,state)
 local q=quests[p] or 1;local id=state.def.id
 if id=='Helena' and q==1 then update(p,2)
 elseif id=='Helena' and q==3 then update(p,4)
 elseif id=='Lia' and q==4 then state.leader=p;update(p,5)
 elseif id=='Irene' and q==6 then update(p,7) end
end)
local actors=Instance.new('Folder');actors.Name='AdventureThreats';actors.Parent=workspace
local function part(parent,name,size,color,cf)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.Color=color;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Material=Enum.Material.Metal;p.CFrame=cf;p.Parent=parent;return p
end
local ships={};for i=1,3 do
 local ship=Instance.new('Model');ship.Name='Observer_'..i;ship.ModelStreamingMode=Enum.ModelStreamingMode.Persistent;ship.Parent=actors
 local hull=part(ship,'Hull',Vector3.new(32,5,32),Color3.fromRGB(52,64,75),CFrame.new());hull.Shape=Enum.PartType.Ball
 local dome=part(ship,'Dome',Vector3.new(13,7,13),Color3.fromRGB(143,180,194),CFrame.new(0,4,0));dome.Shape=Enum.PartType.Ball;dome.Material=Enum.Material.Glass;dome.Transparency=.25
 local a=Instance.new('Attachment');a.Position=Vector3.new(0,-2,0);a.Parent=hull
 local target=part(ship,'SearchTarget',Vector3.new(1,1,1),Color3.new(),CFrame.new(0,-130,0));target.Transparency=1
 local b=Instance.new('Attachment');b.Parent=target
 local beam=Instance.new('Beam');beam.Attachment0=a;beam.Attachment1=b;beam.Width0=3;beam.Width1=180;beam.FaceCamera=true;beam.Transparency=NumberSequence.new(.8);beam.Color=ColorSequence.new(Color3.fromRGB(172,212,222));beam.Parent=hull
 ship.PrimaryPart=hull;table.insert(ships,{model=ship,phase=i*2.1})
end
local function visible(from,root)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={actors,root.Parent};rp.RespectCanCollide=true
 return workspace:Raycast(from,root.Position-from,rp)==nil
end
local combatAssets=RS:WaitForChild('CombatAssets')
local combatEvent=RS:WaitForChild('CombatEvent')
local hunters={}
local function hunter(pos,tall)
 if #hunters>=7 then return end
 local model=Instance.new('Model');model.Name=tall and 'TheWatcher' or 'SearchAlien';model.Parent=actors
 local root=part(model,'HumanoidRootPart',Vector3.new(2,2,1),Color3.fromRGB(56,66,61),CFrame.new(pos));root.Transparency=1
 local height=tall and 12 or 7
 part(model,'Body',Vector3.new(tall and 1.6 or 2, height*.4,1.2),Color3.fromRGB(55,66,65),CFrame.new(pos+Vector3.new(0,height*.15,0)))
 local head=part(model,'Head',Vector3.new(1.6,2,1.4),Color3.fromRGB(151,165,149),CFrame.new(pos+Vector3.new(0,height*.48,0)));head.Shape=Enum.PartType.Ball
 for _,sign in ipairs({-1,1}) do
  part(model,'Arm',Vector3.new(.45,height*.58,.45),Color3.fromRGB(89,104,96),CFrame.new(pos+Vector3.new(sign*1.3,0,0)))
  part(model,'Leg',Vector3.new(.5,height*.48,.5),Color3.fromRGB(71,83,78),CFrame.new(pos+Vector3.new(sign*.55,-height*.32,0)))
 end
 model.PrimaryPart=root;model:SetAttribute('AlienCombatant',true);model:SetAttribute('AlienHealth',tall and 200 or 90)
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') and p~=root then p.CanQuery=true end end
 if not tall then
  local gun=combatAssets.AlienBlaster:Clone();gun.Name='AlienWeapon';gun:ScaleTo(.8);gun:PivotTo(CFrame.new(pos+Vector3.new(.8,.2,-1.1)));gun.Parent=model
  for _,p in ipairs(gun:GetDescendants()) do if p:IsA('BasePart') then p.Anchored=true;p.CanQuery=false;p.CanCollide=false end end
 end
 table.insert(hunters,{model=model,pos=pos,lastSeen=0,tall=tall,nextFire=os.clock()+1.5,nextPath=0,waypoints={}})
end
hunter(center+Vector3.new(150,8,580),true)
local clock=0
while task.wait(.25) do
 clock+=.25
 for p,q in pairs(quests) do
  if q==5 then for _,s in ipairs(D.Residents) do if s.def.id=='Lia' and s.leader==p and (s.rig.HumanoidRootPart.Position-center).Magnitude<130 then s.leader=nil;p:SetAttribute('NPCRescues',(p:GetAttribute('NPCRescues') or 0)+1);update(p,6);D.Say(s,'Cheguei! Eu achei que ninguém vinha me buscar.');break end end end
 end
 for _,ship in ipairs(ships) do
  local angle=clock*.014+ship.phase;local pos=center+Vector3.new(math.cos(angle)*800,130,math.sin(angle)*500+1150)
  ship.model:PivotTo(CFrame.new(pos))
  for _,p in ipairs(Players:GetPlayers()) do
   local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   if root and p:GetAttribute('IslandDestination')=='forestCurrent' and (root.Position-center).Magnitude>250 then
    local horizontal=Vector3.new(root.Position.X-pos.X,0,root.Position.Z-pos.Z).Magnitude
    local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
    if horizontal<110 and (horizontal<20 or speed>7) and visible(pos,root) and os.clock()>(cooldown[p] or 0) then
     p:SetAttribute('ThreatDetectedUntil',workspace:GetServerTimeNow()+12);cooldown[p]=os.clock()+28;Chunks.Warm('forestCurrent',root.Position,64)
     local amount=math.random()<.4 and 5 or 2;for i=1,amount do local angle=i*math.pi*2/amount;hunter(root.Position+Vector3.new(math.cos(angle)*28,5,math.sin(angle)*28),false) end;event:FireClient(p,'detected','Eles te viram. Quebre a linha de visão!')
    end
   end
  end
 end
 for i=#hunters,1,-1 do if not hunters[i].model.Parent then table.remove(hunters,i) end end
 for _,enemy in ipairs(hunters) do
  if not enemy.model.Parent or enemy.model:GetAttribute('Defeated') then continue end
  local target
  for _,p in ipairs(Players:GetPlayers()) do
   local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
   if root and hum and hum.Health>0 and p:GetAttribute('IslandDestination')=='forestCurrent' and (root.Position-center).Magnitude>210 then
    local distance=(root.Position-enemy.pos).Magnitude;local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
    local facing=(root.Position-enemy.pos).Magnitude>0 and enemy.model:GetPivot().LookVector:Dot((root.Position-enemy.pos).Unit)>.1
    if facing and distance<110 and (not enemy.tall or speed>1.2 or distance<14) and visible(enemy.pos+Vector3.new(0,3,0),root) then target=root;p:SetAttribute('ThreatDetectedUntil',workspace:GetServerTimeNow()+12);if os.clock()-enemy.lastSeen>9 then enemy.alertUntil=os.clock()+.8;event:FireClient(p,'detected','Ele percebeu seu movimento…') end;enemy.lastSeen=os.clock();enemy.goal=root.Position;break end
   end
  end
  if not target and os.clock()-enemy.lastSeen>9 then enemy.goal=center+Vector3.new(math.sin(clock*.025)*500,0,600+math.cos(clock*.025)*450) end
  local goal=enemy.goal
  if goal then
   if os.clock()>enemy.nextPath and not enemy.computing then enemy.computing=true;enemy.nextPath=os.clock()+2
    task.spawn(function()
     local ok=pcall(function() local path=Path:CreatePath({AgentRadius=2,AgentHeight=enemy.tall and 12 or 7,AgentCanJump=false});path:ComputeAsync(enemy.pos,goal);if path.Status==Enum.PathStatus.Success then enemy.waypoints=path:GetWaypoints();enemy.waypoint=2 end end)
     enemy.computing=false
    end)
   end
   local wp=enemy.waypoints[enemy.waypoint or 2];local dest=wp and wp.Position or goal
   local delta=Vector3.new(dest.X-enemy.pos.X,0,dest.Z-enemy.pos.Z)
   if delta.Magnitude>1 and os.clock()>(enemy.alertUntil or 0) then
    local step=delta.Unit*math.min(delta.Magnitude,(target and 23 or 7)*.25)
    local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain,workspace.Islands.forestCurrent};rp.RespectCanCollide=true
    if not workspace:Raycast(enemy.pos+Vector3.new(0,2,0),step+step.Unit*2,rp) then enemy.pos+=step end
    local floor=workspace:Raycast(enemy.pos+Vector3.new(0,25,0),Vector3.new(0,-60,0),rp);if floor then enemy.pos=Vector3.new(enemy.pos.X,floor.Position.Y+4,enemy.pos.Z) end
    enemy.model:SetAttribute('MotionTarget',CFrame.lookAt(enemy.pos,enemy.pos+delta.Unit));enemy.model:PivotTo(CFrame.lookAt(enemy.pos,enemy.pos+delta.Unit))
    if delta.Magnitude<4 and wp then enemy.waypoint=(enemy.waypoint or 2)+1 end
   end
   if target and not enemy.tall and os.clock()>(enemy.nextFire or 0) then
    enemy.burst=(enemy.burst or 0)+1;enemy.nextFire=os.clock()+(enemy.burst>=3 and 4.5 or .3);if enemy.burst>=3 then enemy.burst=0 end
    local origin=enemy.pos+Vector3.new(0,2,0)
    local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={actors}
    local hit=workspace:Raycast(origin,(target.Position-origin).Unit*120,rp)
    local endpoint=hit and hit.Position or origin+(target.Position-origin).Unit*120
    combatEvent:FireAllClients('alienShot',origin,endpoint)
    if hit and hit.Instance:IsDescendantOf(target.Parent) then local h=target.Parent:FindFirstChildOfClass('Humanoid');if h then h:TakeDamage(4) end end
   end
   if target and (target.Position-enemy.pos).Magnitude<6 then local h=target.Parent:FindFirstChildOfClass('Humanoid');if h then h:TakeDamage(9) end end
  end
 end
end
