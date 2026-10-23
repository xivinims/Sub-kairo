local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local player=Players.LocalPlayer
local ui=script.Parent
local main=ui:WaitForChild("MenuPrincipal")
local scenes=ui:WaitForChild("Escenarios")
local credits=scenes:WaitForChild("MenuCreditos")
local settings=scenes:WaitForChild("MenuAjustes")
local transition=ui:WaitForChild("FrameDeTransicion")
local config=RS:WaitForChild("SweanMenuConfig")
local controls=nil
local inMenu=true
local state="main"
local busy=false
local low=game:GetService("UserInputService").TouchEnabled
local returnButton=ui:WaitForChild("ReturnToMenu")
local mode=settings.AjustesFrame:WaitForChild("QualityToggle")
local title=main:WaitForChild("IslandTitle")
local function visibility(container,value)
 for _,d in ipairs(container:GetDescendants()) do if d:IsA("GuiObject") then d.Visible=value end end
end
local function show(name)
 state=name
 visibility(main,name=="main")
 visibility(credits,name=="credits")
 visibility(settings,name=="settings")
 -- Original logo remains part of the imported design.
 returnButton.Visible=not inMenu
end
local function layout()
 local camera=workspace.CurrentCamera if not camera then return end
 local viewport=camera.ViewportSize
 local w,h=viewport.X,viewport.Y
 local panelWidth=math.min(320,w*.86)
 local x=w-panelWidth-12
 local buttonHeight=math.clamp(h*.10,38,48)
 local logoHeight=math.clamp(h*.22,40,120)
 main.Frame.Position=UDim2.fromOffset(x-12,0)
 main.Frame.Size=UDim2.fromOffset(panelWidth+24,h)
 main.Frame.ZIndex=1
 main.Logo.Position=UDim2.fromOffset(x+16,12)
 main.Logo.Size=UDim2.fromOffset(panelWidth-32,logoHeight)
 main.Logo.ScaleType=Enum.ScaleType.Fit main.Logo.ZIndex=2
 title.Position=UDim2.fromOffset(x+16,logoHeight+16)
 title.Size=UDim2.fromOffset(panelWidth-32,30)
 local top=logoHeight+56
 for i,name in ipairs({"Play","Ajustes","Creditos"}) do
  local b=main[name]
  b.AnchorPoint=Vector2.zero
  b.Position=UDim2.fromOffset(x+16,top+(i-1)*(buttonHeight+8))
  b.Size=UDim2.fromOffset(panelWidth-32,buttonHeight)
  b.ZIndex=3
 end
 for _,scene in ipairs({credits,settings}) do
  local panel=scene:FindFirstChild("CreditosFrame") or scene:FindFirstChild("AjustesFrame")
  local pw=math.min(560,w-32) local ph=math.min(300,h-104)
  panel.AnchorPoint=Vector2.new(.5,.5)
  panel.Position=UDim2.fromScale(.5,.55) panel.Size=UDim2.fromOffset(pw,ph)
  panel.ZIndex=3
  scene.Tittle.AnchorPoint=Vector2.new(.5,1)
  scene.Tittle.Position=UDim2.new(.5,0,.55,-ph/2-8)
  scene.Tittle.Size=UDim2.fromOffset(pw-56,38)
  scene.Tittle.ZIndex=3
  scene.Tittle.TittleText.Position=UDim2.fromScale(0,0)
  scene.Tittle.TittleText.Size=UDim2.fromScale(1,1)
  scene.Tittle.TittleText.ZIndex=4
  scene.Close.AnchorPoint=Vector2.new(1,1)
  scene.Close.Position=UDim2.new(.5,pw/2,.55,-ph/2-8)
  scene.Close.Size=UDim2.fromOffset(44,38) scene.Close.ZIndex=5
 end
end
local function sound(name)
 local sounds=ui:FindFirstChild("Sonidos")
 local s=sounds and sounds:FindFirstChild(name)
 if s and s:IsA("Sound") then s:Play() end
end
local function setQuality()
 for _,e in ipairs(Lighting:GetChildren()) do
  if e:GetAttribute("SourceAssetId")==86563808574363 and
   (e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect")) then
   e.Enabled=not low and e:GetAttribute("OriginalEnabled")~=false
  end
 end
 mode.Text=low and "Gráficos: leve" or "Gráficos: completo"
end
local function bindCamera()
 RunService:UnbindFromRenderStep("SweanMenuCamera")
 RunService:BindToRenderStep("SweanMenuCamera",Enum.RenderPriority.Camera.Value+1,function()
  if not inMenu then return end
  local camera=workspace.CurrentCamera if not camera then return end
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=config:GetAttribute(state=="credits" and "CreditsCamera" or state=="settings" and "SettingsCamera" or "MainCamera")
 end)
end
local function open()
 inMenu=true
 if controls then controls:Disable() end
 bindCamera() show("main") layout()
end
local function close()
 inMenu=false
 RunService:UnbindFromRenderStep("SweanMenuCamera")
 local camera=workspace.CurrentCamera
 if camera then
  camera.CameraType=Enum.CameraType.Custom
  local char=player.Character
  local humanoid=char and char:FindFirstChildOfClass("Humanoid")
  if humanoid then camera.CameraSubject=humanoid end
 end
 if controls then controls:Enable() end
 show("playing")
end
local function navigate(action)
 if busy then return end busy=true
 sound("Click")
 transition.Visible=true
 local fade=TweenService:Create(transition,TweenInfo.new(.18),{BackgroundTransparency=0})
 fade:Play() fade.Completed:Wait()
 action()
 fade=TweenService:Create(transition,TweenInfo.new(.18),{BackgroundTransparency=1})
 fade:Play() fade.Completed:Wait()
 transition.Visible=false busy=false
end
main.Play.Activated:Connect(function() navigate(close) end)
main.Ajustes.Activated:Connect(function() navigate(function() show("settings") end) end)
main.Creditos.Activated:Connect(function() navigate(function() show("credits") end) end)
settings.Close.Activated:Connect(function() navigate(function() show("main") end) end)
credits.Close.Activated:Connect(function() navigate(function() show("main") end) end)
returnButton.Activated:Connect(function() navigate(open) end)
mode.Activated:Connect(function() low=not low setQuality() end)
player.CharacterAdded:Connect(function(char)
 local h=char:WaitForChild("Humanoid",10)
 if not inMenu and h and workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject=h end
end)
local cameraConnection
local function connectCamera()
 if cameraConnection then cameraConnection:Disconnect() end
 if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
 layout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera)
connectCamera()
setQuality()
show("loading")
bindCamera()
-- PlayerModule may arrive late; UI never blocks on it.
task.spawn(function()
 local ps=player:WaitForChild("PlayerScripts",10)
 local pm=ps and ps:WaitForChild("PlayerModule",10)
 if pm then
  local ok,m=pcall(require,pm)
  if ok then controls=m:GetControls() if inMenu then controls:Disable() end end
 end
end)
local start=os.clock()
while not player:GetAttribute("SweanLoadingDone") and os.clock()-start<12 do task.wait(.1) end
open()
