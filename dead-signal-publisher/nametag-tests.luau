local fs=require('@lune/fs')
local luau=require('@lune/luau')
local source=fs.readFile('fallout-progress.luau')
local P=luau.load(source)()
assert(P.title(0)=='Iniciante' and P.title(7199)=='Iniciante')
assert(P.title(7200)=='' and P.title(104399)=='')
assert(P.title(104400)=='Veterano' and P.title(200000)=='Veterano')
assert(P.level(0)==1 and P.level(999)==1 and P.level(1000)==2 and P.level(2750)==3)
assert(P.seconds(-1)==0 and P.seconds(0/0)==0 and P.seconds(math.huge)==0)
local header=[[
local clock=10
local blocked=false
local beforeWrite
local function copy(value)
 if type(value)~='table' then return value end
 local result={};for key,v in pairs(value) do result[key]=copy(v) end;return result
end
local stored={u123={xp=2750,coins=520,owned={service=true},loadout={gun='service',melee='knife',heal='medkit'}}}
local store={}
function store:UpdateAsync(key,callback)
 if beforeWrite then local hook=beforeWrite;beforeWrite=nil;hook() end
 if blocked then error('Simulated unavailable store') end
 local nextValue=callback(copy(stored[key]))
 if nextValue~=nil then stored[key]=copy(nextValue) end
 return copy(nextValue)
end
local game={JobId='nametag-spec-session'}
function game:GetService(name)
 if name=='DataStoreService' then return {GetDataStore=function(_,id) assert(id=='FalloutProfiles_v1');return store end} end
 return {}
end
local task={wait=function(seconds)clock+=seconds end}
local os={clock=function()return clock end,time=function()return 1000000+math.floor(clock)end}
local function player(id)
 local p={UserId=id,attributes={}}
 function p:SetAttribute(k,v)self.attributes[k]=v end
 function p:GetAttribute(k)return self.attributes[k]end
 return p
end
]]
local profile=fs.readFile('fallout-profiles.luau')
local needle='local Progress=require(script.Parent.Progress)'
local start,finish=assert(string.find(profile,needle,1,true))
profile=profile:sub(1,start-1)..'local Progress=(function()\n'..source..'\nend)()'..profile:sub(finish+1)
local checks=[[
local p=player(123)
assert(Profiles.Load(p))
assert(p:GetAttribute('Level')==3 and p:GetAttribute('PlayTimeSeconds')==0)
assert(Profiles.cache[p].owned.service and Profiles.cache[p].loadout.gun=='service')
assert(Profiles.cache[p].coins==520 and Profiles.cache[p].schemaVersion==2)
clock+=7199;Profiles.Refresh(p)
assert(p:GetAttribute('TenureTitle')=='Iniciante')
assert(Profiles.Save(p,false) and stored.u123.playSeconds==7199)
clock+=1;Profiles.Refresh(p)
assert(p:GetAttribute('TenureTitle')=='' and Profiles.PlaySeconds(p)==7200)
assert(Profiles.Save(p,false) and stored.u123.playSeconds==7200)
assert(Profiles.Save(p,false) and stored.u123.playSeconds==7200)
Profiles.Reward(p,250,30);assert(p:GetAttribute('Level')==4)
assert(Profiles.Save(p,true))
assert(stored.u123.coins==550 and stored.u123.xp==3000 and stored.u123.owned.service)
assert(stored.u123.lock==nil and Profiles.cache[p]==nil)
clock+=999999 -- Offline time must not advance tenure.
assert(Profiles.Load(p) and Profiles.PlaySeconds(p)==7200)
clock+=97199;Profiles.Refresh(p);assert(p:GetAttribute('TenureTitle')=='')
clock+=1;Profiles.Refresh(p)
assert(p:GetAttribute('TenureTitle')=='Veterano' and Profiles.PlaySeconds(p)==104400)
blocked=true;assert(not Profiles.Save(p,true))
local stopped=Profiles.PlaySeconds(p);clock+=300;assert(Profiles.PlaySeconds(p)==stopped)
blocked=false;assert(Profiles.Save(p,true));assert(stored.u123.playSeconds==104400)
local leaving=player(456)
beforeWrite=function()clock+=30;Profiles.Save(leaving,true);clock+=20 end
assert(Profiles.Load(leaving));assert(Profiles.PlaySeconds(leaving)==30)
assert(Profiles.Save(leaving,true) and stored.u456.playSeconds==30)
return true
]]
assert(luau.load(header..'\nlocal Profiles=(function()\n'..profile..'\nend)()\n'..checks,{debugName='profile-persistence-spec'})())
print('NAMETAG_TESTS thresholds=passed level=passed migration=passed autosave=passed rejoin=passed offline=excluded releaseRetry=passed leaveDuringLoad=passed')
return true
