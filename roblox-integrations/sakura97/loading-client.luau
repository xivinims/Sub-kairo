local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RS=game:GetService("ReplicatedStorage")
local ContentProvider=game:GetService("ContentProvider")
local player=Players.LocalPlayer
player:SetAttribute("SweanLoadingDone",false)
local gui=Instance.new("ScreenGui") gui.Name="SweanLoading" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=1000
local frame=Instance.new("Frame") frame.Size=UDim2.fromScale(1,1) frame.BackgroundColor3=Color3.fromRGB(17,17,20) frame.Parent=gui
local logo=Instance.new("ImageLabel") logo.Name="BrandLogo" logo.Image="rbxassetid://89648072626653" logo.ScaleType=Enum.ScaleType.Fit
logo.BackgroundTransparency=1 logo.AnchorPoint=Vector2.new(.5,.5) logo.Position=UDim2.fromScale(.5,.40) logo.Size=UDim2.fromScale(.72,.28) logo.Parent=frame
local status=Instance.new("TextLabel") status.BackgroundTransparency=1 status.AnchorPoint=Vector2.new(.5,.5)
status.Position=UDim2.fromScale(.5,.61) status.Size=UDim2.new(.86,0,0,60) status.TextWrapped=true
status.Font=Enum.Font.GothamMedium status.TextColor3=Color3.fromRGB(220,220,226) status.TextSize=16 status.Text="Carregando a ilha…" status.Parent=frame
local retry=Instance.new("TextButton") retry.Text="Tentar novamente" retry.Font=Enum.Font.GothamMedium retry.TextSize=16
retry.AnchorPoint=Vector2.new(.5,.5) retry.Position=UDim2.fromScale(.5,.76) retry.Size=UDim2.fromOffset(200,46)
retry.BackgroundColor3=Color3.fromRGB(46,46,50) retry.BackgroundTransparency=.3 retry.TextColor3=Color3.new(1,1,1) retry.Visible=false retry.Parent=frame
local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,14) corner.Parent=retry
local pg=player:WaitForChild("PlayerGui") gui.Parent=pg ReplicatedFirst:RemoveDefaultLoadingScreen()
local running=false
local function attempt()
 if running then return end running=true retry.Visible=false
 local started=os.clock()
 local ok,err=pcall(function()
  status.Text="Recebendo o mapa completo…"
  while not game:IsLoaded() do
   if os.clock()-started>45 then error("initial replication timeout") end task.wait(.1)
  end
  local function required(parent,name)
   local value=parent:WaitForChild(name,20) assert(value,"Missing "..name) return value
  end
  local roots={required(workspace,"FloatingIsland"),required(workspace,"BigCenterTree"),required(workspace,"MysticalSpawn"),required(RS,"GrassWindTemplate"),game:GetService("Lighting")}
  required(workspace,"IslandSpawn") required(RS,"SweanMenuConfig")
  local coverage=required(workspace,"SkinnedGrassCoverage")
  local completed=0 local failures={} local done=false local preloadOk,preloadError
  local pending=task.spawn(function()
   preloadOk,preloadError=pcall(function()
    ContentProvider:PreloadAsync(roots,function(id,result)
     completed+=1
     if result~=Enum.AssetFetchStatus.Success then failures[#failures+1]=id end
     if gui.Parent then status.Text="Carregando mapa, árvore e grama… "..completed end
    end)
   end)
   done=true
  end)
  local slowAt=os.clock()+40
  while not done do
   if os.clock()>slowAt+35 then pcall(task.cancel,pending) error("Map loading timeout") end
   if os.clock()>slowAt then status.Text="A conexão está demorando. Ainda carregando o mapa…" end
   task.wait(.1)
  end
  assert(preloadOk,tostring(preloadError)) assert(#failures==0,"Map assets unavailable: "..#failures)
  -- Audio permissions or logo moderation must not lock access to an otherwise loaded map.
  status.Text="Preparando interface e sons…"
  local optionalFailures=0
  local media=required(RS,"XNMedia")
  local optionalDone=false
  local optionalThread=task.spawn(function()
   local optionalOk=pcall(function() ContentProvider:PreloadAsync({logo,media},function(_,result)
    if result~=Enum.AssetFetchStatus.Success then optionalFailures+=1 end
   end) end)
   if not optionalOk then optionalFailures+=1 end
   optionalDone=true
  end)
  local optionalDeadline=os.clock()+20
  while not optionalDone and os.clock()<optionalDeadline do task.wait(.1) end
  if not optionalDone then optionalFailures+=1 pcall(task.cancel,optionalThread) end
  player:SetAttribute("OptionalMediaFailures",optionalFailures)
  status.Text="Preparando a grama…"
  local grassStart=os.clock()
  while not coverage:GetAttribute("InitialGrassReady") do
   assert(os.clock()-grassStart<30,"Initial grass timeout") task.wait(.1)
  end
 end)
 running=false
 if ok then
  player:SetAttribute("SweanLoadingDone",true) gui:Destroy()
 else
  warn("XN loading: "..tostring(err))
  status.Text="Não foi possível carregar o mapa. Confira sua conexão e tente novamente."
  retry.Visible=true
 end
end
retry.Activated:Connect(function()
 local media=RS:FindFirstChild("XNMedia")
 if media and player:GetAttribute("MenuSounds")~=false then
  local click=media.MenuClick:Clone() click.Parent=game:GetService("SoundService") click:Play() game:GetService("Debris"):AddItem(click,3)
 end
 task.spawn(attempt)
end)
task.spawn(attempt)
