local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Menu' then return end
local experienceChapter=W:GetAttribute('ExperienceChapter')==2 and 2 or 1
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
local loadingHero=make('ImageLabel',{
 Name='ChapterTwoLoadingArtwork',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
 Image='rbxassetid://__CHAPTER_TWO_ART_ASSET_ID__',ScaleType=Enum.ScaleType.Crop,
 Visible=experienceChapter==2,ZIndex=1
},loadingShade)
local loadingVignette=make('Frame',{
 Name='ChapterTwoLoadingShade',Size=UDim2.fromScale(1,1),BorderSizePixel=0,
 BackgroundColor3=Color3.fromRGB(5,10,8),BackgroundTransparency=.76,
 Visible=experienceChapter==2,ZIndex=2
},loadingShade)
local loadingTitle=make('TextLabel',{
 Name='ChapterTwoLoadingTitle',AnchorPoint=Vector2.new(0,1),
 Position=UDim2.new(0,28,1,-112),Size=UDim2.new(.78,0,0,48),
 BackgroundTransparency=1,Text='EPISÓDIO 2  ·  AQUELE QUE NÃO ENCONTRA',
 TextColor3=Color3.fromRGB(246,239,213),Font=Enum.Font.Oswald,
 TextSize=30,TextXAlignment=Enum.TextXAlignment.Left,
 Visible=experienceChapter==2,ZIndex=3
},loadingShade)
make('UITextSizeConstraint',{MinTextSize=17,MaxTextSize=32},loadingTitle)
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
 BackgroundTransparency=1,Text=experienceChapter==2 and 'STILL HERE · EPISÓDIO 2' or 'STILL HERE · EPISÓDIO 1',
 TextColor3=Color3.fromRGB(102,118,126),
 Font=Enum.Font.RobotoCondensed,TextSize=10,
 TextXAlignment=Enum.TextXAlignment.Left
},loadingShade)
p:SetAttribute('MenuReady',false)
p:SetAttribute('MenuAssetPreloadStatus','loading')

local bg=make('Frame',{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(6,7,8),BorderSizePixel=0,ClipsDescendants=true},gui)
bg.BackgroundTransparency=1
local hero=make('ImageLabel',{Name='ChapterTwoHero',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image='rbxassetid://__CHAPTER_TWO_ART_ASSET_ID__',ImageColor3=Color3.fromRGB(255,255,249),ScaleType=Enum.ScaleType.Crop,Visible=experienceChapter==2,ZIndex=1},bg)
local camera=workspace.CurrentCamera
camera.CameraType=Enum.CameraType.Scriptable
camera.CFrame=CFrame.lookAt(Vector3.new(0,5001.05,1.3),Vector3.new(-.65,5001.05,-12))
p:SetAttribute('MenuCameraMode','wide')
camera.FieldOfView=60
local lighting=game:GetService('Lighting');lighting.FogEnd=100000
-- Chapter 1 keeps its black-hole palette while lifting the subject and preserving clear shadows.
lighting.ExposureCompensation=experienceChapter==2 and .05 or .12
if experienceChapter==1 then
 lighting.Brightness=math.max(lighting.Brightness,1.25)
 lighting.GlobalShadows=true;lighting.ShadowSoftness=.34
 lighting.EnvironmentDiffuseScale=math.max(lighting.EnvironmentDiffuseScale,.42)
end
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
-- Keep the controls in the upper-left and give Chapter 2's generated art
-- a full-height poster on the right. Chapter 2 uses the same image as its backdrop.
local Tween=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local composition=make('Frame',{
 Name='CinematicLeftMenu',Position=UDim2.fromScale(.047,.075),
 Size=UDim2.fromScale(.35,.57),BackgroundTransparency=1,BorderSizePixel=0
},bg)
local by=UI.Label(composition,experienceChapter==2 and 'EPISÓDIO 2  /  ESTUFA' or 'EPISÓDIO 1',18)
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
local chapterOneTitle=make('TextLabel',{Name='ChapterOneTitle',Position=UDim2.new(0,0,0,68),Size=UDim2.new(1,0,0,27),BackgroundTransparency=1,Text='DEAD SIGNAL',Font=Enum.Font.RobotoCondensed,TextSize=23,TextColor3=Color3.fromRGB(228,224,216),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Visible=experienceChapter==1},composition)
local chapterOneDetail=make('TextLabel',{Name='ChapterOneDescription',Position=UDim2.new(0,0,0,98),Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,Text='EXPLORE A FÁBRICA. ENCONTRE A SAÍDA.',Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(184,183,178),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,Visible=experienceChapter==1},composition)
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
 Size=UDim2.fromScale(.34,.317),BackgroundTransparency=1,BorderSizePixel=0
},bg)
local heading=UI.Label(news,'MESSAGE OF THE DAY',20)
heading.Name='BriefingHeading'
heading.Position=UDim2.new(0,0,0,0)
heading.Size=UDim2.new(1,0,0,20)
heading.TextXAlignment=Enum.TextXAlignment.Left
heading.Font=Enum.Font.RobotoCondensed;heading.TextSize=12
heading.TextColor3=Color3.fromRGB(232,232,222)
local motdText=UI.Label(news,'EPISÓDIO 2 · A SINETA PAROU. A ESTUFA NÃO.',34)
motdText.Name='Chapter2Announcement'
motdText.Position=UDim2.new(0,0,0,22)
motdText.Size=UDim2.new(1,0,0,30)
motdText.Font=Enum.Font.RobotoCondensed;motdText.TextSize=12
motdText.TextColor3=Color3.fromRGB(191,196,190)
motdText.TextXAlignment=Enum.TextXAlignment.Left
motdText.TextWrapped=true
local preview=make('ImageButton',{
 Name='BriefingPreview',Position=UDim2.new(0,0,0,55),
 Size=UDim2.new(1,0,1,-81),BackgroundColor3=Color3.fromRGB(9,13,13),
 BorderSizePixel=0,Image='rbxassetid://__CHAPTER_TWO_ART_ASSET_ID__',
 ScaleType=Enum.ScaleType.Crop,AutoButtonColor=true
},news)
make('UIStroke',{Color=Color3.fromRGB(133,158,150),Thickness=1,Transparency=.35},preview)
local footer=UI.Label(news,'ABRIR EPISÓDIO 2  →',18)
footer.Name='ChapterTwoCallToAction'
footer.Position=UDim2.new(0,0,1,-20)
footer.Size=UDim2.new(1,0,0,18)
footer.TextXAlignment=Enum.TextXAlignment.Left
footer.Font=Enum.Font.RobotoCondensed;footer.TextSize=11
footer.TextColor3=Color3.fromRGB(177,186,187)
local selectedChapter=experienceChapter
p:SetAttribute('MenuChapter',selectedChapter)
local chapterMap=require(RS:WaitForChild('ChapterTwoMap'))
if experienceChapter==2 then chapterMap.BuildMenuBackdrop() end
-- Chapter 2 keeps a steady, warm exposure while its artwork is visible.
local chapterTwo=make('Frame',{
 Name='ChapterTwoMenu',AnchorPoint=Vector2.new(1,0),
 Position=UDim2.fromScale(.96,.18),Size=UDim2.fromScale(.34,.48),
 BackgroundColor3=Color3.fromRGB(7,15,12),BackgroundTransparency=.38,BorderSizePixel=0,Visible=false
},bg)
make('UICorner',{CornerRadius=UDim.new(0,8)},chapterTwo)
make('UIStroke',{Color=Color3.fromRGB(202,190,143),Thickness=1,Transparency=.35},chapterTwo)
local chapterEyebrow=UI.Label(chapterTwo,'EPISÓDIO 02  /  STILL HERE',24)
chapterEyebrow.Name='ChapterTwoEyebrow';chapterEyebrow.Position=UDim2.new(0,0,0,0);chapterEyebrow.Size=UDim2.new(1,0,0,24)
chapterEyebrow.Font=Enum.Font.RobotoCondensed;chapterEyebrow.TextSize=13;chapterEyebrow.TextColor3=Color3.fromRGB(175,181,180)
local chapterTitle=UI.Label(chapterTwo,'AQUELE QUE NÃO ENCONTRA',68)
chapterTitle.Name='ChapterTwoTitle';chapterTitle.Position=UDim2.new(0,0,0,31);chapterTitle.Size=UDim2.new(1,0,0,68)
chapterTitle.Font=Enum.Font.RobotoCondensed;chapterTitle.TextSize=31;chapterTitle.TextWrapped=true;chapterTitle.TextColor3=Color3.fromRGB(232,230,220)
local chapterDetail=UI.Label(chapterTwo,'A SINETA PAROU. A ESTUFA NÃO.',30)
chapterDetail.Name='ChapterTwoLanguage';chapterDetail.Position=UDim2.new(0,0,0,106);chapterDetail.Size=UDim2.new(1,0,0,28)
chapterDetail.Font=Enum.Font.RobotoCondensed;chapterDetail.TextSize=15;chapterDetail.TextColor3=Color3.fromRGB(184,188,183)
local chapterUnavailable=UI.Label(chapterTwo,'RECUPERE OS 3 FRAGMENTOS, REATIVE O GERADOR E ENCONTRE A SAÍDA.',56)
chapterUnavailable.Name='ChapterTwoAvailability';chapterUnavailable.Position=UDim2.new(0,0,0,146);chapterUnavailable.Size=UDim2.new(1,0,0,56)
chapterUnavailable.Font=Enum.Font.RobotoCondensed;chapterUnavailable.TextSize=12;chapterUnavailable.TextColor3=Color3.fromRGB(177,190,178)
chapterUnavailable.TextWrapped=true
local function layout()
 local size=bg.AbsoluteSize
 local landscape=size.X>=size.Y
 local compact=size.X<900
 local mobile=UIS.TouchEnabled and not UIS.MouseEnabled
 composition.Position=UDim2.fromScale(landscape and .047 or .065,.075)
 composition.Size=UDim2.fromScale(mobile and (landscape and .40 or .39) or (landscape and (compact and .43 or .32) or .86),landscape and .58 or .45)
 if experienceChapter==1 then
  title.Position=UDim2.new(0,0,0,18);title.Size=UDim2.new(1,0,0,48)
  titleFallback.Position=UDim2.new(0,0,0,18);titleFallback.Size=UDim2.new(1,0,0,48)
  chapterOneTitle.Position=UDim2.new(0,0,0,68);chapterOneTitle.Size=UDim2.new(1,0,0,27);chapterOneTitle.TextSize=mobile and 18 or 23
  chapterOneDetail.Position=UDim2.new(0,0,0,98);chapterOneDetail.Size=UDim2.new(1,0,0,34);chapterOneDetail.TextSize=mobile and 10 or 12
  local menuTop=compact and 136 or 144
  nav.Position=UDim2.new(0,0,0,menuTop);nav.Size=UDim2.new(1,0,1,-menuTop)
 else
  title.Size=UDim2.fromOffset(mobile and 52 or 60,mobile and 52 or 60)
  titleFallback.Size=UDim2.new(1,0,0,53)
  nav.Position=UDim2.new(0,0,0,compact and 65 or 88);nav.Size=UDim2.new(1,0,1,-(compact and 65 or 88))
 end
 if mobile then
  news.AnchorPoint=Vector2.new(1,0)
  news.Position=UDim2.fromScale(.97,landscape and .06 or .52)
  news.Size=UDim2.fromScale(landscape and .43 or .52,landscape and .86 or .40)
  chapterTwo.Position=UDim2.fromScale(.97,landscape and .12 or .51)
  chapterTwo.Size=UDim2.fromScale(landscape and .45 or .52,landscape and .73 or .41)
 else
  news.AnchorPoint=landscape and Vector2.new(1,0) or Vector2.new(0,0)
  news.Position=landscape and UDim2.fromScale(.96,.15) or UDim2.fromScale(.065,.52)
  news.Size=landscape and UDim2.fromScale(compact and .42 or .40,.63) or UDim2.fromScale(.83,.45)
  chapterTwo.Position=landscape and UDim2.fromScale(.96,.16) or UDim2.fromScale(.065,.55)
  chapterTwo.Size=landscape and UDim2.fromScale(compact and .43 or .39,.62) or UDim2.fromScale(.83,.38)
 end
 heading.TextSize=mobile and 10 or 12
 motdText.TextSize=mobile and 10 or 12
 chapterTitle.TextSize=mobile and 23 or 31
 chapterDetail.TextSize=mobile and 12 or 15
 chapterUnavailable.TextSize=mobile and 10 or 12
 preview.Position=UDim2.new(0,0,0,55)
 local artHeight=math.min(news.AbsoluteSize.X*9/16,math.max(94,news.AbsoluteSize.Y-88))
 preview.Size=UDim2.new(1,0,0,artHeight)
 footer.Position=UDim2.new(0,0,1,-20)
end
layout()
bg:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
composition.Visible=true
news.Visible=experienceChapter==1
chapterTwo.Visible=experienceChapter==2
local startLabel=UI.Label(bg,'INICIANDO...',55)
startLabel.Name='StartingMessage'
startLabel.AnchorPoint=Vector2.new(.5,.5)
startLabel.Position=UDim2.fromScale(.73,.54)
startLabel.Size=UDim2.fromScale(.38,.12)
startLabel.Font=Enum.Font.Oswald;startLabel.TextScaled=true
startLabel.TextXAlignment=Enum.TextXAlignment.Center
startLabel.Visible=false
make('UITextSizeConstraint',{MinTextSize=16,MaxTextSize=38},startLabel)
startLabel.ZIndex=22
local transitionArt=make('ImageLabel',{
 Name='ChapterTwoTransition',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
 Image='rbxassetid://__CHAPTER_TWO_ART_ASSET_ID__',ScaleType=Enum.ScaleType.Crop,
 Visible=false,ZIndex=20
},bg)
local transitionShade=make('Frame',{
 Name='ChapterTwoTransitionShade',Size=UDim2.fromScale(1,1),
 BackgroundColor3=Color3.fromRGB(3,8,7),BackgroundTransparency=.40,
 BorderSizePixel=0,Visible=false,ZIndex=21
},bg)
local transitionHeadline=make('TextLabel',{
 Name='TransitionHeadline',Position=UDim2.new(.065,0,1,-129),
 Size=UDim2.new(.82,0,0,47),BackgroundTransparency=1,
 Text='ENTRANDO NO EPISÓDIO 2',Font=Enum.Font.Oswald,TextSize=32,
 TextColor3=Color3.fromRGB(246,239,213),TextXAlignment=Enum.TextXAlignment.Left,
 Visible=false,ZIndex=23
},bg)
local transitionDetail=make('TextLabel',{
 Name='TransitionDetail',Position=UDim2.new(.065,0,1,-80),
 Size=UDim2.new(.78,0,0,25),BackgroundTransparency=1,
 Text='A ESTUFA AINDA ESTÁ VIVA.',Font=Enum.Font.RobotoCondensed,TextSize=16,
 TextColor3=Color3.fromRGB(213,222,210),TextXAlignment=Enum.TextXAlignment.Left,
 Visible=false,ZIndex=23
},bg)
local transitionTrack=make('Frame',{
 Name='TransitionProgressTrack',Position=UDim2.new(.065,0,1,-38),
 Size=UDim2.new(.70,0,0,3),BackgroundColor3=Color3.fromRGB(183,194,173),
 BackgroundTransparency=.55,BorderSizePixel=0,Visible=false,ZIndex=23
},bg)
local transitionProgress=make('Frame',{
 Name='TransitionProgress',Size=UDim2.new(.26,0,1,0),
 BackgroundColor3=Color3.fromRGB(241,223,165),BorderSizePixel=0,ZIndex=24
},transitionTrack)
local transitionTween
local starting=false
local navButtons={}
local activeNav=1
local backButton
local busy=false
local function startPresentation(action)
 starting=true
 p:SetAttribute('MenuCameraMode','starting')
 composition.Visible=false
 news.Visible=false
 chapterTwo.Visible=false

 local isChapterHop=action=='chapterOne' or action=='chapterTwo'
 local showArtwork=experienceChapter==2 or action=='chapterTwo'
 transitionArt.Visible=showArtwork
 transitionArt.ImageTransparency=showArtwork and 1 or 0
 transitionShade.Visible=showArtwork
 transitionHeadline.Visible=showArtwork
 transitionDetail.Visible=showArtwork
 transitionTrack.Visible=showArtwork
 if showArtwork then
  transitionProgress.BackgroundColor3=Color3.fromRGB(241,223,165);transitionShade.BackgroundColor3=Color3.fromRGB(3,8,7)
  transitionHeadline.Text=action=='chapterOne' and 'VOLTANDO AO ARQUIVO' or (isChapterHop and 'ENTRANDO NO EPISÓDIO 2' or 'AQUELE QUE NÃO ENCONTRA')
  transitionDetail.Text=action=='chapterOne' and 'RETORNANDO AO EPISÓDIO 1…' or (isChapterHop and 'A ESTUFA AINDA ESTÁ VIVA.' or 'RECUPERE AS MEMÓRIAS. ENCONTRE A SAÍDA.')
  if transitionTween then transitionTween:Cancel() end
  transitionProgress.Position=UDim2.new(0,0,0,0)
  transitionTween=Tween:Create(transitionProgress,TweenInfo.new(1.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Position=UDim2.new(.74,0,0,0)})
  transitionTween:Play()
  Tween:Create(transitionArt,TweenInfo.new(.45,Enum.EasingStyle.Quad),{ImageTransparency=0}):Play()
  startLabel.Visible=false
 elseif experienceChapter==1 then
  transitionArt.Visible=false;transitionShade.BackgroundColor3=Color3.fromRGB(7,5,6)
  transitionShade.BackgroundTransparency=1;transitionShade.Visible=true
  transitionHeadline.Text='EPISÓDIO 1 · DEAD SIGNAL';transitionDetail.Text='SINTONIZANDO O SINAL…'
  transitionHeadline.TextTransparency=1;transitionDetail.TextTransparency=1
  transitionHeadline.Visible=true;transitionDetail.Visible=true
  transitionTrack.BackgroundTransparency=1;transitionTrack.Visible=true
  transitionProgress.BackgroundColor3=Color3.fromRGB(190,54,57)
  if transitionTween then transitionTween:Cancel() end
  transitionProgress.Position=UDim2.new(0,0,0,0)
  transitionTween=Tween:Create(transitionProgress,TweenInfo.new(1.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Position=UDim2.new(.74,0,0,0)})
  transitionTween:Play()
  Tween:Create(transitionShade,TweenInfo.new(.35,Enum.EasingStyle.Quad),{BackgroundTransparency=.14}):Play()
  Tween:Create(transitionHeadline,TweenInfo.new(.32),{TextTransparency=0}):Play()
  Tween:Create(transitionDetail,TweenInfo.new(.42),{TextTransparency=0}):Play()
  Tween:Create(transitionTrack,TweenInfo.new(.35),{BackgroundTransparency=.55}):Play()
  startLabel.Visible=false
 else
  transitionArt.Visible=false;transitionShade.Visible=false
  transitionHeadline.Visible=false;transitionDetail.Visible=false;transitionTrack.Visible=false
  startLabel.Text='INICIANDO...';startLabel.Visible=true
 end
end
local function restorePresentation()
 if not starting then return end
 starting=false
 p:SetAttribute('MenuCameraMode','wide')
 startLabel.Visible=false
 transitionArt.Visible=false;transitionShade.Visible=false
 transitionHeadline.Visible=false;transitionDetail.Visible=false;transitionTrack.Visible=false
 if transitionTween then transitionTween:Cancel();transitionTween=nil end
 transitionShade.BackgroundColor3=Color3.fromRGB(3,8,7);transitionShade.BackgroundTransparency=.40
 transitionHeadline.TextTransparency=0;transitionDetail.TextTransparency=0
 transitionTrack.BackgroundTransparency=.55;transitionProgress.BackgroundColor3=Color3.fromRGB(241,223,165)

 composition.Visible=not p:GetAttribute('InterfaceOpen')
 news.Visible=not p:GetAttribute('InterfaceOpen') and selectedChapter==1
 chapterTwo.Visible=not p:GetAttribute('InterfaceOpen') and selectedChapter==2
end
p:GetAttributeChangedSignal('InterfaceOpen'):Connect(function()
 local visible=not starting and not p:GetAttribute('InterfaceOpen')
 composition.Visible=visible
 news.Visible=visible and selectedChapter==1
 chapterTwo.Visible=visible and selectedChapter==2
end)
local function request(action,value)
 if busy then return end
 if action=='solo' then value={chapter=selectedChapter}
 elseif action=='state' then value={chapter=selectedChapter} end
 busy=true
 local launching=action=='solo' or action=='start' or action=='chapterTwo' or action=='chapterOne'
 local target=status
 if launching then
  local saved,err=UI.Save()
  if not saved then target.Text=err;busy=false;return end
  startPresentation(action)
  -- Give only the initiating client time to see the singularity burst before teleport.
  task.wait(1.35)
 else target.Text='Aguarde…' end
 local ok,result=pcall(function() return remote:InvokeServer(action,value) end)
 busy=false
 if not ok or type(result)~='table' then
  restorePresentation();target.Text='Falha de conexão. Tente novamente.';return
 end
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
end
-- Reference-style text-only actions, red selection marker and subtle easing.
-- Buttons retain generous transparent tap zones for iPhone touch.
local function selectNavigation(index)
 if #navButtons==0 then return end
 index=(index-1)%#navButtons+1
 for _=1,#navButtons do
  if navButtons[index].button.Visible then break end
  index=index%#navButtons+1
 end
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
local function layoutNavigation()
 local row=0
 for _,item in ipairs(navButtons) do
  if item.button.Visible then
   item.button.Position=UDim2.new(0,0,0,row*42)
   row+=1
  end
 end
end
local function moveNavigation(direction)
 for step=1,#navButtons do
  local index=(activeNav-1+direction*step)%#navButtons+1
  if navButtons[index].button.Visible then selectNavigation(index);return end
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
preview.Activated:Connect(function() request('chapterTwo') end)
backButton=addNavigation('VOLTAR AO EPISÓDIO 1',function() request('chapterOne') end)
addNavigation('JOGAR (SOLO)',function() request('solo') end)
addNavigation('CONFIGURAÇÕES',UI.OpenSettings)
backButton.Visible=experienceChapter==2
layoutNavigation()
selectNavigation(experienceChapter==2 and 2 or 1)
UIS.InputBegan:Connect(function(input,processed)
 if processed or starting or p:GetAttribute('InterfaceOpen') then return end
 if input.KeyCode==Enum.KeyCode.Up or input.KeyCode==Enum.KeyCode.DPadUp then
  moveNavigation(-1)
 elseif input.KeyCode==Enum.KeyCode.Down or input.KeyCode==Enum.KeyCode.DPadDown then
  moveNavigation(1)
 elseif input.KeyCode==Enum.KeyCode.Return or input.KeyCode==Enum.KeyCode.ButtonA then
  navButtons[activeNav].action()
 end
end)
-- Do not preload the entire world or rely on RequestQueueSize. Preload the
-- source black-hole meshes/textures and the existing menu audio only.
local assetsDone=false
local assetsFailed=0
task.spawn(function()
 local preloads={}
 local model=experienceChapter==1 and RS:WaitForChild('SkyBlackHoleTemplate',12) or nil
 if model then table.insert(preloads,model) end
 -- Load the generated Chapter 2 artwork before revealing the menu.
 table.insert(preloads,preview)
 table.insert(preloads,hero)
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
 if not preview.IsLoaded then warn('[MenuLoad] Chapter 2 artwork did not load; the card remains available') end
 assetsDone=true
end)
task.spawn(function()
 -- Wait for the real first-frame black-hole and effects, and for essential
 -- resource fetches. Never wait forever for a blocked third-party sound.
 local started=os.clock()
 local complete=false
 while gui.Parent and os.clock()-started<22 do
  local sceneReady=experienceChapter==2 and hero.IsLoaded or p:GetAttribute('MenuBlackHoleReady')==true
  local effectsReady=experienceChapter==2 or p:GetAttribute('MenuEffectsReady')==true
  local avatarReady=experienceChapter==2 or p:GetAttribute('MenuAvatarReady')==true
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
  Tween:Create(loadingTitle,TweenInfo.new(.5),{TextTransparency=1}):Play()
  Tween:Create(loadingHero,TweenInfo.new(.5),{ImageTransparency=1}):Play()
  Tween:Create(loadingVignette,TweenInfo.new(.5),{BackgroundTransparency=1}):Play()
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
 p:SetAttribute('MenuReady',true)
 task.spawn(function() request('state') end)
end)
task.spawn(function() UI.Load() end)
RS:WaitForChild('SessionNotice').OnClientEvent:Connect(function(message)
 busy=false
 restorePresentation()
 status.Text=message

end)
