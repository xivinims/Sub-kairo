local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local SSS=game:GetService("ServerScriptService")
local RunService=game:GetService("RunService")
local net=RS:WaitForChild("Survival") local config=require(net.Config)
local Rules=require(SSS.RoundRules) local AI=require(SSS.PursuerAI) local KillerFactory=require(SSS.KillerFactory)
local bridge=SSS.SurvivalBridge local assets=SS.SurvivalAssets
local state=Rules.new() local queued={} local rates={} local motions={} local catching={}
local arena,npc,brain=nil,nil,nil local killerName="Jason" local endTime=0
local jasonPlayer=nil local morphing={} local portalInside={} local lastAttack=0
local gate=workspace:WaitForChild("LobbyJoinPortal")
local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function humanoid(p) return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end
local function entry(p) return state.entries[p.UserId] end
local function now() return workspace:GetServerTimeNow() end
local function players()
 local list={} for _,p in ipairs(Players:GetPlayers()) do local e=entry(p) if e and e.status=="alive" and p~=jasonPlayer then table.insert(list,p) end end return list
end
local function sync(p)
 p:SetAttribute("IsJason",p==jasonPlayer)
 local e=entry(p)
 p:SetAttribute("InRound",e~=nil and (e.status=="alive" or e.status=="downed"))
 p:SetAttribute("Downed",e~=nil and e.status=="downed")
 p:SetAttribute("BleedoutAt",e and e.deadline or 0)
 p:SetAttribute("HasMedkit",e~=nil and e.kit or false) p:SetAttribute("HasBoost",e~=nil and e.boost or false)
 p:SetAttribute("RoundStatus",e and e.status or "lobby")
 p:SetAttribute("Queued",queued[p] or false)
 local h=humanoid(p)
 if h then
  h.PlatformStand=false h.AutoRotate=true
  h.WalkSpeed=p==jasonPlayer and 22 or (e and e.status=="downed") and 0 or (p:GetAttribute("MoveMode")=="slow" and 8 or p:GetAttribute("MoveMode")=="run" and 21 or 16)
  h.JumpPower=(e and e.status=="downed") and 0 or 50 h.JumpHeight=(e and e.status=="downed") and 0 or 7.2
 end
end
local function points(p,n)
 local stats=p:FindFirstChild("leaderstats") local v=stats and stats:FindFirstChild("Pontos") if v then v.Value+=n end
end
local function lobby(p)
 local r=root(p) local h=humanoid(p)
 if r then r.Anchored=false p.Character:PivotTo(workspace.IslandSpawn.CFrame*CFrame.new(0,4,0)) r.AssemblyLinearVelocity=Vector3.zero end
 if h then h.PlatformStand=false h.AutoRotate=true h.WalkSpeed=16 h.JumpPower=50 h.JumpHeight=7.2 end
 p:SetAttribute("MoveMode","walk") p:SetAttribute("InRound",false) p:SetAttribute("Downed",false)
end
local function eliminate(p,cause)
 local e=entry(p) if not e or (e.status~="alive" and e.status~="downed") then return end
 e.status="eliminated" e.channel=nil sync(p)
 bridge.DeathRequest:Fire(p,cause or killerName,"spectate")
end
bridge.RoundEliminate.Event:Connect(function(p,cause) eliminate(p,cause) end)
bridge.DeathFinished.Event:Connect(function(p)
 local e=entry(p) if e and e.status=="eliminated" and state.phase=="Partida" then p:SetAttribute("Spectating",true) end
end)
local function vulnerable(p)
 local e=entry(p) return p~=jasonPlayer and e and e.status=="alive" and now()>(e.protectedUntil or 0)
end
local function down(p)
 if not vulnerable(p) or not Rules.down(state,p.UserId,now()) then return end
 local e=entry(p) e.channel=nil e.cause=killerName sync(p)
 net.Update:FireClient(p,"notice","Você caiu. Use seu kit ou espere ajuda.")
end
local function catchPlayer(p)
 if catching[p] or not vulnerable(p) or not npc or not npc.PrimaryPart then return end
 local r=root(p) if not r or (r.Position-npc.PrimaryPart.Position).Magnitude>6 then return end
 catching[p]=true local attacker=npc local roundId=state.id
 attacker:SetAttribute("AttackAt",now()) attacker:SetAttribute("AttackUntil",now()+.75)
 task.delay(.3,function()
  catching[p]=nil
  if state.id~=roundId or npc~=attacker or not attacker.Parent or not p.Parent or not vulnerable(p) then return end
  local rr=root(p) if not rr or (rr.Position-attacker.PrimaryPart.Position).Magnitude>6 then return end
  local param=RaycastParams.new() param.FilterType=Enum.RaycastFilterType.Exclude param.FilterDescendantsInstances={attacker}
  local hit=workspace:Raycast(attacker.PrimaryPart.Position,rr.Position-attacker.PrimaryPart.Position,param)
  if hit and not hit.Instance:IsDescendantOf(p.Character) then return end
  net.Update:FireClient(p,"caught","Jason",attacker.PrimaryPart.CFrame) down(p)
 end)
end
local function join(p)
 if p:GetAttribute("VoidActive") or not root(p) or not humanoid(p) or humanoid(p).Health<=0 then return end
 if not Rules.join(state,p.UserId) then net.Update:FireClient(p,"notice","Partida cheia ou você já participou desta rodada.") return end
 queued[p]=nil p:SetAttribute("Spectating",false) sync(p)
 local e=entry(p) e.loadDeadline=now()+50
 net.Update:FireClient(p,"load",state.id,arena)
end
local function spawnPlayer(p)
 local e=entry(p) local r=root(p) if not r or not npc or not arena then return end
 local best=arena:GetAttribute("EntranceSpawn")
 if p==jasonPlayer then best=arena:GetAttribute("KillerSpawn") end
 if not best then return end
 e.status="alive" e.protectedUntil=now()+5 e.lastScore=now() e.lastNoise=0
 p:SetAttribute("MoveMode","walk") p:SetAttribute("Spectating",false)
 local entranceCF=arena.ArenaEntrance:GetAttribute("DoorCFrame")
 p.Character:PivotTo(CFrame.lookAt(best,best+entranceCF.LookVector))
 if p~=jasonPlayer then e.doorClosed=false e.entryAt=now() net.Update:FireClient(p,"entrance",state.id,entranceCF) end r.AssemblyLinearVelocity=Vector3.zero r.Anchored=false
 motions[p]={position=best,speed=0,grounded=true} sync(p)
end
local function channel(p)
 local h=entry(p) local r=root(p) if not h or not h.kit or h.channel or not r then return end
 local target=p
 if h.status=="alive" then
  local nearest=9 target=nil
  for _,other in ipairs(Players:GetPlayers()) do
   local t=entry(other) local rr=root(other)
   if t and t.status=="downed" and rr and (rr.Position-r.Position).Magnitude<nearest then nearest=(rr.Position-r.Position).Magnitude target=other end
  end
 elseif h.status~="downed" then return end
 if not target then net.Update:FireClient(p,"notice","Aproxime-se de alguém caído para usar o kit.") return end
 h.channel={target=target,started=now(),position=r.Position,status=h.status}
 p:SetAttribute("ReviveAt",now()+Rules.ReviveTime)
end
net.Action.OnServerEvent:Connect(function(p,action,value)
 if type(action)~="string" then return end
 rates[p]=rates[p] or {} local t=now() if t-(rates[p][action] or 0)<.18 then return end rates[p][action]=t
 if action=="join" then return -- Admission is exclusively server-observed portal crossing.
 elseif action=="attack" then
  if p~=jasonPlayer then return end
  local e=entry(p) if not e or e.status~="alive" or t-lastAttack<1.8 then return end
  lastAttack=t
  local rr=root(p) if not rr then return end
  npc:SetAttribute("AttackAt",t) npc:SetAttribute("AttackUntil",t+.75)
  local best=nil local distance=6
  for _,other in ipairs(players()) do local pr=root(other)
   if pr then local delta=pr.Position-rr.Position
    if delta.Magnitude<distance and (delta.Magnitude<.1 or rr.CFrame.LookVector:Dot(delta.Unit)>.1) then best=other distance=delta.Magnitude end
   end
  end
  if best then catchPlayer(best) end
 elseif action=="ready" then local e=entry(p) if e and e.status=="loading" and value==state.id and state.phase=="Partida" then spawnPlayer(p) end
 elseif action=="loadFailed" then if p==jasonPlayer then endTime=now() end local e=entry(p) if e and e.status=="loading" then state.entries[p.UserId]=nil sync(p) end
 elseif action=="mode" then
  local e=entry(p) if p~=jasonPlayer and e and e.status=="alive" and (value=="walk" or value=="slow" or value=="run") then p:SetAttribute("MoveMode",value) sync(p) end
 elseif action=="boost" then if p==jasonPlayer then return end local e=entry(p) if e and e.status=="alive" and e.boost then e.boost=false e.boostUntil=t+4 sync(p) end
 elseif action=="kit" then if p~=jasonPlayer then channel(p) end
 elseif action=="voice" then
  local e=entry(p) local r=root(p) if brain and r and e and e.status=="alive" and type(value)=="number" and value==value and value>.015 and value<=1 then brain.noise(r.Position,config.Killers[killerName].hearing*.8) end
 elseif action=="leave" then
  if p==jasonPlayer then endTime=now() end
  local e=entry(p) if e then e.status="eliminated" e.channel=nil end queued[p]=nil p:SetAttribute("Spectating",false) lobby(p) sync(p)
 elseif action=="spectateExit" then p:SetAttribute("Spectating",false) end
end)
local function hook(p)
 local stats=Instance.new("Folder",p) stats.Name="leaderstats" local v=Instance.new("IntValue",stats) v.Name="Pontos"
 sync(p)
 p.CharacterAdded:Connect(function(char)
  if morphing[p] or (p==jasonPlayer and char:GetAttribute("ActivePursuer")) then return end
  local e=entry(p) if e and (e.status=="alive" or e.status=="downed" or e.status=="loading") then e.status="eliminated" end
  sync(p)
  local h=char:WaitForChild("Humanoid",10)
  if h then h.Died:Connect(function() local x=entry(p) if x and (x.status=="alive" or x.status=="downed") then x.status="eliminated" sync(p) p:SetAttribute("Spectating",true) end end) end
 end)
end
Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
Players.PlayerRemoving:Connect(function(p)
 if p==jasonPlayer then jasonPlayer=nil endTime=now() end
 portalInside[p]=nil morphing[p]=nil
 state.entries[p.UserId]=nil queued[p]=nil rates[p]=nil motions[p]=nil catching[p]=nil end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.2 then return end local step=elapsed elapsed=0 local t=now()
 for _,p in ipairs(Players:GetPlayers()) do
  local e=entry(p) local r=root(p) local h=humanoid(p)
  -- Spatial gate validation cannot be bypassed by firing a client join event.
  if r and h and h.Health>0 and not p:GetAttribute("VoidActive") then
   local pos=gate.CFrame:PointToObjectSpace(r.Position)
   local inside=math.abs(pos.X)<=gate.Size.X/2 and math.abs(pos.Y)<=gate.Size.Y/2 and math.abs(pos.Z)<=gate.Size.Z/2
   if inside and not portalInside[p] and not e then
    if state.phase=="Partida" then join(p) else queued[p]=true lobby(p) sync(p) net.Update:FireClient(p,"notice","Você está na próxima partida.") end
   end
   portalInside[p]=inside
  end
  if e then
   if e.status=="loading" and t>e.loadDeadline then if p==jasonPlayer then endTime=t end state.entries[p.UserId]=nil sync(p) net.Update:FireClient(p,"notice","Carregamento demorou. Tente entrar novamente.") end
   if e.status=="downed" and t>=e.deadline then eliminate(p,e.cause) end
   if e.channel then
    local c=e.channel local tr=root(c.target) local te=entry(c.target)
    local valid=r and tr and te and te.status=="downed" and e.status==c.status and (r.Position-c.position).Magnitude<2 and (r.Position-tr.Position).Magnitude<9
    if valid then
     local param=RaycastParams.new() param.FilterType=Enum.RaycastFilterType.Exclude param.FilterDescendantsInstances={p.Character,c.target.Character}
     valid=not workspace:Raycast(r.Position,tr.Position-r.Position,param)
    end
    if not valid then e.channel=nil p:SetAttribute("ReviveAt",0)
    elseif t-c.started>=Rules.ReviveTime then
     if Rules.revive(state,p.UserId,c.target.UserId,t) then
      te.protectedUntil=t+4 sync(c.target) sync(p) if c.target~=p then points(p,10) end
     end e.channel=nil p:SetAttribute("ReviveAt",0)
    end
   end
   if r and h and (e.status=="alive" or e.status=="downed") then
    if r.Position.Y<20 then
     if p==jasonPlayer then p.Character:PivotTo(CFrame.new(arena:GetAttribute("KillerSpawn"))) else eliminate(p,"void") end
    else
     if p~=jasonPlayer and e.entryAt then
      local doorCF=arena.ArenaEntrance:GetAttribute("DoorCFrame") local localPos=doorCF:PointToObjectSpace(r.Position)
      if not e.doorClosed and (localPos.Z < -7 or t-e.entryAt>2.5) then
       e.doorClosed=true net.Update:FireClient(p,"closeEntrance",state.id)
      end
      if e.doorClosed and math.abs(localPos.X)<4 and math.abs(localPos.Y)<6 and localPos.Z>-.8 and localPos.Z<6 then
       p.Character:PivotTo(doorCF*CFrame.new(math.clamp(localPos.X,-2,2),0,-2)) r.AssemblyLinearVelocity=Vector3.zero
      end
     end
     local m=motions[p] or {position=r.Position,speed=0,grounded=true}
     local displacement=r.Position-m.position m.speed=Vector3.new(displacement.X,0,displacement.Z).Magnitude/step m.position=r.Position motions[p]=m
     if e.status=="alive" then
      if p==jasonPlayer then h.WalkSpeed=22 elseif e.boostUntil and t<e.boostUntil then h.WalkSpeed=27 else h.WalkSpeed=p:GetAttribute("MoveMode")=="run" and 21 or p:GetAttribute("MoveMode")=="slow" and 8 or 16 end
      local grounded=h.FloorMaterial~=Enum.Material.Air
      local jump=m.grounded and not grounded and r.AssemblyLinearVelocity.Y>5
      if p~=jasonPlayer and brain and (jump or m.speed>10) and t-(e.lastNoise or 0)>.45 then
       brain.noise(r.Position,config.Killers[killerName].hearing*(jump and 1 or m.speed>18 and 1 or .55)) e.lastNoise=t
      end m.grounded=grounded
      if t-(e.lastScore or t)>=10 then e.lastScore=t points(p,1) end
     end
    end
   end
  end
 end
end)
local function finish()
 state.phase="Intervalo" if brain then brain.stop() brain=nil end
 local former=jasonPlayer jasonPlayer=nil
 if former and former.Parent then morphing[former]=true former:SetAttribute("IsJason",false) pcall(function() former:LoadCharacterAsync() end) morphing[former]=nil end
 for _,p in ipairs(Players:GetPlayers()) do
  net.Update:FireClient(p,"reset")
  local e=entry(p) if e then if e.status=="alive" then points(p,20) end
   -- Finish cinematic before cleaning arena; lobby position remains safe.
   RS.SweanVoidEvent:FireClient(p,"finish") p:SetAttribute("Spectating",false) lobby(p)
  end
 end
 table.clear(state.entries) for _,p in ipairs(Players:GetPlayers()) do sync(p) end
 if npc then npc:Destroy() npc=nil end if arena then arena:Destroy() arena=nil end
end
task.spawn(function()
 while true do
  finish()

  while #Players:GetPlayers()<1 do
   net:SetAttribute("Phase","Aguardando")
   net:SetAttribute("EndsAt",0)
   net:SetAttribute("Count",0)
   net:SetAttribute("Waiting",0)
   net:SetAttribute("MaxPlayers",Rules.Capacity)
   task.wait(1)
  end

  endTime=now()+Rules.Intermission
  while now()<endTime and #Players:GetPlayers()>0 do
   net:SetAttribute("Phase","Intervalo")
   net:SetAttribute("EndsAt",endTime)
   net:SetAttribute("Count",0)
   local waiting=0 for p in pairs(queued) do if p.Parent then waiting+=1 end end
   net:SetAttribute("Waiting",math.min(waiting,Rules.Capacity))
   net:SetAttribute("MaxPlayers",Rules.Capacity)
   task.wait(1)
  end

  if #Players:GetPlayers()>0 then
   local ok,err=xpcall(function()
    Rules.begin(state)
    local mapList=assets.Maps:GetChildren() local rigList=assets.Killers:GetChildren()
    arena=mapList[math.random(#mapList)]:Clone() arena.Name="ActiveArena" arena.Parent=workspace arena:SetAttribute("RoundId",state.id)
    local chosen=rigList[math.random(#rigList)]
    killerName=chosen.Name
    npc=KillerFactory.create(killerName,config.Killers[killerName])
    npc.Parent=workspace
    npc:PivotTo(CFrame.new(arena:GetAttribute("KillerSpawn")))
    for _,d in ipairs(npc:GetDescendants()) do if d:IsA("BasePart") then d.Anchored=false pcall(function() d:SetNetworkOwner(nil) end) end end
    npc:SetAttribute("ActivePursuer",true)
    npc:FindFirstChildOfClass("Humanoid").Died:Connect(function() endTime=now() end)
    local eligible={}
    for _,p in ipairs(Players:GetPlayers()) do if queued[p] and root(p) and humanoid(p) and humanoid(p).Health>0 and not p:GetAttribute("VoidActive") then table.insert(eligible,p) end end
    table.sort(eligible,function(a,b) return a.UserId<b.UserId end)
    if #eligible>=8 and math.random()<config.PlayerJasonChance then
     jasonPlayer=eligible[math.random(1,8)]
     local old=jasonPlayer.Character morphing[jasonPlayer]=true
     npc.Name=jasonPlayer.Name jasonPlayer.Character=npc
     morphing[jasonPlayer]=nil if old then old:Destroy() end
     for _,d in ipairs(npc:GetDescendants()) do if d:IsA("BasePart") then pcall(function() d:SetNetworkOwner(jasonPlayer) end) end end
     net.Update:FireClient(jasonPlayer,"notice","Você é Jason. Persiga os sobreviventes e use o botão de ataque.")
    else
     brain=AI.start(npc,arena,config.Killers.Jason,{players=players,vulnerable=vulnerable,catch=catchPlayer})
    end
    endTime=now()+Rules.Duration
    net:SetAttribute("Phase","Partida")
    net:SetAttribute("EndsAt",endTime)
    net:SetAttribute("Killer",killerName)
    net:SetAttribute("Map",arena:GetAttribute("DisplayName") or "Mapa")
    net:SetAttribute("MaxPlayers",Rules.Capacity)

    local admitted=0
    if jasonPlayer then join(jasonPlayer) if entry(jasonPlayer) then admitted=1 end end
    for _,p in ipairs(Players:GetPlayers()) do
     if admitted>=Rules.Capacity then break end
     if queued[p] and p.Parent and root(p) and humanoid(p) and humanoid(p).Health>0 and not p:GetAttribute("VoidActive") then
      join(p)
      if entry(p) then admitted+=1 end
     end
    end

    while now()<endTime do
     net:SetAttribute("Count",Rules.count(state))
     task.wait(1)
    end
   end,debug.traceback)
   if not ok then
    warn("Survival round: "..tostring(err))
    net.Update:FireAllClients("notice","A rodada foi reiniciada com segurança.")
   end
  end
 end
end)

