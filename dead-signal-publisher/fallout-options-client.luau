-- Compact in-world options: live camera stays visible, no picture and no full-screen overlay.
-- Inspired by the narrow left-aligned settings menus of cinematic FPS games.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Lighting=game:GetService('Lighting')
local SoundService=game:GetService('SoundService')
local RunService=game:GetService('RunService')
local Menu={}
local defaults={
 reticle=true,radar=true,killfeed=true,hitmarker=true,notices=true,
 aimMode='hold',buttonScale=100,buttonOpacity=85,
 brightness=50,contrast=50,saturation=50,shadows=true,performance=false,
 effectsVolume=100,musicVolume=100,dialogueVolume=100,language='pt'
}
local order={'game','controls','display','audio','language','credits'}
local dictionary={
 pt={
  options='OPÇÕES',back='VOLTAR',game='JOGO',controls='CONTROLES',display='VISUAL',audio='ÁUDIO',language='IDIOMA',credits='CRÉDITOS',
  on='Ligado',off='Desligado',hold='Segurar',toggle='Alternar',pt='Português',en='English',
  reticle='MIRA CENTRAL',radar='RADAR DA EQUIPE',killfeed='ELIMINAÇÕES',hitmarker='MARCADOR DE ACERTO',notices='AVISOS DO JOGO',
  aimMode='TIPO DE MIRA',buttonScale='BOTÕES MOBILE',buttonOpacity='VISIBILIDADE DOS BOTÕES',
  brightness='BRILHO',contrast='CONTRASTE',saturation='SATURAÇÃO',shadows='SOMBRAS',performance='MODO LEVE',
  effectsVolume='EFEITOS',musicVolume='MÚSICA',dialogueVolume='DIÁLOGOS',
  textLanguage='IDIOMA DO MENU',creditsText='CRIAÇÃO: AURIVANE WORKS',creditsGame='FPS • 5 VS 5',
  videoNote='Ajustes visuais aplicados somente à sua câmera.',controlNote='As ações básicas seguem os controles do Roblox.',
  languageNote='O idioma altera este menu. O jogo continua em português.',
  gameMode='MODO DE JOGO',gameValue='5 VS 5',saved='SALVO',saving='SALVANDO',offline='SEM SALVAR',
  reset='RESTAURAR PADRÕES',resetCategory='RESTAURAR ESTA SEÇÃO',open='CONFIGURAÇÕES',
 },
 en={
  options='OPTIONS',back='BACK',game='GAME',controls='CONTROLS',display='DISPLAY',audio='AUDIO',language='LANGUAGE',credits='CREDITS',
  on='On',off='Off',hold='Hold',toggle='Toggle',pt='Português',en='English',
  reticle='CROSSHAIR',radar='TEAM RADAR',killfeed='KILL FEED',hitmarker='HIT MARKER',notices='GAME NOTICES',
  aimMode='AIM MODE',buttonScale='MOBILE BUTTON SIZE',buttonOpacity='BUTTON VISIBILITY',
  brightness='BRIGHTNESS',contrast='CONTRAST',saturation='SATURATION',shadows='SHADOWS',performance='LIGHT MODE',
  effectsVolume='EFFECTS',musicVolume='MUSIC',dialogueVolume='DIALOGUE',
  textLanguage='MENU LANGUAGE',creditsText='CREATED BY: AURIVANE WORKS',creditsGame='FPS • 5 VS 5',
  videoNote='Display changes only affect your own camera.',controlNote='Core movement uses Roblox controls.',
  languageNote='Language changes this menu only.',gameMode='GAME MODE',gameValue='5 VS 5',
  saved='SAVED',saving='SAVING',offline='NOT SAVED',
  reset='RESET DEFAULTS',resetCategory='RESET THIS SECTION',open='SETTINGS'
 }
}
local pages={
 game={{'readonly','gameMode'},{'toggle','reticle'},{'toggle','radar'},{'toggle','killfeed'},{'toggle','hitmarker'},{'toggle','notices'}},
 controls={{'enum','aimMode',{'hold','toggle'}},{'range','buttonScale',80,110,5},{'range','buttonOpacity',30,100,5},{'note','controlNote'}},
 display={{'range','brightness',0,100,5},{'range','contrast',0,100,5},{'range','saturation',0,100,5},{'toggle','shadows'},{'toggle','performance'},{'note','videoNote'}},
 audio={{'range','effectsVolume',0,100,5},{'range','musicVolume',0,100,5},{'range','dialogueVolume',0,100,5}},
 language={{'enum','language',{'pt','en'}},{'note','languageNote'}},
 credits={{'note','creditsText'},{'note','creditsGame'}}
}
local sectionKeys={
 game={'reticle','radar','killfeed','hitmarker','notices'},
 controls={'aimMode','buttonScale','buttonOpacity'},
 display={'brightness','contrast','saturation','shadows','performance'},
 audio={'effectsVolume','musicVolume','dialogueVolume'},
 language={'language'}
}
local function make(class,parent,props)
 local inst=Instance.new(class)
 for k,v in pairs(props or {}) do inst[k]=v end
 inst.Parent=parent
 return inst
end
local function copy(value)
 local result={}
 for k,v in pairs(value) do result[k]=v end
 return result
end
local function addText(parent,value,size,position,height,color,bold)
 return make('TextLabel',parent,{
  BackgroundTransparency=1,Text=value,TextXAlignment=Enum.TextXAlignment.Left,
  TextYAlignment=Enum.TextYAlignment.Center,
  TextColor3=color or Color3.fromRGB(201,208,205),
  Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
  TextSize=height or 11,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd,
  Position=position,Size=size
 })
end
function Menu.new(args)
 local player=Players.LocalPlayer
 local values=copy(defaults)
 local modified={}
 local currentPage='home'
 local opened=false
 local saveSequence=0
 local saveStatus=''
 local originalShadows=Lighting.GlobalShadows
 local originalPost=setmetatable({},{__mode='k'})
 local originalSound=setmetatable({},{__mode='k'})
 local audioRoots={workspace,SoundService}
 local effect=Lighting:FindFirstChild('FalloutUserColorCorrection')
 if not effect then
  effect=Instance.new('ColorCorrectionEffect')
  effect.Name='FalloutUserColorCorrection'
  effect.Parent=Lighting
 end
 local gui=make('ScreenGui',player:WaitForChild('PlayerGui'),{
  Name='FalloutOptionsMenu',DisplayOrder=51,ResetOnSpawn=false,IgnoreGuiInset=true,
  ScreenInsets=Enum.ScreenInsets.None,SafeAreaCompatibility=Enum.SafeAreaCompatibility.None
 })
 local openButton=make('TextButton',gui,{
  Name='OpenOptions',Position=UDim2.fromOffset(16,62),Size=UDim2.fromOffset(99,29),
  BackgroundColor3=Color3.fromRGB(18,22,23),BackgroundTransparency=.34,
  BorderSizePixel=0,Text='OPÇÕES  ☰',TextSize=10,Font=Enum.Font.GothamBold,
  TextColor3=Color3.fromRGB(241,239,228),AutoButtonColor=true,Modal=false
 })
 make('UICorner',openButton,{CornerRadius=UDim.new(0,3)})
 local panel=make('Frame',gui,{
  Name='SmallLeftSettings',Position=UDim2.fromOffset(14,96),
  Size=UDim2.fromOffset(266,320),BackgroundTransparency=1,
  BorderSizePixel=0,Visible=false,ClipsDescendants=true
 })
 local shadow=make('Frame',panel,{
  Name='CameraOverlayGradient',Position=UDim2.fromOffset(0,0),Size=UDim2.fromScale(1,1),
  BackgroundColor3=Color3.fromRGB(3,5,6),BackgroundTransparency=.08,BorderSizePixel=0
 })
 make('UIGradient',shadow,{
  Rotation=0,
  Transparency=NumberSequence.new({
   NumberSequenceKeypoint.new(0,0),
   NumberSequenceKeypoint.new(.62,.18),
   NumberSequenceKeypoint.new(1,1)
  })
 })
 local header=addText(panel,'OPTIONS',UDim2.new(1,-30,0,28),UDim2.fromOffset(14,5),18,Color3.fromRGB(242,242,233),true)
 local hint=addText(panel,'',UDim2.new(1,-20,0,15),UDim2.fromOffset(14,33),10,Color3.fromRGB(146,158,156))
 local list=make('ScrollingFrame',panel,{
  Name='SmallOptionList',Position=UDim2.fromOffset(9,55),
  Size=UDim2.new(1,-19,1,-95),BackgroundTransparency=1,
  BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=Color3.fromRGB(180,190,183),
  CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
  ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,
 })
 local layout=make('UIListLayout',list,{FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)})
 local footer=make('TextButton',panel,{
  Name='Back',Position=UDim2.new(0,15,1,-37),Size=UDim2.new(1,-30,0,31),
  BackgroundTransparency=1,Text='‹  BACK',TextXAlignment=Enum.TextXAlignment.Left,
  Font=Enum.Font.GothamMedium,TextColor3=Color3.fromRGB(218,220,211),
  TextSize=12,AutoButtonColor=true,Modal=true
 })
 local status=addText(panel,'',UDim2.fromOffset(70,18),UDim2.new(1,-77,1,-31),9,Color3.fromRGB(146,164,156))
 status.TextXAlignment=Enum.TextXAlignment.Right
 local drag
 local t=function(key) return (dictionary[values.language] or dictionary.pt)[key] or key end

 local function classifySound(sound)
  local name=(sound.Name..' '..(sound.Parent and sound.Parent.Name or '')):lower()
  if name:find('music',1,true) or name:find('song',1,true) or name:find('bgm',1,true) or name:find('theme',1,true) then return 'musicVolume' end
  if name:find('dialog',1,true) or name:find('voice',1,true) or name:find('speech',1,true) or name:find('talk',1,true) then return 'dialogueVolume' end
  return 'effectsVolume'
 end
 local function applySound(sound)
  if not sound or not sound:IsA('Sound') then return end
  if originalSound[sound]==nil then originalSound[sound]=sound.Volume end
  sound.Volume=originalSound[sound]*(values[classifySound(sound)]/100)
 end
 local function applyVisuals()
  effect.Brightness=(values.brightness-50)/260
  effect.Contrast=(values.contrast-50)/220
  effect.Saturation=(values.saturation-50)/160
  pcall(function()Lighting.GlobalShadows=values.shadows and originalShadows or false end)
  for _,desc in ipairs(Lighting:GetDescendants()) do
   if desc:IsA('PostEffect') and desc~=effect then
    if originalPost[desc]==nil then originalPost[desc]=desc.Enabled end
    if values.performance then desc.Enabled=false else desc.Enabled=originalPost[desc] end
   end
  end
  for _,root in ipairs(audioRoots) do
   for _,inst in ipairs(root:GetDescendants()) do
    if inst:IsA('Sound') then applySound(inst) end
   end
  end
 end
 local function changed()
  applyVisuals()
  if args.onChanged then args.onChanged(copy(values)) end
 end
 local function scheduleSave()
  saveSequence+=1
  local sequence=saveSequence
  saveStatus=t('saving')
  status.Text=saveStatus
  task.delay(1.1,function()
   if saveSequence~=sequence then return end
   local ok,response=pcall(function()return args.remote:InvokeServer('SettingsSave',copy(values)) end)
   if saveSequence~=sequence then return end
   saveStatus=ok and response and response.ok and t('saved') or t('offline')
   status.Text=saveStatus
  end)
 end
 local function set(key,value,liveOnly)
  if defaults[key]==nil or values[key]==value then return end
  values[key]=value;modified[key]=true
  changed()
  if not liveOnly then scheduleSave() end
 end
 local function resize()
  local camera=workspace.CurrentCamera
  local viewport=camera and camera.ViewportSize or Vector2.new(896,414)
  local width=math.floor(math.min(270,math.max(208,viewport.X*.32)))
  local height=math.floor(math.max(205,viewport.Y-115))
  if viewport.Y<330 then height=math.max(170,viewport.Y-105) end
  panel.Size=UDim2.fromOffset(width,height)
  panel.Position=UDim2.fromOffset(viewport.X<460 and 9 or 14,viewport.Y<330 and 91 or 96)
  openButton.Position=UDim2.fromOffset(viewport.X<460 and 11 or 16,61)
 end
 local function clearRows()
  drag=nil
  for _,child in ipairs(list:GetChildren()) do
   if child~=layout then child:Destroy() end
  end
  list.CanvasPosition=Vector2.zero
 end
 local function baseRow(name,height)
  local row=make('Frame',list,{Name=name,Size=UDim2.new(1,-4,0,height),BackgroundTransparency=1,BorderSizePixel=0})
  make('Frame',row,{Name='Divider',Position=UDim2.new(0,5,1,-1),Size=UDim2.new(1,-14,0,1),BackgroundColor3=Color3.fromRGB(93,105,103),BackgroundTransparency=.74,BorderSizePixel=0})
  return row
 end
 local function optionButton(key,isCategory,action)
  local row=baseRow(key,30)
  local b=make('TextButton',row,{
   Name='Option',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
   Text='',AutoButtonColor=true,Modal=true
  })
  local left=addText(b,isCategory and t(key) or t(key),UDim2.new(.59,0,1,0),UDim2.fromOffset(5,0),11,Color3.fromRGB(202,212,210),false)
  local right=addText(b,isCategory and '›' or tostring(values[key]),UDim2.new(.41,-8,1,0),UDim2.new(.59,0,0,0),11,Color3.fromRGB(224,226,219))
  right.TextXAlignment=Enum.TextXAlignment.Right
  b.Activated:Connect(action)
  return left,right
 end
 local redraw
 local function addValue(key,kind,options)
  local left,right=optionButton(key,false,function()
   if kind=='toggle' then set(key,not values[key])
   else
    local index=table.find(options,values[key]) or 1
    set(key,options[(index%#options)+1])
   end
   redraw()
  end)
  if kind=='toggle' then right.Text=values[key] and t('on') or t('off')
  else right.Text='‹ '..t(values[key])..' ›' end
 end
 local function addRange(key,min,max,step)
  local row=baseRow(key,49)
  local title=addText(row,t(key),UDim2.new(.74,0,0,17),UDim2.fromOffset(5,0),10,Color3.fromRGB(206,215,213))
  local valueLabel=addText(row,tostring(values[key])..'%',UDim2.new(.24,-5,0,18),UDim2.new(.76,0,0,0),10,Color3.fromRGB(230,231,225))
  valueLabel.TextXAlignment=Enum.TextXAlignment.Right
  local track=make('Frame',row,{
   Name='SliderTrack',Position=UDim2.fromOffset(10,27),Size=UDim2.new(1,-22,0,3),
   BackgroundColor3=Color3.fromRGB(86,95,94),BorderSizePixel=0
  })
  local fill=make('Frame',track,{
   Name='SliderFill',Size=UDim2.fromScale((values[key]-min)/(max-min),1),
   BackgroundColor3=Color3.fromRGB(217,222,217),BorderSizePixel=0
  })
  local knob=make('Frame',track,{
   Name='SliderKnob',AnchorPoint=Vector2.new(.5,.5),
   Position=UDim2.fromScale((values[key]-min)/(max-min),.5),
   Size=UDim2.fromOffset(7,10),BackgroundColor3=Color3.fromRGB(239,239,227),
   BorderSizePixel=0
  })
  local zone=make('TextButton',row,{
   Name='SliderTouchArea',Text='',Position=UDim2.fromOffset(3,17),Size=UDim2.new(1,-6,0,29),
   BackgroundTransparency=1,BorderSizePixel=0,Modal=true
  })
  local function positionToValue(x)
   local percentage=math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
   local raw=min+(max-min)*percentage
   return math.clamp(math.floor((raw-min)/step+.5)*step+min,min,max)
  end
  local function liveAt(x)
   local nextValue=positionToValue(x)
   set(key,nextValue,true)
   valueLabel.Text=tostring(values[key])..'%'
   local percent=(values[key]-min)/(max-min)
   fill.Size=UDim2.fromScale(percent,1)
   knob.Position=UDim2.fromScale(percent,.5)
  end
  zone.InputBegan:Connect(function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
    drag={input=input,mouse=input.UserInputType==Enum.UserInputType.MouseButton1,move=liveAt}
    liveAt(input.Position.X)
   end
  end)
  zone.Activated:Connect(function()
   if not drag then scheduleSave() end
  end)
 end
 local function addNote(value)
  local row=baseRow('Note',46)
  local note=addText(row,t(value),UDim2.new(1,-12,1,-5),UDim2.fromOffset(5,1),10,Color3.fromRGB(154,164,162))
  note.TextWrapped=true;note.TextYAlignment=Enum.TextYAlignment.Top
 end
 local function addReadonly(key)
  local row=baseRow(key,32)
  addText(row,t(key),UDim2.new(.58,0,1,0),UDim2.fromOffset(5,0),11,Color3.fromRGB(205,214,212))
  local value=addText(row,t('gameValue'),UDim2.new(.4,-5,1,0),UDim2.new(.58,0,0,0),11,Color3.fromRGB(224,225,220))
  value.TextXAlignment=Enum.TextXAlignment.Right
 end
 local function addReset(page)
  if not sectionKeys[page] then return end
  local b=make('TextButton',list,{
   Name='ResetSection',Size=UDim2.new(1,-6,0,34),BackgroundTransparency=1,Text=t('resetCategory'),
   TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamMedium,TextSize=10,
   TextColor3=Color3.fromRGB(179,192,190),AutoButtonColor=true,Modal=true
  })
  b.Activated:Connect(function()
   for _,key in ipairs(sectionKeys[page]) do set(key,defaults[key],true) end
   scheduleSave()
   redraw()
  end)
 end
 redraw=function()
  clearRows()
  header.Text=t('options')
  openButton.Text=t('open')..'  ☰'
  hint.Text=currentPage=='home' and '' or t(currentPage)
  footer.Text='‹  '..t('back')
  status.Text=saveStatus
  if currentPage=='home' then
   for _,page in ipairs(order) do
    optionButton(page,true,function()
     currentPage=page
     redraw()
    end)
   end
  else
   for _,spec in ipairs(pages[currentPage] or {}) do
    if spec[1]=='toggle' then addValue(spec[2],'toggle')
    elseif spec[1]=='enum' then addValue(spec[2],'enum',spec[3])
    elseif spec[1]=='range' then addRange(spec[2],spec[3],spec[4],spec[5])
    elseif spec[1]=='note' then addNote(spec[2])
    elseif spec[1]=='readonly' then addReadonly(spec[2]) end
   end
   addReset(currentPage)
  end
 end
 function Menu:setOpen(value)
  opened=value==true
  panel.Visible=opened
  openButton.Modal=opened
  if opened then resize();redraw() end
  if args.onToggle then args.onToggle(opened) end
 end
 function Menu:isOpen() return opened end
 function Menu:get(key) return values[key] end
 function Menu:values() return copy(values) end
 openButton.Activated:Connect(function()Menu:setOpen(not opened) end)
 footer.Activated:Connect(function()
  if currentPage=='home' then Menu:setOpen(false)
  else currentPage='home';redraw() end
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if processed then return end
  if input.KeyCode==Enum.KeyCode.F10 or input.KeyCode==Enum.KeyCode.O then Menu:setOpen(not opened) end
 end)
 UIS.InputChanged:Connect(function(input)
  if drag and (input==drag.input or (drag.mouse and input.UserInputType==Enum.UserInputType.MouseMovement)) then
   drag.move(input.Position.X)
  end
 end)
 UIS.InputEnded:Connect(function(input)
  if drag and (input==drag.input or (drag.mouse and input.UserInputType==Enum.UserInputType.MouseButton1)) then
   drag=nil
   scheduleSave()
  end
 end)
 local lastViewport=Vector2.zero
 RunService.RenderStepped:Connect(function()
  local camera=workspace.CurrentCamera
  if camera and camera.ViewportSize~=lastViewport then
   lastViewport=camera.ViewportSize
   resize()
  end
 end)
 for _,root in ipairs(audioRoots) do
  root.DescendantAdded:Connect(function(object)
   if object:IsA('Sound') then task.defer(function()if object.Parent then applySound(object) end end) end
  end)
 end
 Lighting.DescendantAdded:Connect(function(item)
  if item:IsA('PostEffect') and item~=effect then
   task.defer(function()
    if item.Parent then
     originalPost[item]=item.Enabled
     if values.performance then item.Enabled=false end
    end
   end)
  end
 end)
 task.spawn(function()
  local ok,response=pcall(function()return args.remote:InvokeServer('SettingsGet') end)
  if ok and response and response.ok and type(response.settings)=='table' then
   for key,value in pairs(response.settings) do
    if defaults[key]~=nil and not modified[key] and type(value)==type(defaults[key]) then
     values[key]=value
    end
   end
   changed()
   if next(modified) then scheduleSave() end
   if opened then redraw() end
  end
 end)
 changed()
 resize()
 return Menu
end
return Menu
