-- Evaluate the supplied keyframes locally. No animation upload/ownership substitution.
local RunService=game:GetService("RunService")
local current=nil local data=nil local elapsed=0
local function prepare(model)
 local d={joints={},bones={},clips={},t=0,last=""}
 for _,j in ipairs(model:GetDescendants()) do
  if j:IsA("Motor6D") and j.Part1 then d.joints[j.Part1.Name]={joint=j,base=j.C0}
  elseif j:IsA("Bone") then d.bones[j.Name]=j end
 end
 local folder=model:FindFirstChild("MotionClips")
 if folder then
  for _,seq in ipairs(folder:GetChildren()) do
   if seq:IsA("KeyframeSequence") then
    local frames=seq:GetKeyframes() table.sort(frames,function(a,b) return a.Time<b.Time end)
    local clip={frames={},length=frames[#frames] and frames[#frames].Time or 0}
    for _,frame in ipairs(frames) do
     local poses={}
     for _,p in ipairs(frame:GetDescendants()) do if p:IsA("Pose") and p.Weight>0 then poses[p.Name]=p.CFrame end end
     table.insert(clip.frames,{time=frame.Time,poses=poses})
    end
    d.clips[seq.Name]=clip
   end
  end
 end
 return d
end
RunService.RenderStepped:Connect(function(dt)
 elapsed+=dt if elapsed<1/30 then return end local step=elapsed elapsed=0
 if not current or not current.Parent then
  current=nil data=nil
  for _,m in ipairs(workspace:GetChildren()) do if m:IsA("Model") and m:GetAttribute("ActivePursuer") then current=m data=prepare(m) break end end
 end
 if not current or not data then return end
 local root=current.PrimaryPart if not root then return end
 local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
 local state=speed>17 and "Run" or speed>1 and "Walk" or "Idle"
 if state~=data.last then data.t=0 data.last=state end data.t+=step
 local clip=data.clips[state] or data.clips.Walk
 if clip and clip.length>0 then
  local t=data.t%clip.length local a,b=clip.frames[1],clip.frames[#clip.frames]
  for i=1,#clip.frames-1 do if clip.frames[i+1].time>=t then a=clip.frames[i] b=clip.frames[i+1] break end end
  local alpha=b.time>a.time and math.clamp((t-a.time)/(b.time-a.time),0,1) or 0
  for name,cf in pairs(a.poses) do
   local pose=cf:Lerp(b.poses[name] or cf,alpha)
   local bone=data.bones[name] local motor=data.joints[name]
   if bone then bone.Transform=pose elseif motor then motor.joint.C0=motor.base*pose end
  end
 else
  -- Native locomotion for rigs without a published walk clip.
  for name,j in pairs(data.joints) do
   local n=name:lower() local angle=math.sin(data.t*(speed>1 and 7 or 1.5))*(speed>1 and .45 or .025)
   if n:find("arm") or n:find("leg") then j.joint.C0=j.base*CFrame.Angles(angle*(n:find("left") and 1 or -1),0,0) end
  end
 end
 if current:GetAttribute("Ability")=="Reveal" then
  for name,j in pairs(data.joints) do if name=="RightUpperArm" or name=="Right Arm" then j.joint.C0=j.base*CFrame.Angles(math.rad(-135),0,math.rad(25)) end end
 end
end)
