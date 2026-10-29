local fs=require('@lune/fs');local R=require('@lune/roblox')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-verified.rbxl'));local W=dm:GetService('Workspace')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-three-islands-v1' and W:GetAttribute('IslandWorldReady')==true,'Incomplete world')
assert(W.Terrain.Decoration==true and math.abs(W.Terrain.GrassLength-.85)<.001,'Native grass lost')
assert(not W:FindFirstChild('OvergrownAtrium'),'Old forest remains')
assert(#W.IslandDestinations:GetChildren()==3,'Missing spawns')
assert(not dm:GetService('ServerStorage'):FindFirstChild('IslandTerrainSnapshots'),'Redundant terrain snapshots remain')
local SP=dm:GetService('StarterPlayer').StarterPlayerScripts
assert(SP.IslandTravelClient.Source==fs.readFile('islands-travel-client.luau'),'Travel client mismatch')
assert(dm:GetService('ServerScriptService').AtriumRuntime.IslandTravelServer.Source==fs.readFile('islands-travel-server.luau'),'Travel server mismatch')
for _,d in ipairs(dm:GetService('ServerStorage').IslandGeometryCatalog:GetDescendants()) do assert(not d:IsA('LuaSourceContainer') and not d:IsA('Sound'),'Unsafe geometry') end
assert(W.StreamingMinRadius==64 and W.StreamingTargetRadius==128,'Wrong streaming')
print('ISLANDS VERIFIED: exact sources, native grass, three spawns, streaming, no old forest or imported scripts')
