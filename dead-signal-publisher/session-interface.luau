local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local Lighting=game:GetService('Lighting')
local Sound=game:GetService('SoundService')
local Input=game:GetService('UserInputService')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
local schema=require(RS.SettingsSchema)
local M={Settings=table.clone(schema.Defaults),Loaded=false,Dirty=false,Revision=0}
function M.Make(class,second,third)
 local parent,props
 if typeof(second)=='Instance' then parent=second;props=third else props=second;parent=third end
 local object=Instance.new(class);for key,value in pairs(props) do object[key]=value end;object.Parent=parent;return object
end
local make=M.Make
function M.List(parent)
 local list=make('ScrollingFrame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},parent)
 make('UIPadding',{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,10)},list)
 make('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},list);return list
end
function M.Button(parent,text,callback)
 local b=make('TextButton',{Size=UDim2.new(1,0,0,44),Text=text,TextWrapped=true,Font=Enum.Font.Garamond,TextSize=21,TextColor3=Color3.fromRGB(178,185,178),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0},parent)
 local function select(on) b.TextColor3=on and Color3.fromRGB(247,244,223) or Color3.fromRGB(178,185,178);b.BackgroundTransparency=on and .88 or 1 end
 b.MouseEnter:Connect(function() select(true) end);b.MouseLeave:Connect(function() select(false) end);b.SelectionGained:Connect(function() select(true) end);b.SelectionLost:Connect(function() select(false) end);b.Activated:Connect(callback);return b
end
function M.Label(parent,text,height)
 return make('TextLabel',{Size=UDim2.new(1,0,0,height or 52),Text=text,TextWrapped=true,Font=Enum.Font.Garamond,TextSize=18,TextColor3=Color3.fromRGB(188,195,187),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},parent)
end
local opened
function M.Panel(title,dock)
 if opened then opened.Close() end
 local gui=make('ScreenGui',{Name='SidePanel',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=1500,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
 local shade=make('TextButton',{Name='WorldInputBlocker',Size=UDim2.fromScale(1,1),Text='',Modal=true,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.78,AutoButtonColor=false,BorderSizePixel=0},gui)
 local pane=make('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(dock=='left' and -.5 or 1.5,.5),Size=UDim2.fromScale(.55,.86),BackgroundColor3=Color3.fromRGB(9,17,18),BackgroundTransparency=.04,BorderSizePixel=0,ClipsDescendants=true},gui)
 local heading=M.Label(pane,title,46);heading.Position=UDim2.new(.04,0,0,4);heading.Size=UDim2.new(.92,0,0,50);heading.Font=Enum.Font.Oswald;heading.TextScaled=true;make('UITextSizeConstraint',heading,{MinTextSize=14,MaxTextSize=36})
 local content=make('Frame',pane,{Position=UDim2.new(.04,0,0,56),Size=UDim2.new(.92,0,1,-118),BackgroundTransparency=1})
 local footer=make('Frame',pane,{Position=UDim2.new(.04,0,1,-53),Size=UDim2.new(.92,0,0,45),BackgroundTransparency=1})
 local controls
 if workspace:GetAttribute('GameMode')=='Match' then pcall(function() controls=require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls();controls:Disable() end) end
 player:SetAttribute('InterfaceOpen',true)
 local obj={Gui=gui,Content=content,Footer=footer}
 function obj.Close() if not gui.Parent then return end;gui:Destroy();if controls then controls:Enable() end;player:SetAttribute('InterfaceOpen',false);if opened==obj then opened=nil end end
 local back=M.Button(footer,'VOLTAR',obj.Close);back.Size=UDim2.fromScale(.32,1);back.Position=UDim2.fromScale(.68,0);obj.Back=back;opened=obj
 local function fit(animate)
  local camera=workspace.CurrentCamera;local v=camera and camera.ViewportSize or Vector2.new(1280,720);local width=v.Y>v.X and .96 or v.X<1000 and .82 or .54
  pane.Size=UDim2.fromScale(width,v.Y>v.X and .9 or .86);local goal=UDim2.fromScale(dock=='left' and width/2+.01 or 1-width/2-.02,.5)
  if animate then Tween:Create(pane,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=goal}):Play() else pane.Position=goal end
 end
 fit(true);local camera=workspace.CurrentCamera;local connection=camera and camera:GetPropertyChangedSignal('ViewportSize'):Connect(function() fit(false) end);gui.Destroying:Connect(function() if connection then connection:Disconnect() end end)
 return obj
end
local master=make('SoundGroup',{Name='StillHereMaster',Volume=1},Sound)
local groupNames={'Music','Ambience','Effects','Dialogue','Movies','Chat'}
local audioGroups={};for _,name in ipairs(groupNames) do audioGroups[name]=make('SoundGroup',{Name='StillHere'..name,Volume=1},master) end
local originalGroups=setmetatable({},{__mode='k'})
local function categoryFor(object)
 local category=object:GetAttribute('SoundCategory')
 if category and audioGroups[category] then return category end
 local text=string.lower(object.Name..' '..(object.Parent and object.Parent.Name or ''))
 if string.find(text,'dialog',1,true) or string.find(text,'speech',1,true) then return 'Dialogue' end
 if string.find(text,'movie',1,true) or string.find(text,'cinema',1,true) then return 'Movies' end
 if string.find(text,'chat',1,true) then return 'Chat' end
 if string.find(text,'ambien',1,true) or string.find(text,'rain',1,true) then return 'Ambience' end
 if string.find(text,'music',1,true) or string.find(text,'piano',1,true) then return 'Music' end
 return 'Effects'
end
local function registerAudio(object)
 if object:IsA('Sound') then
  if not object.SoundGroup or object.SoundGroup==master then object.SoundGroup=audioGroups[categoryFor(object)] end
 elseif object:IsA('SoundGroup') and object~=master and not object:IsDescendantOf(master) then
  originalGroups[object]=originalGroups[object] or object.Volume
 end
end
for _,object in ipairs(game:GetDescendants()) do registerAudio(object) end
game.DescendantAdded:Connect(registerAudio)
local correction=make('ColorCorrectionEffect',{Name='PlayerBrightness'},Lighting)
local bloomOriginal=setmetatable({},{__mode='k'})
function M.Apply()
 local s=M.Settings
 master.Volume=s.volume
 audioGroups.Music.Volume=s.musicVolume;audioGroups.Ambience.Volume=s.ambienceVolume;audioGroups.Effects.Volume=s.effectsVolume;audioGroups.Dialogue.Volume=s.dialogueVolume;audioGroups.Movies.Volume=s.moviesVolume;audioGroups.Chat.Volume=s.chatVolume
 for group,base in pairs(originalGroups) do if group.Parent then group.Volume=base*s.volume end end
 correction.Brightness=(s.brightness-.5)*.3;Lighting.GlobalShadows=s.shadows
 for _,effect in ipairs(Lighting:GetChildren()) do if effect:IsA('BloomEffect') then if bloomOriginal[effect]==nil then bloomOriginal[effect]=effect.Enabled end;effect.Enabled=s.bloom and bloomOriginal[effect] end end
 Input.MouseDeltaSensitivity=s.sensitivity;player:SetAttribute('PreferredFOV',s.fov);player:SetAttribute('LoadingHints',s.loadingHints)
 local camera=workspace.CurrentCamera;if camera and camera.CameraType~=Enum.CameraType.Scriptable then camera.FieldOfView=s.fov end
end
workspace:GetAttributeChangedSignal('GameMode'):Connect(function() if M.Loaded then task.defer(M.Apply) end end)
local loading=false;local saving=false;local autoToken=0;local statusLabel
local function cloneSettings() return table.clone(M.Settings) end
function M.Load()
 while loading do task.wait(.1) end
 if M.Loaded then return true end;loading=true
 local ok,result=pcall(function() return RS:WaitForChild('PlayerSettings'):InvokeServer('get') end);loading=false
 if ok and result and result.ok then M.Settings=schema.Clean(result.settings);M.Loaded=true;M.Dirty=false;M.Apply();return true end
 return false
end
local scheduleSave
function M.Save()
 if not M.Dirty then return true end
 if not M.Loaded then return false,'As configurações ainda estão carregando.' end
 if saving then return false,'Aguarde o salvamento automático.' end
 saving=true;local revision=M.Revision;local snapshot=cloneSettings()
 local ok,response=pcall(function() return RS:WaitForChild('PlayerSettings'):InvokeServer('save',snapshot) end);saving=false
 if ok and response and response.ok then
  if revision==M.Revision then M.Dirty=false else M.Dirty=true;if scheduleSave then scheduleSave() end end
  return true
 end
 if scheduleSave then scheduleSave() end
 return false,ok and response and response.message or 'Não foi possível salvar. Tentando novamente.'
end
scheduleSave=function()
 autoToken+=1;local token=autoToken
 task.delay(.85,function()
  if token~=autoToken or not M.Dirty then return end
  task.spawn(function()
   local ok,message=M.Save()
   if statusLabel and statusLabel.Parent then statusLabel.Text=ok and 'CONFIGURAÇÕES SALVAS AUTOMATICAMENTE' or (message or 'TENTANDO SALVAR…') end
   if not ok and M.Dirty then task.delay(.8,function() if M.Dirty then scheduleSave() end end) end
  end)
 end)
end
local function changeValue(key,value)
 if typeof(M.Settings[key])=='boolean' then M.Settings[key]=not M.Settings[key] else M.Settings[key]=value end
 M.Revision+=1;M.Dirty=true;M.Apply();scheduleSave()
 if statusLabel then statusLabel.Text='SALVANDO AUTOMATICAMENTE…' end
end
local pages={
 {id='GAME',label='JOGO',description='PREFERÊNCIAS DA PARTIDA'},
 {id='CONTROLS',label='CONTROLES',description='AJUSTE A RESPOSTA DOS CONTROLES'},
 {id='DISPLAY',label='TELA',description='BRILHO E EFEITOS VISUAIS'},
 {id='AUDIO',label='ÁUDIO',description='VOLUMES E SAÍDA DE ÁUDIO'},
 {id='LANGUAGE',label='IDIOMA',description='IDIOMA DOS TEXTOS DO JOGO'},
}
local options={
 GAME={{label='DICAS DE CARREGAMENTO',key='loadingHints',kind='toggle'}},
 CONTROLS={{label='SENSIBILIDADE',key='sensitivity',kind='slider',min=.2,max=2,step=.1,format='decimal'}},
 DISPLAY={{label='BRILHO',key='brightness',kind='slider',min=0,max=1,step=.05,format='percent'},{label='CAMPO DE VISÃO',key='fov',kind='slider',min=60,max=90,step=1,format='degrees'},{label='SOMBRAS',key='shadows',kind='toggle'},{label='BRILHO AMBIENTE',key='bloom',kind='toggle'}},
 AUDIO_VOLUMES={{label='EFEITOS',key='effectsVolume',kind='slider',min=0,max=1,step=.05,format='percent'},{label='MÚSICA',key='musicVolume',kind='slider',min=0,max=1,step=.05,format='percent'},{label='AMBIÊNCIA',key='ambienceVolume',kind='slider',min=0,max=1,step=.05,format='percent'},{label='DIÁLOGO',key='dialogueVolume',kind='slider',min=0,max=1,step=.05,format='percent'},{label='FILMES',key='moviesVolume',kind='slider',min=0,max=1,step=.05,format='percent'},{label='CHAT',key='chatVolume',kind='slider',min=0,max=1,step=.05,format='percent'},{label='VOLUME GERAL',key='volume',kind='slider',min=0,max=1,step=.05,format='percent'}},
 AUDIO_OUTPUT={{label='DISPOSITIVO',value='AUTOMÁTICO (ROBLOX)'},{label='CANAIS',value='AUTOMÁTICO'},{label='ALCANCE DINÂMICO',value='AUTOMÁTICO'},{label='CONTROLADOR',value='DETECTADO PELO ROBLOX'}},
 LANGUAGE={{label='TEXTOS',value='PORTUGUÊS (BRASIL)'},{label='LEGENDAS',value='PORTUGUÊS (BRASIL)'},{label='DIÁLOGO',value='PORTUGUÊS (BRASIL)'}},
}
local function openSettings()
 if opened then opened.Close() end
 local gui=make('ScreenGui',{Name='MysterySettingsFullscreen',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2200,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
 make('TextButton',gui,{Name='WorldInputBlocker',Size=UDim2.fromScale(1,1),Text='',Modal=true,Active=true,BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,ZIndex=1})
 local pane=make('Frame',gui,{Name='OptionsPanel',Position=UDim2.new(-.04,0,0,0),Size=UDim2.new(.42,0,1,0),BackgroundColor3=Color3.fromRGB(13,14,14),BackgroundTransparency=.04,BorderSizePixel=0,ClipsDescendants=true,ZIndex=2})
 make('UIGradient',pane,{Rotation=0,Color=ColorSequence.new(Color3.fromRGB(16,16,16),Color3.fromRGB(9,10,10)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.02),NumberSequenceKeypoint.new(.82,.05),NumberSequenceKeypoint.new(1,.22)})})
 make('Frame',pane,{Name='PanelEdge',Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=Color3.fromRGB(188,180,166),BackgroundTransparency=.78,BorderSizePixel=0,ZIndex=3})
 local title=make('TextLabel',pane,{Name='OptionsTitle',Position=UDim2.new(0,42,0,27),Size=UDim2.new(1,-76,0,38),BackgroundTransparency=1,Text='OPÇÕES',Font=Enum.Font.RobotoCondensed,TextSize=26,TextColor3=Color3.fromRGB(220,216,209),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4})
 make('Frame',pane,{Position=UDim2.new(0,42,0,70),Size=UDim2.new(1,-78,0,1),BackgroundColor3=Color3.fromRGB(150,143,134),BackgroundTransparency=.72,BorderSizePixel=0,ZIndex=4})
 local body=make('ScrollingFrame',pane,{Name='SettingsContent',Position=UDim2.new(0,42,0,88),Size=UDim2.new(1,-80,1,-179),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=Color3.fromRGB(153,148,141),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,ZIndex=4})
 make('UIPadding',body,{PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,10)});local bodyLayout=make('UIListLayout',body,{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder})
 statusLabel=make('TextLabel',pane,{Name='SettingsStatus',Position=UDim2.new(0,42,1,-75),Size=UDim2.new(1,-82,0,18),BackgroundTransparency=1,Text='',Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(164,159,151),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4})
 local footer=make('Frame',pane,{Name='SettingsFooter',Position=UDim2.new(0,42,1,-49),Size=UDim2.new(1,-82,0,34),BackgroundTransparency=1,ZIndex=4})
 local back=make('TextButton',footer,{Name='Back',Size=UDim2.new(.52,0,1,0),BackgroundTransparency=1,Text='◯  VOLTAR',Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(191,185,176),TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=5})
 local reset=make('TextButton',footer,{Name='ResetDefaults',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.new(.48,0,1,0),BackgroundTransparency=1,Text='RESTAURAR PADRÕES',Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(163,157,148),TextXAlignment=Enum.TextXAlignment.Right,AutoButtonColor=false,ZIndex=5})
 local controls
 if workspace:GetAttribute('GameMode')=='Match' then pcall(function() controls=require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls();controls:Disable() end) end
 player:SetAttribute('InterfaceOpen',true)
 local closed=false;local drag=nil;local current='HOME';local refreshers={};local connections={};local render
 local obj={Gui=gui,Pane=pane,Status=statusLabel}
 function obj.Close()
  if closed then return end;closed=true
  if M.Dirty then task.spawn(M.Save) end
  gui:Destroy();if controls then controls:Enable() end;player:SetAttribute('InterfaceOpen',false);statusLabel=nil
  if opened==obj then opened=nil end
 end
 opened=obj
 local function clearBody()
  for _,child in ipairs(body:GetChildren()) do if not child:IsA('UIListLayout') and not child:IsA('UIPadding') then child:Destroy() end end
  table.clear(refreshers)
 end
 local function format(spec)
  local value=M.Settings[spec.key]
  if typeof(value)=='boolean' then return value and 'On' or 'Off' end
  if spec.format=='percent' then return tostring(math.floor(value*100+.5))..'%' end
  if spec.format=='degrees' then return tostring(math.floor(value+.5))..'°' end
  return string.format('%.1f',value)
 end
 local function addButton(index,label,description,destination)
  local button=make('TextButton',body,{Name='Page_'..index,LayoutOrder=index,Size=UDim2.new(1,-4,0,48),BackgroundColor3=Color3.fromRGB(74,69,63),BackgroundTransparency=1,BorderSizePixel=0,Text='',AutoButtonColor=false,ZIndex=5})
  make('TextLabel',button,{Position=UDim2.new(0,10,0,1),Size=UDim2.new(1,-20,0,25),BackgroundTransparency=1,Text=label,Font=Enum.Font.RobotoCondensed,TextSize=14,TextColor3=Color3.fromRGB(196,192,185),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6})
  if description then make('TextLabel',button,{Position=UDim2.new(0,10,0,24),Size=UDim2.new(1,-20,0,19),BackgroundTransparency=1,Text=description,Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(136,135,130),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6}) end
  make('Frame',button,{Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),BackgroundColor3=Color3.fromRGB(157,150,140),BackgroundTransparency=.87,BorderSizePixel=0,ZIndex=6})
  button.MouseEnter:Connect(function() button.BackgroundTransparency=.83 end);button.MouseLeave:Connect(function() button.BackgroundTransparency=1 end);button.Activated:Connect(function() current=destination;render() end)
 end
 local function addInfo(index,label,value)
  local row=make('Frame',body,{Name='Info_'..index,LayoutOrder=index,Size=UDim2.new(1,-4,0,42),BackgroundTransparency=1,ZIndex=5})
  make('TextLabel',row,{Position=UDim2.new(0,9,0,0),Size=UDim2.new(.58,-9,1,0),BackgroundTransparency=1,Text=label,Font=Enum.Font.RobotoCondensed,TextSize=11,TextColor3=Color3.fromRGB(155,153,148),TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=6})
  make('TextLabel',row,{Position=UDim2.new(.58,0,0,.0),Size=UDim2.new(.42,-8,1,0),BackgroundTransparency=1,Text=value,Font=Enum.Font.RobotoCondensed,TextSize=11,TextColor3=Color3.fromRGB(203,199,191),TextXAlignment=Enum.TextXAlignment.Right,TextWrapped=true,ZIndex=6})
  make('Frame',row,{Position=UDim2.new(0,9,1,-1),Size=UDim2.new(1,-18,0,1),BackgroundColor3=Color3.fromRGB(157,150,140),BackgroundTransparency=.89,BorderSizePixel=0,ZIndex=6})
 end
 local function addSetting(index,spec)
  local row=make('Frame',body,{Name='Setting_'..spec.key,LayoutOrder=index,Size=UDim2.new(1,-4,0,48),BackgroundTransparency=1,ZIndex=5})
  make('TextLabel',row,{Position=UDim2.new(0,9,0,0),Size=UDim2.new(.48,-9,1,0),BackgroundTransparency=1,Text=spec.label,Font=Enum.Font.RobotoCondensed,TextSize=11,TextColor3=Color3.fromRGB(182,179,172),TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=6})
  if spec.kind=='toggle' then
   local value=make('TextButton',row,{Position=UDim2.new(.68,0,.5,-14),Size=UDim2.new(.29,0,0,28),BackgroundColor3=Color3.fromRGB(39,40,38),BorderSizePixel=0,Text='',Font=Enum.Font.RobotoCondensed,TextSize=11,TextColor3=Color3.fromRGB(214,210,201),AutoButtonColor=false,ZIndex=7});make('UIStroke',value,{Color=Color3.fromRGB(135,129,119),Transparency=.64})
   local function refresh() value.Text=format(spec) end
   value.Activated:Connect(function() if M.Loaded then changeValue(spec.key) end end);refreshers[#refreshers+1]=refresh;refresh()
  else
   local track=make('Frame',row,{Position=UDim2.new(.52,0,.5,-1),Size=UDim2.new(.36,0,0,2),BackgroundColor3=Color3.fromRGB(76,74,69),BorderSizePixel=0,ZIndex=6})
   local fill=make('Frame',track,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(224,216,202),BorderSizePixel=0,ZIndex=7})
   local knob=make('Frame',track,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(13,13),BackgroundColor3=Color3.fromRGB(239,233,221),BorderSizePixel=0,ZIndex=8});make('UICorner',knob,{CornerRadius=UDim.new(1,0)})
   local text=make('TextLabel',row,{Position=UDim2.new(.89,0,0,0),Size=UDim2.new(.1,0,1,0),BackgroundTransparency=1,Text='',Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(212,208,199),TextXAlignment=Enum.TextXAlignment.Right,ZIndex=7})
   local hit=make('TextButton',row,{Position=UDim2.new(.49,0,0,0),Size=UDim2.new(.51,0,1,0),BackgroundTransparency=1,Text='',AutoButtonColor=false,ZIndex=8})
   local function refresh() local alpha=math.clamp((M.Settings[spec.key]-spec.min)/(spec.max-spec.min),0,1);text.Text=format(spec);fill.Size=UDim2.fromScale(alpha,1);knob.Position=UDim2.fromScale(alpha,.5) end
   local function update(x) if not M.Loaded or track.AbsoluteSize.X<=0 then return end;local alpha=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1);local steps=math.round((spec.min+alpha*(spec.max-spec.min)-spec.min)/spec.step);changeValue(spec.key,math.clamp(spec.min+steps*spec.step,spec.min,spec.max));refresh() end
   hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag={spec=spec,track=track,refresh=refresh};update(i.Position.X) end end)
   refreshers[#refreshers+1]=refresh;refresh()
  end
 end
 render=function()
  if closed then return end;clearBody()
  local selected
  if current=='HOME' then title.Text='OPÇÕES';back.Visible=false
  else
   back.Visible=true
   for _,page in ipairs(pages) do if page.id==current then selected=page;break end end
   title.Text=selected and selected.label or (current=='AUDIO_VOLUMES' and 'VOLUMES' or current=='AUDIO_OUTPUT' and 'SAÍDA DE ÁUDIO' or current=='LANGUAGE' and 'IDIOMA' or 'JOGO')
  end
  if current=='HOME' then
   for index,page in ipairs(pages) do addButton(index,page.label,page.description,page.id) end
  elseif current=='AUDIO' then
   addButton(1,'VOLUMES','EFEITOS, MÚSICA, DIÁLOGO E AMBIÊNCIA','AUDIO_VOLUMES')
   addButton(2,'SAÍDA','PREFERÊNCIAS DE ÁUDIO DO DISPOSITIVO','AUDIO_OUTPUT')
  elseif current=='AUDIO_OUTPUT' then
   for index,item in ipairs(options.AUDIO_OUTPUT) do addInfo(index,item.label,item.value) end
   addInfo(5,'ÁUDIO ESPACIAL','ATIVO QUANDO SUPORTADO')
  elseif current=='LANGUAGE' then
   for index,item in ipairs(options.LANGUAGE) do addInfo(index,item.label,item.value) end
  else
   local selectedOptions=options[current] or {}
   for index,spec in ipairs(selectedOptions) do if spec.key then addSetting(index,spec) else addInfo(index,spec.label,spec.value) end end
  end
  statusLabel.Text=M.Loaded and (M.Dirty and 'SALVANDO AUTOMATICAMENTE…' or 'ALTERAÇÕES SALVAS AUTOMATICAMENTE') or 'CARREGANDO CONFIGURAÇÕES…'
 end
 back.Activated:Connect(function()
  if current=='HOME' then return end
  if current=='AUDIO_VOLUMES' or current=='AUDIO_OUTPUT' then current='AUDIO' else current='HOME' end
  render()
 end)
 reset.Activated:Connect(function()
  if not M.Loaded then statusLabel.Text='AGUARDE O CARREGAMENTO';return end
  M.Settings=table.clone(schema.Defaults);M.Revision+=1;M.Dirty=true;M.Apply();scheduleSave();render();statusLabel.Text='SALVANDO PADRÕES…'
 end)
 local viewportConnection;local function fit()
  local camera=workspace.CurrentCamera;local v=camera and camera.ViewportSize or Vector2.new(1280,720)
  pane.Size=UDim2.new(v.Y>v.X and 1 or v.X<1000 and .72 or .42,0,1,0)
  title.TextSize=v.X<520 and 21 or 26
 end
 local function bindCamera()
  if viewportConnection then viewportConnection:Disconnect() end
  local camera=workspace.CurrentCamera;if camera then viewportConnection=camera:GetPropertyChangedSignal('ViewportSize'):Connect(fit) end
 end
 bindCamera();fit();table.insert(connections,workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function() bindCamera();fit() end))
 table.insert(connections,Input.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
  local alpha=math.clamp((i.Position.X-drag.track.AbsolutePosition.X)/math.max(drag.track.AbsoluteSize.X,1),0,1);local spec=drag.spec;local steps=math.round((spec.min+alpha*(spec.max-spec.min)-spec.min)/spec.step);changeValue(spec.key,math.clamp(spec.min+steps*spec.step,spec.min,spec.max));drag.refresh()
 end end))
 table.insert(connections,Input.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=nil end end))
 table.insert(connections,Input.InputBegan:Connect(function(i,processed) if not processed and not closed and i.KeyCode==Enum.KeyCode.Escape then obj.Close() end end))
 gui.Destroying:Connect(function() closed=true;for _,connection in ipairs(connections) do connection:Disconnect() end;if viewportConnection then viewportConnection:Disconnect() end end)
 render();pane.Position=UDim2.new(-pane.Size.X.Scale,0,0,0);Tween:Create(pane,TweenInfo.new(.28,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0,0)}):Play()
 if not M.Loaded then
  task.spawn(function() local ok=M.Load();if not gui.Parent then return end;if ok then render() else statusLabel.Text='NÃO FOI POSSÍVEL CARREGAR. TENTE NOVAMENTE.' end end)
 end
 return obj
end
function M.OpenSettings() return openSettings() end
return M
