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
camera.CFrame=CFrame.lookAt(Vector3.new(0,5001.05,1.3),Vector3.new(-.65,5001.05,-12))
p:SetAttribute('MenuCameraMode','wide')
camera.FieldOfView=60
local lighting=game:GetService('Lighting');lighting.FogEnd=100000
-- Menu-only lighting: expose the singularity, not a screen-filling flare.
lighting.ExposureCompensation=-.32
for _,effect in ipairs(lighting:GetChildren()) do
 if effect:IsA('Atmosphere') then effect.Density=.025;effect.Haze=0;effect.Glare=0
 elseif effect:IsA('BloomEffect') then
  effect.Intensity=math.min(effect.Intensity,.75)
  effect.Threshold=math.max(effect.Threshold,1.15)
  effect.Size=math.min(effect.Size,32)
 elseif effect:IsA('SunRaysEffect') then effect.Enabled=false end
end
-- The original sky effect renders in Workspace: ViewportFrames omit its beams.
-- Leave the entire 3D background uncovered, especially the black-hole disk.
-- The old full-screen semi-transparent shade made a huge rectangular overlay.
local composition=make('Frame',{AnchorPoint=Vector2.new(1,0),Position=UDim2.fromScale(.95,.07),Size=UDim2.fromScale(.42,.86),BackgroundTransparency=1},bg)
local by=UI.Label(composition,'BY CH_CKZ2N',25);by.Size=UDim2.fromScale(1,.07);by.TextXAlignment=Enum.TextXAlignment.Center;by.TextSize=14
local title=UI.Label(composition,'STILL HERE',90);title.Position=UDim2.fromScale(0,.07);title.Size=UDim2.fromScale(1,.23);title.Font=Enum.Font.Antique;title.TextScaled=true;title.TextXAlignment=Enum.TextXAlignment.Center
make('UITextSizeConstraint',{MinTextSize=20,MaxTextSize=76},title)
local holder=make('Frame',{Position=UDim2.fromScale(.10,.36),Size=UDim2.fromScale(.90,.55),BackgroundTransparency=1},composition)
local list=UI.List(holder)
local status=UI.Label(composition,'',32);status.Position=UDim2.fromScale(0,.92);status.Size=UDim2.fromScale(1,.08);status.TextSize=14
local function layout() local size=bg.AbsoluteSize;composition.Size=UDim2.fromScale(size.X<size.Y and .86 or .42,.86) end
layout();bg:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
local startLabel=UI.Label(bg,'INICIANDO...',55)
startLabel.Name='StartingMessage'
startLabel.AnchorPoint=Vector2.new(.5,.5)
startLabel.Position=UDim2.fromScale(.73,.54)
startLabel.Size=UDim2.fromScale(.38,.12)
startLabel.Font=Enum.Font.Oswald;startLabel.TextScaled=true
startLabel.TextXAlignment=Enum.TextXAlignment.Center
startLabel.Visible=false
make('UITextSizeConstraint',{MinTextSize=16,MaxTextSize=38},startLabel)
local starting=false
local infoButton
local creditsGui
local busy=false;local current;local panel;local redraw
local function startPresentation()
 starting=true
 p:SetAttribute('MenuCameraMode','starting')
 if creditsGui and creditsGui.Parent then creditsGui:Destroy();creditsGui=nil end
 if infoButton then infoButton.Visible=false end
 composition.Visible=false
 if panel and panel.Gui.Parent then panel.Gui.Enabled=false end
 startLabel.Visible=true
end
local function restorePresentation()
 if not starting then return end
 starting=false
 p:SetAttribute('MenuCameraMode',panel and panel.Gui.Parent and 'close' or 'wide')
 startLabel.Visible=false
 if panel and panel.Gui.Parent then panel.Gui.Enabled=true end
 composition.Visible=not p:GetAttribute('InterfaceOpen')
 if infoButton then infoButton.Visible=not p:GetAttribute('InterfaceOpen') end
end
p:GetAttributeChangedSignal('InterfaceOpen'):Connect(function()
 local visible=not starting and not p:GetAttribute('InterfaceOpen')
 composition.Visible=visible
 if infoButton then infoButton.Visible=visible end
end)
local function request(action,value)
 if busy then return end
 busy=true
 local launching=action=='solo' or action=='start'
 local target=panel and panel.Gui.Parent and panel.Status or status
 if launching then
  local saved,err=UI.Save()
  if not saved then target.Text=err;busy=false;return end
  startPresentation()
  -- Give only the initiating client time to see the singularity burst before teleport.
  task.wait(1.35)
 else target.Text='Aguarde…' end
 local ok,result=pcall(function() return remote:InvokeServer(action,value) end)
 busy=false
 if not ok or type(result)~='table' then
  restorePresentation();target.Text='Falha de conexão. Tente novamente.';return
 end
 current=result.data or current
 if not result.ok then restorePresentation() end
 target.Text=result.message or ''
 if result.ok and launching then
  -- Teleport keeps the cinematic until a new place loads; recover if teleport never completes.
  task.delay(24,function()
   if starting and gui.Parent then
    restorePresentation()
    status.Text='A partida não iniciou. Tente novamente.'
   end
  end)
 end
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
-- An unobtrusive information icon, anchored to the lower-left safe area.
-- It replaces the old full-size 'Créditos' entry in the main menu.
infoButton=make('TextButton',{
 Name='CreditsInfoButton',AnchorPoint=Vector2.new(0,1),
 Position=UDim2.new(0,18,1,-22),Size=UDim2.fromOffset(40,40),
 BackgroundColor3=Color3.fromRGB(7,17,22),BackgroundTransparency=.28,
 BorderSizePixel=0,Text='i',Font=Enum.Font.GothamBold,TextSize=22,
 TextColor3=Color3.fromRGB(225,231,232),AutoButtonColor=true,ZIndex=5
},bg)
make('UICorner',{CornerRadius=UDim.new(1,0)},infoButton)
make('UIStroke',{Color=Color3.fromRGB(123,151,166),Thickness=1,Transparency=.33},infoButton)

local function openModelCredits()
 if starting then return end
 if creditsGui and creditsGui.Parent then creditsGui:Destroy();creditsGui=nil;return end
 local overlay=make('ScreenGui',{Name='ModelCreditsOverlay',ResetOnSpawn=false,
  IgnoreGuiInset=false,DisplayOrder=1600,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},p:WaitForChild('PlayerGui'))
 creditsGui=overlay
 local dim=make('TextButton',{Name='CloseOutside',Size=UDim2.fromScale(1,1),
  Text='',AutoButtonColor=false,BorderSizePixel=0,
  BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.48},overlay)
 local card=make('Frame',{Name='ModelCreditsCard',AnchorPoint=Vector2.new(.5,.5),
  Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.88,.77),
  BackgroundColor3=Color3.fromRGB(8,15,20),BackgroundTransparency=.05,
  BorderSizePixel=0,ClipsDescendants=true},overlay)
 make('UISizeConstraint',{MaxSize=Vector2.new(520,640),MinSize=Vector2.new(255,300)},card)
 make('UICorner',{CornerRadius=UDim.new(0,12)},card)
 make('UIStroke',{Color=Color3.fromRGB(100,137,150),Thickness=1,Transparency=.4},card)
 make('TextLabel',{Name='CreditsTitle',BackgroundTransparency=1,
  Position=UDim2.new(0,18,0,16),Size=UDim2.new(1,-80,0,39),
  Text='MODEL CREDITS',TextXAlignment=Enum.TextXAlignment.Left,
  Font=Enum.Font.Oswald,TextSize=30,TextColor3=Color3.fromRGB(231,233,233)},card)
 local close=make('TextButton',{Name='CloseCredits',AnchorPoint=Vector2.new(1,0),
  Position=UDim2.new(1,-14,0,15),Size=UDim2.fromOffset(37,37),
  Text='×',Font=Enum.Font.GothamBold,TextSize=26,
  TextColor3=Color3.fromRGB(233,240,239),
  BackgroundColor3=Color3.fromRGB(27,43,51),BackgroundTransparency=.3,
  BorderSizePixel=0},card)
 make('UICorner',{CornerRadius=UDim.new(0,8)},close)
 local scroll=UI.List(card)
 scroll.Name='ModelCreditsScroll'
 scroll.Position=UDim2.new(0,15,0,71)
 scroll.Size=UDim2.new(1,-30,1,-85)
 scroll.ScrollBarThickness=2
 local function addSource(section,project,author,extra)
  local block=make('Frame',{Name='CreditEntry',Size=UDim2.new(1,-8,0,extra and 96 or 75),
   BackgroundColor3=Color3.fromRGB(20,33,41),BackgroundTransparency=.37,BorderSizePixel=0},scroll)
  make('UICorner',{CornerRadius=UDim.new(0,7)},block)
  local category=UI.Label(block,string.upper(section),18)
  category.Position=UDim2.new(0,12,0,5);category.Size=UDim2.new(1,-24,0,18)
  category.Font=Enum.Font.GothamBold;category.TextSize=10;category.TextColor3=Color3.fromRGB(132,168,185)
  local name=UI.Label(block,project,22)
  name.Position=UDim2.new(0,12,0,23);name.Size=UDim2.new(1,-24,0,23)
  name.TextSize=19;name.TextColor3=Color3.fromRGB(235,239,240)
  local creator=UI.Label(block,'Criador: '..author,19)
  creator.Position=UDim2.new(0,12,0,49);creator.Size=UDim2.new(1,-24,0,18)
  creator.Font=Enum.Font.Gotham;creator.TextSize=12;creator.TextColor3=Color3.fromRGB(179,201,208)
  if extra then
   local detail=UI.Label(block,extra,18)
   detail.Position=UDim2.new(0,12,0,71);detail.Size=UDim2.new(1,-24,0,18)
   detail.TextSize=11;detail.Font=Enum.Font.Gotham
   detail.TextColor3=Color3.fromRGB(149,170,177)
  end
 end
 -- Creator names confirmed via Roblox MarketplaceService on 2026-10-30.
 addSource('Mansão','The Mystery of Duvall Drive','Alpha Strike Group')
 addSource('Buraco negro','Beyond the Dark','Alpha Strike Group','Efeitos do buraco negro: Chad Foxglove')
 addSource('Sistemas','FPS System Demo','Bobbity Games')
 addSource('Áudio ambiente','Massive Black Hole','APMOfficial')
 addSource('Emote','Low Gravity','Matching Anime Outfits')
 local note=UI.Label(scroll,'Interface e adaptação: CH_CKZ2N.\\nContextActionUtility: PseudoPerson (CC BY).\\nProjeto independente, sem afiliação oficial com os criadores citados.',98)
 note.Name='CreditsDisclaimer';note.Font=Enum.Font.Gotham;note.TextSize=11
 note.TextColor3=Color3.fromRGB(150,170,178)
 note.TextXAlignment=Enum.TextXAlignment.Center
 local function dismiss()
  if creditsGui==overlay then creditsGui=nil end
  if overlay.Parent then overlay:Destroy() end
 end
 dim.Activated:Connect(dismiss)
 close.Activated:Connect(dismiss)
end
infoButton.Activated:Connect(openModelCredits)
p:SetAttribute('MenuReady',true)
task.spawn(function() UI.Load();request('state') end)
RS:WaitForChild('SessionNotice').OnClientEvent:Connect(function(message)
 busy=false
 restorePresentation()
 status.Text=message
 if panel and panel.Gui.Parent then panel.Status.Text=message end
end)
task.spawn(function() while gui.Parent do task.wait(5);if panel and panel.Gui.Parent and current and current.party and not busy then request('state') end end end)
