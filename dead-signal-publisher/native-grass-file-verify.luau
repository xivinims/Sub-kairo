local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local game=roblox.deserializePlace(fs.readFile("/tmp/still-here-verified.rbxl"))
local W=game:GetService("Workspace")
local t=W:FindFirstChildOfClass("Terrain")
assert(t.Decoration==true,"Published native grass disabled")
assert(math.abs(t.GrassLength-.85)<.001,"Published grass length incorrect")
local map=W.OvergrownAtrium
for _,m in ipairs(map.MeadowUnderstory:GetChildren()) do assert(m:GetAttribute("FoliageType")~="Grass","Grass model remains") end
assert(W:GetAttribute("DeadSignalBuildId")=="still-here-native-grass-v7","Wrong build")
print("PUBLISHED FILE VERIFIED: Terrain.Decoration=true; GrassLength=0.85; grassModels=0")
