local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local TS=game:GetService('TeleportService')
local Memory=game:GetService('MemoryStoreService'):GetHashMap('StillHereSessions_v1');local H=game:GetService('HttpService')
local Profile=require(script.Parent.SessionProfile)
while not workspace:GetAttribute('GameMode') do task.wait(.1) end
local mode=workspace:GetAttribute('GameMode');local parties={};local membership={};local last={};local launching={}
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
 return {profile=Profile.Cache[p],catalog=Profile.Catalog,party=party and {code=code,members=members,leader=party.leader.UserId} or nil}
end
local function launch(members)
 if #members<1 or #members>6 then return false,'O grupo precisa ter de 1 a 6 pessoas.' end
 for _,p in ipairs(members) do if launching[p] or p.Parent~=Players then return false,'Alguém do grupo não está disponível.' end end
 for _,p in ipairs(members) do launching[p]=true end
 local ok,err=pcall(function()
  local options=Instance.new('TeleportOptions');local id=H:GenerateGUID(false)
  local modern=pcall(function() options.ReservedServerId=id end)
  if not modern then local code,privateId=TS:ReserveServerAsync(game.PlaceId);id=privateId;options.ReservedServerAccessCode=code end
  local users={};for _,p in ipairs(members) do users[tostring(p.UserId)]=true end
  Memory:SetAsync(id,{users=users,capacity=6,created=os.time()},3600)
  options:SetTeleportData({session=id});TS:TeleportAsync(game.PlaceId,members,options)
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
 if typeof(action)~='string' or typeof(value)=='table' then return {ok=false,message='Pedido inválido.'} end
 if os.clock()-(last[p] or 0)<.35 then return {ok=false,message='Aguarde um instante.'} end;last[p]=os.clock()
 if action=='state' then if not Profile.Cache[p] then Profile.Load(p) end;return {ok=true,data=snapshot(p)} end
 if launching[p] then return {ok=false,message='A partida já está iniciando.'} end
 local ok,message=true,nil
 if action=='solo' then ok,message=launch({p})
 elseif action=='create' then
  leave(p);local code=H:GenerateGUID(false):gsub('-',''):sub(1,6):upper()
  while parties[code] do code=H:GenerateGUID(false):sub(1,6):upper() end
  parties[code]={leader=p,members={p}};membership[p]=code
 elseif action=='join' then
  local code=typeof(value)=='string' and value:upper():sub(1,6) or '';local party=parties[code]
  if not party or #party.members>=6 then ok=false;message='Grupo não encontrado neste lobby ou está cheio.'
  else leave(p);membership[p]=code;table.insert(party.members,p) end
 elseif action=='leave' then leave(p)
 elseif action=='start' then
  local party=parties[membership[p]];if not party or party.leader~=p then ok=false;message='Só o líder pode iniciar.' else ok,message=launch(party.members) end
 elseif action=='buy' then ok,message=Profile.Buy(p,value);if typeof(message)=='table' then message=ok and 'Compra salva. Será aplicada na partida.' or 'Créditos insuficientes.' end
 else ok=false;message='Pedido inválido.' end
 return {ok=ok,message=message,data=snapshot(p)}
end
TS.TeleportInitFailed:Connect(function(p,result,message) launching[p]=nil;notice:FireClient(p,'Não foi possível entrar na partida. Tenta novamente.');warn('[TeleportInitFailed] '..tostring(result)..': '..message) end)
local function added(p)
 if mode=='Match' then
  local ok,data=pcall(function() return Memory:GetAsync(game.PrivateServerId) end)
  if not ok or not data or not data.users[tostring(p.UserId)] or #Players:GetPlayers()>6 then p:Kick('Esta sessão é restrita ao grupo que a criou.');return end
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
