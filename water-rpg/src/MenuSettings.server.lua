local Players=game:GetService('Players')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('WaterRPG')
local Http=game:GetService('HttpService')
local Schema=require(Shared:WaitForChild('MenuSettingsSchema'))
local Remote=Shared:WaitForChild('MenuSettingsEvent')
local Store=game:GetService('DataStoreService'):GetDataStore('WaterCastle_MenuSettings_v1')
local sessions={}
local function publish(p,s)
 if p.Parent then p:SetAttribute('MenuSettingsJSON',Http:JSONEncode(s.values));p:SetAttribute('MenuSettingsSaved',s.readable) end
end
local function save(p,s)
 if not s.readable or not next(s.pending) or s.busy then return end
 s.busy=true
 local patch=table.clone(s.pending);s.pending={}
 local ok=pcall(function()
  Store:UpdateAsync('u'..p.UserId,function(old)
   local values=Schema.clean(old)
   for key,value in pairs(patch) do values[key]=value end
   return values
  end)
 end)
 if not ok then for key,value in pairs(patch) do if s.pending[key]==nil then s.pending[key]=value end end end
 s.busy=false
 if p.Parent then p:SetAttribute('MenuSettingsSaved',ok) end
end
local function added(p)
 if sessions[p] then return end
 local s={values=Schema.clean(nil),pending={},readable=false,busy=false,last=0};sessions[p]=s
 local ok,saved=pcall(function() return Store:GetAsync('u'..p.UserId) end)
 if sessions[p]~=s then return end
 if ok then
  s.values=Schema.clean(saved);s.readable=true
  for key,value in pairs(s.pending) do s.values[key]=value end
 end
 publish(p,s)
end
Players.PlayerAdded:Connect(added)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
Remote.OnServerEvent:Connect(function(p,payload)
 local s=sessions[p];if not s or os.clock()-s.last<.25 then return end
 s.last=os.clock()
 for key,value in pairs(Schema.patch(payload)) do s.values[key]=value;s.pending[key]=value end
 publish(p,s)
end)
Players.PlayerRemoving:Connect(function(p)
 local s=sessions[p]
 if s then
  local deadline=os.clock()+10
  while s.busy and os.clock()<deadline do task.wait(.1) end
  save(p,s)
 end
 sessions[p]=nil
end)
task.spawn(function()
 while true do task.wait(5);for p,s in pairs(sessions) do task.spawn(save,p,s) end end
end)
game:BindToClose(function()
 local pending=0
 for p,s in pairs(sessions) do
  pending+=1
  task.spawn(function()
   local deadline=os.clock()+10
   while s.busy and os.clock()<deadline do task.wait(.1) end
   save(p,s);pending-=1
  end)
 end
 local deadline=os.clock()+20
 repeat task.wait(.1) until pending==0 or os.clock()>deadline
end)
