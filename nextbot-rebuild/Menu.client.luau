-- Screenshot-driven layout; functionality is supplied by validated server remotes.
local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local player=Players.LocalPlayer
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local config=require(package:WaitForChild('Config'))
local gui=Instance.new('ScreenGui');gui.Name='NextbotMenu';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=5;gui.Parent=player:WaitForChild('PlayerGui')
local colors={Color3.fromRGB(91,127,198),Color3.fromRGB(77,147,104),Color3.fromRGB(181,145,82),Color3.fromRGB(142,98,180),Color3.fromRGB(177,75,86),Color3.fromRGB(72,152,166)}
local emoteCatalog=require(package:WaitForChild('EmoteCatalog'))
local combined=table.clone(config.Catalog)
for _,item in ipairs(emoteCatalog) do table.insert(combined,item) end
local white=Color3.fromRGB(239,239,240)
local function make(class,parent,props)
 local v=Instance.new(class);for k,val in pairs(props or {}) do v[k]=val end;v.Parent=parent;return v
end
local canvas=make('Frame',gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1536,709),BackgroundTransparency=1})
local scale=make('UIScale',canvas)
local function fit()local s=gui.AbsoluteSize;scale.Scale=math.min(s.X/1536,s.Y/709)end
fit();gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
local function label(parent,text,x,y,w,h,size)
 return make('TextLabel',parent,{Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=size or 22,TextColor3=white,TextStrokeColor3=Color3.fromRGB(20,20,23),TextStrokeTransparency=.15,TextWrapped=true})
end
local function panel(parent,x,y,w,h,color)
 local p=make('Frame',parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=Color3.fromRGB(18,20,25),BackgroundTransparency=.2})
 make('UICorner',p,{CornerRadius=UDim.new(0,10)});make('UIStroke',p,{Color=color or colors[1],Thickness=3,Transparency=.15})
 local inner=make('Frame',p,{Position=UDim2.fromOffset(5,5),Size=UDim2.new(1,-10,1,-10),BackgroundTransparency=1})
 make('UICorner',inner,{CornerRadius=UDim.new(0,6)});make('UIStroke',inner,{Color=Color3.fromRGB(190,184,160),Transparency=.65,Thickness=1})
 return p
end
local function button(parent,text,x,y,w,h,color,fn)
 local p=panel(parent,x,y,w,h,color)
 local b=make('TextButton',p,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text='',AutoButtonColor=false})
 label(b,text,8,3,w-16,h-6,21)
 b.Activated:Connect(fn)
 b.MouseEnter:Connect(function()Tween:Create(p,TweenInfo.new(.12),{BackgroundTransparency=.05}):Play()end)
 b.MouseLeave:Connect(function()Tween:Create(p,TweenInfo.new(.12),{BackgroundTransparency=.2}):Play()end)
 return p,b
end
local pages={}
for _,name in ipairs({'Home','Shop','Inventory','Info'}) do pages[name]=make('Frame',canvas,{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=name=='Home'}) end
local active='Home';local transition
local function show(name)
 if transition then transition:Cancel() end
 for key,p in pairs(pages) do p.Visible=key==name end
 active=name
 local page=pages[name];page.Position=UDim2.fromOffset(35,0)
 transition=Tween:Create(page,TweenInfo.new(.24,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(0,0)});transition:Play()
 player:SetAttribute('NBMenuPage',name)
end
local home=pages.Home
local title=label(home,'EXACT RUN',550,210,440,110,78)
make('UIGradient',title,{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,colors[2]),ColorSequenceKeypoint.new(.45,Color3.fromRGB(164,239,243)),ColorSequenceKeypoint.new(1,colors[4])})})
local xp=panel(home,95,121,540,38,colors[1]);local xpText=label(xp,'NÍVEL —',8,0,520,38,20);xpText.TextXAlignment=Enum.TextXAlignment.Left
local amounts={}
for i,entry in ipairs({{'Coins','MOEDAS',colors[2]},{'Points','PONTOS',white},{'Vouchers','CUPONS',colors[3]},{'Wisps','WISPS',colors[4]},{'Wins','VITÓRIAS',colors[3]}}) do
 local p=panel(home,95,167+(i-1)*48,138,40,entry[3]);amounts[entry[1]]=label(p,entry[2]..' —',4,0,130,40,17)
end
local note=label(canvas,'',420,665,700,34,16)
local function message(text)note.Text=text;task.delay(4,function()if note.Text==text then note.Text='' end end)end
local shopCategory='Equipamento';local invCategory='Equipamento'
local drawShop,drawInventory
local shopCard=button(home,'LOJA',400,375,235,104,colors[3],function()show('Shop');drawShop(shopCategory)end)
local playCard=button(home,'ENTRAR NO JOGO',647,360,243,133,colors[2],function()
 if not package:GetAttribute('MapReady') then message('O mapa está carregando.');return end
 package.MatchAction:FireServer('Join');message(package:GetAttribute('Phase')=='Round' and 'Entrando na rodada…'or 'Você entrou na fila. A rodada começa após o intervalo.')
end)
local inventoryCard=button(home,'INVENTÁRIO',903,375,234,104,colors[4],function()show('Inventory');drawInventory(invCategory)end)
local infoTitle=label(pages.Info,'',350,180,840,65,30)
local infoBody=label(pages.Info,'',350,270,840,200,23)
local function info(title,text)infoTitle.Text=title;infoBody.Text=text;show('Info')end
local infoContent=make('ScrollingFrame',pages.Info,{Position=UDim2.fromOffset(330,250),Size=UDim2.fromOffset(900,390),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=5})
local function resetInfo(title)
 for _,v in ipairs(infoContent:GetChildren())do v:Destroy()end
 infoTitle.Text=title;infoBody.Text='';show('Info')
end
local function leaderboard()
 resetInfo('TABELA DE CLASSIFICAÇÃO')
 local list=Players:GetPlayers();table.sort(list,function(a,b)return (a:GetAttribute('NBXP')or 0)>(b:GetAttribute('NBXP')or 0)end)
 for i,p in ipairs(list)do label(infoContent,i..'. '..p.DisplayName..'   •   Nível '..tostring(p:GetAttribute('NBLevel')or 1)..'   •   '..tostring(p:GetAttribute('NBWins')or 0)..' vitórias',0,(i-1)*52,890,46,23)end
end
local function missions()
 resetInfo('MISSÕES')
 for i,m in ipairs({{'survivor','Sobreviva a 2 rodadas','NBWins',2,150},{'medic','Reanime 3 jogadores','NBRescues',3,200},{'runner','Complete 5 rodadas','NBRounds',5,300}})do
  local row=panel(infoContent,5,(i-1)*110,880,92,colors[2])
  label(row,m[2]..'  '..math.min(player:GetAttribute(m[3])or 0,m[4])..'/'..m[4],10,10,600,65,23)
  button(row,'RESGATAR '..m[5],640,20,220,52,colors[3],function()package.Economy:FireServer('Claim',m[1])end)
 end
end
local function maps()
 resetInfo('MAPAS • VOTE NA PRÓXIMA ARENA')
 local list=require(package.MapCatalog)
 for i,m in ipairs(list)do
  button(infoContent,m.name,10,(i-1)*115,870,96,colors[(i-1)%6+1],function()package.MatchAction:FireServer('Vote',m.name);message('Voto enviado para '..m.name)end)
 end
end
button(home,'TABELA DE CLASSIFICAÇÃO',1230,450,210,52,colors[3],leaderboard)
button(home,'MISSÕES',1230,514,210,52,colors[1],missions)
button(home,'COMUNIDADE',1230,578,210,52,colors[4],function()resetInfo('COMUNIDADE');label(infoContent,'Jogue em equipe. Use o rádio para marcar sua posição, carregue colegas caídos e reanime para ganhar recompensas.',25,30,850,210,26)end)
button(home,'COLETÍVEIS',1230,642,210,52,colors[3],function()show('Inventory');drawInventory('Cosméticos')end)
button(home,'EVENTO',95,598,220,95,colors[6],function()resetInfo('RODADAS ESPECIAIS');label(infoContent,'A cada 3 rodadas: escuridão, Nextbots mais rápidos ou o dobro de bots. Sobreviva para receber moedas e experiência.',25,30,850,210,26)end)
button(home,'REGISTRO DE MUDANÇAS',532,625,130,69,colors[6],function()resetInfo('REGISTRO DE MUDANÇAS');label(infoContent,'Arenas da comunidade, votação, lobby, 19 emotes R6, progressão, equipamentos, queda, resgate e carregamento. Intervalo de 1:30 e rodadas de 3:00.',25,25,850,240,24)end)
button(home,'Navegador de Modos',672,610,192,84,colors[3],maps)
button(home,'ASSISTIR',878,625,126,69,colors[4],function()package.MatchAction:FireServer('Spectate')end)
for i,card in ipairs({shopCard,playCard,inventoryCard})do
 local atlas=package:GetAttribute('MenuAtlas')
 if atlas then
  local art=make('ImageLabel',card,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=atlas,ImageRectOffset=Vector2.new(0,(i-1)*512),ImageRectSize=Vector2.new(1024,512),ScaleType=Enum.ScaleType.Crop,ZIndex=1})
  make('UICorner',art,{CornerRadius=UDim.new(0,10)})
  local b=card:FindFirstChildOfClass('TextButton');b.ZIndex=2;local l=b:FindFirstChildOfClass('TextLabel');l.ZIndex=3;l.Position=UDim2.new(0,5,1,-36);l.Size=UDim2.new(1,-10,0,32)
 end
end
local queue=label(home,'',520,518,510,35,20)
for _,name in ipairs({'Shop','Inventory','Info'}) do button(pages[name],'VOLTAR',1340,124,100,58,colors[5],function()show('Home')end) end
local selectedTitle=label(pages.Shop,'',963,457,220,46,25)
local description=panel(pages.Shop,870,510,406,130,colors[3]);local detail=label(description,'',16,10,374,110,23)
local selectedItem
local emoteSlot=1
local buyPanel,buy=button(pages.Shop,'INDISPONÍVEL',1078,650,198,46,colors[2],function()
 if selectedItem and selectedItem.available then if selectedItem.source then package.Emotes:FireServer('Buy',selectedItem.id)else package.Economy:FireServer('Buy',selectedItem.id)end else message('Item ainda não disponível.')end
end)
buy.Active=false;buy.Selectable=false
button(pages.Shop,'EQUIPAR',1078,597,198,44,colors[1],function()
 if not selectedItem then return end
 if selectedItem.source then package.Emotes:FireServer('Equip',selectedItem.id,emoteSlot);return end
 if selectedItem.category=='Personagem'then package.Economy:FireServer('Perk',selectedItem.id);return end
 local owned=player:GetAttribute('NBOwned_'..selectedItem.id) or 0
 if owned<=0 then message('Você não possui este item.');return end
 if player:GetAttribute('NBInRound') then message('Equipe no lobby antes da rodada.');return end
 package:WaitForChild('Equipment'):FireServer('Equip',selectedItem.id)
end)
local inspect=false
button(pages.Shop,'INSPECIONAR',870,650,197,46,colors[1],function()
 inspect=not inspect;description.Visible=not inspect;buyPanel.Visible=not inspect
end)
local grid=make('ScrollingFrame',pages.Shop,{Position=UDim2.fromOffset(100,278),Size=UDim2.fromOffset(570,417),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
make('UIGridLayout',grid,{CellSize=UDim2.fromOffset(136,200),CellPadding=UDim2.fromOffset(7,12),SortOrder=Enum.SortOrder.LayoutOrder})
local heading=label(pages.Shop,'',95,210,575,53,26);heading.TextXAlignment=Enum.TextXAlignment.Left
local function clear(parent)for _,v in ipairs(parent:GetChildren()) do if v:IsA('GuiObject') then v:Destroy() end end end
local function select(item)selectedItem=item;buy.Active=item.available==true;buy.Selectable=buy.Active;buy:FindFirstChildOfClass('TextLabel').Text=item.available and ('COMPRAR '..item.price) or 'INDISPONÍVEL';selectedTitle.Text=item.name;detail.Text=item.description;inspect=false;description.Visible=true;buyPanel.Visible=true end
function drawShop(category)
 shopCategory=category;heading.Text=string.upper(category);clear(grid);selectedTitle.Text='';detail.Text='Selecione um item.'
 for _,item in ipairs(combined) do
  if item.category==category or category=='Em destaque' then
   local p=panel(grid,0,0,136,200,colors[3]);p.LayoutOrder=(item.available and 0 or 1000)+#grid:GetChildren()
   label(p,tostring(item.price),8,8,120,30,22)
   label(p,item.name,6,145,124,49,18)
   local thumb=make('ImageLabel',p,{Position=UDim2.fromOffset(15,40),Size=UDim2.fromOffset(106,100),BackgroundTransparency=1,Image=item.thumbnailId and 'rbxassetid://'..item.thumbnailId or ''})
   if thumb.Image=='' then
    local icons={flashlight='◉',compass='✥',timer='3:00',radio='▥',baton='╱',radar='◎',decoy='♟',headlamp='◉',nvg='◉◉',barrier='▦',cola='▯'}
    local icon=label(p,icons[item.id]or (item.category=='Animações'and '♫'or '♟'),10,48,116,90,45);icon.TextColor3=colors[item.category=='Animações'and 4 or 2]
   end
   local b=make('TextButton',p,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=''});b.Activated:Connect(function()select(item)end)
  end
 end
 if #grid:GetChildren()==1 then label(grid,'Nenhum item validado nesta categoria.',0,0,530,70,20) end
end
for i,name in ipairs({'Em destaque','Equipamento','Personagem','Animações','Caixa de som','Robux'}) do
 button(pages.Shop,string.upper(name),95+(i-1)*207,124,198,58,colors[i],function()drawShop(name)end)
end
local slots=make('Frame',pages.Inventory,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=1})
function drawInventory(category)
 invCategory=category;clear(slots)
 local names=category=='Emotes' and {'EMOTE 1','EMOTE 2','EMOTE 3','EMOTE 4','EMOTE 5','EMOTE 6'} or category=='Equipamento' and {'LUZ','UTILIDADE','BASTÃO','MARTELO','USÁVEL 1','USÁVEL 2','USÁVEL 3','USÁVEL 4'} or category=='Caixa de som' and {'CAIXA DE SOM','AURA','LISTAS DE MÚSICAS'} or {'ESPAÇO 1','ESPAÇO 2','ESPAÇO 3','ESPAÇO 4'}
 local count=#names;local half=math.ceil(count/2)
 for i,name in ipairs(names) do
  local side=i>half;local index=side and i-half-1 or i-1
  local x=side and 1120 or 95;local y=255+math.floor(index/2)*172
  if count<=6 then y=245+index*143 else x+=index%2*168 end
  local p=button(slots,'+',x,y,150,132,colors[3],function()if category=='Emotes' then
    emoteSlot=i
    local id=player:GetAttribute('NBEmoteSlot'..i)
    if id and id~='' then package.Emotes:FireServer('Play',id);message('Emote iniciado. Pule para parar.')else show('Shop');drawShop('Animações')end
   else show('Shop');drawShop('Equipamento')end end)
  label(p,name,5,98,140,30,15)
 end
end
for i,name in ipairs({'Equipamento','Personagem','Cosméticos','Emotes','Caixa de som'}) do
 button(pages.Inventory,string.upper(name),95+(i-1)*248,124,237,58,colors[i],function()drawInventory(name)end)
end
-- A WorldModel preview avoids assigning or moving Workspace.CurrentCamera.
local previewFrames={}
for _,name in ipairs({'Shop','Inventory'}) do
 local viewport=make('ViewportFrame',pages[name],{Position=UDim2.fromOffset(name=='Shop' and 890 or 530,195),Size=UDim2.fromOffset(name=='Shop' and 380 or 480,name=='Shop' and 260 or 480),BackgroundTransparency=1,Ambient=Color3.fromRGB(185,185,185),LightColor=Color3.new(1,1,1)})
 local camera=make('Camera',viewport);viewport.CurrentCamera=camera
 local world=make('WorldModel',viewport)
 previewFrames[name]={world=world,camera=camera}
 label(pages[name],player.DisplayName,name=='Shop' and 890 or 530,195,name=='Shop' and 380 or 480,40,30)
end
local generation=0
local function refreshAvatar(char)
 generation+=1;local token=generation
 task.spawn(function()
  if not char:WaitForChild('HumanoidRootPart',10) or token~=generation then return end
  local original=char.Archivable;char.Archivable=true;local ok,clone=pcall(function()return char:Clone()end);char.Archivable=original
  if not ok or not clone then return end
  for _,v in ipairs(clone:GetDescendants()) do if v:IsA('LuaSourceContainer') or v:IsA('Sound') or v:IsA('Tool') then v:Destroy() elseif v:IsA('BasePart')then v.Anchored=v.Name=='HumanoidRootPart';v.CanCollide=false end end
  clone:PivotTo(CFrame.new())
  for _,entry in pairs(previewFrames) do
   entry.world:ClearAllChildren();local copy=clone:Clone();copy.Parent=entry.world;entry.character=copy;entry.motors=require(package.PosePlayer).Motors(copy)
   local cf,size=copy:GetBoundingBox();local center=cf.Position
   entry.camera.CFrame=CFrame.lookAt(center+Vector3.new(0,size.Y*.08,-math.max(size.Y*1.3,7)),center)
  end
  clone:Destroy()
 end)
end
player.CharacterAppearanceLoaded:Connect(refreshAvatar)
if player.Character then refreshAvatar(player.Character) end
local function updateStats()
 xpText.Text='NÍVEL '..tostring(player:GetAttribute('NBLevel')or 1)..'                                    '..tostring((player:GetAttribute('NBXP')or 0)%250)..'/250'
 local names={Coins='MOEDAS',Points='PONTOS',Vouchers='CUPONS',Wisps='WISPS',Wins='VITÓRIAS'}
 for key,l in pairs(amounts) do l.Text=names[key]..' '..tostring(player:GetAttribute('NB'..key) or '—') end
end
for _,key in ipairs({'Level','Coins','Points','Vouchers','Wisps','Wins'}) do player:GetAttributeChangedSignal('NB'..key):Connect(updateStats) end
updateStats()
local function visibility()gui.Enabled=not player:GetAttribute('NBInRound')and not player:GetAttribute('NBSpectating')end
player:GetAttributeChangedSignal('NBInRound'):Connect(visibility);player:GetAttributeChangedSignal('NBSpectating'):Connect(visibility);visibility()
UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.M then if player:GetAttribute('NBInRound')then package.MatchAction:FireServer('Lobby')else show('Home')end end end)
show('Home')

local function transaction(status)
 local messages={purchased='Emote comprado.',owned='Você já possui este emote.',funds='Moedas insuficientes.',equipped='Emote equipado.',claimed='Recompensa já resgatada.',reward='Recompensa recebida.',incomplete='Missão ainda incompleta.',empty='Você não possui este equipamento.',save_failed='Não foi possível salvar a compra.',unavailable='Inventário ainda não carregado.'}
 message(messages[status] or 'Operação recusada.')
end
package.Emotes.OnClientEvent:Connect(transaction);package.Economy.OnClientEvent:Connect(transaction);package.Equipment.OnClientEvent:Connect(function(status)if status~='ping'then transaction(status)end end)

local pose=require(package.PosePlayer);local elapsed=0
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt
 local remaining=math.max(0,math.ceil((package:GetAttribute('Deadline')or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()))
 queue.Text=player:GetAttribute('NBQueued')and string.format('NA FILA • %d:%02d',math.floor(remaining/60),remaining%60)or (package:GetAttribute('MapName')or '')
 if not gui.Enabled then return end
 local entry=previewFrames[active]
 if entry and entry.motors then
  local sequence=selectedItem and selectedItem.source and package.EmoteClips:FindFirstChild(selectedItem.id)or package.MovementClips:FindFirstChild('idle')
  if sequence then local data=pose.Decode(sequence);pose.Apply(data,entry.motors,data.duration>0 and elapsed%data.duration or 0,math.min(dt*15,1))end
 end
end)
