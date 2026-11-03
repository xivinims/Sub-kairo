assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==94,"Saved version mismatch")
game:GetService("ServerStorage")
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage local f=require(m)local v=f()m:Destroy()return v end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)
run(game.ServerScriptService.ForestServer.Source)
local tests=run([============[local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
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
return{ok=true,version=game.PlaceVersion,tests=tests,terrainSettingsBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Terrain})))}
