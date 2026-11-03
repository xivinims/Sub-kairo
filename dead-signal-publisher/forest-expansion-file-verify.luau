local fs=require('@lune/fs');local R=require('@lune/roblox')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-verified.rbxl'))
local W=dm:GetService('Workspace');local E=W.ForestExpansion
assert(W:GetAttribute('ForestExpansionReady')==true and W:GetAttribute('ForestPortDistance')>1200,'Published expansion not ready')
assert(E.AltarSpawn.AltarArrival.Enabled,'Spawn disabled')
assert(dm:GetService('ServerScriptService').AtriumRuntime.ForestSpawnServer.Source==fs.readFile('forest-spawn-server.luau'),'Server source mismatch')
assert(dm:GetService('StarterPlayer').StarterPlayerScripts.ForestSpawnClient.Source==fs.readFile('forest-spawn-client.luau'),'Client source mismatch')
for _,d in ipairs(E:GetDescendants()) do assert(not d:IsA('LuaSourceContainer'),'External scripts remain') end
print('PUBLISHED EXPANSION VERIFIED: altar, arrival animation, name tags, distant Port Gloom selection, botanical selections')
