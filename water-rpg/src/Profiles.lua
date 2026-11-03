local DSS=game:GetService('DataStoreService')
local Http=game:GetService('HttpService')
local Rules=require(game.ReplicatedStorage.WaterRPG.Rules)
local P={}
function P.start()
 local store=DSS:GetDataStore('WaterCastle_RPG_v1')
 local sessions={};local api={}
 local function sanitize(old)
  old=type(old)=='table' and old or {}
  local items=type(old.items)=='table' and old.items or {}
  return {coins=math.clamp(tonumber(old.coins) or 20,0,1e8),xp=math.clamp(tonumber(old.xp) or 0,0,1e8),quest=math.clamp(tonumber(old.quest) or 0,0,2),items={Potion=math.clamp(tonumber(items.Potion) or 0,0,10),Lantern=math.clamp(tonumber(items.Lantern) or 0,0,1)}}
 end
 function api.load(p)
  local id=Http:GenerateGUID(false);local now=os.time()
  local ok,data=pcall(function()
   return store:UpdateAsync('u'..p.UserId,function(old)
    old=type(old)=='table' and old or {}
    if old.lease and old.lease~=id and (tonumber(old.leaseUntil) or 0)>now then return nil end
    local value=sanitize(old);value.lease=id;value.leaseUntil=now+180;return value
   end)
  end)
  local saved=ok and data and data.lease==id
  if not p.Parent then
   if saved then pcall(function() store:UpdateAsync('u'..p.UserId,function(current) if current and current.lease==id then current.lease=nil;current.leaseUntil=0;return current end;return nil end) end) end
   return
  end
  sessions[p]={id=id,data=sanitize(saved and data or nil),saved=saved,busy=false,dirty=false}
  p:SetAttribute('ProfileReady',true);p:SetAttribute('PersistentProfile',saved==true)
  api.publish(p)
 end
 function api.get(p) local s=sessions[p];return s and s.data end
 function api.publish(p)
  local d=api.get(p);if not d then return end
  p:SetAttribute('Coins',d.coins);p:SetAttribute('XP',d.xp);p:SetAttribute('Level',Rules.level(d.xp));p:SetAttribute('QuestStage',d.quest)
  p:SetAttribute('Potions',d.items.Potion);p:SetAttribute('LanternOwned',d.items.Lantern>0)
 end
 function api.change(p,callback)
  local s=sessions[p];if not s then return false end
  callback(s.data);s.dirty=true;api.publish(p);return true
 end
 function api.save(p,release)
  local s=sessions[p];if not s or not s.saved or s.busy then return end
  s.busy=true
  local snapshot=sanitize(s.data)
  local ok,written=pcall(function()
   return store:UpdateAsync('u'..p.UserId,function(old)
    if type(old)~='table' or old.lease~=s.id then return nil end
    local nextData=sanitize(snapshot);nextData.lease=not release and s.id or nil;nextData.leaseUntil=not release and os.time()+180 or 0
    return nextData
   end)
  end)
  s.busy=false
  if ok and written then s.dirty=false elseif not release then s.saved=false;p:SetAttribute('PersistentProfile',false) end
 end
 function api.remove(p) api.save(p,true);sessions[p]=nil end
 return api
end
return P
