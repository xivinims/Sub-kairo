local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Tween=game:GetService('TweenService')
local SocialService=game:GetService('SocialService')

local player=Players.LocalPlayer
local remote=RS:WaitForChild('MysteryUIAction')
local gui=Instance.new('ScreenGui')
gui.Name='ReceptionistDialogue'
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=1850
gui.Enabled=false
gui.Parent=player:WaitForChild('PlayerGui')

local card=Instance.new('Frame')
card.Name='DialogueCard'
card.AnchorPoint=Vector2.new(.5,1)
card.Position=UDim2.new(.5,0,1,18)
card.Size=UDim2.new(.72,0,0,202)
card.BackgroundColor3=Color3.fromRGB(12,14,14)
card.BackgroundTransparency=.06
card.BorderSizePixel=0
card.Parent=gui
Instance.new('UICorner',card).CornerRadius=UDim.new(0,8)
local sizeLimit=Instance.new('UISizeConstraint')
sizeLimit.MinSize=Vector2.new(300,202)
sizeLimit.MaxSize=Vector2.new(560,202)
sizeLimit.Parent=card
local stroke=Instance.new('UIStroke',card)
stroke.Color=Color3.fromRGB(183,159,120)
stroke.Transparency=.55

local title=Instance.new('TextLabel')
title.Name='Speaker'
title.Position=UDim2.new(0,18,0,12)
title.Size=UDim2.new(1,-36,0,18)
title.BackgroundTransparency=1
title.Text='RECEPCIONISTA'
title.Font=Enum.Font.RobotoCondensed
title.TextSize=12
title.TextColor3=Color3.fromRGB(213,184,128)
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=card

local divider=Instance.new('Frame')
divider.Position=UDim2.new(0,18,0,36)
divider.Size=UDim2.new(1,-36,0,1)
divider.BackgroundColor3=Color3.fromRGB(129,115,93)
divider.BackgroundTransparency=.42
divider.BorderSizePixel=0
divider.Parent=card

local line=Instance.new('TextLabel')
line.Name='DialogueText'
line.Position=UDim2.new(0,18,0,47)
line.Size=UDim2.new(1,-36,0,42)
line.BackgroundTransparency=1
line.Text='Hola. Quer uma partida de sinuca?'
line.Font=Enum.Font.Garamond
line.TextSize=21
line.TextColor3=Color3.fromRGB(235,226,207)
line.TextWrapped=true
line.TextXAlignment=Enum.TextXAlignment.Left
line.TextYAlignment=Enum.TextYAlignment.Center
line.Parent=card

local function makeChoice(name,text,position,width,color)
	local button=Instance.new('TextButton')
	button.Name=name
	button.Position=position
	button.Size=width
	button.BackgroundColor3=color
	button.BackgroundTransparency=.06
	button.BorderSizePixel=0
	button.AutoButtonColor=true
	button.Text=text
	button.Font=Enum.Font.RobotoCondensed
	button.TextSize=15
	button.TextColor3=Color3.fromRGB(242,235,221)
	button.TextWrapped=true
	button.Parent=card
	Instance.new('UICorner',button).CornerRadius=UDim.new(0,5)
	local buttonStroke=Instance.new('UIStroke',button)
	buttonStroke.Color=Color3.fromRGB(174,151,117)
	buttonStroke.Transparency=.65
	return button
end

local friendButton=makeChoice('InviteFriend','CONVIDAR UM AMIGO',UDim2.new(0,18,0,103),UDim2.new(.5,-23,0,48),Color3.fromRGB(43,40,35))
local npcButton=makeChoice('PlayReceptionist','JOGAR COMIGO',UDim2.new(.5,5,0,103),UDim2.new(.5,-23,0,48),Color3.fromRGB(49,63,59))
local laterButton=Instance.new('TextButton')
laterButton.Name='Later'
laterButton.AnchorPoint=Vector2.new(.5,0)
laterButton.Position=UDim2.new(.5,0,0,160)
laterButton.Size=UDim2.new(0,160,0,26)
laterButton.BackgroundTransparency=1
laterButton.BorderSizePixel=0
laterButton.Text='AGORA NÃO'
laterButton.Font=Enum.Font.RobotoCondensed
laterButton.TextSize=12
laterButton.TextColor3=Color3.fromRGB(178,169,151)
laterButton.Parent=card

local activeTween
local invitePending=false
local requestPending=false

local function show(text)
	if activeTween then activeTween:Cancel() end
	gui.Enabled=true
	line.Text=text or 'Hola. Quer uma partida de sinuca?'
	card.BackgroundTransparency=.06
	card.Position=UDim2.new(.5,0,1,18)
	activeTween=Tween:Create(card,TweenInfo.new(.28,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,1,-112)})
	activeTween:Play()
end

local function hide()
	if activeTween then activeTween:Cancel() end
	activeTween=Tween:Create(card,TweenInfo.new(.2,Enum.EasingStyle.Sine,Enum.EasingDirection.In),{Position=UDim2.new(.5,0,1,18),BackgroundTransparency=1})
	activeTween:Play()
	activeTween.Completed:Once(function() gui.Enabled=false end)
end

local function lockChoices(locked)
	friendButton.Active=not locked
	friendButton.AutoButtonColor=not locked
	npcButton.Active=not locked
	npcButton.AutoButtonColor=not locked
	laterButton.Active=not locked
	friendButton.TextTransparency=locked and .4 or 0
	npcButton.TextTransparency=locked and .4 or 0
end

friendButton.Activated:Connect(function()
	if requestPending then return end
	local ok,canInvite=pcall(function() return SocialService:CanSendGameInviteAsync(player) end)
	if not ok or not canInvite then
		line.Text='O convite do Roblox não está disponível agora. Se quiser, posso jogar com você.'
		return
	end
	requestPending=true
	lockChoices(true)
	line.Text='Vou abrir o convite do Roblox. Quando seu amigo entrar neste servidor, ele aparece ao seu lado.'
	remote:FireServer('pool_start_friend')
end)

npcButton.Activated:Connect(function()
	if requestPending then return end
	requestPending=true
	lockChoices(true)
	line.Text='Boa. Vou preparar a mesa.'
	remote:FireServer('pool_start_npc')
end)

laterButton.Activated:Connect(function()
	if not requestPending then hide() end
end)

SocialService.GameInvitePromptClosed:Connect(function(invitingPlayer,recipientIds)
	if invitingPlayer~=player or not invitePending then return end
	invitePending=false
	remote:FireServer('pool_friend_recipients',typeof(recipientIds)=='table' and recipientIds or {})
end)

remote.OnClientEvent:Connect(function(action,data)
	if action=='receptionist_dialogue' then
		requestPending=false
		lockChoices(false)
		title.Text=typeof(data)=='table' and data.speaker or 'RECEPCIONISTA'
		show(typeof(data)=='table' and data.text or 'Hola. Quer uma partida de sinuca?')
	elseif action=='pool_open' then
		if gui.Enabled then hide() end
	elseif action=='pool_invite_ready' then
		invitePending=true
		local ok=pcall(function() SocialService:PromptGameInvite(player) end)
		if not ok then
			invitePending=false
			remote:FireServer('pool_cancel_friend')
		end
	elseif action=='pool_busy' then
		requestPending=false
		lockChoices(false)
		if gui.Enabled then line.Text='A mesa já está ocupada. Tenta de novo quando liberar.' end
	end
end)
