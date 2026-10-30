local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then return end
local p=game:GetService('Players').LocalPlayer;local RS=game:GetService('ReplicatedStorage');local UI=require(RS:WaitForChild('SessionInterface'));local make=UI.Make
local remote=RS:WaitForChild('SessionMenu')
local gui=make('ScreenGui',{Name='StillHereMenu',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=1000},p:WaitForChild('PlayerGui'))
local bg=make('Frame',{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(6,7,8),BorderSizePixel=0,ClipsDescendants=true},gui)
bg.BackgroundTransparency=1
local camera=workspace.CurrentCamera
camera.CameraType=Enum.CameraType.Scriptable
camera.CFrame=CFrame.lookAt(Vector3.new(0,5000,0),Vector3.new(0,5000,-1))
camera.FieldOfView=60
local lighting=game:GetService('Lighting');lighting.FogEnd=100000
for _,effect in ipairs(lighting:GetChildren()) do if effect:IsA('Atmosphere') then effect.Density=.05;effect.Haze=0 end end
-- The original sky effect renders in Workspace: ViewportFrames omit its beams.
local shade=make('Frame',{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0},bg)
make('UIGradient',{Transparency=NumberSequence.new(.75,.08)},shade)
local composition=make('Frame',{AnchorPoint=Vector2.new(1,0),Position=UDim2.fromScale(.95,.07),Size=UDim2.fromScale(.42,.86),BackgroundTransparency=1},bg)
local by=UI.Label(composition,'BY CH_CKZ2N',25);by.Size=UDim2.fromScale(1,.07);by.TextXAlignment=Enum.TextXAlignment.Center;by.TextSize=14
local title=UI.Label(composition,'STILL HERE',90);title.Position=UDim2.fromScale(0,.07);title.Size=UDim2.fromScale(1,.23);title.Font=Enum.Font.Antique;title.TextScaled=true;title.TextXAlignment=Enum.TextXAlignment.Center
make('UITextSizeConstraint',{MinTextSize=20,MaxTextSize=76},title)
local holder=make('Frame',{Position=UDim2.fromScale(.10,.36),Size=UDim2.fromScale(.90,.55),BackgroundTransparency=1},composition)
local list=UI.List(holder)
local status=UI.Label(composition,'',32);status.Position=UDim2.fromScale(0,.92);status.Size=UDim2.fromScale(1,.08);status.TextSize=14
local function layout() local size=bg.AbsoluteSize;composition.Size=UDim2.fromScale(size.X<size.Y and .86 or .42,.86) end
layout();bg:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
p:GetAttributeChangedSignal('InterfaceOpen'):Connect(function() composition.Visible=not p:GetAttribute('InterfaceOpen') end)
local busy=false;local current;local panel;local redraw
local function request(action,value)
 if busy then return end;busy=true
 local target=panel and panel.Gui.Parent and panel.Status or status;target.Text='Aguarde…'
 if action=='solo' or action=='start' then local ok,err=UI.Save();if not ok then target.Text=err;busy=false;return end end
 local ok,result=pcall(function() return remote:InvokeServer(action,value) end);busy=false
 if not ok then target.Text='Falha de conexão. Tente novamente.';return end
 current=result.data or current;target.Text=result.message or ''
 if panel and panel.Gui.Parent and redraw then redraw() end
end
local function groups()
 panel=UI.Panel('MULTIPLAYER');local left=make('Frame',{Position=UDim2.fromScale(.15,0),Size=UDim2.fromScale(.32,1),BackgroundTransparency=1},panel.Content);local tabs=UI.List(left)
 local right=make('Frame',{Position=UDim2.fromScale(.50,0),Size=UDim2.fromScale(.50,1),BackgroundColor3=Color3.fromRGB(8,20,24),BackgroundTransparency=.20,BorderSizePixel=0},panel.Content);local rows=UI.List(right)
 local view='list';local capacity=6;local friends=false
 redraw=function()
  if not panel or not panel.Gui.Parent then return end
  for _,c in ipairs(rows:GetChildren()) do if c:IsA('GuiObject') then c:Destroy() end end
  local party=current and current.party
  if party then
   UI.Label(rows,'GRUPO '..party.code..' · '..#party.members..'/'..(party.capacity or 6),44)
   for _,member in ipairs(party.members) do UI.Label(rows,member.name..(member.id==party.leader and ' · líder' or ''),44) end
   if party.leader==p.UserId then UI.Button(rows,'INICIAR PARTIDA',function() request('start') end) end
   UI.Button(rows,'SAIR DO GRUPO',function() request('leave') end)
  elseif view=='create' then
   UI.Label(rows,'CRIAR GRUPO',44)
   UI.Button(rows,'Limite: '..capacity..' jogadores',function() capacity=capacity==6 and 2 or capacity+1;redraw() end)
   UI.Button(rows,friends and 'Acesso: somente amigos' or 'Acesso: todos',function() friends=not friends;redraw() end)
   UI.Button(rows,'CRIAR',function() request('create',{capacity=capacity,friendsOnly=friends}) end)
  elseif view=='code' then
   UI.Label(rows,'ENTRAR COM CÓDIGO',44)
   local code=make('TextBox',{Size=UDim2.new(1,0,0,48),Text='',PlaceholderText='CÓDIGO DO GRUPO',ClearTextOnFocus=false,Font=Enum.Font.Garamond,TextSize=20,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(25,36,35),BorderSizePixel=0},rows)
   UI.Button(rows,'ENTRAR',function() request('join',code.Text) end)
  else
   UI.Label(rows,'GRUPOS DESTE LOBBY',44)
   local available=current and current.groups or {}
   if #available==0 then UI.Label(rows,'Nenhum grupo esperando. Crie um para chamar outras pessoas.',90) end
   for _,g in ipairs(available) do UI.Button(rows,g.name..' · '..g.count..'/'..g.capacity..(g.friendsOnly and ' · amigos' or ''),function() request('join',g.code) end) end
  end
 end
 UI.Button(tabs,'GRUPOS',function() view='list';redraw();request('state') end)
 UI.Button(tabs,'CRIAR',function() view='create';redraw() end)
 UI.Button(tabs,'CÓDIGO',function() view='code';redraw() end)
 for _,b in ipairs(tabs:GetChildren()) do if b:IsA('TextButton') then b.Font=Enum.Font.Oswald;b.TextSize=28;b.TextXAlignment=Enum.TextXAlignment.Right end end
 redraw();task.spawn(request,'state')
end
UI.Button(list,'Jogar (solo)',function() request('solo') end)
UI.Button(list,'Multiplayer',groups)
UI.Button(list,'Configurações',UI.OpenSettings)
UI.Button(list,'Créditos',function()
 local credits=UI.Panel('CRÉDITOS');local scroll=UI.List(credits.Content)
 UI.Label(scroll,'STILL HERE\nBy ch_ckz2n',90)
 UI.Label(scroll,'Mansão e sistemas originais: The Mystery of Duvall Drive — Roblox.\nArmas: FPS System Demo (asset 15864801103).\nCéu: Beyond the Dark — Roblox.',150)
 UI.Label(scroll,'ContextActionUtility: PseudoPerson · CC BY.\nObrigado por jogar.',90)
end)
p:SetAttribute('MenuReady',true)
task.spawn(function() UI.Load();request('state') end)
RS:WaitForChild('SessionNotice').OnClientEvent:Connect(function(message) busy=false;status.Text=message;if panel and panel.Gui.Parent then panel.Status.Text=message end end)
task.spawn(function() while gui.Parent do task.wait(5);if panel and panel.Gui.Parent and current and current.party and not busy then request('state') end end end)
