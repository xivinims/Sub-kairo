local Workspace=game:GetService("Workspace")
local world=assert(Workspace:FindFirstChild("OveryardPhotoWorld"),"World missing")
local npc=assert(world:FindFirstChild("Caio"),"Caio missing")
local left=assert(npc:FindFirstChild("LeftFoot"))
local right=assert(npc:FindFirstChild("RightFoot"))
local root=assert(npc:FindFirstChild("HumanoidRootPart"))

local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={Workspace.Terrain}
local hit=assert(Workspace:Raycast(Vector3.new(root.Position.X,300,root.Position.Z),Vector3.new(0,-500,0),params),"No terrain below Caio")

local leftBottom=left.Position.Y-left.Size.Y/2
local rightBottom=right.Position.Y-right.Size.Y/2
local lowest=math.min(leftBottom,rightBottom)
local error=lowest-hit.Position.Y

assert(error>=0 and error<.20,"Caio still underground/floating: "..tostring(error))
assert(npc:GetAttribute("GroundingRevision")=="physical-raycast-v15","Grounding revision missing")
assert(game.ServerScriptService:FindFirstChild("CaioGroundingService"),"Grounding service missing")
assert(world:FindFirstChild("WholeMapPhotoDetailV14"),"Current map detail pass lost")
assert(npc:GetAttribute("AppearanceRevision")=="slim-caio-v14","Caio appearance changed")

return {
	ok=true,
	placeVersion=game.PlaceVersion,
	ground=hit.Position.Y,
	leftBottom=leftBottom,
	rightBottom=rightBottom,
	lowestFootError=error,
	groundingRevision=npc:GetAttribute("GroundingRevision"),
	mapPreserved=true,
	appearancePreserved=true,
}
