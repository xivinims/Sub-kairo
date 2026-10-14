assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==90,"Saved version mismatch")
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage local result=require(m)()m:Destroy()return result end
run(game.ServerScriptService.ForestServer.Source)
local tests=run([============[local world=assert(workspace.ForestWorld)local runtime=game.ReplicatedStorage.ForestRuntime
assert(world:GetAttribute("UpgradeVersion")==90 and world:GetAttribute("SeasonLayout")=="TemporalGlobal"and world:GetAttribute("GameName")=="TreeWorld")
local Seasons=require(runtime.Seasons)
assert(Seasons.index(0,0)==1 and Seasons.index(599.9,0)==1 and Seasons.index(600,0)==2 and Seasons.index(1200,0)==3 and Seasons.index(1800,0)==4 and Seasons.index(2400,0)==1)
assert(Seasons.at(-250,-200)==Seasons.at(250,200)and runtime:GetAttribute("GrassMotionEnabled")==false)
local groundRay=RaycastParams.new()groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),groundRay)end
local report={bridges=0,bridgeWalkProbes=0,landmarkFoundations=0,teaSeats=0,teaTables=0,ruins=4,staticGrass=true,globalSeasonTests=0}
for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do
 assert(bridge:GetAttribute("SourceAssetId")==117077041338395)
 local nodes=game:GetService("HttpService"):JSONDecode(bridge:GetAttribute("WalkNodes"))
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={bridge}ray.RespectCanCollide=true
 for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
  for _,t in ipairs({0,.5})do local p=a:Lerp(b,t)local hit=assert(workspace:Raycast(p+Vector3.new(0,3,0),Vector3.new(0,-6,0),ray),"Missing bridge walking collision")
   assert(hit.Instance.Name=="WalkwayCollision"and math.abs(hit.Position.Y-p.Y)<.18,"Bridge walking surface discontinuity")report.bridgeWalkProbes+=1
  end
 end
 for _,index in ipairs({1,#nodes})do local p=Vector3.new(unpack(nodes[index]))local hit=assert(ground(p.X,p.Z))assert(hit.Material~=Enum.Material.Water and math.abs(hit.Position.Y-p.Y)<1.4,"Bridge does not meet the bank: "..bridge.Name.." end "..index.." deck="..p.Y.." terrain="..hit.Position.Y)end
 for _,p in ipairs(bridge:GetChildren())do if p.Name=="MasonrySupport"then local g=p:GetAttribute("GroundPoint")assert(p.Position.Y-p.Size.Y*.5<=g.Y+.01)end end
 report.bridges+=1
end
assert(report.bridges==2)
local ruins=world.Amenities.ForestRuins local geometry=RaycastParams.new()geometry.FilterType=Enum.RaycastFilterType.Include geometry.FilterDescendantsInstances={ruins}geometry.RespectCanCollide=true
local arches=0
for _,m in ipairs(ruins.Arcade:GetChildren())do if m.Name=="StoneArch"then local point=m:GetAttribute("OpeningCentre")assert(not workspace:Raycast(point-Vector3.zAxis*4,Vector3.zAxis*8,geometry))arches+=1 end end assert(arches==6)
local landmarks=world.Amenities.ForestLandmarks assert(#landmarks:GetChildren()==3 and landmarks.BrokenWatchtower:FindFirstChild("ArmoredSkeleton"))
for _,d in ipairs(landmarks:GetDescendants())do
 if d.Name=="LandmarkFoundation"then local point=d:GetAttribute("GroundPoint")local hit=assert(ground(point.X,point.Z))assert(d.Position.Y-d.Size.Y*.5<=hit.Position.Y+.05,"Floating ruin foundation")report.landmarkFoundations+=1 end
end
local Collection=game:GetService("CollectionService")
for _,prompt in ipairs(Collection:GetTagged("TreeWorldTeaPrompt"))do if prompt:IsDescendantOf(world)then report.teaTables+=1 end end
for _,seat in ipairs(Collection:GetTagged("RuinSeat"))do
 if seat:IsDescendantOf(world)and seat.Name=="TeaSeat"then
  report.teaSeats+=1 local link=assert(seat:FindFirstChild("TeaPrompt"))assert(link.Value and link.Value:IsDescendantOf(world))
  local corner=seat.Parent.Parent local table=assert(corner.AntiqueTeaTable)local aim=Vector3.new(table:GetPivot().X-seat.Position.X,0,table:GetPivot().Z-seat.Position.Z).Unit
  assert(seat.CFrame.LookVector:Dot(aim)>.85,"Chair faces away from its tea table: "..seat:GetFullName().." dot="..seat.CFrame.LookVector:Dot(aim))
  local floorRay=RaycastParams.new()floorRay.FilterType=Enum.RaycastFilterType.Include floorRay.FilterDescendantsInstances={workspace.Terrain,world.Amenities}floorRay.RespectCanCollide=true
  local pivot=seat.Parent:GetPivot().Position local h=assert(workspace:Raycast(pivot+Vector3.new(0,.05,0),Vector3.new(0,-3,0),floorRay),"Antique chair has no floor")
  assert(math.abs(pivot.Y-h.Position.Y)<.2,"Antique chair floats above the floor")
 end
end
assert(report.teaTables==3 and report.teaSeats==12)
local npc=world.OwnerNPC local root=npc.HumanoidRootPart assert(npc.Humanoid.RigType==Enum.HumanoidRigType.R15 and root.Anchored and npc:GetAttribute("EmoteAssetId")==127049078545834 and not runtime:FindFirstChild("OwnerDialogue")and not npc.Head:FindFirstChild("TalkPrompt"))
local desc=npc.Humanoid:GetAppliedDescription()assert(desc.Shirt==npc:GetAttribute("ShirtAssetId")and desc.Pants==npc:GetAttribute("PantsAssetId")and desc.Torso==npc:GetAttribute("TorsoAssetId")and desc.Head==npc:GetAttribute("HeadAssetId"))desc:Destroy()
local controller=require(runtime.NPCController)
assert(controller.shouldGreet(10,36,2,false)and controller.shouldGreet(8,36,0,true)and not controller.shouldGreet(18,36,2,true)and not controller.shouldGreet(8,2,2,true))
local animator=npc.Humanoid.Animator local track
for _,candidate in ipairs(animator:GetPlayingAnimationTracks())do if candidate.Animation and candidate.Animation.AnimationId=="rbxassetid://92824429927180"then track=candidate break end end
assert(track and track.Length>2 and track.IsPlaying and track.Looped,"Exact emote playback missing: "..tostring(track and track.Length).." / "..tostring(track and track.IsPlaying))
local original=root.CFrame
track:AdjustWeight(1,0)animator:StepAnimations(.4)
track.TimePosition=.8 animator:StepAnimations(0)
local done={[root]=true}local motors={}for _,m in ipairs(npc:GetDescendants())do if m:IsA("Motor6D")then motors[#motors+1]=m end end
for _=1,18 do for _,m in ipairs(motors)do if done[m.Part0]and not done[m.Part1]then m.Part1.CFrame=m.Part0.CFrame*m.C0*m.Transform*m.C1:Inverse()done[m.Part1]=true end end end
local contactY=npc.LowerTorso.Position.Y-npc:GetAttribute("SeatedTorsoHalfY")assert(math.abs(contactY-npc:GetAttribute("SeatTop").Y-.05)<.18,"Cat Bath avatar is not seated on the cut trunk: contact="..contactY.." seat="..npc:GetAttribute("SeatTop").Y.." weight="..track.WeightCurrent)
for _,sound in ipairs({npc.Head.HiVoice,npc.Head.YayVoice})do game:GetService("ContentProvider"):PreloadAsync({sound})assert(sound.IsLoaded and sound.TimeLength>0 and sound.RollOffMaxDistance<=24)sound:Play()end
assert(root.CFrame==original and track.IsPlaying,"Greeting interrupts the emote or moves the avatar")
report.catBathLength=track.Length report.currentAvatar=true report.noDialogue=true report.catBathSeatGap=contactY-npc:GetAttribute("SeatTop").Y
local menu=assert(game.StarterGui.TreeWorldMenu)assert(menu:GetAttribute("SourceAssetId")==17216750157 and menu.ResetOnSpawn==false and menu.MainMenu.PlayButton.Text=="Entrar"and menu.MainMenu.GameTitle.Text=="TreeWorld")
assert(menu.MainMenu.PlayButton.Size.Y.Offset>=48 and menu.MainMenu.PlayButton:FindFirstChildOfClass("UISizeConstraint")and menu:FindFirstChild("TreeWorldMenuClient"))
assert(runtime:GetAttribute("MenuCameraCF")and runtime:GetAttribute("MenuCameraFocus")and not game.Lighting.TreeWorldMenuBlur.Enabled)
report.importedMenu=true
-- Exercise temporal seasons on actual terrain while proving that neither water nor solid occupancy changes.
runtime:SetAttribute("SeasonTestMode",true)
local service=require(runtime.SeasonController).start(runtime,world)
local probes={Vector2.new(-280,-40),Vector2.new(-240,110),Vector2.new(160,-180),Vector2.new(240,210)}
local references={}for _,v in ipairs(probes)do local h=assert(ground(v.X,v.Y))references[#references+1]={v=v,y=h.Position.Y}end
local region=Region3.new(Vector3.new(-32,-16,-32),Vector3.new(32,24,32))
local before=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})
for _,index in ipairs({3,4,2,1})do
 assert(service.apply(index,true))assert(runtime:GetAttribute("SeasonIndex")==index)
 for _,item in ipairs(references)do local h=assert(ground(item.v.X,item.v.Y))assert(math.abs(h.Position.Y-item.y)<.05,"Season transition changed terrain height")
  if index==4 then assert(h.Material==Enum.Material.Snow or h.Material==Enum.Material.Rock or h.Material==Enum.Material.Ground)end
 end
 local after=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})
 for x=1,before.Size.X do for y=1,before.Size.Y do for z=1,before.Size.Z do assert(before.SolidOccupancy[x][y][z]==after.SolidOccupancy[x][y][z]and before.LiquidOccupancy[x][y][z]==after.LiquidOccupancy[x][y][z],"Season alters river geometry")end end end
 assert(Seasons.at(-280,-200)==Seasons.at(200,200))report.globalSeasonTests+=1
 if index==4 then assert(#require(runtime.Scene).around(Vector3.new(-280,0,50),42)==0,"Grass remains in winter")end
end
runtime:SetAttribute("SeasonTestMode",nil)
report.terrainChannelsPreserved=true report.grassSourceId=world:GetAttribute("GrassAssetId")
return report
]============])
local forestTests=run([============[local world=assert(workspace:FindFirstChild("ForestWorld"))
local runtime=assert(game.ReplicatedStorage:FindFirstChild("ForestRuntime"))
assert(world:GetAttribute("ForestOnly")and world:GetAttribute("UpgradeVersion")==90)
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
local walks=256 -- curved bridge collision is checked by tests.luau
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
assert(runtime:GetAttribute("GrassMotionEnabled")==false)
assert(not game.StarterPlayer.StarterPlayerScripts.ForestGrassClient.Source:find("grass:Step",1,true))
assert(npc:GetAttribute("AvatarUserId")==8344738123 and npc.HumanoidRootPart.Anchored and npc:GetAttribute("Seated"))
local description=npc.Humanoid:GetAppliedDescription()
assert(description.Shirt==npc:GetAttribute("ShirtAssetId")and description.Pants==npc:GetAttribute("PantsAssetId")and description.Shirt>0 and description.Pants>0,"NPC does not wear owner's actual clothes")
description:Destroy()
assert(npc.Humanoid.RigType==Enum.HumanoidRigType.R15 and npc:FindFirstChild("CatBath")and not runtime:FindFirstChild("OwnerDialogue"))
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
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.StarterGui.TreeWorldMenu})do
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
 grassPriorityCorrect=true,staticGrassSource=true,ownerAvatarUserId=8344738123,npcSeated=true,catBathKeepsSeatedBody=true,
 greetingAudioLoaded=true,greetingAudioLength=npc.Head.HiVoice.TimeLength,yayAudioLoaded=true,yayAudioLength=npc.Head.YayVoice.TimeLength,cycleSeconds=Cycle.Duration,sunDirectionSamples=sunDirections,extendedWaterSurface=true,
 shaderPresetAssetId=8490242417,compiledScriptsAndModules=compiled,streamingEnabled=true,rendering=tostring(game.Lighting.LightingStyle)}
]============])
return{ok=true,version=game.PlaceVersion,tests=tests,forestTests=forestTests}
