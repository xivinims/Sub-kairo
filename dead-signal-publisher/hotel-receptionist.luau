local Players=game:GetService('Players')
local ServerStorage=game:GetService('ServerStorage')

local Receptionist={}
local SHIRT=7978206628
local PANTS=6296971062
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

local function clearAppearance(model)
	for _,object in ipairs(model:GetDescendants()) do
		if object:IsA('Shirt') or object:IsA('Pants') or object:IsA('ShirtGraphic') or object:IsA('BodyColors') or object:IsA('Accessory') then
			object:Destroy()
		elseif object:IsA('BaseScript') or object:IsA('ProximityPrompt') or object:IsA('ClickDetector') then
			object:Destroy()
		end
	end
end

local function addOutfit(model,head)
	local shirt=Instance.new('Shirt')
	shirt.Name='ReceptionistShirt'
	shirt.ShirtTemplate='rbxassetid://'..SHIRT
	shirt.Parent=model
	local pants=Instance.new('Pants')
	pants.Name='ReceptionistPants'
	pants.PantsTemplate='rbxassetid://'..PANTS
	pants.Parent=model
	local colors=Instance.new('BodyColors')
	colors.HeadColor3=Color3.fromRGB(20,20,21)
	colors.TorsoColor3=Color3.fromRGB(214,225,221)
	colors.LeftArmColor3=Color3.fromRGB(214,225,221)
	colors.RightArmColor3=Color3.fromRGB(214,225,221)
	colors.LeftLegColor3=Color3.fromRGB(229,226,214)
	colors.RightLegColor3=Color3.fromRGB(229,226,214)
	colors.Parent=model
	if head then head.Color=Color3.fromRGB(20,20,21) end
end

local function addDiceHead(model,head)
	local sx,sy,sz=head.Size.X,head.Size.Y,head.Size.Z
	local pipSize=math.clamp(math.min(sx,sy)*.16,.11,.2)
	local faceZ=-(sz/2+.035)
	local front={{-.25,.22},{.25,.22},{0,0},{-.25,-.22},{.25,-.22}}
	for index,offset in ipairs(front) do
		local pip=addPart(model,'DicePipFront'..index,'Part',Vector3.new(pipSize,pipSize,pipSize*.48),Color3.fromRGB(240,238,225),Enum.Material.SmoothPlastic)
		pip.Shape=Enum.PartType.Ball
		weldTo(pip,head,CFrame.new(offset[1]*sx,offset[2]*sy,faceZ))
	end
	for index,y in ipairs({.27,0,-.27}) do
		local pip=addPart(model,'DicePipSide'..index,'Part',Vector3.new(pipSize*.48,pipSize,pipSize),Color3.fromRGB(240,238,225),Enum.Material.SmoothPlastic)
		pip.Shape=Enum.PartType.Ball
		weldTo(pip,head,CFrame.new(sx/2+.035,y*sy,0))
	end
	for index,side in ipairs({-1,1}) do
		local horn=addPart(model,'BlackHorn'..index,'WedgePart',Vector3.new(.34,.82,.34),Color3.fromRGB(17,17,18),Enum.Material.SmoothPlastic)
		weldTo(horn,head,CFrame.new(side*sx*.36,sy*.58,0)*CFrame.Angles(0,0,math.rad(side*-18)))
	end
	for index,offset in ipairs({Vector3.new(0,-.04,faceZ-.015),Vector3.new(.04,-.24,faceZ-.015)}) do
		local strip=addPart(model,'FaceBandage'..index,'Part',Vector3.new(sx*.46,.12,.04),Color3.fromRGB(212,208,196),Enum.Material.SmoothPlastic)
		weldTo(strip,head,CFrame.new(offset)*CFrame.Angles(0,0,math.rad(index==1 and 5 or -8)))
	end
end

local function setRigForDisplay(model,origin)
	local root=model:FindFirstChild('HumanoidRootPart',true) or model.PrimaryPart
	local humanoid=model:FindFirstChildOfClass('Humanoid')
	assert(root and root:IsA('BasePart') and humanoid,'Dynamic NPC sample rig must contain a HumanoidRootPart and Humanoid')
	model.PrimaryPart=root
	clearAppearance(model)
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
	local head=model:FindFirstChild('Head',true)
	assert(head and head:IsA('BasePart'),'Dynamic NPC sample rig is missing its head')
	addOutfit(model,head)
	addDiceHead(model,head)
	return root,humanoid
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
	return surface.Position-Vector3.new(0,3.25,0),surface.CFrame.LookVector*radiusZ
end

local function addNameplate(model,root)
	local badge=Instance.new('BillboardGui')
	badge.Name='ReceptionistNameplate'
	badge.Size=UDim2.fromOffset(190,34)
	badge.StudsOffset=Vector3.new(0,3.3,0)
	badge.AlwaysOnTop=true
	badge.MaxDistance=48
	badge.Parent=root
	local label=Instance.new('TextLabel')
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Text='RECEPCIONISTA'
	label.Font=Enum.Font.RobotoCondensed
	label.TextSize=14
	label.TextColor3=Color3.fromRGB(244,225,191)
	label.TextStrokeColor3=Color3.fromRGB(14,14,13)
	label.TextStrokeTransparency=.25
	label.Parent=badge
	local highlight=Instance.new('Highlight')
	highlight.Name='ReceptionistOutline'
	highlight.Adornee=model
	highlight.FillTransparency=1
	highlight.OutlineColor=Color3.fromRGB(194,164,117)
	highlight.OutlineTransparency=.48
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

local function startDynamicAnimations(model,humanoid)
	local animationFolder=ServerStorage:FindFirstChild('ReceptionistAnimations')
	assert(animationFolder,'Dynamic NPC animation pack was not assembled')
	local animator=humanoid:FindFirstChildOfClass('Animator')
	if not animator then animator=Instance.new('Animator');animator.Parent=humanoid end
	local tracks={}
	for _,animationName in ipairs({'Idle','IdleToActive','ActiveIdle','ActiveToIdle'}) do
		local animation=animationFolder:FindFirstChild(animationName)
		if animation and animation:IsA('Animation') and animation.AnimationId~='' then
			local ok,track=pcall(function() return animator:LoadAnimation(animation) end)
			if ok and track then
				track.Priority=(animationName=='Idle' or animationName=='ActiveIdle') and Enum.AnimationPriority.Idle or Enum.AnimationPriority.Action
				tracks[animationName]=track
			end
		end
	end
	assert(tracks.Idle,'Receptionist idle animation could not be loaded')
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
		local transition=active and tracks.IdleToActive or tracks.ActiveToIdle
		if transition then
			play(transition,false)
			task.wait(math.clamp(transition.Length,.2,1.8))
		end
		play(active and (tracks.ActiveIdle or tracks.Idle) or tracks.Idle,true)
	end
	task.spawn(function()
		local active=false
		play(tracks.Idle,true)
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
	local rigTemplate=assert(ServerStorage:FindFirstChild('ReceptionistRigTemplate'),'Dynamic NPC animation sample rig is missing')
	local model=rigTemplate:Clone()
	model.Name='HotelReceptionist'
	local root,humanoid=setRigForDisplay(model,targetFrame)
	model:SetAttribute('ReceptionistSpawnPosition',targetFrame.Position)
	model:SetAttribute('AnimationPackAssetId',86582491164528)
	model.Parent=folder
	addNameplate(model,root)
	model:SetAttribute('InteractionKind','Receptionist')
	model:SetAttribute('HotelActorKind','LobbyHost')
	model:SetAttribute('CreatorAvatarSource','RequestedOutfitReference')
	interactions.RegisterActor(model,'Receptionist')
	startDynamicAnimations(model,humanoid)
	return model
end

return Receptionist
