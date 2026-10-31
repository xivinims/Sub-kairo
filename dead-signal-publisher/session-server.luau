local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local TS=game:GetService('TeleportService')
local Memory=game:GetService('MemoryStoreService'):GetHashMap('StillHereSessions_v1');local H=game:GetService('HttpService')
local Profile=require(script.Parent.SessionProfile)
while not workspace:GetAttribute('GameMode') do task.wait(.1) end
local mode=workspace:GetAttribute('GameMode');local experienceChapter=workspace:GetAttribute('ExperienceChapter')==2 and 2 or 1;local parties={};local membership={};local last={};local launching={};local invitedHostByPlayer={};local placedBesideHost={}
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

local function getInviterUserId(p,joinData)
 local teleportData=type(joinData)=='table' and joinData.TeleportData or nil
 local inviterId=type(teleportData)=='table' and tonumber(teleportData.inviteHostUserId or teleportData.inviterUserId) or nil
 inviterId=inviterId or (type(joinData)=='table' and tonumber(joinData.ReferredByPlayerId) or nil)
 if not inviterId and type(joinData)=='table' and type(joinData.LaunchData)=='string' then
  local ok,data=pcall(function() return H:JSONDecode(joinData.LaunchData) end)
  if ok and type(data)=='table' then inviterId=tonumber(data.inviterUserId) end
 end
 if inviterId==p.UserId then return nil end
 return inviterId
end
local function getInviteRecord(inviterId)
 local ok,record=pcall(function() return Memory:GetAsync('invite:'..tostring(inviterId)) end)
 if ok and type(record)=='table' and type(record.serverId)=='string' and record.expires and record.expires>=os.time() then return record end
 return nil
end
local function routeInvitedPlayer(p,inviterId)
 if experienceChapter~=1 or not inviterId then return false,nil end
 local record=getInviteRecord(inviterId)
 if not record or record.chapter~=1 then return false,nil end
 if mode=='Match' and game.PrivateServerId==record.serverId then return false,record end
 if mode~='Menu' and mode~='Match' then return false,record end
 local options=Instance.new('TeleportOptions')
 options.ReservedServerId=record.serverId
 options:SetTeleportData({session=record.serverId,chapter=1,inviteHostUserId=inviterId})
 local ok,err=pcall(function()
  launching[p]=true;TS:TeleportAsync(game.PlaceId,{p},options)
 end)
 if not ok then
  launching[p]=nil
  notice:FireClient(p,'Não foi possível abrir a sessão do seu amigo.')
  warn('[InviteTeleport] '..tostring(err))
  return false,record
 end
 return true,record
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
  if action=='invite' then
   if experienceChapter~=1 or mode~='Match' then return {ok=false,message='Convites disponíveis durante o Chapter 1.'} end
   if os.clock()-(last[p] or 0)<1 then return {ok=false,message='Aguarde um instante.'} end;last[p]=os.clock()
   local sessionOk,sessionData=pcall(function() return Memory:GetAsync(game.PrivateServerId) end)
   if not sessionOk or type(sessionData)~='table' or type(sessionData.users)~='table' or not sessionData.users[tostring(p.UserId)] then return {ok=false,message='Entre em uma partida antes de convidar.'} end
   if #Players:GetPlayers()>=math.clamp(math.floor(tonumber(sessionData.capacity) or 6),1,6) then return {ok=false,message='Esta partida está cheia.'} end
   local record={serverId=game.PrivateServerId,chapter=1,expires=os.time()+600}
   local saved,err=pcall(function() Memory:SetAsync('invite:'..tostring(p.UserId),record,600) end)
   if not saved then warn('[InvitePrepare] '..tostring(err));return {ok=false,message='Não foi possível preparar o convite.'} end
   return {ok=true,message='Convite pronto.'}
  end
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
 if experienceChapter==1 and (action=='create' or action=='join' or action=='leave' or action=='start') then return {ok=false,message='Use o convite dentro da partida.'} end
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
 local joinData={}
 local inviterId
 if experienceChapter==1 then
  local ok,data=pcall(function() return p:GetJoinData() end)
  if ok and type(data)=='table' then joinData=data;inviterId=getInviterUserId(p,data) end
 end
 local inviteRecord
 if inviterId then
  local routed,record=routeInvitedPlayer(p,inviterId)
  inviteRecord=record
  if routed then return end
 end
 if mode=='Match' then
  local ok,data=pcall(function() return Memory:GetAsync(game.PrivateServerId) end)
  local userKey=tostring(p.UserId)
  if not ok or type(data)~='table' or type(data.users)~='table' then p:Kick('Esta sessão é restrita ao grupo que a criou.');return end
  local capacity=math.clamp(math.floor(tonumber(data.capacity) or 6),1,6)
  local listed=data.users[userKey]==true
  local invited=false
  if experienceChapter==1 and inviterId and inviteRecord and inviteRecord.serverId==game.PrivateServerId and inviteRecord.chapter==1 and data.users[tostring(inviterId)] then
   local host=Players:GetPlayerByUserId(inviterId)
   local checked,isFriend=pcall(function() return p:IsFriendsWith(inviterId) end)
   invited=host~=nil and checked and isFriend==true and #Players:GetPlayers()<=capacity
   if invited and not listed then
    local stored,updated=pcall(function()
     return Memory:UpdateAsync(game.PrivateServerId,function(current)
      if type(current)~='table' or type(current.users)~='table' or not current.users[tostring(inviterId)] then return nil end
      local currentCapacity=math.clamp(math.floor(tonumber(current.capacity) or 6),1,6)
      if #Players:GetPlayers()>currentCapacity then return nil end
      current.users[userKey]=true
      return current
     end,3600)
    end)
    invited=stored and type(updated)=='table' and type(updated.users)=='table' and updated.users[userKey]==true
   end
   if invited then
    invitedHostByPlayer[p]=inviterId
    if host then
     notice:FireClient(host,p.DisplayName..' entrou pelo seu convite.')
     notice:FireClient(p,'Você entrou na partida de '..host.DisplayName..'.')
    end
   end
  end
  if (not listed and not invited) or #Players:GetPlayers()>capacity then p:Kick('Esta sessão é restrita ao grupo que a criou.');return end
  local teleportData=joinData.TeleportData or {}
  local chapter=tonumber(teleportData.chapter) or 1
  if chapter~=experienceChapter or chapter~=(data.chapter or 1) then p:Kick('O código desta sala pertence a outro capítulo.');return end
  if not workspace:GetAttribute('SelectedChapter') then workspace:SetAttribute('SelectedChapter',chapter) elseif workspace:GetAttribute('SelectedChapter')~=chapter then p:Kick('Esta sala está restrita a outro capítulo.');return end
 end
 Profile.Load(p)
 if mode=='Match' then
  local function spawnBesideHost(character)
   local hostId=invitedHostByPlayer[p]
   if not hostId or placedBesideHost[p] then return end
   task.spawn(function()
    local guestRoot=character:WaitForChild('HumanoidRootPart',10)
    local deadline=os.clock()+20
    while guestRoot and p.Parent==Players and os.clock()<deadline do
     local host=Players:GetPlayerByUserId(hostId)
     local hostCharacter=host and host.Character
     local hostRoot=hostCharacter and hostCharacter:FindFirstChild('HumanoidRootPart')
     if hostRoot and hostRoot:IsA('BasePart') then
      task.wait(.35)
      if character.Parent and guestRoot.Parent and hostRoot.Parent then
       character:PivotTo(hostRoot.CFrame*CFrame.new(3.5,0,0))
       placedBesideHost[p]=true
       notice:FireClient(p,'Você nasceu ao lado de '..host.DisplayName..'.')
       return
      end
     end
     task.wait(.2)
    end
   end)
  end
  local function character(c) Profile.Apply(p,c);spawnBesideHost(c) end
  p.CharacterAdded:Connect(character);if p.Character then task.spawn(character,p.Character) end
 end
end
Players.PlayerAdded:Connect(added);for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
Players.PlayerRemoving:Connect(function(p) leave(p);if mode=='Match' then Profile.Reward(p,p:GetAttribute('NPCRescues') or 0) end;invitedHostByPlayer[p]=nil;placedBesideHost[p]=nil;Profile.Cache[p]=nil;last[p]=nil;launching[p]=nil;if experienceChapter==1 then pcall(function() Memory:RemoveAsync('invite:'..tostring(p.UserId)) end) end end)

game:BindToClose(function()
 if mode=='Match' then for _,p in ipairs(Players:GetPlayers()) do Profile.Reward(p,p:GetAttribute('NPCRescues') or 0) end end
end)
