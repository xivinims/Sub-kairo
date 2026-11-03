local Lighting = game:GetService("Lighting")
local Visuals = {}
function Visuals.apply()
	Lighting.LightingStyle = Enum.LightingStyle.Realistic Lighting.PrioritizeLightingQuality = true
	Lighting.GlobalShadows = true Lighting.ShadowSoftness = 0.25
	Lighting.EnvironmentDiffuseScale = 1 Lighting.EnvironmentSpecularScale = 1
	Lighting.Brightness = 2.7 Lighting.ClockTime = 10.2 Lighting.GeographicLatitude = 28
	Lighting.ExposureCompensation = -0.10
	Lighting.Ambient = Color3.fromRGB(47, 56, 57) Lighting.OutdoorAmbient = Color3.fromRGB(99, 119, 121)
	Lighting.ColorShift_Top = Color3.fromRGB(12, 9, 3) Lighting.ColorShift_Bottom = Color3.new()
	Lighting.FogColor = Color3.fromRGB(178, 199, 203) Lighting.FogStart = 200 Lighting.FogEnd = 1800
	local color = Lighting:FindFirstChild("ForestColor")
	if color then color.Enabled = true color.Brightness = 0.01 color.Contrast = 0.13 color.Saturation = 0.10 color.TintColor = Color3.fromRGB(255, 253, 242) end
	local rays = Lighting:FindFirstChild("ForestSunRays")
	if rays then rays.Enabled = true rays.Intensity = 0.075 rays.Spread = 0.77 end
	local bloom = Lighting:FindFirstChild("ForestBloom")
	if bloom then bloom.Enabled = true bloom.Intensity = 0.12 bloom.Size = 18 bloom.Threshold = 1.55 end
	local air = Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Density = 0.27 air.Offset = 0.18 air.Color = Color3.fromRGB(196, 215, 221) air.Decay = Color3.fromRGB(105, 137, 134) air.Haze = 1.1 air.Glare = 0.16 end
end
return Visuals
