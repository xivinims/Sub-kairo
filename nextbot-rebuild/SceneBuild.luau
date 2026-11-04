local fs=require('@lune/fs')
local R=require('@lune/roblox')
local serde=require('@lune/serde')
return function(dm,package)
 local function new(class,name,parent,props)
  local v=R.Instance.new(class);v.Name=name;for k,val in pairs(props or {})do if k=='Position'then v.CFrame=R.CFrame.new(val)else v[k]=val end end;v.Parent=parent;return v
 end
 local V,C=R.Vector3,R.CFrame
 local function load(id)
  local path='/tmp/nb-assets/'..id..'.rbxm';if not fs.isFile(path)then return nil end
  local ok,roots=pcall(R.deserializeModel,fs.readFile(path):gsub('^<%?xml.-%?>%s*',''));return ok and roots or nil
 end
 local removals={};local mapCatalog={}
 local maps=new('Folder','NBMaps',dm:GetService('ServerStorage'))
 for _,def in ipairs({{124805122537927,'Rocket Arena'},{123713126320438,'Construct'},{10828666356,'gm_construct'},{10828618634,'Library'},{10844642277,'Complex'},{10828489513,'Elysium'},{10819434129,'Backrooms'}})do
  local roots=load(def[1]);if not roots then continue end
  local map=new('Model',def[2],maps);local geometry=new('Model','Geometry',map)
  for _,root in ipairs(roots)do local inner=root.Name=='Game'and root:FindFirstChild('Map');if inner then inner.Parent=geometry;root:Destroy()else root.Parent=geometry end end
  local removed=0;local count=0
  for _,v in ipairs(geometry:GetDescendants())do
   if not v.Parent then continue end
   if v:IsA('LuaSourceContainer') or v:IsA('PackageLink') or v:IsA('RemoteEvent') or v:IsA('RemoteFunction') or v:IsA('Sound') or v:IsA('KeyframeSequence') or v:IsA('ScreenGui') then v:Destroy();removed+=1
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
  -- IDs exceed 32-bit numeric attribute serialization; retain their exact decimal string.
  map:SetAttribute('SourceAssetId',string.format('%.0f',def[1]));map:SetAttribute('Width',high.X-low.X);map:SetAttribute('Depth',high.Z-low.Z);map:SetAttribute('Height',high.Y-low.Y)
  local points=new('Folder','Candidates',map);local candidates={}
  for _,v in ipairs(geometry:GetDescendants())do if v:IsA('BasePart')and (v:IsA('SpawnLocation')or v.Name:lower():find('spawn')or v.Parent.Name:lower():find('spawn'))then new('Part','SpawnHint',points,{CFrame=v.CFrame+V.new(0,2,0),Size=V.new(1,1,1),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1})end end
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
 -- Menus look into the imported arena. These invisible anchors add no scenery.
 local W=dm:GetService('Workspace')
 local anchors=new('Model','MenuCameras',W);anchors.ModelStreamingMode=R.Enum.ModelStreamingMode.Persistent
 for _,name in ipairs({'Home','Shop','Inventory'})do
  new('Part',name,anchors,{CFrame=C.new(0,4,0),Size=V.new(1,1,1),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1})
 end
 new('SpawnLocation','InitialSpawn',W,{Position=V.new(0,-100,0),Size=V.new(1,1,1),Transparency=1,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Neutral=true,Duration=0})
 local templates=new('Folder','NextbotTemplates',dm:GetService('ServerStorage'))
 for _,def in ipairs({{11128061931,'Freddy'},{11448641842,'Bobo'},{10844522204,'Eye'},{13028240941,'Pack'}})do
  local roots=load(def[1]);if roots then for _,root in ipairs(roots)do
   local models={root};for _,v in ipairs(root:GetDescendants())do if v:IsA('Model') and v:FindFirstChildOfClass('Humanoid')then table.insert(models,v)end end
   for _,m in ipairs(models)do if m:IsA('Model') and m:FindFirstChildOfClass('Humanoid') and m:FindFirstChild('HumanoidRootPart')then
    local bot=m:Clone();bot.Name=def[2]=='Pack'and root.Name or def[2]
    for _,v in ipairs(bot:GetDescendants())do
     if not v.Parent then continue end
     if v:IsA('LuaSourceContainer') or v:IsA('PackageLink') or v:IsA('BodyMover')or v:IsA('ScreenGui')or v:IsA('RemoteEvent')or v:IsA('RemoteFunction')then v:Destroy()
     elseif v:IsA('BasePart')then v.Anchored=false
     elseif v:IsA('Sound')then
      local uri=tostring(v.AudioContent)
      if uri:find('4316136477',1,true)or uri:find('6866520692',1,true)then v:Destroy();continue end
      v.Playing=false;if v.Parent.Name=='HumanoidRootPart'and v.Name=='sound id'then v.Name='Idle'end end
    end
    if bot.Name=='Hitbox'then bot:Destroy();break end
    local hr=bot:FindFirstChild('HumanoidRootPart');local humanoid=bot:FindFirstChildOfClass('Humanoid');humanoid.RequiresNeck=false;humanoid.BreakJointsOnDeath=false;humanoid.AutoRotate=true
    bot.PrimaryPart=hr
    for _,piece in ipairs(bot:GetDescendants())do if piece:IsA('BasePart')and piece~=hr then
     piece.CanCollide=false;piece.Massless=true
     local weld=new('WeldConstraint','NavigationWeld',hr);weld.Part0=hr;weld.Part1=piece
    end end
    hr.CanCollide=true;hr.Massless=false
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
