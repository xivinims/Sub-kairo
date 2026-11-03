local CP=game:GetService("ContentProvider")
local failures={} local ignored={} local completed=0
local optionalMissing={["rbxassetid://720367485"]=true,["720367485"]=true}
local ok,err=pcall(function()
 CP:PreloadAsync({workspace.JediLibrary,game.ReplicatedStorage.XNMedia},function(id,status)
  completed+=1
  if status~=Enum.AssetFetchStatus.Success then
   local key=tostring(id)
   if optionalMissing[key] or key:find("720367485",1,true) then ignored[#ignored+1]=key
   else failures[#failures+1]=key end
  end
 end)
end)
assert(ok,"Lobby preload failed: "..tostring(err))
assert(#failures==0,"Lobby contains unavailable content: "..table.concat(failures,", "))
return {ok=true,loaded=completed,ignoredOptional=ignored,lobbyAsset=852951140}
