local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Settings={}
local initialized=setmetatable({},{__mode="k"})
local categories={
 {key="audio",label="ÁUDIO",color=Color3.fromRGB(105,110,120),title="ÁUDIO",rows={
  {section="SONS"},
  {key="EffectsVolume",label="Efeitos",description="Passos, avisos, ataques e interface",min=0,max=100,default=80,suffix="%"},
  {key="MenuSounds",label="Sons dos botões",description="Som curto ao tocar na interface",default=true},
  {key="FriendAlerts",label="Avisos de amizade",description="Aviso quando um amigo entra",default=true},
 }},
 {key="gameplay",label="JOGO",color=Color3.fromRGB(125,128,134),title="JOGO",rows={
  {key="AFK",label="AFK",description="Fica fora das próximas partidas",default=false},
  {key="CameraFOV",label="Campo de visão",description="Ajusta apenas a câmera",min=48,max=82,step=1,default=62},
  {key="ControlScale",label="Tamanho dos botões",description="Ajusta o HUD para o seu dedo",min=80,max=120,default=100,suffix="%"},
  {key="ShowNametags",label="Nomes dos jogadores",description="Mostra os nomes sobre os avatares",default=true},
  {section="PARTIDA"},
  {info="Correr cria pontos de ruído. Agachar reduz bastante o som."},
  {info="Hackeie os computadores, encontre uma chave e abra a saída."},
 }},
}
local function corner(o,r) local c=Instance.new("UICorner",o) c.CornerRadius=UDim.new(0,r or 3) end
local function stroke(o,c,w,a) local x=Instance.new("UIStroke",o) x.Color=c x.Thickness=w or 1 x.Transparency=a or .6 return x end
local function label(p,t,size,pos,font)
 local x=Instance.new("TextLabel",p) x.BackgroundTransparency=1 x.Text=t x.Size=size x.Position=pos or UDim2.new() x.TextColor3=Color3.fromRGB(232,232,235) x.TextSize=14 x.Font=font or Enum.Font.Gotham x.TextXAlignment=Enum.TextXAlignment.Left x.TextWrapped=true x.ZIndex=p.ZIndex+1 return x
end
local function button(p,t,c)
 local b=Instance.new("TextButton",p) b.Text=t b.BackgroundColor3=Color3.fromRGB(16,16,18) b.BackgroundTransparency=.1 b.BorderSizePixel=0 b.TextColor3=Color3.fromRGB(238,238,240) b.Font=Enum.Font.GothamBold b.TextSize=13 b.ZIndex=p.ZIndex+2 corner(b,3) stroke(b,c,1,.55) return b
end
function Settings.initialize(player)
 if initialized[player] then return end initialized[player]=true
 for _,cat in ipairs(categories) do for _,row in ipairs(cat.rows) do if row.key and player:GetAttribute(row.key)==nil then player:SetAttribute(row.key,row.default) end end end
 local group=SoundService:FindFirstChild("SuviversEffects") or Instance.new("SoundGroup",SoundService) group.Name="SuviversEffects"
 local function apply() group.Volume=(player:GetAttribute("EffectsVolume") or 80)/100 end
 player:GetAttributeChangedSignal("EffectsVolume"):Connect(apply) apply()
 local function bind(o) if o:IsA("Sound") and (o.Name=="MenuClick" or o.Name=="Click" or o.Name=="PlayClick" or o.Name=="FriendJoined" or o.Name=="Regenerate" or o.Name=="RegenerationCue") then o.SoundGroup=group end end
 for _,root in ipairs({SoundService,workspace,player:WaitForChild("PlayerGui")}) do root.DescendantAdded:Connect(bind) for _,o in ipairs(root:GetDescendants()) do bind(o) end end
end
function Settings.build(parent,player,onClose)
 Settings.initialize(player)
 local frame=Instance.new("Frame",parent) frame.Name="ReferenceSettings" frame.AnchorPoint=Vector2.new(.5,.5) frame.Position=UDim2.fromScale(.5,.52) frame.Size=UDim2.new(.86,0,.78,0) frame.BackgroundColor3=Color3.fromRGB(8,8,9) frame.BackgroundTransparency=.20 frame.BorderSizePixel=0 frame.ZIndex=50 corner(frame,1) stroke(frame,Color3.fromRGB(122,122,128),1,.58) frame:SetAttribute("Style","DistrictInspired")
 local limit=Instance.new("UISizeConstraint",frame) limit.MaxSize=Vector2.new(660,460)
 local tabs=Instance.new("Frame",frame) tabs.BackgroundTransparency=1 tabs.Size=UDim2.new(1,-20,0,38) tabs.Position=UDim2.fromOffset(10,10) tabs.ZIndex=51
 local title=label(frame,"",UDim2.new(1,-30,0,28),UDim2.fromOffset(15,56),Enum.Font.GothamBold) title.TextSize=15 title.TextColor3=Color3.fromRGB(205,205,210)
 local content=Instance.new("ScrollingFrame",frame) content.Position=UDim2.fromOffset(15,88) content.Size=UDim2.new(1,-30,1,-103) content.BackgroundTransparency=1 content.BorderSizePixel=0 content.AutomaticCanvasSize=Enum.AutomaticSize.Y content.CanvasSize=UDim2.new() content.ScrollBarThickness=2 content.ZIndex=51
 local list=Instance.new("UIListLayout",content) list.Padding=UDim.new(0,4) list.SortOrder=Enum.SortOrder.LayoutOrder
 local active={} local tabButtons={} local drag=nil
 local function setValue(row,v)
  if row.min then local st=row.step or 1 v=math.clamp(v,row.min,row.max) v=math.floor(v/st+.5)*st end
  if row.key=="AFK" then game.ReplicatedStorage.Survival.Action:FireServer("afk",v) else player:SetAttribute(row.key,v) end
 end
 local function clear() drag=nil for _,c in ipairs(active) do c:Disconnect() end table.clear(active) for _,o in ipairs(content:GetChildren()) do if o:IsA("GuiObject") then o:Destroy() end end end
 local function select(cat)
  clear() title.Text=cat.title
  for k,b in pairs(tabButtons) do b.BackgroundTransparency=k==cat.key and .05 or .65 end
  for i,row in ipairs(cat.rows) do
   local cell=Instance.new("Frame",content) cell.LayoutOrder=i cell.Size=UDim2.new(1,-4,0,row.section and 28 or row.info and 44 or 62) cell.BackgroundTransparency=1 cell.ZIndex=52
   if row.section then local t=label(cell,row.section,UDim2.fromScale(1,1)) t.Font=Enum.Font.GothamBold t.TextSize=12 t.TextColor3=Color3.fromRGB(152,152,160)
   elseif row.info then local t=label(cell,row.info,UDim2.new(1,-8,1,0),nil,Enum.Font.Gotham) t.TextSize=12 t.TextColor3=Color3.fromRGB(176,176,184)
   else
    local n=label(cell,row.label,UDim2.new(.52,-8,0,28),UDim2.fromOffset(0,5),Enum.Font.GothamBold) n.TextSize=13
    local d=label(cell,row.description,UDim2.new(.54,-8,0,27),UDim2.fromOffset(0,33)) d.TextSize=10 d.TextColor3=Color3.fromRGB(154,154,162)
    if row.min then
     local track=Instance.new("TextButton",cell) track.Text="" track.BackgroundColor3=Color3.fromRGB(32,31,31) track.BorderSizePixel=0 track.Position=UDim2.new(.58,0,.5,-5) track.Size=UDim2.new(.28,0,0,10) track.ZIndex=54 corner(track,2)
     local fill=Instance.new("Frame",track) fill.BackgroundColor3=Color3.fromRGB(198,198,202) fill.BorderSizePixel=0 fill.ZIndex=55 corner(fill,2)
     local val=label(cell,"",UDim2.new(.11,0,1,0),UDim2.new(.88,0,0,0)) val.TextXAlignment=Enum.TextXAlignment.Right val.TextSize=12
     local function refresh() local v=player:GetAttribute(row.key) or row.default local r=(v-row.min)/(row.max-row.min) fill.Size=UDim2.fromScale(r,1) val.Text=tostring(math.floor(v+.5))..(row.suffix or "") end
     local function move(x) setValue(row,row.min+(row.max-row.min)*math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)) end
     track.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then drag={input=input,move=move} move(input.Position.X) end end)
     table.insert(active,player:GetAttributeChangedSignal(row.key):Connect(refresh)) refresh()
    else
     local b=button(cell,"",Color3.fromRGB(100,100,108)) b.Size=UDim2.fromOffset(34,34) b.AnchorPoint=Vector2.new(1,.5) b.Position=UDim2.new(1,-2,.5,0)
     local function refresh() b.Text=player:GetAttribute(row.key)==true and "✓" or "" end
     b.Activated:Connect(function() setValue(row,not player:GetAttribute(row.key)) end)
     table.insert(active,player:GetAttributeChangedSignal(row.key):Connect(refresh)) refresh()
    end
   end
  end
 end
 for i,cat in ipairs(categories) do
  local b=button(tabs,cat.label,cat.color)
  b.Name=cat.key b.Size=UDim2.new(.24,-5,1,0) b.Position=UDim2.new((i-1)*.25,0,0,0)
  b.BackgroundTransparency=.72
  if b:FindFirstChildOfClass("UICorner") then b:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,1) end
  tabButtons[cat.key]=b
  b.Activated:Connect(function() select(cat) end)
 end
 local close=button(tabs,"SAÍDA",Color3.fromRGB(115,82,82))
 close.Size=UDim2.new(.20,0,1,0) close.Position=UDim2.new(.80,0,0,0) close.BackgroundTransparency=.72
 close.Activated:Connect(onClose)
 UIS.InputChanged:Connect(function(input) if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseMovement) then drag.move(input.Position.X) end end)
 UIS.InputEnded:Connect(function(input) if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then drag=nil end end)
 select(categories[1])
 return {frame=frame,select=function() end,setValue=setValue}
end
return Settings