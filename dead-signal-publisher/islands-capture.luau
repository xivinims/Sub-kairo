local W=workspace;local T=W.Terrain;local H=game:GetService('HttpService')
local meta=H:JSONDecode(W:GetAttribute('IslandStageMeta'))
local low,high=Vector3.new(unpack(meta.lo)),Vector3.new(unpack(meta.hi))
local min=Vector3int16.new(math.floor((low.X-64)/4),math.floor((low.Y-64)/4),math.floor((low.Z-64)/4))
local max=Vector3int16.new(math.ceil((high.X+64)/4),math.ceil((high.Y+32)/4),math.ceil((high.Z+64)/4))
local regions=Instance.new('Folder');regions.Name='IslandTerrainRegion';regions.Parent=game:GetService('ServerStorage')
local tiles=0
for x=min.X,max.X,64 do for z=min.Z,max.Z,64 do
 local corner=Vector3int16.new(x,min.Y,z)
 local upper=Vector3int16.new(math.min(x+63,max.X),max.Y,math.min(z+63,max.Z))
 local region=T:CopyRegion(Region3int16.new(corner,upper));region.Name='Tile_'..tiles
 region:SetAttribute('SourceCornerCells',Vector3.new(x,min.Y,z));region.Parent=regions;tiles+=1
 if tiles%8==0 then task.wait() end
end end
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={T};params.IgnoreWater=true
local geom=RaycastParams.new();geom.FilterType=Enum.RaycastFilterType.Include;geom.FilterDescendantsInstances={W.SourceGeometry};geom.IgnoreWater=true
local candidates=meta.preferred
local center=(low+high)*.5
for r=0,12 do for j=1,math.max(1,r*8) do
 local a=j/math.max(1,r*8)*math.pi*2
 table.insert(candidates,{center.X+math.cos(a)*r*16,high.Y+10,center.Z+math.sin(a)*r*16})
end end
local spawn
local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={W.SourceGeometry};overlap.RespectCanCollide=true
for _,v in ipairs(candidates) do
 local pos=Vector3.new(unpack(v));local hit=W:Raycast(Vector3.new(pos.X,high.Y+64,pos.Z),Vector3.new(0,low.Y-high.Y-160,0),params)
 local surface=hit and hit.Position
 if pos.Y<high.Y or hit then
  -- Original spawns may stand on a built floor above terrain.
  if pos.Y<high.Y then local f=W:Raycast(pos+Vector3.new(0,2,0),Vector3.new(0,-16,0),geom);if f and f.Normal.Y>.75 and (not surface or f.Position.Y>=surface.Y) then surface=f.Position end end
  if surface and #W:GetPartBoundsInBox(CFrame.new(surface+Vector3.new(0,3.2,0)),Vector3.new(4,5.5,4),overlap)==0 then spawn=surface;break end
 end
end
assert(spawn,'No unobstructed arrival position in source')
meta.spawn={spawn.X,spawn.Y,spawn.Z};meta.corner={min.X,min.Y,min.Z};meta.cells={max.X-min.X+1,max.Y-min.Y+1,max.Z-min.Z+1};meta.tiles=tiles
W:SetAttribute('IslandStageMeta',H:JSONEncode(meta))
game:GetService('AssetService'):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=true})
return H:JSONEncode({captured=true,sourceVersion=game.PlaceVersion,savedVersion=game.PlaceVersion+1,meta=meta})
