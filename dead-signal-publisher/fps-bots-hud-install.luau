assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong game')
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1','Not the current FPS build')
assert(workspace:GetAttribute('FalloutCombatHUDRevision')=='reference-tactical-v1','HUD changed before patch')
assert(workspace:GetAttribute('FalloutOptionsVisualRevision')=='fps-gear-icon-settings-v2','Do not remove the gear settings fix')
assert(#game.Players:GetPlayers()==0,'NPC patch requires isolated execution')
local payload=({ ... })[1]
local bundle=game:GetService('SerializationService'):DeserializeInstancesAsync(payload.BinaryInput)[1]
assert(bundle and bundle.Name=='FPSCombatBotsPatch','Invalid FPS bot payload')
local RS=game:GetService('ReplicatedStorage')
local runtime=game.ServerScriptService.FalloutRuntime
assert(runtime.Server and runtime.OptionsStore and runtime.FrozenAvatar,'Existing server modules unavailable')
assert(RS.FalloutOptionsClient,'Must preserve settings client')
local updated=assert(bundle:FindFirstChild('CombatBots'))
local previous=runtime:FindFirstChild('CombatBots')
if previous then previous:Destroy() end
updated.Parent=runtime
local hud=assert(bundle:FindFirstChild('FalloutCombatHUD'))
local oldHUD=RS:FindFirstChild('FalloutCombatHUD')
if oldHUD then oldHUD:Destroy() end
hud.Parent=RS
game.StarterPlayer.StarterPlayerScripts.FalloutClient.Source=assert(bundle:FindFirstChild('FalloutClient')).Source
runtime.Server.Source=assert(bundle:FindFirstChild('Server')).Source
bundle:Destroy()
workspace:SetAttribute('FalloutCombatHUDRevision','reference-tactical-bots-v2')
workspace:SetAttribute('FalloutBotsBuild','training-bots-v1')
assert(protectedSnapshot()==beforeSnapshot,'Unrelated FPS content changed during bot HUD install')
