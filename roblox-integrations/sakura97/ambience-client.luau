local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain

-- Fixed Suvivers atmosphere: night outside, readable warm interior lights with restrained haze.
-- There are intentionally no player-facing environment/visual sliders.
Lighting.ClockTime=.5
Lighting.Brightness=1.12
Lighting.Ambient=Color3.fromRGB(32,33,42)
Lighting.OutdoorAmbient=Color3.fromRGB(7,9,17)
Lighting.ColorShift_Top=Color3.fromRGB(5,7,15)
Lighting.ColorShift_Bottom=Color3.fromRGB(5,5,9)
Lighting.ExposureCompensation=-.27
Lighting.GlobalShadows=true
Lighting.ShadowSoftness=.28
Lighting.EnvironmentDiffuseScale=.28
Lighting.EnvironmentSpecularScale=.72
Lighting.FogColor=Color3.fromRGB(15,18,30)
Lighting.FogStart=28
Lighting.FogEnd=455
pcall(function() Lighting.Technology=Enum.Technology.Future end)

for _,name in ipairs({"SuviversArenaGrade","SuviversArenaRays","SuviversArenaDOF","SuviversAtmosphere","ViolenceDistrictBloom"}) do
 local old=Lighting:FindFirstChild(name)
 if old then old:Destroy() end
end
for _,obj in ipairs(Lighting:GetChildren()) do
 if obj:IsA("Atmosphere") and obj.Name~="SuviversRoundAtmosphere" then obj:Destroy()
 elseif obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("BloomEffect") then
  obj.Enabled=false
 end
end

local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="SuviversAtmosphere"
atmosphere.Density=.29
atmosphere.Offset=.06
atmosphere.Color=Color3.fromRGB(78,88,116)
atmosphere.Decay=Color3.fromRGB(20,24,39)
atmosphere.Glare=.025
atmosphere.Haze=1.68
atmosphere.Parent=Lighting

local grade=Instance.new("ColorCorrectionEffect")
grade.Name="SuviversArenaGrade"
grade.Brightness=-.05
grade.Contrast=.18
grade.Saturation=-.24
grade.TintColor=Color3.fromRGB(210,218,238)
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

