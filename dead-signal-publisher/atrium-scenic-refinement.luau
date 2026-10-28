-- Dead Signal botanical refinement: architectural wear, fresh grass, leaf clusters.
-- All vegetation stays outside central travel lanes. No per-leaf scripts or lights.
do
 local terrain=W.Terrain
 pcall(function() terrain.Decoration=true end)
 local moss=Color3.fromRGB(43,83,55)
 local fern=Color3.fromRGB(48,89,68)
 local ivy=Color3.fromRGB(36,64,48)
 -- Native material breaks up the obvious tiled checkerboard without adding BaseParts.
 for i=1,64 do
  local x=rng:NextNumber(-46,46)
  local z=rng:NextNumber(-80,74)
  if math.abs(x)>28 then
   terrain:FillBlock(CFrame.new(x,.12,z)*CFrame.Angles(0,rng:NextNumber(-.5,.5),0),Vector3.new(rng:NextNumber(2.5,5.5),.18,rng:NextNumber(3.5,8)),Enum.Material.Grass)
  end
 end
 -- Ferns share a tiny root and have individually angled tapered leaves.
 for i=1,25 do
  local side=i%2==0 and 1 or -1
  local x=side*rng:NextNumber(30,45)
  local z=rng:NextNumber(-73,74)
  local y=.3
  local center=Vector3.new(x,y,z)
  for petal=1,4 do
   local theta=petal*math.pi*.5+rng:NextNumber(-.35,.35)
   local endPoint=center+Vector3.new(math.cos(theta)*rng:NextNumber(1.5,3.2),rng:NextNumber(.6,1.8),math.sin(theta)*rng:NextNumber(1.2,2.9))
   local start=center+Vector3.new(0,.2,0)
   local leaf=rod(foliage,"FernFoliage",start,endPoint,.18,petal%2==0 and moss or fern,Enum.Material.Grass,false)
   leaf.CastShadow=false
   leaf.Size=Vector3.new(.35,.11,(endPoint-start).Magnitude)
  end
 end
 -- Peeling paint strips with subtle tones and tiny masonry seams.
 for _,wallX in ipairs({-55.94,55.94}) do
  for j=1,17 do
   local zz=rng:NextNumber(-76,81)
   local yy=rng:NextNumber(7,64)
   local detail=box("PeelingWallPaint",wallX,yy,zz,.02,rng:NextNumber(1.1,3.2),rng:NextNumber(.45,1.65),Color3.fromRGB(rng:NextInteger(94,118),rng:NextInteger(111,136),rng:NextInteger(126,155)),Enum.Material.Concrete,false,details)
   detail.CastShadow=false
  end
 end
 -- Short steel arch ribs on the balconies strengthen the abandoned gallery silhouette.
 for _,side in ipairs({-1,1}) do
  for level=1,3 do
   for z=-66,66,33 do
    local x=side*40
    local y=level*22
    local a=Vector3.new(x,y+12,z-10)
    local top=Vector3.new(x,y+17,z)
    local b=Vector3.new(x,y+12,z+10)
    local left=rod(details,"GalleryArchRib",a,top,.28,Color3.fromRGB(78,92,112),Enum.Material.Metal,false)
    local right=rod(details,"GalleryArchRib",top,b,.28,Color3.fromRGB(78,92,112),Enum.Material.Metal,false)
    left.CastShadow=false;right.CastShadow=false
   end
  end
 end
 -- Floor planters and stones give the garden a grounded edge, not floating spheres.
 for _,planter in ipairs({{-36,42},{35,-22},{-34,-32},{34,54}}) do
  local x,z=planter[1],planter[2]
  local stone=box("CrumblingPlanter",x,.4,z,7,.75,4,Color3.fromRGB(113,122,127),Enum.Material.Concrete,false,details)
  stone.CastShadow=false
  local soil=box("PlanterSoil",x,.80,z,6.5,.15,3.5,Color3.fromRGB(43,51,43),Enum.Material.Ground,false,foliage)
  soil.CastShadow=false
 end
end
