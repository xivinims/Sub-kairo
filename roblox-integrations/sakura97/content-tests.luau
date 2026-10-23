local CP=game:GetService("ContentProvider")
local failures={} local completed=0
local ok,err=pcall(function()
 CP:PreloadAsync({workspace.JediLibrary,game.ReplicatedStorage.XNMedia},function(id,status)
  completed+=1
  if status~=Enum.AssetFetchStatus.Success then failures[#failures+1]=id end
 end)
end)
assert(ok,"Lobby preload failed: "..tostring(err))
assert(#failures==0,"Lobby contains unavailable content: "..table.concat(failures,", "))
return {ok=true,loaded=completed,lobbyAsset=852951140}
