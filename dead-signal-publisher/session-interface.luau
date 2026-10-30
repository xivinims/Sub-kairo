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
 local gui=make('ScreenGui',{Name='SidePanel',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=1500,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
 make('TextButton',{Size=UDim2.fromScale(1,1),Text='',Modal=true,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.80,AutoButtonColor=false,BorderSizePixel=0},gui)
 local pane=make('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(1.5,.5),Size=UDim2.fromScale(.94,.86),BackgroundColor3=Color3.fromRGB(9,17,18),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true},gui)
 -- Only the options column has a dark panel; the scenery remains visible.
 local heading=M.Label(pane,title,46);heading.Position=UDim2.new(.15,0,0,4);heading.Size=UDim2.new(.33,0,0,50);heading.Font=Enum.Font.Oswald;heading.TextScaled=true;heading.TextXAlignment=Enum.TextXAlignment.Right;make('UITextSizeConstraint',{MinTextSize=14,MaxTextSize=42},heading)
 local content=make('Frame',{Position=UDim2.new(.025,0,0,56),Size=UDim2.new(.95,0,1,-118),BackgroundTransparency=1},pane)
 local footer=make('Frame',{Position=UDim2.new(.035,0,1,-53),Size=UDim2.new(.93,0,0,45),BackgroundTransparency=1},pane)
 local status=M.Label(footer,'',44);status.Size=UDim2.fromScale(.64,1);status.TextSize=15
 local controls
 if workspace:GetAttribute('GameMode')=='Match' then pcall(function() controls=require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls();controls:Disable() end) end
 player:SetAttribute('InterfaceOpen',true)
 local obj={Gui=gui,Content=content,Footer=footer,Status=status}
 function obj.Close()
  if not gui.Parent then return end
  gui:Destroy();if controls then controls:Enable() end;player:SetAttribute('InterfaceOpen',false);if opened==obj then opened=nil end
 end
 local close=M.Button(footer,'VOLTAR',obj.Close);close.Position=UDim2.fromScale(.68,0);close.Size=UDim2.fromScale(.32,1)
 obj.Back=close;obj.Pane=pane;opened=obj;Tween:Create(pane,TweenInfo.new(.25,Enum.EasingStyle.Quad),{Position=UDim2.fromScale(.5,.5)}):Play();return obj
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
 local panel=M.Panel('OPÇÕES');local categories=make('Frame',{Position=UDim2.fromScale(.15,0),Size=UDim2.fromScale(.32,1),BackgroundTransparency=1},panel.Content)
 local tabs=M.List(categories);local caption=M.Label(tabs,'CATEGORIAS',22);caption.Font=Enum.Font.RobotoCondensed;caption.TextSize=12;caption.TextXAlignment=Enum.TextXAlignment.Right
 local right=make('Frame',{Name='OptionsHalf',Position=UDim2.fromScale(.50,0),Size=UDim2.fromScale(.50,1),BackgroundColor3=Color3.fromRGB(8,20,24),BackgroundTransparency=.20,BorderSizePixel=0},panel.Content);local rows=M.List(right);rows.UIListLayout.Padding=UDim.new(0,2)
 local categoryButtons={}
 local groups={{'VÍDEO',{{'Brilho','brightness',0,1,.1},{'Campo de visão','fov',60,90,5},{'Sombras','shadows'},{'Bloom','bloom'}}},{'ÁUDIO',{{'Volume geral','volume',0,1,.1}}},{'CONTROLES',{{'Sensibilidade do mouse','sensitivity',.2,2,.2}}},{'JOGO',{{'Missão no topo','objectives'},{'Frases no carregamento','loadingHints'}}}}
 local function category(group)
  for name,b in pairs(categoryButtons) do b.TextColor3=name==group[1] and Color3.fromRGB(230,237,218) or Color3.fromRGB(102,122,124) end
  for _,c in ipairs(rows:GetChildren()) do if c:IsA('GuiObject') then c:Destroy() end end
  for _,spec in ipairs(group[2]) do
   local row=make('Frame',{Size=UDim2.new(1,0,0,30),BackgroundColor3=Color3.fromRGB(60,76,73),BackgroundTransparency=.85,BorderSizePixel=0},rows)
   local label=M.Label(row,string.upper(spec[1]),30);label.Size=UDim2.fromScale(.48,1);label.Font=Enum.Font.RobotoCondensed;label.TextScaled=true;make('UITextSizeConstraint',{MinTextSize=9,MaxTextSize=14},label)
   local value=M.Label(row,'',30);value.Position=UDim2.fromScale(.60,0);value.Size=UDim2.fromScale(.25,1);value.TextXAlignment=Enum.TextXAlignment.Center;value.TextSize=13;value.Font=Enum.Font.RobotoCondensed
   local function refresh() local v=M.Settings[spec[2]];value.Text=typeof(v)=='boolean' and (v and 'SIM' or 'NÃO') or (spec[2]=='volume' or spec[2]=='brightness') and math.floor(v*100+.5)..'%' or string.format('%.1f',v) end
   local function adjust(direction)
    if not M.Loaded then panel.Status.Text='Aguarde carregar as configurações.';return end
    local key=spec[2];local v=M.Settings[key];if typeof(v)=='boolean' then M.Settings[key]=not v else M.Settings[key]=math.clamp(math.round((v+direction*spec[5])*100)/100,spec[3],spec[4]) end;M.Dirty=true;M.Apply();refresh()
   end
   local left=M.Button(row,'‹',function() adjust(-1) end);left.Position=UDim2.fromScale(.48,0);left.Size=UDim2.fromScale(.12,1);left.TextXAlignment=Enum.TextXAlignment.Center
   local next=M.Button(row,'›',function() adjust(1) end);next.Position=UDim2.fromScale(.85,0);next.Size=UDim2.fromScale(.15,1);next.TextXAlignment=Enum.TextXAlignment.Center
   refresh()
  end
 end
 for _,g in ipairs(groups) do local b=M.Button(tabs,g[1],function() category(g) end);b.Size=UDim2.new(1,0,0,40);b.Font=Enum.Font.Oswald;b.TextScaled=true;b.TextXAlignment=Enum.TextXAlignment.Right;make('UITextSizeConstraint',{MinTextSize=14,MaxTextSize=32},b);categoryButtons[g[1]]=b end
 panel.Back:Destroy();local saving=false
 local save=M.Button(panel.Footer,'SALVAR E VOLTAR',function()
  if saving then return end;saving=true;panel.Status.Text='Salvando…';local ok,err=M.Save();saving=false
  if ok then panel.Close() else panel.Status.Text=err end
 end);save.Position=UDim2.fromScale(.60,0);save.Size=UDim2.fromScale(.40,1);save.TextSize=17
 panel.Status.Text='Carregando…';task.spawn(function() local ok=M.Load();if not panel.Gui.Parent then return end;panel.Status.Text=ok and 'Vale no menu e na partida.' or 'Falha ao carregar. Feche e tente novamente.';if ok then original=table.clone(M.Settings) end;category(groups[1]) end)
 -- Escape from a network error without pretending preferences were saved.
 local cancel=M.Button(tabs,'CANCELAR',function() if original then M.Settings=original;M.Dirty=false;M.Apply() end;panel.Close() end);cancel.LayoutOrder=10;cancel.TextSize=14;cancel.TextXAlignment=Enum.TextXAlignment.Right
 category(groups[1])
end
return M
