local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local Lighting=game:GetService('Lighting')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local config=require(package.Config);local State=require(package.RoundState)
local Profiles=require(script.Parent.ProfileService);local Rescue=require(script.Parent.RescueService);local Maps=require(script.Parent.MapService)
local Doors=require(script.Parent.DoorService)
local Arena=require(script.Parent.ArenaService)
local Bots=require(script.Parent.NextbotService)
local remote=package:WaitForChild('MatchAction')
local state=State.new(workspace:GetServerTimeNow(),config.Intermission,config.RoundDuration)
local admitted,cooldowns,votes,joined={},{},{},{}
local mapNames=Maps.Names();local mapIndex=1
local function publish()
 package:SetAttribute('Phase',state.phase);package:SetAttribute('Deadline',state.deadline);package:SetAttribute('Round',state.round)
end
local function setup(p)
 p:SetAttribute('NBInArena',false);p:SetAttribute('NBInRound',false);p:SetAttribute('NBSpectating',false)
 local function spawned(char)
  local h=char:WaitForChild('Humanoid',10);char:WaitForChild('HumanoidRootPart',10);if not p.Parent or p.Character~=char then return end
  if admitted[p]and state.phase=='Intermission'and package:GetAttribute('MapReady')then Arena.Enter(p,true)else Arena.Leave(p)end
  if h then h.Died:Connect(function()p:SetAttribute('NBInRound',false);p:SetAttribute('NBInArena',false);Rescue.Clear(p)end)end
 end
 p.CharacterAdded:Connect(spawned);if p.Character then task.spawn(spawned,p.Character)end
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers())do setup(p)end
local function syncVotes()
 local counts={};for _,name in pairs(votes)do counts[name]=(counts[name]or 0)+1 end
 package:SetAttribute('MapVotes',Http:JSONEncode(counts))
end
Players.PlayerRemoving:Connect(function(p)admitted[p]=nil;cooldowns[p]=nil;votes[p]=nil;joined[p]=nil;syncVotes()end)
remote.OnServerEvent:Connect(function(p,action,arg)
 if type(action)~='string'or os.clock()-(cooldowns[p]or -10)<.4 then return end;cooldowns[p]=os.clock()
 -- Votes select the arena for the following intermission, never replace the map under waiting players.
 if action=='Vote'and type(arg)=='string'and table.find(mapNames,arg)then votes[p]=arg;syncVotes();return end
 if action=='Spectate'then if not p:GetAttribute('NBInArena')then p:SetAttribute('NBSpectating',not p:GetAttribute('NBSpectating'))end;return end
 if action=='Lobby'then admitted[p]=nil;Arena.Leave(p);return end
 if action~='Join'then return end
 local alreadyActive=p:GetAttribute('NBInRound')
 local ok,status=Arena.Enter(p,false)
 if ok then admitted[p]=true;if p:GetAttribute('NBInRound')and not alreadyActive then joined[p]=workspace:GetServerTimeNow()end end
 remote:FireClient(p,status)
end)
publish()
-- Load the imported arena before accepting entry, and place menu cameras inside that same map.
local preferred=table.find(mapNames,config.InitialMap or 'gm_construct')or 1
for offset=0,#mapNames-1 do
 local index=(preferred+offset-1)%#mapNames+1
 if Maps.Load(mapNames[index])then mapIndex=index;break end
end
for _,p in ipairs(Players:GetPlayers())do if not p:GetAttribute('NBInArena')then Arena.Park(p)end end
state.deadline=workspace:GetServerTimeNow()+config.Intermission;publish()
local rewardAt=workspace:GetServerTimeNow()+30
while true do
 if state.phase=='Round'then Doors.Step()end
 local ready=false
 if package:GetAttribute('MapReady')then
  for _,p in ipairs(Players:GetPlayers())do if admitted[p]and p:GetAttribute('NBInArena')then ready=true;break end end
 end
 if State.tick(state,workspace:GetServerTimeNow(),ready)then
  Bots.Clear();publish()
  if state.phase=='Round'then
   local special=state.round%3==0 and ({'dark','fast','double'})[math.random(3)]or 'normal'
   package:SetAttribute('SpecialRound',special);Lighting.ClockTime=special=='dark'and 0 or 15
   rewardAt=workspace:GetServerTimeNow()+30
   for _,p in ipairs(Players:GetPlayers())do
    if admitted[p]and p:GetAttribute('NBInArena')then
     -- No teleport or map reload: the chase begins exactly where the player was waiting.
     if Arena.Enter(p,false)then joined[p]=workspace:GetServerTimeNow()end
    end
   end
   Bots.Start(state)
  else
   for _,p in ipairs(Players:GetPlayers())do
    if p:GetAttribute('NBInRound')and not p:GetAttribute('NBDowned')and workspace:GetServerTimeNow()-(joined[p]or math.huge)>=30 then task.spawn(Profiles.Reward,p,80,100,'survive')end
    Arena.PrepareMapChange(p)
   end
   package:SetAttribute('MapChanging',true);package:SetAttribute('SpecialRound','normal')
   mapIndex=mapIndex%#mapNames+1
   local counts={};for _,name in pairs(votes)do counts[name]=(counts[name]or 0)+1 end
   local winner=mapNames[mapIndex];local score=0
   for name,count in pairs(counts)do if count>score then score=count;winner=name end end
   mapIndex=table.find(mapNames,winner)or mapIndex
   table.clear(votes);syncVotes()
   if not Maps.Load(winner)then
    for offset=1,#mapNames do local index=(mapIndex+offset-1)%#mapNames+1;if Maps.Load(mapNames[index])then mapIndex=index;break end end
   end
   Lighting.ClockTime=15
   for _,p in ipairs(Players:GetPlayers())do
    local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
    if admitted[p]and h and h.Health>0 then Arena.Enter(p,true)else Arena.Leave(p)end
   end
   package:SetAttribute('MapChanging',false)
   state.deadline=workspace:GetServerTimeNow()+config.Intermission;publish()
  end
 end
 if state.phase=='Round'and workspace:GetServerTimeNow()>=rewardAt then
  rewardAt+=30
  for _,p in ipairs(Players:GetPlayers())do if p:GetAttribute('NBInRound')and not p:GetAttribute('NBDowned')and workspace:GetServerTimeNow()-(joined[p]or math.huge)>=29 then task.spawn(Profiles.Reward,p,10,15)end end
 end
 task.wait(.2)
end
