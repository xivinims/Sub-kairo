local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local SSS=game:GetService('ServerScriptService')
local Http=game:GetService('HttpService')
local Lighting=game:GetService('Lighting')
local Shared=RS:WaitForChild('WaterRPG')
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
local Profiles=require(script.Parent.Profiles).start()
local Residents=require(script.Parent.Residents)
local Net=Shared.Action
local Feedback=Shared.Feedback
local Markers=workspace:WaitForChild('RPGMarkers')
local NPCs=workspace:WaitForChild('Residents')
Players.CharacterAutoLoads=false
local last,loading,conversations={},{},{}
local allowed={Play=true,Respawn=true,Menu=true,Answer=true,CloseDialogue=true,Sprint=true,UsePotion=true,Lantern=true}
local function send(p,kind,value) if p.Parent then Feedback:FireClient(p,kind,value) end end
local function body(p) local c=p.Character;return c,c and c:FindFirstChild('HumanoidRootPart'),c and c:FindFirstChildOfClass('Humanoid') end
local function closeDialogue(p)
 local d=conversations[p]
 if d and d.npc.Parent and d.npc:GetAttribute('ConversationOwner')==p.UserId then
  d.npc:SetAttribute('Conversing',false);d.npc:SetAttribute('ConversationOwner',nil)
 end
 conversations[p]=nil
end
local function inRange(p,npc)
 local c,root,h=body(p);local nr=npc:FindFirstChild('HumanoidRootPart')
 if not root or not h or h.Health<=0 or p:GetAttribute('InMenu') or not nr or not Rules.distanceAllowed((root.Position-nr.Position).Magnitude) then return false end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={c,NPCs}
 return not workspace:Raycast(root.Position,nr.Position-root.Position,ray)
end
local roleText={
 Guide='A estrada continua além dos portões. Leve esta encomenda à boticária de Nicósia; ela fica na cidade, perto da forja.',
 Blacksmith='A forja está acesa. Por enquanto, preparo e conserto as ferramentas dos moradores. A boticária pode precisar de ajuda.',
 Apothecary='Ervas, repouso e paciência. É assim que cuidamos de quem chega pela estrada.',
 Merchant='O movimento aumentou desde a última caravana. Guarde algumas moedas para o caminho de volta.',
 Guard='Os portões estão sob nossa guarda. Pode explorar a cidade, mas tenha cuidado nas muralhas.',
 Stable='Os cavalos descansam aqui. A estrada exterior leva aos campos e ao porto.',
 Citizen='A cidade muda de ritmo com a luz. Há gente trabalhando no mercado, nas oficinas e nos campos.',
}
local function talk(p,npc)
 if not p:GetAttribute('ProfileReady') or not inRange(p,npc) then return end
 if npc:GetAttribute('ConversationOwner') and npc:GetAttribute('ConversationOwner')~=p.UserId then send(p,'Notice','Este morador está conversando.');return end
 closeDialogue(p)
 local role=npc:GetAttribute('Role') or 'Citizen'
 local data=Profiles.get(p);if not data then return end
 local options={}
 local text=roleText[role] or roleText.Citizen
 if role=='Guide' and data.quest==0 then options={{id='AcceptDelivery',text='Posso levar a encomenda.'},{id='Leave',text='Vou explorar primeiro.'}}
 elseif role=='Guide' and data.quest==1 then text='A boticária está na cidade. Siga a indicação da encomenda.';options={{id='Leave',text='Estou a caminho.'}}
 elseif role=='Guide' then text='A encomenda chegou. Obrigado por ajudar quem mora aqui.';options={{id='Leave',text='Até mais.'}}
 elseif role=='Apothecary' and data.quest==1 then text='A encomenda do Nasos! Estávamos esperando essas ervas. Muito obrigada.';options={{id='Deliver',text='Aqui está a encomenda.'},{id='Leave',text='Só um instante.'}}
 elseif role=='Apothecary' or role=='Merchant' then options={{id='BuyPotion',text='Tônico de ervas · 12 moedas'},{id='Leave',text='Até mais.'}}
 else options={{id='Leave',text='Até mais.'}} end
 local token=Http:GenerateGUID(false)
 conversations[p]={token=token,npc=npc,expires=os.clock()+45,options=options}
 npc:SetAttribute('Conversing',true);npc:SetAttribute('ConversationOwner',p.UserId)
 local h=npc:FindFirstChildOfClass('Humanoid');local nr=npc:FindFirstChild('HumanoidRootPart');if h and nr then h:MoveTo(nr.Position) end
 send(p,'Dialogue',{token=token,name=npc:GetAttribute('DisplayName') or npc.Name,role=npc:GetAttribute('Profession') or 'Morador',text=text,options=options})
 task.delay(46,function() if conversations[p] and conversations[p].token==token then closeDialogue(p);send(p,'CloseDialogue',true) end end)
end
local function attachNPC(npc)
 local root=npc:FindFirstChild('HumanoidRootPart');if not root then return end
 local prompt=Instance.new('ProximityPrompt');prompt.Name='Talk';prompt.ActionText='Conversar';prompt.ObjectText=npc:GetAttribute('DisplayName') or npc.Name
 prompt.MaxActivationDistance=10;prompt.HoldDuration=0;prompt.RequiresLineOfSight=true;prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.Parent=root
 prompt.Triggered:Connect(function(p) talk(p,npc) end)
end
for _,npc in ipairs(NPCs:GetChildren()) do attachNPC(npc) end
Residents.start(NPCs,Config)
local function makeLantern(p)
 local data=Profiles.get(p);if not data or data.items.Lantern<1 or p:GetAttribute('InMenu') then return end
 local c=p.Character;local bag=p:FindFirstChildOfClass('Backpack');if not c or not bag then return end
 if bag:FindFirstChild('Lanterna') or c:FindFirstChild('Lanterna') then return end
 local tool=Instance.new('Tool');tool.Name='Lanterna';tool.RequiresHandle=true;tool.CanBeDropped=false
 local handle=Instance.new('Part');handle.Name='Handle';handle.Size=Vector3.new(.5,1,.5);handle.Material=Enum.Material.Metal;handle.Color=Color3.fromRGB(87,72,48);handle.CanCollide=false;handle.Massless=true;handle.Parent=tool
 local light=Instance.new('PointLight');light.Name='Flame';light.Color=Color3.fromRGB(255,209,143);light.Range=22;light.Brightness=1.6;light.Shadows=false;light.Enabled=false;light.Parent=handle
 tool.Equipped:Connect(function() light.Enabled=true end);tool.Unequipped:Connect(function() light.Enabled=false end)
 tool.Parent=bag
end
local function menu(p)
 closeDialogue(p);p:SetAttribute('InMenu',true);p.ReplicationFocus=Markers.MenuFocus
 local c=p.Character;if c then p.Character=nil;c:Destroy() end
 send(p,'Menu',true)
 task.spawn(function() pcall(function() p:RequestStreamAroundAsync(Config.MenuFocus,10) end) end)
end
local function spawnPlayer(p)
 if loading[p] or not p:GetAttribute('ProfileReady') then return end
 loading[p]=true;closeDialogue(p);send(p,'Transition','Preparando a estrada…')
 local ok,err=pcall(function()
  p:RequestStreamAroundAsync(Markers.Arrival.Position,12)
  if not p.Parent then return end
  p:LoadCharacterAsync()
  local c=p.Character;local root=c and c:WaitForChild('HumanoidRootPart',12);local h=c and c:FindFirstChildOfClass('Humanoid')
  assert(root and h,'Personagem não ficou pronto')
  root.Anchored=true;c:PivotTo(Markers.Arrival.CFrame+Vector3.new(0,3.2,0))
  h.WalkSpeed=Config.WalkSpeed;h.UseJumpPower=true;h.JumpPower=50
  p:SetAttribute('InMenu',false);p:SetAttribute('Sprinting',false);p.ReplicationFocus=nil
  task.wait(.3);root.Anchored=false
  h.Died:Connect(function() closeDialogue(p);send(p,'Died',true) end)
  send(p,'Started',true)
 end)
 loading[p]=nil
 if not ok and p.Parent then warn('Water RPG spawn: '..tostring(err));menu(p);send(p,'Notice','Não foi possível entrar. Tente novamente.') end
end
Players.PlayerAdded:Connect(function(p)
 p:SetAttribute('InMenu',true);p:SetAttribute('ProfileReady',false);p.ReplicationFocus=Markers.MenuFocus
 task.spawn(Profiles.load,p)
 task.spawn(function() pcall(function() p:RequestStreamAroundAsync(Config.MenuFocus,10) end) end)
end)
for _,p in ipairs(Players:GetPlayers()) do
 p:SetAttribute('InMenu',true);p:SetAttribute('ProfileReady',false);p.ReplicationFocus=Markers.MenuFocus
 if p.Character then local c=p.Character;p.Character=nil;c:Destroy() end
 task.spawn(Profiles.load,p)
end
Players.PlayerRemoving:Connect(function(p) closeDialogue(p);Profiles.remove(p);last[p]=nil;loading[p]=nil end)
Net.OnServerEvent:Connect(function(p,kind,arg)
 if type(kind)~='string' or not allowed[kind] then return end
 local now=os.clock();local times=last[p] or {};last[p]=times
 if now-(times[kind] or -100)<.2 then return end;times[kind]=now
 if kind=='CloseDialogue' then closeDialogue(p);return end
 if kind=='Play' or kind=='Respawn' then
  local _,_,h=body(p)
  if kind=='Respawn' and h and h.Health>0 then return end
  if kind=='Play' and not p:GetAttribute('InMenu') then return end
  task.spawn(spawnPlayer,p);return
 end
 if kind=='Menu' then if not loading[p] then menu(p) end;return end
 if kind=='Sprint' and type(arg)=='boolean' then
  local _,_,h=body(p);if h and h.Health>0 and not p:GetAttribute('InMenu') and not conversations[p] then h.WalkSpeed=arg and Config.SprintSpeed or Config.WalkSpeed;p:SetAttribute('Sprinting',arg) end;return
 end
 if kind=='UsePotion' then
  local _,_,h=body(p);local d=Profiles.get(p)
  if h and h.Health>0 and h.Health<h.MaxHealth and d and d.items.Potion>0 then Profiles.change(p,function(data) data.items.Potion-=1 end);h.Health=math.min(h.MaxHealth,h.Health+35);send(p,'Notice','Tônico utilizado.') end;return
 end
 if kind=='Lantern' then makeLantern(p);return end
 if kind=='Answer' then
  if type(arg)~='table' or type(arg.token)~='string' or type(arg.id)~='string' then return end
  local d=conversations[p]
  if not d or d.token~=arg.token or now>d.expires or not d.npc.Parent or not inRange(p,d.npc) then closeDialogue(p);send(p,'CloseDialogue',true);return end
  local accepted=false;for _,o in ipairs(d.options) do if o.id==arg.id then accepted=true end end
  if not accepted then return end
  local role=d.npc:GetAttribute('Role');local profile=Profiles.get(p)
  if arg.id=='AcceptDelivery' or arg.id=='Deliver' then
   local nextStage,message=Rules.quest(profile.quest,role)
   if message then
    Profiles.change(p,function(data)
     data.quest=nextStage
     if nextStage==2 then data.coins+=40;data.xp+=50 end
    end)
    send(p,'Notice',nextStage==1 and 'Encomenda recebida. Encontre a boticária.' or 'Entrega concluída: +40 moedas, +50 XP.')
   end
  elseif arg.id=='BuyPotion' or arg.id=='BuyLantern' then
   local key=arg.id=='BuyPotion' and 'Potion' or 'Lantern';local item=Config.Items[key]
   local max=key=='Lantern' and 1 or 10
   if profile.items[key]>=max then send(p,'Notice','Você já tem esse item ou atingiu o limite.')
   elseif Rules.buy(profile.coins,item.Price,profile.items[key]) then
    Profiles.change(p,function(data) data.coins-=item.Price;data.items[key]+=1 end)
    if key=='Lantern' then makeLantern(p) end;send(p,'Notice',item.Name..' comprado.')
   else send(p,'Notice','Moedas insuficientes.') end
  end
  closeDialogue(p);send(p,'CloseDialogue',true)
 end
end)
task.spawn(function()
 while true do
  task.wait(60)
  for _,p in ipairs(Players:GetPlayers()) do task.spawn(Profiles.save,p,false) end
 end
end)
task.spawn(function()
 while true do
  task.wait(1);Lighting.ClockTime=(Lighting.ClockTime+24/2400)%24
  for p,d in pairs(conversations) do if not d.npc.Parent or not inRange(p,d.npc) then closeDialogue(p);send(p,'CloseDialogue',true) end end
 end
end)
game:BindToClose(function()
 local pending=0
 for _,p in ipairs(Players:GetPlayers()) do pending+=1;task.spawn(function() Profiles.save(p,true);pending-=1 end) end
 local deadline=os.clock()+25;repeat task.wait(.1) until pending==0 or os.clock()>deadline
end)
Shared.State:SetAttribute('RuntimeReady',true)
