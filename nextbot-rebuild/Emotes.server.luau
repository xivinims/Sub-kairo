local Players=game:GetService('Players')
local Data=game:GetService('DataStoreService'):GetDataStore('NextbotEmotes_v1')
local Run=game:GetService('RunService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local policy=require(package:WaitForChild('EmotePolicy'))
local catalog=require(package:WaitForChild('EmoteCatalog'))
local remote=package:WaitForChild('Emotes')
local items={};for _,item in ipairs(catalog) do items[item.id]=item end
local profiles,busy,last={},{},{}
local function sync(p,profile)
 p:SetAttribute('NBCoins',profile.coins)
 for id in pairs(items) do p:SetAttribute('NBEmoteOwned_'..id,profile.owned[id]==true) end
 for i=1,6 do p:SetAttribute('NBEmoteSlot'..i,profile.slots[tostring(i)] or '')end
end
local function setup(p)
 local ok,value=pcall(function()return Data:GetAsync(tostring(p.UserId))end)
 if not p.Parent then return end
 if ok then profiles[p]=policy.normalize(value);sync(p,profiles[p])end
 p:SetAttribute('NBEmoteDataReady',ok)
 p.CharacterAdded:Connect(function()p:SetAttribute('NBPlayingEmote','')end)
end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers()) do task.spawn(setup,p)end
Players.PlayerRemoving:Connect(function(p)profiles[p]=nil;last[p]=nil end)
remote.OnServerEvent:Connect(function(p,action,id,slot)
 if type(action)~='string' or type(id)~='string' or #id>80 then return end
 if action=='Stop' then p:SetAttribute('NBPlayingEmote','');return end
 local item=items[id];if not item then return end
 if os.clock()-(last[p] or -10)<.3 or busy[p] then return end;last[p]=os.clock()
 local profile=profiles[p];if not profile then remote:FireClient(p,'unavailable');return end
 if action=='Play' then
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if not profile.owned[id] or not h or h.Health<=0 or h.RigType~=Enum.HumanoidRigType.R6 then return end
  local equipped=false;for _,v in pairs(profile.slots)do if v==id then equipped=true end end
  if not equipped then return end
  p:SetAttribute('NBEmoteStarted',workspace:GetServerTimeNow());p:SetAttribute('NBPlayingEmote',id);return
 end
 if action~='Buy' and action~='Equip' then return end
 if action=='Equip' and (type(slot)~='number' or slot%1~=0 or slot<1 or slot>6) then return end
 busy[p]=true;local status
 local ok,saved=pcall(function()
  return Data:UpdateAsync(tostring(p.UserId),function(old)
   local result
   if action=='Buy' then result,status=policy.buy(old,id,item.price)
   else result,status=policy.equip(old,id,slot)end
   return result
  end)
 end)
 busy[p]=nil
 if not p.Parent then return end
 if ok and saved then profiles[p]=policy.normalize(saved);sync(p,profiles[p]);remote:FireClient(p,status)
 else remote:FireClient(p,'save_failed')end
end)
-- Movement cancels emotes for every observer, not just the initiating client.
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 for _,p in ipairs(Players:GetPlayers()) do
  if (p:GetAttribute('NBPlayingEmote') or '')~='' then
   local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
   local item=items[p:GetAttribute('NBPlayingEmote')]
   local finished=item and not item.loop and workspace:GetServerTimeNow()-(p:GetAttribute('NBEmoteStarted') or 0)>=item.duration
   if finished or not h or h.Health<=0 or h.MoveDirection.Magnitude>.1 or h.Jump then p:SetAttribute('NBPlayingEmote','')end
  end
 end
end)
