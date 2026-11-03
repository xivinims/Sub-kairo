local B={}
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
