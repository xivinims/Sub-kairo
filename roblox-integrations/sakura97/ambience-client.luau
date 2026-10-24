-- Local atmosphere follows the player's arena; the lobby keeps its authored lighting.
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer local net=RS:WaitForChild("Survival")
local original={Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,ExposureCompensation=Lighting.ExposureCompensation,ClockTime=Lighting.ClockTime}
local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
local owned=not atmosphere
if not atmosphere then atmosphere=Instance.new("Atmosphere") atmosphere.Name="SuviversAtmosphere" atmosphere.Density=0 atmosphere.Haze=0 atmosphere.Parent=Lighting end
local originalAir={Color=atmosphere.Color,Decay=atmosphere.Decay,Density=atmosphere.Density,Haze=atmosphere.Haze,Glare=atmosphere.Glare}
local themes={
 ["Bosque do Silêncio"]={ambient=Color3.fromRGB(66,70,84),outdoor=Color3.fromRGB(89,99,120),air=Color3.fromRGB(162,176,201),density=.22,exposure=.15},
 ["Base Abandonada"]={ambient=Color3.fromRGB(79,76,73),outdoor=Color3.fromRGB(100,103,108),air=Color3.fromRGB(181,178,174),density=.16,exposure=.18},
 ["Fortaleza da Névoa"]={ambient=Color3.fromRGB(72,81,91),outdoor=Color3.fromRGB(96,114,128),air=Color3.fromRGB(175,198,211),density=.24,exposure=.25},
}
local lightTween,airTween local lastKey=nil
local function refresh()
 local active=(player:GetAttribute("InRound") or player:GetAttribute("Spectating")) and not player:GetAttribute("InMenu") and not player:GetAttribute("VoidActive")
 local name=net:GetAttribute("Map") local theme=active and themes[name]
 local key=(theme and name or "Lobby")..tostring(player:GetAttribute("LowGraphics"))
 if key==lastKey then return end lastKey=key
 if lightTween then lightTween:Cancel() end if airTween then airTween:Cancel() end
 local light=theme and {Ambient=theme.ambient,OutdoorAmbient=theme.outdoor,ExposureCompensation=theme.exposure,ClockTime=0} or original
 local air=theme and {Color=theme.air,Decay=Color3.fromRGB(92,98,111),Density=theme.density,Haze=player:GetAttribute("LowGraphics") and .3 or .8,Glare=0} or originalAir
 lightTween=TweenService:Create(Lighting,TweenInfo.new(1.2),light) lightTween:Play()
 airTween=TweenService:Create(atmosphere,TweenInfo.new(1.2),air) airTween:Play()
end
for _,name in ipairs({"InRound","Spectating","InMenu","VoidActive","LowGraphics"}) do player:GetAttributeChangedSignal(name):Connect(refresh) end
net:GetAttributeChangedSignal("Map"):Connect(refresh) refresh()
-- The music switch also mutes player-selected songs on this client.
local songs=setmetatable({},{__mode="k"})
local function soundAdded(sound)
 if sound:IsA("Sound") and sound.Name=="CantorMusic" then songs[sound]=sound.Volume if player:GetAttribute("MusicEnabled")==false then sound.Volume=0 end end
end
workspace.DescendantAdded:Connect(soundAdded)
for _,v in ipairs(workspace:GetDescendants()) do soundAdded(v) end
player:GetAttributeChangedSignal("MusicEnabled"):Connect(function()
 for sound,volume in pairs(songs) do if sound.Parent then sound.Volume=player:GetAttribute("MusicEnabled")==false and 0 or volume else songs[sound]=nil end end
end)
