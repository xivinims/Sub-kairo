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
topActions.AnchorPoint=Vector2.new(1,0) topActions.Size=UDim2.fromOffset(112,52) topActions.Position=UDim2.new(1,-118,0,58)
local bar=Instance.new("Frame",gui) bar.Name="Actions" bar.BackgroundTransparency=1
bar.AnchorPoint=Vector2.new(1,1) bar.Size=UDim2.fromOffset(224,88) bar.Position=UDim2.new(1,-24,1,-92)
local function cleanAction(parent,name,label,size,pos,callback)
 local b=button(parent,name,label,size,pos,callback)
 b.BackgroundTransparency=1 b.TextSize=24 b.TextStrokeTransparency=.38
 b.UIStroke.Enabled=false b.UICorner.CornerRadius=UDim.new(1,0)
 return b
end
local run=cleanAction(topActions,"Run","»",UDim2.fromOffset(52,52),UDim2.fromOffset(0,0),function() mode=mode=="run" and "walk" or "run" event:FireServer("mode",mode) end)
local flashlight=cleanAction(topActions,"Flashlight","",UDim2.fromOffset(52,52),UDim2.fromOffset(58,0),function() event:FireServer("flashlight") end)
local slow=cleanAction(bar,"Slow","",UDim2.fromOffset(68,68),UDim2.fromOffset(0,16),function() mode=mode=="slow" and "walk" or "slow" event:FireServer("mode",mode) end)
local jump=cleanAction(bar,"Jump","↑",UDim2.fromOffset(72,72),UDim2.fromOffset(76,8),function()
 local char=player.Character local h=char and char:FindFirstChildOfClass("Humanoid")
 if h and player:GetAttribute("InRound") and not player:GetAttribute("Downed") and not cinematicActive then h.Jump=true end
end) jump.TextSize=34
local attack=cleanAction(bar,"Attack","╱",UDim2.fromOffset(76,76),UDim2.fromOffset(148,0),function()
 if player:GetAttribute("IsJason") then event:FireServer("attack") end
end) attack.TextSize=40
local reviveNearby=cleanAction(bar,"ReviveNearby","+",UDim2.fromOffset(64,64),UDim2.fromOffset(-70,18),function()
 event:FireServer("revive")
end)
reviveNearby.TextSize=38 reviveNearby.Visible=false
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
 topActions.Position=UDim2.new(1,-118,0,58)
end
local notice=text(gui,"Notice","",UDim2.new(.72,0,0,46),UDim2.new(.14,0,1,-132)) notice.TextSize=15
local settingsOverlay=Instance.new("Frame",gui) settingsOverlay.Name="SettingsOverlay" settingsOverlay.Size=UDim2.fromScale(1,1) settingsOverlay.BackgroundColor3=Color3.new(0,0,0) settingsOverlay.BackgroundTransparency=.32 settingsOverlay.ZIndex=110 settingsOverlay.Visible=false
local settingsUI=Settings.build(settingsOverlay,player,function() settingsOverlay.Visible=false end)
local settingsButton=button(gui,"SettingsButton","⚙",UDim2.fromOffset(44,44),UDim2.new(1,-52,0,2),function() settingsOverlay.Visible=not settingsOverlay.Visible end) settingsButton.TextSize=27 settingsButton.BackgroundTransparency=1 settingsButton.UIStroke.Enabled=false
local firstPerson=false
local cameraButton=button(gui,"CameraMode","◉",UDim2.fromOffset(44,44),UDim2.new(1,-102,0,2),function()
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
local roster=Instance.new("Frame",gui)
roster.Name="PlayerRoster" roster.BackgroundTransparency=1 roster.Position=UDim2.fromOffset(14,128) roster.Size=UDim2.fromOffset(204,330)
local rosterList=Instance.new("UIListLayout",roster) rosterList.Padding=UDim.new(0,4) rosterList.SortOrder=Enum.SortOrder.LayoutOrder
local rosterRows={}
local function rosterRow(p)
 local row=Instance.new("Frame",roster)
 row.Name="Player_"..p.UserId row.Size=UDim2.fromOffset(198,36) row.BorderSizePixel=0
 row.BackgroundColor3=Color3.fromRGB(58,59,64) row.BackgroundTransparency=.08 row.LayoutOrder=p.UserId
 local corner=Instance.new("UICorner",row) corner.CornerRadius=UDim.new(0,9)
 local gradient=Instance.new("UIGradient",row)
 gradient.Rotation=0
 gradient.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.78),
  NumberSequenceKeypoint.new(.46,.38),
  NumberSequenceKeypoint.new(1,.04)
 })
 local name=text(row,"Name",p.DisplayName or p.Name,UDim2.new(1,-48,0,18),UDim2.fromOffset(42,2))
 name.Font=Enum.Font.GothamBold name.TextSize=11 name.TextXAlignment=Enum.TextXAlignment.Left name.TextTruncate=Enum.TextTruncate.AtEnd name.TextWrapped=false name.ZIndex=3
 local track=Instance.new("Frame",row)
 track.Name="Health" track.Size=UDim2.new(1,-55,0,5) track.Position=UDim2.fromOffset(42,25)
 track.BackgroundColor3=Color3.fromRGB(50,51,54) track.BackgroundTransparency=.12 track.BorderSizePixel=0 track.ZIndex=3
 Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
 local fill=Instance.new("Frame",track)
 fill.Name="Fill" fill.Size=UDim2.fromScale(1,1) fill.BackgroundColor3=Color3.fromRGB(130,193,74) fill.BorderSizePixel=0 fill.ZIndex=4
 Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
 local heart=text(row,"Heart","♥",UDim2.fromOffset(16,16),UDim2.new(1,-18,0,18))
 heart.TextSize=12 heart.TextColor3=Color3.fromRGB(228,91,91) heart.ZIndex=4
 local avatar=Instance.new("ImageLabel",row)
 avatar.Name="Avatar" avatar.AnchorPoint=Vector2.new(0,.5) avatar.Position=UDim2.new(0,3,.5,0) avatar.Size=UDim2.fromOffset(30,30)
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
local function hideResult()
 result.Visible=false resultGeneration+=1 resultWorld:ClearAllChildren()
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
 task.delay(.72,function()
  if generation~=resultGeneration or not victim.Parent then return end
  local base=root.CFrame
  local alpha=Instance.new("NumberValue") alpha.Value=0 alpha.Parent=resultView
  local conn=alpha:GetPropertyChangedSignal("Value"):Connect(function()
   if not victim.Parent then return end
   local a=alpha.Value
   root.CFrame=base*CFrame.new(0,-1.05*a,.34*a)
   if rootJoint and rootJoint.Parent then rootJoint.Transform=CFrame.new(0,-.18*a,0)*CFrame.Angles(math.rad(18*a),0,0) end
   if neck and neck.Parent then neck.Transform=CFrame.Angles(math.rad(-12*a),0,math.rad(5*a)) end
   if leftShoulder and leftShoulder.Parent then leftShoulder.Transform=CFrame.Angles(math.rad(28*a),0,math.rad(-22*a)) end
   if rightShoulder and rightShoulder.Parent then rightShoulder.Transform=CFrame.Angles(math.rad(34*a),0,math.rad(24*a)) end
   if leftHip and leftHip.Parent then leftHip.Transform=CFrame.Angles(math.rad(-34*a),0,math.rad(-8*a)) end
   if rightHip and rightHip.Parent then rightHip.Transform=CFrame.Angles(math.rad(-42*a),0,math.rad(8*a)) end
  end)
  local tween=TweenService:Create(alpha,TweenInfo.new(.58,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Value=1})
  tween:Play()
  tween.Completed:Connect(function() conn:Disconnect() alpha:Destroy() end)
 end)
end

local function showResult(data)
 hideResult()
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
  local killerPos=base+forward*.8+Vector3.new(0,killerSize.Y*.5,0)
  local victimPos=base+forward*4.1

  if killerModel and killerModel.PrimaryPart then
   killerModel:PivotTo(CFrame.lookAt(killerPos,victimPos+Vector3.new(0,2.5,0)))
  end

  if victim then
   victim.Name="VictorySurvivor"
   victim:SetAttribute("SourceUserId",victimId)
   victim.PrimaryPart=victim.PrimaryPart or victim:FindFirstChild("HumanoidRootPart")
   for _,d in ipairs(victim:GetDescendants()) do
    if d:IsA("LuaSourceContainer") or d:IsA("Tool") or d:IsA("BillboardGui") then d:Destroy()
    elseif d:IsA("BasePart") then d.Anchored=d==victim.PrimaryPart d.CanCollide=false d.CanTouch=false d.CanQuery=false end
   end
   victim.Parent=resultWorld
   local _,vsize=victim:GetBoundingBox()
   local vpos=victimPos+Vector3.new(0,vsize.Y*.5,0)
   victim:PivotTo(CFrame.lookAt(vpos,killerPos))
   resultVictimReaction(victim,generation)
  end

  local focus=base+forward*2.35+Vector3.new(0,math.max(2.5,killerSize.Y*.48),0)
  local cameraPos=base-forward*9.6+right*2.8+Vector3.new(0,math.max(3.2,killerSize.Y*.56),0)
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
local goodLuck=text(loading,"GoodLuck","GOOD LUCK",UDim2.new(.8,0,0,80),UDim2.new(.1,0,.5,-40))
goodLuck.ZIndex=83 goodLuck.Font=Enum.Font.GothamBlack goodLuck.TextSize=30 goodLuck.TextTransparency=1 goodLuck.Visible=false
local progressTrack=Instance.new("Frame",loading)
progressTrack.Name="MapProgress" progressTrack.AnchorPoint=Vector2.new(0,1) progressTrack.Position=UDim2.new(0,0,1,0)
progressTrack.Size=UDim2.new(1,0,0,7) progressTrack.BorderSizePixel=0 progressTrack.BackgroundColor3=Color3.fromRGB(21,21,25) progressTrack.ZIndex=84
local progressFill=Instance.new("Frame",progressTrack)
progressFill.Name="Fill" progressFill.Size=UDim2.fromScale(0,1) progressFill.BorderSizePixel=0 progressFill.BackgroundColor3=Color3.fromRGB(222,222,226) progressFill.ZIndex=85
local progressGlow=Instance.new("Frame",progressFill)
progressGlow.Name="Tip" progressGlow.AnchorPoint=Vector2.new(1,.5) progressGlow.Position=UDim2.new(1,0,.5,0) progressGlow.Size=UDim2.fromOffset(18,16)
progressGlow.BackgroundColor3=Color3.fromRGB(245,245,248) progressGlow.BackgroundTransparency=.35 progressGlow.BorderSizePixel=0 progressGlow.ZIndex=86
local cinematicActive=false
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
 goodLuck.TextTransparency=1
 TweenService:Create(goodLuck,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
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
 loading.Visible=true goodLuck.Visible=false goodLuck.TextTransparency=1
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
   loading.Visible=false event:FireServer("loadFailed",roundId)
   notice.Text="A conexão está lenta. A arena continua carregando." return
  end
  local done=false local mediaDeadline=os.clock()+8
  loadingText.Text="PREPARANDO O AMBIENTE"
  setMapProgress(.82,.22)
  task.spawn(function()
   pcall(function() game:GetService("ContentProvider"):PreloadAsync({map}) end)
   done=true
  end)
  while not done and os.clock()<mediaDeadline and token==loadToken and not cinematicActive do task.wait(.1) end
  if token~=loadToken then return end
  setMapProgress(.96,.22)
  loadingText.Text=""
  playGoodLuckVoice(token)
  task.wait(1.35)
  if token~=loadToken then return end
  setMapProgress(1,.15)
  task.wait(.18)
  loading.Visible=false
  goodLuck.Visible=false
  -- Geometry gates readiness; optional unavailable audio/decals must not eject a player.
  if map and map.Parent and map:GetAttribute("RoundId")==roundId then event:FireServer("ready",roundId) end
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

local doorRound=nil local doorCF=nil
local function clearDoor() doorRound=nil end
local function closeDoor()
 -- The entrance remains an invisible gameplay marker; no physical/visual door is created.
end
net.Update.OnClientEvent:Connect(function(action,a,b)
 if action=="lobbyDoorGlow" then pulseLobbyDoor()
 elseif action=="jasonIntro" then
  local introLoadToken=loadToken
  task.spawn(function()
   while loading.Visible and introLoadToken==loadToken do task.wait(.05) end
   if introLoadToken==loadToken then playJasonIntro(a,b) end
  end)
 elseif action=="entrance" then clearDoor() doorRound=a doorCF=b
 elseif action=="closeEntrance" and a==doorRound then closeDoor()
 elseif action=="reset" then cancelCapture() cancelJasonIntro(not player:GetAttribute("VoidActive") and not player:GetAttribute("InMenu")) clearDoor() doorCF=nil loadToken+=1 loading.Visible=false goodLuck.Visible=false progressFill.Size=UDim2.fromScale(0,1)
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
 elseif input.KeyCode==Enum.KeyCode.F then event:FireServer("flashlight") end
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
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local speed=root and (root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude or 0
  local targetFov=player:GetAttribute("ReducedMotion") and baseFov or math.min(100,baseFov+(speed>4 and 14 or 8))
  jasonPresentationFov+=(targetFov-jasonPresentationFov)*math.min(1,dt*6)
  if camera.CameraType~=Enum.CameraType.Scriptable then camera.FieldOfView=jasonPresentationFov end
 else
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
 settingsButton.Visible=not hidden and not result.Visible settingsOverlay.Visible=settingsOverlay.Visible and not hidden
 profileHUD.Visible=not hidden and not result.Visible
 roster.Visible=not hidden and not result.Visible and player:GetAttribute("InRound")==true and player:GetAttribute("IsJason")~=true and player:GetAttribute("Spectating")~=true
 updateRoster()
 local controlsVisible=not settingsOverlay.Visible and not result.Visible and player:GetAttribute("InMenu")~=true and player:GetAttribute("VoidActive")~=true and player:GetAttribute("SweanLoadingDone")==true and player:GetAttribute("Spectating")~=true and not cinematicActive
 local inRound=player:GetAttribute("InRound") local down=player:GetAttribute("Downed") local status=player:GetAttribute("RoundStatus")
 healthHUD.Visible=not hidden and inRound and not result.Visible
 condition.Text=down and "♥  CAÍDO  0%" or player:GetAttribute("Injured") and "♥  FERIDO  50%" or "♥  100%"
 condition.TextColor3=down and Color3.fromRGB(231,101,107) or player:GetAttribute("Injured") and Color3.fromRGB(229,186,100) or Color3.fromRGB(144,223,111)
 healthHUD.UIStroke.Color=condition.TextColor3
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
 bar.Visible=controlsVisible and inRound topActions.Visible=controlsVisible and inRound
 run.Visible=controlsVisible and inRound and not down and not isJason and not player:GetAttribute("Injured")
 slow.Visible=controlsVisible and inRound and not down and not isJason
 jump.Visible=controlsVisible and inRound and not down
 flashlight.Visible=controlsVisible and inRound and not down and not isJason
 attack.Visible=controlsVisible and inRound and not down
 attack.Active=isJason attack.TextTransparency=isJason and 0 or .72
 mode=player:GetAttribute("MoveMode") or "walk"
 run.TextTransparency=mode=="run" and 0 or .2
 jump.TextTransparency=0
 flashlight.TextTransparency=player:GetAttribute("FlashlightOn") and 0 or .18
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
   watchedId=nil
   spectate.Visible=false
   spectatorName.Text=""
   if not watching then camera.CameraType=Enum.CameraType.Scriptable end
   watching=true
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
