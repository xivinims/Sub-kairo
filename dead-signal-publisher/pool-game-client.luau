local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local UserInputService=game:GetService('UserInputService')
local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild('MysteryUIAction')
local playerGui=player:WaitForChild('PlayerGui')

local gui=Instance.new('ScreenGui')
gui.Name='PoolGameControls'
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=1800
gui.Enabled=false
gui.Parent=playerGui

local block=Instance.new('TextButton')
block.Name='InputBlocker'
block.Size=UDim2.fromScale(1,1)
block.Text=''
block.Modal=true
block.Active=true
block.BackgroundTransparency=1
block.AutoButtonColor=false
block.BorderSizePixel=0
block.Parent=gui

local panel=Instance.new('Frame')
panel.Name='PoolPanel'
panel.AnchorPoint=Vector2.new(.5,1)
panel.Position=UDim2.new(.5,0,1,-22)
panel.Size=UDim2.new(.60,0,0,196)
panel.BackgroundColor3=Color3.fromRGB(14,16,16)
panel.BackgroundTransparency=.08
panel.BorderSizePixel=0
panel.Parent=gui
Instance.new('UICorner',panel).CornerRadius=UDim.new(0,5)
local stroke=Instance.new('UIStroke',panel)
stroke.Color=Color3.fromRGB(170,163,150)
stroke.Transparency=.68
stroke.Thickness=1

local title=Instance.new('TextLabel')
title.Position=UDim2.new(0,18,0,12)
title.Size=UDim2.new(.50,-18,0,24)
title.BackgroundTransparency=1
title.Text='MESA DE SINUCA'
title.Font=Enum.Font.RobotoCondensed
title.TextSize=18
title.TextColor3=Color3.fromRGB(231,226,216)
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=panel

local stateLabel=Instance.new('TextLabel')
stateLabel.Position=UDim2.new(.50,0,0,13)
stateLabel.Size=UDim2.new(.50,-18,0,22)
stateLabel.BackgroundTransparency=1
stateLabel.Text='15 BOLAS RESTANTES'
stateLabel.Font=Enum.Font.RobotoCondensed
stateLabel.TextSize=12
stateLabel.TextColor3=Color3.fromRGB(185,181,174)
stateLabel.TextXAlignment=Enum.TextXAlignment.Right
stateLabel.Parent=panel

local message=Instance.new('TextLabel')
message.Position=UDim2.new(0,18,0,42)
message.Size=UDim2.new(1,-36,0,19)
message.BackgroundTransparency=1
message.Text='MIRE E AJUSTE A FORÇA DA TACADA'
message.Font=Enum.Font.RobotoCondensed
message.TextSize=11
message.TextColor3=Color3.fromRGB(151,153,148)
message.TextXAlignment=Enum.TextXAlignment.Left
message.Parent=panel

local angle=0
local power=.55
local moving=false
local onClose
local controls
local buttonColor=Color3.fromRGB(218,213,204)
local mutedColor=Color3.fromRGB(159,156,149)

local function makeButton(name,text,parent,position,size)
	local button=Instance.new('TextButton')
	button.Name=name
	button.Position=position
	button.Size=size
	button.BackgroundColor3=Color3.fromRGB(40,42,41)
	button.BackgroundTransparency=.15
	button.BorderSizePixel=0
	button.Text=text
	button.Font=Enum.Font.RobotoCondensed
	button.TextSize=13
	button.TextColor3=buttonColor
	button.AutoButtonColor=false
	button.Parent=parent
	Instance.new('UICorner',button).CornerRadius=UDim.new(0,3)
	button.MouseEnter:Connect(function() button.TextColor3=Color3.fromRGB(255,251,242) end)
	button.MouseLeave:Connect(function() button.TextColor3=buttonColor end)
	return button
end

local left=makeButton('AimLeft','◀',panel,UDim2.new(.08,0,0,73),UDim2.new(.11,0,0,34))
local angleText=Instance.new('TextLabel')
angleText.Position=UDim2.new(.20,0,0,73)
angleText.Size=UDim2.new(.19,0,0,34)
angleText.BackgroundTransparency=1
angleText.Text='ÂNGULO 0°'
angleText.Font=Enum.Font.RobotoCondensed
angleText.TextSize=12
angleText.TextColor3=buttonColor
angleText.Parent=panel
local right=makeButton('AimRight','▶',panel,UDim2.new(.39,0,0,73),UDim2.new(.11,0,0,34))

local powerLabel=Instance.new('TextLabel')
powerLabel.Position=UDim2.new(.53,0,0,73)
powerLabel.Size=UDim2.new(.20,0,0,34)
powerLabel.BackgroundTransparency=1
powerLabel.Text='FORÇA 55%'
powerLabel.Font=Enum.Font.RobotoCondensed
powerLabel.TextSize=11
powerLabel.TextColor3=mutedColor
powerLabel.TextXAlignment=Enum.TextXAlignment.Right
powerLabel.Parent=panel

local track=Instance.new('Frame')
track.Name='PowerTrack'
track.Position=UDim2.new(.76,0,0,88)
track.Size=UDim2.new(.17,0,0,2)
track.BackgroundColor3=Color3.fromRGB(106,104,98)
track.BorderSizePixel=0
track.Parent=panel
local fill=Instance.new('Frame')
fill.Name='PowerFill'
fill.Size=UDim2.fromScale(power,1)
fill.BackgroundColor3=buttonColor
fill.BorderSizePixel=0
fill.Parent=track
local knob=Instance.new('Frame')
knob.Name='PowerKnob'
knob.AnchorPoint=Vector2.new(.5,.5)
knob.Position=UDim2.fromScale(power,.5)
knob.Size=UDim2.fromOffset(13,13)
knob.BackgroundColor3=Color3.fromRGB(243,239,231)
knob.BorderSizePixel=0
knob.Parent=track
Instance.new('UICorner',knob).CornerRadius=UDim.new(1,0)
local sliderHit=Instance.new('TextButton')
sliderHit.Name='PowerInput'
sliderHit.Position=UDim2.new(.74,0,0,68)
sliderHit.Size=UDim2.new(.22,0,0,42)
sliderHit.BackgroundTransparency=1
sliderHit.Text=''
sliderHit.ZIndex=4
sliderHit.Parent=panel

local shoot=makeButton('Shoot','TACAR',panel,UDim2.new(.08,0,0,125),UDim2.new(.29,0,0,40))
shoot.BackgroundColor3=Color3.fromRGB(87,82,73)
local restart=makeButton('Restart','NOVA PARTIDA',panel,UDim2.new(.40,0,0,125),UDim2.new(.29,0,0,40))
local exit=makeButton('Exit','SAIR',panel,UDim2.new(.72,0,0,125),UDim2.new(.20,0,0,40))

local function refresh()
	angleText.Text='ÂNGULO '..tostring(angle)..'°'
	powerLabel.Text='FORÇA '..tostring(math.floor(power*100+.5))..'%'
	fill.Size=UDim2.fromScale(power,1)
	knob.Position=UDim2.fromScale(power,.5)
	shoot.Text=moving and 'AGUARDE' or 'TACAR'
	shoot.Active=not moving
	shoot.TextColor3=moving and mutedColor or buttonColor
	if moving then restart.TextColor3=mutedColor else restart.TextColor3=buttonColor end
end

local function setPowerFromX(x)
	if track.AbsoluteSize.X<=0 then return end
	power=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,.12,1)
	refresh()
end
local dragging=false
sliderHit.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		dragging=true;setPowerFromX(input.Position.X)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then setPowerFromX(input.Position.X) end
end)
UserInputService.InputEnded:Connect(function(input)
	if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then dragging=false end
end)

local function adjustAngle(amount)
	if moving then return end
	angle=math.clamp(angle+amount,-75,75)
	refresh()
end
local function shootNow()
	if moving or not gui.Enabled then return end
	moving=true;refresh();remote:FireServer('pool_shoot',{angle=angle,power=power})
end
left.Activated:Connect(function() adjustAngle(-5) end)
right.Activated:Connect(function() adjustAngle(5) end)
shoot.Activated:Connect(shootNow)
restart.Activated:Connect(function()
	if moving then return end
	remote:FireServer('pool_restart')
end)
exit.Activated:Connect(function() remote:FireServer('pool_exit') end)

local function setControlsEnabled(enabled)
	if enabled then
		if controls then controls:Enable();controls=nil end
	else
		pcall(function()
			local module=player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule')
			controls=require(module):GetControls();controls:Disable()
		end)
	end
end

local function close()
	gui.Enabled=false
	player:SetAttribute('InterfaceOpen',false)
	setControlsEnabled(true)
	moving=false
end

local function open(data)
	angle=0;power=.55;moving=false
	local state=data or {}
	stateLabel.Text=tostring(state.remaining or 15)..' BOLAS RESTANTES'
	message.Text=state.message or 'MIRE E AJUSTE A FORÇA DA TACADA'
	refresh();gui.Enabled=true
	player:SetAttribute('InterfaceOpen',true)
	setControlsEnabled(false)
end

remote.OnClientEvent:Connect(function(action,data)
	if action=='pool_open' then
		open(data)
	elseif action=='pool_update' and gui.Enabled then
		local state=data or {}
		local remaining=tonumber(state.remaining) or 0
		stateLabel.Text=tostring(remaining)..' BOLAS RESTANTES'
		message.Text=state.message or ''
		moving=state.message=='TACADA EM ANDAMENTO'
		refresh()
	elseif action=='pool_close' then
		close()
	elseif action=='pool_busy' then
		message.Text='A MESA ESTÁ EM USO'
		gui.Enabled=true
		task.delay(2,function() if not player:GetAttribute('InterfaceOpen') then gui.Enabled=false end end)
	end
end)

UserInputService.InputBegan:Connect(function(input,processed)
	if not gui.Enabled or processed then return end
	if input.KeyCode==Enum.KeyCode.Left then adjustAngle(-5)
	elseif input.KeyCode==Enum.KeyCode.Right then adjustAngle(5)
	elseif input.KeyCode==Enum.KeyCode.Space then shootNow()
	elseif input.KeyCode==Enum.KeyCode.Escape then remote:FireServer('pool_exit') end
end)

local function fit()
	local camera=workspace.CurrentCamera
	local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
	local mobile=viewport.X<760 or viewport.Y>viewport.X
	panel.Size=mobile and UDim2.new(.96,0,0,196) or UDim2.new(.60,0,0,196)
	panel.Position=UDim2.new(.5,0,1,mobile and -12 or -22)
	if mobile then
		left.Position=UDim2.new(.03,0,0,73);left.Size=UDim2.new(.13,0,0,34)
		angleText.Position=UDim2.new(.16,0,0,73);angleText.Size=UDim2.new(.22,0,0,34);angleText.TextSize=10
		right.Position=UDim2.new(.38,0,0,73);right.Size=UDim2.new(.13,0,0,34)
		powerLabel.Position=UDim2.new(.53,0,0,73);powerLabel.Size=UDim2.new(.20,0,0,34);powerLabel.TextSize=9
		track.Position=UDim2.new(.76,0,0,88);track.Size=UDim2.new(.19,0,0,2)
		sliderHit.Position=UDim2.new(.74,0,0,68);sliderHit.Size=UDim2.new(.23,0,0,42)
		shoot.Position=UDim2.new(.03,0,0,125);shoot.Size=UDim2.new(.29,0,0,40)
		restart.Position=UDim2.new(.355,0,0,125);restart.Size=UDim2.new(.39,0,0,40)
		exit.Position=UDim2.new(.78,0,0,125);exit.Size=UDim2.new(.19,0,0,40)
	else
		left.Position=UDim2.new(.08,0,0,73);left.Size=UDim2.new(.11,0,0,34)
		angleText.Position=UDim2.new(.20,0,0,73);angleText.Size=UDim2.new(.19,0,0,34);angleText.TextSize=12
		right.Position=UDim2.new(.39,0,0,73);right.Size=UDim2.new(.11,0,0,34)
		powerLabel.Position=UDim2.new(.53,0,0,73);powerLabel.Size=UDim2.new(.20,0,0,34);powerLabel.TextSize=11
		track.Position=UDim2.new(.76,0,0,88);track.Size=UDim2.new(.17,0,0,2)
		sliderHit.Position=UDim2.new(.74,0,0,68);sliderHit.Size=UDim2.new(.22,0,0,42)
		shoot.Position=UDim2.new(.08,0,0,125);shoot.Size=UDim2.new(.29,0,0,40)
		restart.Position=UDim2.new(.40,0,0,125);restart.Size=UDim2.new(.29,0,0,40)
		exit.Position=UDim2.new(.72,0,0,125);exit.Size=UDim2.new(.20,0,0,40)
	end
end

workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(fit)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(fit) end
fit()
refresh()
