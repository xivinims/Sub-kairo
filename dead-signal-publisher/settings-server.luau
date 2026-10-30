local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage')
local schema=require(RS.SettingsSchema)
local data=game:GetService('DataStoreService'):GetDataStore('StillHerePreferences_v1')
local cache={};local loading={};local saving={};local last={}
local function load(p)
 while loading[p] do task.wait(.1) end
 if cache[p] then return cache[p] end
 loading[p]=true
 local ok,value=pcall(function() return data:GetAsync('u'..p.UserId) end)
 loading[p]=nil
 if not ok then warn('[SettingsLoad] '..tostring(value));return nil end
 cache[p]=schema.Clean(value or schema.Defaults);return cache[p]
end
RS.PlayerSettings.OnServerInvoke=function(p,action,value)
 if action=='get' then local settings=load(p);return {ok=settings~=nil,settings=settings} end
 if action~='save' or saving[p] then return {ok=false,message='Aguarde o salvamento.'} end
 if os.clock()-(last[p] or -10)<1 then return {ok=false,message='Aguarde um instante e tente de novo.'} end
 local clean=schema.Clean(value);if not clean then return {ok=false,message='Configurações inválidas.'} end
 saving[p]=true;last[p]=os.clock()
 local ok,err=pcall(function() data:UpdateAsync('u'..p.UserId,function() return clean end) end)
 saving[p]=nil
 if not ok then warn('[SettingsSave] '..tostring(err));return {ok=false,message='Não salvou. Tente novamente.'} end
 cache[p]=clean;return {ok=true,settings=clean}
end
Players.PlayerRemoving:Connect(function(p) cache[p]=nil;last[p]=nil end)
