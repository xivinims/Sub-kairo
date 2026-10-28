local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local L=game:GetService("Lighting")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("AtriumSession")
local camera=workspace.CurrentCamera
local settings={quality="Alta",motion=true}
local state={ready=false}
local started=false
local menuOpen=true
local busy=false
local elapsed=0
local gui=Instance.new("ScreenGui");gui.Name="DeadSignalMenu";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=40;gui.Parent=player:WaitForChild("PlayerGui")
local function frame(parent,name,size,pos,color,alpha)
 local f=Instance.new("Frame");f.Name=name;f.Size=size;f.Position=pos;f.BackgroundColor3=color or Color3.new(0,0,0);f.BackgroundTransparency=alpha or 0;f.BorderSizePixel=0;f.Parent=parent;return f
end
local function label(parent,text,size,pos,fontSize,color)
 local t=Instance.new("TextLabel");t.Size=size;t.Position=pos;t.BackgroundTransparency=1;t.Text=text;t.TextSize=fontSize;t.Font=Enum.Font.Code;t.TextColor3=color or Color3.fromRGB(226,231,239);t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent;return t
end
local shade=frame(gui,"CinematicGradient",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Color3.new(0,0,0),.12)
local gradient=Instance.new("UIGradient");gradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.02),NumberSequenceKeypoint.new(.48,.38),NumberSequenceKeypoint.new(1,1)});gradient.Parent=shade
local layout=frame(shade,"MenuLayout",UDim2.fromOffset(1280,720),UDim2.fromScale(0,0),nil,1)
local scale=Instance.new("UIScale");scale.Parent=layout
local function resize()
 local v=camera.ViewportSize;scale.Scale=math.min(v.X/1280,v.Y/720);layout.Position=UDim2.fromOffset(math.max(0,(v.X-1280*scale.Scale)/2),math.max(0,(v.Y-720*scale.Scale)/2))
end
resize();camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
label(layout,"DEAD SIGNAL",UDim2.fromOffset(540,70),UDim2.fromOffset(64,66),57)
label(layout,"CAPÍTULO 01  /  O ÁTRIO",UDim2.fromOffset(500,30),UDim2.fromOffset(68,143),22,Color3.fromRGB(153,179,211))
frame(layout,"Rule",UDim2.fromOffset(410,1),UDim2.fromOffset(68,189),Color3.fromRGB(157,175,196),.35)
local subtitle=label(layout,"A luz ainda atravessa o teto.\nAlguém deixou este lugar para trás.",UDim2.fromOffset(450,65),UDim2.fromOffset(68,209),18);subtitle.TextWrapped=true
local main=frame(layout,"Main",UDim2.fromOffset(400,310),UDim2.fromOffset(68,330),nil,1)
local function button(parent,text,y,callback,width)
 local b=Instance.new("TextButton");b.Name=text;b.Size=UDim2.fromOffset(width or 330,48);b.Position=UDim2.fromOffset(0,y);b.BackgroundColor3=Color3.fromRGB(12,18,28);b.BackgroundTransparency=.35;b.BorderSizePixel=0;b.Text="  "..text;b.TextXAlignment=Enum.TextXAlignment.Left;b.TextColor3=Color3.fromRGB(230,234,243);b.TextSize=23;b.Font=Enum.Font.Code;b.AutoButtonColor=false;b.Parent=parent
 local stroke=Instance.new("UIStroke");stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;stroke.Color=Color3.fromRGB(143,158,181);stroke.Transparency=.45;stroke.Thickness=1;stroke.Parent=b
 b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.15),{BackgroundTransparency=.05,BackgroundColor3=Color3.fromRGB(37,53,72)}):Play();stroke.Transparency=.05 end)
 b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.15),{BackgroundTransparency=.35,BackgroundColor3=Color3.fromRGB(12,18,28)}):Play();stroke.Transparency=.45 end)
 b.Activated:Connect(function() if not busy then callback() end end);return b
end
local panel=frame(layout,"Submenu",UDim2.fromOffset(490,420),UDim2.fromOffset(68,235),Color3.fromRGB(9,15,24),.05);panel.Visible=false
local mainScale=Instance.new("UIScale");mainScale.Parent=main
local panelScale=Instance.new("UIScale");panelScale.Parent=panel
local function touchLayout()
 local v=camera.ViewportSize
 if v.Y<600 or v.X<600 then
  mainScale.Scale=1/scale.Scale
  main.Position=UDim2.fromOffset(36/scale.Scale,math.max(135,v.Y-248)/scale.Scale)
  panelScale.Scale=1/scale.Scale
  panel.Position=UDim2.fromOffset(20/scale.Scale,math.max(12,(v.Y-330)/2)/scale.Scale)
  panel.Size=UDim2.fromOffset(math.min(490,v.X-40),330)
  local buttons={}
  for _,d in ipairs(panel:GetChildren()) do if d:IsA("TextButton") then table.insert(buttons,d) elseif d:IsA("TextLabel") then d.TextSize=18;d.Size=UDim2.fromOffset(math.min(450,v.X-80),d.Size.Y.Offset) end end
  table.sort(buttons,function(a,b) return a.Position.Y.Offset<b.Position.Y.Offset end)
  for i,b in ipairs(buttons) do b.Size=UDim2.fromOffset(math.min(450,v.X-80),48);b.TextSize=18;b.Position=UDim2.fromOffset(20,330-(#buttons-i+1)*58) end
 else mainScale.Scale=1;panelScale.Scale=1 end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(touchLayout)
panel.ChildAdded:Connect(function() task.defer(touchLayout) end)
task.defer(touchLayout)
local function clearPanel() for _,v in ipairs(panel:GetChildren()) do v:Destroy() end;panel.Visible=true;main.Visible=false;subtitle.Visible=false end
local function home() panel.Visible=false;main.Visible=true;subtitle.Visible=true end
local function invoke(action,payload)
 local ok,result=pcall(function() return remote:InvokeServer(action,payload) end)
 if not ok then return nil end;return result
end
local function apply()
 for _,e in ipairs(L:GetChildren()) do if e:IsA("BloomEffect") or e:IsA("SunRaysEffect") then e.Enabled=settings.quality=="Alta" end end
 L.GlobalShadows=settings.quality=="Alta"
 local map=workspace:FindFirstChild("OvergrownAtrium")
 if map then for _,d in ipairs(map:GetDescendants()) do if d:IsA("ParticleEmitter") then d.Enabled=settings.quality=="Alta" and settings.motion end end end
end
local menuCamera=CFrame.lookAt(Vector3.new(24,8,65),Vector3.new(-8,30,-54))
local function setMenu(open)
 menuOpen=open;shade.Visible=open
 if open then camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=menuCamera;UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true
 else
  local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
  camera.CameraType=Enum.CameraType.Custom;if hum then camera.CameraSubject=hum end;UIS.MouseBehavior=Enum.MouseBehavior.LockCenter;UIS.MouseIconEnabled=false
 end
 local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if hum then hum.WalkSpeed=open and 0 or 16;hum.JumpPower=open and 0 or 50;hum.JumpHeight=open and 0 or 7.2 end
end
local notice=label(layout,"",UDim2.fromOffset(700,30),UDim2.fromOffset(68,669),16,Color3.fromRGB(204,177,142))
local function enter(action)
 if not state.ready then notice.Text="Aguardando seus dados…";return end
 busy=true;notice.Text="CARREGANDO…"
 local result=invoke(action)
 if result and result.ok then started=true;home();setMenu(false);notice.Text=""
 else notice.Text="Não foi possível entrar. Tente novamente." end
 busy=false
end
local continueButton=button(main,"CONTINUAR",0,function() if started then setMenu(false) elseif state.hasSave then enter("continue") end end)
button(main,"NOVO JOGO",58,function()
 if state.hasSave or started then
  clearPanel();label(panel,"COMEÇAR NOVAMENTE?",UDim2.fromOffset(430,40),UDim2.fromOffset(20,20),24)
  label(panel,"O checkpoint do átrio será substituído.",UDim2.fromOffset(450,60),UDim2.fromOffset(20,74),18)
  local yes=button(panel,"COMEÇAR DO INÍCIO",156,function() enter("new") end,440);yes.Position=UDim2.fromOffset(20,156)
  local no=button(panel,"VOLTAR",218,home,440);no.Position=UDim2.fromOffset(20,218)
 else enter("new") end
end)
button(main,"CONFIGURAÇÕES",116,function()
 clearPanel();label(panel,"CONFIGURAÇÕES",UDim2.fromOffset(440,40),UDim2.fromOffset(20,16),26)
 local quality;quality=button(panel,"GRÁFICOS: "..settings.quality,76,function() settings.quality=settings.quality=="Alta" and "Baixa" or "Alta";quality.Text="  GRÁFICOS: "..settings.quality;apply() end,450);quality.Position=UDim2.fromOffset(20,76)
 local motion;motion=button(panel,"MOVIMENTO: "..(settings.motion and "SIM" or "REDUZIDO"),134,function() settings.motion=not settings.motion;motion.Text="  MOVIMENTO: "..(settings.motion and "SIM" or "REDUZIDO");apply() end,450);motion.Position=UDim2.fromOffset(20,134)
 local fov;fov=button(panel,"CAMPO DE VISÃO: "..tostring(math.floor(camera.FieldOfView)),192,function() camera.FieldOfView=camera.FieldOfView>=90 and 70 or camera.FieldOfView+10;fov.Text="  CAMPO DE VISÃO: "..tostring(math.floor(camera.FieldOfView)) end,450);fov.Position=UDim2.fromOffset(20,192)
 local back=button(panel,"SALVAR E VOLTAR",292,function() busy=true;local r=invoke("settings",settings);busy=false;if r and r.ok then home() else notice.Text="Configuração aplicada; não foi possível salvar." end end,450);back.Position=UDim2.fromOffset(20,292)
end)
button(main,"CRÉDITOS",174,function()
 clearPanel();label(panel,"AURIVANE WORKS",UDim2.fromOffset(440,40),UDim2.fromOffset(20,24),30)
 local t=label(panel,"DEAD SIGNAL\n\nÁtrio criado a partir da referência visual.\nArquitetura, vegetação e iluminação\nconstruídas para esta experiência.",UDim2.fromOffset(450,200),UDim2.fromOffset(20,80),20);t.TextWrapped=true
 local b=button(panel,"VOLTAR",310,home,450);b.Position=UDim2.fromOffset(20,310)
end)
label(layout,"AURIVANE WORKS  /  DEAD SIGNAL",UDim2.fromOffset(500,25),UDim2.fromOffset(68,637),14,Color3.fromRGB(115,136,161))
-- Touch target has a real 52px minimum independent of cinematic layout scaling.
local pause=Instance.new("TextButton");pause.Name="Pause";pause.Size=UDim2.fromOffset(68,52);pause.Position=UDim2.new(1,-84,0,16);pause.Text="MENU";pause.Font=Enum.Font.Code;pause.TextSize=18;pause.BackgroundColor3=Color3.fromRGB(12,18,28);pause.BackgroundTransparency=.2;pause.TextColor3=Color3.new(1,1,1);pause.Parent=gui
pause.Activated:Connect(function() if started then home();setMenu(not menuOpen) end end)
UIS.InputBegan:Connect(function(input,processed) if not processed and started and input.KeyCode==Enum.KeyCode.M then home();setMenu(not menuOpen) end end)
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt
 pause.Visible=started and not menuOpen
 if menuOpen then
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=menuCamera*(settings.motion and CFrame.Angles(math.sin(elapsed*.13)*.006,math.sin(elapsed*.09)*.018,0) or CFrame.new())
  UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true
 end
end)
player.CharacterAdded:Connect(function(char) local hum=char:WaitForChild("Humanoid");task.wait(.2);camera.CameraSubject=hum;setMenu(menuOpen) end)
setMenu(true)
player:SetAttribute("AtriumMenuReady",true)
task.spawn(function()
 while not state.ready do
  local result=invoke("status");if result then state=result end
  if not state.ready then task.wait(.5) end
 end
 settings=state.settings or settings;apply()
 continueButton.TextColor3=state.hasSave and Color3.fromRGB(230,234,243) or Color3.fromRGB(90,103,120)
end)
