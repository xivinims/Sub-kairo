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
 ["Bosque do Silêncio"]={
  ambient=Color3.fromRGB(54,62,74),outdoor=Color3.fromRGB(83,101,115),air=Color3.fromRGB(137,164,172),
  decay=Color3.fromRGB(56,70,77),density=.27,haze=1.25,exposure=.02,brightness=1.75,clock=.35,
  tint=Color3.fromRGB(215,229,224),contrast=.15,saturation=-.18,bloom=.15,rays=.018,
 },
 ["Base Abandonada"]={
  ambient=Color3.fromRGB(67,63,61),outdoor=Color3.fromRGB(93,91,88),air=Color3.fromRGB(162,153,147),
  decay=Color3.fromRGB(79,71,69),density=.18,haze=.65,exposure=.04,brightness=1.85,clock=23.65,
  tint=Color3.fromRGB(231,218,211),contrast=.17,saturation=-.22,bloom=.11,rays=.008,
 },
 ["Fortaleza da Névoa"]={
  ambient=Color3.fromRGB(58,69,78),outdoor=Color3.fromRGB(86,104,117),air=Color3.fromRGB(154,185,200),
  decay=Color3.fromRGB(72,87,98),density=.31,haze=1.55,exposure=.08,brightness=1.78,clock=.7,
  tint=Color3.fromRGB(207,224,235),contrast=.13,saturation=-.20,bloom=.13,rays=.012,
 },
}

local lightTween,airTween,gradeTween
local lastKey=nil
local arenaReflectance=setmetatable({},{__mode="k"})

local function active()
 return (player:GetAttribute("InRound") or player:GetAttribute("Spectating"))
  and not player:GetAttribute("InMenu") and not player:GetAttribute("VoidActive")
end

local function reflectionEnabled()
 return player:GetAttribute("LowGraphics")~=true and player:GetAttribute("Reflections")~=false
end

local function restoreReflectance()
 for part,value in pairs(arenaReflectance) do
  if part.Parent then part.Reflectance=value end
  arenaReflectance[part]=nil
 end
end

local function enhanceArena(model)
 restoreReflectance()
 if not model or not reflectionEnabled() then return end
 local count=0
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and part.Transparency<.96 and count<340 then
   local target=nil
   if part.Material==Enum.Material.Metal or part.Material==Enum.Material.DiamondPlate then
    target=.13
   elseif part.Material==Enum.Material.Glass then
    target=.09
   elseif part.Material==Enum.Material.SmoothPlastic and part.Size.X*part.Size.Z>=36 and part.CFrame.UpVector.Y>.9 then
    target=.035
   end
   if target and part.Reflectance<target then
    arenaReflectance[part]=part.Reflectance
    part.Reflectance=target
    count+=1
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
 local key=table.concat({theme and name or "Lobby",tostring(low),tostring(reflect),tostring(player:GetAttribute("MapShadows"))},"|")
 if key==lastKey and not force then return end
 lastKey=key

 if lightTween then lightTween:Cancel() end
 if airTween then airTween:Cancel() end
 if gradeTween then gradeTween:Cancel() end

 if theme then
  local target={
   Ambient=theme.ambient,
   OutdoorAmbient=theme.outdoor,
   ExposureCompensation=low and theme.exposure-.04 or theme.exposure,
   ClockTime=theme.clock,
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
   TintColor=theme.tint,Contrast=low and theme.contrast*.65 or theme.contrast,
   Saturation=low and theme.saturation*.55 or theme.saturation,Brightness=0,
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
  applyWater(false) restoreReflectance()
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
 if child.Name=="ActiveArena" then restoreReflectance() end
end)
refresh(true)

-- Player-selected music, if a future feature re-enables it, still obeys user audio settings.
local songs=setmetatable({},{__mode="k"})
local function soundAdded(sound)
 if sound:IsA("Sound") and sound.Name=="CantorMusic" then
  songs[sound]=sound.Volume
  if player:GetAttribute("MusicEnabled")==false then sound.Volume=0 end
 end
end
workspace.DescendantAdded:Connect(soundAdded)
for _,v in ipairs(workspace:GetDescendants()) do soundAdded(v) end
player:GetAttributeChangedSignal("MusicEnabled"):Connect(function()
 for sound,volume in pairs(songs) do
  if sound.Parent then sound.Volume=player:GetAttribute("MusicEnabled")==false and 0 or volume else songs[sound]=nil end
 end
end)
