local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local ui=script.Parent
local main=ui:WaitForChild("MenuPrincipal")
local scenes=ui:WaitForChild("Escenarios")
local credits=scenes:WaitForChild("MenuCreditos")
local settings=scenes:WaitForChild("MenuAjustes")
local transition=ui:WaitForChild("FrameDeTransicion")
local config=RS:WaitForChild("SweanMenuConfig")
local returnButton=ui:WaitForChild("ReturnToMenu")
local creditsButton=ui:WaitForChild("CreditsButton")
local low=UIS.TouchEnabled
local controls=nil
local inMenu=true
local busy=false
local menuScene=nil
local menuAvatar=nil
local menuCameraCF=nil
local oldFov=70
local MENU_ORIGIN=config:GetAttribute("MenuOrigin") or Vector3.new(10000,2500,10000)

player:SetAttribute("InMenu",true)

local function clearPrivateScene()
 if menuAvatar then menuAvatar:Destroy() menuAvatar=nil end
 if menuScene then menuScene:Destroy() menuScene=nil end
 menuCameraCF=nil
end

local function horizontal(v)
 local h=Vector3.new(v.X,0,v.Z)
 return h.Magnitude>.01 and h.Unit or Vector3.new(0,0,-1)
end

local function chooseFloor(scene)
 local cf,size=scene:GetBoundingBox()
 local bottom=cf.Position.Y-size.Y/2
 local best,bestScore=nil,-math.huge
 for _,p in ipairs(scene:GetDescendants()) do
  if p:IsA("BasePart") and p.Transparency<.98 and p.CFrame.UpVector.Y>.82 and p.Size.X>=7 and p.Size.Z>=7 then
   local top=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0))
   local height=top.Y-bottom
   if height<size.Y*.62 then
    local score=p.Size.X*p.Size.Z-height*2-(Vector2.new(top.X-cf.Position.X,top.Z-cf.Position.Z).Magnitude*.4)
    if score>bestScore then best,bestScore=p,score end
   end
  end
 end
 return best,cf,size
end

local function buildPrivateScene()
 clearPrivateScene()
 local template=RS:WaitForChild("MenuSceneTemplate")
 menuScene=template:Clone()
 menuScene.Name="LocalMenuScene"
 menuScene.Parent=workspace
 local rotation=menuScene:GetPivot().Rotation
 menuScene:PivotTo(CFrame.new(MENU_ORIGIN)*rotation)

 local floor,cf,size=chooseFloor(menuScene)
 local base
 local forward
 local right
 if floor then
  base=floor.CFrame:PointToWorldSpace(Vector3.new(0,floor.Size.Y/2+.08,0))
  forward=horizontal(floor.CFrame.LookVector)
  right=horizontal(floor.CFrame.RightVector)
 else
  base=Vector3.new(cf.Position.X,cf.Position.Y-size.Y*.35,cf.Position.Z)
  forward=horizontal(rotation.LookVector)
  right=horizontal(rotation.RightVector)
 end

 local forwardRoom=floor and math.max(6,floor.Size.Z*.5-2) or math.max(8,size.Z*.25)
 local rightRoom=floor and math.max(6,floor.Size.X*.5-2) or math.max(8,size.X*.25)
 local cameraPos=base-forward*math.min(7.5,forwardRoom*.42)-right*math.min(1.5,rightRoom*.10)+Vector3.new(0,4.4,0)
 local focus=base+forward*math.min(3.4,forwardRoom*.20)+Vector3.new(0,3.0,0)
 menuCameraCF=CFrame.lookAt(cameraPos,focus)

 local candidate=base+forward*math.min(2.8,forwardRoom*.18)+right*math.min(4.2,rightRoom*.32)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={menuScene}
 local hit=workspace:Raycast(candidate+Vector3.new(0,18,0),Vector3.new(0,-36,0),params)
 local avatarFloor=hit and hit.Position or candidate
 local avatarPos=avatarFloor+Vector3.new(0,3.05,0)

 local char=player.Character
 if char then
  local archivable=char.Archivable char.Archivable=true
  menuAvatar=char:Clone() char.Archivable=archivable
  if menuAvatar then
   menuAvatar.Name="LocalMenuAvatar"
   for _,d in ipairs(menuAvatar:GetDescendants()) do
    if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Tool") then d:Destroy()
    elseif d:IsA("BasePart") then d.Anchored=true d.CanCollide=false d.CanTouch=false d.CanQuery=false end
   end
   local hum=menuAvatar:FindFirstChildOfClass("Humanoid")
   if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.AutoRotate=false end
   menuAvatar.Parent=workspace
   menuAvatar:PivotTo(CFrame.lookAt(avatarPos,Vector3.new(cameraPos.X,avatarPos.Y,cameraPos.Z)))
  end
 end
end

local switches={
 {"NametagsToggle","ShowNametags","Nomes"},
 {"SoundToggle","MenuSounds","Sons"},
 {"MusicToggle","MusicEnabled","Música"},
 {"FriendsToggle","FriendAlerts","Amigos"}
}
for _,setting in ipairs(switches) do
 if player:GetAttribute(setting[2])==nil then player:SetAttribute(setting[2],true) end
 local b=settings.AjustesFrame.Controls:WaitForChild(setting[1])
 local function refresh() b.Text=setting[3].."  "..(player:GetAttribute(setting[2]) and "ON" or "OFF") end
 refresh()
 b.Activated:Connect(function() player:SetAttribute(setting[2],not player:GetAttribute(setting[2])) refresh() end)
end

local quality=settings.AjustesFrame.Controls:WaitForChild("QualityToggle")
local function setQuality()
 quality.Text="Gráficos  "..(low and "LEVE" or "COMPLETO")
 for _,e in ipairs(Lighting:GetChildren()) do
  if e:IsA("PostEffect") then e.Enabled=not low end
 end
end
quality.Activated:Connect(function() low=not low setQuality() end)

for _,b in ipairs(ui:GetDescendants()) do
 if b:IsA("TextButton") then
  local scale=Instance.new("UIScale") scale.Parent=b
  local tween
  local function pulse(v)
   if tween then tween:Cancel() end
   tween=TweenService:Create(scale,TweenInfo.new(.09,Enum.EasingStyle.Quad),{Scale=v}) tween:Play()
  end
  b.MouseEnter:Connect(function() pulse(1.018) end)
  b.MouseLeave:Connect(function() pulse(1) end)
  b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pulse(.965) end end)
  b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pulse(1) end end)
  b.Activated:Connect(function()
   local click=ui.Sonidos:FindFirstChild("Click")
   if click and player:GetAttribute("MenuSounds")~=false then click:Stop() click:Play() end
  end)
 end
end

local function layout()
 local camera=workspace.CurrentCamera if not camera then return end
 local v=camera.ViewportSize local w,h=v.X,v.Y
 local panelW=math.clamp(w*.30,220,340)
 local x=math.clamp(w*.035,14,42)
 local top=math.clamp(h*.07,18,48)
 local logoH=math.clamp(h*.18,78,128)
 local buttonH=math.clamp(h*.07,42,52)

 main.LeftPanel.Position=UDim2.fromOffset(x,top)
 main.LeftPanel.Size=UDim2.fromOffset(panelW,math.min(h-top-20,logoH+buttonH*3+74))

 main.Logo.Position=UDim2.fromOffset(x+18,top+12)
 main.Logo.Size=UDim2.fromOffset(panelW-36,logoH)
 main.GameName.Position=UDim2.fromOffset(x+24,top+22)
 main.GameName.Size=UDim2.fromOffset(panelW-48,math.max(48,logoH-16))
 main.GameName.TextSize=math.clamp(panelW*.12,28,42)

 local y=top+logoH+28
 for i,b in ipairs({main.Play,main.Ajustes}) do
  b.Position=UDim2.fromOffset(x+18,y+(i-1)*(buttonH+10))
  b.Size=UDim2.fromOffset(panelW-36,buttonH)
 end

 creditsButton.Position=UDim2.new(1,-64,0,64) creditsButton.Size=UDim2.fromOffset(48,48) creditsButton.Text="i" creditsButton.TextSize=24
 returnButton.Position=UDim2.fromOffset(16,70)
 returnButton.Size=UDim2.fromOffset(40,40) returnButton.TextSize=23

 for _,scene in ipairs({settings,credits}) do
  local body=scene:FindFirstChild("AjustesFrame") or scene:FindFirstChild("CreditosFrame")
  local title=scene.Tittle
  local pw=math.min(520,w-32) local ph=math.min(360,h-110)
  body.Position=UDim2.new(.5,-pw/2,.5,-ph/2+18) body.Size=UDim2.fromOffset(pw,ph)
  title.Position=UDim2.new(.5,-pw/2,.5,-ph/2-28) title.Size=UDim2.fromOffset(pw-54,42)
  title.TittleText.Size=UDim2.fromScale(1,1)
  scene.Close.Position=UDim2.new(.5,pw/2-44,.5,-ph/2-28) scene.Close.Size=UDim2.fromOffset(44,42)
 end
 settings.AjustesFrame.Controls.Position=UDim2.fromOffset(18,18)
 settings.AjustesFrame.Controls.Size=UDim2.new(1,-36,1,-36)
 credits.CreditosFrame.TextCreditos.Size=UDim2.fromScale(1,1)
end

local function show(name)
 main.Visible=name=="main"
 settings.Visible=name=="settings"
 credits.Visible=name=="credits"
 creditsButton.Visible=inMenu and name=="main"
 returnButton.Visible=not inMenu and not player:GetAttribute("InRound") and not player:GetAttribute("Spectating")
end

local function bindCamera()
 RunService:UnbindFromRenderStep("SurviversMenuCamera")
 RunService:BindToRenderStep("SurviversMenuCamera",Enum.RenderPriority.Camera.Value+2,function()
  if not inMenu or player:GetAttribute("VoidActive") then return end
  local camera=workspace.CurrentCamera if not camera then return end
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=56
  if menuCameraCF then camera.CFrame=menuCameraCF end
 end)
end

local function open()
 if player:GetAttribute("InRound") or player:GetAttribute("Spectating") then return end
 inMenu=true player:SetAttribute("InMenu",true)
 if controls then controls:Disable() end
 local camera=workspace.CurrentCamera if camera then oldFov=camera.FieldOfView end
 buildPrivateScene()
 bindCamera()
 show("main")
 layout()
end

local function close()
 inMenu=false player:SetAttribute("InMenu",false)
 RunService:UnbindFromRenderStep("SurviversMenuCamera")
 clearPrivateScene()
 local camera=workspace.CurrentCamera
 if camera then
  camera.CameraType=Enum.CameraType.Custom camera.FieldOfView=oldFov
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum then camera.CameraSubject=hum end
 end
 if controls and not player:GetAttribute("VoidActive") then controls:Enable() end
 show("playing")
end

local function navigate(fn)
 if busy then return end busy=true
 transition.Visible=true
 local a=TweenService:Create(transition,TweenInfo.new(.12),{BackgroundTransparency=0}) a:Play() a.Completed:Wait()
 fn()
 local b=TweenService:Create(transition,TweenInfo.new(.16),{BackgroundTransparency=1}) b:Play() b.Completed:Wait()
 transition.Visible=false busy=false
end

main.Play.Activated:Connect(function() navigate(close) end)
main.Ajustes.Activated:Connect(function() navigate(function() show("settings") end) end)
creditsButton.Activated:Connect(function() navigate(function() show("credits") end) end)
settings.Close.Activated:Connect(function() navigate(function() show("main") end) end)
credits.Close.Activated:Connect(function() navigate(function() show("main") end) end)
returnButton.Activated:Connect(function() navigate(open) end)

player.CharacterAdded:Connect(function(char)
 if inMenu then task.defer(buildPrivateScene) end
end)

local cameraConn
local function watchCamera()
 if cameraConn then cameraConn:Disconnect() end
 if workspace.CurrentCamera then cameraConn=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
 layout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
setQuality()
show("loading")
bindCamera()

task.spawn(function()
 local ps=player:WaitForChild("PlayerScripts",10)
 local pm=ps and ps:WaitForChild("PlayerModule",10)
 if pm then
  local ok,m=pcall(require,pm)
  if ok then controls=m:GetControls() if inMenu then controls:Disable() end end
 end
end)

while not player:GetAttribute("SweanLoadingDone") do task.wait(.1) end
open()

local function refreshReturn()
 returnButton.Visible=not inMenu and not player:GetAttribute("InRound") and not player:GetAttribute("Spectating")
end
player:GetAttributeChangedSignal("InRound"):Connect(refreshReturn)
player:GetAttributeChangedSignal("Spectating"):Connect(refreshReturn)
