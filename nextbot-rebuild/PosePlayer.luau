-- Playback adapter. Clip keyframes remain unchanged; source joint bases are retained.
local Tween=game:GetService('TweenService')
local M={};local cache=setmetatable({},{__mode='k'})
local styles={Linear=Enum.EasingStyle.Linear,Cubic=Enum.EasingStyle.Cubic,CubicV2=Enum.EasingStyle.Cubic,Elastic=Enum.EasingStyle.Elastic,Bounce=Enum.EasingStyle.Bounce}
function M.Decode(sequence)
 if cache[sequence]then return cache[sequence]end
 local data={tracks={},duration=0,loop=sequence.Loop};local frames=sequence:GetKeyframes();table.sort(frames,function(a,b)return a.Time<b.Time end)
 for _,frame in ipairs(frames)do
  data.duration=math.max(data.duration,frame.Time)
  -- Animation-editor exports include zero-weight helper poses with the same name
  -- as the actual nested joint. Keep the active pose once per timestamp.
  local active={}
  for _,pose in ipairs(frame:GetDescendants())do if pose:IsA('Pose')then
   local previous=active[pose.Name]
   if not previous or pose.Weight>previous.Weight then active[pose.Name]=pose end
  end end
  for name,pose in pairs(active)do
   local keys=data.tracks[name]or {};data.tracks[name]=keys
   local key={t=frame.Time,c=pose.CFrame,w=pose.Weight,style=pose.EasingStyle.Name,direction=pose.EasingDirection.Name}
   local previous=keys[#keys]
   if previous and previous.t==key.t then if key.w>previous.w then keys[#keys]=key end else table.insert(keys,key)end
  end
 end
 cache[sequence]=data;return data
end
function M.Motors(char)
 local motors={};for _,v in ipairs(char:GetDescendants())do if v:IsA('Motor6D')and v.Part0 and v.Part1 then motors[v.Part1.Name]=v end end;return motors
end
function M.Bindings(rig)
 local bindings={};for name,motor in pairs(M.Motors(rig))do bindings[name]={parent=motor.Part0.Name,c0=motor.C0,c1=motor.C1}end;return bindings
end
function M.Sample(keys,t)
 if t<=keys[1].t then return keys[1].c,keys[1].w end
 if t>=keys[#keys].t then return keys[#keys].c,keys[#keys].w end
 local low,high=1,#keys
 while high-low>1 do local mid=math.floor((low+high)/2);if keys[mid].t<=t then low=mid else high=mid end end
 local a,b=keys[low],keys[high];local alpha=(t-a.t)/math.max(.0001,b.t-a.t)
 if a.style=='Constant'then alpha=0 else alpha=Tween:GetValue(alpha,styles[a.style]or Enum.EasingStyle.Linear,Enum.EasingDirection[a.direction]or Enum.EasingDirection.InOut)end
 return a.c:Lerp(b.c,alpha),math.clamp(a.w+(b.w-a.w)*alpha,0,1)
end
function M.WorldPose(data,t,bindings)
 t=data.duration>0 and (data.loop and t%data.duration or math.min(t,data.duration))or 0
 local worlds={HumanoidRootPart=CFrame.identity};local visiting={}
 local function world(name)
  if worlds[name]then return worlds[name]end
  local joint=bindings[name];if not joint or visiting[name]then return CFrame.identity end
  visiting[name]=true
  local transform=CFrame.identity;local keys=data.tracks[name]
  if keys then local cf,weight=M.Sample(keys,t);transform=CFrame.identity:Lerp(cf,weight)end
  worlds[name]=world(joint.parent)*joint.c0*transform*joint.c1:Inverse();visiting[name]=nil
  return worlds[name]
 end
 for name in pairs(bindings)do world(name)end
 return worlds
end
function M.Apply(data,motors,t,blend,bindings)
 t=data.duration>0 and (data.loop and t%data.duration or math.min(t,data.duration))or 0
 local worlds=bindings and M.WorldPose(data,t,bindings)
 for name,motor in pairs(motors)do if motor.Parent and motor.Part0 and motor.Part1 then
  local target
  if worlds and worlds[name]and worlds[motor.Part0.Name]then
   -- Preserve the authored world pose even after avatar appearance rebuilds R6 joints.
   target=motor.C0:Inverse()*worlds[motor.Part0.Name]:Inverse()*worlds[name]*motor.C1
  elseif not bindings then
   local keys=data.tracks[name]
   if keys then local cf,weight=M.Sample(keys,t);target=CFrame.identity:Lerp(cf,weight)end
  end
  if target then motor.Transform=motor.Transform:Lerp(target,blend or 1)end
 end end
end
return M
