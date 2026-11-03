assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"wrong target")
assert(game.PlaceVersion==76,"place changed; review required")
local buildStart=os.clock()

local seed=3817
local SEA=0
local BOUNDS=528
local paths={
 {name="VilaPraia",width=10,points={{104,87,16},{121,92,16},{124,126,16},{116,160,13},{104,215,8},{100,264,5.4}}},
 {name="VilaLago",width=9,points={{104,87,16},{80,87,16},{45,70,16},{10,22,19},{4,-31,21},{-17,-88,23}}},
 {name="VilaBosque",width=9,points={{104,87,16},{81,88,16},{80,126,16},{31,128,16},{-35,125,16},{-94,124,16},{-166,105,18},{-212,59,19}}},
 {name="TrilhaMirante",width=7,points={{-212,59,19},{-292,-14,28},{-208,-47,40},{-294,-98,52},{-184,-118,64},{-266,-170,77},{-190,-188,89}}},
 {name="LagoBosque",width=7,points={{4,-31,21},{-10,37,20},{-42,69,18},{-100,70,17},{-166,105,18}}}
}
local function smooth(v) v=math.clamp(v,0,1) return v*v*(3-2*v) end
local function distanceLine(x,z,a,b)
 local dx,dz=b[1]-a[1],b[2]-a[2]
 local t=math.clamp(((x-a[1])*dx+(z-a[2])*dz)/(dx*dx+dz*dz),0,1)
 return math.sqrt((x-a[1]-t*dx)^2+(z-a[2]-t*dz)^2),t
end
local function nearestPath(x,z)
 local best,width,height,name=math.huge,0,0,""
 for _,path in ipairs(paths) do for i=1,#path.points-1 do
  local a,b=path.points[i],path.points[i+1]
  local d,t=distanceLine(x,z,a,b)
  if d<best then best,width,height,name=d,path.width,a[3]+(b[3]-a[3])*t,path.name end
 end end
 return best,width,height,name
end
local function creek(x,z)
 if z< -3 or z>290 then return math.huge,0 end
 local t=math.clamp((z+3)/293,0,1)
 local cx=-70+math.sin(t*math.pi*2)*15
 return math.abs(x-cx),18*(1-t)^1.15
end
local function pond(x,z,cx,cz,rx,rz,level,h)
 local r=math.sqrt(((x-cx)/rx)^2+((z-cz)/rz)^2)
 if r<.76 then h=level-8+5*(r/.76)^2
 elseif r<1 then h=level-3+(r-.76)/.24*6
 elseif r<1.3 then h=(level+3)+(h-level-3)*smooth((r-1)/.3) end
 return h,r
end
local falls={{-126,-110,42},{-119,-93,39},{-112,-81,30},{-108,-70,21},{-102,-58,18}}
local function waterfallChannel(x,z)
 local best,level=math.huge,0
 for i=1,#falls-1 do local d,t=distanceLine(x,z,falls[i],falls[i+1]) if d<best then best,level=d,falls[i][3]+(falls[i+1][3]-falls[i][3])*t end end
 return best,level
end
local function ground(x,z)
 local n=math.noise(x/120,z/120,seed)
 local r=math.sqrt((x/390)^2+(z/340)^2)
 local coast=smooth((1-r+n*.038)/.19)
 local h=-24+40*coast
 local mountain=74*math.exp(-(((x+190)/118)^2+((z+184)/98)^2))
 h+=mountain*coast
 h+=math.noise(x/65,z/65,seed+12)*4*coast
 -- A long, low sand crescent across the south coast.
 local beach=smooth((z-170)/80)*smooth((328-z)/55)*math.exp(-(x/190)^4)
 h=h*(1-beach)+math.max(-3,5.5+math.noise(x/72,z/72,seed+25))*beach
 -- Village terraces are graded before placing buildings.
 local villaDistance=math.max(math.abs(x-104)/82,math.abs(z-102)/55)
 local villaBlend=1-smooth((villaDistance-1)/.35)
 h=h*(1-villaBlend)+16*villaBlend
 local lakeR,upperR
 h,lakeR=pond(x,z,-70,-40,60,48,18,h)
 h,upperR=pond(x,z,-130,-117,24,19,42,h)
 local cd,cw=creek(x,z)
 if cd<18 then local blend=1-smooth((cd-7)/11) h=h*(1-blend)+(cw-4)*blend end
 local fd,fw=waterfallChannel(x,z)
 if fd<7 then local blend=1-smooth((fd-2.5)/4.5) h=h*(1-blend)+(fw-1.6)*blend end
 local plateauDistance=math.max(math.abs(x+190)/16,math.abs(z+188)/16)
 local plateauBlend=1-smooth((plateauDistance-1)/.5)
 h=h*(1-plateauBlend)+89*plateauBlend
 local pd,pwidth,ph,pname=nearestPath(x,z)
 local bridge=(cd<19 and z>60 and z<144)
 if not bridge and pd<pwidth/2+7 then
  local blend=1-smooth((pd-pwidth/2)/7) h=h*(1-blend)+ph*blend
 end
 local wet=SEA
 if lakeR<1.04 then wet=math.max(wet,18) end
 if upperR<1.04 then wet=math.max(wet,42) end
 if cd<10 then wet=math.max(wet,cw) end
 if fd<3.6 then wet=math.max(wet,fw) end
 local mat=Enum.Material.Grass
 if r>.84 or (z>205 and math.abs(x)<215) then mat=Enum.Material.Sand
 elseif mountain>34 and pd>pwidth/2+2 then mat=Enum.Material.Rock
 elseif pd<pwidth/2 then mat=Enum.Material.Ground
 elseif h<wet then mat=Enum.Material.Sand end
 return h,wet,mat,pd,pwidth
end


local terrain=workspace.Terrain
terrain:Clear()
for x=-3072,3072,2048 do for z=-3072,3072,2048 do terrain:FillBlock(CFrame.new(x,-14,z),Vector3.new(2048,28,2048),Enum.Material.Water) end end
local resolution=4
local yMin,yMax=-36,128
local nx=(BOUNDS*2)/resolution
local ny=(yMax-yMin)/resolution
local nz=nx
local tiles=0
-- Bounded voxel tiles avoid keeping a full island of nested tables in memory.
for ix=0,nx-1,48 do
 for iz=0,nz-1,48 do
  local sx,sz=math.min(48,nx-ix),math.min(48,nz-iz)
  local materials,occupancy,liquid={},{},{}
  for x=1,sx do
   materials[x]={} occupancy[x]={} liquid[x]={}
   local wx=-BOUNDS+(ix+x-.5)*resolution
   for y=1,ny do materials[x][y]={} occupancy[x][y]={} liquid[x][y]={} end
   for z=1,sz do
    local wz=-BOUNDS+(iz+z-.5)*resolution
    local h,water,surface=ground(wx,wz)
    for y=1,ny do
     local bottom=yMin+(y-1)*resolution
     local solid=math.clamp((h-bottom)/resolution,0,1)
     materials[x][y][z]=solid>0 and (bottom<h-8 and Enum.Material.Rock or surface) or Enum.Material.Air
     occupancy[x][y][z]=solid
     liquid[x][y][z]=solid>1-1/256 and 0 or math.clamp((water-bottom)/resolution,0,1)
    end
   end
  end
  local minimum=Vector3.new(-BOUNDS+ix*resolution,yMin,-BOUNDS+iz*resolution)
  local maximum=minimum+Vector3.new(sx*resolution,yMax-yMin,sz*resolution)
  terrain:WriteVoxelChannels(Region3.new(minimum,maximum),resolution,{SolidMaterial=materials,SolidOccupancy=occupancy,LiquidOccupancy=liquid})
  tiles+=1
  if tiles%4==0 then task.wait() end
 end
end
terrain.WaterColor=Color3.fromRGB(32,133,153)
terrain.WaterTransparency=.32 terrain.WaterReflectance=.65
terrain.WaterWaveSize=.12 terrain.WaterWaveSpeed=7
pcall(function()terrain.Decoration=true end)
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(121,148,105))
terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(227,209,167))
terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(113,124,121))
terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(181,161,128))


local world=Instance.new("Model") world.Name="IlhaSerena"
world:SetAttribute("DesignVersion",1)
local rng=Random.new(seed)
local function group(name)
 local m=Instance.new("Model") m.Name=name m.Parent=world return m
end
local village=group("VilaCosteira") local nature=group("Bosque") local coast=group("PraiaEPier") local garden=group("Jardins") local trails=group("TrilhasEMirante") local waterFeatures=group("CachoeiraELago")
local stone=Color3.fromRGB(190,182,165) local trim=Color3.fromRGB(233,220,191)
local wood=Color3.fromRGB(151,115,79) local darkWood=Color3.fromRGB(80,69,56)
local palette={Color3.fromRGB(233,210,170),Color3.fromRGB(202,220,202),Color3.fromRGB(207,223,227),Color3.fromRGB(235,198,169),Color3.fromRGB(213,205,220)}
local roofPalette={Color3.fromRGB(161,98,68),Color3.fromRGB(102,123,119),Color3.fromRGB(132,99,82)}
local totalParts=0
local function part(parent,name,size,cf,color,mat,class)
 local p=Instance.new(class or "Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color or stone
 p.Material=mat or Enum.Material.SmoothPlastic p.Anchored=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.CanTouch=false p.Parent=parent totalParts+=1 return p
end
local function rod(parent,name,a,b,diameter,color,mat)
 local length=(b-a).Magnitude
 local p=part(parent,name,Vector3.new(length,diameter,diameter),CFrame.lookAt((a+b)*.5,b)*CFrame.Angles(0,math.pi/2,0),color,mat or Enum.Material.Wood)
 p.Shape=Enum.PartType.Cylinder return p
end
local groundRay=RaycastParams.new() groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={terrain} groundRay.IgnoreWater=true
local function floorAt(x,z)
 local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-240,0),groundRay)
 return hit and hit.Position.Y or ground(x,z)
end
local function seat(parent,cf,width)
 width=width or 8
 local s=part(parent,"Banco",Vector3.new(width,.4,2.2),cf* CFrame.new(0,1.4,0),wood,Enum.Material.WoodPlanks,"Seat") s.CanTouch=true
 part(parent,"Encosto",Vector3.new(width,1.5,.3),cf*CFrame.new(0,2.3,1),wood,Enum.Material.WoodPlanks)
 for _,x in ipairs({-width*.36,width*.36}) do part(parent,"Pé",Vector3.new(.5,1.5,1.5),cf*CFrame.new(x,.65,0),darkWood,Enum.Material.Metal) end
end
local function lamp(parent,cf,height)
 height=height or 9
 part(parent,"Poste",Vector3.new(.4,height,.4),cf*CFrame.new(0,height/2,0),darkWood,Enum.Material.Metal)
 local globe=part(parent,"Lanterna",Vector3.new(1.4,1.8,1.4),cf*CFrame.new(0,height+.35,0),Color3.fromRGB(245,211,146),Enum.Material.Glass)
 globe.Transparency=.15 globe:SetAttribute("NightGlow",true)
 part(parent,"Cobertura",Vector3.new(2,.3,2),cf*CFrame.new(0,height+1.4,0),darkWood,Enum.Material.Metal)
 local l=Instance.new("PointLight") l.Range=18 l.Brightness=1.2 l.Color=Color3.fromRGB(255,218,164) l.Shadows=false l.Enabled=false l.Parent=globe
end
-- General facade: cells occupied by doors/windows are omitted from the wall mesh.
local function facade(parent,base,w,h,openingList,color)
 local xs={-w/2,w/2} local ys={0,h}
 for _,o in ipairs(openingList) do table.insert(xs,o.x-o.w/2) table.insert(xs,o.x+o.w/2) table.insert(ys,o.y) table.insert(ys,o.y+o.h) end
 table.sort(xs) table.sort(ys)
 for xi=1,#xs-1 do for yi=1,#ys-1 do
  local x=(xs[xi]+xs[xi+1])/2 local y=(ys[yi]+ys[yi+1])/2
  local dx,dy=xs[xi+1]-xs[xi],ys[yi+1]-ys[yi]
  local hole=false
  for _,o in ipairs(openingList) do if math.abs(x-o.x)<o.w/2+.001 and y>o.y-.001 and y<o.y+o.h+.001 then hole=true break end end
  if dx>.01 and dy>.01 and not hole then part(parent,"Parede",Vector3.new(dx,dy,.8),base*CFrame.new(x,y,0),color,Enum.Material.Concrete) end
 end end
 for _,o in ipairs(openingList) do
  local center=base*CFrame.new(o.x,o.y+o.h/2,0)
  if o.y>0 then
   local glass=part(parent,"Janela",Vector3.new(o.w-.35,o.h-.35,.15),center,Color3.fromRGB(136,177,179),Enum.Material.Glass)
   glass.Transparency=.5
   for _,x in ipairs({-o.w/2,o.w/2,0}) do part(parent,"Caixilho",Vector3.new(.2,o.h+.3,.3),center*CFrame.new(x,0,0),trim,Enum.Material.Wood) end
   for _,y in ipairs({-o.h/2,o.h/2,0}) do part(parent,"Caixilho",Vector3.new(o.w+.3,.2,.3),center*CFrame.new(0,y,0),trim,Enum.Material.Wood) end
   part(parent,"Peitoril",Vector3.new(o.w+1,.3,1.2),center*CFrame.new(0,-o.h/2,-.25),trim,Enum.Material.Wood)
  else
   for _,x in ipairs({-o.w/2-.1,o.w/2+.1}) do part(parent,"Portal",Vector3.new(.35,o.h+.3,1.1),center*CFrame.new(x,0,0),trim,Enum.Material.Wood) end
   part(parent,"Portal",Vector3.new(o.w+.7,.4,1.1),center*CFrame.new(0,o.h/2,0),trim,Enum.Material.Wood)
  end
 end
end
local function house(id,x,z,yaw,colorIndex)
 local home=Instance.new("Model") home.Name=id home.Parent=village
 local h=floorAt(x,z)
 local cf=CFrame.new(x,h+.35,z)*CFrame.Angles(0,math.rad(yaw),0)
 local width,depth,height=26,24,15
 local skin=palette[colorIndex%#palette+1] local roof=roofPalette[colorIndex%#roofPalette+1]
 part(home,"Fundação",Vector3.new(28,1.5,26),cf*CFrame.new(0,-.65,0),stone,Enum.Material.Slate)
 part(home,"PisoInterior",Vector3.new(width,.35,depth),cf,wood,Enum.Material.WoodPlanks)
 facade(home,cf*CFrame.new(0,0,depth/2),width,height,{{x=0,y=0,w=6,h=10},{x=-8.5,y=5,w=4.5,h=5.5},{x=8.5,y=5,w=4.5,h=5.5}},skin)
 facade(home,cf*CFrame.new(0,0,-depth/2),width,height,{{x=0,y=5,w=7,h=6}},skin)
 for _,side in ipairs({-1,1}) do facade(home,cf*CFrame.new(side*width/2,0,0)*CFrame.Angles(0,math.pi/2,0),depth,height,{{x=0,y=5,w=7,h=6}},skin) end
 -- Two rising roof planes and terracotta seams give a roof silhouette from every side.
 local rise=6 local run=width/2+1.5 local slope=math.atan(rise/run) local length=math.sqrt(run*run+rise*rise)
 for _,side in ipairs({-1,1}) do
  local panel=cf*CFrame.new(side*run/2,height+rise/2,0)*CFrame.Angles(0,0,side==1 and -slope or slope)
  part(home,"Telhado",Vector3.new(length,.65,depth+3),panel,roof,Enum.Material.Slate)
  for v=-depth/2-1,depth/2+1,2.3 do
   local seam=part(home,"FileiraDeTelhas",Vector3.new(length,.12,.22),panel*CFrame.new(0,.38,v),roof:Lerp(trim,.08),Enum.Material.Slate) seam.CanCollide=false
  end
 end
 part(home,"Cumeeira",Vector3.new(.9,.7,depth+4),cf*CFrame.new(0,height+rise+.2,0),roof,Enum.Material.Slate)
 for _,zSide in ipairs({-1,1}) do
  local base=cf*CFrame.new(0,height,zSide*depth/2)
  local g1=part(home,"Frontão",Vector3.new(.8,rise,width/2),base*CFrame.new(-width/4,rise/2,0)*CFrame.Angles(0,math.pi/2,0),skin,Enum.Material.Concrete,"WedgePart")
  local g2=part(home,"Frontão",Vector3.new(.8,rise,width/2),base*CFrame.new(width/4,rise/2,0)*CFrame.Angles(0,-math.pi/2,0),skin,Enum.Material.Concrete,"WedgePart")
 end
 for _,zSide in ipairs({-1,1}) do part(home,"Beiral",Vector3.new(width+3,.55,.5),cf*CFrame.new(0,height,zSide*(depth/2+1.3)),trim,Enum.Material.Wood) end
 part(home,"Varanda",Vector3.new(15,.5,7),cf*CFrame.new(0,.15,depth/2+3.5),stone,Enum.Material.Cobblestone)
 part(home,"Degrau",Vector3.new(7,.35,2),cf*CFrame.new(0,-.2,depth/2+7),stone,Enum.Material.Cobblestone)
 for _,dx in ipairs({-6,6}) do
  part(home,"ColunaVaranda",Vector3.new(.45,8,.45),cf*CFrame.new(dx,4,depth/2+5.5),trim,Enum.Material.Wood)
 end
 part(home,"Marquise",Vector3.new(15,.5,7),cf*CFrame.new(0,8.3,depth/2+3.5)*CFrame.Angles(math.rad(6),0,0),roof,Enum.Material.Slate)
 -- Every building is enterable, furnished and sheltered from rain.
 part(home,"Mesa",Vector3.new(6,.4,3),cf*CFrame.new(-6,2.5,-5),wood,Enum.Material.Wood)
 for _,dx in ipairs({-8.3,-3.7}) do part(home,"PéDaMesa",Vector3.new(.35,2.4,2.5),cf*CFrame.new(dx,1.2,-5),darkWood,Enum.Material.Wood) end
 seat(home,cf*CFrame.new(-6,0,-8)*CFrame.Angles(0,math.pi,0),6)
 seat(home,cf*CFrame.new(6,0,-5)*CFrame.Angles(0,-math.pi/2,0),7)
 local pendant=part(home,"LuzInterior",Vector3.new(1.5,.6,1.5),cf*CFrame.new(0,11,-1),Color3.fromRGB(250,220,164),Enum.Material.Glass)
 local light=Instance.new("PointLight") light.Range=14 light.Brightness=.8 light.Color=pendant.Color light.Shadows=false light.Enabled=false light.Parent=pendant
 rod(home,"Fio",(cf*CFrame.new(0,11,-1)).Position,(cf*CFrame.new(0,14,-1)).Position,.1,darkWood,Enum.Material.Metal)
 return home,cf
end
local homes={
 {"CasaDaPraça",66,60,0,1},{"Ateliê",107,51,0,2},{"CasaAzul",149,61,0,3},
 {"CaféDoMar",161,111,270,4},{"CasaDoJardim",149,151,180,0},{"CasaDaVaranda",64,149,180,2},{"Biblioteca",47,110,90,1}
}
local entries={}
for _,h in ipairs(homes) do local home,cf=house(table.unpack(h)) table.insert(entries,{name=h[1],cf=cf}) end
-- Plaza paving uses a restrained two-tone pattern and leaves the spawn center clear.
local py=floorAt(104,102)+.15
for x=76,132,8 do for z=82,122,8 do
 local tile=part(village,"Praça",Vector3.new(7.85,.25,7.85),CFrame.new(x,py,z),((x+z)%16==0) and trim or stone,Enum.Material.Cobblestone)
end end
local fountainCF=CFrame.new(104,py+.8,108)*CFrame.Angles(0,0,math.pi/2)
local basin=part(village,"Fonte",Vector3.new(1.4,13,13),fountainCF,stone,Enum.Material.Slate) basin.Shape=Enum.PartType.Cylinder
local surface=part(village,"ÁguaDaFonte",Vector3.new(.2,11,11),fountainCF*CFrame.new(.65,0,0),Color3.fromRGB(115,180,184),Enum.Material.Glass) surface.Shape=Enum.PartType.Cylinder surface.Transparency=.35 surface.CanCollide=false
rod(village,"Bica",Vector3.new(104,py+1,108),Vector3.new(104,py+4.5,108),.7,trim,Enum.Material.Slate)
for _,v in ipairs({{75,112,270},{135,101,90},{105,126,0}}) do seat(village,CFrame.new(v[1],py,v[2])*CFrame.Angles(0,math.rad(v[3]),0),8) end
local spawn=part(village,"SerenaSpawn",Vector3.new(8,.4,8),CFrame.new(104,py+.15,87),stone,Enum.Material.Cobblestone,"SpawnLocation")
spawn.Transparency=1 spawn.CanCollide=false spawn.Neutral=true spawn.Duration=0 spawn.Enabled=true
world:SetAttribute("SpawnCF",CFrame.new(104,py+4.5,87))
-- Safe signs at the first trail split are physical details, not a menu.
local function sign(parent,x,z,label)
 local h=floorAt(x,z)
 rod(parent,"PosteDaPlaca",Vector3.new(x,h,z),Vector3.new(x,h+5,z),.45,wood)
 local board=part(parent,"Placa",Vector3.new(10,2.2,.3),CFrame.new(x,h+4.4,z),wood,Enum.Material.Wood)
 local ui=Instance.new("SurfaceGui") ui.Face=Enum.NormalId.Front ui.PixelsPerStud=36 ui.Parent=board
 local t=Instance.new("TextLabel") t.Size=UDim2.fromScale(1,1) t.BackgroundTransparency=1 t.Text=label t.Font=Enum.Font.GothamMedium t.TextSize=25 t.TextColor3=trim t.Parent=ui
end
sign(village,141,162,"PRAIA  ↓") sign(trails,18,93,"LAGO  ←   BOSQUE  ↑") sign(trails,-208,63,"MIRANTE  ↑")
for _,v in ipairs({{72,79},{136,80},{141,129},{75,130},{106,157},{30,113}}) do lamp(village,CFrame.new(v[1],floorAt(v[1],v[2]),v[2])) end
-- A timber pier follows the bay's shallow shore instead of hovering over dry land.
local pierY=6.5
for i=0,19 do
 local z=270+i*3.2
 part(coast,"PranchaDoPier",Vector3.new(12,.5,3.05),CFrame.new(100,pierY,z),wood,Enum.Material.WoodPlanks)
 if i%3==0 then
  for _,side in ipairs({-1,1}) do
   local x=100+side*5.6
   rod(coast,"EstacaDoPier",Vector3.new(x,floorAt(x,z)-1,z),Vector3.new(x,pierY+3,z),.7,darkWood)
   if i<18 then rod(coast,"Corrimão",Vector3.new(x,pierY+2.4,z),Vector3.new(x,pierY+2.4,z+9.6),.27,wood) end
  end
 end
end
part(coast,"DeckDoPier",Vector3.new(23,.6,14),CFrame.new(100,pierY,337),wood,Enum.Material.WoodPlanks)
for i=0,3 do part(coast,"DegrauDoPier",Vector3.new(12,.32,1.5),CFrame.new(100,5.2+i*.35,264+i*1.4),wood,Enum.Material.WoodPlanks) end
seat(coast,CFrame.new(100,pierY+.3,340),9)
lamp(coast,CFrame.new(91,pierY+.3,334),7)
-- Decorative moored skiff, built as an open hull with seats rather than a solid block.
local boatCF=CFrame.new(118,.25,324)*CFrame.Angles(0,math.rad(12),0)
part(coast,"FundoDoBarco",Vector3.new(6,.6,15),boatCF,Color3.fromRGB(195,198,173),Enum.Material.WoodPlanks)
for _,side in ipairs({-1,1}) do
 part(coast,"LateralDoBarco",Vector3.new(.55,2.5,15),boatCF*CFrame.new(side*3,1,0)*CFrame.Angles(0,0,side*math.rad(-8)),Color3.fromRGB(89,141,147),Enum.Material.WoodPlanks)
end
for _,z in ipairs({-5,0,5}) do part(coast,"BancoDoBarco",Vector3.new(6,.35,1.7),boatCF*CFrame.new(0,1,z),wood,Enum.Material.WoodPlanks) end
rod(coast,"CordaDeAmarração",Vector3.new(111,pierY,324),(boatCF*CFrame.new(-3,1.5,0)).Position,.1,Color3.fromRGB(189,174,139),Enum.Material.Fabric)
-- Footbridges span the carved stream; ramps keep both ends flush with the path.
local bridges={}
for _,z in ipairs({70,124}) do
 local t=math.clamp((z+3)/293,0,1) local cx=-70+math.sin(t*math.pi*2)*15
 local by=z==124 and 16 or 17.2
 local bridge=Instance.new("Model") bridge.Name="Ponte"..z bridge.Parent=trails
 for i=0,17 do
  local x=cx-22+i*2.6
  part(bridge,"Prancha",Vector3.new(2.48,.45,8.5),CFrame.new(x,by,z),wood,Enum.Material.WoodPlanks)
  if i%3==0 then for _,side in ipairs({-1,1}) do
   rod(bridge,"GuardaCorpo",Vector3.new(x,by,z+side*4),Vector3.new(x,by+3,z+side*4),.32,darkWood)
  end end
 end
 for _,side in ipairs({-1,1}) do rod(bridge,"Corrimão",Vector3.new(cx-22,by+2.7,z+side*4),Vector3.new(cx+22,by+2.7,z+side*4),.27,wood) end
 table.insert(bridges,{x=cx,z=z,y=by,model=bridge})
end
-- Viewing platform at the top, with a continuous safety rail on three sides.
local peakX,peakZ=-190,-188 local peakY=floorAt(peakX,peakZ)+.5
part(trails,"DeckDoMirante",Vector3.new(24,.55,20),CFrame.new(peakX,peakY,peakZ),wood,Enum.Material.WoodPlanks)
for _,dx in ipairs({-10,10}) do for _,dz in ipairs({-8,8}) do local x,z=peakX+dx,peakZ+dz rod(trails,"ApoioMirante",Vector3.new(x,floorAt(x,z)-.7,z),Vector3.new(x,peakY-.25,z),.7,darkWood) end end
for _,x in ipairs({-12,12}) do
 for z=-10,10,5 do
  if x==12 or z< -1 or z>6 then rod(trails,"PilarMirante",Vector3.new(peakX+x,peakY,peakZ+z),Vector3.new(peakX+x,peakY+3,peakZ+z),.35,darkWood) end
 end
 if x==12 then rod(trails,"CorrimãoMirante",Vector3.new(peakX+x,peakY+2.8,peakZ-10),Vector3.new(peakX+x,peakY+2.8,peakZ+10),.25,wood)
 else
  rod(trails,"CorrimãoMirante",Vector3.new(peakX+x,peakY+2.8,peakZ-10),Vector3.new(peakX+x,peakY+2.8,peakZ-1),.25,wood)
  rod(trails,"CorrimãoMirante",Vector3.new(peakX+x,peakY+2.8,peakZ+6),Vector3.new(peakX+x,peakY+2.8,peakZ+10),.25,wood)
 end
end
local rampZ=peakZ+2.7
local rampA=Vector3.new(peakX-20,floorAt(peakX-20,rampZ)+.1,rampZ)
local rampB=Vector3.new(peakX-11,peakY+.1,rampZ)
part(trails,"RampaMirante",Vector3.new((rampB-rampA).Magnitude,.4,6.5),CFrame.new((rampA+rampB)*.5)*CFrame.Angles(0,0,math.atan2(rampB.Y-rampA.Y,rampB.X-rampA.X)),wood,Enum.Material.WoodPlanks)
rod(trails,"CorrimãoMirante",Vector3.new(peakX-12,peakY+2.8,peakZ-10),Vector3.new(peakX+12,peakY+2.8,peakZ-10),.25,wood)
seat(trails,CFrame.new(peakX,peakY+.3,peakZ-5)*CFrame.Angles(0,math.pi,0),8)
sign(trails,peakX+15,peakZ+8,"ILHA SERENA")
-- Waterfall ribbons follow the descending water channel, with mist kept close to the fall.
local foam=Color3.fromRGB(211,238,234)
for i=1,#falls-1 do
 local a,b=falls[i],falls[i+1]
 local pa=part(waterFeatures,"ÂncoraCachoeira",Vector3.new(.3,.3,.3),CFrame.new(a[1],a[3]+.7,a[2]),foam)
 local pb=part(waterFeatures,"ÂncoraCachoeira",Vector3.new(.3,.3,.3),CFrame.new(b[1],b[3]+.7,b[2]),foam)
 for _,p in ipairs({pa,pb}) do p.Transparency=1 p.CanCollide=false p.CanQuery=false end
 local aa=Instance.new("Attachment") aa.Parent=pa local ab=Instance.new("Attachment") ab.Parent=pb
 local beam=Instance.new("Beam") beam.Name="ÁguaEmMovimento" beam.Attachment0=aa beam.Attachment1=ab
 beam.Width0=5 beam.Width1=5.5 beam.FaceCamera=true beam.Segments=8 beam.LightInfluence=.65
 beam.Color=ColorSequence.new(Color3.fromRGB(137,205,211),foam)
 beam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(.45,.4),NumberSequenceKeypoint.new(1,.08)})
 beam.Texture="rbxasset://textures/particles/smoke_main.dds" beam.TextureMode=Enum.TextureMode.Wrap beam.TextureSpeed=1.2 beam.TextureLength=6 beam.Parent=pa
 if i==3 then
  local mist=Instance.new("ParticleEmitter") mist.Name="Névoa" mist.Texture="rbxasset://textures/particles/smoke_main.dds" mist.Rate=5
  mist.Lifetime=NumberRange.new(1.8,2.8) mist.Speed=NumberRange.new(1,3) mist.SpreadAngle=Vector2.new(80,80)
  mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,7)})
  mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.65),NumberSequenceKeypoint.new(1,1)}) mist.Color=ColorSequence.new(foam) mist.LightInfluence=.8 mist.Parent=ab
 end
end
-- An elliptical oak canopy uses different leaf volumes and real branches.
local foliage={Color3.fromRGB(91,130,83),Color3.fromRGB(113,149,89),Color3.fromRGB(137,161,100)}
local treePositions={}
local function oak(x,z,scale)
 local model=Instance.new("Model") model.Name="Árvore" model.Parent=nature
 local y=floorAt(x,z)
 local a=Vector3.new(x,y,z) local b=a+Vector3.new(rng:NextNumber(-1.2,1.2)*scale,12*scale,rng:NextNumber(-1,1)*scale)
 rod(model,"Tronco",a,b,1.6*scale,Color3.fromRGB(100,84,62))
 for i=1,5 do
  local angle=i*math.pi*2/5+rng:NextNumber(-.3,.3)
  local branch=b+Vector3.new(math.cos(angle)*5*scale,rng:NextNumber(2,5)*scale,math.sin(angle)*5*scale)
  rod(model,"Galho",a+Vector3.new(0,8*scale,0),branch,.65*scale,Color3.fromRGB(100,84,62))
  local crown=part(model,"Copa",Vector3.new(10,9,10)*scale,CFrame.new(branch+Vector3.new(0,2*scale,0)),foliage[(i%3)+1],Enum.Material.Grass)
  crown.Shape=Enum.PartType.Ball crown.CanCollide=false
 end
 local top=part(model,"CopaSuperior",Vector3.new(12,9,12)*scale,CFrame.new(b+Vector3.new(0,6*scale,0)),foliage[2],Enum.Material.Grass) top.Shape=Enum.PartType.Ball top.CanCollide=false
 table.insert(treePositions,Vector2.new(x,z))
end
local function palm(x,z,scale)
 local model=Instance.new("Model") model.Name="Palmeira" model.Parent=coast
 local y=floorAt(x,z) local lean=Vector3.new(rng:NextNumber(-3,3),0,rng:NextNumber(-3,3))*scale
 local top=Vector3.new(x,y+21*scale,z)+lean
 for i=0,4 do
  local t0,t1=i/5,(i+1)/5
  local a=Vector3.new(x,y,z)+Vector3.new(0,21*scale*t0,0)+lean*t0*t0
  local b=Vector3.new(x,y,z)+Vector3.new(0,21*scale*t1,0)+lean*t1*t1
  rod(model,"TroncoCurvo",a,b,(1.15-.45*t0)*scale,Color3.fromRGB(151,133,96))
 end
 for leaf=1,7 do
  local angle=leaf*math.pi*2/7
  for s=0,3 do
   local t0,t1=s/4,(s+1)/4
   local function point(t)return top+Vector3.new(math.cos(angle)*12*scale*t,(math.sin(t*math.pi)*3-5*t*t)*scale,math.sin(angle)*12*scale*t)end
   local a,b=point(t0),point(t1)
   local p=part(model,"Folha",Vector3.new((2.2*(1-t0)+.3)*scale,.12*scale,(b-a).Magnitude),CFrame.lookAt((a+b)*.5,b),foliage[leaf%3+1],Enum.Material.Grass)
   p.CanCollide=false
  end
 end
 for i=1,3 do local fruit=part(model,"Coco",Vector3.new(.85,.95,.85)*scale,CFrame.new(top+Vector3.new(math.cos(i*2)*scale,-.8*scale,math.sin(i*2)*scale)),Color3.fromRGB(109,92,61),Enum.Material.Wood) fruit.Shape=Enum.PartType.Ball fruit.CanCollide=false end
 table.insert(treePositions,Vector2.new(x,z))
end
local function vegetationAllowed(x,z,radius)
 local h,w,mat,pd,pwidth=ground(x,z)
 if h<w+2 or mat~=Enum.Material.Grass or pd<pwidth/2+radius then return false end
 if math.abs(x-104)<103 and math.abs(z-102)<79 then return false end
 local fd=waterfallChannel(x,z) if fd<17 then return false end
 for _,t in ipairs(treePositions) do if (t-Vector2.new(x,z)).Magnitude<radius*1.6 then return false end end
 return h<78
end
for i=1,240 do
 local x,z=rng:NextNumber(-290,260),rng:NextNumber(-195,192)
 if #treePositions<100 and vegetationAllowed(x,z,9) then oak(x,z,rng:NextNumber(.75,1.18)) end
end
for _,v in ipairs({{-88,214},{-40,231},{10,249},{48,229},{151,220},{182,204},{201,177},{205,115},{-130,190},{-197,171},{-234,148},{-275,124}}) do
 local h,w=ground(v[1],v[2]) if h>w+2 then palm(v[1],v[2],rng:NextNumber(.8,1.12)) end
end
-- Mixed pebble clusters along the water and scattered rock outcrops above the tree line.
for i=1,140 do
 local angle=rng:NextNumber(0,math.pi*2) local radius=rng:NextNumber(.73,.99)
 local x,z=math.cos(angle)*390*radius,math.sin(angle)*340*radius
 local h,w,mat,pd,pwidth=ground(x,z)
 if pd>pwidth/2+4 and h>w-4 and (math.abs(x-104)>95 or math.abs(z-102)>70) then
  local size=rng:NextNumber(2.5,6.5)
  local rock=part(nature,"PedraCosteira",Vector3.new(size*1.5,size*.65,size)*rng:NextNumber(.9,1.25),CFrame.new(x,floorAt(x,z)+size*.15,z)*CFrame.Angles(rng:NextNumber(-.2,.2),rng:NextNumber(0,math.pi),rng:NextNumber(-.15,.15)),Color3.fromRGB(123+rng:NextInteger(-10,10),130,124),Enum.Material.Rock)
  rock.Shape=Enum.PartType.Ball
 end
end
local function planter(x,z)
 local h=floorAt(x,z)
 local box=part(garden,"Floreira",Vector3.new(5,1.8,2.5),CFrame.new(x,h+.8,z),Color3.fromRGB(163,103,79),Enum.Material.SmoothPlastic)
 for i=1,4 do
  local sx=x-2+i*.9
  rod(garden,"Haste",Vector3.new(sx,h+1.4,z),Vector3.new(sx,h+2.8,z),.09,foliage[1],Enum.Material.Grass)
  for j=1,5 do local angle=j*math.pi*2/5 local petal=part(garden,"Flor",Vector3.new(.45,.25,.45),CFrame.new(sx+math.cos(angle)*.3,h+2.85,z+math.sin(angle)*.3),i%2==0 and Color3.fromRGB(232,198,199) or Color3.fromRGB(232,204,127),Enum.Material.SmoothPlastic) petal.Shape=Enum.PartType.Ball petal.CanCollide=false end
 end
end
for _,v in ipairs({{81,73},{132,77},{80,133},{134,134},{163,89},{48,132}}) do planter(v[1],v[2]) end
for _,v in ipairs({{-151,51},{-225,67},{-25,-87},{162,201},{-274,-31}}) do seat(trails,CFrame.new(v[1],floorAt(v[1],v[2])+.05,v[2])*CFrame.Angles(0,rng:NextNumber(-.4,.4),0),7) end
-- A lake-side refuge gives a view over water and shelters players from rainfall.
local refuge=Instance.new("Model") refuge.Name="PavilhãoDoLago" refuge.Parent=waterFeatures
local rx,rz=-12,-50 local ry=floorAt(rx,rz)+.4
part(refuge,"DeckLago",Vector3.new(18,.45,16),CFrame.new(rx,ry,rz),wood,Enum.Material.WoodPlanks)
for _,dx in ipairs({-8,8}) do for _,dz in ipairs({-7,7}) do part(refuge,"Coluna",Vector3.new(.5,11,.5),CFrame.new(rx+dx,ry+5.5,rz+dz),trim,Enum.Material.Wood) end end
part(refuge,"TelhadoLago",Vector3.new(21,.7,19),CFrame.new(rx,ry+11.5,rz),roofPalette[2],Enum.Material.Slate)
seat(refuge,CFrame.new(rx,ry+.25,rz+4),8)
-- Local character for the village: books in the library and a small shaded cafe terrace.
for _,entry in ipairs(entries) do
 local home=village:FindFirstChild(entry.name) local cf=entry.cf
 if entry.name=="Biblioteca" then
  for _,x in ipairs({5,11}) do part(home,"LateralEstante",Vector3.new(.35,8,1.4),cf*CFrame.new(x,4,-10.5),wood,Enum.Material.Wood) end
  for y=1,7,2 do
   part(home,"Prateleira",Vector3.new(6,.25,1.4),cf*CFrame.new(8,y,-10.5),wood,Enum.Material.Wood)
   for n=1,7 do
    part(home,"Livro",Vector3.new(.55,1.4,.9),cf*CFrame.new(5.5+n*.65,y+.8,-10.35)*CFrame.Angles(0,0,math.rad(n%3-1)*4),palette[n%#palette+1]:Lerp(darkWood,.2),Enum.Material.Fabric)
   end
  end
 elseif entry.name=="CaféDoMar" then
  local patio=cf*CFrame.new(0,-.1,23)
  part(home,"Pátio",Vector3.new(21,.4,12),patio,stone,Enum.Material.Cobblestone)
  part(home,"MesaDoCafé",Vector3.new(6,.35,4),patio*CFrame.new(5,2.6,0),wood,Enum.Material.Wood)
  for _,dx in ipairs({3,7}) do part(home,"PéDaMesa",Vector3.new(.3,2.5,3),patio*CFrame.new(dx,1.25,0),darkWood,Enum.Material.Wood) end
  seat(home,patio*CFrame.new(5,.2,3.5),6)
  for _,dx in ipairs({-9,9}) do part(home,"PostePérgola",Vector3.new(.5,8,.5),patio*CFrame.new(dx,4,-4),trim,Enum.Material.Wood) end
  for dx=-10,10,2.5 do part(home,"Pérgola",Vector3.new(.4,.5,11),patio*CFrame.new(dx,8.2,0),trim,Enum.Material.Wood) end
 end
end
-- Low flowers stay off paths; the grass itself is native wind-animated terrain decoration.
for i=1,28 do
 local x,z=rng:NextNumber(-270,220),rng:NextNumber(-160,185)
 local h,w,mat,pd,pwidth=ground(x,z)
 if h>w+3 and mat==Enum.Material.Grass and pd>pwidth/2+9 and (math.abs(x-104)>110 or math.abs(z-102)>82) then
  local y=floorAt(x,z)
  for j=1,3 do
   local fx=x+rng:NextNumber(-2,2) local fz=z+rng:NextNumber(-2,2)
   local leaf=part(garden,"FloresSilvestres",Vector3.new(.75,.2,.75),CFrame.new(fx,y+.8,fz),j%2==0 and Color3.fromRGB(234,213,152) or Color3.fromRGB(220,200,218),Enum.Material.SmoothPlastic)
   leaf.Shape=Enum.PartType.Ball leaf.CanCollide=false leaf.CanQuery=false
   local stem=rod(garden,"HasteSilvestre",Vector3.new(fx,y,fz),Vector3.new(fx,y+.75,fz),.07,foliage[1],Enum.Material.Grass) stem.CanCollide=false stem.CanQuery=false
  end
 end
end


local L=game.Lighting
for _,d in ipairs(L:GetChildren()) do d:Destroy() end
L.ClockTime=9.25 L.Brightness=3 L.GlobalShadows=true L.GeographicLatitude=23
L.Ambient=Color3.fromRGB(105,114,124) L.OutdoorAmbient=Color3.fromRGB(141,155,170)
L.EnvironmentDiffuseScale=.65 L.EnvironmentSpecularScale=.8 L.ExposureCompensation=.08 L.ShadowSoftness=.35
local lightingApplied=pcall(function()L.LightingStyle=Enum.LightingStyle.Realistic L.PrioritizeLightingQuality=true end)
local sky=Instance.new("Sky") sky.Name="SerenaSky" sky.StarCount=3000 sky.SunAngularSize=10 sky.MoonAngularSize=9 sky.CelestialBodiesShown=true sky.Parent=L
local faces={"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}
for i,id in ipairs({153258865,153259937,153258844,153258851,153259421,153259943}) do sky[faces[i]]="rbxassetid://"..id end
local atmosphere=Instance.new("Atmosphere") atmosphere.Name="SerenaAtmosphere"
atmosphere.Density=.235 atmosphere.Offset=.05 atmosphere.Haze=1.05 atmosphere.Glare=.1
atmosphere.Color=Color3.fromRGB(185,211,224) atmosphere.Decay=Color3.fromRGB(102,136,152) atmosphere.Parent=L
local color=Instance.new("ColorCorrectionEffect") color.Name="SerenaColor" color.Contrast=.045 color.Saturation=.035 color.Brightness=0 color.Parent=L
local bloom=Instance.new("BloomEffect") bloom.Name="SerenaBloom" bloom.Intensity=.075 bloom.Threshold=1.35 bloom.Size=24 bloom.Parent=L
local rays=Instance.new("SunRaysEffect") rays.Name="SerenaSunRays" rays.Intensity=.022 rays.Spread=.62 rays.Parent=L
local clouds=Instance.new("Clouds") clouds.Name="SerenaClouds" clouds.Cover=.16 clouds.Density=.32 clouds.Color=Color3.fromRGB(242,244,245) clouds.Parent=terrain
world:SetAttribute("LightingConfigured",true)
world:SetAttribute("NativeRealisticLightingApplied",lightingApplied)
workspace.GlobalWind=Vector3.new(4,0,2)

local serverSource=[====[local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local world=workspace:WaitForChild("IlhaSerena")
local terrain=workspace.Terrain
local atmosphere=Lighting:WaitForChild("SerenaAtmosphere")
local grade=Lighting:WaitForChild("SerenaColor")
local clouds=terrain:WaitForChild("SerenaClouds")
local lamps={}
for _,d in ipairs(world:GetDescendants()) do if d:IsA("PointLight") then table.insert(lamps,d) end end
local start=workspace:GetServerTimeNow()
world:SetAttribute("ClockStart",start) world:SetAttribute("DayLength",1200)
local weather={{"Sol",360},{"Nublado",35},{"Chuva",80},{"Nublado",35},{"Sol",300},{"Nublado",40},{"Chuva",110},{"Nublado",35}}
local index=1 local nextWeather=start+weather[1][2]
local lastNight
local function phase(hour)
 if hour<5 then return "Madrugada" elseif hour<6.5 then return "Amanhecer" elseif hour<12 then return "Manhã"
 elseif hour<17 then return "Tarde" elseif hour<18.5 then return "Pôr do sol" elseif hour<20 then return "Anoitecer" else return "Noite" end
end
Players.CharacterAutoLoads=true Players.RespawnTime=3
local function bind(p)
 p.CharacterAdded:Connect(function(c)
  local h=c:WaitForChild("Humanoid",10)
  if h then h.WalkSpeed=16 h.JumpPower=50 h.UseJumpPower=true h.PlatformStand=false h.AutoRotate=true end
 end)
end
Players.PlayerAdded:Connect(bind) for _,p in ipairs(Players:GetPlayers()) do bind(p) end
while true do
 local now=workspace:GetServerTimeNow()
 if now>=nextWeather then index=index%#weather+1 nextWeather=now+weather[index][2] end
 local state=weather[index][1]
 local hour=(9.25+(now-start)*24/1200)%24
 local sun=math.clamp((math.sin((hour-6)/24*math.pi*2)+.15)/1.15,0,1)
 local sunset=math.clamp(1-math.abs(hour-17.6)/1.8,0,1)
 local dawn=math.clamp(1-math.abs(hour-6.15)/1.4,0,1)
 local wet=state=="Chuva" local overcast=state~="Sol"
 world:SetAttribute("Weather",state) world:SetAttribute("TimePhase",phase(hour)) world:SetAttribute("Hour",hour)
 Lighting.ClockTime=hour
 Lighting.Brightness=.65+sun*(overcast and 1.45 or 2.5)
 Lighting.ExposureCompensation=.08
 Lighting.Ambient=Color3.fromRGB(47,57,77):Lerp(Color3.fromRGB(105,114,124),sun)
 Lighting.OutdoorAmbient=Color3.fromRGB(62,77,100):Lerp(Color3.fromRGB(141,155,170),sun)
 Lighting.ColorShift_Top=Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(108,48,21),sunset):Lerp(Color3.fromRGB(56,30,24),dawn*.45)
 atmosphere.Color=Color3.fromRGB(185,211,224):Lerp(Color3.fromRGB(237,186,145),sunset*.7)
 atmosphere.Decay=Color3.fromRGB(102,136,152):Lerp(Color3.fromRGB(169,105,73),sunset*.7)
 atmosphere.Density=wet and .36 or (overcast and .29 or .235)
 atmosphere.Haze=wet and 2.4 or 1.05 atmosphere.Glare=overcast and 0 or .1
 grade.TintColor=Color3.fromRGB(255,255,255):Lerp(Color3.fromRGB(255,229,205),sunset*.22)
 grade.Saturation=wet and -.045 or .035 grade.Contrast=.045 grade.Brightness=0
 clouds.Cover=wet and .82 or (overcast and .53 or .16)
 clouds.Density=wet and .62 or .32 clouds.Color=wet and Color3.fromRGB(169,181,189) or Color3.fromRGB(242,244,245)
 terrain.WaterColor=Color3.fromRGB(32,133,153):Lerp(Color3.fromRGB(49,112,133),wet and .6 or 0)
 terrain.WaterWaveSize=wet and .22 or .12 terrain.WaterWaveSpeed=wet and 11 or 7
 workspace.GlobalWind=wet and Vector3.new(13,0,8) or Vector3.new(4,0,2)
 local night=sun<.25
 if night~=lastNight then
  for _,light in ipairs(lamps) do if light.Parent then light.Enabled=night end end
  for _,d in ipairs(world:GetDescendants()) do
   if d:IsA("ParticleEmitter") and d.Name=="Vagalumes" then d.Enabled=night end
  end
  lastNight=night
 end
 task.wait(1)
end
]====]
local clientSource=[====[local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local world=workspace:WaitForChild("IlhaSerena")
local player=Players.LocalPlayer
local rain=Instance.new("Folder") rain.Name="SerenaLocalRain" rain.Parent=workspace
local rng=Random.new() local drops={}
for i=1,64 do
 local p=Instance.new("Part") p.Name="Chuva" p.Size=Vector3.new(.03,1.4,.03) p.Material=Enum.Material.Glass p.Color=Color3.fromRGB(198,223,235)
 p.Transparency=1 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=rain
 drops[i]={part=p,x=rng:NextNumber(-27,27),y=rng:NextNumber(-9,27),z=rng:NextNumber(-27,27)}
end
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Exclude ray.IgnoreWater=true
local nextRoofCheck=0 local outside=true
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera if not camera then return end
 local clockStart=world:GetAttribute("ClockStart")
 if clockStart then Lighting.ClockTime=(9.25+(workspace:GetServerTimeNow()-clockStart)*24/(world:GetAttribute("DayLength") or 1200))%24 end
 local wet=world:GetAttribute("Weather")=="Chuva"
 if wet and os.clock()>nextRoofCheck then
  nextRoofCheck=os.clock()+.4
  ray.FilterDescendantsInstances={rain,player.Character}
  local head=player.Character and player.Character:FindFirstChild("Head")
  outside=not workspace:Raycast(head and head.Position or camera.CFrame.Position,Vector3.new(0,120,0),ray)
 end
 for _,d in ipairs(drops) do
  if wet and outside then
   d.y-=math.min(dt,.1)*57
   if d.y< -10 then d.y=27 d.x=rng:NextNumber(-27,27) d.z=rng:NextNumber(-27,27) end
   d.part.CFrame=CFrame.new(camera.CFrame.Position+Vector3.new(d.x,d.y,d.z))*CFrame.Angles(0,0,-.15)
   d.part.Transparency=.42
  elseif d.part.Transparency~=1 then d.part.Transparency=1 end
 end
end)
local function cameraFor(char)
 local hum=char:WaitForChild("Humanoid",10)
 if hum then local camera=workspace.CurrentCamera camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=hum camera.FieldOfView=70 end
end
player.CharacterAdded:Connect(cameraFor)
if player.Character then task.spawn(cameraFor,player.Character) end
]====]

world.Parent=workspace
local pathGrades={}
for _,path in ipairs(paths) do
 local grade=0 for i=1,#path.points-1 do local a,b=path.points[i],path.points[i+1] local length=math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2) grade=math.max(grade,math.abs(b[3]-a[3])/length) end
 assert(grade<.27,"trail too steep: "..path.name) pathGrades[path.name]=grade
end
local spawnCF=world:GetAttribute("SpawnCF")
local floorHit=workspace:Raycast(spawnCF.Position,Vector3.new(0,-12,0),groundRay)
assert(floorHit and spawnCF.Y-floorHit.Position.Y<7,"spawn above terrain")
local query=OverlapParams.new() query.FilterType=Enum.RaycastFilterType.Include query.FilterDescendantsInstances={world} query.RespectCanCollide=true
local clearanceIssues={}
local function freeStanding(pos,name)
 local blockers=workspace:GetPartBoundsInBox(CFrame.new(pos),Vector3.new(3,5,3),query)
 for _,p in ipairs(blockers) do if p.CanCollide then table.insert(clearanceIssues,{place=name,part=p:GetFullName()}) end end
end
freeStanding(spawnCF.Position,"spawn")
for _,entry in ipairs(entries) do
 local pos=(entry.cf*CFrame.new(0,3.3,13)).Position
 freeStanding(pos,entry.name.." door")
end
local walkable=0 local badSamples={}
for _,path in ipairs(paths) do for i=1,#path.points-1 do
 local a,b=path.points[i],path.points[i+1]
 for n=0,6 do
  local t=n/6 local x,z=a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t
  local expected=a[3]+(b[3]-a[3])*t
  local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={terrain,world} ray.IgnoreWater=true
  local hit=workspace:Raycast(Vector3.new(x,expected+10,z),Vector3.new(0,-22,0),ray)
  if hit then
   freeStanding(Vector3.new(x,hit.Position.Y+3.3,z),path.name.."("..string.format("%.1f,%.1f",x,z)..")")
  end
  local rampSurface=hit and hit.Instance.Name=="RampaMirante"
  if rampSurface then assert(hit.Normal.Y>.90 and math.abs(rampB.Y-rampA.Y)/(rampB.X-rampA.X)<.45,"unsafe overlook ramp") end
  if not hit or (not rampSurface and math.abs(hit.Position.Y-expected)>4) then table.insert(badSamples,{path=path.name,x=x,z=z,expected=expected,actual=hit and hit.Position.Y or -999,part=hit and hit.Instance.Name or "none",terrainHeight=floorAt(x,z),peak=peakY,rampRise=rampB.Y-rampA.Y,rampRun=rampB.X-rampA.X}) else walkable+=1 end
 end
end end
assert(#clearanceIssues==0,"clearance: "..game:GetService("HttpService"):JSONEncode(clearanceIssues))
assert(#badSamples==0,"route ground gap: "..game:GetService("HttpService"):JSONEncode(badSamples))
local readRegion=Region3.new(Vector3.new(-80,8,-48),Vector3.new(-60,24,-32)):ExpandToGrid(4)
local channels=terrain:ReadVoxelChannels(readRegion,4,{"SolidOccupancy","LiquidOccupancy"})
local liquidCount=0
for _,x in ipairs(channels.LiquidOccupancy) do for _,y in ipairs(x) do for _,v in ipairs(y) do if v>0 then liquidCount+=1 end end end end
assert(liquidCount>0,"lake contains no native water")
local partCount=0
for _,d in ipairs(world:GetDescendants()) do if d:IsA("BasePart") then partCount+=1 assert(d.Anchored,"unanchored map part") end assert(not d:IsA("LuaSourceContainer"),"unintended map script") end
assert(partCount<6500,"map detail budget exceeded")
local compiled={}
for name,source in pairs({server=serverSource,client=clientSource}) do
 local m=Instance.new("ModuleScript") m.Source="return function()\n"..source.."\nend" m.Parent=game.ServerStorage
 local ok,fn=pcall(require,m) m:Destroy() assert(ok and type(fn)=="function",name..": "..tostring(fn)) compiled[name]=true
end
local result={ok=true,sourceVersion=game.PlaceVersion,parts=partCount,trees=#treePositions,houses=#entries,voxelTiles=tiles,walkableRouteSamples=walkable,pathGrades=pathGrades,nativeWaterCells=liquidCount,lightingApplied=lightingApplied,compiled=compiled}

result.buildSeconds=os.clock()-buildStart
-- The previous published place version remains available in Roblox version history.
-- Remove the old worlds and their systems from this build entirely.
for _,d in ipairs(workspace:GetChildren()) do if d~=world and not d:IsA("Terrain") and not d:IsA("Camera") then d:Destroy() end end
for _,d in ipairs(game.ServerScriptService:GetChildren()) do d:Destroy() end
for _,d in ipairs(game.ReplicatedStorage:GetChildren()) do d:Destroy() end
for _,d in ipairs(game.ServerStorage:GetChildren()) do d:Destroy() end
for _,d in ipairs(game.StarterGui:GetChildren()) do d:Destroy() end
for _,d in ipairs(game.StarterPack:GetChildren()) do d:Destroy() end
local SP=game.StarterPlayer
for _,d in ipairs(SP.StarterPlayerScripts:GetChildren()) do d:Destroy() end
for _,d in ipairs(SP.StarterCharacterScripts:GetChildren()) do d:Destroy() end
local oldCharacter=SP:FindFirstChild("StarterCharacter") if oldCharacter then oldCharacter:Destroy() end
for name in pairs(workspace:GetAttributes()) do workspace:SetAttribute(name,nil) end
workspace:SetAttribute("ActiveDesign","IlhaSerena")
world:SetAttribute("Weather","Sol") world:SetAttribute("TimePhase","Manhã") world:SetAttribute("Hour",9.25)
local server=Instance.new("Script") server.Name="SerenaAmbienceServer" server.Source=serverSource server.Parent=game.ServerScriptService
local client=Instance.new("LocalScript") client.Name="SerenaAmbienceClient" client.Source=clientSource client.Parent=SP.StarterPlayerScripts
SP.LoadCharacterAppearance=true SP.CameraMode=Enum.CameraMode.Classic SP.CameraMinZoomDistance=.5 SP.CameraMaxZoomDistance=24
SP.DevComputerMovementMode=Enum.DevComputerMovementMode.UserChoice SP.DevTouchMovementMode=Enum.DevTouchMovementMode.UserChoice
SP.CharacterWalkSpeed=16 SP.CharacterJumpPower=50
game.Players.CharacterAutoLoads=true game.Players.RespawnTime=3
workspace.StreamingEnabled=true workspace.FallenPartsDestroyHeight=-150
result.singleMap=true result.oldSystemsRemoved=true
game:GetService("AssetService"):SavePlaceAsync()
result.saved=true
return result
