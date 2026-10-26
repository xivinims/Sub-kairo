local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain

-- Fixed Suvivers atmosphere: night outside, readable warm interior lights with restrained haze.
-- There are intentionally no player-facing environment/visual sliders.
Lighting.ClockTime=.5
Lighting.Brightness=1.45
Lighting.Ambient=Color3.fromRGB(42,43,52)
Lighting.OutdoorAmbient=Color3.fromRGB(14,18,29)
Lighting.ColorShift_Top=Color3.fromRGB(8,10,18)
Lighting.ColorShift_Bottom=Color3.fromRGB(8,8,10)
Lighting.ExposureCompensation=-.18
Lighting.GlobalShadows=true
Lighting.ShadowSoftness=.28
Lighting.EnvironmentDiffuseScale=.28
Lighting.EnvironmentSpecularScale=.72
Lighting.FogColor=Color3.fromRGB(24,29,42)
Lighting.FogStart=35
Lighting.FogEnd=520
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
atmosphere.Density=.24
atmosphere.Offset=.08
atmosphere.Color=Color3.fromRGB(99,112,141)
atmosphere.Decay=Color3.fromRGB(30,35,51)
atmosphere.Glare=.04
atmosphere.Haze=1.35
atmosphere.Parent=Lighting

local grade=Instance.new("ColorCorrectionEffect")
grade.Name="SuviversArenaGrade"
grade.Brightness=-.025
grade.Contrast=.12
grade.Saturation=-.20
grade.TintColor=Color3.fromRGB(222,228,242)
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

