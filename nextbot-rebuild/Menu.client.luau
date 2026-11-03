-- Native reference layout. Art IDs remain unset until audited; never invent ownership or balances.
local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local config=require(package:WaitForChild('Config'))
local gui=Instance.new('ScreenGui');gui.Name='NextbotMenu';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=5;gui.Parent=player:WaitForChild('PlayerGui')
local colors={Color3.fromRGB(91,127,198),Color3.fromRGB(77,147,104),Color3.fromRGB(181,145,82),Color3.fromRGB(142,98,180),Color3.fromRGB(177,75,86),Color3.fromRGB(72,152,166)}
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
local title=label(home,'EVADE',550,210,440,110,78)
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
button(home,'LOJA',400,375,235,104,colors[3],function()show('Shop');drawShop(shopCategory)end)
button(home,'ENTRAR NO JOGO',647,360,243,133,colors[2],function()
 if not package:GetAttribute('MapReady') then message('O mapa desta prévia ainda não está integrado.');return end
 package.MatchAction:FireServer('Join')
end)
button(home,'INVENTÁRIO',903,375,234,104,colors[4],function()show('Inventory');drawInventory(invCategory)end)
local infoTitle=label(pages.Info,'',350,180,840,65,30)
local infoBody=label(pages.Info,'',350,270,840,200,23)
local function info(title,text)infoTitle.Text=title;infoBody.Text=text;show('Info')end
for i,name in ipairs({'TABELA DE CLASSIFICAÇÃO','MISSÕES','COMUNIDADE','COLETÍVEIS'}) do
 button(home,name,1230,450+(i-1)*64,210,52,colors[(i+1)%6+1],function()info(name,'Esta seção ainda não está integrada nesta prévia.')end)
end
button(home,'EVENTO',95,598,220,95,colors[6],function()info('EVENTO','Nenhum evento foi configurado para esta experiência.')end)
button(home,'REGISTRO DE MUDANÇAS',532,625,130,69,colors[6],function()info('REGISTRO DE MUDANÇAS','Menu, navegação, prévia do avatar e configurações em desenvolvimento.')end)
button(home,'Navegador de Modos',672,610,192,84,colors[3],function()info('MODOS','Intervalo: 1:30\nPartida: 3:00\nIntegração do mapa pendente.')end)
button(home,'ASSISTIR',878,625,126,69,colors[4],function()info('ASSISTIR','O modo espectador ainda não está integrado.')end)
for _,name in ipairs({'Shop','Inventory','Info'}) do button(pages[name],'VOLTAR',1340,124,100,58,colors[5],function()show('Home')end) end
local selectedTitle=label(pages.Shop,'',963,457,220,46,25)
local description=panel(pages.Shop,870,510,406,130,colors[3]);local detail=label(description,'',16,10,374,110,23)
local buyPanel,buy=button(pages.Shop,'INDISPONÍVEL',1078,650,198,46,colors[2],function()message('Este item ainda não tem assets e função validados.')end)
buy.Active=false;buy.Selectable=false
local selectedItem
button(pages.Shop,'EQUIPAR',1078,597,198,44,colors[1],function()
 if not selectedItem then return end
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
local function select(item)selectedItem=item;selectedTitle.Text=item.name;detail.Text=item.description;inspect=false;description.Visible=true;buyPanel.Visible=true end
function drawShop(category)
 shopCategory=category;heading.Text=string.upper(category);clear(grid);selectedTitle.Text='';detail.Text='Selecione um item.'
 for _,item in ipairs(config.Catalog) do
  if item.category==category or category=='Em destaque' then
   local p=panel(grid,0,0,136,200,colors[3]);p.LayoutOrder=#grid:GetChildren()
   label(p,tostring(item.price),8,8,120,30,22)
   label(p,item.name,6,145,124,49,18)
   local thumb=make('ImageLabel',p,{Position=UDim2.fromOffset(15,40),Size=UDim2.fromOffset(106,100),BackgroundTransparency=1,Image=item.thumbnailId and 'rbxassetid://'..item.thumbnailId or ''})
   if thumb.Image=='' then label(p,'PRÉVIA\nPENDENTE',10,60,116,70,15) end
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
  local p=button(slots,'+',x,y,150,132,colors[3],function()show('Shop');drawShop('Equipamento')end)
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
  for _,v in ipairs(clone:GetDescendants()) do if v:IsA('LuaSourceContainer') or v:IsA('Sound') or v:IsA('Tool') then v:Destroy() elseif v:IsA('BasePart') then v.Anchored=true end end
  clone:PivotTo(CFrame.new())
  for _,entry in pairs(previewFrames) do
   entry.world:ClearAllChildren();local copy=clone:Clone();copy.Parent=entry.world
   local cf,size=copy:GetBoundingBox();local center=cf.Position
   entry.camera.CFrame=CFrame.lookAt(center+Vector3.new(0,size.Y*.08,-math.max(size.Y*1.3,7)),center)
  end
  clone:Destroy()
 end)
end
player.CharacterAppearanceLoaded:Connect(refreshAvatar)
if player.Character then refreshAvatar(player.Character) end
local function updateStats()
 xpText.Text='NÍVEL '..tostring(player:GetAttribute('NBLevel') or '—')
 local names={Coins='MOEDAS',Points='PONTOS',Vouchers='CUPONS',Wisps='WISPS',Wins='VITÓRIAS'}
 for key,l in pairs(amounts) do l.Text=names[key]..' '..tostring(player:GetAttribute('NB'..key) or '—') end
end
for _,key in ipairs({'Level','Coins','Points','Vouchers','Wisps','Wins'}) do player:GetAttributeChangedSignal('NB'..key):Connect(updateStats) end
updateStats()
player:GetAttributeChangedSignal('NBInRound'):Connect(function()gui.Enabled=not player:GetAttribute('NBInRound')end)
UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.M then gui.Enabled=not gui.Enabled end end)
show('Home')
