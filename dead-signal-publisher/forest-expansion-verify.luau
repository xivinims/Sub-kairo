local W=workspace;assert(W:GetAttribute('ForestExpansionId')=='still-here-altar-botanical-v1' and W:GetAttribute('ForestExpansionReady')==true,'Expansion not finalized')
local E=W.ForestExpansion
assert(E.AltarSpawn.AltarArrival.Enabled and E.AltarSpawn.AltarArrival.Neutral,'Altar spawn disabled')
assert(W:GetAttribute('ForestPortDistance')>1200,'Port too close')
assert(#E.DemoBotanicalSelections:GetChildren()>100,'Flora selections missing')
local SSS=game:GetService('ServerScriptService');local SP=game:GetService('StarterPlayer').StarterPlayerScripts
assert(SSS.AtriumRuntime.ForestSpawnServer.Enabled and #SSS.AtriumRuntime.ForestSpawnServer.Source>500,'Name tags missing')
assert(SP.ForestSpawnClient.Enabled and SP.ForestSpawnClient.Source:find('ArrivalGlow'),'Spawn animation missing')
for _,d in ipairs(E:GetDescendants()) do assert(not d:IsA('LuaSourceContainer') and not d:IsA('Sound'),'External executable/audio found') end
return game:GetService('HttpService'):JSONEncode({ok=true,version=game.PlaceVersion,expansion=W:GetAttribute('ForestExpansionId'),portDistance=W:GetAttribute('ForestPortDistance'),botanical=#E.DemoBotanicalSelections:GetChildren(),altarParts=#E.AltarSpawn:GetDescendants(),portParts=#E.PortGloom_Wreck:GetDescendants(),nameTags=true,arrivalAnimation=true})
