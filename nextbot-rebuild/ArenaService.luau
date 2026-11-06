-- Presence in the arena is independent from participation in the timed chase.
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local Rescue=require(script.Parent.RescueService)
local Service={};local tickets=setmetatable({},{__mode='k'})
local function rig(p)
 local c=p.Character;return c,c and c:FindFirstChild('HumanoidRootPart'),c and c:FindFirstChildOfClass('Humanoid')
end
function Service.Park(p)
 local c,root=rig(p);if not root then return end
 local cameras=workspace:FindFirstChild('MenuCameras');local home=cameras and cameras:FindFirstChild('Home')
 root.Anchored=true;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 c:PivotTo(CFrame.new(home and home.Position.X or 0,-100,home and home.Position.Z or 0))
 p.ReplicationFocus=home
end
function Service.Leave(p)
 tickets[p]=(tickets[p]or 0)+1
 Rescue.Clear(p);p:SetAttribute('NBInRound',false);p:SetAttribute('NBInArena',false);p:SetAttribute('NBSpectating',false)
 Service.Park(p)
end
function Service.Enter(p,reposition)
 if not package:GetAttribute('MapReady')then return false,'loading'end
 -- Server-only permission: a local loading-screen flag cannot admit an unready client.
 if typeof(p)=='Instance'and p:IsA('Player')and p:GetAttribute('NBClientReadyRevision')~=package:GetAttribute('MapRevision')then return false,'loading'end
 local c,root,h=rig(p);if not root or not h or h.Health<=0 then return false,'character'end
 tickets[p]=(tickets[p]or 0)+1;local ticket=tickets[p]
 if not p:GetAttribute('NBInArena')or reposition then
  local folder=workspace:FindFirstChild('RoundSpawns');local points=folder and folder:GetChildren()or {}
  if #points==0 then return false,'loading'end
  local point=points[math.random(#points)];local destination=point.CFrame+Vector3.new(0,4,0)
  root.Anchored=true
  pcall(function()p:RequestStreamAroundAsync(destination.Position,1)end)
  if tickets[p]~=ticket or p.Character~=c or h.Health<=0 or not p.Parent then return false,'cancelled'end
  if not point.Parent or not package:GetAttribute('MapReady')then Service.Leave(p);return false,'loading'end
  c:PivotTo(destination);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  p:SetAttribute('NBInvulnerableUntil',workspace:GetServerTimeNow()+5)
 end
 p.ReplicationFocus=nil;root.Anchored=false
 p:SetAttribute('NBSpectating',false);p:SetAttribute('NBInArena',true)
 p:SetAttribute('NBInRound',package:GetAttribute('Phase')=='Round')
 return true,'entered'
end
function Service.PrepareMapChange(p)
 tickets[p]=(tickets[p]or 0)+1
 Rescue.Clear(p);p:SetAttribute('NBInRound',false)
 local _,root=rig(p);if root then root.Anchored=true;root.AssemblyLinearVelocity=Vector3.zero end
end
return Service
