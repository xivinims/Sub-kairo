-- Development-only match controls. Replaced by the screenshot-based main menu later.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local player=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='MatchPreview';gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild('PlayerGui')
local status=Instance.new('TextLabel');status.Size=UDim2.fromOffset(320,36);status.Position=UDim2.new(.5,-160,0,16);status.BackgroundColor3=Color3.fromRGB(20,24,30);status.BackgroundTransparency=.15;status.TextColor3=Color3.new(1,1,1);status.Font=Enum.Font.GothamBold;status.TextSize=16;status.Parent=gui
local join=Instance.new('TextButton');join.Size=UDim2.fromOffset(220,44);join.Position=UDim2.new(.5,-110,1,-60);join.BackgroundColor3=Color3.fromRGB(40,90,60);join.TextColor3=Color3.new(1,1,1);join.Font=Enum.Font.GothamBold;join.TextSize=16;join.Parent=gui
for _,v in ipairs({status,join}) do local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,8);corner.Parent=v end
join.Activated:Connect(function() package.MatchAction:FireServer(player:GetAttribute('NBQueued') and 'Lobby' or 'Join') end)
local function visibility()gui.Enabled=player:GetAttribute('NBInRound')==true end
player:GetAttributeChangedSignal('NBInRound'):Connect(visibility)
visibility()
local last=''
Run.Heartbeat:Connect(function()
	local remaining=math.max(0,math.ceil((package:GetAttribute('Deadline') or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()))
	local phase=package:GetAttribute('Phase')=='Round' and 'PARTIDA' or 'INTERVALO'
	local value=string.format('%s • %d:%02d',phase,math.floor(remaining/60),remaining%60)
	if package:GetAttribute('MapReady')==false then value='PRÉVIA • mapa ainda não integrado' end
	if value~=last then status.Text=value;last=value end
	join.Text=player:GetAttribute('NBQueued') and 'VOLTAR AO LOBBY' or 'ENTRAR NO JOGO'
end)
