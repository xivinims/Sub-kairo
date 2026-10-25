local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local SSS=game:GetService("ServerScriptService")
local RunService=game:GetService("RunService")
local profileStore=nil
pcall(function() profileStore=game:GetService("DataStoreService"):GetDataStore("SuviversProfiles_v1") end)
local Profiles=require(SSS:WaitForChild("ProfileService"))
local profiles=Profiles.new(profileStore)
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
local arena,npc,brain=nil,nil,nil local killerName="Jason" local endTime=0 local roundJoinUntil=0
local jasonPlayer=nil local morphing={} local rigRetries={} local hookedCharacters=setmetatable({},{__mode="k"}) local expectedCharacters={} local lastAttack=0
local roundClosing=false local previousMap=nil local saveAt={}
local lastKilledUserId=0 local lastKilledName=nil
local lastVictimReplay=nil local lastExecutionCF=nil
local objectiveFolder=nil
local carryWelds=setmetatable({},{__mode="k"})
local objectiveConnections={}
local escapedThisRound=0
local adminResetRequested=false local lastAdminReset=-math.huge
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
 p:SetAttribute("RoundStatus",e and e.status or "lobby")
 p:SetAttribute("Queued",queued[p] or false)
 p:SetAttribute("HasKey",e and e.hasKey==true or false)
 p:SetAttribute("Stamina",e and math.floor((e.stamina or 0)*10+.5)/10 or 0)
 p:SetAttribute("MaxStamina",p==jasonPlayer and Rules.KillerStamina or Rules.SurvivorStamina)
 p:SetAttribute("CarryingUserId",e and e.carryingUserId or 0)
 p:SetAttribute("CarriedBy",e and e.carriedBy or 0)
 local h=humanoid(p)
 if h then
  h.PlatformStand=false h.AutoRotate=not (e and e.status=="downed")
  local pursuerSpec=config.Killers[killerName]
  local mode=p:GetAttribute("MoveMode") or "walk"
  local stamina=e and (e.stamina or 0) or 0
  local carrying=e and (e.carryingUserId or 0)>0
  if p==jasonPlayer then
   local chase=(pursuerSpec and pursuerSpec.speed or 20)
   h.WalkSpeed=(mode=="run" and stamina>0) and chase+2.2 or math.max(15,chase-1.8)
  elseif e and e.status=="downed" then
   h.WalkSpeed=0
  elseif e and e.injured then
   h.WalkSpeed=mode=="crouch" and 7 or 11.5
  elseif mode=="crouch" then
   h.WalkSpeed=Rules.SurvivorCrouch
  elseif mode=="run" and stamina>0 then
   h.WalkSpeed=carrying and 13 or Rules.SurvivorRun
  else
   h.WalkSpeed=carrying and 10.5 or Rules.SurvivorWalk
  end
  h.JumpPower=(e and e.status=="downed") and 0 or (mode=="crouch" and 0 or 50)
  h.JumpHeight=(e and e.status=="downed") and 0 or (mode=="crouch" and 0 or 7.2)
 end
end
local function points(p,n)
 profiles:points(p,n)
end
local function reward(p,pointAmount,xpAmount)
 if not p or not p.Parent then return end
 local e=entry(p)
 if pointAmount and pointAmount~=0 then points(p,pointAmount) end
 if e then
  e.roundXP=(e.roundXP or 0)+(xpAmount or 0)
  e.actionPoints=(e.actionPoints or 0)+(pointAmount or 0)
 end
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
 local source=items.Flashlight:Clone()
 local grip=source:IsA("Tool") and source.Grip or CFrame.identity
 local visual=Instance.new("Model") visual.Name="EquippedFlashlight"
 for _,child in ipairs(source:GetChildren()) do
  if child:IsA("LuaSourceContainer") then child:Destroy() else child.Parent=visual end
 end
 source:Destroy()
 local handle=visual:FindFirstChild("Handle",true)
 if not handle or not handle:IsA("BasePart") then visual:Destroy() return false end
 for _,part in ipairs(visual:GetDescendants()) do
  if part:IsA("BasePart") then part.Anchored=false part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Massless=true end
 end
 visual.PrimaryPart=handle visual.Parent=char
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
 e.injured=true e.channel=nil p:SetAttribute("MoveMode","walk") p:SetAttribute("HitAt",now())
 local h=humanoid(p) if h then h.Health=math.max(1,h.MaxHealth*.55) end
 sync(p)
 net.Update:FireClient(p,"hitFlash",.45)
 net.Update:FireClient(p,"notice","Você está ferido. Seus movimentos ficaram mais lentos.")
 return true
end
local function down(p)
 if not vulnerable(p) or not Rules.down(state,p.UserId,now()) then return end
 clearFlashlight(p)
 local e=entry(p) e.downedAt=now() e.hits=(e.hits or 0)+1 local hitStats=p:FindFirstChild("leaderstats") if hitStats and hitStats:FindFirstChild("Atingido") then hitStats.Atingido.Value+=1 end e.falls=(e.falls or 0)+1 local stats=p:FindFirstChild("leaderstats") local falls=stats and stats:FindFirstChild("Quedas") if falls then falls.Value+=1 end e.injured=true e.channel=nil e.cause=killerName
 local h=humanoid(p) if h then h.Health=math.max(1,h.MaxHealth*.14) end
 sync(p)
 net.Update:FireClient(p,"hitFlash",.72)
 net.Update:FireClient(p,"notice","Você caiu. Outro sobrevivente pode reanimar ou carregar você.")
end
local function executeDowned(p,attacker)
 local e=entry(p)
 if not e or e.status~="downed" or catching[p] or not attacker or not attacker.PrimaryPart or (attacker:GetAttribute("ExecutionTargetUserId") or 0)>0 then return false end
 local rr=root(p)
 if not rr or (rr.Position-attacker.PrimaryPart.Position).Magnitude>7 then return false end
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={attacker}
 local obstruction=workspace:Raycast(attacker.PrimaryPart.Position,rr.Position-attacker.PrimaryPart.Position,params)
 if obstruction and not obstruction.Instance:IsDescendantOf(p.Character) then return false end
 local capturedEntry=e local capturedCharacter=p.Character local capturedRound=state.id
 e.channel=nil p:SetAttribute("ReviveAt",0)
 if lastVictimReplay then lastVictimReplay:Destroy() end
 local archivable=capturedCharacter.Archivable capturedCharacter.Archivable=true
 lastVictimReplay=capturedCharacter:Clone() capturedCharacter.Archivable=archivable
 lastExecutionCF=attacker:GetPivot()
 for _,obj in ipairs(lastVictimReplay:GetDescendants()) do if obj:IsA("LuaSourceContainer") or obj:IsA("Tool") or obj:IsA("BillboardGui") then obj:Destroy() end end sync(p)
 catching[p]=true
 local t=now()
 local executionDuration=attacker:GetAttribute("ExecutionLength") or 2.5
 local attackerRoot=attacker.PrimaryPart
 local attackerWasAnchored=attackerRoot.Anchored
 local victimWasAnchored=rr.Anchored
 attacker:SetAttribute("ExecutionAt",t)
 attacker:SetAttribute("ExecutionDuration",executionDuration)
 attacker:SetAttribute("ExecutionTargetUserId",p.UserId)
 attacker:SetAttribute("AttackUntil",t+executionDuration)
 p:SetAttribute("ExecutionKiller",killerName)
 p:SetAttribute("BeingExecuted",true)
 p:SetAttribute("ExecutionAt",t)
 p:SetAttribute("ExecutionDuration",executionDuration)
 local facing=attackerRoot.CFrame
 local rawTarget=(facing*CFrame.new(.45,0,-3.05)).Position
 local targetPos=Vector3.new(rawTarget.X,rr.Position.Y,rawTarget.Z)
 local faceDirection=Vector3.new(facing.LookVector.X,0,facing.LookVector.Z)
 if faceDirection.Magnitude<.1 then faceDirection=Vector3.new(0,0,-1) else faceDirection=faceDirection.Unit end
 p.Character:PivotTo(CFrame.lookAt(targetPos,targetPos+faceDirection))
 attackerRoot.Anchored=true
 rr.Anchored=true
 attackerRoot.AssemblyLinearVelocity=Vector3.zero attackerRoot.AssemblyAngularVelocity=Vector3.zero
 rr.AssemblyLinearVelocity=Vector3.zero rr.AssemblyAngularVelocity=Vector3.zero
 net.Update:FireClient(p,"executed",killerName,attackerRoot.CFrame,executionDuration)
 task.delay(executionDuration,function()
  catching[p]=nil
  if rr and rr.Parent then rr.Anchored=victimWasAnchored end
  if attackerRoot and attackerRoot.Parent then attackerRoot.Anchored=attackerWasAnchored end
  if p.Parent then
   p:SetAttribute("BeingExecuted",false)
   p:SetAttribute("ExecutionAt",0)
   p:SetAttribute("ExecutionDuration",0)
  end
  if attacker and attacker.Parent then
   attacker:SetAttribute("ExecutionTargetUserId",0)
   attacker:SetAttribute("ExecutionDuration",0)
  end
  local current=entry(p)
  if state.id==capturedRound and current==capturedEntry and p.Character==capturedCharacter and current.status=="downed" then
    reward(jasonPlayer,60,32)
    eliminate(p,killerName)
   end
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
  local hitSound=Instance.new("Sound",rr) hitSound.SoundId="rbxassetid://135029802046345" hitSound.Volume=.6 hitSound.RollOffMaxDistance=40 hitSound:Play() game:GetService("Debris"):AddItem(hitSound,5)
  local current=entry(p)
  if current and current.injured then
   down(p)
   reward(jasonPlayer,25,14)
  elseif injure(p) then
   reward(jasonPlayer,15,8)
  end
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

local function recoverFromFall(p)
 if not arena or not p.Character then return false end
 local r=root(p) if not r then return false end
 local target=nil
 if p==jasonPlayer then
  target=arena:GetAttribute("KillerSpawn")
 else
  local safe=arena:FindFirstChild("SafePoints")
  local best=math.huge
  if safe then
   for _,point in ipairs(safe:GetChildren()) do
    if point:IsA("Vector3Value") then
     local d=(Vector2.new(point.Value.X,point.Value.Z)-Vector2.new(r.Position.X,r.Position.Z)).Magnitude
     if d<best then best=d target=point.Value end
    end
   end
  end
  target=target or arena:GetAttribute("EntranceSpawn")
 end
 if typeof(target)~="Vector3" then return false end
 local face=arena:GetAttribute("SpawnFacing")
 if typeof(face)~="Vector3" then face=Vector3.new(0,0,-1) end
 local cf=safeRoundSpawnCF(p.Character,target,face)
 if not cf then return false end
 r.Anchored=true p.Character:PivotTo(cf) r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
 task.delay(.18,function() if r.Parent then r.Anchored=false end end)
 local e=entry(p) if e then e.protectedUntil=math.max(e.protectedUntil or 0,now()+3) sync(p) end
 return true
end

local function spawnPlayer(p)
 local e=entry(p) local r=root(p)
 if not e or not r or not p.Character or not npc or not arena then return false end
 local face=arena:GetAttribute("SpawnFacing")
 if typeof(face)~="Vector3" then face=Vector3.new(0,0,-1) end
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
 e.channel=nil e.deadline=nil e.downedAt=nil
 e.lastScore=now() e.lastNoise=0 e.lastStepSound=0 e.lastStaminaSync=0
 e.hasKey=false e.carryingUserId=0 e.carriedBy=0
 e.stamina=p==jasonPlayer and Rules.KillerStamina or Rules.SurvivorStamina
 clearFlashlight(p)
 p:SetAttribute("BeingExecuted",false) p:SetAttribute("ReviveAt",0)
 p:SetAttribute("MoveMode","walk") p:SetAttribute("Spectating",false) p:SetAttribute("InMenu",false)

 local h=humanoid(p)
 if h then h.Health=h.MaxHealth h.PlatformStand=false h.AutoRotate=true end
 local oldShield=p.Character:FindFirstChild("RoundSpawnProtection")
 if oldShield then oldShield:Destroy() end
 local shield=Instance.new("ForceField") shield.Name="RoundSpawnProtection" shield.Visible=false shield.Parent=p.Character

 r.Anchored=true
 p.Character:PivotTo(chosenCF)
 r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
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
local function channelRevive(p)
 local h=entry(p) local r=root(p)
 if not h or h.status~="alive" or h.channel or not r or p:GetAttribute("BeingExecuted") then return end
 local target=nil local nearest=8.5
 for _,other in ipairs(Players:GetPlayers()) do
  if other~=p then
   local t=entry(other) local rr=root(other)
   if t and t.status=="downed" and rr and not other:GetAttribute("BeingExecuted") then
    local distance=(rr.Position-r.Position).Magnitude
    if distance<nearest then nearest=distance target=other end
   end
  end
 end
 if not target then return end
 h.channel={target=target,started=now(),position=r.Position,status=h.status}
 p:SetAttribute("ReviveAt",now()+Rules.ReviveTime)
end

local function disconnectObjectives()
 for _,c in ipairs(objectiveConnections) do pcall(function() c:Disconnect() end) end
 table.clear(objectiveConnections)
 if objectiveFolder then objectiveFolder:Destroy() objectiveFolder=nil end
 net:SetAttribute("MissionStage","Waiting")
 net:SetAttribute("ComputersDone",0)
 net:SetAttribute("ComputersRequired",Rules.ComputersRequired)
end

local function dropCarry(carrier)
 local e=carrier and entry(carrier)
 if not e then return end
 local targetId=e.carryingUserId or 0
 local weld=carryWelds[carrier]
 if weld then weld:Destroy() carryWelds[carrier]=nil end
 e.carryingUserId=0
 local target=targetId>0 and Players:GetPlayerByUserId(targetId) or nil
 if target then
  local te=entry(target)
  if te then te.carriedBy=0 end
  local rr=root(target)
  if rr then rr.Massless=false rr.CanCollide=false end
  local th=humanoid(target) if th then th.AutoRotate=false end
  sync(target)
 end
 sync(carrier)
end

local function toggleCarry(carrier)
 local e=entry(carrier) local cr=root(carrier)
 if not e or e.status~="alive" or carrier==jasonPlayer or not cr then return end
 if (e.carryingUserId or 0)>0 then dropCarry(carrier) return end
 local target=nil local distance=7
 for _,other in ipairs(Players:GetPlayers()) do
  local te=entry(other) local rr=root(other)
  if other~=carrier and te and te.status=="downed" and (te.carriedBy or 0)==0 and rr and not other:GetAttribute("BeingExecuted") then
   local d=(rr.Position-cr.Position).Magnitude
   if d<distance then target=other distance=d end
  end
 end
 if not target then return end
 local te=entry(target) local rr=root(target)
 local shoulder=carrier.Character and (carrier.Character:FindFirstChild("Torso") or carrier.Character:FindFirstChild("UpperTorso"))
 if not te or not rr or not shoulder then return end
 rr.CFrame=shoulder.CFrame*CFrame.new(1.15,.35,.35)*CFrame.Angles(0,0,math.rad(82))
 rr.AssemblyLinearVelocity=Vector3.zero rr.AssemblyAngularVelocity=Vector3.zero
 rr.Massless=true rr.CanCollide=false
 local weld=Instance.new("WeldConstraint") weld.Name="CarryWeld" weld.Part0=shoulder weld.Part1=rr weld.Parent=shoulder
 carryWelds[carrier]=weld e.carryingUserId=target.UserId te.carriedBy=carrier.UserId
 sync(carrier) sync(target)
 net.Update:FireClient(carrier,"notice","Você está carregando "..(target.DisplayName or target.Name)..". Sua velocidade foi reduzida.")
end

local function objectivePositions()
 local folder=arena and arena:FindFirstChild("ObjectiveSites")
 assert(folder,"Map objective sites must be verified during publishing")
 local values=folder:GetChildren() table.sort(values,function(a,b) return tonumber(a.Name)<tonumber(b.Name) end)
 local list={} for _,v in ipairs(values) do table.insert(list,v.Value) end return list
end

local function alignObjective(model,pos)
 model.Parent=objectiveFolder
 model:PivotTo(CFrame.new(pos))
 local cf,size=model:GetBoundingBox()
 model:PivotTo(model:GetPivot()+Vector3.new(pos.X-cf.Position.X,pos.Y+size.Y/2-cf.Position.Y,pos.Z-cf.Position.Z))
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA("BasePart") then d.Anchored=true d.CanTouch=false end
 end
 return model
end

local function promptAt(name,pos,action,objectText,hold)
 local anchor=Instance.new("Part")
 anchor.Name=name.."PromptAnchor" anchor.Size=Vector3.new(.6,.6,.6) anchor.Transparency=1
 anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false
 anchor.Position=pos+Vector3.new(0,2.3,0) anchor.Parent=objectiveFolder
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name=name.."Prompt" prompt.ActionText=action prompt.ObjectText=objectText
 prompt.HoldDuration=hold or 0 prompt.MaxActivationDistance=9 prompt.RequiresLineOfSight=false prompt.Parent=anchor
 return prompt,anchor
end

local function setMission(stage)
 net:SetAttribute("MissionStage",stage)
 net.Update:FireAllClients("mission",stage,net:GetAttribute("ComputersDone") or 0,net:GetAttribute("ComputersRequired") or Rules.ComputersRequired)
end

local function activeSurvivors()
 local n=0
 for id,e in pairs(state.entries) do
  if not jasonPlayer or id~=jasonPlayer.UserId then
   if e.status=="alive" or e.status=="downed" or e.status=="loading" then n+=1 end
  end
 end
 return n
end

local function escapePlayer(p)
 local e=entry(p)
 if not e or e.status~="alive" or p==jasonPlayer or not net:GetAttribute("ExitUnlocked") then return end
 if (net:GetAttribute("ComputersDone") or 0)<(net:GetAttribute("ComputersRequired") or Rules.ComputersRequired) then return end
 dropCarry(p)
 e.hasKey=false e.status="escaped" e.escapes=(e.escapes or 0)+1 escapedThisRound+=1
 reward(p,100,80)
 p:SetAttribute("HasKey",false)
 sync(p)
 net.Update:FireAllClients("escape",p.DisplayName or p.Name)
 net.Update:FireClient(p,"achievement","FIRST ESCAPE","Você concluiu uma partida e escapou.")
 local badgeId=tonumber(config.FirstWinBadgeId) or 0
 if badgeId>0 then task.spawn(function() pcall(function() game:GetService("BadgeService"):AwardBadgeAsync(p.UserId,badgeId) end) end) end
 lobby(p)
 task.spawn(saveProfile,p)
 if activeSurvivors()==0 then endTime=math.min(endTime,now()+1) end
end

local hackSessions={} local computers={} local hackedCount=0 local exitDoor=nil
local function canInteract(p,pos,range)
 local e=entry(p) local rr=root(p)
 if state.phase~="Partida" or not e or e.status~="alive" or p==jasonPlayer or not rr or p:GetAttribute("BeingExecuted") or (e.carriedBy or 0)>0 then return false end
 -- Objective prompts intentionally ignore line of sight so indoor meshes/door frames
 -- cannot block a legitimate nearby interaction. Security remains server-owned through
 -- round state, survivor state and strict distance checks.
 return (rr.Position-pos).Magnitude<=(range or 10)
end
local function spatialSound(parent,id,volume)
 local sound=Instance.new("Sound") sound.SoundId="rbxassetid://"..id sound.Volume=volume or .6
 sound.RollOffMinDistance=5 sound.RollOffMaxDistance=65 sound.Parent=parent sound:Play()
 game:GetService("Debris"):AddItem(sound,12)
end
local function cancelHack(p)
 local s=hackSessions[p]
 if s and s.pc and s.pc.Parent then s.pc:SetAttribute("HackerUserId",nil) end
 hackSessions[p]=nil
 if p.Parent then p:SetAttribute("Hacking",false) net.Update:FireClient(p,"hackEnd") end
end
local function startHack(p,pc,pos)
 if not canInteract(p,pos,10) or pc:GetAttribute("Hacked") or pc:GetAttribute("HackerUserId") then return end
 cancelHack(p)
 local progress=pc:GetAttribute("HackProgress") or 0
 local s={pc=pc,pos=pos,progress=progress,nextCheck=math.floor(progress*30/6+1)*6,round=state.id}
 hackSessions[p]=s pc:SetAttribute("HackerUserId",p.UserId)
 p:SetAttribute("Hacking",true) p:SetAttribute("MoveMode","walk")
 net.Update:FireClient(p,"hackStart",pc,progress)
end
local function hackTap(p,id)
 local s=hackSessions[p]
 if not s or type(id)~="number" or id~=s.challenge or not s.checkAt or not canInteract(p,s.pos,10) then return end
 local fraction=(now()-s.checkAt)/1.6
 if fraction<0 then return end
 s.checkAt=nil
 local success=fraction>=.32 and fraction<=.78
 if not success then s.progress=math.max(0,s.progress-.08) spatialSound(s.pc.PrimaryPart or s.pc:FindFirstChildWhichIsA("BasePart",true),135029802046345,.35) end
 s.pc:SetAttribute("HackProgress",s.progress)
 net.Update:FireClient(p,"hackCheckResult",success)
end
local function giveKey(p,key,prompt,pos)
 if not key.Parent or not canInteract(p,pos,10) then return end
 local e=entry(p) if e.hasKey then return end
 e.hasKey=true e.keys=(e.keys or 0)+1 reward(p,20,16)
 p:SetAttribute("HasKey",true) key:Destroy() prompt.Enabled=false
 sync(p) net.Update:FireClient(p,"mission","Exit")
end
local function spawnKeysAndExit(positions)
 setMission("Key")
 for i=1,4 do
  local pos=positions[Rules.ComputersRequired+i]
  local key=alignObjective(items.KeyTemplate:Clone(),pos)
  key.Name="ObjectiveKey_"..i key:SetAttribute("ObjectiveType","Key")
  local prompt=promptAt("Key"..i,pos,"PEGAR","Chave da saída",.15)
  local chest=objectiveFolder:FindFirstChild("KeyChest_"..i)
  if chest and not chest:GetAttribute("Opened") then
   key.Parent=chest
   for _,part in ipairs(key:GetDescendants()) do if part:IsA("BasePart") then part:SetAttribute("VisibleTransparency",part.Transparency) part.Transparency=1 part.CanCollide=false end end
   prompt.Enabled=false
   table.insert(objectiveConnections,chest:GetAttributeChangedSignal("Opened"):Connect(function()
    if chest:GetAttribute("Opened") then
     for _,part in ipairs(key:GetDescendants()) do if part:IsA("BasePart") then part.Transparency=part:GetAttribute("VisibleTransparency") or 0 end end
     prompt.Enabled=true
    end
   end))
  end
  table.insert(objectiveConnections,prompt.Triggered:Connect(function(p) if prompt.Enabled then giveKey(p,key,prompt,pos) end end))
 end
end
local function updateHacks(step)
 for p,s in pairs(hackSessions) do
  local e=entry(p)
  if not p.Parent or state.id~=s.round or not s.pc.Parent or not canInteract(p,s.pos,10) or not e or e.injured and p:GetAttribute("BeingExecuted") then cancelHack(p)
  elseif s.checkAt then
   if now()>s.checkAt+1.6 then hackTap(p,s.challenge) end
  else
   s.progress=math.min(1,s.progress+step/30)
   s.pc:SetAttribute("HackProgress",s.progress)
   net.Update:FireClient(p,"hackProgress",s.progress)
   if s.progress>=1 then
    local pc=s.pc pc:SetAttribute("Hacked",true) hackedCount+=1
    for _,part in ipairs(pc:GetDescendants()) do if part:IsA("BasePart") and (part.Name:lower():find("screen") or part.Name:lower():find("monitor") or part:GetAttribute("HackScreen")) then part.Color=Color3.fromRGB(65,210,116) part.Material=Enum.Material.Neon end end
    local screen=pc:FindFirstChild("HackStatusScreen") if screen then screen.Color=Color3.fromRGB(65,210,116) end
    local prompt=objectiveFolder:FindFirstChild(pc.Name.."PromptAnchor")
    if prompt then local pp=prompt:FindFirstChildOfClass("ProximityPrompt") if pp then pp.Enabled=false end end
    spatialSound(pc.PrimaryPart or pc:FindFirstChildWhichIsA("BasePart",true),987728667,.65)
    e.hacks=(e.hacks or 0)+1 reward(p,40,28) cancelHack(p)
    net:SetAttribute("ComputersDone",hackedCount)
    if jasonPlayer and jasonPlayer.Parent then net.Update:FireClient(jasonPlayer,"pcComplete",pc,10) end
    net.Update:FireAllClients("objectiveDone","Computer",p.DisplayName or p.Name,hackedCount,Rules.ComputersRequired)
    if hackedCount>=Rules.ComputersRequired then spawnKeysAndExit(objectivePositions()) else setMission("Hack") end
   elseif s.progress*30>=s.nextCheck then
    s.nextCheck+=6 s.challenge=(s.challenge or 0)+1 s.checkAt=now()+.35
    net.Update:FireClient(p,"hackCheck",s.challenge,s.checkAt)
   end
  end
 end
end
local function setupObjectives()
 for p in pairs(hackSessions) do cancelHack(p) end
 disconnectObjectives() table.clear(computers) hackedCount=0 escapedThisRound=0
 objectiveFolder=Instance.new("Folder") objectiveFolder.Name="RoundObjectives" objectiveFolder.Parent=arena
 local positions=objectivePositions()
 assert(#positions>=Rules.ComputersRequired+6,"Arena needs separate verified sites for PCs, keys, chests and exit")
 net:SetAttribute("ComputersRequired",Rules.ComputersRequired) net:SetAttribute("ComputersDone",0) net:SetAttribute("ExitUnlocked",false)
 for i=1,Rules.ComputersRequired do
  local pos=positions[i]
  local pc=alignObjective(items.ComputerTemplate:Clone(),pos)
  pc.Name="HackComputer_"..i pc:SetAttribute("ObjectiveType","Computer") pc:SetAttribute("Hacked",false) pc:SetAttribute("HackProgress",0)
  pc.PrimaryPart=pc.PrimaryPart or pc:FindFirstChildWhichIsA("BasePart",true)
  local cf,size=pc:GetBoundingBox()
  local display=Instance.new("Part") display.Name="HackStatusScreen" display.Size=Vector3.new(1.8,1.05,.08)
  display.CFrame=CFrame.new(cf.Position+Vector3.new(0,math.min(size.Y*.15,.5),-size.Z*.5-.05))
  display.Anchored=true display.CanCollide=false display.CanTouch=false display.CanQuery=false display.Material=Enum.Material.Neon display.Color=Color3.fromRGB(50,101,170) display.Parent=pc
  local prompt=promptAt(pc.Name,pos,"HACKEAR","Computador",.2)
  table.insert(objectiveConnections,prompt.Triggered:Connect(function(p) startHack(p,pc,pos) end))
  table.insert(computers,pc)
 end
 -- Two guaranteed key chests and one noisy empty chest, shuffled between verified sites.
 local chestIndices={Rules.ComputersRequired+3,Rules.ComputersRequired+4,Rules.ComputersRequired+5}
 for order,index in ipairs(chestIndices) do
  local pos=positions[index] local chest=Instance.new("Model") chest.Name=order<=2 and ("KeyChest_"..(order+2)) or "NoiseChest" chest:SetAttribute("Opened",false) chest.Parent=objectiveFolder
  local box=Instance.new("Part") box.Name="Chest" box.Size=Vector3.new(3,1.5,2) box.Position=pos+Vector3.new(0,.75,0) box.Color=Color3.fromRGB(65,42,24) box.Material=Enum.Material.Wood box.Anchored=true box.Parent=chest chest.PrimaryPart=box
  local lid=Instance.new("Part") lid.Name="Lid" lid.Size=Vector3.new(3.2,.22,2.2) lid.Position=pos+Vector3.new(0,1.6,0) lid.Color=Color3.fromRGB(35,29,25) lid.Material=Enum.Material.Metal lid.Anchored=true lid.Parent=chest
  local prompt=promptAt(chest.Name,pos,"ABRIR","Baú",.5)
  table.insert(objectiveConnections,prompt.Triggered:Connect(function(p)
   if chest:GetAttribute("Opened") or not canInteract(p,pos,10) then return end
   chest:SetAttribute("Opened",true) prompt.Enabled=false
   game:GetService("TweenService"):Create(lid,TweenInfo.new(.45),{CFrame=lid.CFrame*CFrame.new(0,.65,.85)*CFrame.Angles(math.rad(95),0,0)}):Play()
   if order==3 then spatialSound(box,135029802046345,.85) net.Update:FireClient(p,"notice","A batida do baú pode ter sido ouvida por perto.") end
  end))
 end
 local exitPos=positions[#positions]
 local exitModel=Instance.new("Model") exitModel.Name="EscapeExit" exitModel:SetAttribute("ObjectiveType","Exit") exitModel.Parent=objectiveFolder
 local door=Instance.new("Part") door.Name="Door" door.Size=Vector3.new(5,8,.5) door.CFrame=CFrame.new(exitPos+Vector3.new(0,4,0)) door.Color=Color3.fromRGB(28,29,32) door.Material=Enum.Material.Metal door.Anchored=true door.Parent=exitModel exitModel.PrimaryPart=door exitDoor=door
 for _,x in ipairs({-2.8,2.8}) do local frame=door:Clone() frame.Name="Frame" frame.Size=Vector3.new(.6,8.6,1) frame.Position=exitPos+Vector3.new(x,4.3,0) frame.Parent=exitModel end
 local prompt=Instance.new("ProximityPrompt") prompt.Name="ExitPrompt" prompt.ActionText="DESTRANCAR / SAIR" prompt.ObjectText="Saída" prompt.MaxActivationDistance=9 prompt.RequiresLineOfSight=true prompt.Parent=door
 table.insert(objectiveConnections,prompt.Triggered:Connect(function(p)
  if not canInteract(p,exitPos,10) then return end
  local e=entry(p)
  if not net:GetAttribute("ExitUnlocked") then
   if not e.hasKey or hackedCount<Rules.ComputersRequired then net.Update:FireClient(p,"notice","Conclua os computadores e encontre uma chave.") return end
   e.hasKey=false p:SetAttribute("HasKey",false) net:SetAttribute("ExitUnlocked",true) setMission("Exit")
   door.CanCollide=false game:GetService("TweenService"):Create(door,TweenInfo.new(.7),{CFrame=door.CFrame*CFrame.new(-2.5,0,0)*CFrame.Angles(0,math.rad(95),0)*CFrame.new(2.5,0,0)}):Play()
  end
  escapePlayer(p)
 end))
 setMission("Hack")
end

local mapVotes=setmetatable({},{__mode="k"}) local voteOptions={} local selectionPlayer=nil local selectedKiller=nil
local function chooseVoteOptions()
 local pool=assets.Maps:GetChildren()
 table.sort(pool,function(a,b) return a.Name<b.Name end)
 local shuffled=table.clone(pool)
 for i=#shuffled,2,-1 do
  local j=math.random(i)
  shuffled[i],shuffled[j]=shuffled[j],shuffled[i]
 end
 table.clear(voteOptions)
 for i=1,math.min(4,#shuffled) do table.insert(voteOptions,shuffled[i].Name) end
 net:SetAttribute("MapVoteOptions",game:GetService("HttpService"):JSONEncode(voteOptions))
end
local function voteCounts()
 local counts={RANDOM=0}
 for _,name in ipairs(voteOptions) do counts[name]=0 end
 for p,name in pairs(mapVotes) do if p.Parent and not p:GetAttribute("AFK") and counts[name]~=nil then counts[name]+=1 end end
 net:SetAttribute("MapVotes",game:GetService("HttpService"):JSONEncode(counts))
 return counts
end
net.Action.OnServerEvent:Connect(function(p,action,value)
 if type(action)~="string" or #action>24 then return end
 rates[p]=rates[p] or {} local t=now()
 if action~="mode" and t-(rates[p][action] or -math.huge)<.18 then return end
 rates[p][action]=t
 if action=="adminReset" then
  if p.UserId~=8344738123 or t-lastAdminReset<10 then return end
  lastAdminReset=t adminResetRequested=true endTime=t
  net.Update:FireAllClients("notice","Rodada reiniciada pelo administrador.")
  return
 elseif action=="hackTap" then hackTap(p,value) return
 elseif action=="hackCancel" then cancelHack(p) return end
 if action=="voteMap" then
  if state.phase~="Votação" or p:GetAttribute("AFK") or type(value)~="string" or #value>80 then return end
  if value~="RANDOM" and not table.find(voteOptions,value) then return end
  mapVotes[p]=value p:SetAttribute("MapVote",value) voteCounts() return
 elseif action=="chooseKiller" then
  if state.phase~="Escolha" or p~=selectionPlayer or selectedKiller or p:GetAttribute("AFK") or type(value)~="string" or #value>40 or not assets.Killers:FindFirstChild(value) then return end
  selectedKiller=value p:SetAttribute("ChoosingKiller",false) return
 end
 if action=="afk" then
  if type(value)~="boolean" then return end
  p:SetAttribute("AFK",value)
  if value then queued[p]=nil end
  sync(p)
  net.Update:FireClient(p,"notice",value and "AFK ativado. Você não entra nas próximas partidas." or "AFK desativado. Você participa da próxima partida.")
  return
 end
 if action=="attack" then
  if p~=jasonPlayer or not npc or (npc:GetAttribute("ExecutionTargetUserId") or 0)>0 then return end
  local e=entry(p) if not e or e.status~="alive" or t-lastAttack<1.8 then return end
  lastAttack=t
  local rr=root(p) if not rr then return end
  npc:SetAttribute("AttackAt",t) npc:SetAttribute("AttackUntil",t+.75)
  local best=nil local pursuerSpec=config.Killers[killerName] local distance=(pursuerSpec and pursuerSpec.range or 5.5)+.5
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
  if value~="walk" and value~="run" and value~="crouch" then return end
  if e and e.status=="downed" and value=="run" then value="walk" end
  if e and e.status=="alive" then
   if e.injured and value=="run" then value="walk" end
   if value=="run" and (e.stamina or 0)<=1 then value="walk" end
   p:SetAttribute("MoveMode",value) sync(p)
  end
 elseif action=="carry" then
  toggleCarry(p)
 elseif action=="flashlight" then
  local e=entry(p)
  if p~=jasonPlayer and not p:GetAttribute("Downed") and (not e or e.status=="alive") then setFlashlight(p,not p:GetAttribute("FlashlightOn")) end
 elseif action=="revive" then if p~=jasonPlayer then channelRevive(p) end
 elseif action=="voice" then
  local e=entry(p) local r=root(p) if brain and r and e and e.status=="alive" and type(value)=="number" and value==value and value>.015 and value<=1 then brain.noise(r.Position,config.Killers[killerName].hearing*.8) end
 elseif action=="leave" then
  if p==jasonPlayer then endTime=now() end
  local e=entry(p) if e then e.status="eliminated" e.channel=nil end p:SetAttribute("ReviveAt",0) queued[p]=nil p:SetAttribute("Spectating",false) lobby(p) sync(p)
 elseif action=="spectateExit" then
  p:SetAttribute("Spectating",false)
  local e=entry(p)
  if e and e.status=="eliminated" then lobby(p) end
 end
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
 p:SetAttribute("SessionJoinedAt",now())
 local stats=Instance.new("Folder",p) stats.Name="leaderstats"
 local function makeStat(name,value) local v=Instance.new("IntValue",stats) v.Name=name v.Value=value or 0 return v end
 makeStat("Pontos",0) local xp=makeStat("XP",0) makeStat("Nível",1) makeStat("Atingido",0) makeStat("Quedas",0)
 profiles:attach(p) saveAt[p]=now()+150+math.random(0,30)
 task.spawn(function() if not profiles:load(p) and p.Parent then net.Update:FireClient(p,"notice","O progresso está temporariamente indisponível. Sua compra fica protegida.") end end)
 sync(p)
 local onCharacter
 onCharacter=function(char)
  if morphing[p] or (p==jasonPlayer and char:GetAttribute("ActivePursuer")) then return end
  if hookedCharacters[char] then return end
  hookedCharacters[char]=true
  local h=char:WaitForChild("Humanoid",10)
  if h and h.RigType~=Enum.HumanoidRigType.R6 and p~=jasonPlayer then
   morphing[p]=true
   local converted=convertCharacterToR6(p,char)
   morphing[p]=nil
   if converted and converted~=char then
    rigRetries[p]=nil
    expectedCharacters[p]=converted
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
  local expectedReplacement=expectedCharacters[p]==char
  if expectedReplacement then expectedCharacters[p]=nil end
  local e=entry(p)
  if e and (e.status=="alive" or e.status=="downed" or e.status=="loading") then
   if state.phase=="Partida" and (e.spawnRecovery or expectedReplacement) then
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
 saveAt[p]=nil
 morphing[p]=nil rigRetries[p]=nil expectedCharacters[p]=nil
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
 updateHacks(step)
 for _,p in ipairs(Players:GetPlayers()) do
  local e=entry(p) local r=root(p) local h=humanoid(p)
  if t>=(saveAt[p] or math.huge) then saveAt[p]=t+150+math.random(0,30) task.spawn(saveProfile,p) end
  -- Admission is automatic between rounds; AFK never cancels an active death or round.
  if not e then
   local eligible=not p:GetAttribute("AFK") and not p:GetAttribute("InMenu") and not p:GetAttribute("VoidActive") and r and h and h.Health>0
   if eligible and state.phase=="Partida" and t<=roundJoinUntil then
    if Rules.count(state)<Rules.Capacity and not roundClosing then if join(p) then spawnPlayer(p) end end
   elseif eligible and not queued[p] then queued[p]=true sync(p)
   elseif not eligible and queued[p] then queued[p]=nil sync(p) end
  end
  if e then
   if (e.carryingUserId or 0)>0 and (e.status~="alive" or not r) then dropCarry(p) end
   if (e.carriedBy or 0)>0 and e.status~="downed" then
    local carrier=Players:GetPlayerByUserId(e.carriedBy)
    if carrier then dropCarry(carrier) else e.carriedBy=0 end
   end
   if e.status=="alive" or e.status=="downed" then e.survivalTime=(e.survivalTime or 0)+step end
   if e.status=="loading" and t>e.loadDeadline then if p==jasonPlayer then endTime=t end state.entries[p.UserId]=nil sync(p) net.Update:FireClient(p,"notice","Carregamento demorou. Tente entrar novamente.") end
   if e.status=="downed" and not p:GetAttribute("BeingExecuted") and t>=e.deadline then eliminate(p,e.cause) end
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
      te.injured=true te.protectedUntil=t+4
      if te.carriedBy and te.carriedBy>0 then
       local carrier=Players:GetPlayerByUserId(te.carriedBy) if carrier then dropCarry(carrier) end
      end
      sync(c.target) sync(p)
      if c.target~=p then reward(p,30,18) end
     end e.channel=nil p:SetAttribute("ReviveAt",0)
    end
   end
   if r and h and (e.status=="alive" or e.status=="downed") then
    if r.Position.Y<(arena:GetAttribute("RecoveryY") or (arena:GetAttribute("FloorY") or 20)-3) then
     recoverFromFall(p)
    else
     local m=motions[p] or {position=r.Position,speed=0,grounded=true}
     local displacement=r.Position-m.position m.speed=Vector3.new(displacement.X,0,displacement.Z).Magnitude/step m.position=r.Position motions[p]=m
     if e.status=="alive" then
      local mode=p:GetAttribute("MoveMode") or "walk"
      local maxStamina=p==jasonPlayer and Rules.KillerStamina or Rules.SurvivorStamina
      local running=mode=="run" and m.speed>2
      if running then
       e.stamina=math.max(0,(e.stamina or maxStamina)-(p==jasonPlayer and Rules.KillerDrain or Rules.SurvivorDrain)*step)
       if e.stamina<=.1 then p:SetAttribute("MoveMode","walk") mode="walk" end
      else
       e.stamina=math.min(maxStamina,(e.stamina or maxStamina)+(p==jasonPlayer and Rules.KillerRegen or Rules.SurvivorRegen)*step)
      end
      local grounded=h.FloorMaterial~=Enum.Material.Air
      local jump=m.grounded and not grounded and r.AssemblyLinearVelocity.Y>5
      if grounded and m.speed>2 and mode~="crouch" and t-(e.lastNoise or 0)>(mode=="run" and .38 or .65) then
       local template=net:FindFirstChild("FootstepSound")
       if template then local sound=template:Clone() sound.Volume=mode=="run" and .42 or .16 sound.RollOffMinDistance=4 sound.RollOffMaxDistance=mode=="run" and 48 or 18 sound.Parent=r sound:Play() game:GetService("Debris"):AddItem(sound,3) end
       e.lastNoise=t
      end
      m.grounded=grounded
      if t-(e.lastStaminaSync or 0)>.35 then e.lastStaminaSync=t sync(p) end
     end
    end
   end
  end
 end
 if arena and npc and npc.Parent and npc.PrimaryPart and not jasonPlayer then
  local recoveryY=arena:GetAttribute("RecoveryY") or ((arena:GetAttribute("FloorY") or 20)-3)
  if npc.PrimaryPart.Position.Y<recoveryY then
   local spawn=arena:GetAttribute("KillerSpawn")
   if typeof(spawn)=="Vector3" then
    local offset=npc:GetAttribute("GroundOffset") or 3
    local rotation=npc:GetPivot().Rotation
    npc:PivotTo(CFrame.new(spawn+Vector3.new(0,offset,0))*rotation)
    npc.PrimaryPart.AssemblyLinearVelocity=Vector3.zero
    npc.PrimaryPart.AssemblyAngularVelocity=Vector3.zero
   end
  end
 end
end)
local RESULT_PRESENTATION_SECONDS=9

local function finish()
 for p in pairs(hackSessions) do cancelHack(p) end
 local participants={} local living=0 local escaped=0
 if state.phase=="Partida" and not adminResetRequested then
  for _,p in ipairs(Players:GetPlayers()) do
   local e=entry(p)
   if e then
    if p~=jasonPlayer and (e.status=="alive" or e.status=="downed" or e.status=="loading") then living+=1 end
    if p~=jasonPlayer and e.status=="escaped" then escaped+=1 end
    if p~=jasonPlayer then table.insert(participants,{name=p.DisplayName or p.Name,userId=p.UserId,time=math.floor(e.survivalTime or 0),hits=e.hits or 0,falls=e.falls or 0,level=1}) end
   end
  end
  table.sort(participants,function(x,y) if x.time~=y.time then return x.time>y.time elseif x.hits~=y.hits then return x.hits<y.hits else return x.falls<y.falls end end)
  local jasonWon=escaped==0 and (jasonPlayer~=nil or (npc and npc.Parent and npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChildOfClass("Humanoid").Health>0))
  local earned={}
  for _,p in ipairs(Players:GetPlayers()) do
   local e=entry(p)
   if e then
    local timeXP=math.floor((e.survivalTime or 0)/45)*2
    local reward=math.max(0,(e.roundXP or 0)+timeXP)
    if p==jasonPlayer and jasonWon then reward+=25 end
    earned[p]=reward
    if reward>0 then profiles:awardXP(p,reward) end
    for _,row in ipairs(participants) do if row.userId==p.UserId then row.level=Profiles.level(p:FindFirstChild("leaderstats") and p:FindFirstChild("leaderstats").XP.Value or 0) end end
    task.spawn(saveProfile,p)
   end
  end
  if jasonWon and npc and npc.PrimaryPart and lastVictimReplay then
   if lastExecutionCF then npc:PivotTo(lastExecutionCF) end
   npc.PrimaryPart.Anchored=true
   local replay=lastVictimReplay:Clone() replay.Name="ResultVictim"
   replay.PrimaryPart=replay:FindFirstChild("HumanoidRootPart")
   for _,part in ipairs(replay:GetDescendants()) do if part:IsA("BasePart") then part.Anchored=part==replay.PrimaryPart part.CanCollide=false part.CanTouch=false part.CanQuery=false end end
   replay:SetAttribute("PresentationVictim",true) replay:SetAttribute("ExecutionKiller",killerName)
   replay:SetAttribute("ExecutionAt",now()) replay:SetAttribute("ExecutionDuration",npc:GetAttribute("ExecutionLength") or 2.5)
   replay.Parent=arena
   if replay.PrimaryPart then
    local target=(npc.PrimaryPart.CFrame*CFrame.new(.45,0,-3.05)).Position
    target=Vector3.new(target.X,replay.PrimaryPart.Position.Y,target.Z)
    replay:PivotTo(CFrame.lookAt(target,target+npc.PrimaryPart.CFrame.LookVector))
   end
  end
  local killerWasPlayer=jasonPlayer~=nil
  local killerWinnerName=killerWasPlayer and (jasonPlayer.DisplayName or jasonPlayer.Name) or killerName
  for _,p in ipairs(Players:GetPlayers()) do
   net.Update:FireClient(p,"roundResult",{jasonWon=jasonWon,killer=killerName,killerPlayer=killerWasPlayer,killerWinnerName=killerWinnerName,winnerText=jasonWon and (killerWinnerName.." venceu a partida") or (tostring(escaped).." sobrevivente(s) escaparam"),lastVictimUserId=lastKilledUserId,lastVictimName=lastKilledName,board=participants,xp=earned[p] or 0,map=arena and arena:GetAttribute("DisplayName") or ""})
  end
  -- Keep the real arena and real winner alive while every client owns a full-screen cinematic camera.
  state.phase="Resultados"
  roundClosing=true
  net:SetAttribute("Phase","Resultados")
  net:SetAttribute("EndsAt",now()+RESULT_PRESENTATION_SECONDS)
  local resultEnd=now()+RESULT_PRESENTATION_SECONDS
  while now()<resultEnd and not adminResetRequested do task.wait(.2) end
 end
 state.phase="Intervalo" roundClosing=false roundJoinUntil=0 net:SetAttribute("JoinUntil",0) if brain then brain.stop() brain=nil end
 local former=jasonPlayer jasonPlayer=nil
 if former and former.Parent then morphing[former]=true former:SetAttribute("IsJason",false) pcall(function() former:LoadCharacterAsync() end) morphing[former]=nil end
 for _,p in ipairs(Players:GetPlayers()) do
  net.Update:FireClient(p,"reset")
  local e=entry(p) if e then
   -- Finish any death presentation before cleaning the arena; lobby position remains safe.
   RS.SweanVoidEvent:FireClient(p,"finish") p:SetAttribute("Spectating",false)
   local rr=root(p) if rr then rr.Anchored=false end p:SetAttribute("BeingExecuted",false) lobby(p)
  end
 end
 if lastVictimReplay then lastVictimReplay:Destroy() lastVictimReplay=nil end
 adminResetRequested=false
 table.clear(state.entries) for _,p in ipairs(Players:GetPlayers()) do sync(p) end
 disconnectObjectives()
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

  table.clear(mapVotes) voteCounts()
  for _,p in ipairs(Players:GetPlayers()) do p:SetAttribute("MapVote",nil) end
  endTime=now()+Rules.Intermission
  while now()<endTime and #Players:GetPlayers()>0 and not adminResetRequested do
   net:SetAttribute("Phase","Intervalo")
   net:SetAttribute("EndsAt",endTime)
   net:SetAttribute("Count",0)
   local waiting=0 for p in pairs(queued) do if p.Parent then waiting+=1 end end
   net:SetAttribute("Waiting",math.min(waiting,Rules.Capacity))
   net:SetAttribute("MaxPlayers",Rules.Capacity)
   task.wait(1)
  end

  local function hasQueued()
   local count=0
   for p in pairs(queued) do if not p:GetAttribute("AFK") and p.Parent and root(p) and humanoid(p) and humanoid(p).Health>0 and not p:GetAttribute("VoidActive") then count+=1 end end
   return count>=2
  end
  while #Players:GetPlayers()>0 and not hasQueued() and not adminResetRequested do
   net:SetAttribute("Phase","Intervalo") net:SetAttribute("EndsAt",0) net:SetAttribute("Waiting",0) task.wait(.5)
  end

  if #Players:GetPlayers()>0 and not adminResetRequested then
   table.clear(mapVotes)
   chooseVoteOptions()
   voteCounts()
   for _,p in ipairs(Players:GetPlayers()) do p:SetAttribute("MapVote",nil) end
   state.phase="Votação"
   local voteEnd=now()+Rules.VoteDuration
   while now()<voteEnd and hasQueued() and not adminResetRequested do
    net:SetAttribute("Phase","Votação")
    net:SetAttribute("EndsAt",voteEnd)
    task.wait(.15)
   end
  end
  if #Players:GetPlayers()>0 and not adminResetRequested then
   local ok,err=xpcall(function()
    roundClosing=false lastKilledUserId=0 lastKilledName=nil
    local mapList=assets.Maps:GetChildren() local rigList=assets.Killers:GetChildren()
    table.sort(mapList,function(a,b) return a.Name<b.Name end)
    local counts=voteCounts() local winnerTokens={} local highest=0
    for _,token in ipairs(voteOptions) do
     local count=counts[token] or 0
     if count>highest then highest=count winnerTokens={token}
     elseif count==highest and count>0 then table.insert(winnerTokens,token) end
    end
    do
     local randomCount=counts.RANDOM or 0
     if randomCount>highest then highest=randomCount winnerTokens={"RANDOM"}
     elseif randomCount==highest and randomCount>0 then table.insert(winnerTokens,"RANDOM") end
    end
    local token=highest>0 and winnerTokens[math.random(#winnerTokens)] or "RANDOM"
    local selected=nil
    if token=="RANDOM" then
     local randomPool={}
     for _,candidate in ipairs(mapList) do
      if candidate.Name~=previousMap or #mapList==1 then table.insert(randomPool,candidate) end
     end
     selected=randomPool[math.random(#randomPool)]
    else
     selected=assets.Maps:FindFirstChild(token)
    end
    assert(selected,"Selected voting map missing")
    previousMap=selected.Name
    local eligible={}
    for _,p in ipairs(Players:GetPlayers()) do if queued[p] and not p:GetAttribute("AFK") and root(p) and humanoid(p) and humanoid(p).Health>0 and not p:GetAttribute("VoidActive") then table.insert(eligible,p) end end
    assert(#eligible>=2,"Two participants required for player-controlled killer")
    selectionPlayer=eligible[math.random(math.min(#eligible,Rules.Capacity))]
    selectedKiller=nil state.phase="Escolha"
    net:SetAttribute("Phase","Escolha") net:SetAttribute("EndsAt",now()+Rules.KillerChoiceDuration)
    selectionPlayer:SetAttribute("ChoosingKiller",true)
    local deadline=now()+Rules.KillerChoiceDuration
    while now()<deadline and not adminResetRequested and not selectedKiller and selectionPlayer.Parent and not selectionPlayer:GetAttribute("AFK") do task.wait(.2) end
    selectionPlayer:SetAttribute("ChoosingKiller",false)
    if adminResetRequested or not selectionPlayer.Parent or selectionPlayer:GetAttribute("AFK") or not humanoid(selectionPlayer) or humanoid(selectionPlayer).Health<=0 then selectionPlayer=nil return end
    jasonPlayer=selectionPlayer selectionPlayer=nil
    Rules.begin(state)
    arena=selected:Clone() arena.Name="ActiveArena" arena.Parent=workspace arena:SetAttribute("RoundId",state.id)
    setupObjectives()
    local chosen=assets.Killers:FindFirstChild(selectedKiller or "Jason") or rigList[1]
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
    npc:SetAttribute("AttackUntil",0)
    npc:FindFirstChildOfClass("Humanoid").Died:Connect(function() endTime=now() end)
    do
     clearFlashlight(jasonPlayer)
     local old=jasonPlayer.Character morphing[jasonPlayer]=true
     npc.Name=jasonPlayer.Name jasonPlayer.Character=npc
     morphing[jasonPlayer]=nil if old then old:Destroy() end
     for _,d in ipairs(npc:GetDescendants()) do if d:IsA("BasePart") then pcall(function() d:SetNetworkOwner(jasonPlayer) end) end end
     net.Update:FireClient(jasonPlayer,"notice","Você é "..killerName..". Persiga os sobreviventes e use o botão de ataque.")
    end
    endTime=now()+Rules.Duration
    net:SetAttribute("Phase","Partida")
    roundJoinUntil=now()+5
    net:SetAttribute("JoinUntil",roundJoinUntil)
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
