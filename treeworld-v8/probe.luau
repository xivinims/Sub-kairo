assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
local w=workspace:FindFirstChild("ReferenceWorld")
assert(w,"Current world missing")
local h=w.House:FindFirstChild("JapaneseHouse")
assert(h,"Current house missing")
local cf,size=h:GetBoundingBox()
local parts={}
for _,p in ipairs(h:GetDescendants()) do
 if p:IsA("BasePart") then
  local entry={name=p.Name,class=p.ClassName,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},collide=p.CanCollide,query=p.CanQuery,transparency=p.Transparency}
  if p:IsA("MeshPart") then entry.mesh=p.MeshId;entry.fidelity=tostring(p.CollisionFidelity);entry.meshSize={p.MeshSize.X,p.MeshSize.Y,p.MeshSize.Z} end
  table.insert(parts,entry)
 end
end
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={workspace.Terrain}
local ground={}
for _,pos in ipairs({Vector3.new(0,0,-70),Vector3.new(-58,0,155),Vector3.new(58,0,155),Vector3.new(-116,0,-850),Vector3.new(116,0,-850)}) do
 local hit=workspace:Raycast(pos+Vector3.new(0,300,0),Vector3.new(0,-700,0),params)
 table.insert(ground,{x=pos.X,z=pos.Z,y=hit and hit.Position.Y,material=hit and tostring(hit.Material)})
end
return {placeVersion=game.PlaceVersion,version=workspace:GetAttribute("WorldRebuildVersion"),house={size={size.X,size.Y,size.Z},cf={cf:GetComponents()},pivot={h:GetPivot():GetComponents()},scale=h:GetScale(),parts=parts},terrain=ground}
