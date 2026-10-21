-- Overyard Mage Duel V2 - exact requested assets + enhanced combat
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")

local remotes=ReplicatedStorage:WaitForChild("MageDuelRemotes")
local cast=remotes:WaitForChild("Cast")
local feedback=remotes:WaitForChild("Feedback")
local world=workspace:WaitForChild("MageDuelWorld")
local templates=ReplicatedStorage:WaitForChild("MageAssetTemplates")
local boss=world:WaitForChild("AstraVeyra")
local hum=boss:WaitForChild("Humanoid")
local root=boss:WaitForChild("HumanoidRootPart")

local C={
 white=Color3.fromRGB(245,251,255),
 ice=Color3.fromRGB(195,232,255),
 blue=Color3.fromRGB(105,164,255),
 violet=Color3.fromRGB(174,128,255),
 gold=Color3.fromRGB(255,225,132),
 dark=Color3.fromRGB(18,14,30),
 storm=Color3.fromRGB(178,215,255),
}
local ARENA=290
local active=false
local target=nil
local bossCD={}
local playerCD={}
local bossShield={untilTime=0,layers=0}
local playerShield={}
local poseBusy=false
local motors={}
for _,d in ipairs(boss:GetDescendants())do
 if d:IsA("Motor6D")then
  motors[d.Name]=d
  local aliases={
   ["Right Shoulder"]="RightShoulder",["Left Shoulder"]="LeftShoulder",
   ["Right Hip"]="RightHip",["Left Hip"]="LeftHip",["RootJoint"]="Root",
   ["Neck"]="Neck",
  }
  if aliases[d.Name]then motors[aliases[d.Name]]=d end
 end
end

local function now() return os.clock() end
local function ready(tbl,key,cd)
 if (tbl[key] or 0)>now() then return false end
 tbl[key]=now()+cd
 return true
end
local function tween(obj,t,props,style,dir)
 local tw=TweenService:Create(obj,TweenInfo.new(t,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props)
 tw:Play();return tw
end
local function folder(name,life)
 local f=Instance.new("Folder");f.Name=name;f.Parent=world
 if life then Debris:AddItem(f,life)end
 return f
end
local function ppart(parent,name,size,cf,color,material,trans)
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Color=color;p.Material=material or Enum.Material.Neon;p.Transparency=trans or 0;p.Parent=parent
 return p
end
local function orb(parent,pos,size,color,life,trans)
 local p=ppart(parent,"ManaOrb",Vector3.new(size,size,size),CFrame.new(pos),color,Enum.Material.Neon,trans or 0)
 p.Shape=Enum.PartType.Ball
 local l=Instance.new("PointLight");l.Color=color;l.Brightness=1.8;l.Range=math.max(8,size*7);l.Parent=p
 if life then Debris:AddItem(p,life)end
 return p
end
local function seg(parent,a,b,w,color,life,trans)
 local d=b-a;local len=d.Magnitude;if len<.02 then return nil end
 local p=ppart(parent,"ManaLine",Vector3.new(w,w,len),CFrame.lookAt((a+b)/2,b),color,Enum.Material.Neon,trans or 0)
 if life then Debris:AddItem(p,life)end
 return p
end
local function dust(pos,color,count,spread,life)
 local f=folder("ManaDust",life+0.5)
 local anchor=ppart(f,"DustAnchor",Vector3.new(.2,.2,.2),CFrame.new(pos),color,Enum.Material.Neon,1)
 local e=Instance.new("ParticleEmitter")
 e.Rate=0;e.LightEmission=.8;e.Lifetime=NumberRange.new(life*.55,life);e.Speed=NumberRange.new(spread*.35,spread)
 e.SpreadAngle=Vector2.new(180,180);e.Drag=1.6;e.Acceleration=Vector3.new(0,-1.5,0)
 e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.16),NumberSequenceKeypoint.new(.55,.08),NumberSequenceKeypoint.new(1,0)})
 e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.75,.35),NumberSequenceKeypoint.new(1,1)})
 e.Color=ColorSequence.new(color);e.Parent=anchor;e:Emit(count)
 return f
end
local function shards(pos,normal,color,count)
 local f=folder("BarrierShards",1.15)
 for i=1,count do
  local s=Instance.new("WedgePart")
  s.Name="ManaShard";s.Anchored=true;s.CanCollide=false;s.CanTouch=false;s.CanQuery=false;s.CastShadow=false
  local n=math.random(9,20)/100
  s.Size=Vector3.new(n,math.random(14,34)/100,n*2.2);s.Material=Enum.Material.Glass;s.Color=color;s.Transparency=.08
  local tangent=Vector3.new(normal.Z,0,-normal.X)
  if tangent.Magnitude<.1 then tangent=Vector3.new(1,0,0)end
  local offset=tangent.Unit*math.random(-18,18)/10+Vector3.new(0,math.random(-12,12)/10,0)
  s.CFrame=CFrame.lookAt(pos+offset,pos+offset+normal)*CFrame.Angles(math.random(),math.random(),math.random());s.Parent=f
  local goal=s.CFrame+normal*math.random(12,28)/10+Vector3.new(math.random(-8,8)/10,math.random(-4,15)/10,math.random(-8,8)/10)
  tween(s,.75,{CFrame=goal,Transparency=1,Size=s.Size*.35},Enum.EasingStyle.Quad)
 end
 dust(pos,color,28,5,.85)
end

local function ringPoints(cf,r,n)
 local pts={}
 for i=0,n-1 do
  local a=i/n*math.pi*2
  pts[i+1]=cf:PointToWorldSpace(Vector3.new(math.cos(a)*r,math.sin(a)*r,0))
 end
 return pts
end
local function proceduralMagicCircle(cf,r,color,life)
 local model=Instance.new("Model");model.Name="RotatingMagicCircle";model.Parent=world
 local rings={{r,48,.10},{r*.73,40,.075},{r*.43,32,.065}}
 for ri,data in ipairs(rings)do
  local pts=ringPoints(cf,data[1],data[2])
  for i=1,#pts do seg(model,pts[i],pts[i%#pts+1],data[3],color,life,.05)end
 end
 for i=1,12 do
  local a=i/12*math.pi*2
  local p1=cf:PointToWorldSpace(Vector3.new(math.cos(a)*r*.78,math.sin(a)*r*.78,0))
  local p2=cf:PointToWorldSpace(Vector3.new(math.cos(a)*r*.96,math.sin(a)*r*.96,0))
  seg(model,p1,p2,.12,color,life,0)
 end
 for i=1,6 do
  local a=(i-1)/6*math.pi*2;local b=i/6*math.pi*2
  local p1=cf:PointToWorldSpace(Vector3.new(math.cos(a)*r*.52,math.sin(a)*r*.52,0))
  local p2=cf:PointToWorldSpace(Vector3.new(math.cos(b)*r*.52,math.sin(b)*r*.52,0))
  seg(model,p1,p2,.08,color,life,.08)
 end
 local center=orb(model,cf.Position,.42,color,life,.05);model.PrimaryPart=center
 task.spawn(function()
  local t0=now()
  while model.Parent and now()-t0<life do
   local dt=RunService.Heartbeat:Wait()
   model:PivotTo(model:GetPivot()*CFrame.Angles(0,0,dt*.75))
  end
 end)
 Debris:AddItem(model,life)
 return model
end


local function sanitizeClone(obj)
 for _,d in ipairs(obj:GetDescendants())do
  if d:IsA("LuaSourceContainer") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then d:Destroy()
  elseif d:IsA("BasePart")then d.CanCollide=false;d.CanTouch=false;d.CanQuery=false end
 end
 return obj
end

local function fitModel(model,cf,targetDiameter,life)
 local ok,boxCF,size=pcall(function()return model:GetBoundingBox()end)
 if not ok then return nil end
 local maxDim=math.max(size.X,size.Y,size.Z)
 local scale=maxDim>0 and targetDiameter/maxDim or 1
 pcall(function()model:ScaleTo(scale)end)
 local cf2,size2=model:GetBoundingBox()
 model:PivotTo(cf*cf2.Rotation:Inverse())
 local cf3=model:GetBoundingBox()
 model:PivotTo(cf*(cf3:Inverse()*model:GetPivot()))
 if life then Debris:AddItem(model,life)end
 return model
end

local function smartMagicCircle(cf,r,color,life)
 local bank=templates:FindFirstChild("MagicCircles")
 if bank then
  local candidates={}
  for _,d in ipairs(bank:GetChildren())do
   if d:IsA("Model") or d:IsA("BasePart")then table.insert(candidates,d)end
  end
  if #candidates>0 then
   local chosen=candidates[math.random(1,#candidates)]
   local clone=chosen:Clone()
   clone.Name="RequestedMagicCircle"
   clone.Parent=world
   sanitizeClone(clone)
   if clone:IsA("BasePart")then
    clone.Anchored=true;clone.Material=Enum.Material.Neon;clone.Color=color;clone.CFrame=cf
    local max=math.max(clone.Size.X,clone.Size.Y,clone.Size.Z)
    if max>0 then clone.Size=clone.Size*(r*2/max) end
    Debris:AddItem(clone,life)
    task.spawn(function()
     local t0=now()
     while clone.Parent and now()-t0<life do
      local dt=RunService.Heartbeat:Wait()
      clone.CFrame=clone.CFrame*CFrame.Angles(0,0,dt*.85)
     end
    end)
    return clone
   elseif clone:IsA("Model")then
    local parts={}
    for _,p in ipairs(clone:GetDescendants())do
     if p:IsA("BasePart")then p.Anchored=true;table.insert(parts,p)end
    end
    if #parts>0 then
     local bcf,bs=clone:GetBoundingBox()
     local max=math.max(bs.X,bs.Y,bs.Z)
     pcall(function()clone:ScaleTo(max>0 and (r*2/max) or 1)end)
     clone:PivotTo(cf)
     Debris:AddItem(clone,life)
     task.spawn(function()
      local t0=now()
      while clone.Parent and now()-t0<life do
       local dt=RunService.Heartbeat:Wait()
       clone:PivotTo(clone:GetPivot()*CFrame.Angles(0,0,dt*.85))
      end
     end)
     return clone
    end
   end
  end
 end
 return proceduralMagicCircle(cf,r,color,life)
end

local function emitTemplate(name,pos,scale,life)
 local src=templates:FindFirstChild(name)
 if not src then return nil end
 local clone=src:Clone();clone.Name=name.."Runtime";clone.Parent=world;sanitizeClone(clone)
 local rootPart=clone:IsA("BasePart") and clone or clone:FindFirstChildWhichIsA("BasePart",true)
 if rootPart then
  if clone:IsA("Model")then
   local cf,size=clone:GetBoundingBox()
   local max=math.max(size.X,size.Y,size.Z)
   if scale and max>0 then pcall(function()clone:ScaleTo(scale/max)end)end
   clone:PivotTo(CFrame.new(pos))
  else
   rootPart.Anchored=true
   if scale then
    local max=math.max(rootPart.Size.X,rootPart.Size.Y,rootPart.Size.Z)
    if max>0 then rootPart.Size=rootPart.Size*(scale/max)end
   end
   rootPart.CFrame=CFrame.new(pos)
  end
 end
 for _,d in ipairs(clone:GetDescendants())do
  if d:IsA("ParticleEmitter")then
   d.Enabled=true
   pcall(function()d:Emit(math.clamp(math.floor(d.Rate*.18)+8,8,40))end)
  end
 end
 Debris:AddItem(clone,life or 1.2)
 return clone
end

local function hexPts(cf,x,y,r)
 local pts={}
 for i=0,5 do
  local a=math.rad(60*i+30)
  pts[i+1]=cf:PointToWorldSpace(Vector3.new(x+math.cos(a)*r,y+math.sin(a)*r,0))
 end
 return pts
end
local function barrierVisual(ownerPos,facePos,color,life,layers)
 local f=folder("LayeredHexBarrier",life+.25)
 local base=CFrame.lookAt(ownerPos,facePos)
 layers=layers or 3
 for layer=1,layers do
  local layerCF=base*CFrame.new(0,0,(layer-1)*-.38)
  local r=1.55+(layer-1)*.05
  for row=-1,1 do
   for col=-2,2 do
    if not (math.abs(row)==1 and math.abs(col)==2) then
     local x=col*r*1.74+((row%2)*r*.87)
     local y=row*r*1.51
     local pts=hexPts(layerCF,x,y,r)
     for i=1,6 do seg(f,pts[i],pts[i%6+1],.085+(layers-layer)*.012,color,life,.04+(layer-1)*.08)end
    end
   end
  end
 end
 local glow=ppart(f,"BarrierGlow",Vector3.new(13,9,.08),base,color,Enum.Material.ForceField,.82)
 return f,base
end
local function barrierBreak(pos,facePos,color,layer)
 local normal=(pos-facePos).Magnitude>.1 and (pos-facePos).Unit or Vector3.new(0,0,1)
 shards(pos,normal,color,18+layer*4)
end

local function beam(origin,target,life)
 local f=folder("PiercingBeam",life+.25)
 local core=seg(f,origin,target,.28,C.white,life,.01)
 local aura=seg(f,origin,target,.75,C.blue,life,.62)
 local dir=(target-origin).Unit
 local len=(target-origin).Magnitude
 for i=1,math.max(5,math.floor(len/8)) do
  local t=i/(math.max(5,math.floor(len/8))+1)
  local center=origin:Lerp(target,t)
  local a=t*math.pi*10
  local offset=Vector3.new(math.cos(a),math.sin(a),0)*.38
  local o=orb(f,center+offset,.12,C.ice,life,.05)
 end
 return f
end
local function impact(pos,color)
 emitTemplate("BlackFlash",pos,7,.8)
 dust(pos,color,34,7,.8)
 local f=folder("ImpactNeedles",.55)
 for i=1,12 do
  local dir=Vector3.new(math.random(-100,100),math.random(-40,100),math.random(-100,100)).Unit
  seg(f,pos,pos+dir*math.random(18,45)/10,.09,color,.48,.05)
 end
end

local function lightning(origin,target)
 local f=folder("GeometricLightning",.7)
 local points={origin}
 local delta=target-origin
 local steps=8
 for i=1,steps-1 do
  local t=i/steps
  local base=origin+delta*t
  local j=Vector3.new(math.random(-42,42)/10,math.random(-28,28)/10,math.random(-42,42)/10)
  points[#points+1]=base+j
 end
 points[#points+1]=target
 for i=1,#points-1 do
  seg(f,points[i],points[i+1],.23,C.white,.62,.02)
  seg(f,points[i],points[i+1],.62,C.storm,.62,.62)
  if i>1 and i<#points and i%2==0 then
   local branchStart=points[i]
   local b1=branchStart+Vector3.new(math.random(-8,8),math.random(-3,8),math.random(-8,8))
   local b2=b1+Vector3.new(math.random(-6,6),math.random(-5,4),math.random(-6,6))
   seg(f,branchStart,b1,.11,C.storm,.55,.08);seg(f,b1,b2,.08,C.storm,.55,.15)
  end
 end
 impact(target,C.storm)
end

local function singularity(pos)
 emitTemplate("GravityField",pos,24,2.4)
 local f=folder("SpatialCollapse",2.6)
 local core=orb(f,pos,2.3,C.dark,2.5,0);core.Material=Enum.Material.SmoothPlastic
 local halo=orb(f,pos,3.2,C.violet,2.5,.72);halo.Material=Enum.Material.ForceField
 local rings={}
 for j=1,3 do
  local model=Instance.new("Model");model.Name="GravityRing";model.Parent=f
  local cf=CFrame.new(pos)*CFrame.Angles(math.rad(90),math.rad(j*37),math.rad(j*23))
  local pts=ringPoints(cf,3.8+j*.8,32)
  for i=1,#pts do seg(model,pts[i],pts[i%#pts+1],.08,C.ice,2.4,.18)end
  rings[#rings+1]=model
 end
 local dustAnchor=ppart(f,"InwardDust",Vector3.new(.2,.2,.2),CFrame.new(pos),C.violet,Enum.Material.Neon,1)
 local e=Instance.new("ParticleEmitter")
 e.Rate=85;e.Lifetime=NumberRange.new(.7,1.1);e.Speed=NumberRange.new(-8,-3);e.SpreadAngle=Vector2.new(180,180)
 e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.12),NumberSequenceKeypoint.new(1,0)});e.Color=ColorSequence.new(C.violet);e.LightEmission=1;e.Parent=dustAnchor
 task.spawn(function()
  local t0=now()
  while f.Parent and now()-t0<2.1 do
   local dt=RunService.Heartbeat:Wait()
   for i,m in ipairs(rings)do if m.Parent then m:PivotTo(CFrame.new(pos)*CFrame.Angles(dt*i*.8,dt*i*1.1,dt*i*.55)*m:GetPivot().Rotation) end end
  end
 end)
 task.delay(1.45,function()
  if not core.Parent then return end
  e.Enabled=false
  tween(core,.22,{Size=Vector3.new(.2,.2,.2)},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
  tween(halo,.22,{Size=Vector3.new(.4,.4,.4),Transparency=1},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
  task.wait(.24)
  local shock=orb(f,pos,.5,C.white,.45,.65);shock.Material=Enum.Material.ForceField
  tween(shock,.35,{Size=Vector3.new(24,24,24),Transparency=1},Enum.EasingStyle.Quart)
  dust(pos,C.white,48,11,.8)
 end)
 return f
end

local function alivePlayer(plr)
 local ch=plr and plr.Character
 local h=ch and ch:FindFirstChildOfClass("Humanoid")
 local r=ch and ch:FindFirstChild("HumanoidRootPart")
 if ch and h and r and h.Health>0 then return ch,h,r end
end
local function faceBoss(pos)
 local here=root.Position
 local flat=Vector3.new(pos.X,here.Y,pos.Z)
 if (flat-here).Magnitude>.1 then boss:PivotTo(CFrame.lookAt(here,flat))end
end
local function playerInArena(plr)
 local ch,h,r=alivePlayer(plr)
 return ch and (r.Position-Vector3.new(0,r.Position.Y,0)).Magnitude<ARENA,ch,h,r
end
local function damageChar(ch,amount)
 if not ch then return false end
 local shield=playerShield[ch]
 if shield and shield.untilTime>now() and shield.layers>0 then
  shield.layers-=1
  local r=ch:FindFirstChild("HumanoidRootPart")
  if r then barrierBreak(r.Position+Vector3.new(0,3,0),root.Position,C.ice,shield.layers+1)end
  return false
 end
 local h=ch:FindFirstChildOfClass("Humanoid")
 if h then h:TakeDamage(amount);return true end
 return false
end
local function damageBoss(amount,impactPos,attackerPos)
 if bossShield.untilTime>now() and bossShield.layers>0 then
  local old=bossShield.layers
  bossShield.layers-=1
  barrierBreak(impactPos,attackerPos,C.ice,old)
  if bossShield.layers>0 then
   task.delay(.16,function()
    if bossShield.untilTime>now() then
     local face=attackerPos
     barrierVisual(root.Position+Vector3.new(0,3.1,0),face,C.ice,.42,math.min(2,bossShield.layers))
    end
   end)
  end
  return false
 end
 hum:TakeDamage(amount);impact(impactPos,C.white);return true
end

local function resetPose(time)
 poseBusy=false
 for _,m in pairs(motors)do tween(m,time or .2,{Transform=CFrame.new()},Enum.EasingStyle.Sine)end
end
local function castPose(kind)
 poseBusy=true
 if kind=="shield" then
  if motors.LeftShoulder then tween(motors.LeftShoulder,.16,{Transform=CFrame.Angles(math.rad(-122),0,math.rad(-25))})end
  if motors.LeftElbow then tween(motors.LeftElbow,.16,{Transform=CFrame.Angles(math.rad(-46),0,0)})end
  if motors.Waist then tween(motors.Waist,.16,{Transform=CFrame.Angles(0,math.rad(22),0)})end
 elseif kind=="beam" then
  if motors.RightShoulder then tween(motors.RightShoulder,.2,{Transform=CFrame.Angles(math.rad(-112),math.rad(-8),math.rad(20))})end
  if motors.RightElbow then tween(motors.RightElbow,.2,{Transform=CFrame.Angles(math.rad(-33),0,0)})end
  if motors.LeftShoulder then tween(motors.LeftShoulder,.2,{Transform=CFrame.Angles(math.rad(-60),math.rad(14),math.rad(-38))})end
  if motors.Waist then tween(motors.Waist,.2,{Transform=CFrame.Angles(0,math.rad(-17),0)})end
 elseif kind=="storm" then
  if motors.LeftShoulder then tween(motors.LeftShoulder,.24,{Transform=CFrame.Angles(math.rad(-145),0,math.rad(-32))})end
  if motors.RightShoulder then tween(motors.RightShoulder,.24,{Transform=CFrame.Angles(math.rad(-145),0,math.rad(32))})end
  if motors.Neck then tween(motors.Neck,.24,{Transform=CFrame.Angles(math.rad(-8),0,0)})end
 end
end
local function finishPose(delay)
 task.delay(delay or .35,function()resetPose(.28)end)
end

local function bossBarrier(attackerPos)
 if not ready(bossCD,"barrier",2.8) then return false end
 castPose("shield");bossShield.untilTime=now()+1.85;bossShield.layers=3
 barrierVisual(root.Position+Vector3.new(0,3.2,0),attackerPos,C.ice,1.85,3)
 finishPose(.5);return true
end
local function bossBeam(plr,counter)
 if not ready(bossCD,counter and "counter" or "beam",counter and 2.6 or 1.8)then return end
 local ch,h,r=alivePlayer(plr);if not ch then return end
 faceBoss(r.Position);castPose("beam")
 local origin=(boss:FindFirstChild("StaffTip",true) and boss:FindFirstChild("StaffTip",true).Position) or (boss:FindFirstChild("NPCStaffTip",true) and boss:FindFirstChild("NPCStaffTip",true).Position) or root.Position+Vector3.new(0,4,0)
 local predicted=r.Position+r.AssemblyLinearVelocity*.18+Vector3.new(0,1.2,0)
 smartMagicCircle(CFrame.lookAt(origin,predicted),counter and 4.8 or 5.8,counter and C.violet or C.ice,.75)
 task.wait(counter and .18 or .34)
 beam(origin,predicted,.38)
 local dir=(predicted-origin).Unit
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={boss}
 local ray=workspace:Raycast(origin,dir*math.min(180,(predicted-origin).Magnitude+12),params)
 if ray and ray.Instance and ray.Instance:IsDescendantOf(ch) then damageChar(ch,counter and 20 or 27)end
 finishPose(.2)
end
local function bossStorm(plr)
 if not ready(bossCD,"storm",6.5)then return end
 local ch,h,r=alivePlayer(plr);if not ch then return end
 castPose("storm")
 local high=root.Position+Vector3.new(0,16,0)
 local circle=smartMagicCircle(CFrame.new(high)*CFrame.Angles(math.rad(90),0,0),9,C.storm,1.4)
 task.wait(.48)
 for i=1,5 do
  local aim=r.Position+r.AssemblyLinearVelocity*.08+Vector3.new(math.random(-5,5),1,math.random(-5,5))
  lightning(high+Vector3.new(math.random(-8,8),math.random(-2,5),math.random(-8,8)),aim)
  if (r.Position-aim).Magnitude<6 then damageChar(ch,10)end
  task.wait(.13)
 end
 finishPose(.25)
end
local function bossSingularity(plr)
 if not ready(bossCD,"singularity",8.2)then return end
 local ch,h,r=alivePlayer(plr);if not ch then return end
 castPose("shield")
 local p=r.Position+r.AssemblyLinearVelocity*.25+Vector3.new(0,2.5,0)
 singularity(p)
 task.wait(1.72)
 if alivePlayer(plr) then
  local dist=(r.Position-p).Magnitude
  if dist<13 then damageChar(ch,26)end
  local pull=(p-r.Position)
  if pull.Magnitude>1 and dist<24 then r.AssemblyLinearVelocity+=pull.Unit*28 end
 end
 finishPose(.25)
end
local function bossOrbit(plr)
 if not ready(bossCD,"orbit",5.2)then return end
 local ch,h,r=alivePlayer(plr);if not ch then return end
 castPose("beam")
 local f=folder("OrbitalSpell",3)
 local center=root.Position+Vector3.new(0,5,0)
 local os={}
 for i=1,8 do
  local a=i/8*math.pi*2
  os[i]=orb(f,center+Vector3.new(math.cos(a)*7,math.sin(a*.7)*2.2,math.sin(a)*7),.55,i%2==0 and C.ice or C.violet,3,.02)
 end
 for i=1,8 do seg(f,os[i].Position,os[i%8+1].Position,.07,C.ice,1.5,.2)end
 task.wait(.5)
 for i,o in ipairs(os)do
  if not alivePlayer(plr)then break end
  local aim=r.Position+r.AssemblyLinearVelocity*.1
  beam(o.Position,aim,.25)
  if (r.Position-aim).Magnitude<5.5 then damageChar(ch,7)end
  task.wait(.11)
 end
 finishPose(.18)
end
local function bossHeal()
 if hum.Health>hum.MaxHealth*.72 or not ready(bossCD,"heal",10)then return end
 castPose("storm")
 smartMagicCircle(CFrame.new(root.Position+Vector3.new(0,.15,0))*CFrame.Angles(math.rad(90),0,0),7,C.gold,1.3)
 dust(root.Position+Vector3.new(0,3,0),C.gold,45,4,1.2)
 hum.Health=math.min(hum.MaxHealth,hum.Health+145)
 finishPose(.45)
end
local function bossDodge(plr,fly)
 if not ready(bossCD,fly and "fly" or "dodge",fly and 5.5 or 3.5)then return end
 local ch,h,r=alivePlayer(plr);if not ch then return end
 local dir=(root.Position-r.Position)
 if dir.Magnitude<1 then dir=Vector3.new(1,0,0)end
 local side=Vector3.new(-dir.Z,0,dir.X).Unit*(math.random(0,1)==0 and -1 or 1)
 local targetPos=root.Position+side*math.random(10,17)+Vector3.new(0,fly and 12 or 0,0)
 local ground=workspace:Raycast(targetPos+Vector3.new(0,40,0),Vector3.new(0,-80,0))
 if ground and not fly then targetPos=Vector3.new(targetPos.X,ground.Position.Y+4.1,targetPos.Z)end
 dust(root.Position+Vector3.new(0,3,0),C.ice,22,5,.7)
 boss:PivotTo(CFrame.lookAt(targetPos,Vector3.new(r.Position.X,targetPos.Y,r.Position.Z)))
 dust(targetPos+Vector3.new(0,3,0),C.ice,22,5,.7)
end

cast.OnServerEvent:Connect(function(plr,ability,data)
 local ok,ch,h,r=playerInArena(plr)
 if not ok then return end
 if type(ability)~="string" then return end
 local key=plr.UserId..":"..ability
 local cd={Attack=.66,Barrier=2.8,Storm=5.5,Singularity=7.5,Heal=6,Dodge=1.8,Fly=5}[ability]
 if not cd or not ready(playerCD,key,cd)then return end

 if ability=="Attack" then
  -- Boss arena lock-on: button/touch input must never depend on mouse.Hit.
  local origin=(ch:FindFirstChild("RightHand") and ch.RightHand.Position or r.Position)+Vector3.new(0,.8,0)
  local endpoint=root.Position+Vector3.new(0,2.7,0)
  active=true;target=plr
  smartMagicCircle(CFrame.lookAt(origin,endpoint),4.2,C.ice,.65)
  task.wait(.12)

  local react=math.random()
  if react<.34 then
   bossBarrier(origin)
   task.wait(.07)
   beam(origin,endpoint,.32)
   damageBoss(58,endpoint,origin)
  elseif react<.48 then
   -- Real dodge: preserve the original target point so the beam misses after the boss moves.
   local missedPoint=endpoint
   bossDodge(plr,false)
   beam(origin,missedPoint,.32)
   dust(missedPoint,C.ice,12,3,.45)
   if math.random()<.55 then task.spawn(bossBeam,plr,true)end
  else
   beam(origin,endpoint,.32)
   damageBoss(58,endpoint,origin)
  end

  if react>.82 then task.spawn(bossBeam,plr,true)end
  feedback:FireClient(plr,"accepted","Attack","Zoltraak")
 elseif ability=="Barrier" then
  local face=root.Position
  playerShield[ch]={untilTime=now()+1.8,layers=3}
  barrierVisual(r.Position+Vector3.new(0,3,0),face,C.ice,1.8,3)
  feedback:FireClient(plr,"accepted","Barrier","Barreira")
 elseif ability=="Storm" then
  -- Judradjim locks around the boss and walks its lightning pattern across the target.
  active=true;target=plr
  local high=r.Position+Vector3.new(0,14,0)
  smartMagicCircle(CFrame.new(high)*CFrame.Angles(math.rad(90),0,0),7.5,C.storm,1.1)
  task.wait(.25)
  for i=1,5 do
   local bossPoint=root.Position+Vector3.new(math.random(-3,3),math.random(1,5),math.random(-3,3))
   lightning(high+Vector3.new(math.random(-5,5),0,math.random(-5,5)),bossPoint)
   damageBoss(13,bossPoint,r.Position)
   task.wait(.1)
  end
  feedback:FireClient(plr,"accepted","Storm","Judradjim")
 elseif ability=="Singularity" then
  -- Spatial collapse appears on the boss, but a real dodge can escape before collapse.
  active=true;target=plr
  local pos=root.Position+Vector3.new(0,2.5,0)
  singularity(pos)
  task.wait(1.62)
  if boss.Parent and hum.Health>0 then
   local current=root.Position+Vector3.new(0,2.5,0)
   if (current-pos).Magnitude<=13 then
    damageBoss(46,current,r.Position)
   else
    dust(pos,C.violet,18,4,.55)
   end
  end
  feedback:FireClient(plr,"accepted","Singularity","Singularidade")
 elseif ability=="Heal" then
  smartMagicCircle(CFrame.new(r.Position+Vector3.new(0,.12,0))*CFrame.Angles(math.rad(90),0,0),5.2,C.gold,1.1)
  dust(r.Position+Vector3.new(0,2,0),C.gold,28,3,1)
  h.Health=math.min(h.MaxHealth,h.Health+28)
  feedback:FireClient(plr,"accepted","Heal","Vida")
 elseif ability=="Dodge" then
  dust(r.Position+Vector3.new(0,2,0),C.ice,16,4,.55)
  r.AssemblyLinearVelocity=r.CFrame.LookVector*52+Vector3.new(0,6,0)
  feedback:FireClient(plr,"accepted","Dodge","Esquiva")
 elseif ability=="Fly" then
  smartMagicCircle(CFrame.new(r.Position+Vector3.new(0,.1,0))*CFrame.Angles(math.rad(90),0,0),4.4,C.ice,.7)
  local att=Instance.new("Attachment");att.Name="FlightAttachment";att.Parent=r
  local lv=Instance.new("LinearVelocity");lv.Name="FlightVelocity";lv.Attachment0=att;lv.MaxForce=42000;lv.VectorVelocity=r.CFrame.LookVector*28+Vector3.new(0,16,0);lv.Parent=r
  task.delay(1.2,function()if lv.Parent then lv.VectorVelocity=r.CFrame.LookVector*34+Vector3.new(0,2,0)end end)
  Debris:AddItem(lv,2.3);Debris:AddItem(att,2.35)
  feedback:FireClient(plr,"accepted","Fly","Voo")
 end
end)

hum.Died:Connect(function()
 active=false
 smartMagicCircle(CFrame.new(root.Position+Vector3.new(0,.1,0))*CFrame.Angles(math.rad(90),0,0),12,C.gold,3)
 dust(root.Position+Vector3.new(0,4,0),C.ice,80,10,1.8)
end)

task.spawn(function()
 local t=0
 while boss.Parent and hum.Health>0 do
  local dt=RunService.Heartbeat:Wait();t+=dt
  if not poseBusy then
   if motors.Waist then motors.Waist.Transform=CFrame.Angles(math.sin(t*1.2)*.012,math.sin(t*.55)*.025,0)end
   if motors.Neck then motors.Neck.Transform=CFrame.Angles(math.sin(t*.8)*.015,math.sin(t*.48)*.04,0)end
   local floatY=math.sin(t*1.35)*.035
   if motors.Root then motors.Root.Transform=CFrame.new(0,floatY,0)end
  end
 end
end)

task.spawn(function()
 while boss.Parent and hum.Health>0 do
  if active then
   local best,bestD=nil,180
   for _,plr in ipairs(Players:GetPlayers())do
    local ok,ch,h,r=playerInArena(plr)
    if ok then
     local d=(r.Position-root.Position).Magnitude
     if d<bestD then best,bestD=plr,d end
    end
   end
   if best then
    target=best
    local ch,h,r=alivePlayer(best)
    if ch then
     faceBoss(r.Position)
     if hum.Health<hum.MaxHealth*.42 and math.random()<.18 then bossHeal()
     else
      local x=math.random()
      if x<.25 then bossBeam(best,false)
      elseif x<.45 then bossOrbit(best)
      elseif x<.62 then bossStorm(best)
      elseif x<.76 then bossSingularity(best)
      elseif x<.87 then bossBarrier(r.Position)
      elseif x<.95 then bossDodge(best,false)
      else bossDodge(best,true) end
     end
    end
   end
  end
  task.wait(math.random(85,145)/100)
 end
end)
