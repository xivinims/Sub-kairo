local Workspace=game:GetService("Workspace")
local ServerScriptService=game:GetService("ServerScriptService")
local AssetService=game:GetService("AssetService")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")

local world=assert(Workspace:FindFirstChild("OveryardPhotoWorld"),"World missing")
local npc=assert(world:FindFirstChild("Caio"),"Caio missing")
local sourceVersion=game.PlaceVersion

local function physicalGroundAndFoot(model)
	local left=assert(model:FindFirstChild("LeftFoot"),"LeftFoot missing")
	local right=assert(model:FindFirstChild("RightFoot"),"RightFoot missing")
	local root=assert(model:FindFirstChild("HumanoidRootPart"),"HumanoidRootPart missing")

	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={Workspace.Terrain}

	local hit=Workspace:Raycast(
		Vector3.new(root.Position.X,300,root.Position.Z),
		Vector3.new(0,-500,0),
		params
	)
	assert(hit,"No physical terrain below Caio")

	local leftBottom=left.Position.Y-left.Size.Y/2
	local rightBottom=right.Position.Y-right.Size.Y/2
	return hit.Position.Y,math.min(leftBottom,rightBottom),leftBottom,rightBottom
end

local ground,bottom,leftBefore,rightBefore=physicalGroundAndFoot(npc)
local desired=ground+.06
local delta=desired-bottom
npc:PivotTo(npc:GetPivot()+Vector3.new(0,delta,0))

local groundAfter,bottomAfter,leftAfter,rightAfter=physicalGroundAndFoot(npc)
assert(math.abs(bottomAfter-desired)<.08,"Caio grounding correction failed")

local old=ServerScriptService:FindFirstChild("CaioGroundingService")
if old then old:Destroy() end

local service=Instance.new("Script")
service.Name="CaioGroundingService"
service.Source=[=[
local Workspace=game:GetService("Workspace")

local function groundCaio()
	local world=Workspace:WaitForChild("OveryardPhotoWorld",30)
	if not world then return end
	local npc=world:WaitForChild("Caio",30)
	if not npc then return end
	local left=npc:FindFirstChild("LeftFoot")
	local right=npc:FindFirstChild("RightFoot")
	local root=npc:FindFirstChild("HumanoidRootPart")
	if not left or not right or not root then return end

	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={Workspace.Terrain}

	local hit=Workspace:Raycast(
		Vector3.new(root.Position.X,300,root.Position.Z),
		Vector3.new(0,-500,0),
		params
	)
	if not hit then return end

	local bottom=math.min(
		left.Position.Y-left.Size.Y/2,
		right.Position.Y-right.Size.Y/2
	)
	local desired=hit.Position.Y+.06
	local delta=desired-bottom

	if math.abs(delta)>.015 then
		npc:PivotTo(npc:GetPivot()+Vector3.new(0,delta,0))
	end
	npc:SetAttribute("PhysicalGroundY",hit.Position.Y)
	npc:SetAttribute("GroundingError",math.abs(desired-(bottom+delta)))
	npc:SetAttribute("GroundingRevision","physical-raycast-v15")
end

task.wait(.25)
groundCaio()
]=]
service.Parent=ServerScriptService

npc:SetAttribute("PhysicalGroundY",groundAfter)
npc:SetAttribute("GroundingError",math.abs((groundAfter+.06)-bottomAfter))
npc:SetAttribute("GroundingRevision","physical-raycast-v15")

AssetService:SavePlaceAsync()

return {
	ok=true,
	sourceVersion=sourceVersion,
	delta=delta,
	ground=groundAfter,
	leftBefore=leftBefore,
	rightBefore=rightBefore,
	leftAfter=leftAfter,
	rightAfter=rightAfter,
	bottomAfter=bottomAfter,
}
