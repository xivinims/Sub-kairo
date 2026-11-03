-- Overyard Mage Duel V1 - client runtime
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local ContextActionService=game:GetService("ContextActionService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("MageDuelRemotes")
local cast=remotes:WaitForChild("Cast")
local tool=script.Parent
local mouse=nil
local equipped=false
local localCD={}

local function ready(key,cd)
 if (localCD[key] or 0)>os.clock() then return false end
 localCD[key]=os.clock()+cd
 return true
end

local function motor(name)
 local ch=player.Character
 if not ch then return nil end
 for _,d in ipairs(ch:GetDescendants())do
  if d:IsA("Motor6D") and d.Name==name then return d end
 end
end
local function poseCast()
 local rs=motor("RightShoulder")
 local re=motor("RightElbow")
 local ls=motor("LeftShoulder")
 local w=motor("Waist")
 if rs then TweenService:Create(rs,TweenInfo.new(.12,Enum.EasingStyle.Quad),{Transform=CFrame.Angles(math.rad(-108),0,math.rad(24))}):Play()end
 if re then TweenService:Create(re,TweenInfo.new(.12,Enum.EasingStyle.Quad),{Transform=CFrame.Angles(math.rad(-32),0,0)}):Play()end
 if ls then TweenService:Create(ls,TweenInfo.new(.12,Enum.EasingStyle.Quad),{Transform=CFrame.Angles(math.rad(-42),0,math.rad(-26))}):Play()end
 if w then TweenService:Create(w,TweenInfo.new(.12),{Transform=CFrame.Angles(0,math.rad(-12),0)}):Play()end
 task.delay(.34,function()
  for _,m in ipairs({rs,re,ls,w})do if m and m.Parent then TweenService:Create(m,TweenInfo.new(.2,Enum.EasingStyle.Sine),{Transform=CFrame.new()}):Play()end end
 end)
end
local function poseShield()
 local ls=motor("LeftShoulder")
 local le=motor("LeftElbow")
 local w=motor("Waist")
 if ls then TweenService:Create(ls,TweenInfo.new(.12),{Transform=CFrame.Angles(math.rad(-120),0,math.rad(-18))}):Play()end
 if le then TweenService:Create(le,TweenInfo.new(.12),{Transform=CFrame.Angles(math.rad(-45),0,0)}):Play()end
 if w then TweenService:Create(w,TweenInfo.new(.12),{Transform=CFrame.Angles(0,math.rad(16),0)}):Play()end
 task.delay(.42,function()
  for _,m in ipairs({ls,le,w})do if m and m.Parent then TweenService:Create(m,TweenInfo.new(.2),{Transform=CFrame.new()}):Play()end end
 end)
end

local function fire(name)
 if not equipped then return end
 local data={}
 if mouse then data.aim=mouse.Hit.Position end
 if name=="Attack" then
  if not ready(name,.66)then return end
  poseCast()
 elseif name=="Barrier" then
  if not ready(name,2.8)then return end
  poseShield()
 elseif name=="Heal" then
  if not ready(name,6)then return end
 elseif name=="Dodge" then
  if not ready(name,1.8)then return end
 elseif name=="Jump" then
  if not ready(name,2.2)then return end
 elseif name=="Fly" then
  if not ready(name,5)then return end
 end
 cast:FireServer(name,data)
end

local gui=nil
local function buildUI()
 if gui then gui:Destroy() end
 gui=Instance.new("ScreenGui")
 gui.Name="MageDuelAbilities"
 gui.ResetOnSpawn=false
 gui.IgnoreGuiInset=true
 gui.DisplayOrder=200
 gui.Parent=player:WaitForChild("PlayerGui")
 local holder=Instance.new("Frame")
 holder.AnchorPoint=Vector2.new(.5,1)
 holder.Position=UDim2.fromScale(.5,.965)
 holder.Size=UDim2.fromOffset(530,58)
 holder.BackgroundColor3=Color3.fromRGB(8,10,14)
 holder.BackgroundTransparency=.16
 holder.BorderSizePixel=0
 holder.Parent=gui
 local grad=Instance.new("UIGradient")
 grad.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.88),
  NumberSequenceKeypoint.new(.12,.18),
  NumberSequenceKeypoint.new(.88,.18),
  NumberSequenceKeypoint.new(1,.88),
 })
 grad.Parent=holder
 local names={
  {"Q","Barreira"},
  {"E","Vida"},
  {"R","Esquiva"},
  {"F","Pulo"},
  {"X","Voo"},
 }
 for i,item in ipairs(names)do
  local b=Instance.new("TextButton")
  b.Name=item[2]
  b.Size=UDim2.fromOffset(92,38)
  b.Position=UDim2.fromOffset(18+(i-1)*100,10)
  b.BackgroundColor3=Color3.fromRGB(18,21,27)
  b.BackgroundTransparency=.12
  b.BorderSizePixel=0
  b.Font=Enum.Font.GothamMedium
  b.Text=item[1].."  "..item[2]
  b.TextColor3=Color3.fromRGB(225,235,245)
  b.TextSize=13
  b.Parent=holder
  b.Activated:Connect(function()
   local map={Barreira="Barrier",Vida="Heal",Esquiva="Dodge",Pulo="Jump",Voo="Fly"}
   fire(map[item[2]])
  end)
 end
end

tool.Equipped:Connect(function(m)
 equipped=true;mouse=m;buildUI()
end)
tool.Unequipped:Connect(function()
 equipped=false;mouse=nil
 if gui then gui:Destroy();gui=nil end
end)
tool.Activated:Connect(function()fire("Attack")end)

UserInputService.InputBegan:Connect(function(input,gp)
 if gp or not equipped then return end
 if input.KeyCode==Enum.KeyCode.Q then fire("Barrier")
 elseif input.KeyCode==Enum.KeyCode.E then fire("Heal")
 elseif input.KeyCode==Enum.KeyCode.R then fire("Dodge")
 elseif input.KeyCode==Enum.KeyCode.F then fire("Jump")
 elseif input.KeyCode==Enum.KeyCode.X then fire("Fly") end
end)
