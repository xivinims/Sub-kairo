local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local menuGrade=Instance.new("ColorCorrectionEffect");menuGrade.Name="StillHereMenuFilmGrade";menuGrade.Brightness=-.035;menuGrade.Contrast=.18;menuGrade.Saturation=-.22;menuGrade.TintColor=Color3.fromRGB(222,228,221);menuGrade.Enabled=false;menuGrade.Parent=Lighting
local player=Players.LocalPlayer
local Config=require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Campaign=require(RS.Shared.Campaign)
local remotes=RS:WaitForChild("BrambleRemotes")
local action,update=remotes:WaitForChild("Action"),remotes:WaitForChild("Update")
local Hands=require(script.Parent.Hands)
local camera=workspace.CurrentCamera
local assets=RS:WaitForChild("BrambleAssets",30)
if assets then local deadline=os.clock()+30;while not assets:GetAttribute("Ready") and os.clock()<deadline do task.wait(.1) end end
local hands=Hands.new(camera)
local gui=Instance.new("ScreenGui");gui.Name="BramblesSprout";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Enabled=false;gui.Parent=player:WaitForChild("PlayerGui")
local root=Instance.new("Frame");root.Size=UDim2.fromOffset(1280,720);root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5);root.BackgroundTransparency=1;root.ZIndex=3;root.Parent=gui
local scale=Instance.new("UIScale");scale.Parent=root
local phoneLayout=false
local compactLayout=false
local mode="menu"
local menuActive=true
local subpageActive=false
local logo,heading,chapter,description,rule,controls,desktopMOTD,mobileMOTD,footer,hud
local optionsPanel,optionsTitle,optionsRows,optionsBack
local mobileHud,mobileObjectiveCard,mobileObjective,mobileStamina,mobilePrompt,mobileCrosshair,touchPad
local resizeOptions
local function resize()
 local size=camera.ViewportSize
 phoneLayout=UIS.TouchEnabled
 compactLayout=phoneLayout and size.Y>size.X
 if compactLayout then
  root.Size=UDim2.fromOffset(520,720)
  scale.Scale=math.min(size.X/520,size.Y/720)
  root.AnchorPoint=Vector2.new(0,.5);root.Position=UDim2.new(0,0,.5,0)
 else
  root.Size=UDim2.fromOffset(1280,720)
  scale.Scale=math.min(size.X/1280,size.Y/720)
  root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5)
 end
 if logo then logo.Position=UDim2.fromOffset(24,12);logo.Size=UDim2.fromOffset(220,150) end
 if heading then heading.Position=UDim2.fromOffset(55,45);heading.Size=UDim2.fromOffset(680,75) end
 if chapter then chapter.Position=UDim2.fromOffset(55,135);chapter.Size=UDim2.fromOffset(480,26) end
 if description then description.Position=UDim2.fromOffset(55,195);description.Size=UDim2.fromOffset(480,205) end
 if rule then rule.Position=UDim2.fromOffset(55,165);rule.Size=UDim2.fromOffset(460,1) end
 if controls then controls.Position=UDim2.fromOffset(55,if subpageActive then 425 else 178) end
 if optionsPanel then optionsPanel.Size=UDim2.fromOffset(if compactLayout then 430 else 520,720) end
 if optionsRows then optionsRows.Size=UDim2.fromOffset(if compactLayout then 385 else 448,490) end
 if desktopMOTD then desktopMOTD.Visible=menuActive and not subpageActive and not phoneLayout end
 if mobileMOTD then mobileMOTD.Visible=menuActive and not subpageActive and phoneLayout end
 if footer then footer.Position=UDim2.fromOffset(55,680) end
 if mobileHud then mobileHud.Visible=phoneLayout and mode=="playing" end
  if hud then hud.Visible=mode=="playing" and not phoneLayout end
 if mobileObjectiveCard then
  local w=math.clamp(math.floor(size.X*.6),205,360)
  mobileObjectiveCard.Size=UDim2.fromOffset(w,118)
  if mobileObjective then mobileObjective.Position=UDim2.fromOffset(10,8);mobileObjective.Size=UDim2.new(1,-20,1,-34) end
  if mobileStamina then mobileStamina.Position=UDim2.new(0,10,1,-24);mobileStamina.Size=UDim2.new(1,-20,0,18) end
 end
 if mobilePrompt then
  local w=math.clamp(size.X-48,180,420)
  mobilePrompt.Position=UDim2.new(.5,0,1,-88);mobilePrompt.Size=UDim2.fromOffset(w,48)
 end
 if touchPad then touchPad.Position=UDim2.new(1,-12,if size.Y<520 then .39 else .5,0) end
 if mobileCrosshair then mobileCrosshair.Position=UDim2.fromScale(.5,.5) end
 if resizeOptions then resizeOptions() end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()

local function frame(parent,name,pos,size,color,transparency)
 local f=Instance.new("Frame");f.Name=name;f.Position=UDim2.fromOffset(pos.X,pos.Y);f.Size=UDim2.fromOffset(size.X,size.Y);f.BorderSizePixel=0;f.BackgroundColor3=color or Color3.new(0,0,0);f.BackgroundTransparency=transparency or 0;f.Parent=parent;return f
end
local function label(parent,text,pos,size,fontSize)
 local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Position=UDim2.fromOffset(pos.X,pos.Y);t.Size=UDim2.fromOffset(size.X,size.Y);t.Text=text;t.TextColor3=Color3.fromRGB(230,230,216);t.Font=Enum.Font.Code;t.TextSize=fontSize or 22;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Top;t.TextWrapped=true;t.Parent=parent;return t
end
local function button(parent,text,pos,size,fn)
 local b=Instance.new("TextButton");b.Position=UDim2.fromOffset(pos.X,pos.Y);b.Size=UDim2.fromOffset(size.X,size.Y);b.BackgroundColor3=Color3.fromRGB(9,12,11);b.BackgroundTransparency=.3;b.BorderSizePixel=1;b.BorderColor3=Color3.fromRGB(112,119,111);b.TextColor3=Color3.fromRGB(228,232,218);b.Font=Enum.Font.Code;b.TextSize=21;b.Text=text;b.Parent=parent;b.Activated:Connect(fn);return b
end
local backdrop=Instance.new("Frame");backdrop.Name="MenuBackdrop";backdrop.Size=UDim2.fromScale(1,1);backdrop.BackgroundColor3=Color3.new(0,0,0);backdrop.BackgroundTransparency=.5;backdrop.BorderSizePixel=0;backdrop.ZIndex=1;backdrop.Visible=false;backdrop.Parent=gui
local menu=frame(root,"Menu",Vector2.zero,Vector2.new(1280,720),Color3.new(0,0,0),1)
local shade=frame(menu,"ReadingShade",Vector2.zero,Vector2.new(550,720),Color3.new(0,0,0),.12)
logo=Instance.new("ImageLabel");logo.Name="StillHereLogo";logo.Position=UDim2.fromOffset(24,12);logo.Size=UDim2.fromOffset(220,150);logo.BackgroundTransparency=1;logo.Image=if Config.Assets.MenuLogo>0 then "rbxassetid://"..Config.Assets.MenuLogo else "";logo.ScaleType=Enum.ScaleType.Fit;logo.Visible=Config.Assets.MenuLogo>0;logo.Parent=menu
heading=label(menu,"STILL HERE",Vector2.new(55,45),Vector2.new(680,75),58);heading.Font=Enum.Font.GothamBlack;heading.Visible=Config.Assets.MenuLogo<=0
chapter=label(menu,"CHAPTER 1 / DEAD SIGNAL",Vector2.new(55,135),Vector2.new(480,26),18);chapter.Visible=false
rule=frame(menu,"Rule",Vector2.new(55,165),Vector2.new(460,1),Color3.fromRGB(109,117,109));rule.Visible=false
description=label(menu,"",Vector2.new(55,195),Vector2.new(480,205),22);description.Visible=false
controls=frame(menu,"Buttons",Vector2.new(55,178),Vector2.new(405,280),nil,1)
optionsPanel=frame(root,"ProfessionalOptions",Vector2.zero,Vector2.new(520,720),Color3.fromRGB(5,7,7),.18)
optionsPanel.ZIndex=2;optionsPanel.Visible=false;optionsPanel.ClipsDescendants=true
local optionsGradient=Instance.new("UIGradient");optionsGradient.Color=ColorSequence.new(Color3.fromRGB(7,9,9),Color3.fromRGB(24,26,24));optionsGradient.Rotation=90;optionsGradient.Parent=optionsPanel
local optionShade=frame(optionsPanel,"ShadowPanel",Vector2.zero,Vector2.new(520,720),Color3.new(0,0,0),.16)
optionsTitle=label(optionsPanel,"OPTIONS",Vector2.new(52,38),Vector2.new(430,48),30);optionsTitle.Font=Enum.Font.GothamMedium;optionsTitle.TextColor3=Color3.fromRGB(230,232,222)
optionsRows=frame(optionsPanel,"Rows",Vector2.new(48,106),Vector2.new(448,490),nil,1)
local footerLabel=label(menu,"PLAY THE STORY OF STILL HERE",Vector2.new(55,680),Vector2.new(520,24),16);footer=footerLabel
footer.TextYAlignment=Enum.TextYAlignment.Center
local status=label(menu,"Conectando ao servidor…",Vector2.new(720,680),Vector2.new(510,24),15);status.TextXAlignment=Enum.TextXAlignment.Right;status.TextYAlignment=Enum.TextYAlignment.Center
local cassetteViews={}
local cassetteIndex=1
local cassetteAssets=Config.Assets.Cassettes or {}
local cassetteEntries={
 {title="CHAPTER 1",id=cassetteAssets.Chapter1 or 0},
 {title="MISSION FOUND",id=cassetteAssets.MissionFound or 0},
 {title="YOU ARE MY TOOLS",id=cassetteAssets.YouAreMyTools or 0},
}
local cycleCassette
local function makeCassettePanel(parent,name,pos,size,isMobile)
 local panel=frame(parent,name,pos,size,Color3.fromRGB(8,10,9),.2);panel.BorderSizePixel=1;panel.BorderColor3=Color3.fromRGB(98,103,97);panel.ZIndex=if parent==gui then 3 else 4;panel.ClipsDescendants=true
 local title=label(panel,"MESSAGE OF THE DAY",Vector2.new(8,5),Vector2.new(if isMobile then size.X-56 else size.X-130,20),if isMobile then 12 else 16);title.Font=Enum.Font.Code;title.TextYAlignment=Enum.TextYAlignment.Center;title.ZIndex=panel.ZIndex+1
 local counter=label(panel,"1 / 3",Vector2.new(size.X-(if isMobile then 48 else 112),5),Vector2.new(if isMobile then 40 else 104,20),if isMobile then 12 else 16);counter.TextXAlignment=Enum.TextXAlignment.Right;counter.TextYAlignment=Enum.TextYAlignment.Center;counter.ZIndex=panel.ZIndex+1
 local image=Instance.new("ImageLabel");image.Name="CassetteImage";image.Position=UDim2.fromOffset(8,if isMobile then 29 else 32);image.Size=UDim2.fromOffset(size.X-16,if isMobile then size.Y-62 else size.Y-66);image.BackgroundColor3=Color3.fromRGB(18,20,18);image.BackgroundTransparency=.1;image.BorderSizePixel=1;image.BorderColor3=Color3.fromRGB(55,60,55);image.ScaleType=Enum.ScaleType.Crop;image.ZIndex=panel.ZIndex+1;image.Parent=panel
 local fallback=label(image,"",Vector2.zero,Vector2.fromOffset(size.X-16,if isMobile then size.Y-62 else size.Y-66),if isMobile then 14 else 20);fallback.TextColor3=Color3.fromRGB(235,232,220);fallback.TextXAlignment=Enum.TextXAlignment.Center;fallback.TextYAlignment=Enum.TextYAlignment.Center;fallback.Font=Enum.Font.Code;fallback.ZIndex=image.ZIndex+1
 local prev=button(panel,if isMobile then "‹" else "Q  ‹",Vector2.new(8,size.Y-28),Vector2.new(if isMobile then 36 else 64,22),function() if cycleCassette then cycleCassette(-1) end end);prev.TextSize=if isMobile then 14 else 13;prev.ZIndex=panel.ZIndex+1
 local nextButton=button(panel,if isMobile then "›" else "›  E",Vector2.new(size.X-(if isMobile then 44 else 72),size.Y-28),Vector2.new(if isMobile then 36 else 64,22),function() if cycleCassette then cycleCassette(1) end end);nextButton.TextSize=if isMobile then 14 else 13;nextButton.ZIndex=panel.ZIndex+1
 table.insert(cassetteViews,{image=image,fallback=fallback,counter=counter})
 return panel
end
desktopMOTD=makeCassettePanel(menu,"MessageOfTheDayDesktop",Vector2.new(38,405),Vector2.new(360,225),false)
mobileMOTD=makeCassettePanel(gui,"MessageOfTheDayMobile",Vector2.zero,Vector2.new(180,168),true);mobileMOTD.AnchorPoint=Vector2.new(1,0);mobileMOTD.Position=UDim2.new(1,-12,0,12);mobileMOTD.Visible=false
local function updateCassetteViews()
 local entry=cassetteEntries[cassetteIndex]
 for _,view in ipairs(cassetteViews) do
  view.image.Image=if entry.id>0 then "rbxassetid://"..entry.id else ""
  view.fallback.Text=entry.title
  view.fallback.Visible=entry.id<=0
  view.counter.Text=tostring(cassetteIndex).." / "..tostring(#cassetteEntries)
 end
end
cycleCassette=function(delta)
 cassetteIndex=((cassetteIndex-1+delta)%#cassetteEntries)+1
 updateCassetteViews()
end
updateCassetteViews()
hud=frame(root,"HUD",Vector2.zero,Vector2.new(1280,720),nil,1);hud.Visible=false
local objectivePanel=frame(hud,"MissionObjectiveCard",Vector2.new(20,20),Vector2.new(468,150),Color3.fromRGB(6,8,8),.34);objectivePanel.BorderSizePixel=1;objectivePanel.BorderColor3=Color3.fromRGB(86,91,83);objectivePanel.ZIndex=2
local objective=label(objectivePanel,"",Vector2.new(14,10),Vector2.new(438,128),17);objective.Font=Enum.Font.GothamMedium;objective.TextColor3=Color3.fromRGB(229,231,220)
local stamina=label(hud,"",Vector2.new(24,180),Vector2.new(460,30),17)
local prompt=label(hud,"",Vector2.new(220,565),Vector2.new(850,60),19);prompt.TextXAlignment=Enum.TextXAlignment.Center;prompt.TextYAlignment=Enum.TextYAlignment.Center
local crosshair=label(hud,"·",Vector2.new(627,342),Vector2.new(28,35),30);crosshair.TextXAlignment=Enum.TextXAlignment.Center;crosshair.TextYAlignment=Enum.TextYAlignment.Center
local cinema=frame(root,"Cinema",Vector2.zero,Vector2.new(1280,720),nil,1);cinema.Visible=false
frame(cinema,"TopBar",Vector2.zero,Vector2.new(1280,85));frame(cinema,"BottomBar",Vector2.new(0,610),Vector2.new(1280,110))
local caption=label(cinema,"",Vector2.new(95,635),Vector2.new(1090,75),24);caption.TextXAlignment=Enum.TextXAlignment.Center
local data={state=Campaign.new(),active=false,stamina=100,elapsed=0}
local loaded=false;local sceneEpoch=0;local shotTween;local menuCameraBase
local run=false;local crouch=false;local sensitivity=1;local volume=.75;local lowGraphics=false;local missionHudEnabled=true;local tutorialHints=true;local showReticle=true;local ambientEnabled=true;local subtitlesEnabled=true;local brightness=1;local defaultBrightness=Lighting.Brightness;local defaultGlobalShadows=Lighting.GlobalShadows;local activeOptionsPage="OPTIONS"
local messageUntil=0;local message="";local function sound(id,loop,vol)
 if type(id)~="number" or id<=0 then return nil end
 local s=Instance.new("Sound");s.SoundId="rbxassetid://"..id;s.Looped=loop;s.Volume=vol or .4;s.Parent=SoundService;return s
end
local ambience=sound(Config.Assets.Ambient,true,.25);local pursuit=sound(Config.Assets.Pursuit,true,0);local voice
if ambience then ambience:Play() end;if pursuit then pursuit:Play() end
local function stopVoice() if voice then voice:Stop();voice:Destroy();voice=nil end end
local function playVoice(id) stopVoice();voice=sound(id,false,.9*volume);if voice then voice:Play() end end
local menuOptionButtons={}
local selectedMenuOption=1
local function clearButtons()
 for _,b in ipairs(controls:GetChildren()) do b:Destroy() end
 table.clear(menuOptionButtons)
end
local function add(text,index,fn)
 return button(controls,text,Vector2.new(0,(index-1)*46),Vector2.new(330,39),fn)
end
local function refreshMenuOptions()
 for _,item in ipairs(menuOptionButtons) do
  local prefix=if item.index==selectedMenuOption then "<font color='#d6403a'>▶</font>  " else "   "
  item.button.Text=prefix..item.label
  item.button.TextColor3=if item.index==selectedMenuOption then Color3.fromRGB(241,239,225) else Color3.fromRGB(199,200,190)
 end
end
local function addMenuOption(text,index,fn)
 local b=Instance.new("TextButton");b.Name="MenuOption_"..index;b.Position=UDim2.fromOffset(0,(index-1)*40);b.Size=UDim2.fromOffset(380,34);b.BackgroundTransparency=1;b.BorderSizePixel=0;b.TextColor3=Color3.fromRGB(199,200,190);b.Font=Enum.Font.Code;b.TextSize=22;b.TextXAlignment=Enum.TextXAlignment.Left;b.TextYAlignment=Enum.TextYAlignment.Center;b.RichText=true;b.AutoButtonColor=false;b.Parent=controls
 local item={button=b,label=text,index=index};table.insert(menuOptionButtons,item)
 b.MouseEnter:Connect(function() selectedMenuOption=index;refreshMenuOptions() end)
 b.Activated:Connect(function() selectedMenuOption=index;refreshMenuOptions();fn() end)
 refreshMenuOptions()
 return b
end

local function mouse(free) if UIS.TouchEnabled then UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=false else UIS.MouseBehavior=if free then Enum.MouseBehavior.Default else Enum.MouseBehavior.LockCenter;UIS.MouseIconEnabled=free end end
local function gameplay()
 mode="playing";menuActive=false;subpageActive=false;menu.Visible=false;optionsPanel.Visible=false;backdrop.Visible=false;if desktopMOTD then desktopMOTD.Visible=false end;if mobileMOTD then mobileMOTD.Visible=false end;hud.Visible=not phoneLayout;cinema.Visible=false;hands:setEnabled(data.state.hasGrabPack==true)
 mobileHud.Visible=phoneLayout;menuGrade.Enabled=false;camera.FieldOfView=70
 camera.CameraType=Enum.CameraType.Custom;player.CameraMode=Enum.CameraMode.LockFirstPerson
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid");if h then camera.CameraSubject=h end;mouse(false);resize()
end
local mainMenu,storyMenu,askNew,settings,extraMenu,visitPros,quitConfirm
local function showSubpage(title,body)
 menuActive=true;subpageActive=true;mode="menu"
 menu.Visible=true;optionsPanel.Visible=false;backdrop.Visible=true;hud.Visible=false;mobileHud.Visible=false;cinema.Visible=false;menuGrade.Enabled=true
 if logo then logo.Visible=false end
 if chapter then chapter.Visible=true;chapter.Text="CHAPTER 1 / DEAD SIGNAL" end
 if heading then heading.Visible=true;heading.Text=title end
 if description then description.Visible=true;description.Text=body end
 if rule then rule.Visible=true end
 if desktopMOTD then desktopMOTD.Visible=false end
 if mobileMOTD then mobileMOTD.Visible=false end
 clearButtons();resize()
end
askNew=function()
 showSubpage("NEW GAME","Isso substitui seu checkpoint atual. Começar de novo?")
 add("COMEÇAR",1,function() if loaded then action:FireServer("Start",false) end end)
 add("VOLTAR",2,storyMenu)
end
storyMenu=function()
 showSubpage("STORY","Escolha continuar do último checkpoint ou recomeçar o capítulo.")
 local cont=add(if data.dead then "RETOMAR CHECKPOINT" else "CONTINUAR",1,function()
  if not loaded or data.state.finished then return end
  if data.active then action:FireServer("Resume") else action:FireServer("Start",true) end
 end);cont.AutoButtonColor=loaded and not data.state.finished
 add("NOVO JOGO",2,askNew);add("VOLTAR",3,mainMenu)
end
local function optionRow(text,value,index,fn)
 local b=Instance.new("TextButton");b.Name="Option_"..index;b.Position=UDim2.fromOffset(0,(index-1)*43);b.Size=UDim2.new(1,0,0,37);b.BackgroundColor3=Color3.fromRGB(22,25,24);b.BackgroundTransparency=.52;b.BorderSizePixel=0;b.Text="";b.AutoButtonColor=false;b.Parent=optionsRows
 local labelText=Instance.new("TextLabel");labelText.BackgroundTransparency=1;labelText.Position=UDim2.fromOffset(8,0);labelText.Size=UDim2.new(.61,-8,1,0);labelText.Text=text;labelText.TextColor3=Color3.fromRGB(207,211,202);labelText.Font=Enum.Font.GothamMedium;labelText.TextSize=if compactLayout then 15 else 17;labelText.TextXAlignment=Enum.TextXAlignment.Left;labelText.TextYAlignment=Enum.TextYAlignment.Center;labelText.TextWrapped=true;labelText.Parent=b
 local valueText=Instance.new("TextLabel");valueText.BackgroundTransparency=1;valueText.Position=UDim2.new(.61,0,0,0);valueText.Size=UDim2.new(.39,-8,1,0);valueText.Text=value or "";valueText.TextColor3=Color3.fromRGB(166,171,164);valueText.Font=Enum.Font.Code;valueText.TextSize=if compactLayout then 13 else 15;valueText.TextXAlignment=Enum.TextXAlignment.Right;valueText.TextYAlignment=Enum.TextYAlignment.Center;valueText.TextWrapped=true;valueText.Parent=b
  local slider=if text=="BRIGHTNESS" then (brightness-.6)/.8 else if text=="MASTER VOLUME" then volume else if text=="MOUSE SENSITIVITY" then sensitivity-.5 else nil
  if slider then
   valueText.Position=UDim2.new(.82,0,0,0);valueText.Size=UDim2.new(.18,-8,1,0)
   local track=Instance.new("Frame");track.Name="SliderTrack";track.Active=false;track.Position=UDim2.new(.61,0,.5,2);track.Size=UDim2.new(.19,0,0,4);track.BackgroundColor3=Color3.fromRGB(61,66,62);track.BorderSizePixel=0;track.Parent=b
   local fill=Instance.new("Frame");fill.Name="SliderFill";fill.Active=false;fill.Size=UDim2.new(math.clamp(slider,0,1),0,1,0);fill.BackgroundColor3=Color3.fromRGB(220,222,211);fill.BorderSizePixel=0;fill.Parent=track
  end
 b.MouseEnter:Connect(function() b.BackgroundTransparency=.22 end);b.MouseLeave:Connect(function() b.BackgroundTransparency=.52 end)
 if fn then b.Activated:Connect(fn) end
 return b
end
local function renderOptionsPage(page)
 activeOptionsPage=page;optionsTitle.Text=page;optionsPanel.Visible=true;optionsRows.Visible=true
 for _,child in ipairs(optionsRows:GetChildren()) do child:Destroy() end
 local rows={}
 local function addRow(name,value,fn) table.insert(rows,{name=name,value=value,fn=fn}) end
 local onOff=function(v) return if v then "ON" else "OFF" end
 if page=="OPTIONS" then
  for _,category in ipairs({"GAME","CONTROLS","DISPLAY","AUDIO","LANGUAGE","CREDITS"}) do addRow(category,"›",function() renderOptionsPage(category) end) end
 elseif page=="GAME" then
  addRow("MISSION OBJECTIVES",onOff(missionHudEnabled),function() missionHudEnabled=not missionHudEnabled;renderOptionsPage(page) end)
  addRow("TUTORIAL HINTS",onOff(tutorialHints),function() tutorialHints=not tutorialHints;renderOptionsPage(page) end)
  addRow("SHOW RETICLE",onOff(showReticle),function() showReticle=not showReticle;renderOptionsPage(page) end)
  addRow("DIFFICULTY","NORMAL")
 elseif page=="CONTROLS" then
  addRow("BLUE HAND",if phoneLayout then "TOUCH • AZUL" else "E / LEFT CLICK")
  addRow("RED HAND",if phoneLayout then "TOUCH • VERMELHO" else "Q / RIGHT CLICK")
  addRow("RUN",if phoneLayout then "BOTÃO CORRER" else "LEFT SHIFT")
  addRow("CROUCH",if phoneLayout then "BOTÃO AGACHAR" else "C")
  addRow("FLASHLIGHT",if phoneLayout then "BOTÃO LUZ" else "F")
  addRow("PAUSE",if phoneLayout then "BOTÃO PAUSA" else "P")
  addRow("MOUSE SENSITIVITY",string.format("%.1f",sensitivity),function() sensitivity=if sensitivity>=1.5 then .5 else sensitivity+.25;UIS.MouseDeltaSensitivity=sensitivity;renderOptionsPage(page) end)
 elseif page=="DISPLAY" then
  addRow("BRIGHTNESS",math.floor(brightness*100).."%",function() brightness=if brightness>=1.4 then .6 else brightness+.2;Lighting.Brightness=defaultBrightness*brightness;renderOptionsPage(page) end)
  addRow("LOW GRAPHICS",onOff(lowGraphics),function() lowGraphics=not lowGraphics;Lighting.GlobalShadows=if lowGraphics then false else defaultGlobalShadows;renderOptionsPage(page) end)
  addRow("SHOW RETICLE",onOff(showReticle),function() showReticle=not showReticle;renderOptionsPage(page) end)
 elseif page=="AUDIO" then
  addRow("MASTER VOLUME",math.floor(volume*100).."%",function() volume=if volume>=1 then 0 else volume+.1;if voice then voice.Volume=volume*.9 end;renderOptionsPage(page) end)
  addRow("AMBIENT SOUND",onOff(ambientEnabled),function() ambientEnabled=not ambientEnabled;renderOptionsPage(page) end)
 elseif page=="LANGUAGE" then
  addRow("TEXT","PORTUGUÊS (BRASIL)")
  addRow("SUBTITLES",onOff(subtitlesEnabled),function() subtitlesEnabled=not subtitlesEnabled;caption.Visible=subtitlesEnabled;renderOptionsPage(page) end)
  addRow("DIALOGUE","PORTUGUÊS (BRASIL)")
 elseif page=="CREDITS" then
  addRow("STUDIO","AURIVANE WORKS")
  addRow("GAME","STILL HERE / DEAD SIGNAL")
  addRow("CHAPTER","CHAPTER 1")
  addRow("ASSET SOURCES","ASSETS.MD")
 end
 for i,row in ipairs(rows) do optionRow(row.name,row.value,i,row.fn) end
 for _,child in ipairs(optionsPanel:GetChildren()) do if child.Name=="OptionsBack" then child:Destroy() end end
 local back=Instance.new("TextButton");back.Name="OptionsBack";back.Position=UDim2.fromOffset(52,650);back.Size=UDim2.fromOffset(170,38);back.BackgroundColor3=Color3.fromRGB(11,13,13);back.BackgroundTransparency=.35;back.BorderSizePixel=0;back.Text="◉  BACK";back.TextColor3=Color3.fromRGB(219,221,212);back.Font=Enum.Font.GothamMedium;back.TextSize=15;back.TextXAlignment=Enum.TextXAlignment.Left;back.Parent=optionsPanel
 back.Activated:Connect(function() if page=="OPTIONS" then mainMenu() else renderOptionsPage("OPTIONS") end end)
end
settings=function()
 mode="menu";menuActive=true;subpageActive=true;menu.Visible=false;optionsPanel.Visible=true;backdrop.Visible=true;hud.Visible=false;mobileHud.Visible=false;cinema.Visible=false;hands:setEnabled(false);mouse(true);menuGrade.Enabled=true
 if desktopMOTD then desktopMOTD.Visible=false end;if mobileMOTD then mobileMOTD.Visible=false end
 camera.CameraType=Enum.CameraType.Scriptable
 renderOptionsPage("OPTIONS");resize()
end
extraMenu=function()
 local selected=cassetteEntries[cassetteIndex].title
 showSubpage("EXTRA","FITAS RECUPERADAS\nCHAPTER 1\nMISSION FOUND\nYOU ARE MY TOOLS\n\nSelecionada: "..selected)
 add("FITA ANTERIOR",1,function() cycleCassette(-1);extraMenu() end)
 add("PRÓXIMA FITA",2,function() cycleCassette(1);extraMenu() end)
 add("VOLTAR",3,mainMenu)
end
visitPros=function()
 showSubpage("VISIT PROS","AURIVANE WORKS\nStill Here — Chapter 1\nPort nativo em Luau, com cenário e sistemas próprios.\nVeja ASSETS.md para créditos e origens dos recursos.")
 add("VOLTAR",1,mainMenu)
end
quitConfirm=function()
 showSubpage("QUIT GAME","Seu último checkpoint continua salvo quando o armazenamento online está disponível.")
 add("SAIR DA EXPERIÊNCIA",1,function() action:FireServer("Quit") end)
 add("VOLTAR",2,mainMenu)
end
mainMenu=function()
 mode="menu";menuActive=true;subpageActive=false;menu.Visible=true;optionsPanel.Visible=false;backdrop.Visible=true;hud.Visible=false;mobileHud.Visible=false;cinema.Visible=false;hands:setEnabled(false);mouse(true);menuGrade.Enabled=true;camera.FieldOfView=56
 if logo then logo.Visible=Config.Assets.MenuLogo>0 end
 if heading then heading.Visible=Config.Assets.MenuLogo<=0;heading.Text="STILL HERE" end
 if chapter then chapter.Visible=false end
 if description then description.Visible=false end
 if rule then rule.Visible=false end
 resize();clearButtons();selectedMenuOption=1
 addMenuOption("STORY",1,storyMenu)
 addMenuOption("OPTIONS",2,settings)
 addMenuOption("EXTRA",3,extraMenu)
 addMenuOption("VISIT PROS",4,visitPros)
 addMenuOption("QUIT GAME",5,quitConfirm)
 camera.CameraType=Enum.CameraType.Scriptable;menuCameraBase=CFrame.lookAt(Vector3.new(-8,7,92),Vector3.new(6,7,67));camera.CFrame=menuCameraBase
end

local function sceneDone()
 sceneEpoch+=1;if shotTween then shotTween:Cancel() end;stopVoice();cinema.Visible=false;action:FireServer("SceneDone")
end
button(cinema,"PULAR CENA ›",Vector2.new(1040,25),Vector2.new(190,45),sceneDone)
local function scene(payload,ending)
 sceneEpoch+=1;local token=sceneEpoch
 mode="cinema";menuActive=false;subpageActive=false;menu.Visible=false;optionsPanel.Visible=false;backdrop.Visible=false;menuGrade.Enabled=false;camera.FieldOfView=70;if desktopMOTD then desktopMOTD.Visible=false end;if mobileMOTD then mobileMOTD.Visible=false end;hud.Visible=false;cinema.Visible=true;mobileHud.Visible=false;hands:setEnabled(false);mouse(true);camera.CameraType=Enum.CameraType.Scriptable;resize()
 caption.Visible=subtitlesEnabled
  local sector=payload.state.sector;local o=payload.origin or Vector3.zero
 local lines=if ending then {"O ELEVADOR / 00:03","VOCÊ: Acabou. A antena está muda.","RÁDIO: Você não desligou o sinal. Você me levou com você."} else Config.Sectors[sector].Lines
 local shots={o+Vector3.new(10,8,-15),o+Vector3.new(-20,8,-100),o+Vector3.new(10,9,-220)}
 if sector==4 then shots={o+Vector3.new(-63,14,-15),o+Vector3.new(-15,14,-100),o+Vector3.new(50,14,-220)} end
 if ending then shots={o+Vector3.new(8,8,-240),o+Vector3.new(0,14,-235),o+Vector3.new(0,21,-240)} end
 if sector==1 and not ending then playVoice(Config.Assets.OpeningVoice) end
 for i=1,3 do
  if token~=sceneEpoch then return end
  caption.Text=lines[i]
  local key=(if ending then 7 else sector-1).."_"..(i-1)
  if (i>1 and sector~=1) or (ending and i>1) then playVoice(Config.Assets.Voices[key]) end
  camera.CFrame=CFrame.lookAt(shots[i],shots[i]+Vector3.new(0,-1,-20))
  local duration=if sector==1 and Config.Assets.OpeningVoice>0 and not ending then 11.3 else 4.8
  if voice then
   local deadline=os.clock()+3
   while not voice.IsLoaded and os.clock()<deadline do task.wait(.05);if token~=sceneEpoch then return end end
   if voice.IsLoaded then
    if sector==1 and not ending then duration=(voice.TimeLength+.5)/3 else duration=math.max(duration,voice.TimeLength+.4) end
   end
  end
  shotTween=TweenService:Create(camera,TweenInfo.new(duration,Enum.EasingStyle.Sine),{CFrame=camera.CFrame*CFrame.new(2,.3,-5)});shotTween:Play()
  local deadline=os.clock()+duration
  repeat task.wait(.05);if token~=sceneEpoch then return end until os.clock()>deadline
 end
 sceneDone()
end
local function nextMissionStep(s)
 local f=s.flags
 if s.sector==1 then
  if not s.hasGrabPack then return "PEGUE O GRABPACK" end
  if not f.card then return "ENCONTRE O CRACHÁ" end
  if not f.fuse then return "ENCONTRE O FUSÍVEL" end
  if not f.power then return "LIGUE O QUADRO PRINCIPAL" end
  if not f.socket1 then return "USE A MÃO AZUL NO TERMINAL 1" end
  if not f.socket2 then return "USE A MÃO VERMELHA NO TERMINAL 2" end
  if Campaign.count(s,"bloom")<3 then return "PODE AS TRÊS FLORES" end
  if not f.socket3 then return "USE A MÃO AZUL NO TERMINAL 3" end
  if not f.release then return "LIBERE A SAÍDA COM A MÃO VERMELHA" end
 elseif s.sector==2 then
  if Campaign.count(s,"page")<3 then return "RECUPERE AS TRÊS PÁGINAS" end
  if table.concat(s.digits)~="1784" then return "AJUSTE O COFRE PARA 1784" end
  return "ABRA O COFRE"
 elseif s.sector==3 then
  if Campaign.count(s,"cell")<3 then return "ENCONTRE AS TRÊS CÉLULAS" end
  if not s.valves[1] or s.valves[2] or not s.valves[3] or not s.valves[4] then return "ENTRADA, RETORNO E RESERVA ABERTAS" end
  if s.pressure~=6 then return "AJUSTE A PRESSÃO PARA 6" end
  return "LIGUE A MÁQUINA COM A MÃO VERMELHA"
 elseif s.sector==4 then
  if Campaign.count(s,"seed")<6 then return "ENCONTRE AS SEIS SEMENTES" end
 elseif s.sector==5 then
  if s.tones<6 then return "REPITA A SEQUÊNCIA 2 • 4 • 1 • 3 • 2 • 1" end
  for _,on in ipairs(s.matrix) do if on then return "APAGUE TODAS AS LÂMPADAS" end end
 elseif s.sector==6 then
  for i=1,4 do if not f["isolate"..i] then return "ISOLE A RAIZ "..i.." COM AZUL" end;if not f["cut"..i] then return "CORTE A RAIZ "..i.." COM VERMELHO" end end
 else
  if Campaign.count(s,"fuse")<4 then return "RECUPERE OS QUATRO FUSÍVEIS" end
  if table.concat(s.angles)~="314" then return "ALINHE AS ANTENAS EM 3 • 1 • 4" end
  if not f.silent then return "DESLIGUE A CHAVE MESTRE" end
 end
 return "SIGA ATÉ A SAÍDA"
end
local function missionText()
 local state=data.state;local info=Config.Sectors[state.sector] or Config.Sectors[1]
 local value="MISSION / "..info.Name.."\n"..info.Goal.."\n"..Campaign.progress(state)
 if tutorialHints then value=value.."\nPRÓXIMO: "..nextMissionStep(state) end
 return value
end
local function targetAtCrosshair()
 local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character,hands.root}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*Config.MaxReach,params)
 local obj=hit and hit.Instance
 while obj and obj~=workspace do if obj:GetAttribute("TargetId") then return obj end;obj=obj.Parent end
 return nil
end
mobilePrompt.Activated:Connect(function()
 if mode~="playing" then return end
 local target=targetAtCrosshair()
 if not target then return end
 if target:GetAttribute("Action")=="pack" then action:FireServer("Interact",target:GetAttribute("TargetId"),false)
 elseif data.state.hasGrabPack then local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2);action:FireServer("FireHand",ray.Direction,false) end
end)
local function use(right)
 if mode~="playing" then return end
 if not data.state.hasGrabPack then message="PEGUE O GRABPACK PARA USAR AS MÃOS";messageUntil=os.clock()+3;return end
 local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 action:FireServer("FireHand",ray.Direction,right)
end
local lamp
local function movement() action:FireServer("Move",{run=run,crouch=crouch}) end
local function pause() if mode=="playing" then run=false;movement();action:FireServer("Pause") end end
button(hud,"Ⅱ",Vector2.new(1190,20),Vector2.new(65,55),pause)
mobileHud=Instance.new("Frame");mobileHud.Name="MobileGameplayHUD";mobileHud.Size=UDim2.fromScale(1,1);mobileHud.BackgroundTransparency=1;mobileHud.BorderSizePixel=0;mobileHud.ZIndex=4;mobileHud.Visible=false;mobileHud.Parent=gui
mobileObjectiveCard=frame(mobileHud,"MobileMissionCard",Vector2.new(12,56),Vector2.new(250,118),Color3.fromRGB(6,8,8),.3);mobileObjectiveCard.ZIndex=5;mobileObjectiveCard.BorderSizePixel=1;mobileObjectiveCard.BorderColor3=Color3.fromRGB(86,91,83)
mobileObjective=label(mobileObjectiveCard,"",Vector2.new(10,8),Vector2.new(230,80),14);mobileObjective.Font=Enum.Font.GothamMedium;mobileObjective.TextColor3=Color3.fromRGB(231,233,222);mobileObjective.ZIndex=6
mobileStamina=label(mobileObjectiveCard,"FÔLEGO 100%",Vector2.new(10,91),Vector2.new(230,18),12);mobileStamina.Font=Enum.Font.GothamMedium;mobileStamina.TextColor3=Color3.fromRGB(174,181,169);mobileStamina.ZIndex=6
mobilePrompt=Instance.new("TextButton");mobilePrompt.Name="MobileTargetPrompt";mobilePrompt.BackgroundColor3=Color3.fromRGB(8,10,10);mobilePrompt.BackgroundTransparency=.18;mobilePrompt.BorderSizePixel=1;mobilePrompt.BorderColor3=Color3.fromRGB(116,120,108);mobilePrompt.TextColor3=Color3.fromRGB(242,239,224);mobilePrompt.Text="";mobilePrompt.TextSize=14;mobilePrompt.Font=Enum.Font.GothamBold;mobilePrompt.TextWrapped=true;mobilePrompt.AutoButtonColor=false;mobilePrompt.AnchorPoint=Vector2.new(.5,1);mobilePrompt.ZIndex=5;mobilePrompt.Visible=false;mobilePrompt.Parent=mobileHud;local promptCorner=Instance.new("UICorner");promptCorner.CornerRadius=UDim.new(.12,0);promptCorner.Parent=mobilePrompt
mobileCrosshair=label(mobileHud,"·",Vector2.new(0,0),Vector2.new(26,34),30);mobileCrosshair.AnchorPoint=Vector2.new(.5,.5);mobileCrosshair.TextXAlignment=Enum.TextXAlignment.Center;mobileCrosshair.TextYAlignment=Enum.TextYAlignment.Center;mobileCrosshair.ZIndex=6
touchPad=frame(mobileHud,"GrabPackControls",Vector2.new(0,0),Vector2.new(148,238),Color3.fromRGB(7,9,9),.28);touchPad.AnchorPoint=Vector2.new(1,.5);touchPad.Position=UDim2.new(1,-12,.5,0);touchPad.ZIndex=5;touchPad.BorderSizePixel=1;touchPad.BorderColor3=Color3.fromRGB(92,99,92)
local touchHeader=label(touchPad,"GRABPACK",Vector2.new(8,5),Vector2.new(132,20),11);touchHeader.Font=Enum.Font.GothamBold;touchHeader.TextColor3=Color3.fromRGB(193,198,188);touchHeader.TextYAlignment=Enum.TextYAlignment.Center;touchHeader.ZIndex=6
local function touchButton(text,x,y,color,fn)
 local b=button(touchPad,text,Vector2.new(x,y),Vector2.new(68,58),fn);b.ZIndex=6;b.TextSize=13;b.Font=Enum.Font.GothamBold;b.TextWrapped=true;b.BackgroundColor3=color;b.BackgroundTransparency=.22;b.BorderColor3=Color3.fromRGB(116,120,108)
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(.14,0);corner.Parent=b
 return b
end
touchButton("AZUL",4,30,Color3.fromRGB(23,61,103),function() use(false) end)
touchButton("VERMELHA",76,30,Color3.fromRGB(104,36,31),function() use(true) end)
touchButton("CORRER",4,98,Color3.fromRGB(30,36,33),function() run=not run;movement() end)
touchButton("AGACHAR",76,98,Color3.fromRGB(30,36,33),function() crouch=not crouch;movement() end)
touchButton("LUZ",4,166,Color3.fromRGB(30,36,33),function() if lamp then lamp.Enabled=not lamp.Enabled end end)
touchButton("PAUSAR",76,166,Color3.fromRGB(30,36,33),pause)
resize()
local function character(c)
 local head=c:WaitForChild("Head",10);if head then lamp=Instance.new("SpotLight");lamp.Face=Enum.NormalId.Front;lamp.Range=65;lamp.Angle=60;lamp.Brightness=2;lamp.Shadows=false;lamp.Parent=head end
end
player.CharacterAdded:Connect(character);if player.Character then task.spawn(character,player.Character) end
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if mode=="menu" and not subpageActive and input.KeyCode==Enum.KeyCode.Q then cycleCassette(-1)
 elseif mode=="menu" and not subpageActive and input.KeyCode==Enum.KeyCode.E then cycleCassette(1)
 elseif input.KeyCode==Enum.KeyCode.E or input.UserInputType==Enum.UserInputType.MouseButton1 then use(false)
 elseif input.KeyCode==Enum.KeyCode.Q or input.UserInputType==Enum.UserInputType.MouseButton2 then use(true)
 elseif input.KeyCode==Enum.KeyCode.LeftShift then run=true;movement()
 elseif input.KeyCode==Enum.KeyCode.C then crouch=not crouch;movement()
 elseif input.KeyCode==Enum.KeyCode.F and lamp then lamp.Enabled=not lamp.Enabled
 elseif input.KeyCode==Enum.KeyCode.P then pause() end
end)
UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.LeftShift then run=false;movement() end end)
local lastVisual="";local lastWorldScan=0
local function refreshWorld(force)
 local st=data.state
 local signature=game:GetService("HttpService"):JSONEncode(st)
 if signature==lastVisual and not force then return end;lastVisual=signature
 local world=workspace:FindFirstChild("BrambleWorld");local index=world and world:FindFirstChild("TargetIndex");if not index then lastVisual="";return end
 for _,ref in ipairs(index:GetChildren()) do
  local target=ref.Value
  if target and target:GetAttribute("Sector")==st.sector then
   local id=target:GetAttribute("Action");local collected=(st.flags[id] and (string.match(id,"^page") or string.match(id,"^seed") or string.match(id,"^cell") or string.match(id,"^fuse") or id=="card" or string.match(id,"^bloom"))) or (id=="pack" and st.hasGrabPack==true)
   target.LocalTransparencyModifier=if collected then 1 else 0
   for _,item in ipairs(target:GetDescendants()) do if item:IsA("BasePart") then item.LocalTransparencyModifier=if collected then 1 else 0 end end
   local pro=target:FindFirstChildOfClass("ProximityPrompt");if pro then pro.Enabled=id=="pack" and not collected end
   local surface=target:FindFirstChildOfClass("SurfaceGui");local readout=surface and surface:FindFirstChild("Readout")
   local value=target:GetAttribute("Title")
   if string.match(id,"^digit[1234]$") then value=tostring(st.digits[tonumber(string.sub(id,-1))])
   elseif string.match(id,"^valve[1234]$") then value=if st.valves[tonumber(string.sub(id,-1))] then "ABERTA" else "FECHADA"
   elseif id=="pressure" then value=st.pressure.." BAR"
   elseif string.match(id,"^angle[123]$") then value=tostring(st.angles[tonumber(string.sub(id,-1))])
   elseif id=="exit" then value=if Campaign.complete(st) then "LIBERADO" else "BLOQUEADO" end
   if readout then readout.Text=value;surface.Enabled=not collected end
    local marker=target:FindFirstChild("MissionMarker");if marker and marker:IsA("BillboardGui") then marker.Enabled=not collected;local markerText=marker:FindFirstChild("Label",true);if markerText then markerText.Text=value end end
   if string.match(id,"^lamp[123456789]$") and target:FindFirstChild("Indicator") then target.Indicator.Color=if st.matrix[tonumber(string.sub(id,-1))] then Color3.fromRGB(240,190,50) else Color3.fromRGB(20,28,24) end
  end
 end
end
update.OnClientEvent:Connect(function(kind,payload)
 if kind=="Hand" then hands:launch(payload.point,payload.right);return end
 if kind=="HandHold" then hands:hold(payload.part,payload.right);return end
 if kind=="HandRelease" then hands:release(payload.right);return end
 if payload.state then data=payload;refreshWorld();if mode=="playing" then hands:setEnabled(data.state.hasGrabPack==true) end end
 status.Text=payload.saveStatus or ""
 if payload.message then message=payload.message;messageUntil=os.clock()+4 end
 if kind=="Ready" then loaded=true;if mode=="menu" then mainMenu() end
 elseif kind=="Scene" or kind=="Ending" then task.spawn(scene,payload,kind=="Ending")
 elseif kind=="Dead" then
  showSubpage("ELE ENCONTROU VOCÊ",payload.message or "Retome o checkpoint para tentar outra vez.")
  add("RETOMAR CHECKPOINT",1,function() action:FireServer("Start",true) end);add("MENU PRINCIPAL",2,mainMenu)
 elseif kind=="Won" then
  showSubpage("O SINAL NÃO MORREU","FIM DO CAPÍTULO 1 / DEAD SIGNAL\nVocê saiu. A transmissão foi junto.")
  add("VOLTAR AO MENU",1,mainMenu)
 elseif kind=="Paused" then
  showSubpage("PAUSADO","O capítulo está pausado.")
  mode="paused";add("CONTINUAR",1,function() action:FireServer("Resume") end);add("CONFIGURAÇÕES",2,settings);add("MENU PRINCIPAL",3,mainMenu)
 elseif kind=="Document" then
  showSubpage("PROTOCOLO",payload.message or "")
  mode="reading";hud.Visible=false;hands:setEnabled(false);mouse(true);add("FECHAR",1,gameplay)
 elseif data.active and not data.scene and not data.dead and mode~="reading" and mode~="cinema" and mode~="playing" then gameplay()
 elseif data.active and not data.scene and mode=="cinema" then gameplay() end
end)
RunService.RenderStepped:Connect(function()
 if mode=="playing" then
  local text=missionText()
  objective.Text=text;objective.Visible=missionHudEnabled and not phoneLayout
  mobileObjective.Text=text;mobileObjectiveCard.Visible=missionHudEnabled
  stamina.Text="FÔLEGO "..math.floor(data.stamina or 100).."%";stamina.Visible=not phoneLayout
  mobileStamina.Text=stamina.Text
  crosshair.Visible=showReticle;mobileCrosshair.Visible=showReticle
  local target=targetAtCrosshair()
  local targetName=target and target:GetAttribute("Title") or nil
  local isPack=target and target:GetAttribute("Action")=="pack"
  local defaultPrompt=if isPack then "PEGAR GRABPACK • TOQUE" else if targetName then targetName.."  •  AZUL / VERMELHA" else ""
  local liveMessage=os.clock()<messageUntil
  prompt.Text=if liveMessage then message else if targetName then targetName.."  •  E / AZUL   Q / VERMELHA" else ""
  prompt.Visible=not phoneLayout and (liveMessage or targetName~=nil)
  mobilePrompt.Text=if liveMessage then message else defaultPrompt
  mobilePrompt.Visible=liveMessage or targetName~=nil
 end
 local danger=Campaign.danger(data.state) and mode=="playing"
 if ambience then ambience.Volume=if ambientEnabled then volume*(if voice and voice.IsPlaying then .1 else .32) else 0 end
 if pursuit then pursuit.Volume=if danger then volume*.55 else 0 end
 local now=os.clock()
 if mode=="playing" and now-lastWorldScan>1 then lastWorldScan=now;refreshWorld(true) end
end)
while not player:GetAttribute("BrambleBootDone") do task.wait(.1) end
gui.Enabled=true;mainMenu();action:FireServer("Sync")
