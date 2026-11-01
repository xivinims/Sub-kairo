assert(game.PlaceId==118064584465155 and game.GameId==9421311218,'Wrong target')
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1')
assert(workspace:GetAttribute('FalloutNametagBuild')=='nametags-v1')
assert(#game.Players:GetPlayers()==0,'Patch must be isolated')
local before=protectedSnapshot()
local bundle=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
assert(bundle.Name=='HUDFixPatch')
local runtime=game.ServerScriptService.FalloutRuntime
runtime.Profiles.Source=bundle.Profiles.Source
runtime.Server.Source=bundle.Server.Source
game.StarterPlayer.StarterPlayerScripts.FalloutClient.Source=bundle.FalloutClient.Source
for _,entry in ipairs({{name='FalloutUI',parent=game.ReplicatedStorage},{name='LobbyHealthTemplate',parent=game.ReplicatedStorage},{name='FrozenAvatar',parent=runtime},{name='OptionsStore',parent=runtime},{name='FalloutOptionsClient',parent=game.ReplicatedStorage},{name='ShopkeeperLayout',parent=runtime}}) do
 local old=entry.parent:FindFirstChild(entry.name);if old then old:Destroy() end
 bundle[entry.name].Parent=entry.parent
end
bundle:Destroy()
require(runtime.ShopkeeperLayout).refresh()
game.ReplicatedStorage.FalloutItemVisuals:SetAttribute('UseReliableIcons',nil)
workspace:SetAttribute('FalloutViewportRevision','weapon-clones-v1')
workspace:SetAttribute('FalloutHUDRevision','fps-left-options-v4')
assert(protectedSnapshot()==before,'Unrelated game content changed')
