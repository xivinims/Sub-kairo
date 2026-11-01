assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong Roblox experience')
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1','Not the active FPS game')
assert(workspace:GetAttribute('FalloutCombatHUDRevision')=='reference-tactical-bots-v2','Match HUD must not change')
assert(workspace:GetAttribute('FalloutBotsBuild')=='training-bots-v1','Previous bots release changed')
assert(workspace:GetAttribute('FalloutOptionsVisualRevision')=='fps-gear-icon-settings-v2','Keep gear settings intact')
assert(#game.Players:GetPlayers()==0,'Install requires isolated Roblox session')
local RS=game:GetService('ReplicatedStorage')
local runtime=game.ServerScriptService.FalloutRuntime
local playerScripts=game.StarterPlayer.StarterPlayerScripts
local previousHUDHash=sourceHash(RS.FalloutCombatHUD.Source)
local previousSettingsHash=sourceHash(RS.FalloutOptionsClient.Source)
local bundle=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
assert(bundle and bundle.Name=='MatchBotsPatch','Invalid match bot bundle')
for _,entry in ipairs({
 {name='CombatBots',parent=runtime},
 {name='Server',parent=runtime},
 {name='FalloutClient',parent=playerScripts}
}) do
 local source=assert(bundle:FindFirstChild(entry.name),'Missing required source '..entry.name)
 local existing=assert(entry.parent:FindFirstChild(entry.name),'Missing active game component '..entry.name)
 assert(source:IsA('LuaSourceContainer') and existing:IsA('LuaSourceContainer'))
 existing.Source=source.Source
end
bundle:Destroy()
workspace:SetAttribute('FalloutBotsBuild','training-bots-match-only-v2')
assert(sourceHash(RS.FalloutCombatHUD.Source)==previousHUDHash,'The reference combat HUD changed')
assert(sourceHash(RS.FalloutOptionsClient.Source)==previousSettingsHash,'The settings GUI changed')
assert(protectedSnapshot()==beforeSnapshot,'Unrelated Roblox game assets changed')
