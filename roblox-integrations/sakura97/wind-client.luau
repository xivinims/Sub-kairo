local player=game:GetService("Players").LocalPlayer
local WindLines=require(script:WaitForChild("WindLines"))
local WindShake=require(script:WaitForChild("WindShake"))
local function apply()
 local wind=workspace.GlobalWind
 local enabled=player:GetAttribute("WindEnabled")~=false
 if enabled then
  WindLines:Init({Direction=wind.Unit,Speed=wind.Magnitude,Lifetime=2,SpawnRate=6})
  WindShake:SetDefaultSettings({WindSpeed=wind.Magnitude,WindDirection=wind.Unit,WindPower=.45})
  WindShake:Init() WindShake:Resume()
 else WindLines:Cleanup() WindShake:Pause() end
end
apply()
player:GetAttributeChangedSignal("WindEnabled"):Connect(apply)
