local fs=require('@lune/fs');local R=require('@lune/roblox');local Safe=require('./SafeAssetImporterFile')
return function(dm)
 local source=R.deserializePlace(fs.readFile('/tmp/asset-5326950832.rbxl'));local root=source:GetService('Workspace')
 local trees=R.Instance.new('Folder');trees.Name='AdventureTrees';trees.Parent=dm:GetService('ServerStorage')
 local candidates={}
 for _,m in ipairs(root:GetDescendants()) do if m:IsA('Model') then
  local name=m.Name:lower();local count=0;local lo=R.Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
  for _,p in ipairs(m:GetDescendants()) do if p:IsA('BasePart') and not p:IsA('Terrain') then
   count+=1;local pos=p.CFrame.Position;local s=p.Size*.5
   lo=R.Vector3.new(math.min(lo.X,pos.X-s.X),math.min(lo.Y,pos.Y-s.Y),math.min(lo.Z,pos.Z-s.Z));hi=R.Vector3.new(math.max(hi.X,pos.X+s.X),math.max(hi.Y,pos.Y+s.Y),math.max(hi.Z,pos.Z+s.Z))
  end end
  local size=hi-lo
  if count>=2 and count<=180 and size.Y>18 and size.Y<150 and size.X<90 and size.Z<90 and (name:find('tree') or name:find('pine') or name:find('fir')) then table.insert(candidates,{model=m,lo=lo,hi=hi}) end
 end end
 for i=1,math.min(#candidates,8) do
  local row=candidates[i];local tree=Safe.Parts(row.model,'5326950832',180);tree.Name='Tree_'..i
  local base=R.Vector3.new((row.lo.X+row.hi.X)/2,row.lo.Y,(row.lo.Z+row.hi.Z)/2)
  for _,p in ipairs(tree:GetChildren()) do p.CFrame=p.CFrame-base end
  local cover=false
  for _,p in ipairs(tree:GetChildren()) do
   if p:IsA('BasePart') and not p:GetAttribute('IslandWind') and p.Size.Y>p.Size.X*1.8 then p.CanCollide=true;p.CanQuery=true;cover=true end
  end
  if not cover then
   local trunk=R.Instance.new('Part');trunk.Name='TrunkCover';trunk.Size=R.Vector3.new(1.8,(row.hi.Y-row.lo.Y)*.55,1.8);trunk.CFrame=R.CFrame.new(0,trunk.Size.Y/2,0);trunk.Transparency=1;trunk.Anchored=true;trunk.CanCollide=true;trunk.CanQuery=true;trunk.CanTouch=false;trunk.Parent=tree
  end
  tree.WorldPivot=R.CFrame.new();tree:SetAttribute('GroundedTemplate',true);tree.Parent=trees
 end
 assert(#trees:GetChildren()>0,'No authored tree templates found')
 print('ADVENTURE TREE TEMPLATES '..#trees:GetChildren())
end
