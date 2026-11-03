local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Profiles=require(script.Parent.ProfileService)
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local Config=require(package.Config)
local Service={};local downed,carried,carriers,reviving={},{},{},{}
local function rig(p)
 local c=p and p.Character;return c,c and c:FindFirstChild('HumanoidRootPart'),c and c:FindFirstChildOfClass('Humanoid')
end
local function close(a,b)
 local ac,ar,ah=rig(a);local bc,br,bh=rig(b)
 if not ar or not br or not ah or ah.Health<=0 or a:GetAttribute('NBDowned')or not a:GetAttribute('NBInRound')or not b:GetAttribute('NBInRound')or (ar.Position-br.Position).Magnitude>9 then return false end
 local rp=RaycastParams.new();rp.FilterDescendantsInstances={ac,bc};rp.FilterType=Enum.RaycastFilterType.Exclude
 return workspace:Raycast(ar.Position,br.Position-ar.Position,rp)==nil
end
function Service.Drop(carrier)
 local target=carried[carrier];if not target then return end
 carried[carrier]=nil;carriers[target]=nil;carrier:SetAttribute('NBCarrying',0);target:SetAttribute('NBCarried',false)
 local c,r,h=rig(target)
 if c then
  local weld=r and r:FindFirstChild('CarryWeld');if weld then weld:Destroy()end
  for _,p in ipairs(c:GetDescendants())do if p:IsA('BasePart')then
   local old=p:GetAttribute('NBMasslessBeforeCarry');if old~=nil then p.Massless=old;p:SetAttribute('NBMasslessBeforeCarry',nil)end
   local collide=p:GetAttribute('NBCollideBeforeCarry');if collide~=nil then p.CanCollide=collide;p:SetAttribute('NBCollideBeforeCarry',nil)end
  end end
  if h then h.PlatformStand=false end
  if r then r.CFrame+=Vector3.new(2,0,0);pcall(function()r:SetNetworkOwner(target)end)end
 end
end
function Service.Clear(p)
 Service.Drop(p);if carriers[p]then Service.Drop(carriers[p])end
 downed[p]=nil;reviving[p]=nil;p:SetAttribute('NBDowned',false);p:SetAttribute('NBReviveProgress',0)
 local c,r,h=rig(p)
 if c then for _,v in ipairs(c:GetDescendants())do if v:IsA('ProximityPrompt')and (v.Name=='NBRevive'or v.Name=='NBCarry')then v:Destroy()end end end
 if h then h.PlatformStand=false;h.AutoRotate=true;h.WalkSpeed=Config.WalkSpeed;h.JumpPower=45 end
end
local function revive(helper,target)
 if not downed[target]or not close(helper,target)or carriers[target]then return end
 if reviving[target]then return end
 reviving[target]=helper
 local start=workspace:GetServerTimeNow();local duration=Config.ReviveDuration/((helper:GetAttribute('NBPerk')=='stethoscope'or helper:GetAttribute('NBPerk2')=='stethoscope')and 1.4 or 1)
 while downed[target]and close(helper,target)and not carriers[target]and workspace:GetServerTimeNow()-start<duration do
  target:SetAttribute('NBReviveProgress',(workspace:GetServerTimeNow()-start)/duration);task.wait(.1)
 end
 if downed[target]and close(helper,target)and not carriers[target]and workspace:GetServerTimeNow()-start>=duration then
  Service.Clear(target);local _,_,h=rig(target);if h then h.Health=h.MaxHealth end
  target:SetAttribute('NBInvulnerableUntil',workspace:GetServerTimeNow()+3)
  task.spawn(Profiles.Reward,helper,30,50,'rescue')
 end
 reviving[target]=nil;target:SetAttribute('NBReviveProgress',0)
end
function Service.Down(p)
 if downed[p]or not p:GetAttribute('NBInRound')or workspace:GetServerTimeNow()<(p:GetAttribute('NBInvulnerableUntil')or 0)then return end
 Service.Drop(p)
 local c,r,h=rig(p);if not r or not h then return end
 p:SetAttribute('NBPlayingEmote','');p:SetAttribute('NBDowned',true);p:SetAttribute('NBDownUntil',workspace:GetServerTimeNow()+Config.BleedoutDuration)
 h.WalkSpeed=3;h.JumpPower=0;h.Health=math.max(h.Health,1)
 downed[p]=true
 local revivePrompt=Instance.new('ProximityPrompt');revivePrompt.Name='NBRevive';revivePrompt.ActionText='Reanimar';revivePrompt.ObjectText=p.DisplayName;revivePrompt.KeyboardKeyCode=Enum.KeyCode.E;revivePrompt.GamepadKeyCode=Enum.KeyCode.ButtonX;revivePrompt.MaxActivationDistance=8;revivePrompt.HoldDuration=0;revivePrompt.RequiresLineOfSight=true;revivePrompt.Parent=r
 revivePrompt.Triggered:Connect(function(helper)task.spawn(revive,helper,p)end)
 local carry=Instance.new('ProximityPrompt');carry.Name='NBCarry';carry.ActionText='Carregar';carry.KeyboardKeyCode=Enum.KeyCode.Q;carry.GamepadKeyCode=Enum.KeyCode.ButtonY;carry.MaxActivationDistance=7;carry.UIOffset=Vector2.new(0,75);carry.Parent=r
 carry.Triggered:Connect(function(helper)
  if not downed[p]or carriers[p]or carried[helper]or helper==p or not close(helper,p)then return end
  local _,hr=rig(helper);if not hr then return end
  carried[helper]=p;carriers[p]=helper;helper:SetAttribute('NBCarrying',p.UserId);p:SetAttribute('NBCarried',true)
  for _,v in ipairs(c:GetDescendants())do if v:IsA('BasePart')then v:SetAttribute('NBMasslessBeforeCarry',v.Massless);v:SetAttribute('NBCollideBeforeCarry',v.CanCollide);v.Massless=true;v.CanCollide=false end end
  r.CFrame=hr.CFrame*CFrame.new(0,1.8,1);h.PlatformStand=true
  local weld=Instance.new('WeldConstraint');weld.Name='CarryWeld';weld.Part0=hr;weld.Part1=r;weld.Parent=r
  pcall(function()r:SetNetworkOwner(helper)end)
 end)
end
package:WaitForChild('Rescue').OnServerEvent:Connect(function(p,action)if action=='Drop'then Service.Drop(p)end end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.2 then return end;elapsed=0
 for p in pairs(downed)do
  local c,r,h=rig(p)
  if not p.Parent or not r or not h or h.Health<=0 or not p:GetAttribute('NBInRound')then Service.Clear(p)
  elseif workspace:GetServerTimeNow()>=(p:GetAttribute('NBDownUntil')or 0)then Service.Clear(p);h.Health=0 end
 end
end)
Players.PlayerRemoving:Connect(Service.Clear)
return Service
