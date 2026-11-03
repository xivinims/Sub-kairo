local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "DeadSignalLoadingGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
gui.Parent = player:WaitForChild("PlayerGui")

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(35, 45, 38)
bg.BorderSizePixel = 0
bg.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 58, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 28, 24)),
})
gradient.Rotation = 28
gradient.Parent = bg

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.fromScale(0.42, 0.34)
card.BackgroundColor3 = Color3.fromRGB(249, 241, 216)
card.BorderSizePixel = 0
card.Parent = bg

local size = Instance.new("UISizeConstraint")
size.MinSize = Vector2.new(300, 220)
size.MaxSize = Vector2.new(620, 390)
size.Parent = card

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 22)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(71, 48, 38)
stroke.Thickness = 3
stroke.Parent = card

local ribbon = Instance.new("Frame")
ribbon.Size = UDim2.new(1, 0, 0, 18)
ribbon.BackgroundColor3 = Color3.fromRGB(144, 31, 31)
ribbon.BorderSizePixel = 0
ribbon.Parent = card

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -36, 0, 52)
title.Position = UDim2.new(0, 18, 0, 36)
title.Font = Enum.Font.GothamBold
title.Text = "Entrando no lobby..."
title.TextSize = 27
title.TextColor3 = Color3.fromRGB(56, 43, 35)
title.Parent = card

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, -40, 0, 48)
subtitle.Position = UDim2.new(0, 20, 0, 88)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Preparando o mapa, as pessoas e as folhinhas."
subtitle.TextWrapped = true
subtitle.TextSize = 15
subtitle.TextColor3 = Color3.fromRGB(103, 88, 72)
subtitle.Parent = card

local book = Instance.new("Frame")
book.AnchorPoint = Vector2.new(0.5, 0)
book.Position = UDim2.fromScale(0.5, 0.48)
book.Size = UDim2.fromOffset(128, 72)
book.BackgroundColor3 = Color3.fromRGB(112, 28, 28)
book.BorderSizePixel = 0
book.Parent = card
Instance.new("UICorner", book).CornerRadius = UDim.new(0, 12)

for side = 0, 1 do
    local page = Instance.new("Frame")
    page.Size = UDim2.new(0.43, 0, 0.78, 0)
    page.Position = UDim2.new(side == 0 and 0.05 or 0.52, 0, 0.11, 0)
    page.BackgroundColor3 = Color3.fromRGB(250, 244, 222)
    page.BorderSizePixel = 0
    page.Parent = book
    Instance.new("UICorner", page).CornerRadius = UDim.new(0, 6)
end

local spine = Instance.new("Frame")
spine.AnchorPoint = Vector2.new(0.5, 0)
spine.Position = UDim2.fromScale(0.5, 0.08)
spine.Size = UDim2.new(0, 8, 0.84, 0)
spine.BackgroundColor3 = Color3.fromRGB(54, 39, 31)
spine.BorderSizePixel = 0
spine.Parent = book

for i = 1, 4 do
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, i / 5, 0)
    ring.Size = UDim2.fromOffset(22, 7)
    ring.BackgroundColor3 = Color3.fromRGB(177, 112, 46)
    ring.BorderSizePixel = 0
    ring.Parent = book
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
end

local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 1)
barBack.Position = UDim2.new(0.5, 0, 1, -34)
barBack.Size = UDim2.new(0.78, 0, 0, 12)
barBack.BackgroundColor3 = Color3.fromRGB(214, 200, 168)
barBack.BorderSizePixel = 0
barBack.Parent = card
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(149, 42, 42)
bar.BorderSizePixel = 0
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local percent = Instance.new("TextLabel")
percent.BackgroundTransparency = 1
percent.AnchorPoint = Vector2.new(0.5, 1)
percent.Position = UDim2.new(0.5, 0, 1, -8)
percent.Size = UDim2.fromOffset(160, 20)
percent.Font = Enum.Font.GothamMedium
percent.Text = "0%"
percent.TextSize = 13
percent.TextColor3 = Color3.fromRGB(115, 96, 76)
percent.Parent = card

local pageSound = Instance.new("Sound")
pageSound.SoundId = "rbxassetid://12222076"
pageSound.Volume = 0.35
pageSound.Parent = gui

pcall(function()
    ContentProvider:PreloadAsync({pageSound})
end)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

for i = 1, 100 do
    bar.Size = UDim2.fromScale(i / 100, 1)
    percent.Text = tostring(i) .. "%"
    if i == 54 then
        pcall(function() pageSound:Play() end)
    end
    task.wait(i < 80 and 0.012 or 0.018)
end

TweenService:Create(bg, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 1,
}):Play()
TweenService:Create(card, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
    Position = UDim2.fromScale(0.5, 0.55),
    BackgroundTransparency = 1,
}):Play()

task.wait(0.4)
gui:Destroy()
