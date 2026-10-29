local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then return end
local p=game:GetService('Players').LocalPlayer;local RS=game:GetService('ReplicatedStorage');local RF=game:GetService('ReplicatedFirst')
local remote=RS:WaitForChild('SessionMenu');local gui=Instance.new('ScreenGui');gui.Name='StillHereMenu';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=1000;gui.Parent=p:WaitForChild('PlayerGui')
local function make(class,props,parent) local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o end
local Tween=game:GetService('TweenService')
local bg=make('Frame',{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(6,7,8),BorderSizePixel=0},gui)
local viewport=make('ViewportFrame',{Name='MansionBackdrop',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Ambient=Color3.fromRGB(85,88,85),LightColor=Color3.fromRGB(155,165,151),LightDirection=Vector3.new(-1,-.6,-.4),ImageColor3=Color3.fromRGB(144,155,151)},bg)
local camera=make('Camera',{FieldOfView=64},viewport);viewport.CurrentCamera=camera
local template=RS:WaitForChild('MenuBackdrop',30)
if template then
 local scene=template:Clone();scene.Parent=viewport
 camera.CFrame=template:GetAttribute('CameraCFrame')
end
local function shade(position,size,rotation,first,last)
 local f=make('Frame',{Position=position,Size=size,BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0},bg)
 make('UIGradient',{Rotation=rotation,Transparency=NumberSequence.new(first,last)},f)
end
shade(UDim2.fromScale(0,0),UDim2.fromScale(1,1),0,.8,.06)
shade(UDim2.fromScale(0,0),UDim2.fromScale(1,.23),90,.12,1)
shade(UDim2.fromScale(0,.68),UDim2.fromScale(1,.32),270,.1,1)
shade(UDim2.fromScale(0,0),UDim2.fromScale(.16,1),0,.12,1)
local composition=make('Frame',{Name='RightAlignedMenu',Position=UDim2.fromScale(.59,.12),Size=UDim2.fromScale(.37,.80),BackgroundTransparency=1},bg)
make('TextLabel',{Size=UDim2.fromScale(1,.075),Text='B Y   C H _ C K Z 2 N',Font=Enum.Font.Garamond,TextScaled=true,TextColor3=Color3.fromRGB(170,175,170),BackgroundTransparency=1},composition)
local title=make('TextLabel',{Position=UDim2.fromScale(-.04,.065),Size=UDim2.fromScale(1.08,.24),Text='STILL HERE',Font=Enum.Font.Antique,TextScaled=true,TextColor3=Color3.fromRGB(218,219,207),TextStrokeColor3=Color3.new(0,0,0),TextStrokeTransparency=.55,BackgroundTransparency=1},composition)
make('UITextSizeConstraint',{MaxTextSize=78,MinTextSize=18},title)
make('TextLabel',{Position=UDim2.fromScale(0,.31),Size=UDim2.fromScale(1,.05),Text='A CASA AINDA SE LEMBRA.',Font=Enum.Font.Garamond,TextScaled=true,TextColor3=Color3.fromRGB(143,148,145),BackgroundTransparency=1},composition)
local body=make('Frame',{Position=UDim2.fromScale(.06,.46),Size=UDim2.fromScale(.94,.53),BackgroundTransparency=1},composition)
-- A fixed design surface scales as a unit, keeping panels within the safe screen bounds.
local scale=make('UIScale',{Scale=1},body)
local function resize()
 local v=gui.AbsoluteSize
 scale.Scale=math.clamp(math.min(v.Y/620,v.X/1040),.55,1.25)
 body.Size=UDim2.fromOffset(math.max(240,v.X*.32/scale.Scale),230)
end
resize();gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize)
local status=make('TextLabel',{Position=UDim2.fromScale(.6,.92),Size=UDim2.fromScale(.36,.065),Text='',Font=Enum.Font.Garamond,TextSize=14,TextColor3=Color3.fromRGB(189,190,180),TextWrapped=true,BackgroundTransparency=1},bg)
local busy=false;local view='home';local current;local request;local render
local function button(text,y,fn)
 local b=make('TextButton',{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,44),Text=text,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Garamond,TextSize=21,TextColor3=Color3.fromRGB(156,159,151),BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false},body)
 local function focus(active)
  Tween:Create(b,TweenInfo.new(.15),{TextColor3=active and Color3.fromRGB(248,245,226) or Color3.fromRGB(156,159,151),TextStrokeTransparency=active and .7 or 1}):Play()
 end
 b.MouseEnter:Connect(function() focus(true) end);b.MouseLeave:Connect(function() focus(false) end)
 b.SelectionGained:Connect(function() focus(true) end);b.SelectionLost:Connect(function() focus(false) end)
 b.Activated:Connect(function() if not busy then fn() end end);return b
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
  button('Jogar (solo)',0,function() request('solo') end)
  button('Multiplayer',54,function() view='group';render();request('state') end)
  button('Loja',108,function() view='shop';render();request('state') end)
 elseif view=='group' then
  local party=current and current.party
  if party then
   local names={};for _,m in ipairs(party.members) do table.insert(names,m.name) end
   make('TextLabel',{Size=UDim2.new(1,0,0,55),Text='CÓDIGO: '..party.code..'  ·  '..#names..'/6\n'..table.concat(names,', '),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Garamond,TextSize=14,TextColor3=Color3.new(1,1,1),BackgroundTransparency=1},body)
   if party.leader==p.UserId then button('INICIAR GRUPO',65,function() request('start') end) end
   button('SAIR DO GRUPO',116,function() request('leave') end)
  else
   button('CRIAR GRUPO PRIVADO',0,function() request('create') end)
   local code=make('TextBox',{Position=UDim2.fromOffset(0,54),Size=UDim2.new(.6,0,0,42),PlaceholderText='CÓDIGO DO GRUPO',Text='',ClearTextOnFocus=false,Font=Enum.Font.Garamond,TextSize=16,TextColor3=Color3.new(1,1,1),BackgroundTransparency=.65,BackgroundColor3=Color3.fromRGB(10,12,12),BorderSizePixel=0},body)
   button('ENTRAR COM CÓDIGO',108,function() request('join',code.Text) end)
  end
  button('VOLTAR',170,function() view='home';render() end)
 elseif view=='shop' then
  local profile=current and current.profile
  if not profile then status.Text='Não foi possível carregar seu inventário. Reabra a loja.' end
  make('TextLabel',{Size=UDim2.new(1,0,0,25),Text='CRÉDITOS: '..tostring(profile and profile.coins or '—'),TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Garamond,TextSize=14,TextColor3=Color3.new(1,1,1),BackgroundTransparency=1},body)
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
