local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local DialogueController = {}
DialogueController.__index = DialogueController

function DialogueController.new(parentGui)
    local self = setmetatable({}, DialogueController)

    local frame = Instance.new("Frame")
    frame.Name = "DialoguePanel"
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.Position = UDim2.new(0.5, 0, 1, 160)
    frame.Size = UDim2.new(0.78, 0, 0, 132)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 21)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = parentGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

    local size = Instance.new("UISizeConstraint")
    size.MinSize = Vector2.new(340, 120)
    size.MaxSize = Vector2.new(900, 160)
    size.Parent = frame

    local speaker = Instance.new("TextLabel")
    speaker.Position = UDim2.fromOffset(22, 14)
    speaker.Size = UDim2.new(1, -44, 0, 24)
    speaker.BackgroundTransparency = 1
    speaker.Font = Enum.Font.GothamBold
    speaker.Text = ""
    speaker.TextSize = 15
    speaker.TextColor3 = Color3.fromRGB(180, 68, 72)
    speaker.TextXAlignment = Enum.TextXAlignment.Left
    speaker.Parent = frame

    local text = Instance.new("TextLabel")
    text.Position = UDim2.fromOffset(22, 41)
    text.Size = UDim2.new(1, -44, 0, 68)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.Gotham
    text.Text = ""
    text.TextWrapped = true
    text.TextSize = 16
    text.TextColor3 = Color3.fromRGB(242, 239, 228)
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Parent = frame

    local prompt = Instance.new("TextLabel")
    prompt.AnchorPoint = Vector2.new(1, 1)
    prompt.Position = UDim2.new(1, -18, 1, -10)
    prompt.Size = UDim2.fromOffset(180, 18)
    prompt.BackgroundTransparency = 1
    prompt.Font = Enum.Font.GothamMedium
    prompt.Text = "toque para continuar"
    prompt.TextSize = 11
    prompt.TextColor3 = Color3.fromRGB(143, 139, 130)
    prompt.TextXAlignment = Enum.TextXAlignment.Right
    prompt.Parent = frame

    self.Frame = frame
    self.Speaker = speaker
    self.Text = text
    self.Prompt = prompt
    self.AdvanceRequested = Instance.new("BindableEvent")
    self.Current = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.AdvanceRequested:Fire()
        end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not frame.Visible then return end
        if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
            self.AdvanceRequested:Fire()
        end
    end)

    return self
end

function DialogueController:Show(line)
    self.Current = line
    self.Speaker.Text = line.speaker and line.speaker.displayName or "???"
    self.Text.Text = line.text or ""
    self.Prompt.Text = line.radio and "TRANSMISSÃO • continuar" or "continuar"
    self.Frame.Visible = true
    self.Frame.Position = UDim2.new(0.5, 0, 1, 160)
    TweenService:Create(self.Frame, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 1, -24),
    }):Play()
end

function DialogueController:Hide()
    local tween = TweenService:Create(self.Frame, TweenInfo.new(0.18), {
        Position = UDim2.new(0.5, 0, 1, 160),
    })
    tween:Play()
    tween.Completed:Wait()
    self.Frame.Visible = false
    self.Current = nil
end

return DialogueController
