local fs=require('@lune/fs');local luau=require('@lune/luau');local schema=luau.load(fs.readFile('settings-schema.luau'))()
local clean=schema.Clean({volume=0/0,fov=900,sensitivity=-9,brightness=math.huge,shadows=false,bloom=true,unexpected='x'})
assert(clean.volume==.8 and clean.fov==90 and clean.sensitivity==.2 and clean.brightness==.5 and clean.shadows==false and clean.unexpected==nil,'Preference validation failed')
local stored;local fail=false;local clock=10
local remote={};local fakeRS={PlayerSettings=remote};local fakePlayers={PlayerRemoving={Connect=function() end}}
local data={GetAsync=function() if fail then error('network') end;return stored end,UpdateAsync=function(_,key,fn) if fail then error('network') end;stored=fn(stored);return stored end}
local game={GetService=function(_,name) if name=='ReplicatedStorage' then return fakeRS elseif name=='Players' then return fakePlayers else return {GetDataStore=function() return data end} end end}
local source=fs.readFile('settings-server.luau'):gsub('local schema=require%(RS.SettingsSchema%)','')
local run=luau.load('return function(game,schema,os,warn)\n'..source..'\nreturn RS.PlayerSettings.OnServerInvoke end')()
local invoke=run(game,schema,{clock=function() return clock end},function() end)
local p={UserId=11};assert(invoke(p,'get').ok)
local prefs=table.clone(schema.Defaults);prefs.volume=.3;prefs.shadows=false;prefs.fov=85
assert(invoke(p,'save',prefs).ok and stored.volume==.3 and stored.shadows==false)
assert(not invoke(p,'save',prefs).ok,'Save spam not throttled')
local second=run(game,schema,{clock=function() return clock end},function() end)
local loaded=second({UserId=11},'get');assert(loaded.ok and loaded.settings.fov==85 and loaded.settings.shadows==false,'Menu-to-match preference persistence failed')
clock=20;fail=true;assert(not invoke(p,'save',prefs).ok,'Failed write reported as saved')
print('PREFERENCES REGRESSION PASS: finite validation, clamps, false toggles, save throttling, cross-session read and write-failure reporting')
