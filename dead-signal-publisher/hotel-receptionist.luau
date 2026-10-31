local Players=game:GetService('Players')
local ServerStorage=game:GetService('ServerStorage')
local TweenService=game:GetService('TweenService')

local Receptionist={}
local SHIRT=7978206628
local PANTS=6296971062
local HEADLESS_HEAD=134082579
local KORBLOX_RIGHT_LEG=139607718
local INTEREST_DISTANCE=20

local function addPart(model,name,class,size,color,material)
	local part=Instance.new(class or 'Part')
	part.Name=name
	part.Size=size
	part.Color=color
	part.Material=material or Enum.Material.SmoothPlastic
	part.Anchored=false
	part.CanCollide=false
	part.CanTouch=false
	part.CanQuery=false
	part.Massless=true
	part.TopSurface=Enum.SurfaceType.Smooth
	part.BottomSurface=Enum.SurfaceType.Smooth
	part.Parent=model
	return part
end

local function weldTo(part,base,offset)
	part.CFrame=base.CFrame*offset
	local weld=Instance.new('WeldConstraint')
	weld.Name='ReceptionistAccessoryWeld'
	weld.Part0=base
	weld.Part1=part
	weld.Parent=part
	return part
end

local function createR6Description()
	local description=Instance.new('HumanoidDescription')
	description.Head=HEADLESS_HEAD
	description.RightLeg=KORBLOX_RIGHT_LEG
	description.Shirt=SHIRT
	description.Pants=PANTS
	description.HeadColor=Color3.fromRGB(20,20,21)
	description.TorsoColor=Color3.fromRGB(214,225,221)
	description.LeftArmColor=Color3.fromRGB(214,225,221)
	description.RightArmColor=Color3.fromRGB(214,225,221)
	description.LeftLegColor=Color3.fromRGB(229,226,214)
	description.RightLegColor=Color3.fromRGB(229,226,214)
	return description
end

local function createR6Rig()
	local description=createR6Description()
	local ok,model=pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(
			description,
			Enum.HumanoidRigType.R6,
			Enum.AssetTypeVerification.Default
		)
	end)
	if not ok or not model then
		local template=ServerStorage:FindFirstChild('ReceptionistRigTemplate')
		local templateHumanoid=template and template:FindFirstChildOfClass('Humanoid')
		if template and templateHumanoid and templateHumanoid.RigType==Enum.HumanoidRigType.R6 then
			model=template:Clone()
			local humanoid=model:FindFirstChildOfClass('Humanoid')
			local applied=pcall(function() humanoid:ApplyDescriptionResetAsync(description) end)
			if not applied then model:Destroy();description:Destroy();error('Roblox could not apply the R6 Headless/Korblox appearance') end
		else
			description:Destroy()
			error('Roblox could not create the requested R6 Headless/Korblox receptionist')
		end
	end
	description:Destroy()
	local humanoid=assert(model:FindFirstChildOfClass('Humanoid'),'Created receptionist has no Humanoid')
	assert(humanoid.RigType==Enum.HumanoidRigType.R6,'Created receptionist is not R6')
	return model,humanoid
end

local function setRigForDisplay(model,humanoid,origin)
	local root=model:FindFirstChild('HumanoidRootPart',true)
	assert(root and root:IsA('BasePart'),'R6 receptionist is missing HumanoidRootPart')
	model.PrimaryPart=root
	for _,object in ipairs(model:GetDescendants()) do
		if object:IsA('BasePart') then
			object.Anchored=false
			object.CanCollide=false
			object.CanTouch=false
			object.CanQuery=true
			object.CastShadow=true
		end
	end
	model:PivotTo(origin)
	root.Anchored=true
	humanoid.WalkSpeed=0
	humanoid.AutoRotate=false
	humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	local animator=humanoid:FindFirstChildOfClass('Animator')
	if not animator then animator=Instance.new('Animator');animator.Parent=humanoid end
	return root
end

local function addCuteAccessories(model,torso)
	for index,side in ipairs({-1,1}) do
		local bow=addPart(model,'ReceptionistBowTie'..index,'WedgePart',Vector3.new(.22,.19,.10),Color3.fromRGB(229,147,161),Enum.Material.SmoothPlastic)
		weldTo(bow,torso,CFrame.new(side*.105,.50,-.57)*CFrame.Angles(0,math.rad(side*-8),math.rad(side*-10)))
	end
	local knot=addPart(model,'ReceptionistBowKnot','Part',Vector3.new(.11,.12,.10),Color3.fromRGB(255,219,177),Enum.Material.SmoothPlastic)
	weldTo(knot,torso,CFrame.new(0,.50,-.62))
	local pin=addPart(model,'ReceptionistHeartPin','Part',Vector3.new(.13,.13,.08),Color3.fromRGB(233,127,154),Enum.Material.SmoothPlastic)
	pin.Shape=Enum.PartType.Ball
	weldTo(pin,torso,CFrame.new(.48,.22,-.54))
end

local function findFloor(tableModel,surface,folder)
	local radiusX=math.min(surface.Size.X/2+1.4,6.4)
	local radiusZ=math.min(surface.Size.Z/2+1.4,4.6)
	local offsets={
		surface.CFrame.LookVector*radiusZ,
		-surface.CFrame.LookVector*radiusZ,
		surface.CFrame.RightVector*radiusX,
		-surface.CFrame.RightVector*radiusX,
	}
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	local excluded={tableModel,folder}
	for _,name in ipairs({'StillHerePoolGame','HotelPianoRuntime'}) do
		local object=workspace:FindFirstChild(name)
		if object then table.insert(excluded,object) end
	end
	params.FilterDescendantsInstances=excluded
	params.RespectCanCollide=true
	local best
	local expected=3.15
	for index,offset in ipairs(offsets) do
		local point=surface.Position+offset
		local hit=workspace:Raycast(point+Vector3.new(0,25,0),Vector3.new(0,-65,0),params)
		if hit then
			local drop=surface.Position.Y-hit.Position.Y
			if drop>1.25 and drop<8 then
				local score=math.abs(drop-expected)+index*.002
				if not best or score<best.score then best={position=hit.Position,offset=offset,score=score} end
			end
		end
	end
	if best then return best.position,best.offset end
	local fallbackOffset=surface.CFrame.LookVector*radiusZ
	return surface.Position-Vector3.new(0,3.15,0)+fallbackOffset,fallbackOffset
end

local function addVisualAccents(model,root)
	local highlight=Instance.new('Highlight')
	highlight.Name='ReceptionistOutline'
	highlight.Adornee=model
	highlight.FillTransparency=1
	highlight.OutlineColor=Color3.fromRGB(235,193,168)
	highlight.OutlineTransparency=.6
	highlight.DepthMode=Enum.HighlightDepthMode.Occluded
	highlight.Parent=model
	local lamp=Instance.new('PointLight')
	lamp.Name='ReceptionistWarmLight'
	lamp.Color=Color3.fromRGB(255,218,164)
	lamp.Brightness=.28
	lamp.Range=8
	lamp.Shadows=false
	lamp.Parent=root
end

local function createDoodleEffects(root)
	local billboard=Instance.new('BillboardGui')
	billboard.Name='ReceptionistDoodleReactions'
	billboard.Adornee=root
	billboard.Size=UDim2.fromOffset(126,98)
	billboard.StudsOffset=Vector3.new(0,3.25,0)
	billboard.AlwaysOnTop=false
	billboard.MaxDistance=40
	billboard.LightInfluence=0
	billboard.Enabled=false
	billboard.Parent=root
	local canvas=Instance.new('Frame')
	canvas.Name='DoodleCanvas'
	canvas.Size=UDim2.fromScale(1,1)
	canvas.BackgroundTransparency=1
	canvas.Parent=billboard
	local burst=Instance.new('Frame')
	burst.Name='HalftoneSurprise'
	burst.Size=UDim2.fromScale(1,1)
	burst.BackgroundTransparency=1
	burst.Visible=false
	burst.Parent=canvas
	local burstScale=Instance.new('UIScale')
	burstScale.Scale=.35
	burstScale.Parent=burst
	local center=Vector2.new(63,82)
	for _,degrees in ipairs({-143,-90,-37}) do
		local angle=math.rad(degrees)
		local direction=Vector2.new(math.cos(angle),math.sin(angle))
		local perpendicular=Vector2.new(-direction.Y,direction.X)
		for step=1,6 do
			local lanes=math.floor((step+1)/2)
			for lane=-lanes,lanes do
				local point=center+direction*(step*6)+perpendicular*(lane*3.3)
				local dot=Instance.new('Frame')
				dot.Name='BurstDot'
				dot.AnchorPoint=Vector2.new(.5,.5)
				dot.Position=UDim2.fromOffset(point.X,point.Y)
				local dotSize=math.max(1.5,3.5-step*.22)
				dot.Size=UDim2.fromOffset(dotSize,dotSize)
				dot.BackgroundColor3=(step+lane)%2==0 and Color3.fromRGB(255,236,204) or Color3.fromRGB(251,189,190)
				dot.BorderSizePixel=0
				dot.Parent=burst
				Instance.new('UICorner',dot).CornerRadius=UDim.new(1,0)
			end
		end
	end
	local spiral=Instance.new('Frame')
	spiral.Name='DizzySpiral'
	spiral.AnchorPoint=Vector2.new(.5,.5)
	spiral.Position=UDim2.fromOffset(63,48)
	spiral.Size=UDim2.fromOffset(60,60)
	spiral.BackgroundTransparency=1
	spiral.Visible=false
	spiral.Parent=canvas
	local spiralScale=Instance.new('UIScale')
	spiralScale.Scale=.55
	spiralScale.Parent=spiral
	for step=1,34 do
		local t=step/34*math.pi*4.4
		local radius=2+step*.62
		local dot=Instance.new('Frame')
		dot.Name='SpiralDot'
		dot.AnchorPoint=Vector2.new(.5,.5)
		dot.Position=UDim2.new(.5,math.cos(t)*radius,.5,math.sin(t)*radius)
		dot.Size=UDim2.fromOffset(math.clamp(4.6-step*.065,2.2,4.6),math.clamp(4.6-step*.065,2.2,4.6))
		dot.BackgroundColor3=step%3==0 and Color3.fromRGB(255,221,190) or Color3.fromRGB(210,194,242)
		dot.BorderSizePixel=0
		dot.Parent=spiral
		Instance.new('UICorner',dot).CornerRadius=UDim.new(1,0)
	end
	return billboard,burst,burstScale,spiral,spiralScale
end

local function startCuteReactions(model,root)
	local billboard,burst,burstScale,spiral,spiralScale=createDoodleEffects(root)
	local token=0
	local activeTweens={}
	local function stopTweens()
		for _,tween in ipairs(activeTweens) do tween:Cancel() end
		table.clear(activeTweens)
	end
	local function runReaction(kind)
		token+=1
		local current=token
		stopTweens()
		billboard.Enabled=true
		burst.Visible=kind=='Burst'
		spiral.Visible=kind=='Spiral'
		burstScale.Scale=.36
		spiralScale.Scale=.52
		spiral.Rotation=0
		if kind=='Spiral' then
			local grow=TweenService:Create(spiralScale,TweenInfo.new(.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1})
			local spin=TweenService:Create(spiral,TweenInfo.new(1.25,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1,false),{Rotation=360})
			table.insert(activeTweens,grow);table.insert(activeTweens,spin);grow:Play();spin:Play()
			task.delay(2.1,function()
				if token==current and billboard.Parent then
					stopTweens();spiral.Visible=false;billboard.Enabled=false
				end
			end)
		else
			local pop=TweenService:Create(burstScale,TweenInfo.new(.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1})
			table.insert(activeTweens,pop);pop:Play()
			task.delay(1.15,function()
				if token==current and billboard.Parent then burst.Visible=false;billboard.Enabled=false end
			end)
		end
	end
	model:GetAttributeChangedSignal('CuteReactionAt'):Connect(function()
		local reaction=model:GetAttribute('CuteReaction')
		if reaction=='Spiral' then runReaction('Spiral')
		elseif reaction=='Burst' then runReaction('Burst') end
	end)
	model:SetAttribute('CuteReaction','Burst')
	model:SetAttribute('CuteReactionAt',os.clock())
	return function(kind) runReaction(kind or 'Burst') end
end

local function startDynamicAnimations(model,humanoid,playCuteReaction)
	local animationFolder=ServerStorage:FindFirstChild('ReceptionistAnimations')
	assert(animationFolder,'Dynamic NPC animation pack was not assembled')
	local animator=humanoid:FindFirstChildOfClass('Animator')
	if not animator then animator=Instance.new('Animator');animator.Parent=humanoid end
	local tracks={}
	local animationRigType=workspace:GetAttribute('NPCAnimationRigType')
	if animationRigType==humanoid.RigType.Name then
		for _,animationName in ipairs({'Idle','IdleToActive','ActiveIdle','ActiveToIdle'}) do
			local animation=animationFolder:FindFirstChild(animationName)
			if animation and animation:IsA('Animation') then
				local ok,animationId=pcall(function() return animation.AnimationId end)
				if not ok or animationId~='' then
					local loaded,track=pcall(function() return animator:LoadAnimation(animation) end)
					if loaded and track then
						track.Priority=(animationName=='Idle' or animationName=='ActiveIdle') and Enum.AnimationPriority.Idle or Enum.AnimationPriority.Action
						tracks[animationName]=track
					end
				end
			end
		end
	end
	model:SetAttribute('ReceptionistAnimationRigType',animationRigType or 'Unknown')
	model:SetAttribute('ReceptionistAnimationMode',tracks.Idle and 'AnimationPack' or 'R6Fallback')
	local current
	local function play(track,looped)
		if not track then return end
		if current==track then
			track.Looped=looped
			if not track.IsPlaying then track:Play(.2,1,1) end
			return
		end
		local previous=current
		track.Looped=looped
		track:Play(.2,1,1)
		current=track
		if previous then previous:Stop(.2) end
	end
	local function isPlayerNear()
		local root=model.PrimaryPart
		if not root then return false end
		for _,player in ipairs(Players:GetPlayers()) do
			local character=player.Character
			local playerRoot=character and character:FindFirstChild('HumanoidRootPart')
			local playerHumanoid=character and character:FindFirstChildOfClass('Humanoid')
			if playerRoot and playerHumanoid and playerHumanoid.Health>0 and (playerRoot.Position-root.Position).Magnitude<=INTEREST_DISTANCE then return true end
		end
		return false
	end
	local function playState(active)
		if active and playCuteReaction then playCuteReaction('Burst') end
		local transition=active and tracks.IdleToActive or tracks.ActiveToIdle
		if transition then
			play(transition,false)
			task.wait(math.clamp(transition.Length,.2,1.8))
		end
		play(active and (tracks.ActiveIdle or tracks.Idle) or tracks.Idle,true)
	end
	task.spawn(function()
		local active=false
		if tracks.Idle then
			play(tracks.Idle,true)
		else
			local root=model.PrimaryPart
			if root then
				local idle=TweenService:Create(root,TweenInfo.new(1.25,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{CFrame=root.CFrame+Vector3.new(0,.10,0)})
				idle:Play()
			end
		end
		while model.Parent do
			local nextActive=isPlayerNear()
			if nextActive~=active then
				active=nextActive
				playState(active)
			end
			task.wait(.35)
		end
		for _,track in pairs(tracks) do track:Stop(.15) end
	end)
end

function Receptionist.Initialize(map,interactions)
	local oldFolder=workspace:FindFirstChild('HotelActors')
	if oldFolder and oldFolder:FindFirstChild('HotelReceptionist') then return oldFolder.HotelReceptionist end
	local tableModel=assert(map:FindFirstChild('PoolTable1',true),'Pool table is missing')
	local surface
	for _,part in ipairs(tableModel:GetDescendants()) do
		if part:IsA('BasePart') and part.Size.X>10 and part.Size.Z>5 and part.Size.Y<.01 then surface=part;break end
	end
	assert(surface,'Pool felt surface missing')
	local folder=oldFolder or Instance.new('Folder')
	folder.Name='HotelActors'
	folder.Parent=workspace
	local floor=findFloor(tableModel,surface,folder)
	local position=floor+Vector3.new(0,3.15,0)
	local target=Vector3.new(surface.Position.X,position.Y,surface.Position.Z)
	local targetFrame=CFrame.lookAt(position,target,Vector3.yAxis)
	local model,humanoid=createR6Rig()
	model.Name='HotelReceptionist'
	local root=setRigForDisplay(model,humanoid,targetFrame)
	model:SetAttribute('ReceptionistSpawnPosition',targetFrame.Position)
	model:SetAttribute('AnimationPackAssetId',86582491164528)
	model:SetAttribute('AppearanceHeadAssetId',HEADLESS_HEAD)
	model:SetAttribute('AppearanceKorbloxRightLegAssetId',KORBLOX_RIGHT_LEG)
	model:SetAttribute('ReceptionistSpawnVerified',false)
	model.Parent=folder
	model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
	local torso=assert(model:FindFirstChild('Torso',true),'R6 receptionist is missing Torso')
	addCuteAccessories(model,torso)
	addVisualAccents(model,root)
	local playCuteReaction=startCuteReactions(model,root)
	model:SetAttribute('InteractionKind','Receptionist')
	model:SetAttribute('HotelActorKind','LobbyHost')
	model:SetAttribute('CreatorAvatarSource','HeadlessKorbloxR6')
	model:SetAttribute('ReceptionistReady',true)
	interactions.RegisterActor(model,'Receptionist')
	startDynamicAnimations(model,humanoid,playCuteReaction)
	model:SetAttribute('ReceptionistSpawnVerified',(root.Position-targetFrame.Position).Magnitude<.25)
	workspace:SetAttribute('ReceptionistReady',true)
	return model
end

return Receptionist
