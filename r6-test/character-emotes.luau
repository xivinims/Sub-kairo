-- A character-owned reader for the uploaded keyframes; there is no preview GUI.
-- Poses, names, weights and timestamps in the imported sequences remain untouched.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TextChatService = game:GetService('TextChatService')
local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild('Humanoid')
local animator = humanoid:WaitForChild('Animator')
local animate = character:WaitForChild('Animate')
local sequences = character:WaitForChild('Animations'):WaitForChild('Emotes')
local playing, connection = false, nil
local saved = {}
local function stop()
 if connection then connection:Disconnect(); connection=nil end
 for motor, transform in pairs(saved) do if motor.Parent then motor.Transform=transform end end
 saved={}
 if playing and animate.Parent then animate.Enabled=true end
 playing=false
end
local function normalize(text) return text:lower():gsub('[^%w]','') end
local function play(sequence)
 stop()
 if humanoid.Health<=0 or humanoid.MoveDirection.Magnitude>.05 then return end
 playing=true;animate.Enabled=false
 for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
 local channels={};local length=0
 local frames=sequence:GetKeyframes();table.sort(frames,function(a,b)return a.Time<b.Time end)
 for _,frame in ipairs(frames) do
  length=math.max(length,frame.Time)
  for _,pose in ipairs(frame:GetDescendants()) do if pose:IsA('Pose') then
   channels[pose.Name]=channels[pose.Name] or {}
   table.insert(channels[pose.Name],{time=frame.Time,cf=pose.CFrame,weight=pose.Weight,style=pose.EasingStyle})
  end end
 end
 local motors={}
 for _,motor in ipairs(character:GetDescendants()) do
  if motor:IsA('Motor6D') and motor.Part1 and channels[motor.Part1.Name] then
   motors[motor]=channels[motor.Part1.Name];saved[motor]=motor.Transform
  end
 end
 local started=os.clock()
 connection=RunService.PreSimulation:Connect(function()
  if not character.Parent or humanoid.Health<=0 or humanoid.MoveDirection.Magnitude>.05 then stop();return end
  local elapsed=os.clock()-started
  if length>0 and not sequence.Loop and elapsed>length then stop();return end
  local t=length>0 and (sequence.Loop and elapsed%length or math.min(elapsed,length)) or 0
  for motor,samples in pairs(motors) do
   local left,right=samples[1],samples[1]
   for _,sample in ipairs(samples) do
    if sample.time<=t then left=sample else right=sample;break end
    right=sample
   end
   local alpha=right.time>left.time and math.clamp((t-left.time)/(right.time-left.time),0,1) or 0
   if left.style==Enum.PoseEasingStyle.Constant then alpha=0 end
   motor.Transform=CFrame.identity:Lerp(left.cf:Lerp(right.cf,alpha),left.weight+(right.weight-left.weight)*alpha)
  end
 end)
end
-- /r6 CatDance, /r6 Idle Sit, etc. Emotes are optional actions, never movement replacements.
local previous=TextChatService:FindFirstChild('OriginalR6EmotesCommand')
if previous then previous:Destroy() end
local command=Instance.new('TextChatCommand');command.Name='OriginalR6EmotesCommand';command.PrimaryAlias='/r6';command.Parent=TextChatService
command.Triggered:Connect(function(source,text)
 if not source or source.UserId~=player.UserId or player.Character~=character then return end
 local name=normalize(text:gsub('^%S+%s*',''))
 if name=='stop' or name=='parar' then stop();return end
 for _,sequence in ipairs(sequences:GetChildren()) do if normalize(sequence.Name)==name then play(sequence);return end end
end)
humanoid.Running:Connect(function(speed) if speed>.5 then stop() end end)
humanoid.Jumping:Connect(function(jumping) if jumping then stop() end end)
humanoid.Died:Once(function()stop();command:Destroy()end)
