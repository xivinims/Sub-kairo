assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==88,"Published base changed")
local function factory(code)
 local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local value=require(m)m:Destroy()return value
end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)
 local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s
end
local runtime=game.ReplicatedStorage.ForestRuntime
source(runtime,"ModuleScript","Seasons",[============[local Seasons={Names={"Primavera","Verao","Outono","Inverno"}}
function Seasons.axes(x,z)
 return x+28*math.noise(x/40+.37,z/40+.71,33.2),z+28*math.noise(x/40+.37,z/40+.71,36.8)
end
function Seasons.at(x,z)
 local jx,jz=Seasons.axes(x,z)
 if jx>=0 then return jz<0 and "Primavera"or "Verao"end
 return jz>=0 and "Outono"or "Inverno"
end
local function smooth(t)t=math.clamp(t,0,1)return t*t*(3-2*t)end
function Seasons.weights(x,z)
 local jx,jz=Seasons.axes(x,z)local east=smooth((jx+24)/48)local south=smooth((jz+24)/48)
 return{Primavera=east*(1-south),Verao=east*south,Outono=(1-east)*south,Inverno=(1-east)*(1-south)}
end
function Seasons.visual(point,day)
 local w=Seasons.weights(point.X,point.Z)local air=game.Lighting:FindFirstChild("ForestAtmosphere")local color=game.Lighting:FindFirstChild("ForestColor")
 if not air or not color then return end
 air.Density=.28+w.Inverno*.045 air.Haze=1.15+w.Inverno*.25
 local tint=Color3.fromRGB(247,246,234):Lerp(Color3.fromRGB(225,238,251),w.Inverno):Lerp(Color3.fromRGB(255,232,202),w.Outono)
 color.TintColor=color.TintColor:Lerp(tint,.25*day)
 color.Saturation+=w.Primavera*.025-w.Inverno*.06+w.Outono*.015
end
return Seasons
]============])
source(runtime,"ModuleScript","Scene",[============[local Seasons=require(script.Parent:WaitForChild("Seasons"))
local Scene = {Minimum = -512, Maximum = 512, Spacing = 4, RiverY = 6, SeaY = 6, Seed = 20261013}
local function smooth(a, b, x)
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end
local function gaussian(x, z, cx, cz, radius)
	return math.exp(-((x - cx)^2 + (z - cz)^2) / radius^2)
end
function Scene.riverX(z)
	return 38 * math.sin(z / 115) + 22 * math.sin(z / 57 + 0.7)
end
function Scene.riverWidth(z)
	return 13 + 3 * math.sin(z / 92)^2 + 7 * gaussian(0, z, 0, 150, 64)
end
function Scene.pathX(z)
	return -110 + 47 * math.sin((z + 140) / 140) + 16 * math.sin(z / 62)
end
function Scene.pathDistance(x, z)
	local main = math.abs(x - Scene.pathX(z))
	local east = math.abs(x - (145 + 30 * math.sin(z / 100)))
	local crossing = math.min(math.abs(z + 108), math.abs(z - 176))
	if x > -170 and x < 210 then main = math.min(main, crossing) end
	return math.min(main, east)
end
function Scene.sample(x, z)
	local r = math.sqrt((x / 442)^2 + (z / 405)^2)
	local shore = r + math.noise(x / 95, z / 95, 7) * 0.045
	local interior = 1 - smooth(0.75, 1.05, shore)
	local hill = 70 * gaussian(x, z, 220, 228, 114) + 43 * gaussian(x, z, -256, -174, 128)
		+ 31 * gaussian(x, z, -275, 177, 110) + 24 * gaussian(x, z, 274, -184, 116)
	local detail = 3.1 * math.noise(x / 75, z / 75, 3.17) + 1.5 * math.noise(x / 23, z / 23, 12.47)
	local height = -12 + interior * (29 + hill + detail)
	local rd = math.abs(x - Scene.riverX(z))
	local rw = Scene.riverWidth(z)
	local riverInfluence = (1 - smooth(rw - 2, rw + 28, rd)) * (1 - smooth(337, 401, math.abs(z)))
	local bed = Scene.RiverY - 6.5 + math.noise(x / 45, z / 65, 2) * 0.30
	height = height * (1 - riverInfluence) + bed * riverInfluence
	local lake = math.sqrt(((x - 39) / 61)^2 + ((z - 157) / 62)^2)
	local lakeInfluence = 1 - smooth(0.65, 1.25, lake)
	height = height * (1 - lakeInfluence) + (Scene.RiverY - 7) * lakeInfluence
	local path = Scene.pathDistance(x, z)
	local material = Enum.Material.Grass
	if shore > 0.94 then material = Enum.Material.Sand
	elseif height > 57 and hill > 45 then material = Enum.Material.Rock
	elseif height < Scene.RiverY + 1.5 and (rd < rw + 10 or lake < 1.25) then material = Enum.Material.Mud
	elseif path < 4.5 and shore < 0.91 then material = Enum.Material.Ground
	elseif math.noise(x / 45, z / 45, 40) > 0.1 then material = Enum.Material.LeafyGrass end
	local water = Scene.SeaY
	if riverInfluence > 0.2 or lakeInfluence > 0.1 then water = Scene.RiverY end
	return height, material, water, shore, path, rd
end
function Scene.isGreen(x, z)
	local y, material, water, shore = Scene.sample(x, z)
	return Seasons.at(x,z)~="Inverno" and shore < 0.96 and y > water + 0.5 and (material == Enum.Material.Grass or material == Enum.Material.LeafyGrass)
end
function Scene.cell(ix, iz)
	local count = (Scene.Maximum - Scene.Minimum) / Scene.Spacing + 1
	if ix < 0 or iz < 0 or ix >= count or iz >= count then return nil end
	local x, z = Scene.Minimum + ix * Scene.Spacing, Scene.Minimum + iz * Scene.Spacing
	-- Dense cells overlap the actual bone footprint, including both sides of material edges.
	local green = Scene.isGreen(x, z)
	if not green then
		for _, offset in ipairs({Vector2.new(-5, -5), Vector2.new(5, -5), Vector2.new(-5, 5), Vector2.new(5, 5),Vector2.new(0,-5),Vector2.new(0,5),Vector2.new(-5,0),Vector2.new(5,0)}) do
			if Scene.isGreen(x + offset.X, z + offset.Y) then green = true break end
		end
	end
	if not green then return nil end
	local y = Scene.sample(x, z)
	return {key = ix * count + iz + 1, center = Vector3.new(x, y, z), ix = ix, iz = iz}
end
function Scene.around(point, radius)
	local ix = math.floor((point.X - Scene.Minimum) / Scene.Spacing + 0.5)
	local iz = math.floor((point.Z - Scene.Minimum) / Scene.Spacing + 0.5)
	local steps, cells = math.ceil(radius / Scene.Spacing) + 1, {}
	for x = ix - steps, ix + steps do for z = iz - steps, iz + steps do
		local cell = Scene.cell(x, z)
		if cell and (Vector2.new(cell.center.X - point.X, cell.center.Z - point.Z)).Magnitude <= radius then cells[#cells + 1] = cell end
	end end
	table.sort(cells, function(a, b)
		return (Vector2.new(a.center.X - point.X, a.center.Z - point.Z)).Magnitude < (Vector2.new(b.center.X - point.X, b.center.Z - point.Z)).Magnitude
	end)
	return cells
end
return Scene
]============])
local report=factory([============[local Builder={}
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
]============]).install()
local seasonsReport=factory([============[local Builder={}
local Collection=game:GetService("CollectionService")
function Builder.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime
 local Seasons=require(runtime.Seasons)local Scene=require(runtime.Scene)local terrain=workspace.Terrain
 local rng=Random.new(2024)local report={chunks=0,changedVoxels=0,camps=0,logSeats=0,lilies=0,seasonTrees={},seasonPlants={}}
 for _,s in ipairs(Seasons.Names)do report.seasonTrees[s]=0 report.seasonPlants[s]=0 end
 local materials={Primavera=Enum.Material.Grass,Verao=Enum.Material.Grass,Outono=Enum.Material.LeafyGrass,Inverno=Enum.Material.Snow}
 -- Only surface materials change. Solid and liquid occupancy, bank height and bridge landings stay intact.
 for bx=-512,384,128 do for bz=-512,384,128 do
  local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))
  local channels=terrain:ReadVoxelChannels(region,4,{"SolidMaterial"})local grid=channels.SolidMaterial
  for ix=1,32 do for iz=1,32 do
   local material=materials[Seasons.at(bx+(ix-.5)*4,bz+(iz-.5)*4)]
   for iy=1,54 do local previous=grid[ix][iy][iz]
    if previous==Enum.Material.Grass or previous==Enum.Material.LeafyGrass then grid[ix][iy][iz]=material report.changedVoxels+=1 end
   end
  end end
  terrain:WriteVoxelChannels(region,4,{SolidMaterial=grid})report.chunks+=1 task.wait()
 end end
 terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(104,154,58))
 terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(166,127,62))
 terrain:SetMaterialColor(Enum.Material.Snow,Color3.fromRGB(238,245,252))
 local palettes={Primavera={Color3.fromRGB(181,207,127),Color3.fromRGB(211,171,178),Color3.fromRGB(163,193,109)},Verao={Color3.fromRGB(80,126,64),Color3.fromRGB(102,150,74),Color3.fromRGB(71,113,60)},Outono={Color3.fromRGB(184,118,57),Color3.fromRGB(200,153,77),Color3.fromRGB(166,101,49)},Inverno={Color3.fromRGB(104,137,126),Color3.fromRGB(139,159,151),Color3.fromRGB(90,116,107)}}
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,model in ipairs(folder:GetChildren())do
  local p=model:GetPivot().Position local season=Seasons.at(p.X,p.Z)model:SetAttribute("Season",season)
  local counts=folder==world.Decor.Trees and report.seasonTrees or report.seasonPlants counts[season]+=1
  local palette=palettes[season]local color=palette[rng:NextInteger(1,#palette)]
  for _,leaf in ipairs(model:GetDescendants())do if leaf:IsA("MeshPart")then local name=leaf.Name:lower()
   if name:find("leaf",1,true)or name:find("leaves",1,true)or name:find("fern",1,true)then
    leaf.Color=color local appearance=leaf:FindFirstChildOfClass("SurfaceAppearance")if appearance then appearance.Color=color end
   end
  end end
 end end
 local root=Instance.new("Folder")root.Name="SeasonalDetails"root.Parent=world.Amenities
 local camps=Instance.new("Folder")camps.Name="Camps"camps.Parent=root
 local rivers=Instance.new("Folder")rivers.Name="RiverPlants"rivers.Parent=root
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),params)end
 local function part(parent,name,size,cf,color,material,collide)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.Wood
  p.Anchored=true p.CanCollide=collide==true p.CanQuery=p.CanCollide p.CanTouch=false p.Parent=parent return p
 end
 local function clear(x,z,r)
  for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do for _,model in ipairs(folder:GetChildren())do
   local p=model:GetPivot().Position if(Vector2.new(p.X-x,p.Z-z)).Magnitude<r then model:Destroy()end
  end end
 end
 local original=assert(world.Amenities.LogBenches:FindFirstChildOfClass("Model"))
 local function logBench(camp,position,centre)
  local rotation=CFrame.lookAt(Vector3.zero,Vector3.new(centre.X-position.X,0,centre.Z-position.Z)).Rotation
  local bench=original:Clone()bench.Name="CampLogBench"
  for _,d in ipairs(bench:GetDescendants())do if d:IsA("Seat")or d:IsA("ProximityPrompt")then d:Destroy()end end
  bench:ScaleTo(original:GetScale()*.68)bench.Parent=camp
  local _,size=bench:GetBoundingBox()local half=math.min(size.X*.5,3.5)
  local y=position.Y-.16
  for _,x in ipairs({-half,0,half})do local off=rotation:VectorToWorldSpace(Vector3.new(x,0,0))local h=assert(ground(position.X+off.X,position.Z+off.Z))y=math.min(y,h.Position.Y-.16)end
  bench:PivotTo(CFrame.new(position.X,y,position.Z)*rotation)
  for _,p in ipairs(bench:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=true p.CanQuery=true p.CanTouch=false end end
  local mesh=RaycastParams.new()mesh.FilterType=Enum.RaycastFilterType.Include mesh.FilterDescendantsInstances={bench}
  local h=assert(workspace:Raycast(Vector3.new(position.X,y+12,position.Z),Vector3.new(0,-16,0),mesh),"Camp bench has no native top")
  local seat=Instance.new("Seat")seat.Name="CampLogSeat"seat.Anchored=true seat.Size=Vector3.new(2,.15,1.5)seat.CFrame=CFrame.new(position.X,h.Position.Y+.04,position.Z)*rotation seat.Transparency=1 seat.CanCollide=false seat.CanQuery=false seat.CanTouch=false seat.Parent=bench
  local prompt=Instance.new("ProximityPrompt")prompt.Name="SitPrompt"prompt.ActionText="Sentar"prompt.ObjectText="Acampamento"prompt.MaxActivationDistance=7 prompt.HoldDuration=.2 prompt.RequiresLineOfSight=false prompt.Parent=seat
  Collection:AddTag(seat,"RuinSeat")report.logSeats+=1
 end
 local targets={Primavera=Vector2.new(225,-130),Verao=Vector2.new(160,70),Outono=Vector2.new(-290,40),Inverno=Vector2.new(-180,-260)}
 for _,season in ipairs(Seasons.Names)do
  local wanted=targets[season]local site
  for radius=0,144,8 do
   for k=0,15 do local a=k*math.pi/8 local x,z=wanted.X+math.cos(a)*radius,wanted.Y+math.sin(a)*radius
    local h=ground(x,z)
    if h and h.Position.Y>10 and h.Normal.Y>.93 and Seasons.at(x,z)==season and Scene.pathDistance(x,z)>12 and (Vector2.new(x+180,z-30)).Magnitude>62 and (Vector2.new(x-world.OwnerNPC:GetPivot().X,z-world.OwnerNPC:GetPivot().Z)).Magnitude>24 then
     local low,high=h.Position.Y,h.Position.Y local valid=true
     for n=0,7 do local b=n*math.pi/4 local bank=ground(x+math.cos(b)*9,z+math.sin(b)*9)
      if not bank or bank.Material==Enum.Material.Water then valid=false break end low=math.min(low,bank.Position.Y)high=math.max(high,bank.Position.Y)
     end
     if valid and high-low<1.8 then site=h.Position break end
    end
   end
   if site then break end
  end
  assert(site,"No supported camp location for "..season)clear(site.X,site.Z,12)
  local camp=Instance.new("Model")camp.Name=season camp.ModelStreamingMode=Enum.ModelStreamingMode.Atomic camp:SetAttribute("Centre",site)camp:SetAttribute("Season",season)camp.Parent=camps
  for i=0,11 do local angle=i*math.pi/6 local h=assert(ground(site.X+math.cos(angle)*1.9,site.Z+math.sin(angle)*1.9))
   local stone=part(camp,"FireRingStone",Vector3.new(.85,.65,.75),CFrame.new(h.Position+Vector3.new(0,.22,0))*CFrame.Angles(.1,angle,.1),Color3.fromRGB(108,108,101),Enum.Material.Slate,true)stone:SetAttribute("GroundPoint",h.Position)
  end
  for i=0,2 do local p=part(camp,"Firewood",Vector3.new(2.8,.4,.4),CFrame.new(site+Vector3.new(0,.28,0))*CFrame.Angles(0,i*math.pi/3,.12),Color3.fromRGB(88,60,43),Enum.Material.Wood,false)p.Shape=Enum.PartType.Cylinder end
  local core=part(camp,"FireCore",Vector3.new(.4,.4,.4),CFrame.new(site+Vector3.new(0,.3,0)),Color3.fromRGB(68,45,30),Enum.Material.Wood,false)
  local fire=Instance.new("Fire")fire.Name="Campfire"fire.Size=3.5 fire.Heat=4 fire.Color=Color3.fromRGB(255,175,86)fire.SecondaryColor=Color3.fromRGB(245,103,47)fire.Parent=core Collection:AddTag(fire,"RuinVFX")
  local light=Instance.new("PointLight")light.Color=Color3.fromRGB(255,190,116)light.Range=20 light.Brightness=0 light.Shadows=false light.Parent=core Collection:AddTag(light,"ForestNightLight")
  for i=0,3 do local a=i*math.pi*.5+.3 local h=assert(ground(site.X+math.cos(a)*6,site.Z+math.sin(a)*6))logBench(camp,h.Position,site)end
  report.camps+=1
 end
 for i=1,30 do
  local z=-260+(i-.5)*520/30 local x=Scene.riverX(z)+(i%2==0 and -1 or 1)*4
  if math.abs(z+108)<10 or math.abs(z-176)<12 then continue end
  local h=ground(x,z)if not h or h.Material~=Enum.Material.Water then continue end
  local d=rng:NextNumber(1.4,2.3)
  local pad=part(rivers,"LilyPad",Vector3.new(.055,d,d),CFrame.new(x,Scene.RiverY+.04,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(83,123,65),Enum.Material.SmoothPlastic,false)pad.Shape=Enum.PartType.Cylinder
  if i%3==0 then
   for p=0,5 do local a=p*math.pi/3 local petal=part(rivers,"LilyPetal",Vector3.new(.45,.13,.20),CFrame.new(x+math.cos(a)*.18,Scene.RiverY+.13,z+math.sin(a)*.18)*CFrame.Angles(0,-a,0),Color3.fromRGB(227,180,194),Enum.Material.SmoothPlastic,false)petal.Shape=Enum.PartType.Ball end
  end
  report.lilies+=1
 end
 for _,season in ipairs(Seasons.Names)do
  local trees,plants=0,0
  for _,m in ipairs(world.Decor.Trees:GetChildren())do if m:GetAttribute("Season")==season then trees+=1 end end
  for _,m in ipairs(world.Decor.Plants:GetChildren())do if m:GetAttribute("Season")==season then plants+=1 end end
  report.seasonTrees[season]=trees report.seasonPlants[season]=plants world:SetAttribute(season.."Trees",trees)
 end
 world.Amenities.ForestRuins:SetAttribute("AutumnTrees",report.seasonTrees.Outono)
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())world:SetAttribute("LanternCount",#Collection:GetTagged("ForestNightLight"))world:SetAttribute("SeasonCount",4)
 root:SetAttribute("CampCount",report.camps)root:SetAttribute("LogSeatCount",report.logSeats)root:SetAttribute("LilyCount",report.lilies)
 return report
end
return Builder
]============]).install()
source(runtime,"ModuleScript","RuinController",[============[local Controller={}
local Players=game:GetService("Players")local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
function Controller.allowed(distance,alive,elapsed)return alive and distance<=10 and elapsed>=4 end
function Controller.start(runtime,world)
 local ruins=assert(world.Amenities:FindFirstChild("ForestRuins"))local remote=runtime.RuinInteraction
 local last={}local sip={}
 local function actor(player)
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then return c,h,r end
 end
 for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
  if seat:IsDescendantOf(world)then seat.SitPrompt.Triggered:Connect(function(player)
   local c,h,r=actor(player)if r and(r.Position-seat.Position).Magnitude<=9 and not seat.Occupant then seat:Sit(h)end
  end)end
 end
 local prompt=ruins.TeaCorner.Teapot.PotBody.ServeTea
 local function serve(player)
  local c,h,r=actor(player)if not r then return false end
  local now=os.clock()
  if not Controller.allowed((r.Position-prompt.Parent.Position).Magnitude,true,now-(last[player]or -math.huge))then return false end
  last[player]=now
  local backpack=player:FindFirstChildOfClass("Backpack")if not backpack then return false end
  for _,container in ipairs({c,backpack})do for _,item in ipairs(container:GetChildren())do
   if item:IsA("Tool")and item:GetAttribute("RuinTeaCup")then remote:FireClient(player,"Já tem uma xícara! Equipe para tomar um gole.")return true end
  end end
  local tool=runtime.TeaCupTool:Clone()tool.Name="Chá"tool:SetAttribute("RuinTeaCup",true)tool:SetAttribute("ServedToUserId",player.UserId)
  tool.Parent=backpack
  tool.Activated:Connect(function()
   local model,hum,root=actor(player)
   if not model or tool.Parent~=model or tool:GetAttribute("ServedToUserId")~=player.UserId then return end
   local time=os.clock()if time-(sip[player]or -math.huge)<3 then return end sip[player]=time
   local original=tool.Grip
   local lift=Tween:Create(tool,TweenInfo.new(.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original*CFrame.new(.08,-.15,-.22)*CFrame.Angles(math.rad(-24),0,0)})lift:Play()
   remote:FireClient(player,"Um chá quentinho. ☕")
   task.delay(.9,function()if tool.Parent then Tween:Create(tool,TweenInfo.new(.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Grip=original}):Play()end end)
  end)
  task.delay(240,function()if tool.Parent then tool:Destroy()end end)
  hum:EquipTool(tool)remote:FireClient(player,"Chá servido! Toque na xícara equipada para tomar um gole.")return true
 end
 prompt.Triggered:Connect(serve)
 Players.PlayerRemoving:Connect(function(player)last[player]=nil sip[player]=nil end)
 return{serve=serve}
end
return Controller
]============])
source(runtime,"ModuleScript","RuinMood",[============[local Mood={}
function Mood.weight(point,origin)
 local distance=(Vector2.new(point.X-origin.X,point.Z-origin.Z)).Magnitude
 local t=math.clamp((115-distance)/45,0,1)return t*t*(3-2*t)
end
function Mood.apply(point,origin,mode,day)
 local lighting=game.Lighting local weight=Mood.weight(point,origin)
 local air=lighting:FindFirstChild("ForestAtmosphere")local color=lighting:FindFirstChild("ForestColor")
 if not air or not color then return end
 local fog=mode=="Neblina"
 if weight==0 then return end
 air.Density+=(fog and .12 or -.025)*weight
 air.Haze+=(fog and .85 or -.15)*weight
 air.Color=air.Color:Lerp(fog and Color3.fromRGB(157,181,159)or Color3.fromRGB(223,208,159),weight*(fog and .40 or .33)*day)
 color.TintColor=color.TintColor:Lerp(fog and Color3.fromRGB(213,230,211)or Color3.fromRGB(255,237,196),weight*.27)
 color.Saturation+=weight*(fog and -.03 or .035)
 local rays=lighting:FindFirstChild("ForestSunRays")if rays then rays.Intensity+=weight*(fog and -.035 or .018)*day end
end
return Mood
]============])
source(game.ServerScriptService,"Script","ForestServer",[============[local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Visuals=require(runtime:WaitForChild("Visuals"))Visuals.apply()
local Cycle=require(runtime:WaitForChild("Cycle"))
runtime:SetAttribute("CycleEpoch",Cycle.epoch(workspace:GetServerTimeNow()))
runtime:SetAttribute("CycleSeconds",Cycle.Duration)
local world = workspace:WaitForChild("ForestWorld")
local spawn = world:WaitForChild("ForestSpawn")
local spawnCF = runtime:GetAttribute("MainSpawnCF")
require(runtime:WaitForChild("NPCController")).start(runtime,world)
require(runtime:WaitForChild("RuinController")).start(runtime,world)
local Collection=game:GetService("CollectionService")
for _,seat in ipairs(world.Amenities.LogBenches:GetDescendants())do if seat:IsA("Seat")then
	local prompt=seat:FindFirstChild("SitPrompt")
	if prompt then prompt.Triggered:Connect(function(player)
		local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
		if h and h.Health>0 and r and not seat.Occupant and(r.Position-seat.Position).Magnitude<9 then seat:Sit(h)end
	end)end
end end
local function character(player, model)
	local humanoid = model:WaitForChild("Humanoid", 10) local root = model:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= model then return end
	root.Anchored = false humanoid.PlatformStand = false humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16 humanoid.UseJumpPower = true humanoid.JumpPower = 50
	if (root.Position - spawnCF.Position).Magnitude > 28 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero end
end
local function playerAdded(player)
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(model) character(player, model) end)
	if player.Character then task.spawn(character, player, player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt if elapsed < 1 then return end elapsed = 0
	local time = workspace:GetServerTimeNow()
	local clock=Cycle.clock(time,runtime:GetAttribute("CycleEpoch"))Visuals.clock(clock)
	for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do light.Enabled=Cycle.night(clock)>.015 light.Brightness=Cycle.night(clock)*1.7 end
	local strength = 6.8 + math.sin(time * 0.047) * 0.45 + math.sin(time * 0.023) * 0.25
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestCycleClient",[============[local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Cycle=require(runtime:WaitForChild("Cycle"))local Visuals=require(runtime:WaitForChild("Visuals"))
local Seasons=require(runtime:WaitForChild("Seasons"))
local Mood=require(runtime:WaitForChild("RuinMood"))local player=game.Players.LocalPlayer
Visuals.apply()
local lights={}local function added(light)if light:IsA("PointLight")then lights[light]=true end end
for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do added(light)end
local addConnection=Collection:GetInstanceAddedSignal("ForestNightLight"):Connect(added)
local removeConnection=Collection:GetInstanceRemovedSignal("ForestNightLight"):Connect(function(light)lights[light]=nil end)
local elapsed=0
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt if elapsed<1/15 then return end elapsed=0
 local epoch=runtime:GetAttribute("CycleEpoch")if not epoch then return end
 local clock=Cycle.clock(workspace:GetServerTimeNow(),epoch)Visuals.clock(clock)
 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
 if root then Seasons.visual(root.Position,Cycle.daylight(clock))end
 local origin=runtime:GetAttribute("RuinOrigin")
 if root and origin then Mood.apply(root.Position,origin,player:GetAttribute("RuinLocalMood")or "Dourado",Cycle.daylight(clock))end
 local night=Cycle.night(clock)
 for light in pairs(lights)do if light.Parent then light.Enabled=night>.015 light.Brightness=night*1.7 else lights[light]=nil end end
end)
script.Destroying:Connect(function()connection:Disconnect()addConnection:Disconnect()removeConnection:Disconnect()table.clear(lights)end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestRuinClient",[============[local Players=game:GetService("Players")local Collection=game:GetService("CollectionService")local Run=game:GetService("RunService")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local gui=Instance.new("ScreenGui")gui.Name="RuinTeaNotice"gui.ResetOnSpawn=false gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel")label.Name="Notice"label.AnchorPoint=Vector2.new(.5,0)label.Position=UDim2.new(.5,0,0,65)label.Size=UDim2.new(.88,0,0,48)label.BackgroundColor3=Color3.fromRGB(39,48,36)label.BackgroundTransparency=.10 label.TextColor3=Color3.fromRGB(240,231,211)label.TextSize=14 label.Font=Enum.Font.GothamMedium label.TextWrapped=true label.Visible=false label.Parent=gui
local limit=Instance.new("UISizeConstraint")limit.MaxSize=Vector2.new(430,80)limit.Parent=label
local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,12)corner.Parent=label
local untilTime=0
local remote=runtime:WaitForChild("RuinInteraction"):OnClientEvent:Connect(function(text)if type(text)=="string"then label.Text=text label.Visible=true untilTime=os.clock()+4.5 end end)
local prompts={}
local function bind(prompt)
 if prompts[prompt]or not prompt:IsA("ProximityPrompt")then return end
 prompts[prompt]=prompt.Triggered:Connect(function(who)
  if who~=player then return end
  local current=player:GetAttribute("RuinLocalMood")or "Dourado"local nextMood=current=="Dourado"and "Neblina"or "Dourado"
  player:SetAttribute("RuinLocalMood",nextMood)label.Text=nextMood=="Neblina"and "Ruínas com neblina verde — somente para você."or "Luz dourada nas ruínas — somente para você."label.Visible=true untilTime=os.clock()+3.5
 end)
end
for _,prompt in ipairs(Collection:GetTagged("RuinMoodPrompt"))do bind(prompt)end
local added=Collection:GetInstanceAddedSignal("RuinMoodPrompt"):Connect(bind)
local removed=Collection:GetInstanceRemovedSignal("RuinMoodPrompt"):Connect(function(prompt)if prompts[prompt]then prompts[prompt]:Disconnect()prompts[prompt]=nil end end)
local effects={}
local function effect(instance)if instance:IsA("Beam")or instance:IsA("ParticleEmitter")or instance:IsA("Fire")then effects[instance]=true end end
for _,instance in ipairs(Collection:GetTagged("RuinVFX"))do effect(instance)end
local vfxAdd=Collection:GetInstanceAddedSignal("RuinVFX"):Connect(effect)
local vfxRemove=Collection:GetInstanceRemovedSignal("RuinVFX"):Connect(function(instance)effects[instance]=nil end)
local elapsed=0
local frame=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.4 then return end elapsed=0 if label.Visible and os.clock()>untilTime then label.Visible=false end
 local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")if not root then return end
 for instance in pairs(effects)do
  if instance.Parent and instance:IsDescendantOf(workspace)then
   local p=instance.Parent local point
   if p:IsA("Attachment")then point=p.WorldPosition elseif p:IsA("BasePart")then point=p.Position elseif instance:IsA("Beam")and instance.Attachment0 then point=instance.Attachment0.WorldPosition end
   if point then instance.Enabled=(point-root.Position).Magnitude<85 end
  end
 end
end)
script.Destroying:Connect(function()remote:Disconnect()frame:Disconnect()added:Disconnect()removed:Disconnect()vfxAdd:Disconnect()vfxRemove:Disconnect()for _,connection in pairs(prompts)do connection:Disconnect()end gui:Destroy()end)
]============])
run(game.ServerScriptService.ForestServer.Source)
local tests=run([============[local world=assert(workspace:FindFirstChild("ForestWorld"))local runtime=game.ReplicatedStorage.ForestRuntime
local ruins=assert(world.Amenities:FindFirstChild("ForestRuins"))local origin=ruins:GetAttribute("Origin")
assert(world:GetAttribute("UpgradeVersion")==89 and world:GetAttribute("ForestOnly"))
local stats={parts=0,arches=0,seats=0,teaStools=0,cups=0,cookies=0,jets=0,vines=0,leaves=0,foundations=0,roofSlabs=0}
local terrain=RaycastParams.new()terrain.FilterType=Enum.RaycastFilterType.Include terrain.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),terrain)end
local geometry=RaycastParams.new()geometry.FilterType=Enum.RaycastFilterType.Include geometry.FilterDescendantsInstances={ruins}geometry.RespectCanCollide=true
for _,d in ipairs(ruins:GetDescendants())do
 if d:IsA("BasePart")then stats.parts+=1 assert(d.Anchored,"Unanchored ruin geometry")end
 assert(not d:IsA("LuaSourceContainer"),"Unexpected script inside ruin geometry")
 if d.Name=="StoneArch"then
  stats.arches+=1 local p=d:GetAttribute("OpeningCentre")
  assert(not workspace:Raycast(p+Vector3.new(0,0,-4),Vector3.new(0,0,8),geometry),"Arch opening is blocked")
 elseif d:IsA("Seat")then stats.seats+=1 assert(d:FindFirstChild("SitPrompt")and d.CanCollide)if d.Name=="TeaSeat"then stats.teaStools+=1 end
 elseif d.Name=="TeaCup"then stats.cups+=1
 elseif d.Name=="Cookie"then stats.cookies+=1
 elseif d.Name=="WaterJet"then stats.jets+=1 assert(d.Attachment0 and d.Attachment1 and d.Attachment0:IsDescendantOf(workspace)and d.Segments<=20)
 elseif d.Name=="SpiralVine"then stats.vines+=1
 elseif d.Name=="VineLeaf"then stats.leaves+=1
 elseif d.Name=="RoofSlab"then stats.roofSlabs+=1
 elseif d.Name=="Foundation"then
  stats.foundations+=1 local reference=d:GetAttribute("GroundPoint")local h=assert(ground(reference.X,reference.Z))
  assert(d.Position.Y-d.Size.Y*.5<=h.Position.Y+.05,"Foundation floats above the native terrain")
 end
end
assert(stats.parts<1600 and stats.arches==6 and stats.seats==8 and stats.teaStools==4 and stats.cups==4 and stats.cookies==6 and stats.jets==4)
assert(stats.vines>=160 and stats.leaves>=160 and stats.foundations>=50 and ruins:GetAttribute("RoofHoles")>3 and stats.roofSlabs>10)
local walkProbes=0
for x=-28,28,7 do for z=3,24,7 do
 local p=origin+Vector3.new(x,4,z)local h=assert(workspace:Raycast(p,Vector3.new(0,-8,0),geometry),"Courtyard floor missing")
 assert(h.Position.Y>=origin.Y-.1,"Courtyard walking surface too low")walkProbes+=1
end end
local spawn=runtime:GetAttribute("MainSpawnCF")local h=assert(workspace:Raycast(spawn.Position+Vector3.new(0,2,0),Vector3.new(0,-9,0),geometry))
assert(math.abs(spawn.Y-h.Position.Y-3.5)<.08,"Courtyard spawn is not on the floor")
local torso=spawn.Position-Vector3.new(0,1.3,0)
for _,direction in ipairs({Vector3.xAxis,-Vector3.xAxis,Vector3.zAxis,-Vector3.zAxis})do assert(not workspace:Raycast(torso,direction*2.5,geometry),"Courtyard spawn blocked")end
local stepCount=0 local stepHeights={}
for _,step in ipairs(ruins.EntrancePath:GetChildren())do if step.Name=="ApproachStep"then
 stepCount+=1 local floor=step.Position.Y+step.Size.Y*.5 stepHeights[#stepHeights+1]={x=step.Position.X,y=floor,z=step.Position.Z}
 local p=step:GetAttribute("GroundPoint")assert(step.Position.Y-step.Size.Y*.5<=p.Y+.05,"Approach step unsupported")
end end
table.sort(stepHeights,function(a,b)return a.x<b.x end)
for i=2,#stepHeights do assert(math.abs(stepHeights[i].y-stepHeights[i-1].y)<1.0,"Stair rise prevents walking")end
assert(stepCount>20)
local tool=assert(runtime:FindFirstChild("TeaCupTool"))assert(tool:IsA("Tool")and tool.Handle and not tool.CanBeDropped)
local tools=0
for _,p in ipairs(tool:GetDescendants())do if p:IsA("BasePart")then tools+=1 assert(not p.Anchored and not p.CanCollide and p.Massless)if p~=tool.Handle then assert(p:FindFirstChildOfClass("WeldConstraint"),"Tea cup part not attached")end end end
assert(tools>18 and ruins.TeaCorner.Teapot.PotBody:FindFirstChild("ServeTea"))
local Controller=require(runtime.RuinController)
assert(Controller.allowed(8,true,5)and not Controller.allowed(15,true,5)and not Controller.allowed(5,false,5)and not Controller.allowed(5,true,1))
local Mood=require(runtime.RuinMood)local Visuals=require(runtime.Visuals)
assert(Mood.weight(origin,origin)==1 and Mood.weight(origin+Vector3.new(130,0,0),origin)==0)
Visuals.clock(12)require(runtime.Seasons).visual(Vector3.new(200,0,200),1)Mood.apply(origin,origin,"Neblina",1)assert(game.Lighting.ForestAtmosphere.Density>.38)
Visuals.clock(12)require(runtime.Seasons).visual(Vector3.new(200,0,200),1)Mood.apply(origin+Vector3.new(130,0,0),origin,"Dourado",1)assert(math.abs(game.Lighting.ForestAtmosphere.Density-.28)<.001)
Visuals.clock(10.4)
assert(ruins:GetAttribute("AutumnTrees")>15 and #world.Decor.Trees:GetChildren()>350 and #world.Decor.Plants:GetChildren()>1000)
stats.walkProbes=walkProbes stats.approachSteps=stepCount stats.toolParts=tools stats.autumnTrees=ruins:GetAttribute("AutumnTrees")stats.teaServingValidated=true stats.localMoodValidated=true stats.safeCourtyardSpawn=true
local Seasons=require(runtime.Seasons)
assert(Seasons.at(200,-200)=="Primavera"and Seasons.at(200,200)=="Verao"and Seasons.at(-200,200)=="Outono"and Seasons.at(-200,-200)=="Inverno")
local weights=Seasons.weights(0,0)local sum=0 for _,v in pairs(weights)do assert(v>=0 and v<=1)sum+=v end assert(math.abs(sum-1)<.00001)
local seasonal=assert(world.Amenities:FindFirstChild("SeasonalDetails"))local camps=seasonal.Camps
assert(#camps:GetChildren()==4 and seasonal:GetAttribute("LogSeatCount")==16 and seasonal:GetAttribute("LilyCount")>=20)
local snow=0 local autumn=0
for x=-300,-100,40 do for z=-300,-100,40 do local h=ground(x,z)if h and h.Material==Enum.Material.Snow then snow+=1 end end end
for x=-300,-100,40 do for z=100,300,40 do local h=ground(x,z)if h and h.Material==Enum.Material.LeafyGrass then autumn+=1 end end end
assert(snow>15 and autumn>15,"Seasonal surface missing")
for _,camp in ipairs(camps:GetChildren())do
 local centre=camp:GetAttribute("Centre")assert(Seasons.at(centre.X,centre.Z)==camp.Name)
 local h=assert(ground(centre.X,centre.Z))assert(h.Material~=Enum.Material.Water)
 local seats=0
 for _,d in ipairs(camp:GetDescendants())do
  assert(not d:IsA("LuaSourceContainer"))
  if d.Name=="FireRingStone"then local gp=d:GetAttribute("GroundPoint")assert(d.Position.Y-d.Size.Y*.5<=gp.Y)end
  if d:IsA("Seat")then seats+=1 assert(d:FindFirstChild("SitPrompt"))end
 end
 assert(seats==4)
end
for _,pad in ipairs(seasonal.RiverPlants:GetChildren())do if pad.Name=="LilyPad"then local h=assert(ground(pad.Position.X,pad.Position.Z))assert(h.Material==Enum.Material.Water and math.abs(pad.Position.Y-h.Position.Y)<.1)end end
stats.camps=4 stats.campLogSeats=16 stats.snowProbes=snow stats.autumnProbes=autumn stats.lilies=seasonal:GetAttribute("LilyCount")stats.seasonTrees={}
for _,season in ipairs(Seasons.Names)do stats.seasonTrees[season]=world:GetAttribute(season.."Trees")assert(stats.seasonTrees[season]>50)end
return stats
]============])
local forestTests=run([============[local world=assert(workspace:FindFirstChild("ForestWorld"))
local runtime=assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"))
assert(world:GetAttribute("ForestOnly")and world:GetAttribute("UpgradeVersion")==89)
assert(not workspace:FindFirstChild("MonCalamariWorld")and not workspace:FindFirstChild("IlhaSerena"))
local Scene=require(runtime.Scene)
local npc=assert(world:FindFirstChild("OwnerNPC"))
local parts,meshes,pbr,foreign=0,0,0,0
for _,d in ipairs(world:GetDescendants())do
 if d:IsA("BasePart")then parts+=1 if not d:IsDescendantOf(npc)then assert(d.Anchored,d:GetFullName().." unanchored")end end
 if d:IsA("MeshPart")then meshes+=1 end
 if d:IsA("SurfaceAppearance")then pbr+=1 end
 if d:IsA("LuaSourceContainer")then foreign+=1 end
end
assert(foreign==0 and meshes>2000 and pbr>1800,"PBR forest or imported-script isolation failed")
assert(world:GetAttribute("TreeCount")>350 and world:GetAttribute("PlantCount")>1000)
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),ray)end
local treeCount,plantCount,supports,maxGap,maxBurial,tallest,shortest=0,0,0,0,0,0,math.huge
local buriedExamples={}
for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do
 for _,model in ipairs(folder:GetChildren())do
  local profile=assert(runtime.GroundingProfiles:FindFirstChild(model.Name),"Missing root profile")
  local pivot=model:GetPivot()local scale=model:GetAttribute("GroundingScale")
  assert(model:GetAttribute("SupportGeometryProbes")>0,model.Name.." has no lower geometry ray samples")
  local localBurial=0
  for _,point in ipairs(profile:GetChildren())do
   local p=pivot:PointToWorldSpace(point.Value*scale)
   local h=assert(ground(p.X,p.Z),"No terrain under lower geometry")
   if h.Material~=Enum.Material.Water then
    local gap=p.Y-h.Position.Y
    assert(gap<.035,model.Name.." floats at a lower contact: "..gap)
    supports+=1 maxGap=math.max(maxGap,gap)maxBurial=math.max(maxBurial,-gap)localBurial=math.max(localBurial,-gap)
   end
  end
  if localBurial>1 then buriedExamples[#buriedExamples+1]={kind=folder.Name,name=model.Name,burial=localBurial,position={pivot.X,pivot.Y,pivot.Z},scale=scale}end
  local p=pivot.Position local h=assert(ground(p.X,p.Z))
  assert(h.Material~=Enum.Material.Water,"Vegetation root is submerged")
  if folder==world.Decor.Trees then
   treeCount+=1 assert(model:FindFirstChild("TrunkCollision"))
   local _,size=model:GetBoundingBox()tallest=math.max(tallest,size.Y)shortest=math.min(shortest,size.Y)
  else plantCount+=1 end
 end
end
assert(supports>10000 and tallest>95 and tallest-shortest>45 and maxBurial<2.85,"Tree size variation or contact coverage insufficient")
local probes,green,water,trail,minY,maxY=0,0,0,0,math.huge,-math.huge
for x=-360,360,24 do for z=-336,336,24 do
 local h=ground(x,z)if h then probes+=1 minY=math.min(minY,h.Position.Y)maxY=math.max(maxY,h.Position.Y)
  if h.Material==Enum.Material.Water then water+=1
  elseif h.Material==Enum.Material.Grass or h.Material==Enum.Material.LeafyGrass then green+=1
  elseif h.Material==Enum.Material.Ground then trail+=1 end
 end
end end
assert(green>300 and water>40 and trail>10 and maxY-minY>50)
local riverProbes=0
for z=-288,288,8 do
 local h=assert(ground(Scene.riverX(z),z))
 assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-Scene.RiverY)<.10,"River has a dry gap or uneven water plane at "..z)
 riverProbes+=1
end
assert(workspace.Terrain.WaterWaveSize>0 and workspace.Terrain.WaterReflectance<.3 and Scene.SeaY==Scene.RiverY)
for _,p in ipairs({Vector2.new(-750,0),Vector2.new(750,0),Vector2.new(0,-750),Vector2.new(0,750)})do
 local h=assert(ground(p.X,p.Y))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-Scene.SeaY)<.10,"Outer water has an abrupt edge")
end
local bridges=world.Amenities.WoodenBridges
assert(#bridges:GetChildren()==2)
local walks=0
for _,bridge in ipairs(bridges:GetChildren())do
 assert(bridge:GetAttribute("SourceAssetId")==1352279393)
 local a,b=bridge:GetAttribute("DeckStart"),bridge:GetAttribute("DeckEnd")
 local include=RaycastParams.new()include.FilterType=Enum.RaycastFilterType.Include include.FilterDescendantsInstances={bridge}include.RespectCanCollide=true
 for i=0,40 do
  local p=a:Lerp(b,i/40)
  local h=workspace:Raycast(p+Vector3.new(0,4,0),Vector3.new(0,-8,0),include)
  assert(h and h.Instance.Name=="WalkwayCollision" and math.abs(h.Position.Y-p.Y)<.05,"Wooden walkway collision: "..bridge.Name.." step "..i.." hit "..(h and h.Instance.Name or "none"))walks+=1
 end
 for _,p in ipairs({a,b})do local h=assert(ground(p.X,p.Z))assert(h.Material~=Enum.Material.Water and h.Position.Y>=p.Y-1.1,"Bridge does not reach the bank")end
end
for _,d in ipairs(world:GetDescendants())do assert(d.Name~="RiverCrossingLog"and d.Name~="CrossingCollision","Old log crossing survived")end
local seats=0
for _,d in ipairs(world.Amenities.LogBenches:GetDescendants())do if d:IsA("Seat")then seats+=1 assert(d.Anchored and d:FindFirstChild("SitPrompt")and not d.CanCollide)end end
assert(seats>=12 and world:GetAttribute("CutTrunkCount")>=18 and world:GetAttribute("LanternCount")>=15)
local lights=game:GetService("CollectionService"):GetTagged("ForestNightLight")assert(#lights==world:GetAttribute("LanternCount"))
local spawn=runtime:GetAttribute("MainSpawnCF")
local spawnRay=RaycastParams.new()spawnRay.FilterType=Enum.RaycastFilterType.Include spawnRay.FilterDescendantsInstances={workspace.Terrain,world.Amenities.ForestRuins.Courtyard.CourtyardFloor}
local floor=assert(workspace:Raycast(spawn.Position+Vector3.new(0,20,0),Vector3.new(0,-40,0),spawnRay))
assert(floor.Material~=Enum.Material.Water and floor.Normal.Y>.65 and math.abs(spawn.Y-floor.Position.Y-3.5)<.06)
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template.Mesh
assert(template:GetAttribute("SourceAssetId")==87377915371959 and Scene.Spacing==4 and mesh.Size.X<8 and mesh.Size.Y>1.2)
local bones,offsets={},{}local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
assert(#bones==100)
for i,b in ipairs(bones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)lo=lo:Min(offsets[i])hi=hi:Max(offsets[i])end
assert(hi.X-lo.X>Scene.Spacing+1 and hi.Z-lo.Z>Scene.Spacing+1,"Grass root footprint does not overlap adjacent cells")
local sampler=require(runtime.GrassSampler).new(world)
local zones,roots,coveragePoints,misses=0,0,0,0
for _,centre in ipairs({Vector3.new(-240,0,110),Vector3.new(-280,0,40),Vector3.new(160,0,-180),Vector3.new(240,0,210)})do
 local buckets={}local zoneRoots=0
 local function key(x,z)return math.floor(x/2)..":"..math.floor(z/2)end
 for _,cell in ipairs(Scene.around(centre,25))do
  local heights,anchor,valid=sampler:sample(cell,offsets)
  if anchor then
   zoneRoots+=valid
   for i,y in pairs(heights)do
    local p=Vector3.new(cell.center.X+offsets[i].X,y,cell.center.Z+offsets[i].Z)
    local k=key(p.X,p.Z)buckets[k]=buckets[k]or{}buckets[k][#buckets[k]+1]=p
   end
  end
 end
 if zoneRoots>100 then zones+=1 roots+=zoneRoots end
 for x=centre.X-8,centre.X+8,1 do for z=centre.Z-8,centre.Z+8,1 do
  local h=ground(x,z)
  if h and(h.Material==Enum.Material.Grass or h.Material==Enum.Material.LeafyGrass)and h.Normal.Y>.35 then
   local blocked=RaycastParams.new()blocked.FilterType=Enum.RaycastFilterType.Include blocked.FilterDescendantsInstances={world.Decor,world.Amenities}blocked.RespectCanCollide=true
   if not workspace:Raycast(h.Position+Vector3.new(0,20,0),Vector3.new(0,-20,0),blocked)then
    coveragePoints+=1 local covered=false
    for dx=-1,1 do for dz=-1,1 do
     for _,p in ipairs(buckets[key(x+dx*2,z+dz*2)]or{})do if(Vector2.new(p.X-x,p.Z-z)).Magnitude<.90 then covered=true break end end
    end end
    if not covered then misses+=1 end
   end
  end
 end end
end
assert(zones>=3 and coveragePoints>400 and misses==0,"Green terrain still has gaps between grass root grids: "..misses.."/"..coveragePoints)
local Priority=require(runtime.GrassPriority)
local removals,queue=Priority.plan({[99]=true,[100]=true},{{key=1},{key=2}},2,{},0)
assert(#removals==2 and #queue==2 and queue[1].key==1,"Old distant patches prevent nearer grass")
assert(#Scene.around(spawn.Position,42)<=432 and #Scene.around(spawn.Position,70)<=1152,"Client grass budget cannot cover a complete circle")
local storage=Instance.new("Folder")storage.Parent=game.ReplicatedStorage
local Skinned=require(runtime.SkinnedGrass)local simulation=Skinned.new({MeshStorage=storage,RenderDistanceEnabled=false,WindStrengthScale=.40})
local sample=template:Clone()sample:PivotTo(CFrame.new(-210,40,30))sample.Parent=workspace
local bone=sample.Mesh:FindFirstChildWhichIsA("Bone")
bone:SetAttribute("SerenaTerrainOffset",CFrame.new(0,1.25,0))bone:SetAttribute("SerenaGroundPoint",bone.WorldPosition+Vector3.new(0,1.25,0))
simulation:AddMeshes({sample})simulation:Step(1/30,{},bone.TransformedWorldCFrame.Position)
assert(math.abs(bone.Transform.Y-1.25)<.01,"Grass wind lifts roots")
simulation:RemoveMeshes({sample})assert(next(simulation.MeshRecords)==nil)simulation:Destroy()sample:Destroy()storage:Destroy()
assert(npc:GetAttribute("AvatarUserId")==8344738123 and npc.HumanoidRootPart.Anchored and npc:GetAttribute("Seated"))
local description=npc.Humanoid:GetAppliedDescription()
assert(description.Shirt==npc:GetAttribute("ShirtAssetId")and description.Pants==npc:GetAttribute("PantsAssetId")and description.Shirt>0 and description.Pants>0,"NPC does not wear owner's actual clothes")
description:Destroy()
local Pose=require(runtime.NPCPose)local neck=npc.Torso.Neck local shoulder=npc.Torso["Right Shoulder"]
local rootCF=npc.HumanoidRootPart.CFrame
local raised=Pose.wave(shoulder:GetAttribute("OriginalC0"),1.2)
assert((raised.Position-shoulder:GetAttribute("OriginalC0").Position).Magnitude<.001)
local looked=Pose.look(neck:GetAttribute("OriginalC0"),Vector3.new(5,1,-3))
assert((looked.Position-neck.C0.Position).Magnitude<.001 and npc.HumanoidRootPart.CFrame==rootCF)
assert(runtime:FindFirstChild("OwnerDialogue")and npc.Head:FindFirstChild("TalkPrompt"))
local statuses={}
game:GetService("ContentProvider"):PreloadAsync({npc.Head.HiVoice,npc.Head.YayVoice},function(id,status)statuses[#statuses+1]=tostring(status)end)
assert(npc.Head.HiVoice.IsLoaded and npc.Head.HiVoice.TimeLength>0,"Requested greeting audio is unavailable in this experience")
assert(npc.Head.YayVoice.IsLoaded and npc.Head.YayVoice.TimeLength>0,"Yay voice is unavailable in this experience")
local Cycle=require(runtime.Cycle)local Visuals=require(runtime.Visuals)
assert(Cycle.clock(0,0)==6 and Cycle.clock(720,0)==18 and Cycle.clock(960,0)==6)
local epsilon=.001 local before=Cycle.clock(720-epsilon,0)local after=Cycle.clock(720+epsilon,0)
assert(math.abs(before-after)<.001,"Day/night cycle jumps")
local sunDirections={}
for _,hour in ipairs({6,12,18,0})do Visuals.clock(hour)sunDirections[#sunDirections+1]={game.Lighting:GetSunDirection().X,game.Lighting:GetSunDirection().Y,game.Lighting:GetSunDirection().Z}
 assert(game.Lighting.Brightness>=1 and game.Lighting.ForestColor.Enabled and Cycle.night(hour)>=0 and Cycle.night(hour)<=1)
end
assert(Cycle.night(0)>.9 and Cycle.night(12)<.01)
Visuals.clock(Cycle.StartClock)
assert(runtime:GetAttribute("CycleEpoch")and runtime:GetAttribute("ShaderPresetAssetId")==8490242417 and game.Lighting.ForestSky:GetAttribute("SourceAssetId")==8490242417)
assert(not game.Lighting.ForestBlur.Enabled and game.Lighting.ForestSunRays.Enabled)
assert(runtime.WindEffects:GetAttribute("SourceAssetId")==11946229834 and workspace.GlobalWind.Magnitude>6)
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do
 for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
  local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
  local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..": "..tostring(result))compiled+=1
 end end
end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,result=pcall(require,s)assert(ok,s.Name..": "..tostring(result))compiled+=1 end end
assert(workspace.StreamingEnabled and #game.ServerScriptService:GetChildren()==1)
table.sort(buriedExamples,function(a,b)return a.burial>b.burial end)
while#buriedExamples>12 do table.remove(buriedExamples)end
return{forestOnly=true,parts=parts,realMeshParts=meshes,pbrAppearances=pbr,foreignScripts=foreign,trees=treeCount,plants=plantCount,buriedExamples=buriedExamples,
 supportPoints=supports,maximumSupportGap=maxGap,maximumSupportBurial=maxBurial,treeHeightRange={shortest,tallest},
 terrainProbes=probes,greenTerrainProbes=green,waterProbes=water,trailProbes=trail,riverContinuityProbes=riverProbes,
 woodenBridges=2,continuousWalkwayProbes=walks,logSeats=seats,cutTrunks=world:GetAttribute("CutTrunkCount"),lanterns=#lights,
 grassSampledZones=zones,validGrassRoots=roots,grassCoveragePoints=coveragePoints,grassCoverageMisses=misses,grassRootOverlap=hi.X-lo.X-Scene.Spacing,
 grassPriorityCorrect=true,grassRootWindStable=true,ownerAvatarUserId=8344738123,npcSeated=true,npcWaveAndLookKeepBodyFixed=true,
 greetingAudioLoaded=true,greetingAudioLength=npc.Head.HiVoice.TimeLength,yayAudioLoaded=true,yayAudioLength=npc.Head.YayVoice.TimeLength,cycleSeconds=Cycle.Duration,sunDirectionSamples=sunDirections,extendedWaterSurface=true,
 shaderPresetAssetId=8490242417,compiledScriptsAndModules=compiled,streamingEnabled=true,rendering=tostring(game.Lighting.LightingStyle)}
]============])
return{staged=true,baseVersion=game.PlaceVersion,ruins=report,seasons=seasonsReport,tests=tests,forestTests=forestTests}
