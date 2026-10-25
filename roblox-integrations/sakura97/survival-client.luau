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
topActions.AnchorPoint=Vector2.new(1,1) topActions.Size=UDim2.fromOffset(64,64) topActions.Position=UDim2.new(1,-165,1,-115)
local bar=Instance.new("Frame",gui) bar.Name="Actions" bar.BackgroundTransparency=1
bar.AnchorPoint=Vector2.new(1,1) bar.Size=UDim2.fromOffset(74,74) bar.Position=UDim2.new(1,-84,1,-86)
local function cleanAction(parent,name,label,size,pos,callback)
 local b=button(parent,name,label,size,pos,callback)
 b.BackgroundTransparency=1 b.TextSize=24 b.TextStrokeTransparency=.38
 b.UIStroke.Enabled=false b.UICorner.CornerRadius=UDim.new(1,0)
 return b
end
local run=cleanAction(topActions,"Run","CORRER",UDim2.fromOffset(64,64),UDim2.fromOffset(0,0),function()
 if player:GetAttribute("IsJason") then event:FireServer("attack") end
end)
run.TextSize=11 run.BackgroundTransparency=.35 run.BackgroundColor3=Color3.fromRGB(25,26,30)
local heldRunInput=nil
local function stopHeldRun(input)
 if heldRunInput and (not input or input==heldRunInput) then
  heldRunInput=nil
  mode="walk"
  event:FireServer("mode","walk")
 end
end
run.InputBegan:Connect(function(input)
 if player:GetAttribute("IsJason") or player:GetAttribute("Downed") or player:GetAttribute("Injured") then return end
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
local profileHUD=panel("Profile",UDim2.fromOffset(190,58),UDim2.fromOffset(18,66)) profileHUD.BackgroundTransparency=1 profileHUD.UIStroke.Enabled=false
local xpTrack=Instance.new("Frame",profileHUD) xpTrack.Name="XP" xpTrack.Size=UDim2.new(1,0,0,8) xpTrack.BackgroundColor3=Color3.fromRGB(22,23,32) xpTrack.BackgroundTransparency=.3 xpTrack.BorderSizePixel=0 Instance.new("UICorner",xpTrack).CornerRadius=UDim.new(0,5)
local xpFill=Instance.new("Frame",xpTrack) xpFill.Name="Fill" xpFill.Size=UDim2.fromScale(0,1) xpFill.BackgroundColor3=Color3.fromRGB(96,118,205) xpFill.BorderSizePixel=0 Instance.new("UICorner",xpFill).CornerRadius=UDim.new(0,5)
local levelText=text(xpTrack,"Level","NÍVEL 1",UDim2.new(1,-12,0,18),UDim2.fromOffset(6,-20)) levelText.TextSize=11 levelText.Font=Enum.Font.GothamBold levelText.TextXAlignment=Enum.TextXAlignment.Left
local pointsText=text(profileHUD,"Points","◉  0",UDim2.new(1,0,0,28),UDim2.fromOffset(0,26)) pointsText.TextSize=19 pointsText.TextColor3=Color3.fromRGB(165,215,121) pointsText.TextXAlignment=Enum.TextXAlignment.Left
local healthHUD=panel("Condition",UDim2.fromOffset(148,38),UDim2.new(0,18,1,-52)) healthHUD.UIStroke.Color=Color3.fromRGB(106,150,91)
local condition=text(healthHUD,"Value","♥  100",UDim2.fromScale(1,1),UDim2.new()) condition.Font=Enum.Font.GothamBold condition.TextSize=22 condition.TextColor3=Color3.fromRGB(144,223,111)
local roster=Instance.new("Frame",gui)
roster.Name="PlayerRoster" roster.BackgroundTransparency=1 roster.Position=UDim2.fromOffset(12,112) roster.Size=UDim2.fromOffset(190,306)
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
result.BackgroundColor3=Color3.new(0,0,0) result.BackgroundTransparency=0 result.BorderSizePixel=0
result.Visible=false result.ZIndex=70 result.ClipsDescendants=true
local resultView=Instance.new("ViewportFrame",result)
resultView.Name="WinnerPortrait" resultView.BackgroundColor3=Color3.new(0,0,0) resultView.BackgroundTransparency=0
resultView.Size=UDim2.fromScale(1,1) resultView.Position=UDim2.new() resultView.ZIndex=71
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
local function restoreResultCamera()
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
 restoreResultCamera()
end
local resultClose=button(result,"Close","×",UDim2.fromOffset(42,42),UDim2.new(1,-54,0,10),hideResult)
resultClose.ZIndex=77 resultClose.TextSize=26 resultClose.BackgroundTransparency=1 resultClose.UIStroke.Enabled=false

local function resultVictimReaction(victim,generation)
 local root=victim.PrimaryPart or victim:FindFirstChild("HumanoidRootPart")
 if not root then return end
 victim.PrimaryPart=root
 local joints={}
 for _,j in ipairs(victim:GetDescendants()) do
  if j:IsA("Motor6D") then joints[j.Name:lower()]=j end
 end
 local rootJoint=joints.rootjoint or joints.root
 local neck=joints.neck
 local leftShoulder=joints["left shoulder"] or joints.leftshoulder
 local rightShoulder=joints["right shoulder"] or joints.rightshoulder
 local leftHip=joints["left hip"] or joints.lefthip
 local rightHip=joints["right hip"] or joints.righthip
 task.delay(.56,function()
  if generation~=resultGeneration or not victim.Parent then return end
  local base=root.CFrame
  local fallen=base*CFrame.new(1.25,-1.45,-.55)*CFrame.Angles(math.rad(74),0,math.rad(-48))
  local alpha=Instance.new("NumberValue") alpha.Value=0 alpha.Parent=resultView
  local conn=alpha:GetPropertyChangedSignal("Value"):Connect(function()
   if not victim.Parent then return end
   local a=alpha.Value
   local eased=TweenService:GetValue(a,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
   root.CFrame=base:Lerp(fallen,eased)
   if rootJoint and rootJoint.Parent then rootJoint.Transform=CFrame.Angles(math.rad(10*a),0,math.rad(-8*a)) end
   if neck and neck.Parent then neck.Transform=CFrame.Angles(math.rad(-10*a),0,math.rad(8*a)) end
   if leftShoulder and leftShoulder.Parent then leftShoulder.Transform=CFrame.Angles(math.rad(24*a),0,math.rad(-18*a)) end
   if rightShoulder and rightShoulder.Parent then rightShoulder.Transform=CFrame.Angles(math.rad(18*a),0,math.rad(22*a)) end
   if leftHip and leftHip.Parent then leftHip.Transform=CFrame.Angles(math.rad(-14*a),0,math.rad(-6*a)) end
   if rightHip and rightHip.Parent then rightHip.Transform=CFrame.Angles(math.rad(-18*a),0,math.rad(8*a)) end
  end)
  local tween=TweenService:Create(alpha,TweenInfo.new(.62,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Value=1})
  tween:Play()
  tween.Completed:Connect(function() conn:Disconnect() alpha:Destroy() end)
 end)
end

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
 resultWinner.Text=data.jasonWon and ("VENCEDOR  •  "..winnerName) or "A EQUIPE DE SOBREVIVENTES RESISTIU"
 resultView.Visible=data.jasonWon==true
 resultShade.BackgroundTransparency=data.jasonWon and .64 or .22

 if data.jasonWon then
  local template=nil
  for _,candidate in ipairs(workspace:GetChildren()) do
   if candidate:IsA("Model") and candidate:GetAttribute("ActivePursuer") then template=candidate break end
  end
  template=template or net:FindFirstChild("PresentationJason")

  local sceneTemplate=RS:FindFirstChild("MenuSceneTemplate")
  local scene=sceneTemplate and sceneTemplate:Clone()
  local base=Vector3.zero
  local forward=Vector3.new(0,0,-1)
  if scene then
   scene.Name="VictoryDoorsScene"
   for _,d in ipairs(scene:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then d:Destroy()
    elseif d:IsA("Sound") then d.Playing=false
    elseif d:IsA("BasePart") then d.Anchored=true d.CanCollide=false d.CanTouch=false d.CanQuery=false end
   end
   scene.Parent=resultWorld
   local best,bestArea=nil,-1
   for _,part in ipairs(scene:GetDescendants()) do
    if part:IsA("BasePart") and part.Transparency<.98 and part.CFrame.UpVector.Y>.82 and part.Size.X>=7 and part.Size.Z>=7 then
     local area=part.Size.X*part.Size.Z
     if area>bestArea then best,bestArea=part,area end
    end
   end
   if best then
    base=best.CFrame:PointToWorldSpace(Vector3.new(0,best.Size.Y/2+.05,0))
    forward=Vector3.new(best.CFrame.LookVector.X,0,best.CFrame.LookVector.Z)
    if forward.Magnitude<.1 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
   end
  end

  local right=forward:Cross(Vector3.yAxis)
  if right.Magnitude<.1 then right=Vector3.xAxis else right=right.Unit end
  local killerModel=nil
  if template then
   template.Archivable=true
   killerModel=template:Clone()
   killerModel.Name="WinnerPursuer" killerModel:SetAttribute("PresentationPursuer",true)
   killerModel:SetAttribute("PresentationState","Execution")
   killerModel:SetAttribute("PresentationAt",workspace:GetServerTimeNow())
   killerModel:SetAttribute("ActivePursuer",nil)
   killerModel.PrimaryPart=killerModel.PrimaryPart or killerModel:FindFirstChild("HumanoidRootPart")
   for _,part in ipairs(killerModel:GetDescendants()) do
    if part:IsA("BasePart") then part.Anchored=part==killerModel.PrimaryPart part.CanCollide=false part.CanTouch=false part.CanQuery=false end
   end
   killerModel.Parent=resultWorld
  end

  local victimId=tonumber(data.lastVictimUserId) or 0
  if victimId<=0 then
   local fallback=(data.board or {})[1]
   victimId=fallback and fallback.userId or 0
  end
  local victimPlayer=victimId>0 and Players:GetPlayerByUserId(victimId) or nil
  local victimCharacter=victimPlayer and victimPlayer.Character
  local victim=nil
  if victimCharacter then
   local oldArchivable=victimCharacter.Archivable victimCharacter.Archivable=true
   local ok,clone=pcall(function() return victimCharacter:Clone() end)
   victimCharacter.Archivable=oldArchivable
   if ok then victim=clone end
  end

  local killerSize=Vector3.new(4,6,2)
  if killerModel then local _,size=killerModel:GetBoundingBox() killerSize=size end
  local killerPos=base+forward*.55-right*.25+Vector3.new(0,killerSize.Y*.5,0)
  local victimPos=base+forward*4.9+right*1.15

  if killerModel and killerModel.PrimaryPart then
   killerModel:PivotTo(CFrame.lookAt(killerPos,victimPos+Vector3.new(0,2.5,0)))
  end

  if victim then
   victim.Name="VictorySurvivor"
   victim:SetAttribute("SourceUserId",victimId)
   victim.PrimaryPart=victim.PrimaryPart or victim:FindFirstChild("HumanoidRootPart")
   for _,d in ipairs(victim:GetDescendants()) do
    if d:IsA("LuaSourceContainer") or d:IsA("Tool") or d:IsA("BillboardGui") then d:Destroy()
    elseif d:IsA("BasePart") then d.Anchored=d==victim.PrimaryPart d.CanCollide=false d.CanTouch=false d.CanQuery=false
    elseif d:IsA("Motor6D") then d.Transform=CFrame.identity end
   end
   local victimHumanoid=victim:FindFirstChildOfClass("Humanoid")
   if victimHumanoid then victimHumanoid.AutoRotate=false victimHumanoid.PlatformStand=false end
   victim.Parent=resultWorld
   local _,vsize=victim:GetBoundingBox()
   local vpos=victimPos+Vector3.new(0,vsize.Y*.5,0)
   victim:PivotTo(CFrame.lookAt(vpos,vpos+forward))
   resultVictimReaction(victim,generation)
  end

  local focus=base+forward*2.65+right*.45+Vector3.new(0,math.max(2.5,killerSize.Y*.48),0)
  local cameraPos=base-forward*8.4-right*3.6+Vector3.new(0,math.max(3.3,killerSize.Y*.58),0)
  resultCamera.CFrame=CFrame.lookAt(cameraPos,focus)
  resultCamera.FieldOfView=50

  if killerModel then
   task.delay(1.6,function()
    if generation~=resultGeneration or not killerModel.Parent then return end
    killerModel:SetAttribute("PresentationState","Winning Screen")
    killerModel:SetAttribute("PresentationAt",workspace:GetServerTimeNow())
   end)
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
 result.Visible=true resultUntil=os.clock()+11
 task.delay(11,function() if generation==resultGeneration then hideResult() end end)
end

local spectate=panel("Spectate",UDim2.fromOffset(300,90),UDim2.new(.5,-150,1,-120))
local spectatorName=text(spectate,"Player","Assistindo",UDim2.new(1,0,0,34),UDim2.new())
local index=1 local watching=false local watchedId=nil
button(spectate,"Previous","‹",UDim2.fromOffset(50,38),UDim2.fromOffset(8,42),function() index-=1 watchedId=nil end)
button(spectate,"Next","›",UDim2.fromOffset(50,38),UDim2.fromOffset(242,42),function() index+=1 watchedId=nil end)
button(spectate,"Exit","Sair da câmera",UDim2.fromOffset(170,38),UDim2.fromOffset(65,42),function() event:FireServer("spectateExit") end)
local loading=panel("ArenaLoading",UDim2.fromScale(1,1),UDim2.new())
loading.BackgroundColor3=Color3.fromRGB(4,4,6) loading.BackgroundTransparency=0 loading.ZIndex=80 loading.Visible=false loading.ClipsDescendants=true
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
loadingAvatar.ZIndex=82
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
 buildArenaLoadingAvatar()
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
   loading.Visible=false clearArenaLoadingAvatar() event:FireServer("loadFailed",roundId)
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
  loadToken+=1 loading.Visible=false goodLuck.Visible=false clearArenaLoadingAvatar() progressFill.Size=UDim2.fromScale(0,1)
 elseif action=="notice" then
  notice.Text=a noticeUntil=os.clock()+5
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

local votePanel=panel("MapVoting",UDim2.new(.66,0,.68,0),UDim2.fromScale(.17,.15))
votePanel.BackgroundTransparency=.18 votePanel.Visible=false
local voteTitle=text(votePanel,"Title","VOTAR UM MAPA",UDim2.new(1,0,0,34),UDim2.new()) voteTitle.Font=Enum.Font.GothamBold
local mapButtons={}
local mapNames={DoomspireBrickbattle="Doomspire Brickbattle",JuggernautFightArena="Juggernaut Fight Arena",PirateBayIsland="Pirate Bay",NaturalDisasterSurvival="Natural Disaster Survival",RocketArena="Rocket Arena"}
for i,map in ipairs(config.Maps) do
 local col=(i-1)%2 local row=math.floor((i-1)/2)
 local b=button(votePanel,map.name,map.name,UDim2.new(.48,0,.19,0),UDim2.new(.01+col*.50,0,.12+row*.21,0),function() event:FireServer("voteMap",map.name) end)
 b.TextSize=12 b.TextWrapped=true mapButtons[map.name]=b
 local preview=Instance.new("ImageLabel",b) preview.Name="Preview" preview.Size=UDim2.fromScale(1,1) preview.BackgroundTransparency=1 preview.Image="rbxthumb://type=Asset&id="..map.id.."&w=420&h=420" preview.ImageTransparency=.3 preview.ScaleType=Enum.ScaleType.Crop preview.ZIndex=b.ZIndex b.Text=""
 Instance.new("UICorner",preview).CornerRadius=UDim.new(0,10)
 local caption=text(b,"Caption",mapNames[map.name] or map.name,UDim2.new(1,-8,0,24),UDim2.new(0,4,1,-26)) caption.TextSize=12 caption.Font=Enum.Font.GothamBold caption.ZIndex=b.ZIndex+1 caption.TextStrokeTransparency=.2
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
 votePanel.Visible=player:GetAttribute("MapVote")==nil and net:GetAttribute("Phase")=="Intervalo" and not player:GetAttribute("InMenu") and not player:GetAttribute("AFK") and not settingsOverlay.Visible and not loading.Visible
 if not votePanel.Visible then return end
 local seconds=math.max(0,math.ceil((net:GetAttribute("EndsAt") or 0)-workspace:GetServerTimeNow()))
 voteTitle.Text=seconds>0 and ("VOTAR UM MAPA • "..seconds.."s") or "AGUARDANDO 2 JOGADORES"
 local ok,counts=pcall(function() return game:GetService("HttpService"):JSONDecode(net:GetAttribute("MapVotes") or "{}") end)
 for name,b in pairs(mapButtons) do b.Caption.Text=(mapNames[name] or name).." • "..tostring(ok and counts[name] or 0).." votos" b.BackgroundColor3=player:GetAttribute("MapVote")==name and Color3.fromRGB(42,90,46) or Color3.fromRGB(18,18,22) end
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
 run.Visible=controlsVisible and inRound and not down and (isJason or not player:GetAttribute("Injured"))
 if heldRunInput and not isJason and not down and not player:GetAttribute("Injured") then
  mode="run"
 else
  mode=player:GetAttribute("MoveMode") or "walk"
 end
 run.Text=isJason and "ATACAR" or "CORRER"
 run.TextTransparency=(not isJason and mode=="run") and 0 or .12
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
 reviveNearby.Visible=reviveTarget~=nil and (player:GetAttribute("ReviveAt") or 0)<=workspace:GetServerTimeNow()
 reviveNearby.Active=reviveNearby.Visible
 bar.Visible=bar.Visible and reviveNearby.Visible
 timer.Text=string.format("%d:%02d",math.floor(left/60),left%60)
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
   if p~=player and p:GetAttribute("InRound") and not p:GetAttribute("IsJason") and not p:GetAttribute("VoidActive") and hum and hum.Health>0 then table.insert(targets,p) end
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
  if player:GetAttribute("VoidActive") then loading.Visible=false goodLuck.Visible=false clearArenaLoadingAvatar() end
 end)
end


