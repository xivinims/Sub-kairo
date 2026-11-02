local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local Lighting=game:GetService('Lighting')
local SoundService=game:GetService('SoundService')
local StarterGui=game:GetService('StarterGui')
local player=Players.LocalPlayer
local Shared=RS:WaitForChild('WaterRPG')
local Config=require(Shared.Config)
local MenuScene=require(Shared.MenuScene)
local Net=Shared:WaitForChild('Action')
local Feedback=Shared:WaitForChild('Feedback')
local settings=table.clone(Config.Defaults)
settings.HighQuality=not UIS.TouchEnabled
local C={white=Color3.fromRGB(241,245,246),edge=Color3.fromRGB(165,183,201),glass=Color3.fromRGB(12,22,42),pink=Color3.fromRGB(255,32,162),muted=Color3.fromRGB(172,185,196),gold=Color3.fromRGB(220,199,144)}
local gui=Instance.new('ScreenGui');gui.Name='WaterCastleInterface';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=10;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=player:WaitForChild('PlayerGui')
local function make(class,parent,props)
 local x=Instance.new(class);for k,v in pairs(props or {}) do x[k]=v end;x.Parent=parent;return x
end
local function corner(x,r) make('UICorner',x,{CornerRadius=UDim.new(0,r or 12)}) end
local function stroke(x,color,trans) return make('UIStroke',x,{Color=color or C.edge,Transparency=trans or .4,Thickness=1}) end
local function text(parent,value,size,pos,fontSize,bold)
 return make('TextLabel',parent,{Text=value,Size=size,Position=pos,BackgroundTransparency=1,Font=bold and Enum.Font.GothamBold or Enum.Font.SourceSansLight,TextSize=fontSize or 22,TextColor3=C.white,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,RichText=true})
end
local function frame(parent,size,pos,color,trans)
 return make('Frame',parent,{Size=size,Position=pos,BackgroundColor3=color or C.glass,BackgroundTransparency=trans or 0,BorderSizePixel=0})
end
local function button(parent,value,size,pos,callback)
 local b=make('TextButton',parent,{Text=value,Size=size,Position=pos,BackgroundColor3=Color3.fromRGB(3,8,16),BackgroundTransparency=.25,TextColor3=C.white,Font=Enum.Font.SourceSansLight,TextSize=23,BorderSizePixel=0,AutoButtonColor=false,RichText=true})
 b.Activated:Connect(callback)
 b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.16),{BackgroundTransparency=.08}):Play() end)
 b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.2),{BackgroundTransparency=.25}):Play() end)
 return b
end
local function icon(parent,kind)
 local host=frame(parent,UDim2.fromOffset(56,56),UDim2.fromOffset(0,0),C.white,1)
 local function bar(size,pos,rotation)
  local b=frame(host,size,pos,C.white,0);b.Rotation=rotation or 0;return b
 end
 if kind=='Play' then
  text(host,'▶',UDim2.fromScale(1,1),UDim2.fromScale(0,0),40,true).TextXAlignment=Enum.TextXAlignment.Center
 elseif kind=='Settings' then
  for i=0,7 do
   local b=bar(UDim2.fromOffset(12,32),UDim2.fromOffset(22,12),i*45);corner(b,2)
  end
  local circle=bar(UDim2.fromOffset(31,31),UDim2.fromOffset(12.5,12.5));corner(circle,20)
  local hole=frame(host,UDim2.fromOffset(11,11),UDim2.fromOffset(22.5,22.5),C.glass,0);corner(hole,10)
 elseif kind=='Credits' then
  for i=0,2 do local dot=bar(UDim2.fromOffset(5,5),UDim2.fromOffset(9,12+i*12));corner(dot,3);bar(UDim2.fromOffset(27,3),UDim2.fromOffset(21,13+i*12)) end
 elseif kind=='Log' then
  local sheet=frame(host,UDim2.fromOffset(31,38),UDim2.fromOffset(13,11),C.white,1);corner(sheet,2);stroke(sheet,C.white,0)
  local clip=bar(UDim2.fromOffset(17,7),UDim2.fromOffset(20,7));corner(clip,3)
 end
 return host
end
local soundGroup=make('SoundGroup',SoundService,{Name='WaterRPGClient',Volume=.5})
local function soundRoute(x) if x:IsA('Sound') then x.SoundGroup=soundGroup end end
for _,x in ipairs(SoundService:GetDescendants()) do soundRoute(x) end
workspace.DescendantAdded:Connect(soundRoute)
local blur=make('BlurEffect',Lighting,{Name='RPGMenuBlur',Size=0,Enabled=true})
local dof=make('DepthOfFieldEffect',Lighting,{Name='RPGMenuDepth',Enabled=false,FarIntensity=.22,NearIntensity=.08,FocusDistance=220,InFocusRadius=100})
local menuActive=true
local modalName=nil
local displayedSection='Settings'
local sceneName='Main'
local sceneRevision=0
local menuCameraValue=make('CFrameValue',nil,{Value=MenuScene.route(Config.MenuCamera,'Main')})
local cameraTween
local closeModal
local function travel(section)
 sceneRevision+=1;sceneName=section
 if cameraTween then cameraTween:Cancel() end
 local target=MenuScene.route(Config.MenuCamera,section)
 cameraTween=Tween:Create(menuCameraValue,TweenInfo.new(MenuScene.Duration,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{Value=target})
 cameraTween:Play()
 return sceneRevision
end
local transitionActive=false
local dying=false
local pointer=Vector2.zero
local tilt=Vector2.zero
local menuAt=os.clock()
local camera=workspace.CurrentCamera
local scenery=make('Model',workspace,{Name='LocalMenuPresentation'})
local function menuPart(name,size)
 local p=make('Part',scenery,{Name=name,Size=size,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1})
 return p
end
local menuPlane=menuPart('MenuPlane',Vector3.new(12.5,10,.02))
local surface=make('SurfaceGui',player.PlayerGui,{Name='WaterMenu3D',Adornee=menuPlane,Face=Enum.NormalId.Back,SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,CanvasSize=Vector2.new(1000,800),AlwaysOnTop=true,Active=true,LightInfluence=0,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
menuPlane.CanQuery=true
local content=make('CanvasGroup',surface,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,GroupTransparency=0})
local glow=text(content,Config.Title,UDim2.fromOffset(850,92),UDim2.fromOffset(88,70),67,true);glow.TextTransparency=.68;glow.TextStrokeTransparency=.6
local title=text(content,Config.Title,UDim2.fromOffset(850,92),UDim2.fromOffset(85,66),67,true)
local menuCaption=text(content,'MENU',UDim2.fromOffset(680,45),UDim2.fromOffset(110,165),28,true);menuCaption.TextXAlignment=Enum.TextXAlignment.Center
local shapes={}
local rows={}
local showModal,beginPlay
for i,entry in ipairs({{'Play','Play'},{'Settings','Settings'},{'Credits','Credits'},{'Update Log','Log'}}) do
 local y=235+(i-1)*110
 local row=frame(content,UDim2.fromOffset(790,88),UDim2.fromOffset(105,y),C.glass,1)
 local square=frame(row,UDim2.fromOffset(84,84),UDim2.new(),C.glass,.65);stroke(square,C.white,.2)
 local ic=icon(square,entry[2]);ic.Position=UDim2.fromOffset(14,12)
 local b=button(row,'<i>'..entry[1]..'</i>',UDim2.fromOffset(690,84),UDim2.fromOffset(92,0),function()
  if transitionActive then return end
  if entry[2]=='Play' then beginPlay() else showModal(entry[2]) end
 end)
 b.TextSize=45;b.BackgroundTransparency=1;rows[i]={frame=row,button=b,base=y}
 local line=frame(row,UDim2.fromOffset(766,1),UDim2.fromOffset(0,85),C.white,.55)
 local body=menuPart('Ribbon'..i,Vector3.new(8.1,1.05,.035));body.Transparency=.52;body.Color=C.glass;body.Material=Enum.Material.Glass
 local tip=make('WedgePart',scenery,{Name='RibbonTip'..i,Size=Vector3.new(.035,1.05,.75),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=.52,Color=C.glass,Material=Enum.Material.Glass})
 shapes[i]={body=body,tip=tip,y=y}
 b.MouseEnter:Connect(function() Tween:Create(row,TweenInfo.new(.2),{Position=UDim2.fromOffset(122,y)}):Play() end)
 b.MouseLeave:Connect(function() Tween:Create(row,TweenInfo.new(.2),{Position=UDim2.fromOffset(105,y)}):Play() end)
end
local modalPlane=menuPart('SectionPlane',Vector3.new(12,9.6,.035))
modalPlane.CanQuery=false
local modalSurface=make('SurfaceGui',player.PlayerGui,{Name='WaterMenuSection3D',Adornee=modalPlane,Face=Enum.NormalId.Back,SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,CanvasSize=Vector2.new(500,400),AlwaysOnTop=true,Active=true,LightInfluence=0,Enabled=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local modal=make('CanvasGroup',modalSurface,{Size=UDim2.fromScale(1,1),Position=UDim2.new(),BackgroundColor3=C.glass,BackgroundTransparency=.28,BorderSizePixel=0,GroupTransparency=1});corner(modal,14);stroke(modal,C.edge,.25);modal.Visible=false
local modalScale=make('UIScale',modal,{Scale=1})
local modalHeader=text(modal,'',UDim2.new(1,-65,0,36),UDim2.fromOffset(14,9),28);modalHeader.Font=Enum.Font.SourceSansLight
frame(modal,UDim2.new(1,-30,0,1),UDim2.fromOffset(15,48),C.white,.1)
local closeGlow=frame(modal,UDim2.fromOffset(44,44),UDim2.new(1,-50,0,-1),C.pink,.75);corner(closeGlow,30)
local close=button(modal,'×',UDim2.fromOffset(30,30),UDim2.new(1,-43,0,6),function() closeModal() end);close.TextSize=34;close.BackgroundColor3=C.pink;close.BackgroundTransparency=.15;corner(close,20);stroke(close,C.white,.15)
local panelBody=make('ScrollingFrame',modal,{Size=UDim2.new(1,-28,1,-66),Position=UDim2.fromOffset(14,58),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.edge,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
local function clearBody() for _,x in ipairs(panelBody:GetChildren()) do x:Destroy() end end
local function applySettings()
 Lighting.GlobalShadows=settings.HighQuality
 dof.Enabled=menuActive and settings.DepthOfField
 soundGroup.Volume=settings.MusicVolume
 for _,x in ipairs(Lighting:GetChildren()) do
  if x~=dof and x~=blur and (x:IsA('SunRaysEffect') or x:IsA('BloomEffect')) then x.Enabled=settings.HighQuality end
 end
end
local function settingRow(label,key,y)
 local row=frame(panelBody,UDim2.new(1,-8,0,34),UDim2.fromOffset(4,y),Color3.new(0,0,0),.22);corner(row,18);stroke(row,C.edge,.4)
 text(row,label,UDim2.new(1,-90,1,0),UDim2.fromOffset(13,0),17)
 if key=='MusicVolume' then
  local amount=text(row,tostring(math.floor(settings[key]*100)),UDim2.fromOffset(32,30),UDim2.new(1,-66,0,2),17);amount.TextXAlignment=Enum.TextXAlignment.Center
  for _,v in ipairs({{-1,'‹',-92},{1,'›',-31}}) do
   local b=button(row,v[2],UDim2.fromOffset(25,30),UDim2.new(1,v[3],0,2),function() settings[key]=math.clamp(settings[key]+v[1]*.1,0,1);amount.Text=tostring(math.floor(settings[key]*100+.5));applySettings() end);b.TextSize=31;b.BackgroundTransparency=1
  end
 else
  local toggle=button(row,'',UDim2.fromOffset(46,25),UDim2.new(1,-57,0,4),function() end);corner(toggle,15);stroke(toggle,C.white,.45)
  local knob=frame(toggle,UDim2.fromOffset(18,18),UDim2.fromOffset(settings[key] and 25 or 3,3.5),C.white,0);corner(knob,20)
  local function paint() Tween:Create(knob,TweenInfo.new(.18),{Position=UDim2.fromOffset(settings[key] and 25 or 3,3.5),BackgroundTransparency=settings[key] and 0 or .45}):Play() end
  toggle.Activated:Connect(function() settings[key]=not settings[key];paint();applySettings() end);paint()
 end
end
closeModal=function()
 if not modal.Visible then return end
 modalName=nil
 local revision=menuActive and travel('Main') or (sceneRevision+1)
 if not menuActive then sceneRevision=revision end
 modalPlane.CanQuery=false
 Tween:Create(modal,TweenInfo.new(.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.fromScale(-1.1,0),GroupTransparency=1}):Play()
 task.delay(.31,function() if sceneRevision==revision then modal.Visible=false;modalSurface.Enabled=false end end)
 if menuActive then
  surface.Enabled=true;content.Visible=true;content.GroupTransparency=1
  for i,row in ipairs(rows) do
   row.frame.Position=UDim2.fromOffset(950,row.base)
   task.delay(.25+i*.045,function()
    if sceneRevision==revision then Tween:Create(row.frame,TweenInfo.new(.5,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(105,row.base)}):Play() end
   end)
  end
  task.delay(.3,function() if sceneRevision==revision then Tween:Create(content,TweenInfo.new(.35),{GroupTransparency=0}):Play();menuPlane.CanQuery=true end end)
 end
end
showModal=function(kind)
 modalName=kind;displayedSection=kind;clearBody();modal.Visible=true;modalSurface.Enabled=true;modalPlane.CanQuery=false
 modal.Position=UDim2.fromScale(1.15,0);modal.GroupTransparency=1
 local revision=menuActive and travel(kind) or (sceneRevision+1)
 if not menuActive then sceneRevision=revision end
 menuPlane.CanQuery=false
 if menuActive then
  Tween:Create(content,TweenInfo.new(.28),{GroupTransparency=1}):Play()
  for i,row in ipairs(rows) do task.delay(i*.035,function()
   if sceneRevision==revision then Tween:Create(row.frame,TweenInfo.new(.35,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.fromOffset(-950,row.base)}):Play() end
  end) end
  task.delay(.5,function() if sceneRevision==revision then surface.Enabled=false end end)
 end
 task.delay(menuActive and .45 or 0,function()
  if sceneRevision~=revision then return end
  Tween:Create(modal,TweenInfo.new(.52,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(),GroupTransparency=0}):Play()
  modalPlane.CanQuery=true
 end)
 if kind=='Settings' then
  modalHeader.Text='<i>SETTINGS</i>'
  local names={{'Camera Banking','CameraBanking'},{'Camera Tilt','CameraTilt'},{'High Quality Graphics','HighQuality'},{'Music Volume','MusicVolume'},{'Neon Glow Pulse','GlowPulse'},{'Panel Bob','PanelBob'},{'Realistic DOF','DepthOfField'}}
  for i,v in ipairs(names) do settingRow(v[1],v[2],(i-1)*43) end
 elseif kind=='Credits' then
  modalHeader.Text='<i>CREDITS</i>'
  local bar=frame(panelBody,UDim2.new(1,-8,0,42),UDim2.fromOffset(4,0),Color3.new(0,0,0),.1);corner(bar,22);stroke(bar,C.edge,.5)
  local tx=text(bar,'<i>Aurivane Works</i>',UDim2.fromScale(1,1),UDim2.new(),25);tx.TextXAlignment=Enum.TextXAlignment.Center
  text(panelBody,'Cenário e roupas: arquivo water castle enviado por você.\n\nInterface e sistemas adaptados às referências enviadas.\n\nPersonagens mantêm as roupas e peças dos modelos originais.',UDim2.new(1,-20,0,155),UDim2.fromOffset(10,65),19)
 else
  modalHeader.Text='<i>UPDATE LOG</i>'
  local area=frame(panelBody,UDim2.new(1,-8,0,265),UDim2.fromOffset(4,0),C.glass,.2);corner(area,12);stroke(area,C.edge,.6)
  local h=text(area,'<i>Update Log</i>',UDim2.new(1,-30,0,50),UDim2.fromOffset(15,0),42);h.TextXAlignment=Enum.TextXAlignment.Center
  text(area,'<i>v0.1 — Water Castle RPG</i>\n\n• Cenário e terreno do arquivo original\n• Moradores com roupas preservadas\n• Conversas, comércio e uma entrega inicial\n• Menu com câmera dinâmica e painéis animados\n• Tela de morte e retorno ao menu\n• Controles de toque e configurações gráficas',UDim2.new(1,-32,0,205),UDim2.fromOffset(16,55),21)
 end
end
local fade=frame(gui,UDim2.fromScale(1,1),UDim2.new(),Color3.fromRGB(3,7,10),1);fade.ZIndex=70;fade.Visible=false
local fadeText=text(fade,'',UDim2.new(1,-40,0,65),UDim2.new(0,20,.5,-32),22);fadeText.TextXAlignment=Enum.TextXAlignment.Center;fadeText.ZIndex=71
local loadingBar=frame(fade,UDim2.fromOffset(240,2),UDim2.new(.5,-120,.5,45),C.white,.8);loadingBar.ZIndex=71
local barFill=frame(loadingBar,UDim2.fromScale(.05,1),UDim2.new(),C.white,0);barFill.ZIndex=72
local function transition(message)
 transitionActive=true;sceneRevision+=1;modal.Visible=false;modalSurface.Enabled=false;modalPlane.CanQuery=false;fade.Visible=true;fadeText.Text=message;fade.BackgroundTransparency=1
 Tween:Create(fade,TweenInfo.new(.35),{BackgroundTransparency=0}):Play()
end
local function finishFade()
 transitionActive=false
 Tween:Create(fade,TweenInfo.new(.55),{BackgroundTransparency=1}):Play();Tween:Create(fadeText,TweenInfo.new(.4),{TextTransparency=1}):Play()
 task.delay(.6,function() if not transitionActive then fade.Visible=false;fadeText.TextTransparency=0 end end)
end
beginPlay=function()
 if not player:GetAttribute('ProfileReady') then return end
 if transitionActive then return end
 transitionActive=true;menuPlane.CanQuery=false;sceneRevision+=1
 if cameraTween then cameraTween:Cancel() end
 local start=MenuScene.route(Config.MenuCamera,'Main')
 cameraTween=Tween:Create(menuCameraValue,TweenInfo.new(.65,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{Value=start*CFrame.new(0,.25,-4)*CFrame.Angles(0,math.rad(-7),0)})
 cameraTween:Play()
 Tween:Create(content,TweenInfo.new(.38),{GroupTransparency=1}):Play()
 for i,row in ipairs(rows) do task.delay(i*.035,function() Tween:Create(row.frame,TweenInfo.new(.3),{Position=UDim2.fromOffset(-950,row.base)}):Play() end) end
 task.delay(.45,function() transition('Preparando a estrada…');Net:FireServer('Play') end)
end
local death=frame(gui,UDim2.fromScale(1,1),UDim2.new(),Color3.fromRGB(3,10,12),0);death.ZIndex=50;death.Visible=false
make('UIGradient',death,{Color=ColorSequence.new(Color3.fromRGB(18,33,36),Color3.fromRGB(0,0,0)),Rotation=0})
local deathTitle=text(death,'YOU DIED',UDim2.new(1,0,0,60),UDim2.new(0,0,.35,-30),46,true);deathTitle.TextXAlignment=Enum.TextXAlignment.Center;deathTitle.ZIndex=51
local deathSub=text(death,'A jornada não termina aqui.',UDim2.new(1,0,0,30),UDim2.new(0,0,.35,45),18);deathSub.TextXAlignment=Enum.TextXAlignment.Center;deathSub.TextColor3=C.muted;deathSub.ZIndex=51
local line=frame(death,UDim2.fromOffset(260,1),UDim2.new(.5,-130,.35,100),C.edge,.7);line.ZIndex=51
for _,e in ipairs({{'RESPAWN',-150,'Respawn'},{'RETURN TO MENU',10,'Menu'}}) do
 local b=button(death,e[1],UDim2.fromOffset(140,36),UDim2.new(.5,e[2],.35,145),function() death.Visible=false;dying=false;transition('Preparando…');Net:FireServer(e[3]) end);b.BackgroundTransparency=1;b.TextSize=19;b.ZIndex=51
 local ln=frame(b,UDim2.new(1,-20,0,1),UDim2.new(0,10,1,0),C.white,.5);ln.ZIndex=51
end
local hud=frame(gui,UDim2.fromScale(1,1),UDim2.new(),C.glass,1);hud.Visible=false
local status=frame(hud,UDim2.fromOffset(245,76),UDim2.fromOffset(18,68),C.glass,.25);corner(status,10);stroke(status,C.edge,.75)
local statusText=text(status,'',UDim2.new(1,-24,0,25),UDim2.fromOffset(12,8),18,true)
local healthTrack=frame(status,UDim2.new(1,-24,0,5),UDim2.fromOffset(12,42),C.white,.88);corner(healthTrack,3)
local healthFill=frame(healthTrack,UDim2.fromScale(1,1),UDim2.new(),Color3.fromRGB(155,194,174),0);corner(healthFill,3)
local money=text(status,'',UDim2.new(1,-24,0,22),UDim2.fromOffset(12,50),15)
local questBox=frame(hud,UDim2.fromOffset(280,78),UDim2.new(1,-296,0,68),C.glass,.3);corner(questBox,10);stroke(questBox,C.edge,.75)
local questText=text(questBox,'',UDim2.new(1,-24,1,-14),UDim2.fromOffset(12,7),18)
local notice=text(gui,'',UDim2.new(.8,0,0,58),UDim2.new(.1,0,.18,0),22,true);notice.TextXAlignment=Enum.TextXAlignment.Center;notice.TextStrokeTransparency=.5;notice.ZIndex=80
local noticeId=0
local function notify(value)
 noticeId+=1;local id=noticeId;notice.Text=value
 task.delay(5,function() if noticeId==id then notice.Text='' end end)
end
button(hud,'⚙',UDim2.fromOffset(40,40),UDim2.new(1,-56,0,15),function() showModal('Settings') end)
local dialogue=Shared.PlayerAssets.DialogueSkin:Clone();dialogue.Name='ResidentDialogue';dialogue.Size=UDim2.fromOffset(570,250);dialogue.Position=UDim2.new(.5,-285,1,-275);dialogue.Visible=false;dialogue.Parent=gui
for _,obj in ipairs(dialogue:GetDescendants()) do if obj:IsA('GuiObject') then obj.Visible=false end end
local dialogueScale=make('UIScale',dialogue,{Scale=1})
local speaker=text(dialogue,'',UDim2.new(1,-55,0,30),UDim2.fromOffset(20,12),22,true)
local speech=text(dialogue,'',UDim2.new(1,-40,0,77),UDim2.fromOffset(20,49),22)
local choices=frame(dialogue,UDim2.new(1,-40,0,105),UDim2.fromOffset(20,130),C.glass,1)
local activeDialogue
button(dialogue,'×',UDim2.fromOffset(30,30),UDim2.new(1,-42,0,10),function() activeDialogue=nil;dialogue.Visible=false;Net:FireServer('CloseDialogue') end)
local function showDialogue(d)
 activeDialogue=d;dialogue.Visible=true;speaker.Text=d.name..'  <font size="15">'..d.role..'</font>';speech.Text=d.text
 for _,x in ipairs(choices:GetChildren()) do x:Destroy() end
 for i,o in ipairs(d.options) do
  local b=button(choices,o.text,UDim2.new(1,0,0,29),UDim2.fromOffset(0,(i-1)*35),function()
   if activeDialogue then Net:FireServer('Answer',{token=activeDialogue.token,id=o.id}) end
  end);b.TextSize=18;corner(b,6)
 end
end
local missionMarker
local function refreshQuestMarker()
 if missionMarker then missionMarker:Destroy();missionMarker=nil end
 if player:GetAttribute('QuestStage')~=1 then return end
 local part=make('Part',workspace,{Name='LocalQuestTarget',Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Position=Vector3.new(1033.5,54,2004)})
 local bill=make('BillboardGui',part,{Size=UDim2.fromOffset(170,55),AlwaysOnTop=true,MaxDistance=3000})
 local label=text(bill,'BOTICÁRIA\nENCOMENDA',UDim2.fromScale(1,1),UDim2.new(),16,true);label.TextXAlignment=Enum.TextXAlignment.Center;label.TextColor3=C.gold;label.TextStrokeTransparency=.4
 missionMarker=part
end
player:GetAttributeChangedSignal('QuestStage'):Connect(refreshQuestMarker)
Feedback.OnClientEvent:Connect(function(kind,value)
 if kind=='Transition' then transition(value)
 elseif kind=='Started' then
  menuActive=false;surface.Enabled=false;menuPlane.CanQuery=false;modalSurface.Enabled=false;modalPlane.CanQuery=false;modal.Visible=false;dying=false;death.Visible=false;hud.Visible=true
  camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Custom
  local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then camera.CameraSubject=h end
  player.CameraMinZoomDistance=4;player.CameraMaxZoomDistance=22
  for _,v in ipairs(shapes) do v.body.Transparency=1;v.tip.Transparency=1 end
  dof.Enabled=false;Tween:Create(blur,TweenInfo.new(.6),{Size=0}):Play();finishFade();refreshQuestMarker()
  if not player:GetAttribute('PersistentProfile') then notify('Progresso temporário nesta sessão: o salvamento está indisponível.') end
 elseif kind=='Menu' then
  menuActive=true;menuAt=os.clock();dying=false;death.Visible=false;hud.Visible=false;dialogue.Visible=false;surface.Enabled=true;content.Visible=true;content.GroupTransparency=0;menuPlane.CanQuery=true;sceneName='Main';menuCameraValue.Value=MenuScene.route(Config.MenuCamera,'Main');for _,row in ipairs(rows) do row.frame.Position=UDim2.fromOffset(105,row.base) end;finishFade()
 elseif kind=='Died' then
  dying=true;death.Visible=true;hud.Visible=false;dialogue.Visible=false
 elseif kind=='Dialogue' then showDialogue(value)
 elseif kind=='CloseDialogue' then dialogue.Visible=false;activeDialogue=nil
 elseif kind=='Notice' then notify(value) end
end)
UIS.InputChanged:Connect(function(input,processed)
 if input.UserInputType==Enum.UserInputType.MouseMovement then
  local size=workspace.CurrentCamera.ViewportSize;local m=UIS:GetMouseLocation();pointer=Vector2.new(math.clamp(m.X/size.X*2-1,-1,1),math.clamp(m.Y/size.Y*2-1,-1,1))
 elseif input.UserInputType==Enum.UserInputType.Touch and not processed then
  local size=workspace.CurrentCamera.ViewportSize;pointer=Vector2.new(math.clamp(input.Position.X/size.X*2-1,-1,1),math.clamp(input.Position.Y/size.Y*2-1,-1,1))
 end
end)
UIS.TouchEnded:Connect(function() pointer=Vector2.zero end)
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.LeftShift then Net:FireServer('Sprint',true)
 elseif input.KeyCode==Enum.KeyCode.H then Net:FireServer('UsePotion')
 elseif input.KeyCode==Enum.KeyCode.M then if modal.Visible then closeModal() else showModal('Settings') end end
end)
UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.LeftShift then Net:FireServer('Sprint',false) end end)
local residentCache={}
local cacheAt=0
Run.RenderStepped:Connect(function(dt)
 camera=workspace.CurrentCamera
 local t=os.clock();local size=camera.ViewportSize
 modalScale.Scale=1
 local ds=math.min(1,(size.X-30)/570,(size.Y-30)/330);dialogueScale.Scale=ds;dialogue.Position=UDim2.new(.5,-285*ds,1,-265*ds)
 tilt=tilt:Lerp(settings.CameraTilt and pointer or Vector2.zero,math.min(1,dt*4))
 if menuActive then
  camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=58
  local base=menuCameraValue.Value
  local drift=CFrame.new(math.sin(t*.22)*.16,math.sin(t*.3)*.1,0)
  camera.CFrame=base*drift*CFrame.Angles(math.rad(-tilt.Y*1.2),math.rad(-tilt.X*2),settings.CameraBanking and math.rad(-tilt.X*.55) or 0)
  local _,mainAnchor=MenuScene.route(Config.MenuCamera,'Main')
  local bob=settings.PanelBob and math.sin(t*1.1)*.035 or 0
  local mainDistance=(camera.CFrame.Position-mainAnchor.Position).Magnitude
  -- Main size is based on its own camera, so it does not inflate while the camera travels away.
  local mainCamera=MenuScene.route(Config.MenuCamera,'Main')
  menuPlane.Size=MenuScene.panelSize(size,58,(mainCamera.Position-mainAnchor.Position).Magnitude,'Main')
  menuPlane.CFrame=mainAnchor*CFrame.new(0,bob,0)*CFrame.Angles(math.rad(-tilt.Y*.3),math.rad(tilt.X*.5),0)
  for i,v in ipairs(shapes) do
   local row=rows[i].frame
   local centerX=row.Position.X.Offset+92+345
   local centerY=row.Position.Y.Offset+42
   local x=(.5-centerX/1000)*menuPlane.Size.X
   local yy=(.5-centerY/800)*menuPlane.Size.Y
   v.body.Size=Vector3.new(menuPlane.Size.X*.69,menuPlane.Size.Y*.105,.035)
   v.body.CFrame=menuPlane.CFrame*CFrame.new(x,yy,.025)
   v.tip.Size=Vector3.new(.035,menuPlane.Size.Y*.105,menuPlane.Size.X*.06)
   v.tip.CFrame=menuPlane.CFrame*CFrame.new(x-menuPlane.Size.X*.375,yy,.025)*CFrame.Angles(0,math.rad(-90),0)
   local opacity=content.GroupTransparency
   v.body.Transparency=.52+.48*opacity;v.tip.Transparency=.52+.48*opacity
  end
  local focus=sceneName=='Main' and mainAnchor.Position or select(2,MenuScene.route(Config.MenuCamera,sceneName)).Position
  camera.Focus=CFrame.new(focus)
  dof.Enabled=settings.DepthOfField;dof.FocusDistance=(focus-camera.CFrame.Position).Magnitude;dof.InFocusRadius=6
  blur.Size=0
  glow.TextTransparency=settings.GlowPulse and (.72+math.sin(t*2)*.12) or .8
  closeGlow.BackgroundTransparency=settings.GlowPulse and (.7+math.sin(t*3)*.12) or .85
  rows[1].button.Text=player:GetAttribute('ProfileReady') and '<i>Play</i>' or '<i>Loading…</i>'
 else
  local desired=player:GetAttribute('BowAiming') and 48 or (70+(player:GetAttribute('Sprinting') and 5 or 0))
  camera.FieldOfView=camera.FieldOfView+(desired-camera.FieldOfView)*math.min(1,dt*5)
 end
 if modal.Visible then
  local anchor
  if menuActive then local _,plane=MenuScene.route(Config.MenuCamera,displayedSection);anchor=plane
  else anchor=camera.CFrame*CFrame.new(0,0,-13) end
  local distance=(camera.CFrame.Position-anchor.Position).Magnitude
  local targetCamera=menuActive and MenuScene.route(Config.MenuCamera,displayedSection) or camera.CFrame
  local designedDistance=(targetCamera.Position-anchor.Position).Magnitude
  modalPlane.Size=MenuScene.panelSize(size,camera.FieldOfView,designedDistance,'Section')
  modalPlane.CFrame=anchor*CFrame.new(0,settings.PanelBob and math.sin(t*1.2)*.025 or 0,0)*CFrame.Angles(math.rad(-tilt.Y*.3),math.rad(tilt.X*.4),0)
 end
 if transitionActive then barFill.Size=UDim2.fromScale(.15+((t*.2)% .75),1) end
 hud.Visible=not menuActive and not dying and not transitionActive
 questBox.Visible=size.X>600
 local stage=player:GetAttribute('QuestStage') or 0
 questText.Text=stage==0 and 'PRIMEIROS PASSOS\nConverse com Nasos, na estrada.' or (stage==1 and 'ENCOMENDA\nEntregue as ervas à boticária.' or 'EXPLORAÇÃO LIVRE\nConheça os moradores e a cidade.')
 statusText.Text='NÍVEL '..(player:GetAttribute('Level') or 1)..'  ·  '..(player.DisplayName)
 money.Text=(player:GetAttribute('Coins') or 20)..' moedas  ·  '..(player:GetAttribute('XP') or 0)..' XP'
 local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if h then healthFill.Size=UDim2.fromScale(math.clamp(h.Health/h.MaxHealth,0,1),1) end
 if t-cacheAt>2 then
  cacheAt=t;residentCache={};local folder=workspace:FindFirstChild('Residents')
  if folder then for _,npc in ipairs(folder:GetChildren()) do local root=npc:FindFirstChild('HumanoidRootPart');if root then table.insert(residentCache,{npc=npc,root=root,motors=npc:GetDescendants()}) end end end
 end
 for _,entry in ipairs(residentCache) do
  if entry.root.Parent and (entry.root.Position-camera.CFrame.Position).Magnitude<130 then
   local amount=math.min(entry.root.AssemblyLinearVelocity.Magnitude/7,1)
   local swing=math.sin(t*7)*.4*amount
   for _,m in ipairs(entry.motors) do
    if m:IsA('Motor6D') then
     local n=m.Name:lower()
     if n:find('shoulder') or n:find('hip') then m.Transform=CFrame.Angles((n:find('left') and 1 or -1)*swing,0,0)
     elseif n=='waist' then m.Transform=CFrame.Angles(math.sin(t*1.6)*.015,0,0) end
    end
   end
  end
 end
end)
applySettings()
transition('WATER CASTLE')
task.spawn(function()
 local untilAt=os.clock()+18
 repeat task.wait(.1) until (player:GetAttribute('ProfileReady') and Shared.State:GetAttribute('WorldReady')) or os.clock()>untilAt
 finishFade()
end)
