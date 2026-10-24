local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local runtime = game.ReplicatedStorage:WaitForChild("MonCalamariRuntime")
local Visuals = require(runtime:WaitForChild("Visuals"))
Visuals.apply()
while not workspace.CurrentCamera do RunService.Heartbeat:Wait() end
local WindLines = require(runtime:WaitForChild("WindEffects"):WaitForChild("WindLines"))
local wind = workspace.GlobalWind
WindLines:Init({Direction = wind.Unit, Speed = 12, Lifetime = 2, SpawnRate = UserInputService.TouchEnabled and 7 or 12})

local stopped = false
local elapsed = 0
local update = RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.5 then return end
	elapsed = 0
	local value = workspace.GlobalWind
	if value.Magnitude > 0.01 then WindLines.Direction = value.Unit end
	WindLines.Speed = math.clamp(value.Magnitude * 1.25, 5, 18)
end)

script.Destroying:Connect(function()
	if stopped then return end
	stopped = true
	update:Disconnect()
	WindLines:Cleanup()
end)
