-- Direct playback of original R6 Pose transforms; no invented Animation IDs.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local CAS=game:GetService('ContextActionService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local clips=package:WaitForChild('EmoteClips')
local catalog=require(package:WaitForChild('EmoteCatalog'))
local entries={};for _,item in ipairs(catalog) do entries[item.id]=item end
local cache,states={},{}
local function decode(id)
 if cache[id] then return cache[id]end
 local sequence=clips:FindFirstChild(id);if not sequence then return end
 local frames=sequence:GetKeyframes();table.sort(frames,function(a,b)return a.Time<b.Time end)
 local tracks={};local duration=0
 for _,frame in ipairs(frames)do
  duration=math.max(duration,frame.Time)
  for _,pose in ipairs(frame:GetDescendants())do
   if pose:IsA('Pose') then
    tracks[pose.Name]=tracks[pose.Name] or {}
    table.insert(tracks[pose.Name],{t=frame.Time,c=pose.CFrame,w=pose.Weight,style=pose.EasingStyle.Name,direction=pose.EasingDirection.Name})
   end
  end
 end
 cache[id]={tracks=tracks,duration=duration,loop=sequence.Loop};return cache[id]
end
local function stop(p)
 local s=states[p];if not s then return end
 for _,motor in pairs(s.motors)do if motor.Parent then motor.Transform=CFrame.identity end end
 if s.animate and s.animate.Parent then s.animate.Enabled=s.animateEnabled end
 if s.sound then s.sound:Destroy()end
 states[p]=nil
end
local function begin(p)
 stop(p)
 local id=p:GetAttribute('NBPlayingEmote');if not id or id=='' then return end
 local char=p.Character;local h=char and char:FindFirstChildOfClass('Humanoid')
 if not h or h.RigType~=Enum.HumanoidRigType.R6 then return end
 local data=decode(id);if not data then return end
 local motors={};for _,v in ipairs(char:GetDescendants())do if v:IsA('Motor6D') and v.Part1 then motors[v.Part1.Name]=v end end
 local animate=char:FindFirstChild('Animate');local enabled=animate and animate.Enabled
 if animate then animate.Enabled=false end
 local animator=h:FindFirstChildOfClass('Animator');if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks())do track:Stop(.1)end end
 local s={data=data,motors=motors,character=char,start=p:GetAttribute('NBEmoteStarted') or workspace:GetServerTimeNow(),animate=animate,animateEnabled=enabled}
 local item=entries[id]
 if item and item.soundId and item.soundId>0 and char:FindFirstChild('HumanoidRootPart') then
  local sound=Instance.new('Sound');sound.SoundId='rbxassetid://'..item.soundId;sound.Looped=data.loop;sound.Volume=.6;sound.RollOffMaxDistance=45
  sound.SoundGroup=game:GetService('SoundService'):FindFirstChild('NB_EmoteVolume');sound.Parent=char.HumanoidRootPart
  sound.Loaded:Connect(function()if sound.TimeLength>0 then sound.TimePosition=(workspace:GetServerTimeNow()-s.start)%sound.TimeLength end end)
  sound:Play();s.sound=sound
 end
 states[p]=s
end
local function watch(p)
 p:GetAttributeChangedSignal('NBPlayingEmote'):Connect(function()begin(p)end)
 p:GetAttributeChangedSignal('NBEmoteStarted'):Connect(function()begin(p)end)
 p.CharacterRemoving:Connect(function()stop(p)end)
 p.CharacterAdded:Connect(function()task.defer(begin,p)end)
 begin(p)
end
Players.PlayerAdded:Connect(watch);Players.PlayerRemoving:Connect(stop);for _,p in ipairs(Players:GetPlayers())do watch(p)end
Run.PreSimulation:Connect(function()
 for p,s in pairs(states)do
  if not s.character.Parent then stop(p);continue end
  local t=math.max(0,workspace:GetServerTimeNow()-s.start)
  if s.data.duration>0 then if s.data.loop then t%=s.data.duration elseif t>s.data.duration then stop(p);continue end else t=0 end
  for name,keys in pairs(s.data.tracks)do
   local motor=s.motors[name];if not motor then continue end
   local a,b=keys[1],keys[#keys]
   for i=1,#keys-1 do if t>=keys[i].t then a=keys[i];b=keys[i+1]else break end end
   local alpha=b.t>a.t and math.clamp((t-a.t)/(b.t-a.t),0,1) or 0
   if a.style=='Constant' then alpha=0 else
    local styles={Linear=Enum.EasingStyle.Linear,Cubic=Enum.EasingStyle.Cubic,CubicV2=Enum.EasingStyle.Cubic,Elastic=Enum.EasingStyle.Elastic,Bounce=Enum.EasingStyle.Bounce}
    local style=styles[a.style] or Enum.EasingStyle.Linear
    alpha=Tween:GetValue(alpha,style,Enum.EasingDirection[a.direction] or Enum.EasingDirection.InOut)
   end
   motor.Transform=CFrame.identity:Lerp(a.c:Lerp(b.c,alpha),math.clamp(a.w+(b.w-a.w)*alpha,0,1))
  end
 end
end)
local player=Players.LocalPlayer
CAS:BindAction('NBStopEmote',function(_,state)if state==Enum.UserInputState.Begin then package.Emotes:FireServer('Stop','')end;return Enum.ContextActionResult.Pass end,false,Enum.KeyCode.Space)
