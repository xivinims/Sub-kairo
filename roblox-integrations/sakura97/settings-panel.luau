-- Reference-inspired settings: category tabs, framed sections, real sliders and checkboxes.
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local Settings={}
local initialized=false
local categories={
 {key="audio",label="ÁUDIO",color=Color3.fromRGB(99,145,212),title="AJUSTES DE ÁUDIO",rows={
  {section="SONS"},{key="EffectsVolume",label="Efeitos e interface",description="Cliques, avisos e regeneração",min=0,max=100,default=80,suffix="%"},
  {key="MenuSounds",label="Sons dos botões",description="Resposta sonora ao tocar",default=true},
  {key="FriendAlerts",label="Avisos de amizade",description="Som quando um amigo entra",default=true},
 }},
 {key="visual",label="VISUAL",color=Color3.fromRGB(160,126,202),title="SETTINGS",rows={
  {section="IMAGEM"},
  {key="CameraFOV",label="Camera FOV",description="Campo de visão da câmera",min=40,max=100,step=1,default=48},
  {key="VisualSaturation",label="Saturation",description="Intensidade das cores",min=-1,max=1,step=.05,decimals=2,default=-.65},
  {key="VisualContrast",label="Contrast",description="Diferença entre áreas claras e escuras",min=-1,max=1,step=.05,decimals=2,default=0},
  {key="VisualExposure",label="Exposure",description="Exposição geral da imagem",min=-2,max=2,step=.1,decimals=1,default=1.5},
  {key="VisualTime",label="Time",description="Horário visual do mapa",min=0,max=23.75,step=.25,format="time",default=8.25},
  {key="MapShadows",label="Shadows",description="Ativa sombras dinâmicas",default=true},
  {section="AVANÇADO"},
  {key="LowGraphics",label="Gráficos leves",description="Reduz pós-processamento e efeitos",default=UIS.TouchEnabled},
  {key="Reflections",label="Reflexos",description="Água e superfícies recebem reflexos especulares leves",default=not UIS.TouchEnabled},
  {key="ReducedMotion",label="Menos movimento",description="Reduz movimentos da câmera e do menu",default=false},
  {section="JOGADORES"},{key="ShowNametags",label="Nomes dos jogadores",description="Mostra os nomes acima dos avatares",default=true},
 }},
 {key="gameplay",label="JOGO",color=Color3.fromRGB(118,166,112),title="AJUSTES DE JOGO",rows={
  {key="AFK",label="AFK",description="Fica fora das próximas partidas; a atual continua",default=false},
  {section="CÂMERA E CONTROLES"},
  {key="ControlScale",label="Tamanho dos botões",description="Ajuste para o seu polegar",min=80,max=120,default=100,suffix="%"},
  {section="COMO SOBREVIVER"},{info="Correr e pular fazem barulho. Quebre a linha de visão e use obstáculos para despistar o perseguidor."},
  {info="Segure CORRER para acelerar e solte para voltar a andar. Jogadores feridos não conseguem correr."},
  {info="Se alguém cair, outro sobrevivente tem 30 segundos para chegar perto e usar o botão +."},
  {info="As partidas começam automaticamente. Ative AFK para ficar no lobby."},
 }},
}
local function corner(o,r) local c=Instance.new("UICorner",o) c.CornerRadius=UDim.new(0,r or 9) end
local function stroke(o,color,width,alpha) local s=Instance.new("UIStroke",o) s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Color=color s.Thickness=width or 1 s.Transparency=alpha or .4 return s end
local function label(parent,value,size,pos,font)
 local t=Instance.new("TextLabel",parent) t.BackgroundTransparency=1 t.Text=value t.Size=size t.Position=pos or UDim2.new() t.TextColor3=Color3.fromRGB(235,234,239) t.TextSize=15 t.Font=font or Enum.Font.GothamBold t.TextXAlignment=Enum.TextXAlignment.Left t.TextWrapped=true t.ZIndex=parent.ZIndex+1 return t
end
local function button(parent,value,color)
 local b=Instance.new("TextButton",parent) b.Text=value b.BackgroundColor3=color b.BackgroundTransparency=.35 b.BorderSizePixel=0 b.TextColor3=Color3.fromRGB(243,241,244) b.TextStrokeTransparency=.55 b.TextStrokeColor3=Color3.new(0,0,0) b.Font=Enum.Font.GothamBold b.TextSize=14 b.ZIndex=parent.ZIndex+2 b.AutoButtonColor=true corner(b,9) stroke(b,color,2,.15)
 local inner=Instance.new("Frame",b) inner.Name="Inset" inner.BackgroundTransparency=1 inner.Size=UDim2.new(1,-8,1,-8) inner.Position=UDim2.fromOffset(4,4) inner.ZIndex=b.ZIndex corner(inner,6) stroke(inner,Color3.fromRGB(220,218,226),1,.8)
 return b
end
function Settings.initialize(player)
 if initialized then return end initialized=true
 for _,category in ipairs(categories) do for _,row in ipairs(category.rows) do
  if row.key and player:GetAttribute(row.key)==nil then player:SetAttribute(row.key,row.default) end
 end end
 local groups={}
 local effects=Instance.new("SoundGroup") effects.Name="SuviversEffects" effects.Parent=SoundService groups.Effects=effects
 local function applyAudio()
  groups.Effects.Volume=(player:GetAttribute("EffectsVolume") or 80)/100
 end
 player:GetAttributeChangedSignal("EffectsVolume"):Connect(applyAudio)
 local function sound(sound)
  if not sound:IsA("Sound") then return end
  if sound.Name=="MenuClick" or sound.Name=="Click" or sound.Name=="PlayClick" or sound.Name=="LightFlicker" or sound.Name=="MapLoadGlitch" or sound.Name=="FriendJoined" or sound.Name=="Regenerate" or sound.Name=="RegenerationCue" then sound.SoundGroup=groups.Effects end
 end
 for _,root in ipairs({SoundService,workspace,player:WaitForChild("PlayerGui")}) do
  root.DescendantAdded:Connect(sound) for _,s in ipairs(root:GetDescendants()) do sound(s) end
 end
 local function shadows() Lighting.GlobalShadows=player:GetAttribute("MapShadows")==true end
 player:GetAttributeChangedSignal("MapShadows"):Connect(shadows) shadows() applyAudio()
end

function Settings.build(parent,player,onClose)
 Settings.initialize(player)
 local Players=game:GetService("Players")
 local UserInputService=UIS
 local TweenService=game:GetService("TweenService")
 local controls={}
 local function connectControl(signal,fn) local c=signal:Connect(fn) table.insert(controls,c) return c end
local root = Instance.new("Frame")
root.Name = "SettingsPanelPro_Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = parent

local function corner(obj: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
	return c
end

local function stroke(obj: Instance, thickness: number, color: Color3, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function pad(parent: Instance, l: number, r: number, t: number, b: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l)
	p.PaddingRight = UDim.new(0, r)
	p.PaddingTop = UDim.new(0, t)
	p.PaddingBottom = UDim.new(0, b)
	p.Parent = parent
	return p
end

local function vlist(parent: Instance, spacing: number)
	local ll = Instance.new("UIListLayout")
	ll.Padding = UDim.new(0, spacing)
	ll.FillDirection = Enum.FillDirection.Vertical
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Parent = parent
	return ll
end

local THEMES = {
	Obsidian = {
		bg = Color3.fromRGB(5, 10, 21),
		panel = Color3.fromRGB(8, 14, 28),
		card = Color3.fromRGB(11, 21, 43),
		card2 = Color3.fromRGB(15, 26, 51),
		stroke = Color3.fromRGB(37, 84, 182),
		accent = Color3.fromRGB(78, 145, 255),
		accent2 = Color3.fromRGB(0, 229, 182),
		text = Color3.fromRGB(244, 247, 255),
		sub = Color3.fromRGB(164, 176, 205),
		good = Color3.fromRGB(90, 237, 169),
		warn = Color3.fromRGB(255, 200, 80),
	},
	Neon = {
		bg = Color3.fromRGB(10, 8, 24),
		panel = Color3.fromRGB(18, 10, 38),
		card = Color3.fromRGB(24, 14, 49),
		card2 = Color3.fromRGB(29, 18, 60),
		stroke = Color3.fromRGB(118, 71, 255),
		accent = Color3.fromRGB(0, 186, 255),
		accent2 = Color3.fromRGB(215, 94, 255),
		text = Color3.fromRGB(247, 245, 255),
		sub = Color3.fromRGB(190, 176, 220),
		good = Color3.fromRGB(66, 233, 205),
		warn = Color3.fromRGB(255, 172, 66),
	},
	Minimal = {
		bg = Color3.fromRGB(16, 18, 22),
		panel = Color3.fromRGB(20, 22, 28),
		card = Color3.fromRGB(25, 28, 36),
		card2 = Color3.fromRGB(31, 33, 41),
		stroke = Color3.fromRGB(84, 90, 104),
		accent = Color3.fromRGB(235, 235, 235),
		accent2 = Color3.fromRGB(160, 160, 160),
		text = Color3.fromRGB(245, 245, 245),
		sub = Color3.fromRGB(177, 181, 190),
		good = Color3.fromRGB(131, 221, 152),
		warn = Color3.fromRGB(255, 201, 92),
	},
}

local settingsState = {
	theme = "Obsidian",

	masterVolume = 61,
	musicVolume = 37,
	sfxVolume = 34,
	voiceVolume = 75,

	graphicsMode = "Balanced",
	shadowQuality = "High",
	antiAliasing = "TAA",
	brightness = 55,
	fov = 70,
	gamma = 0,
	bloomIntensity = 20,
	blurStrength = 0,

	sensitivity = 50,
	autoSprint = false,
	toggleADS = false,
	toggleCrouch = false,
	hitmarkers = true,
	damageNumbers = true,

	uiScale = 100,
	crosshairOpacity = 100,
	streamerMode = false,
	showHud = true,
	reduceMotion = false,

	colorBlind = "Off",
	subtitles = false,
	gammaAssist = 0,
	highContrast = false,
}

local currentTheme = THEMES[settingsState.theme]

local panelWidth = 560
local hidden = false

local holder = Instance.new("Frame")
holder.Name = "Holder"
holder.AnchorPoint = Vector2.new(1, 0)
holder.Position = UDim2.new(1, -24, 0, 58)
holder.Size = UDim2.new(0, panelWidth, 0.88, 0)
holder.BackgroundTransparency = 1
holder.Parent = root

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(1, 1)
panel.BackgroundColor3 = currentTheme.bg
panel.Parent = holder
corner(panel, 24)
stroke(panel, 2, currentTheme.stroke, 0.18)

local panelGrad = Instance.new("UIGradient")
panelGrad.Rotation = 90
panelGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, currentTheme.panel),
	ColorSequenceKeypoint.new(1, currentTheme.bg),
})
panelGrad.Parent = panel

local inner = Instance.new("Frame")
inner.BackgroundTransparency = 1
inner.Size = UDim2.fromScale(1, 1)
inner.Parent = panel
pad(inner, 14, 14, 14, 14)

local header = Instance.new("Frame")
header.BackgroundColor3 = currentTheme.panel
header.Size = UDim2.new(1, 0, 0, 92)
header.Parent = inner
corner(header, 22)
stroke(header, 1.4, currentTheme.stroke, 0.2)

local avatar = Instance.new("ImageLabel")
avatar.BackgroundColor3 = currentTheme.card
avatar.Position = UDim2.fromOffset(16, 16)
avatar.Size = UDim2.fromOffset(56, 56)
avatar.Image = "rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=180&h=180"
avatar.Parent = header
corner(avatar, 16)
stroke(avatar, 1.2, currentTheme.accent, 0.08)

local themeButton = Instance.new("TextButton")
themeButton.AutoButtonColor = false
themeButton.BackgroundColor3 = currentTheme.card
themeButton.AnchorPoint = Vector2.new(1, 0)
themeButton.Position = UDim2.new(1, -84, 16/92, 0)
themeButton.Size = UDim2.fromOffset(58, 34)
themeButton.Text = "Tema"
themeButton.Font = Enum.Font.GothamBold
themeButton.TextSize = 12
themeButton.TextColor3 = currentTheme.text
themeButton.Parent = header
corner(themeButton, 999)
stroke(themeButton, 1.2, currentTheme.accent, 0.08)

local hideButton = Instance.new("TextButton")
hideButton.AutoButtonColor = false
hideButton.BackgroundColor3 = currentTheme.card
hideButton.AnchorPoint = Vector2.new(1, 0)
hideButton.Position = UDim2.new(1, -16, 16/92, 0)
hideButton.Size = UDim2.fromOffset(54, 34)
hideButton.Text = "Fechar"
hideButton.Font = Enum.Font.GothamBold
hideButton.TextSize = 12
hideButton.TextColor3 = currentTheme.text
hideButton.Parent = header
corner(hideButton, 999)
stroke(hideButton, 1.2, currentTheme.accent, 0.08)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(88, 10)
title.Size = UDim2.new(1, -240, 0, 28)
title.Font = Enum.Font.GothamBold
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = currentTheme.text
title.Text = "Configurações"
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(88, 38)
subtitle.Size = UDim2.new(1, -240, 0, 16)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = currentTheme.sub
subtitle.Text = "Advanced client settings • audio • graphics • gameplay • accessibility"
subtitle.Parent = header

local statusBadge = Instance.new("TextLabel")
statusBadge.BackgroundColor3 = Color3.fromRGB(8, 83, 69)
statusBadge.Position = UDim2.fromOffset(88, 58)
statusBadge.Size = UDim2.fromOffset(190, 22)
statusBadge.Font = Enum.Font.GothamBold
statusBadge.TextSize = 12
statusBadge.TextXAlignment = Enum.TextXAlignment.Left
statusBadge.TextColor3 = Color3.fromRGB(126, 255, 208)
statusBadge.Text = "  ● Ready to customize"
statusBadge.Parent = header
corner(statusBadge, 999)
stroke(statusBadge, 1, Color3.fromRGB(0, 220, 180), 0.1)

local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(0, 102)
body.Size = UDim2.new(1, 0, 1, -102)
body.Parent = inner

local tabsBar = Instance.new("Frame")
tabsBar.BackgroundTransparency = 1
tabsBar.Size = UDim2.new(1, 0, 0, 52)
tabsBar.Parent = body

local tabPadding = 8
local tabWidth = (panelWidth - 28 - 28 - tabPadding * 4) / 5

local tabButtons: {[string]: TextButton} = {}
local activeTab = "Audio"
local tabNames = {"Audio", "Graphics", "Gameplay", "Interface", "Accessibility"}

for i, name in ipairs(tabNames) do
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Name = name
	b.BackgroundColor3 = currentTheme.card
	b.Position = UDim2.fromOffset((i - 1) * (tabWidth + tabPadding), 0)
	b.Size = UDim2.fromOffset(tabWidth, 52)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Text = name
	b.TextColor3 = currentTheme.sub
	b.Parent = tabsBar
	corner(b, 18)
	stroke(b, 1, currentTheme.stroke, 0.2)
	tabButtons[name] = b
end

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(0, 60)
content.Size = UDim2.new(1, 0, 1, -60)
content.Parent = body

local left = Instance.new("Frame")
left.BackgroundTransparency = 1
left.Size = UDim2.new(0.66, -8, 1, 0)
left.Parent = content

local right = Instance.new("Frame")
right.BackgroundTransparency = 1
right.Position = UDim2.new(0.66, 8, 0, 0)
right.Size = UDim2.new(0.34, -8, 1, 0)
right.Parent = content

local scroll = Instance.new("ScrollingFrame")
scroll.BackgroundTransparency = 1
scroll.Size = UDim2.fromScale(1, 1)
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = currentTheme.accent
scroll.BorderSizePixel = 0
scroll.Parent = left
pad(scroll, 0, 8, 0, 0)
local scrollLayout = vlist(scroll, 12)

local sidebar = Instance.new("ScrollingFrame")
sidebar.BackgroundTransparency = 1
sidebar.Size = UDim2.fromScale(1, 1)
sidebar.CanvasSize = UDim2.new()
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.ScrollBarThickness = 0
sidebar.BorderSizePixel = 0
sidebar.Parent = right
local sideLayout = vlist(sidebar, 12)

local sideTab = Instance.new("TextButton")
sideTab.Visible = false
sideTab.AutoButtonColor = false
sideTab.AnchorPoint = Vector2.new(1, 0)
sideTab.Position = UDim2.new(1, -8, 0, 120)
sideTab.Size = UDim2.fromOffset(42, 120)
sideTab.BackgroundColor3 = currentTheme.card
sideTab.TextColor3 = currentTheme.text
sideTab.Text = "◀"
sideTab.Font = Enum.Font.GothamBold
sideTab.TextSize = 22
sideTab.Parent = root
corner(sideTab, 18)
stroke(sideTab, 1.5, currentTheme.accent, 0.15)

local function clearChildren(parent: Instance)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function makeSection(titleText: string, descText: string, parent: Instance)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = currentTheme.panel
	card.Size = UDim2.new(1, -4, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = parent
	corner(card, 22)
	stroke(card, 1.2, currentTheme.stroke, 0.22)
	pad(card, 14, 14, 14, 14)
	vlist(card, 10)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, 28)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 17
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextColor3 = currentTheme.text
	titleLabel.Text = titleText
	titleLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.BackgroundTransparency = 1
	descLabel.Size = UDim2.new(1, 0, 0, 0)
	descLabel.AutomaticSize = Enum.AutomaticSize.Y
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextColor3 = currentTheme.sub
	descLabel.Text = descText
	descLabel.Parent = card

	return card
end

local function makeControlCard(parent: Instance, titleText: string, descText: string)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = currentTheme.card
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = parent
	corner(card, 18)
	stroke(card, 1, currentTheme.stroke, 0.18)
	pad(card, 12, 12, 10, 10)
	vlist(card, 8)

	local titleRow = Instance.new("Frame")
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, 0, 0, 22)
	titleRow.Parent = card

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(0.72, 0, 1, 0)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 14
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = currentTheme.text
	t.Text = titleText
	t.Parent = titleRow

	local v = Instance.new("TextLabel")
	v.Name = "Value"
	v.BackgroundTransparency = 1
	v.Position = UDim2.new(0.72, 0, 0, 0)
	v.Size = UDim2.new(0.28, 0, 1, 0)
	v.Font = Enum.Font.GothamBold
	v.TextSize = 14
	v.TextXAlignment = Enum.TextXAlignment.Right
	v.TextColor3 = currentTheme.text
	v.Text = ""
	v.Parent = titleRow

	local d = Instance.new("TextLabel")
	d.BackgroundTransparency = 1
	d.Size = UDim2.new(1, 0, 0, 0)
	d.AutomaticSize = Enum.AutomaticSize.Y
	d.TextWrapped = true
	d.Font = Enum.Font.Gotham
	d.TextSize = 12
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.TextColor3 = currentTheme.sub
	d.Text = descText
	d.Parent = card

	return card, v
end

local function setStatus(msg: string, good: boolean)
	statusBadge.Text = "  ● " .. msg
	statusBadge.BackgroundColor3 = good and Color3.fromRGB(8, 83, 69) or Color3.fromRGB(94, 73, 14)
	statusBadge.TextColor3 = good and Color3.fromRGB(126, 255, 208) or currentTheme.warn
end

local function animateTabButton(button: TextButton, on: boolean)
	TweenService:Create(button, TweenInfo.new(0.18), {
		BackgroundColor3 = on and currentTheme.accent or currentTheme.card
	}):Play()
	for _, ch in ipairs(button:GetChildren()) do
		if ch:IsA("UIStroke") then
			TweenService:Create(ch, TweenInfo.new(0.18), {
				Color = on and currentTheme.accent or currentTheme.stroke,
				Transparency = on and 0 or 0.2
			}):Play()
		end
	end
	TweenService:Create(button, TweenInfo.new(0.18), {
		TextColor3 = on and ((settingsState.theme == "Minimal") and Color3.fromRGB(18, 18, 18) or Color3.fromRGB(255, 255, 255)) or currentTheme.sub
	}):Play()
end

local function makeToggle(parent: Instance, titleText: string, descText: string, initial: boolean, onChanged: (boolean) -> ())
	local card = makeControlCard(parent, titleText, descText)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 46)
	row.Parent = card

	local toggleBg = Instance.new("TextButton")
	toggleBg.AutoButtonColor = false
	toggleBg.AnchorPoint = Vector2.new(1, 0.5)
	toggleBg.Position = UDim2.new(1, 0, 0.5, 0)
	toggleBg.Size = UDim2.fromOffset(88, 42)
	toggleBg.BackgroundColor3 = Color3.fromRGB(71, 79, 103)
	toggleBg.Text = ""
	toggleBg.Parent = row
	corner(toggleBg, 999)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(34, 34)
	knob.Position = UDim2.fromOffset(4, 4)
	knob.BackgroundColor3 = Color3.fromRGB(240, 243, 250)
	knob.Parent = toggleBg
	corner(knob, 999)

	local state = initial
	local function render()
		TweenService:Create(toggleBg, TweenInfo.new(0.16), {
			BackgroundColor3 = state and currentTheme.accent or Color3.fromRGB(71, 79, 103)
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.16), {
			Position = state and UDim2.fromOffset(50, 4) or UDim2.fromOffset(4, 4)
		}):Play()
	end
	render()

	toggleBg.MouseButton1Click:Connect(function()
		state = not state
		render()
		onChanged(state)
	end)

	return toggleBg
end

local function makeSlider(parent: Instance, titleText: string, descText: string, min: number, max: number, step: number, initial: number, suffix: string, onChanged: (number) -> ())
	local card, valueLabel = makeControlCard(parent, titleText, descText)
	local track = Instance.new("Frame")
	track.BackgroundColor3 = Color3.fromRGB(28, 39, 67)
	track.Size = UDim2.new(1, 0, 0, 14)
	track.Parent = card
	corner(track, 999)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = currentTheme.accent
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = track
	corner(fill, 999)

	local knob = Instance.new("TextButton")
	knob.AutoButtonColor = false
	knob.Text = ""
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(28, 28)
	knob.BackgroundColor3 = Color3.fromRGB(233, 237, 246)
	knob.Parent = track
	corner(knob, 999)
	stroke(knob, 1, currentTheme.accent, 0.15)

	local dragging = false
	local value = initial

	local function clampRound(v: number)
		local c = math.clamp(v, min, max)
		local snaps = math.round(c / step)
		return snaps * step
	end

	local function setValue(v: number)
		value = clampRound(v)
		local alpha = (value - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		local display = if step < 1 then string.format("%.2f", value) else string.format("%d", value)
		valueLabel.Text = display .. suffix
		onChanged(value)
	end

	local function move(inputX: number)
		local rel = (inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X
		setValue(min + (max - min) * rel)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			move(input.Position.X)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	connectControl(UserInputService.InputChanged,function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			move(input.Position.X)
		end
	end)

	connectControl(UserInputService.InputEnded,function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	setValue(initial)
	return track
end

local function makeCycle(parent: Instance, titleText: string, descText: string, options: {string}, initialIndex: number, onChanged: (string) -> ())
	local card, valueLabel = makeControlCard(parent, titleText, descText)
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = currentTheme.card2
	btn.Size = UDim2.new(1, 0, 0, 42)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = ""
	btn.Parent = card
	corner(btn, 999)
	stroke(btn, 1, currentTheme.stroke, 0.18)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(14, 0)
	label.Size = UDim2.new(1, -48, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = currentTheme.text
	label.Parent = btn

	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, -14, 0.5, 0)
	arrow.Size = UDim2.fromOffset(18, 18)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 16
	arrow.Text = "›"
	arrow.TextColor3 = currentTheme.sub
	arrow.Parent = btn

	local index = initialIndex
	local function render()
		local val = options[index]
		label.Text = val
		valueLabel.Text = val
		onChanged(val)
	end
	render()

	btn.MouseButton1Click:Connect(function()
		index += 1
		if index > #options then
			index = 1
		end
		render()
	end)

	return btn
end

local hudPreviewCard = makeSection("Live Preview", "Watch settings react live as you tweak your experience.", sidebar)
local previewBox = Instance.new("Frame")
previewBox.BackgroundColor3 = currentTheme.card
previewBox.Size = UDim2.new(1, 0, 0, 140)
previewBox.Parent = hudPreviewCard
corner(previewBox, 18)
stroke(previewBox, 1, currentTheme.stroke, 0.18)

local previewTitle = Instance.new("TextLabel")
previewTitle.BackgroundTransparency = 1
previewTitle.Position = UDim2.fromOffset(12, 10)
previewTitle.Size = UDim2.new(1, -24, 0, 16)
previewTitle.Font = Enum.Font.Gotham
previewTitle.TextSize = 11
previewTitle.TextXAlignment = Enum.TextXAlignment.Left
previewTitle.TextColor3 = currentTheme.sub
previewTitle.Text = "HUD preview • graphics feedback • accessibility"
previewTitle.Parent = previewBox

local previewCrosshair = Instance.new("Frame")
previewCrosshair.BackgroundTransparency = 1
previewCrosshair.AnchorPoint = Vector2.new(0.5, 0.5)
previewCrosshair.Position = UDim2.fromScale(0.5, 0.55)
previewCrosshair.Size = UDim2.fromOffset(48, 48)
previewCrosshair.Parent = previewBox

local crossParts = {}
for i = 1, 4 do
	local f = Instance.new("Frame")
	f.BackgroundColor3 = currentTheme.text
	f.BorderSizePixel = 0
	f.Parent = previewCrosshair
	crossParts[i] = f
end
crossParts[1].Size = UDim2.fromOffset(2, 12); crossParts[1].Position = UDim2.new(0.5, -1, 0, 2)
crossParts[2].Size = UDim2.fromOffset(2, 12); crossParts[2].Position = UDim2.new(0.5, -1, 1, -14)
crossParts[3].Size = UDim2.fromOffset(12, 2); crossParts[3].Position = UDim2.new(0, 2, 0.5, -1)
crossParts[4].Size = UDim2.fromOffset(12, 2); crossParts[4].Position = UDim2.new(1, -14, 0.5, -1)

local previewBadge = Instance.new("TextLabel")
previewBadge.BackgroundColor3 = currentTheme.accent
previewBadge.AnchorPoint = Vector2.new(0.5, 1)
previewBadge.Position = UDim2.new(0.5, 0, 1, -12)
previewBadge.Size = UDim2.fromOffset(130, 22)
previewBadge.Font = Enum.Font.GothamBold
previewBadge.TextSize = 11
previewBadge.TextColor3 = settingsState.theme == "Minimal" and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
previewBadge.Text = "Performance Balanced"
previewBadge.Parent = previewBox
corner(previewBadge, 999)

local systemCard = makeSection("System Status", "Useful readout for the current session and active profile.", sidebar)

local function statRow(parent: Instance, key: string, value: string)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = currentTheme.card
	row.Size = UDim2.new(1, 0, 0, 42)
	row.Parent = parent
	corner(row, 16)
	stroke(row, 1, currentTheme.stroke, 0.14)

	local k = Instance.new("TextLabel")
	k.Name = "Key"
	k.BackgroundTransparency = 1
	k.Position = UDim2.fromOffset(12, 0)
	k.Size = UDim2.new(0.48, 0, 1, 0)
	k.Font = Enum.Font.Gotham
	k.TextSize = 12
	k.TextXAlignment = Enum.TextXAlignment.Left
	k.TextColor3 = currentTheme.sub
	k.Text = key
	k.Parent = row

	local v = Instance.new("TextLabel")
	v.Name = "Value"
	v.BackgroundTransparency = 1
	v.AnchorPoint = Vector2.new(1, 0)
	v.Position = UDim2.new(1, -12, 0, 0)
	v.Size = UDim2.new(0.46, 0, 1, 0)
	v.Font = Enum.Font.GothamBold
	v.TextSize = 12
	v.TextXAlignment = Enum.TextXAlignment.Right
	v.TextColor3 = currentTheme.text
	v.Text = value
	v.Parent = row

	return row
end

local profileRow = statRow(systemCard, "Profile", player.DisplayName)
local inputRow = statRow(systemCard, "Input", "Keyboard + Mouse")
local themeRow = statRow(systemCard, "Theme", settingsState.theme)

local actionsCard = makeSection("Quick Actions", "Fast access buttons for testing, resets and dramatic presets.", sidebar)

local function actionButton(parent: Instance, text: string, color: Color3, fn: () -> ())
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = currentTheme.card
	b.Size = UDim2.new(1, 0, 0, 42)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.Text = text
	b.TextColor3 = color
	b.Parent = parent
	corner(b, 16)
	stroke(b, 1.2, color, 0.05)
	b.MouseButton1Click:Connect(fn)
	return b
end

local function applyTheme()
	currentTheme = THEMES[settingsState.theme]

	panel.BackgroundColor3 = currentTheme.bg
	panelGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, currentTheme.panel),
		ColorSequenceKeypoint.new(1, currentTheme.bg),
	})
	header.BackgroundColor3 = currentTheme.panel
	avatar.BackgroundColor3 = currentTheme.card
	title.TextColor3 = currentTheme.text
	subtitle.TextColor3 = currentTheme.sub
	scroll.ScrollBarImageColor3 = currentTheme.accent
	sideTab.BackgroundColor3 = currentTheme.card
	sideTab.TextColor3 = currentTheme.text

	for _, button in pairs(tabButtons) do
		button.BackgroundColor3 = currentTheme.card
		for _, ch in ipairs(button:GetChildren()) do
			if ch:IsA("UIStroke") then
				ch.Color = currentTheme.stroke
			end
		end
	end

	themeButton.BackgroundColor3 = currentTheme.card
	hideButton.BackgroundColor3 = currentTheme.card
	themeButton.TextColor3 = currentTheme.text
	hideButton.TextColor3 = currentTheme.text

	previewBox.BackgroundColor3 = currentTheme.card
	previewBadge.BackgroundColor3 = currentTheme.accent
	previewBadge.TextColor3 = settingsState.theme == "Minimal" and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
	themeRow.Value.Text = settingsState.theme
end


 local byKey={}
 for _,category in ipairs(categories) do for _,row in ipairs(category.rows) do if row.key then byKey[row.key]=row end end end
 local function setValue(key,value)
  local row=byKey[key] if not row then return end
  if row.min then
   if type(value)~="number" then return end
   value=math.clamp(value,row.min,row.max) local step=row.step or 1
   value=math.floor(value/step+.5)*step
   if row.decimals then value=tonumber(string.format("%."..row.decimals.."f",value)) end
  elseif type(value)~="boolean" then return end
  if key=="AFK" then game:GetService("ReplicatedStorage").Survival.Action:FireServer("afk",value)
  else player:SetAttribute(key,value) end
 end
 local tabKeys={
 Audio={"EffectsVolume","MenuSounds","FriendAlerts"},
 Graphics={"CameraFOV","VisualSaturation","VisualContrast","VisualExposure","VisualTime","MapShadows","LowGraphics","Reflections"},
 Gameplay={"AFK","ControlScale"},
 Interface={"ShowNametags"},
 Accessibility={"ReducedMotion"}
 }
 local titles={Audio="Áudio",Graphics="Imagem",Gameplay="Jogo",Interface="Interface",Accessibility="Acessibilidade"}
 local function refreshContent()
  for _,c in ipairs(controls) do c:Disconnect() end table.clear(controls)
  clearChildren(scroll)
  local section=makeSection(titles[activeTab],"Ajustes aplicados ao seu jogo.",scroll)
  for _,key in ipairs(tabKeys[activeTab]) do
   local row=byKey[key] local value=player:GetAttribute(key) if value==nil then value=row.default end
   local control
   if row.min then control=makeSlider(section,row.label,row.description,row.min,row.max,row.step or 1,value,row.suffix or "",function(v) setValue(key,v) end)
   else control=makeToggle(section,row.label,row.description,value,function(v) setValue(key,v) end) end
   control.Name=key
  end
  for name,b in pairs(tabButtons) do b.Text=titles[name] animateTabButton(b,name==activeTab) end
 end
 for name,b in pairs(tabButtons) do b.Activated:Connect(function() activeTab=name refreshContent() end) end
 themeButton.Activated:Connect(function()
  local names={"Obsidian","Neon","Minimal"}
  settingsState.theme=names[(table.find(names,settingsState.theme) or 1)%#names+1]
  applyTheme() refreshContent()
 end)
 hideButton.Activated:Connect(onClose)
 sideTab.Visible=false
 actionsCard.Visible=false
 hudPreviewCard.Visible=false
 local function updateLayout()
  local size=parent.AbsoluteSize
  local w=math.min(560,math.max(300,size.X-24))
  holder.AnchorPoint=Vector2.new(.5,.5) holder.Position=UDim2.fromScale(.5,.5)
  holder.Size=UDim2.new(0,w,.94,0)
  for i,name in ipairs(tabNames) do local b=tabButtons[name] b.Size=UDim2.new(.2,-5,1,0) b.Position=UDim2.new((i-1)*.2,0,0,0) b.TextSize=11 end
  left.Size=UDim2.new(.70,-6,1,0) right.Position=UDim2.fromScale(.70,0) right.Size=UDim2.new(.30,-4,1,0)
  if w<440 then left.Size=UDim2.fromScale(1,1) right.Visible=false else right.Visible=true end
 end
 -- Match the existing overlay layer; all original asset colors, cards and controls remain.
 local baseZ=parent.ZIndex+1 root.ZIndex=baseZ
 for _,obj in ipairs(root:GetDescendants()) do if obj:IsA("GuiObject") then obj.ZIndex=baseZ+obj.ZIndex end end
 root:SetAttribute("SourceAssetId",93583640955196)
 applyTheme() refreshContent() updateLayout()
 parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
 parent:GetPropertyChangedSignal("Visible"):Connect(function() if parent.Visible then refreshContent() updateLayout() end end)
 setStatus("Configurações do seu jogo",true)
 return {frame=root,select=function(key) activeTab=({audio="Audio",visual="Graphics",gameplay="Gameplay"})[key] or key refreshContent() end,setValue=setValue}
end
return Settings
