local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain
-- Fixed Violence District look. No user-facing environment/visual sliders.
Lighting.ClockTime=5
Lighting.Brightness=3
Lighting.Ambient=Color3.fromRGB(78,102,108)
Lighting.OutdoorAmbient=Color3.fromRGB(93,104,124)
Lighting.ColorShift_Top=Color3.fromRGB(62,78,81)
Lighting.ExposureCompensation=0
Lighting.GlobalShadows=true
Lighting.ShadowSoftness=.2
Lighting.EnvironmentDiffuseScale=.222
Lighting.EnvironmentSpecularScale=1
Lighting.FogColor=Color3.fromRGB(192,192,192)
Lighting.FogStart=0
Lighting.FogEnd=100000
pcall(function() Lighting.Technology=Enum.Technology.Future end)

for _,name in ipairs({"SuviversArenaGrade","SuviversArenaRays","SuviversArenaDOF","SuviversAtmosphere"}) do
 local old=Lighting:FindFirstChild(name) if old then old:Destroy() end
end
for _,obj in ipairs(Lighting:GetChildren()) do
 if obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("Atmosphere") then
  if obj.Name~="ViolenceDistrictBloom" then obj.Enabled=false end
 end
end
local bloom=Lighting:FindFirstChild("ViolenceDistrictBloom")
if not bloom then bloom=Instance.new("BloomEffect") bloom.Name="ViolenceDistrictBloom" bloom.Parent=Lighting end
bloom.Intensity=1 bloom.Threshold=2 bloom.Size=24 bloom.Enabled=true
Terrain.WaterReflectance=.35
Terrain.WaterTransparency=.32
Terrain.WaterWaveSize=.08
Terrain.WaterWaveSpeed=7