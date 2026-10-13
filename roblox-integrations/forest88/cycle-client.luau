local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Cycle=require(runtime:WaitForChild("Cycle"))local Visuals=require(runtime:WaitForChild("Visuals"))
Visuals.apply()
local lights={}local function added(light)if light:IsA("PointLight")then lights[light]=true end end
for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do added(light)end
local addConnection=Collection:GetInstanceAddedSignal("ForestNightLight"):Connect(added)
local removeConnection=Collection:GetInstanceRemovedSignal("ForestNightLight"):Connect(function(light)lights[light]=nil end)
local elapsed=0
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt if elapsed<1/15 then return end elapsed=0
 local epoch=runtime:GetAttribute("CycleEpoch")if not epoch then return end
 local clock=Cycle.clock(workspace:GetServerTimeNow(),epoch)Visuals.clock(clock)
 local night=Cycle.night(clock)
 for light in pairs(lights)do if light.Parent then light.Enabled=night>.015 light.Brightness=night*1.7 else lights[light]=nil end end
end)
script.Destroying:Connect(function()connection:Disconnect()addConnection:Disconnect()removeConnection:Disconnect()table.clear(lights)end)
