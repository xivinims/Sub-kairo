local RS=game:GetService('ReplicatedStorage')
local Tags=game:GetService('CollectionService')
local T=workspace.Terrain
local C=require(RS.PhotoWorldConfig)
local Meta=require(RS.LivingMeshMeta)
local world=assert(workspace:FindFirstChild('OveryardPhotoWorld'))
local runtime=RS:WaitForChild('LivingForest')
local V,CF=Vector3.new,CFrame.new
local rng=Random.new(20261020)
local sourceVersion=game.PlaceVersion
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local assets=game:GetService('InsertService'):LoadAsset(C.AssetId)
local meshes=Instance.new('Folder');meshes.Name='Meshes';meshes.Parent=runtime
for _,p in ipairs(assets:GetDescendants())do
 if p:IsA('MeshPart')then
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.DoubleSided=true;p.RenderFidelity=Enum.RenderFidelity.Automatic
  p.CFrame=CF();p.Parent=meshes
 end
end
assets:Destroy()
for name in pairs(Meta)do assert(meshes:FindFirstChild(name),'Missing geometry '..name)end
local oldTrees={}
for _,p in ipairs(world:GetDescendants())do
 if p:IsA('Model')and p:GetAttribute('Tree')then table.insert(oldTrees,{root=p:GetAttribute('RootPosition'),height=p:GetExtentsSize().Y,name=p.Name,parent=p.Parent});p:Destroy()
 elseif p.Name=='WeatheredBench' or p.Name=='WeatheredRock' or p.Name=='LayeredSandstone' then p:Destroy()end
end
if world:FindFirstChild('Monolith')then world.Monolith:Destroy()end
local forest=Instance.new('Folder');forest.Name='LivingWoodland';forest.Parent=world
local deep=Instance.new('Folder');deep.Name='DeepForest';deep.Parent=world
-- Continuous terrain, including broad underwater shelves and the western sea.
local chunks=0
for bx=-C.Extent,C.Extent-128,128 do
 for bz=-C.Extent,C.Extent-128,128 do
  local mats,occ={},{}
  for ix=1,32 do
   mats[ix]={};occ[ix]={};local surfaces={}
   for iz=1,32 do surfaces[iz]={C.surface(bx+(ix-.5)*4,bz+(iz-.5)*4)}end
   for iy=1,36 do
    mats[ix][iy]={};occ[ix][iy]={};local low=-24+(iy-1)*4
    for iz=1,32 do
     local s=surfaces[iz];local h,mat,w=s[1],s[2],s[3];local n=math.clamp((h-low)/4,0,1)
     if n>0 then mats[ix][iy][iz]=low<h-9 and Enum.Material.Rock or mat;occ[ix][iy][iz]=n
     elseif w and w>low then mats[ix][iy][iz]=Enum.Material.Water;occ[ix][iy][iz]=math.clamp((w-low)/4,0,1)
     else mats[ix][iy][iz]=Enum.Material.Air;occ[ix][iy][iz]=0 end
    end
   end
  end
  T:WriteVoxels(Region3.new(V(bx,-24,bz),V(bx+128,120,bz+128)),4,mats,occ);chunks+=1
 end
 task.wait()
end
T:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(104,85,61))
T:SetMaterialColor(Enum.Material.Mud,Color3.fromRGB(91,88,65))
T:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(87,99,100))
local function detail(m)
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local ok=pcall(function()m.LevelOfDetail=Enum.ModelLevelOfDetail.SLIM end)
 if not ok then pcall(function()m.LevelOfDetail=Enum.ModelLevelOfDetail.StreamingMesh end)end
end
local function mesh(name,frame,k,parent)
 local p=meshes[name]:Clone();p.Size*=k;p.CFrame=frame*CF(Meta[name].center*k);p.Parent=parent;return p
end
local treeCount=0;local fruitCount=0
local function tree(name,x,z,scale,yaw,parent,special)
 local ground,_,water=C.surface(x,z);if water then return nil end
 local root=V(x,ground-.1,z);local frame=CF(root)*CFrame.Angles(0,yaw or rng:NextNumber(-math.pi,math.pi),0)
 local m=Instance.new('Model');m.Name=name;detail(m);m:SetAttribute('Tree',true);m:SetAttribute('RootPosition',root);m:SetAttribute('TreeKind',name)
 local bark=mesh(name..'Bark',frame,scale,m);bark.Name='Bark'
 local leaves=mesh(name..'Leaves',frame,scale,m);leaves.Name='Leaves';leaves:SetAttribute('WindPower',.075);leaves:SetAttribute('WindSpeed',9);Tags:AddTag(leaves,'WindShake')
 local h=Meta[name..'Leaves'].center.Y*scale;m:SetAttribute('CanopyHeight',h);m:SetAttribute('CanopyRadius',Meta[name..'Leaves'].size.X*scale*.36)
 m:SetAttribute('Evergreen',name=='HighPine');m:SetAttribute('Petals',name=='RoseBlossom' or name=='PearlBlossom')
 local radius=(name=='LakeWillow' and 2.6 or name=='HighPine' and 1.1 or 1.25)*scale
 local trunk=Instance.new('Part');trunk.Name='TrunkCollision';trunk.Size=V(radius*2,math.min(14,18*scale),radius*2);trunk.CFrame=CF(root+V(0,trunk.Size.Y/2-.25,0));trunk.Transparency=1;trunk.Anchored=true;trunk.CanTouch=true;trunk.Parent=m;m.PrimaryPart=trunk
 if not special and(name=='AncientOak' or name=='AmberMaple')and rng:NextNumber()<.18 then
  m:SetAttribute('FruitKind',name=='AncientOak' and 'Apple' or 'Orange');fruitCount+=1
 end
 m.Parent=parent or forest;Tags:AddTag(m,'LivingTree');treeCount+=1;return m
end
local names={'PearlBlossom','RoseBlossom','EmeraldWillow','AncientOak','AmberMaple'}
for i,old in ipairs(oldTrees)do
 local p=old.root
 if p and Vector2.new(p.X-12,p.Z).Magnitude>52 and C.zone(p.X,p.Z).id~='DeepForest' then
  local okay=C.open(p.X,p.Z,4)
  if okay then
   local zone=C.zone(p.X,p.Z).id;local name=zone=='BlueAutumn' and 'HighPine' or zone=='Sakura' and 'RoseBlossom' or zone=='Willow' and 'EmeraldWillow' or zone=='Golden' and(i%3==0 and 'HighPine' or 'AmberMaple')or(i%5==0 and 'PearlBlossom' or(i%3==0 and 'HighPine' or 'AncientOak'))
   tree(name,p.X,p.Z,rng:NextNumber(.75,1.25))
  end
 end
end
-- Full forest fills the removed dark architecture and the extended landscape.
for gx=-C.Extent+42,C.Extent-42,42 do for gz=-C.Extent+42,C.Extent-42,42 do
 local x,z=gx+rng:NextNumber(-13,13),gz+rng:NextNumber(-13,13)
 if math.max(math.abs(x),math.abs(z))>610 or C.zone(x,z).id=='DeepForest' then
  local okay,h=C.open(x,z,9);local h1=C.surface(x+3,z);local h2=C.surface(x,z+3)
  if okay and math.abs(h1-h)<2 and math.abs(h2-h)<2 and x>C.coast(z)+57 then
   local zone=C.zone(x,z).id;local n=rng:NextNumber();local kind=n<.28 and 'HighPine' or n<.39 and 'EmeraldWillow' or n<.46 and 'PearlBlossom' or n<.51 and 'RoseBlossom' or n<.63 and 'AmberMaple' or 'AncientOak'
   if zone=='BlueAutumn'and n<.8 then kind='HighPine'end
   tree(kind,x,z,rng:NextNumber(.78,1.35),nil,zone=='DeepForest' and deep or forest)
  end
 end
end;task.wait()end
-- Hero compositions are deliberate. The lake's central island is 26 studs high.
local hero=tree('LakeWillow',12,0,1,0,world.Willow,true);hero.Name='RootedLakeWillow';hero:SetAttribute('HeroTree',true)
local cliff=tree('CliffCrimson',C.Cliff.x,C.Cliff.z,1.1,-.35,forest,true);cliff.Name='CoastalCliffTree';cliff:SetAttribute('HeroTree',true)
for i,name in ipairs(names)do tree(name,-465+(i-1)*38,-375,.95,i*.65,deep,true)end
-- Natural shore clusters remain attached after the slopes are recarved.
for _,p in ipairs(world:GetDescendants())do if p:IsA('MeshPart')and p:GetAttribute('RootPosition')and not p.Parent:GetAttribute('Tree')then
 local root=p:GetAttribute('RootPosition');local h,_,w=C.surface(root.X,root.Z)
 if w then p:Destroy()else p.CFrame+=V(0,h-root.Y,0);p:SetAttribute('RootPosition',V(root.X,h,root.Z))end
end end
local plants=RS.PhotoGroundcover
for i=1,2100 do
 local x,z=rng:NextNumber(-1360,1980),rng:NextNumber(-1980,1980)
 local okay,h=C.open(x,z,5)
 if okay then
  local name=i%4==0 and 'FernRosette' or i%3==0 and 'WhiteFlowerPatch' or 'MeadowShrub';local p=plants[name]:Clone();local k=rng:NextNumber(.8,1.6);p.Size*=k
  p.CFrame=CF(x,h+p.Size.Y/2-.2,z)*CFrame.Angles(0,rng:NextNumber(0,6.28),0);p.Parent=forest;p:SetAttribute('WindPower',.04);Tags:AddTag(p,'WindShake')
 end
end
-- Exact requested log asset replaces all benches, with a small integrated seat.
local raw=game:GetService('InsertService'):LoadAsset(9731248486);local log=raw:FindFirstChildWhichIsA('MeshPart',true);assert(log)
local logs=Instance.new('Folder');logs.Name='TrailLogs';logs.Parent=world
for _,pos in ipairs({V(367,0,404),V(40,0,405),V(-126,0,72),V(-153,0,119),V(-425,0,-335),V(570,0,-210),V(1150,0,-620),V(800,0,1280),V(-1150,0,960),V(C.Cliff.x+47,0,C.Cliff.z+30)})do
 local m=Instance.new('Model');m.Name='TreeLog';m:SetAttribute('SourceAssetId',9731248486);detail(m)
 local p=log:Clone();p.Anchored=true;p.CanCollide=true;p.CanTouch=false;local h=C.surface(pos.X,pos.Z);p.CFrame=CF(pos.X,h+p.Size.Y/2-.45,pos.Z)*CFrame.Angles(0,rng:NextNumber(0,6.28),0);p.Parent=m
 local seat=Instance.new('Seat');seat.Name='LogSeat';seat.Size=V(2,.2,2);seat.CFrame=p.CFrame*CF(0,p.Size.Y/2-.1,0);seat.Transparency=1;seat.Anchored=true;seat.CanCollide=false;seat.Parent=m;m.Parent=logs
end;raw:Destroy()
-- Exact hidden pond, stripped only of preview cameras and lighting overrides.
raw=game:GetService('InsertService'):LoadAsset(119986768245480)
local pond=raw:FindFirstChildWhichIsA('Model');assert(pond);pond.Parent=nil;raw:Destroy();pond.Name='HiddenForestPond';pond:SetAttribute('SourceAssetId',119986768245480)
for _,p in ipairs(pond:GetDescendants())do
 if p:IsA('Camera')or p:IsA('PostEffect')or p:IsA('LuaSourceContainer')then p:Destroy()
 elseif p:IsA('BasePart')then p.Anchored=true;p.CanTouch=false end
end
local _,size=pond:GetBoundingBox();pond:ScaleTo(pond:GetScale()*46/math.max(size.X,size.Z))
local box,bsize=pond:GetBoundingBox();pond:PivotTo(pond:GetPivot()+V(C.HiddenPond.x-box.X,30-(box.Y-bsize.Y/2)-.8,C.HiddenPond.z-box.Z))
detail(pond);pond.Parent=forest;C.HiddenPond.surface=30+bsize.Y*.4
local hp=runtime:FindFirstChild('HiddenPondSurface')or Instance.new('NumberValue');hp.Name='HiddenPondSurface';hp.Value=C.HiddenPond.surface;hp.Parent=runtime
-- Preserve bridge decks, with their buried approach landings at the same grade.
for _,m in ipairs(world.Crossings:GetChildren())do
 local center=m:GetAttribute('Center');local len=m:GetAttribute('Length');local frame=CF(center)*CFrame.Angles(0,m:GetAttribute('Axis'),0)
 for side=-1,1,2 do local p=(frame*CF(side*(len/2+4),0,0)).Position;T:FillBlock(CF(p.X,center.Y-8,p.Z),V(14,16,14),Enum.Material.Ground)end
end
-- Narrow crossings on the new path/river intersections are level with the banks.
for _,s in ipairs(C.Paths)do if math.max(math.abs(s[1]),math.abs(s[2]),math.abs(s[3]),math.abs(s[4]))>620 then
 local length=Vector2.new(s[3]-s[1],s[4]-s[2]).Magnitude;local first,last=nil,nil
 for t=0,1,1/math.ceil(length/4)do local x,z=s[1]+(s[3]-s[1])*t,s[2]+(s[4]-s[2])*t;local _,_,w=C.surface(x,z);if w then first=first or V(x,w,z);last=V(x,w,z)end end
 if first and last and(last-first).Magnitude>3 then
  local dir=(last-first).Unit;local mid=(first+last)/2;local grade=mid.Y+1.3;local len=(last-first).Magnitude+18
  local m=Instance.new('Model');m.Name='LevelForestCrossing';detail(m);m.Parent=world.Crossings;m:SetAttribute('NaturalCrossing',true)
  local p=Instance.new('Part');p.Name='Deck';p.Anchored=true;p.Material=Enum.Material.WoodPlanks;p.Color=Color3.fromRGB(103,82,57);p.Size=V(7,.6,len);p.CFrame=CF(V(mid.X,grade-.3,mid.Z),V(mid.X,grade-.3,mid.Z)+dir);p.Parent=m
  for sign=-1,1,2 do local point=mid+dir*sign*(len/2+3);T:FillBlock(CF(point.X,grade-7,point.Z),V(12,14,12),Enum.Material.Ground)end
 end
end end
local L=game:GetService('Lighting');local sky=L:FindFirstChildOfClass('Sky');if sky then sky.SunAngularSize=6;sky.MoonAngularSize=8 end
L.PhotoSun.Intensity=.055;L.PhotoSun.Spread=.68;L.PhotoBloom.Intensity=.10
T.WaterTransparency=.34;T.WaterReflectance=.28;T.WaterWaveSize=.14;T.WaterWaveSpeed=6
workspace.GlobalWind=V(3.4,0,1.1)
world.PhotoWorldSpawn.Position=V(-130,C.surface(-130,95)+.15,95)
world:SetAttribute('RefinementVersion','living-forest-v12');world:SetAttribute('TreeCount',treeCount);world:SetAttribute('FruitTrees',fruitCount)
world:SetAttribute('Extent',C.Extent);world:SetAttribute('AssetLibrary',C.AssetId);world:SetAttribute('SourceVersion',sourceVersion)
return {ok=true,sourceVersion=sourceVersion,trees=treeCount,fruitTrees=fruitCount,terrainChunks=chunks,extent=C.Extent,hiddenPond=true,logs=#logs:GetChildren()}
