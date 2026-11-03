local RS=game.ReplicatedStorage
local world=assert(workspace:FindFirstChild('OveryardPhotoWorld'))
local runtime=assert(RS:FindFirstChild('LivingForest'))
local C=require(RS.PhotoWorldConfig)
assert(world:GetAttribute('RefinementVersion')=='living-forest-v12','Wrong forest revision')
assert(workspace.StreamingEnabled,'Streaming is required')
assert(not world:FindFirstChild('Monolith'),'Tilted dark district survived')
local count,trees,fruitTrees=0,0,0;local quadrants={0,0,0,0};local kinds={}
for _,p in ipairs(world:GetDescendants())do
 if p:IsA('Model')and p:GetAttribute('Tree')then
  trees+=1;local root=assert(p:GetAttribute('RootPosition'));local h,_,water=C.surface(root.X,root.Z)
  assert(not water and math.abs(root.Y-h)<.3,'Floating/submerged tree '..p.Name)
  assert(p.PrimaryPart and p.PrimaryPart.Name=='TrunkCollision','Tree collider missing')
  assert(p.PrimaryPart.Size.X<9,'Oversized trunk blocker')
  local q=(root.X>=0 and 1 or 0)+(root.Z>=0 and 2 or 0)+1;quadrants[q]+=1
  kinds[p:GetAttribute('TreeKind')]=true
  if p:GetAttribute('FruitKind')then fruitTrees+=1 end
 elseif p:IsA('BasePart')then
  count+=1
  assert(p.Name~='WeatheredRock'and p.Name~='LayeredSandstone'and p.Name~='FractureDebris'and p.Name~='WeatheredBench','Unwanted scenery survived')
  if not p:IsDescendantOf(world.Caio)then assert(p.Anchored,'Unanchored scenery')end
  if p.Transparency==1 and p.CanCollide then assert(p.Name=='TrunkCollision','Invisible blocker '..p:GetFullName())end
 end
end
assert(trees>4000 and count<35000,'Forest distribution/part budget '..trees..'/'..count)
for _,n in ipairs(quadrants)do assert(n>700,'Sparse map quadrant')end
for _,kind in ipairs({'PearlBlossom','RoseBlossom','EmeraldWillow','AncientOak','AmberMaple','CliffCrimson','LakeWillow','HighPine'})do assert(kinds[kind],'Tree variant missing '..kind)end
assert(fruitTrees>100,'Fruit grove distribution missing')
local hero=assert(world.Willow:FindFirstChild('RootedLakeWillow'));assert(hero:GetExtentsSize().Y<68,'Lake tree too large')
assert(math.abs(hero:GetAttribute('RootPosition').Y-25.9)<.1,'Lake tree root not on island')
local function terrainHeight(x,z)
 local low=Vector3.new(math.floor(x/4)*4,-24,math.floor(z/4)*4)
 local mats,occ=workspace.Terrain:ReadVoxels(Region3.new(low,low+Vector3.new(4,144,4)),4)
 for y=36,1,-1 do if occ[1][y][1]>0 and mats[1][y][1]~=Enum.Material.Water then return -24+(y-1)*4+occ[1][y][1]*4 end end
 error('Missing terrain')
end
local cliff=assert(world.LivingWoodland:FindFirstChild('CoastalCliffTree'))
local cp=cliff:GetAttribute('RootPosition');assert(math.abs(cp.Y-terrainHeight(cp.X,cp.Z))<3,'Cliff tree unsupported')
assert(math.abs(terrainHeight(12,0)-26)<1,'Island not grounded')
local pond=assert(world.LivingWoodland:FindFirstChild('HiddenForestPond'));assert(pond:GetAttribute('SourceAssetId')==119986768245480)
assert(#world.TrailLogs:GetChildren()==10,'Log replacements missing')
local npc=assert(world.Caio);local hum=npc.Humanoid
assert(hum.RigType==Enum.HumanoidRigType.R15,'NPC must be R15')
assert(npc:GetAttribute('RightLegAsset')==139607718,'Korblox right leg missing')
assert(npc.ExactAdventurerShirt.ShirtTemplate=='rbxassetid://134896954466438','Wrong original shirt')
assert(npc.ExactAdventurerPants.PantsTemplate=='rbxassetid://139899689316791','Wrong original pants')
assert(npc:GetAttribute('IdleReferenceResolved')and npc.IdleAnimation.AnimationId=='rbxassetid://105149630069175','Wrong Naoya idle')
local motors=0;for _,p in ipairs(npc:GetDescendants())do if p:IsA('Motor6D')then motors+=1 end end;assert(motors>=15,'R15 rig is disconnected')
assert(math.abs(npc.HumanoidRootPart.Position.Y-hum.HipHeight-npc.HumanoidRootPart.Size.Y/2-terrainHeight(C.NPC.X,C.NPC.Z))<2,'NPC floats')
assert(runtime.SafetyEvent:IsA('RemoteEvent')and runtime.ReportEvent:IsA('RemoteEvent'))
local data=require(runtime.DialogueData);for _,t in pairs(data.Locales)do assert(t.report and t.choices.report and t.choices.feedback)end
assert(require(runtime.FruitRules).Lifetime==420)
assert(require(runtime.VoiceManifest).report==123343535077049)
local inventory=assert(game.StarterGui:FindFirstChild('Custom Inventory'));assert(inventory:GetAttribute('SourceAssetId')==73852738603629)
assert(runtime.InventorySlotTemplate:FindFirstChild('toolAmount'))
local sps=game.StarterPlayer.StarterPlayerScripts
for _,name in ipairs({'OveryardCameraClient','PhotoEnvironmentClient','LivingNatureClient','ForestInventoryClient','CaioDialogueClient','ForestSafetyClient'})do assert(sps:FindFirstChild(name),'Missing client '..name)end
assert(game.StarterPlayer.CameraMode==Enum.CameraMode.Classic and game.StarterPlayer.CameraMaxZoomDistance>=24,'Camera locked in starter settings')
local bridges=0
for _,bridge in ipairs(world.Crossings:GetChildren())do
 local center=bridge:GetAttribute('Center');local axis=bridge:GetAttribute('Axis');local len=bridge:GetAttribute('Length')
 if center and axis and len then
  bridges+=1;local cf=CFrame.new(center)*CFrame.Angles(0,axis,0);local deck=assert(bridge:FindFirstChild('Deck'))
  assert(math.abs(deck.Position.Y+deck.Size.Y/2-center.Y)<.1,'Bridge grade')
  for sign=-1,1,2 do local p=(cf*CFrame.new(sign*(len/2+4),0,0)).Position;assert(math.abs(terrainHeight(p.X,p.Z)-center.Y)<2,'Floating bridge approach '..bridge.Name)end
 end
end
assert(bridges>=3,'Missing river crossings')
local walking=0;local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={world};overlap.RespectCanCollide=true
for _,s in ipairs(C.Paths)do
 local a,b=Vector2.new(s[1],s[2]),Vector2.new(s[3],s[4]);local steps=math.ceil((a-b).Magnitude/12)
 for i=0,steps do
  local q=a:Lerp(b,i/steps);local h,_,water=C.surface(q.X,q.Y)
  for _,bridge in ipairs(world.Crossings:GetChildren())do
   local center=bridge:GetAttribute('Center');if center then
    local point=(CFrame.new(center)*CFrame.Angles(0,bridge:GetAttribute('Axis'),0)):PointToObjectSpace(Vector3.new(q.X,center.Y,q.Y))
    if math.abs(point.X)<bridge:GetAttribute('Length')/2+7 and math.abs(point.Z)<6.5 then h=center.Y;water=nil end
   end
  end
  assert(not water,'Unbridged path '..q.X..','..q.Y)
  local hits=workspace:GetPartBoundsInBox(CFrame.new(q.X,h+3.8,q.Y),Vector3.new(2.2,4.7,2.2),overlap)
  assert(#hits==0,'Path blocked at '..q.X..','..q.Y..' by '..(hits[1]and hits[1]:GetFullName()or''));walking+=1
 end
end
local lakes={}
for _,lake in ipairs(C.Lakes)do
 local low=Vector3.new(math.floor((lake.x-lake.rx*1.25)/4)*4,4,math.floor((lake.z-lake.rz*1.25)/4)*4)
 local high=Vector3.new(math.ceil((lake.x+lake.rx*1.25)/4)*4,28,math.ceil((lake.z+lake.rz*1.25)/4)*4)
 local mats,occ=workspace.Terrain:ReadVoxels(Region3.new(low,high),4);local columns=0
 for x=1,#mats do for z=1,#mats[x][1]do for y=1,#mats[x]do if mats[x][y][z]==Enum.Material.Water and occ[x][y][z]>.1 then columns+=1;break end end end end
 assert(columns*16>15000,'Lake missing '..lake.id);lakes[lake.id]=columns*16
end
local first=game.ReplicatedFirst
assert(first:FindFirstChild('MapLoadingScreen')and first:FindFirstChild('OveryardLoadingView'),'Loading screen missing')
assert(first.OveryardLoadingView.Source:find('77442764802726',1,true),'Loading logo changed')
return {ok=true,placeVersion=game.PlaceVersion,trees=trees,fruitTrees=fruitTrees,parts=count,quadrants=quadrants,bridges=bridges,walkingChecks=walking,lakes=lakes,npcR15=true,npcMotors=motors,exactOutfit=true,naoyaIdle=true,reportVoice=true,extent=C.Extent}
