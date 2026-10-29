local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then
 local p=game:GetService('Players').LocalPlayer;local rs=game:GetService('ReplicatedStorage')
 local gui=Instance.new('ScreenGui');gui.Name='ReturnToMenu';gui.ResetOnSpawn=false;gui.Parent=p:WaitForChild('PlayerGui')
 local b=Instance.new('TextButton');b.Position=UDim2.fromOffset(16,65);b.Size=UDim2.fromOffset(64,44);b.BackgroundTransparency=1;b.Text='MENU';b.TextSize=13;b.Font=Enum.Font.Code;b.TextColor3=Color3.new(1,1,1);b.Parent=gui
 local text=Instance.new('TextLabel');text.Position=UDim2.fromOffset(16,110);text.Size=UDim2.fromOffset(230,48);text.TextWrapped=true;text.TextSize=12;text.Font=Enum.Font.Code;text.TextColor3=Color3.new(1,1,1);text.BackgroundTransparency=1;text.Text='';text.Parent=gui
 local busy=false
 b.Activated:Connect(function() if busy then return end;busy=true
  local ok,result=pcall(function() return rs:WaitForChild('SessionMenu'):InvokeServer('return') end)
  text.Text=ok and result.message or 'Falha na conexão.';busy=false
 end)
 return
end
local p=game:GetService('Players').LocalPlayer;local RS=game:GetService('ReplicatedStorage');local RF=game:GetService('ReplicatedFirst')
local remote=RS:WaitForChild('SessionMenu');local gui=Instance.new('ScreenGui');gui.Name='StillHereMenu';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=1000;gui.Parent=p:WaitForChild('PlayerGui')
local function make(class,props,parent) local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o end
local bg=make('Frame',{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(8,13,23),BorderSizePixel=0},gui)
make('UIGradient',{Color=ColorSequence.new(Color3.fromRGB(2,4,9),Color3.fromRGB(31,47,64)),Rotation=15},bg)
make('TextLabel',{Position=UDim2.fromScale(.07,.14),Size=UDim2.fromScale(.86,.14),Text='STILL HERE',TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Code,TextSize=42,TextColor3=Color3.fromRGB(237,240,246),BackgroundTransparency=1},bg)
local body=make('Frame',{Position=UDim2.fromScale(.07,.37),Size=UDim2.new(.86,0,.55,0),BackgroundTransparency=1},bg)
local status=make('TextLabel',{Position=UDim2.fromScale(.07,.9),Size=UDim2.fromScale(.86,.08),Text='',Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(217,225,235),TextWrapped=true,BackgroundTransparency=1},bg)
local busy=false;local view='home';local current;local request;local render
local function button(text,y,fn)
 local b=make('TextButton',{Position=UDim2.fromOffset(0,y),Size=UDim2.new(.9,0,0,42),Text='  '..text,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Code,TextSize=16,TextColor3=Color3.fromRGB(235,240,246),BackgroundTransparency=.85,BackgroundColor3=Color3.fromRGB(17,26,38),BorderSizePixel=0,AutoButtonColor=true},body)
 make('UISizeConstraint',{MaxSize=Vector2.new(440,42),MinSize=Vector2.new(220,42)},b);make('UIStroke',{Color=Color3.fromRGB(168,184,204),Transparency=.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b);b.Activated:Connect(fn);return b
end
request=function(action,value)
 if busy then return end;busy=true;status.Text='Aguarde…'
 local ok,result=pcall(function() return remote:InvokeServer(action,value) end);busy=false
 if not ok then status.Text='Falha na conexão. Tenta novamente.';return end
 current=result.data or current;status.Text=result.message or (result.ok and '' or 'Não foi possível concluir.')
 render()
end
render=function()
 for _,c in ipairs(body:GetChildren()) do c:Destroy() end
 if view=='home' then
  button('JOGAR SOLO',0,function() request('solo') end)
  button('MULTIPLAYER (COM GRUPOS)',54,function() view='group';render();request('state') end)
  button('LOJA',108,function() view='shop';render();request('state') end)
 elseif view=='group' then
  local party=current and current.party
  if party then
   local names={};for _,m in ipairs(party.members) do table.insert(names,m.name) end
   make('TextLabel',{Size=UDim2.new(1,0,0,55),Text='CÓDIGO: '..party.code..'  ·  '..#names..'/6\n'..table.concat(names,', '),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Code,TextSize=14,TextColor3=Color3.new(1,1,1),BackgroundTransparency=1},body)
   if party.leader==p.UserId then button('INICIAR GRUPO',65,function() request('start') end) end
   button('SAIR DO GRUPO',116,function() request('leave') end)
  else
   button('CRIAR GRUPO PRIVADO',0,function() request('create') end)
   local code=make('TextBox',{Position=UDim2.fromOffset(0,54),Size=UDim2.new(.6,0,0,42),PlaceholderText='CÓDIGO DO GRUPO',Text='',ClearTextOnFocus=false,Font=Enum.Font.Code,TextSize=16,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(22,30,43)},body)
   button('ENTRAR COM CÓDIGO',108,function() request('join',code.Text) end)
  end
  button('VOLTAR',170,function() view='home';render() end)
 elseif view=='shop' then
  local profile=current and current.profile
  if not profile then status.Text='Não foi possível carregar seu inventário. Reabra a loja.' end
  make('TextLabel',{Size=UDim2.new(1,0,0,25),Text='CRÉDITOS: '..tostring(profile and profile.coins or '—'),TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Code,TextSize=14,TextColor3=Color3.new(1,1,1),BackgroundTransparency=1},body)
  for i,id in ipairs({'lantern','trail','mark'}) do
   local item=current and current.catalog and current.catalog[id]
   if item then button(item.name:upper()..(profile and profile.owned[id] and ' · ADQUIRIDO' or ' · '..item.price),28+(i-1)*46,function() request('buy',id) end) end
  end
  button('VOLTAR',174,function() view='home';render() end)
 end
end
render();RF:RemoveDefaultLoadingScreen();task.spawn(request,'state')
RS:WaitForChild('SessionNotice').OnClientEvent:Connect(function(message) busy=false;status.Text=message end)
task.spawn(function() while gui.Parent do task.wait(4);if view=='group' and current and current.party and not busy then request('state') end end end)
