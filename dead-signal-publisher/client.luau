local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("DeadSignalRemotes")
local getSettings = remotes:WaitForChild("GetSettings")
local saveSettings = remotes:WaitForChild("SaveSettings")
local world = workspace:WaitForChild("DeadSignalLobby")
local leafAnchors = world:WaitForChild("LeafAnchors")

local DEFAULTS = {
    profileOnTap = true,
    showNames = true,
    uiMotion = true,
    leafFx = true,
    leafDensity = 0.7,
    sfxVolume = 0.8,
}

local settings = {}
for k, v in pairs(DEFAULTS) do settings[k] = v end

pcall(function()
    local loaded = getSettings:InvokeServer()
    if type(loaded) == "table" then
        for k, v in pairs(DEFAULTS) do
            if loaded[k] ~= nil then settings[k] = loaded[k] else settings[k] = v end
        end
    end
end)

local function save()
    saveSettings:FireServer(settings)
end

local gui = Instance.new("ScreenGui")
gui.Name = "DeadSignalInterface"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = playerGui

local pageSound = Instance.new("Sound")
pageSound.Name = "PageTurn"
pageSound.SoundId = "rbxassetid://12222076"
pageSound.Volume = settings.sfxVolume
pageSound.Parent = SoundService

local function playPage()
    pageSound.Volume = settings.sfxVolume
    if settings.sfxVolume > 0 then
        pageSound.TimePosition = 0
        pageSound:Play()
    end
end

local function rounded(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function label(parent, text, size, pos, textSize, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = size
    l.Position = pos
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.Text = text
    l.TextSize = textSize or 16
    l.TextColor3 = Color3.fromRGB(55, 45, 38)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Parent = parent
    return l
end

local shade = Instance.new("TextButton")
shade.Name = "BookShade"
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(5, 6, 6)
shade.BackgroundTransparency = 0.28
shade.Text = ""
shade.AutoButtonColor = false
shade.Visible = false
shade.ZIndex = 100
shade.Parent = gui

local book = Instance.new("Frame")
book.Name = "SettingsBook"
book.AnchorPoint = Vector2.new(0.5, 0.5)
book.Position = UDim2.fromScale(0.5, 0.5)
book.Size = UDim2.fromScale(0.82, 0.76)
book.BackgroundColor3 = Color3.fromRGB(77, 13, 15)
book.BorderSizePixel = 0
book.Visible = false
book.ZIndex = 101
book.Parent = gui
rounded(book, 18)
stroke(book, Color3.fromRGB(24, 20, 19), 6, 0)

local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1.5
aspect.AspectType = Enum.AspectType.ScaleWithParentSize
aspect.DominantAxis = Enum.DominantAxis.Width
aspect.Parent = book

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(540, 360)
sizeConstraint.MaxSize = Vector2.new(1180, 760)
sizeConstraint.Parent = book

local innerCover = Instance.new("Frame")
innerCover.Position = UDim2.fromScale(0.025, 0.035)
innerCover.Size = UDim2.fromScale(0.95, 0.93)
innerCover.BackgroundColor3 = Color3.fromRGB(28, 27, 26)
innerCover.BorderSizePixel = 0
innerCover.ZIndex = 102
innerCover.Parent = book
rounded(innerCover, 13)
stroke(innerCover, Color3.fromRGB(128, 122, 113), 3, 0)

local topStrip = Instance.new("Frame")
topStrip.Position = UDim2.fromScale(0.03, 0.02)
topStrip.Size = UDim2.fromScale(0.94, 0.045)
topStrip.BackgroundColor3 = Color3.fromRGB(122, 24, 28)
topStrip.BorderSizePixel = 0
topStrip.ZIndex = 104
topStrip.Parent = book
rounded(topStrip, 6)

local leftPage = Instance.new("Frame")
leftPage.Position = UDim2.fromScale(0.055, 0.085)
leftPage.Size = UDim2.fromScale(0.405, 0.84)
leftPage.BackgroundColor3 = Color3.fromRGB(248, 240, 215)
leftPage.BorderSizePixel = 0
leftPage.ZIndex = 105
leftPage.Parent = book
rounded(leftPage, 7)
stroke(leftPage, Color3.fromRGB(78, 64, 50), 2, 0)

local rightPage = Instance.new("Frame")
rightPage.Position = UDim2.fromScale(0.535, 0.085)
rightPage.Size = UDim2.fromScale(0.405, 0.84)
rightPage.BackgroundColor3 = Color3.fromRGB(248, 240, 215)
rightPage.BorderSizePixel = 0
rightPage.ZIndex = 105
rightPage.Parent = book
rounded(rightPage, 7)
stroke(rightPage, Color3.fromRGB(78, 64, 50), 2, 0)

for _, page in ipairs({leftPage, rightPage}) do
    local border = Instance.new("Frame")
    border.Position = UDim2.fromScale(0.035, 0.035)
    border.Size = UDim2.fromScale(0.93, 0.93)
    border.BackgroundTransparency = 1
    border.ZIndex = 106
    border.Parent = page
    stroke(border, Color3.fromRGB(91, 77, 59), 1, 0.35)
end

local spine = Instance.new("Frame")
spine.AnchorPoint = Vector2.new(0.5, 0)
spine.Position = UDim2.fromScale(0.5, 0.055)
spine.Size = UDim2.fromScale(0.052, 0.89)
spine.BackgroundColor3 = Color3.fromRGB(45, 37, 31)
spine.BorderSizePixel = 0
spine.ZIndex = 108
spine.Parent = book
rounded(spine, 8)
stroke(spine, Color3.fromRGB(13, 13, 12), 2, 0)

for i = 1, 7 do
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.11 + (i - 1) * 0.13, 0)
    ring.Size = UDim2.fromScale(0.105, 0.035)
    ring.BackgroundColor3 = Color3.fromRGB(156, 92, 35)
    ring.BorderSizePixel = 0
    ring.ZIndex = 110
    ring.Parent = book
    rounded(ring, 999)
    stroke(ring, Color3.fromRGB(63, 39, 20), 2, 0)

    local hole = Instance.new("Frame")
    hole.AnchorPoint = Vector2.new(0.5, 0.5)
    hole.Position = UDim2.fromScale(0.5, 0.5)
    hole.Size = UDim2.fromScale(0.72, 0.42)
    hole.BackgroundColor3 = Color3.fromRGB(35, 29, 25)
    hole.BorderSizePixel = 0
    hole.ZIndex = 111
    hole.Parent = ring
    rounded(hole, 999)
end

local tabs = {"JOGO", "VISUAL", "SOM", "UI"}
for i, name in ipairs(tabs) do
    local tab = Instance.new("TextLabel")
    tab.AnchorPoint = Vector2.new(0, 0)
    tab.Position = UDim2.new(0.94, 0, 0.12 + (i - 1) * 0.125, 0)
    tab.Size = UDim2.fromScale(0.075, 0.08)
    tab.BackgroundColor3 = i == 1 and Color3.fromRGB(160, 28, 32) or Color3.fromRGB(57, 55, 52)
    tab.BorderSizePixel = 0
    tab.Font = Enum.Font.GothamBold
    tab.Text = name
    tab.TextSize = 11
    tab.TextColor3 = Color3.fromRGB(247, 236, 217)
    tab.ZIndex = 104
    tab.Parent = book
    rounded(tab, 4)
end

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(0.975, 0, 0.02, 0)
close.Size = UDim2.fromOffset(42, 42)
close.BackgroundColor3 = Color3.fromRGB(141, 28, 31)
close.BorderSizePixel = 0
close.Font = Enum.Font.GothamBold
close.Text = "×"
close.TextSize = 28
close.TextColor3 = Color3.fromRGB(255, 240, 224)
close.ZIndex = 120
close.Parent = book
rounded(close, 9)
stroke(close, Color3.fromRGB(42, 26, 24), 2, 0)

local settingsButton = Instance.new("TextButton")
settingsButton.AnchorPoint = Vector2.new(1, 0)
settingsButton.Position = UDim2.new(1, -18, 0, 18)
settingsButton.Size = UDim2.fromOffset(52, 52)
settingsButton.BackgroundColor3 = Color3.fromRGB(90, 28, 30)
settingsButton.BorderSizePixel = 0
settingsButton.Font = Enum.Font.GothamBold
settingsButton.Text = "⚙"
settingsButton.TextSize = 25
settingsButton.TextColor3 = Color3.fromRGB(250, 239, 214)
settingsButton.ZIndex = 30
settingsButton.Parent = gui
rounded(settingsButton, 15)
stroke(settingsButton, Color3.fromRGB(235, 220, 187), 2, 0.2)

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -18)
hint.Size = UDim2.new(0.7, 0, 0, 34)
hint.BackgroundColor3 = Color3.fromRGB(30, 39, 32)
hint.BackgroundTransparency = 0.18
hint.BorderSizePixel = 0
hint.Font = Enum.Font.GothamMedium
hint.Text = "Converse pelo chat • toque em alguém para abrir o perfil"
hint.TextSize = 13
hint.TextColor3 = Color3.fromRGB(245, 239, 221)
hint.ZIndex = 20
hint.Parent = gui
rounded(hint, 12)

task.delay(7, function()
    if hint and hint.Parent then
        TweenService:Create(hint, TweenInfo.new(0.4), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
        task.wait(0.45)
        if hint then hint:Destroy() end
    end
end)

local leftContent = Instance.new("Frame")
leftContent.Position = UDim2.fromScale(0.07, 0.07)
leftContent.Size = UDim2.fromScale(0.86, 0.86)
leftContent.BackgroundTransparency = 1
leftContent.ZIndex = 112
leftContent.Parent = leftPage

local rightContent = Instance.new("Frame")
rightContent.Position = UDim2.fromScale(0.07, 0.07)
rightContent.Size = UDim2.fromScale(0.86, 0.86)
rightContent.BackgroundTransparency = 1
rightContent.ZIndex = 112
rightContent.Parent = rightPage

label(leftContent, "JOGO", UDim2.new(1, 0, 0, 35), UDim2.fromOffset(0, 0), 23, true)
local leftIntro = label(leftContent, "Configurações sociais do lobby", UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 35), 13, false)
leftIntro.TextColor3 = Color3.fromRGB(116, 97, 77)

label(rightContent, "VISUAL & SOM", UDim2.new(1, 0, 0, 35), UDim2.fromOffset(0, 0), 23, true)
local rightIntro = label(rightContent, "Efeitos leves para celular", UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 35), 13, false)
rightIntro.TextColor3 = Color3.fromRGB(116, 97, 77)

local controlYLeft = 82
local controlYRight = 82
local refreshNameTags

local function makeToggle(parent, titleText, key, y, description, callback)
    local row = Instance.new("Frame")
    row.Position = UDim2.new(0, 0, 0, y)
    row.Size = UDim2.new(1, 0, 0, 82)
    row.BackgroundTransparency = 1
    row.ZIndex = 114
    row.Parent = parent

    local title = label(row, titleText, UDim2.new(0.72, 0, 0, 25), UDim2.fromOffset(0, 3), 15, true)
    title.ZIndex = 115
    local desc = label(row, description, UDim2.new(0.72, 0, 0, 48), UDim2.fromOffset(0, 29), 11, false)
    desc.TextColor3 = Color3.fromRGB(125, 105, 84)
    desc.ZIndex = 115

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0)
    button.Position = UDim2.new(1, 0, 0, 10)
    button.Size = UDim2.fromOffset(58, 30)
    button.BackgroundColor3 = settings[key] and Color3.fromRGB(151, 42, 43) or Color3.fromRGB(142, 132, 116)
    button.BorderSizePixel = 0
    button.Text = ""
    button.ZIndex = 116
    button.Parent = row
    rounded(button, 999)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = settings[key] and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 15, 0.5, 0)
    knob.Size = UDim2.fromOffset(22, 22)
    knob.BackgroundColor3 = Color3.fromRGB(251, 242, 218)
    knob.BorderSizePixel = 0
    knob.ZIndex = 117
    knob.Parent = button
    rounded(knob, 999)

    local function render(animated)
        local pos = settings[key] and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 15, 0.5, 0)
        local color = settings[key] and Color3.fromRGB(151, 42, 43) or Color3.fromRGB(142, 132, 116)
        if animated and settings.uiMotion then
            TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {Position = pos}):Play()
            TweenService:Create(button, TweenInfo.new(0.16), {BackgroundColor3 = color}):Play()
        else
            knob.Position = pos
            button.BackgroundColor3 = color
        end
    end

    button.Activated:Connect(function()
        settings[key] = not settings[key]
        playPage()
        render(true)
        save()
        if callback then callback(settings[key]) end
    end)

    return row
end

local function makeSlider(parent, titleText, key, y, minValue, maxValue, suffix, callback)
    local row = Instance.new("Frame")
    row.Position = UDim2.new(0, 0, 0, y)
    row.Size = UDim2.new(1, 0, 0, 76)
    row.BackgroundTransparency = 1
    row.ZIndex = 114
    row.Parent = parent

    local title = label(row, titleText, UDim2.new(0.75, 0, 0, 24), UDim2.fromOffset(0, 0), 15, true)
    title.ZIndex = 115

    local valueLabel = label(row, "", UDim2.new(0.25, 0, 0, 24), UDim2.new(0.75, 0, 0, 0), 12, true)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 115

    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 0, 0, 39)
    track.Size = UDim2.new(1, 0, 0, 9)
    track.BackgroundColor3 = Color3.fromRGB(194, 178, 147)
    track.BorderSizePixel = 0
    track.ZIndex = 115
    track.Parent = row
    rounded(track, 999)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Color3.fromRGB(151, 42, 43)
    fill.BorderSizePixel = 0
    fill.ZIndex = 116
    fill.Parent = track
    rounded(fill, 999)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(22, 22)
    knob.BackgroundColor3 = Color3.fromRGB(250, 241, 216)
    knob.BorderSizePixel = 0
    knob.ZIndex = 117
    knob.Parent = track
    rounded(knob, 999)
    stroke(knob, Color3.fromRGB(105, 79, 57), 1, 0)

    local dragging = false

    local function render()
        local alpha = math.clamp((settings[key] - minValue) / (maxValue - minValue), 0, 1)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.fromScale(alpha, 0.5)
        valueLabel.Text = tostring(math.floor(settings[key] * 100 + 0.5)) .. suffix
    end

    local function applyFromX(x)
        local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        settings[key] = minValue + (maxValue - minValue) * alpha
        render()
        if callback then callback(settings[key]) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            applyFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            applyFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            save()
            playPage()
        end
    end)

    render()
    return row
end

makeToggle(leftContent, "Perfil ao tocar", "profileOnTap", controlYLeft,
    "Toque ou clique diretamente no avatar de alguém para abrir o perfil.")
controlYLeft += 94

makeToggle(leftContent, "Mostrar nomes", "showNames", controlYLeft,
    "Exibe o nome acima dos jogadores no lobby.", function()
        if refreshNameTags then refreshNameTags() end
    end)
controlYLeft += 94

makeToggle(leftContent, "Animações da interface", "uiMotion", controlYLeft,
    "Liga ou desliga movimentos suaves do livro e dos painéis.")
controlYLeft += 94

makeToggle(rightContent, "Folhas caindo", "leafFx", controlYRight,
    "Folhinhas físicas leves caem perto das árvores.")
controlYRight += 94

makeSlider(rightContent, "Quantidade de folhas", "leafDensity", controlYRight, 0.25, 1, "%")
controlYRight += 88

makeSlider(rightContent, "Volume dos efeitos", "sfxVolume", controlYRight, 0, 1, "%", function(value)
    pageSound.Volume = value
end)
controlYRight += 88

local note = label(rightContent, "O efeito de folhas é local para manter o lobby leve em celulares.", UDim2.new(1, 0, 0, 54), UDim2.new(0, 0, 1, -62), 11, false)
note.TextColor3 = Color3.fromRGB(125, 105, 84)
note.TextYAlignment = Enum.TextYAlignment.Bottom

local function setBookVisible(visible)
    if visible then
        shade.Visible = true
        book.Visible = true
        playPage()
        if settings.uiMotion then
            book.Size = UDim2.fromScale(0.74, 0.68)
            book.BackgroundTransparency = 0.12
            TweenService:Create(book, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromScale(0.82, 0.76),
                BackgroundTransparency = 0,
            }):Play()
        end
    else
        playPage()
        if settings.uiMotion then
            local tween = TweenService:Create(book, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.fromScale(0.76, 0.70),
                BackgroundTransparency = 0.2,
            })
            tween:Play()
            tween.Completed:Wait()
        end
        book.Visible = false
        shade.Visible = false
        book.Size = UDim2.fromScale(0.82, 0.76)
        book.BackgroundTransparency = 0
    end
end

settingsButton.Activated:Connect(function()
    setBookVisible(true)
end)
close.Activated:Connect(function()
    setBookVisible(false)
end)
shade.Activated:Connect(function()
    setBookVisible(false)
end)

local profileShade = Instance.new("TextButton")
profileShade.Size = UDim2.fromScale(1, 1)
profileShade.BackgroundColor3 = Color3.new(0, 0, 0)
profileShade.BackgroundTransparency = 0.45
profileShade.Text = ""
profileShade.AutoButtonColor = false
profileShade.Visible = false
profileShade.ZIndex = 200
profileShade.Parent = gui

local profile = Instance.new("Frame")
profile.AnchorPoint = Vector2.new(0.5, 0.5)
profile.Position = UDim2.fromScale(0.5, 0.5)
profile.Size = UDim2.fromScale(0.34, 0.42)
profile.BackgroundColor3 = Color3.fromRGB(246, 238, 215)
profile.BorderSizePixel = 0
profile.Visible = false
profile.ZIndex = 201
profile.Parent = gui
rounded(profile, 20)
stroke(profile, Color3.fromRGB(92, 31, 31), 4, 0)

local profileSize = Instance.new("UISizeConstraint")
profileSize.MinSize = Vector2.new(300, 310)
profileSize.MaxSize = Vector2.new(500, 460)
profileSize.Parent = profile

local profileHeader = Instance.new("Frame")
profileHeader.Size = UDim2.new(1, 0, 0, 72)
profileHeader.BackgroundColor3 = Color3.fromRGB(113, 28, 31)
profileHeader.BorderSizePixel = 0
profileHeader.ZIndex = 202
profileHeader.Parent = profile
rounded(profileHeader, 18)

local avatar = Instance.new("ImageLabel")
avatar.Position = UDim2.fromOffset(28, 92)
avatar.Size = UDim2.fromOffset(104, 104)
avatar.BackgroundColor3 = Color3.fromRGB(222, 211, 184)
avatar.BorderSizePixel = 0
avatar.ZIndex = 203
avatar.Parent = profile
rounded(avatar, 52)
stroke(avatar, Color3.fromRGB(89, 67, 48), 2, 0)

local displayName = label(profile, "", UDim2.new(1, -166, 0, 34), UDim2.fromOffset(150, 96), 22, true)
displayName.ZIndex = 203
local username = label(profile, "", UDim2.new(1, -166, 0, 26), UDim2.fromOffset(150, 132), 14, false)
username.TextColor3 = Color3.fromRGB(118, 94, 73)
username.ZIndex = 203
local accountAge = label(profile, "", UDim2.new(1, -166, 0, 48), UDim2.fromOffset(150, 163), 12, false)
accountAge.TextColor3 = Color3.fromRGB(118, 94, 73)
accountAge.ZIndex = 203

local statusText = label(profile, "No lobby agora", UDim2.new(1, -56, 0, 40), UDim2.new(0, 28, 1, -98), 14, true)
statusText.TextColor3 = Color3.fromRGB(70, 104, 63)
statusText.ZIndex = 203

local profileClose = Instance.new("TextButton")
profileClose.AnchorPoint = Vector2.new(1, 0)
profileClose.Position = UDim2.new(1, -18, 0, 15)
profileClose.Size = UDim2.fromOffset(40, 40)
profileClose.BackgroundColor3 = Color3.fromRGB(70, 20, 22)
profileClose.BorderSizePixel = 0
profileClose.Text = "×"
profileClose.TextSize = 26
profileClose.Font = Enum.Font.GothamBold
profileClose.TextColor3 = Color3.fromRGB(252, 240, 216)
profileClose.ZIndex = 204
profileClose.Parent = profile
rounded(profileClose, 10)

local profileTitle = label(profileHeader, "PERFIL", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(24, 0), 18, true)
profileTitle.TextColor3 = Color3.fromRGB(250, 239, 215)
profileTitle.TextYAlignment = Enum.TextYAlignment.Center
profileTitle.ZIndex = 203

local function closeProfile()
    profile.Visible = false
    profileShade.Visible = false
end
profileClose.Activated:Connect(closeProfile)
profileShade.Activated:Connect(closeProfile)

local function openProfile(targetPlayer)
    if not targetPlayer or not settings.profileOnTap then return end
    displayName.Text = targetPlayer.DisplayName
    username.Text = "@" .. targetPlayer.Name
    accountAge.Text = "Conta no Roblox há " .. tostring(targetPlayer.AccountAge) .. " dias"
    avatar.Image = ""
    profileShade.Visible = true
    profile.Visible = true
    playPage()

    task.spawn(function()
        local ok, image = pcall(function()
            return Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
        if ok and targetPlayer.Parent == Players then
            avatar.Image = image
        end
    end)
end

local function playerFromPart(part)
    local current = part
    while current and current ~= workspace do
        if current:IsA("Model") then
            local found = Players:GetPlayerFromCharacter(current)
            if found then return found end
        end
        current = current.Parent
    end
    return nil
end

local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
    if shade.Visible or profileShade.Visible or not settings.profileOnTap then return end
    local target = mouse.Target
    if target then
        openProfile(playerFromPart(target))
    end
end)

UserInputService.TouchTap:Connect(function(positions, processed)
    if processed or shade.Visible or profileShade.Visible or not settings.profileOnTap then return end
    local pos = positions and positions[1]
    if not pos then return end

    local camera = workspace.CurrentCamera
    if not camera then return end
    local ray = camera:ViewportPointToRay(pos.X, pos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if result then
        openProfile(playerFromPart(result.Instance))
    end
end)

local nameTags = {}

local function installNameTag(targetPlayer, character)
    local head = character:WaitForChild("Head", 8)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head then return end
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    if nameTags[targetPlayer] then
        nameTags[targetPlayer]:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DeadSignalName"
    billboard.Size = UDim2.fromOffset(180, 44)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 70
    billboard.Enabled = settings.showNames
    billboard.Adornee = head
    billboard.Parent = playerGui

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.Text = targetPlayer.DisplayName
    text.TextSize = 15
    text.TextColor3 = Color3.fromRGB(255, 246, 224)
    text.TextStrokeTransparency = 0.35
    text.TextStrokeColor3 = Color3.fromRGB(33, 31, 28)
    text.Parent = billboard

    nameTags[targetPlayer] = billboard
end

local function watchPlayer(targetPlayer)
    targetPlayer.CharacterAdded:Connect(function(character)
        installNameTag(targetPlayer, character)
    end)
    if targetPlayer.Character then
        task.spawn(installNameTag, targetPlayer, targetPlayer.Character)
    end
end

refreshNameTags = function()
    for _, billboard in pairs(nameTags) do
        if billboard and billboard.Parent then
            billboard.Enabled = settings.showNames
        end
    end
end

Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(targetPlayer)
    if nameTags[targetPlayer] then
        nameTags[targetPlayer]:Destroy()
        nameTags[targetPlayer] = nil
    end
end)
for _, targetPlayer in ipairs(Players:GetPlayers()) do
    watchPlayer(targetPlayer)
end

local leafColors = {
    Color3.fromRGB(105, 151, 75),
    Color3.fromRGB(139, 168, 86),
    Color3.fromRGB(178, 137, 70),
    Color3.fromRGB(157, 95, 54),
}

local rng = Random.new()
local lastLeaf = 0

local function spawnLeaf(anchor)
    local leaf = Instance.new("WedgePart")
    leaf.Name = "LocalFallingLeaf"
    leaf.Size = Vector3.new(0.16, 0.04, 0.3)
    leaf.Material = Enum.Material.SmoothPlastic
    leaf.Color = leafColors[rng:NextInteger(1, #leafColors)]
    leaf.Transparency = rng:NextNumber(0, 0.15)
    leaf.CanCollide = false
    leaf.CanTouch = false
    leaf.CanQuery = false
    leaf.Massless = true
    leaf.CFrame = CFrame.new(
        anchor.Position + Vector3.new(rng:NextNumber(-7, 7), rng:NextNumber(-1, 4), rng:NextNumber(-7, 7))
    ) * CFrame.Angles(rng:NextNumber(0, 6.2), rng:NextNumber(0, 6.2), rng:NextNumber(0, 6.2))
    leaf.Parent = workspace
    leaf.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-2.4, 2.4), rng:NextNumber(-2.8, -1.3), rng:NextNumber(-2.0, 2.0))
    leaf.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(-6, 6), rng:NextNumber(-6, 6))
    Debris:AddItem(leaf, rng:NextNumber(4.5, 7))
end

RunService.Heartbeat:Connect(function()
    if not settings.leafFx then return end
    local now = os.clock()
    local interval = 0.52 - settings.leafDensity * 0.32
    if now - lastLeaf < interval then return end
    lastLeaf = now

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local nearby = {}
    for _, anchor in ipairs(leafAnchors:GetChildren()) do
        if anchor:IsA("BasePart") and (anchor.Position - root.Position).Magnitude < 115 then
            nearby[#nearby + 1] = anchor
        end
    end
    if #nearby == 0 then return end

    local amount = settings.leafDensity > 0.78 and 2 or 1
    for _ = 1, amount do
        spawnLeaf(nearby[rng:NextInteger(1, #nearby)])
    end
end)
