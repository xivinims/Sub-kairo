local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local SoundService=game:GetService('SoundService')
local player=Players.LocalPlayer
local remote=RS:WaitForChild('MysteryUIAction')
local function make(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props) do o[k]=v end
 o.Parent=parent;return o
end
local gui=make('ScreenGui',player:WaitForChild('PlayerGui'),{Name='PoolGameControls',IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=1800,Enabled=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
make('Frame',gui,{Name='Shade',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(4,7,8),BackgroundTransparency=.58,BorderSizePixel=0})
local bar=make('Frame',gui,{Name='TopBar',Size=UDim2.new(1,0,0,58),BackgroundColor3=Color3.fromRGB(9,11,11),BackgroundTransparency=.12,BorderSizePixel=0})
make('UIGradient',bar,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.04),NumberSequenceKeypoint.new(1,1)})})
make('TextLabel',bar,{Position=UDim2.fromOffset(26,7),Size=UDim2.new(.65,0,0,26),BackgroundTransparency=1,Text='BILHAR',Font=Enum.Font.RobotoCondensed,TextSize=20,TextColor3=Color3.fromRGB(236,225,203),TextXAlignment=Enum.TextXAlignment.Left})
make('TextLabel',bar,{Position=UDim2.fromOffset(27,33),Size=UDim2.new(.7,0,0,16),BackgroundTransparency=1,Text='MIRE COM AS SETAS · ESPAÇO PARA TACAR',Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(166,163,155),TextXAlignment=Enum.TextXAlignment.Left})
local count=make('TextLabel',bar,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-26,0,14),Size=UDim2.fromOffset(180,28),BackgroundTransparency=1,Text='15 BOLAS RESTANTES',Font=Enum.Font.RobotoCondensed,TextSize=13,TextColor3=Color3.fromRGB(232,219,191),TextXAlignment=Enum.TextXAlignment.Right})
local panel=make('Frame',gui,{Name='PoolPanel',AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-16),Size=UDim2.new(.56,0,0,180),BackgroundColor3=Color3.fromRGB(13,15,15),BackgroundTransparency=.05,BorderSizePixel=0})
make('UICorner',panel,{CornerRadius=UDim.new(0,6)})
make('UIStroke',panel,{Color=Color3.fromRGB(181,162,127),Transparency=.72,Thickness=1})
make('UIGradient',panel,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(27,29,27),Color3.fromRGB(10,12,12))})
local message=make('TextLabel',panel,{Position=UDim2.new(0,18,0,12),Size=UDim2.new(1,-36,0,24),BackgroundTransparency=1,Text='AJUSTE A DIREÇÃO E A FORÇA',Font=Enum.Font.RobotoCondensed,TextSize=13,TextColor3=Color3.fromRGB(202,195,180),TextXAlignment=Enum.TextXAlignment.Left})
make('TextLabel',panel,{Position=UDim2.new(0,18,0,49),Size=UDim2.new(.28,0,0,17),BackgroundTransparency=1,Text='DIREÇÃO',Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(151,149,143),TextXAlignment=Enum.TextXAlignment.Left})
local angleLabel=make('TextLabel',panel,{Position=UDim2.new(0,18,0,68),Size=UDim2.new(.28,0,0,22),BackgroundTransparency=1,Text='0°',Font=Enum.Font.RobotoCondensed,TextSize=19,TextColor3=Color3.fromRGB(235,225,207),TextXAlignment=Enum.TextXAlignment.Left})
local powerLabel=make('TextLabel',panel,{Position=UDim2.new(.55,0,0,49),Size=UDim2.new(.4,0,0,18),BackgroundTransparency=1,Text='FORÇA 55%',Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(151,149,143),TextXAlignment=Enum.TextXAlignment.Left})
local track=make('Frame',panel,{Position=UDim2.new(.55,0,0,78),Size=UDim2.new(.40,0,0,3),BackgroundColor3=Color3.fromRGB(77,76,70),BorderSizePixel=0})
local fill=make('Frame',track,{Size=UDim2.fromScale(.55,1),BackgroundColor3=Color3.fromRGB(221,204,171),BorderSizePixel=0})
local knob=make('Frame',track,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.55,.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=Color3.fromRGB(244,235,215),BorderSizePixel=0})
make('UICorner',knob,{CornerRadius=UDim.new(1,0)})
local slider=make('TextButton',panel,{Position=UDim2.new(.52,0,0,57),Size=UDim2.new(.45,0,0,43),BackgroundTransparency=1,Text='',ZIndex=5})
local actions=make('Frame',panel,{Position=UDim2.new(0,16,0,112),Size=UDim2.new(1,-32,0,52),BackgroundTransparency=1})
local row=make('UIListLayout',actions,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local function makeButton(name,text,width,order)
 local b=make('TextButton',actions,{Name=name,LayoutOrder=order,Size=UDim2.new(width,0,1,0),BackgroundColor3=Color3.fromRGB(43,44,40),BackgroundTransparency=.08,BorderSizePixel=0,Text=text,Font=Enum.Font.RobotoCondensed,TextSize=13,TextColor3=Color3.fromRGB(229,219,199),AutoButtonColor=false})
 make('UICorner',b,{CornerRadius=UDim.new(0,4)});make('UIStroke',b,{Color=Color3.fromRGB(166,150,120),Transparency=.82})
 b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(65,60,49) end);b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(43,44,40) end)
 return b
end
local shoot=makeButton('Shoot','TACAR · ESPAÇO',.40,1);shoot.BackgroundColor3=Color3.fromRGB(80,69,51)
local restart=makeButton('Restart','NOVA PARTIDA',.34,2)
local exit=makeButton('Exit','SAIR · ESC',.26,3)
local impact=make('Sound',SoundService,{Name='PoolImpact',SoundId='rbxassetid://9120907256',Volume=.2,RollOffMaxDistance=42})
local angle=0;local power=.55;local active=false;local moving=false;local surface;local halfX=4.5;local halfZ=1.8
local controls;local camera;local savedCamera={};local cameraTween;local renderConnection;local inputDragging=false;local ballAddedConnection
local cueParts={};local aimPart;local aimDot
local function setControls(enabled)
 if enabled then if controls then controls:Enable();controls=nil end
 else pcall(function() local module=require(player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'));controls=module:GetControls();controls:Disable() end) end
end
local function align(position,axis)
 local up=axis.Unit;local right=up:Cross(Vector3.yAxis)
 if right.Magnitude<.01 then right=up:Cross(Vector3.xAxis) end
 right=right.Unit;return CFrame.fromMatrix(position,right,up,right:Cross(up).Unit)
end
local function createVisuals()
 for _,part in ipairs(cueParts) do part:Destroy() end;table.clear(cueParts)
 local segments={{3.62,.052,Color3.fromRGB(101,66,39),-1.92},{.15,.064,Color3.fromRGB(214,204,182),-.075},{.08,.04,Color3.fromRGB(169,143,109),.035},{.13,.058,Color3.fromRGB(39,32,27),-3.78}}
 for i,s in ipairs(segments) do cueParts[i]=make('Part',workspace,{Name='CueVisual'..i,Shape=Enum.PartType.Cylinder,Size=Vector3.new(s[2]*2,s[1],s[2]*2),Color=s[3],Material=i==1 and Enum.Material.Wood or Enum.Material.SmoothPlastic,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false}) end
 aimPart=make('Part',workspace,{Name='PoolAimGuide',Size=Vector3.new(.05,.05,.05),Transparency=1,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false})
 local a0=make('Attachment',aimPart,{Name='Start'});local a1=make('Attachment',aimPart,{Name='End'})
 make('Beam',aimPart,{Name='AimBeam',Attachment0=a0,Attachment1=a1,FaceCamera=true,Width0=.028,Width1=.012,LightEmission=.35,Color=ColorSequence.new(Color3.fromRGB(237,220,181)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.04),NumberSequenceKeypoint.new(1,.5)})})
 aimDot=make('Part',workspace,{Name='PoolAimDot',Shape=Enum.PartType.Ball,Size=Vector3.new(.13,.13,.13),Material=Enum.Material.Neon,Color=Color3.fromRGB(239,219,175),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false})
end
local function aimUpdate(extra)
 if not surface then return end
 local folder=workspace:FindFirstChild('StillHerePoolGame');local balls=folder and folder:FindFirstChild('Balls');local cue=balls and balls:FindFirstChild('CueBall')
 if not cue then return end
 local radians=math.rad(angle);local direction=(surface.CFrame.RightVector*math.cos(radians)+surface.CFrame.LookVector*math.sin(radians)).Unit
 local ballPos=cue.Position+surface.CFrame.UpVector*(.03+(extra or 0))
 local centers={ballPos-direction*1.94,ballPos-direction*.09,ballPos+direction*.035,ballPos-direction*3.78}
 for i,part in ipairs(cueParts) do part.CFrame=align(centers[i],direction) end
 local localDir=surface.CFrame:VectorToObjectSpace(direction)
 local dx=math.abs(localDir.X)>.001 and (halfX-.36)/math.abs(localDir.X) or math.huge
 local dz=math.abs(localDir.Z)>.001 and (halfZ-.36)/math.abs(localDir.Z) or math.huge
 local endpoint=ballPos+direction*math.max(.2,math.min(dx,dz))+surface.CFrame.UpVector*.04
 aimPart.CFrame=CFrame.new(ballPos);aimPart.End.Position=aimPart.CFrame:PointToObjectSpace(endpoint);aimDot.Position=endpoint
end
local function cameraGoal()
 camera=workspace.CurrentCamera;if not camera or not surface then return nil end
 local vp=camera.ViewportSize;local aspect=math.max(.5,vp.X/math.max(vp.Y,1));local vfov=math.rad(camera.FieldOfView);local hfov=2*math.atan(math.tan(vfov/2)*aspect)
 local distance=math.clamp(math.max(halfZ/math.tan(vfov/2),halfX/math.tan(hfov/2))*1.43,9,42)
 local center=surface.Position+surface.CFrame.UpVector*(surface.Size.Y/2+.7)
 return CFrame.lookAt(center+surface.CFrame.UpVector*distance+surface.CFrame.LookVector*distance*.08,center,surface.CFrame.UpVector)
end
local function refresh()
 angleLabel.Text=tostring(angle)..'°';powerLabel.Text='FORÇA '..math.floor(power*100+.5)..'%';fill.Size=UDim2.fromScale(power,1);knob.Position=UDim2.fromScale(power,.5)
 shoot.Text=moving and 'AGUARDE' or 'TACAR · ESPAÇO';shoot.Active=not moving;restart.Active=not moving
end
local function setPower(x)
 if track.AbsoluteSize.X>0 and not moving then power=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,.08,1);refresh() end
end
slider.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then inputDragging=true;setPower(i.Position.X) end end)
Input.InputChanged:Connect(function(i) if inputDragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setPower(i.Position.X) end end)
Input.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then inputDragging=false end end)
local function rotateBy(delta) if moving then return end;angle=math.clamp(angle+delta,-48,48);refresh() end
local function strike()
 if moving or not gui.Enabled then return end
 moving=true;refresh()
 local started=os.clock();local connection
 connection=Run.RenderStepped:Connect(function()
  if not gui.Enabled then connection:Disconnect();return end
  local t=math.clamp((os.clock()-started)/.4,0,1);local shift=t<.35 and -.42*t/.35 or t<.55 and (-.42+(t-.35)/.2*.53) or (.11-(t-.55)/.45*.53)
  aimUpdate(shift);if t>=1 then connection:Disconnect() end
 end)
 task.delay(.14,function() if gui.Enabled then remote:FireServer('pool_shoot',{angle=angle,power=power}) end end)
end
local function close()
 if cameraTween then cameraTween:Cancel();cameraTween=nil end
 if renderConnection then renderConnection:Disconnect();renderConnection=nil end
 if ballAddedConnection then ballAddedConnection:Disconnect();ballAddedConnection=nil end
 gui.Enabled=false;active=false;moving=false;player:SetAttribute('InterfaceOpen',false);setControls(true)
 for _,part in ipairs(cueParts) do if part.Parent then part:Destroy() end end;table.clear(cueParts)
 if aimPart then aimPart:Destroy();aimPart=nil end;if aimDot then aimDot:Destroy();aimDot=nil end
 camera=workspace.CurrentCamera
 if camera then camera.CameraType=savedCamera.type or Enum.CameraType.Custom;camera.CameraSubject=savedCamera.subject or (player.Character and player.Character:FindFirstChildOfClass('Humanoid'));camera.FieldOfView=savedCamera.fov or player:GetAttribute('PreferredFOV') or 70 end
 table.clear(savedCamera);surface=nil
end
local function open(data)
 local d=data or {};surface=d.surface;halfX=tonumber(d.halfX) or 4.5;halfZ=tonumber(d.halfZ) or 1.8
 if typeof(surface)~='Instance' or not surface:IsA('BasePart') then return end
 angle=0;power=.55;moving=false;active=true;count.Text=tostring(d.remaining or 15)..' BOLAS RESTANTES';message.Text=d.message or 'AJUSTE A DIREÇÃO E A FORÇA';refresh();gui.Enabled=true
 player:SetAttribute('InterfaceOpen',true);setControls(false);createVisuals()
 camera=workspace.CurrentCamera
 if camera then
  savedCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView};camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=52
  local goal=cameraGoal();if goal then cameraTween=Tween:Create(camera,TweenInfo.new(.62,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{CFrame=goal});cameraTween:Play() end
 end
 local gameFolder=workspace:WaitForChild('StillHerePoolGame',5);local ballFolder=gameFolder and gameFolder:FindFirstChild('Balls')
 local function markNumber(ball)
  if ball.Name=='CueBall' or ball:FindFirstChild('PoolNumberTag') then return end
  local tag=make('BillboardGui',ball,{Name='PoolNumberTag',Size=UDim2.fromOffset(20,20),StudsOffset=Vector3.new(0,.22,0),AlwaysOnTop=true,MaxDistance=38})
  local label=make('TextLabel',tag,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(246,240,222),Text=tostring(ball:GetAttribute('PoolNumber') or ''),Font=Enum.Font.RobotoCondensed,TextSize=11,TextColor3=Color3.fromRGB(22,22,20)})
  make('UICorner',label,{CornerRadius=UDim.new(1,0)})
 end
 if ballFolder then for _,ball in ipairs(ballFolder:GetChildren()) do markNumber(ball) end;ballAddedConnection=ballFolder.ChildAdded:Connect(markNumber) end
 renderConnection=Run.RenderStepped:Connect(function()
  local goal=cameraGoal();camera=workspace.CurrentCamera
  if goal and camera and camera.CameraType==Enum.CameraType.Scriptable then camera.CFrame=camera.CFrame:Lerp(goal,.075) end
  aimUpdate(0)
 end)
end
local function fit()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720);local compact=v.X<760 or v.Y>v.X
 panel.Size=compact and UDim2.new(.97,0,0,180) or UDim2.new(.54,0,0,180);panel.Position=UDim2.new(.5,0,1,compact and -8 or -16)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(fit) end;fit()
shoot.Activated:Connect(strike)
restart.Activated:Connect(function() if not moving then remote:FireServer('pool_restart') end end)
exit.Activated:Connect(function() remote:FireServer('pool_exit') end)
remote.OnClientEvent:Connect(function(action,data)
 if action=='pool_open' then open(data)
 elseif action=='pool_update' and gui.Enabled then
  local d=data or {};count.Text=tostring(d.remaining or 0)..' BOLAS RESTANTES';message.Text=d.message or '';moving=d.message=='TACADA EM ANDAMENTO';refresh()
 elseif action=='pool_close' then close()
 elseif action=='pool_busy' then message.Text='A MESA ESTÁ EM USO';gui.Enabled=true;task.delay(2,function() if not player:GetAttribute('InterfaceOpen') then gui.Enabled=false end end)
 elseif action=='pool_strike' or action=='pool_impact' then if impact.IsLoaded then impact:Play() else task.spawn(function() pcall(function() impact.Loaded:Wait();impact:Play() end) end) end end
end)
Input.InputBegan:Connect(function(i,processed)
 if not gui.Enabled or processed then return end
 if i.KeyCode==Enum.KeyCode.Left or i.KeyCode==Enum.KeyCode.A then rotateBy(-2)
 elseif i.KeyCode==Enum.KeyCode.Right or i.KeyCode==Enum.KeyCode.D then rotateBy(2)
 elseif i.KeyCode==Enum.KeyCode.Space then strike()
 elseif i.KeyCode==Enum.KeyCode.Escape then remote:FireServer('pool_exit') end
end)
