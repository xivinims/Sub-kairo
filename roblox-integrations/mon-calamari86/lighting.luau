-- Native Roblox renderer and post-processing, applied on both server and client.
local Lighting = game:GetService("Lighting")
local Visuals = {}

function Visuals.apply()
	Lighting.LightingStyle = Enum.LightingStyle.Realistic
	Lighting.PrioritizeLightingQuality = true
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.22
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.Brightness = 2.6
	Lighting.ClockTime = 15.35
	Lighting.GeographicLatitude = 22
	Lighting.ExposureCompensation = -0.12
	Lighting.Ambient = Color3.fromRGB(47, 57, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 119, 132)
	Lighting.ColorShift_Top = Color3.fromRGB(12, 7, 2)
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	Lighting.FogStart = 900
	Lighting.FogEnd = 4200
	Lighting.FogColor = Color3.fromRGB(182, 213, 225)
	local color = Lighting:FindFirstChild("MonCalamariColor")
	if color then
		color.Enabled = true
		color.Brightness = 0.015
		color.Contrast = 0.12
		color.Saturation = 0.10
		color.TintColor = Color3.fromRGB(255, 249, 239)
	end
	local bloom = Lighting:FindFirstChild("MonCalamariBloom")
	if bloom then
		bloom.Enabled = true
		bloom.Intensity = 0.18
		bloom.Size = 20
		bloom.Threshold = 1.4
	end
	local rays = Lighting:FindFirstChild("MonCalamariSunRays")
	if rays then
		rays.Enabled = true
		rays.Intensity = 0.065
		rays.Spread = 0.78
	end
	local air = Lighting:FindFirstChild("MonCalamariAtmosphere")
	if air then
		air.Density = 0.24
		air.Offset = 0.13
		air.Color = Color3.fromRGB(190, 215, 228)
		air.Decay = Color3.fromRGB(125, 148, 172)
		air.Glare = 0.18
		air.Haze = 1.10
	end
end

return Visuals
