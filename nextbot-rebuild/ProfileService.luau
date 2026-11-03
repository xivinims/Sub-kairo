local Players=game:GetService('Players')
local Data=game:GetService('DataStoreService')
local Store=Data:GetDataStore('ExactRunProfiles_v2')
local Legacy=Data:GetDataStore('NextbotEmotes_v1')
local Service={};local profiles,busy={},{ }
local function integer(v,default)
 return type(v)=='number' and v==v and v~=math.huge and math.clamp(math.floor(v),0,100000000) or default
end
local function normalize(v)
 v=type(v)=='table' and v or {}
 local p={coins=integer(v.coins,0),xp=integer(v.xp,0),wins=integer(v.wins,0),rescues=integer(v.rescues,0),rounds=integer(v.rounds,0),owned={},slots={},equipment={flashlight=1},utility='',power='',usables={},light='flashlight',perk='',perk2='',claims={},musicFavorites={},revision=integer(v.revision,0)}
 for k,n in pairs(type(v.equipment)=='table' and v.equipment or {})do if type(k)=='string' then p.equipment[k]=integer(n,0)end end
 for k,b in pairs(type(v.owned)=='table' and v.owned or {})do if type(k)=='string' and b==true then p.owned[k]=true end end
 for i=1,6 do local id=type(v.slots)=='table' and v.slots[tostring(i)];if type(id)=='string' and p.owned[id]then p.slots[tostring(i)]=id end end
 if type(v.utility)=='string' then p.utility=v.utility end
 if type(v.light)=='string' and (p.equipment[v.light]or 0)>0 then p.light=v.light end
 if type(v.power)=='string'then p.power=v.power end
 for i=1,4 do local id=type(v.usables)=='table'and v.usables[tostring(i)];if type(id)=='string'then p.usables[tostring(i)]=id end end
 if type(v.perk2)=='string'and p.owned[v.perk2]then p.perk2=v.perk2 end
 if type(v.perk)=='string' and p.owned[v.perk]then p.perk=v.perk end
 for _,id in ipairs(type(v.musicFavorites)=='table'and v.musicFavorites or {})do if type(id)=='number'and id==id and id>0 and id<9007199254740991 and #p.musicFavorites<20 then table.insert(p.musicFavorites,math.floor(id))end end
 for k,b in pairs(type(v.claims)=='table' and v.claims or {})do if type(k)=='string' and b==true then p.claims[k]=true end end
 return p
end
function Service.Sync(p,v)
 if not p.Parent then return end
 p:SetAttribute('NBCoins',v.coins);p:SetAttribute('NBXP',v.xp);p:SetAttribute('NBLevel',1+math.floor(v.xp/250));p:SetAttribute('NBWins',v.wins);p:SetAttribute('NBRescues',v.rescues);p:SetAttribute('NBRounds',v.rounds);p:SetAttribute('NBPerk',v.perk);p:SetAttribute('NBPerk2',v.perk2)
 for _,k in ipairs({'Points','Vouchers','Wisps'})do p:SetAttribute('NB'..k,0)end
 for k,n in pairs(v.equipment)do p:SetAttribute('NBOwned_'..k,n)end
 for k in pairs(v.owned)do p:SetAttribute('NBEmoteOwned_'..k,true)end
 for i=1,6 do p:SetAttribute('NBEmoteSlot'..i,v.slots[tostring(i)]or '')end
 p:SetAttribute('NBPower',v.power);for i=1,4 do p:SetAttribute('NBUsable'..i,v.usables[tostring(i)]or '')end
 p:SetAttribute('NBUtility',v.utility);p:SetAttribute('NBLightID',v.light)
 local leader=p:FindFirstChild('leaderstats')
 if not leader then leader=Instance.new('Folder');leader.Name='leaderstats';leader.Parent=p;for _,name in ipairs({'Nível','Vitórias','Resgates'})do local n=Instance.new('IntValue');n.Name=name;n.Parent=leader end end
 leader['Nível'].Value=1+math.floor(v.xp/250);leader['Vitórias'].Value=v.wins;leader['Resgates'].Value=v.rescues
end
function Service.Get(p)return profiles[p]end
function Service.Mutate(p,fn)
 local deadline=os.clock()+12
 while busy[p] and p.Parent and os.clock()<deadline do task.wait(.05)end
 if not profiles[p]or busy[p]or not p.Parent then return false,'unavailable'end
 busy[p]=true;local status='saved'
 local ok,saved=pcall(function()return Store:UpdateAsync(tostring(p.UserId),function(old)
  local v=normalize(old);local changed;changed,status=fn(v)
  if changed==false then return nil end
  v.revision+=1;return v
 end)end)
 busy[p]=nil
 if ok and saved then profiles[p]=normalize(saved);Service.Sync(p,profiles[p]);return true,status end
 return false,ok and status or 'save_failed'
end
function Service.Reward(p,coins,xp,kind)
 return Service.Mutate(p,function(v)
  v.coins+=math.floor(coins*((v.perk=='briefcase'or v.perk2=='briefcase')and 1.1 or 1));v.xp+=math.floor(xp*((v.perk=='badge'or v.perk2=='badge')and 1.1 or 1))
  if kind=='survive'then v.wins+=1;v.rounds+=1 elseif kind=='rescue'then v.rescues+=1 end
  return true,'reward'
 end)
end
local function setup(p)
 p:SetAttribute('NBEmoteDataReady',false)
 local ok,value=pcall(function()return Store:GetAsync(tostring(p.UserId))end)
 if ok and value==nil then
  local migrated,old=pcall(function()return Legacy:GetAsync(tostring(p.UserId))end)
  if not migrated then ok=false else
   local normalized=normalize(old)
   local saved,result=pcall(function()return Store:UpdateAsync(tostring(p.UserId),function(current)return current or normalized end)end)
   ok=saved;value=result
  end
 end
 if not p.Parent then return end
 if ok then profiles[p]=normalize(value);Service.Sync(p,profiles[p])end
 p:SetAttribute('NBEmoteDataReady',ok)
end
Players.PlayerAdded:Connect(function(p)task.spawn(setup,p)end)
Players.PlayerRemoving:Connect(function(p)profiles[p]=nil end)
for _,p in ipairs(Players:GetPlayers())do task.spawn(setup,p)end
return Service
