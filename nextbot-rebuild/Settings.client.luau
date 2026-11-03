-- Native Roblox settings screen reconstructed from IMG_2686..IMG_2688.
-- Installs independently for review. Other Nextbot screens are not implemented here.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local TweenService=game:GetService('TweenService')
local Lighting=game:GetService('Lighting')
local SoundService=game:GetService('SoundService')
local RS=game:GetService('ReplicatedStorage')
local player=Players.LocalPlayer
local package=RS:WaitForChild('NextbotReference')
local config=require(package:WaitForChild('Config'))
local remote=package:WaitForChild('Settings')
local values=table.clone(config.Settings)
local colors={Audio=Color3.fromRGB(103,137,215),Visual=Color3.fromRGB(157,112,201),Game=Color3.fromRGB(105,174,74)}
local gui=Instance.new('ScreenGui')
gui.Name='NextbotSettingsReference';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=40
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild('PlayerGui')
local function make(class,parent,props)
	local o=Instance.new(class);for k,v in pairs(props or {}) do o[k]=v end;o.Parent=parent;return o
end
local function round(o,r)make('UICorner',o,{CornerRadius=UDim.new(0,r or 12)})end
local function edge(o,c,w)make('UIStroke',o,{Color=c or Color3.fromRGB(83,85,87),Thickness=w or 3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})end
local white=Color3.fromRGB(237,237,237)
local function text(parent,value,x,y,w,h,size,bold)
	return make('TextLabel',parent,{BackgroundTransparency=1,Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Font=bold==false and Enum.Font.Gotham or Enum.Font.GothamBold,TextSize=size,TextColor3=white,TextStrokeTransparency=.35,TextStrokeColor3=Color3.new(0,0,0),TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true})
end
local canvas=make('Frame',gui,{Name='Canvas',Size=UDim2.fromOffset(1624,750),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundTransparency=1})
local scaler=make('UIScale',canvas,{Scale=1})
local cameraConnection
local function resize()
	local c=workspace.CurrentCamera;if not c then return end
	scaler.Scale=math.min(c.ViewportSize.X/1624,c.ViewportSize.Y/750)
end
local function bindCamera()
	if cameraConnection then cameraConnection:Disconnect() end
	local c=workspace.CurrentCamera;if c then cameraConnection=c:GetPropertyChangedSignal('ViewportSize'):Connect(resize) end
	resize()
end
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(bindCamera);bindCamera()
local shade=make('TextButton',gui,{Name='Dim',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.28,Text='',AutoButtonColor=false,Visible=false,ZIndex=1})
canvas.ZIndex=2
local open=make('TextButton',canvas,{Name='OpenSettings',Text='⚙',Font=Enum.Font.GothamBold,TextSize=48,TextColor3=white,BackgroundColor3=Color3.fromRGB(15,34,40),BackgroundTransparency=.12,Position=UDim2.fromOffset(1307,26),Size=UDim2.fromOffset(81,81),ZIndex=2})
round(open,16);edge(open,Color3.fromRGB(57,108,123),4)
local window=make('Frame',canvas,{Name='SettingsWindow',BackgroundTransparency=1,Position=UDim2.fromOffset(348,130),Size=UDim2.fromOffset(928,604),Visible=false,ZIndex=3})
local tabs={};local active='Audio';local controls={};local drag=nil
local bar=make('Frame',window,{Position=UDim2.fromOffset(0,74),Size=UDim2.fromOffset(928,74),BackgroundColor3=colors.Audio,BackgroundTransparency=.45})
round(bar,13);edge(bar,Color3.fromRGB(15,18,18),3)
local heading=text(bar,'CONFIGURAÇÕES DE ÁUDIO',18,8,720,58,28)
local reset=make('TextButton',bar,{Text='REINICIAR',Font=Enum.Font.GothamBold,TextSize=22,TextColor3=white,BackgroundColor3=Color3.fromRGB(20,24,24),BackgroundTransparency=.12,Position=UDim2.fromOffset(760,12),Size=UDim2.fromOffset(152,50)})
round(reset,10);edge(reset)
local scroll=make('ScrollingFrame',window,{Name='Options',Position=UDim2.fromOffset(20,166),Size=UDim2.fromOffset(888,438),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageTransparency=.45,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y})
make('UIListLayout',scroll,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
make('UIPadding',scroll,{PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,10)})
local definitions={
	Audio={title='CONFIGURAÇÕES DE ÁUDIO',sections={
		{title='MÚSICA',rows={{'GameMusic','Música do jogo','',0,1},{'LobbyMusic','Música do lobby','',0,1},{'BoomboxVolume','Caixas de som portáteis','',0,1}}},
		{title='SONS',rows={{'NextbotVolume','Nextbots','',0,1},{'EmoteVolume','Emotes','',0,1}}},
	}},
	Visual={title='CONFIGURAÇÕES VISUAIS',sections={
		{title='GRÁFICOS',rows={{'LowGraphics','Gráficos baixos','Desativa materiais'},{'MapShadows','Sombras do mapa','As luzes projetam sombras'},{'NextbotVignette','Vinheta do Nextbot','Efeito de tela próximo a um nextbot'}}},
	}},
	Game={title='CONFIGURAÇÕES DE JOGABILIDADE',sections={
		{title='CÂMERA',rows={{'FOV','Campo de visão','',70,100},{'Viewbob','Viewbob','Sua câmera se move conforme você faz'},{'RunningViewmodel','Modelo de visualização de corrida','Animação de corrida em primeira pessoa'},{'LegacyCamera','Câmera legada','A câmera pré-revisão'}}},
	}},
}
local originalMaterials=setmetatable({},{__mode='k'})
local originalShadows=setmetatable({},{__mode='k'})
local originalGlobalShadows=Lighting.GlobalShadows
local function visualObject(o)
	if o:IsA('BasePart') then
		if values.LowGraphics then
			if not originalMaterials[o] then originalMaterials[o]={o.Material,o.MaterialVariant} end
			o.Material=Enum.Material.SmoothPlastic;o.MaterialVariant=''
		elseif originalMaterials[o] then
			local m=originalMaterials[o];o.Material=m[1];o.MaterialVariant=m[2];originalMaterials[o]=nil
		end
	elseif o:IsA('Light') then
		if originalShadows[o]==nil then originalShadows[o]=o.Shadows end
		o.Shadows=values.MapShadows and originalShadows[o] or false
	end
end
local function apply(key)
	if key=='FOV' then
		local c=workspace.CurrentCamera;if c and c.CameraType~=Enum.CameraType.Scriptable then c.FieldOfView=values.FOV end
	elseif key=='LowGraphics' or key=='MapShadows' then
		Lighting.GlobalShadows=values.MapShadows and originalGlobalShadows
		for _,o in ipairs(workspace:GetDescendants()) do visualObject(o) end
	elseif key:find('Music') or key:find('Volume') then
		local group=SoundService:FindFirstChild('NB_'..key)
		if group and group:IsA('SoundGroup') then group.Volume=values[key] end
	end
	-- Controllers consume attributes; this screen never starts a second camera loop.
	player:SetAttribute('NBSetting_'..key,values[key])
end
workspace.DescendantAdded:Connect(visualObject)
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()apply('FOV')end)
local changedSerial=0
local function save()
	changedSerial+=1;local serial=changedSerial
	task.delay(.35,function()if serial==changedSerial then remote:FireServer('Save',values) end end)
end
local function refresh(key)
	local row=controls[key];if not row then return end
	local v=values[key]
	if row.kind=='slider' then
		local a=(v-row.min)/(row.max-row.min)
		row.fill.Size=UDim2.fromScale(a,1);row.knob.Position=UDim2.fromScale(a,.5)
		row.label.Text=key=='FOV' and tostring(math.floor(v+.5)) or tostring(math.floor(v*100+.5))..'%'
	else
		row.button.Text=v and '✓' or ''
		row.button.BackgroundColor3=v and colors[active]:Lerp(Color3.new(1,1,1),.35) or Color3.fromRGB(40,41,44)
	end
end
local function set(key,v)
	values[key]=v;apply(key);refresh(key);save()
end
local function sliderAt(inputX)
	if not drag then return end
	local a=math.clamp((inputX-drag.track.AbsolutePosition.X)/drag.track.AbsoluteSize.X,0,1)
	local value=drag.min+(drag.max-drag.min)*a
	value=drag.key=='FOV' and math.floor(value+.5) or math.floor(value*100+.5)/100
	set(drag.key,value)
end
UIS.InputChanged:Connect(function(input)
	if drag and ((drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) or input==drag.input) then sliderAt(input.Position.X) end
end)
UIS.InputEnded:Connect(function(input)
	if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then drag=nil end
end)
local function draw(category)
	active=category;drag=nil;controls={}
	for _,o in ipairs(scroll:GetChildren()) do if o:IsA('Frame') then o:Destroy() end end
	scroll.CanvasPosition=Vector2.zero
	bar.BackgroundColor3=colors[category];heading.Text=definitions[category].title
	for key,b in pairs(tabs) do b.BackgroundTransparency=key==category and .25 or .85 end
	for index,section in ipairs(definitions[category].sections) do
		local panel=make('Frame',scroll,{Name=section.title,Size=UDim2.new(1,-8,0,58+#section.rows*92),BackgroundColor3=Color3.fromRGB(25,26,28),BackgroundTransparency=.23,LayoutOrder=index})
		round(panel,13);edge(panel,Color3.fromRGB(80,82,84),4)
		text(panel,section.title,18,8,820,43,25)
		make('Frame',panel,{Position=UDim2.fromOffset(18,58),Size=UDim2.new(1,-36,0,2),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(66,67,69),BackgroundTransparency=.2})
		for i,item in ipairs(section.rows) do
			local key,label,description,min,max=table.unpack(item)
			local y=60+(i-1)*92
			text(panel,label,18,y+(description=='' and 12 or 7),470,45,25)
			if description~='' then text(panel,description,18,y+45,730,30,20,false) end
			if min then
				local track=make('TextButton',panel,{Text='',AutoButtonColor=false,Position=UDim2.fromOffset(496,y+35),Size=UDim2.fromOffset(280,10),BackgroundColor3=Color3.fromRGB(37,39,43),BorderSizePixel=0})
				round(track,8);edge(track,Color3.fromRGB(9,11,13),2)
				local fill=make('Frame',track,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(169,193,247),BorderSizePixel=0});round(fill,8)
				for tick=1,11 do make('Frame',track,{Position=UDim2.new(tick/12,0,0,0),Size=UDim2.new(0,4,1,0),BackgroundColor3=Color3.fromRGB(28,30,33),BackgroundTransparency=.55,BorderSizePixel=0}) end
				local knob=make('TextButton',track,{Text='',AutoButtonColor=false,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(36,36),BackgroundColor3=Color3.fromRGB(40,42,45),ZIndex=5})
				round(knob,40);edge(knob,Color3.fromRGB(90,92,96),2)
				local valueLabel=text(panel,'',788,y+12,80,45,25);valueLabel.TextXAlignment=Enum.TextXAlignment.Right
				controls[key]={kind='slider',min=min,max=max,fill=fill,knob=knob,label=valueLabel}
				local function begin(input)
					if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
						drag={key=key,track=track,min=min,max=max,input=input};sliderAt(input.Position.X)
					end
				end
				track.InputBegan:Connect(begin);knob.InputBegan:Connect(begin)
				knob.InputBegan:Connect(function(input)
					if input.KeyCode==Enum.KeyCode.DPadLeft then set(key,math.max(min,values[key]-(max-min)/20))
					elseif input.KeyCode==Enum.KeyCode.DPadRight then set(key,math.min(max,values[key]+(max-min)/20)) end
				end)
			else
				local b=make('TextButton',panel,{Position=UDim2.fromOffset(818,y+22),Size=UDim2.fromOffset(46,46),Text='',Font=Enum.Font.GothamBold,TextSize=40,TextColor3=Color3.fromRGB(52,67,42),BackgroundColor3=Color3.fromRGB(40,41,44)})
				round(b,7);edge(b,Color3.fromRGB(107,110,110),2);controls[key]={kind='toggle',button=b}
				b.Activated:Connect(function()set(key,not values[key])end)
			end
			refresh(key)
			if i<#section.rows then make('Frame',panel,{Position=UDim2.fromOffset(18,y+82),Size=UDim2.new(1,-36,0,2),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(65,66,68),BackgroundTransparency=.2}) end
		end
	end
end
for i,entry in ipairs({{'Audio','ÁUDIO'},{'Visual','VISUAIS'},{'Game','Jogabilidade'}}) do
	local key,label=entry[1],entry[2]
	local b=make('TextButton',window,{Name=key,Position=UDim2.fromOffset((i-1)*267,0),Size=UDim2.fromOffset(253,62),Text=label,Font=Enum.Font.GothamBold,TextSize=23,TextColor3=white,TextStrokeTransparency=.4,BackgroundColor3=colors[key],BackgroundTransparency=.85})
	round(b,12);edge(b,colors[key]:Lerp(Color3.new(0,0,0),.3),4);tabs[key]=b
	b.Activated:Connect(function()draw(key)end)
end
local close=make('TextButton',window,{Name='Close',Position=UDim2.fromOffset(807,0),Size=UDim2.fromOffset(120,62),Text='FECHAR',Font=Enum.Font.GothamBold,TextSize=23,TextColor3=white,TextStrokeTransparency=.3,BackgroundColor3=Color3.fromRGB(225,91,96)})
round(close,12);edge(close,Color3.fromRGB(133,58,61),4)
local function show(enabled)
	window.Visible=enabled;shade.Visible=enabled;drag=nil
	if enabled then draw(active);window.Position=UDim2.fromOffset(348,141);TweenService:Create(window,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(348,130)}):Play() end
end
open.Activated:Connect(function()show(not window.Visible)end)
close.Activated:Connect(function()show(false)end)
shade.Activated:Connect(function()show(false)end)
reset.Activated:Connect(function()
	for _,s in ipairs(definitions[active].sections) do for _,r in ipairs(s.rows) do set(r[1],config.Settings[r[1]]) end end
end)
UIS.InputBegan:Connect(function(input,processed)
	if not processed and input.KeyCode==Enum.KeyCode.Escape and window.Visible then show(false) end
end)
remote.OnClientEvent:Connect(function(action,data)
	if action=='Loaded' and type(data)=='table' then
		for key,default in pairs(config.Settings) do if typeof(data[key])==typeof(default) then values[key]=data[key];apply(key) end end
		if window.Visible then draw(active) end
	end
end)
remote:FireServer('Load')
for key in pairs(values) do apply(key) end
draw(active)
