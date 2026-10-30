local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Tween=game:GetService('TweenService');local Lighting=game:GetService('Lighting');local Sound=game:GetService('SoundService')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui');local M={};local schema=require(RS.SettingsSchema)
M.Settings=table.clone(schema.Defaults);M.Loaded=false;M.Dirty=false
function M.Make(class,props,parent) local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o end
local make=M.Make
function M.List(parent)
 local sc=make('ScrollingFrame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(150,160,156),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},parent)
 make('UIPadding',{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,10)},sc)
 make('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},sc);return sc
end
function M.Button(parent,text,fn)
 local b=make('TextButton',{Size=UDim2.new(1,0,0,44),Text=text,TextWrapped=true,Font=Enum.Font.Garamond,TextSize=21,TextColor3=Color3.fromRGB(178,185,178),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0},parent)
 local function select(on) b.TextColor3=on and Color3.fromRGB(247,244,223) or Color3.fromRGB(178,185,178);b.BackgroundTransparency=on and .88 or 1 end
 b.MouseEnter:Connect(function() select(true) end);b.MouseLeave:Connect(function() select(false) end);b.SelectionGained:Connect(function() select(true) end);b.SelectionLost:Connect(function() select(false) end);b.Activated:Connect(fn);return b
end
function M.Label(parent,text,height)
 return make('TextLabel',{Size=UDim2.new(1,0,0,height or 52),Text=text,TextWrapped=true,Font=Enum.Font.Garamond,TextSize=18,TextColor3=Color3.fromRGB(188,195,187),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},parent)
end
local opened
function M.Panel(title)
 if opened then opened.Close() end
 if workspace:GetAttribute('GameMode')=='Menu' and player:GetAttribute('MenuCameraMode')~='starting' then player:SetAttribute('MenuCameraMode','close') end
 local gui=make('ScreenGui',{Name='SidePanel',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=1500,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
 make('TextButton',{Size=UDim2.fromScale(1,1),Text='',Modal=true,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.80,AutoButtonColor=false,BorderSizePixel=0},gui)
 local pane=make('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(1.5,.5),Size=UDim2.fromScale(.55,.86),BackgroundColor3=Color3.fromRGB(9,17,18),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true},gui)
 -- Only the options column has a dark panel; the scenery remains visible.
 local heading=M.Label(pane,title,46);heading.Position=UDim2.new(.02,0,0,4);heading.Size=UDim2.new(.40,0,0,50);heading.Font=Enum.Font.Oswald;heading.TextScaled=true;heading.TextXAlignment=Enum.TextXAlignment.Right;make('UITextSizeConstraint',{MinTextSize=14,MaxTextSize=42},heading)
 local content=make('Frame',{Position=UDim2.new(.025,0,0,56),Size=UDim2.new(.95,0,1,-118),BackgroundTransparency=1},pane)
 local footer=make('Frame',{Position=UDim2.new(.035,0,1,-53),Size=UDim2.new(.93,0,0,45),BackgroundTransparency=1},pane)
 local status=M.Label(footer,'',44);status.Size=UDim2.fromScale(.64,1);status.TextSize=15
 local controls
 if workspace:GetAttribute('GameMode')=='Match' then pcall(function() controls=require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls();controls:Disable() end) end
 player:SetAttribute('InterfaceOpen',true)
 local obj={Gui=gui,Content=content,Footer=footer,Status=status}
 function obj.Close()
  if not gui.Parent then return end
  gui:Destroy();if controls then controls:Enable() end;player:SetAttribute('InterfaceOpen',false)
  if workspace:GetAttribute('GameMode')=='Menu' and player:GetAttribute('MenuCameraMode')~='starting' then player:SetAttribute('MenuCameraMode','wide') end
  if opened==obj then opened=nil end
 end
 local close=M.Button(footer,'VOLTAR',obj.Close);close.Position=UDim2.fromScale(.68,0);close.Size=UDim2.fromScale(.32,1)
 obj.Back=close;obj.Pane=pane;opened=obj
 -- Screen-aware side sheet: never spills beyond a portrait or landscape viewport.
 -- Leave the 3D cinematic visible to the left on wide landscape devices.
 local viewportConnection
 local function fitPanel(animate)
  if not gui.Parent then return end
  local camera=workspace.CurrentCamera
  local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
  local portrait=viewport.Y>viewport.X
  local compact=viewport.X<1000
  local width=portrait and .94 or compact and .79 or .57
  local center=portrait and .50 or (1-width/2-.025)
  local height=portrait and .87 or .86
  pane.Size=UDim2.fromScale(width,height)
  local destination=UDim2.fromScale(center,.50)
  if animate then
   Tween:Create(pane,TweenInfo.new(.31,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=destination}):Play()
  else pane.Position=destination end
 end
 fitPanel(true)
 local camera=workspace.CurrentCamera
 if camera then
  viewportConnection=camera:GetPropertyChangedSignal('ViewportSize'):Connect(function() fitPanel(false) end)
 end
 gui.Destroying:Connect(function() if viewportConnection then viewportConnection:Disconnect() end end)
 return obj
end
local master=make('SoundGroup',{Name='StillHereMaster',Volume=.8},Sound)
local groupVolumes=setmetatable({},{__mode='k'})
local function audio(o)
 if o:IsA('SoundGroup') and o~=master and o.Parent==Sound then groupVolumes[o]=groupVolumes[o] or o.Volume;o.Volume=groupVolumes[o]*M.Settings.volume
 elseif o:IsA('Sound') and not o.SoundGroup then o.SoundGroup=master end
end
for _,o in ipairs(game:GetDescendants()) do audio(o) end
game.DescendantAdded:Connect(audio)
local correction=make('ColorCorrectionEffect',{Name='PlayerBrightness'},Lighting)
local bloomOriginal=setmetatable({},{__mode='k'})
-- When the menu has been removed for a match, re-apply the player's saved
-- graphics preferences rather than allowing the cinematic overrides to leak.
workspace:GetAttributeChangedSignal('GameMode'):Connect(function()
 if M.Loaded then task.defer(function() if player.Parent then M.Apply() end end) end
end)
function M.Apply()
 local s=M.Settings;master.Volume=s.volume;for group,volume in pairs(groupVolumes) do if group.Parent then group.Volume=volume*s.volume end end
 -- MENU IS CINEMATIC: saved graphics options affect only the game match.
 -- The local menu uses the creator's high-quality light/shadow/Bloom setup.
 -- Roblox device-level graphics quality may still disable expensive effects.
 local cinematicMenu=workspace:GetAttribute('GameMode')=='Menu'
 correction.Brightness=cinematicMenu and 0 or (s.brightness-.5)*.3
 Lighting.GlobalShadows=cinematicMenu or s.shadows
 for _,e in ipairs(Lighting:GetChildren()) do
  if e:IsA('BloomEffect') then
   if bloomOriginal[e]==nil then bloomOriginal[e]=e.Enabled end
   e.Enabled=cinematicMenu or (s.bloom and bloomOriginal[e])
  end
 end
 game:GetService('UserInputService').MouseDeltaSensitivity=s.sensitivity
 player:SetAttribute('ShowObjectives',s.objectives);player:SetAttribute('PreferredFOV',s.fov);player:SetAttribute('LoadingHints',s.loadingHints)
 if workspace.CurrentCamera and workspace.CurrentCamera.CameraType~=Enum.CameraType.Scriptable then workspace.CurrentCamera.FieldOfView=s.fov end
end
local loading=false
function M.Load()
 while loading do task.wait(.1) end
 if M.Loaded then return true end;loading=true
 local ok,result=pcall(function() return RS:WaitForChild('PlayerSettings'):InvokeServer('get') end);loading=false
 if ok and result.ok then M.Settings=schema.Clean(result.settings);M.Loaded=true;M.Apply();return true end
 return false
end
function M.Save()
 if not M.Dirty then return true end
 if not M.Loaded then return false,'Não foi possível carregar as configurações.' end
 local ok,r=pcall(function() return RS.PlayerSettings:InvokeServer('save',M.Settings) end)
 if ok and r.ok then M.Dirty=false;return true end
 return false,ok and r.message or 'Falha ao salvar. Tente novamente.'
end
function M.OpenSettings()
 local initial=M.Loaded and table.clone(M.Settings) or nil
 local panel=M.Panel('CONFIGURAÇÕES')
 -- A proper editorial settings sheet, not giant floating text over the scene.
 panel.Pane.BackgroundTransparency=.10
 panel.Pane.BackgroundColor3=Color3.fromRGB(11,17,21)
 make('UICorner',{CornerRadius=UDim.new(0,10)},panel.Pane)
 make('UIStroke',{Color=Color3.fromRGB(99,113,122),Transparency=.47,Thickness=1},panel.Pane)
 make('UIGradient',{
  Rotation=90,
  Color=ColorSequence.new(Color3.fromRGB(22,30,35),Color3.fromRGB(6,12,17)),
  Transparency=NumberSequence.new(.04,.14)
 },panel.Pane)
 panel.Pane:FindFirstChildWhichIsA('UIStroke').Enabled=true
 panel.Pane.ClipsDescendants=false
 local titleText=panel.Pane:FindFirstChildWhichIsA('TextLabel')
 if titleText then
  titleText.Text='CONFIGURAÇÕES'
  titleText.Font=Enum.Font.RobotoCondensed
  titleText.TextSize=18;titleText.TextScaled=false
  titleText.TextXAlignment=Enum.TextXAlignment.Left
  titleText.Position=UDim2.new(0,20,0,8)
  titleText.Size=UDim2.new(1,-40,0,29)
  titleText.TextColor3=Color3.fromRGB(231,232,225)
 end
 local titleDivider=make('Frame',{
  Name='SettingsHeaderDivider',Position=UDim2.new(0,20,0,52),
  Size=UDim2.new(1,-40,0,1),BorderSizePixel=0,
  BackgroundColor3=Color3.fromRGB(81,92,101),BackgroundTransparency=.46
 },panel.Pane)

 local categoryStack=make('Frame',{
  Name='OptionCategoryStack',
  Position=UDim2.fromScale(0,0),
  Size=UDim2.fromScale(.395,1),
  BackgroundTransparency=1
 },panel.Content)
 local tabs=M.List(categoryStack)
 tabs.Name='SettingsCategoryScroll'
 tabs.ScrollBarThickness=2
 tabs.UIListLayout.Padding=UDim.new(0,7)
 local caption=M.Label(tabs,'CATEGORIAS',28)
 caption.Name='OptionsPath'
 caption.LayoutOrder=-5
 caption.TextXAlignment=Enum.TextXAlignment.Left
 caption.Font=Enum.Font.RobotoCondensed
 caption.TextSize=11
 caption.TextColor3=Color3.fromRGB(167,181,188)
 local right=make('Frame',{
  Name='OptionsHalf',
  Position=UDim2.fromScale(.415,0),
  Size=UDim2.fromScale(.585,1),
  BackgroundColor3=Color3.fromRGB(10,17,23),
  BackgroundTransparency=.22,
  BorderSizePixel=0,
  ClipsDescendants=true
 },panel.Content)
 make('UIStroke',{Color=Color3.fromRGB(77,95,105),Transparency=.60,Thickness=1},right)
 local sectionHeading=M.Label(right,'VÍDEO',33)
 sectionHeading.Name='ActiveSettingsCategory'
 sectionHeading.Position=UDim2.new(0,12,0,10)
 sectionHeading.Size=UDim2.new(1,-24,0,31)
 sectionHeading.Font=Enum.Font.RobotoCondensed
 sectionHeading.TextXAlignment=Enum.TextXAlignment.Left
 sectionHeading.TextSize=21
 sectionHeading.TextColor3=Color3.fromRGB(234,235,229)
 local accent=make('Frame',{
  Name='SettingsRedAccent',Position=UDim2.new(0,12,0,47),
  Size=UDim2.new(0,33,0,2),
  BackgroundColor3=Color3.fromRGB(183,46,57),BorderSizePixel=0
 },right)
 local rows=M.List(right)
 rows.Name='SettingsValuesScroll'
 rows.Position=UDim2.new(0,9,0,60)
 rows.Size=UDim2.new(1,-18,1,-71)
 rows.ScrollBarThickness=3
 rows.UIListLayout.Padding=UDim.new(0,7)

 local groups={
  {'VÍDEO',{{'Campo de visão','fov',60,90,5,'Altera a visão durante a partida.'}}},
  {'CALIBRAÇÃO',{{'Brilho','brightness',0,1,.1,'Ajusta a luminosidade da imagem.'}}},
  {'QUALIDADE',{{'Sombras','shadows',nil,nil,nil,'Sombras dinâmicas durante a partida.'},
                 {'Bloom','bloom',nil,nil,nil,'Pós-processamento durante a partida.'}}},
  {'CONTROLES',{{'Sensibilidade','sensitivity',.2,2,.2,'Velocidade do movimento da câmera.'}}},
  {'JOGABILIDADE',{{'Objetivos','objectives',nil,nil,nil,'Exibe os objetivos na interface.'},
                   {'Dicas no carregamento','loadingHints',nil,nil,nil,'Exibe dicas nas telas de carregamento.'}}},
  {'ÁUDIO',{{'Volume geral','volume',0,1,.1,'Volume dos efeitos, ambiente e menu.'}}}
 }
 local tabsByName={}
 local selected
 local busy=false
 local closed=false
 local function valueText(key)
  local v=M.Settings[key]
  if typeof(v)=='boolean' then return v and 'ATIVADO' or 'DESATIVADO' end
  if key=='volume' or key=='brightness' then return tostring(math.floor(v*100+.5))..'%' end
  if key=='fov' then return tostring(math.floor(v+.5))..'°' end
  return string.format('%.1f',v)
 end
 local function canAdjust()
  if M.Loaded then return true end
  panel.Status.Text='As preferências ainda não foram carregadas.'
  return false
 end
 local function changeValue(spec,direction)
  if not canAdjust() then return end
  local key=spec[2]
  local old=M.Settings[key]
  if typeof(old)=='boolean' then M.Settings[key]=not old
  else
   local min,max,step=spec[3],spec[4],spec[5]
   local rounded=math.round(((old+direction*step)-min)/step)*step+min
   M.Settings[key]=math.clamp(math.floor(rounded*100+.5)/100,min,max)
  end
  M.Dirty=true
  M.Apply()
  panel.Status.Text='Alterações não salvas.'
 end
 local function drawSettings(group)
  if closed or not panel.Gui.Parent then return end
  selected=group[1]
  if group[1]=='QUALIDADE' then
   panel.Status.Text='A qualidade do menu permanece cinematográfica.'
  else
   panel.Status.Text='Alterações são aplicadas ao entrar na partida.'
  end
  caption.Text='CONFIGURAÇÕES'
  sectionHeading.Text=group[1]
  for name,tab in pairs(tabsByName) do
   local active=name==selected
   Tween:Create(tab.button,TweenInfo.new(.16),{
    TextColor3=active and Color3.fromRGB(244,242,235) or Color3.fromRGB(159,166,172)
   }):Play()
   Tween:Create(tab.mark,TweenInfo.new(.16),{
    BackgroundTransparency=active and 0 or 1
   }):Play()
  end
  for _,o in ipairs(rows:GetChildren()) do
   if o:IsA('GuiObject') then o:Destroy() end
  end
  for i,spec in ipairs(group[2]) do
   local boolean=typeof(M.Settings[spec[2]])=='boolean'
   local height=boolean and 73 or 99
   local row=make('Frame',{
    Name='Setting_'..spec[2],LayoutOrder=i,
    Size=UDim2.new(1,-5,0,height),
    BackgroundColor3=Color3.fromRGB(22,30,36),
    BackgroundTransparency=.30,BorderSizePixel=0
   },rows)
   make('UICorner',{CornerRadius=UDim.new(0,5)},row)
   local name=M.Label(row,string.upper(spec[1]),24)
   name.Name='SettingName'
   name.Position=UDim2.new(0,11,0,8)
   name.Size=UDim2.new(.73,-11,0,24)
   name.Font=Enum.Font.RobotoCondensed
   name.TextSize=15
   name.TextXAlignment=Enum.TextXAlignment.Left
   name.TextColor3=Color3.fromRGB(220,229,228)
   local hint=M.Label(row,spec[6] or '',33)
   hint.Name='SettingDescription'
   hint.Position=UDim2.new(0,11,0,33)
   hint.Size=UDim2.new(boolean and .68 or .80,-11,0,32)
   hint.Font=Enum.Font.Gotham
   hint.TextSize=10
   hint.TextColor3=Color3.fromRGB(149,163,170)
   hint.TextXAlignment=Enum.TextXAlignment.Left
   if boolean then
    local toggle=make('TextButton',{
     Name='Toggle_'..spec[2],AnchorPoint=Vector2.new(1,.5),
     Position=UDim2.new(1,-10,.5,0),
     Size=UDim2.fromOffset(61,37),
     BackgroundColor3=Color3.fromRGB(35,45,52),
     BackgroundTransparency=.07,
     BorderSizePixel=0,Text='',AutoButtonColor=true
    },row)
    make('UICorner',{CornerRadius=UDim.new(1,0)},toggle)
    local knob=make('Frame',{
     Name='SwitchKnob',AnchorPoint=Vector2.new(0,.5),
     Position=UDim2.new(0,5,.5,0),Size=UDim2.fromOffset(25,25),
     BackgroundColor3=Color3.fromRGB(217,220,214),BorderSizePixel=0
    },toggle)
    make('UICorner',{CornerRadius=UDim.new(1,0)},knob)
    local function refresh()
     local on=M.Settings[spec[2]]
     Tween:Create(toggle,TweenInfo.new(.15),{BackgroundColor3=on and Color3.fromRGB(99,42,50) or Color3.fromRGB(35,45,52)}):Play()
     Tween:Create(knob,TweenInfo.new(.15),{Position=UDim2.new(on and 1 or 0,on and -30 or 5,.5,0)}):Play()
    end
    toggle.Activated:Connect(function()
     changeValue(spec,1)
     refresh()
    end)
    refresh()
   else
    local value=M.Label(row,'',23)
    value.Name='SettingValue'
    value.Position=UDim2.new(.69,0,0,8)
    value.Size=UDim2.new(.28,-12,0,23)
    value.TextXAlignment=Enum.TextXAlignment.Right
    value.Font=Enum.Font.RobotoCondensed;value.TextSize=14
    value.TextColor3=Color3.fromRGB(235,236,229)
    local bar=make('Frame',{
     Name='ValueTrack',Position=UDim2.new(0,11,1,-17),
     Size=UDim2.new(1,-22,0,2),BackgroundColor3=Color3.fromRGB(58,68,74),
     BorderSizePixel=0
    },row)
    local progress=make('Frame',{
     Name='ValueProgress',Size=UDim2.fromScale(0,1),
     BackgroundColor3=Color3.fromRGB(187,55,66),BorderSizePixel=0
    },bar)
    local function refresh()
     value.Text=valueText(spec[2])
     progress.Size=UDim2.fromScale(math.clamp((M.Settings[spec[2]]-spec[3])/(spec[4]-spec[3]),0,1),1)
    end
    local function arrow(text,offset,direction)
     local button=make('TextButton',{
      Name=(direction<0 and 'Decrease_' or 'Increase_')..spec[2],
      Position=UDim2.new(1,offset,0,37),Size=UDim2.fromOffset(43,43),
      BackgroundColor3=Color3.fromRGB(41,51,58),
      BackgroundTransparency=.28,BorderSizePixel=0,
      Text=text,Font=Enum.Font.GothamBold,TextSize=20,
      TextColor3=Color3.fromRGB(233,238,237),AutoButtonColor=true
     },row)
     make('UICorner',{CornerRadius=UDim.new(0,5)},button)
     button.Activated:Connect(function() changeValue(spec,direction);refresh() end)
    end
    arrow('−',-102,-1)
    arrow('+',-52,1)
    refresh()
   end
  end
  right.Position=UDim2.fromScale(.435,0)
  Tween:Create(right,TweenInfo.new(.24,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
   {Position=UDim2.fromScale(.415,0)}):Play()
  rows.CanvasPosition=Vector2.zero
 end

 for i,g in ipairs(groups) do
  local button=make('TextButton',{
   Name='Category_'..g[1],LayoutOrder=i,Size=UDim2.new(1,-3,0,49),
   BackgroundTransparency=1,BorderSizePixel=0,
   Text=g[1],Font=Enum.Font.RobotoCondensed,TextSize=15,
   TextColor3=Color3.fromRGB(159,166,172),
   TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=false,
   AutoButtonColor=false
  },tabs)
  local marker=make('Frame',{
   Name='CategoryActiveMarker',Size=UDim2.fromOffset(3,20),
   Position=UDim2.new(1,-6,.5,-10),
   BackgroundColor3=Color3.fromRGB(189,48,59),
   BackgroundTransparency=1,BorderSizePixel=0
  },button)
  tabsByName[g[1]]={button=button,mark=marker}
  button.Activated:Connect(function() drawSettings(g) end)
 end

 panel.Back:Destroy()
 panel.Status.Size=UDim2.fromScale(.37,1)
 panel.Status.TextSize=11
 local function leave(saveChanges)
  if busy or closed then return end
  busy=true
  if saveChanges then
   panel.Status.Text='Salvando…'
   local ok,err=M.Save()
   if not ok then
    panel.Status.Text=err or 'Falha ao salvar as configurações.'
    busy=false
    return
   end
  else
   if initial then M.Settings=table.clone(initial);M.Dirty=false;M.Apply() end
  end
  closed=true
  panel.Close()
 end
 local cancel=M.Button(panel.Footer,'DESCARTAR',function() leave(false) end)
 cancel.Name='DiscardSettings'
 cancel.Position=UDim2.fromScale(.40,0)
 cancel.Size=UDim2.fromScale(.25,1)
 cancel.TextSize=12
 cancel.Font=Enum.Font.RobotoCondensed
 cancel.TextXAlignment=Enum.TextXAlignment.Center
 local save=M.Button(panel.Footer,'SALVAR / VOLTAR',function() leave(true) end)
 save.Name='SaveSettings'
 save.Position=UDim2.fromScale(.66,0)
 save.Size=UDim2.fromScale(.34,1)
 save.TextSize=12
 save.Font=Enum.Font.RobotoCondensed
 save.TextXAlignment=Enum.TextXAlignment.Center
 local UIS=game:GetService('UserInputService')
 local binding=UIS.InputBegan:Connect(function(input,processed)
  if processed or closed or not panel.Gui.Parent then return end
  if input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.Backspace then leave(true) end
 end)
 panel.Gui.Destroying:Connect(function()
  closed=true
  binding:Disconnect()
 end)
 drawSettings(groups[1])
 panel.Status.Text='Carregando configurações…'
 task.spawn(function()
  local ok=M.Load()
  if closed or not panel.Gui.Parent then return end
  if ok then
   initial=table.clone(M.Settings)
   panel.Status.Text='Pronto para ajustar.'
  else
   panel.Status.Text='Erro ao carregar. Tente novamente.'
  end
  for _,group in ipairs(groups) do
   if group[1]==selected then drawSettings(group);break end
  end
 end)
end

return M
