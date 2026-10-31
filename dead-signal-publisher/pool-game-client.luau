local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local SoundService=game:GetService('SoundService')
local player=Players.LocalPlayer
local remote=RS:WaitForChild('MysteryUIAction')
local angle=0
local power=.35
local active=false
local moving=false
local surface
local halfX=4.5
local halfZ=1.8
local controls
local camera
local savedCamera={}
local cameraTween
local renderConnection
local cueParts={}
local aimPart
local aimDot
local aimBeam
local mouseHeld=false
local mouseStarted=0
local touchInput
local touchStarted=0
local shotStarted=0
local shotPower=.4
local impact=Instance.new('Sound')
impact.Name='PoolImpact'
impact.SoundId='rbxassetid://9120907256'
impact.Volume=.22
impact.Parent=SoundService

local function make(class,parent,props)
	local object=Instance.new(class)
	for name,value in pairs(props or {}) do object[name]=value end
	object.Parent=parent
	return object
end

local function setControls(enabled)
	if enabled then
		if controls then controls:Enable();controls=nil end
	else
		pcall(function()
			local module=require(player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'))
			controls=module:GetControls();controls:Disable()
		end)
	end
end

local function cueBall()
	local gameFolder=workspace:FindFirstChild('StillHerePoolGame')
	local folder=gameFolder and gameFolder:FindFirstChild('Balls')
	return folder and folder:FindFirstChild('CueBall')
end

local function align(position,axis)
	local up=axis.Unit
	local right=up:Cross(Vector3.yAxis)
	if right.Magnitude<.01 then right=up:Cross(Vector3.xAxis) end
	right=right.Unit
	return CFrame.fromMatrix(position,right,up,right:Cross(up).Unit)
end

local function clearCue()
	for _,part in ipairs(cueParts) do if part.Parent then part:Destroy() end end
	table.clear(cueParts)
	if aimPart then aimPart:Destroy();aimPart=nil end
	if aimDot then aimDot:Destroy();aimDot=nil end
end

local function createCue()
	clearCue()
	local pieces={
		{3.66,.050,Color3.fromRGB(117,75,43),-1.91},
		{.16,.059,Color3.fromRGB(225,214,190),-.075},
		{.075,.045,Color3.fromRGB(176,142,99),.04},
		{.20,.058,Color3.fromRGB(48,37,29),-3.80},
	}
	for index,piece in ipairs(pieces) do
		cueParts[index]=make('Part',workspace,{Name='HotelPoolCue_'..index,Shape=Enum.PartType.Cylinder,Size=Vector3.new(piece[2]*2,piece[1],piece[2]*2),Color=piece[3],Material=index==1 and Enum.Material.Wood or Enum.Material.SmoothPlastic,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false})
	end
	aimPart=make('Part',workspace,{Name='HotelPoolAimAnchor',Size=Vector3.new(.05,.05,.05),Transparency=1,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false})
	local start=make('Attachment',aimPart,{Name='AimStart'})
	local finish=make('Attachment',aimPart,{Name='AimEnd'})
	aimBeam=make('Beam',aimPart,{Name='HotelPoolAimBeam',Attachment0=start,Attachment1=finish,FaceCamera=true,Width0=.026,Width1=.009,LightEmission=.35,Color=ColorSequence.new(Color3.fromRGB(236,220,184)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(1,.62)})})
	aimDot=make('Part',workspace,{Name='HotelPoolAimPoint',Shape=Enum.PartType.Ball,Size=Vector3.new(.12,.12,.12),Material=Enum.Material.Neon,Color=Color3.fromRGB(236,218,176),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false})
end

local function shotOffset()
	if mouseHeld or touchInput then
		local started=mouseHeld and mouseStarted or touchStarted
		local charge=.35+math.clamp((os.clock()-started)/1.7,0,1)*.62
		return .47*charge
	end
	if shotStarted<=0 then return 0 end
	local t=(os.clock()-shotStarted)/.34
	if t>=1 then shotStarted=0;return 0 end
	if t<.38 then return .47*shotPower*(1-t/.38) end
	if t<.60 then return -.10*shotPower*((t-.38)/.22) end
	return -.10*shotPower*(1-(t-.60)/.40)
end

local function aimUpdate()
	if not surface then return end
	local cue=cueBall()
	if not cue then return end
	local radians=math.rad(angle)
	local direction=(surface.CFrame.RightVector*math.cos(radians)+surface.CFrame.LookVector*math.sin(radians)).Unit
	local up=surface.CFrame.UpVector
	local ballPosition=cue.Position+up*.03
	local offset=shotOffset()
	local centers={ballPosition-direction*(1.92+offset),ballPosition-direction*(.075+offset),ballPosition+direction*(.04+offset),ballPosition-direction*(3.8+offset)}
	for index,part in ipairs(cueParts) do part.CFrame=align(centers[index],direction) end
	local localDirection=surface.CFrame:VectorToObjectSpace(direction)
	local dx=math.abs(localDirection.X)>.001 and (halfX-.34)/math.abs(localDirection.X) or math.huge
	local dz=math.abs(localDirection.Z)>.001 and (halfZ-.34)/math.abs(localDirection.Z) or math.huge
	local endpoint=ballPosition+direction*math.max(.25,math.min(dx,dz))+up*.05
	if aimPart and aimBeam and aimDot then
		aimPart.CFrame=CFrame.new(ballPosition)
		local start=aimPart:FindFirstChild('AimStart')
		local finish=aimPart:FindFirstChild('AimEnd')
		if start and finish then finish.Position=aimPart.CFrame:PointToObjectSpace(endpoint) end
		aimDot.Position=endpoint
	end
end

local function cameraGoal()
	camera=workspace.CurrentCamera
	local character=player.Character
	local root=character and character:FindFirstChild('HumanoidRootPart')
	local cue=cueBall()
	if not camera or not root or not surface or not cue then return nil end
	local up=surface.CFrame.UpVector
	local away=root.Position-surface.Position
	away=Vector3.new(away.X,0,away.Z)
	if away.Magnitude<.1 then away=-surface.CFrame.LookVector end
	away=away.Unit
	local focus=surface.Position+up*.32
	local position=surface.Position+away*5.1+up*6.2
	return CFrame.lookAt(position,focus,Vector3.yAxis)
end

local function open(data)
	if active then return end
	local config=data or {}
	surface=config.surface
	halfX=tonumber(config.halfX) or 4.5
	halfZ=tonumber(config.halfZ) or 1.8
	if typeof(surface)~='Instance' or not surface:IsA('BasePart') then return end
	angle=0;power=.35;moving=false;active=true
	setControls(false)
	createCue()
	camera=workspace.CurrentCamera
	if camera then
		savedCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,mode=player.CameraMode}
		camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=58
		local goal=cameraGoal()
		if goal then cameraTween=TweenService:Create(camera,TweenInfo.new(.7,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{CFrame=goal});cameraTween:Play() end
	end
	renderConnection=Run.RenderStepped:Connect(function()
		local goal=cameraGoal()
		camera=workspace.CurrentCamera
		if goal and camera and camera.CameraType==Enum.CameraType.Scriptable then
			camera.CFrame=camera.CFrame:Lerp(goal,.065)
			local cue=cueBall()
			if cue then camera.Focus=CFrame.new(cue.Position) end
		end
		aimUpdate()
	end)
end

local function close()
	active=false;moving=false;mouseHeld=false;touchInput=nil
	if cameraTween then cameraTween:Cancel();cameraTween=nil end
	if renderConnection then renderConnection:Disconnect();renderConnection=nil end
	clearCue();setControls(true)
	camera=workspace.CurrentCamera
	if camera then
		camera.CameraType=savedCamera.type or Enum.CameraType.Custom
		camera.CameraSubject=savedCamera.subject or (player.Character and player.Character:FindFirstChildOfClass('Humanoid'))
		camera.FieldOfView=savedCamera.fov or player:GetAttribute('PreferredFOV') or 70
	end
	if savedCamera.mode then player.CameraMode=savedCamera.mode end
	table.clear(savedCamera);surface=nil
end

local function rotateBy(amount)
	if not moving then angle=math.clamp(angle+amount,-48,48) end
end

local function strike(heldSeconds)
	if not active or moving then return end
	local cue=cueBall()
	if not cue then return end
	moving=true
	power=math.clamp(.35+math.clamp(heldSeconds/1.7,0,1)*.62,.35,.97)
	shotPower=power;shotStarted=os.clock();aimUpdate()
	task.delay(.16,function()
		if active then remote:FireServer('pool_shoot',{angle=angle,power=power}) end
	end)
end

local function inputBegan(input,processed)
	if not active or processed then return end
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		mouseHeld=true;mouseStarted=os.clock()
	elseif input.UserInputType==Enum.UserInputType.Touch then
		touchInput=input;touchStarted=os.clock()
	elseif input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.Left then rotateBy(-2)
	elseif input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Right then rotateBy(2)
	elseif input.KeyCode==Enum.KeyCode.Space then mouseHeld=true;mouseStarted=os.clock()
	elseif input.KeyCode==Enum.KeyCode.Escape then remote:FireServer('pool_exit') end
end

local function inputChanged(input,processed)
	if not active or processed then return end
	if input.UserInputType==Enum.UserInputType.MouseMovement and mouseHeld then
		rotateBy(input.Delta.X*.15)
	elseif input.UserInputType==Enum.UserInputType.Touch and touchInput==input then
		rotateBy(input.Delta.X*.13)
	end
end

local function inputEnded(input)
	if not active then return end
	if input.UserInputType==Enum.UserInputType.MouseButton1 and mouseHeld then
		mouseHeld=false;strike(os.clock()-mouseStarted)
	elseif input.KeyCode==Enum.KeyCode.Space and mouseHeld then
		mouseHeld=false;strike(os.clock()-mouseStarted)
	elseif input.UserInputType==Enum.UserInputType.Touch and touchInput==input then
		touchInput=nil
		strike(os.clock()-touchStarted)
	end
end

Input.InputBegan:Connect(inputBegan)
Input.InputChanged:Connect(inputChanged)
Input.InputEnded:Connect(inputEnded)

remote.OnClientEvent:Connect(function(action,data)
	if action=='pool_open' then open(data)
	elseif action=='pool_close' then close()
	elseif action=='pool_update' then moving=data and data.message=='TACADA EM ANDAMENTO' or false
	elseif action=='pool_busy' then impact.PlaybackSpeed=.72;impact:Play()
	elseif action=='pool_strike' or action=='pool_impact' then
		if impact.IsLoaded then impact:Play() else task.spawn(function() pcall(function() impact.Loaded:Wait();impact:Play() end) end) end
	end
end)
