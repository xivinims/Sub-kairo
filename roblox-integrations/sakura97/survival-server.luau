local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local SSS=game:GetService("ServerScriptService")
local RunService=game:GetService("RunService")
local profileStore=nil
pcall(function() profileStore=game:GetService("DataStoreService"):GetDataStore("SuviversProfiles_v1") end)
local Profiles=require(SSS:WaitForChild("ProfileService"))
local profiles=Profiles.new(profileStore)
local musicObjects={} local MUSIC_PRICE=20
local function saveProfile(p,flush)
 if not p:GetAttribute("ProfileLoaded") and p.Parent then profiles:load(p) end
 local ok
 if flush then ok=profiles:flush(p,20) else ok=profiles:save(p) end
 if not ok and p.Parent and p:GetAttribute("ProfileLoaded") then warn("Suvivers profile save pending for "..tostring(p.UserId)) end
 return ok
end
local net=RS:WaitForChild("Survival") local config=require(net.Config)
local Rules=require(SSS.RoundRules) local AI=require(SSS.PursuerAI) local KillerFactory=require(SSS.KillerFactory)
local bridge=SSS.SurvivalBridge local assets=SS.SurvivalAssets local items=assets:WaitForChild("Items")
local state=Rules.new() local queued={} local rates={} local motions={} local catching={}
local arena,npc,brain=nil,nil,nil local killerName="Jason" local endTime=0 local introUntil=0
local jasonPlayer=nil local morphing={} local rigRetries={} local portalInside={} local lastAttack=0
local roundClosing=false local previousMap=nil local saveAt={}
local lastKilledUserId=0 local lastKilledName=nil
local gate=workspace:WaitForChild("LobbyJoinPortal")
local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function humanoid(p) return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end
local function entry(p) return state.entries[p.UserId] end
local function now() return workspace:GetServerTimeNow() end
local function players()
 local list={} for _,p in ipairs(Players:GetPlayers()) do local e=entry(p) if e and (e.status=="alive" or e.status=="downed") and p~=jasonPlayer then table.insert(list,p) end end return list
end
local function sync(p)
 p:SetAttribute("IsJason",p==jasonPlayer)
 local e=entry(p)
 p:SetAttribute("InRound",e~=nil and (e.status=="alive" or e.status=="downed"))
 p:SetAttribute("Downed",e~=nil and e.status=="downed")
 p:SetAttribute("Injured",e~=nil and e.injured==true)
 p:SetAttribute("BleedoutAt",e and e.deadline or 0)
 p:SetAttribute("ProtectedUntil",e and e.protectedUntil or 0)
 p:SetAttribute("HasMedkit",e~=nil and e.kit or false) p:SetAttribute("HasBoost",e~=nil and e.boost or false)
 p:SetAttribute("RoundStatus",e and e.status or "lobby")
 p:SetAttribute("Queued",queued[p] or false)
 local h=humanoid(p)
 if h then
  local introLocked=e and e.status=="alive" and now()<introUntil
  h.PlatformStand=false h.AutoRotate=true
  h.WalkSpeed=introLocked and 0 or p==jasonPlayer and 22 or (e and e.status=="downed") and 0 or (e and e.injured and (p:GetAttribute("MoveMode")=="slow" and 7 or 12)) or (p:GetAttribute("MoveMode")=="slow" and 8 or p:GetAttribute("MoveMode")=="run" and 21 or 16)
  h.JumpPower=(introLocked or (e and e.status=="downed")) and 0 or 50
  h.JumpHeight=(introLocked or (e and e.status=="downed")) and 0 or 7.2
 end
end
local function points(p,n)
 profiles:points(p,n)
end
local function clearFlashlight(p)
 local char=p.Character
 local existing=char and char:FindFirstChild("EquippedFlashlight")
 if existing then existing:Destroy() end
 p:SetAttribute("FlashlightOn",false)
end
local function setFlashlight(p,on)
 clearFlashlight(p)
 if not on or p==jasonPlayer then return false end
 local char=p.Character local h=humanoid(p)
 if not char or not h or h.Health<=0 or p:GetAttribute("Downed") then return false end
 local hand=char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
 if not hand or not hand:IsA("BasePart") then return false end
 local tool=items.Flashlight:Clone()
 tool.Name="EquippedFlashlight"
 local handle=tool:FindFirstChild("Handle")
 if not handle or not handle:IsA("BasePart") then tool:Destroy() return false end
 for _,part in ipairs(tool:GetDescendants()) do
  if part:IsA("BasePart") then part.Anchored=false part.CanCollide=false part.CanTouch=false part.Massless=true end
 end
 tool.Parent=char
 local grip=tool.Grip
 handle.CFrame=hand.CFrame*grip
 local weld=Instance.new("WeldConstraint")
 weld.Name="FlashlightGrip" weld.Part0=hand weld.Part1=handle weld.Parent=handle
 local light=handle:FindFirstChild("GameplayLight") or Instance.new("PointLight")
 light.Name="GameplayLight" light.Color=Color3.fromRGB(240,238,214) light.Range=24 light.Brightness=2.4 light.Shadows=false light.Parent=handle
 p:SetAttribute("FlashlightOn",true)
 return true
end

local function lobby(p)
 bridge.CancelDeath:Fire(p)
 clearFlashlight(p)
 local r=root(p) local h=humanoid(p)
 if r and p.Character then
  local spawn=workspace:FindFirstChild("IslandSpawn")
  local lobbyModel=workspace:FindFirstChild("JediLibrary")
  local base=lobbyModel and lobbyModel:GetAttribute("VerifiedSpawn")
  if typeof(base)~="Vector3" then base=spawn and spawn.Position or r.Position end
  local pivot=p.Character:GetPivot()
  local bcf,bsize=p.Character:GetBoundingBox()
  local bottom=bcf.Position.Y-bsize.Y/2
  local pivotToBottom=math.max(2.5,pivot.Position.Y-bottom)
  local pos=Vector3.new(base.X,base.Y+pivotToBottom+.3,base.Z)
  local forward=spawn and Vector3.new(spawn.CFrame.LookVector.X,0,spawn.CFrame.LookVector.Z) or Vector3.new(0,0,-1)
  if forward.Magnitude<.1 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
  r.Anchored=true
  p.Character:PivotTo(CFrame.lookAt(pos,pos+forward))
  r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
  task.delay(.2,function() if r.Parent and p.Character and p.Character:IsAncestorOf(r) then r.Anchored=false end end)
 end
 if h then h.Health=h.MaxHealth h.PlatformStand=false h.AutoRotate=true h.WalkSpeed=16 h.JumpPower=50 h.JumpHeight=7.2 end
 p:SetAttribute("MoveMode","walk") p:SetAttribute("InRound",false) p:SetAttribute("Downed",false) p:SetAttribute("Injured",false)
end
local function eliminate(p,cause)
 local e=entry(p) if not e or (e.status~="alive" and e.status~="downed") then return end
 local actualCause=cause or killerName
 if p~=jasonPlayer and actualCause==killerName then
  lastKilledUserId=p.UserId
  lastKilledName=p.DisplayName or p.Name
 end
 e.status="eliminated" e.channel=nil p:SetAttribute("ReviveAt",0) sync(p)
 bridge.DeathRequest:Fire(p,actualCause,"spectate")
end
bridge.RoundEliminate.Event:Connect(function(p,cause) eliminate(p,cause) end)
bridge.DeathFinished.Event:Connect(function(p)
 local e=entry(p) if e and e.status=="eliminated" and state.phase=="Partida" then p:SetAttribute("Spectating",true) end
end)
local function vulnerable(p)
 local e=entry(p) return p~=jasonPlayer and e and e.status=="alive" and now()>(e.protectedUntil or 0)
end
local function targetable(p)
 local e=entry(p)
 return vulnerable(p) or (p~=jasonPlayer and e and e.status=="downed" and now()>(e.downedAt or now())+5 and not p:GetAttribute("BeingExecuted"))
end
local function injure(p)
 if not vulnerable(p) then return false end
 local e=entry(p)
 if e.injured then return false end
 e.hits=(e.hits or 0)+1
 local stats=p:FindFirstChild("leaderstats") local hitCount=stats and stats:FindFirstChild("Atingido") if hitCount then hitCount.Value+=1 end
 e.injured=true e.channel=nil e.boostUntil=nil p:SetAttribute("MoveMode","walk") p:SetAttribute("HitAt",now())
 sync(p)
 net.Update:FireClient(p,"notice","Você está ferido. Seus movimentos ficaram mais lentos.")
 return true
end
local function down(p)
 if not vulnerable(p) or not Rules.down(state,p.UserId,now()) then return end
 clearFlashlight(p)
 local e=entry(p) e.downedAt=now() e.hits=(e.hits or 0)+1 local hitStats=p:FindFirstChild("leaderstats") if hitStats and hitStats:FindFirstChild("Atingido") then hitStats.Atingido.Value+=1 end e.falls=(e.falls or 0)+1 local stats=p:FindFirstChild("leaderstats") local falls=stats and stats:FindFirstChild("Quedas") if falls then falls.Value+=1 end e.injured=true e.channel=nil e.cause=killerName sync(p)
 net.Update:FireClient(p,"notice","Você caiu. Use seu kit ou espere ajuda.")
end
local function executeDowned(p,attacker)
 local e=entry(p)
 if not e or e.status~="downed" or catching[p] or not attacker or not attacker.PrimaryPart then return false end
 local rr=root(p)
 if not rr or (rr.Position-attacker.PrimaryPart.Position).Magnitude>7 then return false end
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={attacker}
 local obstruction=workspace:Raycast(attacker.PrimaryPart.Position,rr.Position-attacker.PrimaryPart.Position,params)
 if obstruction and not obstruction.Instance:IsDescendantOf(p.Character) then return false end
 local capturedEntry=e local capturedCharacter=p.Character local capturedRound=state.id
 e.channel=nil p:SetAttribute("ReviveAt",0)
 catching[p]=true
 local t=now()
 attacker:SetAttribute("ExecutionAt",t)
 attacker:SetAttribute("ExecutionTargetUserId",p.UserId)
 attacker:SetAttribute("AttackUntil",t+1.65)
 p:SetAttribute("BeingExecuted",true)
 local facing=attacker.PrimaryPart.CFrame
 local targetCF=facing*CFrame.new(0,0,-2.15)
 p.Character:PivotTo(CFrame.lookAt(targetCF.Position,attacker.PrimaryPart.Position))
 rr.Anchored=true
 net.Update:FireClient(p,"executed",killerName,attacker.PrimaryPart.CFrame)
 task.delay(1.25,function()
  catching[p]=nil
  if rr and rr.Parent then rr.Anchored=false end
  if p.Parent then p:SetAttribute("BeingExecuted",false) end
  if attacker and attacker.Parent then
   attacker:SetAttribute("ExecutionTargetUserId",0)
  end
  local current=entry(p)
  if state.id==capturedRound and current==capturedEntry and p.Character==capturedCharacter and current.status=="downed" then eliminate(p,killerName) end
 end)
 return true
end
local function catchPlayer(p)
 if catching[p] or not npc or not npc.PrimaryPart then return end
 local e=entry(p)
 if not e then return end
 if e.status=="downed" then
  executeDowned(p,npc)
  return
 end
 if not vulnerable(p) then return end
 local r=root(p) if not r or (r.Position-npc.PrimaryPart.Position).Magnitude>6 then return end
 catching[p]=true local attacker=npc local roundId=state.id local targetCharacter=p.Character
 attacker:SetAttribute("AttackAt",now()) attacker:SetAttribute("AttackUntil",now()+.75)
 task.delay(.3,function()
  catching[p]=nil
  if p.Character~=targetCharacter or state.id~=roundId or npc~=attacker or not attacker.Parent or not p.Parent or not vulnerable(p) then return end
  local rr=root(p) if not rr or (rr.Position-attacker.PrimaryPart.Position).Magnitude>6 then return end
  local param=RaycastParams.new() param.FilterType=Enum.RaycastFilterType.Exclude param.FilterDescendantsInstances={attacker}
  local hit=workspace:Raycast(attacker.PrimaryPart.Position,rr.Position-attacker.PrimaryPart.Position,param)
  if hit and not hit.Instance:IsDescendantOf(p.Character) then return end
  net.Update:FireClient(p,"caught",killerName,attacker.PrimaryPart.CFrame)
  local current=entry(p)
  if current and current.injured then down(p) else injure(p) end
 end)
end
local function join(p)
 if roundClosing or p:GetAttribute("AFK") or p:GetAttribute("VoidActive") or not root(p) or not humanoid(p) or humanoid(p).Health<=0 then return false end
 if not Rules.join(state,p.UserId) then net.Update:FireClient(p,"notice","Partida cheia ou você já participou desta rodada.") return false end
 queued[p]=nil p:SetAttribute("Spectating",false) p:SetAttribute("InMenu",false) sync(p)
 local e=entry(p) e.loadDeadline=now()+50
 -- Preload is advisory only. Admission itself is server-owned and must never wait on a client ready callback.
 net.Update:FireClient(p,"load",state.id,arena)
 return true
end
local function introSceneData()
 if not arena or not npc or not npc.PrimaryPart then return nil end
 local killerSpawn=arena:GetAttribute("KillerSpawn")
 if typeof(killerSpawn)~="Vector3" then return nil end
 local endPivot=npc:GetPivot()
 local safe=arena:FindFirstChild("SafePoints")
 local startPoint=nil local bestDistance=0
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={arena}
 params.RespectCanCollide=true
 if safe then
  for _,v in ipairs(safe:GetChildren()) do
   if v:IsA("Vector3Value") then
    local distance=(v.Value-killerSpawn).Magnitude
    if distance>=12 and distance<=34 then
     local origin=v.Value+Vector3.new(0,1.7,0)
     local delta=killerSpawn-v.Value
     local hit=workspace:Raycast(origin,delta,params)
     if not hit and distance>bestDistance then startPoint=v.Value bestDistance=distance end
    end
   end
  end
  if not startPoint then
   local nearest=nil local nearestDistance=math.huge
   for _,v in ipairs(safe:GetChildren()) do
    if v:IsA("Vector3Value") then
     local distance=(v.Value-killerSpawn).Magnitude
     if distance>8 and distance<nearestDistance then nearest=v.Value nearestDistance=distance end
    end
   end
   startPoint=nearest
  end
 end
 -- Start at the real pursuer spawn and let the local clone walk straight through a low camera.
 local startPos=endPivot.Position
 local toward=startPoint and (startPoint-startPos) or npc.PrimaryPart.CFrame.LookVector*24
 toward=Vector3.new(toward.X,0,toward.Z)
 if toward.Magnitude<1 then toward=Vector3.new(npc.PrimaryPart.CFrame.LookVector.X,0,npc.PrimaryPart.CFrame.LookVector.Z) end
 if toward.Magnitude<1 then toward=Vector3.new(0,0,-1) end
 local forward=toward.Unit
 local endPos=startPos+forward*22
 local startCF=CFrame.lookAt(startPos,startPos+forward)
 local endCF=CFrame.lookAt(endPos,endPos+forward)
 local right=forward:Cross(Vector3.yAxis)
 if right.Magnitude<.1 then right=Vector3.xAxis else right=right.Unit end
 local cameraPos=startPos+forward*10+right*1.4+Vector3.new(0,.65,0)
 local focus=cameraPos+forward*7+Vector3.new(0,1.35,0)
 local cameraCF=CFrame.lookAt(cameraPos,focus)
 return {duration=4,runDuration=3.25,startCF=startCF,endCF=endCF,cameraCF=cameraCF,passThroughCamera=true}
end

local function safeRoundSpawnCF(character,desired,face)
 if not character or typeof(desired)~="Vector3" or not arena then return nil end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={arena}
 params.RespectCanCollide=true
 local hit=workspace:Raycast(desired+Vector3.new(0,12,0),Vector3.new(0,-30,0),params)
 if not hit or hit.Normal.Y<.82 then return nil end
 local _,size=character:GetBoundingBox()
 if workspace:Raycast(hit.Position+Vector3.new(0,.35,0),Vector3.new(0,size.Y+1.2,0),params) then return nil end
 local pivot=character:GetPivot()
 local bcf,bsize=character:GetBoundingBox()
 local bottom=bcf.Position.Y-bsize.Y/2
 local pivotToBottom=math.max(2.5,pivot.Position.Y-bottom)
 local pos=Vector3.new(hit.Position.X,hit.Position.Y+pivotToBottom+.25,hit.Position.Z)
 local forward=Vector3.new(face.X,0,face.Z)
 if forward.Magnitude<.1 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
 return CFrame.lookAt(pos,pos+forward),hit.Position
end

local function spawnPlayer(p)
 local e=entry(p) local r=root(p)
 if not e or not r or not p.Character or not npc or not arena then return false end
 local entranceCF=arena.ArenaEntrance:GetAttribute("DoorCFrame")
 local face=entranceCF and entranceCF.LookVector or Vector3.new(0,0,-1)
 local chosenCF=nil local ground=nil

 if p==jasonPlayer then
  local wanted=arena:GetAttribute("KillerSpawn")
  chosenCF,ground=safeRoundSpawnCF(p.Character,wanted,face)
 else
  local spawns=arena:FindFirstChild("ArrivalSpawns")
  local choices={}
  if spawns then
   for _,point in ipairs(spawns:GetChildren()) do
    if point:IsA("Vector3Value") then
     local cf,g=safeRoundSpawnCF(p.Character,point.Value,face)
     if cf then
      local clearance=1000
      for _,other in ipairs(Players:GetPlayers()) do
       local oe=entry(other) local oroot=root(other)
       if other~=p and oe and oe.status=="alive" and oroot then clearance=math.min(clearance,(oroot.Position-g).Magnitude) end
      end
      table.insert(choices,{cf=cf,ground=g,clearance=clearance})
     end
    end
   end
  end
  table.sort(choices,function(a,b) return a.clearance>b.clearance end)
  if choices[1] then chosenCF,ground=choices[1].cf,choices[1].ground end
 end

 if not chosenCF then
  warn("No safe round spawn for "..p.Name)
  return false
 end

 e.status="alive" e.spawnRecovery=nil e.spawnGraceUntil=now()+12
 e.protectedUntil=math.max(e.protectedUntil or 0,now()+10)
 e.lastScore=now() e.lastNoise=0
 p:SetAttribute("MoveMode","walk") p:SetAttribute("Spectating",false) p:SetAttribute("InMenu",false)

 local h=humanoid(p)
 if h then h.Health=h.MaxHealth h.PlatformStand=false h.AutoRotate=true end
 local oldShield=p.Character:FindFirstChild("RoundSpawnProtection")
 if oldShield then oldShield:Destroy() end
 local shield=Instance.new("ForceField") shield.Name="RoundSpawnProtection" shield.Visible=false shield.Parent=p.Character

 r.Anchored=true
 p.Character:PivotTo(chosenCF)
 r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
 if p~=jasonPlayer then e.doorClosed=false e.entryAt=now() net.Update:FireClient(p,"entrance",state.id,entranceCF) end
 motions[p]={position=ground or chosenCF.Position,speed=0,grounded=true}
 sync(p)
 task.delay(.4,function()
  if r.Parent and p.Character and p.Character:IsAncestorOf(r) and entry(p)==e and e.status=="alive" then
   r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero r.Anchored=false
  end
 end)
 task.delay(6,function() if shield.Parent then shield:Destroy() end end)
 return true
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
 if p:GetAttribute("BeingExecuted") or target:GetAttribute("BeingExecuted") then return end
 h.channel={target=target,started=now(),position=r.Position,status=h.status}
 p:SetAttribute("ReviveAt",now()+Rules.ReviveTime)
end
net.Action.OnServerEvent:Connect(function(p,action,value)
 if type(action)~="string" or #action>24 then return end
 rates[p]=rates[p] or {} local t=now() if t-(rates[p][action] or 0)<.18 then return end rates[p][action]=t
 if action=="afk" then
  if type(value)~="boolean" then return end
  p:SetAttribute("AFK",value)
  if value then queued[p]=nil end
  sync(p)
  net.Update:FireClient(p,"notice",value and "AFK ativado. Você não entra nas próximas partidas." or "AFK desativado. Você participa da próxima partida.")
  return
 end
 if t<introUntil and action~="leave" and action~="spectateExit" then return end
 if action=="join" then return -- Admission is exclusively server-observed portal crossing.
 elseif action=="attack" then
  if p~=jasonPlayer then return end
  local e=entry(p) if not e or e.status~="alive" or t-lastAttack<1.8 then return end
  lastAttack=t
  local rr=root(p) if not rr then return end
  npc:SetAttribute("AttackAt",t) npc:SetAttribute("AttackUntil",t+.75)
  local best=nil local distance=6
  for _,other in ipairs(Players:GetPlayers()) do
   if other~=p then
    local oe=entry(other) local pr=root(other)
    if oe and (oe.status=="alive" or oe.status=="downed") and pr then
     local delta=pr.Position-rr.Position
     if delta.Magnitude<distance and (delta.Magnitude<.1 or rr.CFrame.LookVector:Dot(delta.Unit)>.1) then
      best=other distance=delta.Magnitude
     end
    end
   end
  end
  if best then catchPlayer(best) end
 elseif action=="ready" then local e=entry(p) if e and e.status=="loading" and value==state.id and state.phase=="Partida" then spawnPlayer(p) end
 elseif action=="loadFailed" then
  local e=entry(p)
  if value==state.id and e and e.status=="loading" then
   if p==jasonPlayer then endTime=now() end
   state.entries[p.UserId]=nil sync(p)
  end
 elseif action=="mode" then
  local e=entry(p)
  if e and e.injured and value=="run" then value="walk" end
  if p~=jasonPlayer and (value=="walk" or value=="slow" or value=="run") and (not e or e.status=="alive") then p:SetAttribute("MoveMode",value) sync(p) end
 elseif action=="boost" then if p==jasonPlayer then return end local e=entry(p) if e and e.status=="alive" and not e.injured and e.boost then e.boost=false e.boostUntil=t+4 sync(p) end
 elseif action=="flashlight" then
  local e=entry(p)
  if p~=jasonPlayer and not p:GetAttribute("Downed") and (not e or e.status=="alive") then setFlashlight(p,not p:GetAttribute("FlashlightOn")) end
 elseif action=="kit" then if p~=jasonPlayer then channel(p) end
 elseif action=="musicBuy" then
  if not p:GetAttribute("ProfileLoaded") then net.Update:FireClient(p,"notice","Seu progresso ainda está carregando. Aguarde para comprar.") return end
  if p:GetAttribute("Cantor") then net.Update:FireClient(p,"notice","Você já liberou o distintivo Cantor.") return end
  local stats=p:FindFirstChild("leaderstats") local currency=stats and stats:FindFirstChild("Pontos")
  if not currency or currency.Value<MUSIC_PRICE then net.Update:FireClient(p,"notice","Music custa 20 Pontos.") return end
  points(p,-MUSIC_PRICE) p:SetAttribute("Cantor",true) task.spawn(saveProfile,p)
  net.Update:FireClient(p,"notice","Music desbloqueado! Distintivo Cantor liberado.")
 elseif action=="musicPlay" then
  if not p:GetAttribute("Cantor") or type(value)~="string" or #value<1 or #value>20 or not value:match("^%d+$") then return end
  local id=tonumber(value) if not id or id<1 or id>9007199254740991 or id%1~=0 then return end
  if musicObjects[p] then musicObjects[p]:Destroy() musicObjects[p]=nil end
  local r=root(p) if not r then return end
  local sound=Instance.new("Sound") sound.Name="CantorMusic" sound.SoundId="rbxassetid://"..id sound.Volume=.16 sound.Looped=true sound.RollOffMaxDistance=45 sound.RollOffMinDistance=8 sound.Parent=r
  musicObjects[p]=sound pcall(function() sound:Play() end)
 elseif action=="musicStop" then if musicObjects[p] then musicObjects[p]:Destroy() musicObjects[p]=nil end
 elseif action=="voice" then
  local e=entry(p) local r=root(p) if brain and r and e and e.status=="alive" and type(value)=="number" and value==value and value>.015 and value<=1 then brain.noise(r.Position,config.Killers[killerName].hearing*.8) end
 elseif action=="leave" then
  if p==jasonPlayer then endTime=now() end
  local e=entry(p) if e then e.status="eliminated" e.channel=nil end p:SetAttribute("ReviveAt",0) queued[p]=nil p:SetAttribute("Spectating",false) lobby(p) sync(p)
 elseif action=="spectateExit" then p:SetAttribute("Spectating",false) end
end)
local function isR6Character(char)
 local h=char and char:FindFirstChildOfClass("Humanoid")
 return h and h.RigType==Enum.HumanoidRigType.R6 and char:FindFirstChild("Torso")~=nil and char:FindFirstChild("Left Arm")~=nil and char:FindFirstChild("Right Arm")~=nil
end

local function convertCharacterToR6(p,char)
 local h=char and char:FindFirstChildOfClass("Humanoid")
 if not h or h.RigType==Enum.HumanoidRigType.R6 then
  if char then char:SetAttribute("SurvivorR6",true) char:SetAttribute("AppearanceUserId",p.UserId) end
  p:SetAttribute("SurvivorRig","R6")
  return char
 end
 local pivot=char:GetPivot()
 local animate=char:FindFirstChild("Animate")
 -- Use the player's actual Roblox avatar description, then force that appearance onto an R6 body.
 local okDesc,description=pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(p.UserId) end)
 if not okDesc or not description then okDesc,description=pcall(function() return h:GetAppliedDescription() end) end
 if not okDesc or not description then return nil end
 description.UseAvatarSettings=false
 local ok,newChar=pcall(function()
  return Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
 end)
 if not ok or not newChar then return nil end
 newChar.Name=p.Name
 newChar:SetAttribute("SurvivorR6",true)
 newChar:SetAttribute("AppearanceUserId",p.UserId)
 newChar:SetAttribute("AppearancePreserved",true)
 local nh=assert(newChar:FindFirstChildOfClass("Humanoid"),"R6 avatar missing Humanoid")
 nh.RequiresNeck=false nh.BreakJointsOnDeath=false
 pcall(function() nh.DisplayName=p.DisplayName end)
 if animate and not newChar:FindFirstChild("Animate") then
  local clone=animate:Clone() clone.Disabled=false clone.Parent=newChar
 end
 newChar.Parent=workspace
 newChar:PivotTo(pivot)
 for _,part in ipairs(newChar:GetDescendants()) do
  if part:IsA("BasePart") then pcall(function() part:SetNetworkOwner(p) end) end
 end
 p.Character=newChar
 char:Destroy()
 p:SetAttribute("SurvivorRig","R6")
 return newChar
end

local function hook(p)
 local stats=Instance.new("Folder",p) stats.Name="leaderstats"
 local function makeStat(name,value) local v=Instance.new("IntValue",stats) v.Name=name v.Value=value or 0 return v end
 makeStat("Pontos",0) local xp=makeStat("XP",0) makeStat("Nível",1) makeStat("Atingido",0) makeStat("Quedas",0)
 profiles:attach(p) saveAt[p]=now()+150+math.random(0,30)
 task.spawn(function() if not profiles:load(p) and p.Parent then net.Update:FireClient(p,"notice","O progresso está temporariamente indisponível. Sua compra fica protegida.") end end)
 sync(p)
 local onCharacter
 onCharacter=function(char)
  if morphing[p] or (p==jasonPlayer and char:GetAttribute("ActivePursuer")) then return end
  local h=char:WaitForChild("Humanoid",10)
  if h and h.RigType~=Enum.HumanoidRigType.R6 and p~=jasonPlayer then
   morphing[p]=true
   local converted=convertCharacterToR6(p,char)
   morphing[p]=nil
   if converted and converted~=char then
    rigRetries[p]=nil
    onCharacter(converted)
    return
   end
   rigRetries[p]=(rigRetries[p] or 0)+1
   if rigRetries[p]<3 then task.delay(1.5,function() if p.Parent and p.Character==char then onCharacter(char) end end) end
  elseif h and p~=jasonPlayer then
   rigRetries[p]=nil
   char:SetAttribute("SurvivorR6",true)
   char:SetAttribute("AppearanceUserId",p.UserId)
   p:SetAttribute("SurvivorRig","R6")
  end
  local e=entry(p)
  if e and (e.status=="alive" or e.status=="downed" or e.status=="loading") then
   if state.phase=="Partida" and e.spawnRecovery then
    e.spawnRecovery=nil
    task.defer(function() if p.Parent and entry(p)==e and state.phase=="Partida" then spawnPlayer(p) end end)
   elseif state.phase=="Partida" then
    eliminate(p,"reset")
    p:SetAttribute("Spectating",true)
   else
    e.status="eliminated"
   end
  end
  sync(p)
  h=char:FindFirstChildOfClass("Humanoid")
  if h then h.Died:Connect(function()
   if p.Character~=char then return end
   if p==jasonPlayer then endTime=now() return end
   local x=entry(p)
   if x and (x.status=="alive" or x.status=="downed") then
    if now()<(x.spawnGraceUntil or 0) then
     x.spawnRecovery=true
     warn("Recovered accidental spawn death for "..p.Name)
     return
    end
    eliminate(p,"death")
   end
  end) end
 end
 p.CharacterAdded:Connect(onCharacter)
 if p.Character then task.spawn(onCharacter,p.Character) end
end
Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
Players.PlayerRemoving:Connect(function(p)
 if p==jasonPlayer then jasonPlayer=nil endTime=now() end
 saveAt[p]=nil if musicObjects[p] then musicObjects[p]:Destroy() musicObjects[p]=nil end
 portalInside[p]=nil morphing[p]=nil rigRetries[p]=nil
 state.entries[p.UserId]=nil queued[p]=nil rates[p]=nil motions[p]=nil catching[p]=nil
 saveProfile(p,true) profiles.records[p]=nil
end)
if game.BindToClose then game:BindToClose(function()
 local pending=0
 for _,p in ipairs(Players:GetPlayers()) do pending+=1 task.spawn(function() saveProfile(p,true) pending-=1 end) end
 local deadline=os.clock()+25
 while pending>0 and os.clock()<deadline do task.wait(.1) end
end) end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.2 then return end local step=elapsed elapsed=0 local t=now()
 for _,p in ipairs(Players:GetPlayers()) do
  local e=entry(p) local r=root(p) local h=humanoid(p)
  if t>=(saveAt[p] or math.huge) then saveAt[p]=t+150+math.random(0,30) task.spawn(saveProfile,p) end
  -- Admission is automatic between rounds; AFK never cancels an active death or round.
  if not e then
   local eligible=not p:GetAttribute("AFK") and not p:GetAttribute("InMenu") and not p:GetAttribute("VoidActive") and r and h and h.Health>0
   if eligible and state.phase=="Partida" then
    if Rules.count(state)<Rules.Capacity and not roundClosing then if join(p) then spawnPlayer(p) end end
   elseif eligible and not queued[p] then queued[p]=true sync(p)
   elseif not eligible and queued[p] then queued[p]=nil sync(p) end
  end
  if e then
   if e.status=="alive" or e.status=="downed" then e.survivalTime=(e.survivalTime or 0)+step end
   if e.status=="loading" and t>e.loadDeadline then if p==jasonPlayer then endTime=t end state.entries[p.UserId]=nil sync(p) net.Update:FireClient(p,"notice","Carregamento demorou. Tente entrar novamente.") end
   if e.status=="downed" and t>=e.deadline then eliminate(p,e.cause) end
   if e.channel then
    local c=e.channel local tr=root(c.target) local te=entry(c.target)
    local valid=not p:GetAttribute("BeingExecuted") and not c.target:GetAttribute("BeingExecuted") and r and tr and te and te.status=="downed" and e.status==c.status and (r.Position-c.position).Magnitude<2 and (r.Position-tr.Position).Magnitude<9
    if valid then
     local param=RaycastParams.new() param.FilterType=Enum.RaycastFilterType.Exclude param.FilterDescendantsInstances={p.Character,c.target.Character}
     valid=not workspace:Raycast(r.Position,tr.Position-r.Position,param)
    end
    if not valid then e.channel=nil p:SetAttribute("ReviveAt",0)
    elseif t-c.started>=Rules.ReviveTime then
     if Rules.revive(state,p.UserId,c.target.UserId,t) then
      te.injured=true te.protectedUntil=t+4 sync(c.target) sync(p) if c.target~=p then points(p,10) end
     end e.channel=nil p:SetAttribute("ReviveAt",0)
    end
   end
   if r and h and (e.status=="alive" or e.status=="downed") then
    if r.Position.Y<(arena:GetAttribute("VoidY") or 20) then
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
      if t<introUntil then
       h.WalkSpeed=0 h.JumpPower=0 h.JumpHeight=0
      else
       h.JumpPower=50 h.JumpHeight=7.2
       if p==jasonPlayer then h.WalkSpeed=22
       elseif e.boostUntil and t<e.boostUntil then h.WalkSpeed=e.injured and 20 or 27
       elseif e.injured then h.WalkSpeed=p:GetAttribute("MoveMode")=="run" and 16 or p:GetAttribute("MoveMode")=="slow" and 7 or 12
       else h.WalkSpeed=p:GetAttribute("MoveMode")=="run" and 21 or p:GetAttribute("MoveMode")=="slow" and 8 or 16 end
      end
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
 local participants={} local living=0
 if state.phase=="Partida" then
  for _,p in ipairs(Players:GetPlayers()) do
   local e=entry(p)
   if e then
    if p~=jasonPlayer and (e.status=="alive" or e.status=="downed") then living+=1 end
    if p~=jasonPlayer then table.insert(participants,{name=p.DisplayName or p.Name,userId=p.UserId,time=math.floor(e.survivalTime or 0),hits=e.hits or 0,falls=e.falls or 0,level=1}) end
   end
  end
  table.sort(participants,function(x,y) if x.time~=y.time then return x.time>y.time elseif x.hits~=y.hits then return x.hits<y.hits else return x.falls<y.falls end end)
  local jasonWon=living==0 and (jasonPlayer~=nil or (npc and npc.Parent and npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChildOfClass("Humanoid").Health>0))
  local earned={}
  for _,p in ipairs(Players:GetPlayers()) do
   local e=entry(p)
   if e then
    local reward=math.max(10,math.floor((e.survivalTime or 0)/4))+(jasonWon and p==jasonPlayer and 30 or 0)
    earned[p]=reward profiles:awardXP(p,reward)
    for _,row in ipairs(participants) do if row.userId==p.UserId then row.level=Profiles.level(p:FindFirstChild("leaderstats") and p:FindFirstChild("leaderstats").XP.Value or 0) end end
    task.spawn(saveProfile,p)
   end
  end
  local killerWasPlayer=jasonPlayer~=nil
  local killerWinnerName=killerWasPlayer and (jasonPlayer.DisplayName or jasonPlayer.Name) or killerName
  for _,p in ipairs(Players:GetPlayers()) do
   net.Update:FireClient(p,"roundResult",{jasonWon=jasonWon,killer=killerName,killerPlayer=killerWasPlayer,killerWinnerName=killerWinnerName,winnerText=jasonWon and (killerWinnerName.." venceu a partida") or "Sobreviventes venceram a partida",lastVictimUserId=lastKilledUserId,lastVictimName=lastKilledName,board=participants,xp=earned[p] or 0,map=arena and arena:GetAttribute("DisplayName") or ""})
  end
 end
 state.phase="Intervalo" roundClosing=false introUntil=0 net:SetAttribute("IntroUntil",0) if brain then brain.stop() brain=nil end
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

  local function hasQueued()
   for p in pairs(queued) do if not p:GetAttribute("AFK") and p.Parent and root(p) and humanoid(p) and humanoid(p).Health>0 and not p:GetAttribute("VoidActive") then return true end end
   return false
  end
  while #Players:GetPlayers()>0 and not hasQueued() do
   net:SetAttribute("Phase","Intervalo") net:SetAttribute("EndsAt",0) net:SetAttribute("Waiting",0) task.wait(.5)
  end
  if #Players:GetPlayers()>0 then
   local ok,err=xpcall(function()
    Rules.begin(state) roundClosing=false lastKilledUserId=0 lastKilledName=nil
    local mapList=assets.Maps:GetChildren() local rigList=assets.Killers:GetChildren()
    table.sort(mapList,function(a,b) return a.Name<b.Name end)
    local choices={} for _,candidate in ipairs(mapList) do if candidate.Name~=previousMap or #mapList==1 then table.insert(choices,candidate) end end
    local selected=choices[math.random(#choices)] previousMap=selected.Name
    arena=selected:Clone() arena.Name="ActiveArena" arena.Parent=workspace arena:SetAttribute("RoundId",state.id)
    local chosen=rigList[math.random(#rigList)]
    killerName=chosen.Name
    npc=KillerFactory.create(killerName,config.Killers[killerName])
    npc.Parent=workspace
    local killerSpawn=arena:GetAttribute("KillerSpawn")
    local authoredRotation=npc:GetPivot().Rotation
    npc:PivotTo(CFrame.new(killerSpawn+Vector3.new(0,20,0))*authoredRotation)
    local boxCF,boxSize=npc:GetBoundingBox()
    local bottom=boxCF.Position.Y-boxSize.Y/2
    npc:PivotTo(npc:GetPivot()+Vector3.new(0,killerSpawn.Y+.08-bottom,0))
    npc:SetAttribute("GroundOffset",npc.PrimaryPart.Position.Y-killerSpawn.Y)
    for _,d in ipairs(npc:GetDescendants()) do if d:IsA("BasePart") then d.Anchored=false pcall(function() d:SetNetworkOwner(nil) end) end end
    npc:SetAttribute("ActivePursuer",true)
    local introStarted=now()
    introUntil=introStarted+4
    npc:SetAttribute("RoundIntroAt",introStarted)
    npc:SetAttribute("RoundIntroUntil",introUntil)
    npc:SetAttribute("AttackUntil",introUntil)
    net:SetAttribute("IntroUntil",introUntil)
    npc:FindFirstChildOfClass("Humanoid").Died:Connect(function() endTime=now() end)
    local eligible={}
    for _,p in ipairs(Players:GetPlayers()) do if queued[p] and not p:GetAttribute("AFK") and root(p) and humanoid(p) and humanoid(p).Health>0 and not p:GetAttribute("VoidActive") then table.insert(eligible,p) end end
    table.sort(eligible,function(a,b) return a.UserId<b.UserId end)
    if #eligible>=8 and math.random()<config.PlayerJasonChance then
     jasonPlayer=eligible[math.random(1,8)]
     clearFlashlight(jasonPlayer)
     local old=jasonPlayer.Character morphing[jasonPlayer]=true
     npc.Name=jasonPlayer.Name jasonPlayer.Character=npc
     morphing[jasonPlayer]=nil if old then old:Destroy() end
     for _,d in ipairs(npc:GetDescendants()) do if d:IsA("BasePart") then pcall(function() d:SetNetworkOwner(jasonPlayer) end) end end
     net.Update:FireClient(jasonPlayer,"notice","Você é Jason. Persiga os sobreviventes e use o botão de ataque.")
    else
     brain=AI.start(npc,arena,config.Killers[killerName],{players=players,vulnerable=targetable,catch=catchPlayer})
    end
    endTime=introUntil+Rules.Duration
    net:SetAttribute("Phase","Partida")
    net:SetAttribute("EndsAt",endTime)
    net:SetAttribute("Killer",killerName)
    net:SetAttribute("Map",arena:GetAttribute("DisplayName") or "Mapa")
    net:SetAttribute("MaxPlayers",Rules.Capacity)

    local admitted=0
    if jasonPlayer then
     if join(jasonPlayer) then spawnPlayer(jasonPlayer) admitted=1 end
    end
    for _,p in ipairs(Players:GetPlayers()) do
     if admitted>=Rules.Capacity then break end
     if queued[p] and not p:GetAttribute("AFK") and p.Parent and root(p) and humanoid(p) and humanoid(p).Health>0 and not p:GetAttribute("VoidActive") then
      if join(p) then spawnPlayer(p) admitted+=1 end
     end
    end

    local introData=introSceneData()
    if introData then
     for _,p in ipairs(Players:GetPlayers()) do
      local e=entry(p)
      if e and e.status=="alive" then net.Update:FireClient(p,"jasonIntro",introData,npc) end
     end
    end

    while now()<endTime do
     net:SetAttribute("Count",Rules.count(state))
     local survivors=0 local entered=0
     for id,e in pairs(state.entries) do
      if not jasonPlayer or id~=jasonPlayer.UserId then
       entered+=1 if e.status=="alive" or e.status=="downed" or e.status=="loading" then survivors+=1 end
      end
     end
     if entered>0 and survivors==0 and not roundClosing then
      roundClosing=true endTime=math.min(endTime,now()+2.5) net:SetAttribute("EndsAt",endTime)
     end
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


