local Builder={}
local Collection=game:GetService("CollectionService")
local CFG={Origin=Vector3.new(-180,28.2,30),Mood="Dourado",Ruin=.30,VineDensity=1,Seed=891013,SpawnInCourtyard=true}
local STONE=Color3.fromRGB(208,196,162)local PALE=Color3.fromRGB(225,212,174)
local GREEN=Color3.fromRGB(69,99,47)local PINK=Color3.fromRGB(196,135,159)
local function part(parent,name,size,cf,color,material,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color or STONE p.Material=material or Enum.Material.Limestone
 p.Anchored=true p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local function cylinder(parent,name,diameter,height,cf,color,material,collide)
 local p=part(parent,name,Vector3.new(height,diameter,diameter),cf*CFrame.Angles(0,0,math.pi/2),color,material,collide)p.Shape=Enum.PartType.Cylinder return p
end
local function ball(parent,name,size,cf,color,material)
 local p=part(parent,name,size,cf,color,material,false)p.Shape=Enum.PartType.Ball return p
end
local function line(parent,name,a,b,thickness,color,material)
 return part(parent,name,Vector3.new(thickness,thickness,(b-a).Magnitude+.025),CFrame.lookAt((a+b)*.5,b),color,material,false)
end
function Builder.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime
 assert(not world.Amenities:FindFirstChild("ForestRuins"),"Courtyard already exists")
 local rng=Random.new(CFG.Seed)local origin=CFrame.new(CFG.Origin)
 local function cf(x,y,z)return origin*CFrame.new(x,y,z)end
 local function pos(x,y,z)return cf(x,y,z).Position end
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-320,0),ray)end
 local removed={trees=0,plants=0,rocks=0}
 for _,info in ipairs({{world.Decor.Trees,"trees"},{world.Decor.Plants,"plants"},{world.Decor.RocksAndLogs,"rocks"}})do
  for _,m in ipairs(info[1]:GetChildren())do if m:IsA("Model")then local p=origin:PointToObjectSpace(m:GetPivot().Position)
   if math.abs(p.X)<44 and math.abs(p.Z)<34 then removed[info[2]]+=1 m:Destroy()end
  end end
 end
 local ruins=Instance.new("Model")ruins.Name="ForestRuins"ruins.Parent=world.Amenities ruins:SetAttribute("Origin",CFG.Origin)
 runtime:SetAttribute("RuinOrigin",CFG.Origin)
 ruins:SetAttribute("Mood",CFG.Mood)ruins:SetAttribute("Ruin",CFG.Ruin)ruins:SetAttribute("VineDensity",CFG.VineDensity)ruins:SetAttribute("Seed",CFG.Seed)
 local architecture=Instance.new("Model")architecture.Name="Arcade"architecture.ModelStreamingMode=Enum.ModelStreamingMode.Atomic architecture.Parent=ruins
 local courtyard=Instance.new("Model")courtyard.Name="Courtyard"courtyard.ModelStreamingMode=Enum.ModelStreamingMode.Atomic courtyard.Parent=ruins
 local garden=Instance.new("Folder")garden.Name="Garden"garden.Parent=ruins
 local floor=part(courtyard,"CourtyardFloor",Vector3.new(76,1,56),cf(0,-.5,0),STONE,Enum.Material.Limestone,true)
 -- Deep retaining blocks connect the raised level to the actual terrain; the courtyard has no floating underside.
 for x=-34,34,8 do for z=-24,24,8 do
  local h=assert(ground(CFG.Origin.X+x,CFG.Origin.Z+z))local height=math.max(.4,CFG.Origin.Y-1-h.Position.Y+.30)
  local base=part(courtyard,"Foundation",Vector3.new(8.1,height,8.1),cf(x,-1-height*.5,z),Color3.fromRGB(151,146,123),Enum.Material.Slate,true)
  base:SetAttribute("GroundPoint",h.Position)
 end end
 for x=-34,34,4 do for z=-24,24,4 do
  local tile=part(courtyard,"WornPaving",Vector3.new(3.92,.13,3.92),cf(x,.065,z),STONE:Lerp(Color3.fromRGB(152,157,132),rng:NextNumber(0,.23)),Enum.Material.Limestone,false)
  if rng:NextNumber()<.15 then
   local moss=part(courtyard,"PavingMoss",Vector3.new(rng:NextNumber(.5,2.0),.015,rng:NextNumber(.25,1.4)),cf(x+rng:NextNumber(-1,1),.139,z+rng:NextNumber(-1,1))*CFrame.Angles(0,rng:NextNumber(0,6.28),0),GREEN,Enum.Material.Grass,false)
  end
 end end
 -- Front and rear arcades: eight pillars, six real open semicircular arches.
 local archCount=0 local columns={}
 for _,z in ipairs({-16,-2})do
  for _,x in ipairs({-33,-11,11,33})do
   columns[#columns+1]=Vector3.new(x,0,z)
   part(architecture,"ColumnPlinth",Vector3.new(4.3,.7,4.3),cf(x,.35,z),STONE,Enum.Material.Limestone,true)
   part(architecture,"ColumnBase",Vector3.new(3.65,.35,3.65),cf(x,.88,z),PALE,Enum.Material.Limestone,true)
   cylinder(architecture,"ColumnShaft",2.65,9.6,cf(x,5.8,z),PALE,Enum.Material.Limestone,true)
   for _,y in ipairs({1.3,3.7,6.2,8.7,10.4})do cylinder(architecture,"ColumnMoulding",3.03,.25,cf(x,y,z),STONE,Enum.Material.Limestone,false)end
   part(architecture,"ColumnCapital",Vector3.new(4.1,.65,3.7),cf(x,10.9,z),PALE,Enum.Material.Limestone,true)
  end
  for _,x in ipairs({-22,0,22})do
   local arch=Instance.new("Model")arch.Name="StoneArch"arch.Parent=architecture arch:SetAttribute("OpeningCentre",pos(x,7,z))
   local radius=9.3 local segments=18
   for i=0,segments-1 do
    local angle=(i+.5)*math.pi/segments
    local size=Vector3.new(2*(radius+.9)*math.sin(math.pi/segments/2)+.045,1.65,2.6)
    part(arch,"Voussoir",size,cf(x+radius*math.cos(angle),11.1+radius*math.sin(angle),z)*CFrame.Angles(0,0,angle+math.pi*.5),i==8 and PALE or STONE,Enum.Material.Limestone,true)
   end
   part(arch,"Keystone",Vector3.new(1.65,2.0,2.85),cf(x,20.2,z),PALE,Enum.Material.Limestone,false)
   archCount+=1
  end
 end
 for _,x in ipairs({-33,33})do part(architecture,"SideLintel",Vector3.new(2.9,1.5,17),cf(x,11.3,-9),STONE,Enum.Material.Limestone,true)end
 for _,z in ipairs({-16,-2})do part(architecture,"Cornice",Vector3.new(70,1.1,3.5),cf(0,21,z),PALE,Enum.Material.Limestone,true)end
 -- Roof gaps let sunlight into the walkable hall. Sparse fallen pieces remain outside the entrances.
 local holes=0
 for x=-32,32,8 do for z=-14,-4,5 do
  if rng:NextNumber()<CFG.Ruin then holes+=1 else
   part(architecture,"RoofSlab",Vector3.new(7.8,.55,4.85),cf(x,21.75,z),Color3.fromRGB(112,114,100),Enum.Material.Slate,true)
  end
 end end
 for x=-32,32,8 do part(architecture,"RoofJoist",Vector3.new(.45,.65,16.8),cf(x,21.45,-9),Color3.fromRGB(91,72,54),Enum.Material.Wood,false)end
 local vineSegments=0 local leaves=0
 for _,column in ipairs(columns)do
  local previous=nil
  for i=0,math.floor(22*CFG.VineDensity)do
   local t=i/(22*CFG.VineDensity)local angle=t*math.pi*5+column.X*.07
   local point=pos(column.X+math.cos(angle)*1.48,1.0+t*10.8,column.Z+math.sin(angle)*1.48)
   if previous then line(architecture,"SpiralVine",previous,point,.10,Color3.fromRGB(63,81,37),Enum.Material.Grass)vineSegments+=1 end previous=point
   if i%2==0 then
    for _,side in ipairs({-1,1})do ball(architecture,"VineLeaf",Vector3.new(.46,.095,.83),CFrame.new(point+Vector3.new(side*.22,.04,0))*CFrame.Angles(.2,angle+side*.5,.18*side),GREEN,Enum.Material.Grass)leaves+=1 end
   end
  end
 end
 -- Broken boundary wall, rubble and a fallen column, laid directly onto stone or native ground.
 for x=-34,34,4 do
  if math.abs(x)>7 then
   local rows=rng:NextInteger(1,3)
   for row=1,rows do part(courtyard,"BrokenWall",Vector3.new(3.9,1.3,1.4),cf(x,(row-.5)*1.3,-26),STONE,Enum.Material.Limestone,true)end
  end
 end
 for i=1,14 do
  local x,z=rng:NextNumber(-34,34),rng:NextNumber(-25,-21)
  part(courtyard,"RuinStone",Vector3.new(rng:NextNumber(.7,1.7),.55,rng:NextNumber(.7,1.5)),cf(x,.40,z)*CFrame.Angles(.06,rng:NextNumber(0,6.28),.08),STONE,Enum.Material.Limestone,true)
 end
 cylinder(courtyard,"FallenColumn",2.1,10,cf(28,1.18,-23)*CFrame.Angles(0,0,math.pi/2),PALE,Enum.Material.Limestone,true)
 local seatCount=0
 local function seat(parent,name,position,angle,cushion)
  local s=Instance.new("Seat")s.Name=name s.Size=Vector3.new(2.25,.22,2.1)s.CFrame=CFrame.new(position)*CFrame.Angles(0,angle,0)
  s.Anchored=true s.CanCollide=true s.CanTouch=false s.Color=cushion and PINK or STONE s.Material=cushion and Enum.Material.Fabric or Enum.Material.Limestone s.Parent=parent
  Collection:AddTag(s,"RuinSeat")local prompt=Instance.new("ProximityPrompt")prompt.Name="SitPrompt"prompt.ActionText="Sentar"prompt.ObjectText=cushion and "Banquinho do chá"or "Banco de pedra"prompt.MaxActivationDistance=7 prompt.HoldDuration=.15 prompt.RequiresLineOfSight=false prompt.Parent=s
  seatCount+=1 return s
 end
 for _,x in ipairs({-28,28})do
  local bench=Instance.new("Model")bench.Name="StoneBench"bench.ModelStreamingMode=Enum.ModelStreamingMode.Atomic bench.Parent=architecture
  part(bench,"BenchTop",Vector3.new(7,.45,2.5),cf(x,2.05,-9),PALE,Enum.Material.Limestone,true)
  for _,side in ipairs({-1,1})do part(bench,"BenchSupport",Vector3.new(.75,1.8,2.15),cf(x+side*2.35,.9,-9),STONE,Enum.Material.Limestone,true)seat(bench,"StoneSeat",pos(x+side*1.8,2.40,-9),0,false)end
 end
 local plantTemplate=assert(world.Decor.Plants:FindFirstChild("RhododendronVar01"))
 for _,point in ipairs({Vector2.new(-30,22),Vector2.new(30,22),Vector2.new(-34,-22),Vector2.new(34,-22)})do
  local pot=Instance.new("Model")pot.Name="PottedTopiary"pot.ModelStreamingMode=Enum.ModelStreamingMode.Atomic pot.Parent=garden
  cylinder(pot,"Planter",2.7,1.65,cf(point.X,.825,point.Y),Color3.fromRGB(174,163,135),Enum.Material.Limestone,true)
  cylinder(pot,"PlanterLip",3.05,.22,cf(point.X,1.63,point.Y),STONE,Enum.Material.Limestone,false)
  cylinder(pot,"Soil",2.65,.08,cf(point.X,1.76,point.Y),Color3.fromRGB(73,55,40),Enum.Material.Ground,false)
  local plant=plantTemplate:Clone()plant.Name="LivingTopiary"local _,size=plant:GetBoundingBox()plant:ScaleTo(plant:GetScale()*3.6/size.Y)plant:PivotTo(cf(point.X,1.76,point.Y))
  for _,d in ipairs(plant:GetDescendants())do if d:IsA("BasePart")then d.Anchored=true d.CanCollide=false d.CanQuery=false d.CanTouch=false d:SetAttribute("ForestRestCF",d.CFrame)d:SetAttribute("WindPower",.03)end end
  plant.Parent=pot
 end
 -- The tea setting is ceramic geometry: a round table, open-rim cups, curved handles, teapot, cookies and flowers.
 local tea=Instance.new("Model")tea.Name="TeaCorner"tea.ModelStreamingMode=Enum.ModelStreamingMode.Atomic tea.Parent=ruins
 local teaCentre=Vector3.new(-16,0,-9)
 local function teaCF(x,y,z)return cf(teaCentre.X+x,y,teaCentre.Z+z)end
 cylinder(tea,"TableTop",6.5,.32,teaCF(0,3.05,0),Color3.fromRGB(171,147,113),Enum.Material.Wood,true)
 cylinder(tea,"TablePedestal",.8,2.7,teaCF(0,1.4,0),Color3.fromRGB(118,94,68),Enum.Material.Wood,true)
 cylinder(tea,"TableFoot",2.9,.28,teaCF(0,.14,0),Color3.fromRGB(118,94,68),Enum.Material.Wood,true)
 local function cup(parent,base,name)
  local m=Instance.new("Model")m.Name=name m.Parent=parent
  cylinder(m,"CupBody",.72,.47,base*CFrame.new(0,.235,0),Color3.fromRGB(241,227,222),Enum.Material.SmoothPlastic,false)
  cylinder(m,"Tea",.61,.024,base*CFrame.new(0,.461,0),Color3.fromRGB(115,65,32),Enum.Material.Glass,false)
  for i=0,11 do local a=i*math.pi*2/12 local b=(i+1)*math.pi*2/12
   line(m,"CupRim",base:PointToWorldSpace(Vector3.new(.35*math.cos(a),.49,.35*math.sin(a))),base:PointToWorldSpace(Vector3.new(.35*math.cos(b),.49,.35*math.sin(b))),.052,Color3.fromRGB(224,188,160),Enum.Material.SmoothPlastic)
  end
  for i=0,7 do local a=-math.pi*.65+i*math.pi*1.3/8 local b=-math.pi*.65+(i+1)*math.pi*1.3/8
   line(m,"CupHandle",base:PointToWorldSpace(Vector3.new(.48+.2*math.cos(a),.27+.22*math.sin(a),0)),base:PointToWorldSpace(Vector3.new(.48+.2*math.cos(b),.27+.22*math.sin(b),0)),.065,Color3.fromRGB(237,222,214),Enum.Material.SmoothPlastic)
  end
  local attachment=Instance.new("Attachment")attachment.Position=Vector3.new(.30,0,0)attachment.Parent=m.CupBody
  local steam=Instance.new("ParticleEmitter")steam.Name="TeaSteam"steam.Texture="rbxasset://textures/particles/smoke_main.dds"steam.Color=ColorSequence.new(Color3.fromRGB(235,232,220))steam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.85),NumberSequenceKeypoint.new(.3,.93),NumberSequenceKeypoint.new(1,1)})steam.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.11),NumberSequenceKeypoint.new(1,.55)})steam.Rate=2 steam.Lifetime=NumberRange.new(1,1.8)steam.Speed=NumberRange.new(.25,.45)steam.SpreadAngle=Vector2.new(8,8)steam.Acceleration=Vector3.new(.03,.1,0)steam.Parent=attachment Collection:AddTag(steam,"RuinVFX")
  return m
 end
 for i=0,3 do local angle=i*math.pi*.5 local x,z=math.cos(angle)*4.2,math.sin(angle)*4.2
  local stool=Instance.new("Model")stool.Name="PinkStool"stool.Parent=tea
  cylinder(stool,"StoolFrame",2.3,.35,teaCF(x,1.8,z),Color3.fromRGB(127,104,76),Enum.Material.Wood,true)
  for _,sx in ipairs({-1,1})do for _,sz in ipairs({-1,1})do part(stool,"StoolLeg",Vector3.new(.25,1.55,.25),teaCF(x+sx*.65,.8,z+sz*.65),Color3.fromRGB(127,104,76),Enum.Material.Wood,true)end end
  seat(stool,"TeaSeat",teaCF(x,2.09,z).Position,-angle-math.pi*.5,true)
  cylinder(tea,"Saucer",1.08,.06,teaCF(math.cos(angle)*2.1,3.26,math.sin(angle)*2.1),Color3.fromRGB(235,222,204),Enum.Material.SmoothPlastic,false)
  cup(tea,teaCF(math.cos(angle)*2.1,3.29,math.sin(angle)*2.1)*CFrame.Angles(0,-angle,0),"TeaCup")
 end
 local pot=Instance.new("Model")pot.Name="Teapot"pot.Parent=tea
 ball(pot,"PotBody",Vector3.new(1.55,1.17,1.55),teaCF(0,3.76,.15),Color3.fromRGB(235,215,207),Enum.Material.SmoothPlastic)
 cylinder(pot,"PotFoot",.95,.12,teaCF(0,3.24,.15),Color3.fromRGB(219,192,175),Enum.Material.SmoothPlastic,false)
 cylinder(pot,"PotLid",1.16,.14,teaCF(0,4.29,.15),Color3.fromRGB(237,219,209),Enum.Material.SmoothPlastic,false)
 ball(pot,"LidKnob",Vector3.new(.24,.22,.24),teaCF(0,4.46,.15),Color3.fromRGB(202,162,132),Enum.Material.SmoothPlastic)
 for i=0,7 do local a=-math.pi*.7+i*math.pi*1.4/8 local b=-math.pi*.7+(i+1)*math.pi*1.4/8
  line(pot,"PotHandle",teaCF(0,0,0):PointToWorldSpace(Vector3.new(-.88-.34*math.cos(a),3.78+.44*math.sin(a),.15)),teaCF(0,0,0):PointToWorldSpace(Vector3.new(-.88-.34*math.cos(b),3.78+.44*math.sin(b),.15)),.13,Color3.fromRGB(232,210,200),Enum.Material.SmoothPlastic)
 end
 local previous=teaCF(.55,3.65,.15).Position
 for _,point in ipairs({Vector3.new(.95,3.82,.15),Vector3.new(1.22,4.13,.15),Vector3.new(1.52,4.28,.15)})do local nextPoint=teaCF(point.X,point.Y,point.Z).Position line(pot,"CurvedSpout",previous,nextPoint,.24,Color3.fromRGB(235,215,207),Enum.Material.SmoothPlastic)previous=nextPoint end
 local serve=Instance.new("ProximityPrompt")serve.Name="ServeTea"serve.ActionText="Servir chá"serve.ObjectText="Cantinho do chá"serve.MaxActivationDistance=8 serve.RequiresLineOfSight=false serve.HoldDuration=.6 serve.Parent=pot.PotBody
 cylinder(tea,"CookiePlate",1.9,.07,teaCF(.15,3.26,-1.5),Color3.fromRGB(219,190,147),Enum.Material.SmoothPlastic,false)
 for i=1,6 do local x,z=.15+rng:NextNumber(-.5,.5),-1.5+rng:NextNumber(-.4,.4)
  cylinder(tea,"Cookie",.43,.075,teaCF(x,3.33+(i%2)*.06,z),Color3.fromRGB(183,129,72),Enum.Material.Sand,false)
  for chip=1,3 do ball(tea,"ChocolateChip",Vector3.new(.055,.025,.055),teaCF(x+rng:NextNumber(-.12,.12),3.38+(i%2)*.06,z+rng:NextNumber(-.12,.12)),Color3.fromRGB(70,43,24),Enum.Material.SmoothPlastic)end
 end
 cylinder(tea,"FlowerVase",.48,.67,teaCF(-.9,3.51,1.0),Color3.fromRGB(176,192,164),Enum.Material.SmoothPlastic,false)
 for i=0,4 do local a=i*math.pi*2/5 local tip=teaCF(-.9+.2*math.cos(a),4.30+(i%2)*.16,1+.2*math.sin(a)).Position
  line(tea,"FlowerStem",teaCF(-.9,3.76,1).Position,tip,.035,GREEN,Enum.Material.Grass)
  for petal=0,4 do local b=petal*math.pi*2/5 ball(tea,"PinkPetal",Vector3.new(.20,.10,.15),CFrame.new(tip+Vector3.new(math.cos(b)*.1,.02,math.sin(b)*.1)),PINK,Enum.Material.SmoothPlastic)end
 end
 local tool=Instance.new("Tool")tool.Name="Chá"tool.RequiresHandle=true tool.CanBeDropped=false tool.ToolTip="Toque para tomar um gole"tool.Grip=CFrame.new(0,-.15,0)*CFrame.Angles(0,0,math.rad(-12))
 local toolCup=cup(tool,CFrame.identity,"CupGeometry")
 local handle=Instance.new("Part")handle.Name="Handle"handle.Size=Vector3.new(.7,.55,.7)handle.Transparency=1 handle.Anchored=false handle.CanCollide=false handle.CanQuery=false handle.CanTouch=false handle.Massless=true handle.Parent=tool
 for _,p in ipairs(toolCup:GetDescendants())do if p:IsA("BasePart")then p.Anchored=false p.CanCollide=false p.CanQuery=false p.Massless=true local weld=Instance.new("WeldConstraint")weld.Part0=handle weld.Part1=p weld.Parent=p end end
 tool.Name="TeaCupTool"tool.Parent=runtime
 -- Fountain with four curved animated streams, a shallow bowl and bounded droplets.
 local fountain=Instance.new("Model")fountain.Name="GardenFountain"fountain.ModelStreamingMode=Enum.ModelStreamingMode.Atomic fountain.Parent=ruins
 local fc=cf(15,0,14)
 cylinder(fountain,"FountainBase",10,.6,fc*CFrame.new(0,.3,0),STONE,Enum.Material.Limestone,true)
 cylinder(fountain,"BasinFloor",8.9,.2,fc*CFrame.new(0,.74,0),Color3.fromRGB(133,151,142),Enum.Material.Slate,true)
 for i=0,19 do local a=i*math.pi*2/20 local b=(i+1)*math.pi*2/20
  local mid=(a+b)*.5 part(fountain,"BasinRim",Vector3.new(1.58,.95,.72),fc*CFrame.new(math.cos(mid)*4.7,1.05,math.sin(mid)*4.7)*CFrame.Angles(0,-mid-math.pi*.5,0),PALE,Enum.Material.Limestone,true)
 end
 local water=cylinder(fountain,"FountainWater",8.6,.08,fc*CFrame.new(0,1.00,0),Color3.fromRGB(111,171,175),Enum.Material.Glass,false)water.Transparency=.38 water.Reflectance=.12
 cylinder(fountain,"FountainPedestal",1.05,2.3,fc*CFrame.new(0,1.7,0),PALE,Enum.Material.Limestone,true)
 cylinder(fountain,"UpperBowl",3.2,.3,fc*CFrame.new(0,2.85,0),STONE,Enum.Material.Limestone,false)
 ball(fountain,"Finial",Vector3.new(.75,.85,.75),fc*CFrame.new(0,3.46,0),PALE,Enum.Material.Limestone)
 for i=0,3 do
  local a=i*math.pi*.5 local start=Instance.new("Attachment")start.Name="JetStart"start.CFrame=fountain.FountainBase.CFrame:ToObjectSpace(fc*CFrame.new(math.cos(a)*.5,3.05,math.sin(a)*.5)*CFrame.Angles(0,-a,math.pi*.35))start.Parent=fountain.FountainBase
  local finish=Instance.new("Attachment")finish.Name="JetEnd"finish.CFrame=fountain.FountainBase.CFrame:ToObjectSpace(fc*CFrame.new(math.cos(a)*3.5,.75,math.sin(a)*3.5)*CFrame.Angles(0,-a,-math.pi*.40))finish.Parent=fountain.FountainBase
  local jet=Instance.new("Beam")jet.Name="WaterJet"jet.Attachment0=start jet.Attachment1=finish jet.CurveSize0=3.2 jet.CurveSize1=2.0 jet.Width0=.10 jet.Width1=.18 jet.FaceCamera=true jet.Segments=16 jet.Color=ColorSequence.new(Color3.fromRGB(180,216,218))jet.Transparency=NumberSequence.new(.32)jet.LightEmission=.1 jet.Texture="rbxasset://textures/particles/smoke_main.dds"jet.TextureSpeed=2 jet.TextureLength=.65 jet.Parent=fountain Collection:AddTag(jet,"RuinVFX")
  local drops=Instance.new("ParticleEmitter")drops.Name="FountainDroplets"drops.Texture="rbxasset://textures/particles/sparkles_main.dds"drops.Rate=5 drops.Lifetime=NumberRange.new(.3,.5)drops.Speed=NumberRange.new(.7,1.5)drops.SpreadAngle=Vector2.new(25,25)drops.Size=NumberSequence.new(.06)drops.Color=ColorSequence.new(Color3.fromRGB(177,219,221))drops.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(1,1)})drops.Acceleration=Vector3.new(0,-8,0)drops.Parent=finish Collection:AddTag(drops,"RuinVFX")
 end
 local originalLantern=assert(world.Amenities.Lanterns:FindFirstChildOfClass("Model"))local addedLights=0
 for _,x in ipairs({-22,0,22})do
  for _,z in ipairs({-14,-4})do
   local lamp=originalLantern:Clone()lamp.Name="HangingLantern"
   for _,name in ipairs({"TimberPost","LanternBracket","HangingChain"})do local p=lamp:FindFirstChild(name,true)if p then p:Destroy()end end
   lamp:PivotTo(cf(x,15.4,z))lamp.Parent=architecture lamp.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   line(architecture,"LanternChain",pos(x,17.2,z),pos(x,21.2,z),.065,Color3.fromRGB(80,75,60),Enum.Material.Metal)
   for _,light in ipairs(lamp:GetDescendants())do if light:IsA("PointLight")then Collection:AddTag(light,"ForestNightLight")addedLights+=1 end end
  end
 end
 -- Walkable stone stairs and a winding path connect the courtyard to the existing forest trail.
 local way=Instance.new("Model")way.Name="EntrancePath"way.ModelStreamingMode=Enum.ModelStreamingMode.Atomic way.Parent=ruins
 local Scene=require(runtime.Scene)local endpoint=Vector3.new(Scene.pathX(CFG.Origin.Z+18),0,CFG.Origin.Z+18)
 local start=pos(37,0,18)local eh=assert(ground(endpoint.X,endpoint.Z))endpoint=eh.Position
 local distance=(Vector2.new(endpoint.X-start.X,endpoint.Z-start.Z)).Magnitude
 local steps=math.ceil(distance/2.8)
 local lastHeight=CFG.Origin.Y
 for i=0,steps do local t=i/steps local p=start:Lerp(endpoint,t)
  local h=assert(ground(p.X,p.Z))local desired=math.max(h.Position.Y+.12,CFG.Origin.Y+(endpoint.Y-CFG.Origin.Y)*t)
  desired=math.min(desired,lastHeight+.45)local height=math.max(.35,desired-h.Position.Y+.25)
  local stone=part(way,"ApproachStep",Vector3.new(3.0,height,8),CFrame.new(p.X,desired-height*.5,p.Z),STONE,Enum.Material.Limestone,true)stone:SetAttribute("GroundPoint",h.Position)lastHeight=desired
 end
 local mood=Instance.new("ProximityPrompt")mood.Name="MoodPrompt"mood.ActionText="Trocar luz / neblina"mood.ObjectText="Ambiente das ruínas"mood.MaxActivationDistance=9 mood.RequiresLineOfSight=false mood.Parent=architecture.ColumnPlinth
 Collection:AddTag(mood,"RuinMoodPrompt")
 local groveCount=0
 for _,tree in ipairs(world.Decor.Trees:GetChildren())do
  local p=tree:GetPivot().Position local distance=(Vector2.new(p.X-CFG.Origin.X,p.Z-CFG.Origin.Z)).Magnitude
  if distance<120 and distance>35 then
   tree:SetAttribute("AutumnGrove",true)groveCount+=1
   for _,leaf in ipairs(tree:GetDescendants())do if leaf:IsA("MeshPart")then local name=leaf.Name:lower()
    if name:find("leaf",1,true)or name:find("leaves",1,true)then local color=Color3.fromRGB(212+rng:NextInteger(-15,10),163+rng:NextInteger(-25,15),86+rng:NextInteger(-12,10))leaf.Color=color local appearance=leaf:FindFirstChildOfClass("SurfaceAppearance")if appearance then appearance.Color=color end end
   end end
  end
 end
 local spawn=world.ForestSpawn local spawnCF=cf(0,3.52,19)*CFrame.Angles(0,math.pi,0)
 local courtyardSpawn=Instance.new("SpawnLocation")courtyardSpawn.Name="CourtyardSpawn"courtyardSpawn.Size=Vector3.new(4,.2,4)courtyardSpawn.CFrame=cf(0,.15,19)courtyardSpawn.Transparency=1 courtyardSpawn.Anchored=true courtyardSpawn.CanCollide=false courtyardSpawn.CanQuery=false courtyardSpawn.CanTouch=false courtyardSpawn.Neutral=true courtyardSpawn.Enabled=false courtyardSpawn.Parent=courtyard
 if CFG.SpawnInCourtyard then runtime:SetAttribute("OriginalForestSpawnCF",runtime:GetAttribute("MainSpawnCF"))runtime:SetAttribute("MainSpawnCF",spawnCF)world:SetAttribute("MainSpawnCF",spawnCF)spawn.CFrame=courtyardSpawn.CFrame end
 local remote=Instance.new("RemoteEvent")remote.Name="RuinInteraction"remote.Parent=runtime
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())
 world:SetAttribute("LanternCount",#Collection:GetTagged("ForestNightLight"))world:SetAttribute("UpgradeVersion",89)
 ruins:SetAttribute("ArchCount",archCount)ruins:SetAttribute("SeatCount",seatCount)ruins:SetAttribute("RoofHoles",holes)ruins:SetAttribute("AutumnTrees",groveCount)
 return{origin={CFG.Origin.X,CFG.Origin.Y,CFG.Origin.Z},arches=archCount,columns=#columns,seats=seatCount,roofHoles=holes,vineSegments=vineSegments,vineLeaves=leaves,addedLanterns=addedLights,autumnTrees=groveCount,removedVegetation=removed,spawnInCourtyard=CFG.SpawnInCourtyard}
end
return Builder
