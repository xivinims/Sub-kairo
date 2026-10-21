-- Overyard Mage Duel V2 - side spell controls
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local cast=ReplicatedStorage:WaitForChild("MageDuelRemotes"):WaitForChild("Cast")
local tool=script.Parent
local mouse=nil
local equipped=false
local localCD={}
local function ensureStaffEquipped()
 local ch=player.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 local bp=player:FindFirstChildOfClass("Backpack")
 local toolNow=(ch and ch:FindFirstChild("AstralStaff")) or (bp and bp:FindFirstChild("AstralStaff"))
 if hum and toolNow and toolNow:IsA("Tool") and toolNow.Parent~=ch then
  pcall(function() hum:EquipTool(toolNow) end)
 end
 return toolNow
end
local gui=nil

local CD={
 Attack=.66,Barrier=2.8,Storm=5.5,Singularity=7.5,
 Heal=6,Dodge=1.8,Fly=5,
}

local function ready(key)
 local cd=CD[key] or 1
 if (localCD[key] or 0)>os.clock() then return false end
 localCD[key]=os.clock()+cd
 return true
end

local function getMotor(name)
 local ch=player.Character
 if not ch then return nil end
 for _,d in ipairs(ch:GetDescendants())do
  if d:IsA("Motor6D") and d.Name==name then return d end
 end
end

local function resetPose(ms)
 task.delay(ms or .34,function()
  for _,name in ipairs({"RightShoulder","RightElbow","LeftShoulder","LeftElbow","Waist","Neck"})do
   local m=getMotor(name)
   if m then TweenService:Create(m,TweenInfo.new(.2,Enum.EasingStyle.Sine),{Transform=CFrame.new()}):Play()end
  end
 end)
end

local function castPose(kind)
 local rs=getMotor("RightShoulder")
 local re=getMotor("RightElbow")
 local ls=getMotor("LeftShoulder")
 local le=getMotor("LeftElbow")
 local waist=getMotor("Waist")
 local neck=getMotor("Neck")
 if kind=="shield" then
  if ls then TweenService:Create(ls,TweenInfo.new(.12),{Transform=CFrame.Angles(math.rad(-120),0,math.rad(-18))}):Play()end
  if le then TweenService:Create(le,TweenInfo.new(.12),{Transform=CFrame.Angles(math.rad(-45),0,0)}):Play()end
  if waist then TweenService:Create(waist,TweenInfo.new(.12),{Transform=CFrame.Angles(0,math.rad(16),0)}):Play()end
  resetPose(.43)
 elseif kind=="storm" then
  if rs then TweenService:Create(rs,TweenInfo.new(.16),{Transform=CFrame.Angles(math.rad(-135),0,math.rad(24))}):Play()end
  if ls then TweenService:Create(ls,TweenInfo.new(.16),{Transform=CFrame.Angles(math.rad(-125),0,math.rad(-26))}):Play()end
  if neck then TweenService:Create(neck,TweenInfo.new(.16),{Transform=CFrame.Angles(math.rad(-7),0,0)}):Play()end
  resetPose(.6)
 else
  if rs then TweenService:Create(rs,TweenInfo.new(.12,Enum.EasingStyle.Quad),{Transform=CFrame.Angles(math.rad(-108),0,math.rad(24))}):Play()end
  if re then TweenService:Create(re,TweenInfo.new(.12),{Transform=CFrame.Angles(math.rad(-32),0,0)}):Play()end
  if ls then TweenService:Create(ls,TweenInfo.new(.12),{Transform=CFrame.Angles(math.rad(-42),0,math.rad(-26))}):Play()end
  if waist then TweenService:Create(waist,TweenInfo.new(.12),{Transform=CFrame.Angles(0,math.rad(-12),0)}):Play()end
  resetPose(.36)
 end
end

local function fire(name)
 if not ready(name) then return end
 ensureStaffEquipped()
 local data={}
 local liveMouse=player:GetMouse()
 if liveMouse then data.aim=liveMouse.Hit.Position
 elseif mouse then data.aim=mouse.Hit.Position end
 if name=="Barrier" then castPose("shield")
 elseif name=="Storm" then castPose("storm")
 elseif name=="Singularity" then castPose("storm")
 elseif name=="Attack" then castPose("cast")end
 cast:FireServer(name,data)
end

local buttons={
 {"Z","Zoltraak","Attack"},
 {"Q","Barreira","Barrier"},
 {"C","Judradjim","Storm"},
 {"V","Singularidade","Singularity"},
 {"E","Vida","Heal"},
 {"R","Esquiva","Dodge"},
 {"X","Voo","Fly"},
}

local function buildUI()
 if gui then gui:Destroy()end
 gui=Instance.new("ScreenGui")
 gui.Name="MageDuelAbilities"
 gui.ResetOnSpawn=false
 gui.IgnoreGuiInset=true
 gui.DisplayOrder=200
 gui.Parent=player:WaitForChild("PlayerGui")

 local holder=Instance.new("Frame")
 holder.Name="SpellRail"
 holder.AnchorPoint=Vector2.new(0,.5)
 holder.Position=UDim2.new(0,18,.5,0)
 holder.Size=UDim2.fromOffset(178,384)
 holder.BackgroundTransparency=1
 holder.Parent=gui

 local title=Instance.new("TextLabel")
 title.Size=UDim2.fromOffset(160,32)
 title.Position=UDim2.fromOffset(0,0)
 title.BackgroundColor3=Color3.fromRGB(6,8,12)
 title.BackgroundTransparency=.2
 title.BorderSizePixel=0
 title.Font=Enum.Font.GothamMedium
 title.Text="MAGIAS"
 title.TextColor3=Color3.fromRGB(230,238,248)
 title.TextSize=14
 title.Parent=holder

 local close=Instance.new("TextButton")
 close.Size=UDim2.fromOffset(32,32)
 close.Position=UDim2.fromOffset(144,0)
 close.BackgroundColor3=Color3.fromRGB(6,8,12)
 close.BackgroundTransparency=.2
 close.BorderSizePixel=0
 close.Font=Enum.Font.GothamBold
 close.Text="×"
 close.TextSize=18
 close.TextColor3=Color3.fromRGB(230,238,248)
 close.Parent=holder
 local reopen=Instance.new("TextButton")
 reopen.Name="ReopenSpells"
 reopen.Size=UDim2.fromOffset(72,32)
 reopen.Position=UDim2.new(0,18,.5,-16)
 reopen.BackgroundColor3=Color3.fromRGB(6,8,12)
 reopen.BackgroundTransparency=.18
 reopen.BorderSizePixel=0
 reopen.Font=Enum.Font.GothamMedium
 reopen.Text="MAGIAS"
 reopen.TextColor3=Color3.fromRGB(230,238,248)
 reopen.TextSize=12
 reopen.Visible=false
 reopen.Parent=gui

 close.Activated:Connect(function()
  holder.Visible=false
  reopen.Visible=true
 end)
 reopen.Activated:Connect(function()
  reopen.Visible=false
  holder.Visible=true
 end)

 for i,item in ipairs(buttons)do
  local b=Instance.new("TextButton")
  b.Name=item[2]
  b.Size=UDim2.fromOffset(176,40)
  b.Position=UDim2.fromOffset(0,38+(i-1)*46)
  b.BackgroundColor3=Color3.fromRGB(11,14,20)
  b.BackgroundTransparency=.12
  b.BorderSizePixel=0
  b.AutoButtonColor=true
  b.Font=Enum.Font.GothamMedium
  b.Text=item[1].."   "..item[2]
  b.TextXAlignment=Enum.TextXAlignment.Left
  b.TextColor3=Color3.fromRGB(228,236,247)
  b.TextSize=13
  b.Parent=holder
  local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,12);pad.Parent=b
  local line=Instance.new("Frame")
  line.Size=UDim2.fromOffset(2,40);line.BackgroundColor3=Color3.fromRGB(170,215,255);line.BorderSizePixel=0;line.Parent=b
  local function castFromButton() fire(item[3]) end
  b.Activated:Connect(castFromButton)
  b.MouseButton1Click:Connect(castFromButton)
 end
end

tool.Equipped:Connect(function(m)
 equipped=true;mouse=m
 if not gui then buildUI() end
end)
tool.Unequipped:Connect(function()
 equipped=false;mouse=nil
end)
tool.Activated:Connect(function()fire("Attack")end)

task.defer(function()
 buildUI()
 task.wait(.4)
 ensureStaffEquipped()
end)

player.CharacterAdded:Connect(function()
 task.wait(.8)
 ensureStaffEquipped()
 if not gui then buildUI() end
end)

UserInputService.InputBegan:Connect(function(input,gp)
 if gp then return end
 local k=input.KeyCode
 if k==Enum.KeyCode.Z then fire("Attack")
 elseif k==Enum.KeyCode.Q then fire("Barrier")
 elseif k==Enum.KeyCode.C then fire("Storm")
 elseif k==Enum.KeyCode.V then fire("Singularity")
 elseif k==Enum.KeyCode.E then fire("Heal")
 elseif k==Enum.KeyCode.R then fire("Dodge")
 elseif k==Enum.KeyCode.X then fire("Fly")end
end)
