assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local W=workspace;local T=W.Terrain;local H=game:GetService('HttpService')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-three-islands-v1','Wrong build')
local manifest=H:JSONDecode(W:GetAttribute('IslandWorldMeta'))
local snapshots=game:GetService('ServerStorage').IslandTerrainSnapshots
T:Clear()
for _,meta in ipairs(manifest) do
 local region=snapshots:FindFirstChild(meta.id);assert(region,'Terrain snapshot missing')
 local offset=Vector3.new(unpack(meta.offset))/4
 for _,tile in ipairs(region:GetChildren()) do
  local c=tile:GetAttribute('SourceCornerCells')+offset
  T:PasteRegion(tile,Vector3int16.new(c.X,c.Y,c.Z),true)
  if meta.id~='city' then
   local minPoint=c*4;local maxPoint=minPoint+tile.SizeInCells*4
   T:ReplaceMaterial(Region3.new(minPoint,maxPoint):ExpandToGrid(4),4,Enum.Material.LeafyGrass,Enum.Material.Grass)
  end
 end
 local min=Vector3.new(meta.corner[1]*4,meta.corner[2]*4,meta.corner[3]*4)
 local max=min+Vector3.new(unpack(meta.cells))*4
 -- Ocean surrounds each independent landmass, not the entire world.
 local sea=meta.spawn[2]-48;local pad=192;local x=(min.X+max.X)/2;local z=(min.Z+max.Z)/2
 T:FillBlock(CFrame.new(x,sea-8,min.Z-pad/2),Vector3.new(max.X-min.X+pad*2,16,pad),Enum.Material.Water)
 T:FillBlock(CFrame.new(x,sea-8,max.Z+pad/2),Vector3.new(max.X-min.X+pad*2,16,pad),Enum.Material.Water)
 T:FillBlock(CFrame.new(min.X-pad/2,sea-8,z),Vector3.new(pad,16,max.Z-min.Z),Enum.Material.Water)
 T:FillBlock(CFrame.new(max.X+pad/2,sea-8,z),Vector3.new(pad,16,max.Z-min.Z),Enum.Material.Water)

end
-- Ground the three distinct arrivals and clear only nearby vegetation at the altar.
local destinations=W.IslandDestinations
local Chunks=require(game:GetService('ServerScriptService').AtriumRuntime.IslandChunks)
for _,s in ipairs(destinations:GetChildren()) do Chunks.Warm(s.Name,s.Position,128) end
local checks={}
for _,meta in ipairs(manifest) do
 local spawn=destinations[meta.id];local source=W.Islands[meta.id]
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={T,source};params.IgnoreWater=true
 local hit=W:Raycast(spawn.Position+Vector3.new(0,3,0),Vector3.new(0,-24,0),params)
 assert(hit and hit.Normal.Y>.7,'Invalid arrival floor for '..meta.id)
 spawn.CFrame=CFrame.lookAt(hit.Position+Vector3.new(0,.15,0),hit.Position+Vector3.new(0,.15,-10))
 local altar=source:FindFirstChild('ArrivalAltar')
 if altar then
  -- Use the existing altar's actual floor, not a guessed platform height.
  local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Include;p.FilterDescendantsInstances={altar}
  local cf,size=altar:GetBoundingBox()
  local floor=W:Raycast(spawn.Position+Vector3.new(0,.7,0),Vector3.new(0,-12,0),p)
  assert(floor,'Altar floor missing');spawn.CFrame=CFrame.lookAt(floor.Position+Vector3.new(0,.15,0),floor.Position+Vector3.new(0,.15,-10))
  local removed=0
  local clearList=source:GetDescendants()
  for _,d in ipairs(game:GetService('ServerStorage').IslandGeometryCatalog[meta.id]:GetDescendants()) do table.insert(clearList,d) end
  for _,d in ipairs(clearList) do if d:IsA('BasePart') and not d:IsDescendantOf(altar) then
   local v=d.Position-spawn.Position
   if Vector3.new(v.X,0,v.Z).Magnitude<18 and (d:GetAttribute('IslandWind') or d:IsA('MeshPart')) then d:Destroy();removed+=1 end
  end end
 end
 local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include;op.FilterDescendantsInstances={source};op.RespectCanCollide=true
 local blockers=W:GetPartBoundsInBox(CFrame.new(spawn.Position+Vector3.new(0,3.3,0)),Vector3.new(3.5,5.5,3.5),op)
 assert(#blockers==0,'Arrival blocked: '..meta.id..' / '..(#blockers>0 and blockers[1]:GetFullName() or ''))
 table.insert(checks,{id=meta.id,floor=hit.Instance.Name,position={spawn.Position.X,spawn.Position.Y,spawn.Position.Z}})
end
for _,d in ipairs(W.Islands:GetDescendants()) do assert(not d:IsA('LuaSourceContainer') and not d:IsA('Sound'),'External runtime content found') end
snapshots:Destroy()
W:SetAttribute('IslandWorldReady',true)
W:SetAttribute('ForestSurfaceMaterial','Grass')
game:GetService('AssetService'):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=true})
return H:JSONEncode({ready=true,sourceVersion=game.PlaceVersion,savedVersion=game.PlaceVersion+1,arrivals=checks})
