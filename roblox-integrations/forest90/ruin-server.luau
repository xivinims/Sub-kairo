local Controller={}
local Players=game:GetService("Players")local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
function Controller.allowed(distance,alive,elapsed)return alive and distance<=10 and elapsed>=4 end
function Controller.start(runtime,world)
 local ruins=assert(world.Amenities:FindFirstChild("ForestRuins"))local remote=runtime.RuinInteraction
 local last={}local sip={}
 local function actor(player)
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then return c,h,r end
 end
 for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
  if seat:IsDescendantOf(world)then seat.SitPrompt.Triggered:Connect(function(player)
   local c,h,r=actor(player)if r and(r.Position-seat.Position).Magnitude<=9 and not seat.Occupant then seat:Sit(h)end
  end)end
 end
 local prompt=ruins.TeaCorner.Teapot.PotBody.ServeTea
 local function serve(player,sourcePrompt,seated)
  sourcePrompt=sourcePrompt or prompt
  local c,h,r=actor(player)if not r then return false end
  local now=os.clock()
  if not Controller.allowed((r.Position-sourcePrompt.Parent.Position).Magnitude,true,now-(last[player]or -math.huge))then return false end
  last[player]=now
  local backpack=player:FindFirstChildOfClass("Backpack")if not backpack then return false end
  for _,container in ipairs({c,backpack})do for _,item in ipairs(container:GetChildren())do
   if item:IsA("Tool")and item:GetAttribute("RuinTeaCup")then h:EquipTool(item)remote:FireClient(player,"Já tem uma xícara! Toque para tomar um gole.")return true end
  end end
  local tool=runtime.TeaCupTool:Clone()tool.Name="Chá"tool:SetAttribute("RuinTeaCup",true)tool:SetAttribute("ServedToUserId",player.UserId)
  tool.Parent=backpack
  local bases={}local tweens={}
  local function restore()
   for _,t in ipairs(tweens)do t:Cancel()end table.clear(tweens)
   for joint,base in pairs(bases)do if joint.Parent then joint.C0=base end end table.clear(bases)
  end
  tool.Unequipped:Connect(restore)tool.Destroying:Connect(restore)
  tool.Activated:Connect(function()
   local model,hum,root=actor(player)
   if not model or tool.Parent~=model or tool:GetAttribute("ServedToUserId")~=player.UserId then return end
   local time=os.clock()if time-(sip[player]or -math.huge)<3 then return end sip[player]=time
   local original=tool.Grip
   restore()
   for _,joint in ipairs(model:GetDescendants())do if joint:IsA("Motor6D")then
    local shoulder=joint.Name=="RightShoulder"or joint.Name=="Right Shoulder"
    local elbow=joint.Name=="RightElbow"
    if shoulder or elbow then
     local base=joint.C0 bases[joint]=base
     local angle=shoulder and(hum.RigType==Enum.HumanoidRigType.R6 and 105 or 65)or 90
     local rotation=CFrame.Angles(math.rad(angle),0,math.rad(shoulder and -12 or 0))
     local goal=CFrame.new(base.Position)*rotation*base.Rotation
     local t=Tween:Create(joint,TweenInfo.new(.38,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{C0=goal})tweens[#tweens+1]=t t:Play()
    end
   end end
   task.delay(1.1,function()
    for joint,base in pairs(bases)do if joint.Parent then local t=Tween:Create(joint,TweenInfo.new(.45,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{C0=base})tweens[#tweens+1]=t t:Play()end end
    task.delay(.5,restore)
   end)
   local lift=Tween:Create(tool,TweenInfo.new(.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original*CFrame.new(.08,-.15,-.22)*CFrame.Angles(math.rad(-24),0,0)})lift:Play()
   remote:FireClient(player,"Um chá quentinho. ☕")
   task.delay(.9,function()if tool.Parent then Tween:Create(tool,TweenInfo.new(.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original}):Play()end end)
  end)
  task.delay(240,function()if tool.Parent then tool:Destroy()end end)
  hum:EquipTool(tool)remote:FireClient(player,"Chá servido! Toque na xícara equipada para tomar um gole.")return true
 end
 for _,p in ipairs(Collection:GetTagged("TreeWorldTeaPrompt"))do
  if p:IsDescendantOf(world)then p.Triggered:Connect(function(player)serve(player,p,false)end)end
 end
 for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
  local target=seat:FindFirstChild("TeaPrompt")
  if target and target.Value then seat:GetPropertyChangedSignal("Occupant"):Connect(function()
   local humanoid=seat.Occupant local player=humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
   if player then task.delay(.35,function()if seat.Occupant==humanoid then serve(player,target.Value,true)end end)end
  end)end
 end
 Players.PlayerRemoving:Connect(function(player)last[player]=nil sip[player]=nil end)
 return{serve=serve}
end
return Controller
