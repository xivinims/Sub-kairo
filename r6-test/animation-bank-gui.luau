-- Exactly TWO compact mode buttons at the top of the HUD (mobile + desktop).
-- UI merely selects a bank. R6Locomotion, INSIDE this avatar, owns playback.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
if humanoid.RigType ~= Enum.HumanoidRigType.R6 then return end

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("R6AnimationBanks")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "R6AnimationBanks"
gui.ResetOnSpawn = true
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 15
gui.Parent = playerGui

local holder = Instance.new("Frame")
holder.Name = "TopAnimationSwitch"
holder.AnchorPoint = Vector2.new(0.5, 0)
holder.Position = UDim2.new(0.5, 0, 0, 7)
holder.Size = UDim2.fromOffset(246, 36)
holder.BackgroundTransparency = 1
holder.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = holder

local function addButton(name, label)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromOffset(119, 36)
    button.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
    button.BackgroundTransparency = 0.13
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamSemibold
    button.Text = label
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(224, 229, 238)
    button.AutoButtonColor = false
    button.Selectable = true
    button.Parent = holder
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(108, 116, 131)
    stroke.Parent = button
    return button, stroke
end

local standard, standardStroke = addButton("DefaultR6", "R6 PADRÃO")
local files, filesStroke = addButton("UploadedR6", "R6 ARQUIVOS")

local function render()
    local selected = character:GetAttribute("R6AnimationGroup") == "Arquivos" and "Arquivos" or "Padrao"
    for _, data in ipairs({
        {standard, standardStroke, selected == "Padrao"},
        {files, filesStroke, selected == "Arquivos"},
    }) do
        local button, stroke, on = data[1], data[2], data[3]
        button.BackgroundColor3 = on and Color3.fromRGB(233, 239, 247) or Color3.fromRGB(30, 35, 44)
        button.TextColor3 = on and Color3.fromRGB(18, 24, 35) or Color3.fromRGB(226, 232, 242)
        button.BackgroundTransparency = on and 0 or 0.17
        stroke.Color = on and Color3.fromRGB(247, 249, 252) or Color3.fromRGB(101, 113, 133)
    end
end
local function choose(bank)
    if player.Character ~= character or humanoid.Health <= 0 then return end
    if character:GetAttribute("R6AnimationGroup") == bank then return end
    character:SetAttribute("R6AnimationGroup", bank)
    render()
end
standard.Activated:Connect(function() choose("Padrao") end)
files.Activated:Connect(function() choose("Arquivos") end)
character:GetAttributeChangedSignal("R6AnimationGroup"):Connect(render)
if character:GetAttribute("R6AnimationGroup") ~= "Arquivos" then
    character:SetAttribute("R6AnimationGroup", "Padrao")
end
render()
humanoid.Died:Once(function() if gui.Parent then gui:Destroy() end end)
script.Destroying:Once(function() if gui.Parent then gui:Destroy() end end)
