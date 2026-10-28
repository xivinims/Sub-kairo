-- 2048 x 2048 stud woodland, composed from audited Creator Store trees,
-- flower/fern selections, bespoke trails, and a hand-shaped continuous terrain field.
local rng=Random.new(468271)
local map=Instance.new("Model");map.Name="OvergrownAtrium";map:SetAttribute("Environment","PineForest");map.Parent=W
local trees=Instance.new("Folder");trees.Name="Pines";trees.Parent=map
local flora=Instance.new("Folder");flora.Name="MeadowUnderstory";flora.Parent=map
local rocks=Instance.new("Folder");rocks.Name="StoneAndDeadfall";rocks.Parent=map
local routes=Instance.new("Folder");routes.Name="RouteMarkers";routes.Parent=map
local doors=Instance.new("Folder");doors.Name="Doors";doors.Parent=map
local function part(parent,name,size,cf,color,mat,solid)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=mat
 p.Anchored=true;p.CanCollide=solid==true;p.CanQuery=p.CanCollide;p.CanTouch=false;p.CastShadow=true;p.Parent=parent
 return p
end

local function mainX(z)
 return 48*math.sin((1000-z)/285)+27*math.sin((1000-z)/113)+11*math.sin((1000-z)/61)
end
local function sideX(side,z)
 if z>620 or z< -770 then return nil end
 local t=math.clamp((620-z)/1390,0,1)
 return mainX(z)+side*(245*math.sin(math.pi*t)+20*math.sin(3*math.pi*t))
end
local function trailDistance(x,z)
 local best=math.abs(x-mainX(z))
 for _,side in ipairs({-1,1}) do
  local sx=sideX(side,z)
  if sx then best=math.min(best,math.abs(x-sx)) end
 end
 return best
end
local function creekX(z)
 if z< -210 or z>70 then return nil end
 return sideX(1,z)+42+16*math.sin((z+210)/78)
end
local function rawHeight(x,z)
 local edge=math.max(math.abs(x),math.abs(z))
 local rim=math.clamp((edge-760)/265,0,1)
 local hill=19+math.noise(x/310,z/310,4)*14+math.noise(x/118,z/118,11)*4.2+math.noise(x/38,z/38,19)*1.15
 hill+=rim*rim*26
 return hill
end
local function groundHeight(x,z)
 local d=trailDistance(x,z)
 local inset=math.max(0,1-d/15)*.9
 local cx=creekX(z)
 local channel=cx and math.max(0,1-math.abs(x-cx)/10)*5.2 or 0
 return rawHeight(x,z)-inset-channel
end

-- One continuous hilly terrain field with three winding paths and soft wooded ridges.
local ny=24
for chunkX=0,7 do
 for chunkZ=0,7 do
  local minX=-1024+chunkX*256;local minZ=-1024+chunkZ*256
  local region=Region3.new(Vector3.new(minX,-16,minZ),Vector3.new(minX+256,80,minZ+256)):ExpandToGrid(4)
  local materials=table.create(64);local occupancy=table.create(64)
  for ix=1,64 do
   materials[ix]=table.create(ny);occupancy[ix]=table.create(ny)
   for iy=1,ny do materials[ix][iy]=table.create(64);occupancy[ix][iy]=table.create(64) end
   local x=minX+(ix-.5)*4
   for iz=1,64 do
    local z=minZ+(iz-.5)*4
    local d=trailDistance(x,z);local h=groundHeight(x,z)
    local cx=creekX(z);local creekDistance=cx and math.abs(x-cx) or math.huge
    local surface
    if creekDistance<6.3 then surface=Enum.Material.Water
    elseif d<9 then surface=Enum.Material.Ground
    elseif d<16 then surface=Enum.Material.LeafyGrass
    elseif h>42 and math.noise(x/43,z/43,7)>.25 then surface=Enum.Material.Rock
    elseif math.noise(x/73,z/73,2)>.19 then surface=Enum.Material.LeafyGrass
    else surface=Enum.Material.Grass end
    for iy=1,ny do
     local bottom=-16+(iy-1)*4
     materials[ix][iy][iz]=surface
     occupancy[ix][iy][iz]=math.clamp((h-bottom)/4,0,1)
    end
   end
  end
  W.Terrain:WriteVoxels(region,4,materials,occupancy)
 end
end
task.wait(3)
W.Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(104,123,62))
W.Terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(82,112,54))
W.Terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(111,91,62))
W.Terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(105,104,92))
W.Terrain:SetMaterialColor(Enum.Material.Mud,Color3.fromRGB(80,71,52))
pcall(function() W.Terrain.Decoration=true;W.Terrain.GrassLength=.9 end)
local terrainRay=RaycastParams.new();terrainRay.FilterType=Enum.RaycastFilterType.Include;terrainRay.FilterDescendantsInstances={W.Terrain}
local function ground(x,z)
 local hit=W:Raycast(Vector3.new(x,145,z),Vector3.new(0,-260,0),terrainRay)
 return hit and hit.Position.Y or groundHeight(x,z)
end

local function marker(name,x,z)
 local p=part(routes,name,Vector3.one,CFrame.new(x,ground(x,z)+3.2,z),Color3.new(),Enum.Material.SmoothPlastic,false)
 p.Transparency=1;p.CanQuery=false;p:SetAttribute("ForestCheckpoint",true);return p
end
local routePoints={
 Start={mainX(800),800},Garden={sideX(-1,540),540},Floor1={sideX(1,235),235},
 Floor2={sideX(-1,-170),-170},Floor3={mainX(-735),-735},
 VaultedHall={mainX(110),110},HaloChamber={sideX(1,-455),-455},GlassChapel={sideX(-1,-545),-545},
 CreekBend={sideX(1,-80),-80},RidgeLookout={mainX(-900),-900},MeadowRest={mainX(930),930},
}
for name,pt in pairs(routePoints) do marker(name,pt[1] or mainX(pt[2]),pt[2]) end
local spawn=Instance.new("SpawnLocation");spawn.Name="ForestTrailSpawn";spawn.Anchored=true;spawn.Size=Vector3.new(8,.2,8)
spawn.CanCollide=false;spawn.CanQuery=false;spawn.Transparency=1;spawn.Neutral=true;spawn.Duration=0
local sx,sz=mainX(800),800;local sy=ground(sx,sz)
spawn.CFrame=CFrame.lookAt(Vector3.new(sx,sy+.12,sz),Vector3.new(mainX(710),sy+.12,710));spawn.Parent=map

-- All templates are selective geometry-only copies made by SafeAssetImporter.
local treeTemplates={}
for variant=1,12 do
 local name="Ponderosa "..variant
 table.insert(treeTemplates,{template=SafeAssetImporter.Select(130515502281374,name),species="Ponderosa",minScale=1.8,maxScale=2.65})
end
local coniferNames={"Pine Tree 1","Pine Tree 2","Pine Tree 3","Pine Tree 4","Pine Tree 5","Pine Tree 6","Pine Tree 7","RedwoodTree-Var01","Tree4"}
for _,name in ipairs(coniferNames) do
 table.insert(treeTemplates,{template=SafeAssetImporter.Select(11730123582,name),species="Highland Pine",minScale=name=="RedwoodTree-Var01" and .42 or .68,maxScale=name=="RedwoodTree-Var01" and .62 or .98})
end
local accentTemplates={
 {template=SafeAssetImporter.Select(11730123582,"BeechwoodTree_Var01"),species="Beechwood",minScale=.48,maxScale=.68},
 {template=SafeAssetImporter.Select(11730123582,"BroadLeafTree_Var01"),species="Broadleaf",minScale=.78,maxScale=1.08},
 {template=SafeAssetImporter.Select(11730123582,"DogwoodTree_Var01"),species="Dogwood",minScale=1.0,maxScale=1.35},
}
local grassTemplate=SafeAssetImporter.Select(11730123582,"Short Unioned Grass")
local bushTemplate=SafeAssetImporter.Select(11730123582,"Large Bush 5")
local fernTemplate=SafeAssetImporter.Select(11730123582,"Fern")
local yellowFlowerTemplate=SafeAssetImporter.Select(11730123582,"Yellow flower")
local wildflowerTemplate=SafeAssetImporter.Select(15482908101,"Flower")
local groveTemplates={}
for i=1,3 do table.insert(groveTemplates,SafeAssetImporter.Select(134979255746081,"__FLOWER_GROVE_"..i.."__")) end
local stoneTemplate=SafeAssetImporter.Select(11730123582,"__ROCK_GROVE__")

local function treeTrunk(partInstance)
 local name=string.lower(partInstance.Name)
 if string.find(name,"trunk") or string.find(name,"tree wood") then return true end
 if string.find(name,"pine") and math.max(partInstance.Size.X,partInstance.Size.Y,partInstance.Size.Z)>12 then
  local smallest=math.min(partInstance.Size.X,partInstance.Size.Y,partInstance.Size.Z)
  return smallest<2.7
 end
 return false
end
local function verticalHalf(box,size)
 return math.abs(box.RightVector.Y)*size.X/2+math.abs(box.UpVector.Y)*size.Y/2+math.abs(box.LookVector.Y)*size.Z/2
end

local function placeModel(template,parent,name,x,z,yaw,scale,solidTrunk)
 local model=template:Clone();model.Name=name;model.Parent=parent
 if scale and math.abs(scale-1)>.001 then model:ScaleTo(scale) end
 local pivot=model:GetPivot();local rotation=pivot-pivot.Position
 model:PivotTo(rotation)
 local box,size=model:GetBoundingBox()
 local halfY=verticalHalf(box,size)
 local bottom=box.Position.Y-halfY
 local y=ground(x,z)-bottom
 model:PivotTo(CFrame.new(x,y,z)*CFrame.Angles(0,yaw,0)*rotation)
 local finalBox,finalSize=model:GetBoundingBox()
 local correction=ground(x,z)-(finalBox.Position.Y-verticalHalf(finalBox,finalSize))
 if math.abs(correction)>.001 then model:PivotTo(model:GetPivot()+Vector3.new(0,correction,0)) end
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA("BasePart") then
   p.Anchored=true;p.CanTouch=false;p.CanQuery=false;p.CanCollide=false;p.Massless=true
   if solidTrunk and treeTrunk(p) then
    p.CanCollide=true;p.CanQuery=true
    if p:IsA("MeshPart") then p.CollisionFidelity=Enum.CollisionFidelity.Box end
   end
   if p:IsA("MeshPart") then p.RenderFidelity=Enum.RenderFidelity.Performance end
  end
 end
 return model
end

-- Jittered forest grid keeps trunks spread naturally and clears every trail.
local occupied={};local function acceptsTree(x,z)
 local gx,gz=math.floor(x/34),math.floor(z/34)
 for dx=-1,1 do for dz=-1,1 do
  local list=occupied[(gx+dx)..":"..(gz+dz)]
  if list then for _,v in ipairs(list) do if (Vector2.new(x,z)-v).Magnitude<24 then return false end end end
 end end
 local key=gx..":"..gz;occupied[key]=occupied[key] or {};table.insert(occupied[key],Vector2.new(x,z));return true
end
local treeCount=0
for gx=-1000,1000,28 do
 for gz=-1000,1000,28 do
  local x=gx+rng:NextNumber(-9,9);local z=gz+rng:NextNumber(-9,9)
  local d=trailDistance(x,z)
  local cover=.9+math.noise(x/180,z/180,31)*.16
  if z>640 and z<990 and math.abs(x-mainX(z))<355 then cover=.16 end
  if z< -680 and math.abs(x-mainX(z))<170 then cover*=.58 end
  if d>24 and rng:NextNumber()<cover and acceptsTree(x,z) then
   local roll=rng:NextNumber();local variant
   if roll<.71 then variant=treeTemplates[rng:NextInteger(1,12)]
   elseif roll<.95 then variant=treeTemplates[rng:NextInteger(13,#treeTemplates)]
   else variant=accentTemplates[rng:NextInteger(1,#accentTemplates)] end
   local scale=rng:NextNumber(variant.minScale,variant.maxScale)
   local model=placeModel(variant.template,trees,"ForestTree_"..(treeCount+1),x,z,rng:NextNumber(0,math.pi*2),scale,false)
   local treeBox,treeSize=model:GetBoundingBox()
   local trunkHeight=math.clamp(treeSize.Y*.54,10,28)
   local trunkBottom=treeBox.Position.Y-verticalHalf(treeBox,treeSize)
   local collider=part(model,"TreeCollisionTrunk",Vector3.new(2.35,trunkHeight,2.35),CFrame.new(x,trunkBottom+trunkHeight*.5,z),Color3.new(),Enum.Material.SmoothPlastic,true)
   collider.Transparency=1;collider.CastShadow=false
   model:SetAttribute("ForestSpecies",variant.species);model:SetAttribute("AuditedAssetGeometry",true)
   treeCount+=1
  end
 end
end

-- Continuous pockets of grasses, ferns, flowers and shrubs along routes and meadow edges.
local grassCount,flowerCount,fernCount,bushCount=0,0,0,0
for gx=-1000,1000,13 do
 for gz=-1000,1000,13 do
  local x=gx+rng:NextNumber(-5,5);local z=gz+rng:NextNumber(-5,5)
  local d=trailDistance(x,z)
  local meadow=z>640 and z<990 and math.abs(x-mainX(z))<390
  local meadowEdge=z>470 and z<990 and math.abs(x-mainX(z))<510
  local chance=(d>8 and d<165) and .62 or 0
  if meadow then chance=math.max(chance,.68) elseif meadowEdge and d<235 then chance=math.max(chance,.28) end
  if rng:NextNumber()<chance then
   local roll=rng:NextNumber()
   if roll<.43 then
    local model=placeModel(grassTemplate,flora,"WildGrass_"..(grassCount+1),x,z,rng:NextNumber(0,math.pi*2),rng:NextNumber(.22,.43),false)
    model:SetAttribute("FoliageType","Grass");grassCount+=1
   elseif roll<.60 and bushCount<390 then
    local model=placeModel(bushTemplate,flora,"HeatherBush_"..(bushCount+1),x,z,rng:NextNumber(0,math.pi*2),rng:NextNumber(.34,.62),false)
    model:SetAttribute("FoliageType","Shrub");bushCount+=1;grassCount+=1
   elseif roll<.75 and fernCount<420 then
    local model=placeModel(fernTemplate,flora,"Fern_"..(fernCount+1),x,z,rng:NextNumber(0,math.pi*2),rng:NextNumber(.42,.82),false)
    model:SetAttribute("FoliageType","Fern");fernCount+=1;grassCount+=1
   elseif roll<.91 and flowerCount<980 then
    local template=roll<.85 and wildflowerTemplate or yellowFlowerTemplate
    local model=placeModel(template,flora,"WoodlandFlower_"..(flowerCount+1),x,z,rng:NextNumber(0,math.pi*2),rng:NextNumber(.2,.5),false)
    model:SetAttribute("FoliageType","Wildflower");flowerCount+=1;grassCount+=1
   else
    local template=groveTemplates[rng:NextInteger(1,#groveTemplates)]
    local model=placeModel(template,flora,"FlowerGrove_"..(flowerCount+1),x,z,rng:NextNumber(0,math.pi*2),rng:NextNumber(.24,.39),false)
    model:SetAttribute("FoliageType","FlowerGrove");flowerCount+=1;grassCount+=1
   end
  end
 end
end

-- Rock clusters settle into slopes; split trunks and boulder shelves define landmarks.
local rockCount=0
 for i=1,88 do
 local x=rng:NextNumber(-900,900);local z=rng:NextNumber(-920,920)
 if trailDistance(x,z)>18 then
  local model=placeModel(stoneTemplate,rocks,"MossyStoneCluster_"..i,x,z,rng:NextNumber(0,math.pi*2),rng:NextNumber(.25,.48),false)
  for _,p in ipairs(model:GetDescendants()) do
   if p:IsA("BasePart") then p.CanCollide=true;p.CanQuery=true;if p:IsA("MeshPart") then p.CollisionFidelity=Enum.CollisionFidelity.Hull end end
  end
  rockCount+=1
 end
end
local logCount=0
for i=1,68 do
 local x=rng:NextNumber(-920,920);local z=rng:NextNumber(-940,940)
 if trailDistance(x,z)>36 then
  local y=ground(x,z);local length=rng:NextNumber(15,34);local angle=rng:NextNumber(0,math.pi*2)
  local axis=Vector3.new(math.cos(angle),0,math.sin(angle));local center=Vector3.new(x,y+1.05,z)
  local frame=CFrame.lookAt(center,center+axis)*CFrame.Angles(0,math.pi/2,0)
  local log=part(rocks,"FallenPineTrunk_"..i,Vector3.new(length,2.1,2.1),frame,Color3.fromRGB(91,69,48),Enum.Material.Wood,true)
  log.Shape=Enum.PartType.Cylinder;logCount+=1
  for side=-1,1,2 do
   local cap=part(rocks,"PaleBrokenHeartwood",Vector3.new(.12,1.8,1.8),frame*CFrame.new(side*(length/2-.06),0,0),Color3.fromRGB(154,133,100),Enum.Material.Wood,false)
   cap.Shape=Enum.PartType.Cylinder
  end
 end
end

-- Stumps and branch fall keep the woodland floor varied between the large landmarks.
local stumpCount=0
for i=1,92 do
 local x=rng:NextNumber(-950,950);local z=rng:NextNumber(-950,950)
 if trailDistance(x,z)>20 then
  local y=ground(x,z);local height=rng:NextNumber(1.5,4.4);local diameter=rng:NextNumber(2.1,4.8)
  local upright=CFrame.new(x,y+height*.5,z)*CFrame.Angles(0,0,math.pi/2)
  local stump=part(rocks,"WeatheredPineStump_"..i,Vector3.new(height,diameter,diameter),upright,Color3.fromRGB(91,72,52),Enum.Material.Wood,true)
  stump.Shape=Enum.PartType.Cylinder
  local cut=part(rocks,"FreshHeartwoodCut",Vector3.new(.12,diameter*.84,diameter*.84),CFrame.new(x,y+height-.025,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(159,137,104),Enum.Material.Wood,false)
  cut.Shape=Enum.PartType.Cylinder;stumpCount+=1
 end
end
local branchCount=0
for i=1,138 do
 local x=rng:NextNumber(-940,940);local z=rng:NextNumber(-940,940)
 if trailDistance(x,z)>16 then
  local y=ground(x,z)+.38;local length=rng:NextNumber(5,15);local angle=rng:NextNumber(0,math.pi*2)
  local axis=Vector3.new(math.cos(angle),0,math.sin(angle));local center=Vector3.new(x,y,z)
  local frame=CFrame.lookAt(center,center+axis)*CFrame.Angles(0,math.pi/2,0)
  local twig=part(rocks,"RainFallenBranch_"..i,Vector3.new(length,rng:NextNumber(.22,.48),rng:NextNumber(.24,.58)),frame,Color3.fromRGB(84,67,48),Enum.Material.Wood,false)
  twig.Shape=Enum.PartType.Cylinder;branchCount+=1
 end
end

local atmosphere=Instance.new("Atmosphere");atmosphere.Name="ForestAerialPerspective";atmosphere.Density=.29;atmosphere.Offset=.08
atmosphere.Haze=2.25;atmosphere.Glare=.22;atmosphere.Color=Color3.fromRGB(220,207,172);atmosphere.Decay=Color3.fromRGB(140,148,111);atmosphere.Parent=L
L.ClockTime=16.35;L.GeographicLatitude=34;L.Brightness=2.45;L.GlobalShadows=true;L.Ambient=Color3.fromRGB(96,94,71)
L.OutdoorAmbient=Color3.fromRGB(138,137,101);L.ExposureCompensation=.08;L.EnvironmentDiffuseScale=.82;L.EnvironmentSpecularScale=.5
pcall(function() L.Technology=Enum.Technology.Future end)
local grade=Instance.new("ColorCorrectionEffect");grade.Name="ForestGoldenGrade";grade.Saturation=-.045;grade.Contrast=.09;grade.TintColor=Color3.fromRGB(255,245,218);grade.Parent=L
local bloom=Instance.new("BloomEffect");bloom.Name="ForestSoftBloom";bloom.Intensity=.19;bloom.Size=24;bloom.Threshold=1.55;bloom.Parent=L
local rays=Instance.new("SunRaysEffect");rays.Name="ForestCanopyRays";rays.Intensity=.075;rays.Spread=.78;rays.Parent=L
local clouds=Instance.new("Clouds");clouds.Name="WoodlandCloudDeck";clouds.Cover=.43;clouds.Density=.62;clouds.Color=Color3.fromRGB(241,229,202);clouds.Parent=W.Terrain
W.GlobalWind=Vector3.new(3.6,0,1.2)
pcall(function()
 W.StreamingEnabled=true;W.StreamingMinRadius=64;W.StreamingTargetRadius=1024
 W.StreamOutBehavior=Enum.StreamOutBehavior.Opportunistic
 W.ModelStreamingBehavior=Enum.ModelStreamingBehavior.Improved
end)
W:SetAttribute("ForestTreeCount",treeCount);W:SetAttribute("ForestTrailCount",3);W:SetAttribute("ForestMapSize",2048)
W:SetAttribute("ForestGrassClusters",grassCount);W:SetAttribute("ForestFlowers",flowerCount);W:SetAttribute("ForestFerns",fernCount)
W:SetAttribute("ForestRockClusters",rockCount);W:SetAttribute("ForestDeadfallLogs",logCount);W:SetAttribute("ForestStumps",stumpCount)
W:SetAttribute("ForestBranches",branchCount);W:SetAttribute("ForestDefaultFOV",65)
map:SetAttribute("ReferenceStyle","Warm conifer meadow with misted distance and natural dirt trails")
SafeAssetImporter.ClearSelectionCache()
for _,template in ipairs(treeTemplates) do template.template:Destroy() end
for _,template in ipairs(accentTemplates) do template.template:Destroy() end
for _,template in ipairs({grassTemplate,bushTemplate,fernTemplate,yellowFlowerTemplate,wildflowerTemplate,stoneTemplate}) do template:Destroy() end
for _,template in ipairs(groveTemplates) do template:Destroy() end
