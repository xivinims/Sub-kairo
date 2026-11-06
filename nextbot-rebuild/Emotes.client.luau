-- Original uploaded R6 keyframes, using the same deduplicating/retargeting adapter as locomotion.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local CAS=game:GetService('ContextActionService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local Pose=require(package:WaitForChild('PosePlayer'))
local clips=package:WaitForChild('EmoteClips')
local bindings=Pose.Bindings(package:WaitForChild('EmoteSourceRig'))
local entries={};for _,item in ipairs(require(package:WaitForChild('EmoteCatalog')))do entries[item.id]=item end
local player=Players.LocalPlayer
local states,watchers={},{}
local function stop(p)
 local s=states[p];if not s then return end
 for _,motor in pairs(s.motors)do if motor.Parent then motor.Transform=CFrame.identity end end
 if s.animate and s.animate.Parent and not s.character:GetAttribute('NBManualLocomotion')then s.animate.Enabled=s.animateEnabled end
 if s.running and s.running.Parent then s.running.Volume=s.runningVolume end
 if s.sound then s.sound:Destroy()end
 states[p]=nil
end
local function begin(p)
 stop(p)
 local id=p:GetAttribute('NBPlayingEmote');if not id or id==''then return end
 local char=p.Character;local h=char and char:FindFirstChildOfClass('Humanoid');local sequence=clips:FindFirstChild(id)
 if not h or h.Health<=0 or h.RigType~=Enum.HumanoidRigType.R6 or not sequence then return end
 local animate=char:FindFirstChild('Animate');local enabled=animate and animate.Enabled
 if animate then animate.Enabled=false end
 local animator=h:FindFirstChildOfClass('Animator');if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks())do track:Stop(.1)end end
 local s={data=Pose.Decode(sequence),motors=Pose.Motors(char),character=char,humanoid=h,start=p:GetAttribute('NBEmoteStarted')or workspace:GetServerTimeNow(),animate=animate,animateEnabled=enabled,cancelled=false}
 local root=char:FindFirstChild('HumanoidRootPart');local running=root and root:FindFirstChild('Running')
 if running and running:IsA('Sound')then s.running=running;s.runningVolume=running.Volume;running.Volume=0 end
 local item=entries[id]
 if item and item.soundId and item.soundId>0 and root then
  local sound=Instance.new('Sound');sound.SoundId='rbxassetid://'..item.soundId;sound.Looped=s.data.loop;sound.Volume=.6;sound.RollOffMaxDistance=45
  sound.SoundGroup=game:GetService('SoundService'):FindFirstChild('NB_EmoteVolume');sound.Parent=root
  sound.Loaded:Connect(function()if sound.Parent and sound.TimeLength>0 then sound.TimePosition=(workspace:GetServerTimeNow()-s.start)%sound.TimeLength end end)
  sound:Play();s.sound=sound
 end
 states[p]=s
end
local function release(p)
 stop(p);for _,connection in ipairs(watchers[p]or {})do connection:Disconnect()end;watchers[p]=nil
end
local function watch(p)
 local connections={};watchers[p]=connections
 local function connect(signal,callback)table.insert(connections,signal:Connect(callback))end
 connect(p:GetAttributeChangedSignal('NBPlayingEmote'),function()begin(p)end)
 connect(p:GetAttributeChangedSignal('NBEmoteStarted'),function()begin(p)end)
 connect(p:GetAttributeChangedSignal('NBAppearanceRevision'),function()begin(p)end)
 connect(p.CharacterRemoving,function()stop(p)end)
 connect(p.CharacterAdded,function(char)
  stop(p);task.spawn(function()char:WaitForChild('Humanoid',10);if p.Character==char then begin(p)end end)
 end)
 begin(p)
end
Players.PlayerAdded:Connect(watch);Players.PlayerRemoving:Connect(release);for _,p in ipairs(Players:GetPlayers())do watch(p)end
Run.PreSimulation:Connect(function()
 for p,s in pairs(states)do
  if not s.character.Parent or s.humanoid.Health<=0 then stop(p);continue end
  if p==player and not s.cancelled and (s.humanoid.MoveDirection.Magnitude>.1 or s.humanoid.Jump or p:GetAttribute('NBDowned'))then
   s.cancelled=true;package.Emotes:FireServer('Stop','');stop(p);continue
  end
  local t=math.max(0,workspace:GetServerTimeNow()-s.start)
  if s.data.duration>0 and not s.data.loop and t>s.data.duration then stop(p);continue end
  Pose.Apply(s.data,s.motors,t,1,bindings)
 end
end)
CAS:BindAction('NBStopEmote',function(_,state)
 if state==Enum.UserInputState.Begin and (player:GetAttribute('NBPlayingEmote')or '')~=''then package.Emotes:FireServer('Stop','')end
 return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.Space,Enum.KeyCode.ButtonA)
script.Destroying:Connect(function()CAS:UnbindAction('NBStopEmote');for p in pairs(watchers)do release(p)end end)
