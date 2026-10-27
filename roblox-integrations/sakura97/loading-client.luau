local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RS=game:GetService("ReplicatedStorage")
local ContentProvider=game:GetService("ContentProvider")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
player:SetAttribute("SweanLoadingDone",false)
ReplicatedFirst:RemoveDefaultLoadingScreen()

local startedAt=os.clock()
local CINEMATIC_DURATION=10
local LOGO_END=5

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
glow.BackgroundColor3=Color3.fromRGB(70,49,54)
glow.BackgroundTransparency=.89
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
viewport.Ambient=Color3.fromRGB(3,3,5)
viewport.LightColor=Color3.fromRGB(82,69,68)
viewport.LightDirection=Vector3.new(-.7,-1,-.45)
viewport.ZIndex=2
viewport.Parent=background

local function vignetteLayer(name,rotation)
 local layer=Instance.new("Frame")
 layer.Name=name
 layer.Size=UDim2.fromScale(1,1)
 layer.BackgroundColor3=Color3.new(0,0,0)
 layer.BorderSizePixel=0
 layer.ZIndex=3
 layer.Parent=background
 local gradient=Instance.new("UIGradient")
 gradient.Rotation=rotation
 gradient.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.06),
  NumberSequenceKeypoint.new(.22,.68),
  NumberSequenceKeypoint.new(.5,1),
  NumberSequenceKeypoint.new(.78,.68),
  NumberSequenceKeypoint.new(1,.06),
 })
 gradient.Parent=layer
 return layer
end
vignetteLayer("HorizontalVignette",0)
vignetteLayer("VerticalVignette",90)

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

pcall(function() tableModel:ScaleTo(.48) end)
pcall(function() tv:ScaleTo(1.04) end)

-- Model bounds inherit the pivot rotation; project part corners into world axes.
local function worldBounds(model)
 local lo=Vector3.new(math.huge,math.huge,math.huge)
 local hi=-lo
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local v=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)*.5)
    lo=Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z))
    hi=Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
   end end end
  end
 end
 return CFrame.new((lo+hi)*.5),hi-lo
end
local function fitLoadingCamera(view,camera,television,tableModel)
 local a,sa=worldBounds(television) local b,sb=worldBounds(tableModel)
 local lo=Vector3.new(math.min(a.X-sa.X/2,b.X-sb.X/2),math.min(a.Y-sa.Y/2,b.Y-sb.Y/2),math.min(a.Z-sa.Z/2,b.Z-sb.Z/2))
 local hi=Vector3.new(math.max(a.X+sa.X/2,b.X+sb.X/2),math.max(a.Y+sa.Y/2,b.Y+sb.Y/2),math.max(a.Z+sa.Z/2,b.Z+sb.Z/2))
 local center=(lo+hi)*.5 local size=hi-lo
 local pixels=view.AbsoluteSize
 local aspect=math.max(.1,pixels.X/math.max(1,pixels.Y))
 local fitDistance=math.max(size.Y,size.X/aspect)*.5/math.tan(math.rad(camera.FieldOfView*.5))
 local cameraDistance=fitDistance*1.18+size.Z*.5
 camera.CFrame=CFrame.lookAt(center+Vector3.new(0,0,cameraDistance),center)
 return camera.CFrame
end
local function moveBoundingBox(model,targetCF)
 local currentCF=worldBounds(model)
 model:PivotTo(model:GetPivot()+(targetCF.Position-currentCF.Position))
end
-- Local X faces the viewer, local Z points DOWN in this authored television.
local tableCF,tableSize=worldBounds(tableModel)
moveBoundingBox(tableModel,CFrame.new(0,-1.72,0))
tableCF,tableSize=worldBounds(tableModel)
local tableTop=tableCF.Position.Y+tableSize.Y/2

local screen=assert(tv:FindFirstChild("Screen",true),"Requested TV screen missing")
local screenCenter=Vector3.new(0,tableTop+1.58,0)
local screenNormal=Vector3.new(0,0,1)
local screenUp=Vector3.new(-1,0,0)
local desiredScreen=CFrame.fromMatrix(screenCenter,screenNormal,screenUp)
local correction=desiredScreen*screen.CFrame:Inverse()
tv:PivotTo(correction*tv:GetPivot())

local tvCF,tvSize=worldBounds(tv)
local tvBottom=tvCF.Position.Y-tvSize.Y/2
tv:PivotTo(CFrame.new(0,tableTop-tvBottom+.035,0)*tv:GetPivot())
tvCF,tvSize=worldBounds(tv)
screen=assert(tv:FindFirstChild("Screen",true))

screen.Material=Enum.Material.Neon
screen.Color=Color3.fromRGB(76,57,62)
screen.Transparency=.34
screen:SetAttribute("LoadingScreenGlow",true)
screen.Material=Enum.Material.Neon
screen.Color=Color3.fromRGB(105,119,126)
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
local logoExtent=math.min(screen.Size.Y,screen.Size.Z)*.72
logoPanel.Size=Vector3.new(.035,logoExtent,logoExtent)
logoPanel:SetAttribute("PreserveLogoAspect",true)
logoPanel.CFrame=CFrame.fromMatrix(screen.Position+Vector3.new(0,0,screen.Size.X/2+.028),Vector3.new(0,0,1),Vector3.new(0,1,0))
logoPanel.Parent=world

local logo=Instance.new("Decal")
logo.Name="GameLogo"
logo.Face=Enum.NormalId.Right
logo.Texture="rbxassetid://99002027743613"
logo.Transparency=0
logo.Parent=logoPanel

local hand=assert(assets:FindFirstChild("BloodHand"),"Requested blood hand asset missing"):Clone()
hand.Name="HandInsideTelevision"
hand:SetAttribute("SourceAssetId",8091676187)
hand.Parent=world

local handVisuals={}
for _,d in ipairs(hand:GetDescendants()) do
 if d:IsA("BasePart") then
  d.Anchored=true d.CanCollide=false d.CanTouch=false d.CanQuery=false d.CastShadow=false
  handVisuals[d]=d.Transparency
  d.Transparency=1
 elseif d:IsA("Decal") or d:IsA("Texture") then
  handVisuals[d]=d.Transparency
  d.Transparency=1
 elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
  d.Enabled=false
 end
end

local _,rawHandSize=worldBounds(hand)
local rawHandExtent=math.max(rawHandSize.X,rawHandSize.Y,rawHandSize.Z)
local targetHandExtent=math.min(screen.Size.Y,screen.Size.Z)*.84
if rawHandExtent>.001 then
 local currentScale=1
 pcall(function() currentScale=hand:GetScale() end)
 pcall(function() hand:ScaleTo(currentScale*targetHandExtent/rawHandExtent) end)
end
local handCenter=screen.Position+Vector3.new(0,-math.min(screen.Size.Y,screen.Size.Z)*.05,0)
moveBoundingBox(hand,CFrame.new(handCenter+Vector3.new(0,0,-.52)))
local behindHand=hand:GetPivot()
local impactHand=behindHand+Vector3.new(0,0,.52+screen.Size.X/2+.035)
local retreatHand=behindHand+Vector3.new(0,0,.28)

local cameraBase
local function resizeCamera()
 cameraBase=fitLoadingCamera(viewport,camera,tv,tableModel)
end
resizeCamera()
viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeCamera)

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
  viewport.Ambient=(n%4==0) and Color3.fromRGB(7,6,9) or Color3.fromRGB(2,2,4)
  task.wait(.055+(n%3)*.018)
 end
end)

local function revealHand()
 for obj,alpha in pairs(handVisuals) do
  if obj.Parent then obj.Transparency=alpha end
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
 waitUntil(4.62)
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

 waitUntil(9.05)
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
