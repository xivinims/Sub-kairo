local map=workspace:FindFirstChild("OvergrownAtrium")
local errors={}
local function check(v,m) if not v then table.insert(errors,m) end end
check(map~=nil,"Forest missing")
check(workspace:GetAttribute("ForestTrailCount")==0,"Trails remain")
check(#game:GetService("StarterGui"):GetChildren()==0,"UI remains")
check(#game:GetService("ReplicatedFirst"):GetChildren()==0,"Loading screen remains")
check(map and #map.Pines:GetChildren()>1900,"Trees missing")
check(map and #map.MeadowUnderstory:GetChildren()>80000,"Grass coverage missing")
return {ok=#errors==0,errors=errors,build=workspace:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,trees=map and #map.Pines:GetChildren(),plants=map and #map.MeadowUnderstory:GetChildren(),trails=workspace:GetAttribute("ForestTrailCount")}
