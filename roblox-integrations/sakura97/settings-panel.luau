local M={}
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local TweenService=game:GetService("TweenService")
local initialized=setmetatable({},{__mode="k"})
local BOOK_PAGE_SOUND_ID=6102885802

local PAPER=Color3.fromRGB(231,218,190)
local INK=Color3.fromRGB(42,33,29)
local MUTED=Color3.fromRGB(94,77,67)
local RED=Color3.fromRGB(118,20,25)
local DARK=Color3.fromRGB(21,19,20)

local function corner(parent,r)
 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,r or 5)
 c.Parent=parent
 return c
end

local function stroke(parent,color,transparency,thickness)
 local s=Instance.new("UIStroke")
 s.Color=color or INK
 s.Transparency=transparency or 0
 s.Thickness=thickness or 1
 s.Parent=parent
 return s
end

local function label(parent,name,value,size,pos,z)
 local t=Instance.new("TextLabel")
 t.Name=name
 t.Text=value
 t.Size=size
 t.Position=pos or UDim2.new()
 t.BackgroundTransparency=1
 t.BorderSizePixel=0
 t.Font=Enum.Font.Garamond
 t.TextColor3=INK
 t.TextSize=18
 t.TextWrapped=true
 t.ZIndex=z or 46
 t.Parent=parent
 return t
end

local function textButton(parent,name,value,size,pos,z)
 local b=Instance.new("TextButton")
 b.Name=name
 b.Text=value
 b.Size=size
 b.Position=pos or UDim2.new()
 b.BackgroundColor3=Color3.fromRGB(224,207,175)
 b.BackgroundTransparency=.08
 b.BorderSizePixel=0
 b.AutoButtonColor=false
 b.Font=Enum.Font.Garamond
 b.TextColor3=INK
 b.TextSize=17
 b.ZIndex=z or 48
 corner(b,5)
 stroke(b,Color3.fromRGB(75,57,49),.25,1)
 b.Parent=parent
 return b
end

local function ensure(player,key,default)
 local value=player:GetAttribute(key)
 if value==nil then
  player:SetAttribute(key,default)
  value=default
 end
 return value
end

local GAME_SPECS={
 {key="MusicVolume",label="MÚSICA",default=65,min=0,max=100,step=5,suffix="%"},
 {key="EffectsVolume",label="EFEITOS",default=80,min=0,max=100,step=5,suffix="%"},
 {key="ControlScale",label="TAMANHO DOS CONTROLES",default=100,min=80,max=120,step=5,suffix="%"},
 {key="CameraSensitivity",label="SENSIBILIDADE",default=100,min=50,max=150,step=5,suffix="%"},
}
local LANGUAGE_SPEC={key="language",attribute="GameLanguage",default="pt-BR"}
local VISUAL_SPECS={
 {key="CameraFOV",label="CAMPO DE VISÃO",default=62,min=50,max=80,step=1,suffix="°"},

}

function M.initialize(player)
 if initialized[player] then return end
 initialized[player]=true
 if player:GetAttribute("GameLanguage")==nil then
  local locale=tostring(player.LocaleId or "en"):lower()
  player:SetAttribute("GameLanguage",locale:sub(1,2)=="pt" and "pt-BR" or "en")
 end
 for key,value in pairs({MusicVolume=65,EffectsVolume=80,MenuSounds=true,FriendAlerts=true,AFK=false,CameraFOV=62,ControlScale=100,ShowNametags=true,CameraSensitivity=100}) do
  if player:GetAttribute(key)==nil then player:SetAttribute(key,value) end
 end
 local music=SoundService:FindFirstChild("SuviversMusic") or Instance.new("SoundGroup",SoundService)
 music.Name="SuviversMusic"
 local function applyMusic() music.Volume=(player:GetAttribute("MusicVolume") or 65)/100 end
 player:GetAttributeChangedSignal("MusicVolume"):Connect(applyMusic) applyMusic()
 local group=SoundService:FindFirstChild("SuviversEffects") or Instance.new("SoundGroup",SoundService)
 group.Name="SuviversEffects"
 local function apply() group.Volume=(player:GetAttribute("EffectsVolume") or 80)/100 end
 player:GetAttributeChangedSignal("EffectsVolume"):Connect(apply) apply()
 local function bind(o)
  if o:IsA("Sound") and o.Name=="SuviversMatchMusic" then o.SoundGroup=music end
  if o:IsA("Sound") and (o.Name=="MenuClick" or o.Name=="Click" or o.Name=="PlayClick" or o.Name=="FriendJoined" or o.Name=="Regenerate" or o.Name=="RegenerationCue") then
   o.SoundGroup=group
  end
 end
 for _,root in ipairs({SoundService,workspace,player:WaitForChild("PlayerGui")}) do
  root.DescendantAdded:Connect(bind)
  for _,o in ipairs(root:GetDescendants()) do bind(o) end
 end
end

function M.build(parent,player,onClose)
 M.initialize(player)
 local frame=Instance.new("Frame")
 frame.Name="ReferenceSettings"
 frame.Size=UDim2.fromScale(1,1)
 frame.BackgroundTransparency=1
 frame.BorderSizePixel=0
 frame.ZIndex=41
 frame:SetAttribute("Style","RedBinderBook")
 frame:SetAttribute("ScrollablePages",true)
 frame:SetAttribute("RibbonTabs",true)
 frame:SetAttribute("BookAudio",true)
 frame:SetAttribute("BookAnimation",true)
 frame.Parent=parent

 local shadow=Instance.new("Frame")
 shadow.Name="BookShadow"
 shadow.AnchorPoint=Vector2.new(.5,.5)
 shadow.Position=UDim2.fromScale(.5,.515)
 shadow.BackgroundColor3=Color3.new(0,0,0)
 shadow.BackgroundTransparency=.38
 shadow.BorderSizePixel=0
 shadow.ZIndex=41
 corner(shadow,18)
 shadow.Parent=frame

 local book=Instance.new("ImageLabel")
 book.Name="BookBackground"
 book.AnchorPoint=Vector2.new(.5,.5)
 book.Position=UDim2.fromScale(.5,.5)
 book.BackgroundColor3=Color3.fromRGB(28,22,23)
 book.BackgroundTransparency=0
 book.BorderSizePixel=0
 book.ScaleType=Enum.ScaleType.Stretch
 book.ZIndex=42

 local paper=Instance.new("Sound")
 paper.Name="SettingsBookPaper"
 paper.SoundId="rbxassetid://"..BOOK_PAGE_SOUND_ID
 paper.Volume=.26
 paper.PlaybackSpeed=1
 paper.SoundGroup=SoundService:FindFirstChild("SuviversEffects")
 paper.Parent=SoundService
 local function playPaper(speed,volume)
  if player:GetAttribute("MenuSounds")==false then return end
  paper:Stop()
  paper.TimePosition=0
  paper.PlaybackSpeed=speed or 1
  paper.Volume=volume or .26
  pcall(function() paper:Play() end)
 end
 local function animatePaperTurn(direction)
  local sign=direction or 1
  book.Rotation=sign*.9
  TweenService:Create(book,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Rotation=0}):Play()
 end
 local function animateBookOpen()
  if not parent.Visible then return end
  playPaper(.88,.34)
  book.Rotation=-2.2
  book.Position=UDim2.fromScale(.5,.515)
  book.ImageTransparency=.08
  TweenService:Create(book,TweenInfo.new(.30,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
   Position=UDim2.fromScale(.5,.5),Rotation=0,ImageTransparency=0
  }):Play()
 end
 local previousVisible=parent.Visible
 parent:GetPropertyChangedSignal("Visible"):Connect(function()
  if parent.Visible and not previousVisible then
   animateBookOpen()
  elseif not parent.Visible and previousVisible then
   playPaper(.76,.17)
  end
  previousVisible=parent.Visible
 end)
 frame.Destroying:Connect(function() if paper.Parent then paper:Destroy() end end)

 local bookAsset=tonumber(game:GetService("ReplicatedStorage"):WaitForChild("Survival"):GetAttribute("SettingsBookAssetId")) or 0
 if bookAsset>0 then
  book.Image="rbxassetid://"..tostring(bookAsset)
  book.BackgroundTransparency=1
 end
 book.Parent=frame

 -- Fallback paper spread so the panel is still usable if the texture is loading.
 local fallback=Instance.new("Frame")
 fallback.Name="FallbackPaper"
 fallback.Position=UDim2.fromScale(.105,.095)
 fallback.Size=UDim2.fromScale(.79,.80)
 fallback.BackgroundColor3=Color3.fromRGB(235,224,200)
 fallback.BackgroundTransparency=bookAsset>0 and 1 or 0
 fallback.BorderSizePixel=0
 fallback.ZIndex=42
 corner(fallback,8)
 stroke(fallback,Color3.fromRGB(63,42,40),.1,2)
 fallback.Parent=book
 fallback.Visible=not book.IsLoaded
 book:GetPropertyChangedSignal("IsLoaded"):Connect(function() fallback.Visible=not book.IsLoaded end)

 local title=label(book,"Title","CONFIGURAÇÕES",UDim2.fromScale(.34,.065),UDim2.fromScale(.115,.095),46)
 title.Font=Enum.Font.Garamond
 title.TextSize=31
 title.TextScaled=true
 local titleLimit=Instance.new("UITextSizeConstraint",title) titleLimit.MinTextSize=14 titleLimit.MaxTextSize=31
 title.TextXAlignment=Enum.TextXAlignment.Left
 title.TextStrokeColor3=Color3.fromRGB(249,239,216)
 title.TextStrokeTransparency=.72

 local subtitle=label(book,"Subtitle","JOGO",UDim2.fromScale(.28,.035),UDim2.fromScale(.115,.145),46)
 subtitle.TextSize=13
 subtitle.TextColor3=MUTED
 subtitle.TextXAlignment=Enum.TextXAlignment.Left

 local scroll=Instance.new("ScrollingFrame")
 scroll.Name="PageScroll"
 scroll.Position=UDim2.fromScale(.125,.20)
 scroll.Size=UDim2.fromScale(.75,.64)
 scroll.BackgroundTransparency=1
 scroll.BorderSizePixel=0
 scroll.CanvasSize=UDim2.new()
 scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
 scroll.ScrollingDirection=Enum.ScrollingDirection.Y
 scroll.ScrollBarThickness=4
 scroll.ScrollBarImageColor3=RED
 scroll.ScrollBarImageTransparency=.15
 scroll.ElasticBehavior=Enum.ElasticBehavior.WhenScrollable
 scroll.ZIndex=45
 scroll.Parent=book

 local pad=Instance.new("UIPadding")
 pad.PaddingTop=UDim.new(0,8)
 pad.PaddingBottom=UDim.new(0,16)
 pad.PaddingLeft=UDim.new(0,3)
 pad.PaddingRight=UDim.new(0,7)
 pad.Parent=scroll

 local grid=Instance.new("UIGridLayout")
 grid.Name="TwoPageGrid"
 grid.CellSize=UDim2.new(.44,0,0,102)
 grid.CellPadding=UDim2.new(.12,0,0,14)
 grid.FillDirection=Enum.FillDirection.Horizontal
 grid.FillDirectionMaxCells=2
 grid.HorizontalAlignment=Enum.HorizontalAlignment.Left
 grid.SortOrder=Enum.SortOrder.LayoutOrder
 grid.Parent=scroll

 local cards={}
 local cardConnections={}
 local function track(connection) table.insert(cardConnections,connection) end
 local activeCategory="game"
 local tabButtons={}

 local function clearCards()
  for _,connection in ipairs(cardConnections) do connection:Disconnect() end
  table.clear(cardConnections)
  for _,c in ipairs(cards) do if c.Parent then c:Destroy() end end
  table.clear(cards)
  scroll.CanvasPosition=Vector2.zero
 end

 local function cardBase(name,order)
  local card=Instance.new("Frame")
  card.Name=name
  card.LayoutOrder=order
  card.BackgroundColor3=Color3.fromRGB(239,228,204)
  card.BackgroundTransparency=.22
  card.BorderSizePixel=0
  card.ZIndex=46
  corner(card,6)
  stroke(card,Color3.fromRGB(78,61,52),.42,1)
  card.Parent=scroll
  table.insert(cards,card)
  return card
 end

 local function addSlider(spec,order)
  local card=cardBase(spec.key,order)
  local name=label(card,"Label",spec.label,UDim2.new(1,-20,0,36),UDim2.fromOffset(10,4),48)
  local translations={MusicVolume="MUSIC",EffectsVolume="EFFECTS",ControlScale="CONTROL SIZE",CameraSensitivity="SENSITIVITY",CameraFOV="FIELD OF VIEW"}
  if player:GetAttribute("GameLanguage")=="en" then name.Text=translations[spec.key] or spec.label end
  name.TextSize=14
  name.TextScaled=true
  local fit=Instance.new("UITextSizeConstraint",name) fit.MinTextSize=10 fit.MaxTextSize=14
  name.Font=Enum.Font.Garamond
  name.TextXAlignment=Enum.TextXAlignment.Left
  local valueLabel=label(card,"Value","",UDim2.new(1,-20,0,18),UDim2.fromOffset(10,42),48)
  valueLabel.TextSize=15
  valueLabel.TextXAlignment=Enum.TextXAlignment.Right

  local minus=textButton(card,"Minus","−",UDim2.fromOffset(28,28),UDim2.new(0,10,1,-37),49)
  minus.TextSize=21
  local plus=textButton(card,"Plus","+",UDim2.fromOffset(28,28),UDim2.new(1,-38,1,-37),49)
  plus.TextSize=20
  local rail=Instance.new("Frame")
  rail.Name="Rail"
  rail.Position=UDim2.new(0,46,1,-27)
  rail.Size=UDim2.new(1,-92,0,7)
  rail.BackgroundColor3=Color3.fromRGB(115,94,77)
  rail.BackgroundTransparency=.48
  rail.BorderSizePixel=0
  rail.Active=true
  rail.ZIndex=48
  corner(rail,4)
  rail.Parent=card
  local fill=Instance.new("Frame")
  fill.Name="Fill"
  fill.Size=UDim2.fromScale(0,1)
  fill.BackgroundColor3=RED
  fill.BorderSizePixel=0
  fill.ZIndex=49
  corner(fill,4)
  fill.Parent=rail

  local dragging=nil
  local function current()
   return math.clamp(tonumber(ensure(player,spec.key,spec.default)) or spec.default,spec.min,spec.max)
  end
  local function apply(v)
   v=math.clamp(v,spec.min,spec.max)
   v=math.floor((v/spec.step)+.5)*spec.step
   player:SetAttribute(spec.key,v)
   valueLabel.Text=tostring(v)..(spec.suffix or "")
   fill.Size=UDim2.fromScale((v-spec.min)/(spec.max-spec.min),1)
   if spec.key=="CameraFOV" and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=v end
   if spec.key=="CameraSensitivity" then UIS.MouseDeltaSensitivity=v/100 end
  end
  local function fromX(x)
   local ratio=math.clamp((x-rail.AbsolutePosition.X)/math.max(1,rail.AbsoluteSize.X),0,1)
   apply(spec.min+(spec.max-spec.min)*ratio)
  end
  minus.Activated:Connect(function() apply(current()-spec.step) end)
  plus.Activated:Connect(function() apply(current()+spec.step) end)
  rail.InputBegan:Connect(function(input)
   if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=input fromX(input.Position.X) end
  end)
  rail.InputEnded:Connect(function(input)
   if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil end
  end)
  track(UIS.InputChanged:Connect(function(input)
   if dragging and (input==dragging or input.UserInputType==Enum.UserInputType.MouseMovement) then fromX(input.Position.X) end
  end))
  track(UIS.InputEnded:Connect(function(input)
   if input==dragging or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil end
  end))
  track(player:GetAttributeChangedSignal(spec.key):Connect(function() if card.Parent then
   local v=current() valueLabel.Text=tostring(v)..(spec.suffix or "") fill.Size=UDim2.fromScale((v-spec.min)/(spec.max-spec.min),1)
  end end))
  apply(current())
 end

 local function addToggle(nameText,key,default,order)
  local card=cardBase(key,order)
  local name=label(card,"Label",nameText,UDim2.new(1,-20,0,38),UDim2.fromOffset(10,4),48)
  name.TextSize=15 name.TextXAlignment=Enum.TextXAlignment.Left
  local b=textButton(card,"Toggle","",UDim2.fromOffset(82,34),UDim2.new(.5,-41,1,-43),49)
  local function refresh()
   local on=ensure(player,key,default)==true
   local english=player:GetAttribute("GameLanguage")=="en"
   b.Text=on and (english and "ON" or "ATIVO") or (english and "OFF" or "DESL.")
   b.BackgroundColor3=on and Color3.fromRGB(132,42,42) or Color3.fromRGB(176,159,134)
   b.TextColor3=on and Color3.fromRGB(248,231,208) or INK
  end
  b.Activated:Connect(function()
   local nextValue=not (player:GetAttribute(key)==true)
   if key=="AFK" then game.ReplicatedStorage.Survival.Action:FireServer("afk",nextValue)
   else player:SetAttribute(key,nextValue) end
   refresh()
  end)
  track(player:GetAttributeChangedSignal(key):Connect(refresh))
  refresh()
 end

 local function addLanguage(order)
  local card=cardBase("language",order)
  card.Size=UDim2.new()
  local name=label(card,"Label","IDIOMA DO JOGO",UDim2.new(1,-20,0,26),UDim2.fromOffset(10,7),48)
  name.TextSize=15 name.TextXAlignment=Enum.TextXAlignment.Left
  local pt=textButton(card,"Portuguese","PORTUGUÊS",UDim2.new(.46,0,0,34),UDim2.new(.03,0,1,-42),49)
  local en=textButton(card,"English","ENGLISH",UDim2.new(.46,0,0,34),UDim2.new(.51,0,1,-42),49)
  pt.TextSize=13 en.TextSize=13 pt.TextScaled=true en.TextScaled=true
  for _,b in ipairs({pt,en}) do local fit=Instance.new("UITextSizeConstraint",b) fit.MinTextSize=9 fit.MaxTextSize=13 end
  local function refresh()
   local lang=ensure(player,"GameLanguage","pt-BR")
   pt.BackgroundColor3=lang=="pt-BR" and RED or Color3.fromRGB(224,207,175)
   en.BackgroundColor3=lang=="en" and RED or Color3.fromRGB(224,207,175)
   pt.TextColor3=lang=="pt-BR" and Color3.fromRGB(248,231,208) or INK
   en.TextColor3=lang=="en" and Color3.fromRGB(248,231,208) or INK
  end
  pt.Activated:Connect(function() player:SetAttribute("GameLanguage","pt-BR") refresh() end)
  en.Activated:Connect(function() player:SetAttribute("GameLanguage","en") refresh() end)
  refresh()
 end

 local function addInfo(titleText,body,order)
  local card=cardBase("Info"..order,order)
  local t=label(card,"Label",titleText,UDim2.new(1,-20,0,24),UDim2.fromOffset(10,6),48)
  t.TextSize=15 t.TextXAlignment=Enum.TextXAlignment.Left
  local b=label(card,"Body",body,UDim2.new(1,-20,1,-34),UDim2.fromOffset(10,31),48)
  b.TextSize=12 b.TextColor3=MUTED b.TextXAlignment=Enum.TextXAlignment.Left b.TextYAlignment=Enum.TextYAlignment.Top
 end

 local function buildCategory(category)
  activeCategory=category
  clearCards()
  local english=player:GetAttribute("GameLanguage")=="en"
  if category=="game" then
   subtitle.Text=english and "GAME" or "JOGO"
   for i,spec in ipairs(GAME_SPECS) do addSlider(spec,i) end
   addToggle("AFK","AFK",false,7)
   addToggle(english and "BUTTON SOUNDS" or "SONS DOS BOTÕES","MenuSounds",true,8)
   addToggle(english and "FRIEND ALERTS" or "AVISOS DE AMIZADE","FriendAlerts",true,9)
   addInfo(english and "CONTROLS" or "CONTROLES",english and "Hold the run button to sprint. Crouch and action buttons remain on the right side." or "Segure o botão de correr para sprintar. Agachar e ações continuam no lado direito.",11)
  elseif category=="visual" then
   subtitle.Text="VISUAL"
   for i,spec in ipairs(VISUAL_SPECS) do addSlider(spec,i) end
   addToggle(english and "PLAYER NAMES" or "NOMES DOS JOGADORES","ShowNametags",true,10)
   addInfo(english and "NIGHT" or "NOITE",english and "The lobby keeps the authored dark-night lighting. These options do not brighten the outside map." or "O lobby mantém a iluminação noturna escura do mapa. Estas opções não clareiam a parte externa.",11)
  else
   subtitle.Text=english and "LANGUAGE" or "LINGUAGEM"
   addLanguage(1)
   addInfo(english and "INTERFACE LANGUAGE" or "IDIOMA DA INTERFACE",english and "Changes menu and HUD text. Character names and proper names stay unchanged." or "Troca os textos do menu e da HUD. Nomes de personagens e nomes próprios continuam iguais.",2)
  end
  for key,data in pairs(tabButtons) do
   if key~="close" then
    local selected=key==category
    data.tint.BackgroundTransparency=selected and .42 or 1
    data.button.TextColor3=selected and Color3.fromRGB(255,238,218) or Color3.fromRGB(220,214,202)
   end
  end
 end

 local function addRibbon(key,ptLabel,enLabel,y)
  local b=Instance.new("TextButton")
  b.Name=key=="close" and "Close" or key
  b.Position=UDim2.fromScale(.905,y)
  b.Size=UDim2.fromScale(.08,.075)
  b.BackgroundTransparency=1
  b.BorderSizePixel=0
  b.Text=""
  b:SetAttribute("AccessibleLabel",ptLabel)
  local icon=label(b,"Icon",({game="⚙",visual="◉",language="文",close="×"})[key],UDim2.fromScale(1,1),UDim2.new(),54)
  icon.Font=Enum.Font.GothamBold icon.TextScaled=true icon.TextColor3=Color3.fromRGB(245,232,213)
  local iconLimit=Instance.new("UITextSizeConstraint",icon) iconLimit.MinTextSize=14 iconLimit.MaxTextSize=27
  b.Font=Enum.Font.Garamond
  b.TextScaled=true
  b.TextColor3=Color3.fromRGB(220,214,202)
  b.TextStrokeColor3=Color3.fromRGB(23,18,18)
  b.TextStrokeTransparency=.2
  b.ZIndex=52
  b.Parent=book
  local lim=Instance.new("UITextSizeConstraint") lim.MinTextSize=8 lim.MaxTextSize=15 lim.Parent=b
  local tint=Instance.new("Frame")
  tint.Name="SelectionTint"
  tint.Size=UDim2.fromScale(1,1)
  tint.BackgroundColor3=RED
  tint.BackgroundTransparency=1
  tint.BorderSizePixel=0
  tint.ZIndex=51
  tint.Parent=b
  corner(tint,3)
  tabButtons[key]={button=b,tint=tint,pt=ptLabel,en=enLabel}
  return b
 end

 local gameTab=addRibbon("game","JOGO","GAME",.115)
 local visualTab=addRibbon("visual","VISUAL","VISUAL",.215)
 local languageTab=addRibbon("language","LINGUAGEM","LANGUAGE",.315)
 local closeTab=addRibbon("close","X","X",.415)

 gameTab.Activated:Connect(function() playPaper(1.04,.22) animatePaperTurn(-1) buildCategory("game") end)
 visualTab.Activated:Connect(function() playPaper(1.08,.22) animatePaperTurn(1) buildCategory("visual") end)
 languageTab.Activated:Connect(function() playPaper(1.12,.22) animatePaperTurn(-1) buildCategory("language") end)
 closeTab.Activated:Connect(function() playPaper(.78,.18) if onClose then onClose() else parent.Visible=false end end)

 local function refreshLanguage()
  local english=player:GetAttribute("GameLanguage")=="en"
  title.Text=english and "SETTINGS" or "CONFIGURAÇÕES"
  for key,data in pairs(tabButtons) do data.button:SetAttribute("AccessibleLabel",english and data.en or data.pt) end
  buildCategory(activeCategory)
 end
 player:GetAttributeChangedSignal("GameLanguage"):Connect(refreshLanguage)

 frame.Destroying:Connect(clearCards)
 local function fitBook()
  local s=parent.AbsoluteSize
  local aspect=1536/1024
  local w=math.min(s.X*.96,s.Y*.91*aspect)
  local h=w/aspect
  book.Size=UDim2.fromOffset(w,h)
  shadow.Size=UDim2.fromOffset(w,h)
 end
 parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitBook)
 fitBook()
 refreshLanguage()
 return frame
end

return M

-- binder publish trigger

