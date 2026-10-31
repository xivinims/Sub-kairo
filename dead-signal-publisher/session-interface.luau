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
function M.Panel(title,dock)
 if opened then opened.Close() end
 
 local gui=make('ScreenGui',{Name='SidePanel',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=1500,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
 make('TextButton',{Size=UDim2.fromScale(1,1),Text='',Modal=true,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.80,AutoButtonColor=false,BorderSizePixel=0},gui)
 local startX=dock=='left' and -.5 or 1.5
 local pane=make('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(startX,.5),Size=UDim2.fromScale(.55,.86),BackgroundColor3=Color3.fromRGB(9,17,18),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true},gui)
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
  local width
  local center
  if dock=='center' then
   width=portrait and .96 or compact and .92 or .72
   center=.5
  elseif dock=='left' then
   width=portrait and .94 or compact and .82 or .54
   center=portrait and .50 or (width/2+.012)
  else
   width=portrait and .94 or compact and .79 or .57
   center=portrait and .50 or (1-width/2-.025)
  end
  local height=dock=='center' and (portrait and .91 or .88) or (portrait and .87 or .86)
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
-- Re-apply saved graphics preferences to the active mystery session.
workspace:GetAttributeChangedSignal('GameMode'):Connect(function()
 if M.Loaded then task.defer(function() if player.Parent then M.Apply() end end) end
end)
function M.Apply()
 local s=M.Settings;master.Volume=s.volume;for group,volume in pairs(groupVolumes) do if group.Parent then group.Volume=volume*s.volume end end
 -- Device-level graphics quality may still disable expensive effects.
 correction.Brightness=(s.brightness-.5)*.3
 Lighting.GlobalShadows=s.shadows
 for _,e in ipairs(Lighting:GetChildren()) do
  if e:IsA('BloomEffect') then
   if bloomOriginal[e]==nil then bloomOriginal[e]=e.Enabled end
   e.Enabled=s.bloom and bloomOriginal[e]
  end
 end
 game:GetService('UserInputService').MouseDeltaSensitivity=s.sensitivity
 player:SetAttribute('PreferredFOV',s.fov);player:SetAttribute('LoadingHints',s.loadingHints)
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
local function openMysterySettings()
 local UIS=game:GetService('UserInputService')
 local initial=M.Loaded and table.clone(M.Settings) or nil
 if opened then opened.Close() end
 local gui=make('ScreenGui',{Name='MysterySettingsFullscreen',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2200,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
 local blocker=make('TextButton',{Name='WorldInputBlocker',Size=UDim2.fromScale(1,1),Position=UDim2.fromScale(0,0),Text='',Modal=true,Active=true,BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,ZIndex=1},gui)
 local pane=make('Frame',{Name='OptionsPanel',Position=UDim2.new(-.035,0,0,0),Size=UDim2.new(.58,0,1,0),BackgroundColor3=Color3.fromRGB(12,13,13),BackgroundTransparency=.04,BorderSizePixel=0,ClipsDescendants=true,ZIndex=2},gui)
 make('UIGradient',{Rotation=0,Color=ColorSequence.new(Color3.fromRGB(14,14,14),Color3.fromRGB(10,11,11)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.02),NumberSequenceKeypoint.new(.76,.08),NumberSequenceKeypoint.new(1,1)})},pane)
 make('Frame',{Name='EdgeLine',Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=Color3.fromRGB(191,184,172),BackgroundTransparency=.72,BorderSizePixel=0,ZIndex=3},pane)
 local title=make('TextLabel',{Name='MysterySettingsTitle',Position=UDim2.fromOffset(26,20),Size=UDim2.new(1,-52,0,38),BackgroundTransparency=1,Text='OPÇÕES',Font=Enum.Font.RobotoCondensed,TextSize=26,TextColor3=Color3.fromRGB(222,218,212),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},pane)
 make('Frame',{Name='MysterySettingsDivider',Position=UDim2.new(0,26,0,65),Size=UDim2.new(1,-52,0,1),BackgroundColor3=Color3.fromRGB(154,145,138),BackgroundTransparency=.65,BorderSizePixel=0,ZIndex=4},pane)
 local nav=make('Frame',{Name='SettingsCategories',Position=UDim2.fromOffset(26,91),Size=UDim2.new(0,142,1,-178),BackgroundTransparency=1,ZIndex=4},pane)
 make('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},nav)
 local page=make('Frame',{Name='SettingsPage',Position=UDim2.fromOffset(190,91),Size=UDim2.new(1,-218,1,-178),BackgroundTransparency=1,ZIndex=4},pane)
 local pageTitle=make('TextLabel',{Name='SettingsPageTitle',Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,0,0,31),BackgroundTransparency=1,Text='',Font=Enum.Font.RobotoCondensed,TextSize=19,TextColor3=Color3.fromRGB(222,218,212),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},page)
 local description=make('TextLabel',{Name='SettingsDescription',Position=UDim2.new(0,0,0,32),Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,Text='',TextWrapped=true,Font=Enum.Font.RobotoCondensed,TextSize=13,TextColor3=Color3.fromRGB(157,154,149),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=5},page)
 local rows=make('ScrollingFrame',{Name='MysterySettingsRows',Position=UDim2.new(0,0,0,73),Size=UDim2.new(1,0,1,-74),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=Color3.fromRGB(160,155,149),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,ZIndex=5},page)
 make('UIPadding',{PaddingRight=UDim.new(0,9),PaddingBottom=UDim.new(0,8)},rows)
 local rowLayout=make('UIListLayout',{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},rows)
 local status=make('TextLabel',{Name='SettingsStatus',Position=UDim2.new(0,26,1,-76),Size=UDim2.new(1,-52,0,18),BackgroundTransparency=1,Text='',Font=Enum.Font.RobotoCondensed,TextSize=11,TextColor3=Color3.fromRGB(166,159,151),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},pane)
 local footer=make('Frame',{Name='SettingsFooter',Position=UDim2.new(0,26,1,-48),Size=UDim2.new(1,-52,0,36),BackgroundTransparency=1,ZIndex=5},pane)
 local controls
 if workspace:GetAttribute('GameMode')=='Match' then pcall(function() controls=require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls();controls:Disable() end) end
 player:SetAttribute('InterfaceOpen',true)
 local obj={Gui=gui,Pane=pane,Status=status}
 function obj.Close()
  if not gui.Parent then return end
  gui:Destroy();if controls then controls:Enable() end;player:SetAttribute('InterfaceOpen',false)
  if opened==obj then opened=nil end
 end
 opened=obj
 local pages={
  {id='GAME',label='JOGO',description='DICAS E PREFERÊNCIAS DA PARTIDA'},
  {id='CONTROLS',label='CONTROLES',description='AJUSTE A RESPOSTA DOS CONTROLES'},
  {id='DISPLAY',label='TELA',description='BRILHO E EFEITOS VISUAIS'},
  {id='AUDIO',label='ÁUDIO',description='VOLUME DE SOM'},
  {id='LANGUAGE',label='IDIOMA',description='IDIOMA DOS TEXTOS DO JOGO'}
 }
 local pageOptions={
  GAME={{label='DICAS DE CARREGAMENTO',key='loadingHints',kind='toggle'}},
  CONTROLS={{label='SENSIBILIDADE DO MOUSE',key='sensitivity',kind='slider',min=.2,max=2,step=.2,format='decimal'}},
  DISPLAY={
   {label='BRILHO',key='brightness',kind='slider',min=0,max=1,step=.1,format='percent'},
   {label='CAMPO DE VISÃO',key='fov',kind='slider',min=60,max=90,step=5,format='degrees'},
   {label='SOMBRAS',key='shadows',kind='toggle'},
   {label='BRILHO AMBIENTE',key='bloom',kind='toggle'}
  },
  AUDIO={{label='VOLUME GERAL',key='volume',kind='slider',min=0,max=1,step=.1,format='percent'}},
  LANGUAGE={{label='TEXTOS',value='PORTUGUÊS (BRASIL)'},{label='LEGENDAS E INTERAÇÕES',value='PORTUGUÊS (BRASIL)'}}
 }
 local refreshers={};local drag;local closed=false;local busy=false;local compact=false;local currentPage='GAME'
 local function formatValue(spec)
  local value=M.Settings[spec.key]
  if typeof(value)=='boolean' then return value and 'SIM' or 'NÃO' end
  if spec.format=='percent' then return tostring(math.floor(value*100+.5))..'%' end
  if spec.format=='degrees' then return tostring(math.floor(value+.5))..'°' end
  return string.format('%.1f',value)
 end
 local function canChange()
  if M.Loaded then return true end
  status.Text='CARREGANDO CONFIGURAÇÕES…';return false
 end
 local function setValue(spec,value)
  if not canChange() then return end
  if typeof(M.Settings[spec.key])=='boolean' then M.Settings[spec.key]=not M.Settings[spec.key]
  else
   local steps=math.round((value-spec.min)/spec.step);local rounded=spec.min+steps*spec.step
   M.Settings[spec.key]=math.clamp(math.floor(rounded*100+.5)/100,spec.min,spec.max)
  end
  M.Dirty=true;M.Apply();status.Text='ALTERAÇÕES NÃO APLICADAS'
  for _,refresh in ipairs(refreshers) do refresh() end
 end
 local function setFromPointer(spec,track,x)
  if track.AbsoluteSize.X<=0 then return end
  local alpha=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
  setValue(spec,spec.min+alpha*(spec.max-spec.min))
 end
 local function clearRows()
  for _,child in ipairs(rows:GetChildren()) do if not child:IsA('UIListLayout') and not child:IsA('UIPadding') then child:Destroy() end end
  table.clear(refreshers)
 end
 local function addInfoRow(index,label,value)
  local row=make('Frame',{Name='SettingInfo_'..index,LayoutOrder=index,Size=UDim2.new(1,-5,0,51),BackgroundColor3=Color3.fromRGB(61,59,56),BackgroundTransparency=.91,BorderSizePixel=0,ZIndex=5},rows)
  make('TextLabel',{Position=UDim2.new(0,8,0,0),Size=UDim2.new(.53,-8,1,0),BackgroundTransparency=1,Text=label,Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(172,170,164),TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=6},row)
  make('TextLabel',{Position=UDim2.new(.53,0,0,0),Size=UDim2.new(.47,-6,1,0),BackgroundTransparency=1,Text=value,Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(220,216,209),TextXAlignment=Enum.TextXAlignment.Right,TextWrapped=true,ZIndex=6},row)
 end
 local function addSettingRow(index,spec)
  local row=make('Frame',{Name='Setting_'..spec.key,LayoutOrder=index,Size=UDim2.new(1,-5,0,54),BackgroundColor3=Color3.fromRGB(61,59,56),BackgroundTransparency=.92,BorderSizePixel=0,ZIndex=5},rows)
  make('TextLabel',{Name='SettingName',Position=UDim2.new(0,8,0,0),Size=UDim2.new(.50,-8,1,0),BackgroundTransparency=1,Text=spec.label,Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(202,199,192),TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=6},row)
  if spec.kind=='toggle' then
   local button=make('TextButton',{Name='SettingValue',Position=UDim2.new(.62,0,.5,-17),Size=UDim2.new(.36,-4,0,34),BackgroundColor3=Color3.fromRGB(30,31,30),BackgroundTransparency=.25,BorderSizePixel=0,Text='',Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(228,224,217),AutoButtonColor=false,ZIndex=7},row)
   make('UIStroke',{Color=Color3.fromRGB(126,120,112),Transparency=.55,Thickness=1},button)
   local function refresh() button.Text=formatValue(spec) end
   button.Activated:Connect(function() setValue(spec) end)
   refreshers[#refreshers+1]=refresh;refresh()
  else
   local track=make('Frame',{Name='SliderTrack',Position=UDim2.new(.57,0,.5,-1),Size=UDim2.new(.34,0,0,2),BackgroundColor3=Color3.fromRGB(101,98,93),BorderSizePixel=0,ZIndex=6},row)
   local fill=make('Frame',{Name='SliderFill',Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(223,218,211),BorderSizePixel=0,ZIndex=7},track)
   local knob=make('Frame',{Name='SliderKnob',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=Color3.fromRGB(242,238,231),BorderSizePixel=0,ZIndex=8},track)
   make('UICorner',{CornerRadius=UDim.new(1,0)},knob)
   local value=make('TextLabel',{Name='SettingValue',Position=UDim2.new(.91,0,0,0),Size=UDim2.new(.09,0,1,0),BackgroundTransparency=1,Text='',Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(224,220,214),TextXAlignment=Enum.TextXAlignment.Right,ZIndex=7},row)
   local hit=make('TextButton',{Name='SliderInput_'..spec.key,Position=UDim2.new(.55,0,0,0),Size=UDim2.new(.39,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Text='',AutoButtonColor=false,ZIndex=8},row)
   local function refresh()
    local alpha=math.clamp((M.Settings[spec.key]-spec.min)/(spec.max-spec.min),0,1)
    value.Text=formatValue(spec);fill.Size=UDim2.fromScale(alpha,1);knob.Position=UDim2.fromScale(alpha,.5)
   end
   hit.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag={spec=spec,track=track};setFromPointer(spec,track,input.Position.X) end
   end)
   refreshers[#refreshers+1]=refresh;refresh()
  end
  make('Frame',{Name='SettingDivider',Position=UDim2.new(0,8,1,-1),Size=UDim2.new(1,-16,0,1),BackgroundColor3=Color3.fromRGB(164,157,148),BackgroundTransparency=.85,BorderSizePixel=0,ZIndex=6},row)
 end
 local function renderPage(id)
  currentPage=id;clearRows()
  local selected
  for _,data in ipairs(pages) do if data.id==id then selected=data;break end end
  pageTitle.Text=selected and selected.label or 'JOGO'
  description.Text=selected and selected.description or ''
  local options=pageOptions[id] or {}
  if #options==0 then addInfoRow(1,'IDIOMA DO JOGO','PORTUGUÊS (BRASIL)')
  else
   for index,spec in ipairs(options) do
    if spec.key then addSettingRow(index,spec) else addInfoRow(index,spec.label,spec.value) end
   end
  end
  for _,child in ipairs(nav:GetChildren()) do
   if child:IsA('TextButton') then
    local active=child.Name=='Category_'..id
    child.TextColor3=active and Color3.fromRGB(245,241,233) or Color3.fromRGB(162,159,153)
    child.BackgroundTransparency=active and .84 or 1
   end
  end
 end
 for order,data in ipairs(pages) do
  local button=make('TextButton',{Name='Category_'..data.id,LayoutOrder=order,Size=UDim2.new(1,0,0,37),BackgroundColor3=Color3.fromRGB(100,94,86),BackgroundTransparency=1,BorderSizePixel=0,Text=data.label,Font=Enum.Font.RobotoCondensed,TextSize=13,TextColor3=Color3.fromRGB(162,159,153),TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=5},nav)
  make('UIPadding',{PaddingLeft=UDim.new(0,8)},button)
  button.Activated:Connect(function() renderPage(data.id) end)
  button.MouseEnter:Connect(function() if currentPage~=data.id then button.TextColor3=Color3.fromRGB(221,217,209) end end)
  button.MouseLeave:Connect(function() if currentPage~=data.id then button.TextColor3=Color3.fromRGB(162,159,153) end end)
 end
 local back=make('TextButton',{Name='BackSettings',Position=UDim2.new(0,0,0,0),Size=UDim2.new(.28,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Text='◯  VOLTAR',Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(193,187,179),TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=6},footer)
 local reset=make('TextButton',{Name='ResetDefaults',Position=UDim2.new(.40,0,0,0),Size=UDim2.new(.31,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Text='RESTAURAR',Font=Enum.Font.RobotoCondensed,TextSize=11,TextColor3=Color3.fromRGB(171,164,156),TextXAlignment=Enum.TextXAlignment.Center,AutoButtonColor=false,ZIndex=6},footer)
 local apply=make('TextButton',{Name='ApplySettings',Position=UDim2.new(.73,0,0,0),Size=UDim2.new(.27,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Text='APLICAR',Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(209,203,195),TextXAlignment=Enum.TextXAlignment.Right,AutoButtonColor=false,ZIndex=6},footer)
 local function hover(button,base)
  button.MouseEnter:Connect(function() button.TextColor3=Color3.fromRGB(250,247,240) end)
  button.MouseLeave:Connect(function() button.TextColor3=base end)
 end
 hover(back,Color3.fromRGB(193,187,179));hover(reset,Color3.fromRGB(171,164,156));hover(apply,Color3.fromRGB(209,203,195))
 local function closeSettings(discard)
  if closed then return end
  if discard and initial then M.Settings=table.clone(initial);M.Dirty=false;M.Apply() end
  closed=true;obj.Close()
 end
 back.Activated:Connect(function() closeSettings(true) end)
 reset.Activated:Connect(function()
  if not canChange() then return end
  M.Settings=table.clone(schema.Defaults);M.Dirty=true;M.Apply();status.Text='PADRÕES RESTAURADOS — APLIQUE PARA SALVAR'
  for _,refresh in ipairs(refreshers) do refresh() end
 end)
 apply.Activated:Connect(function()
  if busy or closed then return end
  busy=true;status.Text='APLICANDO…';local ok,err=M.Save()
  if ok then initial=table.clone(M.Settings);status.Text='CONFIGURAÇÕES APLICADAS' else status.Text=err or 'NÃO FOI POSSÍVEL SALVAR' end
  busy=false
 end)
 local function fitPanel(animate)
  if not gui.Parent then return end
  local camera=workspace.CurrentCamera
  local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
  compact=viewport.X<760 or viewport.Y>viewport.X
  local width=compact and 1 or (viewport.X<1100 and .72 or .58)
  pane.Size=UDim2.new(width,0,1,0)
  title.TextSize=viewport.X<500 and 22 or 26
  if compact then
   nav.Position=UDim2.fromOffset(16,73);nav.Size=UDim2.new(1,-32,0,38)
   nav:ClearAllChildren()
   make('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},nav)
   local widths=math.max(61,math.floor((viewport.X-40)/#pages))
   for index,data in ipairs(pages) do
    local button=make('TextButton',{Name='Category_'..data.id,LayoutOrder=index,Size=UDim2.new(0,widths,1,0),BackgroundColor3=Color3.fromRGB(100,94,86),BackgroundTransparency=1,BorderSizePixel=0,Text=data.label,Font=Enum.Font.RobotoCondensed,TextSize=viewport.X<500 and 9 or 11,TextColor3=Color3.fromRGB(162,159,153),TextWrapped=true,AutoButtonColor=false,ZIndex=5},nav)
    button.Activated:Connect(function() renderPage(data.id) end)
   end
   page.Position=UDim2.fromOffset(16,122);page.Size=UDim2.new(1,-32,1,-214)
   status.Position=UDim2.new(0,18,1,-78);status.Size=UDim2.new(1,-36,0,17)
   footer.Position=UDim2.new(0,18,1,-49);footer.Size=UDim2.new(1,-36,0,35)
  else
   nav.Position=UDim2.fromOffset(26,91);nav.Size=UDim2.new(0,142,1,-178)
   nav:ClearAllChildren()
   make('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},nav)
   for index,data in ipairs(pages) do
    local button=make('TextButton',{Name='Category_'..data.id,LayoutOrder=index,Size=UDim2.new(1,0,0,37),BackgroundColor3=Color3.fromRGB(100,94,86),BackgroundTransparency=1,BorderSizePixel=0,Text=data.label,Font=Enum.Font.RobotoCondensed,TextSize=13,TextColor3=Color3.fromRGB(162,159,153),TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=5},nav)
    make('UIPadding',{PaddingLeft=UDim.new(0,8)},button)
    button.Activated:Connect(function() renderPage(data.id) end)
   end
   page.Position=UDim2.fromOffset(190,91);page.Size=UDim2.new(1,-218,1,-178)
   status.Position=UDim2.new(0,26,1,-76);status.Size=UDim2.new(1,-52,0,18)
   footer.Position=UDim2.new(0,26,1,-48);footer.Size=UDim2.new(1,-52,0,36)
  end
  renderPage(currentPage)
  if animate then Tween:Create(pane,TweenInfo.new(.28,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)}):Play()
  else pane.Position=UDim2.new(0,0,0,0) end
 end
 local changed=UIS.InputChanged:Connect(function(input)
  if drag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then setFromPointer(drag.spec,drag.track,input.Position.X) end
 end)
 local ended=UIS.InputEnded:Connect(function(input)
  if drag and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then drag=nil end
 end)
 local inputConnection=UIS.InputBegan:Connect(function(input,processed)
  if not processed and not closed and input.KeyCode==Enum.KeyCode.Escape then closeSettings(true) end
 end)
 local cameraConnection
 local function bindCamera()
  if cameraConnection then cameraConnection:Disconnect() end
  local camera=workspace.CurrentCamera
  if camera then cameraConnection=camera:GetPropertyChangedSignal('ViewportSize'):Connect(function() fitPanel(false) end) end
 end
 local cameraChanged=workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function() bindCamera();fitPanel(false) end)
 gui.Destroying:Connect(function()
  closed=true;changed:Disconnect();ended:Disconnect();inputConnection:Disconnect();cameraChanged:Disconnect()
  if cameraConnection then cameraConnection:Disconnect() end
 end)
 renderPage(currentPage);fitPanel(true)
 status.Text=M.Loaded and 'CONFIGURAÇÕES DO JOGO' or 'CARREGANDO CONFIGURAÇÕES…'
 if not M.Loaded then
  task.spawn(function()
   local ok=M.Load()
   if closed or not gui.Parent then return end
   if ok then initial=table.clone(M.Settings);status.Text='CONFIGURAÇÕES DO JOGO';for _,refresh in ipairs(refreshers) do refresh() end
   else status.Text='NÃO FOI POSSÍVEL CARREGAR — TENTE NOVAMENTE' end
  end)
 end
 return obj
end

function M.OpenSettings()
 return openMysterySettings()
end
return M


