local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RS=game:GetService("ReplicatedStorage")
local ContentProvider=game:GetService("ContentProvider")

local player=Players.LocalPlayer
player:SetAttribute("SweanLoadingDone",false)

local gui=Instance.new("ScreenGui")
gui.Name="SurviversLoading"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=1000

local frame=Instance.new("Frame")
frame.Size=UDim2.fromScale(1,1)
frame.BackgroundColor3=Color3.fromRGB(17,17,20)
frame.BorderSizePixel=0
frame.Parent=gui

local title=Instance.new("ImageLabel")
title.Name="BrandTitle"
title.BackgroundTransparency=1
title.AnchorPoint=Vector2.new(.5,.5)
title.Position=UDim2.fromScale(.5,.42)
title.Size=UDim2.new(.78,0,.26,0)
title.Image="rbxassetid://99002027743613"
title.ScaleType=Enum.ScaleType.Fit
title.Parent=frame

local status=Instance.new("TextLabel")
status.BackgroundTransparency=1
status.AnchorPoint=Vector2.new(.5,.5)
status.Position=UDim2.fromScale(.5,.58)
status.Size=UDim2.new(.86,0,0,60)
status.TextWrapped=true
status.Font=Enum.Font.GothamMedium
status.TextColor3=Color3.fromRGB(220,220,226)
status.TextSize=16
status.Text="Carregando Suvivers…"
status.Parent=frame

local track=Instance.new("Frame",frame) track.Name="LoadingTrack" track.AnchorPoint=Vector2.new(.5,.5) track.Position=UDim2.fromScale(.5,.66) track.Size=UDim2.new(.45,0,0,5) track.BackgroundColor3=Color3.fromRGB(50,42,47) track.BorderSizePixel=0 Instance.new("UICorner",track).CornerRadius=UDim.new(0,3)
local progress=Instance.new("Frame",track) progress.Name="Stage" progress.Size=UDim2.fromScale(.08,1) progress.BackgroundColor3=Color3.fromRGB(173,72,82) progress.BorderSizePixel=0 Instance.new("UICorner",progress).CornerRadius=UDim.new(0,3)
local tip=Instance.new("TextLabel",frame) tip.AnchorPoint=Vector2.new(.5,.5) tip.Size=UDim2.new(.85,0,0,40) tip.Position=UDim2.fromScale(.5,.84) tip.BackgroundTransparency=1 tip.Text="Correr faz barulho. Agache, escute e use seu kit com cuidado." tip.Font=Enum.Font.Gotham tip.TextSize=12 tip.TextWrapped=true tip.TextColor3=Color3.fromRGB(159,151,160)
local function stage(value) game:GetService("TweenService"):Create(progress,TweenInfo.new(.35),{Size=UDim2.fromScale(value,1)}):Play() end
local retry=Instance.new("TextButton")
retry.Text="Tentar novamente"
retry.Font=Enum.Font.GothamMedium
retry.TextSize=16
retry.AnchorPoint=Vector2.new(.5,.5)
retry.Position=UDim2.fromScale(.5,.72)
retry.Size=UDim2.fromOffset(200,46)
retry.BackgroundColor3=Color3.fromRGB(46,46,50)
retry.BackgroundTransparency=.3
retry.TextColor3=Color3.new(1,1,1)
retry.Visible=false
retry.Parent=frame
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,14)
corner.Parent=retry

local pg=player:WaitForChild("PlayerGui")
gui.Parent=pg
ReplicatedFirst:RemoveDefaultLoadingScreen()

local running=false
local function waitFor(parent,name,timeout)
 local value=parent:WaitForChild(name,timeout)
 assert(value,"Missing "..name)
 return value
end

local function attempt()
 if running then return end
 running=true
 retry.Visible=false
 status.Text="Carregando Suvivers…"

 local ok,err=pcall(function()
  local started=os.clock()
  while not game:IsLoaded() do
   assert(os.clock()-started<45,"initial replication timeout")
   task.wait(.1)
  end

  status.Text="Preparando lobby…" stage(.3)
  local lobby=waitFor(workspace,"JediLibrary",25)
  waitFor(workspace,"IslandSpawn",25)

  status.Text="Preparando partidas…" stage(.55)
  local survival=waitFor(RS,"Survival",25)
  local config=waitFor(RS,"SweanMenuConfig",25)
  local menuScene=waitFor(RS,"MenuSceneTemplate",25)
  assert(config:GetAttribute("GameName")=="Suvivers [ALFA]","Wrong game config")

  -- Preload only current Survivers content. Missing optional media never blocks entry.
  stage(.72)
  local loaded=0 local preloadDone=false
  local preloadThread=task.spawn(function()
   pcall(function()
    ContentProvider:PreloadAsync({lobby,menuScene,survival,title},function() loaded+=1 if status.Parent then status.Text="Preparando recursos • "..loaded end end)
   end)
   preloadDone=true
  end)
  local deadline=os.clock()+25
  while not preloadDone and os.clock()<deadline do
   task.wait(.1)
  end
  if not preloadDone then
   pcall(task.cancel,preloadThread)
  end

  status.Text="Pronto" stage(1)
  task.wait(.15)
 end)

 running=false
 if ok then
  player:SetAttribute("SweanLoadingDone",true)
  gui:Destroy()
 else
  warn("Survivers loading: "..tostring(err))
  status.Text="Não foi possível carregar o Suvivers. Tente novamente."
  retry.Visible=true
 end
end

retry.Activated:Connect(function()
 task.spawn(attempt)
end)

task.spawn(attempt)


