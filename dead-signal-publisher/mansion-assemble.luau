local fs=require('@lune/fs');local R=require('@lune/roblox');local luau=require('@lune/luau');local J=require('@lune/serde')
local V,C=R.Vector3,R.CFrame
local base=R.deserializePlace(fs.readFile('/tmp/still-here-source.rbxl'))
local original=R.deserializePlace(fs.readFile('/tmp/asset-7902470429.rbxl'));local OW=original:GetService('Workspace')
local orderly=R.deserializePlace(fs.readFile('/tmp/asset-13037825880.rbxl'))
local W=base:GetService('Workspace');local SS=base:GetService('ServerStorage');local SSS=base:GetService('ServerScriptService');local RS=base:GetService('ReplicatedStorage');local RF=base:GetService('ReplicatedFirst');local L=base:GetService('Lighting');local SP=base:GetService('StarterPlayer').StarterPlayerScripts
local wind=SP:FindFirstChild('ForestWindClient') and SP.ForestWindClient:Clone()
for _,name in ipairs({'ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','SoundService','Lighting'}) do for _,c in ipairs(base:GetService(name):GetChildren()) do c:Destroy() end end
for _,c in ipairs(SP:GetChildren()) do c:Destroy() end
for _,c in ipairs(base:GetService('StarterPlayer').StarterCharacterScripts:GetChildren()) do c:Destroy() end
for _,c in ipairs(W:GetChildren()) do if not c:IsA('Terrain') and not c:IsA('Camera') then c:Destroy() end end
for key in pairs(W:GetAttributes()) do W:SetAttribute(key,nil) end
local catalog=R.Instance.new('Folder');catalog.Name='MansionCatalog';catalog.Parent=SS
local islands=R.Instance.new('Folder');islands.Name='Islands';local scene=R.Instance.new('Folder');scene.Name='mansion';scene.Parent=islands
local architecture=R.Instance.new('Folder');architecture.Name='Architecture';architecture.Parent=scene
local archive=R.Instance.new('Folder');archive.Name='MatchWorld';archive.Parent=SS;islands.Parent=archive
local destinations=R.Instance.new('Folder');destinations.Name='IslandDestinations';destinations.Parent=archive
local spawn=OW.SpawnLocationHouse:Clone();for _,c in ipairs(spawn:GetChildren()) do c:Destroy() end;spawn.Name='forestCurrent';spawn.Transparency=1;spawn.CanCollide=false;spawn.CanQuery=false;spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=destinations
local regions=R.Instance.new('TerrainRegion');regions.Name='MansionTerrain';regions.SmoothGrid=OW.Terrain.SmoothGrid;regions.ExtentsMin=R.Vector3int16.new(-144,-64,-192);regions.ExtentsMax=R.Vector3int16.new(144,100,144);regions.Parent=SS
W.Terrain.SmoothGrid=orderly:GetService('Workspace').Terrain.SmoothGrid
-- Clear the public menu's terrain using the empty serialized terrain from the source city.
if fs.isFile('/tmp/asset-186677844.rbxl') then local city=R.deserializePlace(fs.readFile('/tmp/asset-186677844.rbxl'));W.Terrain.SmoothGrid=city:GetService('Workspace').Terrain.SmoothGrid end
W.Terrain.Decoration=true;W.Terrain.GrassLength=.85
local childVisual={Decal=true,Texture=true,SurfaceAppearance=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true,PointLight=true,SpotLight=true,SurfaceLight=true,Attachment=true,Bone=true}
local cells={};local count={Interior=0,Exterior=0,Forest=0};local doorIds={};local nextDoor=0
local function doorRoot(part)
 local a=part
 while a and a~=OW do
  if a:IsA('BasePart') and a.Name=='Interrior_Door' then return a end
  if a.Parent and (part.Name=='Door_Knob' or part.Name=='Door_Plate') then local sibling=a.Parent:FindFirstChild('Interrior_Door');if sibling then return sibling end end
  a=a.Parent
 end
end
local function add(part,section,offset)
 if not part:IsA('BasePart') or part:IsA('Terrain') or part:IsA('SpawnLocation') then return end
 if part.Transparency>=1 and not part.CanCollide then return end
 local ancestor=part.Parent
 while ancestor do
  if ancestor:IsA('Model') and ancestor:FindFirstChildOfClass('Humanoid') then return end
  local name=ancestor.Name:lower()
  if name:find('target',1,true) or name:find('editoronly',1,true) or name:find('trigger',1,true) or name:find('animsaves',1,true) then return end
  ancestor=ancestor.Parent
 end
 local clone=part:Clone();local list=clone:GetDescendants()
 for i=#list,1,-1 do if not childVisual[list[i].ClassName] then list[i]:Destroy() end end
 clone.Anchored=true;clone.CanTouch=false;clone.CFrame+=offset or V.zero;clone:SetAttribute('MansionGrabbable',part.Size.Magnitude<5 and (part.Name:lower():find('book')~=nil or part.Name:lower():find('cup')~=nil or part.Name:lower():find('vase')~=nil))
 clone:SetAttribute('MansionSource',section=='Forest' and '13037825880' or '7902470429')
 for _,light in ipairs(clone:GetDescendants()) do if light:IsA('Light') then light.Shadows=false;light.Range=math.min(light.Range,30);light.Brightness=math.min(light.Brightness,2.5) end end
 local root=section~='Forest' and doorRoot(part)
 if root then
  if not doorIds[root] then nextDoor+=1;doorIds[root]=nextDoor end
  clone:SetAttribute('MansionDoorId',doorIds[root]);clone:SetAttribute('DoorOriginalRoot',root.CFrame)
  if root==part then clone:SetAttribute('MansionDoor',true);if part:GetFullName():find('FrontDoor',1,true) then clone:SetAttribute('FrontEntrance',true) end end
 end
 local pos=(root and root.CFrame.Position) or clone.CFrame.Position
 local key=section..'_'..math.floor(pos.X/64)..'_'..math.floor(pos.Z/64)
 if not cells[key] then local c=R.Instance.new('Model');c.Name=key;c:SetAttribute('CellCenter',V.new((math.floor(pos.X/64)+.5)*64,0,(math.floor(pos.Z/64)+.5)*64));c:SetAttribute('Section',section);c.Parent=catalog;cells[key]=c end
 if math.max(clone.Size.X,clone.Size.Z)>170 and not root then clone.Parent=architecture else clone.Parent=cells[key] end
 count[section]+=1
end
for _,p in ipairs(OW.Content.Interior:GetDescendants()) do add(p,'Interior') end
for _,p in ipairs(OW.Content.Exterior.House:GetDescendants()) do add(p,'Exterior') end
for _,p in ipairs(OW.Content.Exterior.Props:GetDescendants()) do add(p,'Exterior') end
-- Orderly's forest is generated from this authored tree template, not a prebuilt tree collection.
local tree=assert(orderly:GetService('ReplicatedStorage').Dreams.EmmaDream.Map:FindFirstChild('Realistic Tree'),'Orderly tree template missing')
local min=V.new(math.huge,math.huge,math.huge);local max=-min
for _,p in ipairs(tree:GetDescendants()) do if p:IsA('BasePart') then local v=p.CFrame.Position;local s=p.Size*.5;min=V.new(math.min(min.X,v.X-s.X),math.min(min.Y,v.Y-s.Y),math.min(min.Z,v.Z-s.Z));max=V.new(math.max(max.X,v.X+s.X),math.max(max.Y,v.Y+s.Y),math.max(max.Z,v.Z+s.Z)) end end
local sourceBase=V.new((min.X+max.X)/2,min.Y,(min.Z+max.Z)/2)
local library=R.Instance.new('Model');library.Name='OrderlyTree';library.WorldPivot=C.new();library.Parent=SS
for _,part in ipairs(tree:GetDescendants()) do if part:IsA('BasePart') then
 local copy=part:Clone();for _,d in ipairs(copy:GetChildren()) do if not childVisual[d.ClassName] then d:Destroy() end end;copy.CFrame-=sourceBase;copy.Anchored=true;copy.CanTouch=false;copy.Parent=library
end end
assert(#library:GetChildren()>=2,'Incomplete Orderly tree')
-- Forest placements are generated/grounded in the native initializer, outside the mansion footprint.
W:SetAttribute('ForestSource','13037825880');W:SetAttribute('MansionSource','7902470429');W:SetAttribute('MansionParts',count.Interior+count.Exterior);W:SetAttribute('MansionRoomCount',#OW.Content.Interior:GetChildren());W:SetAttribute('MansionDoors',nextDoor)
W:SetAttribute('DeadSignalBuildId','still-here-duvall-forest-v1');W:SetAttribute('IslandWorldReady',false);W:SetAttribute('EntrancePosition',V.new(0,16,-26.4));W:SetAttribute('SessionArchitecture','public-menu-reserved-match-v1');W:SetAttribute('DisasterPhase','Calm')
W.StreamingEnabled=true;W.StreamingMinRadius=64;W.StreamingTargetRadius=128
base:GetService('Players').CharacterAutoLoads=false
local runtime=R.Instance.new('Folder');runtime.Name='AtriumRuntime';runtime.Parent=SSS
local function install(parent,name,class,file)
 local source=fs.readFile(file);luau.load(source,{debugName=file});local s=R.Instance.new(class);s.Name=name;s.Source=source;if class~='ModuleScript' then s.Disabled=false end;s.Parent=parent
end
install(runtime,'MansionChunks','ModuleScript','mansion-chunks.luau');install(runtime,'MansionRuntime','Script','mansion-runtime.luau');install(runtime,'ResidentAppearance','ModuleScript','mansion-appearance.luau')
install(runtime,'SessionProfile','ModuleScript','session-profile.luau');install(runtime,'SessionRuntime','Script','session-server.luau');install(RF,'SessionMenuClient','LocalScript','session-menu-client.luau')
require('./mansion-ui-extract')(base,original,orderly)
require('./combat-extract')(base)
install(RS.CombatAssets,'FPSMotion','ModuleScript','fps-motion.luau')
install(runtime,'CombatRules','ModuleScript','combat-rules.luau')
install(runtime,'CombatRuntime','Script','combat-server.luau')
install(runtime,'MansionForestAI','Script','mansion-forest-ai.luau')
install(SP,'CombatClient','LocalScript','combat-client.luau')
install(SP,'MansionUIClient','LocalScript','mansion-ui-client.luau')
local combatEvent=R.Instance.new('RemoteEvent');combatEvent.Name='CombatEvent';combatEvent.Parent=RS
install(SP,'MansionClient','LocalScript','mansion-client.luau');install(RF,'IslandLoadingClient','LocalScript','islands-loading-client.luau')
for _,entry in ipairs({{'SessionMenu','RemoteFunction'},{'SessionNotice','RemoteEvent'},{'MansionEvent','RemoteEvent'}}) do local e=R.Instance.new(entry[2]);e.Name=entry[1];e.Parent=RS end
for _,sound in ipairs(original:GetDescendants()) do if sound:IsA('Sound') and sound.Name:lower():find('knock',1,true) then
 local copy=sound:Clone();for _,c in ipairs(copy:GetChildren()) do c:Destroy() end;copy.Name='MansionKnock';copy.PlayOnRemove=false;copy.Parent=RS;break
end end
require('./blackhole-extract')(base)
if wind then wind.Source=fs.readFile('forest-wind-client.luau');wind.Parent=SP end
local init=fs.readFile('mansion-initialize.luau');luau.load(init,{debugName='mansion-initialize'})
local boot="local mode=game.PrivateServerId=='' and 'Menu' or 'Match';workspace:SetAttribute('GameMode',mode);if mode=='Menu' then script:Destroy();return end\nlocal SS=game:GetService('ServerStorage');for _,c in ipairs(SS.MatchWorld:GetChildren()) do c.Parent=workspace end\nlocal ok,err=xpcall(function()\n"..init.."\nend,debug.traceback);if not ok then workspace:SetAttribute('IslandWorldError',tostring(err));error(err) end\nlocal P=game:GetService('Players');P.CharacterAutoLoads=true;for _,p in ipairs(P:GetPlayers()) do if not p.Character then p:LoadCharacterAsync() end end;script:Destroy()"
luau.load(boot,{debugName='MansionInitializer'});local script=R.Instance.new('Script');script.Name='MansionInitializer';script.Source=boot;script.Parent=runtime
for _,d in ipairs(orderly:GetService('Lighting'):GetChildren()) do if d:IsA('Sky') then local sky=d:Clone();for _,c in ipairs(sky:GetChildren()) do c:Destroy() end;sky.Parent=L;break end end
L.ClockTime=0;L.Brightness=.65;L.Ambient=R.Color3.fromRGB(17,20,26);L.OutdoorAmbient=R.Color3.fromRGB(28,34,42);L.ExposureCompensation=-.75;L.EnvironmentDiffuseScale=.2;L.EnvironmentSpecularScale=.5;L.GlobalShadows=true
local atmosphere=R.Instance.new('Atmosphere');atmosphere.Density=.27;atmosphere.Haze=1.7;atmosphere.Color=R.Color3.fromRGB(165,181,185);atmosphere.Decay=R.Color3.fromRGB(103,123,136);atmosphere.Parent=L
local grade=R.Instance.new('ColorCorrectionEffect');grade.Name='MansionGrade';grade.Saturation=-.28;grade.Contrast=.16;grade.TintColor=R.Color3.fromRGB(219,227,223);grade.Parent=L
local bloom=R.Instance.new('BloomEffect');bloom.Intensity=.22;bloom.Size=25;bloom.Threshold=1.15;bloom.Parent=L
fs.writeFile('/tmp/still-here-mansion.rbxl',R.serializePlace(base))
local bundle=R.Instance.new('Model');bundle.Name='MansionBundle'
for key,value in pairs(W:GetAttributes()) do bundle:SetAttribute(key,value) end
for _,c in ipairs(archive:GetChildren()) do c.Parent=bundle end
for _,name in ipairs({'MansionCatalog','MansionTerrain','OrderlyTree'}) do SS[name].Parent=bundle end
local assets=R.Instance.new('Folder');assets.Name='ReplicatedAssets';assets.Parent=bundle;for _,c in ipairs(RS:GetChildren()) do c.Parent=assets end
runtime.Name='Runtime';runtime.Parent=bundle
local clients=R.Instance.new('Folder');clients.Name='Clients';clients.Parent=bundle;for _,c in ipairs(SP:GetChildren()) do c.Parent=clients end
local early=R.Instance.new('Folder');early.Name='Early';early.Parent=bundle;for _,c in ipairs(RF:GetChildren()) do c.Parent=early end
local lighting=R.Instance.new('Folder');lighting.Name='Lighting';lighting.Parent=bundle;for _,c in ipairs(L:GetChildren()) do c.Parent=lighting end
fs.writeFile('/tmp/mansion-payload.rbxm',R.serializeModel({bundle}))
print('MANSION ASSEMBLED '..J.encode('json',{parts=count,doors=nextDoor,source='7902470429',forest='13037825880'}))
