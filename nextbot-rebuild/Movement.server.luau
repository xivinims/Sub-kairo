local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local config=require(package.Config)
local states={}
local function setup(p)
 states[p]={sprint=false,crouch=false,last=-10,slide=0}
 p.CharacterAdded:Connect(function(c)
  local s=states[p];if not s then return end;s.sprint=false;s.crouch=false;s.slide=0
  local h=c:WaitForChild('Humanoid',10);if h then s.hip=h.HipHeight end
 end)
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers())do setup(p)end
Players.PlayerRemoving:Connect(function(p)states[p]=nil end)
package:WaitForChild('Movement').OnServerEvent:Connect(function(p,action,on)
 local s=states[p];local c=p.Character;local root=c and c:FindFirstChild('HumanoidRootPart');local h=c and c:FindFirstChildOfClass('Humanoid')
 if not s or not h or not root or not p:GetAttribute('NBInArena')or p:GetAttribute('NBDowned')or h.Health<=0 or os.clock()-s.last<.07 then return end
 s.last=os.clock()
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
  s.hip=s.hip or h.HipHeight
  local active=p:GetAttribute('NBInArena')
  if not active then s.sprint=false;s.crouch=false;s.slideUntil=0 end
  local down=p:GetAttribute('NBDowned');local sliding=active and not down and (s.slideUntil or 0)>os.clock()
  local function perk(id)return p:GetAttribute('NBPerk')==id or p:GetAttribute('NBPerk2')==id end
  local speed=down and 3 or s.crouch and config.CrouchSpeed or s.sprint and 33.3 or config.WalkSpeed
  if perk('stilts')and not down and not s.crouch then speed*=1.08 end
  if (p:GetAttribute('NBCarrying')or 0)>0 then speed*=.82 end
  if (p:GetAttribute('NBSpeedBoostUntil')or 0)>workspace:GetServerTimeNow()then speed*=1.5 end
  local desired=active and speed or 16
  local acceleration=perk('hermes')and 1.7 or 1
  if (p:GetAttribute('NBSpeedBoostUntil')or 0)>workspace:GetServerTimeNow()then acceleration*=1.5 end
  local crawl=perk('medkit')and 3.6 or 3
  local horizontalSpeed=Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude
  if horizontalSpeed<.1 and not down then s.speed=math.min(desired,16)else s.speed=math.min(desired,(s.speed or 16)+35*step*acceleration)end
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
