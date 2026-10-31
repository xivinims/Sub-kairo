local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local TS=game:GetService('TeleportService')
local Memory=game:GetService('MemoryStoreService'):GetHashMap('StillHereSessions_v1');local H=game:GetService('HttpService')
local Profile=require(script.Parent.SessionProfile)
while not workspace:GetAttribute('GameMode') do task.wait(.1) end
local mode=workspace:GetAttribute('GameMode');local experienceChapter=workspace:GetAttribute('ExperienceChapter')==2 and 2 or 1;local parties={};local membership={};local last={};local launching={}
local remote=RS:WaitForChild('SessionMenu');local notice=RS:WaitForChild('SessionNotice')
local function leave(p)
 local code=membership[p];local party=code and parties[code];membership[p]=nil
 if party then
  local i=table.find(party.members,p);if i then table.remove(party.members,i) end
  if #party.members==0 then parties[code]=nil elseif party.leader==p then party.leader=party.members[1] end
 end
end
local function snapshot(p)
 local code=membership[p];local party=code and parties[code];local members={}
 if party then for _,member in ipairs(party.members) do table.insert(members,{id=member.UserId,name=member.DisplayName}) end end
 local groups={}
 for groupCode,group in pairs(parties) do
  if not launching[group.leader] then table.insert(groups,{code=groupCode,name=group.leader.DisplayName,count=#group.members,capacity=group.capacity or 6,friendsOnly=group.friendsOnly==true,chapter=group.chapter or 1}) end
 end
 table.sort(groups,function(a,b) return a.code<b.code end)
 return {profile=Profile.Cache[p],groups=groups,party=party and {code=code,members=members,leader=party.leader.UserId,capacity=party.capacity or 6,friendsOnly=party.friendsOnly==true,chapter=party.chapter or 1} or nil}
end
local function launch(members,chapter)
 chapter=experienceChapter
 if #members<1 or #members>6 then return false,'O grupo precisa ter de 1 a 6 pessoas.' end
 for _,p in ipairs(members) do if launching[p] or p.Parent~=Players then return false,'Alguém do grupo não está disponível.' end end
 for _,p in ipairs(members) do launching[p]=true end
 local ok,err=pcall(function()
  local options=Instance.new('TeleportOptions');local id=H:GenerateGUID(false)
  local modern=pcall(function() options.ReservedServerId=id end)
  if not modern then local code,privateId=TS:ReserveServerAsync(game.PlaceId);id=privateId;options.ReservedServerAccessCode=code end
  local users={};for _,p in ipairs(members) do users[tostring(p.UserId)]=true end
  Memory:SetAsync(id,{users=users,capacity=6,chapter=chapter,created=os.time()},3600)
  options:SetTeleportData({session=id,chapter=chapter});TS:TeleportAsync(game.PlaceId,members,options)
 end)
 if not ok then for _,p in ipairs(members) do launching[p]=nil end;warn('[SessionTeleport] '..tostring(err));return false,'Falhou ao iniciar. Tenta novamente.' end
 return true,'Entrando na partida…'
end
remote.OnServerInvoke=function(p,action,value)
 if mode~='Menu' then
  if action~='return' then return {ok=false,message='Disponível no menu.'} end
  if workspace:GetAttribute('DisasterPhase')=='Active' then return {ok=false,message='Espere o desastre acabar para voltar ao menu.'} end
  if os.clock()-(last[p] or 0)<2 then return {ok=false,message='Aguarde.'} end;last[p]=os.clock()
  Profile.Reward(p,p:GetAttribute('NPCRescues') or 0)
  local ok,err=pcall(function() TS:TeleportAsync(game.PlaceId,{p}) end)
  if not ok then warn('[ReturnMenu] '..tostring(err)) end
  return {ok=ok,message=ok and 'Voltando ao menu…' or 'Falhou. Tenta novamente.'}
 end
 if typeof(action)~='string' or (typeof(value)=='table' and action~='create' and action~='solo' and action~='join' and action~='state') then return {ok=false,message='Pedido inválido.'} end
 if os.clock()-(last[p] or 0)<.35 then return {ok=false,message='Aguarde um instante.'} end;last[p]=os.clock()
 if action=='state' then if not Profile.Cache[p] then Profile.Load(p) end;return {ok=true,data=snapshot(p)} end
 if launching[p] then return {ok=false,message='A partida já está iniciando.'} end
 local ok,message=true,nil
 if action=='solo' then ok,message=launch({p},experienceChapter)
 elseif action=='create' then
  leave(p);local code=H:GenerateGUID(false):gsub('-',''):sub(1,6):upper()
  while parties[code] do code=H:GenerateGUID(false):sub(1,6):upper() end
  local options=typeof(value)=='table' and value or {};local n=tonumber(options.capacity) or 6;if n~=n or math.abs(n)==math.huge then n=6 end
  local chapter=experienceChapter
  parties[code]={leader=p,members={p},capacity=math.clamp(math.floor(n),2,6),friendsOnly=options.friendsOnly==true,chapter=chapter};membership[p]=code
 elseif action=='join' then
  local code=typeof(value)=='table' and tostring(value.code or ''):upper():sub(1,6) or typeof(value)=='string' and value:upper():sub(1,6) or '';local party=parties[code]
  local chapter=typeof(value)=='table' and tonumber(value.chapter) or experienceChapter
  if chapter~=experienceChapter then return {ok=false,message='Este lobby pertence a outra experiência.'} end
  local allowed=true
  if party and party.friendsOnly and party.leader~=p then local checked,isFriend=pcall(function() return p:IsFriendsWith(party.leader.UserId) end);allowed=checked and isFriend end
  if party and (party.chapter or 1)~=chapter then ok=false;message='Esse grupo está em outro capítulo.'
  elseif not allowed then ok=false;message='Este grupo é somente para amigos do líder.'
  elseif not party or #party.members>=(party.capacity or 6) or launching[party.leader] then ok=false;message='Grupo não encontrado neste lobby ou está cheio.'
  else leave(p);membership[p]=code;table.insert(party.members,p) end
 elseif action=='leave' then leave(p)
 elseif action=='start' then
  local party=parties[membership[p]];if not party or party.leader~=p then ok=false;message='Só o líder pode iniciar.' else ok,message=launch(table.clone(party.members),party.chapter) end
 elseif action=='chapterTwo' or action=='chapterOne' then
  local destinationChapter=action=='chapterTwo' and 2 or 1
  if destinationChapter==experienceChapter then ok=false;message='Você já está neste capítulo.'
  else
   local destinationPlace=destinationChapter==2 and 87600271104551 or 118064584465155
   launching[p]=true
   local teleported,err=pcall(function() TS:TeleportAsync(destinationPlace,{p}) end)
   if not teleported then launching[p]=nil;ok=false;message='Não foi possível abrir o outro capítulo. Tente novamente.';warn('[ChapterTeleport] '..tostring(err))
   else message=destinationChapter==2 and 'Entrando no Chapter 2…' or 'Voltando ao Chapter 1…' end
  end
 elseif action=='buy' then ok,message=Profile.Buy(p,value);if typeof(message)=='table' then message=ok and 'Compra salva. Será aplicada na partida.' or 'Créditos insuficientes.' end
 else ok=false;message='Pedido inválido.' end
 return {ok=ok,message=message,data=snapshot(p)}
end
TS.TeleportInitFailed:Connect(function(p,result,message) launching[p]=nil;notice:FireClient(p,'Não foi possível entrar na partida. Tenta novamente.');warn('[TeleportInitFailed] '..tostring(result)..': '..message) end)
local function added(p)
 if mode=='Match' then
  local ok,data=pcall(function() return Memory:GetAsync(game.PrivateServerId) end)
  if not ok or not data or not data.users[tostring(p.UserId)] or #Players:GetPlayers()>6 then p:Kick('Esta sessão é restrita ao grupo que a criou.');return end
  local join=p:GetJoinData();local teleportData=join and join.TeleportData or {};local chapter=tonumber(teleportData.chapter) or 1
  if chapter~=experienceChapter or chapter~=(data.chapter or 1) then p:Kick('O código desta sala pertence a outro capítulo.');return end
  if not workspace:GetAttribute('SelectedChapter') then workspace:SetAttribute('SelectedChapter',chapter) elseif workspace:GetAttribute('SelectedChapter')~=chapter then p:Kick('Esta sala está restrita a outro capítulo.');return end
 end
 Profile.Load(p)
 if mode=='Match' then
  local function character(c) Profile.Apply(p,c) end;p.CharacterAdded:Connect(character);if p.Character then task.spawn(character,p.Character) end
 end
end
Players.PlayerAdded:Connect(added);for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
Players.PlayerRemoving:Connect(function(p) leave(p);if mode=='Match' then Profile.Reward(p,p:GetAttribute('NPCRescues') or 0) end;Profile.Cache[p]=nil;last[p]=nil;launching[p]=nil end)

game:BindToClose(function()
 if mode=='Match' then for _,p in ipairs(Players:GetPlayers()) do Profile.Reward(p,p:GetAttribute('NPCRescues') or 0) end end
end)
