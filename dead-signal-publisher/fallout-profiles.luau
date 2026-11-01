local DataStoreService=game:GetService('DataStoreService')
local Http=game:GetService('HttpService')
local Progress=require(script.Parent.Progress)
local store=DataStoreService:GetDataStore('FalloutProfiles_v1')
local Profiles={cache={}}
local timers={}
local session=game.JobId~='' and game.JobId or Http:GenerateGUID(false)
local function fresh()
 return {xp=0,coins=0,playSeconds=0,schemaVersion=2,owned={compact=true,knife=true,medkit=true},loadout={gun='compact',melee='knife',heal='medkit'}}
end
function Profiles.PlaySeconds(player)
 local p,t=Profiles.cache[player],timers[player]
 if not p then return nil end
 return t and Progress.elapsed(p.playSeconds,t.started,t.stopped or os.clock()) or Progress.seconds(p.playSeconds)
end
local function attribute(player,name,value)
 if player:GetAttribute(name)~=value then player:SetAttribute(name,value) end
end
function Profiles.Refresh(player)
 local p=Profiles.cache[player];if not p then return end
 local seconds=Profiles.PlaySeconds(player)
 attribute(player,'XP',p.xp or 0);attribute(player,'Coins',p.coins or 0)
 attribute(player,'PlayTimeSeconds',seconds)
 attribute(player,'Level',Progress.level(p.xp))
 attribute(player,'TenureTitle',Progress.title(seconds))
end
function Profiles.StopClock(player)
 local t=timers[player];if t and not t.stopped then t.stopped=os.clock() end
end
function Profiles.Load(player)
 if Profiles.cache[player] then return true end
 timers[player]=timers[player] or {started=os.clock()}
 local result
 for attempt=1,4 do
  local ok=pcall(function()
   result=store:UpdateAsync('u'..player.UserId,function(old)
    old=type(old)=='table' and old or fresh()
    if old.lock and old.lock.session~=session and old.lock.untilTime>os.time() then return nil end
    old.lock={session=session,untilTime=os.time()+150}
    old.owned=old.owned or {};old.owned.compact=true;old.owned.knife=true;old.owned.medkit=true
    old.loadout=old.loadout or fresh().loadout
    old.playSeconds=Progress.seconds(old.playSeconds);old.schemaVersion=2
    return old
   end)
  end)
  if ok and result then break end
  task.wait(attempt*2)
 end
 if not result then timers[player]=nil;return false end
 Profiles.cache[player]=result
 Profiles.Refresh(player);player:SetAttribute('ProfileReady',true)
 return true
end
function Profiles.Reward(player,xp,coins)
 local p=Profiles.cache[player];if not p then return end
 p.xp=(p.xp or 0)+math.max(0,math.floor(xp));p.coins=(p.coins or 0)+math.max(0,math.floor(coins))
 Profiles.Refresh(player)
end
function Profiles.Save(player,release)
 if release then Profiles.StopClock(player) end
 local p=Profiles.cache[player];if not p then return true end
 if p.saving then repeat task.wait(.1) until not p.saving end
 if Profiles.cache[player]~=p then return true end
 p.saving=true
 local snapshot={xp=p.xp,coins=p.coins,playSeconds=Profiles.PlaySeconds(player),schemaVersion=2,owned=table.clone(p.owned),loadout=table.clone(p.loadout)}
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
 if release and success then Profiles.cache[player]=nil;timers[player]=nil end
 return success
end
return Profiles
