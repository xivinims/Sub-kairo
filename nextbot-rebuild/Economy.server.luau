local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference')
local Profiles=require(script.Parent.ProfileService)
local Config=require(package.Config)
local remote=package:WaitForChild('Economy')
local items={};for _,v in ipairs(Config.Catalog)do items[v.id]=v end
local last={}
remote.OnServerEvent:Connect(function(p,action,id,slot)
 if type(id)~='string' or #id>80 or os.clock()-(last[p]or -10)<.4 then return end
 last[p]=os.clock()
 local item=items[id]
 if action=='Buy'and item and item.available and item.category~='Animações'then
  local ok,status=Profiles.Mutate(p,function(v)
   if item.permanent and (v.owned[id]or (v.equipment[id]or 0)>0)then return false,'owned'end
   if v.coins<item.price then return false,'funds'end
   v.coins-=item.price
   if item.category=='Personagem'then v.owned[id]=true else v.equipment[id]=(v.equipment[id]or 0)+(item.quantity or 1)end
   return true,'purchased'
  end);remote:FireClient(p,status)
 elseif action=='Perk'and item and item.category=='Personagem'and not p:GetAttribute('NBInRound')then
  local _,status=Profiles.Mutate(p,function(v)if not v.owned[id]then return false,'invalid'end;if slot==2 then if v.perk==id then v.perk=''end;v.perk2=id else if v.perk2==id then v.perk2=''end;v.perk=id end;return true,'equipped'end);remote:FireClient(p,status)
 elseif action=='Claim'then
  local requirements={survivor={field='wins',goal=2,coins=150},medic={field='rescues',goal=3,coins=200},runner={field='rounds',goal=5,coins=300}}
  local rule=requirements[id];if not rule then return end
  local _,status=Profiles.Mutate(p,function(v)
   if v.claims[id]then return false,'claimed'end
   if v[rule.field]<rule.goal then return false,'incomplete'end
   v.coins+=rule.coins;v.claims[id]=true;return true,'reward'
  end);remote:FireClient(p,status)
 end
end)
game:GetService('Players').PlayerRemoving:Connect(function(p)last[p]=nil end)
