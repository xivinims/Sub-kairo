-- DEAD SIGNAL — sliding, screen-based FPS front menu.
-- The room is a lightweight local scene; opening a tab slides its page and pans
-- the camera along the same set. The live combat map and server scripts stay intact.
local REVISION = 'fps-menu-sliding-v1'
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local SoundService = game:GetService('SoundService')
local Lighting = game:GetService('Lighting')
local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')
local camera = workspace.CurrentCamera
local initialCharacter = player.Character or player.CharacterAdded:Wait()
local controls

local function getControls()
	if controls then return controls end
	local ok, module = pcall(function()
		return require(player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'))
	end)
	if ok and module then controls = module:GetControls() end
	return controls
end

local function part(parent, name, size, cf, color, material, transparency)
	local p = Instance.new('Part')
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

local function rounded(parent, radius)
	local c = Instance.new('UICorner')
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new('UIStroke')
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function makeScene()
	local old = workspace:FindFirstChild('DeadSignalLocalMenuScene')
	if old then old:Destroy() end
	local scene = Instance.new('Folder')
	scene.Name = 'DeadSignalLocalMenuScene'
	scene.Parent = workspace
	local origin = Vector3.new(0, 18000, 0)
	local tile = 8
	local dark = Color3.fromRGB(12, 25, 54)
	local blue = Color3.fromRGB(32, 91, 151)
	local pale = Color3.fromRGB(91, 166, 217)
	local waterBlue = Color3.fromRGB(71, 164, 219)
	part(scene, 'FloatingStage', Vector3.new(104, 2, 104), CFrame.new(origin + Vector3.new(0, -1.5, 0)), dark, Enum.Material.Slate)
	for row = 0, 8 do
		for col = 0, 9 do
			local x = (col - 4.5) * tile
			local z = (row - 4) * tile
			local checker = (row + col) % 2 == 0
			part(scene, 'CheckerTile', Vector3.new(tile - .06, .12, tile - .06), CFrame.new(origin + Vector3.new(x, -.42, z)), checker and blue or dark, Enum.Material.SmoothPlastic)
		end
	end
	-- Glossy central lane echoes the reference scene without expensive water simulation.
	local water = part(scene, 'GlassWaterLane', Vector3.new(13, .08, 81), CFrame.new(origin + Vector3.new(0, -.29, 0)), waterBlue, Enum.Material.Glass, .28)
	water.Reflectance = .12
	for side = -1, 1, 2 do
		for index = 0, 2 do
			local z = -30 + index * 29
			local h = 15 + (index % 2) * 4
			local x = side * (19 + (index % 2) * 4)
			local block = part(scene, 'BlueCheckeredPillar', Vector3.new(8, h, 8), CFrame.new(origin + Vector3.new(x, h / 2, z)), (index + side) % 2 == 0 and blue or dark, Enum.Material.SmoothPlastic)
			for band = 0, 2 do
				if (index + band) % 2 == 0 then
					part(scene, 'PillarBlueSquare', Vector3.new(.14, 3.7, 3.7), CFrame.new(origin + Vector3.new(x - side * 4.05, 2 + band * 4.5, z)), pale, Enum.Material.SmoothPlastic)
				end
			end
			block:SetAttribute('DecorativeOnly', true)
		end
	end
	for _, x in ipairs({-43, 43}) do
		part(scene, 'RoomWall', Vector3.new(1.5, 26, 100), CFrame.new(origin + Vector3.new(x, 12, 0)), dark, Enum.Material.SmoothPlastic)
	end
	local glow = part(scene, 'SoftBlueLight', Vector3.new(1, 1, 1), CFrame.new(origin + Vector3.new(0, 9, -35)), pale, Enum.Material.Neon, 1)
	local light = Instance.new('PointLight')
	light.Color = waterBlue
	light.Range = 68
	light.Brightness = 1.7
	light.Shadows = false
	light.Parent = glow
	return scene, origin
end

local scene, origin = makeScene()
local blur = Lighting:FindFirstChild('DeadSignalMenuBlur')
if blur then blur:Destroy() end
blur = Instance.new('BlurEffect')
blur.Name = 'DeadSignalMenuBlur'
blur.Size = 0
blur.Parent = Lighting

local screen = Instance.new('ScreenGui')
screen.Name = 'DeadSignalSlidingMenu'
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 900
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local backdrop = Instance.new('Frame')
backdrop.Name = 'GlassOverlay'
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(4, 13, 31)
backdrop.BackgroundTransparency = .54
backdrop.BorderSizePixel = 0
backdrop.Parent = screen
local shade = Instance.new('UIGradient')
shade.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 16, 38)),
	ColorSequenceKeypoint.new(.52, Color3.fromRGB(9, 34, 67)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 12, 31)),
})
shade.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, .12),
	NumberSequenceKeypoint.new(.5, .56),
	NumberSequenceKeypoint.new(1, .16),
})
shade.Parent = backdrop

local safe = Instance.new('Frame')
safe.Name = 'MenuSafeArea'
safe.AnchorPoint = Vector2.new(.5, .5)
safe.Position = UDim2.fromScale(.5, .5)
safe.Size = UDim2.fromScale(1, 1)
safe.BackgroundTransparency = 1
safe.Parent = backdrop
local scale = Instance.new('UIScale')
scale.Parent = safe
local function fit()
	local size = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local factor = math.min(size.X / 720, size.Y / 500, 1)
	scale.Scale = math.clamp(factor, .48, 1)
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(fit)

local pages = {}
local active = 'home'
local busy = false
local cameraTween
local cameraBase = CFrame.lookAt(origin + Vector3.new(0, 8.5, 31), origin + Vector3.new(0, 2.5, -2))
local originalFov = camera.FieldOfView
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = cameraBase
camera.FieldOfView = 63
local menuSettings = {music = true, shadows = true, cameraDrift = true}
local originalVolume = SoundService.Volume
local originalShadows = Lighting.GlobalShadows
local driftConnection
local entered = false

local function text(parent, name, value, size, position, fontSize, color)
	local t = Instance.new('TextLabel')
	t.Name = name
	t.Text = value
	t.Size = size
	t.Position = position
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Gotham
	t.TextSize = fontSize
	t.TextColor3 = color or Color3.fromRGB(236, 243, 250)
	t.TextWrapped = true
	t.Parent = parent
	return t
end
local closeMenu

local function makeButton(parent, name, value, size, position, emphasized)
	local b = Instance.new('TextButton')
	b.Name = name
	b.Text = value
	b.Size = size
	b.Position = position
	b.AutoButtonColor = false
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 18
	b.TextColor3 = Color3.fromRGB(238, 245, 251)
	b.BackgroundColor3 = emphasized and Color3.fromRGB(29, 91, 148) or Color3.fromRGB(7, 19, 42)
	b.BackgroundTransparency = emphasized and .08 or .25
	b.BorderSizePixel = 0
	b.Parent = parent
	rounded(b, 7)
	stroke(b, emphasized and Color3.fromRGB(147, 213, 249) or Color3.fromRGB(115, 174, 218), 1, .36)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(.13), {BackgroundTransparency = .02}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(.13), {BackgroundTransparency = emphasized and .08 or .25}):Play()
	end)
	return b
end

local pageHost = Instance.new('Frame')
pageHost.Name = 'SlidingPages'
pageHost.AnchorPoint = Vector2.new(.5, .5)
pageHost.Position = UDim2.fromScale(.49, .53)
pageHost.Size = UDim2.fromOffset(680, 442)
pageHost.BackgroundTransparency = 1
pageHost.ClipsDescendants = true
pageHost.Parent = safe

local function newPage(name, titleText, subtitle)
	local page = Instance.new('Frame')
	page.Name = name
	page.Size = UDim2.fromScale(1, 1)
	page.Position = UDim2.fromScale(0, 0)
	page.BackgroundColor3 = Color3.fromRGB(5, 15, 36)
	page.BackgroundTransparency = .14
	page.BorderSizePixel = 0
	page.Visible = false
	page.Parent = pageHost
	rounded(page, 16)
	stroke(page, Color3.fromRGB(117, 191, 237), 1.2, .38)
	local header = Instance.new('Frame')
	header.Name = 'Header'
	header.Position = UDim2.fromOffset(26, 22)
	header.Size = UDim2.new(1, -52, 0, 56)
	header.BackgroundTransparency = 1
	header.Parent = page
	local title = text(header, 'Title', titleText, UDim2.new(1, -54, 0, 30), UDim2.fromOffset(0, 0), 23, Color3.fromRGB(239, 247, 252))
	title.Font = Enum.Font.GothamMedium
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	local rule = Instance.new('Frame')
	rule.Name = 'TitleRule'
	rule.Position = UDim2.fromOffset(0, 38)
	rule.Size = UDim2.new(1, 0, 0, 2)
	rule.BackgroundColor3 = Color3.fromRGB(129, 201, 238)
	rule.BackgroundTransparency = .17
	rule.BorderSizePixel = 0
	rule.Parent = header
	local copy = text(page, 'Subtitle', subtitle or '', UDim2.new(1, -52, 0, 34), UDim2.fromOffset(26, 87), 14, Color3.fromRGB(179, 205, 222))
	copy.TextXAlignment = Enum.TextXAlignment.Left
	local close = makeButton(page, 'Close', '×', UDim2.fromOffset(38, 38), UDim2.new(1, -54, 0, 17), true)
	close.BackgroundColor3 = Color3.fromRGB(214, 36, 139)
	close.TextSize = 27
	close.Activated:Connect(function()
		if name == 'Home' then
			if closeMenu then closeMenu() end
		else
			busy = true
			active = 'home'
			pages.home.Visible = true
			pages.home.Position = UDim2.fromScale(-1.12, 0)
			TweenService:Create(page, TweenInfo.new(.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.fromScale(1.12, 0)}):Play()
			local slide = TweenService:Create(pages.home, TweenInfo.new(.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, 0)})
			slide:Play()
			if cameraTween then cameraTween:Cancel() end
			cameraTween = TweenService:Create(camera, TweenInfo.new(.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {CFrame = cameraBase})
			cameraTween:Play()
			slide.Completed:Connect(function()
				page.Visible = false
				page.Position = UDim2.fromScale(0, 0)
				busy = false
			end)
		end
	end)
	pages[name:lower()] = page
	return page
end

local home = newPage('Home', 'DEAD SIGNAL', 'FPS • 5 VS 5     /     AURIVANE WORKS')
local hero = text(home, 'HeroTitle', 'ENTRE NA PARTIDA', UDim2.new(1, -72, 0, 42), UDim2.fromOffset(36, 106), 27, Color3.fromRGB(240, 248, 252))
hero.TextXAlignment = Enum.TextXAlignment.Left
local intro = text(home, 'Intro', 'Uma arena. Dois times. Dez minutos para decidir quem domina o mapa.', UDim2.new(1, -72, 0, 44), UDim2.fromOffset(36, 150), 15, Color3.fromRGB(190, 212, 228))
intro.TextXAlignment = Enum.TextXAlignment.Left
local nav = Instance.new('Frame')
nav.Name = 'Navigation'
nav.BackgroundTransparency = 1
nav.Position = UDim2.fromOffset(36, 215)
nav.Size = UDim2.new(1, -72, 0, 194)
nav.Parent = home
local play = makeButton(nav, 'Play', '▶     JOGAR', UDim2.new(1, 0, 0, 43), UDim2.fromOffset(0, 0), true)
local settingsButton = makeButton(nav, 'Settings', '⚙     CONFIGURAÇÕES', UDim2.new(1, 0, 0, 43), UDim2.fromOffset(0, 50), false)
local creditsButton = makeButton(nav, 'Credits', '☷     CRÉDITOS', UDim2.new(1, 0, 0, 43), UDim2.fromOffset(0, 100), false)
local updatesButton = makeButton(nav, 'UpdateLog', '▣     REGISTRO DE ATUALIZAÇÕES', UDim2.new(1, 0, 0, 43), UDim2.fromOffset(0, 150), false)
local buildText = text(home, 'Build', 'VERSÃO FPS 261', UDim2.fromOffset(180, 18), UDim2.new(1, -208, 1, -29), 10, Color3.fromRGB(130, 170, 197))
buildText.TextXAlignment = Enum.TextXAlignment.Right

local settings = newPage('Settings', 'CONFIGURAÇÕES', 'Preferências locais para esta sessão.')
local credits = newPage('Credits', 'CRÉDITOS', 'QUEM ESTÁ POR TRÁS DO JOGO')
local updates = newPage('Updates', 'REGISTRO DE ATUALIZAÇÕES', 'FPS • BUILD 261')

local function bodyText(parent, name, content, y, height)
	local label = text(parent, name, content, UDim2.new(1, -60, 0, height), UDim2.fromOffset(30, y), 16, Color3.fromRGB(218, 231, 240))
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	return label
end
bodyText(credits, 'Creators', 'AURIVANE WORKS\n\nJogo FPS 5 contra 5\nMapa Fallout • Lobby flutuante\nArmas e sistemas de combate originais', 139, 190)
bodyText(updates, 'UpdateNotes', '• Base de FPS restaurada\n• HUD original e oito armas preservados\n• Times Azul e Vermelho\n• Partidas de 10 minutos\n• Lobby com loja e progressão', 139, 208)

local settingsRows = {}
local function refreshSetting(row)
	local value = menuSettings[row.key]
	row.button.Text = row.label .. '     ' .. (value and 'LIGADO' or 'DESLIGADO')
	row.button.BackgroundColor3 = value and Color3.fromRGB(20, 76, 111) or Color3.fromRGB(25, 31, 45)
end
local function addSetting(key, labelText, y)
	local button = makeButton(settings, 'Toggle_' .. key, '', UDim2.new(1, -60, 0, 48), UDim2.fromOffset(30, y), false)
	button.TextXAlignment = Enum.TextXAlignment.Left
	local row = {key = key, label = labelText, button = button}
	settingsRows[key] = row
	refreshSetting(row)
	button.Activated:Connect(function()
		menuSettings[key] = not menuSettings[key]
		if key == 'music' then SoundService.Volume = menuSettings.music and originalVolume or 0 end
		if key == 'shadows' then Lighting.GlobalShadows = menuSettings.shadows and originalShadows or false end
		refreshSetting(row)
	end)
end
addSetting('music', 'ÁUDIO DO JOGO', 137)
addSetting('shadows', 'SOMBRAS', 194)
addSetting('cameraDrift', 'MOVIMENTO DA CÂMERA', 251)
bodyText(settings, 'SettingsNote', 'As alterações de áudio e sombras valem para você. Os controles da partida continuam os padrões do Roblox.', 321, 66)

home.Visible = true
local pageOrder = {home = 1, settings = 2, credits = 3, updates = 4}
local function goTo(name)
	if busy or name == active then return end
	local old = pages[active]
	local nextPage = pages[name]
	if not old or not nextPage then return end
	busy = true
	local direction = (pageOrder[name] or 1) >= (pageOrder[active] or 1) and 1 or -1
	old.Visible = true
	nextPage.Visible = true
	nextPage.Position = UDim2.fromScale(direction * 1.12, 0)
	TweenService:Create(old, TweenInfo.new(.43, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(-direction * 1.12, 0)}):Play()
	local transition = TweenService:Create(nextPage, TweenInfo.new(.43, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, 0)})
	transition:Play()
	local offset = name == 'settings' and -4 or name == 'credits' and 4 or name == 'updates' and 2 or 0
	local target = CFrame.lookAt(origin + Vector3.new(offset, 8.5, 31), origin + Vector3.new(offset * .55, 2.5, -2))
	if cameraTween then cameraTween:Cancel() end
	cameraTween = TweenService:Create(camera, TweenInfo.new(.62, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {CFrame = target})
	cameraTween:Play()
	active = name
	transition.Completed:Wait()
	old.Visible = false
	old.Position = UDim2.fromScale(0, 0)
	busy = false
end

settingsButton.Activated:Connect(function() goTo('settings') end)
creditsButton.Activated:Connect(function() goTo('credits') end)
updatesButton.Activated:Connect(function() goTo('updates') end)

closeMenu = function()
	if entered then return end
	entered = true
	if driftConnection then driftConnection:Disconnect() end
	if cameraTween then cameraTween:Cancel() end
	TweenService:Create(backdrop, TweenInfo.new(.32), {BackgroundTransparency = 1}):Play()
	TweenService:Create(blur, TweenInfo.new(.32), {Size = 0}):Play()
	task.wait(.34)
	local character = player.Character or initialCharacter
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	if camera and humanoid then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
		camera.FieldOfView = originalFov
	end
	local currentControls = getControls()
	if currentControls then pcall(function() currentControls:Enable() end) end
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
	if not menuSettings.music then SoundService.Volume = 0 end
	if not menuSettings.shadows then Lighting.GlobalShadows = false end
	if scene then scene:Destroy() end
	if blur then blur:Destroy() end
	screen:Destroy()
end
play.Activated:Connect(closeMenu)
local escapeConnection = UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape and not entered then closeMenu() end
end)

local function openMenu()
	if entered then return end
	local currentControls = getControls()
	if currentControls then pcall(function() currentControls:Disable() end) end
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
	TweenService:Create(blur, TweenInfo.new(.35), {Size = 6}):Play()
	local idle = 0
	driftConnection = game:GetService('RunService').RenderStepped:Connect(function(dt)
		if entered or not menuSettings.cameraDrift or busy then return end
		idle += dt
		local offset = active == 'settings' and -4 or active == 'credits' and 4 or active == 'updates' and 2 or 0
		local sway = math.sin(idle * .32) * .5
		camera.CFrame = CFrame.lookAt(origin + Vector3.new(offset + sway, 8.5, 31), origin + Vector3.new(offset * .55 + sway * .4, 2.5, -2))
	end)
end

openMenu()
player:SetAttribute('DeadSignalMenuRevision', REVISION)
player:SetAttribute('DeadSignalMenuReady', true)

player.CharacterAdded:Connect(function(character)
	if not entered then
		initialCharacter = character
		openMenu()
	end
end)

screen.AncestryChanged:Connect(function(_, parent)
	if not parent then
		if driftConnection then driftConnection:Disconnect() end
		if escapeConnection then escapeConnection:Disconnect() end
		if scene and scene.Parent then scene:Destroy() end
		if blur and blur.Parent then blur:Destroy() end
	end
end)
