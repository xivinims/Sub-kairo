local W=workspace;local H=game:GetService('HttpService')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-three-islands-v1' and W:GetAttribute('IslandWorldReady')==true,'Wrong or incomplete world')
assert(not W:FindFirstChild('OvergrownAtrium') and not W:FindFirstChild('ForestExpansion'),'Old forest remains')
assert(#W.IslandDestinations:GetChildren()==3,'Exactly three arrivals required')
local Chunks=require(game:GetService('ServerScriptService').AtriumRuntime.IslandChunks)
local manifest=H:JSONDecode(W:GetAttribute('IslandWorldMeta'));local positions={};local counts={}
for _,meta in ipairs(manifest) do
 local spawn=W.IslandDestinations[meta.id];assert(spawn.Enabled and spawn.Neutral,'Arrival disabled')
 Chunks.Warm(meta.id,spawn.Position,128)
 table.insert(positions,spawn.Position)
 local n=0
 for _,d in ipairs(game:GetService('ServerStorage').IslandGeometryCatalog[meta.id]:GetDescendants()) do
  assert(not d:IsA('LuaSourceContainer') and not d:IsA('Sound'),'Unsafe imported content')
  if d:IsA('BasePart') then assert(d.Anchored,'Unanchored scenery');n+=1 end
 end
 assert(n>1000,'Map missing geometry: '..meta.id);counts[meta.id]=n
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={W.Terrain,W.Islands[meta.id]};params.IgnoreWater=true
 assert(W:Raycast(spawn.Position+Vector3.new(0,1,0),Vector3.new(0,-12,0),params),'Arrival unsupported')
end
for i=1,#positions do for j=i+1,#positions do assert((positions[i]-positions[j]).Magnitude>3000,'Islands are too close') end end
local SP=game:GetService('StarterPlayer').StarterPlayerScripts
assert(SP.IslandTravelClient.Enabled and SP.IslandTravelClient.Source:find('🗺️',1,true),'Map UI missing')
assert(game:GetService('ServerScriptService').AtriumRuntime.IslandTravelServer.Enabled,'Travel server disabled')
assert(game:GetService('ReplicatedStorage').IslandTravel:IsA('RemoteEvent'),'Travel remote missing')
assert((W:GetAttribute('IslandStreamingTarget') or 192)<=192,'Streaming metadata changed')
assert(game:GetService('Lighting'):FindFirstChildOfClass('BloomEffect'),'Bloom missing')
assert(#game:GetService('StarterGui'):GetChildren()==0,'Old menu remains')
assert(game:GetService('ReplicatedFirst').IslandLoadingClient.Enabled,'Early loading missing')
assert(game:GetService('ServerScriptService').AtriumRuntime.IslandDoors.Enabled,'Door runtime missing')
local residentModule=require(game:GetService('ServerScriptService').AtriumRuntime.IslandResidents)
local residentReport={}
for _,def in ipairs(residentModule.Definitions) do
 local rig=residentModule.Build(def)
 local position=residentModule.FindGround(def);assert(position,'Unsafe resident placement: '..def.id)
 table.insert(residentReport,{id=def.id,position=tostring(position),parts=#rig:GetDescendants(),hair=def.hair,shirt=def.shirt,pants=def.pants});rig:Destroy()
end
assert(#residentReport==6,'Residents incomplete');print('RESIDENT APPEARANCES VERIFIED '..H:JSONEncode(residentReport))
for _,meta in ipairs(manifest) do if meta.id=='city' then
 assert(meta.water and #meta.water>=8,'Sea missing')
 local volume=meta.water[1];local center=(CFrame.new(unpack(volume.cf))+Vector3.new(unpack(meta.offset))).Position
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={W.Terrain};params.IgnoreWater=false
 local hit=W:Raycast(center+Vector3.new(0,12,0),Vector3.new(0,-24,0),params)
 assert(hit and hit.Material==Enum.Material.Water,'City sea not present in terrain');print('CITY WATER VERIFIED '..#meta.water..' original footprints')
end end
local disasters=require(game:GetService('ServerScriptService').AtriumRuntime.DisasterService)
assert(#disasters.Types==5,'Disaster set incomplete')
for _,kind in ipairs(disasters.Types) do
 disasters.SetPhase('Warning',kind,'city',25);assert(disasters.CanTravel(),'Warning evacuation blocked')
 disasters.SetPhase('Active',kind,'city',70);assert(not disasters.CanTravel(),'Active travel exploit')
 disasters.SetPhase('Recovery',kind,'city',15);assert(disasters.CanTravel(),'Recovery travel blocked')
end
disasters.SetPhase('Calm','','city',90)
local shelterCount=0
for _,def in ipairs(residentModule.Definitions) do if def.island=='city' then
 local pos=residentModule.FindGround(def);local shelter=disasters.FindShelter(pos,'city');if shelter then shelterCount+=1 end
end end
assert(shelterCount>=1,'City has no reachable roof candidates')
print('DISASTER RULES VERIFIED: five modes, phase travel gates, shelter candidates='..shelterCount)
local blackHole
if W:GetAttribute('BlackHoleAsset') then
 local template=game:GetService('ReplicatedStorage'):FindFirstChild('SkyBlackHoleTemplate')
 assert(template and template:GetAttribute('SourceAsset')=='7208091524','Original black hole template missing')
 assert(SP.SkyBlackHoleClient.Enabled,'Sky renderer missing')
 local parts,beams,bones=0,0,0
 for _,d in ipairs(template:GetDescendants()) do
  assert(not d:IsA('LuaSourceContainer') and not d:IsA('Sound') and not d:IsA('Terrain'),'Unsafe celestial data')
  if d:IsA('BasePart') then parts+=1;assert(d.Anchored and not d.CanCollide and not d.CanQuery,'Sky collider present') end
  if d:IsA('Beam') then beams+=1 end
  if d:IsA('Bone') then bones+=1 end
 end
 assert(parts>50 and beams>10 and bones>=100,'Incomplete original black hole or debris rig')
 local probe=template:Clone();probe.WorldPivot=CFrame.lookAt(template:GetAttribute('SourceOrigin'),template:GetAttribute('SourceOrigin')+Vector3.new(1,0,0))
 probe:ScaleTo(math.clamp(450/template:GetAttribute('ReferenceDistance'),.12,.7));probe:PivotTo(CFrame.lookAt(Vector3.new(0,350,-450),Vector3.new(0,100,0)));probe:Destroy()
 blackHole={asset='7208091524',parts=parts,beams=beams,bones=bones,clientRenderer=true}
end
return H:JSONEncode({disasters=5,shelters=shelterCount,residents=residentReport,cityWater=true,ok=true,version=game.PlaceVersion,build=W:GetAttribute('DeadSignalBuildId'),maps=counts,spawns=3,lightAsset=W:GetAttribute('ForestLightAsset'),streaming=W:GetAttribute('IslandStreamingTarget') or 192,oldForestRemoved=true,blackHole=blackHole})
