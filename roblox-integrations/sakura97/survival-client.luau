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
local Lighting=game:GetService("Lighting")
local Settings=require(net:WaitForChild("SettingsPanel"))
Settings.initialize(player)
local gui=Instance.new("ScreenGui") gui.Name="SurvivalHUD" gui.ResetOnSpawn=false gui.DisplayOrder=30 gui.Parent=player:WaitForChild("PlayerGui")
local function panel(name,size,pos)
 local f=Instance.new("Frame") f.Name=name f.Size=size f.Position=pos f.BackgroundColor3=Color3.fromRGB(12,12,15) f.BackgroundTransparency=.22 f.BorderSizePixel=0 f.Parent=gui
 local c=Instance.new("UICorner",f) c.CornerRadius=UDim.new(0,16)
 local s=Instance.new("UIStroke",f) s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Color=Color3.fromRGB(142,142,150) s.Transparency=.4 s.Thickness=2
 return f
end
local function text(parent,name,value,size,pos)
 local l=Instance.new("TextLabel") l.Name=name l.Text=value l.Size=size l.Position=pos l.BackgroundTransparency=1 l.Font=Enum.Font.GothamMedium l.TextSize=15 l.TextColor3=Color3.fromRGB(224,228,232) l.TextStrokeColor3=Color3.new(0,0,0) l.TextStrokeTransparency=.55 l.TextWrapped=true l.Parent=parent return l
end
local function button(parent,name,label,size,pos,callback)
 local b=Instance.new("TextButton") b.Name=name b.Text=label b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(18,18,22) b.BackgroundTransparency=.12 b.TextColor3=Color3.fromRGB(239,239,242) b.Font=Enum.Font.GothamSemibold b.TextSize=14 b.BorderSizePixel=0 b.Parent=parent
 local c=Instance.new("UICorner",b) c.CornerRadius=UDim.new(0,12)
 b.AutoButtonColor=false
 local scale=Instance.new("UIScale",b)
 local feedback
 local function pulse(value)
  if feedback then feedback:Cancel() end
  feedback=TweenService:Create(scale,TweenInfo.new(.1),{Scale=value}) feedback:Play()
 end
 b.MouseEnter:Connect(function() pulse(1.04) end)
 b.MouseLeave:Connect(function() pulse(1) end)
 b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pulse(.92) end end)
 b.InputEnded:Connect(function() pulse(1) end)
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
local topActions=Instance.new("Frame",gui) topActions.Name="TopActions" topActions.BackgroundTransparency=1
topActions.AnchorPoint=Vector2.new(1,0) topActions.Size=UDim2.fromOffset(224,52) topActions.Position=UDim2.new(1,-174,0,8)
local bar=Instance.new("Frame",gui) bar.Name="Actions" bar.BackgroundTransparency=1
bar.AnchorPoint=Vector2.new(1,1) bar.Size=UDim2.fromOffset(224,88) bar.Position=UDim2.new(1,-24,1,-92)
local function cleanAction(parent,name,label,size,pos,callback)
 local b=button(parent,name,label,size,pos,callback)
 b.BackgroundTransparency=1 b.TextSize=24 b.TextStrokeTransparency=.38
 b.UIStroke.Enabled=false b.UICorner.CornerRadius=UDim.new(1,0)
 return b
end
local run=cleanAction(topActions,"Run","»",UDim2.fromOffset(52,52),UDim2.fromOffset(0,0),function() mode=mode=="run" and "walk" or "run" event:FireServer("mode",mode) end)
local boost=cleanAction(topActions,"Boost","↑",UDim2.fromOffset(52,52),UDim2.fromOffset(56,0),function() event:FireServer("boost") end)
local flashlight=cleanAction(topActions,"Flashlight","",UDim2.fromOffset(52,52),UDim2.fromOffset(112,0),function() event:FireServer("flashlight") end)
local kit=cleanAction(topActions,"Medkit","+",UDim2.fromOffset(52,52),UDim2.fromOffset(168,0),function() event:FireServer("kit") end)
local slow=cleanAction(bar,"Slow","",UDim2.fromOffset(68,68),UDim2.fromOffset(0,16),function() mode=mode=="slow" and "walk" or "slow" event:FireServer("mode",mode) end)
local jump=cleanAction(bar,"Jump","↑",UDim2.fromOffset(72,72),UDim2.fromOffset(76,8),function()
 local char=player.Character local h=char and char:FindFirstChildOfClass("Humanoid")
 if h and player:GetAttribute("InRound") and not player:GetAttribute("Downed") and not cinematicActive then h.Jump=true end
end) jump.TextSize=34
local attack=cleanAction(bar,"Attack","╱",UDim2.fromOffset(76,76),UDim2.fromOffset(148,0),function()
 if player:GetAttribute("IsJason") then event:FireServer("attack") end
end) attack.TextSize=40
local function segment(parent,a,b,width)
 local d=b-a local f=Instance.new("Frame",parent) f.AnchorPoint=Vector2.new(.5,.5) f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2) f.Size=UDim2.fromOffset(d.Magnitude,width) f.Rotation=math.deg(math.atan2(d.Y,d.X)) f.BorderSizePixel=0 f.BackgroundColor3=Color3.fromRGB(236,236,240)
 local c=Instance.new("UICorner",f) c.CornerRadius=UDim.new(1,0)
end
local function crouchFigure(button)
 local head=Instance.new("Frame",button) head.Size=UDim2.fromOffset(9,9) head.Position=UDim2.fromOffset(39,18) head.BackgroundColor3=Color3.fromRGB(236,236,240) head.BorderSizePixel=0
 local c=Instance.new("UICorner",head) c.CornerRadius=UDim.new(1,0)
 for _,v in ipairs({{41,30,29,37},{29,37,43,43},{43,43,43,53},{31,37,21,46},{21,46,29,52},{39,29,26,27},{26,27,18,32}}) do segment(button,Vector2.new(v[1],v[2]),Vector2.new(v[3],v[4]),4) end
end
crouchFigure(slow)
do
 local body=Instance.new("Frame",flashlight) body.Size=UDim2.fromOffset(20,9) body.Position=UDim2.fromOffset(16,23) body.Rotation=-18 body.BackgroundColor3=Color3.fromRGB(236,236,240) body.BorderSizePixel=0
 local c=Instance.new("UICorner",body) c.CornerRadius=UDim.new(0,4)
 segment(flashlight,Vector2.new(31,22),Vector2.new(40,17),3)
 segment(flashlight,Vector2.new(32,27),Vector2.new(43,27),2)
 segment(flashlight,Vector2.new(31,32),Vector2.new(40,38),3)
end
local function hideDefaultJump()
 local pg=player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
 for _,d in ipairs(pg:GetDescendants()) do
  if d.Name=="JumpButton" and d:IsA("GuiButton") and not d:IsDescendantOf(gui) then d.Visible=false end
 end
end
hideDefaultJump()
player:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
 if d.Name=="JumpButton" and d:IsA("GuiButton") and not d:IsDescendantOf(gui) then d.Visible=false end
end)
local function actionLayout()
 local cam=workspace.CurrentCamera if not cam then return end
 local scale=math.clamp(cam.ViewportSize.Y/650,.76,1)*math.clamp((player:GetAttribute("ControlScale") or 100)/100,.8,1.2)
 local bottomScale=bar:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",bar) bottomScale.Scale=scale
 local topScale=topActions:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",topActions) topScale.Scale=math.min(scale,.96)
 bar.Position=UDim2.new(1,-24,1,-math.clamp(cam.ViewportSize.Y*.12,76,105))
 topActions.Position=UDim2.new(1,-174,0,8)
end
local notice=text(gui,"Notice","",UDim2.new(.72,0,0,46),UDim2.new(.14,0,1,-132)) notice.TextSize=15
local leave=button(gui,"Leave","⌂",UDim2.fromOffset(42,42),UDim2.new(0,16,0,8),function() event:FireServer("leave") end)
leave.BackgroundTransparency=1 leave.UIStroke.Enabled=false leave.TextSize=25
local settingsOverlay=Instance.new("Frame",gui) settingsOverlay.Name="SettingsOverlay" settingsOverlay.Size=UDim2.fromScale(1,1) settingsOverlay.BackgroundColor3=Color3.new(0,0,0) settingsOverlay.BackgroundTransparency=.32 settingsOverlay.ZIndex=110 settingsOverlay.Visible=false
local settingsUI=Settings.build(settingsOverlay,player,function() settingsOverlay.Visible=false end)
local settingsButton=button(gui,"SettingsButton","⚙",UDim2.fromOffset(44,44),UDim2.new(1,-52,0,8),function() settingsOverlay.Visible=not settingsOverlay.Visible end) settingsButton.TextSize=27 settingsButton.BackgroundTransparency=1 settingsButton.UIStroke.Enabled=false
local firstPerson=false
local cameraButton=button(gui,"CameraMode","◉",UDim2.fromOffset(44,44),UDim2.new(1,-102,0,8),function()
 firstPerson=not firstPerson
end)
cameraButton.TextSize=23 cameraButton.BackgroundTransparency=1 cameraButton.UIStroke.Enabled=false
RunService.RenderStepped:Connect(function()
 local blocked=player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("Spectating") or player:GetAttribute("SweanLoadingDone")~=true
 cameraButton.Visible=not blocked and not settingsOverlay.Visible
 if blocked then return end
 if firstPerson then
  player.CameraMode=Enum.CameraMode.LockFirstPerson
 else
  player.CameraMode=Enum.CameraMode.Classic
  player.CameraMinZoomDistance=10 player.CameraMaxZoomDistance=10
 end
 cameraButton.Text=firstPerson and "1ª" or "3ª"
end)
local profileHUD=panel("Profile",UDim2.fromOffset(190,58),UDim2.fromOffset(18,66)) profileHUD.BackgroundTransparency=1 profileHUD.UIStroke.Enabled=false
local xpTrack=Instance.new("Frame",profileHUD) xpTrack.Name="XP" xpTrack.Size=UDim2.new(1,0,0,22) xpTrack.BackgroundColor3=Color3.fromRGB(22,23,32) xpTrack.BackgroundTransparency=.3 xpTrack.BorderSizePixel=0 Instance.new("UICorner",xpTrack).CornerRadius=UDim.new(0,5)
local xpFill=Instance.new("Frame",xpTrack) xpFill.Name="Fill" xpFill.Size=UDim2.fromScale(0,1) xpFill.BackgroundColor3=Color3.fromRGB(96,118,205) xpFill.BorderSizePixel=0 Instance.new("UICorner",xpFill).CornerRadius=UDim.new(0,5)
local levelText=text(xpTrack,"Level","NÍVEL 1",UDim2.new(1,-12,1,0),UDim2.fromOffset(6,0)) levelText.TextSize=11 levelText.Font=Enum.Font.GothamBold levelText.TextXAlignment=Enum.TextXAlignment.Left
local pointsText=text(profileHUD,"Points","◉  0",UDim2.new(1,0,0,28),UDim2.fromOffset(0,26)) pointsText.TextSize=19 pointsText.TextColor3=Color3.fromRGB(165,215,121) pointsText.TextXAlignment=Enum.TextXAlignment.Left
local healthHUD=panel("Condition",UDim2.fromOffset(148,38),UDim2.new(0,18,1,-52)) healthHUD.UIStroke.Color=Color3.fromRGB(106,150,91)
local condition=text(healthHUD,"Value","♥  INTEIRO",UDim2.fromScale(1,1),UDim2.new()) condition.Font=Enum.Font.GothamBold condition.TextSize=14 condition.TextColor3=Color3.fromRGB(144,223,111)
local quickItems=panel("QuickItems",UDim2.fromOffset(200,34),UDim2.new(.5,-100,1,-54)) quickItems.BackgroundTransparency=.35
local itemText=text(quickItems,"Items","",UDim2.fromScale(1,1),UDim2.new()) itemText.TextSize=11
local musicPanel
local musicButton=button(gui,"MusicButton","♫",UDim2.fromOffset(46,46),UDim2.new(1,-152,0,8),function() musicPanel.Visible=not musicPanel.Visible end)
musicButton.BackgroundTransparency=1 musicButton.UIStroke.Enabled=false musicButton.TextSize=22 musicButton.UICorner.CornerRadius=UDim.new(1,0)
musicPanel=panel("MusicPanel",UDim2.fromOffset(286,190),UDim2.new(1,-306,0,232)) musicPanel.Visible=false musicPanel.ZIndex=60
local musicTitle=text(musicPanel,"Title","MUSIC  •  20 PONTOS",UDim2.new(1,-24,0,30),UDim2.fromOffset(12,8)) musicTitle.Font=Enum.Font.GothamBold musicTitle.ZIndex=61
local musicId=Instance.new("TextBox") musicId.Name="AudioId" musicId.PlaceholderText="ID do áudio" musicId.Text="" musicId.ClearTextOnFocus=false musicId.Size=UDim2.new(1,-24,0,36) musicId.Position=UDim2.fromOffset(12,42) musicId.BackgroundColor3=Color3.fromRGB(32,30,35) musicId.TextColor3=Color3.fromRGB(238,238,240) musicId.PlaceholderColor3=Color3.fromRGB(160,160,166) musicId.Font=Enum.Font.Gotham musicId.TextSize=15 musicId.ZIndex=61 musicId.Parent=musicPanel Instance.new("UICorner",musicId).CornerRadius=UDim.new(0,9)
local musicStatus=text(musicPanel,"Status","Desbloqueie o item Music para receber Cantor e inserir um ID.",UDim2.new(1,-24,0,38),UDim2.fromOffset(12,82)) musicStatus.TextSize=11 musicStatus.ZIndex=61
local musicBuy=button(musicPanel,"BuyMusic","Desbloquear Music • 20 pts",UDim2.new(1,-24,0,32),UDim2.fromOffset(12,124),function() event:FireServer("musicBuy") end) musicBuy.ZIndex=62
local musicPlay=button(musicPanel,"PlayMusic","Tocar",UDim2.fromOffset(124,28),UDim2.fromOffset(12,160),function() event:FireServer("musicPlay",musicId.Text) end) musicPlay.ZIndex=62
local musicStop=button(musicPanel,"StopMusic","Parar",UDim2.fromOffset(124,28),UDim2.new(1,-136,0,160),function() event:FireServer("musicStop") end) musicStop.ZIndex=62
local function updateSinger() local owned=player:GetAttribute("Cantor")==true musicId.TextEditable=owned musicStatus.Text=owned and "🎤 CANTOR • use um ID de áudio" or "Desbloqueie Music por 20 Pontos para receber o distintivo Cantor." musicBuy.Visible=not owned end
updateSinger() if player.GetAttributeChangedSignal then player:GetAttributeChangedSignal("Cantor"):Connect(updateSinger) end
musicId.FocusLost:Connect(function(enter) if enter and player:GetAttribute("Cantor") then event:FireServer("musicPlay",musicId.Text) end end)
local result=panel("RoundResult",UDim2.new(.92,0,.82,0),UDim2.fromScale(.5,.5)) result.AnchorPoint=Vector2.new(.5,.5) result.Visible=false result.ZIndex=70 result.ClipsDescendants=true
local resultLimit=Instance.new("UISizeConstraint",result) resultLimit.MaxSize=Vector2.new(1050,650)
local resultHeader=text(result,"Header","FIM DA PARTIDA",UDim2.new(1,-74,0,34),UDim2.fromOffset(18,12)) resultHeader.Font=Enum.Font.GothamBlack resultHeader.TextSize=22 resultHeader.TextXAlignment=Enum.TextXAlignment.Left resultHeader.ZIndex=71
local resultSubtitle=text(result,"Subtitle","",UDim2.new(.65,-20,0,26),UDim2.fromOffset(18,46)) resultSubtitle.TextSize=12 resultSubtitle.TextXAlignment=Enum.TextXAlignment.Left resultSubtitle.ZIndex=71
local resultRows=Instance.new("ScrollingFrame",result) resultRows.Name="Ranking" resultRows.BackgroundTransparency=1 resultRows.BorderSizePixel=0 resultRows.Position=UDim2.fromOffset(16,80) resultRows.Size=UDim2.new(.64,-20,1,-100) resultRows.ZIndex=71 resultRows.AutomaticCanvasSize=Enum.AutomaticSize.Y resultRows.CanvasSize=UDim2.new() resultRows.ScrollBarThickness=3 resultRows.ScrollBarImageColor3=Color3.fromRGB(156,83,86)
local resultList=Instance.new("UIListLayout",resultRows) resultList.Padding=UDim.new(0,6) resultList.SortOrder=Enum.SortOrder.LayoutOrder
local resultSide=text(result,"WinnerIcon","✦",UDim2.new(.34,-12,.6,0),UDim2.new(.65,0,.17,0)) resultSide.Font=Enum.Font.GothamBlack resultSide.TextSize=72 resultSide.ZIndex=71
local resultView=Instance.new("ViewportFrame",result) resultView.Name="WinnerPortrait" resultView.BackgroundTransparency=1 resultView.Size=UDim2.new(.36,-14,.64,0) resultView.Position=UDim2.new(.64,0,.14,0) resultView.ZIndex=72 resultView.Ambient=Color3.fromRGB(120,95,96) resultView.LightColor=Color3.fromRGB(255,188,177) resultView.LightDirection=Vector3.new(-1,-.4,-1)
local resultWorld=Instance.new("WorldModel",resultView)
local resultCamera=Instance.new("Camera",resultView) resultCamera.FieldOfView=38 resultView.CurrentCamera=resultCamera
local resultWinner=text(result,"Winner","",UDim2.new(.34,-20,.17,0),UDim2.new(.65,0,.78,0)) resultWinner.Font=Enum.Font.GothamBold resultWinner.TextSize=14 resultWinner.ZIndex=73
local resultUntil=0 local resultGeneration=0
local function hideResult()
 result.Visible=false resultGeneration+=1 resultWorld:ClearAllChildren()
end
local resultClose=button(result,"Close","×",UDim2.fromOffset(40,40),UDim2.new(1,-52,0,10),hideResult) resultClose.ZIndex=74 resultClose.TextSize=26
local function showResult(data)
 hideResult()
 local generation=resultGeneration
 for _,old in ipairs(resultRows:GetChildren()) do if old:IsA("Frame") then old:Destroy() end end
 resultRows.CanvasPosition=Vector2.zero
 resultHeader.Text=data.jasonWon and "JASON VENCEU" or "SOBREVIVENTES VENCERAM"
 resultHeader.TextColor3=data.jasonWon and Color3.fromRGB(227,97,102) or Color3.fromRGB(224,225,230)
 resultSubtitle.Text=(data.map or "").."  •  SUA RECOMPENSA +"..tostring(data.xp or 0).." XP"
 resultSide.Visible=not data.jasonWon resultView.Visible=data.jasonWon==true
 resultWinner.Text=data.jasonWon and "JASON\nNINGUÉM ESCAPOU" or "SOBREVIVENTES\nA ESPERANÇA RESISTIU"
 if data.jasonWon then
  local template=net:FindFirstChild("PresentationJason")
  if template then
   local model=template:Clone() model.Name="WinnerJason" model:SetAttribute("PresentationPursuer",true)
   model.Parent=resultWorld model:PivotTo(CFrame.identity)
   local cf,size=model:GetBoundingBox()
   local focus=cf.Position+Vector3.new(0,size.Y*.08,0)
   local distance=math.max(size.Y,size.X)*1.75
   local forward=model.PrimaryPart and model.PrimaryPart.CFrame.LookVector or Vector3.new(0,0,-1)
   resultCamera.CFrame=CFrame.lookAt(focus+forward*distance+Vector3.new(0,size.Y*.04,0),focus)
  end
 end
 for i,row in ipairs(data.board or {}) do if i>8 then break end
  local card=Instance.new("Frame",resultRows) card.Name="Rank"..i card.Size=UDim2.new(1,-6,0,62) card.LayoutOrder=i card.BorderSizePixel=0 card.ZIndex=72 card.BackgroundColor3=row.userId==player.UserId and Color3.fromRGB(79,35,40) or Color3.fromRGB(39,35,40) card.BackgroundTransparency=.28 Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
  local rank=text(card,"Position",string.format("%02d",i),UDim2.fromOffset(34,58),UDim2.fromOffset(2,0)) rank.TextSize=17 rank.ZIndex=73 rank.TextColor3=Color3.fromRGB(174,130,134)
  local name=text(card,"Name",row.name or "Jogador",UDim2.new(1,-48,0,26),UDim2.fromOffset(40,5)) name.Font=Enum.Font.GothamBold name.TextSize=13 name.TextXAlignment=Enum.TextXAlignment.Left name.ZIndex=73 name.TextTruncate=Enum.TextTruncate.AtEnd name.TextWrapped=false
  local seconds=math.max(0,row.time or 0)
  local level=math.clamp(row.level or 1,1,1000) local symbol=level>=100 and "✦" or level>=25 and "◆" or "◇"
  local stats=string.format("%d:%02d  •  %d golpes  •  %d quedas  •  %s %d",math.floor(seconds/60),seconds%60,row.hits or 0,row.falls or 0,symbol,level)
  local metrics=text(card,"Stats",stats,UDim2.new(1,-48,0,26),UDim2.fromOffset(40,30)) metrics.TextSize=11 metrics.TextXAlignment=Enum.TextXAlignment.Left metrics.ZIndex=73 metrics.TextColor3=Color3.fromRGB(183,178,186)
 end
 -- Show the original winning performance full-screen before the ranking.
 result.Size=UDim2.new(.92,0,.82,0) resultLimit.MaxSize=Vector2.new(1050,650)
 resultView.Size=UDim2.new(.36,-14,.64,0) resultView.Position=UDim2.new(.64,0,.14,0)
 resultRows.Visible=true resultSubtitle.Visible=true resultWinner.Visible=true
 if data.jasonWon then
  result.Size=UDim2.fromScale(1,1) resultLimit.MaxSize=Vector2.new(10000,10000)
  resultView.Size=UDim2.fromScale(1,1) resultView.Position=UDim2.new()
  resultRows.Visible=false resultSubtitle.Visible=false resultWinner.Visible=false
  resultHeader.ZIndex=73
  task.delay(4,function()
   if generation~=resultGeneration or not result.Visible then return end
   result.Size=UDim2.new(.92,0,.82,0) resultLimit.MaxSize=Vector2.new(1050,650)
   resultView.Size=UDim2.new(.36,-14,.64,0) resultView.Position=UDim2.new(.64,0,.14,0)
   resultRows.Visible=true resultSubtitle.Visible=true resultWinner.Visible=true
  end)
 end
 result.BackgroundTransparency=.75 result.Position=UDim2.fromScale(.5,.53) result.Visible=true resultUntil=os.clock()+12
 TweenService:Create(result,TweenInfo.new(.42,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=.08,Position=UDim2.fromScale(.5,.5)}):Play()
 task.delay(12,function() if generation==resultGeneration then hideResult() end end)
end

local spectate=panel("Spectate",UDim2.fromOffset(300,90),UDim2.new(.5,-150,1,-120))
local spectatorName=text(spectate,"Player","Assistindo",UDim2.new(1,0,0,34),UDim2.new())
local index=1 local watching=false local watchedId=nil
button(spectate,"Previous","‹",UDim2.fromOffset(50,38),UDim2.fromOffset(8,42),function() index-=1 watchedId=nil end)
button(spectate,"Next","›",UDim2.fromOffset(50,38),UDim2.fromOffset(242,42),function() index+=1 watchedId=nil end)
button(spectate,"Exit","Sair da câmera",UDim2.fromOffset(170,38),UDim2.fromOffset(65,42),function() event:FireServer("spectateExit") end)
local loading=panel("ArenaLoading",UDim2.fromScale(1,1),UDim2.new()) loading.BackgroundTransparency=0 loading.ZIndex=80 loading.Visible=false
local loadingText=text(loading,"Status","Carregando a arena…",UDim2.new(.8,0,0,90),UDim2.fromScale(.1,.4)) loadingText.ZIndex=81
local cinematicActive=false
local loadToken=0
local function preload(roundId,map)
 loadToken+=1 local token=loadToken loading.Visible=true loadingText.Text="Preparando a arena…"
 task.spawn(function()
  local deadline=os.clock()+18 local geometryReady=false
  while os.clock()<deadline and token==loadToken do
   map=map and map.Parent and map or workspace:FindFirstChild("ActiveArena")
   if map and map:GetAttribute("RoundId")==roundId and map:FindFirstChild("SafePoints") then
    local count=0 for _,d in ipairs(map:GetDescendants()) do if d:IsA("BasePart") then count+=1 end end
    local expected=map:GetAttribute("PartCount") or math.huge
    loadingText.Text="Recebendo mapa • "..math.floor(math.min(1,count/expected)*100).."%"
    if count>=expected then geometryReady=true break end
   end
   task.wait(.1)
  end
  if token~=loadToken then return end
  if not geometryReady then
   loading.Visible=false event:FireServer("loadFailed",roundId)
   notice.Text="A conexão está lenta. A arena continua carregando." return
  end
  local done=false local mediaDeadline=os.clock()+8
  loadingText.Text="Preparando texturas e luzes…"
  task.spawn(function()
   pcall(function() game:GetService("ContentProvider"):PreloadAsync({map}) end)
   done=true
  end)
  while not done and os.clock()<mediaDeadline and token==loadToken and not cinematicActive do task.wait(.1) end
  if token~=loadToken then return end
  loading.Visible=false
  -- Geometry gates readiness; optional unavailable audio/decals must not eject a player.
  if map.Parent and map:GetAttribute("RoundId")==roundId then event:FireServer("ready",roundId) end
 end)
end
local noticeUntil=0
local captureActive=false local captureToken=0 local captureTween=nil
local introToken=0
local introClone=nil local introOriginal=nil local introValue=nil local introConnection=nil local introTween=nil local introHidden={}
local capture=Instance.new("Frame") capture.Name="Capture" capture.Size=UDim2.fromScale(1,1) capture.BackgroundColor3=Color3.fromRGB(105,0,7) capture.BackgroundTransparency=1 capture.BorderSizePixel=0 capture.ZIndex=95 capture.Visible=false capture.Parent=gui
local captureText=text(capture,"Killer","",UDim2.new(1,0,0,60),UDim2.new(0,0,.16,0)) captureText.TextSize=22 captureText.Font=Enum.Font.GothamBold captureText.ZIndex=96

local function cancelCapture()
 captureToken+=1 captureActive=false capture.Visible=false
 if captureTween then captureTween:Cancel() captureTween=nil end
end

local function avatarRootJoint(char)
 local root=char and char:FindFirstChild("HumanoidRootPart") if not root then return nil end
 for _,joint in ipairs(char:GetDescendants()) do
  if joint:IsA("Motor6D") and joint.Part0==root then return joint
  elseif joint:IsA("AnimationConstraint") and joint.Attachment0 and joint.Attachment0.Parent==root then return joint end
 end
end
local function caughtAnimation(killer,killerCF)
 if captureActive or player:GetAttribute("ReducedMotion") then return end
 captureToken+=1 local token=captureToken
 captureActive=true capture.Visible=true captureText.Text=tostring(killer or "")
 local camera=workspace.CurrentCamera
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local head=char and char:FindFirstChild("Head")
 local oldType=camera and camera.CameraType
 local oldCF=camera and camera.CFrame
 local oldFov=camera and camera.FieldOfView or 70
 local rootJoint=avatarRootJoint(char)
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
  captureTween=TweenService:Create(camera,TweenInfo.new(.42,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=finish,FieldOfView=72}) captureTween:Play()
 end
 TweenService:Create(capture,TweenInfo.new(.10),{BackgroundTransparency=.58}):Play()
 task.wait(.34)
 if token~=captureToken then return end
 TweenService:Create(capture,TweenInfo.new(.25),{BackgroundTransparency=1}):Play()
 task.wait(.28)
 if token~=captureToken then return end
 if rootJoint and oldTransform then rootJoint.Transform=oldTransform end
 if camera and player.Character==char and not cinematicActive and not player:GetAttribute("VoidActive") and not player:GetAttribute("InMenu") and not player:GetAttribute("Spectating") then
  camera.CameraType=oldType or Enum.CameraType.Custom camera.FieldOfView=oldFov
  if oldType==Enum.CameraType.Scriptable and oldCF then camera.CFrame=oldCF
  else
   local hum=char and char:FindFirstChildOfClass("Humanoid") if hum then camera.CameraSubject=hum end
  end
 end
 capture.Visible=false captureActive=false
end

local introTop=Instance.new("Frame",gui) introTop.Name="IntroTop" introTop.Size=UDim2.new(1,0,0,58) introTop.Position=UDim2.new() introTop.BackgroundColor3=Color3.new(0,0,0) introTop.BorderSizePixel=0 introTop.ZIndex=93 introTop.Visible=false
local introBottom=Instance.new("Frame",gui) introBottom.Name="IntroBottom" introBottom.Size=UDim2.new(1,0,0,70) introBottom.AnchorPoint=Vector2.new(0,1) introBottom.Position=UDim2.new(0,0,1,0) introBottom.BackgroundColor3=Color3.new(0,0,0) introBottom.BorderSizePixel=0 introBottom.ZIndex=93 introBottom.Visible=false

local function hideOriginalJason(model,hidden)
 if hidden then
  table.clear(introHidden)
  if model then for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then introHidden[p]=p.LocalTransparencyModifier p.LocalTransparencyModifier=1 end end end
 else
  for p,value in pairs(introHidden) do if p and p.Parent then p.LocalTransparencyModifier=value end end
  table.clear(introHidden)
 end
end

local function cameraBackTarget()
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local head=char and char:FindFirstChild("Head")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if root and head then
  local pos=head.Position-root.CFrame.LookVector*7+Vector3.new(0,2.3,0)
  return CFrame.lookAt(pos,head.Position+Vector3.new(0,.45,0)),hum
 end
 return nil,hum
end

local function cancelJasonIntro(restore)
 introToken+=1
 cinematicActive=false gui:SetAttribute("CinematicActive",false)
 if introTween then pcall(function() introTween:Cancel() end) introTween=nil end
 if introConnection then introConnection:Disconnect() introConnection=nil end
 if introValue then introValue:Destroy() introValue=nil end
 if introClone then introClone:Destroy() introClone=nil end
 hideOriginalJason(introOriginal,false) introOriginal=nil
 introTop.Visible=false introBottom.Visible=false
 if restore then
  local camera=workspace.CurrentCamera
  local _,hum=cameraBackTarget()
  if camera then
   camera.CameraType=Enum.CameraType.Custom
   if hum then camera.CameraSubject=hum end
   camera.FieldOfView=70
  end
 end
end

local function playJasonIntro(data,original)
 if cinematicActive or captureActive or type(data)~="table" or not original or not original.Parent then return end
 local camera=workspace.CurrentCamera
 if not camera or typeof(data.startCF)~="CFrame" or typeof(data.endCF)~="CFrame" or typeof(data.cameraCF)~="CFrame" then return end
 local duration=math.clamp(tonumber(data.duration) or 4,3.5,5)
 local runDuration=math.clamp(tonumber(data.runDuration) or 3.15,2.5,duration-.5)
 introToken+=1 local token=introToken
 cinematicActive=true gui:SetAttribute("CinematicActive",true)
 loading.Visible=false
 introTop.Visible=true introBottom.Visible=true
 introOriginal=original hideOriginalJason(original,true)
 introClone=original:Clone()
 introClone.Name="LocalJasonIntro"
 introClone:SetAttribute("ActivePursuer",nil)
 introClone:SetAttribute("CinematicPursuer",true)
 introClone:SetAttribute("IntroAt",workspace:GetServerTimeNow())
 introClone:SetAttribute("IntroRunDuration",runDuration)
 introClone:SetAttribute("IntroDuration",duration)
 for _,p in ipairs(introClone:GetDescendants()) do
  if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.LocalTransparencyModifier=0 end
 end
 introClone.Parent=workspace
 introClone:PivotTo(data.startCF)
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=data.cameraCF
 camera.FieldOfView=60
 introValue=Instance.new("CFrameValue")
 introValue.Name="JasonIntroPath"
 introValue.Value=data.startCF
 introConnection=introValue:GetPropertyChangedSignal("Value"):Connect(function()
  if introClone and introClone.Parent then introClone:PivotTo(introValue.Value) end
 end)
 introTween=TweenService:Create(introValue,TweenInfo.new(runDuration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Value=data.endCF})
 introTween:Play()
 task.delay(runDuration,function()
  if token~=introToken or not cinematicActive or not camera.Parent then return end
  local targetCF=cameraBackTarget()
  if targetCF then
   TweenService:Create(camera,TweenInfo.new(math.max(.55,duration-runDuration),Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{CFrame=targetCF,FieldOfView=70}):Play()
  end
 end)
 task.delay(duration,function()
  if token~=introToken or not cinematicActive then return end
  local _,hum=cameraBackTarget()
  hideOriginalJason(introOriginal,false) introOriginal=nil
  if introClone then introClone:Destroy() introClone=nil end
  if introConnection then introConnection:Disconnect() introConnection=nil end
  if introValue then introValue:Destroy() introValue=nil end
  introTween=nil introTop.Visible=false introBottom.Visible=false
  cinematicActive=false gui:SetAttribute("CinematicActive",false)
  if camera then
   camera.CameraType=Enum.CameraType.Custom
   if hum then camera.CameraSubject=hum end
  end
 end)
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
 elseif action=="jasonIntro" then playJasonIntro(a,b)
 elseif action=="entrance" then clearDoor() doorRound=a doorCF=b
 elseif action=="closeEntrance" and a==doorRound then closeDoor()
 elseif action=="reset" then cancelCapture() cancelJasonIntro(not player:GetAttribute("VoidActive") and not player:GetAttribute("InMenu")) clearDoor() doorCF=nil loadToken+=1 loading.Visible=false if jasonTheme.IsPlaying then jasonTheme:Stop() end
 elseif action=="notice" then notice.Text=a noticeUntil=os.clock()+5
 elseif action=="load" then preload(a,b)
 elseif action=="caught" or action=="executed" then task.spawn(caughtAnimation,a,b)
 elseif action=="roundResult" and type(a)=="table" then showResult(a) end
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsOverlay.Visible or result.Visible or cinematicActive or not player:GetAttribute("InRound") then return end
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
 local baseFov=player:GetAttribute("CameraFOV") or 70
 local isJason=player:GetAttribute("IsJason")==true
 local active=isJason and player:GetAttribute("InRound")==true and player:GetAttribute("InMenu")~=true and player:GetAttribute("Spectating")~=true and not captureActive and not cinematicActive
 if active then
  if player:GetAttribute("MusicEnabled")~=false then
   if not jasonTheme.IsPlaying then jasonTheme:Play() end
  elseif jasonTheme.IsPlaying then jasonTheme:Stop() end
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local speed=root and (root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
  local targetFov=player:GetAttribute("ReducedMotion") and baseFov or math.min(100,baseFov+(speed>4 and 14 or 8))
  jasonPresentationFov+=(targetFov-jasonPresentationFov)*math.min(1,dt*6)
  if camera.CameraType~=Enum.CameraType.Scriptable then camera.FieldOfView=jasonPresentationFov end
 else
  if jasonTheme.IsPlaying then jasonTheme:Stop() end
  jasonPresentationFov+=(baseFov-jasonPresentationFov)*math.min(1,dt*6)
  if player:GetAttribute("InMenu")~=true and player:GetAttribute("Spectating")~=true and not captureActive and camera.CameraType~=Enum.CameraType.Scriptable then
   camera.FieldOfView=jasonPresentationFov
  end
 end
end)

local dtSum=0
RunService.RenderStepped:Connect(function(dt)
 dtSum+=dt if dtSum<.1 then return end dtSum=0
 local hidden=player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("SweanLoadingDone")~=true or cinematicActive
 if result.Visible and os.clock()>=resultUntil then hideResult() end
 musicButton.Visible=not hidden and not result.Visible and not settingsOverlay.Visible and not player:GetAttribute("InRound") musicPanel.Visible=musicPanel.Visible and not hidden and not player:GetAttribute("InRound")
 settingsButton.Visible=not hidden and not result.Visible settingsOverlay.Visible=settingsOverlay.Visible and not hidden
 profileHUD.Visible=not hidden and not result.Visible
 local controlsVisible=not settingsOverlay.Visible and not result.Visible and player:GetAttribute("InMenu")~=true and player:GetAttribute("VoidActive")~=true and player:GetAttribute("SweanLoadingDone")==true and player:GetAttribute("Spectating")~=true and not cinematicActive
 local inRound=player:GetAttribute("InRound") local down=player:GetAttribute("Downed") local status=player:GetAttribute("RoundStatus")
 healthHUD.Visible=not hidden and inRound and not result.Visible quickItems.Visible=healthHUD.Visible and not player:GetAttribute("IsJason")
 condition.Text=down and "♥  CAÍDO" or player:GetAttribute("Injured") and "♥  FERIDO" or "♥  INTEIRO"
 condition.TextColor3=down and Color3.fromRGB(231,101,107) or player:GetAttribute("Injured") and Color3.fromRGB(229,186,100) or Color3.fromRGB(144,223,111)
 healthHUD.UIStroke.Color=condition.TextColor3
 itemText.Text="↑ "..(player:GetAttribute("HasBoost") and "1 IMPULSO" or "USADO").."   •   + "..(player:GetAttribute("HasMedkit") and "1 KIT" or "USADO")
 local stats=player:FindFirstChild("leaderstats") local xp=stats and stats:FindFirstChild("XP") local lv=stats and stats:FindFirstChild("Nível") local pts=stats and stats:FindFirstChild("Pontos")
 local n=lv and lv.Value or 1 local total=xp and xp.Value or 0 local minimum=15*(n-1)^2+35*(n-1) local nextLevel=15*n^2+35*n
 xpFill.Size=UDim2.fromScale(n>=1000 and 1 or math.clamp((total-minimum)/(nextLevel-minimum),0,1),1)
 levelText.Text="NÍVEL "..n.."   •   "..(n>=1000 and "MÁXIMO" or math.max(0,total-minimum).."/"..(nextLevel-minimum)) pointsText.Text="◉  "..(pts and pts.Value or 0)
 local phase=net:GetAttribute("Phase") or "Aguardando"
 local left=math.max(0,math.ceil((net:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
 countdown.Visible=not hidden and phase=="Intervalo"
 actionLayout()
 if left==0 and phase=="Intervalo" then countdownText.Text=player:GetAttribute("AFK") and "AFK ativado" or "Aguardando jogadores" else countdownText.Text=string.format("%02d:%02d • %d/%d",math.floor(left/60),left%60,net:GetAttribute("Waiting") or 0,net:GetAttribute("MaxPlayers") or 8) end
 top.Visible=not hidden and phase=="Partida"
 local isJason=player:GetAttribute("IsJason")
 bar.Visible=controlsVisible and inRound topActions.Visible=controlsVisible and inRound leave.Visible=controlsVisible and inRound
 run.Visible=controlsVisible and inRound and not down and not isJason and not player:GetAttribute("Injured")
 slow.Visible=controlsVisible and inRound and not down and not isJason
 jump.Visible=controlsVisible and inRound and not down
 boost.Visible=controlsVisible and inRound and not down and not isJason and not player:GetAttribute("Injured")
 flashlight.Visible=controlsVisible and inRound and not down and not isJason
 kit.Visible=controlsVisible and inRound and not isJason
 attack.Visible=controlsVisible and inRound and not down
 attack.Active=isJason attack.TextTransparency=isJason and 0 or .72
 boost.Text="↑" boost.TextTransparency=(inRound and player:GetAttribute("HasBoost")) and 0 or .45
 kit.Text=player:GetAttribute("HasMedkit") and "+" or "·"
 mode=player:GetAttribute("MoveMode") or "walk"
 run.TextTransparency=mode=="run" and 0 or .2
 jump.TextTransparency=0
 flashlight.TextTransparency=player:GetAttribute("FlashlightOn") and 0 or .18
 timer.Text=string.format("%s • %d:%02d",phase,math.floor(left/60),left%60)
 local killer=net:GetAttribute("Killer") local stats=player:FindFirstChild("leaderstats") local score=stats and stats:FindFirstChild("Pontos")
 detail.Text=string.format("%s • %s • %d/8 • %d pontos",net:GetAttribute("Map") or "Lobby",killer or "",net:GetAttribute("Count") or 0,score and score.Value or 0)
 notice.Visible=not hidden
 local reviveLeft=(player:GetAttribute("ReviveAt") or 0)-workspace:GetServerTimeNow()
 local protected=(player:GetAttribute("ProtectedUntil") or 0)-workspace:GetServerTimeNow()
 if reviveLeft>0 then notice.Text=string.format("Reanimando • %.1fs • fique parado",reviveLeft)
 elseif protected>0 and inRound then notice.Text="Protegido • "..math.ceil(protected).."s"
 elseif down then notice.Text="Caído • "..math.max(0,math.ceil((player:GetAttribute("BleedoutAt") or 0)-workspace:GetServerTimeNow())).."s para receber ajuda"

 elseif os.clock()>noticeUntil then notice.Text=inRound and config.Killers[killer] and config.Killers[killer].tip or "" end
 local spec=player:GetAttribute("Spectating") and not hidden
 spectate.Visible=spec or false
 local camera=workspace.CurrentCamera
 if spec and camera and not captureActive and not cinematicActive then
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
 -- Downed poses are applied with locomotion in PreSimulation, after the Animator.

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



if player.CharacterAdded then player.CharacterAdded:Connect(function()
 cancelCapture() cancelJasonIntro(not player:GetAttribute("InMenu") and not player:GetAttribute("VoidActive"))
end) end
if player.GetAttributeChangedSignal then
 player:GetAttributeChangedSignal("VoidActive"):Connect(function()
  if player:GetAttribute("VoidActive") then cancelCapture() cancelJasonIntro(false) loading.Visible=false end
 end)
end
