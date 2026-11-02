local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Debris=game:GetService('Debris')
local Shared=RS:WaitForChild('WaterRPG')
local Assets=Shared:WaitForChild('PlayerAssets')
local Remote=Shared:WaitForChild('Ability')
local last,stamina,breath,regenAt,wallAt,swapAt,shotAt={},{},{},{},{},{},{}
local projectiles={}
local effects=Instance.new('Folder');effects.Name='RPGEffects';effects.Parent=workspace
local function living(p)
 local c=p.Character;local root=c and c:FindFirstChild('HumanoidRootPart');local h=c and c:FindFirstChildOfClass('Humanoid')
 if not c or not root or not h or h.Health<=0 or p:GetAttribute('InMenu') then return end
 return c,root,h
end
local function notice(p,s) Shared.Feedback:FireClient(p,'Notice',s) end
local function waterAt(pos)
 local a=Vector3.new(math.floor(pos.X/4)*4,math.floor(pos.Y/4)*4,math.floor(pos.Z/4)*4)
 local materials,occupancy=workspace.Terrain:ReadVoxels(Region3.new(a,a+Vector3.new(4,4,4)),4)
 return materials[1][1][1]==Enum.Material.Water and occupancy[1][1][1]>.15
end
local function wall(c,root)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={c,effects,workspace.Residents};params.IgnoreWater=true
 local best
 for _,d in ipairs({root.CFrame.LookVector,root.CFrame.RightVector,-root.CFrame.RightVector,-root.CFrame.LookVector}) do
  local hit=workspace:Raycast(root.Position,d*4.2,params)
  if hit and math.abs(hit.Normal.Y)<.35 and hit.Instance.CanCollide then best=hit;break end
 end
 return best
end
local function attachLamp(c)
 local torso=c:FindFirstChild('Torso') or c:FindFirstChild('UpperTorso');if not torso then return end
 local model=Assets.ClassicLantern:Clone();model.Name='ClassicLantern';model.Parent=c
 for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.Massless=true end end
 local main=model:FindFirstChild('MainPart');local weld=main and main:FindFirstChild('Weld')
 if main and weld then weld.Part0=main;weld.Part1=torso end
 for _,light in ipairs(model:GetDescendants()) do if light:IsA('Light') then light.Enabled=false end end
end
local function bow(p,on)
 local c=living(p);if not c then return end
 local existing=c:FindFirstChild('PlayerBow');if existing then existing:Destroy() end
 p:SetAttribute('BowEquipped',on);p:SetAttribute('BowAiming',false)
 if not on then return end
 local model=Assets.Bow:Clone();model.Name='PlayerBow';model.Parent=c
 local arm=c:FindFirstChild('Left Arm') or c:FindFirstChild('LeftHand');local root=model:FindFirstChild('RootPart')
 local weld=model:FindFirstChild('Weld')
 if not arm or not root or not weld then model:Destroy();p:SetAttribute('BowEquipped',false);return end
 for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.Massless=true end end
 weld.Part0=arm;weld.Part1=root;weld.Parent=arm
 -- Keep the attachment inside the model so unequipping also removes the joint.
 weld.Parent=root
 for _,entry in ipairs({{'PT_Bow_01_a_body','PT_Bow_01_a_bodyMotor6D'},{'PT_Bow_01_a_string','PT_Bow_01_a_stringMotor6D'}}) do
  local part=model:FindFirstChild(entry[1]);local joint=part and part:FindFirstChild(entry[2]);if joint then joint.Part0=root;joint.Part1=part end
 end
end
local function prepare(p,c)
 stamina[p]=100;breath[p]=60;regenAt[p]=0
 for k,v in pairs({Stamina=100,Breath=60,WallMode='',WallWalkEnabled=false,BowEquipped=false,BowAiming=false,LanternOn=false,SwapReadyAt=0}) do p:SetAttribute(k,v) end
 attachLamp(c)
end
local function addPlayer(p) p.CharacterAdded:Connect(function(c) c:WaitForChild('HumanoidRootPart',10);task.wait(.1);if p.Character==c then prepare(p,c) end end) end
Players.PlayerAdded:Connect(addPlayer);for _,p in ipairs(Players:GetPlayers()) do addPlayer(p) end
Players.PlayerRemoving:Connect(function(p) last[p]=nil;stamina[p]=nil;breath[p]=nil;regenAt[p]=nil;wallAt[p]=nil;swapAt[p]=nil;shotAt[p]=nil end)
local function clearAt(c,cf,other)
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={c,other,effects,workspace.Residents};params.RespectCanCollide=true
 for _,part in ipairs(workspace:GetPartBoundsInBox(cf,Vector3.new(2.5,4.5,2.5),params)) do if part.CanCollide and not Players:GetPlayerFromCharacter(part.Parent) then return false end end
 return true
end
Remote.OnServerEvent:Connect(function(p,kind,arg)
 if type(kind)~='string' or not ({Lantern=true,Bow=true,Aim=true,Shoot=true,Swap=true,WallWalk=true,WallRun=true,EndWall=true})[kind] then return end
 local times=last[p] or {};last[p]=times;local now=os.clock()
 if now-(times[kind] or -100)<.18 then return end;times[kind]=now
 local c,root,h=living(p);if not c then return end
 if kind=='Lantern' then
  local on=not p:GetAttribute('LanternOn');p:SetAttribute('LanternOn',on)
  local lamp=c:FindFirstChild('ClassicLantern');if lamp then for _,x in ipairs(lamp:GetDescendants()) do if x:IsA('Light') then x.Enabled=on;x.Brightness=on and 1.6 or 0 end end end
 elseif kind=='Bow' then bow(p,not p:GetAttribute('BowEquipped'))
 elseif kind=='Aim' and type(arg)=='boolean' then p:SetAttribute('BowAiming',p:GetAttribute('BowEquipped') and arg or false)
 elseif kind=='Shoot' then
  if not p:GetAttribute('BowEquipped') or now-(shotAt[p] or -100)<1 or type(arg)~='vector' and typeof(arg)~='Vector3' then return end
  if arg.X~=arg.X or arg.Y~=arg.Y or arg.Z~=arg.Z or arg.Magnitude<.5 or arg.Magnitude>2 then return end
  shotAt[p]=now
  local arrow=Assets.Arrow:Clone();arrow.Name='Arrow';arrow.Anchored=true;arrow.CanCollide=false;arrow.CanTouch=false;arrow.Parent=effects
  local start=(root.CFrame*CFrame.new(1,1,-2)).Position
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={c,effects}
  table.insert(projectiles,{part=arrow,pos=start,velocity=arg.Unit*105,born=now,params=ray,owner=p})
  Shared.Feedback:FireClient(p,'BowShot',true)
 elseif kind=='Swap' then
  if now-(swapAt[p] or -100)<12 or typeof(arg)~='Instance' or not arg:IsA('Model') then return end
  local target=Players:GetPlayerFromCharacter(arg);local tr=arg:FindFirstChild('HumanoidRootPart');local th=arg:FindFirstChildOfClass('Humanoid')
  if not tr or not th or th.Health<=0 or arg==c or (root.Position-tr.Position).Magnitude>65 then return end
  if not target and not arg:GetAttribute('TrainingTarget') then notice(p,'Escolha outro jogador ou um alvo de treino.');return end
  if target and target:GetAttribute('InMenu') then return end
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={c,arg,effects}
  if workspace:Raycast(root.Position,tr.Position-root.Position,ray) then return end
  if not clearAt(c,tr.CFrame,arg) or not clearAt(arg,root.CFrame,c) then return end
  swapAt[p]=now;p:SetAttribute('SwapReadyAt',workspace:GetServerTimeNow()+12)
  local first,second=root.CFrame,tr.CFrame
  root.AssemblyLinearVelocity=Vector3.zero;tr.AssemblyLinearVelocity=Vector3.zero
  c:PivotTo(second);arg:PivotTo(first)
  for _,cf in ipairs({first,second}) do
   local v=Assets:FindFirstChild('ClapVFX');if v then local clone=v:Clone();clone.CFrame=cf;clone.Anchored=true;clone.CanCollide=false;clone.Parent=effects
    for _,emitter in ipairs(clone:GetDescendants()) do if emitter:IsA('ParticleEmitter') then emitter.Enabled=false;emitter:Emit(math.min(emitter:GetAttribute('EmitCount') or 6,20)) end end;Debris:AddItem(clone,3)
   end
  end
  local sound=Assets:FindFirstChild('SwapSound');if sound then local s=sound:Clone();s.Parent=root;s:Play();Debris:AddItem(s,4) end
  Shared.Feedback:FireClient(p,'Swapped',true)
 elseif kind=='WallWalk' then
  local enabled=not p:GetAttribute('WallWalkEnabled');p:SetAttribute('WallWalkEnabled',enabled)
  for _,name in ipairs({'Left Leg','Right Leg','LeftFoot','RightFoot'}) do
   local leg=c:FindFirstChild(name)
   if leg then
    local old=leg:FindFirstChild('ChakraFeet');if old then old:Destroy() end
    if enabled then
     local effect=Assets.ChakraFeet:Clone();effect.Name='ChakraFeet';effect.Anchored=false;effect.CanCollide=false;effect.CanTouch=false;effect.Massless=true;effect.CFrame=leg.CFrame*CFrame.new(0,-.8,0);effect.Parent=leg
     local joint=Instance.new('WeldConstraint');joint.Part0=leg;joint.Part1=effect;joint.Parent=effect
    end
   end
  end
  if not enabled then p:SetAttribute('WallMode','') elseif (stamina[p] or 0)>10 then local hit=wall(c,root);if hit then p:SetAttribute('WallMode','Walk');wallAt[p]=now end end
 elseif kind=='WallRun' then
  if p:GetAttribute('WallMode')~='' or p:GetAttribute('WallWalkEnabled') or not p:GetAttribute('Sprinting') or h.FloorMaterial~=Enum.Material.Air or (stamina[p] or 0)<10 then return end
  local hit=wall(c,root);if hit then p:SetAttribute('WallMode','Run');wallAt[p]=now end
 elseif kind=='EndWall' then p:SetAttribute('WallMode','');wallAt[p]=nil end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 local now=os.clock()
 for i=#projectiles,1,-1 do
  local a=projectiles[i]
  local gravity=Vector3.new(0,-workspace.Gravity*.55,0)
  local step=math.min(dt,.08);local delta=a.velocity*step+gravity*(step*step*.5)
  local hit=workspace:Raycast(a.pos,delta,a.params)
  if hit or now-a.born>5 or not a.part.Parent then
   if hit then
    a.pos=hit.Position
    local model=hit.Instance:FindFirstAncestorOfClass('Model');local h=model and model:FindFirstChildOfClass('Humanoid')
    if h and model:GetAttribute('TrainingTarget') then h:TakeDamage(15);if h.Health<=0 then task.delay(3,function() if h.Parent then h.Health=h.MaxHealth end end) end end
   end
   a.part:Destroy();table.remove(projectiles,i)
  else a.pos+=delta;a.velocity+=gravity*step;a.part.CFrame=CFrame.lookAt(a.pos,a.pos+a.velocity)*CFrame.Angles(math.rad(-90),0,0) end
 end
 elapsed+=dt;if elapsed<.2 then return end;local step=math.min(elapsed,.5);elapsed=0
 for _,p in ipairs(Players:GetPlayers()) do
  local c,root,h=living(p)
  if c then
   local mode=p:GetAttribute('WallMode') or ''
   local swim=waterAt(root.Position);local head=c:FindFirstChild('Head');local underwater=head and waterAt(head.Position) or false
   p:SetAttribute('Swimming',swim);p:SetAttribute('Underwater',underwater)
   local staminaNow=stamina[p] or 100
   if mode~='' then
    local hit=wall(c,root)
    if not hit or swim or staminaNow<=0 or (mode=='Run' and now-(wallAt[p] or now)>2.8) then mode='';p:SetAttribute('WallMode','') end
   elseif p:GetAttribute('WallWalkEnabled') and not swim and staminaNow>10 then local hit=wall(c,root);if hit then mode='Walk';p:SetAttribute('WallMode',mode);wallAt[p]=now end end
   local running=p:GetAttribute('Sprinting') and h.MoveDirection.Magnitude>.1 and not swim
   local drain=mode~='' and 24 or (running and 10 or 0)
   if drain>0 then staminaNow=math.max(0,staminaNow-drain*step);regenAt[p]=now+1
   elseif now>(regenAt[p] or 0) then staminaNow=math.min(100,staminaNow+20*step) end
   stamina[p]=staminaNow;p:SetAttribute('Stamina',math.floor(staminaNow))
   if staminaNow<=0 then p:SetAttribute('Sprinting',false);p:SetAttribute('WallMode','');p:SetAttribute('WallWalkEnabled',false) end
   if mode=='' then h.WalkSpeed=swim and 20 or (p:GetAttribute('BowAiming') and 7 or (p:GetAttribute('Sprinting') and staminaNow>0 and 21 or 14)) end
   local air=breath[p] or 60;air=math.clamp(air+(underwater and -1 or 12)*step,0,60);breath[p]=air;p:SetAttribute('Breath',math.ceil(air))
   if underwater and air<=0 then h:TakeDamage(8*step) end
  end
 end
end)
