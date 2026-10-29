local W=workspace;local SS=game:GetService('ServerStorage')
local region=SS:FindFirstChild('MansionTerrain')
if region then
 W.Terrain:Clear();W.Terrain:PasteRegion(region,Vector3int16.new(-144,-64,-192),false);region:Destroy()
end
local Chunks=require(game:GetService('ServerScriptService').AtriumRuntime.MansionChunks)
-- Ground the source Orderly tree template on the original Duvall terrain; no foreign scene scripts.
local template=SS:WaitForChild('OrderlyTree');local catalog=SS.MansionCatalog
local cf,size=template:GetBoundingBox();local height=size.Y;local rng=Random.new(7902470429)
local trees=0;local cells={}
local checkParams=RaycastParams.new();checkParams.FilterType=Enum.RaycastFilterType.Include;checkParams.FilterDescendantsInstances={W.Terrain}
if not W:Raycast(Vector3.new(400,300,400),Vector3.new(0,-600,0),checkParams) then
 -- Preserve the mansion/basement void; provide continuous native soil only around its footprint.
 for _,strip in ipairs({{Vector3.new(-432,-22,-20),Vector3.new(434,24,1300)},{Vector3.new(432,-22,-20),Vector3.new(434,24,1300)},{Vector3.new(0,-22,392),Vector3.new(430,24,514)},{Vector3.new(0,-22,-460),Vector3.new(430,24,380)}}) do W.Terrain:FillBlock(CFrame.new(strip[1]),strip[2],Enum.Material.Grass) end
end
local terrainParams=RaycastParams.new();terrainParams.FilterType=Enum.RaycastFilterType.Include;terrainParams.FilterDescendantsInstances={W.Terrain};terrainParams.IgnoreWater=false
for x=-9,9 do for z=-10,9 do
 local px,pz=x*56+rng:NextNumber(-15,15),z*56+rng:NextNumber(-15,15)
 if not (math.abs(px)<190 and pz> -220 and pz<90) then
  local ground=W:Raycast(Vector3.new(px,350,pz),Vector3.new(0,-650,0),terrainParams)
  if ground and ground.Material~=Enum.Material.Water and ground.Normal.Y>.65 then
   local tree=template:Clone();tree.Name='OrderlyTree';tree:ScaleTo(rng:NextNumber(60,95)/height)
   tree:PivotTo(CFrame.new(ground.Position)*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0))
   local box,extent=tree:GetBoundingBox();tree:PivotTo(tree:GetPivot()+Vector3.new(0,ground.Position.Y-(box.Y-extent.Y/2),0))
   local widest;local width=0
   for _,p in ipairs(tree:GetDescendants()) do if p:IsA('BasePart') then p.Anchored=true;p.CanTouch=false;if p.Size.X+p.Size.Z>width then widest=p;width=p.Size.X+p.Size.Z end end end
   if widest then widest:SetAttribute('IslandWind',true);widest.CanCollide=false;widest.CanQuery=false end
   local key='Forest_'..math.floor(px/64)..'_'..math.floor(pz/64)
   if not cells[key] then local cell=Instance.new('Model');cell.Name=key;cell:SetAttribute('Section','Forest');cell:SetAttribute('CellCenter',Vector3.new((math.floor(px/64)+.5)*64,0,(math.floor(pz/64)+.5)*64));cell.Parent=catalog;cells[key]=cell end
   tree.Parent=cells[key];trees+=1
  end
 end
end end
assert(trees>=20,'Orderly forest placement failed');W:SetAttribute('OrderlyTreeCount',trees)
local spawn=W.IslandDestinations.forestCurrent
Chunks.Warm(spawn.Position,170)
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={W.Terrain,W.Islands.mansion};params.IgnoreWater=true
local hit=W:Raycast(spawn.Position+Vector3.new(0,4,0),Vector3.new(0,-35,0),params)
assert(hit,'Original mansion spawn has no floor')
spawn.CFrame=CFrame.new(hit.Position+Vector3.new(0,.2,0))
local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include;op.FilterDescendantsInstances={W.Islands.mansion};op.RespectCanCollide=true
local safe
for _,offset in ipairs({Vector3.new(),Vector3.new(4,0,0),Vector3.new(-4,0,0),Vector3.new(0,0,6),Vector3.new(0,0,-6)}) do
 local probe=Instance.new('Part');probe.Size=Vector3.new(3,5,3);probe.CFrame=spawn.CFrame+CFrame.new(offset+Vector3.new(0,3,0)).Position;probe.Anchored=true;probe.Transparency=1;probe.CanCollide=false;probe.Parent=W
 local clear=#W:GetPartsInPart(probe,op)==0;probe:Destroy()
 if clear then safe=spawn.CFrame+offset;break end
end
assert(safe,'Mansion arrival obstructed');spawn.CFrame=safe
W:SetAttribute('IslandWorldReady',true)
