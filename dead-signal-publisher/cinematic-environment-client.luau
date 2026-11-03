-- Still Here: mansion lighting, soft shadows, and restrained cinematic post-processing.
local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' then return end
local Lighting=game:GetService('Lighting')
local function addEffect(class,name,props)
 local id='StillHereCinema'..name
 local old=Lighting:FindFirstChild(id)
 if old then old:Destroy() end
 local effect=Instance.new(class)
 effect.Name=id
 for key,value in pairs(props) do effect[key]=value end
 effect.Parent=Lighting
 return effect
end
addEffect('BloomEffect','Bloom',{Intensity=.93,Size=33,Threshold=1.15})
addEffect('ColorCorrectionEffect','Grade',{
 Brightness=-.055,Contrast=.27,Saturation=-.27,
 TintColor=Color3.fromRGB(189,207,225)
})
addEffect('DepthOfFieldEffect','Focus',{
 Enabled=true,FarIntensity=.26,NearIntensity=.13,FocusDistance=40,InFocusRadius=22
})
addEffect('Atmosphere','Haze',{
 Density=.27,Offset=.12,Color=Color3.fromRGB(110,137,159),
 Decay=Color3.fromRGB(40,56,74),Glare=.07,Haze=1.65
})
addEffect('SunRaysEffect','Rays',{Enabled=true,Intensity=.13,Spread=.63})
Lighting:SetAttribute('StillHereCinematicPreset','MansionHQ')
local modified=0
for _,light in ipairs(W:GetDescendants()) do
 if (light:IsA('PointLight') or light:IsA('SpotLight') or light:IsA('SurfaceLight'))
  and light.Enabled and modified<64 then
  light.Shadows=true
  modified+=1
 end
end
Lighting:SetAttribute('StillHereShadowLights',modified)
