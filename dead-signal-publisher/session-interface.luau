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
function M.Apply()
 local s=M.Settings;master.Volume=s.volume;for group,volume in pairs(groupVolumes) do if group.Parent then group.Volume=volume*s.volume end end;correction.Brightness=(s.brightness-.5)*.3;Lighting.GlobalShadows=s.shadows
 for _,e in ipairs(Lighting:GetChildren()) do if e:IsA('BloomEffect') then if bloomOriginal[e]==nil then bloomOriginal[e]=e.Enabled end;e.Enabled=s.bloom and bloomOriginal[e] end end
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
 local original=M.Loaded and table.clone(M.Settings) or nil
 local panel=M.Panel('OPÇÕES')
 local categories=make('Frame',{Name='OptionCategoryStack',Position=UDim2.fromScale(.27,0),Size=UDim2.fromScale(.405,1),BackgroundTransparency=1},panel.Content)
 local tabs=M.List(categories);tabs.ScrollBarThickness=0
 local caption=M.Label(tabs,'OPÇÕES',24);caption.Name='OptionsPath';caption.LayoutOrder=-5
 caption.Font=Enum.Font.RobotoCondensed;caption.TextSize=11;caption.TextXAlignment=Enum.TextXAlignment.Right
 caption.TextColor3=Color3.fromRGB(182,200,201)
 local right=make('Frame',{Name='OptionsHalf',Position=UDim2.fromScale(1.08,0),Size=UDim2.fromScale(.57,1),BackgroundColor3=Color3.fromRGB(6,19,26),BackgroundTransparency=.13,BorderSizePixel=0,ClipsDescendants=true},panel.Content)
 local rows=M.List(right);rows.UIListLayout.Padding=UDim.new(0,2);rows.ScrollBarThickness=2
 local categoryButtons={}
 local groups={
  {'VÍDEO',{{'Campo de visão','fov',60,90,5}}},
  {'CALIBRAÇÃO',{{'Brilho','brightness',0,1,.1}}},
  {'QUALIDADE',{{'Sombras','shadows'},{'Bloom','bloom'}}},
  {'CONTROLES',{{'Sensibilidade','sensitivity',.2,2,.2}}},
  {'JOGABILIDADE',{{'Objetivos','objectives'},{'Dicas no carregamento','loadingHints'}}},
  {'ÁUDIO',{{'Volume geral','volume',0,1,.1}}}
 }
 local transition=TweenInfo.new(.38,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
 local chosen=nil
 local function category(group)
  if not panel.Gui.Parent then return end
  chosen=group[1]
  caption.Text='OPÇÕES / '..chosen
  for name,b in pairs(categoryButtons) do
   local selected=name==chosen
   b.TextColor3=selected and Color3.fromRGB(234,238,235) or Color3.fromRGB(100,128,132)
   b.BackgroundTransparency=selected and .89 or 1
  end
  for _,o in ipairs(rows:GetChildren()) do if o:IsA('GuiObject') then o:Destroy() end end
  for index,spec in ipairs(group[2]) do
   local item=make('TextButton',{Name=spec[2],LayoutOrder=index,Size=UDim2.new(1,-4,0,33),Text='',AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(95,122,129),BackgroundTransparency=index==1 and .61 or .92,BorderSizePixel=0},rows)
   local label=M.Label(item,string.upper(spec[1]),33)
   label.Position=UDim2.fromScale(.045,0);label.Size=UDim2.fromScale(.47,1)
   label.Font=Enum.Font.RobotoCondensed;label.TextScaled=true;label.TextWrapped=false
   label.TextColor3=Color3.fromRGB(188,211,219)
   make('UITextSizeConstraint',{MinTextSize=8,MaxTextSize=13},label)
   local value=M.Label(item,'',33);value.Position=UDim2.fromScale(.64,0);value.Size=UDim2.fromScale(.23,1)
   value.TextXAlignment=Enum.TextXAlignment.Center;value.TextScaled=true;value.Font=Enum.Font.RobotoCondensed
   value.TextColor3=Color3.fromRGB(222,234,239)
   make('UITextSizeConstraint',{MinTextSize=9,MaxTextSize=13},value)
   local function refresh()
    local v=M.Settings[spec[2]]
    value.Text=typeof(v)=='boolean' and (v and 'ON' or 'OFF') or (spec[2]=='volume' or spec[2]=='brightness') and math.floor(v*100+.5)..'%' or (spec[2]=='fov' and tostring(math.floor(v)) or string.format('%.1f',v))
   end
   local function adjust(direction)
    if not M.Loaded then panel.Status.Text='Carregando configurações…';return end
    local key=spec[2];local v=M.Settings[key]
    if typeof(v)=='boolean' then M.Settings[key]=not v
    else M.Settings[key]=math.clamp(math.round((v+direction*spec[5])*100)/100,spec[3],spec[4]) end
    M.Dirty=true;M.Apply();refresh()
   end
   local previous=M.Button(item,'‹',function() adjust(-1) end)
   previous.Position=UDim2.fromScale(.51,0);previous.Size=UDim2.fromScale(.12,1)
   previous.TextXAlignment=Enum.TextXAlignment.Center;previous.TextSize=20
   local following=M.Button(item,'›',function() adjust(1) end)
   following.Position=UDim2.fromScale(.87,0);following.Size=UDim2.fromScale(.12,1)
   following.TextXAlignment=Enum.TextXAlignment.Center;following.TextSize=20
   item.Activated:Connect(function() adjust(1) end)
   item.MouseEnter:Connect(function()
    item.BackgroundTransparency=.48
    panel.Status.Text=spec[1]
   end)
   item.MouseLeave:Connect(function() item.BackgroundTransparency=index==1 and .61 or .92 end)
   refresh()
  end
  Tween:Create(categories,transition,{Position=UDim2.fromScale(0,0)}):Play()
  Tween:Create(right,transition,{Position=UDim2.fromScale(.43,0)}):Play()
 end
 local function closeCategory()
  chosen=nil
  caption.Text='OPÇÕES'
  for _,b in pairs(categoryButtons) do b.TextColor3=Color3.fromRGB(100,128,132);b.BackgroundTransparency=1 end
  Tween:Create(categories,transition,{Position=UDim2.fromScale(.27,0)}):Play()
  Tween:Create(right,transition,{Position=UDim2.fromScale(1.08,0)}):Play()
 end
 for i,g in ipairs(groups) do
  local b=M.Button(tabs,g[1],function() category(g) end)
  b.LayoutOrder=i;b.Size=UDim2.new(1,-2,0,44);b.Font=Enum.Font.Oswald
  b.TextScaled=true;b.TextXAlignment=Enum.TextXAlignment.Right;b.TextWrapped=false
  make('UITextSizeConstraint',{MinTextSize=11,MaxTextSize=30},b)
  categoryButtons[g[1]]=b
 end
 panel.Back:Destroy()
 local saving=false
 local save=M.Button(panel.Footer,'APLICAR / VOLTAR',function()
  if saving then return end
  if chosen then closeCategory();return end
  saving=true;panel.Status.Text='Salvando…';local ok,err=M.Save();saving=false
  if ok then panel.Close() else panel.Status.Text=err end
 end)
 save.Position=UDim2.fromScale(.61,0);save.Size=UDim2.fromScale(.39,1)
 save.Font=Enum.Font.RobotoCondensed;save.TextSize=15
 local cancel=M.Button(tabs,'DESCARTAR ALTERAÇÕES',function()
  if original then M.Settings=original;M.Dirty=false;M.Apply() end
  panel.Close()
 end)
 cancel.LayoutOrder=99;cancel.TextSize=12;cancel.Font=Enum.Font.RobotoCondensed
 cancel.TextXAlignment=Enum.TextXAlignment.Right
 local UIS=game:GetService('UserInputService')
 local binding
 binding=UIS.InputBegan:Connect(function(input,processed)
  if not panel.Gui.Parent then binding:Disconnect();return end
  if processed then return end
  if input.KeyCode==Enum.KeyCode.Backspace or input.KeyCode==Enum.KeyCode.Escape then
   if chosen then closeCategory()
   else local ok,err=M.Save();if ok then panel.Close() else panel.Status.Text=err end end
  end
 end)
 panel.Gui.Destroying:Connect(function() if binding then binding:Disconnect() end end)
 panel.Status.Text='Selecione uma categoria.'
 task.spawn(function()
  local ok=M.Load();if not panel.Gui.Parent then return end
  panel.Status.Text=ok and 'Selecione uma categoria.' or 'Falha ao carregar. Volte e tente novamente.'
  if ok then original=table.clone(M.Settings) end
  if chosen then
   for _,group in ipairs(groups) do if group[1]==chosen then category(group);break end end
  end
 end)
end

return M
