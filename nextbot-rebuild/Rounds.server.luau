local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local Storage=game:GetService('ServerStorage')
local Lighting=game:GetService('Lighting')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local config=require(package.Config);local State=require(package.RoundState)
local Profiles=require(script.Parent.ProfileService);local Rescue=require(script.Parent.RescueService);local Maps=require(script.Parent.MapService)
local Doors=require(script.Parent.DoorService);local Arena=require(script.Parent.ArenaService);local Bots=require(script.Parent.NextbotService)
local remote=package:WaitForChild('MatchAction')
local state=State.new(workspace:GetServerTimeNow(),config.Intermission,config.RoundDuration)
local admitted,cooldowns,votes,joined={},{},{},{}
local mapNames=Maps.Names();local mapIndex=1;local choices={}
local function publish()
 package:SetAttribute('Phase',state.phase);package:SetAttribute('Deadline',state.deadline);package:SetAttribute('Round',state.round)
end
local function clientReady(p)
 return p:GetAttribute('NBClientReadyRevision')==package:GetAttribute('MapRevision')and package:GetAttribute('MapReady')==true
end
local function syncVotes()package:SetAttribute('MapVotes',Http:JSONEncode(State.CountVotes(votes,choices)))end
local function setup(p)
 p:SetAttribute('NBInArena',false);p:SetAttribute('NBInRound',false);p:SetAttribute('NBSpectating',false);p:SetAttribute('NBClientReadyRevision',0)
 local function spawned(char)
  local h=char:WaitForChild('Humanoid',10);char:WaitForChild('HumanoidRootPart',10);if not p.Parent or p.Character~=char then return end
  if admitted[p]and state.phase=='Intermission'and clientReady(p)then Arena.Enter(p,true)else Arena.Leave(p)end
  if h then h.Died:Connect(function()p:SetAttribute('NBInRound',false);p:SetAttribute('NBInArena',false);Rescue.Clear(p)end)end
 end
 p.CharacterAdded:Connect(spawned);if p.Character then task.spawn(spawned,p.Character)end
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers())do setup(p)end
Players.PlayerRemoving:Connect(function(p)admitted[p]=nil;cooldowns[p]=nil;votes[p]=nil;joined[p]=nil;syncVotes()end)
remote.OnServerEvent:Connect(function(p,action,arg)
 if type(action)~='string'then return end
 if action=='ClientReady'then
  if type(arg)~='number'or arg~=package:GetAttribute('MapRevision')or not package:GetAttribute('MapReady')then return end
  if p:GetAttribute('NBClientReadyRevision')==arg then return end
  p:SetAttribute('NBClientReadyRevision',arg)
  if admitted[p]and state.phase~='Voting'then
   local ok=Arena.Enter(p,true);if ok and state.phase=='Round'then joined[p]=workspace:GetServerTimeNow()end
  end
  return
 end
 if os.clock()-(cooldowns[p]or -10)<.25 then return end;cooldowns[p]=os.clock()
 if action=='Vote'then
  if package:GetAttribute('VotingOpen')and type(arg)=='string'and table.find(choices,arg)then votes[p]=arg;p:SetAttribute('NBVotedMap',arg);syncVotes()end
  return
 end
 if action=='Spectate'then if not p:GetAttribute('NBInArena')then p:SetAttribute('NBSpectating',not p:GetAttribute('NBSpectating'))end;return end
 if action=='Lobby'then admitted[p]=nil;Arena.Leave(p);return end
 if action~='Join'then return end
 admitted[p]=true
 if state.phase=='Voting'then remote:FireClient(p,'voting');return end
 local alreadyActive=p:GetAttribute('NBInRound');local ok,status=Arena.Enter(p,false)
 if ok and p:GetAttribute('NBInRound')and not alreadyActive then joined[p]=workspace:GetServerTimeNow()end
 remote:FireClient(p,status)
end)
local function waitForAdmittedClients()
 package:SetAttribute('WaitingForClients',true)
 while true do
  local pending=false
  for _,p in ipairs(Players:GetPlayers())do if admitted[p]and not clientReady(p)then pending=true;break end end
  if not pending then break end
  task.wait(.1)
 end
 package:SetAttribute('WaitingForClients',false)
end
local function loadMap(name)
 package:SetAttribute('SelectedMap',name);package:SetAttribute('MapChanging',true)
 for _,p in ipairs(Players:GetPlayers())do p:SetAttribute('NBClientReadyRevision',0);Arena.PrepareMapChange(p)end
 local loaded=Maps.Load(name)
 if not loaded then
  for offset=1,#mapNames do local index=(mapIndex+offset-1)%#mapNames+1;if Maps.Load(mapNames[index])then mapIndex=index;loaded=true;break end end
 else mapIndex=table.find(mapNames,name)or mapIndex end
 package:SetAttribute('SelectedMap',package:GetAttribute('MapName')or name)
 package:SetAttribute('MapChanging',false)
 if not loaded then warn('Exact Run: no playable map could load');return false end
 for _,p in ipairs(Players:GetPlayers())do if not admitted[p]then Arena.Leave(p)end end
 waitForAdmittedClients()
 for _,p in ipairs(Players:GetPlayers())do
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if admitted[p]and h and h.Health>0 and clientReady(p)then Arena.Enter(p,true)else Arena.Leave(p)end
 end
 state.phase='Intermission';state.deadline=workspace:GetServerTimeNow()+config.Intermission;publish()
 return true
end
publish();package:SetAttribute('VotingOpen',false);package:SetAttribute('SpecialRound','normal');package:SetAttribute('RoundMode','normal')
package:SetAttribute('ModeNotice','A CADA 3 RODADAS, 1 OU 2 RODADAS COM PERSEGUIDORES')
local preferred=table.find(mapNames,config.InitialMap or 'gm_construct')or 1;mapIndex=preferred
loadMap(mapNames[preferred])
local rewardAt=workspace:GetServerTimeNow()+30
while true do
 if state.phase=='Round'then Doors.Step()end
 local ready=false;local pending=false
 if package:GetAttribute('MapReady')then
  for _,p in ipairs(Players:GetPlayers())do
   if admitted[p]then if not clientReady(p)then pending=true elseif p:GetAttribute('NBInArena')then ready=true end end
  end
 end
 if State.tick(state,workspace:GetServerTimeNow(),ready and not pending)then
  Bots.Clear()
  if state.phase=='Round'then
   local chasers=Storage:FindFirstChild('NBChaserTemplates')
   local special=State.NextKind(state,chasers~=nil and #chasers:GetChildren()>0)
   package:SetAttribute('SpecialRound',special);package:SetAttribute('RoundMode',special);package:SetAttribute('SpecialRoundsRemaining',state.specialRemaining)
   package:SetAttribute('ModeNotice',special=='chasers'and 'RODADA ESPECIAL • SOBREVIVA AOS PERSEGUIDORES'or 'A CADA 3 RODADAS, 1 OU 2 RODADAS COM PERSEGUIDORES')
   Lighting.ClockTime=15;publish();rewardAt=workspace:GetServerTimeNow()+30
   for _,p in ipairs(Players:GetPlayers())do
    if admitted[p]and p:GetAttribute('NBInArena')and clientReady(p)then if Arena.Enter(p,false)then joined[p]=workspace:GetServerTimeNow()end end
   end
   Bots.Start(state)
  else
   for _,p in ipairs(Players:GetPlayers())do
    if p:GetAttribute('NBInRound')and not p:GetAttribute('NBDowned')and workspace:GetServerTimeNow()-(joined[p]or math.huge)>=30 then task.spawn(Profiles.Reward,p,80,100,'survive')end
    Arena.PrepareMapChange(p);p:SetAttribute('NBVotedMap','')
   end
   table.clear(votes);table.clear(choices)
   for offset=1,math.min(3,#mapNames)do table.insert(choices,mapNames[(mapIndex+offset-1)%#mapNames+1])end
   package:SetAttribute('VoteOptions',Http:JSONEncode(choices));package:SetAttribute('VoteChoices',Http:JSONEncode(choices));syncVotes()
   state.phase='Voting';state.deadline=workspace:GetServerTimeNow()+(config.VotingDuration or 12)
   package:SetAttribute('VotingOpen',true);publish()
   repeat task.wait(.1)until workspace:GetServerTimeNow()>=state.deadline
   package:SetAttribute('VotingOpen',false)
   local winner=State.Winner(votes,choices,choices[1]);package:SetAttribute('SelectedMap',winner)
   state.phase='Loading';publish();package:SetAttribute('SpecialRound','normal')
   loadMap(winner)
  end
 end
 if state.phase=='Round'and workspace:GetServerTimeNow()>=rewardAt then
  rewardAt+=30
  for _,p in ipairs(Players:GetPlayers())do if p:GetAttribute('NBInRound')and not p:GetAttribute('NBDowned')and workspace:GetServerTimeNow()-(joined[p]or math.huge)>=29 then task.spawn(Profiles.Reward,p,10,15)end end
 end
 task.wait(.2)
end
