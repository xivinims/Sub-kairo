local StarterPlayer=game:GetService("StarterPlayer")
local ServerScriptService=game:GetService("ServerScriptService")
local out={placeVersion=game.PlaceVersion,starter={},server={},workspace={}}
for _,x in ipairs(StarterPlayer.StarterPlayerScripts:GetChildren())do table.insert(out.starter,{name=x.Name,class=x.ClassName})end
for _,x in ipairs(ServerScriptService:GetChildren())do table.insert(out.server,{name=x.Name,class=x.ClassName})end
for _,x in ipairs(workspace:GetChildren())do table.insert(out.workspace,{name=x.Name,class=x.ClassName})end
return out