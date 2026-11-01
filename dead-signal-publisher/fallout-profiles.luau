local DataStoreService=game:GetService('DataStoreService')
local Http=game:GetService('HttpService')
local store=DataStoreService:GetDataStore('FalloutProfiles_v1')
local Profiles={cache={}}
local session=game.JobId~='' and game.JobId or Http:GenerateGUID(false)
local function fresh()
 return {xp=0,coins=0,owned={compact=true,knife=true,medkit=true},loadout={gun='compact',melee='knife',heal='medkit'}}
end
function Profiles.Load(player)
 local result
 for attempt=1,4 do
  local ok=pcall(function()
   result=store:UpdateAsync('u'..player.UserId,function(old)
    old=type(old)=='table' and old or fresh()
    if old.lock and old.lock.session~=session and old.lock.untilTime>os.time() then return nil end
    old.lock={session=session,untilTime=os.time()+150}
    old.owned=old.owned or {};old.owned.compact=true;old.owned.knife=true;old.owned.medkit=true
    old.loadout=old.loadout or fresh().loadout
    return old
   end)
  end)
  if ok and result then break end
  task.wait(attempt*2)
 end
 if not result then return false end
 Profiles.cache[player]=result
 player:SetAttribute('XP',result.xp or 0);player:SetAttribute('Coins',result.coins or 0);player:SetAttribute('ProfileReady',true)
 return true
end
function Profiles.Reward(player,xp,coins)
 local p=Profiles.cache[player];if not p then return end
 p.xp=(p.xp or 0)+math.max(0,math.floor(xp));p.coins=(p.coins or 0)+math.max(0,math.floor(coins))
 player:SetAttribute('XP',p.xp);player:SetAttribute('Coins',p.coins)
end
function Profiles.Save(player,release)
 local p=Profiles.cache[player];if not p then return true end
 if p.saving then repeat task.wait(.1) until not p.saving end
 p.saving=true
 local snapshot={xp=p.xp,coins=p.coins,owned=table.clone(p.owned),loadout=table.clone(p.loadout)}
 local success=false
 for attempt=1,3 do
  local ok,value=pcall(function()
   return store:UpdateAsync('u'..player.UserId,function(old)
    if old and old.lock and old.lock.session~=session then return nil end
    snapshot.lock=not release and {session=session,untilTime=os.time()+150} or nil
    return snapshot
   end)
  end)
  if ok and value then success=true;break end
  task.wait(attempt)
 end
 p.saving=false
 if release and success then Profiles.cache[player]=nil end
 return success
end
return Profiles
