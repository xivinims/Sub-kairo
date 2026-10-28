local W=workspace
local errors={}
local function check(ok,msg) if not ok then table.insert(errors,msg) end end
local map=W:FindFirstChild("OvergrownAtrium")
if not map then return {ok=false,errors={"Forest missing"}} end
check(map:GetAttribute("Environment")=="PineForest","Wrong map")
check(#map.Pines:GetChildren()>=100,"Insufficient trees")
check(W:GetAttribute("ForestTrailCount")==3,"Missing trail loops")
local params=RaycastParams.new();params.RespectCanCollide=true
local checkpoints={}
for _,p in ipairs(map.RouteMarkers:GetChildren()) do
 local hit=W:Raycast(p.Position,Vector3.new(0,-9,0),params)
 checkpoints[p.Name]=hit and hit.Instance==W.Terrain or false
 check(checkpoints[p.Name],"Checkpoint without terrain "..p.Name)
 local overlap=OverlapParams.new();overlap.RespectCanCollide=true
 check(#W:GetPartBoundsInBox(CFrame.new(p.Position),Vector3.new(3,4,3),overlap)==0,"Spawn or checkpoint intersects object "..p.Name)
end
local navigation={}
local pathService=game:GetService("PathfindingService")
for _,name in ipairs({"Garden","Floor1","Floor2","Floor3"}) do
 local path=pathService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=6})
 path:ComputeAsync(map.RouteMarkers.Start.Position,map.RouteMarkers[name].Position)
 navigation[name]=path.Status==Enum.PathStatus.Success;check(navigation[name],"Unreachable forest route "..name)
end
local parts=0
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("BasePart") then parts+=1;check(d.Anchored,"Unanchored forest part") end
 check(not d:IsA("LuaSourceContainer"),"External map script")
end
check(parts<8500,"Forest geometry over budget")
local L=game:GetService("Lighting");local fog=L:FindFirstChild("ForestAerialPerspective")
check(fog and math.abs(fog.Density-.33)<.001,"Forest atmosphere missing")
local RS=game:GetService("ReplicatedStorage")
check(require(RS.AtriumSettings).Defaults.fov==65,"Reference FOV missing")
check(game:GetService("StarterPlayer").CameraMode==Enum.CameraMode.Classic,"Camera locked")
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("AtriumClient")~=nil,"Client missing")
check(game:GetService("ServerScriptService").AtriumRuntime:FindFirstChild("AtriumServer")~=nil,"Server missing")
check(W:GetAttribute("DeadSignalBuildId")=="dead-signal-pine-trails-v1","Build mismatch")
return {ok=#errors==0,errors=errors,build=W:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,parts=parts,trees=#map.Pines:GetChildren(),trails=3,checkpoints=checkpoints,navigation=navigation,density=fog and fog.Density,defaultFOV=65,terrainGrass=W.Terrain.Decoration}
