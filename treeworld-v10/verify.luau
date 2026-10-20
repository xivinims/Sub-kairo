local W=workspace
local RS=game:GetService('ReplicatedStorage')
local C=require(RS:WaitForChild('PhotoWorldConfig'))
local world=assert(W:FindFirstChild('OveryardPhotoWorld'),'New world missing')
assert(not W:FindFirstChild('ReferenceWorld'),'Old map survived')
assert(world:GetAttribute('Version')=='photo-reset-v10','Wrong version')
assert(W.StreamingEnabled,'Streaming must remain enabled')
local count,meshes,trees=0,0,0
local zones={}
for _,zone in ipairs(C.Zones)do
 local f=assert(world:FindFirstChild(zone.id),'Missing zone '..zone.id)
 local n=0
 for _,m in ipairs(f:GetDescendants())do
  if m:IsA('Model')and m:GetAttribute('Tree')then
   n+=1;trees+=1
   local root=m:GetAttribute('RootPosition');local h,_,water=C.surface(root.X,root.Z)
   assert(not water,'Tree underwater '..zone.id)
   assert(math.abs(root.Y-h)<.01,'Ungrounded tree '..zone.id)
   local collision=assert(m:FindFirstChild('TrunkCollision'))
   assert(collision.Size.X<13 and collision.Size.Z<13,'Oversized trunk collider')
  end
 end
 assert(n>=12,'Insufficient vegetation '..zone.id..' '..n);zones[zone.id]=n
end
for _,p in ipairs(world:GetDescendants())do
 if p:IsA('BasePart')then
  count+=1;assert(p.Anchored,'Unanchored scenery '..p:GetFullName())
  assert(p.Position.Y>-40 and p.Position.Y<240,'Geometry outside vertical bounds')
  if p:IsA('MeshPart')then meshes+=1;assert(string.find(p.MeshId,'rbxassetid://',1,true),'Mesh missing content')end
  if p.Transparency==1 and p.CanCollide then assert(p.Name=='TrunkCollision','Unexpected invisible blocker '..p:GetFullName())end
 elseif p:IsA('LuaSourceContainer')then error('Script inside new scenery')end
end
assert(count<5000,'Scene part budget exceeded: '..count)
assert(meshes>900 and trees>600,'Incomplete distribution')
local function terrainHeight(x,z)
 local low=Vector3.new(math.floor(x/4)*4,-24,math.floor(z/4)*4)
 local materials,occupancy=W.Terrain:ReadVoxels(Region3.new(low,low+Vector3.new(4,80,4)),4)
 for y=20,1,-1 do if occupancy[1][y][1]>0 and materials[1][y][1]~=Enum.Material.Water then return -24+(y-1)*4+occupancy[1][y][1]*4 end end
 error('Missing terrain at '..x..','..z)
end
local function walkHeight(x,z)
 local h,_,water=C.surface(x,z)
 for _,bridge in ipairs(world.Crossings:GetChildren())do
  local center=bridge:GetAttribute('Center');local axis=bridge:GetAttribute('Axis');local len=bridge:GetAttribute('Length')
  local p=(CFrame.new(center)*CFrame.Angles(0,axis,0)):PointToObjectSpace(Vector3.new(x,center.Y,z))
  if math.abs(p.X)<len/2+7 and math.abs(p.Z)<6.5 then return center.Y,false end
 end
 return h,water
end
local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={world};overlap.RespectCanCollide=true
local checks=0;local obstructions={}
for _,s in ipairs(C.Paths)do
 local a,b=Vector2.new(s[1],s[2]),Vector2.new(s[3],s[4]);local steps=math.ceil((a-b).Magnitude/8)
 for i=0,steps do
  local q=a:Lerp(b,i/steps);local h,water=walkHeight(q.X,q.Y)
  assert(not water,'Walking path crosses unbridged water at '..q.X..','..q.Y)
  local hits=W:GetPartBoundsInBox(CFrame.new(q.X,h+3.5,q.Y),Vector3.new(2.5,4.7,2.5),overlap)
  for _,hit in ipairs(hits)do table.insert(obstructions,hit:GetFullName()..' at '..math.floor(q.X)..','..math.floor(q.Y))end
  checks+=1
 end
end
assert(#obstructions==0,'Blocked walking routes: '..table.concat(obstructions,'; ',1,math.min(8,#obstructions)))
local spawn=assert(world:FindFirstChild('PhotoWorldSpawn'))
assert(math.abs(spawn.Position.Y-terrainHeight(spawn.Position.X,spawn.Position.Z))<2,'Spawn footing failed')
for _,bridge in ipairs(world.Crossings:GetChildren())do
 local center=bridge:GetAttribute('Center');local axis=bridge:GetAttribute('Axis');local len=bridge:GetAttribute('Length');local cf=CFrame.new(center)*CFrame.Angles(0,axis,0)
 local deck=assert(bridge:FindFirstChild('Deck'))
 assert(math.abs(deck.Position.Y+deck.Size.Y/2-center.Y)<.01,'Deck grade mismatch')
 for sign=-1,1,2 do
  local p=(cf*CFrame.new(sign*(len/2+4),0,0)).Position
  assert(math.abs(terrainHeight(p.X,p.Z)-center.Y)<1.1,'Floating bridge landing '..bridge.Name)
 end
end
for _,name in ipairs({'GrassPatch','TallGrassPatch','FernRosette','WhiteFlowerPatch','LavenderFlowerPatch','CloverPatch','AutumnUnderstory'})do
 local p=assert(RS.PhotoGroundcover:FindFirstChild(name),'Groundcover template missing');assert(not p.CanCollide,'Grass collider')
end
local first=game:GetService('ReplicatedFirst')
assert(first:FindFirstChild('MapLoadingScreen')and first:FindFirstChild('OveryardLoadingView'),'Loading screen missing')
assert(first.OveryardLoadingView.Source:find('77442764802726',1,true),'Wrong loading logo')
assert(game:GetService('StarterPlayer').StarterPlayerScripts:FindFirstChild('PhotoEnvironmentClient'),'Client not installed')
assert(not game:GetService('ServerScriptService'):FindFirstChild('PortalServer'),'Old map runtime survived')
return {ok=true,placeVersion=game.PlaceVersion,parts=count,meshes=meshes,trees=trees,zones=zones,walkingChecks=checks,bridges=2,streaming=W.StreamingEnabled,loadingLogo=77442764802726}
