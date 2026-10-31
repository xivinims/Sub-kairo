local Receptionist={}
local SHIRT=7978206628
local PANTS=6296971062

local function setPart(part,color,material)
	part.Color=color;part.Material=material or Enum.Material.SmoothPlastic
	part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=true
	part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth
	return part
end

local function positionAt(base,part,offset)
	part.CFrame=base.CFrame*offset
	return part
end

local function fallbackAvatar()
	local model=Instance.new('Model');model.Name='HotelReceptionist'
	local root=setPart(Instance.new('Part'),Color3.fromRGB(35,35,35));root.Name='HumanoidRootPart';root.Size=Vector3.new(2,2,1);root.Transparency=1;root.CFrame=CFrame.new();root.Anchored=true;root.Parent=model;model.PrimaryPart=root
	local shirtColor=Color3.fromRGB(214,225,221);local pantsColor=Color3.fromRGB(229,226,214);local skin=Color3.fromRGB(222,207,184)
	local torso=setPart(Instance.new('Part'),shirtColor);torso.Name='Torso';torso.Size=Vector3.new(2,2,1);torso.CFrame=CFrame.new();torso.Parent=model
	local head=setPart(Instance.new('Part'),Color3.fromRGB(20,20,21));head.Name='Head';head.Size=Vector3.new(2,1,1);head.CFrame=CFrame.new(0,1.5,0);head.Parent=model
	local rightArm=setPart(Instance.new('Part'),shirtColor);rightArm.Name='Right Arm';rightArm.Size=Vector3.new(1,2,1);rightArm.CFrame=CFrame.new(1.5,0,0);rightArm.Parent=model
	local leftArm=setPart(Instance.new('Part'),shirtColor);leftArm.Name='Left Arm';leftArm.Size=Vector3.new(1,2,1);leftArm.CFrame=CFrame.new(-1.5,0,0);leftArm.Parent=model
	local rightLeg=setPart(Instance.new('Part'),pantsColor);rightLeg.Name='Right Leg';rightLeg.Size=Vector3.new(1,2,1);rightLeg.CFrame=CFrame.new(.5,-2,0);rightLeg.Parent=model
	local leftLeg=setPart(Instance.new('Part'),pantsColor);leftLeg.Name='Left Leg';leftLeg.Size=Vector3.new(1,2,1);leftLeg.CFrame=CFrame.new(-.5,-2,0);leftLeg.Parent=model
	local shirt=Instance.new('Shirt');shirt.ShirtTemplate='rbxassetid://'..SHIRT;shirt.Parent=model
	local pants=Instance.new('Pants');pants.PantsTemplate='rbxassetid://'..PANTS;pants.Parent=model
	local colors=Instance.new('BodyColors');colors.HeadColor3=skin;colors.LeftArmColor3=shirtColor;colors.RightArmColor3=shirtColor;colors.TorsoColor3=shirtColor;colors.LeftLegColor3=pantsColor;colors.RightLegColor3=pantsColor;colors.Parent=model
	local pipOffsets={{-.48,.24},{.48,.24},{0,0},{-.48,-.24},{.48,-.24}}
	for index,offset in ipairs(pipOffsets) do
		local pip=setPart(Instance.new('Part'),Color3.fromRGB(240,238,225));pip.Name='DicePipFront'..index;pip.Shape=Enum.PartType.Ball;pip.Size=Vector3.new(.19,.19,.08);pip.Parent=model
		positionAt(head,pip,CFrame.new(offset[1],offset[2],-.54))
	end
	local sidePips={{0,.28},{.3,0},{0,-.28}}
	for index,offset in ipairs(sidePips) do
		local pip=setPart(Instance.new('Part'),Color3.fromRGB(240,238,225));pip.Name='DicePipSide'..index;pip.Shape=Enum.PartType.Ball;pip.Size=Vector3.new(.08,.19,.19);pip.Parent=model
		positionAt(head,pip,CFrame.new(1.04,offset[2],offset[1]))
	end
	for index,side in ipairs({-1,1}) do
		local horn=setPart(Instance.new('WedgePart'),Color3.fromRGB(17,17,18));horn.Name='BlackHorn'..index;horn.Size=Vector3.new(.34,.95,.34);horn.Parent=model
		positionAt(head,horn,CFrame.new(side*.58,.68,0)*CFrame.Angles(0,0,math.rad(side*-18)))
	end
	for index,offset in ipairs({Vector3.new(0,-.05,-.56),Vector3.new(.06,-.25,-.56)}) do
		local strip=setPart(Instance.new('Part'),Color3.fromRGB(212,208,196));strip.Name='FaceBandage'..index;strip.Size=Vector3.new(.9,.13,.045);strip.Parent=model
		positionAt(head,strip,CFrame.new(offset)*CFrame.Angles(0,0,math.rad(index==1 and 5 or -8)))
	end
	return model
end

local function createAvatar()
	-- A static authored rig avoids Roblox placing non-player Humanoids at its hidden preview origin.
	return fallbackAvatar()
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
	local badge=Instance.new('BillboardGui');badge.Name='ReceptionistNameplate';badge.Size=UDim2.fromOffset(190,34);badge.StudsOffset=Vector3.new(0,3.3,0);badge.AlwaysOnTop=true;badge.MaxDistance=48;badge.Parent=root
	local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text='RECEPCIONISTA';label.Font=Enum.Font.RobotoCondensed;label.TextSize=14;label.TextColor3=Color3.fromRGB(244,225,191);label.TextStrokeColor3=Color3.fromRGB(14,14,13);label.TextStrokeTransparency=.25;label.Parent=badge
	local highlight=Instance.new('Highlight');highlight.Name='ReceptionistOutline';highlight.Adornee=model;highlight.FillTransparency=1;highlight.OutlineColor=Color3.fromRGB(194,164,117);highlight.OutlineTransparency=.48;highlight.DepthMode=Enum.HighlightDepthMode.Occluded;highlight.Parent=model
	local lamp=Instance.new('PointLight');lamp.Name='ReceptionistWarmLight';lamp.Color=Color3.fromRGB(255,218,164);lamp.Brightness=.28;lamp.Range=8;lamp.Shadows=false;lamp.Parent=root
end

local function placeAt(model,root,target)
	local parts={}
	for _,object in ipairs(model:GetDescendants()) do
		if object:IsA('BasePart') then object.Anchored=true;table.insert(parts,object) end
	end
	local origin=root.CFrame
	local relative={}
	for _,part in ipairs(parts) do relative[part]=origin:ToObjectSpace(part.CFrame) end
	for _,part in ipairs(parts) do part.CFrame=target*relative[part] end
	model:PivotTo(target)
	root.Position=target.Position
	root.CFrame=target
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
	local folder=oldFolder or Instance.new('Folder');folder.Name='HotelActors';folder.Parent=workspace
	local model=createAvatar();model.Parent=folder
	local floor=findFloor(tableModel,surface,folder)
	local position=floor+Vector3.new(0,3.15,0)
	local target=Vector3.new(surface.Position.X,position.Y,surface.Position.Z)
	local root=model.PrimaryPart or model:FindFirstChild('HumanoidRootPart')
	assert(root,'Receptionist fallback avatar is missing its root')
	local targetFrame=CFrame.lookAt(position,target,Vector3.yAxis)
	placeAt(model,root,targetFrame)
	assert((root.Position-targetFrame.Position).Magnitude<.1,'Could not place receptionist beside the pool: '..tostring(root.Position)..' target '..tostring(targetFrame.Position)..' class='..root.ClassName..' anchored='..tostring(root.Anchored)..' parts='..tostring(#model:GetDescendants()))
	addNameplate(model,root)
	model:SetAttribute('InteractionKind','Receptionist')
	model:SetAttribute('HotelActorKind','LobbyHost')
	model:SetAttribute('CreatorAvatarSource','RequestedOutfitReference')
	interactions.RegisterActor(model,'Receptionist')
	return model
end

return Receptionist
