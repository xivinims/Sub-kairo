assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local W=workspace;local E=W:WaitForChild('ForestExpansion');local map=W.OvergrownAtrium
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={W.Terrain}
local function ground(x,z)
 local hit=W:Raycast(Vector3.new(x,250,z),Vector3.new(0,-400,0),params)
 assert(hit,'Terrain missing below new geometry');return hit.Position.Y
end
local altar=E.AltarSpawn;local ac,as=altar:GetBoundingBox()
local bottom=ac.Y-as.Y/2;local ay=ground(ac.X,ac.Z)
altar:PivotTo(altar:GetPivot()+Vector3.new(0,ay-.35-bottom,0))
local spawn=altar.AltarArrival
local ap=RaycastParams.new();ap.FilterType=Enum.RaycastFilterType.Include;ap.FilterDescendantsInstances={altar}
spawn.CanQuery=false
local floor=W:Raycast(spawn.Position+Vector3.new(0,1,0),Vector3.new(0,-12,0),ap)
assert(floor,'Altar arrival has no floor')
spawn.CFrame=CFrame.lookAt(Vector3.new(spawn.Position.X,floor.Position.Y+.12,spawn.Position.Z),Vector3.new(spawn.Position.X,floor.Position.Y+.12,spawn.Position.Z-10))
local ceiling=W:Raycast(spawn.Position+Vector3.new(0,.3,0),Vector3.new(0,6,0),ap)
assert(not ceiling,'Altar arrival obstructed overhead')
for _,m in ipairs(E.DemoBotanicalSelections:GetChildren()) do
 local cf,s=m:GetBoundingBox();local y=ground(cf.X,cf.Z)
 m:PivotTo(m:GetPivot()+Vector3.new(0,y+.02-(cf.Y-s.Y/2),0));m:SetAttribute('GroundAtFinalize',nil)
end
local port=E.PortGloom_Wreck;local pc,ps=port:GetBoundingBox()
local y=ground(pc.X,pc.Z);port:PivotTo(port:GetPivot()+Vector3.new(0,y-.35-(pc.Y-ps.Y/2),0))
port:SetAttribute('GroundAtFinalize',nil)
local newc,news=port:GetBoundingBox()
local removed=0
for _,folder in ipairs({map.Pines,map.MeadowUnderstory}) do for _,m in ipairs(folder:GetChildren()) do
 local cf=m:GetBoundingBox()
 if math.abs(cf.X-newc.X)<news.X/2+5 and math.abs(cf.Z-newc.Z)<news.Z/2+5 then m:Destroy();removed+=1 end
end end
local distance=(spawn.Position-newc.Position).Magnitude
assert(distance>1200,'Port selection too close to arrival')
for _,d in ipairs(E:GetDescendants()) do assert(not d:IsA('LuaSourceContainer') and not d:IsA('Sound'),'Third-party runtime content found') end
local spawns=0
for _,d in ipairs(W:GetDescendants()) do if d:IsA('SpawnLocation') and d.Enabled then spawns+=1;assert(d==spawn,'Unexpected spawn') end end
assert(spawns==1,'Spawn count incorrect')
assert(game:GetService('StarterGui'):GetChildren()[1]==nil,'Menu unexpectedly present')
W:SetAttribute('ForestTreeCount',#map.Pines:GetChildren())
W:SetAttribute('ForestPortDistance',math.floor(distance))
W:SetAttribute('ForestExpansionReady',true)
game:GetService('AssetService'):SavePlaceAsync({PlaceId=game.PlaceId,SaveWithoutPublish=false})
return game:GetService('HttpService'):JSONEncode({saved=true,sourceVersion=game.PlaceVersion,expansion=W:GetAttribute('ForestExpansionId'),portDistance=distance,removedOverlap=removed,botanical=#E.DemoBotanicalSelections:GetChildren(),spawnFloor=floor.Instance.Name})
