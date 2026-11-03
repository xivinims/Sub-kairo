local world=assert(workspace:FindFirstChild('OveryardPhotoWorld'))
local npc=assert(world:FindFirstChild('Caio'))
local root=assert(npc:FindFirstChild('HumanoidRootPart'))
local hum=assert(npc:FindFirstChildOfClass('Humanoid'))
local C=require(game.ReplicatedStorage.PhotoWorldConfig)
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.Terrain}
local hit=workspace:Raycast(Vector3.new(root.Position.X,300,root.Position.Z),Vector3.new(0,-500,0),params)
local ground=hit and hit.Position.Y or nil
local boxCF,boxSize=npc:GetBoundingBox()
local function foot(name)
 local p=npc:FindFirstChild(name)
 if not p then return nil end
 return {y=p.Position.Y,sizeY=p.Size.Y,bottom=p.Position.Y-p.Size.Y/2}
end
return {
 placeVersion=game.PlaceVersion,
 revision=npc:GetAttribute('AppearanceRevision'),
 root={root.Position.X,root.Position.Y,root.Position.Z},
 hipHeight=hum.HipHeight,
 ground=ground,
 configGround=C.surface(root.Position.X,root.Position.Z),
 boxBottom=boxCF.Position.Y-boxSize.Y/2,
 boxSize={boxSize.X,boxSize.Y,boxSize.Z},
 left=foot('LeftFoot'),
 right=foot('RightFoot'),
 descendants=#npc:GetDescendants(),
}