local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local R=require(script.Parent.MovementRules)
local event=game.ReplicatedStorage:WaitForChild('LivingForest'):WaitForChild('SafetyEvent')
local M={};local states={};local running=false
local function reset(s,pos,now)
 s.last=pos;s.window=now;s.distance=0;s.air=0;s.float=0;s.changed=now
end
function M.authorize(player,seconds)
 local s=states[player];if s then s.grace=math.max(s.grace,os.clock()+math.clamp(seconds or 3,1,15)) end
end
function M.teleport(player,cf)
 M.authorize(player,5);local c=player.Character;if c then c:PivotTo(cf) end
end
function M.evidence(player)
 local result={};local s=states[player];if not s then return result end
 for _,e in ipairs(s.events)do if os.clock()-e.time<R.ReportTTL then table.insert(result,{kind=e.kind,age=math.floor(os.clock()-e.time)}) end end
 return result
end
function M.start()
 if running then return end;running=true
 local function join(p)
  local now=os.clock();local s={grace=now+12,stable=now,events={},ping=0,jitter=0,lastWarning=-100,network=0};states[p]=s
  p.CharacterAdded:Connect(function()s.grace=os.clock()+12;s.last=nil;s.safe=nil;s.events={};s.firstWarning=nil end)
 end
 Players.PlayerAdded:Connect(join);for _,p in ipairs(Players:GetPlayers())do join(p) end
 Players.PlayerRemoving:Connect(function(p)states[p]=nil end)
 local accumulator=0
 Run.Heartbeat:Connect(function(dt)
  accumulator+=dt;if accumulator<.35 then return end;local elapsed=accumulator;accumulator=0;local now=os.clock()
  for p,s in pairs(states)do
   local char=p.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
   if not root or not hum then continue end
   local ping=p:GetNetworkPing();s.jitter=s.jitter*.8+math.abs(ping-s.ping)*.2;s.ping=ping
   local quality=R.network(ping,s.jitter);local bad=quality=='red' or elapsed>1.4
   if bad then s.grace=now+5;s.stable=now;s.events={};s.firstWarning=nil end
   if now-s.network>1.5 then s.network=now;event:FireClient(p,'network',{quality=quality,ms=math.floor(ping*1000+.5)}) end
   if not s.last then reset(s,root.Position,now);continue end
   local step=(root.Position-s.last).Magnitude;local gap=now-s.changed
   s.distance+=Vector2.new(root.Position.X-s.last.X,root.Position.Z-s.last.Z).Magnitude
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char}
   local hit=workspace:Raycast(root.Position,Vector3.new(0,-500,0),params)
   local ground=hit and (root.Position-hit.Position).Magnitude or 500
   local grounded=ground<hum.HipHeight+root.Size.Y/2+1.8
   local swimming=hit and hit.Material==Enum.Material.Water and ground<5
   local velocity=root.AssemblyLinearVelocity
   if grounded or swimming then s.air=0;s.float=0 else
    s.air+=elapsed
    if velocity.Y>=-8 then s.float+=elapsed else s.float=0 end
   end
   local exempt=hum.Health<=0 or root.Anchored or hum.SeatPart~=nil or hum:GetState()==Enum.HumanoidStateType.Climbing
   local kind=R.evaluate({grace=now<s.grace,badNetwork=bad,serverStall=elapsed>1.4,seated=hum.SeatPart~=nil,
    swimming=swimming,climbing=hum:GetState()==Enum.HumanoidStateType.Climbing,dead=exempt,
    allowedSpeed=math.clamp(hum.WalkSpeed,0,40),ping=ping,jumpDistance=step,replicationGap=gap,
    windowTime=now-s.window,planarDistance=s.distance,airTime=s.air,floatingTime=s.float,groundDistance=ground})
   if kind and now-s.lastWarning>=4 then
    s.lastWarning=now;s.firstWarning=s.firstWarning or now;table.insert(s.events,{time=now,kind=kind})
    while #s.events>40 do table.remove(s.events,1) end
    event:FireClient(p,'warning',{code=kind})
    if s.safe then char:PivotTo(s.safe);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
    s.grace=now+1.5;reset(s,root.Position,now)
    if R.shouldKick(s.events,now,s.firstWarning,now-s.stable)then
     p:Kick('Movimento anormal repetido após os avisos. Desative modificações de movimento e entre novamente.')
    end
   elseif grounded and not exempt and now>=s.grace and not kind and step<25 then s.safe=char:GetPivot() end
   if now<s.grace or exempt or swimming then reset(s,root.Position,now)
   elseif now-s.window>=R.Window then s.window=now;s.distance=0 end
   if step>.1 then s.changed=now end;s.last=root.Position
  end
 end)
end
return M
