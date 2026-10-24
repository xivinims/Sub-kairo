-- Shared terrain, paths and nine photo palettes. Coordinates are in studs.
local C={Seed=20102026,AssetId=108640163601160,Extent=640,Grade=24}
C.Zones={
 {id='Monolith',x=-400,z=-400,trees=18,types={'SparseOrangeMaple'},height={18,30},clock=14,density=.43,haze=2.5,color=Color3.fromRGB(143,151,157),tint=Color3.fromRGB(188,202,208),grass=Color3.fromRGB(113,97,66)},
 {id='Canal',x=0,z=-400,trees=112,types={'CanalBlockTree'},height={32,64},clock=10,density=.32,haze=1.8,color=Color3.fromRGB(128,185,202),tint=Color3.fromRGB(193,232,238),grass=Color3.fromRGB(67,121,94)},
 {id='Spring',x=400,z=-400,trees=88,types={'MeadowBirch'},height={26,44},clock=12,density=.21,haze=.8,color=Color3.fromRGB(167,211,229),tint=Color3.fromRGB(246,255,224),grass=Color3.fromRGB(131,193,57)},
 {id='Valley',x=-400,z=0,trees=96,types={'ValleyOak','ValleyOak','LayeredPine'},height={28,47},clock=13,density=.22,haze=1,color=Color3.fromRGB(177,210,223),tint=Color3.fromRGB(255,248,217),grass=Color3.fromRGB(141,193,67)},
 {id='Willow',x=0,z=0,trees=48,types={'RiverPoplar','ValleyOak'},height={25,38},clock=11,density=.24,haze=1.4,color=Color3.fromRGB(155,213,225),tint=Color3.fromRGB(211,245,236),grass=Color3.fromRGB(91,159,89)},
 {id='Pond',x=400,z=0,trees=120,types={'ForestBroadleaf','LayeredPine'},height={33,63},clock=14,density=.23,haze=1,color=Color3.fromRGB(185,210,217),tint=Color3.fromRGB(243,246,220),grass=Color3.fromRGB(104,145,62)},
 {id='BlueAutumn',x=-400,z=400,trees=140,types={'BlueForestCedar'},height={54,92},clock=9,density=.44,haze=2.5,color=Color3.fromRGB(94,164,216),tint=Color3.fromRGB(170,210,247),grass=Color3.fromRGB(198,148,53)},
 {id='Golden',x=0,z=400,trees=48,types={'ValleyOak','LayeredPine'},height={27,57},clock=17.25,density=.33,haze=2,color=Color3.fromRGB(236,198,122),tint=Color3.fromRGB(255,227,160),grass=Color3.fromRGB(177,158,55)},
 {id='Sakura',x=400,z=400,trees=22,types={'MeadowBirch'},height={23,38},clock=18.1,density=.3,haze=2,color=Color3.fromRGB(210,156,154),tint=Color3.fromRGB(255,202,185),grass=Color3.fromRGB(157,149,74)}
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
 local d=math.sqrt(((x-cx)/rx)^2+((z-cz)/rz)^2)
 if d>1.18 then return h,nil end
 local v=bed+(h-bed)*smooth(.76,1.18,d)
 if island then local r=math.sqrt((x-cx)^2+(z-cz)^2);v=math.max(v,bed+(24-bed)*(1-smooth(23,40,r)))end
 return v,v<water and water or nil
end
function C.surface(x,z)
 local zone=C.zone(x,z);local h=24+1.1*math.sin(x*.016)*math.cos(z*.021);local mat=Enum.Material.Grass;local water=nil
 if zone.id=='Monolith' then h=24+.5*math.sin(z*.02);mat=Enum.Material.Slate
 elseif zone.id=='Canal' then h=24
  if z>-580 and z< -220 and math.abs(x)<22 then h=10+14*smooth(12,22,math.abs(x));if h<18 then water=18 end end
 elseif zone.id=='Spring' then
  h+=8*(.5+.5*math.sin(x*.025+z*.014))*smooth(65,145,math.sqrt((x-400)^2+(z+400)^2))
  h,water=lake(h,x,z,400,-400,89,61,20,10)
 elseif zone.id=='Valley' then h+=5*math.sin(z*.015)^2
 elseif zone.id=='Willow' then h,water=lake(h,x,z,12,0,117,87,19,9,true)
 elseif zone.id=='Pond' then
  h+=3*math.sin(z*.018)^2;h,water=lake(h,x,z,400,0,96,73,20,10)
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
 if C.pathDistance(x,z)<0 and not water then mat=zone.id=='Willow' and Enum.Material.Sand or (zone.id=='Monolith' and Enum.Material.Slate or Enum.Material.Ground)end
 if water then mat=Enum.Material.Mud end
 return h,mat,water,zone
end
function C.open(x,z,margin)
 local h,_,w=C.surface(x,z)
 return not w and C.pathDistance(x,z)>(margin or 5) and (Vector2.new(x+130,z-95)).Magnitude>18,h
end
C.Spawn=Vector3.new(-130,28,95)
return C
