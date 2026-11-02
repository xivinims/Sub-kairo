-- R6 motion runtime v16. The Animator writes Transform between PreAnimation
-- and PreSimulation; this script overrides it in PreSimulation, never C0.
-- ONE lightweight R6 pose controller shared by locomotion + combat.
-- Replaces stiff R15-only run and unavailable combat IDs with fully local R6
-- keyed joint poses. Nothing here causes damage or modifies other players.
-- Existing Naruto/Chakra physics, Boogie, and auto-climb remain independent.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local rig=script.Parent
local hum=rig:WaitForChild("Humanoid")
if hum.RigType~=Enum.HumanoidRigType.R6 then return end
local root=rig:WaitForChild("HumanoidRootPart")
local torso=rig:WaitForChild("Torso")
while rig.Parent and not rig:IsDescendantOf(workspace) do task.wait() end
if not rig.Parent then return end
local jointNames={
  RS="Right Shoulder",LS="Left Shoulder",RH="Right Hip",
  LH="Left Hip",Root="RootJoint",Neck="Neck",
}
local joints,originals={},{}
for short,name in pairs(jointNames) do
 local joint=rig:FindFirstChild(name,true)
 if joint and joint:IsA("Motor6D") then
  joints[short]=joint
  originals[short]=joint.C0
 end
end
assert(joints.RS and joints.LS and joints.RH and joints.LH
 and joints.Root and joints.Neck,"R6 avatar is missing essential Motor6D joints")
-- Values are angle degrees. The timeline interpolates key poses for each
-- attack, so this is an actual moving animation, not a static swing/toggle.
local function v(x,y,z) return {x or 0,y or 0,z or 0} end
local function pose(RS,LS,RH,LH,Root,Neck)
 return {RS=RS,LS=LS,RH=RH,LH=LH,Root=Root,Neck=Neck}
end
local Z=v()
local neutral=pose(Z,Z,Z,Z,Z,Z)
local actions={
 M1_1={.40,{
  {0,neutral},
  {.17,pose(v(25,-12,35),v(-38,0,-3),v(-11),v(9),v(0,-22,8),v(0,13))},
  {.49,pose(v(-92,8,-13),v(30),v(15),v(-13),v(-7,30,-9),v(4,-11))},
  {.78,pose(v(-60,6,-5),v(20),v(5),v(-5),v(-3,13),v(0,-5))},
  {1,neutral}}},
 M1_2={.42,{
  {0,neutral},
  {.16,pose(v(32),v(28,15,-34),v(10),v(-11),v(0,22,-6),v(0,-8))},
  {.52,pose(v(22),v(-100,-8,12),v(-10),v(17),v(-6,-28,7),v(5,11))},
  {.8,pose(v(12),v(-47,0,9),Z,Z,v(0,-8),Z)},
  {1,neutral}}},
 M1_3={.48,{
  {0,neutral},
  {.23,pose(v(12,-40,58),v(-42),v(13),v(-10),v(0,-28,12),v(0,17))},
  {.52,pose(v(-65,40,-48),v(18),v(-14),v(16),v(-5,38,-12),v(2,-15))},
  {.79,pose(v(-45,18,-26),v(8),Z,Z,v(0,15),Z)},
  {1,neutral}}},
 M1_4={.53,{
  {0,neutral},
  {.18,pose(v(28,0,25),v(35,0,-25),v(-10),v(15),v(7,0),v(-6))},
  {.54,pose(v(-106,0,-18),v(-106,0,18),v(16),v(-16),v(-19,0),v(12))},
  {.82,pose(v(-59),v(-59),Z,Z,v(-7),Z)},
  {1,neutral}}},
 Block={1,{{0,pose(v(-63,0,36),v(-63,0,-36),v(9),v(-8),v(-7,0),v(7))},
            {1,pose(v(-63,0,36),v(-63,0,-36),v(9),v(-8),v(-7,0),v(7))}}},
 DodgeFront={.42,{{0,neutral},
  {.38,pose(v(32,0,22),v(35,0,-22),v(47),v(45),v(-28,0),v(17))},
  {.68,pose(v(-28,0,15),v(-24,0,-15),v(-11),v(14),v(17),v(-8))},
  {1,neutral}}},
 DodgeBack={.42,{{0,neutral},
  {.33,pose(v(-18),v(-18),v(32),v(27),v(31),v(-14))},
  {.70,pose(v(30),v(30),v(-12),v(12),v(-17),v(6))},
  {1,neutral}}},
 Kick_1={.64,{{0,neutral},
  {.22,pose(v(-22,0,19),v(19,0,-21),v(47,0,-10),v(-30),v(-11,16),v(6,-6))},
  {.48,pose(v(-42),v(17),v(-95,0,8),v(28),v(-17,-14),v(12,4))},
  {.73,pose(v(-18),v(12),v(-54),v(16),v(-9),v(4))},
  {1,neutral}}},
 Kick_2={.62,{{0,neutral},
  {.24,pose(v(25),v(-30),v(-25),v(53),v(-10,-12),v(4,8))},
  {.48,pose(v(28),v(-48),v(25),v(-103,0,-7),v(-17,18),v(12,-8))},
  {.78,pose(v(14),v(-27),Z,v(-50),v(-7,4),Z)},
  {1,neutral}}},
 Uppercut={.61,{{0,neutral},
  {.24,pose(v(56,0,28),v(12),v(32),v(36),v(22,-19),v(-15))},
  {.53,pose(v(-155,0,10),v(-19),v(-20),v(12),v(-16,19),v(13))},
  {.77,pose(v(-91),v(-11),Z,Z,v(-3),v(4))},
  {1,neutral}}},
 Downslam={.70,{{0,neutral},
  {.2,pose(v(-146),v(-139),v(-34),v(27),v(-16),v(9))},
  {.56,pose(v(42,0,22),v(58,0,-25),v(36),v(46),v(35),v(-20))},
  {.82,pose(v(5),v(13),v(14),v(12),v(14),Z)},
  {1,neutral}}},
 HeavyPunch={.79,{{0,neutral},
  {.28,pose(v(45,0,67),v(-23),v(-29),v(24),v(0,-38,17),v(0,18))},
  {.55,pose(v(-125,0,-17),v(30),v(15),v(-16),v(-16,39,-17),v(11,-18))},
  {.78,pose(v(-78,0,9),v(12),Z,Z,v(-8,12),v(4))},
  {1,neutral}}},
 Barrage={.86,{{0,neutral},
  {.12,pose(v(-99),v(35),v(12),v(-13),v(0,14),Z)},
  {.26,pose(v(33),v(-97),v(-12),v(13),v(0,-13),Z)},
  {.42,pose(v(-97),v(31),v(13),v(-10),v(0,18),Z)},
  {.58,pose(v(36),v(-96),v(-12),v(15),v(0,-15),Z)},
  {.74,pose(v(-96),v(31),v(13),v(-12),v(0,15),Z)},
  {1,neutral}}},
}
-- The original R6 RUN source model contains these three untouched assets.
-- Read actual published-style Keyframe/Pose CFrames, not model IDs or invented
-- animation curves. The original KeyframeSequences themselves never change.
local runFolder=rig:WaitForChild("R6RunSource",10)
local originalRun=runFolder and runFolder:FindFirstChild("Run3 [by Newb1e27]")
local rawChannels={}
local rawLength=0
if originalRun and originalRun:IsA("KeyframeSequence") then
 local ok,frames=pcall(function() return originalRun:GetKeyframes() end)
 if ok and #frames>=8 then
  table.sort(frames,function(a,b) return a.Time<b.Time end)
  for _,frame in ipairs(frames) do
   rawLength=math.max(rawLength,frame.Time)
   for _,poseObj in ipairs(frame:GetDescendants()) do
    if poseObj:IsA("Pose") then
     local partName=poseObj.Name
     local points=rawChannels[partName] or {}
     table.insert(points,{t=frame.Time,cf=poseObj.CFrame,weight=poseObj.Weight,
       constant=poseObj.EasingStyle==Enum.PoseEasingStyle.Constant})
     rawChannels[partName]=points
    end
   end
  end
 end
end
local function originalR6RunCF(partName,t)
 local points=rawChannels[partName]
 if not points or #points==0 or rawLength<=0 then return nil end
 local elapsed=t%rawLength
 local a,b=points[1],points[#points]
 for index=2,#points do
  local nextPose=points[index]
  if elapsed<=nextPose.t then a=points[index-1];b=nextPose;break end
 end
 local interval=b.t-a.t
 local alpha=interval>0 and math.clamp((elapsed-a.t)/interval,0,1) or 0
 if a.constant then alpha=0 end
 local transform=a.cf:Lerp(b.cf,alpha)
 local weight=a.weight+(b.weight-a.weight)*alpha
 return CFrame.identity:Lerp(transform,math.clamp(weight,0,1))
end
local runStart=os.clock()
local lastMove="none"
local phase=0
local currentAction=nil
local actionStarted=0
local actionExpires=0
local smooth=pose(v(),v(),v(),v(),v(),v())
local used=false
local lastJump=-1000
local lastLanding=-1000
local airborne=false
hum.StateChanged:Connect(function(_,newState)
 if newState==Enum.HumanoidStateType.Jumping then
  lastJump=os.clock();airborne=true
 elseif newState==Enum.HumanoidStateType.Freefall then
  airborne=true
 elseif newState==Enum.HumanoidStateType.Landed then
  lastLanding=os.clock();airborne=false
 elseif newState==Enum.HumanoidStateType.Running then
  airborne=false
 end
end)
local lastReported=""
local lastReport=0
local function report(mode)
 local now=os.clock()
 if mode~=lastReported or now-lastReport>2.5 then
  lastReported=mode;lastReport=now
  rig:SetAttribute("R6AnimationState",mode)
 end
end
local function interpolated(left,right,a)
 local result={}
 for name in pairs(jointNames) do
  local u=left[name] or Z
  local w=right[name] or Z
  result[name]=v(u[1]+(w[1]-u[1])*a,u[2]+(w[2]-u[2])*a,
    u[3]+(w[3]-u[3])*a)
 end
 return result
end
local function actionFrame(action,time)
 local data=actions[action]
 if not data then return neutral end
 local t=math.clamp(time/data[1],0,1)
 local keys=data[2]
 for k=2,#keys do
  local right=keys[k]
  if t<=right[1] then
   local left=keys[k-1]
   local a=(t-left[1])/math.max(.001,right[1]-left[1])
   a=a*a*(3-2*a)
   return interpolated(left[2],right[2],a)
  end
 end
 return neutral
end
local function motionFrame(kind,dt)
 if kind~=lastMove then phase=0;lastMove=kind end
 local speed=math.max(0,hum.WalkSpeed*hum.MoveDirection.Magnitude)
 local frequency=kind=="run" and (9.8+speed*.18) or
  kind=="walk" and (6.3+speed*.11) or 1.6
 phase+=dt*frequency
 local w=math.sin(phase)
 local bounce=math.abs(w)
 local sway=math.sin(phase*.5)
 if kind=="run" then
  return pose(v(-33+57*w,0,14),v(-33-57*w,0,-14),
   v(66*w-8,0,5),v(-66*w-8,0,-5),
   v(-16+6*bounce,6*sway,4*w),v(9-2*bounce,-6*sway))
 elseif kind=="walk" then
  return pose(v(25*w-7,0,7),v(-25*w-7,0,-7),
   v(-31*w,0,3),v(31*w,0,-3),
   v(-4+1.5*bounce,3*sway,1.8*w),v(1,-3*sway))
 elseif kind=="jump" then
  return pose(v(-48,0,12),v(-48,0,-12),v(23),v(29),
   v(-12),v(4))
 elseif kind=="fall" then
  local flutter=math.sin(phase*.6)*7
  return pose(v(-18,0,26+flutter),v(-18,0,-26-flutter),
   v(-15+flutter*.2),v(11-flutter*.2),v(8),v(-5))
 elseif kind=="land" then
  return pose(v(26,0,7),v(26,0,-7),v(35),v(35),v(22),v(-10))
 else
  local breath=math.sin(phase)*2.3
  return pose(v(-4+breath),v(-4+breath),Z,Z,
   v(-1+breath*.16),v(-breath*.4))
 end
end
local function activeKind()
 if rig:GetAttribute("Climbing")==true or rig:GetAttribute("ChakraActive")==true then return nil end
 if hum.Sit or hum.Health<=0 then return nil end
 local state=hum:GetState()
 if state==Enum.HumanoidStateType.Climbing or
  state==Enum.HumanoidStateType.Swimming or
  state==Enum.HumanoidStateType.Seated then return nil end

 local now=os.clock()
 local aerial=hum.FloorMaterial==Enum.Material.Air
    or state==Enum.HumanoidStateType.Freefall
    or state==Enum.HumanoidStateType.FallingDown
    or state==Enum.HumanoidStateType.Jumping
 if (state==Enum.HumanoidStateType.Jumping or now-lastJump<0.23) and aerial then return "jump" end
 if aerial then return "fall" end
 if now-lastLanding<0.12 and not airborne then return "land" end
 local horizontal=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
 local moving=hum.MoveDirection.Magnitude>.12 or
  (horizontal>2.2 and hum.MoveDirection.Magnitude>.02)
 if moving then return hum.WalkSpeed>=19 and "run" or "walk" end
 return "idle"
end
local function release()
 -- Release only once when other native systems take priority.
 for _,joint in pairs(joints) do
  if joint.Parent then joint.Transform=CFrame.identity end
 end
 used=false
end
local loop
loop=RunService.PreSimulation:Connect(function(dt)
 if not rig.Parent or hum.Health<=0 then
  if used then release() end
  if loop then loop:Disconnect()end
  return
 end
 local now=os.clock()
 local requested=rig:GetAttribute("R6CombatAction")
 local stamp=rig:GetAttribute("R6CombatStarted") or 0
 local guard=rig:GetAttribute("CombatBlocking")==true
 local allowed=player.Character==rig and player:GetAttribute("R6MenuActive")~=true
 local kind=allowed and activeKind() or nil
 if kind then report(kind) end
 if allowed and not (kind==nil and not guard) and guard then
  requested="Block"
  stamp=now
 end
 if requested and actions[requested] and allowed and kind then
  if guard and requested~="Block" then requested="Block"end
  if requested=="Block" or now-stamp<=actions[requested][1]+.08 then
   local poseValues=actionFrame(requested,requested=="Block" and .45 or now-stamp)
   for name,joint in pairs(joints) do
    local angle=poseValues[name] or Z
    local a=math.rad(angle[1])
    local b=math.rad(angle[2])
    local c=math.rad(angle[3])
    joint.Transform=CFrame.Angles(a,b,c)
   end
   used=true
   return
  end
 end
 if not kind then
  if used then release()end
  return
 end
 if kind=="run" and originalRun and rawLength>0 then
  if kind~=lastMove then
   lastMove=kind
   runStart=os.clock()
  end
  local nowT=(os.clock()-runStart)*math.clamp(hum.WalkSpeed/23,.65,1.4)
  -- R6 Motor6D.Part1 names match the original R6 poses. The original
  -- model's Run3 keyframes remain unchanged, only interpolated at playback.
  local applied=0
  for name,joint in pairs(joints) do
   local partName=joint.Part1 and joint.Part1.Name
   local originalPose=partName and originalR6RunCF(partName,nowT)
   if originalPose and joint.Parent then
    joint.Transform=originalPose
    applied+=1
   elseif joint.Parent then
    joint.Transform=CFrame.identity
   end
  end
  if applied>=4 then
   used=true
   return
  end
 end
 local motion=motionFrame(kind,math.min(dt,.06))
 local lag=math.clamp(dt*15,0,1)
 for name,joint in pairs(joints) do
  local target=motion[name] or Z
  local existing=smooth[name]
  for i=1,3 do existing[i]=existing[i]+(target[i]-existing[i])*lag end
  -- Transform is the frame's animated joint pose. PreSimulation is
  -- after Animator evaluation and before physics.
  if joint.Parent then
   joint.Transform=CFrame.Angles(math.rad(existing[1]),
     math.rad(existing[2]),math.rad(existing[3]))
  end
 end
 used=true
end)
script.Destroying:Once(function()
 if loop then loop:Disconnect();loop=nil end
 if used then release() end
end)
