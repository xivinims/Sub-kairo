local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer local net=RS:WaitForChild("Survival") local event=net.Action
local config=require(net.Config)
local gui=Instance.new("ScreenGui") gui.Name="SurvivalHUD" gui.ResetOnSpawn=false gui.DisplayOrder=30 gui.Parent=player:WaitForChild("PlayerGui")
local function panel(name,size,pos)
 local f=Instance.new("Frame") f.Name=name f.Size=size f.Position=pos f.BackgroundColor3=Color3.fromRGB(22,25,29) f.BackgroundTransparency=.3 f.BorderSizePixel=0 f.Parent=gui
 local c=Instance.new("UICorner",f) c.CornerRadius=UDim.new(0,14)
 return f
end
local function text(parent,name,value,size,pos)
 local l=Instance.new("TextLabel") l.Name=name l.Text=value l.Size=size l.Position=pos l.BackgroundTransparency=1 l.Font=Enum.Font.GothamMedium l.TextSize=15 l.TextColor3=Color3.fromRGB(224,228,232) l.TextWrapped=true l.Parent=parent return l
end
local function button(parent,name,label,size,pos,callback)
 local b=Instance.new("TextButton") b.Name=name b.Text=label b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(42,46,51) b.BackgroundTransparency=.2 b.TextColor3=Color3.fromRGB(226,230,234) b.Font=Enum.Font.GothamMedium b.TextSize=14 b.BorderSizePixel=0 b.Parent=parent
 local c=Instance.new("UICorner",b) c.CornerRadius=UDim.new(0,12)
 local stroke=Instance.new("UIStroke",b) stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border stroke.Color=Color3.fromRGB(99,105,111) stroke.Transparency=.65
 b.Activated:Connect(function()
  if player:GetAttribute("MenuSounds")~=false then local s=RS.XNMedia.MenuClick:Clone() s.Parent=b s:Play() game:GetService("Debris"):AddItem(s,3) end
  callback()
 end) return b
end
local countdown=panel("Countdown",UDim2.fromOffset(208,44),UDim2.new(.5,-104,0,10))
countdown.BackgroundTransparency=.16 countdown.Visible=false
local countdownIcon=text(countdown,"Icon","◷",UDim2.fromOffset(36,36),UDim2.fromOffset(7,4))
countdownIcon.TextSize=24 countdownIcon.Font=Enum.Font.GothamBold
local countdownText=text(countdown,"Time","00:30 • 1/8",UDim2.new(1,-48,1,0),UDim2.fromOffset(43,0))
countdownText.TextSize=16 countdownText.Font=Enum.Font.GothamBold countdownText.TextXAlignment=Enum.TextXAlignment.Left
local top=panel("Round",UDim2.fromOffset(290,72),UDim2.new(.5,-145,0,60))
local timer=text(top,"Timer","Partida • 0:00",UDim2.new(1,0,0,30),UDim2.new())
local detail=text(top,"Detail","",UDim2.new(1,-16,0,38),UDim2.fromOffset(8,30)) detail.TextSize=12
local join=button(gui,"Join","Participar",UDim2.fromOffset(180,44),UDim2.new(.5,-90,1,-65),function() event:FireServer("join") end)
local bar=panel("Actions",UDim2.fromOffset(300,108),UDim2.new(1,-314,1,-180))
local mode="walk"
local run=button(bar,"Run","Correr",UDim2.fromOffset(140,42),UDim2.fromOffset(8,8),function() mode=mode=="run" and "walk" or "run" event:FireServer("mode",mode) end)
local slow=button(bar,"Slow","Andar devagar",UDim2.fromOffset(140,42),UDim2.fromOffset(152,8),function() mode=mode=="slow" and "walk" or "slow" event:FireServer("mode",mode) end)
local boost=button(bar,"Boost","Impulso ×1",UDim2.fromOffset(140,42),UDim2.fromOffset(8,58),function() event:FireServer("boost") end)
local kit=button(bar,"Medkit","Kit médico ×1",UDim2.fromOffset(140,42),UDim2.fromOffset(152,58),function() event:FireServer("kit") end)
local notice=text(gui,"Notice","",UDim2.new(.8,0,0,52),UDim2.new(.1,0,.68,0)) notice.TextSize=16
local leave=button(gui,"Leave","Voltar ao lobby",UDim2.fromOffset(130,36),UDim2.new(0,12,0,100),function() event:FireServer("leave") end)
local spectate=panel("Spectate",UDim2.fromOffset(300,90),UDim2.new(.5,-150,1,-120))
local spectatorName=text(spectate,"Player","Assistindo",UDim2.new(1,0,0,34),UDim2.new())
local index=1 local watching=false
button(spectate,"Previous","‹",UDim2.fromOffset(50,38),UDim2.fromOffset(8,42),function() index-=1 end)
button(spectate,"Next","›",UDim2.fromOffset(50,38),UDim2.fromOffset(242,42),function() index+=1 end)
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
net.Update.OnClientEvent:Connect(function(action,a,b)
 if action=="notice" then notice.Text=a noticeUntil=os.clock()+5
 elseif action=="load" then preload(a,b) end
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or not player:GetAttribute("InRound") then return end
 if input.KeyCode==Enum.KeyCode.LeftShift then mode="run" event:FireServer("mode",mode)
 elseif input.KeyCode==Enum.KeyCode.C then mode=mode=="slow" and "walk" or "slow" event:FireServer("mode",mode)
 elseif input.KeyCode==Enum.KeyCode.Q then event:FireServer("boost")
 elseif input.KeyCode==Enum.KeyCode.E then event:FireServer("kit") end
end)
UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.LeftShift and mode=="run" then mode="walk" event:FireServer("mode",mode) end end)
local highlight=Instance.new("Highlight") highlight.Name="PursuerTarget" highlight.FillColor=Color3.fromRGB(200,35,43) highlight.OutlineColor=Color3.fromRGB(242,80,85) highlight.FillTransparency=.8 highlight.DepthMode=Enum.HighlightDepthMode.Occluded highlight.Enabled=false highlight.Parent=gui
local dtSum=0
RunService.RenderStepped:Connect(function(dt)
 dtSum+=dt if dtSum<.1 then return end dtSum=0
 local hidden=player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("SweanLoadingDone")~=true
 local inRound=player:GetAttribute("InRound") local down=player:GetAttribute("Downed") local status=player:GetAttribute("RoundStatus")
 local phase=net:GetAttribute("Phase") or "Aguardando"
 local left=math.max(0,math.ceil((net:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
 countdown.Visible=phase=="Intervalo"
 countdownText.Text=string.format("%02d:%02d • %d/%d",math.floor(left/60),left%60,net:GetAttribute("Waiting") or 0,net:GetAttribute("MaxPlayers") or 8)
 top.Visible=not hidden and phase=="Partida"
 join.Visible=not hidden and phase=="Partida" and not inRound and status~="eliminated" and status~="loading"
 bar.Visible=not hidden and inRound leave.Visible=not hidden and inRound
 run.Visible=not down slow.Visible=not down boost.Visible=not down
 boost.Text=player:GetAttribute("HasBoost") and "Impulso ×1" or "Impulso usado"
 kit.Text=player:GetAttribute("HasMedkit") and (down and "Me reanimar" or "Reanimar • kit ×1") or "Kit usado"
 mode=player:GetAttribute("MoveMode") or "walk" run.Text=mode=="run" and "Correr ✓" or "Correr" slow.Text=mode=="slow" and "Devagar ✓" or "Andar devagar"
 join.Text=player:GetAttribute("Queued") and "Cancelar participação" or net:GetAttribute("Phase")=="Partida" and "Entrar na partida" or "Participar da próxima"
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
 if spec and camera then
  local targets={} for _,p in ipairs(Players:GetPlayers()) do if p~=player and p:GetAttribute("InRound") and p.Character and p.Character:FindFirstChildOfClass("Humanoid") then table.insert(targets,p) end end
  table.sort(targets,function(a,b) return a.UserId<b.UserId end)
  if #targets>0 then index=((index-1)%#targets)+1 local p=targets[index] camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=p.Character:FindFirstChildOfClass("Humanoid") spectatorName.Text=p.DisplayName watching=true
  else spectatorName.Text="Aguardando sobreviventes…" end
 elseif watching and not hidden and camera then watching=false camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
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
