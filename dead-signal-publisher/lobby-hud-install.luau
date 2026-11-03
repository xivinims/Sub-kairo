assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong experience')
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1','Wrong FPS base')
assert(#game.Players:GetPlayers()==0,'Patch must run in an isolated session')
local bundle=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
assert(bundle and bundle.Name=='LobbyHUDPatch','Wrong patch payload')
local RS=game.ReplicatedStorage
local runtime=game.ServerScriptService.FalloutRuntime
for _,entry in ipairs({
 {name='FalloutClient',parent=game.StarterPlayer.StarterPlayerScripts},
 {name='FalloutUI',parent=RS},
 {name='FalloutHealthUI',parent=RS},
 {name='FalloutCombatHUD',parent=RS},
}) do
 local source=assert(bundle:FindFirstChild(entry.name),'Missing patch object '..entry.name)
 local old=entry.parent:FindFirstChild(entry.name);if old then old:Destroy() end
 source.Parent=entry.parent
end
bundle:Destroy()
workspace:SetAttribute('FalloutCombatHUDRevision','reference-tactical-v1')
