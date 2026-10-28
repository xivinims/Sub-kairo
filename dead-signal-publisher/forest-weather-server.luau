local Workspace=game:GetService("Workspace")
local rng=Random.new(71843)

Workspace:SetAttribute("ForestWeather","Clear")
Workspace:SetAttribute("ForestLightningCue",0)

task.spawn(function()
 while true do
  task.wait(2.5)
  local storm=Workspace:GetAttribute("ForestWeather")=="Storm"
  local t=Workspace:GetServerTimeNow()
  local gust=math.sin(t/13)*2.2+math.noise(t/18,0,2)*1.8
  local base=storm and 8 or 3.4
  Workspace.GlobalWind=Vector3.new(base+gust,0,1.1+math.cos(t/17)*1.6)
 end
end)

while true do
 task.wait(32+rng:NextNumber(0,22))
 Workspace:SetAttribute("ForestWeather","Storm")
 local stormEnds=os.clock()+92
 while os.clock()<stormEnds do
  task.wait(rng:NextNumber(23,39))
  if Workspace:GetAttribute("ForestWeather")=="Storm" then
   Workspace:SetAttribute("ForestLightningCue",Workspace:GetServerTimeNow())
  end
 end
 Workspace:SetAttribute("ForestWeather","Clear")
 task.wait(118+rng:NextNumber(0,24))
end
