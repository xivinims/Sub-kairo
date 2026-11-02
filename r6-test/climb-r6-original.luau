local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Settings = {
	ClimbingSpeed = 10;
	StaminaDrainRate = 15;
	StaminaRecoveryRate = 12;
	MaxStamina = 100;
	ClimbCooldownTime = 2;
}

local States = {}
States.HoldingForward = false
States.ClimbCooldown = false

local Wall = nil

local Character = script.Parent
local Humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") :: BasePart

local Animate = Character:WaitForChild("Animate")
local StaminaBillboard = Character:WaitForChild("Stamina")
local Animation = Humanoid:LoadAnimation(Animate.climb.ClimbAnim)
local StaminaBar = require(script.StaminaBar)

local function CanClimb(Stamina: number)
	return not States.ClimbCooldown and Wall and States.HoldingForward and Stamina > 0
end

local function SetAttributes()
	if not Character:GetAttribute("Stamina") then
		Character:SetAttribute("Stamina", Settings.MaxStamina)
	end
	if not Character:GetAttribute("Climbing") then
		Character:SetAttribute("Climbing", false)
	end
end

local function CheckOrigin(): Vector3
	if Humanoid.RigType == Enum.HumanoidRigType.R15 then
		return (Character:FindFirstChild("LeftFoot") or HumanoidRootPart).Position
	elseif Humanoid.RigType == Enum.HumanoidRigType.R6 then
		return (Character:FindFirstChild("Right Leg") or HumanoidRootPart).Position
	end
	return HumanoidRootPart.Position
end

StaminaBar.Init(Character)
SetAttributes()

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.W then
		States.HoldingForward = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		States.HoldingForward = false
	end
end)

RunService.Heartbeat:Connect(function(dt)
	local Stamina = Character:GetAttribute("Stamina")
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {Character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local origin = CheckOrigin()
	local result = workspace:Raycast(origin, HumanoidRootPart.CFrame.LookVector * 1.3, rayParams)
	Wall = result and result.Instance or nil

	if CanClimb(Stamina) then
		HumanoidRootPart.Velocity = Vector3.new(0, Settings.ClimbingSpeed, 0)

		if Humanoid.RigType == Enum.HumanoidRigType.R15 and Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
			Humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
		end

		if not Animation.IsPlaying then
			Animation:Play()
		end

		Character:SetAttribute("Climbing", true)
		StaminaBillboard.Enabled = true

		Stamina -= Settings.StaminaDrainRate * dt
		Stamina = math.max(Stamina, 0)
		Character:SetAttribute("Stamina", Stamina)

		if Stamina <= 0 then
			States.ClimbCooldown = true
			Character:SetAttribute("Climbing", false)
			Animation:Stop()
			task.spawn(function()
				task.wait(Settings.ClimbCooldownTime)
				States.ClimbCooldown = false
			end)
		end
	else
		Stamina += Settings.StaminaRecoveryRate * dt
		Stamina = math.min(Stamina, Settings.MaxStamina)
		Character:SetAttribute("Stamina", Stamina)

		Animation:Stop()
		Character:SetAttribute("Climbing", false)

		if Stamina < Settings.MaxStamina then
			StaminaBillboard.Enabled = true
		else
			StaminaBillboard.Enabled = false
		end
	end
end)
