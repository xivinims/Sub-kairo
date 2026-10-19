-- Targeted repair of the published v7 scene. No world reset or asset reload.
local Workspace=game:GetService("Workspace")
local Terrain=Workspace.Terrain
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")
local VERSION="2026-10-19-house-grounding-forest-v8"
local world=assert(Workspace:FindFirstChild("ReferenceWorld"),"ReferenceWorld missing")
local house=assert(world.House:FindFirstChild("JapaneseHouse"),"Japanese house missing")
local rng=Random.new(1910202608)
local function folder(parent,name)
 local f=Instance.new("Folder");f.Name=name;f.Parent=parent;return f
end
local function part(parent,name,size,cf,material,color,collide,trans)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Material=material;p.Color=color
 p.Anchored=true;p.CanCollide=collide;p.CanTouch=false;p.CanQuery=collide;p.Transparency=trans or 0
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local terrainParams=RaycastParams.new()
terrainParams.FilterType=Enum.RaycastFilterType.Include
terrainParams.FilterDescendantsInstances={Terrain}
local function ground(x,z)
 local h=Workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-500,0),terrainParams)
 if h and h.Material~=Enum.Material.Water then return h.Position,h.Normal end
 return nil
end
local function mustGround(x,z)
 local p=ground(x,z);assert(p,"No dry terrain at "..x..","..z);return p
end
local function dirt(a,b,width)
 local length=(Vector2.new(a.X,a.Z)-Vector2.new(b.X,b.Z)).Magnitude
 local steps=math.max(1,math.ceil(length/6))
 for i=0,steps do
  local p=a:Lerp(b,i/steps);local g=ground(p.X,p.Z)
  if g then
   local region=Region3.new(g-Vector3.new(width/2,4,width/2),g+Vector3.new(width/2,4,width/2)):ExpandToGrid(4)
   Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.Ground)
  end
 end
end
local oldRepair=world:FindFirstChild("GroundingRepair")
if oldRepair then oldRepair:Destroy() end
local repair=folder(world,"GroundingRepair")

-- Remove only the raised banks made by v7, keeping the surrounding map.
local function restoreFlatArea(x,z,sx,sz)
 Terrain:FillBlock(CFrame.new(x,72,z),Vector3.new(sx,240,sz),Enum.Material.Air)
 Terrain:FillBlock(CFrame.new(x,-6,z),Vector3.new(sx,52,sz),Enum.Material.Grass)
end
restoreFlatArea(0,155,330,240)
restoreFlatArea(0,-850,380,220)
for _,p in ipairs(world.Details:GetChildren()) do if p.Name=="BankBlock" then p:Destroy() end end
-- A channel BELOW the existing ground, with banks at the surrounding grade.
Terrain:FillBlock(CFrame.new(0,12,155),Vector3.new(92,26,192),Enum.Material.Air)
Terrain:FillBlock(CFrame.new(0,4,155),Vector3.new(92,16,192),Enum.Material.Water)
Terrain:FillBlock(CFrame.new(0,0,-850),Vector3.new(180,100,112),Enum.Material.Air)

local wood=Color3.fromRGB(78,54,40)
local wood2=Color3.fromRGB(96,66,48)
world.MainBridge:ClearAllChildren()
local bridge=Instance.new("Model");bridge.Name="PhotoWoodBridge";bridge.Parent=world.MainBridge
local mainY=mustGround(-64,155).Y+.12
assert(math.abs(mainY-.12-mustGround(64,155).Y)<.4,"Main bridge banks differ")
for i=-10,10 do
 part(bridge,"DeckPlank",Vector3.new(5.2,.8,23),CFrame.new(i*5.1,mainY-.4,155),Enum.Material.WoodPlanks,wood2,true)
end
for _,x in ipairs({-42,-14,14,42}) do
 part(bridge,"StoneFoot",Vector3.new(5,1.5,5),CFrame.new(x,1.25,155),Enum.Material.Slate,Color3.fromRGB(79,79,75),true)
 part(bridge,"Pillar",Vector3.new(2.6,mainY-2.3,2.6),CFrame.new(x,(mainY-2.3)/2+1.5,155),Enum.Material.Wood,wood,true)
end
for _,side in ipairs({-1,1}) do
 part(bridge,"UnderBeam",Vector3.new(108,1.5,1.8),CFrame.new(0,mainY-1.6,155+side*8),Enum.Material.Wood,wood,true)
end
for _,side in ipairs({-1,1}) do
 local z=155+side*10.5
 for x=-50,50,10 do
  part(bridge,"RailPost",Vector3.new(1.05,4.5,1.05),CFrame.new(x,mainY+2.1,z),Enum.Material.Wood,wood,true)
  part(bridge,"PostCap",Vector3.new(1.65,.55,1.65),CFrame.new(x,mainY+4.55,z),Enum.Material.Wood,wood2,true)
  part(bridge,"PostCollar",Vector3.new(1.25,.35,1.25),CFrame.new(x,mainY+3.3,z),Enum.Material.Wood,wood2,false)
 end
 for _,y in ipairs({1.5,3.6}) do
  part(bridge,"RailTop",Vector3.new(104,.6,.65),CFrame.new(0,mainY+y,z),Enum.Material.Wood,wood,true)
 end
end
for i=1,12 do
 local length=rng:NextNumber(3.5,7)
 local p=part(bridge,"HangingVine",Vector3.new(.4,length,.45),CFrame.new(rng:NextNumber(-44,44),mainY-length/2-1,155+((i%2==0) and 10.5 or -10.5)),Enum.Material.Grass,Color3.fromRGB(72,105,58),false)
 p.CastShadow=false
end
bridge:SetAttribute("DeckY",mainY)

-- Dark bridge uses a ravine cut down into the terrain, never tall banks.
world.DarkZone:ClearAllChildren()
local dark=Instance.new("Model");dark.Name="AbyssBridgeZone";dark.Parent=world.DarkZone
local darkY=mustGround(-400,-850).Y+.12
-- The grade comes from untouched surrounding terrain. The restored bank
-- voxels are solid, but the cloud terrain raycaster can retain the old hole.
-- Buried foundations provide explicit continuous footing, level with the
-- visible soil, all the way from the access path to each bridge end.
for _,side in ipairs({-1,1}) do
 local soilTop=darkY-.12
 local footing=part(dark,"BuriedBankFoundation",Vector3.new(94,soilTop+50,220),CFrame.new(side*143,(soilTop-50)/2,-850),Enum.Material.Rock,Color3.fromRGB(61,59,55),true,1)
 footing.CastShadow=false
end
local darkWood=Color3.fromRGB(43,32,27)
local metal=Color3.fromRGB(49,46,42)
for i=-13,13 do
 part(dark,"DarkDeck",Vector3.new(8.12,.8,16),CFrame.new(i*8,darkY-.4,-850),Enum.Material.WoodPlanks,darkWood,true)
end
for _,side in ipairs({-1,1}) do
 for _,y in ipairs({1.4,3.5}) do
  part(dark,"RailTop",Vector3.new(216,.55,.55),CFrame.new(0,darkY+y,-850+side*7.5),Enum.Material.Metal,metal,true)
 end
 for x=-104,104,16 do
  part(dark,"RailPost",Vector3.new(.7,4,.7),CFrame.new(x,darkY+1.9,-850+side*7.5),Enum.Material.Metal,metal,true)
 end
end
for _,x in ipairs({-72,0,72}) do
 part(dark,"Foundation",Vector3.new(6,darkY+34,6),CFrame.new(x,(darkY-34)/2,-850),Enum.Material.Rock,metal,true)
end
for _,x in ipairs({-96,-48,0,48,96}) do
 part(dark,"LampPost",Vector3.new(.7,6,.7),CFrame.new(x,darkY+3,-840.5),Enum.Material.Metal,metal,true)
 local lamp=part(dark,"Lantern",Vector3.new(1.7,2.1,1.7),CFrame.new(x,darkY+6.3,-840.5),Enum.Material.Glass,Color3.fromRGB(244,169,78),false,.25)
 local light=Instance.new("PointLight");light.Color=lamp.Color;light.Brightness=.9;light.Range=18;light.Shadows=false;light.Parent=lamp
end
local chain=folder(world.DarkZone,"Chain")
for i=0,22 do
 local t=i/22
 local p=Vector3.new(-118+90*t,darkY-32*math.sin(t*math.pi),-858)
 part(chain,"ChainLink",Vector3.new(2.4,4.6,.65),CFrame.new(p)*CFrame.Angles(0,0,(i%2==0) and 0 or math.pi/2),Enum.Material.Metal,metal,false)
end
dark:SetAttribute("DeckY",darkY)

-- The source GLB is a SINGLE concave pavilion mesh. Its old default hull
-- closed the open facade. Measurements below come from horizontal sections
-- of house-japao.glb, normalized to a longest extent of 48 (before 42/48 scale).
local previousColliders=house:FindFirstChild("AuthoredCollision")
if previousColliders then previousColliders:Destroy() end
local oldAccess=house:FindFirstChild("EntryAccess")
if oldAccess then oldAccess:Destroy() end
local mesh=assert(house:FindFirstChildWhichIsA("MeshPart",true),"House mesh missing")
assert(mesh.MeshId=="rbxassetid://75243381364972","House geometry changed; inspect before applying")
house:ScaleTo(house:GetScale()*42/math.max(mesh.Size.X,mesh.Size.Y,mesh.Size.Z))
local houseGround=mustGround(0,-70)
house:PivotTo(CFrame.new(0,houseGround.Y,-70)*CFrame.Angles(0,math.pi,0))
local bottom=mesh.Position.Y-mesh.Size.Y/2
house:PivotTo(house:GetPivot()+Vector3.new(0,houseGround.Y-bottom,0))
mesh.CanCollide=false;mesh.CanTouch=false;mesh.CanQuery=false
local collisions=folder(house,"AuthoredCollision")
local access=folder(house,"EntryAccess")
local factor=mesh.Size.X/48
local function geom(x,y,z)
 return mesh.CFrame*CFrame.new((x-24)*factor,(y-24)*factor,(z-42.551856995/2)*factor)
end
local function collider(name,x,y,z,sx,sy,sz)
 local p=part(collisions,name,Vector3.new(sx,sy,sz)*factor,geom(x,y,z),Enum.Material.Wood,wood,true,1)
 p.CastShadow=false;return p
end
local floorTop=9.05
collider("InteriorFloor",21,8.8,22.6,39,.5,31.2)
for _,p in ipairs({{7.1,8},{23.8,8},{40.1,8},{7.6,28.1},{24.6,28.1},{40.6,28.1}}) do
 collider("SupportColumn",p[1],13.5,p[2],1.05,27,1.05)
end
collider("BackWall",40.1,17,18,.55,16,20)
collider("SideWallLeft",27,17,28.05,4.6,16,.5)
collider("SideWallRight",37.3,17,28.05,6.0,16,.5)
-- Door between x=29.3 and x=34.3 stays completely clear.
collider("RearRailing",2,10.9,22.5,.5,3.8,30)
collider("RearRailing",8,10.9,37.1,12,3.8,.5)
collider("UpperRoof",23.5,33,22,43,12,36)
-- Wide stairs at the open facade, directly facing the approach from spawn.
-- Rise <= 0.8 stud, continuous landing; no need to jump into the pavilion.
for i=1,11 do
 local y=floorTop*i/11
 part(access,"EntryStep",Vector3.new(8.4,y,1.35)*factor,geom(16,y/2,-7+(i-.5)*14/11),Enum.Material.WoodPlanks,wood2,true)
end
part(access,"EntryLanding",Vector3.new(8.4,.5,2)*factor,geom(16,floorTop-.25,7),Enum.Material.WoodPlanks,wood2,true)
-- The model's original side staircase lands next to its solid back wall.
-- A real wooden porch connects that staircase to the actual side doorway.
part(access,"SidePorch",Vector3.new(7,.55,25)*factor,geom(43.75,floorTop-.275,20.5),Enum.Material.WoodPlanks,wood2,true)
part(access,"DoorLanding",Vector3.new(15,.55,5)*factor,geom(36.4,floorTop-.275,31),Enum.Material.WoodPlanks,wood2,true)
for i=1,11 do
 local y=floorTop*i/11
 part(access,"SideEntryStep",Vector3.new(1.35,y,8.4)*factor,geom(60-(i-.5)*14/11,y/2,16),Enum.Material.WoodPlanks,wood2,true)
end
for _,z in ipairs({8.8,31.8}) do
 part(access,"PorchSupport",Vector3.new(.9,floorTop,.9)*factor,geom(46.4,floorTop/2,z),Enum.Material.Wood,wood,true)
end
house:SetAttribute("VisualMaxStuds",42)
house:SetAttribute("EntranceWidth",8.4*factor)
house:SetAttribute("OriginalMaxStuds",105)
house:SetAttribute("CollisionRepairVersion",VERSION)

-- Traversable ground paths approach both bridges from their ENDS.
local routes={
 {Vector3.new(0,0,294),Vector3.new(-72,0,275),Vector3.new(-72,0,155)},
 {Vector3.new(72,0,155),Vector3.new(72,0,-22),Vector3.new(7,0,-22),Vector3.new(7,0,-42)},
 {Vector3.new(0,0,-760),Vector3.new(-126,0,-760),Vector3.new(-126,0,-850)},
 {Vector3.new(126,0,-850),Vector3.new(126,0,-980),Vector3.new(0,0,-1030)},
}
for _,route in ipairs(routes) do for i=1,#route-1 do dirt(route[i],route[i+1],10) end end

-- A few ruins distributed across the full map, using the same pale columns,
-- broken arches and moss as the reference. Keep exactly one house and torii.
local scattered=folder(repair,"ScatteredRuins")
local sites={{-1020,-1020},{0,-1110},{1020,-1030},{-1070,0},{1040,20},{-1040,1030},{0,1100},{1040,1020}}
local stone=Color3.fromRGB(208,202,190)
local moss=Color3.fromRGB(79,111,65)
for index,v in ipairs(sites) do
 local g=mustGround(v[1],v[2]);local m=Instance.new("Model");m.Name="RuinsGrove_"..index;m.Parent=scattered
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local yaw=rng:NextNumber(-math.pi,math.pi)
 local frame=CFrame.new(g)*CFrame.Angles(0,yaw,0)
 for _,x in ipairs({-9,9}) do
  part(m,"ColumnBase",Vector3.new(6,1,6),frame*CFrame.new(x,.5,0),Enum.Material.Marble,stone,true)
  local h=(index%2==0 and x==9) and 9 or 18
  local shaft=part(m,"WeatheredColumn",Vector3.new(h,3,3),frame*CFrame.new(x,1+h/2,0)*CFrame.Angles(0,0,math.pi/2),Enum.Material.Limestone,stone,true)
  shaft.Shape=Enum.PartType.Cylinder
  part(m,"ColumnCap",Vector3.new(5,1,5),frame*CFrame.new(x,h+1.5,0),Enum.Material.Marble,stone,true)
  part(m,"Ivy",Vector3.new(.3,h*.7,1.5),frame*CFrame.new(x+1.52,h*.55,0),Enum.Material.Grass,moss,false)
 end
 if index%2==1 then
  for i=0,8 do
   local a=i/8*math.pi
   part(m,"BrokenArch",Vector3.new(3.5,3.5,3),frame*CFrame.new(math.cos(a)*9,19+math.sin(a)*9,0)*CFrame.Angles(0,0,a-math.pi/2),Enum.Material.Limestone,stone,true)
  end
 end
 for i=1,4 do
  part(m,"MossyPaving",Vector3.new(5,.2,5),frame*CFrame.new(rng:NextNumber(-10,10),.08,rng:NextNumber(-6,6)),Enum.Material.Grass,moss,false)
 end
 m:SetAttribute("GroundPosition",g)
end

-- Deterministic grid coverage: every map sector receives trees. Extra groves
-- frame the paths, without trunks, foliage or shrubs blocking the entrances.
world.Forest:ClearAllChildren()
local chunks={}
local function chunkAt(x,z)
 local key=math.floor((x+1440)/192).."_"..math.floor((z+1440)/192)
 if not chunks[key] then chunks[key]=folder(world.Forest,"Chunk_"..key) end
 return chunks[key]
end
local function segmentDistance(x,z,a,b)
 local p=Vector2.new(x,z);local u=Vector2.new(a.X,a.Z);local d=Vector2.new(b.X-a.X,b.Z-a.Z)
 local t=math.clamp((p-u):Dot(d)/math.max(.001,d:Dot(d)),0,1)
 return (p-u-d*t).Magnitude
end
local function excluded(x,z)
 if math.abs(x)<37 and z>255 and z<800 then return true end
 if math.abs(x)<48 and z>-125 and z<8 then return true end
 if math.abs(x)<140 and z>30 and z<280 then return true end
 if math.abs(x)<150 and z>-470 and z<-245 then return true end
 if math.abs(x)<156 and z>-966 and z<-730 then return true end
 if (Vector2.new(x,z)-Vector2.new(36,720)).Magnitude<32 then return true end
 for _,s in ipairs(sites) do if (Vector2.new(x,z)-Vector2.new(s[1],s[2])).Magnitude<34 then return true end end
 for _,route in ipairs(routes) do for i=1,#route-1 do if segmentDistance(x,z,route[i],route[i+1])<19 then return true end end end
 return false
end
local positions={}
local buckets={}
local trees=0
local function occupied(x,z)
 local bx,bz=math.floor(x/25),math.floor(z/25)
 for dx=-1,1 do for dz=-1,1 do
  for _,p in ipairs(buckets[(bx+dx)..":"..(bz+dz)] or {}) do if (Vector2.new(x,z)-p).Magnitude<24 then return true end end
 end end
 return false
end
local leaves={Color3.fromRGB(54,87,69),Color3.fromRGB(62,94,73),Color3.fromRGB(48,78,64)}
local function addTree(x,z)
 if excluded(x,z) or occupied(x,z) then return false end
 local g,normal=ground(x,z)
 if not g or normal.Y<.95 or g.Y<18 or g.Y>25 then return false end
 trees+=1
 local m=Instance.new("Model");m.Name="ForestTree_"..trees;m.Parent=chunkAt(x,z);m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local s=rng:NextNumber(.85,1.22);local h=rng:NextNumber(21,28)*s
 local frame=CFrame.new(g)*CFrame.Angles(0,rng:NextNumber(-math.pi,math.pi),0)
 local trunkColor=Color3.fromRGB(40,51,48)
 part(m,"Trunk",Vector3.new(2.5*s,h,2.5*s),frame*CFrame.new(0,h/2,0),Enum.Material.Wood,trunkColor,true)
 for _,side in ipairs({-1,1}) do
  part(m,"Branch",Vector3.new(1.5*s,h*.48,1.5*s),frame*CFrame.new(side*3*s,h*.78,0)*CFrame.Angles(0,0,side*math.rad(-30)),Enum.Material.Wood,trunkColor,false)
 end
 for j,v in ipairs({{-6,0,0,14,7,12},{6,3,-1,14,8,12},{0,8,2,16,8,14},{-4,4,7,11,6,10},{7,6,6,11,7,11}}) do
  part(m,"Canopy",Vector3.new(v[4],v[5],v[6])*s,frame*CFrame.new(v[1]*s,h+v[2]*s,v[3]*s)*CFrame.Angles(0,(j%2==0) and .12 or -.08,0),Enum.Material.SmoothPlastic,leaves[rng:NextInteger(1,#leaves)],false)
 end
 m:SetAttribute("GroundPosition",g)
 table.insert(positions,g)
 local key=math.floor(x/25)..":"..math.floor(z/25);buckets[key]=buckets[key] or {};table.insert(buckets[key],Vector2.new(x,z))
 return true
end
for ix=0,17 do for iz=0,17 do
 local added,attempts=0,0
 while added<2 and attempts<24 do
  attempts+=1
  if addTree(-1320+(ix+rng:NextNumber(.12,.88))*146.6667,-1320+(iz+rng:NextNumber(.12,.88))*146.6667) then added+=1 end
 end
end end
-- Dense enough to frame the playable route, with full-map coverage retained.
local tries=0
while trees<768 and tries<7000 do
 tries+=1
 local x,z
 if tries%3~=0 then x=rng:NextNumber(-400,400);z=rng:NextNumber(-1150,900)
 else x=rng:NextNumber(-1320,1320);z=rng:NextNumber(-1320,1320) end
 addTree(x,z)
end
assert(trees==768,"Forest placement could not reach safe density")
local shrubs=0
for i=1,#positions,2 do
 local p=positions[i];local x=p.X+rng:NextNumber(5,10);local z=p.Z+rng:NextNumber(4,10)
 local g=ground(x,z)
 if g and not excluded(x,z) then
  shrubs+=1
  local m=Instance.new("Model");m.Name="Understory_"..shrubs;m.Parent=chunkAt(x,z)
  for j=1,3 do
   local p=part(m,"LowShrub",Vector3.new(3.3,1.8,3.1),CFrame.new(g+Vector3.new((j-2)*1.6,.9,(j%2)*1.1))*CFrame.Angles(0,j*.35,0),Enum.Material.SmoothPlastic,leaves[(j%3)+1],false)
   p.CastShadow=false
  end
 end
end
Workspace:SetAttribute("TreeCount",trees)
Workspace:SetAttribute("ShrubCount",shrubs)
Workspace:SetAttribute("HouseBottomY",mesh.Position.Y-mesh.Size.Y/2)
Workspace:SetAttribute("HouseGroundY",houseGround.Y)
Workspace:SetAttribute("WorldCorrectionVersion",VERSION)
Workspace:SetAttribute("WorldRebuildVersion",VERSION)
Workspace:SetAttribute("MainBridgeDeckY",mainY)
Workspace:SetAttribute("DarkBridgeDeckY",darkY)
-- Original streaming settings, loading screen, portal logic, water audio,
-- central ruins, one torii and the twelve sparse path stones are preserved.
return {version=VERSION,sourceVersion=game.PlaceVersion,trees=trees,shrubs=shrubs,houseVisualMax=42}
