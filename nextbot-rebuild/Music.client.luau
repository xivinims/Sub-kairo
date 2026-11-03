local Players=game:GetService('Players');local SoundService=game:GetService('SoundService');local Run=game:GetService('RunService')
local player=Players.LocalPlayer;local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference');local config=require(package.AudioConfig)
local remote=package:WaitForChild('Boombox')
local lobby=Instance.new('Sound');lobby.Name='NBLobbyMusic';lobby.Volume=.22;lobby.SoundGroup=SoundService:WaitForChild('NB_LobbyMusic');lobby.Parent=SoundService
local track=1
local function playLobby()lobby.SoundId='rbxassetid://'..config.Lobby[track].id;lobby:Play()end
lobby.Ended:Connect(function()track=track%#config.Lobby+1;if not player:GetAttribute('NBInRound')then playLobby()end end)
local ambient=Instance.new('Sound');ambient.Name='NBMapAmbience';ambient.SoundId='rbxassetid://'..config.Ambient;ambient.Volume=.12;ambient.Looped=true;ambient.SoundGroup=SoundService:WaitForChild('NB_GameMusic');ambient.Parent=SoundService
local function state()
 if player:GetAttribute('NBInRound')then lobby:Pause();if not ambient.IsPlaying then ambient:Play()end
 else ambient:Pause();if not lobby.IsPlaying then if lobby.TimePosition>0 then lobby:Resume()else playLobby()end end end
end
player:GetAttributeChangedSignal('NBInRound'):Connect(state);state()
local function new(class,parent,props)local v=Instance.new(class);for k,val in pairs(props or {})do v[k]=val end;v.Parent=parent;return v end
local gui=new('ScreenGui',player:WaitForChild('PlayerGui'),{Name='BoomboxMenu',ResetOnSpawn=false,DisplayOrder=50,Enabled=false,IgnoreGuiInset=true})
local panel=new('Frame',gui,{Size=UDim2.fromOffset(700,480),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=Color3.fromRGB(23,20,32),BackgroundTransparency=.08})
new('UICorner',panel,{CornerRadius=UDim.new(0,16)});new('UIStroke',panel,{Color=Color3.fromRGB(160,91,182),Thickness=3})
local scale=new('UIScale',panel);local function fit()scale.Scale=math.min(1,gui.AbsoluteSize.X/740,gui.AbsoluteSize.Y/520)end;fit();gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
local function button(text,x,y,w,fn)
 local b=new('TextButton',panel,{Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,48),Font=Enum.Font.GothamBold,TextSize=18,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(66,70,104)})
 new('UICorner',b,{CornerRadius=UDim.new(0,7)});b.Activated:Connect(fn);return b
end
new('TextLabel',panel,{Text='CAIXA DE SOM',Position=UDim2.fromOffset(20,12),Size=UDim2.fromOffset(530,50),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextSize=28,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left})
button('FECHAR',565,14,115,function()player:SetAttribute('NBOpenBoombox',false)end)
local input=new('TextBox',panel,{PlaceholderText='ID de áudio Roblox',Text='',ClearTextOnFocus=false,Position=UDim2.fromOffset(20,80),Size=UDim2.fromOffset(380,48),BackgroundColor3=Color3.fromRGB(35,38,45),TextColor3=Color3.new(1,1,1),TextSize=22,Font=Enum.Font.Gotham})
button('TOCAR',412,80,120,function()local id=tonumber(input.Text);if id then remote:FireServer('Play',id)end end)
button('FAVORITAR',544,80,136,function()local id=tonumber(input.Text);if id then remote:FireServer('Favorite',id)end end)
local selected=0
for i,item in ipairs(config.Playlist)do button(item.name,20,145+(i-1)*55,660,function()input.Text=tostring(item.id);remote:FireServer('Play',item.id)end)end
local status=new('TextLabel',panel,{Text='Cole um ID ou escolha uma faixa.',Position=UDim2.fromOffset(20,370),Size=UDim2.fromOffset(660,40),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextSize=17,Font=Enum.Font.Gotham})
local favorites={};local favoriteIndex=0
button('FAVORITOS',20,420,460,function()if #favorites>0 then favoriteIndex=favoriteIndex%#favorites+1;input.Text=tostring(favorites[favoriteIndex]);remote:FireServer('Play',favorites[favoriteIndex])else status.Text='Nenhum favorito salvo.'end end)
button('PARAR',492,420,188,function()remote:FireServer('Stop')end)
player:GetAttributeChangedSignal('NBOpenBoombox'):Connect(function()gui.Enabled=player:GetAttribute('NBOpenBoombox')==true;if gui.Enabled then remote:FireServer('List')end end)
remote.OnClientEvent:Connect(function(kind,value)
 if kind=='favorites'then favorites=value elseif kind=='playing'then status.Text='Tocando áudio '..value elseif kind=='invalid'then status.Text='Esse ID não é um áudio disponível.'end
end)
