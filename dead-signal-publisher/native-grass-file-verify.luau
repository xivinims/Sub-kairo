local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local game=roblox.deserializePlace(fs.readFile("/tmp/still-here-verified.rbxl"))
local W=game:GetService("Workspace")
local t=W:FindFirstChildOfClass("Terrain")
assert(t.Decoration==true,"Published native grass disabled")
assert(math.abs(t.GrassLength-.85)<.001,"Published grass length incorrect")
local map=W.OvergrownAtrium
for _,m in ipairs(map.MeadowUnderstory:GetChildren()) do assert(m:GetAttribute("FoliageType")~="Grass","Grass model remains") end
assert(W:GetAttribute("DeadSignalBuildId")=="still-here-light-weather-v8","Wrong build")
print("PUBLISHED FILE VERIFIED: Terrain.Decoration=true; GrassLength=0.85; grassModels=0")

assert(W.StreamingMinRadius==64 and W.StreamingTargetRadius==192,"Streaming distances not saved")
assert(W.StreamOutBehavior==roblox.Enum.StreamOutBehavior.Opportunistic,"Stream out policy incorrect")
local SP=game:GetService("StarterPlayer").StarterPlayerScripts
assert(SP:FindFirstChild("ForestWindClient") and SP:FindFirstChild("ForestWeatherClient"),"Weather clients missing")
assert(SP.ForestWindClient:FindFirstChild("WindLines") and SP.ForestWindClient.WindShake:FindFirstChild("Octree"),"Wind modules missing")
assert(game:GetService("ServerScriptService").AtriumRuntime.ForestWeatherServer.Disabled==false,"Weather server disabled")
local sourceId=tonumber(W:GetAttribute("ForestWindAsset")) or 0
-- Existing numeric file attributes may round through Float32 serialization.
assert(math.abs(sourceId-11946229834)<512,"Wrong wind pack: "..tostring(sourceId))
print("PUBLISHED WEATHER VERIFIED: streaming=64/192; wind asset=11946229834; rain+lightning installed")
