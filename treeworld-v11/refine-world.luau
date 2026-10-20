local W=workspace
local RS=game:GetService('ReplicatedStorage')
local T=W.Terrain
local L=game:GetService('Lighting')
local C=require(RS.PhotoWorldConfig)
local Meta=require(RS.PhotoMeshMeta)
local world=assert(W:FindFirstChild('OveryardPhotoWorld'),'Photo world is missing')
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,'Wrong target')
local sourceVersion=game.PlaceVersion
local V=Vector3.new
local CF=CFrame.new
local rgb=Color3.fromRGB
local rng=Random.new(2010202611)
local assets=game:GetService('InsertService'):LoadAsset(C.AssetId)
local templates={}
for _,p in ipairs(assets:GetDescendants())do
 if p:IsA('LuaSourceContainer')then p:Destroy()
 elseif p:IsA('MeshPart')then
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.DoubleSided=true;p.RenderFidelity=Enum.RenderFidelity.Automatic;templates[p.Name]=p
 end
end
for name in pairs(Meta)do assert(templates[name],'Imported plant missing: '..name)end
local removed=0
for _,p in ipairs(world:GetDescendants())do
 if p.Name=='WeatheredRock' or p.Name=='LayeredSandstone' or p.Name=='FractureDebris' then p:Destroy();removed+=1 end
end
local previous=world:FindFirstChild('ShoreAndUnderstory');if previous then previous:Destroy()end
local planted=Instance.new('Folder');planted.Name='ShoreAndUnderstory';planted.Parent=world
local function plant(name,x,z,height,y,yaw,parent)
 local meta=assert(Meta[name]);local p=templates[name]:Clone();local scale=height/p.Size.Y;local k=height/meta.height
 p.Size*=scale;p.CFrame=CF(x,y or C.surface(x,z),z)*CFrame.Angles(0,yaw or rng:NextNumber(-math.pi,math.pi),0)*CF(meta.centerX*k,height/2-.18,meta.centerZ*k)
 p:SetAttribute('PhotoModel',name);p:SetAttribute('RootPosition',V(x,y or C.surface(x,z),z));p.CastShadow=height>5;p.Parent=parent or planted;return p
end
-- Re-carve only the affected terrain regions. The same surface is used for footing.
T:SetMaterialColor(Enum.Material.Sandstone,rgb(174,146,103))
T:SetMaterialColor(Enum.Material.Rock,rgb(132,137,123))
for bx=-640,512,128 do for bz=-640,512,128 do
 local cx,cz=bx+64,bz+64
 local needs=(cx< -192 and math.abs(cz)<256)or(cx>192 and cz<192)or(math.abs(cx)<256 and math.abs(cz)<192)
 if needs then
  local mats,occ={},{}
  for ix=1,32 do
   mats[ix]={};occ[ix]={};local surfaces={}
   for iz=1,32 do surfaces[iz]={C.surface(bx+(ix-.5)*4,bz+(iz-.5)*4)}end
   for iy=1,30 do
    mats[ix][iy]={};occ[ix][iy]={};local low=-24+(iy-1)*4
    for iz=1,32 do
     local s=surfaces[iz];local h,mat,water=s[1],s[2],s[3];local solid=math.clamp((h-low)/4,0,1)
     if solid>0 then mats[ix][iy][iz]=low<h-9 and Enum.Material.Rock or mat;occ[ix][iy][iz]=solid
     elseif water and water>low then mats[ix][iy][iz]=Enum.Material.Water;occ[ix][iy][iz]=math.clamp((water-low)/4,0,1)
     else mats[ix][iy][iz]=Enum.Material.Air;occ[ix][iy][iz]=0 end
    end
   end
  end
  T:WriteVoxels(Region3.new(V(bx,-24,bz),V(bx+128,96,bz+128)),4,mats,occ)
 end
end;task.wait()end
-- Restore the two level approach landings after terrain writes.
for _,m in ipairs(world.Crossings:GetChildren())do
 local center=m:GetAttribute('Center');local axis=m:GetAttribute('Axis');local len=m:GetAttribute('Length');local frame=CF(center)*CFrame.Angles(0,axis,0)
 for side=-1,1,2 do
  local q=(frame*CF(side*(len/2+4),0,0)).Position
  T:FillBlock(CF(q.X,center.Y-8,q.Z),V(14,16,14),Enum.Material.Ground)
 end
end
local trees,repositioned=0,0
local allTrees={}
for _,p in ipairs(world:GetDescendants())do if p:IsA('Model')and p:GetAttribute('Tree')then table.insert(allTrees,p)end end
for _,m in ipairs(allTrees)do
 local root=m:GetAttribute('RootPosition');local x,z=root.X,root.Z;local h,_,water=C.surface(x,z)
 if water then
  local zone=C.zone(x,z)
  for i=1,120 do
   local a=i*2.399;local radius=8+math.floor(i/12)*5;local nx,nz=x+math.cos(a)*radius,z+math.sin(a)*radius
   local clear,nh=C.open(nx,nz,8)
   if clear and C.zone(nx,nz)==zone then x,z,h,water=nx,nz,nh,nil;repositioned+=1;break end
  end
 end
 assert(not water,'Cannot seat tree at new shoreline')
 local oldVisual=nil
 for _,p in ipairs(m:GetChildren())do if p:IsA('MeshPart')and p:GetAttribute('PhotoModel')then oldVisual=p;break end end
 assert(oldVisual,'Tree visual missing')
 local name=oldVisual:GetAttribute('PhotoModel');local height=oldVisual.Size.Y;local _,yaw=oldVisual.CFrame:ToOrientation()
 plant(name,x,z,height,h,yaw,m);oldVisual:Destroy()
 local collider=m:FindFirstChild('TrunkCollision');collider.CFrame=CF(x,h+collider.Size.Y/2-.3,z)
 m:SetAttribute('RootPosition',V(x,h,z));trees+=1
end
-- Re-seat decorative pieces, then replace the old isolated shoreline plants.
for _,p in ipairs(world:GetDescendants())do
 if p:IsA('MeshPart')and not (p.Parent:IsA('Model')and p.Parent:GetAttribute('Tree'))then
  local root=p:GetAttribute('RootPosition')
  if root then
   local h,_,water=C.surface(root.X,root.Z)
   if p.Name=='ShoreReeds' or p.Name=='CloverPatch' or water then p:Destroy()
   else p.CFrame+=V(0,h-root.Y,0);p:SetAttribute('RootPosition',V(root.X,h,root.Z))end
  end
 end
end
local plantCount=0
-- Shores are continuous groups of reeds, white irises, clover and low shrubs.
for _,lake in ipairs(C.Lakes)do
 for i=1,88 do
  local angle=i*math.pi*2/88;local chosen=nil
  for ring=0,16 do
   local radius=1+ring*.014
   local x,z=lake.x+math.cos(angle)*lake.rx*radius,lake.z+math.sin(angle)*lake.rz*radius
   local h,_,water=C.surface(x,z)
   if not water and h>lake.water+.12 and h<lake.water+3.8 and C.pathDistance(x,z)>3 then chosen={x=x,z=z,h=h};break end
  end
  if chosen then
   local names=lake.id=='Pond' and {'ShoreReeds','WaterIris','CloverPatch','MeadowShrub'}or{'SmallGrassTuft','WhiteFlowerPatch','MeadowShrub','ShoreReeds'}
   local name=names[(i-1)%#names+1];local height=name=='MeadowShrub' and rng:NextNumber(2,3.8) or(name=='ShoreReeds' and 3.4 or(name=='WaterIris' and 2.5 or(name=='CloverPatch' and .38 or 1.4)))
   if name=='WhiteFlowerPatch' and C.pathDistance(chosen.x,chosen.z)<8 then name='WaterIris';height=2 end
   local p=plant(name,chosen.x,chosen.z,height,chosen.h);p:SetAttribute('ShorePlant',true);p:SetAttribute('Lake',lake.id);plantCount+=1
  end
 end
end
-- Shrubs sit in purposeful woodland groups, leaving the existing routes open.
for _,zone in ipairs(C.Zones)do
 if zone.id~='Monolith' and zone.id~='Golden' and zone.id~='Sakura' and zone.id~='Canal' then
  for i=1,62 do
   local x,z=zone.x+rng:NextNumber(-175,175),zone.z+rng:NextNumber(-175,175)
   local okay,h=C.open(x,z,9)
   if okay then
    local name=zone.id=='BlueAutumn' and (i%3==0 and 'FernRosette' or 'AutumnUnderstory')or(i%3==0 and 'FernRosette' or 'MeadowShrub')
    local p=plant(name,x,z,rng:NextNumber(1.7,3.2),h);p:SetAttribute('Understory',true);plantCount+=1
   end
  end
 end
end
-- The waterfall is carried by the continuous bank, instead of separate rock props.
local fall=world.Pond:FindFirstChild('Waterfall')
if fall then
 local index=0
 for _,p in ipairs(fall:GetChildren())do if p:IsA('BasePart')then
  index+=1;local x=328+(index-3)*1.6
  local a=V(x,C.surface(x,-98)+.35,-98);local b=V(x+2,22.1,-60)
  p.Size=V(1.85,.2,(b-a).Magnitude);p.CFrame=CF((a+b)/2,b);p.Transparency=.34;p.CanCollide=false;p.CanQuery=false
 end end
end
for _,p in ipairs(world.Pond:GetChildren())do if p.Name=='LilyPad' then p.Position=V(p.Position.X,22.07,p.Position.Z)end end
local old=RS:FindFirstChild('PhotoGroundcover');if old then old:Destroy()end
local cover=Instance.new('Folder');cover.Name='PhotoGroundcover';cover.Parent=RS
for _,name in ipairs({'GrassPatch','TallGrassPatch','SmallGrassTuft','FernRosette','WhiteFlowerPatch','LavenderFlowerPatch','CloverPatch','AutumnUnderstory','AutumnLeafCarpet','WaterIris','MeadowShrub'})do
 local p=templates[name]:Clone();p.CFrame=CF();p.CastShadow=false;p.Parent=cover
end
assets:Destroy()
for _,p in ipairs(L:GetChildren())do if p:IsA('Atmosphere')then p:Destroy()end end
L.FogStart=105;L.FogEnd=410;L.FogColor=rgb(155,213,225);L.Brightness=2.3;L.ExposureCompensation=.03
L.Ambient=rgb(88,110,126);L.OutdoorAmbient=rgb(128,147,157)
L:SetAttribute('FogMode','distance-v11');L:SetAttribute('NearViewClear',true)
T.WaterTransparency=.32;T.WaterReflectance=.22;T.WaterWaveSize=.17;T.WaterWaveSpeed=5
world:SetAttribute('RefinementVersion','lakes-fog-foliage-v11');world:SetAttribute('LooseRocksRemoved',true)
world:SetAttribute('RefinedPlantCount',plantCount);world:SetAttribute('TreeCount',trees);world:SetAttribute('AssetLibrary',C.AssetId)
local spawn=world.PhotoWorldSpawn;spawn.Position=V(spawn.Position.X,C.surface(spawn.Position.X,spawn.Position.Z)+.15,spawn.Position.Z)
return {ok=true,sourceVersion=sourceVersion,removedRocks=removed,trees=trees,relocatedShoreTrees=repositioned,plantedGroups=plantCount,assetId=C.AssetId}
