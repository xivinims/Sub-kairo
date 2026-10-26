local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Settings={}
local initialized=setmetatable({},{__mode="k"})

local categories={
 {key="audio",label="ÁUDIO",labelEn="AUDIO",title="ÁUDIO",titleEn="AUDIO",rows={
  {section="SONS",sectionEn="SOUNDS"},
  {key="EffectsVolume",label="Efeitos",labelEn="Effects",description="Passos, avisos, ataques e interface",descriptionEn="Footsteps, alerts, attacks and interface",min=0,max=100,default=80,suffix="%"},
  {key="MenuSounds",label="Sons dos botões",labelEn="Button sounds",description="Som curto ao tocar na interface",descriptionEn="Short sound when using the interface",default=true},
  {key="FriendAlerts",label="Avisos de amizade",labelEn="Friend alerts",description="Aviso quando um amigo entra",descriptionEn="Alert when a friend joins",default=true},
 }},
 {key="gameplay",label="JOGO",labelEn="GAME",title="JOGO",titleEn="GAME",rows={
  {key="AFK",label="AFK",labelEn="AFK",description="Fica fora das próximas partidas",descriptionEn="Stay out of upcoming matches",default=false},
  {key="CameraFOV",label="Campo de visão",labelEn="Field of view",description="Ajusta apenas a câmera",descriptionEn="Adjusts only the camera",min=48,max=82,step=1,default=62},
  {key="ControlScale",label="Tamanho dos botões",labelEn="Button size",description="Ajusta o HUD para o seu dedo",descriptionEn="Adjusts the HUD controls",min=80,max=120,default=100,suffix="%"},
  {key="ShowNametags",label="Nomes dos jogadores",labelEn="Player names",description="Mostra os nomes sobre os avatares",descriptionEn="Shows names above avatars",default=true},
  {section="PARTIDA",sectionEn="MATCH"},
  {info="Correr cria pontos de ruído. Agachar reduz bastante o som.",infoEn="Running creates noise points. Crouching greatly reduces sound."},
  {info="Hackeie os computadores, encontre uma chave e abra a saída.",infoEn="Hack the computers, find a key and open the exit."},
 }},
 {key="language",label="IDIOMA",labelEn="LANGUAGE",title="IDIOMA",titleEn="LANGUAGE",rows={
  {section="TEXTO DO JOGO",sectionEn="GAME TEXT"},
  {key="GameLanguage",label="Idioma do jogo",labelEn="Game language",description="Muda os textos do jogo. A dublagem do Fill continua em inglês.",descriptionEn="Changes game text. Fill's voice always stays in English.",options={"Português (Brasil)","English"},values={"pt-BR","en"},default="pt-BR"},
 }},
}

local function isEnglish(player)
 return player:GetAttribute("GameLanguage")=="en"
end
local function tr(player,pt,en)
 return isEnglish(player) and (en or pt) or pt
end
local function corner(o,r) local c=Instance.new("UICorner",o) c.CornerRadius=UDim.new(0,r or 3) end
local function stroke(o,c,w,a) local x=Instance.new("UIStroke",o) x.Color=c x.Thickness=w or 1 x.Transparency=a or .6 return x end
local function label(p,t,size,pos,font)
 local x=Instance.new("TextLabel",p)
 x.BackgroundTransparency=1 x.Text=t x.Size=size x.Position=pos or UDim2.new()
 x.TextColor3=Color3.fromRGB(232,232,235) x.TextSize=14 x.Font=font or Enum.Font.Gotham
 x.TextXAlignment=Enum.TextXAlignment.Left x.TextWrapped=true x.ZIndex=p.ZIndex+1
 return x
end
local function button(p,t,c)
 local b=Instance.new("TextButton",p)
 b.Text=t b.BackgroundColor3=Color3.fromRGB(16,16,18) b.BackgroundTransparency=.08 b.BorderSizePixel=0
 b.TextColor3=Color3.fromRGB(238,238,240) b.Font=Enum.Font.GothamBold b.TextSize=13 b.ZIndex=p.ZIndex+2
 corner(b,3) stroke(b,c,1,.55)
 return b
end

function Settings.initialize(player)
 if initialized[player] then return end
 initialized[player]=true
 if player:GetAttribute("GameLanguage")==nil then
  local locale=tostring(player.LocaleId or "en"):lower()
  player:SetAttribute("GameLanguage",locale:sub(1,2)=="pt" and "pt-BR" or "en")
 end
 for _,cat in ipairs(categories) do
  for _,row in ipairs(cat.rows) do
   if row.key and player:GetAttribute(row.key)==nil then player:SetAttribute(row.key,row.default) end
  end
 end
 local group=SoundService:FindFirstChild("SuviversEffects") or Instance.new("SoundGroup",SoundService)
 group.Name="SuviversEffects"
 local function apply() group.Volume=(player:GetAttribute("EffectsVolume") or 80)/100 end
 player:GetAttributeChangedSignal("EffectsVolume"):Connect(apply) apply()
 local function bind(o)
  if o:IsA("Sound") and (o.Name=="MenuClick" or o.Name=="Click" or o.Name=="PlayClick" or o.Name=="FriendJoined" or o.Name=="Regenerate" or o.Name=="RegenerationCue") then
   o.SoundGroup=group
  end
 end
 for _,root in ipairs({SoundService,workspace,player:WaitForChild("PlayerGui")}) do
  root.DescendantAdded:Connect(bind)
  for _,o in ipairs(root:GetDescendants()) do bind(o) end
 end
end

function Settings.build(parent,player,onClose)
 Settings.initialize(player)
 local frame=Instance.new("Frame",parent)
 frame.Name="ReferenceSettings" frame.AnchorPoint=Vector2.new(.5,.5) frame.Position=UDim2.fromScale(.5,.52)
 frame.Size=UDim2.new(.86,0,.78,0) frame.BackgroundColor3=Color3.fromRGB(8,8,9)
 frame.BackgroundTransparency=.08 frame.BorderSizePixel=0 frame.ZIndex=parent.ZIndex+2
 corner(frame,1) stroke(frame,Color3.fromRGB(122,122,128),1,.48)
 frame:SetAttribute("Style","DistrictInspired")
 local limit=Instance.new("UISizeConstraint",frame) limit.MaxSize=Vector2.new(660,460)

 local tabs=Instance.new("Frame",frame)
 tabs.BackgroundTransparency=1 tabs.Size=UDim2.new(1,-20,0,38) tabs.Position=UDim2.fromOffset(10,10) tabs.ZIndex=frame.ZIndex+1
 local title=label(frame,"",UDim2.new(1,-30,0,28),UDim2.fromOffset(15,56),Enum.Font.GothamBold)
 title.TextSize=15 title.TextColor3=Color3.fromRGB(224,224,229)
 local content=Instance.new("ScrollingFrame",frame)
 content.Position=UDim2.fromOffset(15,88) content.Size=UDim2.new(1,-30,1,-103)
 content.BackgroundTransparency=1 content.BorderSizePixel=0 content.AutomaticCanvasSize=Enum.AutomaticSize.Y
 content.CanvasSize=UDim2.new() content.ScrollBarThickness=3 content.ZIndex=frame.ZIndex+1
 local list=Instance.new("UIListLayout",content) list.Padding=UDim.new(0,4) list.SortOrder=Enum.SortOrder.LayoutOrder

 local active={} local tabButtons={} local drag=nil local currentCategory=categories[1]
 local function setValue(row,v)
  if row.min then
   local st=row.step or 1
   v=math.clamp(v,row.min,row.max)
   v=math.floor(v/st+.5)*st
  end
  if row.key=="AFK" then
   game.ReplicatedStorage.Survival.Action:FireServer("afk",v)
  else
   player:SetAttribute(row.key,v)
  end
 end
 local function clear()
  drag=nil
  for _,c in ipairs(active) do c:Disconnect() end
  table.clear(active)
  for _,o in ipairs(content:GetChildren()) do if o:IsA("GuiObject") then o:Destroy() end end
 end

 local select
 select=function(cat)
  currentCategory=cat
  clear()
  title.Text=tr(player,cat.title,cat.titleEn)
  for k,b in pairs(tabButtons) do
   b.BackgroundTransparency=k==cat.key and .08 or .48
   local c
   for _,candidate in ipairs(categories) do if candidate.key==k then c=candidate break end end
   if c then b.Text=tr(player,c.label,c.labelEn) end
  end

  for i,row in ipairs(cat.rows) do
   local cell=Instance.new("Frame",content)
   cell.LayoutOrder=i cell.Size=UDim2.new(1,-4,0,row.section and 28 or row.info and 44 or 62)
   cell.BackgroundTransparency=1 cell.ZIndex=content.ZIndex+1
   if row.section then
    local t=label(cell,tr(player,row.section,row.sectionEn),UDim2.fromScale(1,1))
    t.Font=Enum.Font.GothamBold t.TextSize=12 t.TextColor3=Color3.fromRGB(170,170,180)
   elseif row.info then
    local t=label(cell,tr(player,row.info,row.infoEn),UDim2.new(1,-8,1,0),nil,Enum.Font.Gotham)
    t.TextSize=12 t.TextColor3=Color3.fromRGB(190,190,198)
   else
    local n=label(cell,tr(player,row.label,row.labelEn),UDim2.new(.52,-8,0,28),UDim2.fromOffset(0,5),Enum.Font.GothamBold)
    n.TextSize=13
    local d=label(cell,tr(player,row.description,row.descriptionEn),UDim2.new(.54,-8,0,27),UDim2.fromOffset(0,33))
    d.TextSize=10 d.TextColor3=Color3.fromRGB(178,178,188)

    if row.options then
     local b=button(cell,"",Color3.fromRGB(118,118,128))
     b.Size=UDim2.new(.40,0,0,34) b.AnchorPoint=Vector2.new(1,.5) b.Position=UDim2.new(1,-2,.5,0)
     local function refresh()
      local value=player:GetAttribute(row.key)
      local index=table.find(row.values,value) or 1
      b.Text=row.options[index]
     end
     b.Activated:Connect(function()
      local value=player:GetAttribute(row.key)
      local index=table.find(row.values,value) or 1
      index=index%#row.values+1
      setValue(row,row.values[index])
     end)
     table.insert(active,player:GetAttributeChangedSignal(row.key):Connect(refresh))
     refresh()
    elseif row.min then
     local track=Instance.new("TextButton",cell)
     track.Text="" track.BackgroundColor3=Color3.fromRGB(38,38,42) track.BorderSizePixel=0
     track.Position=UDim2.new(.58,0,.5,-5) track.Size=UDim2.new(.28,0,0,10) track.ZIndex=cell.ZIndex+2
     corner(track,2)
     local fill=Instance.new("Frame",track)
     fill.BackgroundColor3=Color3.fromRGB(210,210,216) fill.BorderSizePixel=0 fill.ZIndex=track.ZIndex+1
     corner(fill,2)
     local val=label(cell,"",UDim2.new(.11,0,1,0),UDim2.new(.88,0,0,0))
     val.TextXAlignment=Enum.TextXAlignment.Right val.TextSize=12
     local function refresh()
      local v=player:GetAttribute(row.key) or row.default
      local r=(v-row.min)/(row.max-row.min)
      fill.Size=UDim2.fromScale(r,1)
      val.Text=tostring(math.floor(v+.5))..(row.suffix or "")
     end
     local function move(x)
      setValue(row,row.min+(row.max-row.min)*math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1))
     end
     track.InputBegan:Connect(function(input)
      if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
       drag={input=input,move=move} move(input.Position.X)
      end
     end)
     table.insert(active,player:GetAttributeChangedSignal(row.key):Connect(refresh))
     refresh()
    else
     local b=button(cell,"",Color3.fromRGB(100,100,108))
     b.Size=UDim2.fromOffset(34,34) b.AnchorPoint=Vector2.new(1,.5) b.Position=UDim2.new(1,-2,.5,0)
     local function refresh() b.Text=player:GetAttribute(row.key)==true and "✓" or "" end
     b.Activated:Connect(function() setValue(row,not player:GetAttribute(row.key)) end)
     table.insert(active,player:GetAttributeChangedSignal(row.key):Connect(refresh))
     refresh()
    end
   end
  end
 end

 local tabWidth=.25
 for i,cat in ipairs(categories) do
  local b=button(tabs,tr(player,cat.label,cat.labelEn),cat.color or Color3.fromRGB(112,112,120))
  b.Name=cat.key b.Size=UDim2.new(tabWidth,-5,1,0) b.Position=UDim2.new((i-1)*tabWidth,0,0,0)
  b.BackgroundTransparency=.48
  if b:FindFirstChildOfClass("UICorner") then b:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,1) end
  tabButtons[cat.key]=b
  b.Activated:Connect(function() select(cat) end)
 end
 local close=button(tabs,tr(player,"SAÍDA","EXIT"),Color3.fromRGB(115,82,82))
 close.Name="Close" close.Size=UDim2.new(.20,0,1,0) close.Position=UDim2.new(.80,0,0,0) close.BackgroundTransparency=.48
 close.Activated:Connect(onClose)

 local languageConnection=player:GetAttributeChangedSignal("GameLanguage"):Connect(function()
  close.Text=tr(player,"SAÍDA","EXIT")
  select(currentCategory)
 end)

 UIS.InputChanged:Connect(function(input)
  if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseMovement) then drag.move(input.Position.X) end
 end)
 UIS.InputEnded:Connect(function(input)
  if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then drag=nil end
 end)
 frame.Destroying:Connect(function() if languageConnection then languageConnection:Disconnect() end end)

 select(categories[1])
 return {frame=frame,select=select,setValue=setValue}
end
return Settings
