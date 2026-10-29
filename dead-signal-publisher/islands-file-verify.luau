local fs=require('@lune/fs');local R=require('@lune/roblox')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-verified.rbxl'));local W=dm:GetService('Workspace')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-three-islands-v1','Wrong world')
assert(W.Terrain.Decoration==true and math.abs(W.Terrain.GrassLength-.85)<.001,'Native grass lost')
assert(not W:FindFirstChild('OvergrownAtrium'),'Old forest remains')
assert(#W.IslandDestinations:GetChildren()==3,'Missing spawns')
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

assert(W:GetAttribute('IslandAtmosphereRevision')=='storm-dusk-v1','Atmosphere missing')
assert(dm:GetService('Lighting').ClockTime>17.5,'Dusk not applied')
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
