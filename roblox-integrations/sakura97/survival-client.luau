local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer local net=RS:WaitForChild("Survival") local event=net.Action
local SoundService=game:GetService("SoundService")
local themeTemplate=net:WaitForChild("JasonTheme")
local jasonTheme=themeTemplate:Clone()
jasonTheme.Name="LocalJasonTheme"
jasonTheme.Looped=true
jasonTheme.Parent=SoundService
local config=require(net.Config)
local gui=Instance.new("ScreenGui") gui.Name="SurvivalHUD" gui.ResetOnSpawn=false gui.DisplayOrder=30 gui.Parent=player:WaitForChild("PlayerGui")
local function panel(name,size,pos)
 local f=Instance.new("Frame") f.Name=name f.Size=size f.Position=pos f.BackgroundColor3=Color3.fromRGB(12,12,15) f.BackgroundTransparency=.22 f.BorderSizePixel=0 f.Parent=gui
 local c=Instance.new("UICorner",f) c.CornerRadius=UDim.new(0,16)
 local s=Instance.new("UIStroke",f) s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Color=Color3.fromRGB(142,142,150) s.Transparency=.78 s.Thickness=1
 return f
end
local function text(parent,name,value,size,pos)
 local l=Instance.new("TextLabel") l.Name=name l.Text=value l.Size=size l.Position=pos l.BackgroundTransparency=1 l.Font=Enum.Font.GothamMedium l.TextSize=15 l.TextColor3=Color3.fromRGB(224,228,232) l.TextWrapped=true l.Parent=parent return l
end
local function button(parent,name,label,size,pos,callback)
 local b=Instance.new("TextButton") b.Name=name b.Text=label b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(18,18,22) b.BackgroundTransparency=.12 b.TextColor3=Color3.fromRGB(239,239,242) b.Font=Enum.Font.GothamSemibold b.TextSize=14 b.BorderSizePixel=0 b.Parent=parent
 local c=Instance.new("UICorner",b) c.CornerRadius=UDim.new(0,12)
 local stroke=Instance.new("UIStroke",b) stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border stroke.Color=Color3.fromRGB(150,150,158) stroke.Transparency=.72
 b.Activated:Connect(function()
  if player:GetAttribute("MenuSounds")~=false then local s=RS.XNMedia.MenuClick:Clone() s.Parent=b s:Play() game:GetService("Debris"):AddItem(s,3) end
  callback()
 end) return b
end
local countdown=panel("Countdown",UDim2.fromOffset(208,44),UDim2.new(.5,-104,0,10))
countdown.BackgroundTransparency=1 countdown.UIStroke.Enabled=false countdown.Visible=false
local countdownIcon=text(countdown,"Icon","◷",UDim2.fromOffset(36,36),UDim2.fromOffset(7,4))
countdownIcon.TextSize=24 countdownIcon.Font=Enum.Font.GothamBold
local countdownText=text(countdown,"Time","00:30 • 1/8",UDim2.new(1,-48,1,0),UDim2.fromOffset(43,0))
countdownText.TextSize=16 countdownText.Font=Enum.Font.GothamBold countdownText.TextXAlignment=Enum.TextXAlignment.Left
local top=panel("Round",UDim2.fromOffset(320,60),UDim2.new(.5,-160,0,58))
top.BackgroundTransparency=1 top.UIStroke.Enabled=false
local timer=text(top,"Timer","Partida • 0:00",UDim2.new(1,0,0,30),UDim2.new())
local detail=text(top,"Detail","",UDim2.new(1,-16,0,38),UDim2.fromOffset(8,30)) detail.TextSize=12
local mode="walk"
local bar=Instance.new("Frame",gui) bar.Name="Actions" bar.BackgroundTransparency=1
bar.AnchorPoint=Vector2.new(1,1) bar.Size=UDim2.fromOffset(146,226) bar.Position=UDim2.new(1,-20,1,-175)
local function circle(name,label,x,y,callback)
 local b=button(bar,name,label,UDim2.fromOffset(62,62),UDim2.fromOffset(x,y),callback)
 b.BackgroundColor3=Color3.fromRGB(90,90,90) b.BackgroundTransparency=.58 b.TextSize=14
 b.UICorner.CornerRadius=UDim.new(1,0) b.UIStroke.Thickness=3 b.UIStroke.Transparency=.35
 local inner=Instance.new("Frame",b) inner.Name="InnerRing" inner.Size=UDim2.new(1,-12,1,-12) inner.Position=UDim2.fromOffset(6,6) inner.BackgroundTransparency=1 inner.Active=false
 local corner=Instance.new("UICorner",inner) corner.CornerRadius=UDim.new(1,0)
 local ring=Instance.new("UIStroke",inner) ring.Thickness=1.5 ring.Color=Color3.fromRGB(180,180,180) ring.Transparency=.4
 return b
end
local run=circle("Run","",78,0,function() mode=mode=="run" and "walk" or "run" event:FireServer("mode",mode) end)
local slow=circle("Slow","",0,76,function() mode=mode=="slow" and "walk" or "slow" event:FireServer("mode",mode) end)
local boost=circle("Boost","↑",0,0,function() event:FireServer("boost") end)
local kit=circle("Medkit","+",78,76,function() event:FireServer("kit") end)
local attack=circle("Attack","╱",78,76,function() event:FireServer("attack") end) attack.TextSize=36
local flashlight=circle("Flashlight","",0,152,function() event:FireServer("flashlight") end)
-- Scalable gray silhouettes within the double-ring controls.
local function segment(parent,a,b,width)
 local d=b-a local f=Instance.new("Frame",parent) f.AnchorPoint=Vector2.new(.5,.5) f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2) f.Size=UDim2.fromOffset(d.Magnitude,width) f.Rotation=math.deg(math.atan2(d.Y,d.X)) f.BorderSizePixel=0 f.BackgroundColor3=Color3.fromRGB(195,195,195)
 local c=Instance.new("UICorner",f) c.CornerRadius=UDim.new(1,0)
end
local function figure(button,crouch)
 local head=Instance.new("Frame",button) head.Size=UDim2.fromOffset(9,9) head.Position=UDim2.fromOffset(crouch and 35 or 33,crouch and 17 or 13) head.BackgroundColor3=Color3.fromRGB(195,195,195) head.BorderSizePixel=0
 local c=Instance.new("UICorner",head) c.CornerRadius=UDim.new(1,0)
 local lines=crouch and {{37,29,27,35},{27,35,39,40},{39,40,39,48},{29,35,19,43},{19,43,27,48},{35,28,23,26},{23,26,16,30}} or {{35,25,28,35},{28,35,38,40},{38,40,43,47},{28,35,21,43},{21,43,14,43},{33,27,42,30},{28,28,22,23},{22,23,17,30}}
 for _,v in ipairs(lines) do segment(button,Vector2.new(v[1],v[2]),Vector2.new(v[3],v[4]),4) end
end
figure(run,false) figure(slow,true)
do
 local body=Instance.new("Frame",flashlight) body.Size=UDim2.fromOffset(23,11) body.Position=UDim2.fromOffset(20,27) body.Rotation=-18 body.BackgroundColor3=Color3.fromRGB(205,205,205) body.BorderSizePixel=0
 local c=Instance.new("UICorner",body) c.CornerRadius=UDim.new(0,4)
 segment(flashlight,Vector2.new(38,26),Vector2.new(47,20),3)
 segment(flashlight,Vector2.new(39,31),Vector2.new(50,31),2)
 segment(flashlight,Vector2.new(38,36),Vector2.new(47,42),3)
end
local function actionLayout()
 local cam=workspace.CurrentCamera if not cam then return end
 local scale=bar:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",bar)
 scale.Scale=math.clamp(cam.ViewportSize.Y/650,.78,1)
 bar.Position=UDim2.new(1,-18,1,-math.clamp(cam.ViewportSize.Y*.26,115,190))
end
local notice=text(gui,"Notice","",UDim2.new(.72,0,0,46),UDim2.new(.14,0,1,-132)) notice.TextSize=15
local leave=button(gui,"Leave","×",UDim2.fromOffset(40,40),UDim2.new(0,16,0,70),function() event:FireServer("leave") end)
local spectate=panel("Spectate",UDim2.fromOffset(300,90),UDim2.new(.5,-150,1,-120))
local spectatorName=text(spectate,"Player","Assistindo",UDim2.new(1,0,0,34),UDim2.new())
local index=1 local watching=false local watchedId=nil
button(spectate,"Previous","‹",UDim2.fromOffset(50,38),UDim2.fromOffset(8,42),function() index-=1 watchedId=nil end)
button(spectate,"Next","›",UDim2.fromOffset(50,38),UDim2.fromOffset(242,42),function() index+=1 watchedId=nil end)
button(spectate,"Exit","Sair da câmera",UDim2.fromOffset(170,38),UDim2.fromOffset(65,42),function() event:FireServer("spectateExit") end)
local loading=panel("ArenaLoading",UDim2.fromScale(1,1),UDim2.new()) loading.BackgroundTransparency=0 loading.ZIndex=80 loading.Visible=false
local loadingText=text(loading,"Status","Carregando a arena…",UDim2.new(.8,0,0,90),UDim2.fromScale(.1,.4)) loadingText.ZIndex=81
local loadToken=0
local function preload(roundId,map)
 loadToken+=1 local token=loadToken loading.Visible=true loadingText.Text="Carregando a arena…"
 task.spawn(function()
  local deadline=os.clock()+40
  while not map or not map.Parent or not map:FindFirstChild("SafePoints") do
   if os.clock()>deadline or token~=loadToken then break end
   map=workspace:FindFirstChild("ActiveArena") task.wait(.2)
  end
  if map then
   while os.clock()<deadline and token==loadToken do
    local count=0 for _,d in ipairs(map:GetDescendants()) do if d:IsA("BasePart") then count+=1 end end
    if count>=(map:GetAttribute("PartCount") or math.huge) then break end
    task.wait(.2)
   end
  end
  local done=false local ok=false
  task.spawn(function()
   if map and map.Parent then local failed=false
    ok=pcall(function() game:GetService("ContentProvider"):PreloadAsync({map},function(_,status) if status~=Enum.AssetFetchStatus.Success then failed=true end end) end)
    ok=ok and not failed and os.clock()<deadline end done=true
  end)
  while not done and os.clock()<deadline and token==loadToken do task.wait(.1) end
  if token~=loadToken then return end
  loading.Visible=false
  if done and ok and map:GetAttribute("RoundId")==roundId then event:FireServer("ready",roundId)
  else event:FireServer("loadFailed") notice.Text="Não foi possível carregar a arena. Tente novamente." end
 end)
end
local noticeUntil=0
local captureActive=false
local capture=Instance.new("Frame") capture.Name="Capture" capture.Size=UDim2.fromScale(1,1) capture.BackgroundColor3=Color3.fromRGB(105,0,7) capture.BackgroundTransparency=1 capture.BorderSizePixel=0 capture.ZIndex=95 capture.Visible=false capture.Parent=gui
local captureText=text(capture,"Killer","",UDim2.new(1,0,0,60),UDim2.new(0,0,.16,0)) captureText.TextSize=22 captureText.Font=Enum.Font.GothamBold captureText.ZIndex=96

local function caughtAnimation(killer,killerCF)
 if captureActive then return end
 captureActive=true capture.Visible=true captureText.Text=tostring(killer or "")
 local camera=workspace.CurrentCamera
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local head=char and char:FindFirstChild("Head")
 local oldType=camera and camera.CameraType
 local oldCF=camera and camera.CFrame
 local oldFov=camera and camera.FieldOfView or 70
 local rootJoint=root and root:FindFirstChildWhichIsA("Motor6D")
 local oldTransform=rootJoint and rootJoint.Transform
 if rootJoint then
  TweenService:Create(rootJoint,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transform=CFrame.new(0,-.18,0)*CFrame.Angles(math.rad(22),0,math.rad(-8))}):Play()
 end
 if camera and head and typeof(killerCF)=="CFrame" then
  local killerPos=killerCF.Position
  local dir=head.Position-killerPos
  if dir.Magnitude<.1 then dir=Vector3.new(0,0,1) end
  camera.CameraType=Enum.CameraType.Scriptable
  local start=CFrame.lookAt(head.Position+dir.Unit*1.2+Vector3.new(0,.35,0),killerPos+Vector3.new(0,1.8,0))
  local finish=CFrame.lookAt(head.Position+dir.Unit*.25+Vector3.new(0,.15,0),killerPos+Vector3.new(0,1.7,0))
  camera.CFrame=start camera.FieldOfView=58
  TweenService:Create(camera,TweenInfo.new(.42,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=finish,FieldOfView=72}):Play()
 end
 TweenService:Create(capture,TweenInfo.new(.10),{BackgroundTransparency=.58}):Play()
 task.wait(.34)
 TweenService:Create(capture,TweenInfo.new(.25),{BackgroundTransparency=1}):Play()
 task.wait(.28)
 if rootJoint and oldTransform then rootJoint.Transform=oldTransform end
 if camera then
  camera.CameraType=oldType or Enum.CameraType.Custom camera.FieldOfView=oldFov
  if oldType==Enum.CameraType.Scriptable and oldCF then camera.CFrame=oldCF
  else
   local hum=char and char:FindFirstChildOfClass("Humanoid") if hum then camera.CameraSubject=hum end
  end
 end
 capture.Visible=false captureActive=false
end

local entryFlash=Instance.new("Frame")
entryFlash.Name="EntryFlash" entryFlash.Size=UDim2.fromScale(1,1) entryFlash.BackgroundColor3=Color3.fromRGB(176,42,47)
entryFlash.BackgroundTransparency=1 entryFlash.BorderSizePixel=0 entryFlash.ZIndex=94 entryFlash.Visible=true
entryFlash:SetAttribute("PulseCount",0) entryFlash.Parent=gui

local doorGlowBusy=false
local function pulseLobbyDoor()
 if doorGlowBusy then return end
 doorGlowBusy=true
 entryFlash:SetAttribute("PulseCount",(entryFlash:GetAttribute("PulseCount") or 0)+1)
 local visual=workspace:FindFirstChild("SurviversLobbyDoorVisual")
 local glow
 if visual then
  glow=Instance.new("Highlight")
  glow.Name="LobbyDoorGlowFX" glow.Adornee=visual glow.FillColor=Color3.fromRGB(196,54,58)
  glow.OutlineColor=Color3.fromRGB(255,208,204) glow.FillTransparency=1 glow.OutlineTransparency=1
  glow.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop glow.Parent=workspace
  TweenService:Create(glow,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{FillTransparency=.38,OutlineTransparency=.08}):Play()
  for _,p in ipairs(visual:GetDescendants()) do
   if p:IsA("PointLight") and p.Name=="EntryGlow" then
    TweenService:Create(p,TweenInfo.new(.12),{Brightness=3.2,Range=22}):Play()
    task.delay(.18,function() if p.Parent then TweenService:Create(p,TweenInfo.new(.45),{Brightness=.35,Range=14}):Play() end end)
   end
  end
 end
 entryFlash.BackgroundTransparency=.86
 TweenService:Create(entryFlash,TweenInfo.new(.42,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
 task.delay(.52,function()
  if glow and glow.Parent then
   local t=TweenService:Create(glow,TweenInfo.new(.25),{FillTransparency=1,OutlineTransparency=1})
   t:Play() t.Completed:Connect(function() if glow.Parent then glow:Destroy() end end)
  end
  doorGlowBusy=false
 end)
end

local doorLeaf=nil local doorRound=nil local doorCF=nil
local function clearDoor() if doorLeaf then doorLeaf:Destroy() doorLeaf=nil end doorRound=nil end
local function closeDoor()
 if doorLeaf or not doorCF then return end
 doorLeaf=Instance.new("Part") doorLeaf.Name="PrivateEntranceDoor" doorLeaf.Size=Vector3.new(6,8,.6) doorLeaf.Anchored=true doorLeaf.CanCollide=true doorLeaf.Material=Enum.Material.WoodPlanks doorLeaf.Color=Color3.fromRGB(39,29,28)
 doorLeaf.CFrame=doorCF*CFrame.new(-3,1,0)*CFrame.Angles(0,-math.pi/2,0)*CFrame.new(3,0,0) doorLeaf.Parent=workspace
 TweenService:Create(doorLeaf,TweenInfo.new(.65,Enum.EasingStyle.Sine),{CFrame=doorCF*CFrame.new(0,1,0)}):Play()
end
net.Update.OnClientEvent:Connect(function(action,a,b)
 if action=="lobbyDoorGlow" then pulseLobbyDoor()
 elseif action=="entrance" then clearDoor() doorRound=a doorCF=b
 elseif action=="closeEntrance" and a==doorRound then closeDoor()
 elseif action=="reset" then clearDoor() doorCF=nil loadToken+=1 loading.Visible=false if jasonTheme.IsPlaying then jasonTheme:Stop() end
 elseif action=="notice" then notice.Text=a noticeUntil=os.clock()+5
 elseif action=="load" then preload(a,b)
 elseif action=="caught" then task.spawn(caughtAnimation,a,b) end
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or not player:GetAttribute("InRound") then return end
 if input.KeyCode==Enum.KeyCode.LeftShift then mode="run" event:FireServer("mode",mode)
 elseif input.KeyCode==Enum.KeyCode.C then mode=mode=="slow" and "walk" or "slow" event:FireServer("mode",mode)
 elseif input.UserInputType==Enum.UserInputType.MouseButton1 and player:GetAttribute("IsJason") then event:FireServer("attack")
 elseif input.KeyCode==Enum.KeyCode.Q then event:FireServer("boost")
 elseif input.KeyCode==Enum.KeyCode.F then event:FireServer("flashlight")
 elseif input.KeyCode==Enum.KeyCode.E then event:FireServer("kit") end
end)
UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.LeftShift and mode=="run" then mode="walk" event:FireServer("mode",mode) end end)
local highlight=Instance.new("Highlight") highlight.Name="PursuerTarget" highlight.FillColor=Color3.fromRGB(200,35,43) highlight.OutlineColor=Color3.fromRGB(242,80,85) highlight.FillTransparency=.8 highlight.DepthMode=Enum.HighlightDepthMode.Occluded highlight.Enabled=false highlight.Parent=gui
local localPortalInside=false
RunService.RenderStepped:Connect(function()
 local gate=workspace:FindFirstChild("LobbyJoinPortal")
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not gate or not root or player:GetAttribute("InRound") then localPortalInside=false return end
 local lp=gate.CFrame:PointToObjectSpace(root.Position)
 local inside=math.abs(lp.X)<=gate.Size.X/2 and math.abs(lp.Y)<=gate.Size.Y/2 and math.abs(lp.Z)<=gate.Size.Z/2
 if inside and not localPortalInside then pulseLobbyDoor() end
 localPortalInside=inside
end)

local jasonPresentationFov=70
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera
 if not camera then return end
 local isJason=player:GetAttribute("IsJason")==true
 local active=isJason and player:GetAttribute("InRound")==true and player:GetAttribute("InMenu")~=true and player:GetAttribute("Spectating")~=true and not captureActive
 if active then
  if not jasonTheme.IsPlaying then jasonTheme:Play() end
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local speed=root and (root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
  local targetFov=speed>4 and 84 or 78
  jasonPresentationFov+=(targetFov-jasonPresentationFov)*math.min(1,dt*6)
  if camera.CameraType~=Enum.CameraType.Scriptable then camera.FieldOfView=jasonPresentationFov end
 else
  if jasonTheme.IsPlaying then jasonTheme:Stop() end
  jasonPresentationFov+=(70-jasonPresentationFov)*math.min(1,dt*6)
  if player:GetAttribute("InMenu")~=true and player:GetAttribute("Spectating")~=true and not captureActive and camera.CameraType~=Enum.CameraType.Scriptable then
   camera.FieldOfView=jasonPresentationFov
  end
 end
end)

local dtSum=0
RunService.RenderStepped:Connect(function(dt)
 dtSum+=dt if dtSum<.1 then return end dtSum=0
 local hidden=player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("SweanLoadingDone")~=true
 local controlsVisible=player:GetAttribute("InMenu")~=true and player:GetAttribute("VoidActive")~=true and player:GetAttribute("SweanLoadingDone")==true and player:GetAttribute("Spectating")~=true
 local inRound=player:GetAttribute("InRound") local down=player:GetAttribute("Downed") local status=player:GetAttribute("RoundStatus")
 local phase=net:GetAttribute("Phase") or "Aguardando"
 local left=math.max(0,math.ceil((net:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
 countdown.Visible=not hidden and phase=="Intervalo"
 actionLayout()
 countdownText.Text=string.format("%02d:%02d • %d/%d",math.floor(left/60),left%60,net:GetAttribute("Waiting") or 0,net:GetAttribute("MaxPlayers") or 8)
 top.Visible=not hidden and phase=="Partida"
 local isJason=player:GetAttribute("IsJason")
 bar.Visible=controlsVisible leave.Visible=not hidden and inRound
 run.Visible=controlsVisible and not down and not isJason
 slow.Visible=controlsVisible and not down and not isJason
 boost.Visible=controlsVisible and not down and not isJason
 flashlight.Visible=controlsVisible and not down and not isJason
 kit.Visible=controlsVisible and inRound and not isJason
 attack.Visible=controlsVisible and inRound and isJason and not down
 boost.Text="↑" boost.TextTransparency=(inRound and player:GetAttribute("HasBoost")) and 0 or .38
 kit.Text=player:GetAttribute("HasMedkit") and "+" or "·"
 mode=player:GetAttribute("MoveMode") or "walk"
 run.UIStroke.Transparency=mode=="run" and .05 or .4
 slow.UIStroke.Transparency=mode=="slow" and .05 or .4
 flashlight.UIStroke.Transparency=player:GetAttribute("FlashlightOn") and .05 or .4
 timer.Text=string.format("%s • %d:%02d",phase,math.floor(left/60),left%60)
 local killer=net:GetAttribute("Killer") local stats=player:FindFirstChild("leaderstats") local score=stats and stats:FindFirstChild("Pontos")
 detail.Text=string.format("%s • %s • %d/8 • %d pontos",net:GetAttribute("Map") or "Lobby",killer or "",net:GetAttribute("Count") or 0,score and score.Value or 0)
 notice.Visible=not hidden
 if down then notice.Text="Caído • "..math.max(0,math.ceil((player:GetAttribute("BleedoutAt") or 0)-workspace:GetServerTimeNow())).."s para receber ajuda"
 elseif (player:GetAttribute("ReviveAt") or 0)>workspace:GetServerTimeNow() then notice.Text="Reanimando… fique parado"
 elseif os.clock()>noticeUntil then notice.Text=inRound and config.Killers[killer] and config.Killers[killer].tip or "" end
 local spec=player:GetAttribute("Spectating") and not hidden
 spectate.Visible=spec or false
 local camera=workspace.CurrentCamera
 if spec and camera and not captureActive then
  local targets={}
  for _,p in ipairs(Players:GetPlayers()) do
   local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if p~=player and p:GetAttribute("InRound") and not p:GetAttribute("IsJason") and not p:GetAttribute("VoidActive") and hum and hum.Health>0 then table.insert(targets,p) end
  end
  table.sort(targets,function(a,b) return a.UserId<b.UserId end)
  if #targets>0 then
   if watchedId then for i,p in ipairs(targets) do if p.UserId==watchedId then index=i break end end end
   index=((index-1)%#targets)+1 local p=targets[index] watchedId=p.UserId
   camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=p.Character:FindFirstChildOfClass("Humanoid") camera.FieldOfView=70
   spectatorName.Text=p.DisplayName watching=true
  else
   watchedId=nil camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   spectatorName.Text="Nenhum sobrevivente disponível" watching=true
  end
 elseif watching and not hidden and camera then watching=false watchedId=nil camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") camera.FieldOfView=70 end
 highlight.Enabled=false
 if inRound and not hidden then
  for _,m in ipairs(workspace:GetChildren()) do if m:GetAttribute("ActivePursuer") and (m:GetAttribute("TargetUserId") or 0)>0 then
   local p=Players:GetPlayerByUserId(m:GetAttribute("TargetUserId")) highlight.Adornee=p and p.Character highlight.Enabled=p~=nil break
  end end
 end
 -- Downed pose is visual only; server owns movement and bleedout.
 for _,p in ipairs(Players:GetPlayers()) do
  if p:GetAttribute("Downed") and p.Character then
   local root=p.Character:FindFirstChild("HumanoidRootPart") local motor=root and root:FindFirstChildWhichIsA("Motor6D")
   if motor then motor.Transform=CFrame.Angles(math.rad(75),0,0) end
  end
 end
end)
-- Use only an input Roblox already created for this player. Never unmute or capture audio.
task.spawn(function()
 local analyzer,wire,input
 while gui.Parent do
  local current=player:FindFirstChildWhichIsA("AudioDeviceInput")
  if current~=input then
   if analyzer then analyzer:Destroy() end if wire then wire:Destroy() end input=current
   if input then analyzer=Instance.new("AudioAnalyzer") analyzer.SpectrumEnabled=false analyzer.Parent=gui wire=Instance.new("Wire") wire.SourceInstance=input wire.TargetInstance=analyzer wire.Parent=analyzer end
  end
  if input and analyzer and player:GetAttribute("InRound") and not input.Muted then
   local level=analyzer.RmsLevel if level>.015 then event:FireServer("voice",math.clamp(level,0,1)) end
  end
  task.wait(.35)
 end
end)

