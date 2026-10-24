-- Session deltas and receipts make a retried write idempotent; failed reads never save defaults.
local Profiles={}
Profiles.__index=Profiles
local Http=game:GetService("HttpService")
local function integer(value)
 local n=tonumber(value)
 if not n or n~=n or math.abs(n)==math.huge then return 0 end
 return math.clamp(math.floor(n),0,2000000000)
end
function Profiles.level(xp)
 return math.clamp(math.floor((-35+math.sqrt(1225+60*integer(xp)))/30)+1,1,1000)
end
function Profiles.new(store,options)
 return setmetatable({store=store,records={},options=options or {}},Profiles)
end
function Profiles:attach(p)
 self.records[p]={id=Http:GenerateGUID(false),xp=0,points=0,savedXP=0,savedPoints=0,loaded=false,busy=false}
 p:SetAttribute("ProfileLoaded",false)
end
function Profiles:retry(fn)
 local last
 for attempt=1,3 do
  local ok,value=pcall(fn)
  if ok then return true,value end
  last=value
  if attempt<3 then (self.options.wait or task.wait)(attempt) end
 end
 return false,last
end
function Profiles:load(p)
 local r=self.records[p]
 if not r or not self.store then return false end
 local ok,data=self:retry(function() return self.store:GetAsync(tostring(p.UserId)) end)
 if not ok or (data~=nil and type(data)~="table") or not p.Parent or self.records[p]~=r then return false end
 data=data or {}
 local stats=p:FindFirstChild("leaderstats") if not stats then return false end
 stats.XP.Value=integer(data.xp)+r.xp
 stats.Pontos.Value=math.max(0,integer(data.points)+r.points)
 stats["Nível"].Value=Profiles.level(stats.XP.Value)
 r.loaded=true p:SetAttribute("ProfileLoaded",true)
 return true
end
function Profiles:points(p,delta)
 local stats=p:FindFirstChild("leaderstats") local r=self.records[p]
 if not stats or not r then return end
 stats.Pontos.Value+=delta r.points+=delta
end
function Profiles:awardXP(p,delta)
 local stats=p:FindFirstChild("leaderstats") local r=self.records[p]
 if not stats or not r then return end
 delta=integer(delta) stats.XP.Value+=delta r.xp+=delta
 stats["Nível"].Value=Profiles.level(stats.XP.Value)
end
function Profiles:save(p)
 local r=self.records[p]
 if not self.store or not r or not r.loaded then return false end
 if r.busy then r.pending=true return false end
 if r.xp==r.savedXP and r.points==r.savedPoints then return true end
 r.busy=true
 local xp,points=r.xp,r.points
 local timestamp=os.time()
 local ok=self:retry(function()
  return self.store:UpdateAsync(tostring(p.UserId),function(old)
   old=type(old)=="table" and old or {}
   local receipts=type(old.receipts)=="table" and old.receipts or {}
   local previous=type(receipts[r.id])=="table" and receipts[r.id] or {xp=0,points=0}
   old.xp=integer(old.xp)+math.max(0,xp-integer(previous.xp))
   old.points=math.max(0,integer(old.points)+points-(tonumber(previous.points) or 0))
   receipts[r.id]={xp=xp,points=points,at=timestamp}
   local keys={} for id,v in pairs(receipts) do if id~=r.id then table.insert(keys,{id=id,at=type(v)=="table" and (v.at or 0) or 0}) end end
   table.sort(keys,function(a,b) return a.at>b.at end)
   for i=12,#keys do receipts[keys[i].id]=nil end
   old.receipts=receipts old.schema=2
   return old
  end)
 end)
 r.busy=false
 if ok then r.savedXP=xp r.savedPoints=points end
 local again=r.pending r.pending=false
 if again and (r.xp~=xp or r.points~=points) then return self:save(p) end
 return ok
end
function Profiles:flush(p,timeout)
 local deadline=os.clock()+(timeout or 20)
 local r=self.records[p]
 while r and r.busy and os.clock()<deadline do task.wait(.05) end
 return self:save(p)
end
return Profiles
