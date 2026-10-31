local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' or W:GetAttribute('SelectedChapter')==2 then return end
local Players=game:GetService('Players');local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui');local RS=game:GetService('ReplicatedStorage')
local gui=Instance.new('ScreenGui');gui.Name='MissionTop';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=40;gui.Parent=pg
local panel=Instance.new('Frame');panel.Name='MissionObjectivePanel';panel.Position=UDim2.new(0,18,0,14);panel.Size=UDim2.new(.48,0,0,72);panel.BackgroundColor3=Color3.fromRGB(18,18,18);panel.BackgroundTransparency=.18;panel.BorderSizePixel=0;panel.Parent=gui
Instance.new('UICorner',panel).CornerRadius=UDim.new(0,4)
local inviteButton=Instance.new('TextButton');inviteButton.Name='InviteFriendButton';inviteButton.AnchorPoint=Vector2.new(1,0);inviteButton.Size=UDim2.fromOffset(164,42);inviteButton.BackgroundColor3=Color3.fromRGB(18,18,18);inviteButton.BackgroundTransparency=.12;inviteButton.BorderSizePixel=0;inviteButton.Text='CONVIDAR AMIGO';inviteButton.TextColor3=Color3.fromRGB(235,232,220);inviteButton.Font=Enum.Font.RobotoCondensed;inviteButton.TextSize=14;inviteButton.AutoButtonColor=false;inviteButton.ZIndex=5;inviteButton.Parent=gui
Instance.new('UICorner',inviteButton).CornerRadius=UDim.new(0,4)
local inviteEdge=Instance.new('UIStroke');inviteEdge.Color=Color3.fromRGB(137,132,125);inviteEdge.Transparency=.55;inviteEdge.Thickness=1;inviteEdge.Parent=inviteButton
local inviteStatus=Instance.new('TextLabel');inviteStatus.Name='InviteStatus';inviteStatus.AnchorPoint=Vector2.new(1,0);inviteStatus.Size=UDim2.fromOffset(228,28);inviteStatus.BackgroundTransparency=1;inviteStatus.Text='';inviteStatus.TextColor3=Color3.fromRGB(207,199,188);inviteStatus.Font=Enum.Font.RobotoCondensed;inviteStatus.TextSize=11;inviteStatus.TextXAlignment=Enum.TextXAlignment.Right;inviteStatus.TextWrapped=true;inviteStatus.Visible=false;inviteStatus.ZIndex=5;inviteStatus.Parent=gui
local function fitInvite()
 local camera=workspace.CurrentCamera;local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
 local compact=viewport.X<520
 inviteButton.Position=UDim2.new(1,compact and -12 or -18,0,compact and 94 or 14)
 inviteStatus.Position=UDim2.new(1,compact and -12 or -18,0,compact and 138 or 58)
end
fitInvite()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(fitInvite) end
local inviteBusy=false
local function showInviteStatus(message)
 inviteStatus.Text=message or '';inviteStatus.Visible=message~=nil and message~=''
end
inviteButton.MouseEnter:Connect(function() inviteButton.TextColor3=Color3.fromRGB(255,248,236);inviteEdge.Transparency=.18 end)
inviteButton.MouseLeave:Connect(function() inviteButton.TextColor3=Color3.fromRGB(235,232,220);inviteEdge.Transparency=.55 end)
inviteButton.Activated:Connect(function()
 if inviteBusy then return end
 inviteBusy=true;inviteButton.Text='VERIFICANDO…';showInviteStatus('VERIFICANDO CONVITES DISPONÍVEIS')
 local social=game:GetService('SocialService')
 local allowedOk,allowed=pcall(function() return social:CanSendGameInviteAsync(player) end)
 if not allowedOk or not allowed then
  showInviteStatus('CONVITE INDISPONÍVEL NESTA PLATAFORMA')
  inviteButton.Text='CONVIDAR AMIGO';inviteBusy=false;return
 end
 local remote=RS:WaitForChild('SessionMenu')
 local preparedOk,prepared=pcall(function() return remote:InvokeServer('invite') end)
 if not preparedOk or type(prepared)~='table' or not prepared.ok then
  showInviteStatus(preparedOk and (prepared and prepared.message or 'NÃO FOI POSSÍVEL PREPARAR O CONVITE') or 'FALHA DE CONEXÃO')
  inviteButton.Text='CONVIDAR AMIGO';inviteBusy=false;return
 end
 local options=Instance.new('ExperienceInviteOptions')
 options.PromptMessage='Convide um amigo para jogar ao seu lado.'
 options.LaunchData=game:GetService('HttpService'):JSONEncode({inviterUserId=player.UserId})
 local prompted,err=pcall(function() social:PromptGameInvite(player,options) end)
 if prompted then showInviteStatus('ESCOLHA UM AMIGO NO CONVITE DO ROBLOX')
 else showInviteStatus('NÃO FOI POSSÍVEL ABRIR O CONVITE') end
 inviteButton.Text=prompted and 'CONVITE ABERTO' or 'CONVIDAR AMIGO'
 task.delay(5,function() inviteBusy=false;if gui.Parent then inviteButton.Text='CONVIDAR AMIGO';if prompted then showInviteStatus('') end end end)
end)
RS:WaitForChild('SessionNotice').OnClientEvent:Connect(function(message)
 showInviteStatus(tostring(message))
 task.delay(8,function() if gui.Parent and inviteStatus.Text==tostring(message) then showInviteStatus('') end end)
end)
local limit=Instance.new('UISizeConstraint');limit.MinSize=Vector2.new(230,72);limit.MaxSize=Vector2.new(470,72);limit.Parent=panel
local edge=Instance.new('UIStroke');edge.Color=Color3.fromRGB(137,132,125);edge.Thickness=1;edge.Transparency=.78;edge.Parent=panel
local accent=Instance.new('Frame');accent.Name='ObjectiveAccent';accent.Position=UDim2.new(0,0,0,8);accent.Size=UDim2.new(0,2,1,-16);accent.BackgroundColor3=Color3.fromRGB(177,54,57);accent.BorderSizePixel=0;accent.Parent=panel
local eyebrow=Instance.new('TextLabel');eyebrow.Name='ChapterLabel';eyebrow.Position=UDim2.new(0,15,0,7);eyebrow.Size=UDim2.new(1,-24,0,16);eyebrow.BackgroundTransparency=1;eyebrow.Text='CHAPTER 1   /   OBJETIVO';eyebrow.TextColor3=Color3.fromRGB(171,166,158);eyebrow.Font=Enum.Font.RobotoCondensed;eyebrow.TextSize=10;eyebrow.TextXAlignment=Enum.TextXAlignment.Left;eyebrow.Parent=panel
local text=Instance.new('TextLabel');text.Name='Objective';text.Position=UDim2.new(0,15,0,25);text.Size=UDim2.new(1,-24,0,40);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(235,232,220);text.Font=Enum.Font.RobotoCondensed;text.TextSize=16;text.TextXAlignment=Enum.TextXAlignment.Left;text.TextYAlignment=Enum.TextYAlignment.Center;text.TextWrapped=true;text.Parent=panel
local textLimit=Instance.new('UITextSizeConstraint');textLimit.MinTextSize=12;textLimit.MaxTextSize=17;textLimit.Parent=text
local missions={OpenHouseDoor='Encontre a chave e abra a porta da mansão.',Son='Investigue o escritório e recupere a fotografia.',Mother='Encontre as peças e complete o manequim.',Father='Encontre os ingredientes e complete a receita.',Daughter='Encontre as peças e restaure a escultura.',Grandmother='Encontre as peças da estátua no solário.',Grandfather='Encontre as velas e complete o ritual.'}
local current;local generation=0;local fade
local function objective()
 local state=W:GetAttribute('OriginalMissionState');local name=W:GetAttribute('OriginalMissionName')
 if state==11 then return missions[name] or 'Explore o cômodo e resolva o enigma.' end
 if state==6 or state==17 then return 'Explore a mansão e procure os objetos da família.' end
 if state==7 then return 'Leia a lembrança encontrada.' end
 if state==15 then return 'Recolha o objeto restaurado.' end
 if state==16 then return 'Leve o objeto restaurado ao ritual no hall.' end
 if state==18 or state==19 or state==20 then return 'Prepare-se para o ritual final.' end
 if state==21 then return 'Encontre a saída da mansão.' end
 if state and state>=8 and state<=14 then return current or 'Investigue a mansão.' end
 return 'Explore os arredores e encontre a entrada da mansão.'
end
local function refresh()
 local nextText=objective();if nextText==current then return end
 local first=current==nil;current=nextText;generation+=1;local token=generation
 if fade then fade:Cancel() end
 text.Text=(first and 'Missão: ' or 'Nova missão: ')..nextText;text.TextTransparency=1
 fade=Tween:Create(text,TweenInfo.new(.45),{TextTransparency=0});fade:Play()
 Tween:Create(accent,TweenInfo.new(.24,Enum.EasingStyle.Quad),{BackgroundTransparency=.08}):Play()
 if not first then task.delay(5,function() if token==generation and gui.Parent then text.Text='Missão: '..nextText end end) end
end
W:GetAttributeChangedSignal('OriginalMissionState'):Connect(refresh)
W:GetAttributeChangedSignal('OriginalMissionName'):Connect(function() task.defer(refresh) end)
refresh()

local function visibility() gui.Enabled=player:GetAttribute("ShowObjectives")~=false end
player:GetAttributeChangedSignal("ShowObjectives"):Connect(visibility);visibility()
