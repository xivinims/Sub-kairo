local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer
local npc=workspace:WaitForChild('Shopkeeper',60)
if not npc then warn('Shopkeeper missing');return end
local clips={}
for _,sequence in ipairs(RS.FalloutNpcClips:GetChildren()) do
 local frames={}
 for _,key in ipairs(sequence:GetChildren()) do
  if key:IsA('Keyframe') then
   local poses={}
   for _,pose in ipairs(key:GetDescendants()) do if pose:IsA('Pose') then poses[pose.Name]={cf=pose.CFrame,style=pose.EasingStyle.Name,direction=pose.EasingDirection.Name} end end
   table.insert(frames,{time=key.Time,poses=poses})
  end
 end
 table.sort(frames,function(a,b)return a.time<b.time end)
 if #frames>1 then clips[sequence.Name]={frames=frames,length=frames[#frames].time} end
end
local joints={}
for _,joint in ipairs(npc:GetDescendants()) do if joint:IsA('Motor6D') and joint.Part1 then joints[joint.Part1.Name]=joint end end
local active=false
local current='Idle'
local start=os.clock()
local from={}
local function switch(name)
 if not clips[name] then return end
 for limb,j in pairs(joints) do from[limb]=j.Transform end
 current=name;start=os.clock()
end
Run.PreSimulation:Connect(function()
 if not npc.Parent or not npc.PrimaryPart then return end
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local near=root and (root.Position-npc.PrimaryPart.Position).Magnitude<14 or false
 if near~=active then active=near;switch(near and 'IdleToActive' or 'ActiveToIdle') end
 local clip=clips[current];if not clip then return end
 local elapsed=os.clock()-start
 if elapsed>clip.length and (current=='IdleToActive' or current=='ActiveToIdle') then switch(active and 'ActiveIdle' or 'Idle');clip=clips[current];elapsed=0 end
 if not clip then return end
 local t=elapsed%math.max(clip.length,.01)
 local a,b=clip.frames[1],clip.frames[#clip.frames]
 for i=2,#clip.frames do if clip.frames[i].time>=t then a=clip.frames[i-1];b=clip.frames[i];break end end
 local alpha=math.clamp((t-a.time)/math.max(.001,b.time-a.time),0,1)
 for limb,joint in pairs(joints) do
  local p,q=a.poses[limb],b.poses[limb]
  if p and q then
   local easing=p.style=='Constant' and 0 or alpha
   if p.style~='Constant' then pcall(function()easing=Tween:GetValue(alpha,Enum.EasingStyle[p.style],Enum.EasingDirection[p.direction]) end) end
   local target=p.cf:Lerp(q.cf,easing)
   if elapsed<.2 and from[limb] then target=from[limb]:Lerp(target,elapsed/.2) end
   joint.Transform=target
  end
 end
end)
