assert(game.PlaceId==118064584465155 and game.GameId==9421311218,'Wrong target')
assert(workspace:GetAttribute('DeadSignalBuildId')=='fallout-5v5-v1','Unexpected base game')
assert(#game.Players:GetPlayers()==0,'Patch must run in an isolated session')
local before=protectedSnapshot()
local bundle=game:GetService('SerializationService'):DeserializeInstancesAsync(({...})[1].BinaryInput)[1]
assert(bundle.Name=='NametagPatch')
local runtime=game.ServerScriptService:WaitForChild('FalloutRuntime')
runtime.Profiles.Source=bundle.Profiles.Source
bundle.Profiles:Destroy()
for _,name in ipairs({'Progress','Nametags','NametagController'}) do
 local old=runtime:FindFirstChild(name);if old then old:Destroy() end
 local item=assert(bundle:FindFirstChild(name));item.Parent=runtime
end
local oldTemplate=game.ServerStorage:FindFirstChild('FalloutNametagTemplate');if oldTemplate then oldTemplate:Destroy() end
bundle.FalloutNametagTemplate.Parent=game.ServerStorage
bundle:Destroy()
workspace:SetAttribute('FalloutNametagBuild','nametags-v1')
assert(protectedSnapshot()==before,'Unrelated game content changed')
