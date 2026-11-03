local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local Profiles=require(script.Parent.ProfileService)
local catalog=require(package:WaitForChild('EmoteCatalog'))
local remote=package:WaitForChild('Emotes')
local items={};for _,item in ipairs(catalog)do items[item.id]=item end
local last={}
local function setup(p)p.CharacterAdded:Connect(function()p:SetAttribute('NBPlayingEmote','')end)end
Players.PlayerAdded:Connect(setup);for _,p in ipairs(Players:GetPlayers())do setup(p)end
Players.PlayerRemoving:Connect(function(p)last[p]=nil end)
remote.OnServerEvent:Connect(function(p,action,id,slot)
 if type(action)~='string'or type(id)~='string'or #id>80 then return end
 if action=='Stop'then p:SetAttribute('NBPlayingEmote','');return end
 local item=items[id];if not item or os.clock()-(last[p]or -10)<.3 then return end;last[p]=os.clock()
 local profile=Profiles.Get(p);if not profile then remote:FireClient(p,'unavailable');return end
 if action=='Play'then
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if p:GetAttribute('NBDowned')or not profile.owned[id]or not h or h.Health<=0 or h.RigType~=Enum.HumanoidRigType.R6 then return end
  local equipped=false;for _,v in pairs(profile.slots)do if v==id then equipped=true end end
  if not equipped then return end
  p:SetAttribute('NBEmoteStarted',workspace:GetServerTimeNow());p:SetAttribute('NBPlayingEmote',id);return
 end
 if action~='Buy'and action~='Equip'then return end
 if action=='Equip'and (type(slot)~='number'or slot%1~=0 or slot<1 or slot>6)then return end
 local _,status=Profiles.Mutate(p,function(v)
  if action=='Buy'then
   if v.owned[id]then return false,'owned'end
   if v.coins<item.price then return false,'funds'end
   v.coins-=item.price;v.owned[id]=true;return true,'purchased'
  end
  if not v.owned[id]then return false,'invalid'end
  for key,value in pairs(v.slots)do if value==id then v.slots[key]=nil end end
  v.slots[tostring(slot)]=id;return true,'equipped'
 end)
 remote:FireClient(p,status)
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 for _,p in ipairs(Players:GetPlayers())do
  if (p:GetAttribute('NBPlayingEmote')or '')~=''then
   local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');local item=items[p:GetAttribute('NBPlayingEmote')]
   local finished=item and not item.loop and workspace:GetServerTimeNow()-(p:GetAttribute('NBEmoteStarted')or 0)>=item.duration
   if finished or p:GetAttribute('NBDowned')or not h or h.Health<=0 or h.MoveDirection.Magnitude>.1 or h.Jump then p:SetAttribute('NBPlayingEmote','')end
  end
 end
end)
