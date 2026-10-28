local W=workspace
local errors={}
local function check(ok,msg) if not ok then table.insert(errors,msg) end end
local map=W:FindFirstChild("OvergrownAtrium")
if not map then return {ok=false,errors={"Forest missing"}} end
check(map:GetAttribute("Environment")=="PineForest","Wrong map")
check(W:GetAttribute("ForestMapSize")==2048,"Forest bounds changed unexpectedly")
check(W:GetAttribute("ForestTrailCount")==3,"Missing winding trails")
check(#map.Pines:GetChildren()>=1900,"Forest canopy is too sparse")
check(#map.MeadowUnderstory:GetChildren()>=3500,"Forest understory is too sparse")
check(#map.StoneAndDeadfall:GetChildren()>=180,"Missing ground-level forest details")
check(map:FindFirstChild("Doors")~=nil,"Legacy runtime door folder missing")

local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={W.Terrain}
local checkpoints={}
for _,p in ipairs(map.RouteMarkers:GetChildren()) do
 local hit=W:Raycast(p.Position,Vector3.new(0,-9,0),params)
 checkpoints[p.Name]=hit~=nil and (hit.Material==Enum.Material.Grass or hit.Material==Enum.Material.Ground or hit.Material==Enum.Material.LeafyGrass)
 check(checkpoints[p.Name],"Checkpoint without terrain "..p.Name.." pos="..tostring(p.Position).." hit="..tostring(hit and hit.Material))
 local overlap=OverlapParams.new();overlap.RespectCanCollide=true
 check(#W:GetPartBoundsInBox(CFrame.new(p.Position),Vector3.new(3,4,3),overlap)==0,"Spawn or checkpoint intersects object "..p.Name)
end
for _,name in ipairs({"Start","Garden","Floor1","Floor2","Floor3","VaultedHall","HaloChamber","GlassChapel","CreekBend","RidgeLookout","MeadowRest"}) do
 check(checkpoints[name]==true,"Missing authored forest marker "..name)
end

local navigation={}
local pathService=game:GetService("PathfindingService")
for _,name in ipairs({"Garden","Floor1","Floor2","Floor3"}) do
 local path=pathService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=6})
 path:ComputeAsync(map.RouteMarkers.Start.Position,map.RouteMarkers[name].Position)
 navigation[name]=path.Status==Enum.PathStatus.Success
 check(navigation[name],"Unreachable forest route "..name)
end

local trees,treeColliders=0,0
for _,tree in ipairs(map.Pines:GetChildren()) do
 trees+=1
 local collider=tree:FindFirstChild("TreeCollisionTrunk")
 if collider and collider:IsA("BasePart") and collider.CanCollide and collider.Transparency==1 then treeColliders+=1 end
 if trees%17==0 then
  local box,size=tree:GetBoundingBox()
  local bottom=box.Position.Y-size.Y*.5
  local hit=W:Raycast(Vector3.new(box.Position.X,bottom+1.5,box.Position.Z),Vector3.new(0,-5,0),params)
  check(hit~=nil,"Floating tree geometry "..tree.Name)
 end
end
check(treeColliders==trees,"Tree collision trunk missing")

local parts=0
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("BasePart") then parts+=1;check(d.Anchored,"Unanchored forest part") end
 check(not d:IsA("LuaSourceContainer"),"External map script")
end
check(parts<42000,"Forest geometry exceeded authored detail budget")

local L=game:GetService("Lighting");local fog=L:FindFirstChild("ForestAerialPerspective")
check(fog and math.abs(fog.Density-.29)<.001,"Forest atmosphere missing")
check(L:FindFirstChild("ForestGoldenGrade")~=nil,"Warm forest grade missing")
check(L:FindFirstChild("ForestCanopyRays")~=nil,"Sunlight rays missing")
check(W.Terrain:FindFirstChild("WoodlandCloudDeck")~=nil,"Forest cloud deck missing")
local RS=game:GetService("ReplicatedStorage")
check(require(RS.AtriumSettings).Defaults.fov==65,"Reference FOV missing")
check(game:GetService("StarterPlayer").CameraMode==Enum.CameraMode.Classic,"Camera locked")
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("AtriumClient")~=nil,"Client missing")
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("ForestWeatherClient")~=nil,"Local rain and lightning missing")
local runtime=game:GetService("ServerScriptService"):FindFirstChild("AtriumRuntime")
check(runtime and runtime:FindFirstChild("AtriumServer")~=nil,"Server missing")
check(runtime and runtime:FindFirstChild("ForestWeatherServer")~=nil,"Weather cycle missing")
check(W:GetAttribute("DeadSignalBuildId")=="dead-signal-golden-forest-v3","Build mismatch")
local grassAvailable,grass=pcall(function() return W.Terrain.Decoration end)
return {
 ok=#errors==0,errors=errors,build=W:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,
 parts=parts,trees=trees,treeColliders=treeColliders,understory=#map.MeadowUnderstory:GetChildren(),
 flowers=W:GetAttribute("ForestFlowers"),ferns=W:GetAttribute("ForestFerns"),rocks=W:GetAttribute("ForestRockClusters"),
 logs=W:GetAttribute("ForestDeadfallLogs"),stumps=W:GetAttribute("ForestStumps"),branches=W:GetAttribute("ForestBranches"),
 trails=3,checkpoints=checkpoints,navigation=navigation,density=fog and fog.Density,
 defaultFOV=65,terrainGrass=grassAvailable and grass or false,
 streaming=W.StreamingEnabled,mapSize=W:GetAttribute("ForestMapSize")
}
