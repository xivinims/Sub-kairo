local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local CAS=game:GetService('ContextActionService')
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local GuiService=game:GetService('GuiService')
local player=Players.LocalPlayer
local C=require(RS:WaitForChild('FalloutConfig'))
local UI=require(RS:WaitForChild('FalloutUI'))
local LobbyHealth=require(RS:WaitForChild('FalloutHealthUI'))
local CombatHUD=require(RS:WaitForChild('FalloutCombatHUD'))
local net=RS:WaitForChild('FalloutNet')
local gui=Instance.new('ScreenGui');gui.Name='FalloutHUD';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=30;gui.Parent=player:WaitForChild('PlayerGui')
local state={phase='Waiting',deadline=0,scores={0,0},roster={}}
local touch=UIS.TouchEnabled
local colors={Color3.fromRGB(88,175,240),Color3.fromRGB(237,100,98)}
local function make(class,parent,props)
 local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local function label(parent,text,size,pos,font)
 return make('TextLabel',parent,{Text=text,Size=size,Position=pos,Font=font or Enum.Font.GothamMedium,TextSize=16,TextColor3=Color3.fromRGB(237,239,230),BackgroundTransparency=1,TextWrapped=true})
end
local function corner(o,n)make('UICorner',o,{CornerRadius=UDim.new(0,n or 10)}) end
local function button(parent,text,size,pos,callback)
 local b=make('TextButton',parent,{Text=text,Size=size,Position=pos,Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(240,241,228),BackgroundColor3=Color3.fromRGB(39,47,43),BorderSizePixel=0,AutoButtonColor=true});corner(b,8);b.Activated:Connect(callback);return b
end
local board=UI.scoreboard(player.PlayerGui,colors)
local score,clock,slots=board.score,board.clock,board.slots
local wallet=UI.wallet(gui)
local lobbyHealth=LobbyHealth.create(player.PlayerGui,RS:WaitForChild('LobbyHealthTemplate'))
local combat=CombatHUD.create(player.PlayerGui,UI,function(id)
 if state.phase~='Match' or player:GetAttribute('Downed') then return end
 local character=player.Character;local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 local backpack=player:FindFirstChildOfClass('Backpack');if not humanoid or not backpack then return end
 for _,tool in ipairs(backpack:GetChildren()) do if tool:IsA('Tool') and tool:GetAttribute('FalloutItem')==id then humanoid:EquipTool(tool);return end end
end)
task.spawn(function()
 for _=1,10 do
  local ok=pcall(function()
   game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Health,false)
   game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
  end)
  if ok then return end;task.wait(.25)
 end
end)
local notice=label(gui,'',UDim2.new(.7,0,0,40),UDim2.new(.15,0,.19,0));notice.TextSize=16
local noticeSerial=0
local function showNotice(text)
 noticeSerial+=1;local n=noticeSerial;notice.Text=text;task.delay(3,function()if noticeSerial==n then notice.Text='' end end)
end
local down=label(gui,'',UDim2.new(.7,0,0,60),UDim2.new(.15,0,.7,0),Enum.Font.GothamBold);down.TextColor3=Color3.fromRGB(255,145,120)
local results=make('Frame',gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(12,18,19),BackgroundTransparency=.06,BorderSizePixel=0,Visible=false})
local resultTitle=label(results,'',UDim2.new(.9,0,0,60),UDim2.new(.05,0,.06,0),Enum.Font.GothamBlack);resultTitle.TextSize=30
local resultSubtitle=label(results,'',UDim2.new(.9,0,0,30),UDim2.new(.05,0,.19,0));resultSubtitle.TextSize=14
local resultList=make('ScrollingFrame',results,{Size=UDim2.fromScale(.86,.62),Position=UDim2.fromScale(.07,.29),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
make('UIListLayout',resultList,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local function portrait(parent,id,size,pos)
 return make('ImageLabel',parent,{Image='rbxthumb://type=AvatarHeadShot&id='..id..'&w=150&h=150',Size=size,Position=pos,BackgroundTransparency=1})
end
local function showResults(data)
 for _,child in ipairs(resultList:GetChildren()) do if child:IsA('Frame') then child:Destroy() end end
 if not data then return end
 local winner=data.winner
 resultTitle.Text=winner==0 and 'EMPATE' or (winner==1 and 'TIME AZUL VENCEU' or 'TIME VERMELHO VENCEU')
 resultTitle.TextColor3=winner==0 and Color3.fromRGB(235,230,210) or colors[winner]
 resultSubtitle.Text=string.format('%d — %d   •   ABATES / QUEDAS / MORTES / CURA',data.scores[1],data.scores[2])
 local index=0
 for _,row in ipairs(data.rows) do
  if winner==0 or row.team==winner then
   index+=1
   local entry=make('Frame',resultList,{Size=UDim2.new(1,-8,0,56),BackgroundColor3=Color3.fromRGB(32,41,42),BorderSizePixel=0,LayoutOrder=index});corner(entry,8)
   portrait(entry,row.userId,UDim2.fromOffset(46,46),UDim2.fromOffset(6,5))
   local name=label(entry,(index==1 and '★ ' or '')..row.name,UDim2.new(.48,-40,1,0),UDim2.fromOffset(60,0),Enum.Font.GothamBold);name.TextXAlignment=Enum.TextXAlignment.Left;name.TextSize=15
   local summary=label(entry,string.format('%d / %d / %d / %d',row.kills,row.downs,row.deaths,math.floor(row.heals)),UDim2.new(.48,0,1,0),UDim2.fromScale(.51,0));summary.TextSize=15
  end
 end
end
local shop=make('Frame',gui,{Size=UDim2.fromScale(.9,.83),Position=UDim2.fromScale(.05,.1),BackgroundColor3=Color3.fromRGB(18,24,22),BorderSizePixel=0,Visible=false});corner(shop,12)
local shopTitle=label(shop,'ARMARIA',UDim2.new(.65,0,0,42),UDim2.fromOffset(18,6),Enum.Font.GothamBold);shopTitle.TextSize=24;shopTitle.TextXAlignment=Enum.TextXAlignment.Left
UI.coin(shop,18,UDim2.fromOffset(18,48))
local shopBalance=label(shop,'…',UDim2.new(1,-60,0,24),UDim2.fromOffset(44,44),Enum.Font.GothamMedium);shopBalance.TextXAlignment=Enum.TextXAlignment.Left;shopBalance.TextSize=14
local shopList=make('ScrollingFrame',shop,{Position=UDim2.fromOffset(14,80),Size=UDim2.new(1,-28,1,-94),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
make('UIListLayout',shopList,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local shopping=false
local shopMode
local dialogueController
local function updateWallet()
 local ready=player:GetAttribute('ProfileReady')==true
 local coins=ready and UI.money(player:GetAttribute('Coins')) or '…'
 UI.setBalance(wallet,coins)
 shopBalance.Text=ready and (coins..' moedas disponíveis') or 'Carregando saldo…'
end
for _,name in ipairs({'Coins','XP','Level','ProfileReady'}) do player:GetAttributeChangedSignal(name):Connect(updateWallet) end
updateWallet()
local function closeShop()shop.Visible=false;shopping=false end
button(shop,'FECHAR',UDim2.fromOffset(88,34),UDim2.new(1,-104,0,10),closeShop)
local function query(command,id)
 local ok,response=pcall(function()return net.Query:InvokeServer(command,id) end)
 if not ok then showNotice('Não foi possível conectar. Tente novamente.');return nil end
 return response
end
local function openShop(itemsOnly)
 if state.phase=='Match' then return end
 local profile=query('Profile');if not profile or not profile.ok then showNotice(profile and profile.message or 'Carregando…');return end
 local scroll=shopping and shopMode==itemsOnly and shopList.CanvasPosition or Vector2.zero
 shopping=true;shopMode=itemsOnly;shop.Visible=true;shopTitle.Text=itemsOnly and 'ITENS' or 'ARMARIA'
 shopBalance.Text=UI.money(profile.coins)..' moedas disponíveis'
 for _,child in ipairs(shopList:GetChildren()) do if child:IsA('Frame') then child:Destroy() end end
 for index,item in ipairs(C.Catalog) do
  if not itemsOnly or item.kind=='Heal' or item.kind=='Mine' or item.kind=='Grenade' then
   local iconWidth=shop.AbsoluteSize.X<420 and 76 or 96
   local iconHeight=iconWidth/1.17
   local contentX=iconWidth+12
   local row=make('Frame',shopList,{Name='Item_'..item.id,Size=UDim2.new(1,-8,0,94),BackgroundColor3=Color3.fromRGB(31,39,34),BorderSizePixel=0,LayoutOrder=index});corner(row,8)
   local iconBox=make('Frame',row,{Name='Preview',Size=UDim2.fromOffset(iconWidth,iconHeight),Position=UDim2.fromOffset(5,(94-iconHeight)/2),BackgroundColor3=Color3.fromRGB(25,32,30),BorderSizePixel=0});corner(iconBox,6)
   local visual=RS.FalloutItemVisuals:FindFirstChild(item.id)
   if visual then
    UI.catalogPreview(iconBox,visual,item)
   else
    local missing=label(iconBox,'Prévia indisponível',UDim2.fromScale(1,1),UDim2.new());missing.TextSize=10
   end
   local name=label(row,item.name,UDim2.new(1,-contentX-12,0,23),UDim2.fromOffset(contentX,5),Enum.Font.GothamBold);name.TextXAlignment=Enum.TextXAlignment.Left;name.TextSize=14;name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd
   local description=item.kind=='Gun' and (item.damage..' dano • '..item.mag..' tiros') or item.kind=='Heal' and (item.healing..' PV • cura aliados') or item.kind=='Melee' and (item.damage..' dano • corpo a corpo') or (item.charges..' por partida')
   local text=label(row,description,UDim2.new(1,-contentX-12,0,18),UDim2.fromOffset(contentX,30));text.TextXAlignment=Enum.TextXAlignment.Left;text.TextSize=11;text.TextWrapped=false;text.TextTruncate=Enum.TextTruncate.AtEnd
   local price=label(row,item.price==0 and 'GRÁTIS' or UI.money(item.price),UDim2.new(1,-contentX-122,0,32),UDim2.fromOffset(contentX,56),Enum.Font.GothamBold);price.TextXAlignment=Enum.TextXAlignment.Left;price.TextSize=13;price.TextColor3=Color3.fromRGB(226,185,91);price.TextWrapped=false
   local owned=profile.owned[item.id]
   local equipped=false;for _,id in pairs(profile.loadout) do if id==item.id then equipped=true end end
   local buy
   buy=button(row,equipped and 'EQUIPADO' or owned and 'EQUIPAR' or 'COMPRAR',UDim2.fromOffset(108,32),UDim2.new(1,-116,0,56),function()
    if equipped then return end
    if buy:GetAttribute('Busy') then return end;buy:SetAttribute('Busy',true)
    local result=query(owned and 'Equip' or 'Buy',item.id)
    if result then showNotice(result.message or '');if result.ok then openShop(itemsOnly) end end
    if buy.Parent then buy:SetAttribute('Busy',false) end
   end)
   buy.TextSize=12
  end
 end
 shopList.CanvasPosition=scroll
end
local function applyState(new)
 if type(new)~='table' then return end
 local previous=state.phase;state=new
 score.Text=string.format('%d  —  %d',state.scores[1],state.scores[2])
 for team=1,2 do for i=1,5 do slots[team][i].portrait.Image='';slots[team][i].status.Visible=false end end
 local counts={0,0}
 for _,p in ipairs(state.roster) do if p.team==1 or p.team==2 then counts[p.team]+=1;local s=slots[p.team][counts[p.team]];if s then s.portrait.Image='rbxthumb://type=AvatarHeadShot&id='..p.userId..'&w=150&h=150';s.portrait.ImageTransparency=p.alive and 0 or .65;s.status.Visible=p.downed;s.status.BackgroundColor3=Color3.fromRGB(225,185,101) end end end
 results.Visible=state.phase=='Results';if state.phase=='Results' then showResults(state.results) end
 board.root.BackgroundTransparency=state.phase=='Match' and .76 or .15
 if previous~=state.phase then
  closeShop()
  if dialogueController then dialogueController:hideGui() end
  player.CameraMode=state.phase=='Match' and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
  if state.phase=='Match' then player.CameraMinZoomDistance=.5;player.CameraMaxZoomDistance=.5 else player.CameraMaxZoomDistance=18;player.CameraMinZoomDistance=8 end
 end
end
net.State.OnClientEvent:Connect(applyState)
task.spawn(function()local initial=query('State');if initial then applyState(initial) end end)
local firing=false
local aiming=false
local options=require(RS:WaitForChild('FalloutOptionsClient')).new({
 remote=net.Query,
 onToggle=function(isOpen)
  if isOpen then
   firing=false;aiming=false
   closeShop()
   if dialogueController then dialogueController:hideGui() end
  end
 end
})
local lastFire=0
local recoil=0
local activeTool,viewModel
local function equipped()
 local char=player.Character;local t=char and char:FindFirstChildOfClass('Tool');local id=t and t:GetAttribute('FalloutItem');return t,C.ById[id]
end
local function shoot()
 if state.phase~='Match' or shopping or options:isOpen() or player:GetAttribute('Downed') then return end
 local tool,def=equipped();if not def then return end
 if def.kind=='Heal' then return end
 if tool:GetAttribute('Reloading') or (tool:GetAttribute('Ammo') or 0)==0 then return end
 if os.clock()-lastFire<def.rate then return end;lastFire=os.clock()
 local camera=workspace.CurrentCamera;local ray=camera:ViewportPointToRay(camera.ViewportSize.X*.5,camera.ViewportSize.Y*.5)
 net.Action:FireServer('Fire',ray.Origin,ray.Direction.Unit);recoil=math.min(recoil+.08,.18)
end
local function healNearest()
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');if not root then return end
 local target,distance=nil,C.HealDistance
 for _,p in ipairs(Players:GetPlayers()) do
  local ch=p.Character;local r=ch and ch:FindFirstChild('HumanoidRootPart');local h=ch and ch:FindFirstChildOfClass('Humanoid')
  if p~=player and p.Team==player.Team and r and h and h.Health>0 and h.Health<h.MaxHealth then local d=(r.Position-root.Position).Magnitude;if d<distance then target=p;distance=d end end
 end
 if target then net.Action:FireServer('Heal',target.UserId) else showNotice('Aproxime-se de um companheiro ferido') end
end
local function input(action,status)
 if options:isOpen() then firing=false;return Enum.ContextActionResult.Sink end
 if action=='FalloutFire' then firing=status==Enum.UserInputState.Begin;if firing then shoot() end
 elseif status==Enum.UserInputState.Begin then if action=='FalloutReload' then net.Action:FireServer('Reload') elseif action=='FalloutHeal' then healNearest() end end
 return state.phase=='Match' and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
end
CAS:BindAction('FalloutFire',input,false,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2)
CAS:BindAction('FalloutReload',input,false,Enum.KeyCode.R,Enum.KeyCode.ButtonX)
CAS:BindAction('FalloutHeal',input,false,Enum.KeyCode.G,Enum.KeyCode.ButtonY)
for index,key in ipairs({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four}) do
 CAS:BindAction('FalloutEquip'..index,function(_,status)
  if state.phase~='Match' then return Enum.ContextActionResult.Pass end
  if options:isOpen() then return Enum.ContextActionResult.Sink end
  if status==Enum.UserInputState.Begin then CombatHUD.equipSlot(combat,index) end
  return Enum.ContextActionResult.Sink
 end,false,key)
end
UIS.InputBegan:Connect(function(i,processed)if not processed and not options:isOpen() and i.UserInputType==Enum.UserInputType.MouseButton2 then if options:get('aimMode')=='toggle' then aiming=not aiming else aiming=true end end end)
CAS:BindAction('FalloutCycleEquipment',function(_,status,inputObject)
 if state.phase~='Match' then return Enum.ContextActionResult.Pass end
 if options:isOpen() then return Enum.ContextActionResult.Sink end
 if status==Enum.UserInputState.Begin then CombatHUD.cycleEquipment(combat,inputObject.KeyCode==Enum.KeyCode.ButtonR1 and 1 or -1) end
 return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.ButtonL1,Enum.KeyCode.ButtonR1)
UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton2 and options:get('aimMode')=='hold' then aiming=false end end)
UIS.WindowFocusReleased:Connect(function()firing=false;aiming=false end)
local mobile=make('Frame',gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
local fire=button(mobile,'',UDim2.fromOffset(60,60),UDim2.new(1,-66,.44,-30),function()end);corner(fire,30);CombatHUD.styleControl(fire,'fire')
local fireTouch
fire.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch then fireTouch=i;firing=true;shoot() end end)
UIS.InputEnded:Connect(function(i)if i==fireTouch then fireTouch=nil;firing=false end end)
local aim=button(mobile,'',UDim2.fromOffset(44,44),UDim2.new(1,-122,.31,-22),function()if not options:isOpen() and options:get('aimMode')=='toggle' then aiming=not aiming end end);corner(aim,22);CombatHUD.styleControl(aim,'aim')
local aimTouch
aim.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch and options:get('aimMode')=='hold' and not options:isOpen() then aimTouch=i;aiming=true end end)
UIS.InputEnded:Connect(function(i)if i==aimTouch then aimTouch=nil;aiming=false end end)
local reloadButton=button(mobile,'',UDim2.fromOffset(44,44),UDim2.new(1,-122,.57,-22),function()net.Action:FireServer('Reload')end);corner(reloadButton,22);CombatHUD.styleControl(reloadButton,'reload')
local healButton=button(mobile,'',UDim2.fromOffset(44,44),UDim2.new(1,-174,.57,-22),healNearest);corner(healButton,22);CombatHUD.styleControl(healButton,'heal')
local mobileScale={}
for _,control in ipairs({fire,aim,reloadButton,healButton}) do mobileScale[control]=make('UIScale',control,{Scale=1}) end
local function cleanupView()
 if viewModel then viewModel:Destroy();viewModel=nil end
 if activeTool then for _,p in ipairs(activeTool:GetDescendants()) do if p:IsA('BasePart') then p.LocalTransparencyModifier=0 end end end
 activeTool=nil
end
player.CharacterAdded:Connect(function()firing=false;aiming=false;cleanupView() end)
net.Fx.OnClientEvent:Connect(function(info)
 if info.kind=='Notice' then showNotice(info.text)
 elseif info.kind=='Reward' then showNotice('+'..info.xp..' XP  •  +'..info.coins..' moedas  —  '..info.reason)
 elseif info.kind=='Hit' then if options:get('hitmarker') and not options:isOpen() then CombatHUD.hit(combat,info.headshot) end
 elseif info.kind=='Kill' then if options:get('killfeed') then CombatHUD.addKill(combat,info) end
 elseif info.kind=='Shot' then
  if not info.melee then
   local length=(info.to-info.from).Magnitude
   if length>.01 then local beam=make('Part',workspace.FalloutEffects,{Name='Tracer',Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Material=Enum.Material.Neon,Color=Color3.fromRGB(255,216,147),Size=Vector3.new(.025,.025,length),CFrame=CFrame.lookAt(info.from,info.to)*CFrame.new(0,0,-length/2)});Debris:AddItem(beam,.055) end
  end
  local sound=RS:FindFirstChild('FalloutShotSound');if sound and not info.melee then local anchor=make('Part',workspace.FalloutEffects,{Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.one,Position=info.from});local s=sound:Clone();s.Volume=info.weapon=='suppressed' and .18 or .4;s.RollOffMaxDistance=120;s.Parent=anchor;s:Play();Debris:AddItem(anchor,4) end
 elseif info.kind=='Explosion' then
  local flash=make('Part',workspace.FalloutEffects,{Shape=Enum.PartType.Ball,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Material=Enum.Material.Neon,Color=Color3.fromRGB(255,167,76),Size=Vector3.one,Position=info.position,Transparency=.2});Tween:Create(flash,TweenInfo.new(.3),{Size=Vector3.one*info.radius*1.3,Transparency=1}):Play();Debris:AddItem(flash,.35)
 end
end)
Run.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera;if not camera then return end
 UI.fitScoreboard(board,camera.ViewportSize,GuiService:GetInsetArea(Enum.ScreenInsets.TopbarSafeInsets),GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets))
 wallet.root.Position=UDim2.new(1,-10,0,board.fallback and 34 or 6)
 notice.Visible=options:get('notices') and not options:isOpen()
 for control,scale in pairs(mobileScale) do scale.Scale=options:get('buttonScale')/100;control.BackgroundTransparency=1-options:get('buttonOpacity')/100 end
 if touch then
  local height=GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets).Height
  local hotbarTop=height-130
  local reloadY=math.max(52,hotbarTop-52)
  reloadButton.Position=UDim2.new(1,-122,0,reloadY);healButton.Position=UDim2.new(1,-174,0,reloadY)
  aim.Position=UDim2.new(1,-122,0,math.max(0,reloadY-54))
  fire.Position=UDim2.new(1,-66,0,math.max(38,math.min(height*.4,hotbarTop-26))-30)
 end
 local left=math.max(0,math.ceil((state.deadline or 0)-workspace:GetServerTimeNow()))
 clock.Text=state.phase=='Waiting' and 'AGUARDANDO' or (state.phase=='Match' and '' or 'INTERV. ')..string.format('%02d:%02d',math.floor(left/60),left%60)
 local char=player.Character;local hum=char and char:FindFirstChildOfClass('Humanoid')
 LobbyHealth.update(lobbyHealth,state.phase,hum)
 local isDown=player:GetAttribute('Downed');down.Text=isDown and ('VOCÊ CAIU • AGUARDE UM COMPANHEIRO\n'..math.max(0,math.ceil((player:GetAttribute('BleedEnds') or 0)-workspace:GetServerTimeNow()))..'s') or ''
 mobile.Visible=touch and state.phase=='Match' and not isDown and not shopping and not options:isOpen()
 local tool,def=equipped()
 CombatHUD.update(combat,{phase=state.phase,humanoid=hum,character=char,backpack=player:FindFirstChildOfClass('Backpack'),player=player,catalog=C.ById,tool=tool,def=def,downed=isDown,touch=touch,aiming=aiming,recoil=recoil,menuOpen=options:isOpen(),reticleEnabled=options:get('reticle'),radarEnabled=options:get('radar'),killfeedEnabled=options:get('killfeed')})
 if firing and def and def.automatic then shoot() end
 if state.phase=='Match' and tool and def and not isDown then
  if activeTool~=tool then
   cleanupView();activeTool=tool
   local original=RS.FalloutItemVisuals:FindFirstChild(def.id)
   if original then viewModel=original:Clone();viewModel.Anchored=true;viewModel.CanCollide=false;viewModel.CanQuery=false;viewModel.CanTouch=false;viewModel.Parent=camera end
  end
  for _,part in ipairs(tool:GetDescendants()) do if part:IsA('BasePart') then part.LocalTransparencyModifier=1 end end
  if viewModel then
   recoil=math.max(0,recoil-dt*.45)
   local reload=tool:GetAttribute('Reloading') and math.sin(os.clock()*6)*.3 or 0
   local x=aiming and 0 or .55;local y=aiming and -.34 or -.65
   viewModel.CFrame=camera.CFrame*CFrame.new(x,y+math.sin(os.clock()*2)*.012,-1.25+recoil)*CFrame.Angles(recoil+reload,0,reload)*RS.FalloutItemVisuals[def.id].CFrame.Rotation
   camera.FieldOfView+=( (aiming and 58 or options:get('cameraFov'))-camera.FieldOfView)*math.min(1,dt*12)
  end
 else cleanupView() end
end)
task.spawn(function()
 local npc=workspace:WaitForChild('Shopkeeper',60);if not npc then return end
 local prompt=npc:WaitForChild('ProximityPrompt');local Dialog=require(RS:WaitForChild('DialogModule'))
 local dialog=Dialog.new('ch_ckz2n',npc,prompt)
 dialogueController=dialog
 dialog:addDialog('Oi! O que você quer saber?',{'Sobre o jogo','Loja','Itens'})
 prompt.Triggered:Connect(function()if state.phase~='Match' then dialog:triggerDialog(player,1) end end)
 dialog.responded:Connect(function(option)
  if option==1 then dialog:hideGui('São dois times de até cinco. Cada partida dura 10 minutos, com 1 minuto e meio de intervalo. Elimine o outro time e ajude seus companheiros para ganhar XP e moedas!')
  elseif option==2 then dialog:hideGui('Dá uma olhada nas armas.');openShop(false)
  elseif option==3 then dialog:hideGui('Aqui estão os itens de combate e de cura.');openShop(true) end
 end)
end)

