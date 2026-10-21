-- Shared terrain, paths and nine photo palettes. Coordinates are in studs.
local C={Seed=20102026,AssetId=140184843098344,Extent=2048,Grade=24}
C.Zones={
 {id='DeepForest',x=-400,z=-400,trees=120,types={'AncientOak','EmeraldWillow'},height={18,30},clock=14,density=.43,haze=2.5,color=Color3.fromRGB(143,151,157),tint=Color3.fromRGB(188,202,208),grass=Color3.fromRGB(113,97,66)},
 {id='Canal',x=0,z=-400,trees=112,types={'CanalBlockTree'},height={32,64},clock=10,density=.32,haze=1.8,color=Color3.fromRGB(128,185,202),tint=Color3.fromRGB(193,232,238),grass=Color3.fromRGB(67,121,94)},
 {id='Spring',x=400,z=-400,trees=88,types={'MeadowBirch'},height={26,44},clock=12,density=.21,haze=.8,color=Color3.fromRGB(167,211,229),tint=Color3.fromRGB(246,255,224),grass=Color3.fromRGB(131,193,57)},
 {id='Valley',x=-400,z=0,trees=96,types={'ValleyOak','ValleyOak','LayeredPine'},height={28,47},clock=13,density=.22,haze=1,color=Color3.fromRGB(177,210,223),tint=Color3.fromRGB(255,248,217),grass=Color3.fromRGB(141,193,67)},
 {id='Willow',x=0,z=0,trees=48,types={'RiverPoplar','ValleyOak'},height={25,38},clock=11,density=.24,haze=1.4,color=Color3.fromRGB(155,213,225),tint=Color3.fromRGB(211,245,236),grass=Color3.fromRGB(91,159,89)},
 {id='Pond',x=400,z=0,trees=120,types={'ForestBroadleaf','LayeredPine'},height={33,63},clock=14,density=.23,haze=1,color=Color3.fromRGB(185,210,217),tint=Color3.fromRGB(243,246,220),grass=Color3.fromRGB(104,145,62)},
 {id='BlueAutumn',x=-400,z=400,trees=140,types={'BlueForestCedar'},height={54,92},clock=9,density=.44,haze=2.5,color=Color3.fromRGB(94,164,216),tint=Color3.fromRGB(239,244,255),grass=Color3.fromRGB(198,148,53)},
 {id='Golden',x=0,z=400,trees=48,types={'ValleyOak','LayeredPine'},height={27,57},clock=17.25,density=.33,haze=2,color=Color3.fromRGB(236,198,122),tint=Color3.fromRGB(255,227,160),grass=Color3.fromRGB(177,158,55)},
 {id='Sakura',x=400,z=400,trees=22,types={'MeadowBirch'},height={23,38},clock=18.1,density=.3,haze=2,color=Color3.fromRGB(210,156,154),tint=Color3.fromRGB(255,202,185),grass=Color3.fromRGB(157,149,74)}
}

-- Distance is explicit: clear foreground, a long soft fade across the treeline.
local weather={
 DeepForest={65,300,2.1,.02},Canal={52,265,2.0,0},Spring={140,480,2.5,.07},
 Valley={110,420,2.5,.06},Willow={105,410,2.3,.03},Pond={85,340,2.15,0},
 BlueAutumn={42,235,1.65,-.04},Golden={90,360,2.2,.02},Sakura={130,450,1.8,-.04}
}
for _,zone in ipairs(C.Zones)do
 local p=weather[zone.id];zone.fogStart=p[1];zone.fogEnd=p[2];zone.brightness=p[3];zone.exposure=p[4]
 zone.water=zone.id=='Pond' and Color3.fromRGB(73,125,121) or Color3.fromRGB(61,148,168)
end
C.Lakes={
 {id='Spring',x=400,z=-400,rx=102,rz=72,water=22},
 {id='Willow',x=12,z=0,rx=122,rz=93,water=21,island=true},
 {id='Pond',x=400,z=0,rx=112,rz=84,water=22}
}

function C.zone(x,z)
 local best,d=C.Zones[1],math.huge
 for _,a in ipairs(C.Zones)do local q=(x-a.x)^2+(z-a.z)^2;if q<d then best,d=a,q end end
 return best
end
local function smooth(a,b,x)local t=math.clamp((x-a)/(b-a),0,1);return t*t*(3-2*t)end
C.smooth=smooth
-- The primary connected walking network stays on dry ground around the lakes.
C.Paths={
 {-400,-570,-400,-200,8},{-400,-200,-400,190,7},{-400,190,-400,580,7},
 {-400,-320,0,-320,8},{0,-320,270,-320,8},{270,-320,400,-260,7},
 {400,-260,540,-170,7},{540,-170,540,180,7},{540,180,400,230,7},
 {-400,160,-130,160,8},{-130,160,140,160,8},{140,160,400,160,8},
 {-400,520,0,520,7},{0,520,400,520,7},{0,160,0,520,7},
 {-100,-320,-130,-130,7},{-130,-130,-140,30,7},{-140,30,-130,160,7},
 {400,230,370,320,6},{370,320,345,400,6},{345,400,400,520,6},
 {260,-320,270,-480,6},{270,-480,400,-520,6},{400,-520,520,-460,6},
 {520,-460,540,-330,6},{540,-330,400,-260,6}
}
function C.pathDistance(x,z)
 local best=math.huge
 for _,s in ipairs(C.Paths)do
  local dx,dz=s[3]-s[1],s[4]-s[2];local t=math.clamp(((x-s[1])*dx+(z-s[2])*dz)/(dx*dx+dz*dz),0,1)
  best=math.min(best,math.sqrt((x-s[1]-t*dx)^2+(z-s[2]-t*dz)^2)-s[5]*.5)
 end
 return best
end
local function lake(h,x,z,cx,cz,rx,rz,water,bed,island)
 local angle=math.atan2((z-cz)/rz,(x-cx)/rx)
 local scallop=1+.025*math.sin(angle*3+.6)+.018*math.sin(angle*7)
 local d=math.sqrt(((x-cx)/rx)^2+((z-cz)/rz)^2)/scallop
 if d>1.42 then return h,nil end
 local v=bed+(h-bed)*smooth(.35,1.42,d)
 if island then local r=math.sqrt((x-cx)^2+(z-cz)^2);v=math.max(v,bed+(26-bed)*(1-smooth(30,63,r)))end
 return v,v<water and water or nil
end
local function innerSurface(x,z)
 local zone=C.zone(x,z);local h=24+1.1*math.sin(x*.016)*math.cos(z*.021);local mat=Enum.Material.Grass;local water=nil
 if zone.id=='DeepForest' then h=24+2*math.sin(z*.012)^2;mat=Enum.Material.Grass
 elseif zone.id=='Canal' then h=24
  if z>-580 and z< -220 and math.abs(x)<22 then h=10+14*smooth(12,22,math.abs(x));if h<18 then water=18 end end
 elseif zone.id=='Spring' then
  h+=8*(.5+.5*math.sin(x*.025+z*.014))*smooth(65,145,math.sqrt((x-400)^2+(z+400)^2))
  h,water=lake(h,x,z,400,-400,102,72,22,11)
 elseif zone.id=='Valley' then
  h+=5*math.sin(z*.015)^2
  local side=math.abs(x+400);local ridge=smooth(48,78,side)*(1-smooth(91,134,side))
  local length=smooth(-190,-154,z)*(1-smooth(100,142,z))
  h+=31*ridge*length
  if ridge*length>.2 then mat=Enum.Material.Sandstone end
 elseif zone.id=='Willow' then h,water=lake(h,x,z,12,0,122,93,21,10,true)
 elseif zone.id=='Pond' then
  h+=3*math.sin(z*.018)^2;h,water=lake(h,x,z,400,0,112,84,22,11)
  local bank=44*math.exp(-((x-322)/28)^2-((z+112)/36)^2)*(1-smooth(-85,-66,z))
  if bank>1 then h=math.max(h,24+bank);water=nil;mat=bank>8 and Enum.Material.Rock or Enum.Material.Grass end
 elseif zone.id=='BlueAutumn' then
  h+=2*math.sin(x*.035+z*.018);mat=Enum.Material.LeafyGrass
  local d=math.abs(z-(427+math.sin(x*.025)*14))
  if x>-580 and x< -230 and d<11 then h=15+10*smooth(5,11,d);if h<19 then water=19 end end
 elseif zone.id=='Golden' then h+=5*(.5+.5*math.sin(x*.02+z*.012))
 elseif zone.id=='Sakura' then h+=12*math.exp(-((x-390)^2+(z-400)^2)/18000)end
 -- Blend biome edges to a common low grade, avoiding cliffs at grid boundaries.
 local edge=math.min(200-math.abs(x-zone.x),200-math.abs(z-zone.z));local blend=smooth(0,42,edge)
 h=24+(h-24)*blend
 if water and h>=water then water=nil end
 if C.pathDistance(x,z)<0 and not water then mat=Enum.Material.Ground end
 if water then mat=Enum.Material.Mud end
 return h,mat,water,zone
end
-- Large continuous woodland beyond the original nine clearings.
C.HiddenPond={x=930,z=-1070,radius=27}
C.Cliff={x=-1410,z=-830}
C.NPC=Vector3.new(-153,24,112)
C.Grove={x=-310,z=-345}
C.ExtraLakes={
 {id='NorthLake',x=950,z=-790,rx=135,rz=106,water=25},
 {id='EastLake',x=1460,z=410,rx=160,rz=112,water=25},
 {id='SouthLake',x=300,z=1300,rx=143,rz=110,water=25},
 {id='WestLake',x=-930,z=540,rx=130,rz=95,water=25},
}
for _,l in ipairs(C.ExtraLakes)do table.insert(C.Lakes,l)end
for _,p in ipairs({
 {-400,-570,-650,-700,7},{-650,-700,-980,-810,6},{-980,-810,-1300,-830,5},
 {-400,580,-650,820,7},{-650,820,-420,1120,6},{-420,1120,70,1460,6},
 {70,1460,500,1500,6},{500,1500,890,1350,6},{890,1350,1300,1000,6},
 {400,520,750,710,7},{750,710,1200,720,7},{1200,720,1600,730,6},
 {540,-330,760,-470,7},{760,-470,1190,-540,7},{1190,-540,1310,-930,6},
 {1310,-930,1170,-1220,6},{1170,-1220,850,-1250,5},{850,-1250,600,-1020,6},
 {600,-1020,190,-900,6},{190,-900,-280,-960,6},{-280,-960,-650,-700,6},
 {-650,820,-1150,930,5},{-1150,930,-1230,1320,5},{1300,1000,1710,1310,5},
 {70,1460,-140,1830,5},{1170,-1220,1430,-1660,5},{-280,-960,-500,-1640,5}
})do table.insert(C.Paths,p)end
function C.coast(z)return -1440+55*math.sin(z*.004)+25*math.sin(z*.011)end
C.Cliff.x=C.coast(C.Cliff.z)+34
local innerZone=C.zone
function C.zone(x,z)
 if math.abs(x)<620 and math.abs(z)<620 then return innerZone(x,z)end
 -- Forest remains lit; fog softens distance without hiding the near ground.
 local key=math.noise(x*.00065,z*.00065,17)
 if key>.22 then return C.Zones[3]elseif key<-.22 then return C.Zones[7]end
 return C.Zones[6]
end
function C.surface(x,z)
 if math.abs(x)<=620 and math.abs(z)<=620 then return innerSurface(x,z)end
 local zone=C.zone(x,z);local h=30+18*math.noise(x*.002,z*.002,3)+5*math.sin(x*.007)*math.cos(z*.006)
 local blend=smooth(620,810,math.max(math.abs(x),math.abs(z)));h=24+(h-24)*blend
 local mat=Enum.Material.Grass;local water=nil
 local coast=C.coast(z);local shore=x-coast
 if shore<0 then return -16,Enum.Material.Rock,4,zone end
 if shore<300 then
  local plateau=64+8*math.noise(z*.012,0,2)
  h=h+(plateau-h)*(1-smooth(85,300,shore))
  h=-12+(h+12)*smooth(0,19,shore)
  if shore<27 then mat=Enum.Material.Rock end
  if h<4 then water=4 end
 end
 for _,l in ipairs(C.ExtraLakes)do
  if math.abs(x-l.x)<l.rx*1.5 and math.abs(z-l.z)<l.rz*1.5 then
   -- A broad shelf starts descending well before the waterline.
   local surrounding=30;h=surrounding+(h-surrounding)*smooth(1.4,1.8,math.sqrt(((x-l.x)/l.rx)^2+((z-l.z)/l.rz)^2))
   h,water=lake(h,x,z,l.x,l.z,l.rx,l.rz,l.water,14)
  end
 end
 -- Two meandering rivers feed the northern and southern lakes.
 local riverX=950+55*math.sin((z+790)*.005)
 if z>-790 and z<1080 and x>620 then
  local d=math.abs(x-riverX);local blendRiver=1-smooth(27,70,d)
  local riverGrade=24.5+(z+790)/1870*.5
  h=h*(1-blendRiver)+(riverGrade-4+5*smooth(7,29,d))*blendRiver
  if d<24 and h<riverGrade then water=riverGrade end
 end
 local hp=C.HiddenPond;local d=Vector2.new(x-hp.x,z-hp.z).Magnitude
 if d<50 then local base=30;h=h+(base-h)*(1-smooth(35,50,d))end
 if C.pathDistance(x,z)<0 and not water then mat=Enum.Material.Ground end
 if water then mat=Enum.Material.Mud end
 return h,mat,water,zone
end
function C.open(x,z,margin)
 local h,_,w=C.surface(x,z)
 local hidden=Vector2.new(x-C.HiddenPond.x,z-C.HiddenPond.z).Magnitude
 return not w and C.pathDistance(x,z)>(margin or 5) and Vector2.new(x+130,z-95).Magnitude>18 and hidden>39,h
end
C.Spawn=Vector3.new(-130,28,95)
return C
