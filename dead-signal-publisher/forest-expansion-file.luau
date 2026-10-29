local fs=require('@lune/fs');local R=require('@lune/roblox');local luau=require('@lune/luau')
local Safe=require('./SafeAssetImporterFile')
local V,C=R.Vector3,R.CFrame
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-source.rbxl'))
local W=dm:GetService('Workspace');local map=W.OvergrownAtrium
assert(W:GetAttribute('DeadSignalBuildId')=='still-here-light-weather-v8','Unexpected base')
local old=W:FindFirstChild('ForestExpansion');if old then old:Destroy() end
local expansion=R.Instance.new('Folder');expansion.Name='ForestExpansion';expansion.Parent=W
local function bounds(model)
 local lo=V.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  local cf,s=p.CFrame,p.Size*.5
  for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
   local v=cf:PointToWorldSpace(V.new(s.X*x,s.Y*y,s.Z*z))
   lo=V.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z));hi=V.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
  end end end
 end end
 return lo,hi
end
local function move(model,origin,target,scale)
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  local cf=p.CFrame;p.CFrame=C.new(target+(cf.Position-origin)*scale)*cf.Rotation;p.Size=p.Size*scale
  local mesh=p:FindFirstChildOfClass('SpecialMesh');if mesh then mesh.Scale=mesh.Scale*scale;mesh.Offset=mesh.Offset*scale end
 end end
end
local altarSource=R.deserializeModel(fs.readFile('/tmp/asset-76722373571113.rbxl'))[1]
assert(altarSource,'Altar model missing')
-- Discard the 3D text meshes, imported emitters and stock spawn decorations.
for _,d in ipairs(altarSource:GetDescendants()) do if d.Name=='ThreeDTextObject' then d:Destroy() end end
local sourceSpawn=altarSource:FindFirstChildWhichIsA('SpawnLocation',true)
assert(sourceSpawn,'Altar spawn missing')
local altar,n=Safe.Parts(altarSource,'76722373571113',24);altar.Name='AltarSpawn';altar.Parent=expansion
local lo,hi=bounds(altar)
local prior=map:FindFirstChild('ForestTrailSpawn')
local base=prior and prior.CFrame.Position or W:GetAttribute('ForestOriginalSpawnPosition')
assert(base,'Original spawn position missing');W:SetAttribute('ForestOriginalSpawnPosition',base)
local origin=V.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2)
local target=V.new(base.X,base.Y-.5,base.Z)
local scale=.85
local arrival=target+(sourceSpawn.CFrame.Position-origin)*scale
move(altar,origin,target,scale)
for _,p in ipairs(altar:GetDescendants()) do if p:IsA('BasePart') then p.CanCollide=true;p.CanQuery=true end end
local spawn=R.Instance.new('SpawnLocation');spawn.Name='AltarArrival';spawn.Size=V.new(6,.2,6)
spawn.CFrame=C.new(arrival+V.new(0,.25,0));spawn.Transparency=1;spawn.Anchored=true;spawn.CanCollide=true;spawn.CanTouch=false
spawn.Neutral=true;spawn.Enabled=true;spawn.Duration=0;spawn.Parent=altar
if prior then prior:Destroy() end
-- Remove vegetation only inside the altar footprint, preserving all surrounding forest.
for _,folder in ipairs({map.Pines,map.MeadowUnderstory}) do for _,m in ipairs(folder:GetChildren()) do
 local p=m:FindFirstChildWhichIsA('BasePart',true)
 if p and (V.new(p.CFrame.X,0,p.CFrame.Z)-V.new(base.X,0,base.Z)).Magnitude<20 then m:Destroy() end
end end
local portdm=R.deserializePlace(fs.readFile('/tmp/asset-186677844.rbxl'))
local wreck=portdm:GetService('Workspace'):FindFirstChild('ShipWreck');assert(wreck,'Audited Port Gloom selection missing')
local port,portParts=Safe.Parts(wreck,'186677844',600);port.Name='PortGloom_Wreck';port.Parent=expansion
local pl,ph=bounds(port);local pc=V.new((pl.X+ph.X)/2,pl.Y,(pl.Z+ph.Z)/2)
-- More than 1400 studs from arrival, beyond the low streaming target.
local dest=V.new(650,10,-750)
move(port,pc,dest,1)
port:SetAttribute('GroundAtFinalize',true)
for _,p in ipairs(port:GetDescendants()) do if p:IsA('BasePart') then p.CanQuery=true;p.CanCollide=true end end
-- Small, individual fern and flower selections from Roblox's demo, no terrain/scripts imported.
local demo=R.deserializePlace(fs.readFile('/tmp/asset-5326950832.rbxl')):GetService('Workspace')
local flora=R.Instance.new('Folder');flora.Name='DemoBotanicalSelections';flora.Parent=expansion
local templates={}
for _,groupName in ipairs({'Group-Ferns','Group-FlowerBushes','Group-Flowers'}) do
 local group=demo:FindFirstChild(groupName)
 if group then for _,m in ipairs(group:GetChildren()) do if m:IsA('Model') and #m:GetDescendants()<=8 then
  local found=false;for _,t in ipairs(templates) do if t.Name==m.Name then found=true end end
  if not found then local t=Safe.Parts(m,'5326950832',8);table.insert(templates,t) end
  if #templates>=8 then break end
 end end end
 if #templates>=8 then break end
end
assert(#templates>0,'No audited botanical templates')
for i=1,180 do
 local t=templates[(i-1)%#templates+1]:Clone();t.Name='DemoBotanical_'..i
 local low,high=bounds(t);local o=V.new((low.X+high.X)/2,low.Y,(low.Z+high.Z)/2)
 local a=i*2.399963;local radius=28+((i*37)%380)
 local pos=V.new(base.X+math.cos(a)*radius,base.Y,base.Z+math.sin(a)*radius)
 if math.abs(pos.X)<980 and math.abs(pos.Z)<980 then
  move(t,o,pos,.75+(i%4)*.1)
  for _,p in ipairs(t:GetDescendants()) do if p:IsA('BasePart') then p.CanCollide=false;p.CanQuery=false end end
  t:SetAttribute('GroundAtFinalize',true);t.Parent=flora
 else t:Destroy() end
end
local function install(parent,name,class,file)
 local old=parent:FindFirstChild(name);if old then old:Destroy() end
 local source=fs.readFile(file);luau.load(source,{debugName=file})
 local s=R.Instance.new(class);s.Name=name;s.Source=source;s.Disabled=false;s.Parent=parent
end
install(dm:GetService('ServerScriptService').AtriumRuntime,'ForestSpawnServer','Script','forest-spawn-server.luau')
install(dm:GetService('StarterPlayer').StarterPlayerScripts,'ForestSpawnClient','LocalScript','forest-spawn-client.luau')
W:SetAttribute('ForestExpansionId','still-here-altar-botanical-v1')
W:SetAttribute('ForestAltarAsset','76722373571113');W:SetAttribute('ForestPortAsset','186677844')
W:SetAttribute('ForestPortSelection','ShipWreck');W:SetAttribute('ForestDemoAsset','5326950832')
fs.writeFile('/tmp/still-here-expansion.rbxl',R.serializePlace(dm))
print('EXPANSION SERIALIZED: altar='..n..'; port='..portParts..'; botanical='..#flora:GetChildren()..'; arrival='..tostring(arrival))
