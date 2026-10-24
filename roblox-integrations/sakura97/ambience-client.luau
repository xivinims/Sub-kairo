-- Local arena grading. Visual upgrades stay client-side so low-end devices can opt out.
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local Terrain=workspace.Terrain

local player=Players.LocalPlayer
local net=RS:WaitForChild("Survival")

local original={
 Ambient=Lighting.Ambient,
 OutdoorAmbient=Lighting.OutdoorAmbient,
 ExposureCompensation=Lighting.ExposureCompensation,
 ClockTime=Lighting.ClockTime,
 Brightness=Lighting.Brightness,
 ShadowSoftness=Lighting.ShadowSoftness,
 EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale,
 EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale,
 WaterReflectance=Terrain.WaterReflectance,
 WaterTransparency=Terrain.WaterTransparency,
 WaterWaveSize=Terrain.WaterWaveSize,
 WaterWaveSpeed=Terrain.WaterWaveSpeed,
}

local atmosphere=Lighting:FindFirstChild("SuviversAtmosphere") or Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then atmosphere=Instance.new("Atmosphere") atmosphere.Name="SuviversAtmosphere" atmosphere.Parent=Lighting end
local originalAir={
 Color=atmosphere.Color,Decay=atmosphere.Decay,Density=atmosphere.Density,
 Haze=atmosphere.Haze,Glare=atmosphere.Glare,Offset=atmosphere.Offset,
}

local function effect(class,name)
 local old=Lighting:FindFirstChild(name)
 if old and old.ClassName~=class then old:Destroy() old=nil end
 local obj=old or Instance.new(class)
 obj.Name=name obj.Parent=Lighting
 return obj
end

local grade=effect("ColorCorrectionEffect","SuviversArenaGrade")
local bloom=effect("BloomEffect","SuviversArenaBloom")
local rays=effect("SunRaysEffect","SuviversArenaRays")
local dof=effect("DepthOfFieldEffect","SuviversArenaDOF")

grade.Enabled=false
bloom.Enabled=false
rays.Enabled=false
dof.Enabled=false

local themes={
 ["Doomspire Brickbattle"]={
  ambient=Color3.fromRGB(67,73,82),outdoor=Color3.fromRGB(105,112,124),air=Color3.fromRGB(158,175,192),
  decay=Color3.fromRGB(76,84,94),density=.13,haze=.42,exposure=.05,brightness=1.9,clock=8.25,
  tint=Color3.fromRGB(224,231,239),contrast=.08,saturation=-.10,bloom=.10,rays=.02,
 },
 ["Juggernaut Fight Arena"]={
  ambient=Color3.fromRGB(62,59,60),outdoor=Color3.fromRGB(94,90,91),air=Color3.fromRGB(150,144,144),
  decay=Color3.fromRGB(73,68,68),density=.17,haze=.58,exposure=.02,brightness=1.8,clock=8.25,
  tint=Color3.fromRGB(230,220,218),contrast=.13,saturation=-.16,bloom=.11,rays=.012,
 },
 ["Pirate Bay Island Cove"]={
  ambient=Color3.fromRGB(64,75,79),outdoor=Color3.fromRGB(100,122,127),air=Color3.fromRGB(155,184,190),
  decay=Color3.fromRGB(72,88,91),density=.16,haze=.7,exposure=.08,brightness=1.95,clock=8.25,
  tint=Color3.fromRGB(217,233,232),contrast=.09,saturation=-.08,bloom=.12,rays=.025,
 },
 ["Natural Disaster Survival"]={
  ambient=Color3.fromRGB(72,72,75),outdoor=Color3.fromRGB(113,112,113),air=Color3.fromRGB(166,166,171),
  decay=Color3.fromRGB(81,81,84),density=.12,haze=.38,exposure=.06,brightness=1.95,clock=8.25,
  tint=Color3.fromRGB(232,232,235),contrast=.07,saturation=-.12,bloom=.08,rays=.018,
 },
 ["RocketArena"]={
  ambient=Color3.fromRGB(66,69,78),outdoor=Color3.fromRGB(101,108,123),air=Color3.fromRGB(154,169,188),
  decay=Color3.fromRGB(74,81,94),density=.14,haze=.5,exposure=.04,brightness=1.9,clock=8.25,
  tint=Color3.fromRGB(219,228,240),contrast=.11,saturation=-.13,bloom=.10,rays=.018,
 },
}

local lightTween,airTween,gradeTween
local lastKey=nil
local arenaReflectance=setmetatable({},{__mode="k"})
local arenaLights=setmetatable({},{__mode="k"})

local function active()
 return (player:GetAttribute("InRound") or player:GetAttribute("Spectating"))
  and not player:GetAttribute("InMenu") and not player:GetAttribute("VoidActive")
end

local function reflectionEnabled()
 return player:GetAttribute("LowGraphics")~=true and player:GetAttribute("Reflections")~=false
end

local function restoreArenaEnhancements()
 for part,value in pairs(arenaReflectance) do
  if part.Parent then part.Reflectance=value end
  arenaReflectance[part]=nil
 end
 for light,state in pairs(arenaLights) do
  if light.Parent then
   light.Shadows=state.shadows
   light.Brightness=state.brightness
  end
  arenaLights[light]=nil
 end
end

local function enhanceArena(model)
 restoreArenaEnhancements()
 if not model then return end
 local low=player:GetAttribute("LowGraphics")==true
 local reflect=reflectionEnabled()
 local shadowLights=0
 local reflectedParts=0
 for _,obj in ipairs(model:GetDescendants()) do
  if obj:IsA("Light") and obj.Enabled and shadowLights<10 then
   arenaLights[obj]={shadows=obj.Shadows,brightness=obj.Brightness}
   obj.Shadows=not low and player:GetAttribute("MapShadows")==true
   obj.Brightness=math.min(1.75,obj.Brightness*(low and 1 or 1.08))
   shadowLights+=1
  elseif reflect and obj:IsA("BasePart") and obj.Transparency<.96 and reflectedParts<340 then
   local target=nil
   if obj.Material==Enum.Material.Metal or obj.Material==Enum.Material.DiamondPlate then
    target=.13
   elseif obj.Material==Enum.Material.Glass then
    target=.09
   elseif obj.Material==Enum.Material.SmoothPlastic and obj.Size.X*obj.Size.Z>=36 and obj.CFrame.UpVector.Y>.9 then
    target=.035
   end
   if target and obj.Reflectance<target then
    arenaReflectance[obj]=obj.Reflectance
    obj.Reflectance=target
    reflectedParts+=1
   end
  end
 end
end

local function findArena()
 local arena=workspace:FindFirstChild("ActiveArena")
 return arena and arena:IsA("Model") and arena or nil
end

local function applyWater(on)
 if on then
  Terrain.WaterReflectance=.55
  Terrain.WaterTransparency=.28
  Terrain.WaterWaveSize=.11
  Terrain.WaterWaveSpeed=8
 else
  Terrain.WaterReflectance=original.WaterReflectance
  Terrain.WaterTransparency=original.WaterTransparency
  Terrain.WaterWaveSize=original.WaterWaveSize
  Terrain.WaterWaveSpeed=original.WaterWaveSpeed
 end
end

local function refresh(force)
 local inArena=active()
 local name=net:GetAttribute("Map")
 local theme=inArena and themes[name] or nil
 local low=player:GetAttribute("LowGraphics")==true
 local reflect=reflectionEnabled()
 local userSaturation=player:GetAttribute("VisualSaturation")
 local userContrast=player:GetAttribute("VisualContrast")
 local userExposure=player:GetAttribute("VisualExposure")
 local userTime=player:GetAttribute("VisualTime")
 if userSaturation==nil then userSaturation=-.65 end
 if userContrast==nil then userContrast=0 end
 if userExposure==nil then userExposure=1.5 end
 if userTime==nil then userTime=8.25 end
 local key=table.concat({
  theme and name or "Lobby",tostring(low),tostring(reflect),tostring(player:GetAttribute("MapShadows")),
  tostring(userSaturation),tostring(userContrast),tostring(userExposure),tostring(userTime)
 },"|")
 if key==lastKey and not force then return end
 lastKey=key

 if lightTween then lightTween:Cancel() end
 if airTween then airTween:Cancel() end
 if gradeTween then gradeTween:Cancel() end

 if theme then
  local target={
   Ambient=theme.ambient,
   OutdoorAmbient=theme.outdoor,
   ExposureCompensation=userExposure,
   ClockTime=userTime,
   Brightness=low and math.min(theme.brightness,1.65) or theme.brightness,
   ShadowSoftness=low and .65 or .38,
   EnvironmentDiffuseScale=low and .22 or .42,
   EnvironmentSpecularScale=reflect and .92 or .18,
  }
  lightTween=TweenService:Create(Lighting,TweenInfo.new(1.15,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),target)
  lightTween:Play()

  local air={
   Color=theme.air,Decay=theme.decay,
   Density=low and theme.density*.58 or theme.density,
   Haze=low and theme.haze*.38 or theme.haze,
   Glare=low and 0 or .05,Offset=.08,
  }
  airTween=TweenService:Create(atmosphere,TweenInfo.new(1.15),air) airTween:Play()

  grade.Enabled=true
  gradeTween=TweenService:Create(grade,TweenInfo.new(.8),{
   TintColor=theme.tint,Contrast=userContrast,
   Saturation=userSaturation,Brightness=0,
  })
  gradeTween:Play()

  bloom.Enabled=not low
  bloom.Intensity=theme.bloom
  bloom.Size=18
  bloom.Threshold=1.18

  rays.Enabled=not low
  rays.Intensity=theme.rays
  rays.Spread=.72

  dof.Enabled=not low
  dof.FocusDistance=19
  dof.InFocusRadius=17
  dof.NearIntensity=.035
  dof.FarIntensity=.07

  applyWater(reflect)
  enhanceArena(findArena())
 else
  lightTween=TweenService:Create(Lighting,TweenInfo.new(1),{
   Ambient=original.Ambient,OutdoorAmbient=original.OutdoorAmbient,
   ExposureCompensation=original.ExposureCompensation,ClockTime=original.ClockTime,
   Brightness=original.Brightness,ShadowSoftness=original.ShadowSoftness,
   EnvironmentDiffuseScale=original.EnvironmentDiffuseScale,
   EnvironmentSpecularScale=original.EnvironmentSpecularScale,
  }) lightTween:Play()
  airTween=TweenService:Create(atmosphere,TweenInfo.new(1),originalAir) airTween:Play()
  grade.Enabled=false bloom.Enabled=false rays.Enabled=false dof.Enabled=false
  applyWater(false) restoreArenaEnhancements()
 end
end

for _,name in ipairs({"InRound","Spectating","InMenu","VoidActive","LowGraphics","Reflections","MapShadows"}) do
 player:GetAttributeChangedSignal(name):Connect(function() refresh(true) end)
end
net:GetAttributeChangedSignal("Map"):Connect(function() refresh(true) end)
workspace.ChildAdded:Connect(function(child)
 if child.Name=="ActiveArena" then task.defer(function() refresh(true) end) end
end)
workspace.ChildRemoved:Connect(function(child)
 if child.Name=="ActiveArena" then restoreArenaEnhancements() end
end)
refresh(true)
