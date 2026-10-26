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
 self.records[p]={id=Http:GenerateGUID(false),xp=0,points=0,savedXP=0,savedPoints=0,loaded=false,busy=false,ownedKillers={Jason=true},ownedDirty=false,lanternTier=0,lanternDirty=false}
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
 r.ownedKillers={Jason=true}
 if type(data.ownedKillers)=="table" then
  for name,owned in pairs(data.ownedKillers) do if owned==true and type(name)=="string" then r.ownedKillers[name]=true end end
 end
 p:SetAttribute("OwnedKillersJson",Http:JSONEncode(r.ownedKillers))
 r.lanternTier=math.clamp(integer(data.lanternTier),0,6)
 p:SetAttribute("LanternDurabilityTier",r.lanternTier)
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
function Profiles:ownsKiller(p,name)
 local r=self.records[p]
 return r and r.ownedKillers and r.ownedKillers[name]==true
end
function Profiles:buyKiller(p,name,price)
 local r=self.records[p] local stats=p:FindFirstChild("leaderstats")
 if not r or not r.loaded or not stats or not self.store then return false,"Aguarde seu progresso carregar." end
 if r.busy then return false,"Salvando progresso. Tente novamente em instantes." end
 if self:ownsKiller(p,name) then return true,"Você já tem esse perseguidor." end
 if type(price)~="number" or price<0 or price%1~=0 then return false,"Preço inválido." end
 r.busy=true
 if r.purchase and r.purchase.name~=name then r.busy=false return false,"Aguarde a confirmação da compra anterior." end
 r.purchase=r.purchase or {name=name,price=price,token=Http:GenerateGUID(false),xp=r.xp,points=r.points}
 local xp,points=r.purchase.xp,r.purchase.points
 local token=r.purchase.token
 local ok,data=self:retry(function()
  return self.store:UpdateAsync(tostring(p.UserId),function(old)
   old=type(old)=="table" and old or {}
   old.purchaseReceipts=type(old.purchaseReceipts)=="table" and old.purchaseReceipts or {}
   if old.purchaseReceipts[token] then return old end
   local owned=type(old.ownedKillers)=="table" and old.ownedKillers or {}
   local receipts=type(old.receipts)=="table" and old.receipts or {}
   local previous=type(receipts[r.id])=="table" and receipts[r.id] or {xp=0,points=0}
   local balance=math.max(0,integer(old.points)+points-(tonumber(previous.points) or 0))
   local cost=owned[name] and 0 or price
   if balance<cost then return old end
   old.xp=integer(old.xp)+math.max(0,xp-integer(previous.xp))
   old.points=balance-cost
   owned[name]=true owned.Jason=true old.ownedKillers=owned
   receipts[r.id]={xp=xp,points=points-cost,at=os.time()} old.receipts=receipts
   old.purchaseReceipts[token]={cost=cost,at=os.time()}
   local order={} for id,v in pairs(old.purchaseReceipts) do table.insert(order,{id=id,at=v.at or 0}) end
   table.sort(order,function(a,b) return a.at>b.at end)
   for i=25,#order do old.purchaseReceipts[order[i].id]=nil end
   old.schema=3 return old
  end)
 end)
 r.busy=false
 if not ok then return false,"Compra não confirmada. Tente novamente; não há cobrança duplicada." end
 local receipt=data and data.purchaseReceipts and data.purchaseReceipts[token]
 if not receipt then r.purchase=nil return false,"Moedas insuficientes." end
 r.purchase=nil
 r.points-=receipt.cost r.savedPoints=points-receipt.cost r.savedXP=xp
 r.ownedKillers=data.ownedKillers or {Jason=true}
 stats.Pontos.Value=math.max(0,integer(data.points)+(r.points-r.savedPoints))
 stats.XP.Value=integer(data.xp)+math.max(0,r.xp-r.savedXP)
 stats["Nível"].Value=Profiles.level(stats.XP.Value)
 p:SetAttribute("OwnedKillersJson",Http:JSONEncode(r.ownedKillers))
 return true,name.." desbloqueado!"
end


function Profiles:lanternTier(p)
 local r=self.records[p]
 return r and r.lanternTier or 0
end

function Profiles:buyLanternUpgrade(p,price,maxTier)
 local r=self.records[p]
 local stats=p:FindFirstChild("leaderstats")
 maxTier=math.clamp(integer(maxTier),0,20)
 if not r or not r.loaded or not stats then return false,"Aguarde seu progresso carregar." end
 if r.busy then return false,"Salvando progresso. Tente novamente em instantes." end
 local tier=math.clamp(integer(r.lanternTier),0,maxTier)
 if tier>=maxTier then return true,"Lanterna já está no MAX." end
 if type(price)~="number" or price<0 or price%1~=0 then return false,"Preço inválido." end
 if stats.Pontos.Value<price then return false,"Pontos insuficientes." end
 self:points(p,-price)
 r.lanternTier=tier+1
 r.lanternDirty=true
 p:SetAttribute("LanternDurabilityTier",r.lanternTier)
 return true,"Durabilidade da lanterna melhorada."
end

function Profiles:save(p)
 local r=self.records[p]
 if not self.store or not r or not r.loaded then return false end
 if r.busy then r.pending=true return false end
 if r.purchase then return self:buyKiller(p,r.purchase.name,r.purchase.price) end
 if r.xp==r.savedXP and r.points==r.savedPoints and not r.ownedDirty and not r.lanternDirty then return true end
 r.busy=true
 local xp,points=r.xp,r.points
 local ownedSnapshot={} for name,owned in pairs(r.ownedKillers or {}) do if owned then ownedSnapshot[name]=true end end
 local lanternTier=math.clamp(integer(r.lanternTier),0,6)
 local timestamp=os.time()
 local ok=self:retry(function()
  return self.store:UpdateAsync(tostring(p.UserId),function(old)
   old=type(old)=="table" and old or {}
   local receipts=type(old.receipts)=="table" and old.receipts or {}
   local previous=type(receipts[r.id])=="table" and receipts[r.id] or {xp=0,points=0}
   old.xp=integer(old.xp)+math.max(0,xp-integer(previous.xp))
   old.points=math.max(0,integer(old.points)+points-(tonumber(previous.points) or 0))
   old.ownedKillers=type(old.ownedKillers)=="table" and old.ownedKillers or {}
   old.ownedKillers.Jason=true
   for name,owned in pairs(ownedSnapshot) do if owned then old.ownedKillers[name]=true end end
   old.lanternTier=math.max(integer(old.lanternTier),lanternTier)
   receipts[r.id]={xp=xp,points=points,at=timestamp}
   local keys={} for id,v in pairs(receipts) do if id~=r.id then table.insert(keys,{id=id,at=type(v)=="table" and (v.at or 0) or 0}) end end
   table.sort(keys,function(a,b) return a.at>b.at end)
   for i=12,#keys do receipts[keys[i].id]=nil end
   old.receipts=receipts old.schema=2
   return old
  end)
 end)
 r.busy=false
 if ok then r.savedXP=xp r.savedPoints=points r.ownedDirty=false r.lanternDirty=false end
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

