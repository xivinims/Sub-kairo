local world=assert(workspace:FindFirstChild("ForestWorld"))local runtime=game.ReplicatedStorage.ForestRuntime
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
