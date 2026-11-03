local fs=require('@lune/fs')
local luau=require('@lune/luau')
require('./nametag-tests') -- Persistence/time/level behavior must survive the wallet change.
local progress=fs.readFile('fallout-progress.luau')
local profile=fs.readFile('fallout-profiles.luau')
local start,finish=assert(profile:find('local Progress=require(script.Parent.Progress)',1,true))
profile=profile:sub(1,start-1)..'local Progress=(function()\n'..progress..'\nend)()'..profile:sub(finish+1)
local header=[[
local clock=0
local blocked=false
local hook
local function copy(v)if type(v)~='table' then return v end;local r={};for k,x in pairs(v)do r[k]=copy(x)end;return r end
local stored={xp=1500,coins=1000,owned={compact=true,knife=true,medkit=true},loadout={gun='compact',melee='knife',heal='medkit'},playSeconds=7250}
local store={}
function store:UpdateAsync(_,callback)
 if hook then local call=hook;hook=nil;call() end
 if blocked then error('Store unavailable') end
 local result=callback(copy(stored));if result then stored=copy(result) end;return copy(result)
end
local game={JobId='wallet-spec'}
function game:GetService(name)if name=='DataStoreService' then return {GetDataStore=function()return store end}end;return{}end
local task={wait=function(n)clock+=n end}
local os={clock=function()return clock end,time=function()return 10000+math.floor(clock)end}
local p={UserId=1,attributes={}}
function p:GetAttribute(k)return self.attributes[k]end
function p:SetAttribute(k,v)self.attributes[k]=v end
]]
local cases=[[
assert(Profiles.Load(p))
local service={id='service',price=400}
hook=function()
 assert(p:GetAttribute('Coins')==1000,'Uncommitted purchase leaked to HUD')
 local xp,coins=Profiles.Reward(p,10.9,30.9);assert(xp==10 and coins==30)
end
assert(Profiles.SelectItem(p,service,'gun',true))
assert(Profiles.cache[p].coins==630 and p:GetAttribute('Coins')==630)
assert(Profiles.cache[p].loadout.gun=='service' and Profiles.cache[p].owned.service)
assert(Profiles.SelectItem(p,service,'gun',true))
assert(Profiles.cache[p].coins==630,'Already-owned item charged twice')
local heavy={id='heavy',price=600}
blocked=true
hook=function()Profiles.Reward(p,20,40)end
assert(not Profiles.SelectItem(p,heavy,'gun',true))
assert(Profiles.cache[p].coins==670,'Failed purchase erased incoming reward')
assert(not Profiles.cache[p].owned.heavy and Profiles.cache[p].loadout.gun=='service')
assert(p:GetAttribute('Coins')==670)
blocked=false
assert(not Profiles.SelectItem(p,{id='expensive',price=9999},'gun',true))
assert(not Profiles.SelectItem(p,heavy,'gun',false))
assert(Profiles.SelectItem(p,{id='compact',price=0},'gun',false))
assert(stored.loadout.gun=='compact','Equipped choice was not persisted')
assert(Profiles.Save(p,true))
assert(stored.coins==670 and stored.xp==1530 and stored.playSeconds>=7250)
assert(Profiles.Load(p));assert(p:GetAttribute('Coins')==670)
return true
]]
assert(luau.load(header..'\nlocal Profiles=(function()\n'..profile..'\nend)()\n'..cases,{debugName='wallet-transaction-spec'})())
print('HUDFIX_TESTS purchases=passed duplicatePurchase=passed rewardDuringSave=passed failedPurchase=passed equipPersistence=passed integerRewards=passed')
return true
