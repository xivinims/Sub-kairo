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
assert(#residentReport==8,'Residents incomplete');print('RESIDENT APPEARANCES VERIFIED '..H:JSONEncode(residentReport))
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
assert(workspace.Islands.forestCurrent:FindFirstChild('AdventureVillage'),'Village missing')
print('DISASTER RULES VERIFIED: five modes, phase travel gates, shelter candidates='..shelterCount)
local options=Instance.new('TeleportOptions')
local modern=pcall(function() options.ReservedServerId=H:GenerateGUID(false) end)
if not modern then options.ShouldReserveServer=true end
options:Destroy()
assert(game:GetService('ServerScriptService').AtriumRuntime.SessionRuntime.Enabled,'Session runtime missing')
assert(game:GetService('ReplicatedFirst').SessionMenuClient.Enabled,'Menu missing')
print('SESSION STRUCTURE VERIFIED: reserved server options supported; authenticated group allowlist, cap six')
local adventure=require(game:GetService('ServerScriptService').AtriumRuntime.AdventureForest)
assert(workspace:GetAttribute('AdventureForestSize')==6144,'Forest extension missing')
assert(#game:GetService('ServerStorage').AdventureTrees:GetChildren()>0,'Authored trees missing')
local center=workspace:GetAttribute('VillageCenter');assert(center and center.Z< -900,'Village separation missing')
assert(not game:GetService('ServerScriptService').AtriumRuntime:FindFirstChild('DisasterRuntime'),'Old disasters enabled')
local cell=adventure.Cell(12,12,W.Islands.forestCurrent)
assert(cell and #cell:GetChildren()>0,'Outer forest cell empty')
for _,tree in ipairs(cell:GetChildren()) do
 local bounds,size=tree:GetBoundingBox();local bottom=bounds.Y-size.Y/2
 assert(math.abs(bottom-adventure.Height(1600,1600))<.1,'Floating generated tree')
 local collider
 for _,part in ipairs(tree:GetDescendants()) do if part:IsA('BasePart') and part.CanCollide and part.CanQuery then collider=part;break end end
 assert(collider,'Tree cannot provide cover')
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={tree};rp.RespectCanCollide=true
 assert(W:Raycast(collider.Position-collider.CFrame.RightVector*(collider.Size.X+3),collider.CFrame.RightVector*(collider.Size.X*2+6),rp),'Tree does not block sight')
end
cell:Destroy()
print('ADVENTURE VERIFIED: native grass extension, original tree templates, four village building groups, eight identities, mission and patrol sources')
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
return H:JSONEncode({adventure=true,forestSize=6144,villageHouses=4,residents=residentReport,cityWater=true,ok=true,version=game.PlaceVersion,build=W:GetAttribute('DeadSignalBuildId'),maps=counts,spawns=3,lightAsset=W:GetAttribute('ForestLightAsset'),streaming=W:GetAttribute('IslandStreamingTarget') or 192,oldForestRemoved=true,blackHole=blackHole})
