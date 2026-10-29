local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local game=roblox.deserializePlace(fs.readFile("/tmp/still-here-source.rbxl"))
local W=game:GetService("Workspace")
local terrain=W:FindFirstChildOfClass("Terrain")
assert(terrain,"Terrain missing")
terrain.Decoration=true
terrain.GrassLength=.85
local map=W:FindFirstChild("OvergrownAtrium")
assert(map and #map.Pines:GetChildren()>1900,"Unexpected source map")
local removed=0
for _,m in ipairs(map.MeadowUnderstory:GetChildren()) do
 if m:GetAttribute("FoliageType")=="Grass" then m:Destroy();removed+=1 end
end
local C=roblox.Color3
local L=game:GetService("Lighting")
local fog=L:FindFirstChild("ForestAerialPerspective")
assert(fog,"Forest atmosphere missing")
fog.Density=.22;fog.Offset=.08;fog.Haze=1.3;fog.Glare=.15
fog.Color=C.fromRGB(242,233,207);fog.Decay=C.fromRGB(235,222,185)
L.FogColor=C.fromRGB(235,222,190);L.FogStart=250;L.FogEnd=2200
L.ClockTime=15.2;L.Brightness=2.7;L.Ambient=C.fromRGB(142,143,117)
L.OutdoorAmbient=C.fromRGB(173,174,141);L.ExposureCompensation=.12
local grade=L:FindFirstChild("ForestGoldenGrade")
if grade then grade.Contrast=.025;grade.Saturation=.015;grade.TintColor=C.fromRGB(255,250,235) end
if not L:FindFirstChildOfClass("Sky") then
 local sky=roblox.Instance.new("Sky");sky.Name="MeadowSky";sky.Parent=L
end
W:SetAttribute("DeadSignalBuildId","still-here-native-grass-v7")
W:SetAttribute("ForestNativeGrass",true)
W:SetAttribute("ForestGrassClusters",0)
W:SetAttribute("ForestGrassModelCount",0)
fs.writeFile("/tmp/still-here-native.rbxl",roblox.serializePlace(game))
local check=roblox.deserializePlace(fs.readFile("/tmp/still-here-native.rbxl"))
local ct=check:GetService("Workspace"):FindFirstChildOfClass("Terrain")
assert(ct.Decoration==true and math.abs(ct.GrassLength-.85)<.001,"Native grass not serialized")
print("Native grass serialized; models removed="..removed.."; trees="..#map.Pines:GetChildren())
