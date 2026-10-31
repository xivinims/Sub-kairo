-- Roblox-side, low-part-count adaptation of the Blender-authored hotel cart.
-- Static ambience only: it adds no prompts, collision, or gameplay rules.
local Decor={}

local BRASS=Color3.fromRGB(166,111,46)
local BRASS_LIGHT=Color3.fromRGB(218,166,88)
local WALNUT=Color3.fromRGB(91,49,29)
local WALNUT_EDGE=Color3.fromRGB(133,75,42)
local LEATHER=Color3.fromRGB(102,39,30)
local LEATHER_TRIM=Color3.fromRGB(167,83,52)
local TAG=Color3.fromRGB(224,204,157)
local RUBBER=Color3.fromRGB(35,31,29)

local function part(model,name,size,color,material,localFrame,shape)
	local item=Instance.new('Part')
	item.Name=name
	item.Size=size
	item.Color=color
	item.Material=material or Enum.Material.SmoothPlastic
	item.Shape=shape or Enum.PartType.Block
	item.Anchored=true
	item.CanCollide=false
	item.CanTouch=false
	item.CanQuery=false
	item.CastShadow=true
	item.TopSurface=Enum.SurfaceType.Smooth
	item.BottomSurface=Enum.SurfaceType.Smooth
	item.CFrame=localFrame
	item.Parent=model
	return item
end

local function beam(model,name,a,b,width,color,material,frame)
	local midpoint=(a+b)*.5
	local direction=b-a
	local unit=direction.Unit
	local reference=math.abs(unit:Dot(Vector3.yAxis))>.98 and Vector3.zAxis or Vector3.yAxis
	local back=unit:Cross(reference).Unit
	local up=back:Cross(unit).Unit
	local item=part(model,name,Vector3.new(direction.Magnitude,width,width),color,material,
		frame*CFrame.fromMatrix(midpoint,unit,up,back),Enum.PartType.Cylinder)
	return item
end

function Decor.Initialize(receptionist)
	if not receptionist or not receptionist.Parent then return nil end
	local parent=receptionist.Parent
	local existing=parent:FindFirstChild('HotelBellhopCart')
	if existing then return existing end
	local root=receptionist:FindFirstChild('HumanoidRootPart')	
	if not root then return nil end

	local model=Instance.new('Model')
	model.Name='HotelBellhopCart'
	model:SetAttribute('BlenderDesignedProp','1940s Bellhop Luggage Cart')
	model:SetAttribute('StaticLobbyDecoration',true)

	local forward=root.CFrame.LookVector
	local right=root.CFrame.RightVector
	local floorY=root.Position.Y-3.15
	local origin=Vector3.new(root.Position.X, floorY, root.Position.Z)-forward*4.8+right*2.7
	local target=origin+Vector3.new(forward.X,0,forward.Z)
	if (target-origin).Magnitude<.01 then target=origin+Vector3.new(0,0,-1) end
	local frame=CFrame.lookAt(origin,target,Vector3.yAxis)
	local function at(x,y,z,rx,ry,rz)
		return frame*CFrame.new(x,y,z)*CFrame.Angles(rx or 0,ry or 0,rz or 0)
	end
	local function block(name,x,y,z,sx,sy,sz,color,mat,rx,ry,rz)
		return part(model,name,Vector3.new(sx,sy,sz),color,mat,at(x,y,z,rx,ry,rz))
	end
	local function rod(name,a,b,width,color,mat)
		local localA=Vector3.new(a[1],a[2],a[3])
		local localB=Vector3.new(b[1],b[2],b[3])
		return beam(model,name,localA,localB,width,color,mat,frame)
	end

	-- Walnut deck with thin polished brass rails.
	block('Walnut luggage deck',0,.82,0,1.62,.18,1.04,WALNUT,Enum.Material.Wood,.015)
	block('Brass deck edge',0,.82,-.515,1.42,.075,.035,BRASS_LIGHT,Enum.Material.Metal)
	block('Brass rear deck edge',0,.82,.515,1.42,.075,.035,BRASS_LIGHT,Enum.Material.Metal)

	-- Four uprights and tiered finials.
	for _,x in ipairs({-.66,.66}) do
		for _,z in ipairs({-.40,.40}) do
			rod('Aged brass upright',{x,.90,z},{x,3.36,z},.075,BRASS,Enum.Material.Metal)
			block('Foot collar',x,1.00,z,.14,.10,.14,BRASS_LIGHT,Enum.Material.Metal)
			block('Top collar',x,3.18,z,.12,.11,.12,BRASS_LIGHT,Enum.Material.Metal)
			block('Stepped finial',x,3.38,z,.105,.12,.105,BRASS_LIGHT,Enum.Material.Metal)
		end
		rod('Art deco upper rail',{x,3.25,-.40},{-x,3.25,-.40},.075,BRASS_LIGHT,Enum.Material.Metal)
		rod('Art deco rear rail',{x,3.25,.40},{-x,3.25,.40},.075,BRASS_LIGHT,Enum.Material.Metal)
		rod('Rear luggage guard',{x,1.56,.40},{-x,1.56,.40},.045,BRASS,Enum.Material.Metal)
	end

	-- Thick wheels sit outside the luggage deck; hubs make them readable on mobile.
	for _,x in ipairs({-.57,.57}) do
		part(model,'Rubber trolley wheel',Vector3.new(.18,.68,.68),RUBBER,Enum.Material.SmoothPlastic,
			at(x,.43,0,0,0,0),Enum.PartType.Cylinder)
		part(model,'Brass wheel hub',Vector3.new(.09,.23,.23),BRASS,Enum.Material.Metal,
			at(x*1.17,.43,0,0,0,0),Enum.PartType.Cylinder)
		part(model,'Polished hub cap',Vector3.new(.045,.12,.12),BRASS_LIGHT,Enum.Material.Metal,
			at(x*1.25,.43,0,0,0,0),Enum.PartType.Cylinder)
	end
	rod('Wheel axle',{-.57,.43,0},{.57,.43,0},.09,BRASS,Enum.Material.Metal)

	-- Oxblood suitcase with piping, buckles and cream hotel tag.
	block('Oxblood leather suitcase',0,1.56,.02,1.17,.88,.70,LEATHER,Enum.Material.SmoothPlastic,-.055)
	for _,x in ipairs({-.39,.43}) do
		block('Leather strap',x,1.56,-.345,.085,.79,.025,LEATHER_TRIM,Enum.Material.SmoothPlastic,-.055)
	end
	block('Suitcase top seam',0,2.01,-.354,1.00,.025,.025,WALNUT_EDGE,Enum.Material.SmoothPlastic,-.055)
	block('Suitcase bottom seam',0,1.15,-.354,1.00,.025,.025,WALNUT_EDGE,Enum.Material.SmoothPlastic,-.055)
	block('Brass luggage plaque',.08,1.56,-.37,.34,.16,.025,BRASS_LIGHT,Enum.Material.Metal,-.055)
	local tag=block('Cream hotel tag',.08,1.56,-.391,.24,.095,.015,TAG,Enum.Material.SmoothPlastic,-.055)
	local tagFace=Instance.new('SurfaceGui')
	tagFace.Name='HotelTagFace'
	tagFace.Face=Enum.NormalId.Front
	tagFace.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
	tagFace.PixelsPerStud=96
	tagFace.Parent=tag
	local tagText=Instance.new('TextLabel')
	tagText.Size=UDim2.fromScale(1,1)
	tagText.BackgroundTransparency=1
	tagText.Text='HOTEL'
	tagText.Font=Enum.Font.Garamond
	tagText.TextScaled=true
	tagText.TextColor3=Color3.fromRGB(75,48,29)
	tagText.Parent=tagFace
	for _,x in ipairs({-.51,.59}) do
		for _,y in ipairs({1.18,1.94}) do
			block('Suitcase corner cap',x,y,-.365,.075,.08,.025,BRASS_LIGHT,Enum.Material.Metal,-.055)
		end
	end
	rod('Handle support left',{-.05,2.02,-.12},{-.05,2.18,-.12},.065,BRASS,Enum.Material.Metal)
	rod('Handle support right',{-.05,2.02,.27},{-.05,2.18,.27},.065,BRASS,Enum.Material.Metal)
	rod('Leather carry handle',{-.05,2.18,-.12},{-.05,2.18,.27},.07,LEATHER_TRIM,Enum.Material.SmoothPlastic)

	-- Small brass service bell on the front corner.
	part(model,'Service bell base',Vector3.new(.19,.045,.19),BRASS_LIGHT,Enum.Material.Metal,at(-.52,.94,-.39),Enum.PartType.Cylinder)
	part(model,'Service bell dome',Vector3.new(.15,.14,.15),BRASS_LIGHT,Enum.Material.Metal,at(-.52,1.02,-.39),Enum.PartType.Ball)
	part(model,'Service bell button',Vector3.new(.055,.045,.055),BRASS_LIGHT,Enum.Material.Metal,at(-.52,1.10,-.39),Enum.PartType.Ball)

	model.Parent=parent
	return model
end

return Decor
