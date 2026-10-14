assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==96,"Saved version mismatch")
game:GetService("ServerStorage")
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage local f=require(m)local v=f()m:Destroy()return v end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)runtime:SetAttribute("ForestTestMode",true)
run(game.ServerScriptService.ForestServer.Source)
local tests=run([============[local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
assert(world:GetAttribute("UpgradeVersion")==96)
local report={trees=0,plants=0,actualRootProbes=0,walkProbes=0,teaTables=0,teaCups=0,ruins=4,audio=0}
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestGrassClient")and not runtime:FindFirstChild("SkinnedGrassTemplates"),"Skeletal spike grass remains")
assert(runtime:GetAttribute("GrassRenderer")=="NativeTerrain")
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray))end
for _,entry in ipairs(runtime.ActualRootContacts:GetChildren())do local m=entry.Value if m and m:IsDescendantOf(world)then local cf=m:GetPivot()
 for _,point in ipairs(entry:GetChildren())do local p=entry:GetAttribute("CoordinateSpace")=="World"and point.Value or cf:PointToWorldSpace(point.Value)local h=ground(p.X,p.Z)assert(p.Y-h.Position.Y<-.12,"Visible root remains above the soil: "..m.Name)report.actualRootProbes+=1 end
 if m.Parent==world.Decor.Trees then report.trees+=1 else report.plants+=1 end end end
assert(report.trees>=250 and report.plants>700 and report.actualRootProbes>1000)
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
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,v=pcall(require,m)m:Destroy()assert(ok,s:GetFullName()..": "..tostring(v))compiled+=1 end end end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,v=pcall(require,s)assert(ok,s:GetFullName()..": "..tostring(v))compiled+=1 end end
report.compiled=compiled report.noTeaPopups=true report.fogStable=true report.nativeGrassRequested=true report.parts=0 report.pbr=0
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then report.parts+=1 end if p:IsA("SurfaceAppearance")then report.pbr+=1 end assert(not p:IsA("LuaSourceContainer"))end
assert(report.parts<17000 and report.pbr>1400,"Forest loss or mobile geometry increase")
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
assert(not world.Amenities.RiversideGarden:FindFirstChild("CartoonWater")and not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestWaterClient"))
assert(math.abs(workspace.Terrain.WaterReflectance-.14)<.001)
for _,d in ipairs(world:GetDescendants())do assert(not d:IsA("ParticleEmitter")and not d:IsA("Beam")and not d:IsA("Trail"),"Suspended water/tea particles remain")end
local lampCount=0
for _,m in ipairs(world.Amenities.Lanterns:GetChildren())do
 assert(m:GetAttribute("SourceAssetId")==97893326625257,"Incorrect lamp asset")
 assert(m:GetAttribute("SourceFBXSHA256")=="02d7d43c417d633c908243ad34ca44599936876ce0a2b32926b7dc14f1012688","The user's FBX was not used")
 local mesh=assert(m:FindFirstChildWhichIsA("MeshPart",true))
 assert(mesh.MeshId~="rbxassetid://11161434042","Old post mesh remains")
 local cf,size=m:GetBoundingBox()local bottom=cf.Y-size.Y*.5 local anchor=m:GetAttribute("GroundPoint")local g=ground(anchor.X,anchor.Z)
 assert(math.abs(size.Y-10.5)<.05,"Incorrect post scale or orientation")
 assert(bottom<g.Position.Y+.1 and bottom>g.Position.Y-1.5,"Lamp floats")
 local light=assert(m:FindFirstChild("WarmLanternLight",true))assert(light:IsA("PointLight")and C:HasTag(light,"ForestNightLight"))lampCount+=1
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
assert(world:GetAttribute("TerrainOrganized")==true)
local rocks=0 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do local n=m.Name:lower()if n:find("rock",1,true)or n:find("boulder",1,true)then
 assert(m.Name=="PaleFacetedRock"and m:FindFirstChild("PaleStoneTop")and m:FindFirstChild("FacetedStoneSide"),"An old rock model remains")
 local cf,size=m:GetBoundingBox()assert(cf.Y-size.Y*.5<ground(cf.X,cf.Z).Position.Y+.1,"Accent rock floats")
 rocks+=1 end end assert(rocks>=12 and rocks<=24,"Incorrect accent rock density")
local house=world.Amenities.RiversideGarden.WaterCottage assert(house:GetAttribute("RebuiltEntrance"))
local O=house:GetAttribute("Origin")local path=game:GetService("HttpService"):JSONDecode(house:GetAttribute("EntryPath"))
local collision=RaycastParams.new()collision.FilterType=Enum.RaycastFilterType.Include collision.FilterDescendantsInstances={house}collision.RespectCanCollide=true
local entryProbes=0
for i=1,#path-1 do local a,b=Vector3.new(unpack(path[i])),Vector3.new(unpack(path[i+1]))
 for _,offset in ipairs({-1.0,0,1.0})do for _,height in ipairs({1.0,2.6,4.4})do
  local start=a+Vector3.new(0,height,offset)local hit=workspace:Raycast(start,b-a,collision)assert(not hit,"Cottage entrance blocked: "..(hit and hit.Instance.Name or ""))entryProbes+=1
 end end
end
local boardwalk=world.Amenities.RiversideGarden.LakesideBoardwalk local nodes=game:GetService("HttpService"):JSONDecode(boardwalk:GetAttribute("WalkNodes"))
local walkwayRay=RaycastParams.new()walkwayRay.FilterType=Enum.RaycastFilterType.Include walkwayRay.FilterDescendantsInstances={boardwalk}walkwayRay.RespectCanCollide=true
local walkwayProbes=0
for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
 for _,t in ipairs({0,.5,.95})do for _,offset in ipairs({-2.1,0,2.1})do local p=a:Lerp(b,t)+Vector3.zAxis*offset local h=assert(workspace:Raycast(p+Vector3.yAxis*.65,Vector3.yAxis*-1.5,walkwayRay),"Cottage walkway has a hole")assert(h.Instance.Name=="BoardwalkPlank"or h.Instance.Name=="BankApron")assert(math.abs(h.Position.Y-p.Y)<.18)walkwayProbes+=1 end end
end
local cf,size=house.CottageTeaCorner.AntiqueTeaTable:GetBoundingBox()assert(math.abs(cf.Y-size.Y*.5-(O.Y+.31))<.06,"Cottage tea table sank into floor")
local Player=require(runtime.MusicPlayer)local Config=require(runtime.MusicConfig)
assert(Config.parse("123456")==123456 and Config.parse("rbxassetid://123456")==123456 and not Config.parse("-1") and not Config.parse("12.5") and not Config.parse("abc") and not Config.parse(string.rep("9",20)))
for _,track in ipairs(Config.Tracks)do local s=Instance.new("Sound")s.SoundId="rbxassetid://"..track.id s.Parent=game:GetService("SoundService")game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>5,"Preset music unavailable: "..track.title)s:Destroy()end
local listeners={false,false}local a=Instance.new("Folder")a.Parent=game:GetService("SoundService")local b=Instance.new("Folder")b.Parent=game:GetService("SoundService")
local A=Player.new(a,function(state)listeners[1]=state end,function()end)local B=Player.new(b,function(state)listeners[2]=state end,function()end)
assert(A.play(Config.Tracks[1].id,"A")and B.play(Config.Tracks[4].id,"B"))assert(A.sound.Parent==a and B.sound.Parent==b and listeners[1]and listeners[2])
A.pause()assert(not listeners[1]and listeners[2]and not A.sound.IsPlaying and B.sound.IsPlaying)
A.stop()assert(B.sound.IsPlaying and listeners[2])B.stop()assert(not listeners[2])a:Destroy()b:Destroy()
local root=Instance.new("Folder")root.Parent=game.ServerStorage local UI=require(runtime.MusicUI).build(root,Config.Tracks)
assert(UI.panel.Scroll:IsA("ScrollingFrame")and UI.panel.Scroll.AutomaticCanvasSize==Enum.AutomaticSize.Y and UI.input:IsA("TextBox")and #UI.tracks==#Config.Tracks and not UI.panel.Visible)root:Destroy()
local radio=house.PersonalRadio assert(radio:GetAttribute("SourceAssetId")==15855506991)local meshes=0
for _,d in ipairs(radio:GetDescendants())do assert(not d:IsA("Sound")and not d:IsA("LuaSourceContainer"),"Shared original radio playback remains")if d:IsA("MeshPart")then meshes+=1 end end assert(meshes==8)
local service=require(runtime.MusicController).start(runtime,world)
local mock={Character=nil,attributes={}}function mock:SetAttribute(k,v)self.attributes[k]=v end
assert(not service.apply(mock,"123"))assert(service.apply(mock,true)and mock.attributes.ListeningToMusic==true)assert(service.apply(mock,false)and not mock.attributes.ListeningToMusic)
assert(runtime:GetAttribute("MusicPlayback")=="LocalOnly")assert(not game.ServerScriptService.ForestServer.Source:find("SoundId",1,true))
report.accentRocks=rocks report.cottageEntranceProbes=entryProbes report.cottageWalkwayProbes=walkwayProbes report.cottageTeaFloor=true report.radioMeshes=meshes report.musicPresets=#Config.Tracks report.personalPlaybackIsolation=true report.musicStatusValidation=true report.musicScrollUI=true
assert(world:GetAttribute("WorldExtent")==4096 and world:GetAttribute("PreviousTreesRemoved")==453)
for _,m in ipairs(world.Decor.Trees:GetChildren())do assert(m:GetAttribute("FreshReferenceTree")and(m:GetAttribute("SourceAssetId")==580221169 or m:GetAttribute("SourceAssetId")==6432306802),"Old tree model remains")end
for _,click in ipairs(C:GetTagged("TreeWorldCupClick"))do if click:IsDescendantOf(world)then local cup=click.Parent:FindFirstChild("UtahCup")assert(cup and cup.MeshId=="rbxassetid://10080681533")end end
assert(runtime.TeaCupTool.Handle:IsA("MeshPart")and runtime.TeaCupTool.Handle.MeshId=="rbxassetid://10080681533")
local extended=0 for _,v in ipairs({Vector2.new(1500,1200),Vector2.new(-1500,-1200),Vector2.new(1800,-1400),Vector2.new(-1700,1500)})do local h=ground(v.X,v.Y)assert(math.abs(h.Position.Y-20)<.15 and h.Normal.Y>.95)extended+=1 end
local lakes=game:GetService("HttpService"):JSONDecode(runtime:GetAttribute("LakeLocations"))for i=3,#lakes do local p=lakes[i]local h=assert(workspace:Raycast(Vector3.new(p[1],150,p[3]),Vector3.yAxis*-250,water))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.15)end
local Foliage=require(runtime.Foliage)local chunk=assert(Foliage.makeChunk(runtime,world,10,6))local streamedTrees=chunk:GetAttribute("TreeCount")assert(streamedTrees>0 and streamedTrees<=9)
for _,m in ipairs(chunk:GetChildren())do local p=m:GetAttribute("ActualRootPoint")assert(p and p.Y<ground(p.X,p.Z).Position.Y-.5)end chunk:Destroy()
local Mirror=require(runtime.RiverReflection)local actor=Instance.new("Model")actor.Parent=game.ServerStorage local head=Instance.new("Part")head.Name="Head"head.Size=Vector3.one head.CFrame=CFrame.new(0,9,0)head.Parent=actor
local parent=Instance.new("Folder")parent.Parent=game.ServerStorage local reflection=Mirror.create(actor,parent,workspace)
assert(reflection.surface.CanvasSize==Vector2.new(96,144)and reflection.view.ImageTransparency>=.88 and #reflection.pairs<=32)
reflection.update(Vector3.new(0,6,0),CFrame.new(0,12,16))assert(reflection.surface.Enabled and math.abs(reflection.patch.Position.Y-6.018)<.001 and reflection.camera.CFrame.Position.Y==0)
reflection.hide()assert(not reflection.surface.Enabled)reflection.destroy()actor:Destroy()parent:Destroy()
local gui=game.StarterGui.TreeWorldMenu assert(gui.Background.BackgroundColor3==Color3.fromRGB(8,8,8)and gui.MainMenu.PlayButton.TextColor3==Color3.fromRGB(245,245,245))
assert(runtime:GetAttribute("MenuCameraView")=="RuinSide"and(runtime:GetAttribute("MenuCameraCF").Position-runtime:GetAttribute("MenuCameraFocus")).X>50)
local uiRoot=Instance.new("Folder")uiRoot.Parent=game.ServerStorage local ui=require(runtime.MusicUI).build(uiRoot,Config.Tracks)assert(ui.panel.BackgroundColor3==Color3.fromRGB(12,12,12)and ui.panel.BackgroundTransparency>0 and ui.open.TextColor3.R==ui.open.TextColor3.G and ui.open.TextColor3.G==ui.open.TextColor3.B)uiRoot:Destroy()
assert(world:GetAttribute("PathMaterial")=="Ground")
report.nativeUtahTea=true report.noSuspendedWaterEffects=true report.weakAvatarReflection=true report.reflectionResolution={96,144}report.extendedGroundProbes=extended report.newLakes=#lakes-2 report.streamedChunkTrees=streamedTrees report.oldTreesCleared=true report.monochromeMenu=true
return report
]============])
runtime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)runtime:SetAttribute("ForestTestMode",nil)
return{ok=true,version=game.PlaceVersion,tests=tests,terrainSettingsBase64=buffer.tostring(game:GetService("EncodingService"):Base64Encode(game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Terrain})))}
