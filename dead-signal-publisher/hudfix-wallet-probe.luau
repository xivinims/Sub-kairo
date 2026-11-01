-- Uses a unique, non-user key and deletes it even if an assertion fails.
local probeProfiles=require(game.ServerScriptService.FalloutRuntime.Profiles)
local probeStore=game:GetService('DataStoreService'):GetDataStore('FalloutProfiles_v1')
local probePlayer={UserId='__hud_'..game:GetService('HttpService'):GenerateGUID(false),attributes={}}
function probePlayer:GetAttribute(name)return self.attributes[name]end
function probePlayer:SetAttribute(name,value)self.attributes[name]=value end
local probeOK,probeError=xpcall(function()
 assert(probeProfiles.Load(probePlayer),'Native profile load failed')
 probeProfiles.Reward(probePlayer,1555,600)
 assert(probeProfiles.SelectItem(probePlayer,{id='service',price=400},'gun',true),'Native purchase save failed')
 assert(probeProfiles.Save(probePlayer,true),'Native leave save failed')
 assert(probeProfiles.Load(probePlayer),'Native profile reload failed')
 local data=probeProfiles.cache[probePlayer]
 assert(data.coins==200 and data.xp==1555 and data.owned.service and data.loadout.gun=='service','Native wallet did not survive reload')
 assert(probePlayer:GetAttribute('Level')==2,'Native XP level incorrect')
 assert(probeProfiles.Save(probePlayer,true),'Native profile release failed')
end,debug.traceback)
local cleanupOK,cleanupError=pcall(function()probeStore:RemoveAsync('u'..probePlayer.UserId)end)
assert(cleanupOK,'Diagnostic key cleanup failed: '..tostring(cleanupError))
assert(probeOK,tostring(probeError))
print('HUDFIX_NATIVE_WALLET save=true purchase=true reload=true cleanup=true')
