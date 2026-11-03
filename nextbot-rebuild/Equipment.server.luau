local Players=game:GetService('Players');local Debris=game:GetService('Debris')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local Profiles=require(script.Parent.ProfileService);local Rules=require(package.EquipmentRules)
local remote=package:WaitForChild('Equipment');local sessions={}
local decoys=Instance.new('Folder');decoys.Name='NBDecoys';decoys.Parent=workspace
local function clear(p,s)
 s.light=false;if s.decoy then s.decoy:Destroy();s.decoy=nil end
 p:SetAttribute('NBFlashlight',false)
 local c=p.Character;local gear=c and c:FindFirstChild('NBHeldLight');if gear then gear:Destroy()end
end
local function setup(p)
 local s={used={},last=-10,ready=0,light=false};sessions[p]=s
 p.CharacterAdded:Connect(function()clear(p,s)end)
 p:GetAttributeChangedSignal('NBInRound'):Connect(function()if not p:GetAttribute('NBInRound')then clear(p,s)end end)
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers())do setup(p)end
Players.PlayerRemoving:Connect(function(p)local s=sessions[p];if s then clear(p,s)end;sessions[p]=nil end)
local function consume(p,s,id,perUse)
 local round=package:GetAttribute('Round')or 0
 if not perUse and s.used[id]==round then return true end
 local ok,status=Profiles.Mutate(p,function(v)
  if (v.equipment[id]or 0)<=0 then return false,'empty'end
  if not Rules.items[id].permanent then v.equipment[id]-=1 end
  return true,'used'
 end)
 if ok then s.used[id]=round end;return ok
end
local function light(p,s)
 s.light=not s.light;p:SetAttribute('NBFlashlight',s.light)
 local c=p.Character;local old=c and c:FindFirstChild('NBHeldLight');if old then old:Destroy()end
 if not s.light or not c then return end
 local mode=p:GetAttribute('NBLightID')or 'flashlight';local arm=c:FindFirstChild(mode=='headlamp'and 'Head'or 'Right Arm')or c:FindFirstChild('RightHand')
 if not arm then return end
 local handle=Instance.new('Part');handle.Name='NBHeldLight';handle.Size=Vector3.new(.35,.35,1.3);handle.Color=Color3.fromRGB(30,34,40);handle.Material=Enum.Material.Metal;handle.CanCollide=false;handle.CanTouch=false;handle.CanQuery=false;handle.Massless=true
 handle.CFrame=arm.CFrame*CFrame.new(0,mode=='headlamp'and 0 or -.9,-.4);handle.Parent=c
 local weld=Instance.new('WeldConstraint');weld.Part0=arm;weld.Part1=handle;weld.Parent=handle
 local lamp=Instance.new('SpotLight');lamp.Face=Enum.NormalId.Front;lamp.Range=mode=='headlamp'and 65 or 50;lamp.Angle=65;lamp.Brightness=2;lamp.Shadows=true;lamp.Parent=handle
end
remote.OnServerEvent:Connect(function(p,action,id)
 if type(action)~='string'or type(id)~='string'or not Rules.items[id]then return end
 local s=sessions[p];local profile=Profiles.Get(p);if not s or not profile or os.clock()-s.last<.2 then return end;s.last=os.clock()
 if action=='Equip'then
  if p:GetAttribute('NBInRound')then return end
  local _,status=Profiles.Mutate(p,function(v)
   if not Rules.canEquip(id,v.equipment)then return false,'empty'end
   if Rules.items[id].slot=='Light'then v.light=id else v.utility=id end;return true,'equipped'
  end);remote:FireClient(p,status);return
 end
 local char=p.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
 if action~='Use'or not p:GetAttribute('NBInRound')or p:GetAttribute('NBDowned')or not root or not hum or hum.Health<=0 then return end
 if id=='flashlight'then light(p,s);return end
 if profile.utility~=id then return end
 if id=='compass'or id=='timer'or id=='radar'then return end
 if workspace:GetServerTimeNow()<s.ready then return end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={char}
 if (id=='decoy'or id=='barrier')and workspace:Raycast(root.Position,root.CFrame.LookVector*5,rp)then return end
 if not consume(p,s,id,id=='baton'or id=='barrier'or id=='cola')then remote:FireClient(p,'empty');return end
 s.ready=workspace:GetServerTimeNow()+(id=='radio'and 5 or 15);p:SetAttribute('NBDecoyReadyAt',s.ready)
 if id=='baton'or id=='cola'then p:SetAttribute('NBSpeedBoostUntil',workspace:GetServerTimeNow()+(id=='cola'and 10 or 3));return end
 if id=='radio'then for _,other in ipairs(Players:GetPlayers())do if other:GetAttribute('NBInRound')then remote:FireClient(other,'ping',p.UserId,root.Position)end end;return end
 if id=='barrier'then
  local wall=Instance.new('Part');wall.Name='PlayerBarrier';wall.Size=Vector3.new(10,8,1);wall.CFrame=root.CFrame*CFrame.new(0,1,-5);wall.Anchored=true;wall.Color=Color3.fromRGB(130,173,223);wall.Transparency=.35;wall.Material=Enum.Material.ForceField;wall.Parent=workspace;Debris:AddItem(wall,15);return
 end
 if id~='decoy'then return end
 local arch=char.Archivable;char.Archivable=true;local ok,copy=pcall(function()return char:Clone()end);char.Archivable=arch;if not ok or not copy then return end
 if s.decoy then s.decoy:Destroy()end
 for _,v in ipairs(copy:GetDescendants())do
  if v:IsA('LuaSourceContainer')or v:IsA('Tool')or v:IsA('Sound')or v:IsA('ForceField')or v:IsA('ProximityPrompt')then v:Destroy()
  elseif v:IsA('BasePart')then v.Transparency=math.max(v.Transparency,.5);v.Color=Color3.fromRGB(177,144,235);v.Material=Enum.Material.Neon end
 end
 copy.Name='Decoy';copy:PivotTo(root.CFrame*CFrame.new(0,0,-4));copy.Parent=decoys;s.decoy=copy
 local dh=copy:FindFirstChildOfClass('Humanoid');if not dh then copy:Destroy();return end
 dh.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;dh.WalkSpeed=hum.WalkSpeed*.75
 for _,v in ipairs(copy:GetDescendants())do if v:IsA('BasePart')and not v.Anchored then pcall(function()v:SetNetworkOwner(nil)end)end end
 local direction=root.CFrame.LookVector;Debris:AddItem(copy,5)
 task.spawn(function()while copy.Parent do dh:Move(direction,false);task.wait(.1)end end)
end)
local function watch(p)
 p:GetAttributeChangedSignal('NBInRound'):Connect(function()
  if not p:GetAttribute('NBInRound')then return end
  local s=sessions[p];local v=Profiles.Get(p);if not s or not v then return end
  local id=v.utility
  if id=='compass'or id=='timer'or id=='radar'or id=='decoy'or id=='radio'then
   if not consume(p,s,id,false)then p:SetAttribute('NBUtility','')end
  end
 end)
end
Players.PlayerAdded:Connect(watch);for _,p in ipairs(Players:GetPlayers())do watch(p)end
