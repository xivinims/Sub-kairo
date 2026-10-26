local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RS=game:GetService("ReplicatedStorage")
local ContentProvider=game:GetService("ContentProvider")
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
frame.BackgroundColor3=Color3.fromRGB(5,5,7)
frame.BorderSizePixel=0
frame.Parent=gui

local logo=Instance.new("ImageLabel")
logo.Name="BrandTitle"
logo.BackgroundTransparency=1
logo.AnchorPoint=Vector2.new(.5,.5)
logo.Position=UDim2.fromScale(.5,.5)
logo.Size=UDim2.new(.46,0,.22,0)
logo.Image="rbxassetid://99002027743613"
logo.ScaleType=Enum.ScaleType.Fit
logo.ImageTransparency=1
logo.Parent=frame

local retry=Instance.new("TextButton")
retry.Name="Retry"
retry.Text="Tentar novamente"
retry.Font=Enum.Font.GothamMedium
retry.TextSize=15
retry.AnchorPoint=Vector2.new(.5,.5)
retry.Position=UDim2.fromScale(.5,.72)
retry.Size=UDim2.fromOffset(190,44)
retry.BackgroundColor3=Color3.fromRGB(30,30,35)
retry.BackgroundTransparency=.18
retry.TextColor3=Color3.new(1,1,1)
retry.Visible=false
retry.Parent=frame
Instance.new("UICorner",retry).CornerRadius=UDim.new(0,13)

local pg=player:WaitForChild("PlayerGui")
gui.Parent=pg
ReplicatedFirst:RemoveDefaultLoadingScreen()
TweenService:Create(logo,TweenInfo.new(.38,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency=.04}):Play()

local running=false
local function waitFor(parent,name,timeout)
 local value=parent:WaitForChild(name,timeout)
 assert(value,"Missing "..name)
 return value
end

local function finish()
 TweenService:Create(logo,TweenInfo.new(.28),{ImageTransparency=1}):Play()
 TweenService:Create(frame,TweenInfo.new(.32),{BackgroundTransparency=1}):Play()
 task.wait(.34)
 player:SetAttribute("SweanLoadingDone",true)
 gui:Destroy()
end

local function attempt()
 if running then return end
 running=true
 retry.Visible=false
 local ok,err=pcall(function()
  local started=os.clock()
  while not game:IsLoaded() do
   assert(os.clock()-started<45,"initial replication timeout")
   task.wait(.1)
  end
  local lobby=waitFor(workspace,"JediLibrary",25)
  waitFor(workspace,"IslandSpawn",25)
  local survival=waitFor(RS,"Survival",25)
  local config=waitFor(RS,"SweanMenuConfig",25)
  local menuScene=waitFor(RS,"MenuSceneTemplate",25)
  assert(config:GetAttribute("GameName")=="Suvivers [ALFA]","Wrong game config")
  local preloadDone=false
  local thread=task.spawn(function()
   pcall(function() ContentProvider:PreloadAsync({lobby,menuScene,survival,logo}) end)
   preloadDone=true
  end)
  local deadline=os.clock()+25
  while not preloadDone and os.clock()<deadline do task.wait(.12) end
  if not preloadDone then pcall(task.cancel,thread) end
  player:SetAttribute("MenuIntroPending",false)
  player:SetAttribute("InMenu",false)
 end)
 running=false
 if ok then finish()
 else
  warn("Survivers loading: "..tostring(err))
  retry.Visible=true
 end
end

retry.Activated:Connect(function() task.spawn(attempt) end)
task.spawn(attempt)

