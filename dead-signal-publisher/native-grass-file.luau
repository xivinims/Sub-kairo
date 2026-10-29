local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local luau=require("@lune/luau")
local game=roblox.deserializePlace(fs.readFile("/tmp/still-here-source.rbxl"))
local W=game:GetService("Workspace")
local terrain=W:FindFirstChildOfClass("Terrain")
assert(terrain,"Terrain missing")
terrain.Decoration=true
terrain.GrassLength=.85
W.StreamingEnabled=true;W.StreamingMinRadius=64;W.StreamingTargetRadius=192
W.StreamOutBehavior=roblox.Enum.StreamOutBehavior.Opportunistic
W.ModelStreamingBehavior=roblox.Enum.ModelStreamingBehavior.Improved
W.StreamingIntegrityMode=roblox.Enum.StreamingIntegrityMode.PauseOutsideLoadedArea
W.GlobalWind=roblox.Vector3.new(4,0,1.2)
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
local SSS=game:GetService("ServerScriptService")
local runtime=SSS:FindFirstChild("AtriumRuntime")
assert(runtime,"Runtime missing")
local SP=game:GetService("StarterPlayer").StarterPlayerScripts
local function scriptFile(parent,name,class,file)
 local old=parent:FindFirstChild(name);if old then old:Destroy() end
 local source=fs.readFile(file)
 luau.load(source,{debugName=file})
 local inst=roblox.Instance.new(class);inst.Name=name;inst.Source=source;inst.Parent=parent
 if class=="Script" then inst.Disabled=false end
 return inst
end
scriptFile(runtime,"ForestWeatherServer","Script","forest-weather-server.luau")
scriptFile(SP,"ForestWeatherClient","LocalScript","forest-weather-client.luau")
local wind=scriptFile(SP,"ForestWindClient","LocalScript","forest-wind-client.luau")
scriptFile(wind,"WindLines","ModuleScript","vendor/wind/WindLines.luau")
local shake=scriptFile(wind,"WindShake","ModuleScript","vendor/wind/WindShake.luau")
scriptFile(shake,"Settings","ModuleScript","vendor/wind/Settings.luau")
local octree=scriptFile(shake,"Octree","ModuleScript","vendor/wind/Octree.luau")
scriptFile(octree,"OctreeNode","ModuleScript","vendor/wind/OctreeNode.luau")
scriptFile(octree,"OctreeRegionUtils","ModuleScript","vendor/wind/OctreeRegionUtils.luau")
W:SetAttribute("ForestWindAsset",11946229834)
W:SetAttribute("ForestWeather","Clear")
W:SetAttribute("DeadSignalBuildId","still-here-light-weather-v8")
W:SetAttribute("ForestNativeGrass",true)
W:SetAttribute("ForestGrassClusters",0)
W:SetAttribute("ForestGrassModelCount",0)
fs.writeFile("/tmp/still-here-native.rbxl",roblox.serializePlace(game))
local check=roblox.deserializePlace(fs.readFile("/tmp/still-here-native.rbxl"))
local ct=check:GetService("Workspace"):FindFirstChildOfClass("Terrain")
assert(ct.Decoration==true and math.abs(ct.GrassLength-.85)<.001,"Native grass not serialized")
print("Native grass serialized; models removed="..removed.."; trees="..#map.Pines:GetChildren())
