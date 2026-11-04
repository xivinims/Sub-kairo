local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
return function(dm,package)
 local function new(class,name,parent,props)
  local v=R.Instance.new(class);v.Name=name;for k,val in pairs(props or {})do if k=='Position'then v.CFrame=R.CFrame.new(val)else v[k]=val end end;v.Parent=parent;return v
 end
 local V,C=R.Vector3,R.CFrame
 local function part(name,parent,pos,size,color)
  return new('Part',name,parent,{Position=pos,Size=size,Color=R.Color3.fromRGB(table.unpack(color)),Anchored=true,TopSurface=R.Enum.SurfaceType.Smooth,BottomSurface=R.Enum.SurfaceType.Smooth})
 end
 local function load(id)
  local path='/tmp/nb-assets/'..id..'.rbxm';if not fs.isFile(path)then return nil end
  local ok,roots=pcall(R.deserializeModel,fs.readFile(path):gsub('^<%?xml.-%?>%s*',''));return ok and roots or nil
 end
 local removals={};local mapCatalog={}
 local maps=new('Folder','NBMaps',dm:GetService('ServerStorage'))
 for _,def in ipairs({{124805122537927,'Rocket Arena'},{123713126320438,'Construct'},{10828666356,'gm_construct'},{10828618634,'Library'},{10844642277,'Complex'},{10828489513,'Elysium'},{10819434129,'Backrooms'}})do
  local roots=load(def[1]);if not roots then continue end
  local map=new('Model',def[2],maps);local geometry=new('Model','Geometry',map)
  for _,root in ipairs(roots)do root.Parent=geometry end
  local removed=0;local count=0
  for _,v in ipairs(geometry:GetDescendants())do
   if not v.Parent then continue end
   if v:IsA('LuaSourceContainer') or v:IsA('PackageLink') or v:IsA('RemoteEvent') or v:IsA('RemoteFunction') or v:IsA('Sound') or v:IsA('KeyframeSequence') then v:Destroy();removed+=1
   elseif v:IsA('Humanoid') then v.Parent:Destroy();removed+=1
   elseif v:IsA('SpawnLocation') then v.Enabled=false
   elseif v:IsA('BasePart')then v.Anchored=true;count+=1 end
  end
  if count<20 then map:Destroy();continue end
  local low=V.new(math.huge,math.huge,math.huge);local high=V.new(-math.huge,-math.huge,-math.huge)
  for _,v in ipairs(geometry:GetDescendants())do if v:IsA('BasePart')then
   low=V.new(math.min(low.X,v.CFrame.Position.X-v.Size.X/2),math.min(low.Y,v.CFrame.Position.Y-v.Size.Y/2),math.min(low.Z,v.CFrame.Position.Z-v.Size.Z/2))
   high=V.new(math.max(high.X,v.CFrame.Position.X+v.Size.X/2),math.max(high.Y,v.CFrame.Position.Y+v.Size.Y/2),math.max(high.Z,v.CFrame.Position.Z+v.Size.Z/2))
  end end
  local offset=V.new(-(low.X+high.X)/2,-low.Y,-(low.Z+high.Z)/2)
  for _,v in ipairs(geometry:GetDescendants())do if v:IsA('BasePart')then v.CFrame+=offset end end
  map:SetAttribute('SourceAssetId',def[1]);map:SetAttribute('Width',high.X-low.X);map:SetAttribute('Depth',high.Z-low.Z);map:SetAttribute('Height',high.Y-low.Y)
  local points=new('Folder','Candidates',map);local candidates={}
  for _,v in ipairs(geometry:GetDescendants())do
   if v:IsA('BasePart') and v.CanCollide and v.Size.X>=10 and v.Size.Z>=10 and math.abs(v.CFrame.UpVector.Y)>.98 then
    table.insert(candidates,v)
   end
  end
  table.sort(candidates,function(a,b)return a.CFrame.Position.Y+a.Size.Y/2<b.CFrame.Position.Y+b.Size.Y/2 end)
  for i,v in ipairs(candidates)do
   if i>160 then break end
   new('Part','Candidate'..i,points,{Position=v.CFrame.Position+V.new(0,v.Size.Y/2+3,0),Size=V.new(1,1,1),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1})
  end
  removals[def[2]]=removed;table.insert(mapCatalog,{name=def[2],assetId=def[1],parts=count,candidates=#points:GetChildren()})
 end
 assert(#mapCatalog>0,'No usable maps downloaded')
 local catalog=new('ModuleScript','MapCatalog',package);catalog.Source="return game:GetService('HttpService'):JSONDecode([==["..serde.encode('json',mapCatalog).."]==])"
 local W=dm:GetService('Workspace');local lobby=new('Model','LobbyScene',W)
 local base=V.new(0,1100,0)
 part('LobbyFloor',lobby,base+V.new(0,-2,0),V.new(340,4,300),{210,220,205})
 -- A separate scene supplies the reference menu's pastel geometry and purple inventory garden.
 for i=1,18 do
  local x=(i%6-2.5)*48;local z=math.floor((i-1)/6)*55-35;local h=18+(i%4)*13
  local color=i%3==0 and {201,115,221}or i%3==1 and {160,202,83}or {102,117,186}
  part('PastelBlock'..i,lobby,base+V.new(x,h/2,z),V.new(36,h,35),color)
 end
 local garden=base+V.new(450,0,0)
 part('GardenStage',lobby,garden+V.new(0,-2,0),V.new(220,4,190),{106,143,119})
 for i=1,20 do
  local x=(i%5-2)*43;local z=math.floor((i-1)/5)*43+15;local h=12+(i%6)*10
  part('GardenBlock'..i,lobby,garden+V.new(x,h/2,z),V.new(37,h,36),{34,53,91})
  if i%2==0 then
   part('Trunk'..i,lobby,garden+V.new(x,h+7,z),V.new(2,14,2),{61,46,80})
   local leaf=part('Crown'..i,lobby,garden+V.new(x,h+17,z),V.new(24,19,24),i%4==0 and {203,151,244}or {92,219,213});leaf.Shape=R.Enum.PartType.Ball
   new('PointLight','Glow',leaf,{Color=leaf.Color,Brightness=.4,Range=30})
  end
 end
 local fall=part('GardenWaterfall',lobby,garden+V.new(60,24,35),V.new(18,48,2),{151,139,248});fall.Transparency=.45;fall.Material=R.Enum.Material.Neon;fall.CanCollide=false
 local anchors=new('Folder','MenuCameras',W)
 new('Part','Home',anchors,{CFrame=C.lookAt(base+V.new(-35,44,-105),base+V.new(5,24,25)),Size=V.new(1,1,1),Anchored=true,CanCollide=false,CanQuery=false,Transparency=1})
 new('Part','Shop',anchors,{CFrame=C.lookAt(garden+V.new(-38,17,-65),garden+V.new(-10,15,35)),Size=V.new(1,1,1),Anchored=true,CanCollide=false,CanQuery=false,Transparency=1})
 new('Part','Inventory',anchors,{CFrame=C.lookAt(garden+V.new(35,24,-68),garden+V.new(0,18,35)),Size=V.new(1,1,1),Anchored=true,CanCollide=false,CanQuery=false,Transparency=1})
 local lsp=new('Folder','LobbySpawns',W)
 new('Part','Lobby',lsp,{Position=base+V.new(0,3,-105),Size=V.new(1,1,1),Anchored=true,CanCollide=false,CanQuery=false,Transparency=1})
 new('SpawnLocation','LobbySpawn',W,{Position=base+V.new(0,.5,-105),Size=V.new(8,1,8),Transparency=1,Anchored=true,Neutral=true,Duration=0})
 local templates=new('Folder','NextbotTemplates',dm:GetService('ServerStorage'))
 for _,def in ipairs({{11128061931,'Freddy'},{14047690859,'Nextbot'},{11448641842,'Bobo'},{10844522204,'Eye'}})do
  local roots=load(def[1]);if roots then for _,root in ipairs(roots)do
   local models={root};for _,v in ipairs(root:GetDescendants())do if v:IsA('Model') and v:FindFirstChildOfClass('Humanoid')then table.insert(models,v)end end
   for _,m in ipairs(models)do if m:IsA('Model') and m:FindFirstChildOfClass('Humanoid') and m:FindFirstChild('HumanoidRootPart')then
    local bot=m:Clone();bot.Name=def[2]
    for _,v in ipairs(bot:GetDescendants())do
     if v:IsA('LuaSourceContainer') or v:IsA('PackageLink') or v:IsA('BodyMover')then v:Destroy()
     elseif v:IsA('BasePart')then v.Anchored=false
     elseif v:IsA('Sound')then v.Playing=false end
    end
    bot.Parent=templates;break
   end end
  end end
 end
 assert(#templates:GetChildren()>0,'No usable nextbot template')
 local source=load(14026023204);local movement=new('Folder','MovementClips',package)
 if source then for _,root in ipairs(source)do
  for _,v in ipairs(root:GetDescendants())do if v:IsA('KeyframeSequence')then v:Clone().Parent=movement end end
  if root.Name=='StarterCharacter' and root:FindFirstChild('Humanoid')then
   for _,v in ipairs(root:GetDescendants())do if v:IsA('KeyframeSequence')or v:IsA('LuaSourceContainer')then v:Destroy()end end
   local saves=root:FindFirstChild('AnimSaves');if saves then saves:Destroy()end
   root.Parent=dm:GetService('StarterPlayer')
   for _,v in ipairs(root:GetDescendants())do if v:IsA('BasePart')then v.Anchored=false end end
  end
 end end
 local lighting=dm:GetService('Lighting');lighting.ClockTime=15;lighting.Brightness=2;lighting.Ambient=R.Color3.fromRGB(110,110,135);lighting.OutdoorAmbient=R.Color3.fromRGB(140,150,170)
 new('Atmosphere','Air',lighting,{Density=.22,Haze=1,Color=R.Color3.fromRGB(192,210,235)})
 new('BloomEffect','Bloom',lighting,{Intensity=.25,Size=20,Threshold=1.6})
 W.FallenPartsDestroyHeight=-200;W.Gravity=150
 fs.writeFile('/tmp/nb-assets/scenes.json',serde.encode('json',{maps=mapCatalog,removed=removals,bots=#templates:GetChildren(),movementClips=#movement:GetChildren()},true))
 return mapCatalog
end
