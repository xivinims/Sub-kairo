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
 local panel=M.Panel('CONFIGURAÇÕES','center')
 local pane=panel.Pane
 pane.BackgroundColor3=Color3.fromRGB(31,27,25);pane.BackgroundTransparency=.05
 make('UIStroke',{Color=Color3.fromRGB(114,101,94),Thickness=1,Transparency=.55},pane)
 make('UIGradient',{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(37,31,28),Color3.fromRGB(20,18,17)),Transparency=NumberSequence.new(.02,.06)},pane)
 local title=pane:FindFirstChildWhichIsA('TextLabel')
 if title then
  title.Name='MysterySettingsTitle';title.Text='CONFIGURAÇÕES';title.Font=Enum.Font.RobotoCondensed
  title.TextSize=24;title.TextScaled=false;title.TextXAlignment=Enum.TextXAlignment.Left
  title.Position=UDim2.new(0,22,0,13);title.Size=UDim2.new(1,-44,0,30)
  title.TextColor3=Color3.fromRGB(222,218,212)
 end
 make('Frame',{Name='MysterySettingsDivider',Position=UDim2.new(0,22,0,53),Size=UDim2.new(1,-44,0,1),BackgroundColor3=Color3.fromRGB(154,145,138),BackgroundTransparency=.62,BorderSizePixel=0},pane)
 panel.Content.Position=UDim2.new(0,18,0,61);panel.Content.Size=UDim2.new(1,-36,1,-136)
 panel.Footer.Position=UDim2.new(0,22,1,-61);panel.Footer.Size=UDim2.new(1,-44,0,48)
 panel.Status.Position=UDim2.new(0,0,0,-14);panel.Status.Size=UDim2.new(1,0,0,13)
 panel.Status.TextXAlignment=Enum.TextXAlignment.Center;panel.Status.TextSize=10
 panel.Status.TextColor3=Color3.fromRGB(167,158,151);panel.Back:Destroy()
 local rows=M.List(panel.Content);rows.Name='MysterySettingsRows'
 rows.ScrollBarThickness=2;rows.ScrollBarImageColor3=Color3.fromRGB(173,163,156)
 rows.UIListLayout.Padding=UDim.new(0,2)
 local options={
  {label='VOLUME',key='volume',min=0,max=1,step=.1},
  {label='BRILHO',key='brightness',min=0,max=1,step=.1},
  {label='CAMPO DE VISÃO',key='fov',min=60,max=90,step=5},
  {label='SENSIBILIDADE DO MOUSE',key='sensitivity',min=.2,max=2,step=.2},
  {label='SOMBRAS',key='shadows'},
  {label='BLOOM',key='bloom'},
  {label='DICAS DE CARREGAMENTO',key='loadingHints'}
 }
 local refreshers={};local drag;local closed=false;local busy=false
 local function formatValue(spec)
  local value=M.Settings[spec.key]
  if typeof(value)=='boolean' then return value and 'SIM' or 'NÃO' end
  if spec.key=='volume' or spec.key=='brightness' then return tostring(math.floor(value*100+.5))..'%' end
  if spec.key=='fov' then return tostring(math.floor(value+.5))..'°' end
  return string.format('%.1f',value)
 end
 local function canChange()
  if M.Loaded then return true end
  panel.Status.Text='CARREGANDO CONFIGURAÇÕES…';return false
 end
 local function setValue(spec,value)
  if not canChange() then return end
  if typeof(M.Settings[spec.key])=='boolean' then M.Settings[spec.key]=not M.Settings[spec.key]
  else
   local steps=math.round((value-spec.min)/spec.step);local rounded=spec.min+steps*spec.step
   M.Settings[spec.key]=math.clamp(math.floor(rounded*100+.5)/100,spec.min,spec.max)
  end
  M.Dirty=true;M.Apply();panel.Status.Text='ALTERAÇÕES NÃO APLICADAS'
  for _,refresh in ipairs(refreshers) do refresh() end
 end
 local function setFromPointer(spec,track,x)
  if track.AbsoluteSize.X<=0 then return end
  local alpha=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
  setValue(spec,spec.min+alpha*(spec.max-spec.min))
 end
 for index,spec in ipairs(options) do
  local boolean=typeof(M.Settings[spec.key])=='boolean'
  local row=make('Frame',{Name='Setting_'..spec.key,LayoutOrder=index,Size=UDim2.new(1,-5,0,52),BackgroundColor3=Color3.fromRGB(75,63,57),BackgroundTransparency=.94,BorderSizePixel=0},rows)
  make('UICorner',{CornerRadius=UDim.new(0,4)},row)
  make('TextLabel',{Name='SettingName',Position=UDim2.new(0,11,0,0),Size=UDim2.new(.54,-11,1,0),BackgroundTransparency=1,Text=spec.label,Font=Enum.Font.RobotoCondensed,TextSize=14,TextColor3=Color3.fromRGB(221,217,211),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=false,ZIndex=7},row)
  if boolean then
   local value=make('TextLabel',{Name='SettingValue',Position=UDim2.new(.68,0,0,0),Size=UDim2.new(.16,0,1,0),BackgroundTransparency=1,Text='',Font=Enum.Font.RobotoCondensed,TextSize=13,TextColor3=Color3.fromRGB(224,220,214),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7},row)
   local function arrow(text,position,direction)
    local button=make('TextButton',{Name=direction<0 and 'Decrease_'..spec.key or 'Increase_'..spec.key,Position=position,Size=UDim2.fromOffset(28,40),BackgroundTransparency=1,BorderSizePixel=0,Text=text,Font=Enum.Font.GothamMedium,TextSize=20,TextColor3=Color3.fromRGB(181,174,168),AutoButtonColor=false,ZIndex=8},row)
    button.Activated:Connect(function() setValue(spec) end)
    button.MouseEnter:Connect(function() button.TextColor3=Color3.fromRGB(250,247,240) end)
    button.MouseLeave:Connect(function() button.TextColor3=Color3.fromRGB(181,174,168) end)
   end
   arrow('◂',UDim2.new(.58,0,.5,-20),-1);arrow('▸',UDim2.new(.95,-28,.5,-20),1)
   refreshers[#refreshers+1]=function() value.Text=formatValue(spec) end;refreshers[#refreshers]()
  else
   local value=make('TextLabel',{Name='SettingValue',Position=UDim2.new(.89,0,0,0),Size=UDim2.new(.09,-5,1,0),BackgroundTransparency=1,Text='',Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(224,220,214),TextXAlignment=Enum.TextXAlignment.Right,ZIndex=7},row)
   local track=make('Frame',{Name='SliderTrack',Position=UDim2.new(.57,0,.5,-1),Size=UDim2.new(.29,0,0,2),BackgroundColor3=Color3.fromRGB(104,96,91),BorderSizePixel=0,ZIndex=4},row)
   local fill=make('Frame',{Name='SliderFill',Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(229,224,218),BorderSizePixel=0,ZIndex=5},track)
   local knob=make('Frame',{Name='SliderKnob',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=Color3.fromRGB(244,239,232),BorderSizePixel=0,ZIndex=6},track)
   make('UICorner',{CornerRadius=UDim.new(1,0)},knob)
   local hit=make('TextButton',{Name='SliderInput_'..spec.key,Position=UDim2.new(.55,0,0,0),Size=UDim2.new(.34,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Text='',AutoButtonColor=false,ZIndex=6},row)
   local function refresh()
    local valueNow=M.Settings[spec.key];local alpha=math.clamp((valueNow-spec.min)/(spec.max-spec.min),0,1)
    value.Text=formatValue(spec);fill.Size=UDim2.fromScale(alpha,1);knob.Position=UDim2.fromScale(alpha,.5)
   end
   hit.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
     drag={spec=spec,track=track};setFromPointer(spec,track,input.Position.X)
    end
   end)
   refreshers[#refreshers+1]=refresh;refresh()
  end
 end
 local function updateDrag(input)
  if drag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then setFromPointer(drag.spec,drag.track,input.Position.X) end
 end
 local function endDrag(input)
  if drag and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then drag=nil end
 end
 local changed=UIS.InputChanged:Connect(updateDrag);local ended=UIS.InputEnded:Connect(endDrag)
 local inputConnection=UIS.InputBegan:Connect(function(input,processed)
  if not processed and not closed and input.KeyCode==Enum.KeyCode.Escape then
   if initial then M.Settings=table.clone(initial);M.Dirty=false;M.Apply() end
   closed=true;panel.Close()
  end
 end)
 local function closeSettings(discard)
  if closed then return end
  if discard and initial then M.Settings=table.clone(initial);M.Dirty=false;M.Apply() end
  closed=true;panel.Close()
 end
 local function footerButton(name,text,x,fn)
  local button=make('TextButton',{Name=name,Position=UDim2.new(x,0,0,7),Size=UDim2.new(.31,0,0,38),BackgroundTransparency=1,BorderSizePixel=0,Text=text,TextWrapped=true,Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(177,169,162),AutoButtonColor=false},panel.Footer)
  button.MouseEnter:Connect(function() button.TextColor3=Color3.fromRGB(246,242,236) end)
  button.MouseLeave:Connect(function() button.TextColor3=Color3.fromRGB(177,169,162) end)
  button.Activated:Connect(fn)
 end
 footerButton('ResetDefaults','RESTAURAR PADRÃO',0,function()
  if not canChange() then return end
  M.Settings=table.clone(schema.Defaults);M.Dirty=true;M.Apply()
  panel.Status.Text='PADRÕES RESTAURADOS — APLIQUE PARA SALVAR'
  for _,refresh in ipairs(refreshers) do refresh() end
 end)
 footerButton('ApplySettings','APLICAR',.345,function()
  if busy or closed then return end
  busy=true;panel.Status.Text='APLICANDO…';local ok,err=M.Save()
  if ok then initial=table.clone(M.Settings);panel.Status.Text='CONFIGURAÇÕES APLICADAS'
  else panel.Status.Text=err or 'NÃO FOI POSSÍVEL SALVAR' end
  busy=false
 end)
 footerButton('BackSettings','VOLTAR',.69,function() closeSettings(true) end)
 panel.Gui.Destroying:Connect(function() closed=true;changed:Disconnect();ended:Disconnect();inputConnection:Disconnect() end)
 panel.Status.Text=M.Loaded and 'CONFIGURAÇÕES DO JOGO' or 'CARREGANDO CONFIGURAÇÕES…'
 if not M.Loaded then
  task.spawn(function()
   local ok=M.Load()
   if closed or not panel.Gui.Parent then return end
   if ok then
    initial=table.clone(M.Settings);panel.Status.Text='CONFIGURAÇÕES DO JOGO'
    for _,refresh in ipairs(refreshers) do refresh() end
   else panel.Status.Text='NÃO FOI POSSÍVEL CARREGAR — TENTE NOVAMENTE' end
  end)
 end
end

function M.OpenSettings()
 return openMysterySettings()
end
return M

