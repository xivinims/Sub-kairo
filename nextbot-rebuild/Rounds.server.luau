local Players=game:GetService('Players')
local Storage=game:GetService('ServerStorage')
local Pathfinding=game:GetService('PathfindingService')
local Collection=game:GetService('CollectionService')
local Http=game:GetService('HttpService')
local Lighting=game:GetService('Lighting')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local config=require(package.Config);local State=require(package.RoundState)
local Profiles=require(script.Parent.ProfileService);local Rescue=require(script.Parent.RescueService);local Maps=require(script.Parent.MapService)
local Doors=require(script.Parent.DoorService)
local remote=package:WaitForChild('MatchAction')
local state=State.new(workspace:GetServerTimeNow(),config.Intermission,config.RoundDuration)
local admitted,cooldowns,bots,votes,joined={},{},{},{},{}
local mapNames=Maps.Names();local mapIndex=1
for i,name in ipairs(mapNames)do if Maps.Load(name)then mapIndex=i;break end end
local function markers(name)local f=workspace:FindFirstChild(name);return f and f:GetChildren()or {}end
local function teleport(p,name)
 local points=markers(name);local c=p.Character
 if #points==0 or not c then return false end
 local root=c:FindFirstChild('HumanoidRootPart');if not root then return false end
 c:PivotTo(points[math.random(#points)].CFrame+Vector3.new(0,4,0));root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 p:SetAttribute('NBInvulnerableUntil',workspace:GetServerTimeNow()+5);return true
end
local function publish()
 package:SetAttribute('Phase',state.phase);package:SetAttribute('Deadline',state.deadline);package:SetAttribute('Round',state.round)
end
local function setActive(p,active)
 if not active then Rescue.Clear(p)end
 p:SetAttribute('NBInRound',active);p:SetAttribute('NBSpectating',false)
 if active then joined[p]=workspace:GetServerTimeNow()end
end
local function clearBots()for _,bot in ipairs(bots)do bot:Destroy()end;table.clear(bots)end
local function targetFrom(position)
 local closest,distance=nil,math.huge
 for _,p in ipairs(Players:GetPlayers())do
  local c=p.Character;local r=c and c:FindFirstChild('HumanoidRootPart');local h=c and c:FindFirstChildOfClass('Humanoid')
  if p:GetAttribute('NBInRound')and not p:GetAttribute('NBDowned')and r and h and h.Health>0 and workspace:GetServerTimeNow()>=(p:GetAttribute('NBInvulnerableUntil')or 0)then
   local d=(r.Position-position).Magnitude;if d<distance then closest=r;distance=d end
  end
 end
 local f=workspace:FindFirstChild('NBDecoys')
 if f then for _,c in ipairs(f:GetChildren())do local r=c:FindFirstChild('HumanoidRootPart');local h=c:FindFirstChildOfClass('Humanoid');if r and h and h.Health>0 then local d=(r.Position-position).Magnitude;if d<distance then closest=r;distance=d end end end end
 return closest,distance
end
local function startBots()
 local templates=Storage.NextbotTemplates:GetChildren();local points=markers('NextbotSpawns');if #points==0 then return end
 for i=#templates,2,-1 do local j=math.random(i);templates[i],templates[j]=templates[j],templates[i]end
 local count=package:GetAttribute('SpecialRound')=='double'and 6 or 3
 for i=1,count do
  local bot=templates[(i-1)%#templates+1]:Clone();local h=bot:FindFirstChildOfClass('Humanoid');local root=bot:FindFirstChild('HumanoidRootPart')
  if not h or not root then bot:Destroy();continue end
  local safest=points[1];local best=-1
  for _,point in ipairs(points)do
   local minimum=math.huge
   for _,p in ipairs(Players:GetPlayers())do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if p:GetAttribute('NBInRound')and r then minimum=math.min(minimum,(r.Position-point.Position).Magnitude)end end
   if minimum>best then best=minimum;safest=point end
  end
  bot:PivotTo(safest.CFrame+Vector3.new(0,4,0));bot.Parent=workspace;Collection:AddTag(bot,'NBNextbot')
  for _,part in ipairs(bot:GetDescendants())do
   if part:IsA('BasePart')then pcall(function()part:SetNetworkOwner(nil)end)
   elseif part:IsA('Sound')then part.SoundGroup=game:GetService('SoundService'):FindFirstChild('NB_NextbotVolume');part.RollOffMaxDistance=100;part.Volume=math.min(part.Volume,.7);if part.Name=='Idle'then part.Looped=true;part:Play()end end
  end
  h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;h.WalkSpeed=package:GetAttribute('SpecialRound')=='fast'and 37 or 30;h.JumpPower=50;h.MaxHealth=math.huge;h.Health=math.huge
  table.insert(bots,bot)
  task.spawn(function()
   local prev=root.Position;local stuck=0
   while bot.Parent and state.phase=='Round'do
    if workspace:GetServerTimeNow()<(bot:GetAttribute('NBStunnedUntil')or 0)then h:MoveTo(root.Position);task.wait(.2);continue end
    local target,distance=targetFrom(root.Position)
    if target then
     local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={bot}
     local hit=workspace:Raycast(root.Position,target.Position-root.Position,rp)
     local sight=not hit or hit.Instance:IsDescendantOf(target.Parent)
     if distance<4.5 and sight then
      local victim=Players:GetPlayerFromCharacter(target.Parent)
      if victim then Rescue.Down(victim);local voice=bot:FindFirstChild('Voiceline',true);if voice and voice:IsA('Sound')then voice:Play()end else local vh=target.Parent:FindFirstChildOfClass('Humanoid');if vh then vh.Health=0 end end
     elseif sight and math.abs(target.Position.Y-root.Position.Y)<5 then h:MoveTo(target.Position)
     else
      local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
      local ok=pcall(function()path:ComputeAsync(root.Position,target.Position)end)
      if not bot.Parent then break end
      local waypoints=ok and path.Status==Enum.PathStatus.Success and path:GetWaypoints()or {}
      local waypoint=waypoints[2]
      if waypoint then h.Jump=waypoint.Action==Enum.PathWaypointAction.Jump;h:MoveTo(waypoint.Position)else h:MoveTo(target.Position);h.Jump=true end
     end
     if (root.Position-prev).Magnitude<.5 then stuck+=1 else stuck=0 end
     if stuck>=24 or root.Position.Y<-80 then bot:PivotTo(safest.CFrame+Vector3.new(0,4,0));stuck=0 end
     prev=root.Position
    end
    task.wait(.45)
   end
  end)
 end
end
local function setup(p)
 setActive(p,false)
 local function spawned(char)
  local h=char:WaitForChild('Humanoid',10);char:WaitForChild('HumanoidRootPart',10);if not p.Parent then return end
  setActive(p,false);teleport(p,'LobbySpawns')
  if h then h.Died:Connect(function()setActive(p,false)end)end
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
 if action=='Vote'and type(arg)=='string'and table.find(mapNames,arg)and state.phase=='Intermission'then votes[p]=arg;syncVotes();return end
 if action=='Spectate'then if not p:GetAttribute('NBInRound')then p:SetAttribute('NBSpectating',not p:GetAttribute('NBSpectating'))end;return end
 if action~='Join'and action~='Lobby'then return end
 if action=='Lobby'then admitted[p]=nil;setActive(p,false);teleport(p,'LobbySpawns')
 else
  admitted[p]=true
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if state.phase=='Round'and h and h.Health>0 and not p:GetAttribute('NBInRound')and teleport(p,'RoundSpawns')then setActive(p,true)end
 end
 p:SetAttribute('NBQueued',admitted[p]==true)
end)
publish();local rewardAt=workspace:GetServerTimeNow()+30
while true do
 if state.phase=='Round'then Doors.Step()end
 local ready=next(admitted)~=nil and package:GetAttribute('MapReady')==true
 if State.tick(state,workspace:GetServerTimeNow(),ready)then
  clearBots();publish()
  if state.phase=='Round'then
   local counts={};for _,name in pairs(votes)do counts[name]=(counts[name]or 0)+1 end
   local winner=mapNames[mapIndex];local score=0
   for name,count in pairs(counts)do if count>score then score=count;winner=name end end
   if Maps.current~=winner then Maps.Load(winner)end
   table.clear(votes);syncVotes()
   local special=state.round%3==0 and ({'dark','fast','double'})[math.random(3)]or 'normal'
   package:SetAttribute('SpecialRound',special);Lighting.ClockTime=special=='dark'and 0 or 15
   rewardAt=workspace:GetServerTimeNow()+30
  else
   for _,p in ipairs(Players:GetPlayers())do
    if p:GetAttribute('NBInRound')and not p:GetAttribute('NBDowned')and workspace:GetServerTimeNow()-(joined[p]or math.huge)>=30 then task.spawn(Profiles.Reward,p,80,100,'survive')end
   end
  end
  for _,p in ipairs(Players:GetPlayers())do
   local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
   if state.phase=='Round'and admitted[p]and h and h.Health>0 and teleport(p,'RoundSpawns')then setActive(p,true)
   else setActive(p,false);teleport(p,'LobbySpawns')end
  end
  if state.phase=='Round'then startBots()else
   mapIndex=mapIndex%#mapNames+1;Maps.Load(mapNames[mapIndex]);Lighting.ClockTime=15
  end
 end
 if state.phase=='Round'and workspace:GetServerTimeNow()>=rewardAt then
  rewardAt+=30
  for _,p in ipairs(Players:GetPlayers())do if p:GetAttribute('NBInRound')and not p:GetAttribute('NBDowned')and workspace:GetServerTimeNow()-(joined[p]or math.huge)>=29 then task.spawn(Profiles.Reward,p,10,15)end end
 end
 task.wait(.2)
end
