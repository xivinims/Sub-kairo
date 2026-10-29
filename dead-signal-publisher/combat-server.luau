while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Rules=require(script.Parent.CombatRules)
local assets=RS:WaitForChild('CombatAssets');local event=RS:WaitForChild('CombatEvent');local states={};local selection={};local lastSelect={}
while workspace:GetAttribute('IslandWorldReady')~=true do task.wait(.2) end
local function config(id) local model=assets.PlayerWeapons:FindFirstChild(id);if not model then return end;return {interval=model:GetAttribute('FireInterval') or .2,damage=model:GetAttribute('Damage') or 18,mag=model:GetAttribute('Magazine') or 20,reload=model:GetAttribute('ReloadTime') or 2.2,range=350} end
local function notify(p) local s=states[p];if s then event:FireClient(p,'state',s.id,s.ammo,s.reloadingUntil or 0) end end
local function selectWeapon(p,id)
 local center=workspace:GetAttribute('VillageCenter');local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 local residents=workspace:FindFirstChild('IslandResidents');local npc=residents and residents:FindFirstChild('Tomas');local head=npc and npc:FindFirstChild('Head')
 if not root or not head or (root.Position-head.Position).Magnitude>14 or os.clock()-(lastSelect[p] or 0)<1 then return end
 local c=config(id);if not c then return end
 local old=p.Character:FindFirstChild('EquippedWorldWeapon');if old then old:Destroy() end
 local hand=p.Character:FindFirstChild('RightHand') or p.Character:FindFirstChild('Right Arm')
 if hand then
  local gun=assets.PlayerWeapons[id].Weapon:Clone();gun.Name='EquippedWorldWeapon';gun:PivotTo(hand.CFrame*CFrame.new(0,-.5,-.3));gun.Parent=p.Character
  for _,part in ipairs(gun:GetDescendants()) do if part:IsA('BasePart') then part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true end end
  local weld=Instance.new('WeldConstraint');weld.Part0=hand;weld.Part1=gun.PrimaryPart;weld.Parent=gun.PrimaryPart
 end
 lastSelect[p]=os.clock();states[p]={id=id,ammo=c.mag,nextShot=0,reloadingUntil=0};selection[p]=id;p:SetAttribute('EquippedWeapon',id);notify(p)
end
local opener=Instance.new('BindableEvent');opener.Name='OpenArmory';opener.Parent=script.Parent
opener.Event:Connect(function(p,npc)
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local head=npc:FindFirstChild('Head')
 if root and head and (root.Position-head.Position).Magnitude<=13 then event:FireClient(p,'armory') end
end)
event.OnServerEvent:Connect(function(p,action,a,b)
 if action=='select' and typeof(a)=='string' then selectWeapon(p,a);return end
 local s=states[p];local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local head=p.Character and p.Character:FindFirstChild('Head');local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
 if not s or not root or not head or not hum or hum.Health<=0 then return end
 local c=config(s.id);if not c then return end
 local now=workspace:GetServerTimeNow()
 if action=='reload' then
  if now<(s.reloadingUntil or 0) or s.ammo==c.mag then return end
  s.reloadingUntil=now+c.reload;notify(p)
  task.delay(c.reload,function() if states[p]==s then s.ammo=c.mag;s.reloadingUntil=0;notify(p) end end);return
 end
 if action~='fire' or not Rules.ValidVector(a) or not Rules.ValidVector(b) or (a-head.Position).Magnitude>7 or b.Magnitude<.9 or b.Magnitude>1.1 then return end
 if not Rules.SpendShot(s,c,now) then return end
 local direction=b.Unit
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={p.Character};rp.RespectCanCollide=false
 local hit=workspace:Raycast(head.Position,direction*c.range,rp)
 local endpoint=hit and hit.Position or head.Position+direction*c.range
 if hit then
  local model=hit.Instance:FindFirstAncestorOfClass('Model')
  while model and not model:GetAttribute('AlienCombatant') do model=model.Parent and model.Parent:FindFirstAncestorOfClass('Model') end
  if model and model:GetAttribute('AlienCombatant') and (model:GetAttribute('AlienHealth') or 0)>0 then
   local hp=math.max(0,model:GetAttribute('AlienHealth')-c.damage);model:SetAttribute('AlienHealth',hp);event:FireClient(p,'hit',hp<=0)
   if hp<=0 then model:SetAttribute('Defeated',true);task.delay(1,function() if model.Parent then model:Destroy() end end) end
  end
 end
 event:FireAllClients('shot',head.Position,endpoint,p.UserId);notify(p)
end)
Players.PlayerRemoving:Connect(function(p) states[p]=nil;selection[p]=nil;lastSelect[p]=nil end)
local function joined(p) p.CharacterAdded:Connect(function() states[p]=nil;p:SetAttribute('EquippedWeapon',nil);event:FireClient(p,'clear') end) end
Players.PlayerAdded:Connect(joined);for _,p in ipairs(Players:GetPlayers()) do joined(p) end
