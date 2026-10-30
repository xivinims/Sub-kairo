-- Still Here: high-contrast cinematic lighting and the original menu ambience.
-- Menu music: Roblox Creator Store asset 9045936046 ("Massive Black Hole").
-- This does not download, transcode, re-upload, or modify the audio.
-- This client's sound fades out during teleport and never plays during a match.
local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
local menu=W:GetAttribute('GameMode')=='Menu'

local Players=game:GetService('Players')
local Lighting=game:GetService('Lighting')
local SoundService=game:GetService('SoundService')
local TweenService=game:GetService('TweenService')
local RunService=game:GetService('RunService')
local ContentProvider=game:GetService('ContentProvider')
local player=Players.LocalPlayer

local POSTFIX='StillHereCinema'
local function addEffect(class,name,props)
 local id=POSTFIX..name
 local old=Lighting:FindFirstChild(id)
 if old then old:Destroy() end
 local effect=Instance.new(class)
 effect.Name=id
 for key,value in pairs(props) do effect[key]=value end
 effect.Parent=Lighting
 return effect
end

-- Engine-native real-time post-processing. The actual shading and shadows
-- remain GPU/quality-level dependent; no fake performance degradation.
local bloom=addEffect('BloomEffect','Bloom',{
 Intensity=menu and .68 or .93,
 Size=menu and 22 or 33,
 Threshold=menu and 1.38 or 1.15,
})
local grade=addEffect('ColorCorrectionEffect','Grade',{
 Brightness=menu and -.035 or -.055,
 Contrast=menu and .19 or .27,
 Saturation=menu and -.12 or -.27,
 TintColor=menu and Color3.fromRGB(211,221,238) or Color3.fromRGB(189,207,225),
})
local dof=addEffect('DepthOfFieldEffect','Focus',{
 -- Keep the black-hole silhouette sharp behind menu text.
 Enabled=not menu,
 FarIntensity=menu and .04 or .26,
 NearIntensity=menu and 0 or .13,
 FocusDistance=menu and 565 or 40,
 InFocusRadius=menu and 540 or 22,
})
local atmosphere
if not menu then
 atmosphere=addEffect('Atmosphere','Haze',{
  Density=.27,
  Offset=.12,
  Color=Color3.fromRGB(110,137,159),
  Decay=Color3.fromRGB(40,56,74),
  Glare=.07,
  Haze=1.65,
 })
end
local rays=addEffect('SunRaysEffect','Rays',{
 Enabled=not menu,
 Intensity=menu and 0 or .13,
 Spread=.63,
})
Lighting:SetAttribute('StillHereCinematicPreset',menu and 'VoidMenuHQ' or 'MansionHQ')

local menuLights
if menu then
 menuLights=Instance.new('Folder')
 menuLights.Name='LocalCinematicLights'
 menuLights.Parent=W
 local lights={
  {'ColdKey',Vector3.new(-4,5005,-3.7),Color3.fromRGB(95,157,230),3.3,25},
  {'WarmRim',Vector3.new(2.2,5004,-11),Color3.fromRGB(223,152,110),2.5,22},
  {'DeepFill',Vector3.new(-2.1,4998.8,-5),Color3.fromRGB(52,98,154),1.6,13},
 }
 for _,spec in ipairs(lights) do
  local anchor=Instance.new('Part')
  anchor.Name=spec[1]
  anchor.Size=Vector3.new(.5,.5,.5)
  anchor.CFrame=CFrame.new(spec[2])
  anchor.Transparency=1
  anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
  anchor.CastShadow=false
  anchor.Parent=menuLights
  local lamp=Instance.new('PointLight')
  lamp.Name='CastShadowLight'
  lamp.Color=spec[3];lamp.Brightness=spec[4];lamp.Range=spec[5]
  lamp.Shadows=true
  lamp.Parent=anchor
 end
else
 -- Preserve all original mansion fixtures. Give the local player rich shadows
 -- instead of duplicating dozens of expensive light sources.
 local modified=0
 for _,light in ipairs(W:GetDescendants()) do
  if light:IsA('PointLight') or light:IsA('SpotLight') or light:IsA('SurfaceLight') then
   if light.Enabled and modified<64 then
    light.Shadows=true
    modified+=1
   end
  end
 end
 Lighting:SetAttribute('StillHereShadowLights',modified)
end

if not menu then return end

local previous=SoundService:FindFirstChild('MassiveBlackHoleMenu')
if previous then previous:Destroy() end
local music=Instance.new('Sound')
music.Name='MassiveBlackHoleMenu'
music.SoundId='rbxassetid://9045936046'
music.Volume=.42
music.PlaybackSpeed=1
music.Looped=true
music.Parent=SoundService
-- Non-positional stereo audio. SessionInterface applies the player's overall
-- volume setting via its existing StillHereMaster SoundGroup.
local function begin()
 if W:GetAttribute('GameMode')~='Menu' or not music.Parent then return end
 if player:GetAttribute('MenuCameraMode')=='starting' then return end
 music:Play()
end
begin()
task.spawn(function()
 local ok=pcall(function() ContentProvider:PreloadAsync({music}) end)
 if not ok or not music.IsLoaded then
  warn('[StillHere] Massive Black Hole audio may be restricted for this experience (9045936046)')
 end
end)
local fading
local function transition()
 if not music.Parent then return end
 if fading then fading:Cancel() end
 if player:GetAttribute('MenuCameraMode')=='starting' then
  fading=TweenService:Create(music,TweenInfo.new(1.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Volume=0})
  fading:Play()
 else
  fading=TweenService:Create(music,TweenInfo.new(.6),{Volume=.42})
  fading:Play()
  if not music.Playing then music:Play() end
 end
end
local cameraSignal=player:GetAttributeChangedSignal('MenuCameraMode'):Connect(transition)
local worldSignal
worldSignal=W:GetAttributeChangedSignal('GameMode'):Connect(function()
 if W:GetAttribute('GameMode')~='Menu' then
  cameraSignal:Disconnect();worldSignal:Disconnect()
  if fading then fading:Cancel() end
  music:Stop();music:Destroy()
  if menuLights then menuLights:Destroy() end
 end
end)
