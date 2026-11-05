local Players=game:GetService('Players');local Run=game:GetService('RunService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local Pose=require(package:WaitForChild('PosePlayer'));local clips=package:WaitForChild('MovementClips')
local bindings=Pose.Bindings(package:WaitForChild('MovementSourceRig'))
local sourceBindings={}
for _,rig in ipairs(package:WaitForChild('MovementSourceRigs'):GetChildren())do sourceBindings[rig.Name]=Pose.Bindings(rig)end
local states={}
local function release(p)
 local old=states[p];if old then for _,connection in ipairs(old.connections)do connection:Disconnect()end end
 states[p]=nil
end
local function setup(p)
 local function char(c)
  local h=c:WaitForChild('Humanoid',10);local root=c:WaitForChild('HumanoidRootPart',10);if not h or not root or p.Character~=c then return end
  release(p)
  local state={char=c,h=h,root=root,motors=Pose.Motors(c),time=0,name='',previous={},connections={}}
  states[p]=state
  local function ownAnimations(v)
   if v:IsA('LocalScript')and v.Name=='Animate'then v.Enabled=false end
   if v:IsA('Animator')then
    for _,track in ipairs(v:GetPlayingAnimationTracks())do track:Stop(0)end
    table.insert(state.connections,v.AnimationPlayed:Connect(function(track)track:Stop(0)end))
   end
  end
  for _,v in ipairs(c:GetDescendants())do ownAnimations(v)end
  table.insert(state.connections,c.DescendantAdded:Connect(ownAnimations))
  c:SetAttribute('NBManualLocomotion',true)
 end
 p.CharacterAdded:Connect(char);p.CharacterRemoving:Connect(function()release(p)end)
 p:GetAttributeChangedSignal('NBAppearanceRevision'):Connect(function()if p.Character then task.spawn(char,p.Character)end end)
 if p.Character then task.spawn(char,p.Character)end
end
Players.PlayerAdded:Connect(setup);Players.PlayerRemoving:Connect(release);for _,p in ipairs(Players:GetPlayers())do setup(p)end
Run.PreSimulation:Connect(function(dt)
 for p,s in pairs(states)do
  if not s.char.Parent or s.h.Health<=0 then continue end
  if (p:GetAttribute('NBPlayingEmote')or '')~=''then s.name='';table.clear(s.previous);continue end
  local velocity=s.root.CFrame:VectorToObjectSpace(s.root.AssemblyLinearVelocity)
  local moving=Vector3.new(velocity.X,0,velocity.Z).Magnitude>1.5
  local mode=p:GetAttribute('NBMobility');local name
  if mode=='Downed'then name='Downed'
  elseif mode=='Slide'then name='Slide'
  elseif mode=='Crouch'then name=moving and 'Crouch forward'or 'Crouch idle'
  elseif s.h.FloorMaterial==Enum.Material.Air then name=velocity.Y>1 and 'CommunityJump'or 'CommunityFall'
  elseif moving then name=mode=='Sprint'and 'CommunityRun'or 'CommunityWalk'
  else name='CommunityIdle'end
  local sequence=clips:FindFirstChild(name)
  if sequence then
   if s.name~=name then s.name=name;s.time=0 end
   local data=Pose.Decode(sequence);s.time+=dt
   if sequence.Loop and data.duration>0 then s.time%=data.duration end
   if mode=='Downed'and not moving then s.time=0 end
   -- Blend from our previous pose, not a default Animator overwrite each frame.
   for key,motor in pairs(s.motors)do if motor.Parent and s.previous[key]then motor.Transform=s.previous[key]end end
   Pose.Apply(data,s.motors,s.time,1-math.exp(-dt*18),sourceBindings[sequence:GetAttribute('SourceRig')]or bindings)
   for key,motor in pairs(s.motors)do if motor.Parent then s.previous[key]=motor.Transform end end
  end
 end
end)
