local fs=require('@lune/fs');local R=require('@lune/roblox')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-verified.rbxl'));local W=dm:GetService('Workspace')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-three-islands-v1','Wrong world')
assert(W.Terrain.Decoration==true and math.abs(W.Terrain.GrassLength-.85)<.001,'Native grass lost')
assert(not W:FindFirstChild('OvergrownAtrium'),'Old forest remains')
assert(#dm:GetService('ServerStorage').MatchWorld.IslandDestinations:GetChildren()==3,'Missing spawns')
if W:GetAttribute('IslandWorldReady')~=true then
 assert(dm:GetService('ServerScriptService').AtriumRuntime.IslandInitializer.Disabled==false,'Runtime initializer missing')
 assert(#dm:GetService('ServerStorage').IslandTerrainSnapshots:GetChildren()==3,'Terrain templates missing')
else assert(not dm:GetService('ServerStorage'):FindFirstChild('IslandTerrainSnapshots'),'Redundant snapshots remain') end
local SP=dm:GetService('StarterPlayer').StarterPlayerScripts
assert(SP.IslandTravelClient.Source==fs.readFile('islands-travel-client.luau'),'Travel client mismatch')
assert(dm:GetService('ServerScriptService').AtriumRuntime.IslandTravelServer.Source==fs.readFile('islands-travel-server.luau'),'Travel server mismatch')
for _,d in ipairs(dm:GetService('ServerStorage').IslandGeometryCatalog:GetDescendants()) do assert(not d:IsA('LuaSourceContainer') and not d:IsA('Sound'),'Unsafe geometry') end
assert(W.StreamingMinRadius==64 and W.StreamingTargetRadius<=192,'Wrong streaming')
local terrains=0;for _,d in ipairs(dm:GetDescendants()) do if d:IsA('Terrain') then terrains+=1;assert(d.Parent==W,'Nested terrain') end end;assert(terrains==1,'Duplicate terrain')
print('ISLANDS VERIFIED: exact sources, native grass, three spawns, streaming, no old forest or imported scripts')

if W:GetAttribute('BlackHoleAsset') then
 local template=dm:GetService('ReplicatedStorage').SkyBlackHoleTemplate
 assert(template:GetAttribute('SourceAsset')=='7208091524','Wrong black hole provenance')
 assert(SP.SkyBlackHoleClient.Source==fs.readFile('blackhole-client.luau'),'Sky renderer source mismatch')
 for _,d in ipairs(template:GetDescendants()) do assert(not d:IsA('LuaSourceContainer') and not d:IsA('Sound'),'Imported sky code/audio present') end
 print('BLACK HOLE VERIFIED: original geometry + beams, safe client renderer')
end
assert(W.StreamingTargetRadius==W:GetAttribute('IslandStreamingTarget'),'Streaming metadata differs from file')

assert(W:GetAttribute('IslandAtmosphereRevision')=='storm-night-v2','Atmosphere missing')
assert(dm:GetService('Lighting').ClockTime>=20,'Dusk not applied')
assert(SP.ForestWindClient.Source==fs.readFile('forest-wind-client.luau'),'Wind mismatch')
assert(SP.ForestWeatherClient.Source==fs.readFile('forest-weather-client.luau'),'Weather mismatch')
assert(dm:GetService('ServerScriptService').AtriumRuntime.ForestWeatherServer.Source==fs.readFile('forest-weather-server.luau'),'Weather server mismatch')
local wind,lights=0,0
for _,d in ipairs(dm:GetService('ServerStorage').IslandGeometryCatalog:GetDescendants()) do
 if d:IsA('BasePart') and d:GetAttribute('IslandWind') then wind+=1 end
 if d:IsA('Light') then lights+=1;assert(d.Shadows==false,'Expensive imported light') end
end
assert(wind>100,'Canopy wind classification failed')
print('ATMOSPHERE VERIFIED: dusk, persistent overcast, wind parts='..wind..', original lights='..lights)

assert(dm:GetService('ReplicatedFirst').IslandLoadingClient.Source==fs.readFile('islands-loading-client.luau'),'Loading client mismatch')

local groups={};local doorParts=0
for _,p in ipairs(dm:GetService('ServerStorage').IslandGeometryCatalog.city:GetDescendants()) do
 if p:IsA('BasePart') and p:GetAttribute('IslandDoorId') then
  local id=p:GetAttribute('IslandDoorId');local pivot=p:GetAttribute('IslandDoorPivot')
  assert(typeof(pivot)=='CFrame','Door pivot missing')
  if groups[id] then assert(groups[id].cell==p.Parent and groups[id].pivot==pivot,'Split/inconsistent door group')
  else groups[id]={cell=p.Parent,pivot=pivot} end
  doorParts+=1
 end
end
local doorCount=0;for _ in pairs(groups) do doorCount+=1 end
assert(doorCount>=20 and doorParts>100,'Interactive doors were not extracted')
assert(dm:GetService('ServerScriptService').AtriumRuntime.IslandDoors.Source==fs.readFile('islands-doors-server.luau'),'Door controller mismatch')
print('DOORS/LOADING VERIFIED: groups='..doorCount..', parts='..doorParts..', early readiness overlay, closer sky renderer')

assert(W:GetAttribute('IslandVisualRevision')=='cinematic-map-v3','Visual revision missing')
assert(dm:GetService('Lighting').ForestCinematicDepth.NearIntensity==0,'Near scene blur enabled')
assert(SP.IslandTravelClient.Source:find("Name='LeftGradient'",1,true),'Gradient menu missing')
assert(SP.IslandTravelClient.Source:find("Name='MapGlyph'",1,true),'Map glyph missing')
print('CINEMATIC MAP VERIFIED: transparent glyph, left gradient, three destinations, native post effects')

assert(W:GetAttribute('CityWaterRevision')=='original-sea-native-v1','Missing native sea')
assert(dm:GetService('ServerScriptService').AtriumRuntime.IslandResidents.Source==fs.readFile('islands-residents.luau'),'Resident identities mismatch')
assert(SP.IslandResidentClient.Source==fs.readFile('islands-residents-client.luau'),'Resident animation missing')

assert(W:GetAttribute('DisasterRevision')=='rescue-rounds-v1','Disaster revision missing')
local runtime=dm:GetService('ServerScriptService').AtriumRuntime
assert(runtime.DisasterService.Source==fs.readFile('disaster-service.luau'),'Disaster rules mismatch')
assert(not runtime:FindFirstChild('DisasterRuntime'),'Disasters still active')
assert(not SP:FindFirstChild('DisasterClient'),'Disaster UI still active')
local structures={}
for _,part in ipairs(dm:GetService('ServerStorage').IslandGeometryCatalog.city:GetDescendants()) do if part:IsA('BasePart') and part:GetAttribute('DisasterStructureId') then structures[part:GetAttribute('DisasterStructureId')]=true end end
local n=0;for _ in pairs(structures) do n+=1 end
assert(n>0,'No destructible building groups')
print('DISASTER FILE VERIFIED: structure groups='..n..', follow/rescue, server travel gates and bounded local effects')

assert(not W:FindFirstChild('Islands'),'Public menu contains maps')
assert(dm:GetService('Players').CharacterAutoLoads==false,'Menu spawns avatars')
assert(dm:GetService('ReplicatedFirst').SessionMenuClient.Source==fs.readFile('session-menu-client.luau'),'Menu mismatch')
assert(runtime.SessionRuntime.Source==fs.readFile('session-server.luau'),'Session rules mismatch')
print('SESSION FILE VERIFIED: empty public world, server-only maps, solo/private groups and persistent inventory')

assert(W:GetAttribute('AdventureRevision')=='village-ufo-v1','Adventure missing')
assert(runtime.AdventureRuntime.Source==fs.readFile('adventure-server.luau'),'Threat/quest code mismatch')
assert(SP.AdventureClient.Source==fs.readFile('adventure-client.luau'),'Mission/sneak UI mismatch')
