assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==78,"Published version changed; review before applying")
local world=workspace:FindFirstChild("IlhaSerena") assert(world,"Missing island")
assert(world:GetAttribute("DesignVersion")==1,"Upgrade already applied")
local RS=game:GetService("ReplicatedStorage") local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer").StarterPlayerScripts
local old=RS:FindFirstChild("SerenaRuntime") if old then old:Destroy() end
local runtime=Instance.new("Folder") runtime.Name="SerenaRuntime" runtime.Parent=RS
local function source(parent,class,name,code)
 local previous=parent:FindFirstChild(name) if previous then previous:Destroy() end
 local s=Instance.new(class) s.Name=name s.Source=code s.Parent=parent return s
end
local function run(code)
 local m=source(game.ServerStorage,"ModuleScript","TemporaryUpgradeStep","return function()\n"..code.."\nend")
 local result=require(m)() m:Destroy() return result
end

source(runtime,"ModuleScript","Climate",[========[-- Shared climate profile: the same native effects run on server and client.
local Climate={DayLength=1800,InitialHour=9.25,TransitionSeconds=18}
function Climate.hour(now,start)
 return (Climate.InitialHour+(now-start)*24/Climate.DayLength)%24
end
function Climate.phase(hour)
 if hour<5 then return "Madrugada" elseif hour<6.5 then return "Amanhecer" elseif hour<12 then return "Manhã"
 elseif hour<17 then return "Tarde" elseif hour<18.5 then return "Pôr do sol" elseif hour<20 then return "Anoitecer" else return "Noite" end
end
function Climate.weights(now,changed,from,to)
 local t=math.clamp((now-changed)/Climate.TransitionSeconds,0,1) t=t*t*(3-2*t)
 local function amount(state,key) return state==key and 1 or 0 end
 return amount(from,"Chuva")*(1-t)+amount(to,"Chuva")*t,
  amount(from,"Sol")*(1-t)+amount(to,"Sol")*t
end
function Climate.profile(hour,rain,clear,now)
 local sun=math.clamp((math.sin((hour-6)/24*math.pi*2)+.13)/1.13,0,1)
 local sunset=math.clamp(1-math.abs(hour-17.65)/1.8,0,1)
 local dawn=math.clamp(1-math.abs(hour-6.2)/1.5,0,1)
 local warm=math.max(sunset,dawn*.65)
 local gust=1+.17*math.sin(now*.39)+.09*math.sin(now*.91)
 local wind=Vector3.new(5+rain*10,0,2+rain*5)*gust
 local p={sun=sun,rain=rain,clear=clear,warm=warm,wind=wind}
 p.brightness=.85+sun*(1.7+clear*.75-rain*.25)
 p.ambient=Color3.fromRGB(52,63,83):Lerp(Color3.fromRGB(102,114,120),sun)
 p.outdoor=Color3.fromRGB(70,83,107):Lerp(Color3.fromRGB(148,162,166),sun)
 p.atmosphere=Color3.fromRGB(189,215,233):Lerp(Color3.fromRGB(245,186,134),warm*.75)
 p.decay=Color3.fromRGB(104,139,162):Lerp(Color3.fromRGB(163,100,73),warm*.7)
 p.density=.23+(1-clear)*.045+rain*.055
 p.haze=.9+(1-clear)*.45+rain*.9
 p.cover=.2+(1-clear)*.37+rain*.21
 p.cloudDensity=.32+rain*.28
 p.cloudColor=Color3.fromRGB(246,248,244):Lerp(Color3.fromRGB(145,161,176),rain):Lerp(Color3.fromRGB(255,208,169),warm*.25)
 p.rays=(.018+.045*clear)*sun*(1-rain*.8)
 p.waterColor=Color3.fromRGB(39,141,151):Lerp(Color3.fromRGB(61,111,132),rain*.7)
 p.waveSize=.22+rain*.17 p.waveSpeed=8+rain*7
 return p
end
function Climate.apply(lighting,terrain,profile)
 local p=profile
 lighting.ClockTime=p.hour or lighting.ClockTime
 lighting.GlobalShadows=true lighting.Brightness=p.brightness lighting.ExposureCompensation=.08
 lighting.EnvironmentDiffuseScale=.55 lighting.EnvironmentSpecularScale=.9 lighting.ShadowSoftness=.25
 lighting.Ambient=p.ambient lighting.OutdoorAmbient=p.outdoor
 lighting.ColorShift_Top=Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(98,44,19),p.warm)
 local atmosphere=lighting:FindFirstChild("SerenaAtmosphere")
 if atmosphere then atmosphere.Color=p.atmosphere atmosphere.Decay=p.decay atmosphere.Density=p.density atmosphere.Haze=p.haze atmosphere.Glare=p.clear*.22*p.sun end
 local grade=lighting:FindFirstChild("SerenaColor")
 if grade then grade.Contrast=.065 grade.Saturation=.045-p.rain*.09 grade.Brightness=0 grade.TintColor=Color3.fromRGB(255,255,255):Lerp(Color3.fromRGB(255,224,200),p.warm*.25) end
 local bloom=lighting:FindFirstChild("SerenaBloom")
 if bloom then bloom.Enabled=true bloom.Intensity=.13 bloom.Threshold=1.25 bloom.Size=28 end
 local rays=lighting:FindFirstChild("SerenaSunRays")
 if rays then rays.Enabled=true rays.Intensity=p.rays rays.Spread=.78 end
 local clouds=terrain:FindFirstChild("SerenaClouds")
 if clouds then clouds.Cover=p.cover clouds.Density=p.cloudDensity clouds.Color=p.cloudColor end
 terrain.WaterColor=p.waterColor terrain.WaterTransparency=.37 terrain.WaterReflectance=.55
 terrain.WaterWaveSize=p.waveSize terrain.WaterWaveSpeed=p.waveSpeed
 workspace.GlobalWind=p.wind
end
function Climate.rendering(lighting)
 -- A renderer capability failure must not stop rain, grass, time or controls.
 local style=pcall(function()lighting.LightingStyle=Enum.LightingStyle.Realistic end)
 local quality=pcall(function()lighting.PrioritizeLightingQuality=true end)
 return style and quality
end
return Climate
]========])

source(runtime,"ModuleScript","GrassMotion",[========[local Motion={}
function Motion.bend(root,actors,wind,now,phase,current,dt)
 local target=Vector3.zero
 local horizontal=Vector3.new(wind.X,0,wind.Z)
 if horizontal.Magnitude>.01 then target=horizontal.Unit*(.08+.025*math.sin(now*2.1+phase))*math.clamp(horizontal.Magnitude/6,.5,2.5) end
 for _,a in ipairs(actors) do
  local offset=Vector3.new(root.X-a.position.X,0,root.Z-a.position.Z)
  local distance=offset.Magnitude
  if distance<3.3 and math.abs(root.Y-a.feet)<3.3 then
   local away=distance>.08 and offset.Unit or Vector3.new(1,0,0)
   local speed=Vector3.new(a.velocity.X,0,a.velocity.Z).Magnitude
   local strength=(1-distance/3.3)*(.85+math.min(speed/24,.35))
   target+=away*strength
  end
 end
 if target.Magnitude>1.15 then target=target.Unit*1.15 end
 local rate=target.Magnitude>current.Magnitude and 15 or 4.5
 return current:Lerp(target,1-math.exp(-math.min(dt,.15)*rate))
end
function Motion.frame(root,height,yaw,bend)
 -- The root stays in the soil; only the blade leans.
 local angle=math.min(bend.Magnitude,.95)
 local direction=bend.Magnitude>.001 and bend.Unit or Vector3.xAxis
 local axis=Vector3.yAxis:Cross(direction)
 return CFrame.new(root)*CFrame.fromAxisAngle(axis,angle)*CFrame.Angles(0,yaw,0)*CFrame.new(0,height/2,0)
end
return Motion
]========])

source(runtime,"ModuleScript","ItemRules",[========[local Rules={Price=30,StartingCoins=50,Award=10,AwardInterval=60,Duration=3,Cooldown=60}
local function finite(value,default)
 return type(value)=="number" and value==value and math.abs(value)<math.huge and value or default
end
function Rules.profile(data)
 data=type(data)=="table" and data or {}
 return {version=1,coins=math.clamp(math.floor(finite(data.coins,Rules.StartingCoins)),0,1000000),
  apple=data.apple==true,nextAppleAt=math.max(0,finite(data.nextAppleAt,0))}
end
function Rules.apply(data,action,now)
 local p=Rules.profile(data)
 if action=="BuyApple" then
  if p.apple then return p,false,"Você já tem esta maçã." end
  if p.coins<Rules.Price then return p,false,"Você precisa de 30 moedas." end
  p.coins-=Rules.Price p.apple=true return p,true,"Maçã comprada! Equipe na mochila e use."
 elseif action=="UseApple" then
  if not p.apple then return p,false,"Compre a maçã primeiro." end
  if now<p.nextAppleAt then return p,false,"Aguarde "..math.ceil(p.nextAppleAt-now).." s para usar novamente." end
  p.nextAppleAt=now+Rules.Cooldown return p,true,"Invisível por 3 segundos."
 elseif action=="Award" then
  p.coins=math.min(1000000,p.coins+Rules.Award) return p,true,"+10 moedas por jogar na ilha."
 end
 return p,false,"Ação inválida."
end
return Rules
]========])

source(runtime,"ModuleScript","Routes",[========[return {
 {name="VilaPraia",width=10,points={{104,87,16},{121,92,16},{124,126,16},{116,160,13},{104,215,8},{100,264,5.4}}},
 {name="VilaLago",width=9,points={{104,87,16},{80,87,16},{45,70,16},{10,22,19},{4,-31,21},{-17,-88,23}}},
 {name="VilaBosque",width=9,points={{104,87,16},{81,88,16},{80,126,16},{31,128,16},{-35,125,16},{-94,124,16},{-166,105,18},{-212,59,19}}},
 {name="TrilhaMirante",width=7,points={{-212,59,19},{-292,-14,28},{-208,-47,40},{-294,-98,52},{-184,-118,64},{-266,-170,77},{-190,-188,89}}},
 {name="LagoBosque",width=7,points={{4,-31,21},{-10,37,20},{-42,69,18},{-100,70,17},{-166,105,18}}}
}
]========])

source(SSS,"ModuleScript","SerenaInvisibility",[========[local Effect={}
function Effect.begin(character)
 local saved={} local closed=false
 local function save(instance,property,value)
  saved[instance]=saved[instance] or {}
  if saved[instance][property]==nil then saved[instance][property]=instance[property] end
  instance[property]=value
 end
 local function hide(d)
  if closed then return end
  if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then save(d,"Transparency",1)
  elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Sparkles") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Highlight") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("Light") then save(d,"Enabled",false)
  elseif d:IsA("ForceField") then save(d,"Visible",false)
  elseif d:IsA("Humanoid") then save(d,"DisplayDistanceType",Enum.HumanoidDisplayDistanceType.None) end
 end
 for _,d in ipairs(character:GetDescendants()) do hide(d) end
 local connection=character.DescendantAdded:Connect(hide)
 character:SetAttribute("SerenaInvisible",true)
 local function restore()
  if closed then return end closed=true connection:Disconnect()
  for d,properties in pairs(saved) do
   if d.Parent and d:IsDescendantOf(character) then
    for key,value in pairs(properties) do pcall(function()d[key]=value end) end
   end
  end
  if character.Parent then character:SetAttribute("SerenaInvisible",false) end
  table.clear(saved)
 end
 return restore
end
return Effect
]========])

run([========[local world=workspace:WaitForChild("IlhaSerena") local terrain=workspace.Terrain
local CollectionService=game:GetService("CollectionService")
local routes=require(game.ReplicatedStorage.SerenaRuntime.Routes)
local rng=Random.new(7913817)
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={terrain} ray.IgnoreWater=true
local function floor(x,z)
 local hit=workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-310,0),ray)
 assert(hit,"Ground absent at "..x..","..z) return hit.Position.Y
end
local wood=Color3.fromRGB(151,117,78) local darkWood=Color3.fromRGB(94,78,59) local stone=Color3.fromRGB(173,171,150)
local function part(parent,name,size,cf,color,material,shape)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.Wood
 p.Anchored=true p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end p.Parent=parent return p
end
local function rod(parent,name,a,b,diameter,color)
 return part(parent,name,Vector3.new((b-a).Magnitude,diameter,diameter),CFrame.lookAt((a+b)*.5,b)*CFrame.Angles(0,math.pi/2,0),color,Enum.Material.Wood,Enum.PartType.Cylinder)
end
local function trunkBase(m)
 local base local trunk
 for _,p in ipairs(m:GetChildren()) do if p:IsA("BasePart") and (p.Name=="Tronco" or p.Name=="TroncoCurvo") then
  local a=p.CFrame:PointToWorldSpace(Vector3.new(-p.Size.X/2,0,0)) local b=p.CFrame:PointToWorldSpace(Vector3.new(p.Size.X/2,0,0))
  local q=a.Y<b.Y and a or b if not base or q.Y<base.Y then base=q trunk=p end
 end end
 return base,trunk
end
local treeCount=0
for _,m in ipairs(world:GetDescendants()) do
 if m:IsA("Model") and (m.Name=="Árvore" or m.Name=="Palmeira") then
  local base,trunk=trunkBase(m) assert(base,"Tree trunk missing")
  local soil=floor(base.X,base.Z) local sink=m.Name=="Árvore" and .85 or .65
  m:PivotTo(m:GetPivot()+Vector3.new(0,soil-base.Y-sink,0))
  m:SetAttribute("SerenaRootCF",CFrame.new(base.X,soil,base.Z)) m:SetAttribute("SerenaRootDepth",sink)
  m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  local radius=trunk.Size.Y*1.3
  for i=1,4 do
   local angle=i*math.pi/2+rng:NextNumber(-.2,.2) local x,z=base.X+math.cos(angle)*radius,base.Z+math.sin(angle)*radius
   local root=rod(m,"RaizEnterrada",Vector3.new(base.X,soil+.1,base.Z),Vector3.new(x,floor(x,z)-.35,z),trunk.Size.Y*.46,trunk.Color)
   root.CanCollide=false root.CanQuery=false
  end
  for _,p in ipairs(m:GetChildren()) do
   if p:IsA("BasePart") and (p.Name=="Galho" or p.Name=="Coco") then p.CanCollide=false p.CanQuery=false end
   if p:IsA("BasePart") and (p.Name=="Copa" or p.Name=="CopaSuperior" or p.Name=="Folha") then
    p.CanCollide=false p.CanQuery=false p:SetAttribute("SerenaRestCF",p.CFrame)
    p:SetAttribute("SerenaWindStrength",m.Name=="Palmeira" and .055 or .018)
    CollectionService:AddTag(p,"SerenaWindFoliage")
    if p.Name~="Folha" then
     p.Size=Vector3.new(p.Size.X*1.08,p.Size.Y*.73,p.Size.Z)
     p.Material=Enum.Material.LeafyGrass
     for j=1,2 do
      local offset=Vector3.new(rng:NextNumber(-.35,.35)*p.Size.X,rng:NextNumber(-.1,.24)*p.Size.Y,rng:NextNumber(-.35,.35)*p.Size.Z)
      local leaf=part(m,"FolhagemDetalhada",Vector3.new(p.Size.X*.46,p.Size.Y*.53,p.Size.Z*.42),p.CFrame*CFrame.new(offset)*CFrame.Angles(rng:NextNumber(-.2,.2),rng:NextNumber(-1,1),.1),p.Color:Lerp(Color3.fromRGB(75,118,68),rng:NextNumber(.05,.2)),Enum.Material.LeafyGrass,Enum.PartType.Ball)
      leaf.CanCollide=false leaf.CanQuery=false leaf:SetAttribute("SerenaRestCF",leaf.CFrame) leaf:SetAttribute("SerenaWindStrength",.025) CollectionService:AddTag(leaf,"SerenaWindFoliage")
     end
    end
   end
  end
  treeCount+=1
 end
end
-- Bridges are built against measured banks, with a continuous deck and buried supports.
local bridgeSpecs={}
for _,z in ipairs({70,124}) do
 local old=world.TrilhasEMirante:FindFirstChild("Ponte"..z) assert(old,"Missing bridge")
 local cf=old:GetBoundingBox() local cx=cf.X-.1 old:Destroy()
 local m=Instance.new("Model") m.Name="Ponte"..z m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=world.TrilhasEMirante
 local left,right=cx-31,cx+31
 local function bank(x)
  local y=-math.huge for dz=-4.4,4.4,1.1 do y=math.max(y,floor(x,z+dz)) end return y+.22
 end
 local ly,ry=bank(left),bank(right)
 local arch=1.6
 for x=left+.5,right-.5,.5 do
  local t=(x-left)/(right-left)
  arch=math.max(arch,(bank(x)-(ly+(ry-ly)*t))/math.sin(t*math.pi))
 end
 assert(arch<5,"Banks require a redesigned bridge")
 local function top(x)
  local t=math.clamp((x-left)/(right-left),0,1)
  return ly+(ry-ly)*t+math.sin(t*math.pi)*arch
 end
 local count=36 local step=(right-left)/count local deckWidth=9
 for i=0,count-1 do
  local x=left+(i+.5)*step local a,b=top(x-step/2),top(x+step/2) local angle=math.atan2(b-a,step)
  local p=part(m,"Prancha",Vector3.new(step+.035,.5,deckWidth),CFrame.new(x,top(x)-.25,z)*CFrame.Angles(0,0,angle),wood:Lerp(darkWood,(i%4)*.025),Enum.Material.WoodPlanks)
  p:SetAttribute("WalkingSurface",true)
  for _,side in ipairs({-1,1}) do
   local bolt=part(m,"Cavilha",Vector3.new(.09,.018,.09),p.CFrame*CFrame.new(0,.259,side*3.8),Color3.fromRGB(57,62,61),Enum.Material.Metal)
   bolt.CanCollide=false bolt.CanQuery=false
  end
 end
 for i=0,8 do
  local x=left+(right-left)*i/8
  for _,side in ipairs({-1,1}) do
   local zz=z+side*4.45 local y=top(x)
   local pole=rod(m,"PosteCorrimão",Vector3.new(x,y-.5,zz),Vector3.new(x,y+3.3,zz),.42,darkWood)
   if i<8 then
    local xx=left+(right-left)*(i+1)/8
    for _,height in ipairs({1.3,3}) do rod(m,"Corrimão",Vector3.new(x,y+height,zz),Vector3.new(xx,top(xx)+height,zz),height==3 and .34 or .24,wood) end
    part(m,"VigaLongitudinal",Vector3.new(math.sqrt((xx-x)^2+(top(xx)-y)^2),.7,.6),CFrame.new((x+xx)/2,(y+top(xx))/2-.8,zz)*CFrame.Angles(0,0,math.atan2(top(xx)-y,xx-x)),darkWood)
   end
  end
 end
 for _,dx in ipairs({-25,-16,16,25}) do
  local x=cx+dx local y=top(x)
  part(m,"Travessa",Vector3.new(1,.75,10.3),CFrame.new(x,y-.95,z),darkWood)
  for _,side in ipairs({-1,1}) do
   local zz=z+side*4.1 local bottom=floor(x,zz)-1
   local footing=part(m,"Sapata",Vector3.new(2,1.6,2),CFrame.new(x,bottom+.2,zz),stone,Enum.Material.Rock) footing.CanCollide=false
   rod(m,"EstacaEnterrada",Vector3.new(x,bottom,zz),Vector3.new(x,y-.5,zz),.85,darkWood)
  end
 end
 -- Short shallow ramps connect to the actual shoulders without vertical lips.
 for _,side in ipairs({-1,1}) do
  local inner=side==-1 and left or right local outer=inner+side*5
  local outerY=bank(outer)-.12 local innerY=top(inner)
  local a,b=side==-1 and outer or inner,side==-1 and inner or outer
  local ya,yb=side==-1 and outerY or innerY,side==-1 and innerY or outerY
  local slope=math.atan2(yb-ya,b-a)
  part(m,"RampaDeEntrada",Vector3.new(math.sqrt((b-a)^2+(yb-ya)^2)+.08,.3,9),CFrame.new((a+b)/2,(ya+yb)/2-.15,z)*CFrame.Angles(0,0,slope),wood,Enum.Material.WoodPlanks)
 end
 m:SetAttribute("SpanLeft",left) m:SetAttribute("SpanRight",right) m:SetAttribute("BankLeftY",ly) m:SetAttribute("BankRightY",ry) m:SetAttribute("ArchRise",arch)
 table.insert(bridgeSpecs,{model=m,left=left,right=right,z=z,top=top})
end
-- Relocate trunks that intersect a new bridge approach, keeping the walk corridor open.
local function safeTreePoint(x,z)
 local hit=workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-300,0),ray)
 if not hit or hit.Material~=Enum.Material.Grass or hit.Normal.Y<.8 then return false end
 for _,m in ipairs(world:GetDescendants())do
  if m:IsA("Model") and m:GetAttribute("SerenaRootCF")then
   local root=m:GetAttribute("SerenaRootCF") if Vector2.new(x-root.X,z-root.Z).Magnitude<7 then return false end
  end
 end
 for _,b in ipairs(bridgeSpecs)do if x>b.left-9 and x<b.right+9 and math.abs(z-b.z)<8 then return false end end
 for _,r in ipairs(routes)do for i=1,#r.points-1 do
  local a,b=r.points[i],r.points[i+1] local dx,dz=b[1]-a[1],b[2]-a[2]
  local t=math.clamp(((x-a[1])*dx+(z-a[2])*dz)/(dx*dx+dz*dz),0,1)
  if Vector2.new(x-a[1]-t*dx,z-a[2]-t*dz).Magnitude<r.width/2+4 then return false end
 end end
 return true
end
local relocated=0
for _,m in ipairs(world:GetDescendants())do if m:IsA("Model") and (m.Name=="Árvore" or m.Name=="Palmeira")then
 local root=m:GetAttribute("SerenaRootCF") local blocked=false
 for _,b in ipairs(bridgeSpecs)do if root.X>b.left-8 and root.X<b.right+8 and math.abs(root.Z-b.z)<6.5 then blocked=true end end
 if blocked then
  local x,z
  for radius=14,32,6 do
   for i=1,16 do local angle=i*math.pi*2/16 local xx,zz=root.X+math.cos(angle)*radius,root.Z+math.sin(angle)*radius
    if safeTreePoint(xx,zz)then x,z=xx,zz break end
   end
   if x then break end
  end
  assert(x,"No safe tree relocation")
  local base,trunk=trunkBase(m) local soil=floor(x,z) local sink=m:GetAttribute("SerenaRootDepth")
  m:PivotTo(m:GetPivot()+Vector3.new(x-base.X,soil-base.Y-sink,z-base.Z)) m:SetAttribute("SerenaRootCF",CFrame.new(x,soil,z))
  for _,p in ipairs(m:GetChildren())do if p.Name=="RaizEnterrada" then p:Destroy()end end
  for i=1,4 do
   local angle=i*math.pi/2 local xx,zz=x+math.cos(angle)*trunk.Size.Y*1.3,z+math.sin(angle)*trunk.Size.Y*1.3
   local rootPart=rod(m,"RaizEnterrada",Vector3.new(x,soil+.1,z),Vector3.new(xx,floor(xx,zz)-.35,zz),trunk.Size.Y*.46,trunk.Color) rootPart.CanCollide=false rootPart.CanQuery=false
  end
  for _,p in ipairs(m:GetChildren())do if p:IsA("BasePart") and CollectionService:HasTag(p,"SerenaWindFoliage")then p:SetAttribute("SerenaRestCF",p.CFrame)end end
  relocated+=1
 end
end end
world:SetAttribute("TreesRelocatedForAccess",relocated)
-- Pier foundation, safe deck edges and a flush shore approach.
local coast=world.PraiaEPier
for _,d in ipairs(coast:GetChildren()) do if d.Name=="DegrauDoPier" then d:Destroy() end end
local entranceY=floor(100,257)+.1 local endY=6.75
part(coast,"RampaDoPier",Vector3.new(12,.35,math.sqrt(13^2+(endY-entranceY)^2)),CFrame.new(100,(entranceY+endY)/2-.175,263.5)*CFrame.Angles(-math.atan2(endY-entranceY,13),0,0),wood,Enum.Material.WoodPlanks)
for _,side in ipairs({-1,1}) do
 part(coast,"VigaDoPier",Vector3.new(.6,.9,70),CFrame.new(100+side*4.8,5.72,303),darkWood)
 for _,z in ipairs({331,343}) do rod(coast,"EstacaDeck",Vector3.new(100+side*9,floor(100+side*9,z)-1,z),Vector3.new(100+side*9,6.5,z),1,darkWood) end
 rod(coast,"CorrimãoDeck",Vector3.new(100+side*11,9.4,331),Vector3.new(100+side*11,9.4,344),.35,wood)
 for _,z in ipairs({331,338,344}) do rod(coast,"PosteDeck",Vector3.new(100+side*11,6.45,z),Vector3.new(100+side*11,9.65,z),.5,darkWood) end
end
for _,dx in ipairs({-7,0,7}) do rod(coast,"PosteFundoDeck",Vector3.new(100+dx,6.45,344),Vector3.new(100+dx,9.65,344),.5,darkWood) end
rod(coast,"CorrimãoFundoDeck",Vector3.new(89,9.4,344),Vector3.new(111,9.4,344),.35,wood)
for _,p in ipairs(coast:GetChildren()) do if p:IsA("BasePart") and (p.Name=="FundoDoBarco" or p.Name=="LateralDoBarco" or p.Name=="BancoDoBarco") then
 p:SetAttribute("SerenaRestCF",p.CFrame) p.CanCollide=false CollectionService:AddTag(p,"SerenaFloatingDetail")
end end
-- Ground contacts for lake pavilion and trail furniture.
local pavilion=world.CachoeiraELago:FindFirstChild("PavilhãoDoLago")
local lakeDeck=pavilion:FindFirstChild("DeckLago")
for _,dx in ipairs({-7.5,7.5}) do for _,dz in ipairs({-6.5,6.5}) do
 local x,z=lakeDeck.Position.X+dx,lakeDeck.Position.Z+dz
 rod(pavilion,"ApoioEnterrado",Vector3.new(x,floor(x,z)-.8,z),Vector3.new(x,lakeDeck.Position.Y-.1,z),.7,darkWood)
end end
-- Bench legs meet their own contact point, including uneven trail shoulders.
for _,p in ipairs(world:GetDescendants()) do if p:IsA("BasePart") and p.Name=="Pé" then
 local top=p.Position.Y+p.Size.Y/2 local bottom=floor(p.Position.X,p.Position.Z)-.12
 if top-bottom>.25 then
  local rotation=p.CFrame.Rotation p.Size=Vector3.new(p.Size.X,top-bottom,p.Size.Z)
  p.CFrame=CFrame.new(p.Position.X,(top+bottom)/2,p.Position.Z)*rotation
 end
end end
-- The fountain has an open stone rim around visible water, rather than a filled drum.
local fountain=world.VilaCosteira:FindFirstChild("Fonte")
local fountainBase=fountain.Position.Y-.8 fountain:Destroy()
local bottom=part(world.VilaCosteira,"BaseDaFonte",Vector3.new(.4,12.7,12.7),CFrame.new(104,fountainBase+.3,108)*CFrame.Angles(0,0,math.pi/2),stone,Enum.Material.Slate,Enum.PartType.Cylinder)
for i=1,28 do
 local angle=i*math.pi*2/28 local radius=6.13
 part(world.VilaCosteira,"BordaDaFonte",Vector3.new(1.43,1.1,.55),CFrame.new(104+math.cos(angle)*radius,fountainBase+1,108+math.sin(angle)*radius)*CFrame.Angles(0,-angle+math.pi/2,0),stone,Enum.Material.Slate)
end
local fountainWater=world.VilaCosteira:FindFirstChild("ÁguaDaFonte") fountainWater.Transparency=.32 fountainWater.Reflectance=.12
world:SetAttribute("FountainWaterY",fountainWater.Position.Y)
-- Flowers use the actual ground under each stem, rather than a shared center height.
for _,stem in ipairs(world.Jardins:GetChildren()) do if stem:IsA("BasePart") and stem.Name=="HasteSilvestre" then
 local a=stem.CFrame:PointToWorldSpace(Vector3.new(-stem.Size.X/2,0,0)) local b=stem.CFrame:PointToWorldSpace(Vector3.new(stem.Size.X/2,0,0))
 local base=a.Y<b.Y and a or b local y=floor(base.X,base.Z) local offset=y-base.Y-.06
 stem.CFrame+=Vector3.new(0,offset,0)
 for _,flower in ipairs(world.Jardins:GetChildren()) do if flower:IsA("BasePart") and flower.Name=="FloresSilvestres" and math.abs(flower.Position.X-base.X)<.05 and math.abs(flower.Position.Z-base.Z)<.05 then flower.CFrame+=Vector3.new(0,offset,0) end end
end end
-- A few luminous insects provide readable dusk without filling the view with particles.
for _,q in ipairs({{-150,55},{-220,47},{-20,-80},{-148,-7}}) do
 local anchor=part(world.Jardins,"VagalumesDoBosque",Vector3.new(.1,.1,.1),CFrame.new(q[1],floor(q[1],q[2])+2,q[2]),Color3.new(1,1,1))
 anchor.Transparency=1 anchor.CanCollide=false anchor.CanQuery=false
 local e=Instance.new("ParticleEmitter") e.Name="Vagalumes" e.Texture="rbxasset://textures/particles/sparkles_main.dds" e.Rate=2 e.Lifetime=NumberRange.new(3,5) e.Speed=NumberRange.new(.3,.8)
 e.SpreadAngle=Vector2.new(180,180) e.Acceleration=Vector3.new(0,.15,0) e.Color=ColorSequence.new(Color3.fromRGB(205,230,141)) e.LightEmission=.7 e.LightInfluence=.2
 e.Size=NumberSequence.new(.1) e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.1),NumberSequenceKeypoint.new(.7,.25),NumberSequenceKeypoint.new(1,1)}) e.Enabled=false e.Parent=anchor
end
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(110,143,88))
terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(98,135,80))
local decoration=pcall(function()terrain.Decoration=true terrain.GrassLength=.7 end)
world:SetAttribute("NativeGrassSupported",decoration) world:SetAttribute("InteractiveGrass",true) world:SetAttribute("TreesGrounded",treeCount)
world:SetAttribute("DesignVersion",2)
]========])

run([========[local RS=game:GetService("ReplicatedStorage") local SS=game:GetService("ServerStorage")
local stock=SS:FindFirstChild("SerenaItems") or Instance.new("Folder") stock.Name="SerenaItems" stock.Parent=SS
stock:ClearAllChildren()
local tool=Instance.new("Tool") tool.Name="Maçã da Névoa" tool.ToolTip="Invisível por 3 s · recarga de 60 s" tool.CanBeDropped=false tool.RequiresHandle=true
tool:SetAttribute("SerenaItem","Apple") tool.Grip=CFrame.new(0,-.2,0)*CFrame.Angles(0,0,math.rad(-10))
local function applePart(name,size,cf,color,material,shape)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.SmoothPlastic
 p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Shape=shape or Enum.PartType.Ball p.Parent=tool return p
end
local red=Color3.fromRGB(183,42,40)
local handle=applePart("Handle",Vector3.new(1.02,.97,1.02),CFrame.new(),red)
for i=1,5 do
 local a=i*math.pi*2/5
 applePart("Gomo",Vector3.new(.75,.95,.75),CFrame.new(math.cos(a)*.25,-.015,math.sin(a)*.25),red:Lerp(Color3.fromRGB(229,67,45),i%3*.09))
end
applePart("Base",Vector3.new(.66,.55,.66),CFrame.new(0,-.38,0),Color3.fromRGB(153,34,34))
applePart("Caule",Vector3.new(.1,.45,.11),CFrame.new(.02,.61,0)*CFrame.Angles(0,0,-.19),Color3.fromRGB(108,75,42),Enum.Material.Wood,Enum.PartType.Block)
applePart("Folha",Vector3.new(.47,.06,.24),CFrame.new(.2,.7,0)*CFrame.Angles(0,.5,-.25),Color3.fromRGB(78,125,56))
for _,p in ipairs(tool:GetChildren()) do if p:IsA("BasePart") and p~=handle then local weld=Instance.new("WeldConstraint") weld.Part0=handle weld.Part1=p weld.Parent=p end end
tool.Parent=stock
local runtime=RS:WaitForChild("SerenaRuntime")
local old=runtime:FindFirstChild("ApplePreview") if old then old:Destroy() end
local preview=Instance.new("Model") preview.Name="ApplePreview"
for _,p in ipairs(tool:GetChildren()) do if p:IsA("BasePart") then
 local clone=p:Clone() for _,d in ipairs(clone:GetChildren()) do if d:IsA("WeldConstraint") then d:Destroy() end end
 clone.Anchored=true clone.Parent=preview
end end
preview.PrimaryPart=preview:FindFirstChild("Handle") preview.Parent=runtime
-- A sheltered produce stand gives the shop a physical place in the village.
local world=workspace:WaitForChild("IlhaSerena")
local stand=Instance.new("Model") stand.Name="FeiraDeFrutas" stand.ModelStreamingMode=Enum.ModelStreamingMode.Atomic stand.Parent=world.VilaCosteira
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain} rp.IgnoreWater=true
local hit=workspace:Raycast(Vector3.new(128,100,69),Vector3.new(0,-150,0),rp) assert(hit,"Shop ground absent")
local cf=CFrame.new(128,hit.Position.Y,69)
local function stallPart(name,size,offset,color,material)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf*offset p.Color=color p.Material=material or Enum.Material.WoodPlanks p.Anchored=true p.CanTouch=false p.Parent=stand return p
end
for _,x in ipairs({-3.5,3.5}) do
 for _,z in ipairs({-1.7,1.7}) do stallPart("PéDaBanca",Vector3.new(.3,2.8,.3),CFrame.new(x,1.2,z),Color3.fromRGB(115,90,61)) end
 stallPart("PosteDoToldo",Vector3.new(.25,6.8,.25),CFrame.new(x,3.2,-1.8),Color3.fromRGB(115,90,61))
end
local tableTop=stallPart("Banca",Vector3.new(8,.3,4.5),CFrame.new(0,2.75,0),Color3.fromRGB(166,132,92))
for i=0,7 do stallPart("Toldo",Vector3.new(1,.15,5.4),CFrame.new(-3.5+i,6.8,0)*CFrame.Angles(math.rad(8),0,0),i%2==0 and Color3.fromRGB(105,139,93) or Color3.fromRGB(234,225,194),Enum.Material.Fabric) end
for _,x in ipairs({-2,1.8}) do
 stallPart("CaixaDeFrutas",Vector3.new(3.1,.6,2.6),CFrame.new(x,3.08,0),Color3.fromRGB(126,99,67))
 for i=1,3 do local fruit=preview:Clone() fruit.Name="MaçãNaFeira" fruit:ScaleTo(.54) fruit:PivotTo(cf*CFrame.new(x-1+i*.55,3.72,.1)) fruit.Parent=stand end
end
local prompt=Instance.new("ProximityPrompt") prompt.Name="SerenaShopPrompt" prompt.ActionText="Abrir loja" prompt.ObjectText="Feira de frutas" prompt.HoldDuration=.15 prompt.MaxActivationDistance=11 prompt.RequiresLineOfSight=false prompt.Parent=tableTop
local sign=stallPart("PlacaDaFeira",Vector3.new(5.8,1.2,.15),CFrame.new(0,5.7,1.85),Color3.fromRGB(67,92,63))
local surface=Instance.new("SurfaceGui") surface.Face=Enum.NormalId.Back surface.PixelsPerStud=45 surface.Parent=sign
local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1) label.Text="FEIRA DA ILHA" label.Font=Enum.Font.GothamMedium label.TextSize=24 label.TextColor3=Color3.fromRGB(242,234,207) label.Parent=surface
]========])

local previous=RS:FindFirstChild("SerenaShop") if previous then previous:Destroy() end
local remote=Instance.new("RemoteEvent") remote.Name="SerenaShop" remote.Parent=RS

source(SSS,"Script","SerenaAmbienceServer",[========[local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local Climate=require(game:GetService("ReplicatedStorage"):WaitForChild("SerenaRuntime"):WaitForChild("Climate"))
local world=workspace:WaitForChild("IlhaSerena")
local terrain=workspace.Terrain
world:SetAttribute("RenderingServerApplied",Climate.rendering(Lighting))
local lamps={}
for _,d in ipairs(world:GetDescendants()) do if d:IsA("PointLight") then table.insert(lamps,d) end end
local start=workspace:GetServerTimeNow()
world:SetAttribute("ClockStart",start) world:SetAttribute("DayLength",Climate.DayLength)
local sequence={{"Sol",300},{"Nublado",55},{"Chuva",100},{"Nublado",45},{"Sol",360},{"Nublado",65},{"Chuva",130},{"Nublado",45}}
local index=1 local nextWeather=start+sequence[1][2] local changed=start local previous="Sol"
world:SetAttribute("WeatherChanged",changed) world:SetAttribute("PreviousWeather",previous) world:SetAttribute("Weather","Sol")
local lastNight
Players.CharacterAutoLoads=true Players.RespawnTime=3
local function ready(c)
 local h=c:WaitForChild("Humanoid",10)
 if h then h.WalkSpeed=16 h.JumpPower=50 h.UseJumpPower=true h.PlatformStand=false h.AutoRotate=true end
end
local function bind(p)
 p.CharacterAdded:Connect(ready)
 if p.Character then task.spawn(ready,p.Character) end
end
Players.PlayerAdded:Connect(bind) for _,p in ipairs(Players:GetPlayers()) do bind(p) end
while true do
 local now=workspace:GetServerTimeNow()
 if now>=nextWeather then
  previous=sequence[index][1] index=index%#sequence+1 changed=now nextWeather=now+sequence[index][2]
  world:SetAttribute("PreviousWeather",previous) world:SetAttribute("Weather",sequence[index][1]) world:SetAttribute("WeatherChanged",changed)
 end
 local hour=Climate.hour(now,start)
 local rain,clear=Climate.weights(now,changed,previous,sequence[index][1])
 local p=Climate.profile(hour,rain,clear,now) p.hour=hour
 Climate.apply(Lighting,terrain,p)
 world:SetAttribute("TimePhase",Climate.phase(hour)) world:SetAttribute("RainIntensity",rain)
 local night=p.sun<.23
 if night~=lastNight then
  for _,light in ipairs(lamps) do if light.Parent then light.Enabled=night end end
  for _,d in ipairs(world:GetDescendants()) do
   if d:IsA("ParticleEmitter") and d.Name=="Vagalumes" then d.Enabled=night end
  end
  lastNight=night
 end
 task.wait(.5)
end
]========])

source(SSS,"Script","SerenaShopServer",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local DataStoreService=game:GetService("DataStoreService")
local Rules=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("ItemRules"))
local Effect=require(script.Parent:WaitForChild("SerenaInvisibility"))
local remote=RS:WaitForChild("SerenaShop")
local template=ServerStorage:WaitForChild("SerenaItems"):WaitForChild("Maçã da Névoa")
local prompt=workspace:WaitForChild("IlhaSerena"):WaitForChild("VilaCosteira"):WaitForChild("FeiraDeFrutas"):WaitForChild("Banca"):WaitForChild("SerenaShopPrompt")
prompt.Triggered:Connect(function(p)remote:FireClient(p,"Open")end)
local store=DataStoreService:GetDataStore("SerenaItems_v1")
local profiles={} local temporary={} local busy={} local requestTimes={} local active={}
local function attributes(p,data)
 p:SetAttribute("SerenaCoins",data.coins) p:SetAttribute("SerenaAppleOwned",data.apple)
 p:SetAttribute("SerenaAppleReadyAt",data.nextAppleAt) p:SetAttribute("SerenaDataSaved",not temporary[p])
 p:SetAttribute("SerenaShopReady",true)
end
local function message(p,text,ok)
 if p.Parent then remote:FireClient(p,"Message",text,ok==true) end
end
local function transaction(p,action)
 if not profiles[p] or busy[p] then return false,"Aguarde um instante." end
 busy[p]=true
 local now=workspace:GetServerTimeNow() local accepted=false local feedback=""
 local result
 if not temporary[p] then
  local ok,data=pcall(function()
   return store:UpdateAsync("u"..p.UserId,function(old)
    local nextData,succeeded,text=Rules.apply(old,action,now)
    accepted=succeeded feedback=text return nextData
   end)
  end)
  if ok then result=Rules.profile(data)
  else
   -- Do not acknowledge a permanent purchase if saving failed.
   busy[p]=nil return false,"Não foi possível salvar agora. Tente novamente."
  end
 else result,accepted,feedback=Rules.apply(profiles[p],action,now) end
 profiles[p]=result if p.Parent then attributes(p,result) end
 busy[p]=nil return accepted,feedback
end
local useApple
local function ensureApple(p)
 if not profiles[p] or not profiles[p].apple then return nil end
 local backpack=p:FindFirstChildOfClass("Backpack") if not backpack then return nil end
 for _,container in ipairs({backpack,p.Character}) do
  if container then for _,d in ipairs(container:GetChildren()) do
   if d:IsA("Tool") and d:GetAttribute("SerenaItem")=="Apple" then return d end
  end end
 end
 local tool=template:Clone() tool.CanBeDropped=false tool.Parent=backpack
 tool.Activated:Connect(function()if p.Character and tool.Parent==p.Character then useApple(p) end end)
 return tool
end
useApple=function(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 or active[p] then return end
 local item=ensureApple(p) if not item then message(p,"Compre a maçã primeiro.",false) return end
 if item.Parent~=c then h:EquipTool(item) end
 local accepted,feedback=transaction(p,"UseApple")
 if not accepted then message(p,feedback,false) return end
 -- A respawn during DataStore I/O must never hide the replacement character.
 if not p.Parent or p.Character~=c or h.Health<=0 or not c.Parent then return end
 local restore=Effect.begin(c)
 active[p]={character=c,restore=restore}
 p:SetAttribute("SerenaInvisibleUntil",workspace:GetServerTimeNow()+Rules.Duration)
 message(p,feedback,true)
 task.delay(Rules.Duration,function()
  restore()
  if active[p] and active[p].character==c then active[p]=nil if p.Parent then p:SetAttribute("SerenaInvisibleUntil",0) end end
 end)
end
local function character(p,c)
 local effect=active[p]
 if effect then effect.restore() active[p]=nil p:SetAttribute("SerenaInvisibleUntil",0) end
 task.spawn(function()
  c:WaitForChild("Humanoid",10) p:WaitForChild("Backpack",10)
  if p.Character==c then ensureApple(p) end
 end)
end
local function added(p)
 p:SetAttribute("SerenaShopReady",false)
 p.CharacterAdded:Connect(function(c)character(p,c)end)
 local ok,data=pcall(function()
  return store:UpdateAsync("u"..p.UserId,function(old)return Rules.profile(old)end)
 end)
 if not p.Parent then return end
 profiles[p]=Rules.profile(ok and data or nil) temporary[p]=not ok
 attributes(p,profiles[p])
 if p.Character then character(p,p.Character) end
end
Players.PlayerAdded:Connect(function(p)task.spawn(added,p)end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
Players.PlayerRemoving:Connect(function(p)
 if active[p] then active[p].restore() end
 profiles[p]=nil temporary[p]=nil busy[p]=nil requestTimes[p]=nil active[p]=nil
end)
remote.OnServerEvent:Connect(function(p,action)
 if action~="BuyApple" and action~="UseApple" then return end
 local now=os.clock() if requestTimes[p] and now-requestTimes[p]<.35 then return end requestTimes[p]=now
 if action=="UseApple" then useApple(p) return end
 if not p:FindFirstChildOfClass("Backpack") then message(p,"Espere o personagem aparecer.",false) return end
 local accepted,feedback=transaction(p,action)
 if accepted or (profiles[p] and profiles[p].apple) then ensureApple(p) end
 message(p,feedback,accepted)
end)
-- Rewards are generated by elapsed server time, never by a client claim.
task.spawn(function()
 local nextAward={}
 while true do
  local now=workspace:GetServerTimeNow()
  for _,p in ipairs(Players:GetPlayers()) do
   if profiles[p] then
    nextAward[p]=nextAward[p] or now+Rules.AwardInterval
    if now>=nextAward[p] and not busy[p] then
     nextAward[p]=now+Rules.AwardInterval
     task.spawn(function()local ok,text=transaction(p,"Award") if ok then message(p,text,true) end end)
    end
   end
  end
  for p in pairs(nextAward) do if not p.Parent then nextAward[p]=nil end end
  task.wait(1)
 end
end)
]========])

source(SPS,"LocalScript","SerenaAmbienceClient",[========[local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local Climate=require(game.ReplicatedStorage:WaitForChild("SerenaRuntime"):WaitForChild("Climate"))
local world=workspace:WaitForChild("IlhaSerena")
local player=Players.LocalPlayer
player:SetAttribute("SerenaRenderingApplied",Climate.rendering(Lighting))
local rain=Instance.new("Folder") rain.Name="SerenaLocalRain" rain.Parent=workspace
local rng=Random.new() local drops={}
local fountainDrops={}
for i=1,16 do
 local p=Instance.new("Part") p.Name="GotaDaFonte" p.Shape=Enum.PartType.Ball p.Size=Vector3.new(.13,.2,.13) p.Material=Enum.Material.Glass p.Color=Color3.fromRGB(167,222,223)
 p.Transparency=.35 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=rain
 fountainDrops[i]=p
end
for i=1,(UserInputService.TouchEnabled and 60 or 110) do
 local p=Instance.new("Part") p.Name="Chuva" p.Size=Vector3.new(.025,1.55,.025) p.Material=Enum.Material.Glass p.Color=Color3.fromRGB(203,223,235)
 p.Transparency=1 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=rain
 drops[i]={part=p,x=rng:NextNumber(-25,25),y=rng:NextNumber(-9,27),z=rng:NextNumber(-25,25)}
end
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Exclude ray.IgnoreWater=true
local nextRoofCheck=0 local outside=true local climateTime=0
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera if not camera then return end
 local now=workspace:GetServerTimeNow() local start=world:GetAttribute("ClockStart")
 local intensity=0
 if start then
  local hour=Climate.hour(now,start) Lighting.ClockTime=hour
  local wet,clear=Climate.weights(now,world:GetAttribute("WeatherChanged") or start,world:GetAttribute("PreviousWeather") or "Sol",world:GetAttribute("Weather") or "Sol")
  intensity=wet climateTime+=dt
  if climateTime>=.12 then
   climateTime=0 local profile=Climate.profile(hour,wet,clear,now) profile.hour=hour Climate.apply(Lighting,workspace.Terrain,profile)
  end
 end
 if intensity>.015 and os.clock()>nextRoofCheck then
  nextRoofCheck=os.clock()+.35
  local filters={rain} if player.Character then table.insert(filters,player.Character) end
  ray.FilterDescendantsInstances=filters
  local head=player.Character and player.Character:FindFirstChild("Head")
  outside=not workspace:Raycast(head and head.Position or camera.CFrame.Position,Vector3.new(0,140,0),ray)
 end
 local wind=workspace.GlobalWind local slant=math.atan2(wind.X,57)
 local waterY=world:GetAttribute("FountainWaterY")
 if waterY then
  for i,p in ipairs(fountainDrops) do
   if (camera.CFrame.Position-Vector3.new(104,waterY,108)).Magnitude<90 then
    local t=(now*.85+i/16)%1 local angle=i*2.39996 local spread=.15+math.sin(t*math.pi/2)*2.4
    p.CFrame=CFrame.new(104+math.cos(angle)*spread,waterY+3.05*(1-t)+math.sin(t*math.pi)*.3,108+math.sin(angle)*spread) p.Transparency=.35
   else p.Transparency=1 end
  end
 end
 for i,d in ipairs(drops) do
  if intensity>.015 and outside and i<=math.ceil(#drops*intensity) then
   d.y-=math.min(dt,.1)*57 d.x+=math.min(dt,.1)*wind.X*.45
   if d.y< -10 or d.x>29 then d.y=27 d.x=rng:NextNumber(-25,25) d.z=rng:NextNumber(-25,25) end
   d.part.CFrame=CFrame.new(camera.CFrame.Position+Vector3.new(d.x,d.y,d.z))*CFrame.Angles(0,0,-slant)
   d.part.Transparency=.48+(1-intensity)*.4
  elseif d.part.Transparency~=1 then d.part.Transparency=1 end
 end
end)
local function cameraFor(char)
 local hum=char:WaitForChild("Humanoid",10)
 if hum then local camera=workspace.CurrentCamera if camera then camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=hum camera.FieldOfView=70 end end
end
player.CharacterAdded:Connect(cameraFor)
if player.Character then task.spawn(cameraFor,player.Character) end
script.Destroying:Connect(function()rain:Destroy()end)
]========])

source(SPS,"LocalScript","SerenaGrassClient",[========[local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local CollectionService=game:GetService("CollectionService")
local Motion=require(game.ReplicatedStorage:WaitForChild("SerenaRuntime"):WaitForChild("GrassMotion"))
local player=Players.LocalPlayer
local world=workspace:WaitForChild("IlhaSerena")
local folder=Instance.new("Folder") folder.Name="SerenaInteractiveGrass" folder.Parent=workspace
local radius=UserInputService.TouchEnabled and 27 or 36
local limit=UserInputService.TouchEnabled and 185 or 325
local spacing=3.35 local cells={} local rejected={} local queue={} local queueIndex=1
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain,world} ray.IgnoreWater=false
local foliage={} local scenery={} local foliageTimer=0
local function addFoliage(p)if p:IsA("BasePart") then foliage[p]=p:GetAttribute("SerenaRestCF") or p.CFrame end end
for _,p in ipairs(CollectionService:GetTagged("SerenaWindFoliage")) do addFoliage(p) end
CollectionService:GetInstanceAddedSignal("SerenaWindFoliage"):Connect(addFoliage)
CollectionService:GetInstanceRemovedSignal("SerenaWindFoliage"):Connect(function(p)foliage[p]=nil end)
for _,p in ipairs(CollectionService:GetTagged("SerenaFloatingDetail")) do if p:IsA("BasePart") then scenery[p]=p:GetAttribute("SerenaRestCF") or p.CFrame end end
CollectionService:GetInstanceAddedSignal("SerenaFloatingDetail"):Connect(function(p)if p:IsA("BasePart") then scenery[p]=p:GetAttribute("SerenaRestCF") or p.CFrame end end)
CollectionService:GetInstanceRemovedSignal("SerenaFloatingDetail"):Connect(function(p)scenery[p]=nil end)
local function key(x,z)return x..":"..z end
local function rebuild(position)
 local cx,cz=math.floor(position.X/spacing),math.floor(position.Z/spacing)
 for k,c in pairs(cells) do
  if (Vector3.new(position.X,c.root.Y,position.Z)-c.root).Magnitude>radius+5 then
   for _,b in ipairs(c.blades) do b.part:Destroy() end cells[k]=nil
  end
 end
 local desired={} local n=math.ceil(radius/spacing)
 for dx=-n,n do for dz=-n,n do
  local x,z=cx+dx,cz+dz local distance=dx*dx+dz*dz local k=key(x,z)
  if distance*spacing*spacing<radius*radius and not cells[k] and (not rejected[k] or os.clock()>rejected[k]) then
   table.insert(desired,{x=x,z=z,k=k,distance=distance})
  end
 end end
 table.sort(desired,function(a,b)return a.distance<b.distance end)
 queue=desired queueIndex=1
 -- Rejected cells get rechecked after streaming or a move, without unbounded memory.
 for k,untilTime in pairs(rejected) do if os.clock()>untilTime+10 then rejected[k]=nil end end
end
local function createCell(q,position)
 local rng=Random.new((q.x*73856093+q.z*19349663)%2147483647)
 local x,z=q.x*spacing+rng:NextNumber(.15,2.65),q.z*spacing+rng:NextNumber(.15,2.65)
 local hit=workspace:Raycast(Vector3.new(x,position.Y+22,z),Vector3.new(0,-62,0),ray)
 if not hit or hit.Instance~=workspace.Terrain or hit.Material~=Enum.Material.Grass or hit.Normal.Y<.74 then rejected[q.k]=os.clock()+4 return end
 local root=hit.Position-Vector3.new(0,.13,0) local clump={root=root,blades={},bend=Vector3.zero,phase=rng:NextNumber(0,6.28)}
 for i=1,3 do
  local blade=Instance.new("WedgePart") blade.Name="FolhaDeGrama"
  local height=rng:NextNumber(.7,1.27) local yaw=rng:NextNumber(0,math.pi*2)
  blade.Size=Vector3.new(.055,height,rng:NextNumber(.16,.23))
  blade.Color=Color3.fromRGB(rng:NextInteger(91,122),rng:NextInteger(131,158),rng:NextInteger(67,84))
  blade.Material=Enum.Material.Grass blade.Anchored=true blade.CanCollide=false blade.CanTouch=false blade.CanQuery=false blade.CastShadow=false
  local point=root+Vector3.new(rng:NextNumber(-.22,.22),0,rng:NextNumber(-.22,.22))
  blade.CFrame=Motion.frame(point,height,yaw,Vector3.zero) blade.Parent=folder
  table.insert(clump.blades,{part=blade,root=point,height=height,yaw=yaw})
 end
 cells[q.k]=clump
end
local timer=0 local buildTimer=0 local lastPosition=Vector3.new(math.huge,0,0)
local function animate(dt)
 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local now=workspace:GetServerTimeNow() local position=root.Position
 if buildTimer<=0 or (position-lastPosition).Magnitude>spacing*1.5 then
  rebuild(position) buildTimer=.75 lastPosition=position
 end
 buildTimer-=dt
 local count=0 for _ in pairs(cells) do count+=1 end
 local made=0
 while queueIndex<=#queue and count<limit and made<10 do
  local q=queue[queueIndex] queueIndex+=1 made+=1
  if not cells[q.k] then createCell(q,position) if cells[q.k] then count+=1 end end
 end
 local actors={}
 for _,p in ipairs(Players:GetPlayers()) do
  local c=p.Character local r=c and c:FindFirstChild("HumanoidRootPart") local h=c and c:FindFirstChildOfClass("Humanoid")
  if r and h and h.Health>0 and (r.Position-position).Magnitude<radius+8 then
   local feet=r.Position.Y-(h.RigType==Enum.HumanoidRigType.R6 and 3 or h.HipHeight+r.Size.Y/2)
   table.insert(actors,{position=r.Position,feet=feet,velocity=r.AssemblyLinearVelocity})
  end
 end
 local parts={} local frames={} local wind=workspace.GlobalWind
 for _,c in pairs(cells) do
  c.bend=Motion.bend(c.root,actors,wind,now,c.phase,c.bend,dt)
  local distance=(Vector3.new(position.X,c.root.Y,position.Z)-c.root).Magnitude
  local fade=math.clamp((distance-radius+4)/4,0,1)
  for _,b in ipairs(c.blades) do
   b.part.Transparency=fade table.insert(parts,b.part) table.insert(frames,Motion.frame(b.root,b.height,b.yaw,c.bend))
  end
 end
 foliageTimer+=dt
 if foliageTimer>=.1 then
  foliageTimer=0 local moved=0
  for p,rest in pairs(foliage) do
   if p.Parent and (rest.Position-position).Magnitude<105 and moved<200 then
    local strength=(p:GetAttribute("SerenaWindStrength") or .04)*math.clamp(wind.Magnitude/6,.5,2.2)
    local angle=math.sin(now*1.15+rest.X*.065+rest.Z*.07)*strength
    table.insert(parts,p) table.insert(frames,rest*CFrame.Angles(angle*.4,0,angle)) moved+=1
   end
  end
  for p,rest in pairs(scenery) do
   if p.Parent and (rest.Position-position).Magnitude<140 then
    local pivot=CFrame.new(118,.25+math.sin(now*1.7)*.11,324)*CFrame.Angles(math.sin(now*.83)*.009,0,math.cos(now*.73)*.012)
    table.insert(parts,p) table.insert(frames,pivot*CFrame.new(-118,-.25,-324)*rest)
   end
  end
 end
 if #parts>0 then workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged) end
end
RunService.Heartbeat:Connect(function(dt)
 timer+=dt if timer<1/24 then return end
 local step=math.min(timer,.15) timer=0 animate(step)
end)
script.Destroying:Connect(function()folder:Destroy()end)
]========])

source(SPS,"LocalScript","SerenaShopClient",[========[local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local rules=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("ItemRules"))
local remote=RS:WaitForChild("SerenaShop")
local gui=Instance.new("ScreenGui") gui.Name="SerenaShopUI" gui.ResetOnSpawn=false gui.DisplayOrder=15 gui.Parent=player:WaitForChild("PlayerGui")
local cream=Color3.fromRGB(243,239,219) local muted=Color3.fromRGB(173,190,173) local green=Color3.fromRGB(76,118,87)
local function round(o,r)local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 12) c.Parent=o end
local function text(parent,label,size,color)
 local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Text=label l.TextColor3=color or cream l.Font=Enum.Font.GothamMedium l.TextSize=size l.TextWrapped=true l.Parent=parent return l
end
local open=Instance.new("TextButton") open.Name="OpenShop" open.Size=UDim2.fromOffset(156,42) open.AnchorPoint=Vector2.new(1,0) open.Position=UDim2.new(1,-16,0,14)
open.BackgroundColor3=Color3.fromRGB(36,57,47) open.TextColor3=cream open.Text="LOJA  ·  — moedas" open.TextSize=13 open.Font=Enum.Font.GothamMedium open.Parent=gui round(open)
local panel=Instance.new("Frame") panel.Name="ShopPanel" panel.Size=UDim2.new(.9,0,0,418) panel.AnchorPoint=Vector2.new(.5,.5) panel.Position=UDim2.fromScale(.5,.5)
panel.BackgroundColor3=Color3.fromRGB(26,42,36) panel.BackgroundTransparency=.03 panel.Visible=false panel.Parent=gui round(panel,20)
local constraint=Instance.new("UISizeConstraint") constraint.MaxSize=Vector2.new(354,418) constraint.MinSize=Vector2.new(260,330) constraint.Parent=panel
local scale=Instance.new("UIScale") scale.Parent=panel
local stroke=Instance.new("UIStroke") stroke.Color=Color3.fromRGB(106,136,110) stroke.Transparency=.55 stroke.Parent=panel
local title=text(panel,"Feira da ilha",22) title.Size=UDim2.new(1,-70,0,40) title.Position=UDim2.fromOffset(22,15) title.TextXAlignment=Enum.TextXAlignment.Left
local close=Instance.new("TextButton") close.Name="CloseShop" close.Text="×" close.TextSize=27 close.TextColor3=cream close.Font=Enum.Font.Gotham close.BackgroundTransparency=1 close.Size=UDim2.fromOffset(42,42) close.Position=UDim2.new(1,-50,0,12) close.Parent=panel
local subtitle=text(panel,"Itens reutilizáveis · moedas da ilha",12,muted) subtitle.Position=UDim2.fromOffset(22,54) subtitle.Size=UDim2.new(1,-44,0,20) subtitle.TextXAlignment=Enum.TextXAlignment.Left
local viewport=Instance.new("ViewportFrame") viewport.BackgroundColor3=Color3.fromRGB(39,59,46) viewport.Size=UDim2.new(1,-44,0,134) viewport.Position=UDim2.fromOffset(22,85)
viewport.Ambient=Color3.fromRGB(192,192,192) viewport.LightColor=Color3.fromRGB(255,244,213) viewport.LightDirection=Vector3.new(-1,-1,-1) viewport.Parent=panel round(viewport,14)
local wm=Instance.new("WorldModel") wm.Parent=viewport
local preview=RS.SerenaRuntime:WaitForChild("ApplePreview"):Clone() preview.Parent=wm
local camera=Instance.new("Camera") camera.FieldOfView=35 camera.Parent=viewport viewport.CurrentCamera=camera
local itemTitle=text(panel,"Maçã da Névoa",19) itemTitle.Size=UDim2.new(1,-44,0,28) itemTitle.Position=UDim2.fromOffset(22,226)
local description=text(panel,"Fique invisível por 3 segundos.\nUse novamente após 60 segundos.",13,muted) description.Size=UDim2.new(1,-44,0,42) description.Position=UDim2.fromOffset(22,259)
local button=Instance.new("TextButton") button.Name="AppleAction" button.Size=UDim2.new(1,-44,0,45) button.Position=UDim2.fromOffset(22,311)
button.BackgroundColor3=green button.TextColor3=cream button.TextSize=15 button.Font=Enum.Font.GothamBold button.Text="Comprar · 30 moedas" button.Parent=panel round(button,12)
local note=text(panel,"50 moedas iniciais · +10 por minuto",11,muted) note.Size=UDim2.new(1,-38,0,43) note.Position=UDim2.fromOffset(19,365)
local toast=text(gui,"",13) toast.BackgroundColor3=Color3.fromRGB(32,50,41) toast.BackgroundTransparency=1 toast.TextTransparency=1 toast.AnchorPoint=Vector2.new(.5,0)
toast.Size=UDim2.new(.85,0,0,46) toast.Position=UDim2.new(.5,0,0,65) round(toast)
local toastSize=Instance.new("UISizeConstraint") toastSize.MaxSize=Vector2.new(420,46) toastSize.Parent=toast
local pending=false local pendingUntil=0 local toastId=0
local function refresh()
 local owned=player:GetAttribute("SerenaAppleOwned")==true local ready=player:GetAttribute("SerenaShopReady")==true
 local coins=player:GetAttribute("SerenaCoins") or 0
 local now=workspace:GetServerTimeNow() local cooldown=math.max(0,math.ceil((player:GetAttribute("SerenaAppleReadyAt") or 0)-now))
 local invisible=math.max(0,math.ceil((player:GetAttribute("SerenaInvisibleUntil") or 0)-now))
 if pending and now>=pendingUntil then pending=false end
 open.Text="LOJA  ·  "..(ready and tostring(coins) or "—").." moedas"
 if not ready then button.Text="Carregando moedas…"
 elseif pending then button.Text="Aguarde…"
 elseif invisible>0 then button.Text="Invisível · "..invisible.." s"
 elseif owned and cooldown>0 then button.Text="Disponível em "..cooldown.." s"
 elseif owned then button.Text="Usar maçã · invisibilidade"
 else button.Text="Comprar · 30 moedas" end
 local enabled=ready and not pending and (not owned or cooldown==0)
 button.Active=enabled button.AutoButtonColor=enabled button.BackgroundColor3=enabled and green or Color3.fromRGB(61,75,64)
 note.Text=ready and player:GetAttribute("SerenaDataSaved")==false and "Progresso temporário nesta sessão.\n+10 moedas por minuto na ilha." or "50 moedas iniciais · +10 por minuto\nA maçã fica na sua mochila."
 local cam=workspace.CurrentCamera if cam then scale.Scale=math.clamp((cam.ViewportSize.Y-90)/418,.35,1) end
end
open.Activated:Connect(function()panel.Visible=not panel.Visible refresh()end)
close.Activated:Connect(function()panel.Visible=false end)
button.Activated:Connect(function()
 if not button.Active then return end
 pending=true pendingUntil=workspace:GetServerTimeNow()+8
 remote:FireServer(player:GetAttribute("SerenaAppleOwned") and "UseApple" or "BuyApple") refresh()
end)
remote.OnClientEvent:Connect(function(kind,message,ok)
 if kind=="Open" then panel.Visible=true refresh() return end
 if kind~="Message" then return end
 pending=false toastId+=1 local token=toastId toast.Text=message toast.TextColor3=ok and cream or Color3.fromRGB(255,205,180)
 toast.BackgroundTransparency=.08 toast.TextTransparency=0 refresh()
 task.delay(3.5,function()if toastId==token then TweenService:Create(toast,TweenInfo.new(.5),{TextTransparency=1,BackgroundTransparency=1}):Play() end end)
end)
for _,name in ipairs({"SerenaCoins","SerenaAppleOwned","SerenaShopReady","SerenaAppleReadyAt","SerenaInvisibleUntil","SerenaDataSaved"}) do player:GetAttributeChangedSignal(name):Connect(refresh) end
local elapsed=0 local angle=0
RunService.RenderStepped:Connect(function(dt)
 elapsed+=dt if elapsed>.2 then elapsed=0 refresh() end
 if panel.Visible then angle+=dt*.35 camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(angle)*3.4,1.65,math.cos(angle)*3.4),Vector3.new(0,.2,0)) end
end)
refresh()
]========])

run([========[local Lighting=game:GetService("Lighting") local world=workspace:WaitForChild("IlhaSerena")
local sky=Lighting:FindFirstChild("SerenaSky") assert(sky,"Missing sky")
-- These six faces were extracted from HD Sky Realistic (11808837483) using
-- AssetService:LoadAssetAsync. Only texture references are kept, never model scripts.
local faces={
 SkyboxBk="rbxassetid://1084532042",SkyboxDn="rbxassetid://1084533114",
 SkyboxFt="rbxassetid://1084532530",SkyboxLf="rbxassetid://1084532285",
 SkyboxRt="rbxassetid://1084531839",SkyboxUp="rbxassetid://1084532776"
}
for name,texture in pairs(faces)do sky[name]=texture end
sky.CelestialBodiesShown=true sky.StarCount=2500 sky.SunAngularSize=8.5 sky.MoonAngularSize=8
world:SetAttribute("SkyPackImported",true) world:SetAttribute("SkyPackAsset",11808837483)
Lighting.GeographicLatitude=23 Lighting.GlobalShadows=true
local Climate=require(game.ReplicatedStorage.SerenaRuntime.Climate)
world:SetAttribute("RenderingBootstrap",2) world:SetAttribute("NativeRealisticLightingApplied",Climate.rendering(Lighting))
local p=Climate.profile(9.25,0,1,0) p.hour=9.25 Climate.apply(Lighting,workspace.Terrain,p)
world:SetAttribute("DayLength",Climate.DayLength)
world:SetAttribute("ClockStart",nil) world:SetAttribute("WeatherChanged",nil)
world:SetAttribute("Weather","Sol") world:SetAttribute("PreviousWeather","Sol")
]========])

local sceneReport=run([========[local world=workspace.IlhaSerena local RS=game.ReplicatedStorage
local Climate=require(RS.SerenaRuntime.Climate) local Motion=require(RS.SerenaRuntime.GrassMotion) local Rules=require(RS.SerenaRuntime.ItemRules)
local terrain=workspace.Terrain
local groundRay=RaycastParams.new() groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={terrain} groundRay.IgnoreWater=true
local walkRay=RaycastParams.new() walkRay.FilterType=Enum.RaycastFilterType.Include walkRay.FilterDescendantsInstances={terrain,world} walkRay.IgnoreWater=true walkRay.RespectCanCollide=true
local function height(x,z,params)
 local h=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-240,0),params or groundRay) assert(h,"Missing floor") return h.Position.Y,h
end
local overlap=OverlapParams.new() overlap.FilterType=Enum.RaycastFilterType.Include overlap.FilterDescendantsInstances={world} overlap.RespectCanCollide=true
local routeSamples=0
for _,route in ipairs(require(RS.SerenaRuntime.Routes))do for i=1,#route.points-1 do
 local a,b=route.points[i],route.points[i+1]
 for n=0,6 do
  local t=n/6 local x,z=a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t local hint=a[3]+(b[3]-a[3])*t
  local hit=workspace:Raycast(Vector3.new(x,hint+8,z),Vector3.new(0,-24,0),walkRay)
  assert(hit,"Route floor missing: "..route.name)
  local blockers=workspace:GetPartBoundsInBox(CFrame.new(x,hit.Position.Y+3.3,z),Vector3.new(3,5,3),overlap)
  assert(#blockers==0,"Route obstruction: "..route.name.." at "..x..","..z..":"..(#blockers>0 and blockers[1]:GetFullName() or ""))
  routeSamples+=1
 end
end end
local spawn=world:GetAttribute("SpawnCF")
local blockers=workspace:GetPartBoundsInBox(spawn,Vector3.new(3,5,3),overlap) assert(#blockers==0,"Spawn blocked")
local trees=0 local maxTreeGap=-math.huge
for _,m in ipairs(world:GetDescendants()) do if m:IsA("Model") and (m.Name=="Árvore" or m.Name=="Palmeira") then
 local base
 for _,p in ipairs(m:GetChildren()) do if p:IsA("BasePart") and (p.Name=="Tronco" or p.Name=="TroncoCurvo") then
  local a=p.CFrame:PointToWorldSpace(Vector3.new(-p.Size.X/2,0,0)) local b=p.CFrame:PointToWorldSpace(Vector3.new(p.Size.X/2,0,0)) local q=a.Y<b.Y and a or b
  if not base or q.Y<base.Y then base=q end
 end end
 assert(base,"No trunk") local gap=base.Y-height(base.X,base.Z)
 assert(gap<-.5 and gap> -1.1,"Tree floats or excessively buried: "..gap) maxTreeGap=math.max(maxTreeGap,gap)
 local roots=0 for _,p in ipairs(m:GetChildren()) do if p.Name=="RaizEnterrada" then roots+=1 end end assert(roots==4,"Root detail missing") trees+=1
end end
assert(trees==111,"Tree count changed")
local bridgeSamples=0 local maxGrade=0 local minBankClearance=math.huge
for _,z in ipairs({70,124}) do
 local m=world.TrilhasEMirante:FindFirstChild("Ponte"..z) local left,right=m:GetAttribute("SpanLeft"),m:GetAttribute("SpanRight")
 local lastY local lastX local lastName
 for x=left-7,right+7,1 do
  local y,hit=height(x,z,walkRay)
  if lastY then local grade=math.abs(y-lastY)/(x-lastX) maxGrade=math.max(maxGrade,grade) assert(grade<.42,"Bridge lip or steep entrance at "..z..","..x..":"..grade.."; hit="..hit.Instance:GetFullName().."; previous="..lastName) end
  lastY=y lastX=x lastName=hit.Instance:GetFullName()
  local blockers=workspace:GetPartBoundsInBox(CFrame.new(x,y+3.2,z),Vector3.new(3,5,3),overlap)
  assert(#blockers==0,"Blocked bridge at "..z..","..x..":"..(#blockers>0 and blockers[1].Name or ""))
  if x>left+.2 and x<right-.2 then
   assert(hit.Instance:IsDescendantOf(m),"Terrain overtakes bridge deck")
   for _,dz in ipairs({-3.2,3.2}) do
    local top,h=height(x,z+dz,walkRay) local floorY=height(x,z+dz)
    minBankClearance=math.min(minBankClearance,top-floorY)
    assert(h.Instance:IsDescendantOf(m),"Bridge edge buried in terrain at "..z..","..x..","..dz.."; surface="..top..",soil="..floorY)
   end
  end
  bridgeSamples+=1
 end
 local pilings=0 for _,d in ipairs(m:GetChildren())do if d.Name=="EstacaEnterrada" then pilings+=1 end end assert(pilings==8,"Bridge support missing")
end
-- Grounded grass roots, contact response, recovery, and no contact through a roof.
local base=Vector3.new(2,10,3) local bend=Vector3.zero
for _=1,24 do bend=Motion.bend(base,{{position=Vector3.new(1,13,3),feet=10,velocity=Vector3.new(16,0,0)}},Vector3.zero,1,0,bend,1/24) end
assert(bend.X>.45,"Grass does not bend away from walker")
local frame=Motion.frame(base,1.1,0,bend) local root=frame:PointToWorldSpace(Vector3.new(0,-.55,0)) assert((root-base).Magnitude<.001,"Grass root slides")
local unrelated=Motion.bend(base,{{position=Vector3.new(1,30,3),feet=27,velocity=Vector3.new(16,0,0)}},Vector3.zero,1,0,Vector3.zero,.1)
assert(unrelated.Magnitude<.001,"Grass bends through a floor")
for _=1,72 do bend=Motion.bend(base,{},Vector3.zero,1,0,bend,1/24)end assert(bend.Magnitude<.005,"Grass never recovers")
local wind=Motion.bend(base,{},Vector3.new(6,0,2),1,0,Vector3.zero,.1) assert(wind.Magnitude>.03,"Wind does not move grass")
-- Climate remains usable in every phase and weather, with a continuous transition.
local climates=0
for _,hour in ipairs({0,5.5,8,14,17.7,19.2,22})do for _,state in ipairs({"Sol","Nublado","Chuva"})do
 local rain,clear=Climate.weights(18,0,state,state) local p=Climate.profile(hour,rain,clear,1) p.hour=hour
 assert(p.brightness>=.8 and p.brightness<4 and p.waveSize>0 and p.waveSize<.5 and p.cover<=1,"Climate bounds")
 Climate.apply(game.Lighting,terrain,p) climates+=1
end end
local a,b=Climate.weights(0,0,"Sol","Chuva") assert(a==0 and b==1,"Weather jumps at transition start")
local c,d=Climate.weights(9,0,"Sol","Chuva") assert(math.abs(c-.5)<.001 and math.abs(d-.5)<.001,"Weather does not blend")
local e,f=Climate.weights(18,0,"Sol","Chuva") assert(e==1 and f==0,"Weather never reaches target")
assert(math.abs(Climate.hour(1800,0)-9.25)<.001,"Day wrap")
local p=Climate.profile(9.25,0,1,0) p.hour=9.25 Climate.apply(game.Lighting,terrain,p)
local tool=game.ServerStorage.SerenaItems["Maçã da Névoa"] assert(tool:IsA("Tool") and not tool.Handle.Anchored,"Item cannot be equipped")
for _,p in ipairs(tool:GetChildren())do if p:IsA("BasePart") then assert(not p.CanCollide and p.Massless,"Item blocks avatar movement") if p.Name~="Handle" then assert(p:FindFirstChildOfClass("WeldConstraint"),"Loose apple part")end end end
local partCount=0
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart") then assert(p.Anchored,"Unanchored scenery") partCount+=1 end assert(not p:IsA("LuaSourceContainer"),"Unexpected world script")end
assert(partCount<6500,"Scene budget exceeded")
-- Compile every saved runtime source before publication.
local compiled=0
for _,container in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do
 for _,s in ipairs(container:GetChildren())do if s:IsA("Script") or s:IsA("LocalScript") then
  local m=Instance.new("ModuleScript") m.Source="return function()\n"..s.Source.."\nend" m.Parent=game.ServerStorage
  local ok,result=pcall(require,m) m:Destroy() assert(ok,s.Name..":"..tostring(result)) compiled+=1
 end end
end
return {treesGrounded=trees,maxTrunkGap=maxTreeGap,treesRelocated=world:GetAttribute("TreesRelocatedForAccess"),bridgeSamples=bridgeSamples,routeSamples=routeSamples,maxBridgeGrade=maxGrade,minDeckClearance=minBankClearance,grassContactAndRecovery=true,climateCases=climates,compiledScripts=compiled,parts=partCount,skyPackImported=world:GetAttribute("SkyPackImported")}
]========])

local itemReport=run([========[-- Runs the actual saved shop server against deterministic players, storage and time.
local function signal()
 local handlers={} local s={}
 function s:Connect(fn)table.insert(handlers,fn) return {Disconnect=function()end}end
 function s:Fire(...)for _,fn in ipairs(handlers)do fn(...)end end
 return s
end
local now=1000000 local pending={} local waiters={} local clients={}
local scheduled={}
local fakeTask={}
local function resume(co,...)
 local ok,delay=coroutine.resume(co,...); assert(ok,tostring(delay))
 if coroutine.status(co)~="dead" then table.insert(waiters,{co=co,at=now+(delay or 0)}) end
end
function fakeTask.spawn(fn,...)local co=coroutine.create(fn) resume(co,...) return co end
function fakeTask.delay(delay,fn,...)table.insert(scheduled,{at=now+delay,fn=fn,args=table.pack(...)})end
function fakeTask.wait(delay)return coroutine.yield(delay or 0)end
local function advance(seconds)
 local target=now+seconds local iterations=0
 while true do
  local soon=math.huge local kind,index
  for i,t in ipairs(waiters)do if t.at<soon then soon=t.at kind="wait" index=i end end
  for i,t in ipairs(scheduled)do if t.at<soon then soon=t.at kind="delay" index=i end end
  if soon>target then break end
  now=soon iterations+=1 assert(iterations<1000,"Scheduler stalled")
  if kind=="wait" then local item=table.remove(waiters,index) resume(item.co)
  else local item=table.remove(scheduled,index) fakeTask.spawn(item.fn,table.unpack(item.args,1,item.args.n)) end
 end
 now=target
end
local sandbox=Instance.new("Folder") sandbox.Name="SerenaShopValidation" sandbox.Parent=game.ServerStorage
local function dummy(name)
 local c=Instance.new("Model") c.Name=name c.Parent=sandbox
 for _,n in ipairs({"HumanoidRootPart","Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg"}) do
  local p=Instance.new("Part") p.Name=n p.Size=Vector3.new(2,2,1) p.Anchored=true p.CanCollide=false p.Transparency=n=="HumanoidRootPart" and 1 or (n=="Head" and .15 or 0) p.Parent=c
 end
 local face=Instance.new("Decal") face.Name="Face" face.Transparency=.25 face.Parent=c.Head
 local h=Instance.new("Humanoid") h.RigType=Enum.HumanoidRigType.R6 h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer h.Parent=c
 local accessory=Instance.new("Accessory") accessory.Name="Hat" accessory.Parent=c
 local handle=Instance.new("Part") handle.Name="Handle" handle.Transparency=.4 handle.Anchored=true handle.Parent=accessory
 local smoke=Instance.new("ParticleEmitter") smoke.Enabled=true smoke.Parent=handle
 local light=Instance.new("PointLight") light.Enabled=true light.Parent=handle
 local surface=Instance.new("SurfaceGui") surface.Enabled=true surface.Parent=handle
 local field=Instance.new("ForceField") field.Visible=true field.Parent=c
 return c
end
local players={PlayerAdded=signal(),PlayerRemoving=signal()}
local people={}
function players:GetPlayers()return people end
local function newPlayer(id)
 local backpack=Instance.new("Backpack") backpack.Parent=sandbox
 local p={UserId=id,Name="Test"..id,Parent=players,Character=dummy("Character"..id),CharacterAdded=signal(),attributes={},backpack=backpack}
 function p:SetAttribute(k,v)self.attributes[k]=v end
 function p:GetAttribute(k)return self.attributes[k]end
 function p:FindFirstChildOfClass(k)if k=="Backpack" then return backpack end end
 function p:WaitForChild(k)if k=="Backpack" then return backpack end error(k)end
 table.insert(people,p) return p
end
local p=newPlayer(1001)
local database={} local fail=false local writeCount=0
local store={}
function store:UpdateAsync(key,callback)
 if fail then error("Intentional storage failure")end
 writeCount+=1 local value=callback(database[key]) database[key]=table.clone(value) return table.clone(value)
end
local ds={} function ds:GetDataStore(name)assert(name=="SerenaItems_v1")return store end
local remote={OnServerEvent=signal()}
function remote:FireClient(who,kind,message,ok)table.insert(clients,{p=who,kind=kind,text=message,ok=ok})end
local rs={} function rs:WaitForChild(name)if name=="SerenaShop" then return remote end return game.ReplicatedStorage:WaitForChild(name)end
local services={Players=players,ReplicatedStorage=rs,ServerStorage=game.ServerStorage,DataStoreService=ds}
local fakeGame={} function fakeGame:GetService(name)return services[name] or game:GetService(name)end
local ws={} function ws:GetServerTimeNow()return now end function ws:WaitForChild(name)return workspace:WaitForChild(name)end
local env={game=fakeGame,workspace=ws,script={Parent=game.ServerScriptService},task=fakeTask,os={clock=function()return now end}}
local source=game.ServerScriptService.SerenaShopServer.Source
local module=Instance.new("ModuleScript") module.Name="RunActualShopServer" module.Source="return function(__env)\nlocal game=__env.game local workspace=__env.workspace local script=__env.script local task=__env.task local os=__env.os\n"..source.."\nend" module.Parent=sandbox
require(module)(env)
assert(p:GetAttribute("SerenaShopReady")==true and p:GetAttribute("SerenaCoins")==50,"Initial balance")
remote.OnServerEvent:Fire(p,"Award") assert(p:GetAttribute("SerenaCoins")==50,"Client reward exploit")
remote.OnServerEvent:Fire(p,"BuyApple")
assert(p:GetAttribute("SerenaCoins")==20 and p:GetAttribute("SerenaAppleOwned")==true,"Purchase transaction")
local item=p.backpack:FindFirstChild("Maçã da Névoa") assert(item and item:IsA("Tool"),"Real inventory item")
advance(.4) remote.OnServerEvent:Fire(p,"BuyApple") assert(p:GetAttribute("SerenaCoins")==20,"Duplicate charge")
advance(.4) remote.OnServerEvent:Fire(p,"UseApple")
assert(p.Character:GetAttribute("SerenaInvisible")==true,"Invisibility not applied")
assert(p.Character.Head.Transparency==1 and p.Character.Hat.Handle.Transparency==1 and p.Character.Head.Face.Transparency==1,"Body/accessory/face remain visible")
assert(p.Character.Humanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None,"Name remains visible")
assert(p.Character.Hat.Handle.ParticleEmitter.Enabled==false,"Particle effect remains visible")
assert(p.Character.Hat.Handle.PointLight.Enabled==false and p.Character.Hat.Handle.SurfaceGui.Enabled==false and p.Character.ForceField.Visible==false,"Accessory light or overlay remains visible")
local nextAt=p:GetAttribute("SerenaAppleReadyAt") assert(math.abs(nextAt-now-60)<.001,"60 second cooldown")
local added=Instance.new("Part") added.Name="LateAccessory" added.Transparency=.3 added.Parent=p.Character
assert(added.Transparency==1,"Late accessory remains visible")
advance(2.99) assert(p.Character.Head.Transparency==1,"Effect ended before three seconds")
advance(.02)
assert(p.Character:GetAttribute("SerenaInvisible")==false,"Effect did not end")
assert(math.abs(p.Character.Head.Transparency-.15)<.0001 and math.abs(p.Character.Hat.Handle.Transparency-.4)<.0001 and math.abs(p.Character.Head.Face.Transparency-.25)<.0001,"Original transparency not restored")
assert(p.Character.HumanoidRootPart.Transparency==1,"Hidden root became visible")
assert(math.abs(added.Transparency-.3)<.0001 and p.Character.Hat.Handle.ParticleEmitter.Enabled==true,"Late property restoration")
assert(p.Character.Humanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer,"Name not restored")
assert(p.Character.Hat.Handle.PointLight.Enabled==true and p.Character.Hat.Handle.SurfaceGui.Enabled==true and p.Character.ForceField.Visible==true,"Accessory light or overlay not restored")
advance(.4) remote.OnServerEvent:Fire(p,"UseApple") assert(p.Character:GetAttribute("SerenaInvisible")==false,"Early reuse allowed")
-- Reset cannot bypass cooldown and cannot alter the replacement avatar.
local old=p.Character p.Character=dummy("Respawn") p.CharacterAdded:Fire(p.Character)
advance(.4) remote.OnServerEvent:Fire(p,"UseApple")
assert(p.Character:GetAttribute("SerenaInvisible")~=true and p:GetAttribute("SerenaAppleReadyAt")==nextAt,"Respawn bypass")
assert(p.backpack:FindFirstChild("Maçã da Névoa") or p.Character:FindFirstChild("Maçã da Névoa"),"Ownership lost at respawn")
advance(nextAt-now-.001) remote.OnServerEvent:Fire(p,"UseApple") assert(p.Character:GetAttribute("SerenaInvisible")~=true,"59.999 second cooldown bypass")
advance(.401) remote.OnServerEvent:Fire(p,"UseApple") assert(p.Character:GetAttribute("SerenaInvisible")==true,"Ready item unusable")
assert(p:GetAttribute("SerenaCoins")==30,"Server timed reward failed")
p.Parent=nil players.PlayerRemoving:Fire(p)
assert(p.Character:GetAttribute("SerenaInvisible")==false and p.Character.Head.Transparency<1,"Disconnect cleanup")
-- A second account owns its balance; failing persistence must not charge a purchase.
local q=newPlayer(1002) players.PlayerAdded:Fire(q) assert(q:GetAttribute("SerenaCoins")==50,"Independent balance")
fail=true advance(.4) remote.OnServerEvent:Fire(q,"BuyApple")
assert(q:GetAttribute("SerenaCoins")==50 and q:GetAttribute("SerenaAppleOwned")==false and not q.backpack:FindFirstChild("Maçã da Névoa"),"Failed save charged buyer")
fail=false advance(.4) remote.OnServerEvent:Fire(q,"BuyApple") assert(q:GetAttribute("SerenaCoins")==20,"Retry purchase")
database.u1003={coins=5,apple=false,nextAppleAt=0}
local r=newPlayer(1003) players.PlayerAdded:Fire(r) advance(.4) remote.OnServerEvent:Fire(r,"BuyApple")
assert(r:GetAttribute("SerenaCoins")==5 and not r:GetAttribute("SerenaAppleOwned"),"Insufficient funds accepted")
sandbox:Destroy()
return {actualServer=true,initialBalance=50,price=30,threeSecondEffect=true,sixtySecondCooldown=true,respawnSafe=true,restoreAccessoryProperties=true,noClientCoinClaim=true,noDuplicateCharge=true,saveFailureSafe=true,serverMinuteReward=10,storageWrites=writeCount}
]========])

local clientReport=run([========[-- Executes saved client code with native scene/UI objects and simulated input signals.
local function signal()
 local callbacks={} local s={}
 function s:Connect(fn)table.insert(callbacks,fn)return {Disconnect=function()end}end
 function s:Fire(...)for _,fn in ipairs(callbacks)do fn(...)end end
 return s
end
local SS=game.ServerStorage local RS=game.ReplicatedStorage local SPS=game.StarterPlayer.StarterPlayerScripts
local sandbox=Instance.new("Folder") sandbox.Name="SerenaClientValidation" sandbox.Parent=SS
local gui=Instance.new("Folder") gui.Name="SimulatedPlayerGui" gui.Parent=sandbox
local char=Instance.new("Model") char.Parent=sandbox
local root=Instance.new("Part") root.Name="HumanoidRootPart" root.Anchored=true root.CanCollide=false root.Size=Vector3.new(2,2,1) root.Parent=char
local h=Instance.new("Humanoid") h.RigType=Enum.HumanoidRigType.R6 h.Parent=char
local changes={} local attrs={SerenaCoins=50,SerenaAppleOwned=false,SerenaShopReady=true,SerenaDataSaved=true}
local p={Character=char,CharacterAdded=signal()}
function p:WaitForChild(name)assert(name=="PlayerGui")return gui end
function p:GetAttribute(name)return attrs[name]end
function p:GetAttributeChangedSignal(name)changes[name]=changes[name] or signal()return changes[name]end
function p:SetAttribute(name,value)attrs[name]=value if changes[name] then changes[name]:Fire()end end
local players={LocalPlayer=p} function players:GetPlayers()return {p}end
local run={RenderStepped=signal(),Heartbeat=signal()}
local remote={OnClientEvent=signal(),sent={}}
function remote:FireServer(action)table.insert(self.sent,action)end
local rsProxy={SerenaRuntime=RS.SerenaRuntime}
function rsProxy:WaitForChild(name)if name=="SerenaShop" then return remote end return RS:WaitForChild(name)end
local touch={TouchEnabled=false}
local services={Players=players,RunService=run,ReplicatedStorage=rsProxy,UserInputService=touch}
local fakeGame={ReplicatedStorage=rsProxy} function fakeGame:GetService(name)return services[name] or game:GetService(name)end
local bindings={} local scriptProxy={Destroying=signal()}
local function loadClient(name,source,bind)
 local module=Instance.new("ModuleScript") module.Name="ClientTest_"..name
 module.Source="return function(__env)\nlocal game=__env.game local script=__env.script local task=__env.task\n"..source.."\nend" module.Parent=sandbox
 require(module)({game=fakeGame,script=scriptProxy,bind=bind or function()end,task={delay=function()end,spawn=function(fn,...)fn(...)end}})
end
local shop=SPS.SerenaShopClient.Source
for _,name in ipairs({"open","close","button"})do shop=shop:gsub(name.."%.Activated:Connect%(","__env.bind("..name..",")end
loadClient("Shop",shop,function(button,fn)bindings[button]=fn end)
local screen=gui.SerenaShopUI local panel=screen.ShopPanel local button=panel.AppleAction
assert(button.Text=="Comprar · 30 moedas" and button.Active,"Initial shop view")
bindings[screen.OpenShop]() assert(panel.Visible,"Shop does not open")
bindings[button]() assert(remote.sent[#remote.sent]=="BuyApple","Purchase button sends wrong action")
p:SetAttribute("SerenaCoins",20) p:SetAttribute("SerenaAppleOwned",true) remote.OnClientEvent:Fire("Message","Comprada",true)
assert(button.Text=="Usar maçã · invisibilidade" and screen.OpenShop.Text:find("20 moedas",1,true),"Purchase UI does not update")
p:SetAttribute("SerenaAppleReadyAt",workspace:GetServerTimeNow()+60)
assert(not button.Active and button.Text:find("Disponível em",1,true),"Cooldown button stays enabled")
p:SetAttribute("SerenaAppleReadyAt",0) bindings[button]() assert(remote.sent[#remote.sent]=="UseApple","Use button sends wrong action")
remote.OnClientEvent:Fire("Message","Invisível",true)
p:SetAttribute("SerenaInvisibleUntil",workspace:GetServerTimeNow()+3)
assert(button.Text:find("Invisível",1,true),"Invisibility UI missing")
p:SetAttribute("SerenaInvisibleUntil",0) p:SetAttribute("SerenaDataSaved",false)
run.RenderStepped:Fire(.21)
local viewport=panel:FindFirstChildOfClass("ViewportFrame") assert(viewport and viewport.CurrentCamera and viewport:FindFirstChildOfClass("WorldModel"),"3D apple preview missing")
bindings[panel.CloseShop]() assert(not panel.Visible,"Shop does not close")
-- Find a genuine grass surface to exercise placement and movement on the native terrain.
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain} ray.IgnoreWater=false
local spot
for x=-230,-140,15 do for z=-10,55,15 do
 local hit=workspace:Raycast(Vector3.new(x,150,z),Vector3.new(0,-200,0),ray)
 if hit and hit.Material==Enum.Material.Grass and hit.Normal.Y>.8 then spot=hit.Position break end
end if spot then break end end assert(spot,"No grass surface for client test")
root.CFrame=CFrame.new(spot+Vector3.new(0,3,0))
local budgets={}
for _,mobile in ipairs({false,true})do
 touch.TouchEnabled=mobile run.Heartbeat=signal() scriptProxy={Destroying=signal()}
 loadClient(mobile and "GrassMobile" or "GrassDesktop",SPS.SerenaGrassClient.Source)
 for _=1,45 do run.Heartbeat:Fire(1/24)end
 local grass=workspace:FindFirstChild("SerenaInteractiveGrass") assert(grass,"Grass renderer did not start")
 local count=#grass:GetChildren() assert(count>30 and count<=(mobile and 555 or 975),"Grass population or budget")
 local first=grass:GetChildren()[1] local before=first.CFrame
 for _=1,6 do run.Heartbeat:Fire(1/24)end
 assert((before.Position-first.Position).Magnitude>.00001 or before.Rotation~=first.CFrame.Rotation,"Grass stays static")
 for _,b in ipairs(grass:GetChildren())do assert(b.Anchored and not b.CanCollide and not b.CanQuery,"Grass interferes with walking")end
 table.insert(budgets,{mobile=mobile,blades=count}) scriptProxy.Destroying:Fire()
end
-- Actual rain/time startup and native fountain droplets.
run.RenderStepped=signal() scriptProxy={Destroying=signal()}
local oldCamera=workspace.CurrentCamera local cameraCF=oldCamera and oldCamera.CFrame
loadClient("Ambience",SPS.SerenaAmbienceClient.Source)
local w=workspace.IlhaSerena local oldStart=w:GetAttribute("ClockStart")
w:SetAttribute("ClockStart",workspace:GetServerTimeNow()) w:SetAttribute("WeatherChanged",workspace:GetServerTimeNow()-18) w:SetAttribute("PreviousWeather","Sol") w:SetAttribute("Weather","Chuva")
run.RenderStepped:Fire(.13)
local rain=workspace:FindFirstChild("SerenaLocalRain") assert(rain and #rain:GetChildren()>=70,"Rain renderer did not start")
assert(rain:FindFirstChild("GotaDaFonte"),"Fountain droplets missing")
scriptProxy.Destroying:Fire()
w:SetAttribute("ClockStart",oldStart) w:SetAttribute("WeatherChanged",nil) w:SetAttribute("PreviousWeather","Sol") w:SetAttribute("Weather","Sol")
local climate=require(RS.SerenaRuntime.Climate) local profile=climate.profile(9.25,0,1,0) profile.hour=9.25 climate.apply(game.Lighting,workspace.Terrain,profile)
for _,tag in ipairs({"SerenaWindFoliage","SerenaFloatingDetail"})do for _,d in ipairs(game.CollectionService:GetTagged(tag))do if d.Parent then d.CFrame=d:GetAttribute("SerenaRestCF") or d.CFrame end end end
if oldCamera and cameraCF then oldCamera.CFrame=cameraCF end
sandbox:Destroy()
return {actualClientSources=true,shopOpenBuyUseAndCooldown=true,apple3DPreview=true,grassBudgets=budgets,rainAndFountainStarted=true}
]========])

world:SetAttribute("UpgradeVersion",79)
world:SetAttribute("AppleDuration",3) world:SetAttribute("AppleCooldown",60) world:SetAttribute("ApplePrice",30)
game:GetService("AssetService"):SavePlaceAsync()
return {scene=sceneReport,items=itemReport,clients=clientReport,published=true,sourceVersion=game.PlaceVersion}
