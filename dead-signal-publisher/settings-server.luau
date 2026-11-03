local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local DataStore=game:GetService('DataStoreService'):GetDataStore('StillHerePreferences_v1')
local schema=require(RS.SettingsSchema)
local cache={};local loading={};local saving={};local pending={};local lastSave={}
local function key(player) return 'u'..player.UserId end
local function load(player)
 while loading[player] do task.wait(.1) end
 if cache[player] then return cache[player] end
 loading[player]=true
 local ok,value=pcall(function() return DataStore:GetAsync(key(player)) end)
 loading[player]=nil
 if not ok then warn('[SettingsLoad] '..tostring(value));return nil end
 cache[player]=schema.Clean(value or schema.Defaults)
 return cache[player]
end
local function save(player,value,force)
 local clean=schema.Clean(value);if not clean then return false,'Configurações inválidas.' end
 while saving[player] do task.wait(.05) end
 if not force and os.clock()-(lastSave[player] or -10)<.25 then return false,'Aguarde o salvamento automático.' end
 saving[player]=true;pending[player]=clean;lastSave[player]=os.clock()
 local ok,err=pcall(function() DataStore:UpdateAsync(key(player),function() return clean end) end)
 saving[player]=nil
 if not ok then warn('[SettingsSave] '..tostring(err));return false,'Não foi possível salvar. Tentando novamente.' end
 cache[player]=clean;pending[player]=nil
 return true
end
RS.PlayerSettings.OnServerInvoke=function(player,action,value)
 if action=='get' then local settings=load(player);return {ok=settings~=nil,settings=settings} end
 if action=='save' then local ok,message=save(player,value,false);return {ok=ok,message=message} end
 return {ok=false,message='Ação inválida.'}
end
Players.PlayerRemoving:Connect(function(player)
 local cached=pending[player]
 if cached then task.spawn(function() save(player,cached,true);cache[player]=nil;pending[player]=nil;loading[player]=nil;lastSave[player]=nil end) else cache[player]=nil;loading[player]=nil;lastSave[player]=nil end
end)
game:BindToClose(function()
 local pendingWrites=0
 for player,value in pairs(pending) do
  pendingWrites+=1
  task.spawn(function() save(player,value,true);pendingWrites-=1 end)
 end
 local deadline=os.clock()+20
 while pendingWrites>0 and os.clock()<deadline do task.wait(.1) end
end)
