local W=workspace;local SS=game:GetService('ServerStorage');local H=game:GetService('HttpService')
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong game')
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-duvall-forest-v1' and W:GetAttribute('IslandWorldReady')==true,'Mansion not ready')
assert(W:GetAttribute('MansionSource')=='7902470429' and W:GetAttribute('ForestSource')=='13037825880','Wrong source assets')
assert(W:GetAttribute('MansionParts')>9000 and W:GetAttribute('MansionRoomCount')==15,'Incomplete mansion')
assert(W:GetAttribute('MansionDoors')>10,'Doors missing')
assert(W:GetAttribute('OrderlyTreeCount')>=20,'Original forest missing')
local runtime=game:GetService('ServerScriptService').AtriumRuntime
assert(runtime:FindFirstChild('CombatRuntime') and not runtime:FindFirstChild('AdventureRuntime') and not runtime:FindFirstChild('DisasterRuntime'),'Old game systems remain')
local floorParams=RaycastParams.new();floorParams.FilterType=Enum.RaycastFilterType.Include;floorParams.FilterDescendantsInstances={W.Terrain,W.Islands.mansion}
local spawn=W.IslandDestinations.forestCurrent
assert(W:Raycast(spawn.Position+Vector3.new(0,1,0),Vector3.new(0,-12,0),floorParams),'Spawn unsupported')
local appearance=require(runtime.ResidentAppearance)
for _,male in ipairs({true,false}) do
 local rig=appearance.Build({id='VisitorTest',name='Visitante',role='',male=male,hair=male and 62234425 or 62724852,shirt=144076436,pants=398633812,height=1,width=.8,skin=Color3.fromRGB(173,143,116)});rig:Destroy()
end
for _,d in ipairs(SS.MansionCatalog:GetDescendants()) do assert(not d:IsA('LuaSourceContainer'),'Foreign map code') end
assert(game:GetService('ReplicatedStorage').SkyBlackHoleTemplate:GetAttribute('SourceAsset')=='7208091524','Black hole missing')
local RS=game:GetService('ReplicatedStorage')
assert(RS.MansionOriginalUI:FindFirstChild('HUD') and RS.MansionOriginalUI:FindFirstChild('Screenspace_Vignette'),'Original mansion UI missing')
assert(RS.OriginalForestMonster:GetAttribute('SourceAsset')=='13037825880','Original forest monster missing')
assert(RS.CombatAssets.PlayerWeapons:FindFirstChild('M4A1'),'Mansion weapon missing')
assert(game:GetService('StarterPlayer').StarterPlayerScripts.OriginalMissionsLogicClient.Enabled,'Original mission script missing')
return H:JSONEncode({ok=true,build=W:GetAttribute('DeadSignalBuildId'),version=game.PlaceVersion,mansionParts=W:GetAttribute('MansionParts'),rooms=15,doors=W:GetAttribute('MansionDoors'),orderlyTrees=W:GetAttribute('OrderlyTreeCount'),spawn=tostring(spawn.Position),blackHole=true,oldGameplayRemoved=true})
