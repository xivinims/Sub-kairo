-- Execute the actual server controller against real models and deterministic player/clock adapters.
local realGame=game local realWorkspace=workspace local realTask=task local realInstance=Instance local realRequire=require
local RS=game:GetService("ReplicatedStorage") local SSS=game:GetService("ServerScriptService")
local host=Instance.new("Folder",workspace) host.Name="RoundControllerTest"
local events={} local function signal() local e=Instance.new("BindableEvent",host) table.insert(events,e) return e end
local heartbeat=signal() local added=signal() local removed=signal()
local serverActionHandler=nil
local players={} local messages={} local clock=1000 local scheduled={} local aiStopped=0 local noiseCalls=0 local roundErrors={}
local character=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R6)
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
 function p:LoadCharacterAsync() self.Character=players[9].Character:Clone() self.Character.Parent=host end
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
 if name=="DataStoreService" then return {GetDataStore=function() return {GetAsync=function() return nil end,UpdateAsync=function(_,_,fn) return fn(nil) end} end} end
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
 if module==net.Config then local c=realRequire(module) local copy=table.clone(c) copy.PlayerJasonChance=1 return copy
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
 send(players[9],"afk",true)
 advance(1)
 for i=1,8 do assert(players[i]:GetAttribute("Queued"),"Automatic lobby admission did not queue participant") assert(players[i].Character.Humanoid.RigType==Enum.HumanoidRigType.R6,"Participant is not R6") end
 send(players[9],"join") assert(not players[9]:GetAttribute("Queued"),"Remote join bypassed AFK admission")
 for i=1,8 do send(players[i],"chooseKiller","Jeff") end
 local mapName=game.ServerStorage.SurvivalAssets.Maps:GetChildren()[1].Name
 send(players[1],"voteMap",mapName)
 send(players[1],"voteMap","invalid-map")
 assert(players[1]:GetAttribute("MapVote")==mapName,"Invalid map overwrote vote")
 advance(30) assert(net:GetAttribute("Phase")=="Partida",string.format("Round did not start: clock=%s ends=%s phase=%s scheduled=%d errors=%s",tostring(clock),tostring(net:GetAttribute("EndsAt")),tostring(net:GetAttribute("Phase")),#scheduled,table.concat(roundErrors," | ")))
 for i=1,8 do
  local status=players[i]:GetAttribute("RoundStatus")
  assert(status=="alive" and players[i]:GetAttribute("InRound"),"Player "..i.." was not admitted immediately; status="..tostring(status))
  assert(messages[players[i]] and messages[players[i]].load,"Player "..i.." did not receive advisory preload request")
 end
 assert(players[9]:GetAttribute("RoundStatus")=="lobby","Ninth participant admitted")
 local killer=nil local killers=0
 for _,p in ipairs(players) do if p:GetAttribute("IsJason") then killer=p killers+=1 end end
 assert(net:GetAttribute("Killer")=="Jeff","Chosen killer was ignored")
 assert(workspace.ActiveArena:GetAttribute("DisplayName")==game.ServerStorage.SurvivalAssets.Maps[mapName]:GetAttribute("DisplayName"),"Winning map vote ignored")
 assert(killers==1 and killer,"Exactly one player must become Jason")
 assert(killer.Character==killerModel and not aiContext,"AI and player cannot control Jason together")
 assert(not (messages[killer] and messages[killer].jasonIntro),"Removed killer intro cinematic was sent")
 local killerSpec=require(net.Config).Killers[net:GetAttribute("Killer")]
 local expectedKillerSpeed=assert(killerSpec and killerSpec.speed,"Selected killer config missing")
 assert(killer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed==expectedKillerSpeed,"Player killer did not use its configured speed")
 local victim=nil
 for i,p in ipairs(players) do
  p.Character:PivotTo(CFrame.new(i*30,1000,0)) p.Character.HumanoidRootPart.Anchored=true
  if i<=8 and p~=killer then victim=p end
 end
 advance(.5)
 assert(killer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed==expectedKillerSpeed,"Player killer movement changed unexpectedly")
 local before=net:GetAttribute("EndsAt")
 send(killer,"loadFailed",1) advance(.3)
 assert(net:GetAttribute("Phase")=="Partida" and net:GetAttribute("EndsAt")==before,"Advisory preload error ended a running player-Jason round")
 advance(6)
 local protectedFor=math.max(0,(victim:GetAttribute("ProtectedUntil") or 0)-clock)
 if protectedFor>0 then advance(protectedFor+.2) end
 killer.Character:PivotTo(victim.Character:GetPivot()*CFrame.new(0,0,3))
 send(killer,"attack") advance(1)
 assert(victim:GetAttribute("Injured") and not victim:GetAttribute("Downed"),"First player-Jason hit did not injure victim")
 advance(1)
 send(killer,"attack") advance(1)
 assert(victim:GetAttribute("Downed"),"Second player-Jason hit did not down victim")
 killer.Character:PivotTo(victim.Character:GetPivot()*CFrame.new(0,0,3))
 advance(1)
 send(killer,"attack") advance(2)
 assert(victim:GetAttribute("RoundStatus")=="eliminated","Jason execution did not eliminate downed victim")
 assert(not killer:GetAttribute("Downed"),"Jason downed himself")
 send(killer,"leave") advance(2)
 assert(net:GetAttribute("Phase")=="Intervalo","Leaving player Jason must end round safely")
 assert(not killer:GetAttribute("IsJason") and not killer:GetAttribute("InRound"),"Jason role leaked into lobby")
 assert(killer.Character~=killerModel,"Original avatar was not restored")
 return {ok=true,survivorR6=true,eightParticipantPlayerJason=true,noKillerIntro=true,configuredKillerSpeed=true,automaticLobbyAdmission=true,oneController=true,injure=true,down=true,execution=true,attack=true,restoreAvatar=true,advisoryLoadFailureSafe=true}

end,debug.traceback)
dc:Disconnect()
for _,e in ipairs(events) do e:Destroy() end
for _,m in ipairs(workspace:GetChildren()) do if m.Name=="ActiveArena" or m:GetAttribute("ActivePursuer") then m:Destroy() end end
host:Destroy() table.clear(scheduled)
assert(ok,result)
return result


