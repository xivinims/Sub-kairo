local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RS=game:GetService("ReplicatedStorage")
local ContentProvider=game:GetService("ContentProvider")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
player:SetAttribute("SweanLoadingDone",false)

local gui=Instance.new("ScreenGui")
gui.Name="SurviversLoading"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=1000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Global

local frame=Instance.new("Frame")
frame.Name="Background"
frame.Size=UDim2.fromScale(1,1)
frame.BackgroundColor3=Color3.fromRGB(7,7,10)
frame.BorderSizePixel=0
frame.ClipsDescendants=true
frame.Parent=gui

local shade=Instance.new("UIGradient")
shade.Rotation=90
shade.Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromRGB(18,18,23)),
 ColorSequenceKeypoint.new(.56,Color3.fromRGB(8,8,11)),
 ColorSequenceKeypoint.new(1,Color3.fromRGB(2,2,4)),
})
shade.Parent=frame

local title=Instance.new("ImageLabel")
title.Name="BrandTitle"
title.BackgroundTransparency=1
title.AnchorPoint=Vector2.new(.5,0)
title.Position=UDim2.new(.5,0,.055,0)
title.Size=UDim2.new(.42,0,.13,0)
title.Image="rbxassetid://99002027743613"
title.ImageTransparency=.08
title.ScaleType=Enum.ScaleType.Fit
title.ZIndex=5
title.Parent=frame

local goodLuck=Instance.new("TextLabel")
goodLuck.Name="GoodLuckBackdrop"
goodLuck.BackgroundTransparency=1
goodLuck.AnchorPoint=Vector2.new(.5,.5)
goodLuck.Position=UDim2.fromScale(.5,.55)
goodLuck.Size=UDim2.new(.94,0,.20,0)
goodLuck.Text="GOOD LUCK"
goodLuck.TextColor3=Color3.fromRGB(218,218,224)
goodLuck.TextTransparency=.58
goodLuck.TextStrokeColor3=Color3.new(0,0,0)
goodLuck.TextStrokeTransparency=.7
goodLuck.Font=Enum.Font.GothamBlack
goodLuck.TextScaled=true
goodLuck.ZIndex=2
goodLuck.Parent=frame
local goodLuckLimit=Instance.new("UITextSizeConstraint",goodLuck)
goodLuckLimit.MinTextSize=28
goodLuckLimit.MaxTextSize=96

local avatarView=Instance.new("ViewportFrame")
avatarView.Name="LoadingAvatar"
avatarView.BackgroundTransparency=1
avatarView.AnchorPoint=Vector2.new(.5,1)
avatarView.Position=UDim2.new(.5,0,1.12,0)
avatarView.Size=UDim2.new(.72,0,.90,0)
avatarView.Ambient=Color3.fromRGB(78,79,88)
avatarView.LightColor=Color3.fromRGB(224,219,222)
avatarView.LightDirection=Vector3.new(-.7,-.8,-.45)
avatarView.ZIndex=4
avatarView.Parent=frame
local world=Instance.new("WorldModel",avatarView)
local camera=Instance.new("Camera",avatarView)
camera.FieldOfView=34
avatarView.CurrentCamera=camera

local avatarClone=nil
local avatarRoot=nil
local avatarBase=nil
local avatarJoints={}
local animationConnection=nil

local function clearAvatar()
 if animationConnection then animationConnection:Disconnect() animationConnection=nil end
 if avatarClone then avatarClone:Destroy() avatarClone=nil end
 avatarRoot=nil avatarBase=nil table.clear(avatarJoints)
end

local function buildAvatar()
 clearAvatar()
 local char=player.Character or player.CharacterAdded:Wait()
 if not char then return end
 local archivable=char.Archivable
 char.Archivable=true
 local ok,clone=pcall(function() return char:Clone() end)
 char.Archivable=archivable
 if not ok or not clone then return end
 avatarClone=clone
 clone.Name="LoadingAvatarCharacter"
 for _,d in ipairs(clone:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Tool") then
   d:Destroy()
  elseif d:IsA("BasePart") then
   d.CanCollide=false d.CanTouch=false d.CanQuery=false d.CastShadow=false d.Anchored=false
  elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
   d.Enabled=false
  end
 end
 local hum=clone:FindFirstChildOfClass("Humanoid")
 if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.AutoRotate=false end
 local root=clone:FindFirstChild("HumanoidRootPart")
 if not root then clone:Destroy() avatarClone=nil return end
 clone.PrimaryPart=root root.Anchored=true
 clone.Parent=world
 clone:PivotTo(CFrame.new())
 avatarRoot=root avatarBase=CFrame.new(0,-.35,0)*CFrame.Angles(0,math.rad(8),0)
 root.CFrame=avatarBase
 for _,joint in ipairs(clone:GetDescendants()) do
  if joint:IsA("Motor6D") then avatarJoints[joint]=joint.Transform end
 end
 local head=clone:FindFirstChild("Head")
 local torso=clone:FindFirstChild("Torso") or clone:FindFirstChild("UpperTorso")
 local focus=(head and head.Position or Vector3.new(0,2.6,0)):Lerp(torso and torso.Position or Vector3.new(0,1.6,0),.36)
 local _,size=clone:GetBoundingBox()
 local distance=math.max(5.2,size.Y*.82)
 camera.CFrame=CFrame.lookAt(focus+Vector3.new(.15,.12,distance),focus+Vector3.new(0,.02,0))
 local start=os.clock()
 animationConnection=RunService.RenderStepped:Connect(function()
  if not avatarClone or not avatarClone.Parent or not avatarRoot then return end
  local t=os.clock()-start
  avatarRoot.CFrame=avatarBase*CFrame.new(math.sin(t*.58)*.025,math.sin(t*1.35)*.055,0)*CFrame.Angles(0,math.sin(t*.42)*.025,0)
  for joint,base in pairs(avatarJoints) do
   if joint.Parent then
    local name=joint.Name:lower()
    if name:find("neck") then
     joint.Transform=base*CFrame.Angles(math.sin(t*.72)*.025,math.sin(t*.5)*.035,0)
    elseif name:find("shoulder") then
     local side=name:find("left") and -1 or 1
     joint.Transform=base*CFrame.Angles(math.sin(t*1.15+side)*.025,0,side*.035)
    end
   end
  end
 end)
end

local status=Instance.new("TextLabel")
status.Name="Status"
status.BackgroundTransparency=1
status.AnchorPoint=Vector2.new(.5,1)
status.Position=UDim2.new(.5,0,1,-22)
status.Size=UDim2.new(.86,0,0,26)
status.TextWrapped=false
status.Font=Enum.Font.GothamMedium
status.TextColor3=Color3.fromRGB(205,205,211)
status.TextTransparency=.28
status.TextSize=11
status.Text="INICIANDO"
status.ZIndex=7
status.Parent=frame

local track=Instance.new("Frame")
track.Name="Progress"
track.AnchorPoint=Vector2.new(0,1)
track.Position=UDim2.new(0,0,1,0)
track.Size=UDim2.new(1,0,0,6)
track.BackgroundColor3=Color3.fromRGB(22,22,27)
track.BorderSizePixel=0
track.ZIndex=8
track.Parent=frame
local fill=Instance.new("Frame")
fill.Name="Fill"
fill.Size=UDim2.fromScale(0,1)
fill.BackgroundColor3=Color3.fromRGB(226,226,231)
fill.BorderSizePixel=0
fill.ZIndex=9
fill.Parent=track
local tip=Instance.new("Frame")
tip.Name="Tip"
tip.AnchorPoint=Vector2.new(1,.5)
tip.Position=UDim2.new(1,0,.5,0)
tip.Size=UDim2.fromOffset(20,14)
tip.BackgroundColor3=Color3.fromRGB(250,250,252)
tip.BackgroundTransparency=.3
tip.BorderSizePixel=0
tip.ZIndex=10
tip.Parent=fill

local retry=Instance.new("TextButton")
retry.Text="Tentar novamente"
retry.Font=Enum.Font.GothamMedium
retry.TextSize=15
retry.AnchorPoint=Vector2.new(.5,.5)
retry.Position=UDim2.fromScale(.5,.74)
retry.Size=UDim2.fromOffset(190,44)
retry.BackgroundColor3=Color3.fromRGB(38,38,44)
retry.BackgroundTransparency=.18
retry.TextColor3=Color3.new(1,1,1)
retry.Visible=false
retry.ZIndex=20
retry.Parent=frame
local corner=Instance.new("UICorner",retry)
corner.CornerRadius=UDim.new(0,13)

local progressTween=nil
local function stage(value,labelText)
 value=math.clamp(value or 0,0,1)
 if labelText then status.Text=labelText end
 if progressTween then progressTween:Cancel() end
 progressTween=TweenService:Create(fill,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(value,1)})
 progressTween:Play()
end

local pg=player:WaitForChild("PlayerGui")
gui.Parent=pg
ReplicatedFirst:RemoveDefaultLoadingScreen()
task.spawn(buildAvatar)

local running=false
local function waitFor(parent,name,timeout)
 local value=parent:WaitForChild(name,timeout)
 assert(value,"Missing "..name)
 return value
end

local function finishLoading()
 stage(1,"PRONTO")
 task.wait(.18)
 local fadeObjects={frame,title,goodLuck,avatarView,status,track}
 for _,obj in ipairs(fadeObjects) do
  if obj:IsA("Frame") then
   TweenService:Create(obj,TweenInfo.new(.28),{BackgroundTransparency=1}):Play()
  elseif obj:IsA("TextLabel") then
   TweenService:Create(obj,TweenInfo.new(.28),{TextTransparency=1,TextStrokeTransparency=1}):Play()
  elseif obj:IsA("ImageLabel") then
   TweenService:Create(obj,TweenInfo.new(.28),{ImageTransparency=1}):Play()
  elseif obj:IsA("ViewportFrame") then
   TweenService:Create(obj,TweenInfo.new(.28),{ImageTransparency=1}):Play()
  end
 end
 task.wait(.3)
 clearAvatar()
 player:SetAttribute("SweanLoadingDone",true)
 gui:Destroy()
end

local function attempt()
 if running then return end
 running=true
 retry.Visible=false
 status.Visible=true
 stage(.04,"INICIANDO")

 local ok,err=pcall(function()
  local started=os.clock()
  while not game:IsLoaded() do
   assert(os.clock()-started<45,"initial replication timeout")
   task.wait(.1)
  end

  stage(.24,"PREPARANDO LOBBY")
  local lobby=waitFor(workspace,"JediLibrary",25)
  waitFor(workspace,"IslandSpawn",25)

  stage(.48,"PREPARANDO PARTIDAS")
  local survival=waitFor(RS,"Survival",25)
  local config=waitFor(RS,"SweanMenuConfig",25)
  local menuScene=waitFor(RS,"MenuSceneTemplate",25)
  assert(config:GetAttribute("GameName")=="Suvivers [ALFA]","Wrong game config")

  stage(.64,"CARREGANDO RECURSOS")
  local loaded=0 local preloadDone=false
  local preloadThread=task.spawn(function()
   pcall(function()
    ContentProvider:PreloadAsync({lobby,menuScene,survival,title},function()
     loaded+=1
     if status.Parent then status.Text="CARREGANDO RECURSOS  •  "..loaded end
    end)
   end)
   preloadDone=true
  end)
  local deadline=os.clock()+25
  while not preloadDone and os.clock()<deadline do
   local pulse=.64+math.min(.28,(os.clock()-(deadline-25))*.012)
   stage(pulse)
   task.wait(.15)
  end
  if not preloadDone then pcall(task.cancel,preloadThread) end

  stage(.96,"FINALIZANDO")
  player:SetAttribute("MenuIntroPending",true)
  task.wait(.15)
 end)

 running=false
 if ok then
  finishLoading()
 else
  warn("Survivers loading: "..tostring(err))
  status.Visible=true
  status.Text="NÃO FOI POSSÍVEL CARREGAR"
  retry.Visible=true
 end
end

retry.Activated:Connect(function() task.spawn(attempt) end)
player.CharacterAdded:Connect(function() if gui.Parent and not running then task.defer(buildAvatar) end end)
task.spawn(attempt)
