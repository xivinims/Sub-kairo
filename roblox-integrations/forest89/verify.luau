assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==89,"Saved version mismatch")
local function run(code)
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage local value=require(m)()m:Destroy()return value
end
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
return{ok=true,version=game.PlaceVersion,tests=tests,forestTests=forestTests}
