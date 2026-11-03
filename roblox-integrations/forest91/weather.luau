local W={Period=480,RainSeconds=120,FirstRain=90}
function W.raining(now,epoch)local t=math.max(0,now-epoch)if t<W.FirstRain then return false end return(t-W.FirstRain)%W.Period<W.RainSeconds end
function W.partner(a,b)return a and b and a.Health>0 and b.Health>0 and not a.Sit and not b.Sit and a.Parent~=b.Parent and(a.Parent.HumanoidRootPart.Position-b.Parent.HumanoidRootPart.Position).Magnitude<=5 end
function W.canopy(a,b)local p=a.Head.Position if b then local q=b.Head.Position return Vector3.new((p.X+q.X)*.5,math.max(p.Y,q.Y)+1.5,(p.Z+q.Z)*.5)end return p+Vector3.yAxis*1.5 end
function W.start(runtime,world)
 if W.started then return W end
 if runtime:GetAttribute("GardenTestMode")then return W end W.started=true
 local Players=game:GetService("Players")local Run=game:GetService("RunService")
 local epoch=workspace:GetServerTimeNow()runtime:SetAttribute("WeatherEpoch",epoch)runtime:SetAttribute("Raining",false)
 local entries={}local cloudy=false
 local function reset(e)
  for j,base in pairs(e.bases)do if j.Parent then j.C0=base end end
  if e.ik then e.ik:Destroy()e.ik=nil end
  if e.motor then e.motor:Destroy()e.motor=nil end e.tool:SetAttribute("SharingWith",nil)
 end
 local function give(player)
  local c=player.Character local hum=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
  if not hum or not root or hum.Health<=0 or entries[player]then return end
  local t=runtime.UmbrellaTool:Clone()t.Parent=player.Backpack
  local e={tool=t,bases={},player=player}entries[player]=e
  t.Equipped:Connect(function()
   if player.Character~=c then return end
   e.motor=Instance.new("Motor6D")e.motor.Name="UmbrellaHold"e.motor.Part0=root e.motor.Part1=t.UmbrellaAnchor e.motor.C0=root.CFrame:ToObjectSpace(CFrame.new(W.canopy(c)-Vector3.yAxis*3.2))e.motor.Parent=root
   if hum.RigType==Enum.HumanoidRigType.R15 and c:FindFirstChild("RightUpperArm")and c:FindFirstChild("RightHand")then
    local target=t.UmbrellaAnchor:FindFirstChild("GripTarget")or Instance.new("Attachment")target.Name="GripTarget"target.Position=Vector3.new(.05,.8,0)target.Parent=t.UmbrellaAnchor
    local ik=Instance.new("IKControl")ik.Name="UmbrellaHandIK"ik.Type=Enum.IKControlType.Position ik.ChainRoot=c.RightUpperArm ik.EndEffector=c.RightHand ik.Target=target ik.SmoothTime=.25 ik.Weight=1 ik.Parent=hum e.ik=ik
   end
   for _,j in ipairs(c:GetDescendants())do if j:IsA("Motor6D")and(j.Name=="RightShoulder"or j.Name=="Right Shoulder"or j.Name=="RightElbow")then e.bases[j]=j.C0 end end
  end)
  t.Unequipped:Connect(function()reset(e)end)
  t.Destroying:Connect(function()reset(e)if entries[player]==e then entries[player]=nil end end)
  if not hum.Sit and not c:FindFirstChildOfClass("Tool")then hum:EquipTool(t)end
 end
 local function remove(player)local e=entries[player]if e then e.tool:Destroy()end end
 W.give=give W.remove=remove
 local function joined(player)player.CharacterAdded:Connect(function()remove(player)task.delay(1.5,function()if runtime:GetAttribute("Raining")then give(player)end end)end)end
 Players.PlayerAdded:Connect(joined)Players.PlayerRemoving:Connect(remove)for _,p in ipairs(Players:GetPlayers())do joined(p)end
 local elapsed=0
 local function tick(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  local rain=W.raining(workspace:GetServerTimeNow(),epoch)
  if rain~=cloudy then cloudy=rain runtime:SetAttribute("Raining",rain)for _,p in ipairs(Players:GetPlayers())do if rain then give(p)else remove(p)end end end
  local active={}
  for p,e in pairs(entries)do local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")if h and h.Health>0 and e.motor and e.tool.Parent==c and not h.Sit then active[#active+1]=e elseif e.motor then reset(e)if h then h:UnequipTools()end end end
  table.sort(active,function(a,b)return a.player.UserId<b.player.UserId end)
  local paired={}
  for _,e in ipairs(active)do
   local c=e.player.Character local buddy
   if not paired[e]then for _,other in ipairs(active)do if other~=e and not paired[other]and W.partner(c.Humanoid,other.player.Character.Humanoid)then buddy=other paired[e]=other paired[other]=e break end end else buddy=paired[e]end
   local owner=not buddy or e.player.UserId<buddy.player.UserId
   for _,p in ipairs(e.tool:GetDescendants())do if p:IsA("BasePart")then p.Transparency=owner and(p.Name=="UmbrellaAnchor"and 1 or 0)or 1 end end
   local target=W.canopy(c,buddy and buddy.player.Character)-Vector3.yAxis*3.2
   e.motor.C0=e.motor.C0:Lerp(c.HumanoidRootPart.CFrame:ToObjectSpace(CFrame.new(target)),.25)
   e.tool:SetAttribute("SharingWith",buddy and buddy.player.UserId or nil)
   for joint,base in pairs(e.bases)do if joint.Parent and not e.ik then local shoulder=joint.Name~="RightElbow"local angle=shoulder and 120 or 45 local tilt=buddy and math.clamp(c.HumanoidRootPart.CFrame:PointToObjectSpace(target).X*10,-35,35)or -8
    joint.C0=joint.C0:Lerp(CFrame.new(base.Position)*CFrame.Angles(math.rad(angle),0,math.rad(shoulder and tilt or 0))*base.Rotation,.2)
   end end
  end
 end
 W.tick=tick Run.Heartbeat:Connect(tick)
 return W
end
return W
