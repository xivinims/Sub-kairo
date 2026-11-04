local Players=game:GetService('Players');local Run=game:GetService('RunService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local Pose=require(package:WaitForChild('PosePlayer'));local clips=package:WaitForChild('MovementClips')
local states={}
local function setup(p)
 local function char(c)
  local h=c:WaitForChild('Humanoid',10);local root=c:WaitForChild('HumanoidRootPart',10);if not h or not root then return end
  states[p]={char=c,h=h,root=root,motors=Pose.Motors(c),time=0,name=''}
 end
 p.CharacterAdded:Connect(char);p:GetAttributeChangedSignal('NBAppearanceRevision'):Connect(function()if p.Character then task.spawn(char,p.Character)end end);if p.Character then task.spawn(char,p.Character)end
end
Players.PlayerAdded:Connect(setup);Players.PlayerRemoving:Connect(function(p)states[p]=nil end);for _,p in ipairs(Players:GetPlayers())do setup(p)end
Run.PreSimulation:Connect(function(dt)
 for p,s in pairs(states)do
  if not s.char.Parent or s.h.Health<=0 or (p:GetAttribute('NBPlayingEmote')or '')~=''then continue end
  local moving=Vector3.new(s.root.AssemblyLinearVelocity.X,0,s.root.AssemblyLinearVelocity.Z).Magnitude>1.5
  local mode=p:GetAttribute('NBMobility');local name
  if mode=='Downed'then name='Crouch idle'
  elseif mode=='Slide'then name='Slide'
  elseif mode=='Crouch'then name=moving and 'Crouch forward'or 'Crouch idle'
  elseif s.h.FloorMaterial==Enum.Material.Air then name='jump'
  elseif moving then
   local velocity=s.root.CFrame:VectorToObjectSpace(s.root.AssemblyLinearVelocity)
   name=velocity.Z>4 and 'back'or velocity.X>8 and 'right'or velocity.X< -8 and 'left'or 'forward'
  else name='idle'end
  local sequence=clips:FindFirstChild(name)
  if sequence then
   if s.name~=name then s.name=name;s.time=0 end
   local data=Pose.Decode(sequence);s.time+=dt*(mode=='Sprint'and 1.25 or 1)
   if name~='Slide'and name~='jump'and data.duration>0 then s.time%=data.duration end
   Pose.Apply(data,s.motors,s.time,1-math.exp(-dt*18))
  end
 end
end)
