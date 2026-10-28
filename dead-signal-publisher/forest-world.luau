-- Deterministic, original forest: continuous terrain and three joined trails.
local rng=Random.new(93841)
local map=Instance.new("Model");map.Name="OvergrownAtrium";map:SetAttribute("Environment","PineForest");map.Parent=W
local trees=Instance.new("Folder");trees.Name="Pines";trees.Parent=map
local flora=Instance.new("Folder");flora.Name="MeadowUnderstory";flora.Parent=map
local routes=Instance.new("Folder");routes.Name="RouteMarkers";routes.Parent=map
local doors=Instance.new("Folder");doors.Name="Doors";doors.Parent=map
local function part(parent,name,size,cf,color,mat,solid)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=mat;p.Anchored=true;p.CanCollide=solid==true;p.CanQuery=p.CanCollide;p.CanTouch=false;p.CastShadow=true;p.Parent=parent;return p
end
local function height(x,z) return 7+math.noise(x/125,z/125,4)*10+math.noise(x/58,z/58,9)*2+.012*(-z+260) end
local paths={}
for i=0,64 do
 local z=260-i*8;table.insert(paths,{x=math.sin((260-z)/95)*24,z=z,route=1})
end
-- Two side loops depart and rejoin the main trail organically.
for side=-1,1,2 do for i=0,48 do
 local t=i/48;local z=160-t*330
 table.insert(paths,{x=math.sin((260-z)/95)*24+side*math.sin(t*math.pi)*108,z=z,route=side<0 and 2 or 3})
end end
local function distance(x,z)
 local best=math.huge
 for _,v in ipairs(paths) do local d=(x-v.x)^2+(z-v.z)^2;if d<best then best=d end end
 return math.sqrt(best)
end
local function point(name,x,z)
 local p=part(routes,name,Vector3.one,CFrame.new(x,height(x,z)+4,z),Color3.new(),Enum.Material.SmoothPlastic,false);p.Transparency=1;return p
end
point("Start",0,242);point("Garden",math.sin(160/95)*24,100)
point("Floor1",-88,0);point("Floor2",90,0);point("Floor3",math.sin(460/95)*24,-200)
point("VaultedHall",-70,60);point("HaloChamber",70,60);point("GlassChapel",0,-120)
local region=Region3.new(Vector3.new(-256,-16,-288),Vector3.new(256,48,288)):ExpandToGrid(4)
local materials={};local occupancy={}
for ix=1,128 do
 materials[ix]={};occupancy[ix]={}
 for iy=1,16 do materials[ix][iy]={};occupancy[ix][iy]={} end
 for iz=1,144 do
  local x=-256+(ix-.5)*4;local z=-288+(iz-.5)*4
  local d=distance(x,z);local ground=height(x,z)
  -- The walking path is slightly recessed, with continuous soft banks.
  local inset=math.max(0,1-d/12)*.6;ground-=inset
  for iy=1,16 do
   local bottom=-16+(iy-1)*4
   occupancy[ix][iy][iz]=math.clamp((ground-bottom)/4,0,1)
   materials[ix][iy][iz]=d<6.5+math.noise(x/12,z/12)*1.5 and Enum.Material.Ground or Enum.Material.Grass
  end
 end
end
W.Terrain:WriteVoxels(region,4,materials,occupancy)
-- Terrain collision meshes are built asynchronously after voxel edits.
task.wait(2)
W.Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(81,100,46));W.Terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(111,100,73))
pcall(function() W.Terrain.Decoration=true;W.Terrain.GrassLength=.85 end)
local query=RaycastParams.new();query.FilterType=Enum.RaycastFilterType.Include;query.FilterDescendantsInstances={W.Terrain}
local function ground(x,z)
 local hit=W:Raycast(Vector3.new(x,50,z),Vector3.new(0,-100,0),query)
 return hit and hit.Position.Y or height(x,z)
end
-- Move checkpoint markers to actual smoothed terrain, not the analytic approximation.
for _,p in ipairs(routes:GetChildren()) do p.Position=Vector3.new(p.Position.X,ground(p.Position.X,p.Position.Z)+3.3,p.Position.Z) end
local spawn=Instance.new("SpawnLocation");spawn.Name="AtriumSpawn";spawn.Anchored=true;spawn.Size=Vector3.new(8,.2,8);spawn.CanCollide=false;spawn.Transparency=1;spawn.Neutral=true;spawn.Duration=0;spawn.CFrame=CFrame.lookAt(Vector3.new(0,ground(0,242)+.12,242),Vector3.new(0,ground(0,242)+.12,0));spawn.Parent=map
local accepted={}
for attempt=1,1600 do
 if #accepted>=145 then break end
 local x=rng:NextNumber(-230,230);local z=rng:NextNumber(-260,265)
 if distance(x,z)>15 then
  local valid=true
  for _,v in ipairs(accepted) do if (Vector2.new(x,z)-v).Magnitude<23 then valid=false;break end end
  if valid then table.insert(accepted,Vector2.new(x,z)) end
 end
end
for index,v in ipairs(accepted) do
 local x,z=v.X,v.Y;local y=ground(x,z);local h=rng:NextNumber(40,69);local radius=rng:NextNumber(7.5,12)
 local model=Instance.new("Model");model.Name="Pine"..index;model.Parent=trees;model:SetAttribute("RootPosition",Vector3.new(x,y,z))
 local trunk=part(model,"Trunk",Vector3.new(h,2.2,2.2),CFrame.new(x,y+h/2,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(92+rng:NextInteger(-12,12),65,43),Enum.Material.Wood,true);trunk.Shape=Enum.PartType.Cylinder
 local near=math.abs(x)<150 and z> -180
 local levels=near and 8 or 5
 for level=1,levels do
  local t=level/(levels+1);local cy=y+h*(.22+t*.73);local reach=radius*(1-t*.8)
  local count=near and 5 or 3
  for arm=1,count do
   local a=arm*math.pi*2/count+level*1.83+rng:NextNumber(-.35,.35)
   local length=reach*rng:NextNumber(.85,1.2)
   local cf=CFrame.new(x,cy,z)*CFrame.Angles(0,a,0)*CFrame.new(0,rng:NextNumber(-.6,.6),length*.35)*CFrame.Angles(math.rad(-12),0,0)
   local frond=part(model,"NeedleBough",Vector3.new(length*.75,rng:NextNumber(1.5,2.7),length*1.4),cf,Color3.fromRGB(rng:NextInteger(63,89),rng:NextInteger(79,104),rng:NextInteger(35,50)),Enum.Material.Grass,false)
   local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Scale=Vector3.new(1,.65,1);mesh.Parent=frond
  end
 end
 -- Root flare settles into the hillside rather than hovering above it.
 for arm=1,3 do
  local a=arm*2.094;local p=part(model,"RootFlare",Vector3.new(.7,.7,4),CFrame.new(x+math.sin(a)*1.3,y+.15,z+math.cos(a)*1.3)*CFrame.Angles(0,a,math.rad(10)),Color3.fromRGB(77,58,40),Enum.Material.Wood,false)
 end
end
-- Taller grass at trail edges, low fern-like fronds and white wildflowers in patches.
for i=1,800 do
 local sample=paths[rng:NextInteger(1,#paths)];local side=rng:NextNumber()<.5 and -1 or 1
 local x=sample.x+side*rng:NextNumber(9,22);local z=sample.z+rng:NextNumber(-5,5)
 local d=distance(x,z)
 if d>8 and math.abs(z)<265 then
  local y=ground(x,z)
  local cf=CFrame.new(x,y+.7,z)*CFrame.Angles(0,rng:NextNumber(0,6.28),rng:NextNumber(-.2,.2))
  local p=Instance.new("WedgePart");p.Name="GrassBladeCluster";p.Size=Vector3.new(.08,rng:NextNumber(.8,1.9),rng:NextNumber(.4,.9));p.CFrame=cf;p.Color=Color3.fromRGB(93+rng:NextInteger(-12,12),112,48);p.Material=Enum.Material.Grass;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=flora
  if i%3==0 then
   local flower=part(flora,"WhiteWildflower",Vector3.new(.65,.1,.65),CFrame.new(x,y+.85,z),Color3.fromRGB(226,223,196),Enum.Material.SmoothPlastic,false);flower.Shape=Enum.PartType.Ball;flower.CastShadow=false
   part(flora,"FlowerCentre",Vector3.new(.17,.13,.17),CFrame.new(x,y+.92,z),Color3.fromRGB(171,140,52),Enum.Material.SmoothPlastic,false).Shape=Enum.PartType.Ball
  end
 end
end
for i=1,55 do
 local x=rng:NextNumber(-200,200);local z=rng:NextNumber(-240,245)
 if distance(x,z)>12 then
  local y=ground(x,z);local s=rng:NextNumber(2,5)
  local p=part(flora,"WeatheredBoulder",Vector3.new(s*1.3,s*.7,s),CFrame.new(x,y+s*.15,z)*CFrame.Angles(rng:NextNumber(-.3,.3),rng:NextNumber()*6,.1),Color3.fromRGB(108,105,87),Enum.Material.Slate,true);p.Shape=Enum.PartType.Ball
 end
end
local atmosphere=Instance.new("Atmosphere");atmosphere.Name="ForestAerialPerspective";atmosphere.Density=.33;atmosphere.Offset=.12;atmosphere.Haze=2.1;atmosphere.Glare=.18;atmosphere.Color=Color3.fromRGB(205,196,163);atmosphere.Decay=Color3.fromRGB(126,131,106);atmosphere.Parent=L
L.ClockTime=16.1;L.GeographicLatitude=32;L.Brightness=2.25;L.GlobalShadows=true;L.Ambient=Color3.fromRGB(83,85,67);L.OutdoorAmbient=Color3.fromRGB(116,119,93);L.ExposureCompensation=.05;L.EnvironmentDiffuseScale=.8;L.EnvironmentSpecularScale=.45
pcall(function() L.Technology=Enum.Technology.Future end)
local grade=Instance.new("ColorCorrectionEffect");grade.Name="ForestGoldenGrade";grade.Saturation=-.08;grade.Contrast=.08;grade.TintColor=Color3.fromRGB(255,244,214);grade.Parent=L
local bloom=Instance.new("BloomEffect");bloom.Intensity=.16;bloom.Size=20;bloom.Threshold=1.6;bloom.Parent=L
local rays=Instance.new("SunRaysEffect");rays.Intensity=.045;rays.Spread=.8;rays.Parent=L
local clouds=Instance.new("Clouds");clouds.Cover=.48;clouds.Density=.65;clouds.Color=Color3.fromRGB(241,230,203);clouds.Parent=W.Terrain
W.GlobalWind=Vector3.new(3,0,1)
W:SetAttribute("ForestTreeCount",#accepted);W:SetAttribute("ForestTrailCount",3);W:SetAttribute("ForestDefaultFOV",65)
