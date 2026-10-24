-- Reference-inspired settings: category tabs, framed sections, real sliders and checkboxes.
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local Settings={}
local initialized=false
local categories={
 {key="audio",label="ÁUDIO",color=Color3.fromRGB(99,145,212),title="AJUSTES DE ÁUDIO",rows={
  {section="MÚSICA"},{key="MusicVolume",label="Música do jogo",description="Tema do Jason e cena de morte",min=0,max=100,default=75,suffix="%"},
  {key="BoomboxVolume",label="Music dos jogadores",description="Volume das músicas por ID",min=0,max=100,default=65,suffix="%"},
  {section="SONS"},{key="EffectsVolume",label="Efeitos e interface",description="Cliques, avisos e regeneração",min=0,max=100,default=80,suffix="%"},
  {key="MusicEnabled",label="Ativar músicas",description="Liga ou silencia todas as músicas",default=true},
  {key="MenuSounds",label="Sons dos botões",description="Resposta sonora ao tocar",default=true},
  {key="FriendAlerts",label="Avisos de amizade",description="Som quando um amigo entra",default=true},
 }},
 {key="visual",label="VISUAL",color=Color3.fromRGB(160,126,202),title="AJUSTES VISUAIS",rows={
  {section="GRÁFICOS"},{key="LowGraphics",label="Gráficos leves",description="Reduz pós-processamento e efeitos",default=UIS.TouchEnabled},
  {key="MapShadows",label="Sombras do mapa",description="Desative para aliviar o celular",default=not UIS.TouchEnabled},
  {key="ReducedMotion",label="Menos movimento",description="Reduz movimentos da câmera e do menu",default=false},
  {section="JOGADORES"},{key="ShowNametags",label="Nomes dos jogadores",description="Mostra os nomes acima dos avatares",default=true},
 }},
 {key="gameplay",label="JOGO",color=Color3.fromRGB(118,166,112),title="AJUSTES DE JOGO",rows={
  {key="AFK",label="AFK",description="Fica fora das próximas partidas; a atual continua",default=false},
  {section="CÂMERA E CONTROLES"},{key="CameraFOV",label="Campo de visão",description="Abertura da câmera durante o jogo",min=60,max=90,default=70,suffix="°"},
  {key="ControlScale",label="Tamanho dos botões",description="Ajuste para o seu polegar",min=80,max=120,default=100,suffix="%"},
  {section="COMO SOBREVIVER"},{info="Correr e pular fazem barulho. Agachar ajuda a passar despercebido."},
  {info="Você recebe um impulso e um kit em cada rodada. O kit revive você ou um aliado caído."},
  {info="As partidas começam automaticamente. Ative AFK para ficar no lobby."},
 }},
}
local function corner(o,r) local c=Instance.new("UICorner",o) c.CornerRadius=UDim.new(0,r or 9) end
local function stroke(o,color,width,alpha) local s=Instance.new("UIStroke",o) s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Color=color s.Thickness=width or 1 s.Transparency=alpha or .4 return s end
local function label(parent,value,size,pos,font)
 local t=Instance.new("TextLabel",parent) t.BackgroundTransparency=1 t.Text=value t.Size=size t.Position=pos or UDim2.new() t.TextColor3=Color3.fromRGB(235,234,239) t.TextSize=15 t.Font=font or Enum.Font.GothamBold t.TextXAlignment=Enum.TextXAlignment.Left t.TextWrapped=true t.ZIndex=parent.ZIndex+1 return t
end
local function button(parent,value,color)
 local b=Instance.new("TextButton",parent) b.Text=value b.BackgroundColor3=color b.BackgroundTransparency=.35 b.BorderSizePixel=0 b.TextColor3=Color3.fromRGB(243,241,244) b.TextStrokeTransparency=.55 b.TextStrokeColor3=Color3.new(0,0,0) b.Font=Enum.Font.GothamBold b.TextSize=14 b.ZIndex=parent.ZIndex+2 b.AutoButtonColor=true corner(b,9) stroke(b,color,2,.15)
 local inner=Instance.new("Frame",b) inner.Name="Inset" inner.BackgroundTransparency=1 inner.Size=UDim2.new(1,-8,1,-8) inner.Position=UDim2.fromOffset(4,4) inner.ZIndex=b.ZIndex corner(inner,6) stroke(inner,Color3.fromRGB(220,218,226),1,.8)
 return b
end
function Settings.initialize(player)
 if initialized then return end initialized=true
 for _,category in ipairs(categories) do for _,row in ipairs(category.rows) do
  if row.key and player:GetAttribute(row.key)==nil then player:SetAttribute(row.key,row.default) end
 end end
 local groups={}
 for _,name in ipairs({"Music","Boombox","Effects"}) do
  local g=Instance.new("SoundGroup") g.Name="Suvivers"..name g.Parent=SoundService groups[name]=g
 end
 local function applyAudio()
  local enabled=player:GetAttribute("MusicEnabled")~=false
  groups.Music.Volume=enabled and (player:GetAttribute("MusicVolume") or 75)/100 or 0
  groups.Boombox.Volume=enabled and (player:GetAttribute("BoomboxVolume") or 65)/100 or 0
  groups.Effects.Volume=(player:GetAttribute("EffectsVolume") or 80)/100
 end
 for _,key in ipairs({"MusicEnabled","MusicVolume","BoomboxVolume","EffectsVolume"}) do player:GetAttributeChangedSignal(key):Connect(applyAudio) end
 local function sound(sound)
  if not sound:IsA("Sound") then return end
  if sound.Name=="CantorMusic" then sound.SoundGroup=groups.Boombox
  elseif sound.Name=="LocalJasonTheme" or sound.Name=="VoidMusic" or sound.Name=="JasonTheme" then sound.SoundGroup=groups.Music
  elseif sound.Name=="MenuClick" or sound.Name=="Click" or sound.Name=="FriendJoined" or sound.Name=="Regenerate" or sound.Name=="RegenerationCue" then sound.SoundGroup=groups.Effects end
 end
 for _,root in ipairs({SoundService,workspace,player:WaitForChild("PlayerGui")}) do
  root.DescendantAdded:Connect(sound) for _,s in ipairs(root:GetDescendants()) do sound(s) end
 end
 local function shadows() Lighting.GlobalShadows=player:GetAttribute("MapShadows")==true end
 player:GetAttributeChangedSignal("MapShadows"):Connect(shadows) shadows() applyAudio()
end
function Settings.build(parent,player,onClose)
 Settings.initialize(player)
 local frame=Instance.new("Frame",parent) frame.Name="ReferenceSettings" frame.BackgroundTransparency=1 frame.AnchorPoint=Vector2.new(.5,.5) frame.Position=UDim2.fromScale(.5,.53) frame.Size=UDim2.new(.86,0,.80,0) frame.ZIndex=50
 local baseZ=parent.ZIndex+1
 frame.ZIndex=baseZ
 local limit=Instance.new("UISizeConstraint",frame) limit.MaxSize=Vector2.new(960,620)
 local tabs=Instance.new("Frame",frame) tabs.Name="Tabs" tabs.BackgroundTransparency=1 tabs.Size=UDim2.new(1,0,0,42) tabs.ZIndex=baseZ+1
 local heading=Instance.new("Frame",frame) heading.Name="Heading" heading.Position=UDim2.fromOffset(0,50) heading.Size=UDim2.new(1,0,0,44) heading.BorderSizePixel=0 heading.BackgroundTransparency=.25 heading.ZIndex=baseZ+1 corner(heading,10)
 local headingStroke=stroke(heading,Color3.new(1,1,1),2,.3)
 local title=label(heading,"",UDim2.new(1,-110,1,0),UDim2.fromOffset(14,0)) title.TextSize=18
 local reset=button(heading,"REDEFINIR",Color3.fromRGB(75,76,82)) reset.Size=UDim2.fromOffset(92,30) reset.Position=UDim2.new(1,-101,0,7) reset.TextSize=10
 local content=Instance.new("ScrollingFrame",frame) content.Name="SettingsRows" content.Size=UDim2.new(1,0,1,-104) content.Position=UDim2.fromOffset(0,104) content.BackgroundColor3=Color3.fromRGB(11,12,15) content.BackgroundTransparency=.12 content.BorderSizePixel=0 content.ZIndex=baseZ+1 content.AutomaticCanvasSize=Enum.AutomaticSize.Y content.CanvasSize=UDim2.new() content.ScrollBarThickness=3 corner(content,10) stroke(content,Color3.fromRGB(119,117,126),2,.65)
 local pad=Instance.new("UIPadding",content) pad.PaddingLeft=UDim.new(0,14) pad.PaddingRight=UDim.new(0,14) pad.PaddingBottom=UDim.new(0,12)
 local list=Instance.new("UIListLayout",content) list.SortOrder=Enum.SortOrder.LayoutOrder list.Padding=UDim.new(0,2)
 local current=categories[1] local activeConnections={} local drag=nil local tabButtons={}
 local function setValue(row,value)
  if row.min then value=math.clamp(math.floor(value+.5),row.min,row.max) end
  if row.key=="AFK" then game:GetService("ReplicatedStorage").Survival.Action:FireServer("afk",value) return end
  player:SetAttribute(row.key,value)
 end
 local function clearRows()
  drag=nil
  for _,c in ipairs(activeConnections) do c:Disconnect() end table.clear(activeConnections)
  for _,r in ipairs(content:GetChildren()) do if r:IsA("GuiObject") then r:Destroy() end end
 end
 local function select(category)
  current=category clearRows() content.CanvasPosition=Vector2.zero
  title.Text=category.title heading.BackgroundColor3=category.color headingStroke.Color=category.color
  for key,b in pairs(tabButtons) do b.BackgroundTransparency=key==category.key and .2 or .9 end
  for i,row in ipairs(category.rows) do
   local cell=Instance.new("Frame",content) cell.Name=row.key or "Section"..i cell.LayoutOrder=i cell.Size=UDim2.new(1,-4,0,row.section and 40 or row.info and 64 or 76) cell.BackgroundTransparency=1 cell.ZIndex=baseZ+2
   if row.section then local t=label(cell,row.section,UDim2.fromScale(1,1)) t.TextSize=16
   elseif row.info then local t=label(cell,row.info,UDim2.new(1,-8,1,0),nil,Enum.Font.GothamMedium) t.TextSize=13 t.TextColor3=Color3.fromRGB(186,186,196)
   else
    local name=label(cell,row.label,UDim2.new(.52,-8,0,30),UDim2.fromOffset(0,8)) name.TextSize=15
    local desc=label(cell,row.description,UDim2.new(.53,-10,0,31),UDim2.fromOffset(0,37),Enum.Font.Gotham) desc.TextSize=11 desc.TextColor3=Color3.fromRGB(175,175,186)
    if row.min then
     local track=Instance.new("TextButton",cell) track.Name="Slider" track.Text="" track.AutoButtonColor=false track.AnchorPoint=Vector2.new(0,.5) track.Position=UDim2.new(.56,0,.5,0) track.Size=UDim2.new(.30,0,0,34) track.BackgroundTransparency=1 track.ZIndex=baseZ+4
     local rail=Instance.new("Frame",track) rail.Position=UDim2.new(0,0,.5,-4) rail.Size=UDim2.new(1,0,0,8) rail.BackgroundColor3=Color3.fromRGB(40,41,47) rail.BorderSizePixel=0 rail.ZIndex=baseZ+4 corner(rail,4) stroke(rail,Color3.new(0,0,0),1,.3)
     local fill=Instance.new("Frame",rail) fill.Name="Fill" fill.Size=UDim2.fromScale(0,1) fill.BackgroundColor3=category.color fill.BorderSizePixel=0 fill.ZIndex=baseZ+5 corner(fill,4)
     local thumb=Instance.new("Frame",track) thumb.Name="Thumb" thumb.AnchorPoint=Vector2.new(.5,.5) thumb.Size=UDim2.fromOffset(26,26) thumb.BackgroundColor3=Color3.fromRGB(42,43,49) thumb.BorderSizePixel=0 thumb.ZIndex=baseZ+6 corner(thumb,13) stroke(thumb,Color3.fromRGB(163,161,172),2,.2)
     local value=label(cell,"",UDim2.new(.12,0,1,0),UDim2.new(.88,0,0,0)) value.TextXAlignment=Enum.TextXAlignment.Right value.TextSize=14
     local function refresh()
      local n=player:GetAttribute(row.key) or row.default local ratio=(n-row.min)/(row.max-row.min)
      fill.Size=UDim2.fromScale(ratio,1) thumb.Position=UDim2.fromScale(ratio,.5) value.Text=tostring(n)..(row.suffix or "")
     end
     local function move(x) local width=math.max(1,track.AbsoluteSize.X) setValue(row,row.min+(row.max-row.min)*math.clamp((x-track.AbsolutePosition.X)/width,0,1)) end
     track.InputBegan:Connect(function(input)
      if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then drag={input=input,move=move} move(input.Position.X) end
     end)
     table.insert(activeConnections,player:GetAttributeChangedSignal(row.key):Connect(refresh)) refresh()
    else
     local check=button(cell,"",category.color) check.Name="Check" check.Size=UDim2.fromOffset(36,36) check.AnchorPoint=Vector2.new(1,.5) check.Position=UDim2.new(1,-3,.5,0) check.TextSize=25
     local function refresh() local yes=player:GetAttribute(row.key)==true check.Text=yes and "✓" or "" check.BackgroundTransparency=yes and .15 or .85 end
     check.Activated:Connect(function() setValue(row,not player:GetAttribute(row.key)) end)
     table.insert(activeConnections,player:GetAttributeChangedSignal(row.key):Connect(refresh)) refresh()
    end
   end
   local divider=Instance.new("Frame",cell) divider.Name="Divider" divider.BorderSizePixel=0 divider.BackgroundColor3=Color3.fromRGB(112,111,122) divider.BackgroundTransparency=.75 divider.Position=UDim2.new(0,0,1,-1) divider.Size=UDim2.new(1,0,0,1) divider.ZIndex=baseZ+3
  end
 end
 for i,category in ipairs(categories) do
  local b=button(tabs,category.label,category.color) b.Name=category.key b.Size=UDim2.new(.27,-7,1,0) b.Position=UDim2.new((i-1)*.27,0,0,0) tabButtons[category.key]=b
  b.Activated:Connect(function() select(category) end)
 end
 local close=button(tabs,"FECHAR",Color3.fromRGB(195,79,86)) close.Name="Close" close.Size=UDim2.new(.19,-2,1,0) close.Position=UDim2.fromScale(.81,0) close.Activated:Connect(function() drag=nil onClose() end)
 reset.Activated:Connect(function() for _,row in ipairs(current.rows) do if row.key then setValue(row,row.default) end end end)
 UIS.InputChanged:Connect(function(input) if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseMovement) then drag.move(input.Position.X) end end)
 UIS.InputEnded:Connect(function(input) if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then drag=nil end end)
 select(current)
 return {frame=frame,select=function(key) for _,c in ipairs(categories) do if c.key==key then select(c) end end end,setValue=function(key,value) for _,c in ipairs(categories) do for _,row in ipairs(c.rows) do if row.key==key then setValue(row,value) return end end end end}
end
return Settings
