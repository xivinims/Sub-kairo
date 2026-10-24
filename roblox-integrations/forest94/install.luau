assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==93,"Published base changed")
game:GetService("ServerStorage")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
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
Scene.CentralLake=Vector3.new(27,6,-18)
Scene.CentralLakeRadius=Vector2.new(76,52)
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
	local central=math.sqrt(((x-27)/76)^2+((z+18)/52)^2)
 local weight=1-smooth(.65,1.20,central)
 if central<1.20 then height=math.min(height,height*(1-weight)+(-1.8+.22*math.noise(x/25,z/25,17))*weight)end
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
	return Seasons.isGreen() and shore < 0.96 and y > water + 0.5 and (material == Enum.Material.Grass or material == Enum.Material.LeafyGrass)
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
local reports={}
reports.landscape=factory([============[local B={}
local Terrain=workspace.Terrain
local LAKE=Vector3.new(27,6,-18)
local RX,RZ=76,52
local function smooth(t)t=math.clamp(t,0,1)return t*t*(3-2*t)end
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)
 local report={lakeColumns=0,removedVegetation=0,removedLogs=0,flowers=0,stairSteps=0}
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={Terrain}rp.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,rp)end
 local function lakeRadius(x,z)return math.sqrt(((x-LAKE.X)/RX)^2+((z-LAKE.Z)/RZ)^2)end
 -- Carve a single connected basin without resetting the island, camp foundations or ruins.
 local region=Region3.new(Vector3.new(-72,-32,-88),Vector3.new(124,40,52)):ExpandToGrid(4)
 local channels=Terrain:ReadVoxelChannels(region,4,{"SolidMaterial","SolidOccupancy","LiquidOccupancy"})
 local lower=region.CFrame.Position-region.Size*.5
 for ix=1,channels.Size.X do for iz=1,channels.Size.Z do
  local x,z=lower.X+(ix-.5)*4,lower.Z+(iz-.5)*4 local radius=lakeRadius(x,z)
  if radius<1.20 then
   local h=assert(ground(x,z))local weight=1-smooth((radius-.65)/.55)
   local bed=-1.8+.22*math.noise(x/25,z/25,17)
   local height=math.min(h.Position.Y,h.Position.Y*(1-weight)+bed*weight)
   for iy=1,channels.Size.Y do local low=lower.Y+(iy-1)*4 local solid=math.clamp((height-low)/4,0,1)
    channels.SolidOccupancy[ix][iy][iz]=solid
    channels.SolidMaterial[ix][iy][iz]=solid>0 and(height-low<6 and(height<7.5 and Enum.Material.Sand or Enum.Material.Grass)or Enum.Material.Rock)or Enum.Material.Air
    channels.LiquidOccupancy[ix][iy][iz]=solid<1 and math.clamp((LAKE.Y-low)/4,0,1)or 0
   end
   report.lakeColumns+=1
  end
 end end
 Terrain:WriteVoxelChannels(region,4,{SolidMaterial=channels.SolidMaterial,SolidOccupancy=channels.SolidOccupancy,LiquidOccupancy=channels.LiquidOccupancy})
 task.wait(.2)
 world:SetAttribute("CentralLake",LAKE)world:SetAttribute("CentralLakeRadius",Vector2.new(RX,RZ))
 local function passage(x,z,margin)
  if Scene.pathDistance(x,z)<margin then return true end
  for _,bz in ipairs({-108,176})do if math.abs(z-bz)<margin+7 and math.abs(x-Scene.riverX(bz))<85 then return true end end
  if math.abs(z+18)<margin+5 and math.abs(x-Scene.riverX(-18))<70 then return true end
  return false
 end
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs,world.Amenities.CutTrunks,world.Amenities.LogBenches})do
  for _,m in ipairs(folder:GetChildren())do if m:IsA("Model")then
   local point=m:GetAttribute("ActualRootPoint")or m:GetAttribute("GroundPoint")or m:GetPivot().Position
   local hit=ground(point.X,point.Z)
   local invalid=lakeRadius(point.X,point.Z)<1.20 and(not hit or hit.Position.Y<7)
   local name=m.Name:lower()local log=folder==world.Amenities.CutTrunks or folder==world.Amenities.LogBenches or name:find("fallen",1,true)or name:find("stump",1,true)or name:find("stick",1,true)or name:find("branch",1,true)
   local cf,size=m:GetBoundingBox()local radius=math.min(11,math.max(size.X,size.Z)*.5)
   if invalid or log and passage(cf.X,cf.Z,8+radius)then
    m:Destroy()if log then report.removedLogs+=1 else report.removedVegetation+=1 end
   end
  end end
 end
 for _,old in ipairs({world:FindFirstChild("Wildlife"),runtime:FindFirstChild("WildlifeTemplates"),runtime:FindFirstChild("CuteAnimalTemplates"),world.Amenities:FindFirstChild("CuteAnimalRoutes")})do if old then old:Destroy()end end
 world:SetAttribute("AnimalsEnabled",false)
 -- Small native flowers sit in the soil; no tall spiky procedural grass is introduced.
 local flowerTemplates={}local plantTemplates={}
 for _,m in ipairs(world.Decor.Plants:GetChildren())do
  if m.Name:lower():find("wildflower",1,true)then
   local _,size=m:GetBoundingBox()m:ScaleTo(m:GetScale()*math.clamp(.9/size.Y,.15,1))
   if #flowerTemplates<8 then flowerTemplates[#flowerTemplates+1]=m end
  elseif m.Name=="Fern_Var01"then if #plantTemplates<4 then plantTemplates[#plantTemplates+1]=m end end
 end
 assert(#flowerTemplates>0,"Native flower source missing")local rng=Random.new(941027)
 for i=1,180 do
  local a=i*2.39996 local rr=rng:NextNumber(.99,1.27)
  local x,z=LAKE.X+math.cos(a)*RX*rr,LAKE.Z+math.sin(a)*RZ*rr
  local hit=ground(x,z)
  if hit and hit.Position.Y>7.1 and hit.Normal.Y>.76 and not passage(x,z,6)then
   local template=flowerTemplates[(i-1)%#flowerTemplates+1]local m=template:Clone()
   m:SetAttribute("LakeFlower",true)m:PivotTo(m:GetPivot()+Vector3.new(x-m:GetPivot().X,0,z-m:GetPivot().Z))m.Parent=world.Decor.Plants
   local cf,size=m:GetBoundingBox()m:PivotTo(m:GetPivot()+Vector3.yAxis*(hit.Position.Y-(cf.Y-size.Y*.5)-.18))
   report.flowers+=1
  end
 end
 -- Remove the invalid final stair frame (zero-length look direction) and rebuild supported steps.
 local old=world.Amenities:FindFirstChild("WeatheredHillStair")if old then old:Destroy()end
 local sanctuary=world.Amenities.ForestLandmarks.MossySanctuary local target=sanctuary:GetAttribute("Origin")
 local start
 for i=0,31 do local a=i*math.pi/16 local h=ground(target.X+math.cos(a)*38,target.Z+math.sin(a)*38)
  if h and(not start or h.Position.Y<start.Y)then start=h.Position end
 end
 assert(start)local dir=Vector3.new(target.X-start.X,0,target.Z-start.Z).Unit
 local finish=Vector3.new(target.X-dir.X*13,target.Y,target.Z-dir.Z*13)
 local delta=Vector3.new(finish.X-start.X,0,finish.Z-start.Z)local rotation=CFrame.lookAt(Vector3.zero,delta).Rotation
 local n=math.max(16,math.ceil(math.abs(finish.Y-start.Y)/.38))
 local stair=Instance.new("Model")stair.Name="WeatheredHillStair"stair.ModelStreamingMode=Enum.ModelStreamingMode.Atomic stair.Parent=world.Amenities
 local nodes={}
 for i=1,n do local t=i/n local p=start:Lerp(finish,t)local g=assert(ground(p.X,p.Z)).Position local top=math.max(p.Y,g.Y+.12)local height=math.max(.25,top-g.Y+.25)
  local step=Instance.new("Part")step.Name="UphillStoneStep"step.Size=Vector3.new(7,height,delta.Magnitude/n+.15)step.CFrame=CFrame.new(p.X,top-height*.5,p.Z)*rotation step.Color=Color3.fromRGB(143,158,135)step.Material=Enum.Material.Cobblestone step.Anchored=true step.CanCollide=true step.CanQuery=true step.CanTouch=false step.Parent=stair
  nodes[#nodes+1]={p.X,top,p.Z}report.stairSteps+=1
 end
 stair:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))
 Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(98,139,66))
 runtime:SetAttribute("GrassRenderer","NativeTerrain")runtime:SetAttribute("GrassHeightStuds",.4)
 world:SetAttribute("LakeFlowerCount",report.flowers)
 return report
end
return B
]============]).install()
reports.bridges=factory([============[local B={}
local WOOD=Color3.fromRGB(147,115,76)local PALE=Color3.fromRGB(182,146,101)local DARK=Color3.fromRGB(92,69,48)
function B.install()
 local world=workspace.ForestWorld local Scene=require(game.ReplicatedStorage.ForestRuntime.Scene)
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,rp)).Position end
 local folder=world.Amenities.WoodenBridges folder:ClearAllChildren()
 local report={bridges=0,parts=0}
 local function part(parent,name,size,cf,color,material)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color or WOOD p.Material=material or Enum.Material.Wood p.Anchored=true p.CanCollide=true p.CanQuery=true p.CanTouch=false p.Transparency=0 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent report.parts+=1 return p
 end
 local function beam(parent,name,a,b,width,height,color)return part(parent,name,Vector3.new(width,height,(b-a).Magnitude+.03),CFrame.lookAt((a+b)*.5,b),color)end
 for index,z in ipairs({-108,176})do
  local cx=Scene.riverX(z)local xa,xb=cx-8,cx+8
  while ground(xa,z).Y<9 do xa-=2 end while ground(xb,z).Y<9 do xb+=2 end xa-=2 xb+=2
  local a,b=ground(xa,z),ground(xb,z)local W=11 local N=math.ceil((b-a).Magnitude/3.0)
  local m=Instance.new("Model")m.Name="WoodlandBridge"..index m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m:SetAttribute("DeckWidth",W)m:SetAttribute("ReferenceStyle","Wide carved woodland arch, longitudinal timber boards and scalloped support corbels")m.Parent=folder
  local function point(t)return a:Lerp(b,t)+Vector3.yAxis*(.08+2.4*math.sin(math.pi*t))end
  local nodes={}
  for i=0,N do local p=point(i/N)nodes[#nodes+1]={p.X,p.Y,p.Z}end
  for i=1,N do
   local aa,bb=point((i-1)/N),point(i/N)local cf=CFrame.lookAt((aa+bb)*.5,bb)local len=(bb-aa).Magnitude+.08
   for lane=0,7 do local x=-W*.5+(lane+.5)*W/8
    part(m,"SolidDeckPlank",Vector3.new(W/8+.012,.38,len),cf*CFrame.new(x,-.19,0),WOOD:Lerp(PALE,((lane+i)%5)*.09))
   end
   if i%3==1 then
    part(m,"UnderDeckCrossbeam",Vector3.new(W+1.3,.55,.7),cf*CFrame.new(0,-.66,0),DARK)
    for _,s in ipairs({-1,1})do
     local tip=cf:PointToWorldSpace(Vector3.new(s*(W/2+.45),-.65,0))
     for j=0,2 do part(m,"CarvedCorbel",Vector3.new(.64,.4,.75-j*.1),CFrame.new(tip+Vector3.new(0,-.4*j,j*.14))*cf.Rotation,WOOD:Lerp(PALE,j*.16))end
    end
   end
   for _,s in ipairs({-1,1})do
    part(m,"TimberHandrail",Vector3.new(.58,.32,len),cf*CFrame.new(s*(W/2-.25),2.65,0),PALE)
    part(m,"FramedLowerRail",Vector3.new(.28,.23,len),cf*CFrame.new(s*(W/2-.25),1.05,0),WOOD)
    beam(m,"ArchedFoundationTimber",aa+Vector3.new(0,-1.2,s*(W/2-.2)),bb+Vector3.new(0,-1.2,s*(W/2-.2)),.6,.85,DARK)
   end
  end
  local postCount=math.ceil((b-a).Magnitude/10)
  for i=0,postCount do local t=i/postCount local c=point(t)
   for _,s in ipairs({-1,1})do local pos=c+Vector3.zAxis*s*(W/2-.25)local g=ground(pos.X,pos.Z)local top=pos.Y+3.2 local base=g.Y-.45
    part(m,"GroundedCarvedPost",Vector3.new(1,top-base,1),CFrame.new(pos.X,(top+base)*.5,pos.Z),DARK)
    for _,h in ipairs({.75,2.42})do part(m,"CarvedPostCollar",Vector3.new(1.16,.16,1.16),CFrame.new(pos+Vector3.yAxis*h),WOOD)end
    part(m,"PostCapital",Vector3.new(1.34,.25,1.34),CFrame.new(pos+Vector3.yAxis*3.1),PALE)
    part(m,"PostCapFinial",Vector3.new(.68,.2,.68),CFrame.new(pos+Vector3.yAxis*3.32),WOOD)
   end
  end
  for _,endpoint in ipairs({a,b})do part(m,"BankApron",Vector3.new(2.6,.3,W),CFrame.new(endpoint-Vector3.yAxis*.08),WOOD)end
  m:SetAttribute("DeckStart",point(0))m:SetAttribute("DeckEnd",point(1))m:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))report.bridges+=1
 end
 return report
end
return B
]============]).install()
reports.water=factory([============[local B={}
local C=game:GetService("CollectionService")
local function P(parent,name,size,cf,color,mat,collide,class)
 local p=Instance.new(class or"Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=mat or Enum.Material.Slate p.Anchored=true p.CanCollide=collide==true p.CanQuery=collide==true p.CanTouch=false p.CastShadow=collide==true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
-- Two right triangular prisms form each authored polygon face. Their common edge is coplanar, never stacked.
local function triangle(parent,a,b,c,thickness,color,name)
 local ab,ac,bc=b-a,c-a,c-b local abd,acd,bcd=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
 if abd>acd and abd>bcd then c,a=a,c elseif acd>bcd and acd>abd then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit local back=bc.Unit local up=bc:Cross(right).Unit
 local height=math.abs(ab:Dot(up))local length1=math.abs(ab:Dot(back))local length2=math.abs(ac:Dot(back))
 if height<.001 or length1<.001 or length2<.001 then return end
 P(parent,name,Vector3.new(thickness,height,length1),CFrame.fromMatrix((a+b)*.5,right,up,back),color,Enum.Material.Slate,true,"WedgePart")
 P(parent,name,Vector3.new(thickness,height,length2),CFrame.fromMatrix((a+c)*.5,-right,up,-back),color,Enum.Material.Slate,true,"WedgePart")
end
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)local Terrain=workspace.Terrain
 local garden=world.Amenities.RiversideGarden
 for _,name in ipairs({"AnimeRiverFoam","StreamSteppingStones","CartoonWater"})do local old=garden:FindFirstChild(name)if old then old:Destroy()end end
 local waterRay=RaycastParams.new()waterRay.FilterType=Enum.RaycastFilterType.Include waterRay.FilterDescendantsInstances={Terrain}
 local groundRay=RaycastParams.new()groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={Terrain}groundRay.IgnoreWater=true
 local function wet(x,z)local h=workspace:Raycast(Vector3.new(x,200,z),Vector3.yAxis*-300,waterRay)return h and h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.12 end
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,200,z),Vector3.yAxis*-300,groundRay)).Position end
 local raw=game:GetService("AssetService"):LoadAssetAsync(6833503207)
 local surface=assert(raw:FindFirstChild("Water",true))assert(surface:IsA("MeshPart")and surface.MeshId=="rbxassetid://6833048037","Requested water model changed")
 local report={waterTiles=0,shoreFoam=0,stones=0,stoneFaces=0,waterAsset=6833503207}
 local water=Instance.new("Folder")water.Name="CartoonWater"water:SetAttribute("SourceAssetId",6833503207)water.Parent=garden
 Terrain.WaterColor=Color3.fromRGB(55,161,186)Terrain.WaterTransparency=.24 Terrain.WaterReflectance=.025 Terrain.WaterWaveSize=.015 Terrain.WaterWaveSpeed=3
 -- Keep native continuous swimming water. Import only one shallow visual layer from the requested model.
 for z=-294,294,12 do for x=-150,174,12 do
  local safe=true for _,dx in ipairs({-6,0,6})do for _,dz in ipairs({-6,0,6})do if not wet(x+dx,z+dz)then safe=false end end end
  if safe then
   local p=surface:Clone()p.Name="CartoonWaterSurface"p.Size=Vector3.new(12,.035,12)p.CFrame=CFrame.new(x,6.14,z)p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=.91 p.Color=Terrain.WaterColor p:SetAttribute("SourceAssetId",6833503207)p:SetAttribute("WaterCentre",Vector3.new(x,6,z))
   for _,d in ipairs(p:GetDescendants())do if d:IsA("LuaSourceContainer")then d:Destroy()elseif d:IsA("Texture")then d.StudsPerTileU=14 d.StudsPerTileV=14 d.Transparency=.74 d.OffsetStudsU=x%14 d.OffsetStudsV=z%14 C:AddTag(d,"TreeWorldWaterTexture")end end
   p.Parent=water report.waterTiles+=1
  end
 end end
 local foam=Instance.new("Folder")foam.Name="ShoreFoam"foam.Parent=water
 for z=-274,274,8 do local center=Scene.riverX(z)
  if wet(center,z)then for _,side in ipairs({-1,1})do
   local inside,outside=center,center
   for _=1,80 do outside+=side*2 if not wet(outside,z)then break end inside=outside end
   for _=1,8 do local mid=(inside+outside)*.5 if wet(mid,z)then inside=mid else outside=mid end end
   local x=inside-side*.65
   if wet(x,z)then local strip=P(foam,"WaterlineFoam",Vector3.new(.32,.028,3.2),CFrame.new(x,6.075,z)*CFrame.Angles(0,.15*math.sin(z*.1),0),Color3.fromRGB(230,246,244),Enum.Material.SmoothPlastic,false)strip.Transparency=.38 report.shoreFoam+=1 end
  end end
 end
 raw:Destroy()runtime:SetAttribute("WaterStyle","CartoonWaterSingleLayer")runtime:SetAttribute("WaterAssetId",6833503207)
 -- Pale irregular polygon slabs, separated by reachable hops, with fully visible stone sides to the bed.
 local stones=Instance.new("Model")stones.Name="StreamSteppingStones"stones.ModelStreamingMode=Enum.ModelStreamingMode.Atomic stones.Parent=garden
 local z=90 local cx=Scene.riverX(z)local xa,xb=cx-4,cx+4
 while ground(xa,z).Y<7.3 do xa-=2 end while ground(xb,z).Y<7.3 do xb+=2 end
 local a,b=ground(xa,z),ground(xb,z)local count=math.ceil((xb-xa)/6.6)local nodes={}
 local rng=Random.new(942090)
 for i=0,count do
  local t=i/count local x=xa+(xb-xa)*t local zz=z+math.sin(t*math.pi*2)*1.6 local y=math.max(7.25,a.Y*(1-t)+b.Y*t)
  local model=Instance.new("Model")model.Name="FacetedWalkStone"model.Parent=stones local center=Vector3.new(x,y-.035,zz)local points={}
  local angle=rng:NextNumber(-.2,.2)local rx,rz=3.0,3.1
  for k=0,6 do local an=k*math.pi*2/7+angle local jitter=rng:NextNumber(.92,1.08)points[k+1]=center+Vector3.new(math.cos(an)*rx*jitter,0,math.sin(an)*rz*jitter)end
  local bottom=math.min(ground(x,zz).Y-.3,5.1)
  for k=1,#points do local p,q=points[k],points[k%#points+1]
   triangle(model,center,p,q,.07,Color3.fromRGB(190+k%3*4,204+k%3*4,211+k%3*4),"PaleStoneTop")
   local lowP,lowQ=Vector3.new(p.X,bottom,p.Z),Vector3.new(q.X,bottom,q.Z)
   local color=Color3.fromRGB(102+k%3*9,127+k%3*9,144+k%3*9)
   triangle(model,p,lowP,q,.1,color,"FacetedStoneSide")triangle(model,q,lowP,lowQ,.1,color,"FacetedStoneSide")report.stoneFaces+=3
  end
  model:SetAttribute("WalkTop",y)model:SetAttribute("Centre",Vector3.new(x,y,zz))nodes[#nodes+1]={x,y,zz}report.stones+=1
 end
 stones:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))
 -- A few large riverbank stones use the same polygon style without filling the walking route.
 world:SetAttribute("CartoonWaterTiles",report.waterTiles)world:SetAttribute("ReferenceSteppingStones",report.stones)
 return report
end
return B
]============]).install()
reports.lamps=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)local C=game:GetService("CollectionService")
 local raw=game:GetService("AssetService"):LoadAssetAsync(11324928349)
 local template=assert(raw:FindFirstChildOfClass("Model"),"Requested lamp model missing")
 for _,d in ipairs(template:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Camera")then d:Destroy()end end
 local pole
 for _,d in ipairs(template:GetDescendants())do if d:IsA("MeshPart")and d.MeshId=="rbxassetid://11161434042"then pole=d end end
 assert(pole,"Requested lamp post mesh missing")
 local base=pole.Position-Vector3.yAxis*pole.Size.Y*.5
 template:PivotTo(template:GetPivot()-base)template.PrimaryPart=nil template.WorldPivot=CFrame.identity template:ScaleTo(template:GetScale()*.67)
 local folder=world.Amenities.Lanterns folder:ClearAllChildren()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
 local report={lamps=0,sourceAssetId=11324928349}
 local points={}
 for z=-260,280,45 do points[#points+1]=Vector2.new(Scene.pathX(z)+7,z)points[#points+1]=Vector2.new(145+30*math.sin(z/100)-7,z+9)end
 local lake=world:GetAttribute("CentralLake")for i=0,5 do local a=i*math.pi/3 points[#points+1]=Vector2.new(lake.X+math.cos(a)*88,lake.Z+math.sin(a)*66)end
 for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do for _,key in ipairs({"DeckStart","DeckEnd"})do local p=bridge:GetAttribute(key)points[#points+1]=Vector2.new(p.X,p.Z+8)end end
 for _,point in ipairs(points)do local hit=ground(point.X,point.Y)
  if hit and hit.Position.Y>7.4 and hit.Normal.Y>.83 then
   local m=template:Clone()m.Name="CandleLampPost"m:SetAttribute("SourceAssetId",11324928349)m:SetAttribute("GroundPoint",hit.Position)m:PivotTo(CFrame.new(hit.Position-Vector3.yAxis*.2))m.Parent=folder m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=false p.CanCollide=p:IsA("MeshPart")p.CanQuery=p.CanCollide p.CastShadow=p:IsA("MeshPart")
    elseif p:IsA("Light")then p.Enabled=false p.Shadows=false p.Range=14 p.Brightness=1.1 p.Color=Color3.fromRGB(255,210,151)C:AddTag(p,"ForestNightLight")
    elseif p:IsA("Fire")then p.Size=.25 p.Heat=0 C:AddTag(p,"RuinVFX")end
   end
   report.lamps+=1
  end
 end
 raw:Destroy()assert(report.lamps>=18,"Insufficient grounded lamp posts")world:SetAttribute("CandleLampCount",report.lamps)world:SetAttribute("LampAssetId",11324928349)
 return report
end
return B
]============]).install()
reports.roots=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 for _,name in ipairs({"ForestGrassClient"})do local old=game.StarterPlayer.StarterPlayerScripts:FindFirstChild(name)if old then old:Destroy()end end
 for _,name in ipairs({"SkinnedGrassTemplates","GrassSampler","GrassPriority"})do local old=runtime:FindFirstChild(name)if old then old:Destroy()end end
 local terrainRay=RaycastParams.new()terrainRay.FilterType=Enum.RaycastFilterType.Include terrainRay.FilterDescendantsInstances={workspace.Terrain}terrainRay.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-310,0),terrainRay)end
 local report={trees=0,plants=0,rootProbes=0,removedPlants=0,removedDecor=0}
 if runtime:FindFirstChild("ActualRootContacts")then runtime.ActualRootContacts:Destroy()end
 local probeFolder=Instance.new("Folder")probeFolder.Name="ActualRootContacts"probeFolder.Parent=runtime
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,p in ipairs(folder:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=true end end end
 task.wait(.15)
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,m in ipairs(folder:GetChildren())do
  local tree=folder==world.Decor.Trees local parts={}local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p.Name~="TrunkCollision"and(tree and p.Name:lower():find("trunk",1,true)or not tree)then
   parts[#parts+1]=p p.CanQuery=true
   for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local point=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(point)hi=hi:Max(point)end end end
  end end
  local own=RaycastParams.new()own.FilterType=Enum.RaycastFilterType.Include own.FilterDescendantsInstances=parts
  local samples={}local minimum=math.huge
  -- Sample the actual placed mesh from below. Source scale attributes are not trusted.
  local n=tree and 13 or 5
  for ix=0,n-1 do for iz=0,n-1 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/n local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/n
   local h=workspace:Raycast(Vector3.new(x,lo.Y-3,z),Vector3.yAxis*(hi.Y-lo.Y+6),own)
   if h then minimum=math.min(minimum,h.Position.Y)samples[#samples+1]=h.Position end
  end end
  if tree and minimum>lo.Y+1 then
   for ix=0,30 do for iz=0,30 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/31 local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/31
    local h=workspace:Raycast(Vector3.new(x,lo.Y-3,z),Vector3.yAxis*(hi.Y-lo.Y+6),own)if h then minimum=math.min(minimum,h.Position.Y)samples[#samples+1]=h.Position end
   end end
  end
  local contacts={}
  for _,v in ipairs(samples)do if v.Y<minimum+(tree and 2.2 or .3)then contacts[#contacts+1]=v end end
  if #contacts==0 and not tree then
   -- Flat alpha cards can have no underside for an upward ray; use the actual placed mesh bounds for these plants.
   contacts={Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)}m:SetAttribute("GroundingMethod","PlacedMeshBounds")
  else m:SetAttribute("GroundingMethod","PlacedMeshRaycast")end
  assert(#contacts>0,"No real base geometry: "..m.Name)
  local shift=math.huge local center=Vector3.zero local depth=tree and 1.15 or .18
  for _,point in ipairs(contacts)do local h=assert(ground(point.X,point.Z),"No ground beneath visible root")shift=math.min(shift,h.Position.Y-point.Y-depth)center+=point end
  center/= #contacts m:PivotTo(m:GetPivot()+Vector3.yAxis*shift)
  local finalCenter=center+Vector3.yAxis*shift m:SetAttribute("ActualRootPoint",finalCenter)m:SetAttribute("RootEmbedDepth",depth)
  local entry=Instance.new("ObjectValue")entry.Name="RootContact"entry.Value=m entry:SetAttribute("CoordinateSpace","World")entry.Parent=probeFolder
  local cf=m:GetPivot()
  for i,point in ipairs(contacts)do local v=Instance.new("Vector3Value")v.Name=tostring(i)v.Value=point+Vector3.yAxis*shift v.Parent=entry report.rootProbes+=1 end
  if tree then
   C:AddTag(m,"ForestTree")report.trees+=1
   local trunk=m:FindFirstChild("TrunkCollision")if trunk then local h=assert(ground(finalCenter.X,finalCenter.Z))trunk.CFrame=CFrame.new(finalCenter.X,h.Position.Y+trunk.Size.X*.5-.15,finalCenter.Z)*CFrame.Angles(0,0,math.pi*.5)end
  else report.plants+=1 end
  for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")then p.RenderFidelity=Enum.RenderFidelity.Performance p.CastShadow=tree
   if not p.CanCollide then p.CanQuery=false end
   if p:GetAttribute("ForestRestCF")then p:SetAttribute("ForestRestCF",p.CFrame)end
  end end
 end end
 -- Dense leaf carpets and oversized broad weeds are removed; native grass supplies continuous cover.
 for _,m in ipairs(world.Decor.Plants:GetChildren())do
  if m.Name=="DenseLeafPatch"or m.Name=="CloverPatch"then m:Destroy()report.removedPlants+=1 end
 end
 for _,m in ipairs(world.Amenities.CutTrunks:GetChildren())do local cf,size=m:GetBoundingBox()local h=ground(cf.X,cf.Z)if h then m:PivotTo(m:GetPivot()+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end end
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do
  local pivot=m:GetPivot()local h=ground(pivot.X,pivot.Z)
  if h and h.Position.Y>6 then local cf,size=m:GetBoundingBox()m:PivotTo(pivot+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end
 end
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())runtime:SetAttribute("GrassRenderer","NativeTerrain")runtime:SetAttribute("GrassMotionEnabled",false)
 return report
end
return B
]============]).install()
workspace.ForestWorld:SetAttribute("UpgradeVersion",94)
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
require(runtime:WaitForChild("GardenWeather")).start(runtime,world)
require(runtime:WaitForChild("SeasonController")).start(runtime,world)
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
	for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do light.Enabled=Cycle.night(clock)>.015 light.Brightness=Cycle.night(clock)*1.25 end
	local strength = 2.8 + math.sin(time * 0.047) * 0.25 + math.sin(time * 0.023) * 0.15
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestGardenClient",[============[local Run=game:GetService("RunService")local Players=game:GetService("Players")local UIS=game:GetService("UserInputService")local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local world=workspace:WaitForChild("ForestWorld")
local localWorld=Instance.new("Folder")localWorld.Name="TreeWorldGardenEffects"localWorld.Parent=workspace
local rng=Random.new()local leaves={}local cap=UIS.TouchEnabled and 14 or 24
for i=1,cap do local p=Instance.new("Part")p.Name="FallingLeaf"p.Shape=Enum.PartType.Ball p.Size=Vector3.new(.23,.035,.43)p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=1 p.Parent=localWorld leaves[i]={part=p,birth=-100}end
local canopies={}local Collection=game:GetService("CollectionService")
local function tree(m)if m:IsA("Model")then canopies[m]=true end end
for _,m in ipairs(Collection:GetTagged("ForestTree"))do tree(m)end
Collection:GetInstanceAddedSignal("ForestTree"):Connect(tree)Collection:GetInstanceRemovedSignal("ForestTree"):Connect(function(m)canopies[m]=nil end)
local soundFolder=runtime:WaitForChild("GardenSounds")
local function sound(name,parent,volume)local s=soundFolder[name]:Clone()s.Parent=parent s.Volume=volume or s.Volume return s end
local birds=sound("Forest",game:GetService("SoundService"),.27)birds:Play()
local wind=sound("Wind",game:GetService("SoundService"),.12)wind:Play()
local river=sound("River",game:GetService("SoundService"),0)river:Play()
local rain=sound("Rain",game:GetService("SoundService"),0)rain:Play()
local foot local footChar local footTime=0
local rainRoot=Instance.new("Part")rainRoot.Name="LocalRainCeiling"rainRoot.Size=Vector3.new(35,.1,35)rainRoot.Anchored=true rainRoot.Transparency=1 rainRoot.CanCollide=false rainRoot.CanTouch=false rainRoot.CanQuery=false rainRoot.Parent=localWorld
local emitter=Instance.new("ParticleEmitter")emitter.Name="GentleRain"emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"emitter.Rate=0 emitter.Lifetime=NumberRange.new(.45,.65)emitter.Speed=NumberRange.new(32,40)emitter.EmissionDirection=Enum.NormalId.Bottom emitter.Size=NumberSequence.new(.045)emitter.Color=ColorSequence.new(Color3.fromRGB(191,224,228))emitter.Transparency=NumberSequence.new(.65)emitter.Acceleration=Vector3.new(4,-18,1)emitter.SpreadAngle=Vector2.new(4,4)emitter.Parent=rainRoot
local WindLines=require(runtime.WindEffects:WaitForChild("WindLines"))
WindLines:Init({Direction=workspace.GlobalWind.Unit,Speed=7,Lifetime=1.5,SpawnRate=UIS.TouchEnabled and 1 or 3})
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.RespectCanCollide=true
local scan,elapsed,spawnClock,leafIndex=0,0,0,0 local nearby={}
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt scan+=dt spawnClock+=dt if elapsed<1/18 then return end local step=elapsed elapsed=0
 local camera=workspace.CurrentCamera if not camera then return end local pos=camera.CFrame.Position local now=workspace:GetServerTimeNow()
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
 if scan>1.2 then
  scan=0 table.clear(nearby)
  for m in pairs(canopies)do if m.Parent then local p=m:GetAttribute("ActualRootPoint")or m:GetPivot().Position if(Vector2.new(p.X-pos.X,p.Z-pos.Z)).Magnitude<24 then nearby[#nearby+1]=p end end end
  if #nearby>8 then while #nearby>8 do table.remove(nearby)end end
  if root then
   ray.FilterDescendantsInstances={world.Amenities,workspace.Terrain,world.Decor}
   local roof=workspace:Raycast(root.Position+Vector3.yAxis*2,Vector3.yAxis*24,ray)
   local raining=runtime:GetAttribute("Raining")
   emitter.Rate=raining and not roof and(UIS.TouchEnabled and 65 or 100)or 0
   Tween:Create(rain,TweenInfo.new(1),{Volume=raining and(roof and .035 or .14)or 0}):Play()
   local riverX=require(runtime.Scene).riverX(root.Position.Z)local riverWidth=require(runtime.Scene).riverWidth(root.Position.Z)
   local proximity=math.clamp(1-(math.abs(root.Position.X-riverX)-riverWidth)/40,0,1)
   local lake=world:GetAttribute("CentralLake")
   if lake then local r=math.sqrt(((root.Position.X-lake.X)/76)^2+((root.Position.Z-lake.Z)/52)^2)proximity=math.max(proximity,math.clamp((1.35-r)*2,0,1))end
   if math.abs(root.Position.Z)>295 then proximity=0 end
   Tween:Create(river,TweenInfo.new(1),{Volume=.24*proximity}):Play()
  end
 end
 rainRoot.CFrame=CFrame.new((root and root.Position or pos)+Vector3.yAxis*18)
 if spawnClock>.45 and #nearby>0 and runtime:GetAttribute("SeasonName")~="Inverno"then
  spawnClock=0 leafIndex=leafIndex%cap+1 local e=leaves[leafIndex]local p=nearby[rng:NextInteger(1,#nearby)]
  local focus=root and root.Position or pos
  local x=math.clamp(p.X,focus.X-10,focus.X+10)+rng:NextNumber(-3,3)local z=math.clamp(p.Z,focus.Z-10,focus.Z+10)+rng:NextNumber(-3,3)
  e.start=Vector3.new(x,focus.Y+rng:NextNumber(6,9),z)e.birth=now e.phase=rng:NextNumber(0,6.28)e.life=6

  e.part.Color=runtime:GetAttribute("SeasonName")=="Outono"and Color3.fromRGB(181,134,66)or Color3.fromRGB(128,153,93)e.part.Transparency=.12
 end
 for _,e in ipairs(leaves)do local age=now-e.birth if age< (e.life or 0)then local drift=Vector3.new(age*.25+math.sin(age*1.6+e.phase)*.4,-age*1.35,math.cos(age*1.2+e.phase)*.3)
  e.part.CFrame=CFrame.new(e.start+drift)*CFrame.Angles(age*.7,e.phase+age*.9,.3*math.sin(age*2))e.part.Transparency=.12+.88*math.clamp((age-e.life+1.5)/1.5,0,1)
 else e.part.Transparency=1 end end
 if c~=footChar then if foot then foot:Destroy()end footChar=c foot=root and sound("GrassStep",root,.055)or nil if foot then foot.Looped=false end end
 if h and root and foot then
  local default=root:FindFirstChild("Running")if default then default.Volume=0 end
  local moving=h.MoveDirection.Magnitude>.1 and h.FloorMaterial~=Enum.Material.Air and h.Health>0 and not h.Sit and h:GetState()~=Enum.HumanoidStateType.Swimming
  local material=h.FloorMaterial local name=(material==Enum.Material.Wood or material==Enum.Material.WoodPlanks)and"WoodStep"or(material==Enum.Material.Grass or material==Enum.Material.LeafyGrass or material==Enum.Material.Ground or material==Enum.Material.Mud)and"GrassStep"or"StoneStep"
  local id=soundFolder[name].SoundId if foot.SoundId~=id then foot:Stop()foot.SoundId=id end foot.Looped=name~="GrassStep"
  foot.PlaybackSpeed=math.clamp(root.AssemblyLinearVelocity.Magnitude/14,.7,1.25)
  footTime+=step
  if moving then if foot.Looped then if not foot.IsPlaying then foot:Play()end elseif footTime>.42/foot.PlaybackSpeed then footTime=0 foot:Play()end elseif foot.IsPlaying then foot:Stop()end
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
local lights={}local function added(light)if light:IsA("Light")then lights[light]=true end end
for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do added(light)end
local addConnection=Collection:GetInstanceAddedSignal("ForestNightLight"):Connect(added)
local removeConnection=Collection:GetInstanceRemovedSignal("ForestNightLight"):Connect(function(light)lights[light]=nil end)
local elapsed=0
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt if elapsed<1/10 then return end elapsed=0
 local epoch=runtime:GetAttribute("CycleEpoch")if not epoch then return end
 local clock=Cycle.clock(workspace:GetServerTimeNow(),epoch)Visuals.clock(clock)
 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
 if root then Seasons.visual(root.Position,Cycle.daylight(clock))end
 local origin=runtime:GetAttribute("RuinOrigin")
 if root and origin then
  local closest=origin local distance=(root.Position-origin).Magnitude
  local json=runtime:GetAttribute("RuinOrigins")
  if json then for _,v in ipairs(game:GetService("HttpService"):JSONDecode(json))do local p=Vector3.new(unpack(v))local d=(root.Position-p).Magnitude if d<distance then closest=p distance=d end end end
  Mood.apply(root.Position,closest,"Neblina",Cycle.daylight(clock))
 end
 local night=Cycle.night(clock)
 for light in pairs(lights)do if light.Parent then light.Enabled=night>.015 light.Brightness=night*1.25 else lights[light]=nil end end
end)
script.Destroying:Connect(function()connection:Disconnect()addConnection:Disconnect()removeConnection:Disconnect()table.clear(lights)end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestWaterClient",[============[local Run=game:GetService("RunService")local Collection=game:GetService("CollectionService")local UIS=game:GetService("UserInputService")
local textures={}local nearby={}local scan=0 local elapsed=0 local cap=UIS.TouchEnabled and 32 or 64
local function add(texture)if texture:IsA("Texture")then textures[texture]=true end end
for _,t in ipairs(Collection:GetTagged("TreeWorldWaterTexture"))do add(t)end
Collection:GetInstanceAddedSignal("TreeWorldWaterTexture"):Connect(add)
Collection:GetInstanceRemovedSignal("TreeWorldWaterTexture"):Connect(function(t)textures[t]=nil end)
Run.Heartbeat:Connect(function(dt)
 scan+=dt elapsed+=dt if elapsed<.1 then return end elapsed=0
 local camera=workspace.CurrentCamera if not camera then return end local pos=camera.CFrame.Position
 if scan>1 then scan=0 table.clear(nearby)
  for t in pairs(textures)do if t.Parent and t.Parent:IsA("BasePart")and(t.Parent.Position-pos).Magnitude<80 then nearby[#nearby+1]=t end end
  table.sort(nearby,function(a,b)return(a.Parent.Position-pos).Magnitude<(b.Parent.Position-pos).Magnitude end)
  while #nearby>cap do table.remove(nearby)end
 end
 local phase=(workspace:GetServerTimeNow()*.32)%14
 for _,t in ipairs(nearby)do if t.Parent then t.OffsetStudsU=(t.Parent.Position.X+phase)%14 t.OffsetStudsV=(t.Parent.Position.Z+phase*.48)%14 end end
end)
]============])
run(game.ServerScriptService.ForestServer.Source)
reports.tests=run([============[local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
assert(world:GetAttribute("UpgradeVersion")==94)
local report={trees=0,plants=0,actualRootProbes=0,walkProbes=0,teaTables=0,teaCups=0,ruins=4,audio=0}
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestGrassClient")and not runtime:FindFirstChild("SkinnedGrassTemplates"),"Skeletal spike grass remains")
assert(runtime:GetAttribute("GrassRenderer")=="NativeTerrain")
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray))end
for _,entry in ipairs(runtime.ActualRootContacts:GetChildren())do local m=entry.Value if m and m:IsDescendantOf(world)then local cf=m:GetPivot()
 for _,point in ipairs(entry:GetChildren())do local p=entry:GetAttribute("CoordinateSpace")=="World"and point.Value or cf:PointToWorldSpace(point.Value)local h=ground(p.X,p.Z)assert(p.Y-h.Position.Y<-.12,"Visible root remains above the soil: "..m.Name)report.actualRootProbes+=1 end
 if m.Parent==world.Decor.Trees then report.trees+=1 else report.plants+=1 end end end
assert(report.trees>300 and report.plants>700 and report.actualRootProbes>1000)
for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={bridge}rp.RespectCanCollide=true
 for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")then assert(p.Transparency==0 and p.CanCollide and p.CanQuery,"Bridge has an invisible or non-solid part")end end
 local nodes=game:GetService("HttpService"):JSONDecode(bridge:GetAttribute("WalkNodes"))
 for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
  for _,t in ipairs({0,.5,.95})do local center=a:Lerp(b,t)
   for _,offset in ipairs({-4.4,-2,0,2,4.4})do local p=center+Vector3.zAxis*offset local hit=assert(workspace:Raycast(p+Vector3.yAxis*.65,Vector3.yAxis*-1.5,rp),"Bridge has a walking gap")assert(hit.Instance.Name=="SolidDeckPlank"or hit.Instance.Name=="BankApron")assert(math.abs(hit.Position.Y-center.Y)<.18,"Bridge collision disagrees with visible deck")report.walkProbes+=1 end
  end
 end
 for _,i in ipairs({1,#nodes})do local p=Vector3.new(unpack(nodes[i]))assert(math.abs(ground(p.X,p.Z).Position.Y-p.Y)<.2,"Bridge shifted off the bank")end
end
assert(not world.Amenities.ForestRuins:FindFirstChild("EntrancePath"))
local positions={world.Amenities.ForestRuins:GetAttribute("Origin")}
for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do positions[#positions+1]=m:GetAttribute("Origin")end
for i=1,#positions do for j=i+1,#positions do assert((Vector2.new(positions[i].X,positions[i].Z)-Vector2.new(positions[j].X,positions[j].Z)).Magnitude>160,"Ruins still overlap")end end
for _,click in ipairs(C:GetTagged("TreeWorldCupClick"))do if click:IsDescendantOf(world)then assert(click:IsA("ClickDetector")and click.MaxActivationDistance==9)report.teaCups+=1 end end
for _,m in ipairs(world:GetDescendants())do if m:IsA("Model")and m.Name=="AntiqueTeaTable"then local cf,size=m:GetBoundingBox()assert(size.X<6 and size.Z<6 and size.Y<4,"Tea table still enormous")report.teaTables+=1 end
 assert(m.Name~="MoodPrompt"and m.Name~="ServeTea","Old tea interaction or mood selection remains")
end assert(report.teaTables==4 and report.teaCups==16)
for _,seat in ipairs(C:GetTagged("RuinSeat"))do if seat:IsDescendantOf(world)and seat.Name=="TeaSeat"then
 local table=seat.Parent.Parent.AntiqueTeaTable local center=table:GetPivot().Position local direction=Vector3.new(center.X-seat.Position.X,0,center.Z-seat.Position.Z).Unit
 assert(seat.CFrame.LookVector:Dot(direction)>.95,"Compact tea chair faces away from table")
end end
local desc=Instance.new("HumanoidDescription")local actor=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R6)desc:Destroy()actor.Name="TeaTest"actor.Parent=workspace
local click=C:GetTagged("TreeWorldCupClick")[1]local cupPoint=click.Parent:GetPivot().Position actor:PivotTo(CFrame.new(cupPoint+Vector3.yAxis*2))actor.HumanoidRootPart.Anchored=true
local bag=Instance.new("Backpack")bag.Parent=game.ServerStorage local mock={Character=actor,Backpack=bag,UserId=1092}
function mock:FindFirstChildOfClass(name)if name=="Backpack"then return bag end end
local service=require(runtime.RuinController).start(runtime,world)
assert(service.serve(mock,click,false),"Direct cup click failed to serve")assert(actor:FindFirstChildOfClass("Tool"),"Clicked cup did not reach the hand")
actor:Destroy()bag:Destroy()report.directCupServe=true
assert(not runtime:FindFirstChild("RuinInteraction")and not game.StarterPlayer.StarterPlayerScripts.ForestRuinClient.Source:find('TextLabel',1,true))
local Mood=require(runtime.RuinMood)local origin=positions[1]for _=1,60 do Mood.apply(origin,origin,"Neblina",1)end
assert(game.Lighting.ForestAtmosphere.Density<.35 and game.Lighting.ForestAtmosphere.Haze<1.3,"Fog accumulates")Mood.apply(origin+Vector3.xAxis*200,origin,"Neblina",1)assert(math.abs(game.Lighting.ForestAtmosphere.Density-.24)<.001)
for _,s in ipairs(runtime.GardenSounds:GetChildren())do game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>0,"Missing forest audio")report.audio+=1 end
assert(game.StarterPlayer.StarterPlayerScripts.ForestGardenClient.Source:find('root,.055',1,true))
local water=RaycastParams.new()water.FilterType=Enum.RaycastFilterType.Include water.FilterDescendantsInstances={workspace.Terrain}
local Scene=require(runtime.Scene)for z=-288,288,8 do local h=assert(workspace:Raycast(Vector3.new(Scene.riverX(z),200,z),Vector3.yAxis*-300,water))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.1,"River altered by repairs")end
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.StarterGui.TreeWorldMenu})do for _,s in ipairs(parent:GetChildren())do if s:IsA("LuaSourceContainer")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,v=pcall(require,m)m:Destroy()assert(ok,tostring(v))compiled+=1 end end end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,v=pcall(require,s)assert(ok,tostring(v))compiled+=1 end end
report.compiled=compiled report.noTeaPopups=true report.fogStable=true report.nativeGrassRequested=true report.parts=0 report.pbr=0
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then report.parts+=1 end if p:IsA("SurfaceAppearance")then report.pbr+=1 end assert(not p:IsA("LuaSourceContainer"))end
assert(report.parts<12500 and report.pbr>2500,"Forest loss or mobile geometry increase")
assert(world:GetAttribute("AnimalsEnabled")==false and not runtime:FindFirstChild("CuteAnimalTemplates") and not runtime:FindFirstChild("WildlifeTemplates"))
assert(not world:FindFirstChild("Wildlife") and not world.Amenities:FindFirstChild("CuteAnimalRoutes"))
assert(not game.StarterPlayer.StarterPlayerScripts.ForestGardenClient.Source:find("CuteAnimal",1,true))
local lake=assert(world:GetAttribute("CentralLake"))
local lakePoints=0
for dx=-48,48,12 do for dz=-24,24,12 do
 local h=assert(workspace:Raycast(Vector3.new(lake.X+dx,200,lake.Z+dz),Vector3.yAxis*-300,water))
 assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.12,"Central lake contains dry holes")lakePoints+=1
end end
local tiles=0
for _,p in ipairs(world.Amenities.RiversideGarden.CartoonWater:GetChildren())do if p:IsA("MeshPart")then
 assert(p.MeshId=="rbxassetid://6833048037" and p:GetAttribute("SourceAssetId")==6833503207)
 assert(not p.CanCollide and not p.CanQuery and math.abs(p.Position.Y-6.14)<.001 and p.Size.Y<.04,"Water overlay blocks swimming or has stacked layers")
 for _,dx in ipairs({-6,0,6})do for _,dz in ipairs({-6,0,6})do local h=assert(workspace:Raycast(Vector3.new(p.Position.X+dx,200,p.Position.Z+dz),Vector3.yAxis*-300,water))assert(h.Material==Enum.Material.Water,"Water tile crosses the shore")end end
 tiles+=1
end end
assert(tiles>150 and tiles<1000,"Water geometry budget exceeded")
local lampCount=0
for _,m in ipairs(world.Amenities.Lanterns:GetChildren())do
 assert(m:GetAttribute("SourceAssetId")==11324928349,"Incorrect lamp asset")local pole
 for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")and p.MeshId=="rbxassetid://11161434042"then pole=p end end
 assert(pole)local bottom=pole.Position.Y-pole.Size.Y*.5 local g=ground(pole.Position.X,pole.Position.Z)
 assert(bottom<g.Position.Y+.1 and bottom>g.Position.Y-1.5,"Lamp floats")lampCount+=1
end
assert(lampCount>=18)
local stoneCount=0 local stoneProbes=0
for _,m in ipairs(world.Amenities.RiversideGarden.StreamSteppingStones:GetChildren())do
 local center=m:GetAttribute("Centre")local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={m}rp.RespectCanCollide=true
 for _,off in ipairs({Vector3.new(.3,0,.3),Vector3.new(-1.4,0,.4),Vector3.new(.4,0,-1.4)})do local h=assert(workspace:Raycast(center+off+Vector3.yAxis*1,Vector3.yAxis*-2,rp),"Faceted stone has missing walk surface")assert(h.Instance.Name=="PaleStoneTop"and math.abs(h.Position.Y-center.Y)<.08)stoneProbes+=1 end
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then assert(p.Transparency==0 and p.CanCollide,"Stone side invisible or not solid")end end
 stoneCount+=1
end
assert(stoneCount>5)
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then
 for _,n in ipairs({p.CFrame:GetComponents()})do assert(n==n and math.abs(n)<5000,"Invalid world frame: "..p:GetFullName())end
end end
local stair=world.Amenities.WeatheredHillStair local _,stairSize=stair:GetBoundingBox()assert(stairSize.Y<100,"Malformed hill stair survives")
local flowers=0 for _,m in ipairs(world.Decor.Plants:GetChildren())do if m:GetAttribute("LakeFlower")then flowers+=1 local _,size=m:GetBoundingBox()assert(size.Y<1.3,"Lakeside flower too tall")end end assert(flowers>=40)
local Scene=require(runtime.Scene)
for _,m in ipairs(world.Amenities.CutTrunks:GetChildren())do local cf,size=m:GetBoundingBox()assert(Scene.pathDistance(cf.X,cf.Z)>=8+math.min(11,math.max(size.X,size.Z)*.5),"Stump blocks trail")end
report.lakeWaterProbes=lakePoints report.cartoonWaterTiles=tiles report.exactLampPosts=lampCount report.facetedStones=stoneCount report.stoneWalkProbes=stoneProbes report.lowLakeFlowers=flowers report.noAnimals=true report.finiteWorldGeometry=true
return report
]============])
runtime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,expectedVersion=94,reports=reports}
