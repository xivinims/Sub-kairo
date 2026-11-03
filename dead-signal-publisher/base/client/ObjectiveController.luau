local TweenService = game:GetService("TweenService")

local ObjectiveController = {}
ObjectiveController.__index = ObjectiveController

function ObjectiveController.new(parentGui)
    local self = setmetatable({}, ObjectiveController)

    local frame = Instance.new("Frame")
    frame.Name = "ObjectivePanel"
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.Size = UDim2.fromOffset(330, 92)
    frame.BackgroundColor3 = Color3.fromRGB(18, 21, 20)
    frame.BackgroundTransparency = 0.18
    frame.BorderSizePixel = 0
    frame.Parent = parentGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 13)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(113, 37, 39)
    stroke.Thickness = 2
    stroke.Transparency = 0.25
    stroke.Parent = frame

    local chapter = Instance.new("TextLabel")
    chapter.Name = "Chapter"
    chapter.Position = UDim2.fromOffset(15, 10)
    chapter.Size = UDim2.new(1, -30, 0, 20)
    chapter.BackgroundTransparency = 1
    chapter.Font = Enum.Font.GothamBold
    chapter.Text = "DEAD SIGNAL"
    chapter.TextSize = 12
    chapter.TextColor3 = Color3.fromRGB(181, 72, 75)
    chapter.TextXAlignment = Enum.TextXAlignment.Left
    chapter.Parent = frame

    local text = Instance.new("TextLabel")
    text.Name = "Objective"
    text.Position = UDim2.fromOffset(15, 31)
    text.Size = UDim2.new(1, -30, 0, 48)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamMedium
    text.Text = "Explore o local."
    text.TextWrapped = true
    text.TextSize = 15
    text.TextColor3 = Color3.fromRGB(241, 237, 225)
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Parent = frame

    self.Frame = frame
    self.ChapterLabel = chapter
    self.ObjectiveLabel = text
    return self
end

function ObjectiveController:SetChapter(text)
    self.ChapterLabel.Text = string.upper(text or "")
end

function ObjectiveController:SetObjective(text, completed)
    local frame = self.Frame
    if completed then
        self.ObjectiveLabel.Text = "✓ " .. tostring(text)
        self.ObjectiveLabel.TextColor3 = Color3.fromRGB(154, 201, 142)
    else
        self.ObjectiveLabel.Text = tostring(text)
        self.ObjectiveLabel.TextColor3 = Color3.fromRGB(241, 237, 225)
    end

    frame.Position = UDim2.new(0, -350, 0, 20)
    TweenService:Create(frame, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 20, 0, 20),
    }):Play()
end

function ObjectiveController:SetVisible(visible)
    self.Frame.Visible = visible
end

return ObjectiveController
