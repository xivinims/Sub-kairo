-- Per-player FPS options. Separate DataStore from coins, XP and loadouts.
-- Never accept arbitrary keys or unbounded values from the client.
local DataStore=game:GetService('DataStoreService'):GetDataStore('FalloutOptions_v1')
local Options={}
Options.defaults={
 reticle=true,radar=true,killfeed=true,hitmarker=true,notices=true,
 aimMode='hold',buttonScale=100,buttonOpacity=85,
 brightness=50,contrast=50,saturation=50,shadows=true,performance=false,
 effectsVolume=100,musicVolume=100,dialogueVolume=100,language='pt'
}
local numeric={
 buttonScale={80,110},buttonOpacity={30,100},
 brightness={0,100},contrast={0,100},saturation={0,100},
 effectsVolume={0,100},musicVolume={0,100},dialogueVolume={0,100}
}
local booleans={reticle=true,radar=true,killfeed=true,hitmarker=true,notices=true,shadows=true,performance=true}
local enums={aimMode={hold=true,toggle=true},language={pt=true,en=true}}
local cache,dirty,revision,loading,saving,scheduled={},{},{},{},{},{}
Options.cache=cache

local function copy(defaults)
 local out={}
 for key,value in pairs(defaults) do out[key]=value end
 return out
end
function Options.clean(key,value)
 if numeric[key] then
  if type(value)~='number' or value~=value or value==math.huge or value==-math.huge then return nil end
  return math.clamp(math.floor(value+0.5),numeric[key][1],numeric[key][2])
 end
 if booleans[key] and type(value)=='boolean' then return value end
 if enums[key] and type(value)=='string' and enums[key][value] then return value end
 return nil
end
function Options.normalize(input)
 local values=copy(Options.defaults)
 if type(input)=='table' then
  for key,value in pairs(input) do
   if Options.defaults[key]~=nil then
    local clean=Options.clean(key,value)
    if clean~=nil then values[key]=clean end
   end
  end
 end
 return values
end
local function key(player) return 'u'..player.UserId end
function Options.Get(player)
 if cache[player] then return {ok=true,settings=copy(cache[player])} end
 while loading[player] do task.wait(.05) end
 if cache[player] then return {ok=true,settings=copy(cache[player])} end
 loading[player]=true
 local ok,old=pcall(function()return DataStore:GetAsync(key(player)) end)
 loading[player]=nil
 if not ok then
  return {ok=false,message='Não foi possível carregar as configurações. Tente novamente.'}
 end
 cache[player]=Options.normalize(old)
 revision[player]=0
 return {ok=true,settings=copy(cache[player])}
end
function Options.Flush(player)
 while saving[player] do task.wait(.05) end
 if not dirty[player] or not cache[player] then return true end
 saving[player]=true
 local selected=copy(cache[player])
 local savingRevision=revision[player] or 0
 local ok=pcall(function()
  DataStore:UpdateAsync(key(player),function()return selected end)
 end)
 if ok and revision[player]==savingRevision then dirty[player]=nil end
 saving[player]=nil
 return ok
end
local function schedule(player)
 if scheduled[player] then return end
 scheduled[player]=true
 task.delay(3,function()
  scheduled[player]=nil
  if dirty[player] and cache[player] then
   local ok=Options.Flush(player)
   if not ok and player.Parent==game:GetService('Players') then
    task.delay(8,function()if dirty[player] then schedule(player) end end)
   elseif dirty[player] then
    schedule(player)
   end
  end
 end)
end
function Options.Set(player,values)
 if type(values)~='table' then return {ok=false,message='Dados inválidos.'} end
 local got=Options.Get(player)
 if not got.ok then return got end
 local accepted=0
 for k,v in pairs(values) do
  if Options.defaults[k]~=nil then
   local value=Options.clean(k,v)
   if value~=nil then
    if cache[player][k]~=value then cache[player][k]=value;accepted+=1 end
   end
  end
 end
 if accepted>0 then
  revision[player]=(revision[player] or 0)+1
  dirty[player]=true
  schedule(player)
 end
 return {ok=true,settings=copy(cache[player])}
end
function Options.Release(player)
 if dirty[player] then
  for attempt=1,3 do
   if Options.Flush(player) then break end
   task.wait(attempt)
  end
 end
 cache[player]=nil;dirty[player]=nil;revision[player]=nil;loading[player]=nil;scheduled[player]=nil
end
return Options
