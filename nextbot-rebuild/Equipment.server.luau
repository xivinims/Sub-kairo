local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Debris=game:GetService('Debris')
local package=Replicated:WaitForChild('NextbotReference')
local rules=require(package:WaitForChild('EquipmentRules'))
local remote=package:WaitForChild('Equipment')
local sessions={}
local decoys=Instance.new('Folder');decoys.Name='NBDecoys';decoys.Parent=workspace
local function sync(p,s)
 for id in pairs(rules.items) do p:SetAttribute('NBOwned_'..id,s.owned[id] or 0) end
 p:SetAttribute('NBUtility',s.utility or '');p:SetAttribute('NBFlashlight',s.light)
end
local function clear(p,s)
 s.light=false
 if s.decoy then s.decoy:Destroy();s.decoy=nil end
 sync(p,s)
end
local function setup(p)
 local s={owned={flashlight=1},used={},utility=nil,light=false,last=-10,decoyAt=-100}
 -- Test grants are only available in Studio and do not persist as purchases.
 if Run:IsStudio() and workspace:GetAttribute('ReferencePreviewOnly') then
  for _,id in ipairs({'compass','timer','radar','decoy'}) do s.owned[id]=3 end
 end
 sessions[p]=s;sync(p,s)
 p:GetAttributeChangedSignal('NBInRound'):Connect(function()if not p:GetAttribute('NBInRound') then clear(p,s) end end)
 p.CharacterAdded:Connect(function()clear(p,s)end)
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerRemoving:Connect(function(p)local s=sessions[p];if s and s.decoy then s.decoy:Destroy()end;sessions[p]=nil end)
local function activate(p,s,id)
 local round=package:GetAttribute('Round') or 0
 if s.used[id]==round or rules.consume(s.owned,id,round,s.used) then sync(p,s);return true end
 return false
end
remote.OnServerEvent:Connect(function(p,action,id)
 if type(action)~='string' or type(id)~='string' or not rules.items[id] then return end
 local s=sessions[p];if not s or os.clock()-s.last<.15 then return end;s.last=os.clock()
 if action=='Equip' then
  if p:GetAttribute('NBInRound') or not rules.canEquip(id,s.owned) then return end
  if id~='flashlight' then s.utility=id end;sync(p,s);return
 end
 local char=p.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
 if action~='Use' or not p:GetAttribute('NBInRound') or not root or not hum or hum.Health<=0 then return end
 if id=='flashlight' then s.light=not s.light;sync(p,s);return end
 if s.utility~=id or not activate(p,s,id) then return end
 if id~='decoy' or os.clock()-s.decoyAt<15 then return end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={char}
 if workspace:Raycast(root.Position,root.CFrame.LookVector*4,ray) then return end
 local old=char.Archivable;char.Archivable=true;local ok,copy=pcall(function()return char:Clone()end);char.Archivable=old
 if not ok or not copy then return end
 s.decoyAt=os.clock();p:SetAttribute('NBDecoyReadyAt',workspace:GetServerTimeNow()+15)
 if s.decoy then s.decoy:Destroy()end
 for _,v in ipairs(copy:GetDescendants()) do
  if v:IsA('LuaSourceContainer') or v:IsA('Tool') or v:IsA('Sound') or v:IsA('ForceField') then v:Destroy()
  elseif v:IsA('BasePart') then v.Transparency=math.max(v.Transparency,.5);v.Color=Color3.fromRGB(177,144,235);v.Material=Enum.Material.Neon end
 end
 copy.Name='Decoy';copy:PivotTo(root.CFrame*CFrame.new(0,0,-4));copy.Parent=decoys;s.decoy=copy
 local dh=copy:FindFirstChildOfClass('Humanoid');local dr=copy:FindFirstChild('HumanoidRootPart')
 if not dh or not dr then copy:Destroy();return end
 dh.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;dh.WalkSpeed=hum.WalkSpeed*.75
 for _,v in ipairs(copy:GetDescendants()) do if v:IsA('BasePart') and not v.Anchored then pcall(function()v:SetNetworkOwner(nil)end)end end
 local direction=root.CFrame.LookVector
 Debris:AddItem(copy,5)
 task.spawn(function()while copy.Parent do dh:Move(direction,false);task.wait(.1)end end)
end)
-- Consume utilities once per round, including passive timer/compass/radar.
local function startUtility(p)
 local s=sessions[p];if not s or not p:GetAttribute('NBInRound') or not s.utility then return end
 if not activate(p,s,s.utility) then s.utility=nil;sync(p,s)end
end
local function watch(p)p:GetAttributeChangedSignal('NBInRound'):Connect(function()startUtility(p)end)end
Players.PlayerAdded:Connect(watch);for _,p in ipairs(Players:GetPlayers()) do watch(p)end
