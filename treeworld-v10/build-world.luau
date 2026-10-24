local W=workspace
local RS=game:GetService('ReplicatedStorage')
local SS=game:GetService('ServerStorage')
local L=game:GetService('Lighting')
local T=W.Terrain
local Config=require(RS:WaitForChild('PhotoWorldConfig'))
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local sourceVersion=game.PlaceVersion
local rng=Random.new(Config.Seed)
local V=Vector3.new
local CF=CFrame.new
local rgb=Color3.fromRGB
local function folder(parent,name)local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f end
local function part(parent,name,size,cf,color,mat,collide)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true;p.Color=color;p.Material=mat or Enum.Material.Slate
 p.CanCollide=collide==true;p.CanQuery=p.CanCollide;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function beam(parent,name,a,b,width,depth,color,mat,collide)
 return part(parent,name,V(width,depth,(b-a).Magnitude),CF((a+b)/2,b),color,mat,collide)
end
-- Import and validate all replacement geometry before touching the old world.
local library=game:GetService('InsertService'):LoadAsset(Config.AssetId)
local meshes={}
for _,p in ipairs(library:GetDescendants())do
 if p:IsA('LuaSourceContainer')then p:Destroy()
 elseif p:IsA('MeshPart')then
  meshes[p.Name]=p;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  p.RenderFidelity=Enum.RenderFidelity.Automatic;p.DoubleSided=true
 end
end
local expected={'MeadowBirch','ValleyOak','ForestBroadleaf','LayeredPine','RiverPoplar','GreatWillow','BlueForestCedar','SunsetSakura','SparseOrangeMaple','CanalPalm','CanalBlockTree','GrassPatch','TallGrassPatch','FernRosette','ShoreReeds','WhiteFlowerPatch','LavenderFlowerPatch','CloverPatch','AutumnUnderstory','WeatheredRock','LayeredSandstone','ChippedStoneTile','FallenBranch'}
for _,name in ipairs(expected)do assert(meshes[name] and meshes[name].Size.Y>0,'Missing mesh '..name)end
-- Full requested scene reset. Scripts/UI are dealt with explicitly by the installer.
for _,item in ipairs(W:GetChildren())do
 if item~=T and not item:IsA('Camera') and not game:GetService('Players'):GetPlayerFromCharacter(item)then item:Destroy()end
end
T:Clear()
local old=RS:FindFirstChild('PhotoGroundcover');if old then old:Destroy()end
local cover=folder(RS,'PhotoGroundcover')
for _,name in ipairs({'GrassPatch','TallGrassPatch','FernRosette','WhiteFlowerPatch','LavenderFlowerPatch','CloverPatch','AutumnUnderstory'})do
 local p=meshes[name]:Clone();p.CFrame=CF();p.CastShadow=false;p.Parent=cover
end
local world=folder(W,'OveryardPhotoWorld')
world:SetAttribute('Version','photo-reset-v10');world:SetAttribute('AssetLibrary',Config.AssetId)
world:SetAttribute('SourceVersion',sourceVersion)
local zones={}
for _,zone in ipairs(Config.Zones)do
 local f=folder(world,zone.id);f:SetAttribute('Center',V(zone.x,24,zone.z));zones[zone.id]=f
end
T:SetMaterialColor(Enum.Material.Grass,rgb(104,151,66))
T:SetMaterialColor(Enum.Material.LeafyGrass,rgb(183,137,53))
T:SetMaterialColor(Enum.Material.Ground,rgb(117,95,69))
T:SetMaterialColor(Enum.Material.Sand,rgb(211,210,182))
T:SetMaterialColor(Enum.Material.Mud,rgb(89,81,62))
T:SetMaterialColor(Enum.Material.Slate,rgb(77,83,87))
T.WaterColor=rgb(69,137,151);T.WaterTransparency=.36;T.WaterReflectance=.17;T.WaterWaveSize=.12;T.WaterWaveSpeed=5
pcall(function()T.Decoration=true end)
W.GlobalWind=V(2.8,.1,1.4)
-- Bounded 128-stud voxel writes keep the construction memory stable.
for bx=-640,512,128 do
 for bz=-640,512,128 do
  local materials,occupancy={},{}
  for ix=1,32 do
   materials[ix]={};occupancy[ix]={}
   local surfaces={}
   for iz=1,32 do surfaces[iz]={Config.surface(bx+(ix-.5)*4,bz+(iz-.5)*4)}end
   for iy=1,20 do
    materials[ix][iy]={};occupancy[ix][iy]={};local low=-24+(iy-1)*4
    for iz=1,32 do
     local s=surfaces[iz];local h,mat,water=s[1],s[2],s[3]
     local solid=math.clamp((h-low)/4,0,1)
     if solid>0 then materials[ix][iy][iz]=low<h-8 and Enum.Material.Rock or mat;occupancy[ix][iy][iz]=solid
     elseif water and water>low then materials[ix][iy][iz]=Enum.Material.Water;occupancy[ix][iy][iz]=math.clamp((water-low)/4,0,1)
     else materials[ix][iy][iz]=Enum.Material.Air;occupancy[ix][iy][iz]=0 end
    end
   end
  end
  T:WriteVoxels(Region3.new(V(bx,-24,bz),V(bx+128,56,bz+128)),4,materials,occupancy)
 end
 task.wait()
end
local counters={trees=0,meshes=0,details=0}
-- Offset of original trunk from mesh bounds; retain the artist's origin.
local origins={MeadowBirch={.69355,-.56865},ValleyOak={.67745,-.6698},ForestBroadleaf={.9882,-1.2085},LayeredPine={0,0},RiverPoplar={.08855,.4523},GreatWillow={2.9676,-.7892},BlueForestCedar={.31935,-.10235},SunsetSakura={2.7299,.04735},SparseOrangeMaple={.20515,.07645},CanalPalm={.37985,0},CanalBlockTree={.5,3}}
local function mesh(parent,name,x,z,height,ground,yaw,bury)
 local p=meshes[name]:Clone();local size=p.Size;local k=height/size.Y
 p.Size=size*k;local off=origins[name] or {0,0}
 p.CFrame=CF(x,ground or Config.surface(x,z),z)*CFrame.Angles(0,yaw or rng:NextNumber(-math.pi,math.pi),0)*CF(off[1]*k,height/2-(bury or .18),off[2]*k)
 p:SetAttribute('RootPosition',V(x,ground or Config.surface(x,z),z));p:SetAttribute('PhotoModel',name);p.Parent=parent;counters.meshes+=1;return p
end
local treePositions={}
local function tree(parent,name,x,z,height)
 local h=Config.surface(x,z)
 local model=Instance.new('Model');model.Name=name;model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;model.Parent=parent
 local p=mesh(model,name,x,z,height,h,nil,.35)
 local radius=name=='GreatWillow' and height*.052 or height*(name=='BlueForestCedar' and .018 or .016)
 local stem=part(model,'TrunkCollision',V(radius*2,math.min(18,height*.35),radius*2),CF(x,h+math.min(18,height*.35)/2-.3,z),rgb(80,81,65),Enum.Material.Wood,true)
 stem.Transparency=1;stem.CastShadow=false;stem:SetAttribute('TrunkOnly',true)
 model:SetAttribute('RootPosition',V(x,h,z));model:SetAttribute('Tree',true)
 table.insert(treePositions,V(x,h,z));counters.trees+=1;return model
end
local function freeTree(x,z,spacing)
 local ok=Config.open(x,z,7);if not ok then return false end
 for _,p in ipairs(treePositions)do if (Vector2.new(p.X-x,p.Z-z)).Magnitude<spacing then return false end end
 return true
end
for _,zone in ipairs(Config.Zones)do
 local count=0
 for attempt=1,zone.trees*40 do
  if count>=zone.trees then break end
  local x,z=zone.x+rng:NextNumber(-184,184),zone.z+rng:NextNumber(-184,184)
  local allowed=true
  if zone.id=='Willow' then allowed=math.sqrt((x-12)^2+z*z)>140
  elseif zone.id=='Golden' then allowed=math.abs(x)>100 or z>510 or z<300 or count<5
  elseif zone.id=='Sakura' then allowed=x>505 or z>530 or x<255
  elseif zone.id=='Monolith' then allowed=math.abs(x+400)>46 end
  if allowed and freeTree(x,z,zone.id=='BlueAutumn' and 19 or 22)then
   tree(zones[zone.id],zone.types[rng:NextInteger(1,#zone.types)],x,z,rng:NextNumber(zone.height[1],zone.height[2]));count+=1
  end
 end
 zones[zone.id]:SetAttribute('DistributedTrees',count)
end
-- Willow photo: a single enormous hero tree on the island, with vertical poplar rhythm.
tree(zones.Willow,'GreatWillow',12,0,112)
for i=1,18 do
 local a=i*math.pi*2/18;local x,z=12+math.cos(a)*152,math.sin(a)*119
 if freeTree(x,z,10)then tree(zones.Willow,'RiverPoplar',x,z,rng:NextNumber(30,44))end
end
-- Canal photo: palms among squared crowns, hanging vines are part of the mesh.
for _,pos in ipairs({{-47,-270},{78,-280},{48,-470},{-68,-525},{115,-400}})do
 if freeTree(pos[1],pos[2],8)then tree(zones.Canal,'CanalPalm',pos[1],pos[2],rng:NextNumber(39,56))end
end
-- Sakura photo: the hero tree stays isolated against the evening sky.
tree(zones.Sakura,'SunsetSakura',342,397,49)
local function rock(parent,x,z,height,tint)
 local p=mesh(parent,'WeatheredRock',x,z,height,nil,nil,height*.2)
 if tint then p.Color=tint end
 -- Convex mesh collision follows the visible rock, instead of a huge invisible box.
 p.CanCollide=true;p.CanQuery=true;pcall(function()p.CollisionFidelity=Enum.CollisionFidelity.Hull end);return p
end
-- Shore rock groupings and woodland ground clutter follow biome composition.
for _,zone in ipairs(Config.Zones)do
 local parent=folder(zones[zone.id],'GroundDetails')
 for i=1,(zone.id=='Golden' and 8 or 32)do
  local x,z=zone.x+rng:NextNumber(-175,175),zone.z+rng:NextNumber(-175,175)
  if Config.open(x,z,10)then
   if i%4==0 then mesh(parent,'FallenBranch',x,z,rng:NextNumber(1.3,2.4))
   else rock(parent,x,z,rng:NextNumber(2,6))end
  end
 end
end
-- Valley photo: rows of chamfered tan stone blocks form irregular layered cliffs.
for side=-1,1,2 do
 for i=0,10 do
  local z=-174+i*28;local x=-400+side*(70+math.sin(i*.7)*13)
  local h=Config.surface(x,z);local p=mesh(zones.Valley,'LayeredSandstone',x,z,rng:NextNumber(34,49),h,side*math.pi/2,.9)
  p.CanCollide=true;p.CanQuery=true;pcall(function()p.CollisionFidelity=Enum.CollisionFidelity.Hull end)
  -- Moss and ferns at cliff feet, never in the walking corridor.
  mesh(zones.Valley,'FernRosette',x-side*19,z,3.8,h)
 end
end
-- Bridges: every walking deck and landing is built at the same grade.
local bridgeFolder=folder(world,'Crossings')
local function bridge(name,x,z,length,width,axis,grade)
 local m=Instance.new('Model');m.Name=name;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=bridgeFolder
 local frame=CF(x,grade,z)*CFrame.Angles(0,axis,0)
 local deck=part(m,'Deck',V(length,1.4,width),frame*CF(0,-.7,0),rgb(108,118,121),Enum.Material.Slate,true)
 deck:SetAttribute('WalkSurface',true)
 for side=-1,1,2 do
  for ending=-1,1,2 do
   part(m,'Pier',V(3.4,15,3.4),frame*CF(ending*(length/2-4),-7.4,side*(width/2-1)),rgb(91,106,114),Enum.Material.Slate,true)
   part(m,'StonePost',V(2.1,6,2.1),frame*CF(ending*(length/2-4),3,side*(width/2-1)),rgb(103,116,124),Enum.Material.Slate,true)
  end
  part(m,'Parapet',V(length-7,1.1,1.1),frame*CF(0,4,side*(width/2-1)),rgb(101,113,120),Enum.Material.Slate,true)
 end
 for i=-math.floor(length/6),math.floor(length/6)do
  part(m,'PavingJoint',V(.055,.025,width-2),frame*CF(i*3,.018,0),rgb(66,78,83),Enum.Material.Slate,false)
 end
 m:SetAttribute('Grade',grade);m:SetAttribute('Center',V(x,grade,z));m:SetAttribute('Axis',axis);m:SetAttribute('Length',length)
 return m
end
bridge('CanalStoneBridge',0,-320,50,13,0,24.06)
-- A low log-and-stone crossing over the autumn creek shares the route grade.
local creekZ=427+math.sin(-400*.025)*14
bridge('AutumnCreekCrossing',-400,creekZ,34,12,math.pi/2,26.1)
-- Bury explicit abutments at both ends; the deck never balances on a hill.
for _,m in ipairs(bridgeFolder:GetChildren())do
 local center=m:GetAttribute('Center');local axis=m:GetAttribute('Axis');local len=m:GetAttribute('Length');local frame=CF(center)*CFrame.Angles(0,axis,0)
 for side=-1,1,2 do
  local p=part(m,'BuriedAbutment',V(8,12,13),frame*CF(side*(len/2-1),-6,0),rgb(106,115,112),Enum.Material.Rock,true)
  local q=(frame*CF(side*(len/2+4),0,0)).Position
  T:FillBlock(CF(q.X,center.Y-8,q.Z),V(14,16,14),Enum.Material.Ground)
 end
end
local function bench(parent,x,z,yaw)
 local h=Config.surface(x,z);local frame=CF(x,h,z)*CFrame.Angles(0,yaw or 0,0)
 local m=Instance.new('Model');m.Name='WeatheredBench';m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=parent
 for j=-1,1 do part(m,'SeatSlat',V(8,.3,.7),frame*CF(0,2.4,j*.8),rgb(126,95,60),Enum.Material.Wood,true)end
 for side=-1,1,2 do
  part(m,'Leg',V(.5,2.3,2.5),frame*CF(side*2.9,1.15,0),rgb(82,73,57),Enum.Material.Wood,true)
  part(m,'BackPost',V(.45,4.1,.45),frame*CF(side*2.9,2.05,1),rgb(100,78,53),Enum.Material.Wood,true)
 end
 for j=0,1 do part(m,'BackSlat',V(8,.65,.28),frame*CF(0,3.2+j*.8,1),rgb(143,108,71),Enum.Material.Wood,true)end
end
bench(zones.Sakura,367,404,-.35);bench(zones.Golden,40,405,.2);bench(zones.Willow,-126,72,1.2)
-- Broken, individually rotated stepping tiles in the cherry meadow.
for i=0,26 do
 local t=i/26;local x=370-25*t+math.sin(t*7)*3;local z=308+88*t
 local h=Config.surface(x,z);local p=mesh(zones.Sakura,'ChippedStoneTile',x,z,.24,h+.12,rng:NextNumber(-.6,.6),0)
 p.CanCollide=false
end
-- Dark photo: immense tilted frames, layered metal ribs, fractures and red saplings.
local mon=zones.Monolith
for i=1,4 do
 local x,z=-400,-500+i*55
 local base=24;local size=96-i*13;local angle=math.rad(i%2==0 and -14 or 20)
 local frame=CF(x,base,z)*CFrame.Angles(0,math.rad(-10+i*5),angle)
 local col=rgb(57+i*3,65+i*3,72+i*3)
 for side=-1,1,2 do
  local center=frame*CF(side*(size/2),size*.55,0)
  part(mon,'TiltedMonolith',V(10,size*1.45,12),center,col,Enum.Material.Metal,true)
  for edge=-1,1,2 do part(mon,'RaisedRib',V(1.1,size*1.45,1.4),center*CF(edge*3.4,0,-6.5),rgb(47,56,65),Enum.Material.Metal,false)end
  for j=1,9 do part(mon,'PanelSeam',V(10,.18,.25),center*CF(0,-size*.65+j*size*.13,-6.15),rgb(31,40,48),Enum.Material.Metal,false)end
 end
 local lintel=frame*CF(0,size*1.2,0)
 part(mon,'BrokenLintel',V(size+10,10,12),lintel,col,Enum.Material.Metal,true)
 for j=1,11 do part(mon,'LintelJoint',V(.15,10,.3),lintel*CF(-size/2+j*size/12,0,-6.2),rgb(35,43,50),Enum.Material.Metal,false)end
end
for i=1,54 do
 local x,z=-400+rng:NextNumber(-110,110),-400+rng:NextNumber(-165,165)
 if Config.pathDistance(x,z)>8 then
  local h=Config.surface(x,z);local s=rng:NextNumber(.4,3.4)
  part(mon,'FractureDebris',V(s,s*.4,s*1.8),CF(x,h+s*.2,z)*CFrame.Angles(rng:NextNumber(-.4,.4),rng:NextNumber(-3,3),rng:NextNumber(-.4,.4)),rgb(62,70,77),Enum.Material.Slate,false)
 end
end
-- Thin puddles lie on the ground rather than emitting airborne water particles.
for i=1,12 do
 local x,z=-400+rng:NextNumber(-85,85),-400+rng:NextNumber(-140,140);local h=Config.surface(x,z)
 local p=part(mon,'RainPuddle',V(rng:NextNumber(5,12),.045,rng:NextNumber(3,8)),CF(x,h+.03,z)*CFrame.Angles(0,rng:NextNumber(-3,3),0),rgb(87,102,110),Enum.Material.Glass,false)
 p.Transparency=.4;p.Reflectance=.16;p.CastShadow=false
end
-- Natural pond: tall rear rocks, descending water ribbons, reeds and lily pads.
local pond=zones.Pond
for i=1,15 do
 local a=i*2.399;local x,z=330+math.cos(a)*rng:NextNumber(8,32),-77+math.sin(a)*rng:NextNumber(4,19)
 rock(pond,x,z,rng:NextNumber(20,51),rgb(199,198,179))
end
local fall=folder(pond,'Waterfall')
for i=1,5 do
 local x=328+(i-3)*1.8
 local a,b=V(x,65,-82),V(x+2,22,-58)
 local p=beam(fall,'WaterRibbon',a,b,2.1,.22,rgb(196,225,224),Enum.Material.Glass,false)
 p.Transparency=.28;p.CastShadow=false
end
for i=1,28 do
 local a=i*math.pi*2/28;local x,z=400+math.cos(a)*99,math.sin(a)*76
 local h,_,w=Config.surface(x,z)
 if not w and Config.pathDistance(x,z)>7 then
  mesh(pond,'ShoreReeds',x,z,rng:NextNumber(3,5),h)
  mesh(pond,'CloverPatch',x+2,z-2,.6,h)
  if i%3==0 then rock(pond,x,z,rng:NextNumber(4,9))end
 end
end
for i=1,42 do
 local x,z=rng:NextNumber(350,465),rng:NextNumber(20,53);local _,_,w=Config.surface(x,z)
 if w then
  local p=part(pond,'LilyPad',V(.07,rng:NextNumber(1,2.3),rng:NextNumber(1,2.3)),CF(x,w+.07,z)*CFrame.Angles(0,0,math.pi/2),rgb(102,141,57),Enum.Material.SmoothPlastic,false)
  p.Shape=Enum.PartType.Cylinder;p.CastShadow=false
 end
end
-- Canal fences and a small, contained fire from the reference.
for i=0,8 do
 local x,z=-70+i*7,-450
 local h=Config.surface(x,z)
 part(zones.Canal,'FencePost',V(.55,4,.55),CF(x,h+2,z),rgb(158,168,153),Enum.Material.Wood,true)
 if i<8 then for y=1,2 do part(zones.Canal,'FenceRail',V(7,.35,.35),CF(x+3.5,h+y*1.35,z),rgb(158,168,153),Enum.Material.Wood,false)end end
end
local fireBase=mesh(zones.Canal,'FallenBranch',65,-390,1.4)
local fire=Instance.new('Fire');fire.Size=3;fire.Heat=2;fire.Color=rgb(255,164,62);fire.SecondaryColor=rgb(255,95,26);fire.Parent=fireBase
local light=Instance.new('PointLight');light.Color=rgb(255,175,81);light.Brightness=.8;light.Range=14;light.Parent=fireBase
-- Spawn is a normal dry trail landing with full headroom.
local spawn=Instance.new('SpawnLocation');spawn.Name='PhotoWorldSpawn';spawn.Size=V(10,.6,10);spawn.CFrame=CF(Config.Spawn.X,Config.surface(Config.Spawn.X,Config.Spawn.Z)+.15,Config.Spawn.Z)
spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=world
for _,effect in ipairs(L:GetChildren())do if effect:IsA('PostEffect')or effect:IsA('Atmosphere')or effect:IsA('Sky')then effect:Destroy()end end
L.ClockTime=11;L.Brightness=2.3;L.GlobalShadows=true;L.Ambient=rgb(102,119,125);L.OutdoorAmbient=rgb(132,147,151);L.EnvironmentDiffuseScale=.7;L.EnvironmentSpecularScale=.45;L.ExposureCompensation=.03
local at=Instance.new('Atmosphere');at.Name='PhotoAtmosphere';at.Density=.24;at.Haze=1.4;at.Color=rgb(155,213,225);at.Decay=rgb(116,143,155);at.Parent=L
local cc=Instance.new('ColorCorrectionEffect');cc.Name='PhotoGrade';cc.Saturation=.06;cc.Contrast=.08;cc.TintColor=rgb(211,245,236);cc.Parent=L
local bloom=Instance.new('BloomEffect');bloom.Name='PhotoBloom';bloom.Intensity=.12;bloom.Size=18;bloom.Threshold=1.7;bloom.Parent=L
local sun=Instance.new('SunRaysEffect');sun.Name='PhotoSun';sun.Intensity=.035;sun.Spread=.45;sun.Parent=L
local sky=Instance.new('Sky');sky.Name='PhotoSky';sky.CelestialBodiesShown=true;sky.StarCount=650;sky.Parent=L
local clouds=T:FindFirstChildOfClass('Clouds')or Instance.new('Clouds');clouds.Cover=.36;clouds.Density=.48;clouds.Color=rgb(240,242,238);clouds.Parent=T
library:Destroy()
world:SetAttribute('TreeCount',counters.trees);world:SetAttribute('MeshCount',counters.meshes)
W:SetAttribute('PhotoWorldVersion','photo-reset-v10');W:SetAttribute('OldMapRemoved',true)
W:SetAttribute('WorldCorrectionVersion',nil)
return {ok=true,sourceVersion=sourceVersion,trees=counters.trees,meshes=counters.meshes,zones=9,assetId=Config.AssetId}
