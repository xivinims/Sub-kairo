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
