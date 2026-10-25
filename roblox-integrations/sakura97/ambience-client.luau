local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain

-- Fixed Suvivers atmosphere: warm, dirty dusk with restrained haze.
-- There are intentionally no player-facing environment/visual sliders.
Lighting.ClockTime=17.35
Lighting.Brightness=2.15
Lighting.Ambient=Color3.fromRGB(78,67,61)
Lighting.OutdoorAmbient=Color3.fromRGB(118,96,78)
Lighting.ColorShift_Top=Color3.fromRGB(34,18,8)
Lighting.ColorShift_Bottom=Color3.fromRGB(8,8,10)
Lighting.ExposureCompensation=-.18
Lighting.GlobalShadows=true
Lighting.ShadowSoftness=.28
Lighting.EnvironmentDiffuseScale=.28
Lighting.EnvironmentSpecularScale=.72
Lighting.FogColor=Color3.fromRGB(125,111,95)
Lighting.FogStart=35
Lighting.FogEnd=520
pcall(function() Lighting.Technology=Enum.Technology.Future end)

for _,name in ipairs({"SuviversArenaGrade","SuviversArenaRays","SuviversArenaDOF","SuviversAtmosphere","ViolenceDistrictBloom"}) do
 local old=Lighting:FindFirstChild(name)
 if old then old:Destroy() end
end
for _,obj in ipairs(Lighting:GetChildren()) do
 if obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") then
  obj.Enabled=false
 end
end

local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="SuviversAtmosphere"
atmosphere.Density=.24
atmosphere.Offset=.08
atmosphere.Color=Color3.fromRGB(184,164,138)
atmosphere.Decay=Color3.fromRGB(86,72,65)
atmosphere.Glare=.04
atmosphere.Haze=1.35
atmosphere.Parent=Lighting

local grade=Instance.new("ColorCorrectionEffect")
grade.Name="SuviversArenaGrade"
grade.Brightness=-.025
grade.Contrast=.12
grade.Saturation=-.20
grade.TintColor=Color3.fromRGB(238,222,204)
grade.Parent=Lighting

local bloom=Instance.new("BloomEffect")
bloom.Name="SuviversDistrictBloom"
bloom.Intensity=.24
bloom.Threshold=1.65
bloom.Size=18
bloom.Parent=Lighting

Terrain.WaterReflectance=.22
Terrain.WaterTransparency=.38
Terrain.WaterWaveSize=.06
Terrain.WaterWaveSpeed=5
