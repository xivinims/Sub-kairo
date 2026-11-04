local Tween=game:GetService('TweenService')
local M={};local cache=setmetatable({},{__mode='k'})
local styles={Linear=Enum.EasingStyle.Linear,Cubic=Enum.EasingStyle.Cubic,CubicV2=Enum.EasingStyle.Cubic,Elastic=Enum.EasingStyle.Elastic,Bounce=Enum.EasingStyle.Bounce}
function M.Decode(sequence)
 if cache[sequence]then return cache[sequence]end
 local data={tracks={},duration=0,loop=sequence.Loop};local frames=sequence:GetKeyframes();table.sort(frames,function(a,b)return a.Time<b.Time end)
 for _,frame in ipairs(frames)do
  data.duration=math.max(data.duration,frame.Time)
  for _,pose in ipairs(frame:GetDescendants())do if pose:IsA('Pose')then
   local keys=data.tracks[pose.Name]or {};data.tracks[pose.Name]=keys
   table.insert(keys,{t=frame.Time,c=pose.CFrame,w=pose.Weight,style=pose.EasingStyle.Name,direction=pose.EasingDirection.Name})
  end end
 end
 cache[sequence]=data;return data
end
function M.Motors(char)
 local motors={};for _,v in ipairs(char:GetDescendants())do if v:IsA('Motor6D')and v.Part1 then motors[v.Part1.Name]=v end end;return motors
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
function M.Apply(data,motors,t,blend)
 t=data.duration>0 and (data.loop and t%data.duration or math.min(t,data.duration))or 0
 for name,keys in pairs(data.tracks)do
  local motor=motors[name];if motor and motor.Parent then
   local cf,weight=M.Sample(keys,t);motor.Transform=motor.Transform:Lerp(CFrame.identity:Lerp(cf,weight),blend or 1)
  end
 end
end
return M
