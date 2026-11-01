local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local SS=game:GetService('ServerStorage')
local Teams=game:GetService('Teams')
local Debris=game:GetService('Debris')
local C=require(RS.FalloutConfig)
local Rules=require(script.Parent.Rules)
local Profiles=require(script.Parent.Profiles)
local Net=RS.FalloutNet
local Action,Fx,State=Net.Action,Net.Fx,Net.State
local records,states,cooldowns={},{},{}
local round=0
local phase='Waiting'
local deadline=0
local scores={0,0}
local lastResults=nil
local random=Random.new()
local teamObjects={}
for i,name in ipairs({'Azul','Vermelho'}) do
 local team=Teams:FindFirstChild(name) or Instance.new('Team')
 team.Name=name;team.AutoAssignable=false;team.TeamColor=BrickColor.new(i==1 and 'Bright blue' or 'Bright red');team.Parent=Teams;teamObjects[i]=team
end
local function now() return workspace:GetServerTimeNow() end
local function alive(player)
 local char=player.Character;local hum=char and char:FindFirstChildOfClass('Humanoid');local root=char and char:FindFirstChild('HumanoidRootPart')
 if hum and root and hum.Health>0 then return char,hum,root end
end
local function teamIndex(p) return p.Team==teamObjects[1] and 1 or p.Team==teamObjects[2] and 2 or 0 end
local function rows()
 local list={}
 for id,r in pairs(records) do table.insert(list,{userId=id,name=r.name,team=r.team,kills=r.kills,downs=r.downs,deaths=r.deaths,heals=r.heals,headshots=r.headshots}) end
 return Rules.rank(list)
end
local function snapshot()
 local roster={}
 for _,p in ipairs(Players:GetPlayers()) do
  local char,hum=alive(p)
  table.insert(roster,{userId=p.UserId,name=p.DisplayName,team=teamIndex(p),alive=hum~=nil,downed=p:GetAttribute('Downed')==true})
 end
 table.sort(roster,function(a,b)return a.userId<b.userId end)
 return {phase=phase,deadline=deadline,round=round,scores=scores,roster=roster,results=lastResults}
end
local function broadcast() State:FireAllClients(snapshot()) end
local function notify(p,text) Fx:FireClient(p,{kind='Notice',text=text}) end
local function reward(p,xp,coins,reason)
 if not p or p.Parent~=Players then return end
 Profiles.Reward(p,xp,coins)
 Fx:FireClient(p,{kind='Reward',xp=xp,coins=coins,reason=reason})
end
local function refreshGear(p)
 local char,hum=alive(p);if not char then return end
 hum:UnequipTools()
 for _,parent in ipairs({char,p:FindFirstChildOfClass('Backpack')}) do
  if parent then for _,v in ipairs(parent:GetChildren()) do if v:IsA('Tool') and v:GetAttribute('FalloutItem') then v:Destroy() end end end
 end
 local data=states[p];if not data or phase~='Match' then return end
 data.ammo={};data.healBusy=false
 local profile=Profiles.cache[p]
 local loadout=profile and profile.loadout or {gun='compact',melee='knife',heal='medkit'}
 local owned=profile and profile.owned or {compact=true,knife=true,medkit=true}
 for _,id in ipairs({loadout.gun or 'compact',loadout.melee or 'knife',loadout.heal or 'medkit',loadout.utility or ''}) do
  local def=C.ById[id]
  if def and owned[id] then
   local template=SS.FalloutWeaponTemplates:FindFirstChild(id)
   if template then
    local tool=template:Clone();tool.CanBeDropped=false;tool.Parent=p.Backpack
    data.ammo[id]={mag=def.mag or def.charges or -1,reserve=def.reserve or 0,reloading=false,nextShot=0}
    tool:SetAttribute('Ammo',data.ammo[id].mag);tool:SetAttribute('Reserve',def.reserve or 0)
   end
  end
 end
end
local function movePlayer(p)
 local char,hum,root=alive(p);local data=states[p]
 if not char or not data then return end
 data.life+=1;data.killed=false;data.lastHit=nil;data.damage={};data.healCredit=0;data.healBusy=false
 p:SetAttribute('Downed',false);p:SetAttribute('InMatch',phase=='Match')
 root.Anchored=false;hum.PlatformStand=false;hum.AutoRotate=true;hum.WalkSpeed=16;hum.Health=hum.MaxHealth
 local key=phase=='Match' and ('Team'..teamIndex(p)) or 'Lobby'
 local folder=workspace.FalloutSpawns:FindFirstChild(key);if not folder then return end
 local points=folder:GetChildren();local spawn=points[(p.UserId+data.life)%#points+1]
 char:PivotTo(spawn.CFrame);root.AssemblyLinearVelocity=Vector3.zero
 data.protectedUntil=now()+C.SpawnProtection
 local shield=Instance.new('ForceField');shield.Name='SpawnShield';shield.Visible=true;shield.Parent=char;Debris:AddItem(shield,C.SpawnProtection)
 refreshGear(p)
end
local function assign(p)
 local counts={0,0};for _,other in ipairs(Players:GetPlayers()) do if other~=p then local t=teamIndex(other);if t>0 then counts[t]+=1 end end end
 local selected=Rules.team(counts,C.TeamSize,p.UserId+round)
 if not selected then p:Kick('Este servidor já tem 10 jogadores. Entre em outro servidor.');return false end
 p.Team=teamObjects[selected];p.Neutral=false
 return true
end
local function eliminate(victim,killer,headshot)
 local data=states[victim];local char,hum=alive(victim)
 if not data or data.killed then return end
 data.killed=true;victim:SetAttribute('Downed',false)
 if char then local root=char:FindFirstChild('HumanoidRootPart');if root then root.Anchored=false end end
 local row=records[victim.UserId];if row then row.deaths+=1 end
 if phase=='Match' and killer and killer~=victim and killer.Parent==Players and teamIndex(killer)~=teamIndex(victim) then
  local r=records[killer.UserId]
  if r then
   r.kills+=1;local t=teamIndex(killer);scores[t]+=1
   if headshot then r.headshots+=1 end
   reward(killer,C.KillXP+(headshot and C.HeadshotXP or 0),C.KillCoins,headshot and 'Capa!' or 'Eliminação')
   for attacker,amount in pairs(data.damage) do if attacker~=killer and amount>=20 then reward(attacker,30,10,'Assistência') end end
   Fx:FireAllClients({kind='Kill',killer=killer.DisplayName,victim=victim.DisplayName,headshot=headshot})
  end
 end
 if hum then hum.Health=0 end
 broadcast()
end
local function damage(attacker,victim,amount,headshot)
 local a,b=states[attacker],states[victim]
 local char,hum,root=alive(victim)
 if not a or not b or not char or b.killed then return false end
 if not Rules.canDamage({id=attacker.UserId,team=teamIndex(attacker),active=alive(attacker)~=nil,downed=attacker:GetAttribute('Downed')},{id=victim.UserId,team=teamIndex(victim),active=true,protected=b.protectedUntil>now()},phase) then return false end
 local actual=math.min(amount,hum.Health)
 b.lastHit={player=attacker,head=headshot,time=now()};b.damage[attacker]=(b.damage[attacker] or 0)+actual
 b.healCredit+=actual
 local result,hp=Rules.damage(hum.Health,amount,victim:GetAttribute('Downed'),C.DownedHealth)
 if result=='eliminated' then eliminate(victim,attacker,headshot)
 else
  hum:TakeDamage(amount)
  if result=='downed' then
   victim:SetAttribute('Downed',true);victim:SetAttribute('BleedEnds',now()+C.BleedSeconds)
   records[victim.UserId].downs+=1
   hum.WalkSpeed=0;hum.AutoRotate=false;root.Anchored=true
   b.upright=root.CFrame;root.CFrame=(root.CFrame+Vector3.new(0,-1.4,0))*CFrame.Angles(math.pi/2,0,0)
   local life=b.life;task.delay(C.BleedSeconds,function()
    if states[victim]==b and b.life==life and victim:GetAttribute('Downed') and phase=='Match' then eliminate(victim,attacker,headshot) end
   end)
   broadcast()
  end
 end
 Fx:FireClient(attacker,{kind='Hit',headshot=headshot,damage=actual})
 return true
end
local function targetFromPart(part)
 local model=part and part:FindFirstAncestorOfClass('Model')
 while model and model~=workspace do
  local p=Players:GetPlayerFromCharacter(model);if p then return p end
  model=model.Parent and model.Parent:FindFirstAncestorOfClass('Model')
 end
end
local function visible(a,b)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={a.Character,b.Character}
 local ar=a.Character and a.Character:FindFirstChild('HumanoidRootPart');local br=b.Character and b.Character:FindFirstChild('HumanoidRootPart')
 return ar and br and (ar.Position-br.Position).Magnitude<=C.HealDistance and not workspace:Raycast(ar.Position,br.Position-ar.Position,params)
end
local function heal(p,targetId)
 local target=Players:GetPlayerByUserId(tonumber(targetId) or 0);local s=states[p]
 if not s or s.healBusy or phase~='Match' or not target or target==p or target.Team~=p.Team or p:GetAttribute('Downed') then return end
 local char,hum=alive(p);local _,th=alive(target);if not hum or not th or th.Health>=th.MaxHealth or not visible(p,target) then return end
 local profile=Profiles.cache[p];local id=profile and profile.loadout.heal or 'medkit';local def=C.ById[id];local ammo=s.ammo[id]
 if not def or not ammo or ammo.mag<=0 then notify(p,'Sem cargas de cura');return end
 s.healBusy=true;local life=s.life;local targetLife=states[target] and states[target].life
 Fx:FireClient(p,{kind='Notice',text='Curando '..target.DisplayName..'…'} )
 task.spawn(function()
  local endAt=now()+C.HealSeconds
  while now()<endAt do
   task.wait(.1)
   if states[p]~=s or s.life~=life or not states[target] or states[target].life~=targetLife or phase~='Match' or not alive(p) or not alive(target) or not visible(p,target) or p:GetAttribute('Downed') then s.healBusy=false;return end
  end
  s.healBusy=false;ammo.mag-=1
  local t=states[target];local _,h,root=alive(target);if not h then return end
  local wasDown=target:GetAttribute('Downed');local restored=math.min(def.healing,h.MaxHealth-h.Health)
  h.Health+=restored
  local credited=math.min(restored,t.healCredit);t.healCredit=math.max(0,t.healCredit-credited)
  if wasDown then target:SetAttribute('Downed',false);root.CFrame=t.upright+Vector3.new(0,.5,0);root.Anchored=false;h.AutoRotate=true;h.WalkSpeed=16;reward(p,C.ReviveXP,20,'Companheiro reanimado')
  elseif credited>0 then reward(p,math.floor(credited*.5),math.floor(credited*.2),'Companheiro curado') end
  records[p.UserId].heals+=restored
  local tool=p.Backpack:FindFirstChild(id) or char:FindFirstChild(id);if tool then tool:SetAttribute('Ammo',ammo.mag) end
  broadcast()
 end)
end
local function explode(p,position,def)
 if phase~='Match' then return end
 Fx:FireAllClients({kind='Explosion',position=position,radius=def.radius})
 for _,victim in ipairs(Players:GetPlayers()) do
  local char,hum,root=alive(victim)
  if root and (root.Position-position).Magnitude<def.radius then
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char,p.Character}
   if not workspace:Raycast(position,root.Position-position,params) then damage(p,victim,def.damage*(1-(root.Position-position).Magnitude/def.radius*.7),false) end
  end
 end
end
local function finite(v) return typeof(v)=='Vector3' and v.X==v.X and v.Y==v.Y and v.Z==v.Z and v.Magnitude<1e6 end
local function attack(p,origin,direction)
 local s=states[p];local char,hum,root=alive(p)
 if not s or not char or phase~='Match' or p:GetAttribute('Downed') or s.healBusy or not finite(origin) or not finite(direction) or direction.Magnitude<.9 or direction.Magnitude>1.1 then return end
 local tool=char:FindFirstChildOfClass('Tool');local id=tool and tool:GetAttribute('FalloutItem');local def=C.ById[id];local ammo=id and s.ammo[id]
 if not def or not ammo or def.kind=='Heal' or ammo.reloading or now()<ammo.nextShot then return end
 if ammo.mag==0 then notify(p,'Recarregue a arma');return end
 local head=char:FindFirstChild('Head');if not head or (origin-head.Position).Magnitude>5 then return end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char,workspace.FalloutEffects};params.IgnoreWater=false
 if workspace:Raycast(head.Position,origin-head.Position,params) then return end
 ammo.nextShot=now()+def.rate;ammo.mag=ammo.mag>0 and ammo.mag-1 or ammo.mag;tool:SetAttribute('Ammo',ammo.mag)
 s.protectedUntil=0;local shield=char:FindFirstChild('SpawnShield');if shield then shield:Destroy() end
 if def.kind=='Grenade' or def.kind=='Mine' then
  local object=tool.Handle:Clone();object.Name='Utility';object.CanCollide=true;object.Anchored=false;object.CFrame=CFrame.new(root.Position+direction*3);object.Parent=workspace.FalloutEffects
  for _,v in ipairs(object:GetDescendants()) do if v:IsA('JointInstance') or v:IsA('WeldConstraint') then v:Destroy() end end
  object:SetNetworkOwner(nil);object.AssemblyLinearVelocity=def.kind=='Grenade' and (direction*65+Vector3.new(0,18,0)) or Vector3.zero
  local thisRound=round
  if def.kind=='Grenade' then task.delay(2.5,function()if object.Parent then local pos=object.Position;object:Destroy();if thisRound==round then explode(p,pos,def) end end end)
  else task.spawn(function()task.wait(1.5);local limit=now()+120;while object.Parent and phase=='Match' and round==thisRound and now()<limit do
   for _,v in ipairs(Players:GetPlayers()) do local _,_,r=alive(v);if v.Team~=p.Team and r and (r.Position-object.Position).Magnitude<5 then local pos=object.Position;object:Destroy();explode(p,pos,def);return end end
   task.wait(.2)
  end;if object.Parent then object:Destroy() end end) end
  Debris:AddItem(object,125);return
 end
 local spread=def.spread or 0;local dir=(direction+Vector3.new(random:NextNumber(-spread,spread),random:NextNumber(-spread,spread),random:NextNumber(-spread,spread))).Unit
 local result=workspace:Raycast(origin,dir*def.range,params)
 local point=result and result.Position or origin+dir*def.range
 local muzzle=tool.Handle:FindFirstChild('Muzzle');local from=muzzle and muzzle.WorldPosition or tool.Handle.Position
 Fx:FireAllClients({kind='Shot',userId=p.UserId,from=from,to=point,weapon=id,melee=def.kind=='Melee'})
 if result then local victim=targetFromPart(result.Instance);if victim then damage(p,victim,def.damage*(result.Instance.Name=='Head' and def.head or 1),result.Instance.Name=='Head') end end
end
local function reload(p)
 local s=states[p];local char=alive(p);if not s or not char or phase~='Match' or p:GetAttribute('Downed') then return end
 local tool=char:FindFirstChildOfClass('Tool');local id=tool and tool:GetAttribute('FalloutItem');local def=C.ById[id];local ammo=id and s.ammo[id]
 if not def or def.kind~='Gun' or not ammo or ammo.reloading or ammo.mag>=def.mag or ammo.reserve<=0 then return end
 ammo.reloading=true;tool:SetAttribute('Reloading',true);local life=s.life
 task.delay(def.reload,function()
  if states[p]~=s or s.life~=life or not tool.Parent then return end
  ammo.reloading=false;tool:SetAttribute('Reloading',false)
  if phase~='Match' or p:GetAttribute('Downed') then return end
  local count=math.min(def.mag-ammo.mag,ammo.reserve);ammo.mag+=count;ammo.reserve-=count;tool:SetAttribute('Ammo',ammo.mag);tool:SetAttribute('Reserve',ammo.reserve)
 end)
end
local function shopNear(p)
 local _,_,root=alive(p);local npc=workspace:FindFirstChild('Shopkeeper')
 return phase~='Match' and root and npc and npc.PrimaryPart and (root.Position-npc.PrimaryPart.Position).Magnitude<24
end
Net.Query.OnServerInvoke=function(p,command,id)
 local profile=Profiles.cache[p]
 if command=='State' then return snapshot() end
 if not profile then return {ok=false,message='Seus dados ainda estão carregando.'} end
 if command=='Profile' then return {ok=true,coins=profile.coins,xp=profile.xp,owned=profile.owned,loadout=profile.loadout} end
 if (command=='Buy' or command=='Equip') and shopNear(p) then
  local t=now();if (cooldowns[p] or 0)>t then return {ok=false,message='Aguarde um instante'} end;cooldowns[p]=t+.4
  if profile.transaction then return {ok=false,message='Salvando compra…'} end
  local def=type(id)=='string' and C.ById[id];if not def then return {ok=false,message='Item inválido'} end
  if command=='Buy' then
   local before={coins=profile.coins,owned=table.clone(profile.owned)}
   local ok,message=Rules.purchase(profile,def);if not ok then return {ok=false,message=message} end
   profile.transaction=true;local saved=Profiles.Save(p,false);profile.transaction=false
   if not saved then profile.coins=before.coins;profile.owned=before.owned;return {ok=false,message='Não foi possível salvar. A compra foi cancelada.'} end
   p:SetAttribute('Coins',profile.coins)
  end
  if not profile.owned[id] then return {ok=false,message='Compre o item primeiro'} end
  local slot=def.kind=='Gun' and 'gun' or def.kind=='Melee' and 'melee' or def.kind=='Heal' and 'heal' or 'utility'
  profile.loadout[slot]=id
  return {ok=true,message='Equipado para a próxima partida',coins=profile.coins,xp=profile.xp,owned=profile.owned,loadout=profile.loadout}
 end
 return {ok=false,message='Visite a loja no intervalo'}
end
Action.OnServerEvent:Connect(function(p,action,a,b)
 local s=states[p];if not s then return end
 s.remoteCount+=1;if s.remoteCount>90 then return end
 if action=='Fire' then attack(p,a,b) elseif action=='Reload' then reload(p) elseif action=='Heal' then heal(p,a) end
end)
local function add(p)
 states[p]={life=0,ammo={},protectedUntil=0,remoteCount=0,damage={},healCredit=0}
 if not assign(p) then return end
 records[p.UserId]={name=p.DisplayName,team=teamIndex(p),kills=0,downs=0,deaths=0,heals=0,headshots=0}
 p.CharacterAdded:Connect(function(char)
  local hum=char:WaitForChild('Humanoid',10);local root=char:WaitForChild('HumanoidRootPart',10);if not hum or not root then return end
  hum.Died:Connect(function()
   local s=states[p];if phase=='Match' and s and not s.killed then local last=s.lastHit;eliminate(p,last and now()-last.time<10 and last.player or nil,last and last.head) end
   task.delay(C.RespawnSeconds,function()if p.Parent==Players then p:LoadCharacterAsync() end end)
  end)
  movePlayer(p);broadcast()
 end)
 task.spawn(function()
  if not Profiles.Load(p) then notify(p,'Salvamento indisponível agora. Compras bloqueadas; tente entrar novamente.') end
  if p.Parent~=Players then Profiles.Save(p,true);return end
  if p.Character then movePlayer(p) else p:LoadCharacterAsync() end
 end)
end
Players.CharacterAutoLoads=false
Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(function(p)Profiles.Save(p,true);states[p]=nil;cooldowns[p]=nil;task.defer(broadcast) end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(add,p) end
task.spawn(function()while true do task.wait(45);for p in pairs(Profiles.cache) do task.spawn(Profiles.Save,p,false) end end end)
game:BindToClose(function()for p in pairs(Profiles.cache) do task.spawn(Profiles.Save,p,true) end;local limit=os.clock()+25;while next(Profiles.cache) and os.clock()<limit do task.wait(.2) end end)
local function setPhase(value,duration)
 phase=value;deadline=now()+duration;workspace:SetAttribute('FalloutPhase',value);workspace:SetAttribute('FalloutDeadline',deadline)
 broadcast()
end
local function startRound()
 round+=1;scores={0,0};lastResults=nil;records={}
 for _,p in ipairs(Players:GetPlayers()) do p.Team=nil end
 for _,p in ipairs(Players:GetPlayers()) do assign(p);records[p.UserId]={name=p.DisplayName,team=teamIndex(p),kills=0,downs=0,deaths=0,heals=0,headshots=0} end
 setPhase('Match',C.RoundSeconds)
 for _,p in ipairs(Players:GetPlayers()) do if alive(p) then movePlayer(p) else p:LoadCharacterAsync() end end
 broadcast()
end
local function finishRound()
 local winning=Rules.winner(scores)
 lastResults={winner=winning,scores=table.clone(scores),rows=rows(),round=round}
 for _,p in ipairs(Players:GetPlayers()) do reward(p,winning~=0 and teamIndex(p)==winning and 150 or 50,winning~=0 and teamIndex(p)==winning and C.WinCoins or C.ParticipationCoins,winning==teamIndex(p) and 'Vitória' or 'Partida concluída') end
 setPhase('Results',C.ResultsSeconds)
 for _,p in ipairs(Players:GetPlayers()) do if alive(p) then movePlayer(p) end end
end
task.spawn(function()
 while true do
  for _,s in pairs(states) do s.remoteCount=0 end
  if phase=='Waiting' and #Players:GetPlayers()>=2 then setPhase('Intermission',C.IntermissionSeconds)
  elseif phase=='Intermission' and #Players:GetPlayers()<2 then setPhase('Waiting',0)
  elseif phase=='Intermission' and now()>=deadline then startRound()
  elseif phase=='Match' then
   local counts={0,0};for _,p in ipairs(Players:GetPlayers()) do local t=teamIndex(p);if t>0 then counts[t]+=1 end end
   if now()>=deadline then finishRound()
   elseif counts[1]==0 or counts[2]==0 then
    lastResults=nil;setPhase('Waiting',0);for _,p in ipairs(Players:GetPlayers()) do movePlayer(p) end
   end
  elseif phase=='Results' and now()>=deadline then setPhase('Intermission',C.IntermissionSeconds-C.ResultsSeconds) end
  task.wait(1)
 end
end)
