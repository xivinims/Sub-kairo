local Players=game:GetService('Players')
local Storage=game:GetService('ServerStorage')
local Pathfinding=game:GetService('PathfindingService')
local Collection=game:GetService('CollectionService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local State=require(package.RoundState)
local Rescue=require(script.Parent.RescueService)
local Service={};local bots={}
local function markers(name)local f=workspace:FindFirstChild(name);return f and f:GetChildren()or {}end
function Service.Clear()for _,bot in ipairs(bots)do bot:Destroy()end;table.clear(bots)end
local function targetFrom(position)
 local closest,distance=nil,400
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
function Service.Start(state)
 Service.Clear()
 if not State.botsAllowed(state)then return 0 end
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
  local baseSpeed=bot:GetAttribute('Speed')or 22
  local maxSpeed=bot:GetAttribute('MaxSpeed')or (package:GetAttribute('SpecialRound')=='fast'and 37 or 30)
  local chaseTime=0
  local path=Pathfinding:CreatePath({AgentRadius=2.5,AgentHeight=5,AgentCanJump=true,AgentCanClimb=false,WaypointSpacing=4})
  h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;h.WalkSpeed=baseSpeed;h.JumpPower=50;h.MaxHealth=math.huge;h.Health=math.huge
  table.insert(bots,bot)
  task.spawn(function()
   local prev=root.Position;local stuck=0
   while bot.Parent and state.phase=='Round'do
    if workspace:GetServerTimeNow()<(bot:GetAttribute('NBStunnedUntil')or 0)then h:MoveTo(root.Position);task.wait(.2);continue end
    local target,distance=targetFrom(root.Position)
    if target then
     chaseTime+=.15;h.WalkSpeed=math.min(maxSpeed,baseSpeed+chaseTime*.6)
     local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={bot}
     local hit=workspace:Raycast(root.Position,target.Position-root.Position,rp)
     local sight=not hit or hit.Instance:IsDescendantOf(target.Parent)
     if distance<4.5 and sight then
      local victim=Players:GetPlayerFromCharacter(target.Parent)
      if victim then Rescue.Down(victim);local voice=bot:FindFirstChild('Voiceline',true);if voice and voice:IsA('Sound')then voice:Play()end else local vh=target.Parent:FindFirstChildOfClass('Humanoid');if vh then vh.Health=0 end end
     elseif sight and math.abs(target.Position.Y-root.Position.Y)<=4 then h:MoveTo(target.Position)
     else
      local ok=pcall(function()path:ComputeAsync(root.Position,target.Position)end)
      if not bot.Parent then break end
      local waypoints=ok and path.Status==Enum.PathStatus.Success and path:GetWaypoints()or {}
      local waypoint
      for _,candidate in ipairs(waypoints)do
       local delta=candidate.Position-root.Position
       if Vector3.new(delta.X,0,delta.Z).Magnitude>3 then waypoint=candidate;break end
      end
      if waypoint then h.Jump=waypoint.Action==Enum.PathWaypointAction.Jump;h:MoveTo(waypoint.Position)else h:MoveTo(target.Position);h.Jump=true end
     end
     if (root.Position-prev).Magnitude<.5 then stuck+=1 else stuck=0 end
     if stuck>=24 or root.Position.Y<-80 then bot:PivotTo(safest.CFrame+Vector3.new(0,4,0));stuck=0 end
     prev=root.Position
    else
     chaseTime=0;h.WalkSpeed=baseSpeed;h:MoveTo(root.Position)
    end
    task.wait(.15)
   end
  end)
 end
 return #bots
end
return Service
