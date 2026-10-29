-- Offline sanitized source extraction. No imported source code is executed.
local fs=require('@lune/fs');local R=require('@lune/roblox');local serde=require('@lune/serde');local process=require('@lune/process')
local Safe=require('./SafeAssetImporterFile');local V=R.Vector3
local id=process.args[1];local dm=R.deserializePlace(fs.readFile('/tmp/asset-'..id..'.rbxl'));local W=dm:GetService('Workspace')
local source=W
if id=='88883160098456' then source=assert(W:FindFirstChild('Forest'),'Forest selection missing'):FindFirstChild('Model');assert(source,'Forest model missing') end
local forbidden={['group-distantlodtrees']=true,transmittance=true,invisiwalls=true,allgrass=true,minimap=true,playbounds=true,packages=true,vistechdemopackages=true,daysky=true,nightsky=true,ocean=true,boattargets=true,birdtargets=true}
local function include(p)
 if p:IsA('Seat') or p:IsA('VehicleSeat') then return true end
 local a=p
 while a and a~=W do
  local n=string.lower(a.Name)
  if forbidden[n] or n:find('grass',1,true) or n:find('grassbunch',1,true) or n:find('weedbunch',1,true) or n:find('invisiblewall',1,true) or n:find('distantfog',1,true) or n:find('artifactfog',1,true) or n:find('butterfl',1,true) or n:find('dragonfl',1,true) or n:find('group-birds',1,true) or n:find('river-fish',1,true) then return false end
  if a:IsA('Model') and a:FindFirstChildOfClass('Humanoid') then return false end
  a=a.Parent
 end
 return p.Size.X<5000 and p.Size.Z<5000
end
local geo,count=Safe.Parts(source,id,90000,include);geo.Name='SourceGeometry'
local lo=V.new(math.huge,math.huge,math.huge);local hi=-lo
for _,p in ipairs(geo:GetChildren()) do
 local cf,s=p.CFrame,p.Size*.5
 for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
  local v=cf:PointToWorldSpace(V.new(s.X*x,s.Y*y,s.Z*z))
  lo=V.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z));hi=V.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
 end end end
 -- Mark only canopy / fern meshes for the bounded local wind controller.
 local n=string.lower(p.Name)
 if n:find('leaf',1,true) or n:find('foliage',1,true) or n:find('fern',1,true) then p:SetAttribute('IslandWind',true);p.CanCollide=false end
 if p:IsA('MeshPart') then p.RenderFidelity=R.Enum.RenderFidelity.Performance end
end
local preferred={}
for _,p in ipairs(W:GetDescendants()) do if p:IsA('SpawnLocation') then
 local v=p.CFrame.Position
 if v.X>=lo.X and v.X<=hi.X and v.Z>=lo.Z and v.Z<=hi.Z then table.insert(preferred,{v.X,v.Y,v.Z}) end
end end
for _,c in ipairs(W:GetChildren()) do if not c:IsA('Terrain') then c:Destroy() end end
geo.Parent=W
-- Strip every service, source GUI and script outside the selected static geometry.
for _,name in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','StarterPlayer','SoundService'}) do
 local service=dm:GetService(name);for _,c in ipairs(service:GetChildren()) do c:Destroy() end
end
local all=dm:GetDescendants();for i=#all,1,-1 do local d=all[i];if d:IsA('LuaSourceContainer') or d:IsA('Sound') then d:Destroy() end end
local terrain=assert(W:FindFirstChildOfClass('Terrain'),'Source terrain missing');terrain.Decoration=true;terrain.GrassLength=.85
W:SetAttribute('IslandStageAsset',id)
local meta={id=id,parts=count,lo={lo.X,lo.Y,lo.Z},hi={hi.X,hi.Y,hi.Z},preferred=preferred}
W:SetAttribute('IslandStageMeta',serde.encode('json',meta))
fs.writeFile('/tmp/stage-'..id..'.rbxl',R.serializePlace(dm));fs.writeFile('/tmp/stage-'..id..'.json',serde.encode('json',meta))
print('SANITIZED SOURCE '..serde.encode('json',meta))
