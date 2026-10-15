local Lighting = game:GetService("Lighting")
local Visuals = {}
local Cycle=require(script.Parent:WaitForChild("Cycle"))
function Visuals.apply()
	-- Some Roblox runtime versions restrict renderer selection to Studio. The rest of the world must still initialise.
	pcall(function()Lighting.LightingStyle=Enum.LightingStyle.Realistic end)
	pcall(function()Lighting.PrioritizeLightingQuality=true end)
	Lighting.GlobalShadows = true Lighting.ShadowSoftness = 0.25
	Lighting.EnvironmentDiffuseScale = 1 Lighting.EnvironmentSpecularScale = 1
	Lighting.Brightness = 2.7 Lighting.ClockTime = Cycle.StartClock Lighting.GeographicLatitude = 28
	Lighting.ExposureCompensation = -0.10
	Lighting.Ambient = Color3.fromRGB(47, 56, 57) Lighting.OutdoorAmbient = Color3.fromRGB(99, 119, 121)
	Lighting.ColorShift_Top = Color3.fromRGB(12, 9, 3) Lighting.ColorShift_Bottom = Color3.new()
	Lighting.FogColor = Color3.fromRGB(178, 199, 203) Lighting.FogStart = 200 Lighting.FogEnd = 1800
	local color = Lighting:FindFirstChild("ForestColor")
	if color then color.Enabled = true color.Brightness = 0.01 color.Contrast = 0.18 color.Saturation = 0.12 color.TintColor = Color3.fromRGB(255, 247, 230) end
	local rays = Lighting:FindFirstChild("ForestSunRays")
	if rays then rays.Enabled = true rays.Intensity = 0.075 rays.Spread = 0.727 end
	local bloom = Lighting:FindFirstChild("ForestBloom")
	if bloom then bloom.Enabled = true bloom.Intensity = 0.15 bloom.Size = 10 bloom.Threshold = 1.35 end
	local air = Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Density = 0.28 air.Offset = 0.18 air.Color = Color3.fromRGB(196, 215, 221) air.Decay = Color3.fromRGB(105, 137, 134) air.Haze = 1.15 air.Glare = 0.20 end
end
function Visuals.clock(clock)
	local day=Cycle.daylight(clock)local night=1-day
	local warm=math.max(0,1-math.min(math.abs(clock-6.8),math.abs(clock-17.4))/2.4)*day
	Lighting.ClockTime=clock Lighting.Brightness=1.0+1.65*day
	Lighting.ExposureCompensation=-.08-.08*night
	Lighting.Ambient=Color3.fromRGB(24,32,48):Lerp(Color3.fromRGB(49,57,58),day)
	Lighting.OutdoorAmbient=Color3.fromRGB(48,63,88):Lerp(Color3.fromRGB(100,120,123),day)
	local color=Lighting:FindFirstChild("ForestColor")
	if color then color.Contrast=.12+.06*day color.Saturation=.04+.08*day color.TintColor=Color3.fromRGB(201,219,255):Lerp(Color3.fromRGB(255,247,230),day):Lerp(Color3.fromRGB(255,222,181),warm*.38)end
	local rays=Lighting:FindFirstChild("ForestSunRays")if rays then rays.Intensity=(.055+.035*warm)*day end
	local air=Lighting:FindFirstChild("ForestAtmosphere")
	if air then air.Color=Color3.fromRGB(100,133,174):Lerp(Color3.fromRGB(196,215,221),day):Lerp(Color3.fromRGB(224,185,149),warm*.4)air.Glare=.20*day end
end
return Visuals
