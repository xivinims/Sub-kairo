-- Cinematic R6 main menu matching user reference:
-- checkerboard 3D scene, clear slanted menu rows, glass panels, pink X,
-- practical settings, loading transition, respawn and return-to-menu.
local Players=game:GetService("Players")
local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local UserInput=game:GetService("UserInputService")
local Replicated=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local remote=Replicated:WaitForChild("R6MenuRespawn")
local gui=Instance.new("ScreenGui")
gui.Name="R6CinematicUI"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=80
gui.Parent=pg
local function new(class,parent,properties)
 local item=Instance.new(class)
 for key,value in pairs(properties or {}) do item[key]=value end
 item.Parent=parent
 return item
end
local WHITE=Color3.fromRGB(242,246,255)
local PINK=Color3.fromRGB(255,31,169)
local DARK=Color3.fromRGB(3,8,24)
local BLUE=Color3.fromRGB(37,89,148)
local function curve(frame,r)
 return new("UICorner",frame,{CornerRadius=UDim.new(0,r)})
end
local function border(frame,color,width,alpha)
 return new("UIStroke",frame,{Color=color or WHITE,Thickness=width or 1,
  Transparency=alpha or 0.25,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
local function label(parent,text,size,pos,dim,font,alignment)
 return new("TextLabel",parent,{
  Text=text,Font=font or Enum.Font.Gotham,TextSize=size,TextColor3=WHITE,
  BackgroundTransparency=1,TextXAlignment=alignment or Enum.TextXAlignment.Left,
  TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true,
  Position=pos,Size=dim,
 })
end
local vignette=new("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=DARK,BackgroundTransparency=0.72,BorderSizePixel=0})
new("UIGradient",vignette,{Rotation=90,Transparency=NumberSequence.new({
 NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(0.52,0.75),
 NumberSequenceKeypoint.new(1,0.16)})})
local scene=nil
local sceneCenter=Vector3.new(1200,1000,1800)
local originalClock=Lighting.ClockTime
local originalBrightness=Lighting.Brightness
local sceneLight=nil
local function checker(part,columns,rows,face)
 local surface=new("SurfaceGui",part,{
  Face=face,CanvasSize=Vector2.new(384,384),LightInfluence=0,
  AlwaysOnTop=false,Brightness=1,ClipsDescendants=true})
 for row=0,rows-1 do
  for col=0,columns-1 do
   if (row+col)%2==0 then
    new("Frame",surface,{Size=UDim2.fromScale(1/columns,1/rows),
     Position=UDim2.fromScale(col/columns,row/rows),BorderSizePixel=0,
     BackgroundColor3=Color3.fromRGB(5,25,61)})
   end
  end
 end
end
local function addPart(parent,name,size,offset,color,material)
 return new("Part",parent,{Name=name,Size=size,CFrame=CFrame.new(sceneCenter+offset),
  Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
  CastShadow=false,Color=color,Material=material or Enum.Material.SmoothPlastic})
end
local function makeScene()
 if scene then return end
 scene=new("Model",workspace,{Name="ClientOnlyMenuWorld"})
 local floor=addPart(scene,"CheckerFloor",Vector3.new(156,1,142),
  Vector3.new(0,-5,0),Color3.fromRGB(202,230,248))
 checker(floor,16,16,Enum.NormalId.Top)
 local water=addPart(scene,"ShimmerWater",Vector3.new(22,0.15,122),
  Vector3.new(0,-4.4,0),Color3.fromRGB(87,179,243),Enum.Material.Glass)
 water.Transparency=0.22
 local function tower(x,z,w,h)
  local pillar=addPart(scene,"CheckerTower",Vector3.new(w,h,w),
      Vector3.new(x,h/2-5,z),Color3.fromRGB(163,208,244))
  checker(pillar,10,12,Enum.NormalId.Front)
  local side=addPart(scene,"SideShade",Vector3.new(0.06,h,w),
    Vector3.new(x+w/2,h/2-5,z),Color3.fromRGB(27,75,121))
  side.Transparency=0.25
 end
 tower(-48,-18,18,48)
 tower(49,-21,22,54)
 tower(-77,-42,18,73)
 tower(78,-55,19,72)
 tower(-25,-88,16,43)
 tower(31,-79,22,38)
 local sky=addPart(scene,"SkyBackdrop",Vector3.new(190,105,1),
  Vector3.new(0,37,-115),Color3.fromRGB(147,212,251),Enum.Material.Neon)
 sky.Transparency=0.17
 local glow=new("PointLight",water,{Brightness=2.0,Range=110,
  Color=Color3.fromRGB(137,210,255),Shadows=false})
 sceneLight=glow
end
local controls=nil
local function getControls()
 if controls then return controls end
 local ok,result=pcall(function()
  return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
 end)
 if ok then controls=result end
 return controls
end
local hidden={}
local function hideGameplay()
 for _,item in ipairs(pg:GetChildren()) do
  if item~=gui and item:IsA("ScreenGui") and item.Enabled then
   hidden[item]=true
   item.Enabled=false
  end
 end
 local c=getControls();if c then pcall(function()c:Disable()end) end
end
local function restoreGameplay()
 for item in pairs(hidden) do
  if item.Parent then item.Enabled=true end
  hidden[item]=nil
 end
 local c=getControls();if c then pcall(function()c:Enable()end) end
end
local frameRoot=new("Frame",gui,{
 AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.53),
 Size=UDim2.fromOffset(520,390),BackgroundTransparency=1})
local scale=new("UIScale",frameRoot,{Scale=1})
local pages={}
local function pane(name,w,h)
 local frame=new("Frame",frameRoot,{Name=name,AnchorPoint=Vector2.new(0.5,0.5),
  Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(w,h),
  BackgroundTransparency=0.25,BackgroundColor3=Color3.fromRGB(2,7,24),
  Visible=false,BorderSizePixel=0})
 border(frame,Color3.fromRGB(207,235,255),1,0.31)
 new("UIGradient",frame,{Rotation=9,Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,0.56),NumberSequenceKeypoint.new(.65,.21),
  NumberSequenceKeypoint.new(1,.3)})})
 pages[name]=frame
 return frame
end
local function showPage(name)
 for id,frame in pairs(pages) do
  frame.Visible=(name==id)
 end
end
local main=pane("Home",430,356)
main.BackgroundTransparency=1
main:FindFirstChildOfClass("UIStroke"):Destroy()
label(main,"R6  SIMULATION",40,UDim2.fromOffset(22,1),UDim2.new(1,-30,0,52),
 Enum.Font.GothamBold)
label(main,"M E N U",15,UDim2.fromOffset(120,59),UDim2.new(1,-150,0,24),
 Enum.Font.GothamMedium)
local function menuRow(textValue,icon,y,click)
 local wrap=new("Frame",main,{Name=textValue,
  Position=UDim2.fromOffset(31,y),Size=UDim2.fromOffset(380,56),
  BackgroundTransparency=1})
 local symbol=new("TextButton",wrap,{Name="Symbol",Text=icon,
  Size=UDim2.fromOffset(53,49),BackgroundColor3=Color3.fromRGB(12,33,62),
  BackgroundTransparency=0.35,BorderSizePixel=0,TextColor3=WHITE,
  Font=Enum.Font.GothamBold,TextSize=29,AutoButtonColor=false})
 border(symbol,WHITE,1,0.23)
 local action=new("TextButton",wrap,{
  Name="Action",Position=UDim2.fromOffset(61,3),Size=UDim2.fromOffset(316,43),
  Text=textValue,Font=Enum.Font.Gotham,TextSize=24,
  TextColor3=WHITE,TextXAlignment=Enum.TextXAlignment.Center,
  AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(20,59,110),
  BackgroundTransparency=0.43,BorderSizePixel=0})
 new("UIGradient",action,{Rotation=0,Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,0.27),NumberSequenceKeypoint.new(1,0.73)})})
 border(action,Color3.fromRGB(234,248,255),0.8,0.43)
 local function activate() click() end
 action.Activated:Connect(activate)
 symbol.Activated:Connect(activate)
 for _,button in ipairs({action,symbol}) do
  button.MouseEnter:Connect(function()
   Tween:Create(button,TweenInfo.new(0.15),{BackgroundTransparency=0.12}):Play()
  end)
  button.MouseLeave:Connect(function()
   Tween:Create(button,TweenInfo.new(0.16),{BackgroundTransparency=(button==action and .43 or .35)}):Play()
  end)
 end
 return wrap
end
local settings=pane("Settings",480,342)
local credit=pane("Credits",492,340)
local log=pane("Update",497,354)
local function panelHead(frame,title)
 label(frame,title,21,UDim2.fromOffset(14,7),UDim2.fromOffset(380,36),
  Enum.Font.Gotham)
 new("Frame",frame,{Position=UDim2.fromOffset(14,43),
  Size=UDim2.new(1,-27,0,1),BackgroundColor3=WHITE,
  BackgroundTransparency=0.27,BorderSizePixel=0})
 local close=new("TextButton",frame,{Name="Close",AnchorPoint=Vector2.new(1,0),
  Position=UDim2.new(1,-7,0,0),Size=UDim2.fromOffset(42,42),Text="×",
  Font=Enum.Font.GothamBold,TextSize=29,TextColor3=WHITE,
  BackgroundColor3=PINK,AutoButtonColor=false,BorderSizePixel=0})
 curve(close,21)
 border(close,WHITE,1,.23)
 close.Activated:Connect(function()showPage("Home")end)
end
panelHead(settings,"SETTINGS")
panelHead(credit,"CREDITS")
panelHead(log,"UPDATE LOG")
local options={banking=true,tilt=true,quality=true,glow=true,bob=true,dof=false,volume=50}
local dof=new("DepthOfFieldEffect",Lighting,{Name="ClientMenuDOF",Enabled=false,
 InFocusRadius=42,FocusDistance=18,NearIntensity=0.1,FarIntensity=0.14})
local recordedAudio=setmetatable({},{__mode="k"})
local function applyVolume()
 local value=options.volume/100
 for _,root in ipairs({SoundService,workspace}) do
  for _,item in ipairs(root:GetDescendants()) do
   if item:IsA("Sound") then
    if recordedAudio[item]==nil then recordedAudio[item]=item.Volume end
    item.Volume=recordedAudio[item]*value
   end
  end
 end
end
local function settingsRow(title,index,kind,get,set)
 local y=55+(index-1)*38
 local row=new("Frame",settings,{Size=UDim2.new(1,-34,0,32),
  Position=UDim2.fromOffset(17,y),BackgroundTransparency=.45,
  BackgroundColor3=Color3.fromRGB(0,0,3),BorderSizePixel=0})
 curve(row,16);border(row,WHITE,0.8,0.53)
 label(row,title,13,UDim2.fromOffset(13,0),
  UDim2.new(1,-125,1,0),Enum.Font.GothamMedium)
 local action=new("TextButton",row,{
  AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-5,.5,0),
  Size=UDim2.fromOffset(kind=="volume" and 84 or 43,25),
  Text="",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=WHITE,
  BackgroundTransparency=.22,BackgroundColor3=Color3.fromRGB(23,30,44),
  BorderSizePixel=0,AutoButtonColor=false})
 curve(action,12);border(action,WHITE,.8,.35)
 local function redraw()
  if kind=="volume" then action.Text="‹   "..tostring(get()).."   ›"
  else
   local enabled=get()
   action.Text=enabled and "●" or "○"
   action.TextColor3=enabled and Color3.fromRGB(245,250,255)
     or Color3.fromRGB(126,153,185)
   action.BackgroundColor3=enabled and Color3.fromRGB(92,113,121)
     or Color3.fromRGB(21,29,42)
  end
 end
 action.Activated:Connect(function()
  if kind=="volume" then set((get()+10)%110)
  else set(not get()) end
  redraw()
 end)
 redraw()
end
settingsRow("Camera Banking",1,"toggle",function()return options.banking end,
 function(v)options.banking=v end)
settingsRow("Camera Tilt",2,"toggle",function()return options.tilt end,
 function(v)options.tilt=v end)
settingsRow("High Quality Graphics",3,"toggle",function()return options.quality end,
 function(v)options.quality=v;Lighting.GlobalShadows=v end)
settingsRow("Music Volume",4,"volume",function()return options.volume end,
 function(v)options.volume=v;applyVolume()end)
settingsRow("Neon Glow Pulse",5,"toggle",function()return options.glow end,
 function(v)options.glow=v end)
settingsRow("Panel Bob",6,"toggle",function()return options.bob end,
 function(v)options.bob=v end)
settingsRow("Realistic DOF",7,"toggle",function()return options.dof end,
 function(v)options.dof=v;dof.Enabled=v end)
local blackPill=new("Frame",credit,{Position=UDim2.fromOffset(28,61),
 Size=UDim2.new(1,-56,0,38),BackgroundColor3=Color3.fromRGB(0,0,4),
 BackgroundTransparency=.05,BorderSizePixel=0})
curve(blackPill,19)
label(blackPill,"R6 TEST  •  AURIVANE WORKS",17,
 UDim2.fromOffset(8,1),UDim2.new(1,-16,1,-2),Enum.Font.Gotham,
 Enum.TextXAlignment.Center)
label(credit,"Chakra e Boogie: recursos dos modelos originais.",14,
 UDim2.fromOffset(27,114),UDim2.new(1,-54,0,70),Enum.Font.Gotham,
 Enum.TextXAlignment.Center)
label(credit,"Menu recriado a partir da referência enviada.",13,
 UDim2.fromOffset(27,207),UDim2.new(1,-54,0,30),Enum.Font.Gotham,
 Enum.TextXAlignment.Center)
local scroll=new("ScrollingFrame",log,{
 Position=UDim2.fromOffset(13,50),Size=UDim2.new(1,-26,1,-64),
 ScrollBarThickness=3,BackgroundColor3=Color3.fromRGB(0,5,30),
 BackgroundTransparency=.36,BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,420)})
curve(scroll,11);border(scroll,WHITE,0.7,0.55)
label(scroll,"Update Log",34,UDim2.fromOffset(23,4),UDim2.new(1,-46,0,44),
 Enum.Font.Gotham,Enum.TextXAlignment.Center)
label(scroll,"v1.2.0   •   CINEMATIC R6",14,UDim2.fromOffset(20,53),
 UDim2.new(1,-40,0,26),Enum.Font.GothamMedium)
label(scroll,"• Menu 3D com câmera dinâmica e xadrez azul\n• Configurações interativas\n• Tela de morte e retorno ao menu\n• NPCs R6 andando pela arena\n• Chakra nos pés e Boogie Woogie\n• Animação R6 de corrida verificável\n• Compatibilidade com celular e computador",14,
 UDim2.fromOffset(20,89),UDim2.new(1,-40,0,227))
local busy=false
local menu=false
local renderConn=nil
local camPose=Instance.new("CFrameValue")
local sceneCamOffset=0
local function cameraFor(page)
 local offset=page=="Settings" and 4 or page=="Credits" and -4 or page=="Update" and 3 or 0
 local focus=sceneCenter+Vector3.new(offset*1.1,6,-40)
 return CFrame.lookAt(sceneCenter+Vector3.new(offset,13,35),focus)
end
local activePage="Home"
local function navigate(name)
 if busy or not menu then return end
 activePage=name
 showPage(name)
 Tween:Create(camPose,TweenInfo.new(0.7,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),
  {Value=cameraFor(name)}):Play()
end
local overlay=new("Frame",gui,{Visible=false,
 BackgroundColor3=Color3.fromRGB(1,4,11),BackgroundTransparency=0,
 Size=UDim2.fromScale(1,1),BorderSizePixel=0,ZIndex=25})
local loadingText=label(overlay,"INICIANDO...",20,UDim2.fromScale(.25,.64),
 UDim2.fromScale(.5,.07),Enum.Font.GothamMedium,Enum.TextXAlignment.Center)
loadingText.ZIndex=26
local progress=new("Frame",overlay,{AnchorPoint=Vector2.new(0.5,0),
 Position=UDim2.fromScale(.5,.72),Size=UDim2.fromScale(.4,.008),
 BackgroundColor3=Color3.fromRGB(19,34,58),BorderSizePixel=0,ZIndex=26})
curve(progress,8)
local progressInner=new("Frame",progress,{Size=UDim2.fromScale(0,1),
 BackgroundColor3=Color3.fromRGB(211,239,255),BorderSizePixel=0,ZIndex=27})
curve(progressInner,8)
local death=new("Frame",gui,{Visible=false,BackgroundColor3=Color3.fromRGB(2,5,10),
 BackgroundTransparency=.04,Size=UDim2.fromScale(1,1),BorderSizePixel=0,ZIndex=15})
new("UIGradient",death,{Rotation=90,Transparency=NumberSequence.new({
 NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.6,.26),
 NumberSequenceKeypoint.new(1,0)})})
local diedTitle=label(death,"YOU DIED",49,UDim2.fromScale(.2,.29),
 UDim2.fromScale(.6,.11),Enum.Font.GothamBold,Enum.TextXAlignment.Center)
diedTitle.ZIndex=16
local diedSub=label(death,"The void claims all, eventually.",14,
 UDim2.fromScale(.2,.41),UDim2.fromScale(.6,.07),
 Enum.Font.Gotham,Enum.TextXAlignment.Center)
diedSub.TextColor3=Color3.fromRGB(111,119,137);diedSub.ZIndex=16
new("Frame",death,{Position=UDim2.fromScale(.39,.51),Size=UDim2.fromScale(.22,.002),
 BackgroundColor3=Color3.fromRGB(130,146,164),BackgroundTransparency=.67,
 BorderSizePixel=0,ZIndex=16})
local deathOptions=new("Frame",death,{AnchorPoint=Vector2.new(0.5,.5),
 Position=UDim2.fromScale(.5,.62),Size=UDim2.fromOffset(390,70),
 BackgroundTransparency=1,ZIndex=16})
local function deathButton(txt,x,callback)
 local b=new("TextButton",deathOptions,{Name=txt,Text=txt,
  Position=UDim2.fromOffset(x,0),Size=UDim2.fromOffset(175,55),
  BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextColor3=WHITE,
  TextSize=15,AutoButtonColor=false,ZIndex=17})
 new("Frame",b,{Position=UDim2.new(.2,0,.79,0),
  Size=UDim2.new(.6,0,0,1),BackgroundColor3=WHITE,
  BackgroundTransparency=.43,BorderSizePixel=0,ZIndex=18})
 b.Activated:Connect(callback)
 return b
end
local function hideScene()
 if renderConn then renderConn:Disconnect();renderConn=nil end
 if scene then scene:Destroy();scene=nil end
 Lighting.ClockTime=originalClock
 Lighting.Brightness=originalBrightness
end
local function enterMenu()
 busy=false
 menu=true
 death.Visible=false
 makeScene()
 Lighting.ClockTime=11.9;Lighting.Brightness=3
 hideGameplay()
 frameRoot.Visible=true
 vignette.Visible=true
 activePage="Home";showPage("Home")
 camPose.Value=cameraFor("Home")
 local camera=workspace.CurrentCamera
 if camera then camera.CameraType=Enum.CameraType.Scriptable end
 if renderConn then renderConn:Disconnect() end
 renderConn=Run.RenderStepped:Connect(function()
  if not menu then return end
  local cameraNow=workspace.CurrentCamera
  if not cameraNow then return end
  local t=os.clock()
  local mouseX=0
  local mouseY=0
  if not UserInput.TouchEnabled then
   local p=UserInput:GetMouseLocation()
   local view=cameraNow.ViewportSize
   mouseX=math.clamp(p.X/math.max(1,view.X)-.5,-.5,.5)
   mouseY=math.clamp(p.Y/math.max(1,view.Y)-.5,-.5,.5)
  end
  local wobble=options.bob and math.sin(t*.75)*.11 or 0
  local bank=options.banking and mouseX*.025 or 0
  local tilt=options.tilt and mouseY*.018 or 0
  cameraNow.CameraType=Enum.CameraType.Scriptable
  cameraNow.CFrame=camPose.Value*CFrame.new(mouseX*.85,mouseY*.36+wobble,0)
       *CFrame.Angles(tilt,0,bank)
  if sceneLight and options.glow then
   sceneLight.Brightness=2.1+math.sin(t*1.2)*.28
  end
 end)
end
local function beginPlay()
 if busy or not menu then return end
 busy=true
 overlay.Visible=true
 overlay.BackgroundTransparency=1
 progressInner.Size=UDim2.fromScale(0,1)
 Tween:Create(overlay,TweenInfo.new(.22),{BackgroundTransparency=0}):Play()
 Tween:Create(progressInner,TweenInfo.new(.57,Enum.EasingStyle.Quad),{
  Size=UDim2.fromScale(1,1)}):Play()
 task.wait(.65)
 menu=false;frameRoot.Visible=false;vignette.Visible=false
 hideScene()
 restoreGameplay()
 local cam=workspace.CurrentCamera
 local character=player.Character or player.CharacterAdded:Wait()
 local hum=character:WaitForChild("Humanoid",10)
 if cam then
  cam.CameraType=Enum.CameraType.Custom
  if hum then cam.CameraSubject=hum end
 end
 overlay.BackgroundTransparency=0
 task.wait(.08)
 Tween:Create(overlay,TweenInfo.new(.38),{BackgroundTransparency=1}):Play()
 task.wait(.4)
 overlay.Visible=false
 busy=false
end
local reopen=new("TextButton",gui,{Name="MenuIcon",Text="☰",Visible=false,
 AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,56),
 Size=UDim2.fromOffset(44,40),BackgroundColor3=Color3.fromRGB(10,25,49),
 BackgroundTransparency=.3,TextColor3=WHITE,TextSize=22,
 Font=Enum.Font.GothamBold,AutoButtonColor=false,ZIndex=12})
curve(reopen,12)
border(reopen,WHITE,1,.7)
reopen.Activated:Connect(enterMenu)
local function updateReopen()
 reopen.Visible=not menu and not death.Visible
end
local function showDeath(humanoid)
 if humanoid.Health>0 then return end
 if menu then return end
 death.Visible=true
 reopen.Visible=false
end
deathButton("RESPAWN",5,function()
 death.Visible=false
 remote:FireServer()
end)
deathButton("RETURN TO MENU",206,function()
 death.Visible=false
 enterMenu()
end)
local function hook(char)
 local humanoid=char:WaitForChild("Humanoid",10)
 if not humanoid then return end
 humanoid.Died:Connect(function()showDeath(humanoid)end)
 if not menu then
  death.Visible=false
  local cam=workspace.CurrentCamera
  if cam then cam.CameraType=Enum.CameraType.Custom;cam.CameraSubject=humanoid end
 end
 updateReopen()
end
player.CharacterAdded:Connect(hook)
if player.Character then task.spawn(hook,player.Character) end
pg.ChildAdded:Connect(function(child)
 if menu and child~=gui and child:IsA("ScreenGui") then
  task.defer(function()
   if menu and child.Parent==pg and child.Enabled then
    hidden[child]=true;child.Enabled=false
   end
  end)
 end
end)
menuRow("Play","▶",91,function()task.spawn(beginPlay)end)
menuRow("Settings","⚙",153,function()navigate("Settings")end)
menuRow("Credit","☷",215,function()navigate("Credits")end)
menuRow("Update Log","▤",277,function()navigate("Update")end)
local function rescale()
 local camera=workspace.CurrentCamera
 local viewport=camera and camera.ViewportSize or Vector2.new(1000,650)
 scale.Scale=math.clamp(math.min(viewport.X/780,viewport.Y/540),.58,1.15)
 local deadScale=math.clamp(viewport.X/760,.64,1)
 deathOptions.Size=UDim2.fromOffset(390*deadScale,70)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
rescale()
enterMenu()
