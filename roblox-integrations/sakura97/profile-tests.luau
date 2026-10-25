local Profiles=require(game.ServerScriptService.ProfileService)
local host=Instance.new("Folder")
local values={xp=200,points=35,singer=false}
local writes=0 local failRead=false local ambiguous=false
local store={}
function store:GetAsync() if failRead then error("offline") end return table.clone(values) end
function store:UpdateAsync(_,fn)
 writes+=1 values=fn(values)
 if ambiguous then ambiguous=false error("response lost after successful write") end
 return values
end
local function player(id)
 local folder=Instance.new("Folder",host) local stats=Instance.new("Folder",folder) stats.Name="leaderstats"
 for _,name in ipairs({"Pontos","XP","Nível"}) do local v=Instance.new("IntValue",stats) v.Name=name end
 local p={UserId=id,Parent=host,attrs={}}
 function p:SetAttribute(n,v) self.attrs[n]=v end
 function p:GetAttribute(n) return self.attrs[n] end
 function p:FindFirstChild(n) return folder:FindFirstChild(n) end
 return p,stats
end
local p,stats=player(991)
local svc=Profiles.new(store,{wait=function() end}) svc:attach(p)
svc:awardXP(p,10) svc:points(p,3)
assert(svc:load(p) and stats.XP.Value==210 and stats.Pontos.Value==38,"Load overwrote session earnings")
svc:points(p,-20)
ambiguous=true assert(svc:save(p),"Retry did not recover ambiguous save")
assert(values.xp==210 and values.points==18 and values.singer==false,"Retry duplicated earnings or changed legacy singer data")
assert(svc:save(p) and values.xp==210 and values.points==18,"Repeated save was not idempotent")
assert(svc:ownsKiller(p,"Jason"),"Jason must be owned by default")
local bought,msg=svc:buyKiller(p,"JohnDoe",10)
assert(bought and svc:ownsKiller(p,"JohnDoe") and stats.Pontos.Value==8,"Killer purchase did not deduct points/ownership")
assert(svc:save(p) and values.points==8 and values.ownedKillers and values.ownedKillers.JohnDoe==true,"Killer ownership did not persist")
assert(svc:save(p) and values.points==8,"Repeated killer ownership save was not idempotent")
local q,other=player(992) local otherSvc=Profiles.new(store,{wait=function() end}) otherSvc:attach(q) assert(otherSvc:load(q))
otherSvc:awardXP(q,7) assert(otherSvc:save(q))
svc:awardXP(p,5) assert(svc:save(p) and values.xp==222,"Concurrent session lost XP")
local r=player(993) local failed=Profiles.new(store,{wait=function() end}) failed:attach(r) failRead=true
assert(not failed:load(r)) local before=writes failed:awardXP(r,100)
assert(not failed:save(r) and writes==before,"Failed load wrote default profile")
assert(Profiles.level(0)==1 and Profiles.level(49)==1 and Profiles.level(50)==2 and Profiles.level(130)==3 and Profiles.level(1e9)==1000,"Level thresholds incorrect")
host:Destroy()
return {ok=true,killerOwnership=true,killerPurchaseIdempotent=true,pointsPersist=true,readFailureGuard=true,idempotentRetries=true,concurrentSessionXP=true,loadPreservesEarnings=true,levelCap=true}
