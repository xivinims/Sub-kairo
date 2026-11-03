local Data=game:GetService('DataStoreService'):GetDataStore('StillHereInventory_v1')
local M={Cache={},Catalog={lantern={name='Lanterna',price=20},trail={name='Rastro de luz',price=15},mark={name='Marca de chegada',price=10}}}
function M.Load(p)
 local ok,v=pcall(function() return Data:UpdateAsync('u'..p.UserId,function(old) return old or {coins=30,owned={}} end) end)
 if not ok then warn('[Profile] '..tostring(v));return nil end
 v.owned=v.owned or {};M.Cache[p]=v;return v
end
function M.Buy(p,id)
 local item=M.Catalog[id];if not item then return false,'Item inválido.' end
 local ok,v=pcall(function() return Data:UpdateAsync('u'..p.UserId,function(old)
  if not old then return nil end;old.owned=old.owned or {}
  if not old.owned[id] and (old.coins or 0)>=item.price then old.coins-=item.price;old.owned[id]=true end
  return old
 end) end)
 if not ok or not v then return false,'Não foi possível salvar a compra.' end
 M.Cache[p]=v;return v.owned[id]==true,v
end
function M.Apply(p,char)
 local data=M.Cache[p] or M.Load(p);if not data then return end
 local root=char:WaitForChild('HumanoidRootPart',10);if not root then return end
 if data.owned.lantern then
  local handle=Instance.new('Part');handle.Name='PurchasedLanternBody';handle.Size=Vector3.new(.55,.9,.55);handle.Material=Enum.Material.Metal;handle.Color=Color3.fromRGB(65,61,49);handle.Massless=true;handle.CanCollide=false;handle.CanTouch=false;handle.CFrame=root.CFrame*CFrame.new(.9,-.7,.3);handle.Parent=char
  local weld=Instance.new('WeldConstraint');weld.Part0=root;weld.Part1=handle;weld.Parent=handle
  local glass=Instance.new('Part');glass.Name='LanternGlass';glass.Size=Vector3.new(.4,.5,.4);glass.Material=Enum.Material.Neon;glass.Color=Color3.fromRGB(255,218,150);glass.Massless=true;glass.CanCollide=false;glass.CanTouch=false;glass.CFrame=handle.CFrame;glass.Parent=char
  local glassWeld=Instance.new('WeldConstraint');glassWeld.Part0=handle;glassWeld.Part1=glass;glassWeld.Parent=glass
  local light=Instance.new('PointLight');light.Name='PurchasedLantern';light.Color=Color3.fromRGB(255,227,173);light.Range=24;light.Brightness=1.4;light.Shadows=false;light.Parent=root
 end
 if data.owned.trail then
  local a=Instance.new('Attachment');a.Position=Vector3.new(-.5,-2,0);a.Parent=root
  local b=a:Clone();b.Position=Vector3.new(.5,-2,0);b.Parent=root
  local trail=Instance.new('Trail');trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=.45;trail.Transparency=NumberSequence.new(.6,1);trail.Color=ColorSequence.new(Color3.fromRGB(176,206,231));trail.Parent=root
 end
 if data.owned.mark then
  local h=Instance.new('Highlight');h.FillTransparency=.85;h.OutlineTransparency=.3;h.OutlineColor=Color3.fromRGB(177,212,255);h.Parent=char;task.delay(3,function() h:Destroy() end)
 end
end
function M.Reward(p,count)
 if count<=0 then return end
 local ok,err=pcall(function() Data:UpdateAsync('u'..p.UserId,function(old) if not old then return nil end;if old.lastAward~=game.JobId then old.coins=(old.coins or 0)+count*5;old.lastAward=game.JobId end;return old end) end)
 if not ok then warn('[ProfileReward] '..tostring(err)) end
end
function M.SaveAdventure(p,index)
 local data=M.Cache[p];if data then data.adventureMission=math.max(data.adventureMission or 1,index) end
 task.spawn(function()
  local ok,err=pcall(function() Data:UpdateAsync('u'..p.UserId,function(old) if not old then return nil end;old.adventureMission=math.max(old.adventureMission or 1,index);return old end) end)
  if not ok then warn('[AdventureSave] '..tostring(err)) end
 end)
end
return M
