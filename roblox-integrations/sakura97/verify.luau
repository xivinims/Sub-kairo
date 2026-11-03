assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Wrong place")
local RS=game:GetService("ReplicatedStorage")
local runtime=assert(RS:FindFirstChild("SweanRuntime"),"Missing runtime")
assert(runtime:GetAttribute("Version")==115,"Wrong runtime version")
assert(runtime:GetAttribute("LobbyAssetId")==852951140,"Wrong lobby asset")
local lobby=assert(workspace:FindFirstChild("JediLibrary"),"Jedi Library lobby missing")
assert(lobby:GetAttribute("SourceAssetId")==852951140,"Wrong Jedi Library source")
assert(not workspace:FindFirstChild("FloatingIsland"),"Old floating island still exists")
assert(not workspace:FindFirstChild("BigCenterTree"),"Old lobby tree still exists")
assert(not workspace:FindFirstChild("IslandRoads"),"Old island roads still exist")
assert(not workspace:FindFirstChild("FullIslandGrass"),"Old island grass still exists")
assert(not workspace:FindFirstChild("SkinnedGrassCoverage"),"Old skinned-grass controller still exists")
local mapParts=0
for _,d in ipairs(lobby:GetDescendants()) do
 assert(not d:IsA("LuaSourceContainer"),"Imported lobby script")
 if d:IsA("BasePart") then assert(d.Anchored,"Unanchored lobby part") mapParts+=1 end
end
assert(mapParts>0,"Lobby has no geometry")
local spawn=assert(workspace:FindFirstChild("IslandSpawn"),"Lobby spawn missing")
assert(spawn.Transparency==1 and spawn.Enabled and spawn.Neutral)
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={lobby}
local hit=workspace:Raycast(spawn.Position+Vector3.new(0,3,0),Vector3.new(0,-12,0),ray)
assert(hit,"Lobby spawn is not over Jedi Library geometry")
assert(game.ServerScriptService:FindFirstChild("IslandServer"))
assert(game.ServerScriptService:FindFirstChild("NametagService"))
assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("VoidSequence"))
assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("FriendPresence"))
assert(RS:FindFirstChild("SweanVoidEvent") and RS.SweanVoidEvent:IsA("RemoteEvent"))
for name,id in pairs({MenuClick=12221967,VoidMusic=110526913527016,FriendJoined=87437544236708,Regenerate=73292002268424}) do
 assert(RS.XNMedia[name].SoundId=="rbxassetid://"..id)
end
assert(runtime:GetAttribute("VoidThreshold")>workspace.FallenPartsDestroyHeight+100)
local cf,size=lobby:GetBoundingBox()
return {
 ok=true,
 fullMap=true,
 invisibleSpawn=true,
 version=116,
 mapParts=mapParts,
 lobbyAsset=852951140,
 lobbySize=tostring(size),
 spawnGrounded=true
}
