local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local GuiService=game:GetService('GuiService')
local player=Players.LocalPlayer
local remote=RS:WaitForChild('MysteryUIAction')
local active=false
local camera
local savedCamera={}
local controls
local piano
local keyFolder
local keyboardAnchor
local renderConnection
local cameraTween
local keyTweens={}
local hotkeys={'A','W','S','E','D','F','T','G','Y','H','U','J','K'}
local noteByKey={}
for index,key in ipairs(hotkeys) do noteByKey[Enum.KeyCode[key]]=index-1 end

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

local function cameraGoal()
	camera=workspace.CurrentCamera
	local character=player.Character
	local root=character and character:FindFirstChild('HumanoidRootPart')
	if not camera or not root or not keyboardAnchor or not keyboardAnchor.Parent then return nil end
	local up=keyboardAnchor.CFrame.UpVector
	local away=root.Position-keyboardAnchor.Position
	away=Vector3.new(away.X,0,away.Z)
	if away.Magnitude<.1 then away=-root.CFrame.LookVector end
	away=away.Unit
	local focus=keyboardAnchor.Position+up*.3
	local position=root.Position+Vector3.new(0,1.9,0)+away*1.45
	return CFrame.lookAt(position,focus,Vector3.yAxis)
end

local function animateKey(index)
	if not piano then return end
	local key
	for _,part in ipairs(piano:GetDescendants()) do
		if part:IsA('BasePart') and part:GetAttribute('PianoNoteIndex')==index then key=part;break end
	end
	if not key and keyFolder then
		for _,part in ipairs(keyFolder:GetDescendants()) do
			if part:IsA('BasePart') and part:GetAttribute('PianoNoteIndex')==index then key=part;break end
		end
	end
	if not key or not key.Parent then return end
	local old=keyTweens[key]
	if old then old:Cancel() end
	local origin=key.CFrame
	local down=origin-key.CFrame.UpVector*.055
	local press=TweenService:Create(key,TweenInfo.new(.045,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=down})
	local release=TweenService:Create(key,TweenInfo.new(.11,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=origin})
	keyTweens[key]=press
	press.Completed:Once(function()
		if key.Parent then keyTweens[key]=release;release:Play() end
	end)
	press:Play()
end

local function screenRay(screenPosition)
	camera=workspace.CurrentCamera
	if not camera then return nil end
	local inset=GuiService:GetGuiInset()
	return camera:ViewportPointToRay(screenPosition.X-inset.X,screenPosition.Y-inset.Y)
end

local function tapWorld(screenPosition)
	if not active then return end
	local ray=screenRay(screenPosition)
	if not ray then return end
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={piano,keyFolder}
	params.IgnoreWater=true
	local hit=workspace:Raycast(ray.Origin,ray.Direction*120,params)
	local part=hit and hit.Instance
	if not part then return end
	local songId=part:GetAttribute('PianoSongId')
	if songId then
		remote:FireServer('piano_song',{id=songId})
		return
	end
	local note=part:GetAttribute('PianoNoteIndex')
	if note~=nil then
		animateKey(note)
		remote:FireServer('piano_note',{index=note})
	end
end

local function open(data)
	if active then return end
	data=data or {}
	piano=data.piano
	keyFolder=data.keyboard
	keyboardAnchor=data.surface
	if not piano or not keyFolder or not keyboardAnchor then return end
	active=true
	camera=workspace.CurrentCamera
	if camera then
		savedCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,mode=player.CameraMode}
		camera.CameraType=Enum.CameraType.Scriptable
		camera.FieldOfView=62
		local goal=cameraGoal()
		if goal then cameraTween=TweenService:Create(camera,TweenInfo.new(.62,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{CFrame=goal});cameraTween:Play() end
	end
	setControls(false)
	renderConnection=Run.RenderStepped:Connect(function()
		local goal=cameraGoal()
		camera=workspace.CurrentCamera
		if goal and camera and camera.CameraType==Enum.CameraType.Scriptable then
			camera.CFrame=camera.CFrame:Lerp(goal,.075)
			camera.Focus=CFrame.new(keyboardAnchor.Position)
		end
	end)
end

local function close()
	active=false
	if cameraTween then cameraTween:Cancel();cameraTween=nil end
	if renderConnection then renderConnection:Disconnect();renderConnection=nil end
	setControls(true)
	camera=workspace.CurrentCamera
	if camera then
		camera.CameraType=savedCamera.type or Enum.CameraType.Custom
		camera.CameraSubject=savedCamera.subject or (player.Character and player.Character:FindFirstChildOfClass('Humanoid'))
		camera.FieldOfView=savedCamera.fov or player:GetAttribute('PreferredFOV') or 70
	end
	if savedCamera.mode then player.CameraMode=savedCamera.mode end
	table.clear(savedCamera)
	piano=nil;keyFolder=nil;keyboardAnchor=nil
end

Input.InputBegan:Connect(function(input,processed)
	if not active or processed then return end
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		tapWorld(Input:GetMouseLocation())
	elseif input.UserInputType==Enum.UserInputType.Touch then
		tapWorld(input.Position)
	elseif input.KeyCode==Enum.KeyCode.Escape then
		remote:FireServer('piano_exit')
	else
		local note=noteByKey[input.KeyCode]
		if note~=nil then animateKey(note);remote:FireServer('piano_note',{index=note}) end
	end
end)

remote.OnClientEvent:Connect(function(action,data)
	if action=='piano_open' then open(data)
	elseif action=='piano_close' then close()
	elseif action=='piano_note_visual' and typeof(data)=='table' then animateKey(tonumber(data.index))
	end
end)
