-- Execute the actual server controller against real models and deterministic player/clock adapters.
local realGame=game local realWorkspace=workspace local realTask=task local realInstance=Instance local realRequire=require
local RS=game:GetService("ReplicatedStorage") local SSS=game:GetService("ServerScriptService")
local host=Instance.new("Folder",workspace) host.Name="RoundControllerTest"
local events={} local function signal() local e=Instance.new("BindableEvent",host) table.insert(events,e) return e end
local heartbeat=signal() local added=signal() local removed=signal()
local serverActionHandler=nil
local players={} local messages={} local clock=1000 local scheduled={} local aiStopped=0 local noiseCalls=0 local roundErrors={}
local character=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R15)
local templateHum=character:FindFirstChildOfClass("Humanoid")
if not templateHum then templateHum=Instance.new("Humanoid",character) end
templateHum.MaxHealth=100 templateHum.Health=100 templateHum.RequiresNeck=false
local templateRoot=character:FindFirstChild("HumanoidRootPart")
if not templateRoot then
 templateRoot=Instance.new("Part") templateRoot.Name="HumanoidRootPart" templateRoot.Size=Vector3.new(2,2,1)
 templateRoot.Transparency=1 templateRoot.CanCollide=false templateRoot.Anchored=false templateRoot.CFrame=character:GetPivot()
 templateRoot.Parent=character
end
character.PrimaryPart=templateRoot
for i=1,9 do
 local f=Instance.new("Folder",host) f.Name="Player"..i
 local p={Name="Player"..i,UserId=i,Parent=host,Character=character:Clone(),CharacterAdded=signal().Event,attrs={},folder=f}
 p.Character.Name="Player"..i p.Character.Parent=host
 local h=p.Character:FindFirstChildOfClass("Humanoid") h.MaxHealth=100 h.Health=100
 local r=p.Character:FindFirstChild("HumanoidRootPart") assert(r,"Fake player root missing")
 p.Character.PrimaryPart=r p.Character:PivotTo(workspace.IslandSpawn.CFrame*CFrame.new(i*3,4,0))
 function p:GetAttribute(n) return self.attrs[n] end
 function p:SetAttribute(n,v) self.attrs[n]=v end
 function p:FindFirstChild(n) return self.folder:FindFirstChild(n) end
 table.insert(players,p)
end
character:Destroy()
local fakePlayers={PlayerAdded=added.Event,PlayerRemoving=removed.Event}
function fakePlayers:GetPlayers() return players end
local fakeAction={OnServerEvent={}}
function fakeAction.OnServerEvent:Connect(fn)
 serverActionHandler=fn
 return {Disconnect=function() end}
end
local fakeUpdate={}
function fakeUpdate:FireClient(p,kind,a,b) messages[p]=messages[p] or {} messages[p][kind]={a,b} end
function fakeUpdate:FireAllClients(kind,a,b) for _,p in ipairs(players) do self:FireClient(p,kind,a,b) end end
local net=RS.Survival
local proxyNet=setmetatable({Action=fakeAction,Update=fakeUpdate,Config=net.Config},{__index=function(_,k)
 local v=net[k] if type(v)=="function" then return function(_,...) return v(net,...) end end return v
end})
local proxyRS={SweanVoidEvent={FireClient=function() end}}
function proxyRS:WaitForChild(name) if name=="Survival" then return proxyNet end return RS:WaitForChild(name) end
local proxyGame={}
function proxyGame:GetService(name)
 if name=="Players" then return fakePlayers elseif name=="ReplicatedStorage" then return proxyRS elseif name=="RunService" then return {Heartbeat=heartbeat.Event} end
 return realGame:GetService(name)
end
local proxyWorkspace=setmetatable({GetServerTimeNow=function() return clock end},{__index=function(_,k)
 local v=realWorkspace[k] if type(v)=="function" then return function(_,...) return v(realWorkspace,...) end end return v
end})
local proxyInstance={new=function(class,parent) return realInstance.new(class,type(parent)=="table" and parent.folder or parent) end}
local function resume(co,...)
 local ok,delay=coroutine.resume(co,...) assert(ok,delay)
 if coroutine.status(co)~="dead" then table.insert(scheduled,{co=co,at=clock+(tonumber(delay) or 0)}) end
end
local proxyTask={spawn=function(fn,...) local co=coroutine.create(fn) resume(co,...) return co end,wait=function(seconds) return coroutine.yield(seconds or .01) end}
proxyTask.delay=function(seconds,fn,...) local args={...} local co=coroutine.create(function() fn(table.unpack(args)) end) table.insert(scheduled,{co=co,at=clock+seconds}) end
local aiContext local killerModel
local stubAI={start=function(_,_,_,ctx) aiContext=ctx return {noise=function() noiseCalls+=1 end,stop=function() aiStopped+=1 end} end}
local stubFactory={create=function(name)
 local model=Instance.new("Model")
 model.Name=name
 local root=Instance.new("Part")
 root.Name="HumanoidRootPart" root.Size=Vector3.new(2,2,1) root.Anchored=false root.Parent=model
 local hum=Instance.new("Humanoid") hum.RequiresNeck=false hum.Parent=model
 model.PrimaryPart=root killerModel=model
 return model
end}
local function run()
 local game=proxyGame local workspace=realWorkspace local task=proxyTask local Instance=proxyInstance
 local TEST_NOW=function() return clock end
 local warn=function(message) table.insert(roundErrors,tostring(message)) end
 local require=function(module)
 if module==net.Config then local c=realRequire(module) local copy=table.clone(c) copy.PlayerJasonChance=0 return copy
 elseif module==SSS.PursuerAI then return stubAI
 elseif module==SSS.KillerFactory then return stubFactory end
 return realRequire(module)
end
__SURVIVAL_SERVER_TEST_SOURCE__
end
local function advance(seconds)
 local target=clock+seconds
 while clock<target do
  local before=clock
  clock=math.min(target,clock+1)
  local progressed=true
  while progressed do
   progressed=false
   local due=scheduled scheduled={}
   for _,s in ipairs(due) do
    if s.at<=clock then resume(s.co) progressed=true
    else table.insert(scheduled,s) end
   end
  end
  heartbeat:Fire(clock-before)
  realTask.wait()
 end
end
local function send(p,kind,value)
 assert(serverActionHandler,"Server action handler was not connected")
 serverActionHandler(p,kind,value)
 realTask.wait()
end
local deathCount=0 local dc=SSS.SurvivalBridge.DeathRequest.Event:Connect(function() deathCount+=1 end)
local ok,result=xpcall(function()
 run() assert(net:GetAttribute("Phase")=="Intervalo")
 for i,p in ipairs(players) do
  local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  assert(r and h,"Fake player "..i.." missing character root/humanoid before round")
  h.RequiresNeck=false h.MaxHealth=100 h.Health=100 h.BreakJointsOnDeath=false
  r.Anchored=true p.attrs.VoidActive=false
 end
 for i=1,8 do players[i].Character:PivotTo(workspace.LobbyJoinPortal.CFrame) end
 advance(1)
 for i=1,8 do assert(players[i]:GetAttribute("Queued"),"Door did not queue participant") end
 send(players[9],"join") assert(not players[9]:GetAttribute("Queued"),"Remote bypassed portal")
 advance(30) assert(net:GetAttribute("Phase")=="Partida",string.format("Round did not start: clock=%s ends=%s phase=%s scheduled=%d errors=%s",tostring(clock),tostring(net:GetAttribute("EndsAt")),tostring(net:GetAttribute("Phase")),#scheduled,table.concat(roundErrors," | ")))
 for i=1,8 do
  local status=players[i]:GetAttribute("RoundStatus")
  assert(status=="alive" and players[i]:GetAttribute("InRound"),"Player "..i.." was not teleported into round immediately; status="..tostring(status))
  assert(messages[players[i]] and messages[players[i]].load,"Player "..i.." did not receive advisory preload request")
 end
 assert(players[9]:GetAttribute("RoundStatus")=="lobby","Ninth participant admitted")
 local count=0 for _,p in ipairs(players) do if p:GetAttribute("InRound") then count+=1 end end assert(count==8,"Expected 8 active players, got "..count)
 for i=1,8 do
  local c=players[i].Character c:PivotTo(CFrame.new(i*25,1000,0)) c.HumanoidRootPart.Anchored=true
 end
 local function hit(p)
  killerModel:PivotTo(p.Character:GetPivot()*CFrame.new(0,0,2))
  aiContext.catch(p) advance(1)
 end
 local p=players[1] send(p,"boost") assert(not p:GetAttribute("HasBoost"),"Boost item was not consumed")
 advance(1) assert(p.Character.Humanoid.WalkSpeed==27,"Boost speed mismatch: "..tostring(p.Character.Humanoid.WalkSpeed))
 advance(5) assert(p.Character.Humanoid.WalkSpeed==16,"Boost did not expire")
 send(p,"mode","slow") assert(p.Character.Humanoid.WalkSpeed==8,"Slow speed mismatch: "..tostring(p.Character.Humanoid.WalkSpeed))
 assert(aiContext,"AI context missing after round start")
 hit(p) assert(p:GetAttribute("Injured") and not p:GetAttribute("Downed"),"First Jason hit must injure, not down")
 assert(p.Character.Humanoid.WalkSpeed<=16,"Injured survivor was not slowed")
 hit(p) assert(p:GetAttribute("Downed"),"Second Jason hit must down injured survivor")
 send(p,"kit") advance(3.2)
 assert(not p:GetAttribute("Downed") and not p:GetAttribute("HasMedkit"),"Self revive failed")
 local ally=players[2] local healer=players[3]
 hit(ally) assert(ally:GetAttribute("Injured") and not ally:GetAttribute("Downed"),"Ally first hit must injure")
 hit(ally) assert(ally:GetAttribute("Downed"),"Ally second hit must down")
 healer.Character:PivotTo(ally.Character:GetPivot()*CFrame.new(3,0,0))
 send(healer,"kit") advance(3.2)
 assert(not ally:GetAttribute("Downed") and not healer:GetAttribute("HasMedkit"),"Ally revive failed")
 assert(healer.folder.leaderstats.Pontos.Value>=10,"Revive points missing")
 assert(aiContext,"AI context missing before elimination")
 advance(1)
 hit(p) assert(p:GetAttribute("Injured") and not p:GetAttribute("Downed"),"Player was not injured before second hit")
 hit(p) assert(p:GetAttribute("Downed"),"Player was not downed before bleedout elimination")
 advance(26)
 assert(p:GetAttribute("RoundStatus")=="eliminated" and deathCount>=1,"Elimination flow mismatch: status="..tostring(p:GetAttribute("RoundStatus")).." deaths="..deathCount)
 send(p,"join") assert(p:GetAttribute("RoundStatus")=="eliminated","Eliminated player rejoined")
 SSS.SurvivalBridge.DeathFinished:Fire(p) realTask.wait()
 players[9].Character:PivotTo(workspace.LobbyJoinPortal.CFrame) advance(1)
 assert(messages[players[9]] and messages[players[9]].load,"Ninth player did not receive freed-slot preload")
 assert(players[9]:GetAttribute("InRound") and players[9]:GetAttribute("RoundStatus")=="alive","Ninth player was not teleported immediately into freed slot")
 local roundRemaining=math.max(0,(net:GetAttribute("EndsAt") or clock)-clock)
 advance(roundRemaining+1)
 assert(aiStopped==1,"Round AI did not clean up")
 assert(net:GetAttribute("Phase")=="Intervalo","Next intermission did not start after round cleanup")
 assert(not workspace:FindFirstChild("ActiveArena"),"Arena remained during next intermission")
 for _,pl in ipairs(players) do
  assert(not pl:GetAttribute("InRound") and not pl:GetAttribute("Spectating"),"Player state did not reset after round: "..tostring(pl.UserId))
 end
 return {ok=true,selfAndAllyRevive=true,injuredFirstHit=true,injuredSlow=true,doorOnlyAdmission=true,instantDoorTeleport=true,eightPlayerLimit=true,midRoundJoin=true,eliminationCannotRejoin=true,spectatorFlowCoveredByClientTest=true,boostExpires=true,roundCleanup=true}
end,debug.traceback)
dc:Disconnect()
for _,e in ipairs(events) do e:Destroy() end
for _,m in ipairs(workspace:GetChildren()) do if m.Name=="ActiveArena" or m:GetAttribute("ActivePursuer") then m:Destroy() end end
host:Destroy() table.clear(scheduled)
assert(ok,result)
return result

