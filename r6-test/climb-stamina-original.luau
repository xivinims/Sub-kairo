--!strict

local StaminaBar = {}
StaminaBar.__index = StaminaBar

local TweenService : TweenService = game:GetService("TweenService")

function StaminaBar.Init(Character : Model)
	local Bar = script.Parent.Parent.Stamina
	local ScaleBar = Bar.Frame.Bar
	local MaxOutput = 100
	local Count = Character:GetAttribute("Stamina") or 0
	
	local OriginalGradient = ScaleBar.UIGradient.Color :: UIGradient

	Bar.Enabled = true

	ScaleBar.AnchorPoint = Vector2.new(0, 1)
	ScaleBar.Position = UDim2.new(0, 0, 1, 0)

	local function UpdateBar()
		Count = Character:GetAttribute("Stamina") or 0

		local fillRatio = math.clamp(Count / MaxOutput, 0, 1)
		local Goal = {}
		Goal.Size = UDim2.new(1, 0, fillRatio, 0)

		local Tween = TweenService:Create(
			ScaleBar,
			TweenInfo.new(.2, Enum.EasingStyle.Quint),
			Goal
		) :: Tween
		Tween:Play()
		
		if Count <= 30 then
			ScaleBar.UIGradient.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0),
				Color3.fromRGB(255, 0, 0)) --> Red
		elseif Count <= 55 then
			ScaleBar.UIGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0),
				Color3.fromRGB(255, 255, 0)) --> Yellow
		else
			ScaleBar.UIGradient.Color = OriginalGradient
		end
	end

	Character:GetAttributeChangedSignal("Stamina"):Connect(UpdateBar)
	UpdateBar()
end


return StaminaBar