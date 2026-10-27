local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local ScreenEffectsController = {}
ScreenEffectsController.__index = ScreenEffectsController

function ScreenEffectsController.new()
    local self = setmetatable({}, ScreenEffectsController)

    local color = Lighting:FindFirstChild("DeadSignalScreenColor")
    if not color then
        color = Instance.new("ColorCorrectionEffect")
        color.Name = "DeadSignalScreenColor"
        color.Brightness = 0
        color.Contrast = 0
        color.Saturation = 0
        color.Parent = Lighting
    end

    self.Color = color
    self.CameraShake = 0
    return self
end

function ScreenEffectsController:PulseDanger(strength)
    strength = math.clamp(tonumber(strength) or 0.5, 0, 1)
    self.Color.TintColor = Color3.fromRGB(255, 255 - 75 * strength, 255 - 75 * strength)
    self.Color.Contrast = 0.12 * strength
    TweenService:Create(self.Color, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TintColor = Color3.new(1,1,1),
        Contrast = 0,
    }):Play()
end

function ScreenEffectsController:SetPowerFailure(active)
    TweenService:Create(self.Color, TweenInfo.new(0.3), {
        Brightness = active and -0.12 or 0,
        Saturation = active and -0.22 or 0,
    }):Play()
end

return ScreenEffectsController
