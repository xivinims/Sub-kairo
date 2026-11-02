local fs=require('@lune/fs')
local R=require('@lune/roblox')
local luau=require('@lune/luau')
local J=require('@lune/serde')
local V,C,I=R.Vector3,R.CFrame,R.Instance
local here='water-rpg/'
local source=R.deserializePlace(fs.readFile(here..'water-castle.rbxl'))
local W=source:GetService('Workspace')
local SS=source:GetService('ServerStorage')
local bundle=I.new('Model');bundle.Name='WaterRPGPayload'
local folders={}
for _,n in ipairs({'Workspace','ServerStorage','ReplicatedStorage','ServerScriptService','StarterPlayer','StarterGui','ReplicatedFirst','Lighting','MaterialService','SoundService'}) do
 local f=I.new('Folder');f.Name=n;f.Parent=bundle;folders[n]=f
end
local markers=I.new('Model');markers.Name='RPGMarkers';markers.ModelStreamingMode=R.Enum.ModelStreamingMode.Persistent;markers.Parent=folders.Workspace
local function marker(name,position)
 local p=I.new('Part');p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Transparency=1;p.Size=V.new(2,.4,2);p.CFrame=C.new(position);p.Parent=markers;return p
end
marker('Arrival',V.new(1678.8,8.6,1119.7));marker('MenuFocus',V.new(1290,98,2520))
local root=I.new('Model');root.Name='WaterCastleMap';root.Parent=folders.Workspace
local residents=I.new('Folder');residents.Name='Residents';residents.Parent=folders.Workspace
local profile={source='water castle.rbxl',removedScripts=0,npcs={},sourceParts=0,terrainBytes=#W.Terrain.SmoothGrid}
local function strip(container)
 for _,x in ipairs(container:GetDescendants()) do
  if x:IsA('LuaSourceContainer') or x:IsA('PackageLink') or x:IsA('ClickDetector') or x:IsA('ProximityPrompt') or x:IsA('RemoteEvent') or x:IsA('RemoteFunction') then
   if x:IsA('LuaSourceContainer') then profile.removedScripts+=1 end;x:Destroy()
  end
 end
end
local roleMap={['Silver Vendor']={'Merchant','Comerciante de prata'},['Storage Manager']={'Merchant','Responsável pelo armazém'},StableMaster={'Stable','Mestre dos estábulos'},['Nicosia Blacksmith']={'Blacksmith','Ferreiro de Nicósia'},['Nicosia Apothecary']={'Apothecary','Boticária de Nicósia'},['Lochias Pavlos']={'Guard','Guarda do castelo'},['Alexandros Costaou']={'Guard','Guarda do portão'}}
local roaming={['Johana Von Braun']=true,['Jean Deloffre']=true,['Ionas Glafcou']=true,['Fazil Olympiou']=true,['Bakach']=true,['Athanasios Demetriades']=true,['Adamos Panayi']=true}
local function uri(item,key)
 local ok,val=pcall(function() return tostring(item[key..'Content']) end)
 if ok then return val:match('Uri=(.-)%)$') or val end
 local yes,v=pcall(function() return item[key] end);return yes and tostring(v) or ''
end
local function addNPC(original,guide)
 local npc=original:Clone();strip(npc)
 local humanoid=npc:FindFirstChildOfClass('Humanoid');local hrp=npc:FindFirstChild('HumanoidRootPart')
 if not humanoid or not hrp then npc:Destroy();return end
 local index=#profile.npcs+1;local id=string.format('R%02d',index)
 local role=roleMap[original.Name] or {'Citizen','Morador'}
 npc:SetAttribute('ResidentId',id);npc:SetAttribute('DisplayName',original.Name);npc:SetAttribute('Role',guide and 'Guide' or role[1]);npc:SetAttribute('Profession',guide and 'Guia da estrada' or role[2]);npc:SetAttribute('Roam',not guide and roaming[original.Name]==true)
 npc:SetAttribute('OriginalName',original.Name);npc.ModelStreamingMode=R.Enum.ModelStreamingMode.Atomic;npc.PrimaryPart=hrp
 if guide then
  local offset=V.new(1686,10,1128)-hrp.CFrame.Position
  for _,p in ipairs(npc:GetDescendants()) do if p:IsA('BasePart') then p.CFrame=p.CFrame+offset end end
  npc.Name='Nasos — Guia';npc:SetAttribute('DisplayName','Nasos Nanakis')
 end
 local outfit={}
 for _,x in ipairs(npc:GetDescendants()) do
  if x:IsA('Shirt') then outfit.Shirt=uri(x,'ShirtTemplate') elseif x:IsA('Pants') then outfit.Pants=uri(x,'PantsTemplate') end
  if x:IsA('BasePart') then x.Anchored=true end
 end
 npc:SetAttribute('ExpectedShirt',outfit.Shirt or '');npc:SetAttribute('ExpectedPants',outfit.Pants or '')
 profile.npcs[index]={id=id,name=npc.Name,role=npc:GetAttribute('Role'),shirt=outfit.Shirt,pants=outfit.Pants,original=original:GetFullName(),pos={hrp.CFrame.X,hrp.CFrame.Y,hrp.CFrame.Z}}
 npc.Parent=residents
end
local worldNPC={}
for _,h in ipairs(W:GetDescendants()) do if h:IsA('Humanoid') and h.Parent:FindFirstChild('HumanoidRootPart') then table.insert(worldNPC,h.Parent) end end
for _,npc in ipairs(worldNPC) do addNPC(npc,false);npc:Destroy() end
local guide
for _,h in ipairs(SS:GetDescendants()) do
 if h:IsA('Humanoid') and h.Parent:FindFirstChild('HumanoidRootPart') then addNPC(h.Parent,false);if h.Parent.Name=='Nasos Nanakis' then guide=h.Parent end end
end
assert(guide,'Source guide template missing');addNPC(guide,true)
strip(W)
for _,x in ipairs(W:GetDescendants()) do
 if x:IsA('Humanoid') then x:Destroy() end
 if x:IsA('BasePart') and not x:IsA('Terrain') then x.Anchored=true;x.CanTouch=false;profile.sourceParts+=1 end
end
for _,x in ipairs(W:GetChildren()) do if not x:IsA('Terrain') and not x:IsA('Camera') then x.Parent=root end end
local terrain=I.new('TerrainRegion');terrain.Name='OriginalWaterCastleTerrain';terrain.SmoothGrid=W.Terrain.SmoothGrid
terrain.ExtentsMin=R.Vector3int16.new(-2816,-192,-512);terrain.ExtentsMax=R.Vector3int16.new(1536,256,1536);terrain.Parent=folders.ServerStorage
for _,n in ipairs({'Lighting','MaterialService','SoundService'}) do local s=source:GetService(n);strip(s);for _,child in ipairs(s:GetChildren()) do child.Parent=folders[n] end end
local shared=I.new('Folder');shared.Name='WaterRPG';shared.Parent=folders.ReplicatedStorage
for _,n in ipairs({'Action','Feedback','Ability'}) do local e=I.new('RemoteEvent');e.Name=n;e.Parent=shared end
local assets=R.deserializeModel(fs.readFile(here..'player-assets.rbxm'))[1];assets.Parent=shared
local state=I.new('Folder');state.Name='State';state:SetAttribute('WorldReady',true);state.Parent=shared
local scripts=I.new('Folder');scripts.Name='StarterPlayerScripts';scripts.Parent=folders.StarterPlayer
local count=0
for _,entry in ipairs({{shared,'Config','ModuleScript','Config.lua'},{shared,'Rules','ModuleScript','Rules.lua'},{folders.ServerScriptService,'WaterRPGServer','Script','Server.server.lua'},{folders.ServerScriptService,'Profiles','ModuleScript','Profiles.lua'},{folders.ServerScriptService,'Residents','ModuleScript','Residents.lua'},{scripts,'WaterRPGClient','LocalScript','Client.client.lua'},{scripts,'PlayerAbilities','LocalScript','Abilities.client.lua'},{folders.ServerScriptService,'PlayerAbilities','Script','Abilities.server.lua'}}) do
 local s=I.new(entry[3]);s.Name=entry[2];s.Source=fs.readFile(here..'src/'..entry[4]);luau.load(s.Source,{debugName=entry[2]});s.Parent=entry[1];count+=1
end
local training=I.new('Folder');training.Name='TrainingTargets';training.Parent=folders.Workspace
local example=R.deserializeModel(fs.readFile(here..'training-template.rbxm'))[1]
for i=1,3 do
 local model=example:Clone();model.Name='Alvo '..i;model:SetAttribute('TrainingTarget',true);model.ModelStreamingMode=R.Enum.ModelStreamingMode.Atomic
 local hrp=model:FindFirstChild('HumanoidRootPart');model.PrimaryPart=hrp
 local offset=V.new(1660+i*6,12,1144)-hrp.CFrame.Position
 for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then part.CFrame=part.CFrame+offset;part.Anchored=true end end
 model.Parent=training
end
assert(#profile.npcs>=17 and profile.sourceParts>90000 and profile.terrainBytes>1000000,'Source map incomplete')
fs.writeFile(here..'payload.rbxm',R.serializeModel({bundle}));fs.writeFile(here..'manifest.json',J.encode('json',profile,true))
print(J.encode('json',{npcs=#profile.npcs,parts=profile.sourceParts,terrainBytes=profile.terrainBytes,scripts=count,removed=profile.removedScripts}))
