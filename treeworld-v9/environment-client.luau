local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local fog=Lighting:WaitForChild("BaseFog")
local cc=Lighting:WaitForChild("BaseColor")
local rays=Lighting:FindFirstChild("ReferenceSunRays")or Instance.new("SunRaysEffect")
rays.Name="ReferenceSunRays";rays.Intensity=.035;rays.Spread=.75;rays.Parent=Lighting
local rgb=Color3.fromRGB
local function weight(x,z,cx,cz,inner,outer)
 local d=Vector2.new(x-cx,z-cz).Magnitude
 local t=math.clamp((outer-d)/(outer-inner),0,1);return t*t*(3-2*t)
end
local timer=0
RunService.Heartbeat:Connect(function(dt)
 timer+=dt;if timer<.1 then return end;timer=0
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart");if not root then return end
 local p=root.Position
 local dark=weight(p.X,p.Z,0,-850,150,270)
 local ruins=weight(p.X,p.Z,0,-360,120,210)
 local pond=weight(p.X,p.Z,350,220,130,220)
 local bright=math.max(ruins,pond)
 Lighting.Brightness=(1.9+.75*bright)*(1-dark)+.28*dark
 Lighting.ExposureCompensation=-.04+.12*bright-.5*dark
 Lighting.Ambient=rgb(87,108,111):Lerp(rgb(33,33,24),dark)
 Lighting.OutdoorAmbient=rgb(119,137,133):Lerp(rgb(53,51,34),dark)
 fog.Density=.25-.08*bright+.37*dark
 fog.Offset=.08;fog.Haze=1.2-.7*bright+2.4*dark
 fog.Color=rgb(143,181,198):Lerp(rgb(203,213,196),bright):Lerp(rgb(69,68,46),dark)
 fog.Decay=rgb(84,123,150):Lerp(rgb(145,165,136),bright):Lerp(rgb(33,32,23),dark)
 cc.Brightness=.015*bright-.08*dark;cc.Contrast=.06+.08*dark
 cc.Saturation=.03+.08*bright-.48*dark
 cc.TintColor=rgb(226,239,236):Lerp(rgb(255,249,231),bright):Lerp(rgb(176,169,123),dark)
 rays.Intensity=.035+.045*ruins-.03*dark
end)
