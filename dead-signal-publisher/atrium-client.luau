local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local Sound=game:GetService("SoundService")
local L=game:GetService("Lighting")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("AtriumSession")
local Settings=require(RS:WaitForChild("AtriumSettings"))
local View=require(RS:WaitForChild("AtriumMenuView"))
local camera=workspace.CurrentCamera
local settings=Settings.Clean(nil)
local state={ready=false}
local started=false
local menuOpen=true
local busy=false
local elapsed=0
local function make(class,props,parent)
 local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local gui=make("ScreenGui",{Name="DeadSignalMenu",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=40,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild("PlayerGui"))
local view=View.Create(gui)
local safeGui=make("ScreenGui",{Name="DeadSignalMenuAccess",ResetOnSpawn=false,DisplayOrder=41,IgnoreGuiInset=false},gui.Parent)
local pause=make("TextButton",{Name="MenuTopRight",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-4,0,4),Size=UDim2.fromOffset(66,44),Text="MENU",Font=Enum.Font.Michroma,TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.35,BorderSizePixel=0,Visible=false},safeGui)
make("UIStroke",{Thickness=1,Color=Color3.new(1,1,1),Transparency=.45},pause)
local notice=make("TextLabel",{Name="Notice",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-8),Size=UDim2.new(.9,0,0,28),BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(255,208,190),TextSize=13,Font=Enum.Font.Michroma,ZIndex=60},gui)
local menuGrade=make("ColorCorrectionEffect",{Name="MenuWarmGrade",TintColor=Color3.fromRGB(255,152,135),Saturation=-.15,Contrast=.1,Enabled=true},camera)
local brightness=make("ColorCorrectionEffect",{Name="PlayerBrightness",Brightness=0},camera)
local dof=make("DepthOfFieldEffect",{Name="MenuFocus",FocusDistance=72,InFocusRadius=58,FarIntensity=.12,NearIntensity=0},camera)
local music=Sound:FindFirstChild("Music") or make("SoundGroup",{Name="Music"},Sound)
local sfx=Sound:FindFirstChild("SFX") or make("SoundGroup",{Name="SFX"},Sound)
local modal
local cleanup={}
local drag
local creditsTween
local function closeModal()
 drag=nil
 for _,c in ipairs(cleanup) do c:Disconnect() end;cleanup={}
 if creditsTween then creditsTween:Cancel();creditsTween=nil end
 if modal then modal:Destroy();modal=nil end
end
local function tell(text) notice.Text=text end
local function invoke(action,payload)
 local ok,result=pcall(function() return remote:InvokeServer(action,payload) end)
 if not ok then warn("[AtriumMenu] "..tostring(result));return nil end
 return result
end
local dustEmitters={}
for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("ParticleEmitter") and d.Name=="AtriumDust" then dustEmitters[d]=true end end
local function apply()
 settings=Settings.Clean(settings)
 music.Volume=settings.master*settings.music;sfx.Volume=settings.master*settings.sfx
 camera.FieldOfView=settings.fov;brightness.Brightness=(settings.brightness-.5)*.4
 pcall(function() UserSettings():GetService("UserGameSettings").MouseSensitivity=settings.sensitivity end)
 -- This controls our effects, independently of the platform's quality ceiling.
 L.GlobalShadows=settings.quality>=4
 for _,e in ipairs(L:GetChildren()) do
  if e:IsA("BloomEffect") then e.Enabled=settings.quality>=3;e.Intensity=.12+settings.quality*.012
  elseif e:IsA("SunRaysEffect") then e.Enabled=settings.quality>=5;e.Intensity=.025+settings.quality*.003 end
 end
 dof.Enabled=menuOpen and settings.quality>=7
 view.Scanlines.Visible=settings.scanlines
 player:SetAttribute("SubtitlesEnabled",settings.subtitles)
 for d in pairs(dustEmitters) do if d.Parent then d.Enabled=settings.quality>=5 and settings.motion else dustEmitters[d]=nil end end
end
-- Apply quality to objects arriving with streaming without a frame-by-frame scan.
workspace.DescendantAdded:Connect(function(d) if d:IsA("ParticleEmitter") and d.Name=="AtriumDust" then dustEmitters[d]=true;d.Enabled=settings.quality>=5 and settings.motion end end)
local menuCamera=CFrame.lookAt(Vector3.new(24,8,65),Vector3.new(-8,30,-54))
local savedCamera
local controls
task.spawn(function()
 local pm=player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule",15)
 if pm then local ok,value=pcall(function() return require(pm):GetControls() end);if ok then controls=value;if menuOpen then controls:Disable() end end end
end)
local function setMenu(open)
 if open and not menuOpen then savedCamera=camera.CFrame end
 menuOpen=open;if controls then if open then controls:Disable() else controls:Enable() end end;view.Root.Visible=open;pause.Visible=started and not open;menuGrade.Enabled=open;dof.Enabled=open and settings.quality>=7
 if open then camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=menuCamera;UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true
 else
  closeModal();tell("")
  player.CameraMode=Enum.CameraMode.Classic;player.CameraMinZoomDistance=.5;player.CameraMaxZoomDistance=24
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum then camera.CameraSubject=hum end
  if savedCamera then camera.CFrame=savedCamera end
  camera.CameraType=Enum.CameraType.Custom;UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true
 end
 local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if hum then hum.WalkSpeed=open and 0 or 16;hum.JumpPower=open and 0 or 50;hum.JumpHeight=open and 0 or 7.2 end
end
local function outlined(parent,text,pos,size,callback)
 local b=make("TextButton",{Text=text,Name=text,Position=pos,Size=size,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Michroma,TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.55,BorderSizePixel=0,AutoButtonColor=false},parent)
 make("UIPadding",{PaddingLeft=UDim.new(0,10)},b)
 local stroke=make("UIStroke",{Color=Color3.new(1,1,1),Thickness=1,Transparency=.35,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b)
 local function highlight(on)
  Tween:Create(b,TweenInfo.new(.12),{BackgroundColor3=on and Color3.fromRGB(60,10,10) or Color3.new(0,0,0),BackgroundTransparency=on and .15 or .55}):Play()
  Tween:Create(stroke,TweenInfo.new(.12),{Transparency=on and 0 or .35,Color=on and Color3.fromRGB(255,110,100) or Color3.new(1,1,1)}):Play()
 end
 b.MouseEnter:Connect(function() highlight(true) end);b.MouseLeave:Connect(function() highlight(false) end)
 b.SelectionGained:Connect(function() highlight(true) end);b.SelectionLost:Connect(function() highlight(false) end)
 b.Activated:Connect(function() if not busy then callback() end end)
 return b
end
local function text(parent,value,pos,size,fs)
 return make("TextLabel",{Text=value,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Michroma,TextSize=fs or 12,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true},parent)
end
local function panel(title,height)
 closeModal()
 modal=make("Frame",{Name="ModalOverlay",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.25,BorderSizePixel=0,Active=true,ZIndex=20},gui)
 local v=camera.ViewportSize
 local p=make("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(math.min(540,v.X-24),math.min(height,v.Y-24)),BackgroundColor3=Color3.fromRGB(12,4,4),BorderSizePixel=0},modal)
 p:SetAttribute("PreferredHeight",height)
 make("UIStroke",{Thickness=1,Color=Color3.new(1,1,1),Transparency=.3},p)
 text(p,title,UDim2.fromOffset(16,14),UDim2.new(1,-32,0,28),18)
 return p
end
local function confirm(message,action)
 local p=panel("CONFIRM",208)
 text(p,message,UDim2.fromOffset(16,58),UDim2.new(1,-32,0,66),12)
 outlined(p,"YES",UDim2.new(0,16,1,-60),UDim2.new(.5,-24,0,44),function() closeModal();action() end)
 outlined(p,"NO",UDim2.new(.5,8,1,-60),UDim2.new(.5,-24,0,44),closeModal)
end
local function enter(action)
 if not state.ready then tell("LOADING SAVE DATA…");return end
 if state.loadFailed then tell("SAVE UNAVAILABLE. REJOIN TO RETRY.");return end
 busy=true;tell("LOADING…")
 local result=invoke(action)
 busy=false
 if result and result.ok then started=true;state.hasSave=true;setMenu(false) else tell(result and result.error or "COULD NOT START. PLEASE TRY AGAIN.") end
end
local showSettings
local function slider(parent,index,name,key,low,high,step,percent)
 local row=make("Frame",{Position=UDim2.fromOffset(0,index*56),Size=UDim2.new(1,-8,0,56),BackgroundTransparency=1},parent)
 text(row,name,UDim2.fromOffset(0,2),UDim2.new(.75,0,0,20),11)
 local value=text(row,"",UDim2.new(.75,0,0,2),UDim2.new(.25,0,0,20),11);value.TextXAlignment=Enum.TextXAlignment.Right
 local hit=make("TextButton",{Name=key.."Slider",Position=UDim2.fromOffset(0,20),Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,Text="",AutoButtonColor=false},row)
 local track=make("Frame",{Position=UDim2.new(0,8,.5,-2),Size=UDim2.new(1,-16,0,4),BackgroundColor3=Color3.fromRGB(70,60,60),BorderSizePixel=0},hit)
 local fill=make("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(218,72,60),BorderSizePixel=0},track)
 local knob=make("Frame",{Size=UDim2.fromOffset(10,18),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},track)
 local function set(n)
  n=math.clamp(math.floor(n/step+.5)*step,low,high);settings[key]=n
  local alpha=(n-low)/(high-low);fill.Size=UDim2.fromScale(alpha,1);knob.Position=UDim2.fromScale(alpha,.5)
  value.Text=percent and Settings.Percent(n) or string.format(step>=1 and "%d" or "%.1f",n)
  apply()
 end
 set(settings[key])
 local function update(x) set(low+(high-low)*math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)) end
 hit.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then drag={input=input,update=update};parent.ScrollingEnabled=false;update(input.Position.X) end
 end)
 table.insert(cleanup,UIS.InputEnded:Connect(function(input) if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then drag=nil;parent.ScrollingEnabled=true end end))
 hit.InputBegan:Connect(function(input) if input.KeyCode==Enum.KeyCode.Left or input.KeyCode==Enum.KeyCode.DPadLeft then set(settings[key]-step) elseif input.KeyCode==Enum.KeyCode.Right or input.KeyCode==Enum.KeyCode.DPadRight then set(settings[key]+step) end end)
end
showSettings=function()
 local p=panel("SETTINGS",570)
 local scroll=make("ScrollingFrame",{Position=UDim2.fromOffset(16,52),Size=UDim2.new(1,-32,1,-120),CanvasSize=UDim2.fromOffset(0,616),ScrollBarThickness=4,BackgroundTransparency=1,BorderSizePixel=0},p)
 local rows={{"MASTER VOLUME","master",0,1,.01,true},{"MUSIC VOLUME","music",0,1,.01,true},{"SFX VOLUME","sfx",0,1,.01,true},{"BRIGHTNESS","brightness",0,1,.01,true},{"FIELD OF VIEW","fov",50,110,1,false},{"EFFECTS QUALITY","quality",1,10,1,false},{"MOUSE SENSITIVITY","sensitivity",.2,3,.1,false}}
 for i,r in ipairs(rows) do slider(scroll,i-1,r[1],r[2],r[3],r[4],r[5],r[6]) end
 for i,r in ipairs({{"SUBTITLES","subtitles"},{"SCANLINES (CRT)","scanlines"},{"CAMERA MOTION / DUST","motion"}}) do
  local b
  b=outlined(scroll,r[1]..": "..(settings[r[2]] and "ON" or "OFF"),UDim2.fromOffset(0,392+(i-1)*52),UDim2.new(1,-8,0,44),function() settings[r[2]]=not settings[r[2]];b.Text=r[1]..": "..(settings[r[2]] and "ON" or "OFF");apply() end)
 end
 text(scroll,"Effects quality adjusts this scene's lighting and particles.",UDim2.fromOffset(0,554),UDim2.new(1,-12,0,50),10)
 outlined(p,"SAVE & BACK",UDim2.new(0,16,1,-58),UDim2.new(.5,-24,0,44),function()
  busy=true;local result=invoke("settings",settings);busy=false
  if result and result.ok then closeModal();tell("") else tell("SETTINGS APPLIED; SAVE FAILED. TRY AGAIN.") end
 end)
 outlined(p,"RESET DEFAULTS",UDim2.new(.5,8,1,-58),UDim2.new(.5,-24,0,44),function() settings=Settings.Clean(nil);apply();showSettings() end)
end
local function credits()
 local p=panel("CREDITS",430)
 local area=make("Frame",{Position=UDim2.fromOffset(16,54),Size=UDim2.new(1,-32,1,-122),BackgroundTransparency=1,ClipsDescendants=true},p)
 local t=text(area,"DEAD SIGNAL\n\nAURIVANE WORKS\n\nTHE ATRIUM\n\nArchitecture, environment and presentation\ncreated for this experience.\n\nThank you for playing.",UDim2.fromScale(0,1),UDim2.new(1,0,0,500),16);t.TextXAlignment=Enum.TextXAlignment.Center
 creditsTween=Tween:Create(t,TweenInfo.new(20,Enum.EasingStyle.Linear),{Position=UDim2.fromOffset(0,-500)});creditsTween:Play()
 outlined(p,"BACK",UDim2.new(0,16,1,-58),UDim2.new(1,-32,0,44),closeModal)
end
local actions={
 function() if started then setMenu(false) elseif state.hasSave then enter("continue") else tell("NO SAVE FOUND - START A NEW GAME") end end,
 function() confirm("Start a new game? Your atrium checkpoint will be replaced.",function() enter("new") end) end,
 showSettings,
 credits,
 function() confirm("Are you sure you want to quit the game?",function() player:Kick("Thanks for playing Dead Signal!") end) end,
}
for i,b in ipairs(view.Buttons) do
 local stroke=b:FindFirstChildOfClass("UIStroke")
 local function hover(on)
  Tween:Create(b,TweenInfo.new(.12),{BackgroundTransparency=on and .15 or .55,BackgroundColor3=on and Color3.fromRGB(60,10,10) or Color3.new(0,0,0)}):Play()
  stroke.Color=on and Color3.fromRGB(255,90,90) or Color3.new(1,1,1);stroke.Transparency=on and 0 or .35
 end
 b.MouseEnter:Connect(function() hover(true) end);b.MouseLeave:Connect(function() hover(false) end)
 b.SelectionGained:Connect(function() hover(true) end);b.SelectionLost:Connect(function() hover(false) end)
 b.Activated:Connect(function() if not busy and not modal then actions[i]() end end)
end
local function resize()
 local v=camera.ViewportSize;view.Resize(v.X,v.Y,UIS.TouchEnabled)
 if modal then local p=modal:FindFirstChild("Panel");if p then p.Size=UDim2.fromOffset(math.min(540,v.X-24),math.min(p:GetAttribute("PreferredHeight"),v.Y-24)) end end
end
resize();camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
UIS.InputChanged:Connect(function(input) if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseMovement and drag.input.UserInputType==Enum.UserInputType.MouseButton1) then drag.update(input.Position.X) end end)
pause.Activated:Connect(function() if started then setMenu(true) end end)
UIS.InputBegan:Connect(function(input,processed) if not processed and started and input.KeyCode==Enum.KeyCode.M then if modal then closeModal() else setMenu(not menuOpen) end end end)
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt
 if menuOpen then
  camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=menuCamera*(settings.motion and CFrame.Angles(math.sin(elapsed*.13)*.006,math.sin(elapsed*.09)*.018,0) or CFrame.new())
  UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true
 end
end)
player.CharacterAdded:Connect(function(char) local hum=char:WaitForChild("Humanoid");task.wait(.2);camera.CameraSubject=hum;setMenu(menuOpen) end)
setMenu(true);apply();player:SetAttribute("AtriumMenuReady",true)
task.spawn(function()
 while not state.ready do local result=invoke("status");if result then state=result end;if not state.ready then task.wait(.5) end end
 settings=Settings.Clean(state.settings);apply()
 if state.loadFailed then tell("SAVE UNAVAILABLE. REJOIN TO RETRY.") end
end)
