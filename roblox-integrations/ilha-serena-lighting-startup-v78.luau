assert(game.GameId==9421311218 and game.PlaceId==118064584465155)
assert(game.PlaceVersion==77,"place changed")
local world=assert(workspace:FindFirstChild("IlhaSerena"))
local server=game.ServerScriptService.SerenaAmbienceServer
local client=game.StarterPlayer.StarterPlayerScripts.SerenaAmbienceClient
local bootstrap="\n-- Rendering defaults are reapplied every game startup.\nLighting.LightingStyle=Enum.LightingStyle.Realistic\nLighting.PrioritizeLightingQuality=true"
for _,s in ipairs({server,client}) do
 local text=s.Source
 local needle='local Lighting=game:GetService("Lighting")'
 assert(text:find(needle,1,true))
 local a,b=text:find(needle,1,true)
 s.Source=text:sub(1,b)..bootstrap..text:sub(b+1)
 local m=Instance.new("ModuleScript") m.Source="return function()\n"..s.Source.."\nend" m.Parent=game.ServerStorage
 local ok,fn=pcall(require,m) m:Destroy() assert(ok and type(fn)=="function",s.Name)
end
-- Exercise the exact initialization operations in the engine.
local before=tostring(game.Lighting.LightingStyle)
game.Lighting.LightingStyle=Enum.LightingStyle.Realistic
game.Lighting.PrioritizeLightingQuality=true
assert(game.Lighting.LightingStyle==Enum.LightingStyle.Realistic and game.Lighting.PrioritizeLightingQuality)
world:SetAttribute("RenderingBootstrap",1)
game:GetService("AssetService"):SavePlaceAsync()
return {ok=true,saved=true,sourceVersion=game.PlaceVersion,before=before,rendering="Realistic",bootstrap="server + client"}
