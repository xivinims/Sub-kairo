local fs=require('@lune/fs');local R=require('@lune/roblox')
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-verified.rbxl'));local W=dm:GetService('Workspace');local SS=dm:GetService('ServerStorage')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-duvall-forest-v1','Wrong downloaded build')
assert(W:GetAttribute('MansionSource')=='7902470429' and W:GetAttribute('ForestSource')=='13037825880','Source mismatch')
assert(not W:FindFirstChild('Islands') and SS.MatchWorld.Islands.mansion,'Menu contains map or match data lost')
assert(W.StreamingEnabled and W.StreamingTargetRadius==128,'Streaming mismatch')
local count=0;for _,p in ipairs(SS.MansionCatalog:GetDescendants()) do if p:IsA('BasePart') then count+=1 end;assert(not p:IsA('LuaSourceContainer'),'Foreign scene code') end
assert(count>9000,'Mansion incomplete')
local runtime=dm:GetService('ServerScriptService').AtriumRuntime
assert(runtime.MansionRuntime.Source==fs.readFile('mansion-runtime.luau'),'Mansion runtime mismatch')
assert(runtime.MansionChunks.Source==fs.readFile('mansion-chunks.luau'),'Indoor streaming mismatch')
assert(not runtime:FindFirstChild('CombatRuntime') and not runtime:FindFirstChild('AdventureRuntime'),'Previous game remains')
local SP=dm:GetService('StarterPlayer').StarterPlayerScripts
assert(SP.MansionClient.Source==fs.readFile('mansion-client.luau'),'Camera/event client mismatch')
assert(SP.SkyBlackHoleClient.Source==fs.readFile('blackhole-client.luau'),'Sky source mismatch')
local n=0;for _,d in ipairs(dm:GetDescendants()) do if d:IsA('Terrain') then n+=1;assert(d.Parent==W,'Nested terrain') end end;assert(n==1,'Duplicate terrain')
print('MANSION EXACT FILE VERIFIED: full mansion sources, Orderly forest template, indoor distance culling, one visitor runtime, distant black hole and clean public menu')
