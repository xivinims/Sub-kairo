assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong Roblox game')
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1','Wrong FPS project')
assert(workspace:GetAttribute('FalloutCombatHUDRevision')=='reference-tactical-bots-v2','FPS has changed, refuse unsafe restore')
assert(workspace:GetAttribute('FalloutBotsBuild')=='training-bots-match-only-v2','Bot build changed, refuse unsafe restore')
assert(#game.Players:GetPlayers()==0,'GUI restore requires an isolated Roblox session')
local incoming=({ ... })[1]
assert(incoming and incoming.BinaryInput,'Original GUI patch bundle missing')
local bundle=game:GetService('SerializationService'):DeserializeInstancesAsync(incoming.BinaryInput)[1]
assert(bundle and bundle.Name=='OriginalFPSRestore','Incorrect original FPS bundle')
local RS=game:GetService('ReplicatedStorage')
local runtime=game.ServerScriptService.FalloutRuntime
local playerScripts=game.StarterPlayer.StarterPlayerScripts
local targets={
 {name='FalloutClient',parent=playerScripts},
 {name='FalloutUI',parent=RS},
 {name='Server',parent=runtime},
}
for _,entry in ipairs(targets) do
 local source=assert(bundle:FindFirstChild(entry.name),'Missing original source '..entry.name)
 local target=assert(entry.parent:FindFirstChild(entry.name),'Missing existing FPS script '..entry.name)
 assert(source:IsA('LuaSourceContainer') and target:IsA('LuaSourceContainer'))
 target.Source=source.Source
end
bundle:Destroy()
local unused=runtime:FindFirstChild('CombatBots')
if unused then unused:Destroy() end
local unusedHUD=RS:FindFirstChild('FalloutCombatHUD')
if unusedHUD then unusedHUD:Destroy() end
workspace:SetAttribute('FalloutCombatHUDRevision','original-fps-v1')
workspace:SetAttribute('FalloutBotsBuild','disabled-original-fps')
assert(protectedSnapshot()==beforeSnapshot,'Unexpected world, inventory, NPC or map modification')
