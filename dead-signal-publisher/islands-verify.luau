local W=workspace;local H=game:GetService('HttpService')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-three-islands-v1' and W:GetAttribute('IslandWorldReady')==true,'Wrong or incomplete world')
assert(not W:FindFirstChild('OvergrownAtrium') and not W:FindFirstChild('ForestExpansion'),'Old forest remains')
assert(#W.IslandDestinations:GetChildren()==3,'Exactly three arrivals required')
local manifest=H:JSONDecode(W:GetAttribute('IslandWorldMeta'));local positions={};local counts={}
for _,meta in ipairs(manifest) do
 local spawn=W.IslandDestinations[meta.id];assert(spawn.Enabled and spawn.Neutral,'Arrival disabled')
 table.insert(positions,spawn.Position)
 local n=0
 for _,d in ipairs(W.Islands[meta.id]:GetDescendants()) do
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
assert(W.StreamingMinRadius==64 and W.StreamingTargetRadius==128,'Streaming changed')
assert(game:GetService('Lighting'):FindFirstChildOfClass('BloomEffect'),'Bloom missing')
assert(#game:GetService('StarterGui'):GetChildren()==0,'Old menu remains')
return H:JSONEncode({ok=true,version=game.PlaceVersion,build=W:GetAttribute('DeadSignalBuildId'),maps=counts,spawns=3,lightAsset=W:GetAttribute('ForestLightAsset'),streaming=128,oldForestRemoved=true})
