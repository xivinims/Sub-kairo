local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then return end
local p=game:GetService('Players').LocalPlayer;local RS=game:GetService('ReplicatedStorage');local UI=require(RS:WaitForChild('SessionInterface'));local make=UI.Make
local remote=RS:WaitForChild('SessionMenu')
local gui=make('ScreenGui',{Name='StillHereMenu',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=1000},p:WaitForChild('PlayerGui'))
-- Hold the menu until the actual scene has rendered and important local
-- assets have finished their first preload attempt. No imaginary 100% bar.
local ContentProvider=game:GetService('ContentProvider')
local rf=game:GetService('ReplicatedFirst')
local overlay=make('ScreenGui',{
 Name='MenuCinematicLoading',ResetOnSpawn=false,IgnoreGuiInset=true,
 DisplayOrder=1900,ZIndexBehavior=Enum.ZIndexBehavior.Sibling
},p:WaitForChild('PlayerGui'))
local loadingShade=make('Frame',{
 Name='LoadingShade',Size=UDim2.fromScale(1,1),
 BackgroundColor3=Color3.fromRGB(2,3,6),BorderSizePixel=0
},overlay)
local loadingCopy=make('TextLabel',{
 Name='LoadingMessage',AnchorPoint=Vector2.new(0,1),
 Position=UDim2.new(0,28,1,-34),Size=UDim2.new(1,-56,0,28),
 BackgroundTransparency=1,Text='PREPARANDO O CENÁRIO...',
 TextColor3=Color3.fromRGB(213,220,221),
 Font=Enum.Font.RobotoCondensed,TextSize=17,
 TextXAlignment=Enum.TextXAlignment.Left
},loadingShade)
local loadingSub=make('TextLabel',{
 Name='LoadingSubtext',AnchorPoint=Vector2.new(0,1),
 Position=UDim2.new(0,28,1,-12),Size=UDim2.new(1,-56,0,18),
 BackgroundTransparency=1,Text='EXPERIÊNCIA DE TERROR INDEPENDENTE',
 TextColor3=Color3.fromRGB(102,118,126),
 Font=Enum.Font.RobotoCondensed,TextSize=10,
 TextXAlignment=Enum.TextXAlignment.Left
},loadingShade)
p:SetAttribute('MenuReady',false)
p:SetAttribute('MenuAssetPreloadStatus','loading')

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
-- Photo-inspired cinematic layout: small typography in the upper-left,
-- a short operator briefing beneath it, and FULLY UNOBSTRUCTED world 3D.
-- No oversized semi-opaque menu rectangles or right-side button container.
local Tween=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local composition=make('Frame',{
 Name='CinematicLeftMenu',Position=UDim2.fromScale(.047,.075),
 Size=UDim2.fromScale(.35,.57),BackgroundTransparency=1,BorderSizePixel=0
},bg)
local by=UI.Label(composition,'ARQUIVO 01  /  CAPÍTULOS',18)
by.Position=UDim2.fromScale(0,0);by.Size=UDim2.new(1,0,0,18)
by.Font=Enum.Font.GothamMedium;by.TextSize=10
by.TextColor3=Color3.fromRGB(140,144,148)
local stillHereLogoId='rbxassetid://82992691266920'
local title=make('ImageLabel',{
 Name='StillHereTitle',Position=UDim2.new(0,0,0,18),
 Size=UDim2.new(0,0,0,0),BackgroundTransparency=1,
 Image=stillHereLogoId,ScaleType=Enum.ScaleType.Fit
},composition)
local titleFallback=UI.Label(composition,'STILL HERE',55)
titleFallback.Name='StillHereTitleFallback'
titleFallback.Position=UDim2.new(0,0,0,18)
titleFallback.Size=UDim2.new(1,0,0,53)
titleFallback.Font=Enum.Font.Antique;titleFallback.TextSize=37
titleFallback.TextScaled=false;titleFallback.TextXAlignment=Enum.TextXAlignment.Left
titleFallback.TextColor3=Color3.fromRGB(234,230,218)
titleFallback.Visible=false
make('UITextSizeConstraint',{MinTextSize=25,MaxTextSize=40},titleFallback)
local nav=make('Frame',{
 Name='StoryStyleNavigation',Position=UDim2.new(0,0,0,82),
 Size=UDim2.new(1,0,1,-82),BackgroundTransparency=1,BorderSizePixel=0
},composition)
local status=UI.Label(composition,'',28)
status.Name='MenuStatus'
status.Position=UDim2.new(0,0,1,-25)
status.Size=UDim2.new(1,0,0,25)
status.TextSize=12
status.TextColor3=Color3.fromRGB(208,179,163)

local news=make('Frame',{
 Name='OperatorBriefing',Position=UDim2.fromScale(.047,.633),
 Size=UDim2.fromScale(.33,.317),BackgroundTransparency=1,BorderSizePixel=0
},bg)
local heading=UI.Label(news,'MESSAGE OF THE DAY',20)
heading.Name='BriefingHeading'
heading.Position=UDim2.new(0,0,0,0)
heading.Size=UDim2.new(.56,0,0,20)
heading.TextXAlignment=Enum.TextXAlignment.Left
heading.Font=Enum.Font.RobotoCondensed;heading.TextSize=12
heading.TextColor3=Color3.fromRGB(232,232,222)
local newsIndex=1
local motdText=UI.Label(news,'CHAPTER 2 — IN DEVELOPMENT',22)
motdText.Name='Chapter2Announcement'
motdText.Position=UDim2.new(0,0,0,21)
motdText.Size=UDim2.new(1,0,0,21)
motdText.Font=Enum.Font.RobotoCondensed;motdText.TextSize=12
motdText.TextColor3=Color3.fromRGB(191,196,190)
motdText.TextXAlignment=Enum.TextXAlignment.Left
-- Three original cassette illustrations, packed into one horizontal sprite.
-- Each frame is 320×180 and contains the requested hand-lettered label.
local cassetteImageId='rbxassetid://132118511952340'
local fallbackCassetteImageId='rbxassetid://82560036333396'
local cassetteImageReady
local bulletins={
 {name='CHAPTER 1',number='TAPE 01',row=0},
 {name='MISSION FOUND',number='TAPE 02',row=1},
 {name='YOU ARE MY TOOLS',number='TAPE 03',row=2}
}
local paging=UI.Label(news,'1 / 3',20)
paging.Name='BriefingCounter'
paging.Position=UDim2.new(1,-80,0,0)
paging.Size=UDim2.new(0,39,0,20)
paging.TextXAlignment=Enum.TextXAlignment.Center
paging.Font=Enum.Font.RobotoCondensed;paging.TextSize=11
local prior=make('TextButton',{
 Name='PreviousBriefing',Position=UDim2.new(1,-113,0,0),Size=UDim2.fromOffset(25,22),
 Text='‹',Font=Enum.Font.GothamBold,TextSize=20,BackgroundTransparency=1,
 TextColor3=Color3.fromRGB(212,214,213),BorderSizePixel=0
},news)
local nextButton=make('TextButton',{
 Name='NextBriefing',Position=UDim2.new(1,-37,0,0),Size=UDim2.fromOffset(25,22),
 Text='›',Font=Enum.Font.GothamBold,TextSize=20,BackgroundTransparency=1,
 TextColor3=Color3.fromRGB(212,214,213),BorderSizePixel=0
},news)
local preview=make('ImageLabel',{
 Name='BriefingPreview',Position=UDim2.new(0,0,0,44),
 Size=UDim2.new(1,0,1,-67),
 BackgroundTransparency=1,BorderSizePixel=0,
 Image=cassetteImageId,
 ImageRectOffset=Vector2.new(0,0),
 ImageRectSize=Vector2.new(320,180),
 ImageTransparency=0,
 ScaleType=Enum.ScaleType.Fit
},news)
-- Show the cassette itself, not the previous generic text/thumbnail card.
local footer=UI.Label(news,'CHAPTER 1',18)
footer.Name='CassetteLabel'
footer.Position=UDim2.new(0,0,1,-19)
footer.Size=UDim2.new(1,0,0,18)
footer.TextXAlignment=Enum.TextXAlignment.Left
footer.Font=Enum.Font.RobotoCondensed
footer.TextSize=11
footer.TextColor3=Color3.fromRGB(177,186,187)
local function stepTape(direction)
 newsIndex=(newsIndex-1+direction)%#bulletins+1
 local item=bulletins[newsIndex]
 if cassetteImageReady==false then
  preview.Image=fallbackCassetteImageId
  preview.ImageRectSize=Vector2.new(200,66)
  preview.ImageRectOffset=Vector2.new(0,item.row*66)
 else
  preview.Image=cassetteImageId
  preview.ImageRectSize=Vector2.new(320,180)
  preview.ImageRectOffset=Vector2.new(item.row*320,0)
 end
 paging.Text=tostring(newsIndex)..' / '..tostring(#bulletins)
 footer.Text=item.name
end
-- Finger swipe works on iPhone without interfering with menu navigation.
local touchStart
preview.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch then
  touchStart=input.Position
 end
end)
preview.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch and touchStart then
  local delta=input.Position.X-touchStart.X
  if math.abs(delta)>36 then
   stepTape(delta<0 and 1 or -1)
  end
  touchStart=nil
 end
end)

local function updateBriefing()
 stepTape(0)
end
prior.Activated:Connect(function() stepTape(-1) end)
nextButton.Activated:Connect(function() stepTape(1) end)
updateBriefing()
local selectedChapter=1
local chapterTwo=make('Frame',{
 Name='ChapterTwoMenu',AnchorPoint=Vector2.new(1,0),
 Position=UDim2.fromScale(.96,.18),Size=UDim2.fromScale(.34,.48),
 BackgroundTransparency=1,BorderSizePixel=0,Visible=false
},bg)
local chapterEyebrow=UI.Label(chapterTwo,'CHAPTER 02  /  STILL HERE',24)
chapterEyebrow.Name='ChapterTwoEyebrow';chapterEyebrow.Position=UDim2.new(0,0,0,0);chapterEyebrow.Size=UDim2.new(1,0,0,24)
chapterEyebrow.Font=Enum.Font.RobotoCondensed;chapterEyebrow.TextSize=13;chapterEyebrow.TextColor3=Color3.fromRGB(175,181,180)
local chapterTitle=UI.Label(chapterTwo,'AQUELE QUE NÃO ENCONTRA',68)
chapterTitle.Name='ChapterTwoTitle';chapterTitle.Position=UDim2.new(0,0,0,31);chapterTitle.Size=UDim2.new(1,0,0,68)
chapterTitle.Font=Enum.Font.RobotoCondensed;chapterTitle.TextSize=31;chapterTitle.TextWrapped=true;chapterTitle.TextColor3=Color3.fromRGB(232,230,220)
local chapterDetail=UI.Label(chapterTwo,'CHAPTER 2  ·  ENGLISH',30)
chapterDetail.Name='ChapterTwoLanguage';chapterDetail.Position=UDim2.new(0,0,0,106);chapterDetail.Size=UDim2.new(1,0,0,28)
chapterDetail.Font=Enum.Font.RobotoCondensed;chapterDetail.TextSize=15;chapterDetail.TextColor3=Color3.fromRGB(184,188,183)
local chapterUnavailable=UI.Label(chapterTwo,'NOT YET CONNECTED TO THIS EXPERIENCE',46)
chapterUnavailable.Name='ChapterTwoAvailability';chapterUnavailable.Position=UDim2.new(0,0,0,146);chapterUnavailable.Size=UDim2.new(1,0,0,42)
chapterUnavailable.Font=Enum.Font.RobotoCondensed;chapterUnavailable.TextSize=12;chapterUnavailable.TextColor3=Color3.fromRGB(188,97,89)
chapterUnavailable.TextWrapped=true
local function layout()
 local size=bg.AbsoluteSize
 local landscape=size.X>=size.Y
 local compact=size.X<900
 local mobile=UIS.TouchEnabled
 composition.Position=UDim2.fromScale(landscape and .047 or .065,.075)
 composition.Size=UDim2.fromScale(mobile and (landscape and .40 or .39) or (landscape and (compact and .43 or .32) or .86),landscape and .58 or .45)
 title.Size=UDim2.fromOffset(mobile and 52 or 60,mobile and 52 or 60)
 titleFallback.Size=UDim2.new(1,0,0,53)
 nav.Position=UDim2.new(0,0,0,compact and 65 or 88)
 nav.Size=UDim2.new(1,0,1,-(compact and 65 or 88))
 if mobile then
  news.AnchorPoint=Vector2.new(1,0)
  news.Position=UDim2.fromScale(.97,.055)
  news.Size=UDim2.fromScale(landscape and .38 or .54,landscape and .55 or .30)
  chapterTwo.Position=UDim2.fromScale(.97,landscape and .14 or .31)
  chapterTwo.Size=UDim2.fromScale(landscape and .46 or .54,landscape and .57 or .34)
 else
  news.AnchorPoint=Vector2.new(0,0)
  news.Position=UDim2.fromScale(landscape and .047 or .065,landscape and .633 or .59)
  news.Size=UDim2.fromScale(landscape and (compact and .32 or .29) or .83,landscape and .317 or .34)
  chapterTwo.Position=UDim2.fromScale(.96,.18)
  chapterTwo.Size=UDim2.fromScale(.34,.48)
 end
 heading.TextSize=mobile and 10 or 12
 motdText.TextSize=mobile and 10 or 12
 preview.Position=UDim2.new(0,0,0,44)
 preview.Size=UDim2.new(1,0,1,-67)
 footer.Position=UDim2.new(0,0,1,-18)
end
layout()
bg:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
composition.Visible=false
news.Visible=false
chapterTwo.Visible=false
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
local navButtons={}
local activeNav=1
local infoButton
local creditsGui
local busy=false;local current;local panel;local redraw
local function startPresentation()
 starting=true
 p:SetAttribute('MenuCameraMode','starting')
 if creditsGui and creditsGui.Parent then creditsGui:Destroy();creditsGui=nil end
 if infoButton then infoButton.Visible=false end
 composition.Visible=false
 news.Visible=false
 chapterTwo.Visible=false
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
 news.Visible=not p:GetAttribute('InterfaceOpen') and selectedChapter==1
 chapterTwo.Visible=not p:GetAttribute('InterfaceOpen') and selectedChapter==2
 if infoButton then infoButton.Visible=not p:GetAttribute('InterfaceOpen') end
end
p:GetAttributeChangedSignal('InterfaceOpen'):Connect(function()
 local visible=not starting and not p:GetAttribute('InterfaceOpen')
 composition.Visible=visible
 news.Visible=visible and selectedChapter==1
 chapterTwo.Visible=visible and selectedChapter==2
 if infoButton then infoButton.Visible=visible end
end)
local function request(action,value)
 if busy then return end
 if (action=='solo' or action=='start') and selectedChapter==2 then
  status.Text='Chapter 2 is not connected to this experience yet.'
  return
 end
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
-- Reference-style text-only actions, red selection marker and subtle easing.
-- Buttons retain generous transparent tap zones for iPhone touch.
local function selectNavigation(index)
 activeNav=index
 for i,item in ipairs(navButtons) do
  local chosen=i==index
  Tween:Create(item.label,TweenInfo.new(.16),{
   TextColor3=chosen and Color3.fromRGB(247,246,237) or Color3.fromRGB(162,169,174),
   TextTransparency=chosen and 0 or .12
  }):Play()
  Tween:Create(item.marker,TweenInfo.new(.16),{TextTransparency=chosen and 0 or 1}):Play()
 end
end
local function addNavigation(text,action)
 local index=#navButtons+1
 local btn=make('TextButton',{
  Name='MenuAction'..index,Position=UDim2.new(0,0,0,(index-1)*42),
  Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,BorderSizePixel=0,
  Text='',AutoButtonColor=false
 },nav)
 local marker=make('TextLabel',{
  Name='RedSelectionMarker',Position=UDim2.new(0,0,0,0),
  Size=UDim2.fromOffset(21,42),BackgroundTransparency=1,
  Text='▶',Font=Enum.Font.GothamBold,TextSize=11,
  TextColor3=Color3.fromRGB(211,47,59),TextTransparency=1
 },btn)
 local label=make('TextLabel',{
  Name='ActionText',Position=UDim2.new(0,23,0,0),
  Size=UDim2.new(1,-23,1,0),BackgroundTransparency=1,
  Text=text,Font=Enum.Font.RobotoCondensed,
  TextSize=UIS.TouchEnabled and 16 or 18,TextXAlignment=Enum.TextXAlignment.Left,
  TextColor3=Color3.fromRGB(162,169,174)
 },btn)
 table.insert(navButtons,{button=btn,marker=marker,label=label,action=action})
 btn.MouseEnter:Connect(function() selectNavigation(index) end)
 btn.SelectionGained:Connect(function() selectNavigation(index) end)
 btn.Activated:Connect(function()
  selectNavigation(index)
  if not starting then action() end
 end)
 return btn
end
local function chooseChapter(index)
 selectedChapter=index
 local visible=not starting and not p:GetAttribute('InterfaceOpen')
 news.Visible=visible and index==1
 chapterTwo.Visible=visible and index==2
 if index==1 then
  status.Text='Capítulo 1 selecionado.'
 else
  status.Text='Aquele que não encontra · Chapter 2 in English.'
 end
end
addNavigation('CHAPTER 1',function() chooseChapter(1) end)
addNavigation('CHAPTER 2',function() chooseChapter(2) end)
addNavigation('JOGAR (SOLO)',function() request('solo') end)
addNavigation('MULTIPLAYER',groups)
addNavigation('CONFIGURAÇÕES',UI.OpenSettings)
selectNavigation(1)
UIS.InputBegan:Connect(function(input,processed)
 if processed or starting or p:GetAttribute('InterfaceOpen') then return end
 if input.KeyCode==Enum.KeyCode.Up or input.KeyCode==Enum.KeyCode.DPadUp then
  selectNavigation((activeNav-2)%#navButtons+1)
 elseif input.KeyCode==Enum.KeyCode.Down or input.KeyCode==Enum.KeyCode.DPadDown then
  selectNavigation(activeNav%#navButtons+1)
 elseif input.KeyCode==Enum.KeyCode.Return or input.KeyCode==Enum.KeyCode.ButtonA then
  navButtons[activeNav].action()
 elseif input.KeyCode==Enum.KeyCode.Q then
  stepTape(-1)
 elseif input.KeyCode==Enum.KeyCode.E then
  stepTape(1)
 end
end)
-- An unobtrusive information icon, anchored to the lower-left safe area.
-- It replaces the old full-size 'Créditos' entry in the main menu.
infoButton=make('TextButton',{
 Name='CreditsInfoButton',AnchorPoint=Vector2.new(0,1),
 Position=UDim2.new(1,-57,1,-23),Size=UDim2.fromOffset(38,38),
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
  Text='CREDITS',TextXAlignment=Enum.TextXAlignment.Left,
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
infoButton.Visible=false
-- Do not preload the entire world or rely on RequestQueueSize. Preload the
-- source black-hole meshes/textures and the existing menu audio only.
local assetsDone=false
local assetsFailed=0
task.spawn(function()
 local preloads={}
 local model=RS:WaitForChild('SkyBlackHoleTemplate',12)
 if model then table.insert(preloads,model) end
 -- Preload the new cassette image before revealing the slider.
 table.insert(preloads,preview)
 table.insert(preloads,title)
 local music=game:GetService('SoundService'):FindFirstChild('MassiveBlackHoleMenu')
 if music then table.insert(preloads,music) end
 if #preloads>0 then
  local ok,err=pcall(function()
   ContentProvider:PreloadAsync(preloads,function(assetId,status)
    if status~=Enum.AssetFetchStatus.Success then
     assetsFailed+=1
     warn('[MenuLoad] Asset unavailable: '..tostring(assetId)..' ('..tostring(status)..')')
    end
   end)
  end)
  if not ok then
   warn('[MenuLoad] Preload failure (fallback allowed): '..tostring(err))
   assetsFailed+=1
  end
 end
 cassetteImageReady=preview.IsLoaded
 if not cassetteImageReady then stepTape(0) end
 assetsDone=true
end)
task.spawn(function()
 -- Wait for the real first-frame black-hole and effects, and for essential
 -- resource fetches. Never wait forever for a blocked third-party sound.
 local started=os.clock()
 local complete=false
 while gui.Parent and os.clock()-started<22 do
  local sceneReady=p:GetAttribute('MenuBlackHoleReady')==true
  local effectsReady=p:GetAttribute('MenuEffectsReady')==true
  local avatarReady=p:GetAttribute('MenuAvatarReady')==true
  if not sceneReady then loadingCopy.Text='PREPARANDO BURACO NEGRO...'
  elseif not avatarReady then loadingCopy.Text='PREPARANDO O AVATAR...'
  elseif not effectsReady then loadingCopy.Text='AJUSTANDO ILUMINAÇÃO...'
  elseif not assetsDone then loadingCopy.Text='CARREGANDO TEXTURAS E ÁUDIO...'
  else complete=true;break end
  task.wait(.15)
 end
 if not gui.Parent then if overlay.Parent then overlay:Destroy() end;return end
 if not complete then
  warn('[MenuLoad] Timeout: open with best available assets rather than hang')
  p:SetAttribute('MenuAssetPreloadStatus','partial')
 else
  p:SetAttribute('MenuAssetPreloadStatus',assetsFailed==0 and 'ready' or 'partial')
 end
 -- A few rendered frames after readiness let Beams/particles and the local
 -- camera catch up before revealing the real 3D scene.
 for _=1,3 do game:GetService('RunService').RenderStepped:Wait() end
 if overlay.Parent then
  local Tween=game:GetService('TweenService')
  local fade=Tween:Create(loadingShade,TweenInfo.new(.65,Enum.EasingStyle.Quad),{BackgroundTransparency=1})
  Tween:Create(loadingCopy,TweenInfo.new(.5),{TextTransparency=1}):Play()
  Tween:Create(loadingSub,TweenInfo.new(.5),{TextTransparency=1}):Play()
  fade:Play()
  fade.Completed:Wait()
  overlay:Destroy()
 end
 if starting then return end
 title.Visible=title.IsLoaded
 titleFallback.Visible=not title.IsLoaded
 local visible=not p:GetAttribute('InterfaceOpen')
 composition.Visible=visible
 news.Visible=visible and selectedChapter==1
 chapterTwo.Visible=visible and selectedChapter==2
 infoButton.Visible=visible
 p:SetAttribute('MenuReady',true)
 task.spawn(function() request('state') end)
end)
task.spawn(function() UI.Load() end)
RS:WaitForChild('SessionNotice').OnClientEvent:Connect(function(message)
 busy=false
 restorePresentation()
 status.Text=message
 if panel and panel.Gui.Parent then panel.Status.Text=message end
end)
task.spawn(function() while gui.Parent do task.wait(5);if panel and panel.Gui.Parent and current and current.party and not busy then request('state') end end end)
