assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local payload=({...})[1].BinaryInput
print('ISLAND NATIVE INPUT',buffer.len(payload))
local bundle=game:GetService('SerializationService'):DeserializeInstancesAsync(payload)[1]
assert(bundle and bundle.Name=='StillHereIslandBundle','Invalid bundle')
print('ISLAND BUNDLE DESERIALIZED',#bundle:GetDescendants())
local W=workspace;local SSS=game:GetService('ServerScriptService');local SP=game:GetService('StarterPlayer').StarterPlayerScripts
for _,d in ipairs(SSS:GetDescendants()) do if d:IsA('Script') then d.Disabled=true end end
for _,c in ipairs(SSS:GetChildren()) do c:Destroy() end
for _,c in ipairs(SP:GetChildren()) do c:Destroy() end
for _,c in ipairs(game:GetService('ReplicatedStorage'):GetChildren()) do c:Destroy() end
for _,c in ipairs(game:GetService('StarterGui'):GetChildren()) do c:Destroy() end
for _,c in ipairs(game:GetService('ReplicatedFirst'):GetChildren()) do c:Destroy() end
for _,c in ipairs(W:GetChildren()) do if c~=W.Terrain and not c:IsA('Camera') then c:Destroy() end end
for k in pairs(W:GetAttributes()) do W:SetAttribute(k,nil) end
for k,v in pairs(bundle:GetAttributes()) do W:SetAttribute(k,v) end
bundle.Islands.Parent=W;bundle.IslandDestinations.Parent=W
bundle.IslandGeometryCatalog.Parent=game:GetService('ServerStorage')
bundle.IslandTerrainSnapshots.Parent=game:GetService('ServerStorage')
local remote=Instance.new('RemoteEvent');remote.Name='IslandTravel';remote.Parent=game:GetService('ReplicatedStorage')
local runtime=bundle.IslandRuntime;runtime.Name='AtriumRuntime'
local initializer=runtime:FindFirstChild('IslandInitializer');if initializer then initializer:Destroy() end
runtime.Parent=SSS
for _,c in ipairs(bundle.IslandClients:GetChildren()) do c.Parent=SP end
local L=game:GetService('Lighting');for _,c in ipairs(L:GetChildren()) do c:Destroy() end
for _,c in ipairs(bundle.IslandLighting:GetChildren()) do c.Parent=L end
bundle:Destroy()
local configured=pcall(function() W.StreamingMinRadius=64;W.StreamingTargetRadius=128 end)
W:SetAttribute('IslandStreamingTarget',configured and 128 or 192)
print('ISLAND STREAMING',configured,W:GetAttribute('IslandStreamingTarget'))
print('ISLAND TERRAIN INITIALIZATION START')
__FINALIZE__
print('ISLAND TERRAIN INITIALIZATION COMPLETE')
local validation=(function()
__VERIFY__
end)()
assert(validation,'Validation missing')
game:GetService('AssetService'):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return game:GetService('HttpService'):JSONEncode({ok=true,published=true,sourceVersion=game.PlaceVersion,build=W:GetAttribute('DeadSignalBuildId')})
