local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local runtime = game.ReplicatedStorage:WaitForChild("MonCalamariRuntime")
require(runtime:WaitForChild("Visuals")).apply()
local spawnCF = runtime:GetAttribute("MainSpawnCF")
local spawn = workspace:WaitForChild("MonCalamariWorld"):WaitForChild("MonCalamariSpawn")

local function characterReady(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= character then return end
	root.Anchored = false
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 50
	-- The SpawnLocation handles placement. Only repair a spawn outside this entry.
	if (root.Position - spawnCF.Position).Magnitude > 24 then
		character:PivotTo(spawnCF)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end
local function added(player)
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(character) characterReady(player, character) end)
	if player.Character then task.spawn(characterReady, player, player.Character) end
end
Players.PlayerAdded:Connect(added)
for _, player in ipairs(Players:GetPlayers()) do added(player) end

local wired = {}
local function door(panel)
	if not panel:IsA("BasePart") or wired[panel] then return end
	wired[panel] = true
	local last = 0
	local prompt = panel:FindFirstChild("DoorPrompt")
	local function toggle(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - panel.Position).Magnitude > math.max(14, panel.Size.Magnitude * 0.5 + 10) then return end
		local now = os.clock()
		if now - last < 0.35 then return end
		last = now
		local open = not panel:GetAttribute("DoorOpen")
		panel:SetAttribute("DoorOpen", open)
		panel.Transparency = open and 0.65 or panel:GetAttribute("ClosedTransparency")
		panel.CanCollide = not open and panel:GetAttribute("ClosedCollision") or false
		if prompt then prompt.ActionText = open and "Fechar" or "Abrir" end
	end
	local click = panel:FindFirstChildOfClass("ClickDetector")
	if click then click.MouseClick:Connect(toggle) end
	if prompt then prompt.Triggered:Connect(toggle) end
end
for _, panel in ipairs(CollectionService:GetTagged("MonCalamariDoor")) do door(panel) end
CollectionService:GetInstanceAddedSignal("MonCalamariDoor"):Connect(door)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 1 then return end
	elapsed = 0
	local now = workspace:GetServerTimeNow()
	local breeze = 9 + math.sin(now * 0.055) * 0.8 + math.sin(now * 0.021) * 0.5
	workspace.GlobalWind = Vector3.new(breeze, 0, breeze * 0.3)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 and root.Position.Y < -100 then
			character:PivotTo(spawnCF)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)
