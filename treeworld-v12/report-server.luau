local Players=game:GetService('Players')
local Text=game:GetService('TextService')
local Http=game:GetService('HttpService')
local Chat=game:GetService('TextChatService')
local Data=game:GetService('DataStoreService'):GetDataStore('OveryardReports_v1')
local runtime=game.ReplicatedStorage:WaitForChild('LivingForest')
local event=runtime.ReportEvent
local Movement=require(script.Parent.MovementService);Movement.start()
local history={};local reportTime={};local warningTime={};local seen={}
local function filtered(text,userId)
 local ok,value=pcall(function()return Text:FilterStringAsync(text,userId,Enum.TextFilterContext.PublicChat):GetNonChatStringForBroadcastAsync()end)
 return ok and value or nil
end
-- Only the public RBXGeneral channel is observed. Whispers and team chat never enter this buffer.
task.spawn(function()
 local channels=Chat:WaitForChild('TextChannels',30);local channel=channels and channels:WaitForChild('RBXGeneral',30)
 if not channel then return end
 channel.ShouldDeliverCallback=function(message)
  local source=message.TextSource;local id=message.MessageId
  if source and id and not seen[id]then
   seen[id]=os.clock();local uid=source.UserId;local now=os.clock()
   local h=history[uid]or{messages={},repeats=0};history[uid]=h
   -- The original text is held only while filtering, never persisted.
   local normalized=string.lower(message.Text):gsub('%s+',' ')
   local fingerprint=2166136261
   for i=1,#normalized do fingerprint=bit32.bxor(fingerprint,string.byte(normalized,i));fingerprint=(fingerprint*16777619)%4294967296 end
   h.repeats=h.fingerprint==fingerprint and now-(h.last or 0)<4 and h.repeats+1 or 1
   h.fingerprint=fingerprint;h.last=now
   if h.repeats>=6 then h.spam=now end
   task.spawn(function()
    local clean=filtered(message.Text,uid);if clean and history[uid]==h then
     table.insert(h.messages,{time=now,text=clean});while #h.messages>20 do table.remove(h.messages,1)end
    end
   end)
  end
  return true
 end
end)
local valid={speech=true,harassment=true,movement=true,other=true}
event.OnServerEvent:Connect(function(sender,targetId,reasons,details)
 local now=os.clock()
 if now-(reportTime[sender]or -100)<45 then event:FireClient(sender,'wait');return end
 reportTime[sender]=now -- Before every yielding API; remote spam cannot create filter/store work.
 local npc=workspace.OveryardPhotoWorld:FindFirstChild('Caio')
 local root=sender.Character and sender.Character:FindFirstChild('HumanoidRootPart')
 if not npc or not root or(root.Position-npc.HumanoidRootPart.Position).Magnitude>28 then event:FireClient(sender,'far');return end
 if type(targetId)~='number'or targetId%1~=0 or type(reasons)~='table'or type(details)~='string'or #details>700 or not utf8.len(details)then event:FireClient(sender,'invalid');return end
 local target=Players:GetPlayerByUserId(targetId)
 if not target or target==sender then event:FireClient(sender,'missing');return end
 local selected={};local count=0
 for _,reason in ipairs(reasons)do if not valid[reason]or selected[reason]then event:FireClient(sender,'invalid');return end;selected[reason]=true;count+=1;if count>4 then event:FireClient(sender,'invalid');return end end
 if count<1 or selected.other and #details:gsub('%s','')<8 then event:FireClient(sender,'details');return end
 local clean=#details>0 and filtered(details,sender.UserId)or ''
 if not clean then event:FireClient(sender,'retry');return end
 local actions=Movement.evidence(target);local h=history[targetId];local messages={};local strong=0
 for _,a in ipairs(actions)do if a.age<90 and(a.kind=='speed'or a.kind=='flight')then strong+=1 end end
 if h then for _,m in ipairs(h.messages)do if now-m.time<600 then table.insert(messages,{age=math.floor(now-m.time),text=m.text})end end end
 local confirmed=selected.movement and strong>=3 or selected.speech and h and h.spam and now-h.spam<60
 local record={id=Http:GenerateGUID(false),created=os.time(),expires=os.time()+7*86400,reporter=sender.UserId,target=targetId,
  reasons=reasons,details=clean,actions=actions,publicChat=messages,status=confirmed and'evidence_warning'or'pending_review'}
 local key=os.date('!%Y%m%d')..':'..string.sub(game.JobId,1,18)
 local ok=pcall(function()Data:UpdateAsync(key,function(old)
  local list=type(old)=='table'and old or{}
  for _,r in ipairs(list)do if r.id==record.id then return list end end
  if #list>=80 then error('Report bucket full; retry on a new session')end
  table.insert(list,record);return list
 end)end)
 if not ok then event:FireClient(sender,'retry');return end
 if confirmed and now-(warningTime[targetId]or -1000)>120 then
  warningTime[targetId]=now;runtime.SafetyEvent:FireClient(target,'warning',{code='conduct'})
 end
 event:FireClient(sender,'sent') -- Never reveal the reporter or an enforcement outcome to other players.
end)
Players.PlayerRemoving:Connect(function(p)history[p.UserId]=nil;reportTime[p]=nil;warningTime[p.UserId]=nil end)
task.spawn(function()
 while script.Parent do
  task.wait(60);local now=os.clock()
  for id,time in pairs(seen)do if now-time>60 then seen[id]=nil end end
  for _,h in pairs(history)do for i=#h.messages,1,-1 do if now-h.messages[i].time>600 then table.remove(h.messages,i)end end end
 end
end)
-- Bounded cleanup of expired daily buckets; failures are retried next server session.
task.spawn(function()
 task.wait(30)
 pcall(function()
  local pages=Data:ListKeysAsync('',30);local checked=0;local cutoff=os.date('!%Y%m%d',os.time()-7*86400)
  repeat
   for _,key in ipairs(pages:GetCurrentPage())do checked+=1;if string.sub(key.KeyName,1,8)<cutoff then Data:RemoveAsync(key.KeyName)end end
   if pages.IsFinished or checked>=300 then break end;pages:AdvanceToNextPageAsync()
  until false
 end)
end)
