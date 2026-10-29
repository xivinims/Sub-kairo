local fs=require('@lune/fs');local R=require('@lune/roblox');local serde=require('@lune/serde');local luau=require('@lune/luau')
local V,C=R.Vector3,R.CFrame
local dm=R.deserializePlace(fs.readFile('/tmp/still-here-source.rbxl'));local W=dm:GetService('Workspace')
local template=assert(W.ForestExpansion.AltarSpawn,'Altar template unavailable'):Clone()
for _,c in ipairs(W:GetChildren()) do if not c:IsA('Terrain') and not c:IsA('Camera') then c:Destroy() end end
local T=W:FindFirstChildOfClass('Terrain');T.Decoration=true;T.GrassLength=.85
for _,c in ipairs(dm:GetService('ServerStorage'):GetChildren()) do c:Destroy() end
local regions=R.Instance.new('Folder');regions.Name='IslandTerrainSnapshots';regions.Parent=dm:GetService('ServerStorage')
local catalog=R.Instance.new('Folder');catalog.Name='IslandGeometryCatalog';catalog.Parent=dm:GetService('ServerStorage')
local islands=R.Instance.new('Folder');islands.Name='Islands';islands.Parent=W
local destinations=R.Instance.new('Folder');destinations.Name='IslandDestinations';destinations.Parent=W
local input={}
for _,id in ipairs({'5326950832','88883160098456','186677844'}) do
 local path='/tmp/captured-'..id..'.rbxl'
 if not fs.isFile(path) then path='/tmp/stage-'..id..'.rbxl' end
 local staged=R.deserializePlace(fs.readFile(path))
 local sw=staged:GetService('Workspace');local meta=serde.decode('json',sw:GetAttribute('IslandStageMeta'));assert(meta.id==id,'Wrong captured source version')
 local storage=staged:GetService('ServerStorage')
 local region=storage:FindFirstChild('IslandTerrainRegion')
 if not region then
  local raw=assert(storage:FindFirstChild('RawSourceTerrain'),'Raw terrain missing')
  region=R.Instance.new('Folder');region.Name='IslandTerrainRegion'
  raw.Name='Tile_0';raw:SetAttribute('SourceCornerCells',V.new(raw.ExtentsMin.X,raw.ExtentsMin.Y,raw.ExtentsMin.Z));raw.Parent=region
  if #raw.SmoothGrid<=2 then raw.Parent=nil end
  meta.corner={raw.ExtentsMin.X,raw.ExtentsMin.Y,raw.ExtentsMin.Z}
  meta.cells={raw.ExtentsMax.X-raw.ExtentsMin.X+1,raw.ExtentsMax.Y-raw.ExtentsMin.Y+1,raw.ExtentsMax.Z-raw.ExtentsMin.Z+1}
  meta.spawn=meta.preferred[1] or {(meta.lo[1]+meta.hi[1])/2,0,(meta.lo[3]+meta.hi[3])/2}
 end
 input[id]={dm=staged,meta=meta,geo=storage.SourceGeometry,region=region}

end
local widthCurrent=input['88883160098456'].meta.hi[1]-input['88883160098456'].meta.lo[1]
local defs={{id='forestCurrent',asset='88883160098456',name='Floresta (atual)',center=0},{id='forest1',asset='5326950832',name='Floresta (1)'},{id='city',asset='186677844',name='Cidade'}}
local manifest={}
for _,def in ipairs(defs) do
 local src=input[def.asset];local meta=src.meta
 local width=meta.hi[1]-meta.lo[1]
 local desired=def.center or (def.id=='city' and 1 or -1)*((widthCurrent+width)/2+4096)
 local centerX=(meta.lo[1]+meta.hi[1])/2;local centerZ=(meta.lo[3]+meta.hi[3])/2
 local offset=V.new(math.floor((desired-centerX)/4)*4,math.floor((128-meta.spawn[2])/4)*4,math.floor(-centerZ/4)*4)
 local folder=R.Instance.new('Folder');folder.Name=def.id;folder:SetAttribute('SourceAsset',def.asset);folder.Parent=islands
 local library=R.Instance.new('Folder');library.Name=def.id;library.Parent=catalog
 local backdrops=R.Instance.new('Folder');backdrops.Name='Backdrops';backdrops.Parent=folder
 local chunks={};local parts=0
 for _,p in ipairs(src.geo:GetChildren()) do
  assert(p:IsA('BasePart'),'Unexpected source geometry')
  local windName=string.lower(p.Name)
  if windName:find('leaf',1,true) or windName:find('leav',1,true) or windName:find('foliage',1,true) or windName:find('fern',1,true) then p:SetAttribute('IslandWind',true);p.CanCollide=false end
  p.CFrame=p.CFrame+offset
  local doorPivot=p:GetAttribute('IslandDoorPivot');if doorPivot then p:SetAttribute('IslandDoorPivot',doorPivot+offset) end
  local pos=doorPivot and (doorPivot.Position+offset) or p.CFrame.Position;local key=math.floor(pos.X/128)..'_'..math.floor(pos.Z/128)
  local bucket=chunks[key]
  if not bucket then bucket=R.Instance.new('Model');bucket.Name='Cell_'..key;bucket.Parent=library;chunks[key]=bucket end
  if math.max(p.Size.X,p.Size.Z)>192 then p.Parent=backdrops else p.Parent=bucket end;parts+=1
 end
 src.region.Name=def.id;src.region.Parent=regions
 local point=V.new(unpack(meta.spawn))+offset
 local spawn=R.Instance.new('SpawnLocation');spawn.Name=def.id;spawn.Size=V.new(6,.2,6);spawn.CFrame=C.new(point+V.new(0,.15,0))
 spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=true;spawn.CanQuery=false;spawn.CanTouch=false;spawn.Neutral=true;spawn.Enabled=true;spawn.Duration=0;spawn.Parent=destinations
 if def.id=='forestCurrent' then
  local lo=V.new(math.huge,math.huge,math.huge)
  for _,p in ipairs(template:GetDescendants()) do if p:IsA('BasePart') and not p:IsA('SpawnLocation') then
   local cf,s=p.CFrame,p.Size*.5
   for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
    local v=cf:PointToWorldSpace(V.new(s.X*x,s.Y*y,s.Z*z));lo=V.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z))
   end end end
  end end
  local old=template.AltarArrival;local delta=V.new(point.X-old.CFrame.X,point.Y-.35-lo.Y,point.Z-old.CFrame.Z)
  spawn.CFrame=C.new(old.CFrame.Position+delta)
  template:SetAttribute('AltarLandingHeight',old.CFrame.Y-lo.Y)
  old:Destroy()
  for _,p in ipairs(template:GetDescendants()) do if p:IsA('BasePart') then p.CFrame=p.CFrame+delta end end
  template.Name='ArrivalAltar';template.Parent=folder
 end
 local corner={};for i,v in ipairs(meta.corner) do corner[i]=v+({offset.X,offset.Y,offset.Z})[i]/4 end
 table.insert(manifest,{id=def.id,name=def.name,asset=def.asset,parts=parts,corner=corner,cells=meta.cells,offset={offset.X,offset.Y,offset.Z},spawn={point.X,point.Y,point.Z},lo={meta.lo[1]+offset.X,meta.lo[2]+offset.Y,meta.lo[3]+offset.Z},hi={meta.hi[1]+offset.X,meta.hi[2]+offset.Y,meta.hi[3]+offset.Z}})
 print('ASSEMBLED '..def.id..': '..parts..' parts; arrival '..tostring(point))
end
-- Source lighting effects are data only; imported scripts never execute.
local lightingSource=R.deserializeModel(fs.readFile('/tmp/asset-17835285085.rbxl'))
local L=dm:GetService('Lighting');local selected={};local applied={}
local lightingCounts={}
for _,root in ipairs(lightingSource) do
 local list=root:GetDescendants();table.insert(list,1,root)
 for _,d in ipairs(list) do
  lightingCounts[d.ClassName]=(lightingCounts[d.ClassName] or 0)+1
  if (d:IsA('BloomEffect') or d:IsA('SunRaysEffect') or d:IsA('Sky')) and not selected[d.ClassName] then selected[d.ClassName]=d end
 end
end
for class,source in pairs(selected) do
 for _,old in ipairs(L:GetChildren()) do if old.ClassName==class then old:Destroy() end end
 local effect=source:Clone();for _,d in ipairs(effect:GetChildren()) do d:Destroy() end
 effect.Name='OutdoorStart_'..class
 if effect:IsA('BloomEffect') then effect.Intensity=math.clamp(effect.Intensity,.12,.45);effect.Threshold=math.max(effect.Threshold,1.1) end
 if effect:IsA('SunRaysEffect') then effect.Intensity=math.clamp(effect.Intensity,.025,.12) end
 effect.Parent=L;table.insert(applied,class)
end
assert(#applied>0,'No usable lighting data in provided pack')
-- Stormy dusk, readable ground and cool aerial perspective, never a black fog wall.
L.ClockTime=20;L.Brightness=1.15;L.ExposureCompensation=-.45
L.Ambient=R.Color3.fromRGB(48,59,80);L.OutdoorAmbient=R.Color3.fromRGB(76,91,119)
local atmosphere=L:FindFirstChild('ForestAerialPerspective') or R.Instance.new('Atmosphere')
atmosphere.Name='ForestAerialPerspective';atmosphere.Density=.29;atmosphere.Haze=1.8;atmosphere.Glare=.08
atmosphere.Color=R.Color3.fromRGB(185,198,214);atmosphere.Decay=R.Color3.fromRGB(138,156,181);atmosphere.Parent=L
local clouds=W.Terrain:FindFirstChildOfClass('Clouds') or R.Instance.new('Clouds')
clouds.Name='WoodlandCloudDeck';clouds.Cover=.86;clouds.Density=.88;clouds.Color=R.Color3.fromRGB(111,123,143);clouds.Parent=W.Terrain
local grade=L:FindFirstChild('ForestGoldenGrade') or R.Instance.new('ColorCorrectionEffect')
grade.Name='ForestGoldenGrade';grade.Contrast=.21;grade.Saturation=-.10;grade.TintColor=R.Color3.fromRGB(204,220,245);grade.Parent=L
for _,effect in ipairs(L:GetChildren()) do
 if effect:IsA('BloomEffect') then effect.Intensity=.45;effect.Threshold=.95;effect.Size=36 end
 if effect:IsA('SunRaysEffect') then effect.Intensity=.025 end
end
L.EnvironmentDiffuseScale=.55;L.EnvironmentSpecularScale=1;L.GlobalShadows=true;L.ShadowSoftness=.3
local depth=R.Instance.new('DepthOfFieldEffect');depth.Name='ForestCinematicDepth';depth.FocusDistance=85;depth.InFocusRadius=110;depth.NearIntensity=0;depth.FarIntensity=.12;depth.Parent=L
W:SetAttribute('IslandVisualRevision','cinematic-map-v3')
local citySource=R.deserializePlace(fs.readFile('/tmp/asset-186677844.rbxl'))
local cityWater={}
local seaSource=assert(citySource:GetService('Workspace'):FindFirstChild('ocean'),'Original sea missing')
for _,part in ipairs(seaSource:GetDescendants()) do
 if part:IsA('BasePart') and part.Name=='a' and part.Size.Y<1 then
  table.insert(cityWater,{cf={part.CFrame:GetComponents()},size={part.Size.X,part.Size.Z}})
 end
end
assert(#cityWater>=8,'Incomplete sea footprint')
for _,meta in ipairs(manifest) do if meta.id=='city' then meta.water=cityWater end end
local night=citySource:GetService('Workspace'):FindFirstChild('nightsky')
local sky=L:FindFirstChildOfClass('Sky')
if night and sky then
 for i,key in ipairs({'SkyboxBk','SkyboxDn','SkyboxFt','SkyboxLf','SkyboxRt','SkyboxUp'}) do
  local face=night:FindFirstChild(tostring(i))
  if face then local ok,texture=pcall(function() return face.Texture end);if ok and type(texture)=='string' and #texture>0 then sky[key]=texture end end
 end
 sky.CelestialBodiesShown=true;sky.StarCount=1200;sky.MoonAngularSize=11
end

W.GlobalWind=V.new(12,0,4);W:SetAttribute('ForestWeather','Overcast');W:SetAttribute('IslandAtmosphereRevision','storm-night-v2')

print('LIGHTING AUDIT '..serde.encode('json',{counts=lightingCounts,applied=applied}))
local SSS=dm:GetService('ServerScriptService');local runtime=SSS.AtriumRuntime
local SP=dm:GetService('StarterPlayer').StarterPlayerScripts
local function install(parent,name,class,file)
 local old=parent:FindFirstChild(name);if old then old:Destroy() end
 local source=fs.readFile(file);luau.load(source,{debugName=file})
 local s=R.Instance.new(class);s.Name=name;s.Source=source;if class~='ModuleScript' then s.Disabled=false end;s.Parent=parent;return s
end
install(runtime,'IslandChunks','ModuleScript','islands-chunks.luau')
install(runtime,'IslandChunkRuntime','Script','islands-chunks-server.luau')
install(runtime,'IslandResidents','ModuleScript','islands-residents.luau')
install(runtime,'IslandResidentRuntime','Script','islands-residents-server.luau')
install(SP,'IslandResidentClient','LocalScript','islands-residents-client.luau')
install(runtime,'IslandDoors','Script','islands-doors-server.luau')
install(runtime,'IslandTravelServer','Script','islands-travel-server.luau')
install(SP,'IslandTravelClient','LocalScript','islands-travel-client.luau')
install(SP,'ForestSpawnClient','LocalScript','forest-spawn-client.luau')
-- Retain already audited nested wind modules while updating its bootstrap only.
luau.load(fs.readFile('forest-wind-client.luau'),{debugName='forest-wind-client'});SP.ForestWindClient.Source=fs.readFile('forest-wind-client.luau')
install(runtime,'ForestWeatherServer','Script','forest-weather-server.luau')
install(dm:GetService('ReplicatedFirst'),'IslandLoadingClient','LocalScript','islands-loading-client.luau')
install(SP,'ForestWeatherClient','LocalScript','forest-weather-client.luau')
local RS=dm:GetService('ReplicatedStorage');local remote=RS:FindFirstChild('IslandTravel');if remote then remote:Destroy() end
remote=R.Instance.new('RemoteEvent');remote.Name='IslandTravel';remote.Parent=RS
local speech=R.Instance.new('RemoteEvent');speech.Name='ResidentDialogue';speech.Parent=RS
for k in pairs(W:GetAttributes()) do if k:find('ForestExpansion') or k=='ForestPortDistance' then W:SetAttribute(k,nil) end end
if fs.isFile('/tmp/asset-7208091524.rbxl') then require('./blackhole-extract')(dm) end
local initSource=fs.readFile('islands-finalize.luau')
initSource=initSource:sub(1,assert(initSource:find("game:GetService('AssetService'):SavePlaceAsync",1,true))-1)
initSource="if workspace:GetAttribute('IslandWorldReady')==true then script:Destroy();return end\ntask.wait(.25)\nlocal ok,err=xpcall(function()\n"..initSource.."\nend,debug.traceback);if not ok then workspace:SetAttribute('IslandWorldError',tostring(err));error(err) end\nlocal P=game:GetService('Players');P.CharacterAutoLoads=true;for _,p in ipairs(P:GetPlayers()) do if not p.Character then task.spawn(function() p:LoadCharacterAsync() end) end end;script:Destroy()\n"
luau.load(initSource,{debugName='IslandInitializer'})
local initializer=R.Instance.new('Script');initializer.Name='IslandInitializer';initializer.Source=initSource;initializer.Disabled=false;initializer.Parent=runtime
dm:GetService('Players').CharacterAutoLoads=true
W:SetAttribute('IslandStreamingTarget',128)
W:SetAttribute('IslandWorldMeta',serde.encode('json',manifest));W:SetAttribute('IslandWorldReady',false)
W:SetAttribute('DeadSignalBuildId','still-here-three-islands-v1');W:SetAttribute('ForestLightAsset','17835285085')
W:SetAttribute('ResidentsRevision','six-identities-v1');W:SetAttribute('CityWaterRevision','original-sea-native-v1')
W:SetAttribute('MapSource','Sanitized original forest demos and Port Gloom on separate islands')
W.StreamingMinRadius=64;W.StreamingTargetRadius=128
fs.writeFile('/tmp/still-here-islands.rbxl',R.serializePlace(dm))
local check=R.deserializePlace(fs.readFile('/tmp/still-here-islands.rbxl'))
assert(check:GetService('Workspace').Terrain.Decoration==true,'Native grass lost')
assert(#check:GetService('Workspace').IslandDestinations:GetChildren()==3,'Arrival count incorrect')
print('ISLAND FILE READY: '..#fs.readFile('/tmp/still-here-islands.rbxl')..' bytes')
-- Binary input bundle avoids re-encoding DataModel services during installation.
local bundle=R.Instance.new('Model');bundle.Name='StillHereIslandBundle'
for key,value in pairs(W:GetAttributes()) do bundle:SetAttribute(key,value) end
for _,name in ipairs({'Islands','IslandDestinations'}) do W[name].Parent=bundle end
for _,name in ipairs({'IslandGeometryCatalog','IslandTerrainSnapshots'}) do dm:GetService('ServerStorage')[name].Parent=bundle end
local replicatedAssets=R.Instance.new('Folder');replicatedAssets.Name='ReplicatedAssets';replicatedAssets.Parent=bundle
for _,c in ipairs(RS:GetChildren()) do if c.Name~='IslandTravel' then c.Parent=replicatedAssets end end
runtime.Name='IslandRuntime';runtime.Parent=bundle
local clientBundle=R.Instance.new('Folder');clientBundle.Name='IslandClients';clientBundle.Parent=bundle
for _,c in ipairs(SP:GetChildren()) do c.Parent=clientBundle end
local early=R.Instance.new('Folder');early.Name='IslandEarlyClients';early.Parent=bundle
for _,c in ipairs(dm:GetService('ReplicatedFirst'):GetChildren()) do c.Parent=early end
local lightBundle=R.Instance.new('Folder');lightBundle.Name='IslandLighting';lightBundle.Parent=bundle
for _,c in ipairs(L:GetChildren()) do c.Parent=lightBundle end
for _,d in ipairs(bundle:GetDescendants()) do assert(not d:IsA('Terrain'),'Nested Terrain in bundle') end
fs.writeFile('/tmp/island-payload.rbxm',R.serializeModel({bundle}))
for _,d in ipairs(bundle:GetDescendants()) do assert(not d:IsA('Terrain'),'Nested Terrain in bundle') end
print('BINARY MODEL PAYLOAD READY: '..#fs.readFile('/tmp/island-payload.rbxm')..' bytes')
