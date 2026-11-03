local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
require(runtime:WaitForChild("Visuals")).apply()
local world = workspace:WaitForChild("ForestWorld")
local spawn = world:WaitForChild("ForestSpawn")
local spawnCF = runtime:GetAttribute("MainSpawnCF")
local function character(player, model)
	local humanoid = model:WaitForChild("Humanoid", 10) local root = model:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= model then return end
	root.Anchored = false humanoid.PlatformStand = false humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16 humanoid.UseJumpPower = true humanoid.JumpPower = 50
	if (root.Position - spawnCF.Position).Magnitude > 28 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero end
end
local function playerAdded(player)
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(model) character(player, model) end)
	if player.Character then task.spawn(character, player, player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt if elapsed < 1 then return end elapsed = 0
	local time = workspace:GetServerTimeNow()
	local strength = 7.5 + math.sin(time * 0.047) * 0.6 + math.sin(time * 0.023) * 0.35
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
