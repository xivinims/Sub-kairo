local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local config=require(package.Config)
local states={}
local function reset(s,h)
 s.sprint=false;s.crouch=false;s.slide=0;s.slideUntil=0;s.direction=nil
 s.speed=nil;s.active=false;s.hip=h and h.HipHeight or nil;s.humanoid=h
 s.last={Sprint=-10,Crouch=-10}
end
local function setup(p)
 local s={};reset(s);states[p]=s
 local function character(c)
  local h=c:WaitForChild('Humanoid',10)
  if h and p.Character==c and states[p]==s then reset(s,h)end
 end
 p.CharacterAdded:Connect(character)
 if p.Character then task.spawn(character,p.Character)end
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers())do setup(p)end
Players.PlayerRemoving:Connect(function(p)states[p]=nil end)
package:WaitForChild('Movement').OnServerEvent:Connect(function(p,action,on)
 local s=states[p];local c=p.Character;local root=c and c:FindFirstChild('HumanoidRootPart');local h=c and c:FindFirstChildOfClass('Humanoid')
 if not s or not h or not root or not p:GetAttribute('NBInArena')or p:GetAttribute('NBDowned')or h.Health<=0 then return end
 if (action~='Sprint'and action~='Crouch')or type(on)~='boolean'then return end
 -- A release must never be discarded because a different button was just pressed.
 local now=os.clock()
 if on and now-(s.last[action]or -10)<.07 then return end
 s.last[action]=now
 if action=='Sprint'and type(on)=='boolean'then s.sprint=on
 elseif action=='Crouch'and type(on)=='boolean'then
  if on and s.sprint and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude>2 and h.FloorMaterial~=Enum.Material.Air and os.clock()-s.slide>1.8 then
   s.slide=os.clock();s.slideUntil=os.clock()+.65;s.direction=root.CFrame.LookVector;s.sprint=false
  end
  if not on then
   local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={c}
   if workspace:Raycast(root.Position,Vector3.new(0,3.5,0),rp)then return end
  end
  s.crouch=on
 end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.05 then return end;local step=math.min(elapsed,.15);elapsed=0
 for p,s in pairs(states)do
  local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
  if not h or not r then continue end
  if s.humanoid~=h then reset(s,h)end
  local active=p:GetAttribute('NBInArena')==true and h.Health>0
  local down=p:GetAttribute('NBDowned')==true
  if not active or down then s.sprint=false;s.crouch=false;s.slideUntil=0 end
  if active~=s.active then s.speed=active and config.WalkSpeed or 16;s.active=active end
  local sliding=active and not down and s.direction~=nil and (s.slideUntil or 0)>os.clock()
  local function perk(id)return p:GetAttribute('NBPerk')==id or p:GetAttribute('NBPerk2')==id end
  local speed=down and 3 or s.crouch and config.CrouchSpeed or s.sprint and (config.SprintSpeed or 33.3)or config.WalkSpeed
  if perk('stilts')and not down and not s.crouch then speed*=1.08 end
  if (p:GetAttribute('NBCarrying')or 0)>0 then speed*=.82 end
  if (p:GetAttribute('NBSpeedBoostUntil')or 0)>workspace:GetServerTimeNow()then speed*=1.5 end
  local desired=active and speed or 16
  local acceleration=perk('hermes')and 1.7 or 1
  if (p:GetAttribute('NBSpeedBoostUntil')or 0)>workspace:GetServerTimeNow()then acceleration*=1.5 end
  local crawl=perk('medkit')and 3.6 or 3
  -- Retain elapsed-time acceleration without resetting to 16 whenever a new
  -- character stands still or bumps into a wall. Character state is reset above.
  s.speed=math.min(desired,(s.speed or desired)+35*step*acceleration)
  h.WalkSpeed=down and crawl or s.crouch and desired or s.speed;h.JumpPower=down and 0 or s.crouch and 0 or 45;h.UseJumpPower=true
  -- The imported crouch clips already lower TorsoRot. A second hip offset
  -- pushes the character into the floor and fights the camera.
  h.HipHeight=s.hip
  if sliding then
   local velocity=s.direction*(30+20*math.clamp(((s.slideUntil or 0)-os.clock())/.65,0,1))
   r.AssemblyLinearVelocity=Vector3.new(velocity.X,r.AssemblyLinearVelocity.Y,velocity.Z)
  end
  local mobility=down and 'Downed'or sliding and 'Slide'or s.crouch and 'Crouch'or s.sprint and 'Sprint'or 'Walk'
  p:SetAttribute('NBMobility',mobility)
 end
end)
