local CP=game:GetService("ContentProvider")
local failures={} local completed=0 local done=false
local pending=task.spawn(function()
 local ok,err=pcall(function()
  CP:PreloadAsync({workspace.FloatingIsland,workspace.BigCenterTree,workspace.IslandRoads,workspace.FullIslandGrass,game.ReplicatedStorage.GrassWindTemplate,game.Lighting},function(id,status)
   completed+=1 if status~=Enum.AssetFetchStatus.Success then failures[#failures+1]=id end
  end)
 end)
 if not ok then failures[#failures+1]=tostring(err) end
 done=true
end)
local deadline=os.clock()+60
while not done and os.clock()<deadline do task.wait(.1) end
if not done then pcall(task.cancel,pending) end
assert(done,"Map preload timed out before publication")
assert(#failures==0,"Map contains unavailable content: "..table.concat(failures,", "))
return {ok=true,loaded=completed}
