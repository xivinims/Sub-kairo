local W=workspace;local T=W.Terrain;local H=game:GetService('HttpService')
print('CAPTURE BOOT',game.PlaceVersion)
local meta=H:JSONDecode(W:GetAttribute('IslandStageMeta'))
local geometry=game:GetService('ServerStorage').SourceGeometry
local probe=Instance.new('Folder');probe.Name='SpawnProbe';probe.Parent=W
if meta.id=='186677844' and meta.preferred[1] then
 local point=Vector3.new(unpack(meta.preferred[1]))
 for _,p in ipairs(geometry:GetChildren()) do if (p.Position-point).Magnitude<64 then p:Clone().Parent=probe end end
end
local low,high=Vector3.new(unpack(meta.lo)),Vector3.new(unpack(meta.hi))
local min=Vector3int16.new(math.floor((low.X-64)/4),math.floor((low.Y-64)/4),math.floor((low.Z-64)/4))
local max=Vector3int16.new(math.ceil((high.X+64)/4),math.ceil((high.Y+32)/4),math.ceil((high.Z+64)/4))
local raw=game:GetService('ServerStorage').RawSourceTerrain
T:Clear();T:PasteRegion(raw,min,false);raw:Destroy()
print('SOURCE TERRAIN PASTED',T:CountCells())
local regions=Instance.new('Folder');regions.Name='IslandTerrainRegion';regions.Parent=game:GetService('ServerStorage')
local scan=RaycastParams.new();scan.FilterType=Enum.RaycastFilterType.Include;scan.FilterDescendantsInstances={T}
local tiles=0
for x=min.X,max.X,64 do for z=min.Z,max.Z,64 do
 local upperX,upperZ=math.min(x+63,max.X),math.min(z+63,max.Z)
 local bottom,top=math.huge,-math.huge
 for sx=x,upperX,8 do for sz=z,upperZ,8 do
  local hit=W:Raycast(Vector3.new(sx*4,high.Y+64,sz*4),Vector3.new(0,low.Y-high.Y-160,0),scan)
  if hit then bottom=math.min(bottom,hit.Position.Y);top=math.max(top,hit.Position.Y) end
 end end
 if top>-math.huge then
  local lowerY=math.max(min.Y,math.floor((bottom-64)/4));local upperY=math.min(max.Y,math.ceil((top+32)/4))
  local corner=Vector3int16.new(x,lowerY,z);local upper=Vector3int16.new(upperX,upperY,upperZ)
  local region=T:CopyRegion(Region3int16.new(corner,upper));region.Name='Tile_'..tiles
  region:SetAttribute('SourceCornerCells',Vector3.new(x,lowerY,z));region.Parent=regions;tiles+=1
 end
 if (x-min.X)%256==0 then task.wait() end
end end
print('TERRAIN TILES CAPTURED',tiles)
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={T};params.IgnoreWater=true
local geom=RaycastParams.new();geom.FilterType=Enum.RaycastFilterType.Include;geom.FilterDescendantsInstances={probe};geom.IgnoreWater=true
local candidates=meta.preferred
local center=(low+high)*.5
for r=0,12 do for j=1,math.max(1,r*8) do
 local a=j/math.max(1,r*8)*math.pi*2
 table.insert(candidates,{center.X+math.cos(a)*r*16,high.Y+10,center.Z+math.sin(a)*r*16})
end end
local spawn
local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={probe};overlap.RespectCanCollide=true
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
probe:Destroy()
print('SAVING CAPTURE',tiles)
game:GetService('AssetService'):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=true})
return H:JSONEncode({captured=true,sourceVersion=game.PlaceVersion,savedVersion=game.PlaceVersion+1,meta=meta})
