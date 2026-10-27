local M={}
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local initialized=setmetatable({},{__mode="k"})

local PANEL=Color3.fromRGB(13,14,17)
local ROW=Color3.fromRGB(18,19,22)
local TEXT=Color3.fromRGB(238,238,238)
local MUTED=Color3.fromRGB(170,172,178)
local LINE=Color3.fromRGB(152,154,160)
local ACCENT=Color3.fromRGB(236,236,232)
local DEFAULTS={MusicVolume=65,EffectsVolume=80,MenuSounds=true,FriendAlerts=true,AFK=false,CameraFOV=62,ControlScale=100,ShowNametags=true,CameraSensitivity=100,GameLanguage="pt-BR"}

local function corner(parent,r)
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 3) c.Parent=parent return c
end
local function stroke(parent,color,transparency,thickness)
 local s=Instance.new("UIStroke") s.Color=color or LINE s.Transparency=transparency or .35 s.Thickness=thickness or 1 s.Parent=parent return s
end
local function text(parent,name,value,size,pos,z)
 local l=Instance.new("TextLabel")
 l.Name=name l.BackgroundTransparency=1 l.Text=value l.Size=size l.Position=pos or UDim2.new()
 l.Font=Enum.Font.Gotham l.TextColor3=TEXT l.TextSize=14 l.TextXAlignment=Enum.TextXAlignment.Left
 l.TextYAlignment=Enum.TextYAlignment.Center l.ZIndex=z or 45 l.Parent=parent
 return l
end
local function button(parent,name,value,size,pos,z)
 local b=Instance.new("TextButton")
 b.Name=name b.Text=value b.Size=size b.Position=pos or UDim2.new()
 b.BackgroundColor3=ROW b.BackgroundTransparency=.18 b.BorderSizePixel=0
 b.Font=Enum.Font.Gotham b.TextColor3=TEXT b.TextSize=14
 b.AutoButtonColor=false b.ZIndex=z or 46 b.Parent=parent
 corner(b,2) stroke(b,LINE,.55,1)
 return b
end
local function ensure(player,key,default)
 local v=player:GetAttribute(key)
 if v==nil then player:SetAttribute(key,default) return default end
 return v
end

function M.initialize(player)
 if initialized[player] then return end
 initialized[player]=true
 if player:GetAttribute("GameLanguage")==nil then
  local locale=tostring(player.LocaleId or "en"):lower()
  player:SetAttribute("GameLanguage",locale:sub(1,2)=="pt" and "pt-BR" or "en")
 end
 for key,value in pairs(DEFAULTS) do
  if key~="GameLanguage" and player:GetAttribute(key)==nil then player:SetAttribute(key,value) end
 end
 local music=SoundService:FindFirstChild("SuviversMusic") or Instance.new("SoundGroup",SoundService)
 music.Name="SuviversMusic"
 local function applyMusic() music.Volume=(player:GetAttribute("MusicVolume") or 65)/100 end
 player:GetAttributeChangedSignal("MusicVolume"):Connect(applyMusic) applyMusic()
 local effects=SoundService:FindFirstChild("SuviversEffects") or Instance.new("SoundGroup",SoundService)
 effects.Name="SuviversEffects"
 local function applyEffects() effects.Volume=(player:GetAttribute("EffectsVolume") or 80)/100 end
 player:GetAttributeChangedSignal("EffectsVolume"):Connect(applyEffects) applyEffects()
 local function bind(o)
  if o:IsA("Sound") and o.Name=="SuviversMatchMusic" then o.SoundGroup=music end
  if o:IsA("Sound") and (o.Name=="MenuClick" or o.Name=="Click" or o.Name=="PlayClick" or o.Name=="FriendJoined" or o.Name=="Regenerate" or o.Name=="RegenerationCue" or o.Name=="SettingsOpenSound") then
   o.SoundGroup=effects
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
 frame.Name="CinematicSettings"
 frame.Size=UDim2.fromScale(1,1)
 frame.BackgroundTransparency=1
 frame.BorderSizePixel=0
 frame.ZIndex=41
 frame:SetAttribute("Style","CinematicSideSettings")
 frame:SetAttribute("ReferenceLayout","AssassinMenuInspired")
 frame:SetAttribute("FrozenCameraBackdrop",true)
 frame.Parent=parent

 local root=Instance.new("Frame")
 root.Name="SettingsRoot"
 root.AnchorPoint=Vector2.new(.5,.5)
 root.Position=UDim2.fromScale(.5,.5)
 root.Size=UDim2.fromScale(.9,.76)
 root.BackgroundTransparency=1
 root.ZIndex=42
 root.Parent=frame
 local limit=Instance.new("UISizeConstraint",root)
 limit.MaxSize=Vector2.new(1120,650)
 limit.MinSize=Vector2.new(320,300)

 local back=button(root,"Back","‹  CONFIGURAÇÕES",UDim2.new(.24,0,0,42),UDim2.fromScale(0,0),48)
 back.BackgroundTransparency=1
 back.TextXAlignment=Enum.TextXAlignment.Left
 back.TextSize=16
 back.UIStroke.Enabled=false

 local nav=Instance.new("Frame")
 nav.Name="CategoryRail"
 nav.Position=UDim2.new(0,0,0,76)
 nav.Size=UDim2.new(.24,0,1,-98)
 nav.BackgroundTransparency=1
 nav.ZIndex=43
 nav.Parent=root
 local navList=Instance.new("UIListLayout",nav)
 navList.Padding=UDim.new(0,7)
 navList.SortOrder=Enum.SortOrder.LayoutOrder

 local panel=Instance.new("Frame")
 panel.Name="OptionsPanel"
 panel.Position=UDim2.new(.29,0,.07,0)
 panel.Size=UDim2.new(.69,0,.86,0)
 panel.BackgroundColor3=PANEL
 panel.BackgroundTransparency=.15
 panel.BorderSizePixel=0
 panel.ZIndex=43
 panel.Parent=root
 stroke(panel,Color3.fromRGB(110,112,118),.55,1)
 local gradient=Instance.new("UIGradient",panel)
 gradient.Rotation=90
 gradient.Color=ColorSequence.new(Color3.fromRGB(20,21,24),Color3.fromRGB(8,9,11))
 gradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(1,.22)})

 local heading=text(panel,"Heading","GRÁFICOS",UDim2.new(1,-28,0,42),UDim2.fromOffset(14,6),46)
 heading.Font=Enum.Font.Garamond
 heading.TextSize=18
 local headingLine=Instance.new("Frame",panel)
 headingLine.Position=UDim2.fromOffset(14,48)
 headingLine.Size=UDim2.new(1,-28,0,1)
 headingLine.BackgroundColor3=LINE
 headingLine.BackgroundTransparency=.45
 headingLine.BorderSizePixel=0
 headingLine.ZIndex=46

 local scroll=Instance.new("ScrollingFrame")
 scroll.Name="OptionsScroll"
 scroll.Position=UDim2.fromOffset(14,58)
 scroll.Size=UDim2.new(1,-28,1,-72)
 scroll.BackgroundTransparency=1
 scroll.BorderSizePixel=0
 scroll.ScrollBarThickness=3
 scroll.ScrollBarImageColor3=Color3.fromRGB(225,225,225)
 scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
 scroll.CanvasSize=UDim2.new()
 scroll.ZIndex=45
 scroll.Parent=panel
 local layout=Instance.new("UIListLayout",scroll)
 layout.Padding=UDim.new(0,5)
 layout.SortOrder=Enum.SortOrder.LayoutOrder
 local pad=Instance.new("UIPadding",scroll)
 pad.PaddingBottom=UDim.new(0,8)
 pad.PaddingRight=UDim.new(0,4)

 local click=Instance.new("Sound")
 click.Name="SettingsOpenSound"
 click.SoundId="rbxassetid://6102885802"
 click.Volume=.2
 click.PlaybackSpeed=1.08
 click.SoundGroup=SoundService:FindFirstChild("SuviversEffects")
 click.Parent=SoundService
 local function sound(speed)
  if player:GetAttribute("MenuSounds")==false then return end
  click:Stop()
  click.TimePosition=0
  click.PlaybackSpeed=speed or 1.08
  pcall(function() click:Play() end)
 end

 local connections={}
 local function track(c) table.insert(connections,c) return c end
 track(parent:GetPropertyChangedSignal("Visible"):Connect(function()
  if parent.Visible then sound(.88) end
 end))

 local function clearRows()
  for _,child in ipairs(scroll:GetChildren()) do
   if child:IsA("GuiObject") then child:Destroy() end
  end
 end
 local function makeRow(name,order,height)
  local row=Instance.new("Frame")
  row.Name=name
  row.LayoutOrder=order
  row.Size=UDim2.new(1,-4,0,height or 48)
  row.BackgroundColor3=ROW
  row.BackgroundTransparency=.32
  row.BorderSizePixel=0
  row.ZIndex=46
  row.Parent=scroll
  stroke(row,LINE,.68,1)
  return row
 end
 local function addLabel(row,value)
  local l=text(row,"Label",value,UDim2.new(.52,-12,1,0),UDim2.fromOffset(10,0),47)
  l.TextSize=13
  return l
 end
 local function addSlider(labelText,key,min,max,step,suffix,order)
  local row=makeRow(key,order,52)
  addLabel(row,labelText)
  local value=text(row,"Value","",UDim2.new(.18,0,1,0),UDim2.new(.52,0,0,0),47)
  value.TextXAlignment=Enum.TextXAlignment.Right
  value.TextSize=12
  local rail=Instance.new("TextButton",row)
  rail.Name="Rail"
  rail.Text=""
  rail.Position=UDim2.new(.72,10,.5,-3)
  rail.Size=UDim2.new(.25,-18,0,6)
  rail.BackgroundColor3=Color3.fromRGB(88,89,94)
  rail.BorderSizePixel=0
  rail.AutoButtonColor=false
  rail.ZIndex=48
  corner(rail,3)
  local fill=Instance.new("Frame",rail)
  fill.Name="Fill"
  fill.Size=UDim2.fromScale(0,1)
  fill.BackgroundColor3=ACCENT
  fill.BorderSizePixel=0
  fill.ZIndex=49
  corner(fill,3)
  local dragging=false
  local function current()
   return math.clamp(tonumber(ensure(player,key,DEFAULTS[key] or min)) or min,min,max)
  end
  local function apply(v)
   v=math.clamp(v,min,max)
   v=math.floor((v/step)+.5)*step
   player:SetAttribute(key,v)
   value.Text=tostring(v)..(suffix or "")
   fill.Size=UDim2.fromScale((v-min)/(max-min),1)
   if key=="CameraFOV" and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=v end
   if key=="CameraSensitivity" then UIS.MouseDeltaSensitivity=v/100 end
  end
  local function fromX(x)
   apply(min+(max-min)*math.clamp((x-rail.AbsolutePosition.X)/math.max(1,rail.AbsoluteSize.X),0,1))
  end
  rail.InputBegan:Connect(function(input)
   if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
    dragging=true
    fromX(input.Position.X)
   end
  end)
  rail.InputEnded:Connect(function(input)
   if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
  end)
  track(UIS.InputChanged:Connect(function(input)
   if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
    fromX(input.Position.X)
   end
  end))
  track(player:GetAttributeChangedSignal(key):Connect(function()
   if row.Parent then apply(current()) end
  end))
  apply(current())
 end
 local function addToggle(labelText,key,default,order)
  local row=makeRow(key,order,48)
  addLabel(row,labelText)
  local b=button(row,"Toggle","",UDim2.fromOffset(100,30),UDim2.new(1,-112,.5,-15),48)
  local function refresh()
   local on=ensure(player,key,default)==true
   b.Text=on and "‹  LIGADO  ›" or "‹ DESLIGADO ›"
   b.TextColor3=on and TEXT or MUTED
  end
  b.Activated:Connect(function()
   sound(1.14)
   player:SetAttribute(key,not (player:GetAttribute(key)==true))
   refresh()
  end)
  track(player:GetAttributeChangedSignal(key):Connect(refresh))
  refresh()
 end
 local function addLanguage(order)
  local row=makeRow("Language",order,48)
  addLabel(row,"IDIOMA")
  local b=button(row,"Value","",UDim2.fromOffset(154,30),UDim2.new(1,-166,.5,-15),48)
  local function refresh()
   b.Text=player:GetAttribute("GameLanguage")=="en" and "‹  ENGLISH  ›" or "‹ PORTUGUÊS ›"
  end
  b.Activated:Connect(function()
   sound(1.14)
   player:SetAttribute("GameLanguage",player:GetAttribute("GameLanguage")=="en" and "pt-BR" or "en")
   refresh()
  end)
  track(player:GetAttributeChangedSignal("GameLanguage"):Connect(refresh))
  refresh()
 end
 local function addInfo(labelText,valueText,order)
  local row=makeRow("Info"..order,order,48)
  addLabel(row,labelText)
  local v=text(row,"Value",valueText,UDim2.new(.42,-12,1,0),UDim2.new(.58,0,0,0),47)
  v.TextXAlignment=Enum.TextXAlignment.Right
  v.TextColor3=MUTED
  v.TextSize=12
 end

 local categories={
  {key="graphics",pt="GRÁFICOS",en="GRAPHICS",build=function()
   addInfo("MODO DE EXIBIÇÃO","ROBLOX",1)
   addSlider("CAMPO DE VISÃO","CameraFOV",50,90,1,"°",2)
   addInfo("QUALIDADE","AUTOMÁTICA",3)
  end},
  {key="audio",pt="ÁUDIO",en="AUDIO",build=function()
   addSlider("MÚSICA","MusicVolume",0,100,5,"%",1)
   addSlider("EFEITOS","EffectsVolume",0,100,5,"%",2)
   addToggle("SONS DOS BOTÕES","MenuSounds",true,3)
  end},
  {key="controls",pt="CONTROLES",en="CONTROLS",build=function()
   addSlider("SENSIBILIDADE","CameraSensitivity",50,160,5,"%",1)
   addSlider("ESCALA DOS CONTROLES","ControlScale",80,120,5,"%",2)
  end},
  {key="gameplay",pt="JOGABILIDADE",en="GAMEPLAY",build=function()
   addToggle("MODO AFK","AFK",false,1)
   addToggle("AVISOS DE AMIGOS","FriendAlerts",true,2)
  end},
  {key="interface",pt="INTERFACE",en="INTERFACE",build=function()
   addToggle("NOMES DOS JOGADORES","ShowNametags",true,1)
   addLanguage(2)
  end},
 }

 local navButtons={}
 local activeKey="graphics"
 local function selectCategory(spec)
  activeKey=spec.key
  clearRows()
  heading.Text=player:GetAttribute("GameLanguage")=="en" and spec.en or spec.pt
  spec.build()
  for key,data in pairs(navButtons) do
   local selected=key==spec.key
   data.button.BackgroundTransparency=selected and .04 or .42
   data.button.TextColor3=selected and Color3.fromRGB(255,255,255) or Color3.fromRGB(188,190,196)
   data.button.UIStroke.Transparency=selected and .08 or .66
  end
 end
 for i,spec in ipairs(categories) do
  local b=button(nav,spec.key,spec.pt,UDim2.new(1,0,0,42),UDim2.new(),46)
  b.LayoutOrder=i
  b.TextXAlignment=Enum.TextXAlignment.Left
  b.TextSize=13
  local p=Instance.new("UIPadding",b)
  p.PaddingLeft=UDim.new(0,14)
  navButtons[spec.key]={button=b,spec=spec}
  b.Activated:Connect(function()
   sound(1.08)
   selectCategory(spec)
  end)
 end

 local reset=button(nav,"Reset","RESTAURAR PADRÃO",UDim2.new(1,0,0,38),UDim2.new(),46)
 reset.LayoutOrder=99
 reset.TextSize=11
 reset.TextColor3=MUTED
 reset.Activated:Connect(function()
  sound(.92)
  for key,value in pairs(DEFAULTS) do player:SetAttribute(key,value) end
  for _,spec in ipairs(categories) do
   if spec.key==activeKey then selectCategory(spec) break end
  end
 end)

 back.Activated:Connect(function()
  sound(.86)
  if onClose then onClose() else parent.Visible=false end
 end)

 local function refreshLanguage()
  local english=player:GetAttribute("GameLanguage")=="en"
  back.Text=english and "‹  SETTINGS" or "‹  CONFIGURAÇÕES"
  reset.Text=english and "RESTORE DEFAULT" or "RESTAURAR PADRÃO"
  for _,data in pairs(navButtons) do
   data.button.Text=english and data.spec.en or data.spec.pt
  end
  for _,spec in ipairs(categories) do
   if spec.key==activeKey then selectCategory(spec) break end
  end
 end
 track(player:GetAttributeChangedSignal("GameLanguage"):Connect(refreshLanguage))
 frame.Destroying:Connect(function()
  for _,c in ipairs(connections) do c:Disconnect() end
  if click.Parent then click:Destroy() end
 end)
 refreshLanguage()
 return frame
end

return M
