local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RS=game:GetService("ReplicatedStorage")
local ContentProvider=game:GetService("ContentProvider")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
player:SetAttribute("SweanLoadingDone",false)
ReplicatedFirst:RemoveDefaultLoadingScreen()

local startedAt=os.clock()
local CINEMATIC_DURATION=8
local LOGO_END=4

local gui=Instance.new("ScreenGui")
gui.Name="SurviversLoading"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=1000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
gui.Parent=player:WaitForChild("PlayerGui")

local background=Instance.new("Frame")
background.Name="Background"
background.Size=UDim2.fromScale(1,1)
background.BackgroundColor3=Color3.fromRGB(1,1,2)
background.BorderSizePixel=0
background.ZIndex=1
background.Parent=gui

local glow=Instance.new("Frame")
glow.Name="TelevisionGlow"
glow.AnchorPoint=Vector2.new(.5,.5)
glow.Position=UDim2.fromScale(.5,.48)
glow.Size=UDim2.new(.48,0,.62,0)
glow.BackgroundColor3=Color3.fromRGB(46,39,35)
glow.BackgroundTransparency=.92
glow.BorderSizePixel=0
glow.ZIndex=1
glow.Parent=background
local glowCorner=Instance.new("UICorner",glow)
glowCorner.CornerRadius=UDim.new(1,0)

local viewport=Instance.new("ViewportFrame")
viewport.Name="Cinematic"
viewport.Size=UDim2.fromScale(1,1)
viewport.BackgroundTransparency=1
viewport.BorderSizePixel=0
viewport.Ambient=Color3.fromRGB(12,12,15)
viewport.LightColor=Color3.fromRGB(126,112,102)
viewport.LightDirection=Vector3.new(-.7,-1,-.45)
viewport.ZIndex=2
viewport.Parent=background

local world=Instance.new("WorldModel")
world.Name="LoadingWorld"
world.Parent=viewport

local camera=Instance.new("Camera")
camera.Name="LoadingCamera"
camera.FieldOfView=34
camera.Parent=viewport
viewport.CurrentCamera=camera

local fade=Instance.new("Frame")
fade.Name="Fade"
fade.Size=UDim2.fromScale(1,1)
fade.BackgroundColor3=Color3.new(0,0,0)
fade.BackgroundTransparency=1
fade.BorderSizePixel=0
fade.ZIndex=50
fade.Parent=gui

local retry=Instance.new("TextButton")
retry.Name="Retry"
retry.Text="Tentar novamente"
retry.Font=Enum.Font.GothamMedium
retry.TextSize=14
retry.AnchorPoint=Vector2.new(.5,.5)
retry.Position=UDim2.fromScale(.5,.78)
retry.Size=UDim2.fromOffset(188,42)
retry.BackgroundColor3=Color3.fromRGB(20,20,23)
retry.BackgroundTransparency=.08
retry.TextColor3=Color3.fromRGB(235,235,238)
retry.BorderSizePixel=0
retry.Visible=false
retry.ZIndex=60
retry.Parent=gui
Instance.new("UICorner",retry).CornerRadius=UDim.new(0,5)

local assets=ReplicatedFirst:WaitForChild("LoadingCinematicAssets",6)
assert(assets,"LoadingCinematicAssets missing")

local tv=assert(assets:FindFirstChild("TV"),"Requested TV asset missing"):Clone()
local tableModel=assert(assets:FindFirstChild("Mesa"),"Requested table asset missing"):Clone()
tv.Parent=world
tableModel.Parent=world

pcall(function() tableModel:ScaleTo(.78) end)
pcall(function() tv:ScaleTo(1.5) end)

local function moveBoundingBox(model,targetCF)
 local currentCF=model:GetBoundingBox()
 local delta=targetCF*currentCF:Inverse()
 model:PivotTo(delta*model:GetPivot())
end

local tableCF,tableSize=tableModel:GetBoundingBox()
moveBoundingBox(tableModel,CFrame.new(0,-1.75,0))
tableCF,tableSize=tableModel:GetBoundingBox()
local tableTop=tableCF.Position.Y+tableSize.Y/2

local screen=assert(tv:FindFirstChild("Screen",true),"Requested TV screen missing")
local desiredScreen=CFrame.fromMatrix(
 Vector3.new(0,tableTop+1.6,0),
 Vector3.new(0,0,1),
 Vector3.new(0,1,0)
)
local orient=desiredScreen*screen.CFrame:Inverse()
tv:PivotTo(orient*tv:GetPivot())

local tvCF,tvSize=tv:GetBoundingBox()
local tvBottom=tvCF.Position.Y-tvSize.Y/2
tv:PivotTo(CFrame.new(0,tableTop-tvBottom+.04,0)*tv:GetPivot())
tvCF,tvSize=tv:GetBoundingBox()
screen=assert(tv:FindFirstChild("Screen",true))

screen.Transparency=.38
screen.Material=Enum.Material.Neon
screen.Color=Color3.fromRGB(102,119,128)
for _,part in ipairs(tv:GetDescendants()) do
 if part:IsA("BasePart") then
  part.Anchored=true
  part.CanCollide=false
  part.CanTouch=false
  part.CanQuery=false
  part.CastShadow=true
 end
end
for _,part in ipairs(tableModel:GetDescendants()) do
 if part:IsA("BasePart") then
  part.Anchored=true
  part.CanCollide=false
  part.CanTouch=false
  part.CanQuery=false
  part.CastShadow=true
 end
end

local logoPanel=Instance.new("Part")
logoPanel.Name="LogoInsideTelevision"
logoPanel.Anchored=true
logoPanel.CanCollide=false
logoPanel.CanTouch=false
logoPanel.CanQuery=false
logoPanel.CastShadow=false
logoPanel.Material=Enum.Material.SmoothPlastic
logoPanel.Color=Color3.new(0,0,0)
logoPanel.Transparency=.96
logoPanel.Size=Vector3.new(.035,screen.Size.Y*.74,screen.Size.Z*.74)
logoPanel.CFrame=screen.CFrame*CFrame.new(screen.Size.X/2+.028,0,0)
logoPanel.Parent=world

local logo=Instance.new("Decal")
logo.Name="GameLogo"
logo.Face=Enum.NormalId.Right
logo.Texture="rbxassetid://99002027743613"
logo.Transparency=0
logo.Parent=logoPanel

local hand=Instance.new("Model")
hand.Name="HandInsideTelevision"
hand.Parent=world
local handColor=Color3.fromRGB(180,171,166)

local function handPart(name,size,localCF)
 local p=Instance.new("Part")
 p.Name=name
 p.Size=size
 p.CFrame=screen.CFrame*localCF
 p.Anchored=true
 p.CanCollide=false
 p.CanTouch=false
 p.CanQuery=false
 p.CastShadow=false
 p.Material=Enum.Material.SmoothPlastic
 p.Color=handColor
 p.Transparency=1
 p.Parent=hand
 return p
end

local palm=handPart("Palm",Vector3.new(.075,.64,.52),CFrame.new(-.52,-.08,0))
hand.PrimaryPart=palm
local fingerZ={-.205,-.072,.065,.198}
local fingerLength={.39,.49,.52,.44}
for i=1,4 do
 local len=fingerLength[i]
 handPart("Finger"..i,Vector3.new(.065,len,.095),CFrame.new(-.52,.32+len/2,fingerZ[i]))
end
handPart("Thumb",Vector3.new(.065,.28,.11),CFrame.new(-.52,-.02,.34)*CFrame.Angles(math.rad(38),0,0))

local baseHandPivot=hand:GetPivot()
local behindHand=screen.CFrame*CFrame.new(-.54,-.08,0)
local impactHand=screen.CFrame*CFrame.new(screen.Size.X/2+.02,-.08,0)
local retreatHand=screen.CFrame*CFrame.new(-.18,-.08,0)
hand:PivotTo(behindHand)

local cameraTarget=Vector3.new(0,tableTop+1.28,0)
local cameraBase=CFrame.lookAt(Vector3.new(0,tableTop+1.42,10.4),cameraTarget)
camera.CFrame=cameraBase

local handDriver=Instance.new("CFrameValue")
handDriver.Value=hand:GetPivot()
handDriver:GetPropertyChangedSignal("Value"):Connect(function()
 if hand.Parent then hand:PivotTo(handDriver.Value) end
end)

local function waitUntil(seconds)
 local remain=startedAt+seconds-os.clock()
 if remain>0 then task.wait(remain) end
end

local flickerActive=true
task.spawn(function()
 local n=0
 while flickerActive and gui.Parent do
  n+=1
  local pulse=(n%5==0) and .52 or ((n%2==0) and .32 or .41)
  screen.Transparency=pulse
  logo.Transparency=(n%7==0) and .18 or 0
  viewport.Ambient=(n%4==0) and Color3.fromRGB(16,15,18) or Color3.fromRGB(11,11,14)
  task.wait(.055+(n%3)*.018)
 end
end)

local function revealHand()
 for _,p in ipairs(hand:GetDescendants()) do
  if p:IsA("BasePart") then p.Transparency=.06 end
 end
end

local function cameraImpact()
 for i=1,8 do
  local x=math.sin(i*3.7)*.055
  local y=math.cos(i*4.1)*.035
  camera.CFrame=cameraBase*CFrame.new(x,y,0)
  task.wait(.018)
 end
 camera.CFrame=cameraBase
end

task.spawn(function()
 waitUntil(3.62)
 for i=1,5 do
  logo.Transparency=(i%2==0) and .12 or .72
  task.wait(.055)
 end
 waitUntil(LOGO_END)
 flickerActive=false
 logo.Transparency=1
 screen.Transparency=.31

 revealHand()
 handDriver.Value=behindHand
 local slam=TweenService:Create(handDriver,TweenInfo.new(.16,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Value=impactHand})
 slam:Play()
 slam.Completed:Wait()
 screen.Transparency=.08
 task.spawn(cameraImpact)
 TweenService:Create(glow,TweenInfo.new(.08),{BackgroundTransparency=.84}):Play()
 task.wait(.24)
 TweenService:Create(glow,TweenInfo.new(.34),{BackgroundTransparency=.92}):Play()
 local retreat=TweenService:Create(handDriver,TweenInfo.new(.42,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Value=retreatHand})
 retreat:Play()
 screen.Transparency=.28

 waitUntil(7.05)
 TweenService:Create(fade,TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0}):Play()
end)

local loadReady=false
local loadError=nil
local running=false

local function waitFor(parent,name,timeout)
 local value=parent:WaitForChild(name,timeout)
 assert(value,"Missing "..name)
 return value
end

local function loadGame()
 if running then return end
 running=true
 retry.Visible=false
 loadError=nil
 local ok,err=pcall(function()
  local loadStarted=os.clock()
  while not game:IsLoaded() do
   assert(os.clock()-loadStarted<45,"initial replication timeout")
   task.wait(.08)
  end
  local lobby=waitFor(workspace,"JediLibrary",25)
  waitFor(workspace,"IslandSpawn",25)
  local survival=waitFor(RS,"Survival",25)
  local config=waitFor(RS,"SweanMenuConfig",25)
  local menuScene=waitFor(RS,"MenuSceneTemplate",25)
  assert(config:GetAttribute("GameName")=="Suvivers [ALFA]","Wrong game config")

  local preloadDone=false
  local thread=task.spawn(function()
   pcall(function()
    ContentProvider:PreloadAsync({lobby,menuScene,survival,tv,tableModel,logoPanel})
   end)
   preloadDone=true
  end)
  local deadline=os.clock()+25
  while not preloadDone and os.clock()<deadline do task.wait(.1) end
  if not preloadDone then pcall(task.cancel,thread) end

  player:SetAttribute("MenuIntroPending",false)
  player:SetAttribute("InMenu",false)
 end)
 running=false
 if ok then
  loadReady=true
 else
  loadError=tostring(err)
 end
end

task.spawn(loadGame)

waitUntil(CINEMATIC_DURATION)
if fade.BackgroundTransparency>0 then
 local finalFade=TweenService:Create(fade,TweenInfo.new(.18),{BackgroundTransparency=0})
 finalFade:Play()
 finalFade.Completed:Wait()
end

local deadline=os.clock()+37
while not loadReady and not loadError and os.clock()<deadline do task.wait(.05) end

if not loadReady then
 warn("Survivers loading: "..tostring(loadError or "loading timeout"))
 retry.Visible=true
 retry.Activated:Connect(function()
  loadReady=false
  loadError=nil
  task.spawn(loadGame)
  task.spawn(function()
   local retryDeadline=os.clock()+45
   while not loadReady and not loadError and os.clock()<retryDeadline do task.wait(.05) end
   if loadReady then
    player:SetAttribute("SweanLoadingDone",true)
    gui:Destroy()
   else
    retry.Visible=true
   end
  end)
 end)
else
 player:SetAttribute("SweanLoadingDone",true)
 gui:Destroy()
end
