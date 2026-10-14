local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local folder=world.Amenities.RiversideGarden
assert(not world:FindFirstChild("OwnerNPC")and not runtime:FindFirstChild("NPCController"))
local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
local report={walkProbes=0,pilings=0,animals=0,audio=0,teaSeatsFaceTable=0}
for _,p in ipairs(folder:GetDescendants())do if p.Name=="GroundedPiling"then local g=p:GetAttribute("GroundPoint")local hit=assert(workspace:Raycast(g+Vector3.yAxis*20,Vector3.yAxis*-50,rp))assert(p.Position.Y-p.Size.Y*.5<=hit.Position.Y+.01,"Floating cottage piling")report.pilings+=1 end end
local house=folder.WaterCottage local o=house:GetAttribute("Origin")assert(o.Y>workspace.Terrain.WaterWaveSize+6+3)
for _,x in ipairs({-18,0,18})do for _,z in ipairs({-14,0,14})do local h=assert(workspace:Raycast(Vector3.new(o.X+x,200,o.Z+z),Vector3.new(0,-300,0),rp))assert(h.Position.Y<6,"Cottage planted on dry hillside")end end
local walk=folder.LakesideBoardwalk local nodes=game:GetService("HttpService"):JSONDecode(walk:GetAttribute("WalkNodes"))
local col=RaycastParams.new()col.FilterType=Enum.RaycastFilterType.Include col.FilterDescendantsInstances={walk}col.RespectCanCollide=true
for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))assert(math.abs((b-a).Unit.Y)<.45,"Boardwalk too steep")
 for _,t in ipairs({0,.5})do local p=a:Lerp(b,t)local h=assert(workspace:Raycast(p+Vector3.yAxis*2,Vector3.yAxis*-4,col),"Boardwalk collision missing")assert(math.abs(h.Position.Y-p.Y)<.16,"Boardwalk height gap")report.walkProbes+=1 end
end
local last=Vector3.new(unpack(nodes[#nodes]))local bank=assert(workspace:Raycast(last+Vector3.yAxis*20,Vector3.yAxis*-40,rp))assert(math.abs(bank.Position.Y-last.Y)<.5)
col.FilterDescendantsInstances={house}
assert(workspace:Raycast(o+Vector3.new(0,1,-16),Vector3.yAxis*-2,col),"Porch has no floor")
assert(not workspace:Raycast(o+Vector3.new(0,5,-15),Vector3.zAxis*8,col),"Cottage entrance blocked")
for _,route in ipairs(world.Amenities.CuteAnimalRoutes:GetChildren())do
 local template=assert(runtime.CuteAnimalTemplates:FindFirstChild(route:GetAttribute("Species")))assert(template:GetAttribute("SourceAssetId")==77173958514594)
 for _,p in ipairs(game:GetService("HttpService"):JSONDecode(route.Value))do local v=Vector3.new(unpack(p))local h=assert(workspace:Raycast(v+Vector3.yAxis*20,Vector3.yAxis*-40,rp))assert(h.Position.Y>6 and math.abs(h.Position.Y-v.Y)<.1,"Animal floats off its path")end report.animals+=1
end assert(report.animals>=4)
for _,s in ipairs(runtime.GardenSounds:GetChildren())do game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>0,"Ambience unavailable: "..s.Name)report.audio+=1 end
local weather=require(runtime.GardenWeather)
assert(not weather.raining(89.99,0)and weather.raining(90,0)and weather.raining(209.99,0)and not weather.raining(210,0)and weather.raining(570,0))
local a={Head={Position=Vector3.new(0,5,0)}}local b={Head={Position=Vector3.new(4,6,0)}}local target=weather.canopy(a,b)assert(target==Vector3.new(2,7.5,0))assert(weather.canopy(a)==Vector3.new(0,6.5,0))
local tool=runtime.UmbrellaTool assert(tool.RequiresHandle==false and tool.CanBeDropped==false and tool:GetAttribute("RainUmbrella")and tool:FindFirstChild("UmbrellaAnchor")and not tool:FindFirstChild("Handle"))
for _,p in ipairs(tool:GetChildren())do if p:IsA("BasePart")then assert(not p.Anchored and p.Massless and not p.CanCollide)end end
local C=game:GetService("CollectionService")for _,seat in ipairs(C:GetTagged("RuinSeat"))do if seat.Name=="TeaSeat"and seat:IsDescendantOf(world)then
 local center=seat.Parent.Parent.AntiqueTeaTable:GetPivot().Position local aim=Vector3.new(center.X-seat.Position.X,0,center.Z-seat.Position.Z).Unit assert(seat.CFrame.LookVector:Dot(aim)>.9)report.teaSeatsFaceTable+=1 end end
assert(report.teaSeatsFaceTable==16)
report.ownerNPCRemoved=true report.sharedUmbrellaMidpoint=true report.nativeFootsteps=true report.styledWater=true
runtime:SetAttribute("GardenTestMode",nil)
return report
