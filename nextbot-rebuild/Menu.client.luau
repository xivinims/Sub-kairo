-- Safe-area menu. All content reflows from the actual client viewport.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local config=require(package:WaitForChild('Config'))
local policy=require(package:WaitForChild('InventoryPolicy'))
local pose=require(package:WaitForChild('PosePlayer'))
local catalog=table.clone(config.Catalog)
for _,item in ipairs(require(package:WaitForChild('EmoteCatalog')))do table.insert(catalog,item)end
local byId={};for _,item in ipairs(catalog)do byId[item.id]=item end
local white=Color3.fromRGB(239,243,248)
local muted=Color3.fromRGB(170,184,202)
local accent=Color3.fromRGB(143,225,194)
local function new(class,parent,props)
 local o=Instance.new(class);for k,v in pairs(props or {})do o[k]=v end;o.Parent=parent;return o
end
local gui=new('ScreenGui',player:WaitForChild('PlayerGui'),{Name='NextbotMenu',Enabled=false,ResetOnSpawn=false,IgnoreGuiInset=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,DisplayOrder=5,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
new('Frame',gui,{Name='Shade',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(9,13,22),BackgroundTransparency=.22,BorderSizePixel=0})
local root=new('Frame',gui,{Name='SafeContent',Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-32,1,-24),BackgroundTransparency=1})
local function label(parent,value,size,color)
 return new('TextLabel',parent,{Text=value,BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=size or 18,TextColor3=color or white,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})
end
local function surface(parent)
 local p=new('Frame',parent,{BackgroundColor3=Color3.fromRGB(22,29,42),BackgroundTransparency=.12,BorderSizePixel=0})
 new('UICorner',p,{CornerRadius=UDim.new(0,12)});new('UIStroke',p,{Color=Color3.fromRGB(81,104,130),Transparency=.4})
 return p
end
local function button(parent,value,fn)
 local b=new('TextButton',parent,{Text=value,Font=Enum.Font.GothamBold,TextSize=16,TextColor3=white,TextWrapped=true,BackgroundColor3=Color3.fromRGB(43,63,82),BorderSizePixel=0,AutoButtonColor=true})
 new('UICorner',b,{CornerRadius=UDim.new(0,9)})
 if fn then b.Activated:Connect(fn)end
 return b
end
local function place(o,x,y,w,h)o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(math.max(w,0),math.max(h,0))end
local function clear(o)for _,v in ipairs(o:GetChildren())do if v:IsA('GuiObject')then v:Destroy()end end end
local function scroll(parent)
 return new('ScrollingFrame',parent,{BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=4,ScrollBarImageColor3=muted,ClipsDescendants=true})
end
local header=new('Frame',root,{BackgroundTransparency=1})
local heading=label(header,'EXACT RUN',24)
local stats=label(header,'',15,accent);stats.TextXAlignment=Enum.TextXAlignment.Right;stats.TextTruncate=Enum.TextTruncate.AtEnd
local back
local toast=label(root,'',15,accent);toast.Name='TransactionStatus';toast.TextTruncate=Enum.TextTruncate.AtEnd
local toastSerial=0
local function message(value)
 toastSerial+=1;local token=toastSerial;toast.Text=value
 task.delay(5,function()if token==toastSerial then toast.Text=''end end)
end
local tabs=new('ScrollingFrame',root,{Name='Categories',BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=2})
new('UIListLayout',tabs,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local body=new('Frame',root,{BackgroundTransparency=1})
local pages={};for _,name in ipairs({'Home','Shop','Inventory','Info'})do pages[name]=new('Frame',body,{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=name=='Home'})end
local active='Home';local category='Equipamento';local inventoryCategory='Equipamento';local inventoryFilter
local selected;local emoteSlot=1;local equipmentSlot=1;local perkSlot=1;local previewStarted=0
local layout,drawShop,drawInventory,drawTabs,refreshSelection
local function owned(item)return policy.IsOwned(item,player:GetAttribute('NBOwned_'..item.id),player:GetAttribute('NBEmoteOwned_'..item.id))end
local function show(name)
 active=name;for key,p in pairs(pages)do p.Visible=key==name end
 player:SetAttribute('NBMenuPage',name);player:SetAttribute('NBMenuOpen',true)
 if drawTabs then drawTabs()end;if layout then layout()end
end
back=button(header,'VOLTAR',function()
 if active=='Shop'and inventoryFilter then inventoryFilter=nil;show('Inventory');drawInventory(inventoryCategory)
 else inventoryFilter=nil;show('Home')end
end)
local hero=surface(pages.Home)
local logo=require(game:GetService('ReplicatedFirst'):WaitForChild('LoadingView')).Logo(hero,UDim2.fromScale(.5,.2),UDim2.fromOffset(300,82))
local heroAvatarFrame=new('Frame',hero,{Name='AvatarPreview',BackgroundTransparency=1,ClipsDescendants=true})
local heroAvatar;local heroBindings
local welcome=label(hero,'',17);welcome.TextXAlignment=Enum.TextXAlignment.Center
local queue=label(hero,'',15,muted);queue.TextXAlignment=Enum.TextXAlignment.Center
local homeActions=scroll(pages.Home)
new('UIListLayout',homeActions,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
local actions={}
local function homeButton(value,fn)
 local b=button(homeActions,value,fn);b.LayoutOrder=#actions+1;b.Size=UDim2.new(1,-6,0,58);table.insert(actions,b);return b
end
local play=homeButton('ENTRAR NO JOGO',function()
 if not package:GetAttribute('MapReady')then message('O mapa está carregando.');return end
 package.MatchAction:FireServer('Join');message('Carregando sua entrada na arena…')
end)
play.BackgroundColor3=Color3.fromRGB(37,107,86)
homeButton('LOJA',function()inventoryFilter=nil;show('Shop');drawShop(category)end)
homeButton('INVENTÁRIO',function()show('Inventory');drawInventory(inventoryCategory)end)
local infoScroll=scroll(pages.Info);new('UIListLayout',infoScroll,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
local function info(title,rows)
 clear(infoScroll);heading.Text=title;show('Info');heading.Text=title
 for i,row in ipairs(rows)do local l=label(infoScroll,row,18);l.LayoutOrder=i;l.Size=UDim2.new(1,-12,0,76);l.TextYAlignment=Enum.TextYAlignment.Top end
end
homeButton('MISSÕES',function()
 clear(infoScroll);show('Info');heading.Text='MISSÕES'
 for i,m in ipairs({{'survivor','Sobreviva a 2 rodadas','NBWins',2,150},{'medic','Reanime 3 jogadores','NBRescues',3,200},{'runner','Complete 5 rodadas','NBRounds',5,300}})do
  local row=surface(infoScroll);row.Size=UDim2.new(1,-8,0,116);row.LayoutOrder=i
  local t=label(row,m[2]..' • '..math.min(player:GetAttribute(m[3])or 0,m[4])..'/'..m[4],17);t.Position=UDim2.fromOffset(14,10);t.Size=UDim2.new(1,-28,0,34)
  local claim=button(row,'RESGATAR '..m[5]..' MOEDAS',function()package.Economy:FireServer('Claim',m[1])end);claim.Position=UDim2.fromOffset(14,56);claim.Size=UDim2.new(1,-28,0,44)
 end
end)
homeButton('CLASSIFICAÇÃO',function()
 local list=Players:GetPlayers();table.sort(list,function(a,b)return (a:GetAttribute('NBXP')or 0)>(b:GetAttribute('NBXP')or 0)end)
 local rows={};for i,p in ipairs(list)do table.insert(rows,i..'. '..p.DisplayName..' • Nível '..tostring(p:GetAttribute('NBLevel')or 1)..' • '..tostring(p:GetAttribute('NBWins')or 0)..' vitórias')end
 info('CLASSIFICAÇÃO',rows)
end)
homeButton('ASSISTIR À RODADA',function()package.MatchAction:FireServer('Spectate')end)
homeButton('CAIXA DE SOM',function()player:SetAttribute('NBOpenBoombox',true)end)
homeButton('RODADAS E AJUDA',function()
 info('COMO JOGAR',{'Reanime colegas caídos, corra dos perseguidores e sobreviva para ganhar moedas. Equipe seus itens e até seis emotes no inventário.', 'O intervalo dura 30 segundos. Vote na próxima arena quando a votação abrir. A contagem de votos aparece em cada mapa.', 'A cada 3 rodadas normais podem vir 1 ou 2 rodadas especiais com perseguidores. O modo aparece no topo durante a partida.'})
end)
local grid=scroll(pages.Shop)
local gridLayout=new('UIGridLayout',grid,{CellSize=UDim2.fromOffset(148,178),CellPadding=UDim2.fromOffset(10,10),SortOrder=Enum.SortOrder.LayoutOrder})
local detail=surface(pages.Shop);detail.ClipsDescendants=true
local itemTitle=label(detail,'Selecione um item',21)
local itemDescription=label(detail,'Toque em um item para ver os detalhes.',15,muted);itemDescription.TextYAlignment=Enum.TextYAlignment.Top
itemTitle.TextTruncate=Enum.TextTruncate.AtEnd;itemDescription.TextTruncate=Enum.TextTruncate.AtEnd
local itemStatus=label(detail,'',14,accent)
local art=new('Frame',detail,{Name='ItemPreview',BackgroundTransparency=1,ClipsDescendants=true})
local buy=button(detail,'COMPRAR',function()
 if not selected or not selected.available then return end
 if selected.source then package.Emotes:FireServer('Buy',selected.id)else package.Economy:FireServer('Buy',selected.id)end
end)
local equip=button(detail,'EQUIPAR',function()
 if not selected or not owned(selected)then return end
 if selected.source then package.Emotes:FireServer('Equip',selected.id,emoteSlot)
 elseif selected.category=='Personagem'then package.Economy:FireServer('Perk',selected.id,perkSlot)
 else package.Equipment:FireServer('Equip',selected.id,equipmentSlot)end
end)
local empty=label(grid,'',17,muted);empty.Visible=false
local inventory=scroll(pages.Inventory)
local invLayout=new('UIGridLayout',inventory,{CellSize=UDim2.fromOffset(180,164),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder})
local inventoryHint=label(pages.Inventory,'Selecione um espaço para equipar um item que você possui.',16,muted)
local preview
local function sourceThumbnail(item)
 if item.thumbnailId and tonumber(item.thumbnailId)and tonumber(item.thumbnailId)>0 then return 'rbxassetid://'..item.thumbnailId end
 local id=item.sourceAssetId or item.assetId
 if id and tonumber(id)and tonumber(id)>0 then return 'rbxthumb://type=Asset&id='..tostring(id)..'&w=420&h=420'end
 return ''
end
local function itemArt(parent,item)
 local image=sourceThumbnail(item)
 if image~=''then new('ImageLabel',parent,{Image=image,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit})
 else
  local l=label(parent,item.source and 'R6' or item.category=='Personagem'and 'VANTAGEM'or 'EQUIPAMENTO',14,muted);l.Size=UDim2.fromScale(1,1);l.TextXAlignment=Enum.TextXAlignment.Center
 end
end
local function avatar(parent)
 if not player.Character then return nil end
 local original=player.Character.Archivable;player.Character.Archivable=true
 local ok,clone=pcall(function()return player.Character:Clone()end);player.Character.Archivable=original
 if not ok or not clone then return nil end
 for _,v in ipairs(clone:GetDescendants())do
  if v:IsA('LuaSourceContainer')or v:IsA('Sound')or v:IsA('Tool')or v:IsA('BillboardGui')or v:IsA('ProximityPrompt')then v:Destroy()
  elseif v:IsA('BasePart')then v.Anchored=v.Name=='HumanoidRootPart';v.CanCollide=false end
 end
 clone:PivotTo(CFrame.new())
 local viewport=new('ViewportFrame',parent,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Ambient=Color3.fromRGB(180,190,205),LightColor=Color3.new(1,1,1)})
 local world=new('WorldModel',viewport);clone.Parent=world
 local camera=new('Camera',viewport,{FieldOfView=36});viewport.CurrentCamera=camera
 local cf,size=clone:GetBoundingBox();local aspect=math.max(parent.AbsoluteSize.X,1)/math.max(parent.AbsoluteSize.Y,1)
 local distance=math.max(size.Y*.5/math.tan(math.rad(18)),size.X*.5/(math.tan(math.rad(18))*aspect))+size.Z*.5
 camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,size.Y*.025,-distance*1.1),cf.Position)
 return {viewport=viewport,character=clone,camera=camera,motors=pose.Motors(clone)}
end
refreshSelection=function()
 clear(art);preview=nil
 buy.Visible=selected~=nil and inventoryFilter==nil;equip.Visible=selected~=nil and owned(selected)
 buy.Active=selected~=nil and selected.available==true;buy.Selectable=buy.Active
 equip.Active=selected~=nil and owned(selected);equip.Selectable=equip.Active
 if not selected then itemTitle.Text='Selecione um item';itemDescription.Text='Toque em um item para ver os detalhes.';itemStatus.Text='';return end
 itemTitle.Text=selected.name;itemDescription.Text=selected.description or ''
 local count=player:GetAttribute('NBOwned_'..selected.id)or 0
 itemStatus.Text=owned(selected)and (selected.source and 'POSSUÍDO • EMOTE '..emoteSlot or selected.category=='Personagem'and 'POSSUÍDO • VANTAGEM '..perkSlot or 'NO INVENTÁRIO ×'..count)or tostring(selected.price or 0)..' MOEDAS'
 buy.Text='COMPRAR • '..tostring(selected.price or 0)
 if selected.source then preview=avatar(art)else itemArt(art,selected)end
 if inventoryFilter and not owned(selected)then equip.Visible=false end
 if layout then layout()end
end
local function choose(item)selected=item;previewStarted=os.clock();refreshSelection()end
function drawShop(value)
 category=value;clear(grid);empty=label(grid,'',17,muted);empty.Visible=false
 selected=nil;refreshSelection();grid.CanvasPosition=Vector2.zero
 local count=0
 for _,item in ipairs(catalog)do
  if policy.Visible(item,value,inventoryFilter,owned(item))then
   count+=1;local card=button(grid,'',function()choose(item)end);card.Name='Item_'..item.id;card.LayoutOrder=count
   local thumb=new('Frame',card,{Position=UDim2.fromOffset(10,9),Size=UDim2.new(1,-20,1,-78),BackgroundTransparency=1});itemArt(thumb,item)
   local title=label(card,item.name,15);title.Position=UDim2.new(0,9,1,-65);title.Size=UDim2.new(1,-18,0,38);title.TextXAlignment=Enum.TextXAlignment.Center
   local price=label(card,owned(item)and 'POSSUÍDO'or tostring(item.price or 0)..' MOEDAS',12,accent);price.Position=UDim2.new(0,8,1,-26);price.Size=UDim2.new(1,-16,0,20);price.TextXAlignment=Enum.TextXAlignment.Center
  end
 end
 if count==0 then empty.Visible=true;empty.Text=inventoryFilter and 'Você ainda não possui itens para este espaço. Compre-os na loja e volte para equipar.'or 'Nenhum item disponível nesta categoria.'end
 drawTabs();if layout then layout()end
end
function drawInventory(value)
 inventoryCategory=value;clear(inventory);inventory.CanvasPosition=Vector2.zero
 local names=value=='Emotes'and {'EMOTE 1','EMOTE 2','EMOTE 3','EMOTE 4','EMOTE 5','EMOTE 6'}or value=='Personagem'and {'VANTAGEM 1','VANTAGEM 2'}or {'LUZ','UTILIDADE','PODER','USÁVEL 1','USÁVEL 2','USÁVEL 3','USÁVEL 4'}
 for i,name in ipairs(names)do
  local id
  if value=='Emotes'then id=player:GetAttribute('NBEmoteSlot'..i)
  elseif value=='Personagem'then id=player:GetAttribute(i==1 and 'NBPerk'or 'NBPerk2')
  else id=i==1 and (player:GetAttribute('NBLightID')or 'flashlight')or i==2 and player:GetAttribute('NBUtility')or i==3 and player:GetAttribute('NBPower')or player:GetAttribute('NBUsable'..(i-3))end
  local item=byId[id]
  local b=button(inventory,'',function()
   if value=='Emotes'then emoteSlot=i;inventoryFilter='Emote';category='Animações'
   elseif value=='Personagem'then perkSlot=i;inventoryFilter='Perk';category='Personagem'
   else equipmentSlot=i>=4 and i-3 or 1;inventoryFilter=i==1 and 'Light'or i==2 and 'Utility'or i==3 and 'Power'or 'Usable';category='Equipamento'end
   show('Shop');drawShop(category);if item then choose(item)end
  end);b.LayoutOrder=i;b.Name='Slot'..i
  local top=label(b,name,12,accent);top.Position=UDim2.fromOffset(12,8);top.Size=UDim2.new(1,-24,0,22)
  local frame=new('Frame',b,{Position=UDim2.fromOffset(20,34),Size=UDim2.new(1,-40,1,-89),BackgroundTransparency=1})
  if item then itemArt(frame,item)else local plus=label(frame,'+',30,muted);plus.Size=UDim2.fromScale(1,1);plus.TextXAlignment=Enum.TextXAlignment.Center end
  local title=label(b,item and item.name or 'TOQUE PARA EQUIPAR',14);title.Position=UDim2.new(0,10,1,-47);title.Size=UDim2.new(1,-20,0,38);title.TextXAlignment=Enum.TextXAlignment.Center
 end
 drawTabs();if layout then layout()end
end
function drawTabs()
 clear(tabs);tabs.CanvasPosition=Vector2.zero
 local list=active=='Shop'and (inventoryFilter and {'MEUS ITENS','VER LOJA'}or {'Equipamento','Personagem','Animações'})or active=='Inventory'and {'Equipamento','Emotes','Personagem'}or {}
 for i,name in ipairs(list)do
  local b=button(tabs,string.upper(name),function()
   if active=='Shop'then if name=='VER LOJA'then inventoryFilter=nil;drawShop(category)elseif not inventoryFilter then drawShop(name)end
   else drawInventory(name)end
  end);b.LayoutOrder=i;b.Size=UDim2.fromOffset(math.max(128,#name*9+28),42)
  if name==category or name==inventoryCategory or name=='MEUS ITENS'then b.BackgroundColor3=Color3.fromRGB(49,91,102)end
 end
end
layout=function()
 local w,h=root.AbsoluteSize.X,root.AbsoluteSize.Y
 if w<1 or h<1 then return end
 local compact=w<700;local tabbed=active=='Shop'or active=='Inventory'
 place(header,0,0,w,50);place(heading,0,0,w*.58,28)
 place(stats,0,30,w-70,20);stats.TextXAlignment=compact and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
 back.Visible=active~='Home';place(back,w-92,0,92,40);if back.Visible then stats.Size=UDim2.fromOffset(math.max(w-108,0),20)end
 if active~='Info'then heading.Text=active=='Home'and 'EXACT RUN'or active=='Inventory'and 'INVENTÁRIO'or inventoryFilter and 'EQUIPAR ITEM'or 'LOJA'end
 if back.Visible then heading.Size=UDim2.fromOffset(math.max(w-108,0),28)end
 tabs.Visible=tabbed;place(tabs,0,60,w,46)
 local bodyY=tabbed and 116 or 64;local bodyH=math.max(80,h-bodyY-42)
 place(body,0,bodyY,w,bodyH);place(toast,0,h-35,w,32)
 place(infoScroll,0,0,w,bodyH)
 local homeW=compact and w or math.min(400,w*.42)
 place(homeActions,0,0,homeW,bodyH)
 hero.Visible=not compact;place(hero,homeW+20,0,w-homeW-20,bodyH)
 logo.Size=UDim2.fromOffset(math.min(320,w-homeW-36),60);logo.Position=UDim2.new(.5,0,0,40)
 place(heroAvatarFrame,12,78,w-homeW-44,math.max(20,bodyH-198))
 place(welcome,12,bodyH-114,w-homeW-44,50);place(queue,12,bodyH-64,w-homeW-44,54)
 local horizontal=w>=760
 if horizontal then
  local left=math.floor(w*.56);place(grid,0,0,left,bodyH);place(detail,left+14,0,w-left-14,bodyH)
 else
  local dh=math.min(234,math.max(184,bodyH*.39));place(detail,0,0,w,dh);place(grid,0,dh+12,w,bodyH-dh-12)
 end
 local dw,dh=detail.Size.X.Offset,detail.Size.Y.Offset
 local previewWidth=horizontal and dw-28 or math.min(94,dw*.27)
 if horizontal then
  place(art,14,12,dw-28,math.max(60,dh*.38));place(itemTitle,14,dh*.4,dw-28,48)
  place(itemDescription,14,dh*.4+54,dw-28,math.max(40,dh*.6-148));place(itemStatus,14,dh-86,dw-28,28)
 else
  place(art,12,12,previewWidth,dh-78);place(itemTitle,previewWidth+24,10,dw-previewWidth-36,42)
  place(itemDescription,previewWidth+24,57,dw-previewWidth-36,math.max(36,dh-142));place(itemStatus,12,dh-80,dw-24,28)
 end
 if preview then
  local cf,size=preview.character:GetBoundingBox();local aspect=math.max(art.Size.X.Offset,1)/math.max(art.Size.Y.Offset,1)
  local distance=math.max(size.Y*.5/math.tan(math.rad(18)),size.X*.5/(math.tan(math.rad(18))*aspect))+size.Z*.5
  preview.camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,size.Y*.025,-distance*1.1),cf.Position)
 end
 local both=buy.Visible and equip.Visible;local bw=both and (dw-34)/2 or dw-28
 place(buy,14,dh-48,bw,36);place(equip,both and 20+bw or 14,dh-48,bw,36)
 local gw=grid.Size.X.Offset;local cols=math.max(1,math.floor((gw+10)/142));local cellW=math.floor((gw-6-(cols-1)*10)/cols)
 gridLayout.CellSize=UDim2.fromOffset(cellW,164);empty.Size=UDim2.fromOffset(math.max(gw-16,0),156)
 place(inventoryHint,0,0,w,44);place(inventory,0,54,w,bodyH-54)
 local invCols=math.max(1,math.floor((w+12)/174));invLayout.CellSize=UDim2.fromOffset(math.floor((w-6-(invCols-1)*12)/invCols),166)
end
root:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
local function updateStats()
 stats.Text=string.format('NÍVEL %d  •  %d / 250 XP  •  %d MOEDAS',player:GetAttribute('NBLevel')or 1,(player:GetAttribute('NBXP')or 0)%250,player:GetAttribute('NBCoins')or 0)
 welcome.Text=player.DisplayName..'\nSobreviva. Reanime. Fuja.'
end
for _,key in ipairs({'NBLevel','NBXP','NBCoins'})do player:GetAttributeChangedSignal(key):Connect(updateStats)end
local function availability()local ready=package:GetAttribute('MapReady')==true;play.Text=ready and 'ENTRAR NO JOGO'or 'CARREGANDO MAPA…';play.Active=ready;play.Selectable=ready end
package:GetAttributeChangedSignal('MapReady'):Connect(availability)
local function visibility()
 gui.Enabled=player.PlayerGui:GetAttribute('NBLoadComplete')==true and not player:GetAttribute('NBInArena')and not player:GetAttribute('NBSpectating')
 player:SetAttribute('NBMenuOpen',gui.Enabled)
end
for _,key in ipairs({'NBInArena','NBSpectating'})do player:GetAttributeChangedSignal(key):Connect(visibility)end
player.PlayerGui:GetAttributeChangedSignal('NBLoadComplete'):Connect(visibility)
local function transaction(status)
 local messages={limit='Limite de equipamentos posicionados atingido.',purchased='Compra salva. Abra o inventário para equipar.',owned='Você já possui este item.',funds='Moedas insuficientes.',equipped='Item equipado.',claimed='Recompensa já resgatada.',reward='Recompensa recebida.',incomplete='Missão ainda incompleta.',empty='Você não possui este equipamento.',save_failed='Não foi possível salvar. Tente novamente.',unavailable='Seu inventário ainda está carregando.'}
 if messages[status]then message(messages[status])end
 if active=='Inventory'then drawInventory(inventoryCategory)elseif active=='Shop'then local previous=selected;drawShop(category);if previous then choose(previous)end end
end
package.Emotes.OnClientEvent:Connect(transaction);package.Economy.OnClientEvent:Connect(transaction)
package.Equipment.OnClientEvent:Connect(function(status)if status~='ping'then transaction(status)end end)
package.MatchAction.OnClientEvent:Connect(function(status)if status=='loading'then message('A arena está carregando.')elseif status=='character'then message('Seu personagem está carregando.')end end)
local function refreshHero()clear(heroAvatarFrame);heroAvatar=avatar(heroAvatarFrame);heroBindings=pose.Bindings(package.MovementSourceRig)end
player.CharacterAppearanceLoaded:Connect(function()refreshHero();if active=='Shop'then refreshSelection()end end)
player:GetAttributeChangedSignal('NBAppearanceRevision'):Connect(function()refreshHero();if active=='Shop'then refreshSelection()end end)
UIS.InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.M then if player:GetAttribute('NBInArena')then package.MatchAction:FireServer('Lobby')else show('Home')end end
end)
Run.RenderStepped:Connect(function()
 if not gui.Enabled then return end
 local phase=package:GetAttribute('Phase')or 'Carregando'
 local remaining=math.max(0,math.ceil((package:GetAttribute('Deadline')or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()))
 queue.Text=string.format('%s\n%s • %d:%02d',package:GetAttribute('MapName')or 'Carregando arena',phase=='Round'and 'RODADA'or phase=='Voting'and 'VOTAÇÃO'or 'INTERVALO',math.floor(remaining/60),remaining%60)
 if active=='Home'and hero.Visible and heroAvatar then local sequence=package.MovementClips:FindFirstChild('idle');if sequence then local data=pose.Decode(sequence);pose.Apply(data,heroAvatar.motors,data.duration>0 and os.clock()%data.duration or 0,1,heroBindings)end end
 if active=='Shop'and preview and selected and selected.source then
  local sequence=package.EmoteClips:FindFirstChild(selected.id)
  if sequence then local data=pose.Decode(sequence);pose.Apply(data,preview.motors,data.duration>0 and (os.clock()-previewStarted)%data.duration or 0,1)end
 end
end)
updateStats();availability();show('Home');layout();if player.Character then refreshHero()end;visibility()
player.PlayerGui:SetAttribute('NBInterfaceReady',true)
