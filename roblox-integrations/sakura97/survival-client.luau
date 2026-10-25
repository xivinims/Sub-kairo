local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer local net=RS:WaitForChild("Survival") local event=net.Action
local config=require(net.Config)
local Lighting=game:GetService("Lighting")
local Settings=require(net:WaitForChild("SettingsPanel"))
Settings.initialize(player)

local roundMusic=SoundService:FindFirstChild("SuviversMatchMusic")
if not roundMusic then
 roundMusic=Instance.new("Sound")
 roundMusic.Name="SuviversMatchMusic"
 roundMusic.SoundId="rbxassetid://108879410219148"
 roundMusic.Volume=.35
 roundMusic.Looped=true
 roundMusic.Parent=SoundService
end
roundMusic.SoundId="rbxassetid://108879410219148"
roundMusic.Volume=.35
roundMusic.Looped=true
local roundMusicActive=false
local function updateRoundMusic(forceStop)
 local shouldPlay=not forceStop
  and player:GetAttribute("InRound")==true
  and player:GetAttribute("InMenu")~=true
  and player:GetAttribute("VoidActive")~=true
  and player:GetAttribute("Spectating")~=true
  and player:GetAttribute("RoundStatus")~="eliminated"
  and player:GetAttribute("SweanLoadingDone")==true
 if shouldPlay then
  if not roundMusicActive then
   roundMusicActive=true
   if not roundMusic.IsPlaying then roundMusic:Play() end
  end
 elseif roundMusicActive or forceStop or roundMusic.IsPlaying then
  roundMusicActive=false
  roundMusic:Stop()
  roundMusic.TimePosition=0
 end
end
for _,attr in ipairs({"InRound","InMenu","VoidActive","Spectating","RoundStatus","SweanLoadingDone"}) do
 player:GetAttributeChangedSignal(attr):Connect(function() updateRoundMusic(false) end)
end

local gui=Instance.new("ScreenGui") gui.Name="SurvivalHUD" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.DisplayOrder=30 gui.Parent=player:WaitForChild("PlayerGui")
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
local top=panel("Round",UDim2.fromOffset(130,38),UDim2.new(.5,-65,0,8))
top.BackgroundTransparency=1 top.UIStroke.Enabled=false
local timer=text(top,"Timer","0:00",UDim2.fromScale(1,1),UDim2.new()) timer.Font=Enum.Font.GothamBold timer.TextSize=17
local detail=text(top,"Detail","",UDim2.new(),UDim2.new()) detail.Visible=false
local mode="walk"
local topActions=Instance.new("Frame",gui) topActions.Name="TopActions" topActions.BackgroundTransparency=1
topActions.AnchorPoint=Vector2.new(1,1) topActions.Size=UDim2.fromOffset(136,64) topActions.Position=UDim2.new(1,-165,1,-115)
local bar=Instance.new("Frame",gui) bar.Name="Actions" bar.BackgroundTransparency=1
bar.AnchorPoint=Vector2.new(1,1) bar.Size=UDim2.fromOffset(150,74) bar.Position=UDim2.new(1,-84,1,-86)
local function cleanAction(parent,name,label,size,pos,callback)
 local b=button(parent,name,label,size,pos,callback)
 b.BackgroundTransparency=1 b.TextSize=24 b.TextStrokeTransparency=.38
 b.UIStroke.Enabled=false b.UICorner.CornerRadius=UDim.new(1,0)
 return b
end
local run=cleanAction(topActions,"Run","CORRER",UDim2.fromOffset(64,64),UDim2.fromOffset(72,0),function() end)
run.TextSize=11 run.BackgroundTransparency=.35 run.BackgroundColor3=Color3.fromRGB(25,26,30)
local crouch=cleanAction(topActions,"Crouch","AGACHAR",UDim2.fromOffset(64,64),UDim2.fromOffset(0,0),function()
 if player:GetAttribute("Downed") or player:GetAttribute("IsJason") then return end
 local nextMode=(player:GetAttribute("MoveMode")=="crouch") and "walk" or "crouch"
 mode=nextMode event:FireServer("mode",nextMode)
end)
crouch.TextSize=10 crouch.BackgroundTransparency=.4 crouch.BackgroundColor3=Color3.fromRGB(25,26,30)
local heldRunInput=nil
local function stopHeldRun(input)
 if heldRunInput and (not input or input==heldRunInput) then
  heldRunInput=nil
  mode="walk"
  event:FireServer("mode","walk")
 end
end
run.InputBegan:Connect(function(input)
 if player:GetAttribute("Downed") then return end
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  heldRunInput=input
  if mode~="run" then mode="run" event:FireServer("mode","run") end
 end
end)
run.InputEnded:Connect(function(input) stopHeldRun(input) end)
local reviveNearby=cleanAction(bar,"ReviveNearby","+",UDim2.fromOffset(66,66),UDim2.fromOffset(4,4),function()
 event:FireServer("revive")
end)
reviveNearby.TextSize=38 reviveNearby.Visible=false
local carryNearby=cleanAction(bar,"CarryNearby","CARREGAR",UDim2.fromOffset(66,66),UDim2.fromOffset(80,4),function()
 event:FireServer("carry")
end)
carryNearby.TextSize=9 carryNearby.Visible=false
local attackButton=cleanAction(bar,"Attack","ATACAR",UDim2.fromOffset(66,66),UDim2.fromOffset(80,4),function()
 event:FireServer("attack")
end)
attackButton.TextSize=10 attackButton.Visible=false

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
 topActions.Position=UDim2.new(1,-165,1,-115)
 bar.Position=UDim2.new(1,-84,1,-86)
end
local notice=text(gui,"Notice","",UDim2.new(.72,0,0,46),UDim2.new(.14,0,1,-132)) notice.TextSize=15
local settingsOverlay=Instance.new("Frame",gui) settingsOverlay.Name="SettingsOverlay" settingsOverlay.Size=UDim2.fromScale(1,1) settingsOverlay.BackgroundColor3=Color3.new(0,0,0) settingsOverlay.BackgroundTransparency=.32 settingsOverlay.ZIndex=110 settingsOverlay.Visible=false
local settingsUI=Settings.build(settingsOverlay,player,function() settingsOverlay.Visible=false end)
local settingsButton=button(gui,"SettingsButton","⚙",UDim2.fromOffset(44,44),UDim2.new(1,-52,0,2),function() settingsOverlay.Visible=not settingsOverlay.Visible end) settingsButton.TextSize=27 settingsButton.BackgroundTransparency=1 settingsButton.UIStroke.Enabled=false
RunService.RenderStepped:Connect(function()
 local blocked=player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("Spectating") or player:GetAttribute("SweanLoadingDone")~=true
 if blocked then return end
 player.CameraMode=Enum.CameraMode.Classic
 player.CameraMaxZoomDistance=player:GetAttribute("InRound") and 10 or 24
 player.CameraMinZoomDistance=player:GetAttribute("InRound") and 10 or 4
end)
local profileHUD=panel("Profile",UDim2.fromOffset(190,58),UDim2.fromOffset(18,112)) profileHUD.BackgroundTransparency=1 profileHUD.UIStroke.Enabled=false
local xpTrack=Instance.new("Frame",profileHUD) xpTrack.Name="XP" xpTrack.Size=UDim2.new(1,0,0,8) xpTrack.BackgroundColor3=Color3.fromRGB(22,23,32) xpTrack.BackgroundTransparency=.3 xpTrack.BorderSizePixel=0 Instance.new("UICorner",xpTrack).CornerRadius=UDim.new(0,5)
local xpFill=Instance.new("Frame",xpTrack) xpFill.Name="Fill" xpFill.Size=UDim2.fromScale(0,1) xpFill.BackgroundColor3=Color3.fromRGB(96,118,205) xpFill.BorderSizePixel=0 Instance.new("UICorner",xpFill).CornerRadius=UDim.new(0,5)
local levelText=text(xpTrack,"Level","NÍVEL 1",UDim2.new(1,-12,0,18),UDim2.fromOffset(6,-20)) levelText.TextSize=11 levelText.Font=Enum.Font.GothamBold levelText.TextXAlignment=Enum.TextXAlignment.Left
local pointsText=text(profileHUD,"Points","◉  0",UDim2.new(1,0,0,28),UDim2.fromOffset(0,26)) pointsText.TextSize=19 pointsText.TextColor3=Color3.fromRGB(165,215,121) pointsText.TextXAlignment=Enum.TextXAlignment.Left
local healthHUD=panel("Condition",UDim2.fromOffset(148,38),UDim2.new(0,18,1,-52)) healthHUD.UIStroke.Color=Color3.fromRGB(106,150,91)
local condition=text(healthHUD,"Value","♥  100",UDim2.fromScale(1,1),UDim2.new()) condition.Font=Enum.Font.GothamBold condition.TextSize=22 condition.TextColor3=Color3.fromRGB(144,223,111)
local staminaTrack=Instance.new("Frame",gui) staminaTrack.Name="Stamina" staminaTrack.Size=UDim2.fromOffset(148,7) staminaTrack.Position=UDim2.new(0,18,1,-64)
staminaTrack.BackgroundColor3=Color3.fromRGB(20,21,25) staminaTrack.BackgroundTransparency=.2 staminaTrack.BorderSizePixel=0 Instance.new("UICorner",staminaTrack).CornerRadius=UDim.new(1,0)
local staminaFill=Instance.new("Frame",staminaTrack) staminaFill.Name="Fill" staminaFill.Size=UDim2.fromScale(1,1) staminaFill.BackgroundColor3=Color3.fromRGB(190,194,205) staminaFill.BorderSizePixel=0 Instance.new("UICorner",staminaFill).CornerRadius=UDim.new(1,0)
local mission=panel("Mission",UDim2.fromOffset(360,48),UDim2.new(.5,-180,0,48)) mission.BackgroundTransparency=.42 mission.UIStroke.Transparency=.82
local missionTitle=text(mission,"Title","MISSÃO",UDim2.fromOffset(68,16),UDim2.fromOffset(10,5)) missionTitle.TextSize=9 missionTitle.Font=Enum.Font.GothamBold missionTitle.TextColor3=Color3.fromRGB(165,168,178) missionTitle.TextXAlignment=Enum.TextXAlignment.Left
local missionText=text(mission,"Text","",UDim2.new(1,-20,0,22),UDim2.fromOffset(10,20)) missionText.TextSize=12 missionText.Font=Enum.Font.GothamBold missionText.TextXAlignment=Enum.TextXAlignment.Left
local inventory=panel("ObjectiveInventory",UDim2.fromOffset(82,82),UDim2.new(0,18,1,-148)) inventory.BackgroundTransparency=.28 inventory.UIStroke.Transparency=.7
inventory:SetAttribute("SourceAssetId",net:GetAttribute("InventoryAssetId") or 73852738603629)
local inventoryIcon=text(inventory,"Icon","🔑",UDim2.fromScale(1,.62),UDim2.new()) inventoryIcon.TextSize=29
local inventoryLabel=text(inventory,"Label","VAZIO",UDim2.fromScale(1,.32),UDim2.new(0,0,.64,0)) inventoryLabel.TextSize=9 inventoryLabel.Font=Enum.Font.GothamBold
local escapeBanner=panel("EscapeBanner",UDim2.fromOffset(360,30),UDim2.new(.5,-180,0,12)) escapeBanner.BackgroundTransparency=.28 escapeBanner.Visible=false escapeBanner.UIStroke.Transparency=.8 escapeBanner.ZIndex=95
local escapeText=text(escapeBanner,"Text","",UDim2.fromScale(1,1),UDim2.new()) escapeText.TextSize=11 escapeText.Font=Enum.Font.GothamBold escapeText.ZIndex=96
local missionBanner=panel("MissionBanner",UDim2.fromOffset(420,34),UDim2.new(.5,-210,0,104)) missionBanner.BackgroundTransparency=.18 missionBanner.Visible=false missionBanner.ZIndex=96
local missionBannerText=text(missionBanner,"Text","NOVA MISSÃO",UDim2.fromScale(1,1),UDim2.new()) missionBannerText.TextSize=12 missionBannerText.Font=Enum.Font.GothamBlack missionBannerText.ZIndex=97
local hitFlash=Instance.new("Frame",gui) hitFlash.Name="HitFlash" hitFlash.Size=UDim2.fromScale(1,1) hitFlash.BackgroundColor3=Color3.fromRGB(150,0,12) hitFlash.BackgroundTransparency=1 hitFlash.BorderSizePixel=0 hitFlash.ZIndex=200
local hitGradient=Instance.new("UIGradient",hitFlash) hitGradient.Rotation=90 hitGradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.18,.76),NumberSequenceKeypoint.new(.5,.92),NumberSequenceKeypoint.new(.82,.76),NumberSequenceKeypoint.new(1,.05)})
local exitHighlight=Instance.new("Highlight") exitHighlight.Name="ObjectiveExitHighlight" exitHighlight.FillColor=Color3.fromRGB(242,211,79) exitHighlight.OutlineColor=Color3.fromRGB(255,243,170) exitHighlight.FillTransparency=.72 exitHighlight.OutlineTransparency=.08 exitHighlight.Enabled=false exitHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop exitHighlight.Parent=gui
local function missionCopy(stage)
 local done=net:GetAttribute("ComputersDone") or 0 local required=net:GetAttribute("ComputersRequired") or 3
 if stage=="Hack" then return "HACKEIE OS COMPUTADORES  "..done.."/"..required end
 if stage=="Key" then return player:GetAttribute("HasKey") and "ABRA A SAÍDA COM SUA CHAVE" or "ENCONTRE UMA CHAVE ESCONDIDA" end
 if stage=="Exit" then return "ABRA A SAÍDA COM SUA CHAVE" end
 return ""
end
local missionPulse=0
local function announceMission(stage)
 missionText.Text=missionCopy(stage)
 missionBannerText.Text="NOVA MISSÃO:  "..missionText.Text
 missionBanner.Visible=missionText.Text~=""
 missionPulse+=1 local token=missionPulse
 task.delay(2.2,function() if token==missionPulse then missionBanner.Visible=false end end)
end
local roster=Instance.new("Frame",gui)
roster.Name="PlayerRoster" roster.BackgroundTransparency=1 roster.Position=UDim2.fromOffset(12,172) roster.Size=UDim2.fromOffset(190,306)
local rosterList=Instance.new("UIListLayout",roster) rosterList.Padding=UDim.new(0,5) rosterList.SortOrder=Enum.SortOrder.LayoutOrder
local rosterRows={}
local function rosterRow(p)
 local row=Instance.new("Frame",roster)
 row.Name="Player_"..p.UserId row.Size=UDim2.fromOffset(184,40) row.BorderSizePixel=0
 row.BackgroundColor3=Color3.fromRGB(53,54,59) row.BackgroundTransparency=.14 row.LayoutOrder=p.UserId
 local corner=Instance.new("UICorner",row) corner.CornerRadius=UDim.new(1,0)
 local gradient=Instance.new("UIGradient",row)
 gradient.Rotation=0
 gradient.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.28),
  NumberSequenceKeypoint.new(.35,.18),
  NumberSequenceKeypoint.new(1,.06)
 })
 local name=text(row,"Name",p.DisplayName or p.Name,UDim2.new(1,-67,0,18),UDim2.fromOffset(43,3))
 name.Font=Enum.Font.GothamBold name.TextSize=11 name.TextXAlignment=Enum.TextXAlignment.Left name.TextTruncate=Enum.TextTruncate.AtEnd name.TextWrapped=false name.ZIndex=3
 local track=Instance.new("Frame",row)
 track.Name="Health" track.Size=UDim2.new(1,-82,0,6) track.Position=UDim2.fromOffset(43,27)
 track.BackgroundColor3=Color3.fromRGB(50,51,54) track.BackgroundTransparency=.12 track.BorderSizePixel=0 track.ZIndex=3
 Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
 local fill=Instance.new("Frame",track)
 fill.Name="Fill" fill.Size=UDim2.fromScale(1,1) fill.BackgroundColor3=Color3.fromRGB(130,193,74) fill.BorderSizePixel=0 fill.ZIndex=4
 Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
 local heart=text(row,"Heart","♥",UDim2.fromOffset(20,20),UDim2.new(1,-27,0,18))
 heart.TextSize=15 heart.TextColor3=Color3.fromRGB(228,91,91) heart.ZIndex=4
 local avatar=Instance.new("ImageLabel",row)
 avatar.Name="Avatar" avatar.AnchorPoint=Vector2.new(0,.5) avatar.Position=UDim2.new(0,4,.5,0) avatar.Size=UDim2.fromOffset(32,32)
 avatar.BackgroundColor3=Color3.fromRGB(82,83,89) avatar.BackgroundTransparency=.02 avatar.BorderSizePixel=0 avatar.ZIndex=4
 Instance.new("UICorner",avatar).CornerRadius=UDim.new(1,0)
 task.spawn(function()
  local ok,image=pcall(function() return Players:GetUserThumbnailAsync(p.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
  if ok and row.Parent then avatar.Image=image end
 end)
 rosterRows[p.UserId]={frame=row,player=p,fill=fill,name=name,heart=heart}
 return row
end
local function updateRoster()
 local wanted={}
 for _,p in ipairs(Players:GetPlayers()) do
  if p:GetAttribute("InRound")==true and p:GetAttribute("IsJason")~=true then
   wanted[p.UserId]=true
   if not rosterRows[p.UserId] then rosterRow(p) end
  end
 end
 for id,data in pairs(rosterRows) do
  if not wanted[id] or not data.player.Parent then data.frame:Destroy() rosterRows[id]=nil
  else
   local p=data.player
   local down=p:GetAttribute("Downed")==true or p:GetAttribute("RoundStatus")=="eliminated"
   local ratio=down and .08 or p:GetAttribute("Injured") and .5 or 1
   data.fill.Size=UDim2.fromScale(ratio,1)
   data.name.Text=p.DisplayName or p.Name
   data.fill.BackgroundColor3=down and Color3.fromRGB(190,77,77) or p:GetAttribute("Injured") and Color3.fromRGB(216,170,72) or Color3.fromRGB(130,193,74)
   data.heart.TextTransparency=down and .45 or 0
  end
 end
end
local result=Instance.new("Frame",gui)
result.Name="RoundResult" result.Size=UDim2.fromScale(1,1) result.Position=UDim2.new()
result.BackgroundColor3=Color3.new(0,0,0) result.BackgroundTransparency=1 result.BorderSizePixel=0
result.Visible=false result.ZIndex=70 result.ClipsDescendants=true
local resultView=Instance.new("ViewportFrame",result)
resultView.Name="WinnerPortrait" resultView.BackgroundColor3=Color3.new(0,0,0) resultView.BackgroundTransparency=0
resultView.Size=UDim2.fromScale(1,1) resultView.Position=UDim2.new() resultView.ZIndex=71 resultView.Visible=false
resultView.Ambient=Color3.fromRGB(92,77,82) resultView.LightColor=Color3.fromRGB(222,173,162) resultView.LightDirection=Vector3.new(-1,-.35,-1)
local resultWorld=Instance.new("WorldModel",resultView)
local resultCamera=Instance.new("Camera",resultView) resultCamera.FieldOfView=50 resultView.CurrentCamera=resultCamera
local resultShade=Instance.new("Frame",result)
resultShade.Name="Shade" resultShade.Size=UDim2.fromScale(1,1) resultShade.BackgroundColor3=Color3.new(0,0,0) resultShade.BackgroundTransparency=.64 resultShade.BorderSizePixel=0 resultShade.ZIndex=72
local shadeGradient=Instance.new("UIGradient",resultShade)
shadeGradient.Rotation=0 shadeGradient.Transparency=NumberSequence.new({
 NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.42,.62),NumberSequenceKeypoint.new(1,.34)
})
local resultHeader=text(result,"Header","FIM DA PARTIDA",UDim2.new(.92,0,0,42),UDim2.new(.025,0,.045,0))
resultHeader.Font=Enum.Font.GothamBlack resultHeader.TextSize=24 resultHeader.TextXAlignment=Enum.TextXAlignment.Left resultHeader.ZIndex=76
local resultSubtitle=text(result,"Subtitle","",UDim2.new(.7,0,0,26),UDim2.new(.025,0,.10,0))
resultSubtitle.TextSize=11 resultSubtitle.TextXAlignment=Enum.TextXAlignment.Left resultSubtitle.TextColor3=Color3.fromRGB(190,190,196) resultSubtitle.ZIndex=76
local resultRows=Instance.new("ScrollingFrame",result)
resultRows.Name="Ranking" resultRows.BackgroundTransparency=1 resultRows.BorderSizePixel=0
resultRows.Position=UDim2.new(.025,0,.18,0) resultRows.Size=UDim2.new(.34,0,.58,0) resultRows.ZIndex=76
resultRows.AutomaticCanvasSize=Enum.AutomaticSize.Y resultRows.CanvasSize=UDim2.new() resultRows.ScrollBarThickness=0
local resultList=Instance.new("UIListLayout",resultRows) resultList.Padding=UDim.new(0,5) resultList.SortOrder=Enum.SortOrder.LayoutOrder
local resultWinner=text(result,"Winner","",UDim2.new(.92,0,0,32),UDim2.new(.025,0,.82,0))
resultWinner.Font=Enum.Font.GothamBold resultWinner.TextSize=13 resultWinner.TextXAlignment=Enum.TextXAlignment.Left resultWinner.ZIndex=76
local resultUntil=0 local resultGeneration=0
local resultCameraState=nil
local resultCameraConn=nil
local function stopResultCamera()
 if resultCameraConn then resultCameraConn:Disconnect() resultCameraConn=nil end
end
local function captureResultCamera()
 local camera=workspace.CurrentCamera
 if not camera or resultCameraState then return end
 resultCameraState={
  camera=camera,
  cameraType=camera.CameraType,
  cameraSubject=camera.CameraSubject,
  cframe=camera.CFrame,
  fieldOfView=camera.FieldOfView,
 }
 camera.CameraType=Enum.CameraType.Scriptable
end
local function startResultCamera(primary,secondary)
 stopResultCamera()
 local started=os.clock()
 resultCameraConn=RunService.RenderStepped:Connect(function()
  if not result.Visible then return end
  local camera=workspace.CurrentCamera
  if not camera or not primary or not primary.Parent then return end
  local cf,size=primary:GetBoundingBox()
  local center=cf.Position+Vector3.new(0,math.clamp(size.Y*.10,.5,2.4),0)
  if secondary and secondary.Parent then
   local secondaryRoot=secondary:FindFirstChild("HumanoidRootPart") or secondary.PrimaryPart
   if secondaryRoot then center=center:Lerp(secondaryRoot.Position+Vector3.new(0,1.7,0),.22) end
  end
  local forward=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
  if forward.Magnitude<.05 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
  local right=Vector3.new(-forward.Z,0,forward.X)
  local distance=math.clamp(math.max(size.Y*1.45,size.Z*2.6),10,20)
  local sway=math.sin((os.clock()-started)*.32)*1.05
  local cameraPos=center+forward*distance+right*(2.8+sway)+Vector3.new(0,math.max(2.8,size.Y*.30),0)
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt(cameraPos,center)
  camera.FieldOfView=52
 end)
end
local function restoreResultCamera()
 stopResultCamera()
 local state=resultCameraState
 resultCameraState=nil
 if not state then return end
 local camera=workspace.CurrentCamera or state.camera
 if not camera then return end
 local subject=state.cameraSubject
 if not subject or not subject.Parent then
  subject=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 end
 if subject then
  camera.CameraSubject=subject
  camera.CameraType=subject==state.cameraSubject and state.cameraType or Enum.CameraType.Custom
 else
  camera.CameraType=Enum.CameraType.Custom
 end
 camera.FieldOfView=player:GetAttribute("CameraFOV") or state.fieldOfView or 48
 if camera.CameraType==Enum.CameraType.Scriptable and state.cframe then camera.CFrame=state.cframe end
end
local function hideResult()
 result.Visible=false resultGeneration+=1 resultWorld:ClearAllChildren()
 for _,candidate in ipairs(workspace:GetChildren()) do
  if candidate:IsA("Model") and candidate:GetAttribute("ActivePursuer") then
   candidate:SetAttribute("PresentationFrozen",false)
   candidate:SetAttribute("PresentationState",nil)
  end
 end
 restoreResultCamera()
end
local resultClose=button(result,"Close","SAÍDA",UDim2.fromOffset(88,36),UDim2.new(1,-100,0,14),hideResult)
resultClose.ZIndex=77 resultClose.TextSize=12 resultClose.BackgroundTransparency=.18 resultClose.UIStroke.Enabled=false
result:GetPropertyChangedSignal("Visible"):Connect(function()
 if not result.Visible then restoreResultCamera() end
end)

local function showResult(data)
 hideResult()
 captureResultCamera()
 local generation=resultGeneration
 for _,old in ipairs(resultRows:GetChildren()) do if old:IsA("Frame") then old:Destroy() end end
 resultRows.CanvasPosition=Vector2.zero
 local winnerName=data.killerWinnerName or data.killer or "Perseguidor"
 resultHeader.Text=string.upper(data.jasonWon and (winnerName.." venceu a partida") or "Sobreviventes venceram a partida")
 resultHeader.TextColor3=data.jasonWon and Color3.fromRGB(225,104,109) or Color3.fromRGB(235,235,239)
 resultSubtitle.Text=(data.map or "").."  •  +"..tostring(data.xp or 0).." XP"
 resultWinner.Text=data.jasonWon and ("VENCEDOR  •  "..winnerName) or (data.winnerText or "SOBREVIVENTES ESCAPARAM")
 resultView.Visible=false
 resultShade.BackgroundTransparency=data.jasonWon and .58 or .46

 if data.jasonWon then
  local target=nil
  for _,candidate in ipairs(workspace:GetChildren()) do
   if candidate:IsA("Model") and candidate:GetAttribute("ActivePursuer") then target=candidate break end
  end
  local victimId=tonumber(data.lastVictimUserId) or 0
  if victimId<=0 then
   local fallback=(data.board or {})[1]
   victimId=fallback and fallback.userId or 0
  end
  local victimPlayer=victimId>0 and Players:GetPlayerByUserId(victimId) or nil
  local victimCharacter=victimPlayer and victimPlayer.Character or nil
  if target then
   target:SetAttribute("PresentationState","Jason Idle")
   target:SetAttribute("PresentationAt",workspace:GetServerTimeNow())
   target:SetAttribute("PresentationFrozen",true)
   target:SetAttribute("PresentationFreezeTime",.35)
   startResultCamera(target,nil)
  else
   local own=player.Character
   if own then startResultCamera(own,nil) end
  end
 else
  local target=nil
  for _,candidate in ipairs(workspace:GetChildren()) do
   if candidate:IsA("Model") and candidate:GetAttribute("ActivePursuer") then target=candidate break end
  end
  if target then
   target:SetAttribute("PresentationState","Jason Slash")
   target:SetAttribute("PresentationAt",workspace:GetServerTimeNow())
   target:SetAttribute("PresentationFrozen",true)
   target:SetAttribute("PresentationFreezeTime",.28)
   startResultCamera(target,nil)
  else
   target=player.Character
   if target then startResultCamera(target,nil) end
  end
 end

 for i,row in ipairs(data.board or {}) do if i>8 then break end
  local card=Instance.new("Frame",resultRows)
  card.Name="Rank"..i card.Size=UDim2.new(1,-4,0,43) card.LayoutOrder=i card.BorderSizePixel=0 card.ZIndex=76
  card.BackgroundColor3=Color3.new(0,0,0) card.BackgroundTransparency=row.userId==player.UserId and .24 or .36
  Instance.new("UICorner",card).CornerRadius=UDim.new(0,7)
  local fade=Instance.new("UIGradient",card)
  fade.Rotation=0 fade.Transparency=NumberSequence.new({
   NumberSequenceKeypoint.new(0,.06),NumberSequenceKeypoint.new(.72,.20),NumberSequenceKeypoint.new(1,.62)
  })
  local avatar=Instance.new("ImageLabel",card)
  avatar.Name="Avatar" avatar.Size=UDim2.fromOffset(35,35) avatar.Position=UDim2.fromOffset(4,4)
  avatar.BackgroundColor3=Color3.fromRGB(35,35,38) avatar.BackgroundTransparency=.08 avatar.BorderSizePixel=0 avatar.ZIndex=78
  Instance.new("UICorner",avatar).CornerRadius=UDim.new(1,0)
  task.spawn(function()
   local ok,image=pcall(function() return Players:GetUserThumbnailAsync(row.userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
   if ok and avatar.Parent then avatar.Image=image end
  end)
  local name=text(card,"Name",row.name or "Jogador",UDim2.new(1,-118,1,0),UDim2.fromOffset(47,0))
  name.Font=Enum.Font.GothamBold name.TextSize=12 name.TextXAlignment=Enum.TextXAlignment.Left name.TextTruncate=Enum.TextTruncate.AtEnd name.TextWrapped=false name.ZIndex=78
  local seconds=math.max(0,row.time or 0)
  local time=text(card,"Time",string.format("%d:%02d",math.floor(seconds/60),seconds%60),UDim2.fromOffset(58,43),UDim2.new(1,-64,0,0))
  time.Font=Enum.Font.GothamMedium time.TextSize=11 time.TextXAlignment=Enum.TextXAlignment.Right time.TextColor3=Color3.fromRGB(206,206,211) time.ZIndex=78
 end

 result.Position=UDim2.new()
 result.Size=UDim2.fromScale(1,1)
 resultView.Position=UDim2.new() resultView.Size=UDim2.fromScale(1,1)
 resultRows.Position=UDim2.new(.025,0,.18,0) resultRows.Size=UDim2.new(.34,0,.58,0)
 result.Visible=true resultUntil=os.clock()+8.8
 task.delay(8.8,function() if generation==resultGeneration then hideResult() end end)
end

local spectate=panel("Spectate",UDim2.fromOffset(330,74),UDim2.new(.5,-165,1,-102))
spectate.BackgroundTransparency=.28
local spectatorName=text(spectate,"Player","JOGADOR",UDim2.fromOffset(190,32),UDim2.fromOffset(70,3)) spectatorName.Font=Enum.Font.GothamBold spectatorName.TextSize=12
local index=1 local watching=false local watchedId=nil
button(spectate,"Previous","<<",UDim2.fromOffset(54,32),UDim2.fromOffset(8,3),function() index-=1 watchedId=nil end)
button(spectate,"Next",">>",UDim2.fromOffset(54,32),UDim2.fromOffset(268,3),function() index+=1 watchedId=nil end)
button(spectate,"Exit","LOBBY",UDim2.fromOffset(120,28),UDim2.fromOffset(105,40),function() event:FireServer("spectateExit") end)
local loading=panel("ArenaLoading",UDim2.fromScale(1,1),UDim2.new())
loading.BackgroundColor3=Color3.fromRGB(4,4,6) loading.BackgroundTransparency=.28 loading.ZIndex=80 loading.Visible=false loading.ClipsDescendants=true
loading.UIStroke.Enabled=false loading.UICorner.CornerRadius=UDim.new()
local loadingText=text(loading,"Status","CARREGANDO MAPA",UDim2.new(.8,0,0,32),UDim2.new(.1,0,.78,0))
loadingText.ZIndex=82 loadingText.TextSize=11 loadingText.TextTransparency=.28 loadingText.Font=Enum.Font.GothamMedium
local goodLuck=text(loading,"GoodLuck","GOOD LUCK",UDim2.new(.92,0,.18,0),UDim2.new(.04,0,.43,0))
goodLuck.ZIndex=81 goodLuck.Font=Enum.Font.GothamBlack goodLuck.TextScaled=true goodLuck.TextTransparency=.68 goodLuck.Visible=false
local goodLuckLimit=Instance.new("UITextSizeConstraint",goodLuck) goodLuckLimit.MinTextSize=28 goodLuckLimit.MaxTextSize=92

local loadingAvatar=Instance.new("ViewportFrame",loading)
loadingAvatar.Name="ArenaAvatar"
loadingAvatar.BackgroundTransparency=1
loadingAvatar.AnchorPoint=Vector2.new(.5,1)
loadingAvatar.Position=UDim2.new(.5,0,1.14,0)
loadingAvatar.Size=UDim2.new(.72,0,.88,0)
loadingAvatar.Ambient=Color3.fromRGB(70,72,80)
loadingAvatar.LightColor=Color3.fromRGB(224,219,222)
loadingAvatar.LightDirection=Vector3.new(-.7,-.8,-.45)
loadingAvatar.ZIndex=82 loadingAvatar.Visible=false
local loadingAvatarWorld=Instance.new("WorldModel",loadingAvatar)
local loadingAvatarCamera=Instance.new("Camera",loadingAvatar) loadingAvatarCamera.FieldOfView=34 loadingAvatar.CurrentCamera=loadingAvatarCamera
local loadingAvatarClone=nil local loadingAvatarRoot=nil local loadingAvatarBase=nil local loadingAvatarConn=nil local loadingAvatarJoints={}

local function clearArenaLoadingAvatar()
 if loadingAvatarConn then loadingAvatarConn:Disconnect() loadingAvatarConn=nil end
 if loadingAvatarClone then loadingAvatarClone:Destroy() loadingAvatarClone=nil end
 loadingAvatarRoot=nil loadingAvatarBase=nil table.clear(loadingAvatarJoints)
end

local function buildArenaLoadingAvatar()
 clearArenaLoadingAvatar()
 local char=player.Character
 if not char then return end
 local archivable=char.Archivable char.Archivable=true
 local ok,clone=pcall(function() return char:Clone() end)
 char.Archivable=archivable
 if not ok or not clone then return end
 loadingAvatarClone=clone clone.Name="ArenaLoadingCharacter"
 for _,d in ipairs(clone:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Tool") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.CastShadow=false
  elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled=false end
 end
 local root=clone:FindFirstChild("HumanoidRootPart")
 local hum=clone:FindFirstChildOfClass("Humanoid")
 if not root then clone:Destroy() loadingAvatarClone=nil return end
 if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.AutoRotate=false end
 clone.PrimaryPart=root root.Anchored=true clone.Parent=loadingAvatarWorld clone:PivotTo(CFrame.new())
 loadingAvatarRoot=root loadingAvatarBase=CFrame.new(0,-.4,0)*CFrame.Angles(0,math.rad(-6),0) root.CFrame=loadingAvatarBase
 for _,j in ipairs(clone:GetDescendants()) do if j:IsA("Motor6D") then loadingAvatarJoints[j]=j.Transform end end
 local head=clone:FindFirstChild("Head") local torso=clone:FindFirstChild("Torso") or clone:FindFirstChild("UpperTorso")
 local focus=(head and head.Position or Vector3.new(0,2.6,0)):Lerp(torso and torso.Position or Vector3.new(0,1.6,0),.34)
 local _,size=clone:GetBoundingBox()
 loadingAvatarCamera.CFrame=CFrame.lookAt(focus+Vector3.new(.15,.08,math.max(5.2,size.Y*.82)),focus)
 local started=os.clock()
 loadingAvatarConn=RunService.RenderStepped:Connect(function()
  if not loading.Visible or not loadingAvatarRoot or not loadingAvatarRoot.Parent then return end
  local t=os.clock()-started
  loadingAvatarRoot.CFrame=loadingAvatarBase*CFrame.new(math.sin(t*.55)*.025,math.sin(t*1.3)*.05,0)*CFrame.Angles(0,math.sin(t*.45)*.025,0)
  for joint,base in pairs(loadingAvatarJoints) do if joint.Parent then
   local name=joint.Name:lower()
   if name:find("neck") then joint.Transform=base*CFrame.Angles(math.sin(t*.7)*.022,math.sin(t*.48)*.03,0)
   elseif name:find("shoulder") then
    local side=name:find("left") and -1 or 1
    joint.Transform=base*CFrame.Angles(math.rad(-22)+math.sin(t*1.1+side)*.16,0,side*(.3+math.sin(t*.8)*.08))
   end
  end end
 end)
end
local progressTrack=Instance.new("Frame",loading)
progressTrack.Name="MapProgress" progressTrack.AnchorPoint=Vector2.new(0,1) progressTrack.Position=UDim2.new(0,0,1,0)
progressTrack.Size=UDim2.new(1,0,0,7) progressTrack.BorderSizePixel=0 progressTrack.BackgroundColor3=Color3.fromRGB(21,21,25) progressTrack.ZIndex=84
local progressFill=Instance.new("Frame",progressTrack)
progressFill.Name="Fill" progressFill.Size=UDim2.fromScale(0,1) progressFill.BorderSizePixel=0 progressFill.BackgroundColor3=Color3.fromRGB(222,222,226) progressFill.ZIndex=85
local progressGlow=Instance.new("Frame",progressFill)
progressGlow.Name="Tip" progressGlow.AnchorPoint=Vector2.new(1,.5) progressGlow.Position=UDim2.new(1,0,.5,0) progressGlow.Size=UDim2.fromOffset(18,16)
progressGlow.BackgroundColor3=Color3.fromRGB(245,245,248) progressGlow.BackgroundTransparency=.35 progressGlow.BorderSizePixel=0 progressGlow.ZIndex=86
local loadToken=0
local loadingCameraState=nil
local loadingCameraConn=nil
local function restoreLoadingCamera()
 if loadingCameraConn then loadingCameraConn:Disconnect() loadingCameraConn=nil end
 local state=loadingCameraState
 loadingCameraState=nil
 if not state then return end
 local camera=workspace.CurrentCamera or state.camera
 if not camera then return end
 local subject=state.cameraSubject
 if not subject or not subject.Parent then subject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
 if subject then
  camera.CameraSubject=subject
  camera.CameraType=Enum.CameraType.Custom
 else
  camera.CameraType=state.cameraType or Enum.CameraType.Custom
  if camera.CameraType==Enum.CameraType.Scriptable and state.cframe then camera.CFrame=state.cframe end
 end
 camera.FieldOfView=player:GetAttribute("CameraFOV") or state.fieldOfView or 48
end
local function captureLoadingCamera(map,token)
 restoreLoadingCamera()
 local camera=workspace.CurrentCamera
 if not camera then return end
 loadingCameraState={camera=camera,cameraType=camera.CameraType,cameraSubject=camera.CameraSubject,cframe=camera.CFrame,fieldOfView=camera.FieldOfView}
 camera.CameraType=Enum.CameraType.Scriptable
 local started=os.clock()
 local cachedCenter=nil local cachedSize=nil local nextMeasure=0
 loadingCameraConn=RunService.RenderStepped:Connect(function()
  if token~=loadToken or not loading.Visible then return end
  local current=workspace.CurrentCamera
  local arena=map and map.Parent and map or workspace:FindFirstChild("ActiveArena")
  if not current or not arena then return end
  local t=os.clock()
  if not cachedCenter or t>=nextMeasure then
   local cf,size=arena:GetBoundingBox()
   cachedCenter=cf.Position+Vector3.new(0,math.clamp(size.Y*.08,1,6),0)
   cachedSize=size
   nextMeasure=t+.45
  end
  local size=cachedSize or Vector3.new(40,15,40)
  local radius=math.clamp(math.max(size.X,size.Z)*.22,24,60)
  local angle=(t-started)*.11
  local height=math.clamp(size.Y*.32+10,14,30)
  local pos=cachedCenter+Vector3.new(math.cos(angle)*radius,height,math.sin(angle)*radius)
  current.CameraType=Enum.CameraType.Scriptable
  current.CFrame=CFrame.lookAt(pos,cachedCenter)
  current.FieldOfView=60
 end)
end

local function setMapProgress(value,duration)
 value=math.clamp(value,0,1)
 TweenService:Create(progressFill,TweenInfo.new(duration or .16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(value,1)}):Play()
end

local function glitchLeadIn()
 local media=RS:FindFirstChild("XNMedia")
 local template=media and media:FindFirstChild("MenuClick")
 if not template then return end
 for i,speed in ipairs({.34,.51,.27,.68}) do
  task.delay((i-1)*.075,function()
   if not loading.Visible then return end
   local sound=template:Clone()
   sound.Name="MapLoadGlitch" sound.Volume=.12+(i%2)*.04 sound.PlaybackSpeed=speed
   local ok=pcall(function()
    local distortion=Instance.new("DistortionSoundEffect") distortion.Level=.35+(i*.08) distortion.Parent=sound
    local pitch=Instance.new("PitchShiftSoundEffect") pitch.Octave=.72+(i*.05) pitch.Parent=sound
   end)
   sound.Parent=SoundService sound:Play() Debris:AddItem(sound,3)
  end)
 end
end

local function playGoodLuckVoice(token)
 if token~=loadToken or not loading.Visible then return end
 glitchLeadIn()
 task.wait(.24)
 if token~=loadToken or not loading.Visible then return end
 goodLuck.Visible=true
 TweenService:Create(goodLuck,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=.05}):Play()
 -- Layer Roblox TTS voices to create an original broken/interference-like delivery.
 task.spawn(function()
  local holder=Instance.new("Folder") holder.Name="GoodLuckTTS" holder.Parent=SoundService
  local ok=pcall(function()
   local output=Instance.new("AudioDeviceOutput") output.Name="GoodLuckOutput" output.Player=player output.Parent=holder
   for i,voice in ipairs({
    {id="9",pitch=.86,speed=.90,volume=.38,delay=0},
    {id="10",pitch=1.08,speed=1.02,volume=.30,delay=.045},
    {id="11",pitch=.96,speed=.96,volume=.20,delay=.09},
   }) do
    local speech=Instance.new("AudioTextToSpeech")
    speech.Name="GoodLuckVoice"..i speech.Text="Good Luck" speech.AutoLocalize=false
    speech.VoiceId=voice.id speech.Pitch=voice.pitch speech.PlaybackSpeed=voice.speed speech.Volume=voice.volume speech.Parent=holder
    local wire=Instance.new("Wire") wire.Name="VoiceWire"..i wire.SourceInstance=speech wire.TargetInstance=output wire.Parent=holder
    task.spawn(function()
     pcall(function() speech:LoadAsync() end)
     task.wait(voice.delay)
     if token==loadToken and loading.Visible then pcall(function() speech:Play() end) end
    end)
   end
  end)
  task.delay(3,function() if holder.Parent then holder:Destroy() end end)
 end)
end

local function preload(roundId,map)
 loadToken+=1 local token=loadToken
 loading.Visible=true goodLuck.Visible=false goodLuck.TextTransparency=.68
 loadingAvatar.Visible=false
 captureLoadingCamera(map,token)
 progressFill.Size=UDim2.fromScale(0,1) loadingText.Text="CARREGANDO MAPA"
 setMapProgress(.04,.05)
 task.spawn(function()
  local deadline=os.clock()+18 local geometryReady=false
  while os.clock()<deadline and token==loadToken do
   map=map and map.Parent and map or workspace:FindFirstChild("ActiveArena")
   if map and map:GetAttribute("RoundId")==roundId and map:FindFirstChild("SafePoints") then
    local count=0 for _,d in ipairs(map:GetDescendants()) do if d:IsA("BasePart") then count+=1 end end
    local expected=math.max(1,map:GetAttribute("PartCount") or count)
    local ratio=math.clamp(count/expected,0,1)
    loadingText.Text="CARREGANDO MAPA  "..math.floor(ratio*100).."%"
    setMapProgress(.06+ratio*.68,.12)
    if count>=expected then geometryReady=true break end
   end
   task.wait(.1)
  end
  if token~=loadToken then return end
  if not geometryReady then
   loading.Visible=false clearArenaLoadingAvatar() restoreLoadingCamera() event:FireServer("loadFailed",roundId)
   notice.Text="A conexão está lenta. A arena continua carregando." return
  end
  local done=false local mediaDeadline=os.clock()+8
  loadingText.Text="PREPARANDO O AMBIENTE"
  setMapProgress(.82,.22)
  task.spawn(function()
   pcall(function() game:GetService("ContentProvider"):PreloadAsync({map}) end)
   done=true
  end)
  while not done and os.clock()<mediaDeadline and token==loadToken do task.wait(.1) end
  if token~=loadToken then return end
  setMapProgress(.96,.22)
  loadingText.Text=""
  goodLuck.Visible=false
  task.wait(1.35)
  if token~=loadToken then return end
  setMapProgress(1,.15)
  task.wait(.18)
  loading.Visible=false
  goodLuck.Visible=false
  clearArenaLoadingAvatar()
  restoreLoadingCamera()
  -- Geometry gates readiness; optional unavailable audio/decals must not eject a player.
  if map and map.Parent and map:GetAttribute("RoundId")==roundId then event:FireServer("ready",roundId) end
 end)
end
local noticeUntil=0
local shakeToken=0
local function shakeCamera(duration,intensity)
 shakeToken+=1 local token=shakeToken
 task.spawn(function()
  local char=player.Character
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if not hum then return end
  local reduced=player:GetAttribute("ReducedMotion")==true
  local strength=intensity*(reduced and .25 or 1)
  local start=os.clock()
  while token==shakeToken and hum.Parent and os.clock()-start<duration do
   local t=(os.clock()-start)/duration
   local fade=1-math.clamp(t,0,1)
   hum.CameraOffset=Vector3.new(
    math.sin(os.clock()*47)*strength*fade,
    math.cos(os.clock()*61)*strength*.7*fade,
    0
   )
   RunService.RenderStepped:Wait()
  end
  if hum.Parent then hum.CameraOffset=Vector3.zero end
 end)
end

local hitReactionToken=0
local function caughtAnimation(killer,killerCF)
 hitReactionToken+=1 local token=hitReactionToken
 local char=player.Character
 if not char then return end
 local downed=player:GetAttribute("Downed")==true
 shakeCamera(downed and .42 or .28,downed and .36 or .22)
 if downed or player:GetAttribute("ReducedMotion") then return end
 local joints={}
 for _,joint in ipairs(char:GetDescendants()) do
  if joint:IsA("Motor6D") then joints[joint.Name:lower()]=joint end
 end
 local neck=joints.neck
 local left=joints["left shoulder"] or joints.leftshoulder
 local right=joints["right shoulder"] or joints.rightshoulder
 local originals={}
 for _,j in ipairs({neck,left,right}) do if j then originals[j]=j.Transform end end
 if neck then TweenService:Create(neck,TweenInfo.new(.08),{Transform=originals[neck]*CFrame.Angles(math.rad(-7),0,math.rad(4))}):Play() end
 if left then TweenService:Create(left,TweenInfo.new(.08),{Transform=originals[left]*CFrame.Angles(math.rad(10),0,math.rad(-12))}):Play() end
 if right then TweenService:Create(right,TweenInfo.new(.08),{Transform=originals[right]*CFrame.Angles(math.rad(14),0,math.rad(12))}):Play() end
 task.wait(.13)
 if token~=hitReactionToken or player.Character~=char then return end
 for joint,cf in pairs(originals) do if joint.Parent then TweenService:Create(joint,TweenInfo.new(.12),{Transform=cf}):Play() end end
end

player:GetAttributeChangedSignal("Downed"):Connect(function()
 if player:GetAttribute("Downed")==true then shakeCamera(.42,.34) end
end)

net.Update.OnClientEvent:Connect(function(action,a,b)
 if action=="reset" then
  loadToken+=1 loading.Visible=false goodLuck.Visible=false clearArenaLoadingAvatar() restoreLoadingCamera() progressFill.Size=UDim2.fromScale(0,1)
 elseif action=="notice" then
  notice.Text=a noticeUntil=os.clock()+5
 elseif action=="mission" then
  announceMission(a)
 elseif action=="objectiveDone" then
  announceMission(net:GetAttribute("MissionStage") or "Hack")
 elseif action=="escape" then
  escapeText.Text=tostring(a).." ESCAPOU"
  escapeBanner.Visible=true
  task.delay(2.4,function() escapeBanner.Visible=false end)
 elseif action=="achievement" then
  missionBannerText.Text=tostring(a).."  •  "..tostring(b or "")
  missionBanner.Visible=true missionPulse+=1 local token=missionPulse
  task.delay(3,function() if token==missionPulse then missionBanner.Visible=false end end)
 elseif action=="hitFlash" then
  local strength=tonumber(a) or .45
  hitFlash.BackgroundTransparency=math.clamp(.78-strength*.35,.42,.82)
  TweenService:Create(hitFlash,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
 elseif action=="noisePing" and typeof(a)=="Vector3" then
  local marker=Instance.new("Part") marker.Name="NoisePing" marker.Shape=Enum.PartType.Ball marker.Size=Vector3.new(1.2,1.2,1.2) marker.Material=Enum.Material.Neon marker.Color=Color3.fromRGB(235,86,89) marker.Transparency=.25 marker.Anchored=true marker.CanCollide=false marker.CanTouch=false marker.Position=a+Vector3.new(0,.7,0) marker.Parent=workspace
  TweenService:Create(marker,TweenInfo.new(1.6),{Size=Vector3.new(5,5,5),Transparency=1}):Play() Debris:AddItem(marker,1.8)
 elseif action=="load" then
  preload(a,b)
 elseif action=="caught" or action=="executed" then
  task.spawn(caughtAnimation,a,b)
 elseif action=="roundResult" and type(a)=="table" then
  updateRoundMusic(true)
  showResult(a)
 end
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsOverlay.Visible or result.Visible or not player:GetAttribute("InRound") then return end
 if input.KeyCode==Enum.KeyCode.LeftShift then mode="run" event:FireServer("mode",mode)
 elseif input.KeyCode==Enum.KeyCode.C or input.KeyCode==Enum.KeyCode.LeftControl then
  if not player:GetAttribute("IsJason") then mode=(player:GetAttribute("MoveMode")=="crouch") and "walk" or "crouch" event:FireServer("mode",mode) end
 elseif input.KeyCode==Enum.KeyCode.E and not player:GetAttribute("IsJason") then event:FireServer("carry")
 elseif input.UserInputType==Enum.UserInputType.MouseButton1 and player:GetAttribute("IsJason") then event:FireServer("attack")
 elseif input.KeyCode==Enum.KeyCode.F then event:FireServer("flashlight") end
end)
UIS.InputEnded:Connect(function(input)
 if input==heldRunInput then stopHeldRun(input) end
 if input.KeyCode==Enum.KeyCode.LeftShift and mode=="run" then mode="walk" event:FireServer("mode",mode) end
end)
local highlight=Instance.new("Highlight") highlight.Name="PursuerTarget" highlight.FillColor=Color3.fromRGB(200,35,43) highlight.OutlineColor=Color3.fromRGB(242,80,85) highlight.FillTransparency=.8 highlight.DepthMode=Enum.HighlightDepthMode.Occluded highlight.Enabled=false highlight.Parent=gui

local jasonPresentationFov=70
updateRoundMusic(false)
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera
 if not camera then return end
 local baseFov=player:GetAttribute("CameraFOV") or 70
 local isJason=player:GetAttribute("IsJason")==true
 local active=isJason and player:GetAttribute("InRound")==true and player:GetAttribute("InMenu")~=true and player:GetAttribute("Spectating")~=true
 if active then
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local speed=root and (root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
  local targetFov=player:GetAttribute("ReducedMotion") and baseFov or math.min(100,baseFov+(speed>4 and 14 or 8))
  jasonPresentationFov+=(targetFov-jasonPresentationFov)*math.min(1,dt*6)
  if camera.CameraType~=Enum.CameraType.Scriptable then camera.FieldOfView=jasonPresentationFov end
 else
  jasonPresentationFov+=(baseFov-jasonPresentationFov)*math.min(1,dt*6)
  if player:GetAttribute("InMenu")~=true and player:GetAttribute("Spectating")~=true and camera.CameraType~=Enum.CameraType.Scriptable then
   camera.FieldOfView=jasonPresentationFov
  end
 end
end)

local votePanel=panel("MapVoting",UDim2.new(.92,0,.46,0),UDim2.new(.04,0,.27,0))
votePanel.BackgroundColor3=Color3.fromRGB(7,7,10) votePanel.BackgroundTransparency=.08 votePanel.Visible=false votePanel.ZIndex=60
local voteTitle=text(votePanel,"Title","ESCOLHA O PRÓXIMO MAPA",UDim2.new(1,-24,0,40),UDim2.fromOffset(12,8)) voteTitle.Font=Enum.Font.GothamBlack voteTitle.TextSize=20 voteTitle.TextXAlignment=Enum.TextXAlignment.Left voteTitle.ZIndex=62
local voteHint=text(votePanel,"Hint","A votação abre somente depois do intervalo",UDim2.new(1,-24,0,20),UDim2.fromOffset(12,42)) voteHint.TextSize=10 voteHint.TextColor3=Color3.fromRGB(150,150,160) voteHint.TextXAlignment=Enum.TextXAlignment.Left voteHint.ZIndex=62
local voteTimer=text(votePanel,"Timer","6",UDim2.fromOffset(54,48),UDim2.new(1,-68,0,8)) voteTimer.Font=Enum.Font.GothamBlack voteTimer.TextSize=28 voteTimer.ZIndex=63
local mapButtons={}
local mapNames={DoomspireBrickbattle="DOOMSPIRE",JuggernautFightArena="JUGGERNAUT",PirateBayIsland="PIRATE BAY",NaturalDisasterSurvival="NATURAL DISASTER",RocketArena="ROCKET ARENA"}
for i,map in ipairs(config.Maps) do
 local width=.188
 local x=.018+(i-1)*.196
 local b=button(votePanel,map.name,"",UDim2.new(width,0,.70,0),UDim2.new(x,0,.20,0),function() event:FireServer("voteMap",map.name) end)
 b.Text="" b.BackgroundColor3=Color3.fromRGB(16,16,21) b.BackgroundTransparency=.06 b.ZIndex=62
 local preview=Instance.new("ImageLabel",b) preview.Name="Preview" preview.Size=UDim2.new(1,-6,.72,-4) preview.Position=UDim2.fromOffset(3,3) preview.BackgroundTransparency=1 preview.Image="rbxthumb://type=Asset&id="..map.id.."&w=420&h=420" preview.ScaleType=Enum.ScaleType.Crop preview.ZIndex=63
 Instance.new("UICorner",preview).CornerRadius=UDim.new(0,9)
 local shade=Instance.new("UIGradient",preview) shade.Rotation=90 shade.Color=ColorSequence.new(Color3.fromRGB(210,210,215),Color3.fromRGB(90,90,100))
 local caption=text(b,"Caption",mapNames[map.name] or map.name,UDim2.new(1,-8,0,28),UDim2.new(0,4,.73,0)) caption.TextSize=10 caption.Font=Enum.Font.GothamBlack caption.ZIndex=64 caption.TextStrokeTransparency=.35
 local votes=text(b,"Votes","0 VOTOS",UDim2.new(1,-8,0,20),UDim2.new(0,4,.86,0)) votes.TextSize=9 votes.Font=Enum.Font.GothamBold votes.TextColor3=Color3.fromRGB(170,170,180) votes.ZIndex=64
 mapButtons[map.name]=b
end
local killerPanel=panel("KillerSelection",UDim2.new(.66,0,.45,0),UDim2.fromScale(.17,.25))
killerPanel.Visible=false
text(killerPanel,"Title","VOCÊ É O PERSEGUIDOR • ESCOLHA",UDim2.new(1,0,0,44),UDim2.new())
local names={} for name in pairs(config.Killers) do table.insert(names,name) end table.sort(names)
for i,name in ipairs(names) do
 button(killerPanel,name,name,UDim2.new(.3,0,.28,0),UDim2.new(.025+((i-1)%3)*.325,0,.25+math.floor((i-1)/3)*.34,0),function() event:FireServer("chooseKiller",name) end)
end
local voteElapsed=0
RunService.RenderStepped:Connect(function(dt)
 voteElapsed+=dt if voteElapsed<.15 then return end voteElapsed=0
 killerPanel.Visible=net:GetAttribute("Phase")=="Escolha" and player:GetAttribute("ChoosingKiller")==true and not player:GetAttribute("InMenu") and not loading.Visible
 votePanel.Visible=net:GetAttribute("Phase")=="Votação" and not player:GetAttribute("InMenu") and not player:GetAttribute("AFK") and not settingsOverlay.Visible and not loading.Visible
 if not votePanel.Visible then return end
 local seconds=math.max(0,math.ceil((net:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
 voteTimer.Text=tostring(seconds)
 local ok,counts=pcall(function() return game:GetService("HttpService"):JSONDecode(net:GetAttribute("MapVotes") or "{}") end)
 for name,b in pairs(mapButtons) do
  b.Votes.Text=tostring(ok and counts[name] or 0).." VOTOS"
  local selected=player:GetAttribute("MapVote")==name
  b.BackgroundColor3=selected and Color3.fromRGB(58,72,105) or Color3.fromRGB(16,16,21)
  b.UIStroke.Color=selected and Color3.fromRGB(190,205,255) or Color3.fromRGB(150,150,158)
  b.UIStroke.Transparency=selected and .12 or .72
 end
end)

local dtSum=0
RunService.RenderStepped:Connect(function(dt)
 dtSum+=dt if dtSum<.1 then return end dtSum=0
 local hidden=player:GetAttribute("InMenu") or player:GetAttribute("VoidActive") or player:GetAttribute("SweanLoadingDone")~=true
 if result.Visible and os.clock()>=resultUntil then hideResult() end
 settingsButton.Visible=not hidden and not result.Visible settingsOverlay.Visible=settingsOverlay.Visible and not hidden
 profileHUD.Visible=not hidden and not result.Visible
 roster.Visible=not hidden and not result.Visible and player:GetAttribute("InRound")==true and player:GetAttribute("IsJason")~=true and player:GetAttribute("Spectating")~=true
 updateRoster()
 local controlsVisible=not settingsOverlay.Visible and not result.Visible and player:GetAttribute("InMenu")~=true and player:GetAttribute("VoidActive")~=true and player:GetAttribute("SweanLoadingDone")==true and player:GetAttribute("Spectating")~=true
 local inRound=player:GetAttribute("InRound") local down=player:GetAttribute("Downed") local status=player:GetAttribute("RoundStatus")
 healthHUD.Visible=not hidden and inRound and not result.Visible
 local healthHumanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 condition.Text="♥  "..tostring(math.floor(healthHumanoid and healthHumanoid.Health or 0))
 condition.TextColor3=down and Color3.fromRGB(231,101,107) or player:GetAttribute("Injured") and Color3.fromRGB(229,186,100) or Color3.fromRGB(144,223,111)
 healthHUD.UIStroke.Color=condition.TextColor3
 local stats=player:FindFirstChild("leaderstats") local xp=stats and stats:FindFirstChild("XP") local lv=stats and stats:FindFirstChild("Nível") local pts=stats and stats:FindFirstChild("Pontos")
 local n=lv and lv.Value or 1 local total=xp and xp.Value or 0 local minimum=15*(n-1)^2+35*(n-1) local nextLevel=15*n^2+35*n
 xpFill.Size=UDim2.fromScale(n>=1000 and 1 or math.clamp((total-minimum)/(nextLevel-minimum),0,1),1)
 levelText.Text="NÍVEL "..n.."   •   "..(n>=1000 and "MÁXIMO" or math.max(0,total-minimum).."/"..(nextLevel-minimum)) pointsText.Text="◉  "..(pts and pts.Value or 0)
 local phase=net:GetAttribute("Phase") or "Aguardando"
 local left=math.max(0,math.ceil((net:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
 countdown.Visible=not hidden and (phase=="Intervalo" or phase=="Escolha")
 actionLayout()
 if phase=="Escolha" then countdownText.Text="Escolhendo perseguidor • "..left.."s"
 elseif left==0 and phase=="Intervalo" then countdownText.Text=player:GetAttribute("AFK") and "AFK ativado" or "Aguardando jogadores" else countdownText.Text=string.format("%02d:%02d • %d/%d",math.floor(left/60),left%60,net:GetAttribute("Waiting") or 0,net:GetAttribute("MaxPlayers") or 8) end
 top.Visible=not hidden and phase=="Partida" and (inRound or player:GetAttribute("Spectating")==true)
 local isJason=player:GetAttribute("IsJason")
 topActions.Visible=controlsVisible and inRound and not down
 bar.Visible=controlsVisible and inRound
 run.Visible=controlsVisible and inRound and not down
 crouch.Visible=controlsVisible and inRound and not down and not isJason
 attackButton.Visible=controlsVisible and inRound and not down and isJason
 if heldRunInput and not down then mode="run" else mode=player:GetAttribute("MoveMode") or "walk" end
 run.Text="CORRER"
 run.TextTransparency=mode=="run" and 0 or .12
 crouch.Text=mode=="crouch" and "LEVANTAR" or "AGACHAR"
 local stamina=player:GetAttribute("Stamina") or 0 local maxStamina=math.max(1,player:GetAttribute("MaxStamina") or 100)
 staminaFill.Size=UDim2.fromScale(math.clamp(stamina/maxStamina,0,1),1)
 staminaTrack.Visible=not hidden and inRound and not down
 local reviveTarget=nil local reviveDistance=8.5
 if controlsVisible and inRound and not down and not isJason then
  local myRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if myRoot then
   for _,other in ipairs(Players:GetPlayers()) do
    if other~=player and other:GetAttribute("InRound") and other:GetAttribute("Downed") then
     local rr=other.Character and other.Character:FindFirstChild("HumanoidRootPart")
     if rr then
      local distance=(rr.Position-myRoot.Position).Magnitude
      if distance<reviveDistance then reviveDistance=distance reviveTarget=other end
     end
    end
   end
  end
 end
 reviveNearby.Visible=reviveTarget~=nil and (player:GetAttribute("ReviveAt") or 0)<=workspace:GetServerTimeNow() and (player:GetAttribute("CarryingUserId") or 0)==0
 reviveNearby.Active=reviveNearby.Visible
 carryNearby.Visible=controlsVisible and inRound and not isJason and (reviveTarget~=nil or (player:GetAttribute("CarryingUserId") or 0)>0)
 carryNearby.Text=(player:GetAttribute("CarryingUserId") or 0)>0 and "SOLTAR" or "CARREGAR"
 bar.Visible=controlsVisible and inRound and (isJason or reviveNearby.Visible or carryNearby.Visible)
 timer.Text=string.format("%d:%02d",math.floor(left/60),left%60)
 local stage=net:GetAttribute("MissionStage") or "Waiting"
 mission.Visible=not hidden and phase=="Partida" and not isJason and (inRound or player:GetAttribute("Spectating"))
 missionText.Text=missionCopy(stage)
 inventory.Visible=not hidden and inRound and not isJason
 inventoryIcon.Text=player:GetAttribute("HasKey") and "🔑" or "—"
 inventoryLabel.Text=player:GetAttribute("HasKey") and "CHAVE  1/1" or "VAZIO  0/1"
 exitHighlight.Enabled=false
 if player:GetAttribute("HasKey") and phase=="Partida" then
  local activeArena=workspace:FindFirstChild("ActiveArena")
  local objectives=activeArena and activeArena:FindFirstChild("RoundObjectives")
  local exit=objectives and objectives:FindFirstChild("EscapeExit")
  if exit then exitHighlight.Adornee=exit exitHighlight.Enabled=true end
 end
 local killer=net:GetAttribute("Killer") local stats=player:FindFirstChild("leaderstats") local score=stats and stats:FindFirstChild("Pontos")
 detail.Text=""
 local reviveLeft=(player:GetAttribute("ReviveAt") or 0)-workspace:GetServerTimeNow()
 local protected=(player:GetAttribute("ProtectedUntil") or 0)-workspace:GetServerTimeNow()
 if reviveLeft>0 then notice.Text=string.format("Reanimando • %.1fs",reviveLeft)
 elseif down then notice.Text="Caído • "..math.max(0,math.ceil((player:GetAttribute("BleedoutAt") or 0)-workspace:GetServerTimeNow())).."s"
 elseif protected>0 and inRound then notice.Text=""
 elseif os.clock()>noticeUntil then notice.Text="" end
 notice.Visible=not hidden and notice.Text~=""
 local spec=player:GetAttribute("Spectating") and not hidden and not result.Visible
 spectate.Visible=spec or false
 local camera=workspace.CurrentCamera
 if spec and camera then
  local targets={}
  for _,p in ipairs(Players:GetPlayers()) do
   local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if p~=player and p:GetAttribute("InRound") and not p:GetAttribute("VoidActive") and hum and hum.Health>0 then table.insert(targets,p) end
  end
  table.sort(targets,function(a,b) return a.UserId<b.UserId end)
  if #targets>0 then
   if watchedId then for i,p in ipairs(targets) do if p.UserId==watchedId then index=i break end end end
   index=((index-1)%#targets)+1 local p=targets[index] watchedId=p.UserId
   camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=p.Character:FindFirstChildOfClass("Humanoid") camera.FieldOfView=player:GetAttribute("CameraFOV") or 48
   spectatorName.Text=p.DisplayName watching=true
  else
   watchedId=nil
   spectate.Visible=false
   spectatorName.Text=""
   if not watching then camera.CameraType=Enum.CameraType.Scriptable end
   watching=true
  end
 elseif watching and not hidden and camera then watching=false watchedId=nil camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") camera.FieldOfView=player:GetAttribute("CameraFOV") or 48 end
 if camera and not spec and not hidden and not result.Visible and not loading.Visible then
  local ownHumanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if ownHumanoid and ownHumanoid.Health>0 then
   if camera.CameraSubject~=ownHumanoid then camera.CameraSubject=ownHumanoid end
   if camera.CameraType==Enum.CameraType.Scriptable then camera.CameraType=Enum.CameraType.Custom end
  end
 end
 highlight.Enabled=false
 if inRound and not hidden then
  for _,m in ipairs(workspace:GetChildren()) do if m:GetAttribute("ActivePursuer") and (m:GetAttribute("TargetUserId") or 0)>0 then
   local p=Players:GetPlayerByUserId(m:GetAttribute("TargetUserId")) highlight.Adornee=p and p.Character highlight.Enabled=p~=nil break
  end end
 end
 -- Local footstep audio uses the requested walking asset when that package exposes a Sound.
 if inRound and not down and not hidden then
  local rr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  local speed=rr and (rr.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
  local stepDelay=mode=="run" and .38 or mode=="crouch" and .95 or .62
  if hum and hum.FloorMaterial~=Enum.Material.Air and speed>2 then
   gui:SetAttribute("NextFootstep",gui:GetAttribute("NextFootstep") or 0)
   if os.clock()>gui:GetAttribute("NextFootstep") then
    gui:SetAttribute("NextFootstep",os.clock()+stepDelay)
    local template=net:FindFirstChild("FootstepSound")
    if template and rr then
     local sound=template:Clone() sound.Volume=mode=="crouch" and .08 or mode=="run" and .32 or .18 sound.Parent=rr sound:Play() Debris:AddItem(sound,3)
    end
   end
  end
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



if player.GetAttributeChangedSignal then
 player:GetAttributeChangedSignal("VoidActive"):Connect(function()
  if player:GetAttribute("VoidActive") then loading.Visible=false goodLuck.Visible=false clearArenaLoadingAvatar() restoreLoadingCamera() end
 end)
end


