local Controller={}
local Players=game:GetService("Players")local Run=game:GetService("RunService")
function Controller.shouldGreet(distance,elapsed,dwell,entered)
 return distance<=13 and elapsed>=35 and(entered or dwell>=1.4)
end
function Controller.start(runtime,world)
 local npc=assert(world.OwnerNPC)local root=npc.HumanoidRootPart local hum=npc.Humanoid
 local animator=hum:FindFirstChildOfClass("Animator")or Instance.new("Animator",hum)
 local animation=npc:WaitForChild("CatBath")local track=animator:LoadAnimation(animation)
 track.Priority=Enum.AnimationPriority.Action track.Looped=true track:Play(.3,1,.85)
 local deadline=os.clock()+8 repeat task.wait(.1)until track.Length>0 or os.clock()>deadline
 assert(track.Length>0,"Cat Bath playback failed to load")npc:SetAttribute("CatBathTrackLength",track.Length)
 npc:SetAttribute("EmotePlaying",true)
 local previous={}local nearSince={}local spoken={}local globalLast=-math.huge local index=0 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.25 then return end elapsed=0 local now=workspace:GetServerTimeNow()
  for _,p in ipairs(Players:GetPlayers())do
   local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
   local distance=h and h.Health>0 and r and(r.Position-root.Position).Magnitude or math.huge
   if distance<13 then
    nearSince[p]=nearSince[p]or now
    local entered=not previous[p]
    if Controller.shouldGreet(distance,now-(spoken[p]or -math.huge),now-nearSince[p],entered)and now-globalLast>12 then
     spoken[p]=now globalLast=now index+=1
     local sound=index%4==0 and npc.Head.YayVoice or npc.Head.HiVoice sound.PlaybackSpeed=index%2==0 and 1.035 or .98 sound:Play()
    end
    previous[p]=true
   elseif distance>19 then previous[p]=nil nearSince[p]=nil end
  end
 end)
 Players.PlayerRemoving:Connect(function(p)previous[p]=nil nearSince[p]=nil spoken[p]=nil end)
 return{track=track}
end
return Controller
