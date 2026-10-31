local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local GuiService=game:GetService('GuiService')

local player=Players.LocalPlayer
local remote=RS:WaitForChild('MysteryUIAction')
local active=false
local canShoot=false
local waiting=false
local aimAngle=0
local chargeStarted
local chargeInputType
local charge=0
local aimInput
local aimInputPosition=Vector2.zero
local savedCamera={}
local savedMovement={}
local cameraConnection
local camera
local surface
local shotCue
local cueTip
local aimBeam
local startAttachment
local endAttachment
local visualFolder
local lastStrike=0

local gui=Instance.new('ScreenGui')
gui.Name='PoolShotControls'
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=1810
gui.Enabled=false
gui.Parent=player:WaitForChild('PlayerGui')

local status=Instance.new('Frame')
status.Name='MatchStatus'
status.AnchorPoint=Vector2.new(0,0)
status.Position=UDim2.fromOffset(30,25)
status.Size=UDim2.fromOffset(280,64)
status.BackgroundColor3=Color3.fromRGB(11,15,14)
status.BackgroundTransparency=.16
status.BorderSizePixel=0
status.Parent=gui
Instance.new('UICorner',status).CornerRadius=UDim.new(0,5)
local statusStroke=Instance.new('UIStroke',status)
statusStroke.Color=Color3.fromRGB(182,151,99)
statusStroke.Transparency=.48
statusStroke.Thickness=1

local countText=Instance.new('TextLabel')
countText.Name='BallsRemaining'
countText.Position=UDim2.fromOffset(13,7)
countText.Size=UDim2.new(1,-26,0,17)
countText.BackgroundTransparency=1
countText.Font=Enum.Font.RobotoCondensed
countText.Text='BOLAS NA MESA  15'
countText.TextSize=13
countText.TextColor3=Color3.fromRGB(225,205,164)
countText.TextXAlignment=Enum.TextXAlignment.Left
countText.Parent=status

local messageText=Instance.new('TextLabel')
messageText.Name='TurnMessage'
messageText.Position=UDim2.fromOffset(13,27)
messageText.Size=UDim2.new(1,-26,0,25)
messageText.BackgroundTransparency=1
messageText.Font=Enum.Font.RobotoCondensed
messageText.Text='MIRE, SEGURE E SOLTE PARA TACAR'
messageText.TextSize=15
messageText.TextColor3=Color3.fromRGB(239,236,226)
messageText.TextWrapped=true
messageText.TextXAlignment=Enum.TextXAlignment.Left
messageText.Parent=status

local shotButton=Instance.new('TextButton')
shotButton.Name='CircularShotButton'
shotButton.AnchorPoint=Vector2.new(.5,.5)
shotButton.Position=UDim2.new(0,90,1,-224)
shotButton.Size=UDim2.fromOffset(112,112)
shotButton.BackgroundColor3=Color3.fromRGB(21,25,23)
shotButton.BackgroundTransparency=.03
shotButton.BorderSizePixel=0
shotButton.AutoButtonColor=false
shotButton.Text=''
shotButton.Selectable=true
shotButton.Parent=gui
Instance.new('UICorner',shotButton).CornerRadius=UDim.new(1,0)
local shotStroke=Instance.new('UIStroke',shotButton)
shotStroke.Color=Color3.fromRGB(195,164,106)
shotStroke.Thickness=2
shotStroke.Transparency=.1

local ring=Instance.new('Frame')
ring.Name='CircularPowerRing'
ring.AnchorPoint=Vector2.new(.5,.5)
ring.Position=UDim2.fromScale(.5,.5)
ring.Size=UDim2.fromOffset(102,102)
ring.BackgroundTransparency=1
ring.Parent=shotButton
local segments={}
for index=1,28 do
	local dot=Instance.new('Frame')
	dot.Name='PowerSegment'..index
	dot.AnchorPoint=Vector2.new(.5,.5)
	local angle=(index-1)/28*math.pi*2-math.pi/2
	dot.Position=UDim2.new(.5,math.cos(angle)*46,.5,math.sin(angle)*46)
	dot.Size=UDim2.fromOffset(5,5)
	dot.BackgroundColor3=Color3.fromRGB(74,78,72)
	dot.BorderSizePixel=0
	dot.Parent=ring
	Instance.new('UICorner',dot).CornerRadius=UDim.new(1,0)
	segments[index]=dot
end

local shotLabel=Instance.new('TextLabel')
shotLabel.Name='ShotLabel'
shotLabel.AnchorPoint=Vector2.new(.5,.5)
shotLabel.Position=UDim2.fromScale(.5,.5)
shotLabel.Size=UDim2.new(1,-26,0,42)
shotLabel.BackgroundTransparency=1
shotLabel.Font=Enum.Font.RobotoCondensed
shotLabel.Text='SEGURE\nPARA TACAR'
shotLabel.TextSize=14
shotLabel.TextColor3=Color3.fromRGB(239,235,225)
shotLabel.TextWrapped=true
shotLabel.Parent=shotButton

local hint=Instance.new('TextLabel')
hint.Name='AimHint'
hint.AnchorPoint=Vector2.new(.5,1)
hint.Position=UDim2.new(0,90,1,-284)
hint.Size=UDim2.fromOffset(220,20)
hint.BackgroundTransparency=1
hint.Font=Enum.Font.RobotoCondensed
hint.Text='ARRASTE PARA MIRAR  •  PULE PARA SAIR'
hint.TextSize=11
hint.TextColor3=Color3.fromRGB(219,213,199)
hint.TextStrokeTransparency=.6
hint.Parent=gui

local function setPower(value)
	charge=math.clamp(value,0,1)
	local lit=math.floor(charge*#segments+.5)
	for index,dot in ipairs(segments) do
		dot.BackgroundColor3=index<=lit and Color3.fromRGB(229,173,86) or Color3.fromRGB(74,78,72)
	end
	shotStroke.Color=charge>.72 and Color3.fromRGB(242,188,94) or Color3.fromRGB(195,164,106)
	if chargeStarted then
		shotLabel.Text=string.format('%d%%\nSOLTE',math.floor(charge*100))
	else
		shotLabel.Text=canShoot and 'SEGURE\nPARA TACAR' or (waiting and 'AGUARDE\nAMIGO' or 'AGUARDE\nSUA VEZ')
	end
end

local function positionInsideButton(position)
	local absolute=shotButton.AbsolutePosition
	local size=shotButton.AbsoluteSize
	local center=absolute+size/2
	local radius=math.min(size.X,size.Y)/2
	return (position-center).Magnitude<=radius+6
end

local function characterHumanoid()
	local character=player.Character
	return character and character:FindFirstChildOfClass('Humanoid')
end

local function cameraGoal()
	if not surface or not surface.Parent then return nil end
	local center=surface.Position+surface.CFrame.UpVector*(surface.Size.Y/2)
	local character=player.Character
	local root=character and character:FindFirstChild('HumanoidRootPart')
	local away=root and root.Position-center or -surface.CFrame.LookVector
	away=Vector3.new(away.X,0,away.Z)
	if away.Magnitude<.1 then away=-surface.CFrame.LookVector end
	away=away.Unit
	local position=center+away*5+Vector3.new(0,11,0)
	return CFrame.lookAt(position,center+Vector3.new(0,.15,0),Vector3.yAxis)
end

local function removeWorldVisuals()
	if visualFolder then visualFolder:Destroy();visualFolder=nil end
	shotCue=nil;cueTip=nil;aimBeam=nil;startAttachment=nil;endAttachment=nil
end

local function makeWorldVisuals()
	removeWorldVisuals()
	visualFolder=Instance.new('Folder')
	visualFolder.Name='LocalPoolPresentation'
	visualFolder.Parent=workspace
	local function makeAnchor(name)
		local part=Instance.new('Part')
		part.Name=name
		part.Size=Vector3.new(.05,.05,.05)
		part.Transparency=1
		part.Anchored=true
		part.CanCollide=false
		part.CanTouch=false
		part.CanQuery=false
		part.CastShadow=false
		part.Parent=visualFolder
		return part
	end
	local beamStart=makeAnchor('PoolAimOrigin')
	local beamEnd=makeAnchor('PoolAimTarget')
	startAttachment=Instance.new('Attachment');startAttachment.Parent=beamStart
	endAttachment=Instance.new('Attachment');endAttachment.Parent=beamEnd
	aimBeam=Instance.new('Beam')
	aimBeam.Name='HotelPoolAimBeam'
	aimBeam.Attachment0=startAttachment
	aimBeam.Attachment1=endAttachment
	aimBeam.Width0=.026
	aimBeam.Width1=.026
	aimBeam.FaceCamera=true
	aimBeam.LightEmission=.28
	aimBeam.Color=ColorSequence.new(Color3.fromRGB(238,202,130))
	aimBeam.Transparency=NumberSequence.new(.27)
	aimBeam.Parent=visualFolder
	local cue=Instance.new('Part')
	cue.Name='HotelPoolCue_Shaft'
	cue.Size=Vector3.new(.105,.105,3.6)
	cue.Color=Color3.fromRGB(142,90,49)
	cue.Material=Enum.Material.Wood
	cue.Anchored=true
	cue.CanCollide=false
	cue.CanTouch=false
	cue.CanQuery=false
	cue.CastShadow=false
	cue.Parent=visualFolder
	shotCue=cue
	local tip=Instance.new('Part')
	tip.Name='HotelPoolCue_Tip'
	tip.Size=Vector3.new(.115,.115,.15)
	tip.Color=Color3.fromRGB(187,206,191)
	tip.Material=Enum.Material.SmoothPlastic
	tip.Anchored=true
	tip.CanCollide=false
	tip.CanTouch=false
	tip.CanQuery=false
	tip.CastShadow=false
	tip.Parent=visualFolder
	cueTip=tip
end

local function aimDirection()
	if not surface then return Vector3.xAxis end
	local radians=math.rad(aimAngle)
	return (surface.CFrame.RightVector*math.cos(radians)+surface.CFrame.LookVector*math.sin(radians)).Unit
end

local function updateWorldPresentation()
	if not active then return end
	local goal=cameraGoal()
	camera=workspace.CurrentCamera
	if goal and camera and camera.CameraType==Enum.CameraType.Scriptable then
		camera.CFrame=camera.CFrame:Lerp(goal,.14)
		camera.Focus=CFrame.new(surface.Position)
	end
	if not visualFolder then return end
	local balls=workspace:FindFirstChild('StillHerePoolGame')
	balls=balls and balls:FindFirstChild('Balls')
	local cueBall=balls and balls:FindFirstChild('CueBall')
	if not cueBall or not cueBall:IsA('BasePart') then
		if shotCue then shotCue.Transparency=1;cueTip.Transparency=1;aimBeam.Enabled=false end
		return
	end
	local direction=aimDirection()
	local origin=cueBall.Position+surface.CFrame.UpVector*(cueBall.Size.Y/2+.055)
	local pulling=chargeStarted and charge or 0
	local center=origin-direction*(1.98+pulling*.58)
	local orientation=CFrame.lookAt(center,origin,surface.CFrame.UpVector)
	shotCue.Transparency=os.clock()-lastStrike<.28 and 1 or 0
	cueTip.Transparency=shotCue.Transparency
	shotCue.CFrame=orientation
	cueTip.CFrame=orientation*CFrame.new(0,0,-1.84)
	local endpoint=origin+direction*math.min((surface.Size.X+surface.Size.Z)*.76,11)
	startAttachment.Parent.CFrame=CFrame.new(origin)
	endAttachment.Parent.CFrame=CFrame.new(endpoint)
	aimBeam.Enabled=canShoot and not waiting and os.clock()-lastStrike>.28
end

local function restoreCamera()
	if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
	camera=workspace.CurrentCamera
	if camera then
		camera.CameraType=savedCamera.type or Enum.CameraType.Custom
		camera.CameraSubject=savedCamera.subject or characterHumanoid()
		camera.FieldOfView=savedCamera.fov or player:GetAttribute('PreferredFOV') or 70
	end
	if savedCamera.mode then player.CameraMode=savedCamera.mode end
	local humanoid=characterHumanoid()
	if humanoid then
		humanoid.WalkSpeed=savedMovement.walkSpeed or 16
		humanoid.AutoRotate=savedMovement.autoRotate~=false
	end
	table.clear(savedCamera);table.clear(savedMovement)
end

local function close()
	active=false
	chargeStarted=nil;chargeInputType=nil;aimInput=nil
	canShoot=false;waiting=false;surface=nil
	setPower(0)
	gui.Enabled=false
	restoreCamera()
	removeWorldVisuals()
end

local function open(data)
	if active then close() end
	data=data or {}
	surface=data.surface
	if not surface or not surface:IsA('BasePart') then return end
	active=true
	waiting=data.waiting==true
	canShoot=not waiting and data.mode~='friend'
	messageText.Text=data.message or 'MIRE, SEGURE E SOLTE PARA TACAR'
	countText.Text='BOLAS NA MESA  '..tostring(data.remaining or 15)
	gui.Enabled=true
	local humanoid=characterHumanoid()
	if humanoid then savedMovement={walkSpeed=humanoid.WalkSpeed,autoRotate=humanoid.AutoRotate};humanoid.WalkSpeed=0;humanoid.AutoRotate=false end
	camera=workspace.CurrentCamera
	if camera then
		savedCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,mode=player.CameraMode}
		camera.CameraType=Enum.CameraType.Scriptable
		camera.FieldOfView=48
	end
	makeWorldVisuals()
	setPower(0)
	cameraConnection=Run.RenderStepped:Connect(updateWorldPresentation)
end

local function startCharge(inputType)
	if not active or not canShoot or waiting or chargeStarted then return end
	chargeStarted=os.clock()
	chargeInputType=inputType
	setPower(0)
end

local function releaseCharge()
	if not chargeStarted then return end
	local power=math.clamp((os.clock()-chargeStarted)/1.45,.08,1)
	chargeStarted=nil;chargeInputType=nil
	setPower(0)
	if active and canShoot and not waiting then
		lastStrike=os.clock()
		remote:FireServer('pool_shoot',{angle=aimAngle,power=power})
		messageText.Text='TACADA EM ANDAMENTO'
	end
end

local function leave()
	if active then remote:FireServer('pool_exit') end
end

shotButton.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		startCharge(input.UserInputType)
	end
end)

Input.InputBegan:Connect(function(input,processed)
	if not active then return end
	if input.KeyCode==Enum.KeyCode.Left or input.KeyCode==Enum.KeyCode.A then
		if canShoot then aimAngle=math.clamp(aimAngle-2.2,-48,48) end
		return
	elseif input.KeyCode==Enum.KeyCode.Right or input.KeyCode==Enum.KeyCode.D then
		if canShoot then aimAngle=math.clamp(aimAngle+2.2,-48,48) end
		return
	end
	if processed or (Input:GetFocusedTextBox()) then return end
	if input.UserInputType==Enum.UserInputType.MouseMovement then return end
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		local position=Input:GetMouseLocation()
		local inset=GuiService:GetGuiInset()
		position-=Vector2.new(inset.X,inset.Y)
		if not positionInsideButton(position) then aimInput='mouse';aimInputPosition=position end
	elseif input.UserInputType==Enum.UserInputType.Touch then
		local position=input.Position
		local inset=GuiService:GetGuiInset()
		position-=Vector2.new(inset.X,inset.Y)
		if not positionInsideButton(position) then aimInput=input;aimInputPosition=position end
	end
end)

Input.InputChanged:Connect(function(input)
	if not active or not aimInput then return end
	local movement
	if aimInput=='mouse' and input.UserInputType==Enum.UserInputType.MouseMovement then
		local inset=GuiService:GetGuiInset()
		local position=input.Position-Vector3.new(inset.X,inset.Y,0)
		local current=Vector2.new(position.X,position.Y)
		movement=current-aimInputPosition
		 aimInputPosition=current
	elseif typeof(aimInput)=='InputObject' and input==aimInput then
		local inset=GuiService:GetGuiInset()
		local position=input.Position-Vector3.new(inset.X,inset.Y,0)
		local current=Vector2.new(position.X,position.Y)
		movement=current-aimInputPosition
		aimInputPosition=current
	end
	if movement and canShoot then aimAngle=math.clamp(aimAngle+movement.X*.115,-48,48) end
end)

Input.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 and chargeInputType==Enum.UserInputType.MouseButton1 then
		releaseCharge()
	elseif input.UserInputType==Enum.UserInputType.Touch and chargeInputType==Enum.UserInputType.Touch then
		releaseCharge()
	end
	if aimInput=='mouse' and input.UserInputType==Enum.UserInputType.MouseButton1 then aimInput=nil
	elseif aimInput==input then aimInput=nil end
end)

Input.JumpRequest:Connect(leave)

Run.RenderStepped:Connect(function()
	if not active then return end
	if chargeStarted then setPower((os.clock()-chargeStarted)/1.45) end
end)

remote.OnClientEvent:Connect(function(action,data)
	if action=='pool_open' then
		open(data)
	elseif action=='pool_close' then
		close()
	elseif action=='pool_update' and active and typeof(data)=='table' then
		if data.remaining~=nil then countText.Text='BOLAS NA MESA  '..tostring(data.remaining) end
		if data.message then messageText.Text=data.message end
		waiting=data.waiting==true
		canShoot=data.canShoot==true
		setPower(0)
	elseif action=='pool_strike' then
		lastStrike=os.clock()
	elseif action=='pool_impact' and active and typeof(data)=='table' then
		-- A mesa e as bolas permanecem físicas; este evento só atualiza a apresentação local.
	end
end)

player.CharacterAdded:Connect(function()
	if active then leave() end
end)
