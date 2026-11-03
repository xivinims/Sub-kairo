local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("ArenaControl")
local scare=RS:WaitForChild("BrambleScare")
local rig=workspace:WaitForChild("Bramble")
local gui=Instance.new("ScreenGui"); gui.Name="BrambleTestControls"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame"); panel.AnchorPoint=Vector2.new(0.5,0); panel.Position=UDim2.new(0.5,0,0,12); panel.Size=UDim2.new(0.94,0,0,90); panel.BackgroundTransparency=1; panel.Parent=gui
local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(600,90); limit.Parent=panel
local status=Instance.new("TextLabel"); status.Size=UDim2.new(1,0,0,26); status.BackgroundColor3=Color3.fromRGB(20,23,26); status.BackgroundTransparency=0.2; status.TextColor3=Color3.fromRGB(240,240,240); status.Font=Enum.Font.Gotham; status.TextSize=13; status.TextScaled=true; status.Parent=panel
local textLimit=Instance.new("UITextSizeConstraint"); textLimit.MaxTextSize=13; textLimit.MinTextSize=10; textLimit.Parent=status
local labels={Idle="PARADO",Walk="ANDAR",Run="CORRER",Attack="AGARRAR"}
local buttons={}
for i,key in ipairs({"Idle","Walk","Run","Attack"}) do
 local b=Instance.new("TextButton"); b.Name=key; b.Text=labels[key]; b.Position=UDim2.new((i-1)*0.25,3,0,34); b.Size=UDim2.new(0.25,-6,0,44)
 b.BackgroundColor3=Color3.fromRGB(40,46,51); b.TextColor3=Color3.fromRGB(245,245,245); b.Font=Enum.Font.GothamMedium; b.TextSize=12; b.Modal=false; b.Parent=panel
 b.Activated:Connect(function() remote:FireServer(key) end); buttons[key]=b
end
local mute=false; local reduced=false
local function option(text,x,fn)
 local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,0); b.Size=UDim2.fromOffset(100,40); b.Position=UDim2.new(1,x,0,104); b.Text=text; b.Font=Enum.Font.Gotham; b.TextSize=12; b.TextColor3=Color3.new(1,1,1); b.BackgroundColor3=Color3.fromRGB(32,36,41); b.Parent=gui; b.Activated:Connect(function() fn(b) end)
end
option("SOM: LIGADO",-12,function(b) mute=not mute; b.Text=mute and "SOM: MUDO" or "SOM: LIGADO" end)
option("EFEITOS: SIM",-120,function(b) reduced=not reduced; b.Text=reduced and "EFEITOS: NÃO" or "EFEITOS: SIM" end)
local veil=Instance.new("Frame"); veil.Name="ScareVeil"; veil.BackgroundColor3=Color3.fromRGB(36,5,3); veil.BackgroundTransparency=1; veil.BorderSizePixel=0; veil.Size=UDim2.fromScale(1,1); veil.ZIndex=20; veil.Active=false; veil.Parent=gui
local function sound(name,id,volume,pitch)
 local s=Instance.new("Sound"); s.Name=name; s.SoundId=id; s.Volume=volume; s.PlaybackSpeed=pitch; s.Parent=SoundService; return s
end
-- Built-in Roblox audio only: layered and processed locally; no Poppy audio is extracted.
local sting=sound("BrambleGrabSting","rbxasset://sounds/uuhhh.mp3",0.42,0.55)
local distortion=Instance.new("DistortionSoundEffect"); distortion.Level=0.42; distortion.Parent=sting
local eq=Instance.new("EqualizerSoundEffect"); eq.LowGain=3; eq.MidGain=-3; eq.HighGain=-5; eq.Parent=sting
local wind=sound("BrambleGrabRush","rbxasset://sounds/action_falling.mp3",0.3,0.65)
local electric=sound("PowerRelayClick","rbxasset://sounds/electronicpingshort.wav",0.1,0.6)
local captured
local function restore()
 if not captured then return end
 local record=captured; captured=nil
 RunService:UnbindFromRenderStep("BrambleScareCamera")
 local camera=workspace.CurrentCamera
 if camera then
  camera.CameraType=Enum.CameraType.Custom; camera.FieldOfView=record.fov
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then camera.CameraSubject=hum end
 end
 for part,value in pairs(record.hidden) do if part.Parent then part.LocalTransparencyModifier=value end end
 sting:Stop(); wind:Stop(); veil.BackgroundTransparency=1; panel.Visible=true
end
scare.OnClientEvent:Connect(function(kind,at)
 if kind=="End" then restore(); return end
 if kind~="Begin" then return end
 restore()
 local camera=workspace.CurrentCamera; if not camera then return end
 local hidden={}
 if player.Character then for _,d in ipairs(player.Character:GetDescendants()) do if d:IsA("BasePart") then hidden[d]=d.LocalTransparencyModifier; d.LocalTransparencyModifier=1 end end end
 captured={at=at,from=camera.CFrame,fov=camera.FieldOfView,hidden=hidden,sting=false}
 panel.Visible=false; camera.CameraType=Enum.CameraType.Scriptable
 if not mute then wind.Volume=0.3; wind:Play() end
 RunService:BindToRenderStep("BrambleScareCamera",Enum.RenderPriority.Camera.Value+10,function()
  if not captured then return end
  local record=captured; local t=workspace:GetServerTimeNow()-record.at
  if t>3 then restore(); return end
  local head=rig:FindFirstChild("UpperHead",true)
  local cam=workspace.CurrentCamera; if not head or not cam then restore(); return end
  local focus=head.Position
  local forward=rig:GetPivot().LookVector
  local distance=t>1.45 and 2.4 or 3.7
  local target=CFrame.lookAt(focus+forward*distance+Vector3.new(0,-0.15,0),focus)
  local blend=math.clamp((t-0.1)/0.55,0,1); blend=blend*blend*(3-2*blend)
  local cf=record.from:Lerp(target,blend)
  if not reduced then cf*=CFrame.Angles(math.sin(t*39)*0.008,math.sin(t*31)*0.008,math.sin(t*23)*0.012) end
  cam.CameraType=Enum.CameraType.Scriptable; cam.CFrame=cf; cam.FieldOfView=t>1.45 and 72 or 62
  veil.BackgroundTransparency=reduced and 1 or t>1.45 and 0.72 or 0.94
  if t>1.45 and not record.sting then record.sting=true; if not mute then sting:Play() end end
  if mute then sting:Stop(); wind:Stop() end
 end)
end)
player.CharacterAdded:Connect(function() restore() end)
local function update()
 local power=workspace:GetAttribute("PowerOn"); local flicker=workspace:GetAttribute("PowerFlickering")
 local state=rig:GetAttribute("State") or "Idle"
 status.Text=not power and "LIGUE O QUADRO ELÉTRICO PERTO DO SPAWN" or flicker and "ENERGIA INSTÁVEL…" or player:GetAttribute("BrambleCaptured") and "AGARRADO" or "BRAMBLE · "..(labels[state] or state)
 for k,b in pairs(buttons) do b.BackgroundColor3=k==state and Color3.fromRGB(86,69,48) or Color3.fromRGB(40,46,51); b.AutoButtonColor=power and not flicker end
end
rig:GetAttributeChangedSignal("State"):Connect(update)
player:GetAttributeChangedSignal("BrambleCaptured"):Connect(function() update(); if not player:GetAttribute("BrambleCaptured") then restore() end end)
workspace:GetAttributeChangedSignal("PowerOn"):Connect(update)
workspace:GetAttributeChangedSignal("PowerFlickering"):Connect(update)
workspace:GetAttributeChangedSignal("PowerLampOn"):Connect(function() if workspace:GetAttribute("PowerFlickering") and not mute then electric:Play() end end)
local lights={}
for _,container in ipairs({workspace:WaitForChild("PoppyTestMap"),workspace:WaitForChild("TestPowerLights")}) do
 for _,d in ipairs(container:GetDescendants()) do if d:IsA("Light") then table.insert(lights,d) end end
 container.DescendantAdded:Connect(function(d) if d:IsA("Light") then table.insert(lights,d) end end)
end
local budget=0
RunService.Heartbeat:Connect(function(dt)
 budget+=dt; if budget<0.1 then return end; budget=0
 local camera=workspace.CurrentCamera
 local on=workspace:GetAttribute("PowerLampOn")==true
 for _,l in ipairs(lights) do
  if l.Parent and camera then
   local parent=l.Parent; local p=parent:IsA("Attachment") and parent.WorldPosition or parent:IsA("BasePart") and parent.Position
   l.Enabled=on and p~=nil and (p-camera.CFrame.Position).Magnitude<140
  end
 end
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 local key=({[Enum.KeyCode.One]="Idle",[Enum.KeyCode.Two]="Walk",[Enum.KeyCode.Three]="Run",[Enum.KeyCode.Four]="Attack"})[input.KeyCode]
 if key then remote:FireServer(key) end
end)
update()
