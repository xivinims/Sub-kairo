-- Imported geometry is inspected and prepared in the publishing session, never in a live round.
local Builder={}
local PF=game:GetService("PathfindingService")
local specs={
 {name="DoomspireBrickbattle",id=109440846094241,label="Doomspire Brickbattle",scale=1},
 {name="JuggernautFightArena",id=137884561019081,label="Juggernaut Fight Arena",scale=1},
 {name="PirateBayIsland",id=127398591748883,label="Pirate Bay Island Cove",scale=1,maxParts=5500},
 {name="NaturalDisasterSurvival",id=92220535332787,label="Natural Disaster Survival",scale=1},
 {name="RocketArena",id=112232657511704,label="RocketArena",scale=2},
 {name="PiggySewers",id=7757562864,label="Piggy Sewers",scale=1,maxParts=12500,heavy=true,killerClearance=5.8,minKillerDistance=28},
 {name="PiggyMappleDonut",id=16440225099,label="Piggy Book 2 - Mapple Donut",scale=1.25,maxParts=9000,heavy=true,minKillerDistance=28},
}
local function route(a,b)
 local path=PF:CreatePath({AgentRadius=2.2,AgentHeight=5,AgentCanJump=true,AgentCanClimb=true,WaypointSpacing=5})
 local ok=pcall(function() path:ComputeAsync(a,b) end)
 local success=ok and path.Status==Enum.PathStatus.Success
 path:Destroy() return success
end
local function addPoint(folder,name,pos)
 local v=Instance.new("Vector3Value") v.Name=tostring(name) v.Value=pos v.Parent=folder
end
local function smallPart(parent,name,size,cf,color)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color
 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=parent
 return p
end
local function partCount(root)
 local n=0
 if root:IsA("BasePart") then n+=1 end
 for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end
 return n
end

local function chooseMapRoot(asset)
 assert(asset:IsA("Model"),"Loaded map asset must be a Model")
 local total=partCount(asset)
 local best=nil local bestParts=0
 for _,child in ipairs(asset:GetChildren()) do
  if child:IsA("Model") then
   local n=partCount(child)
   if n>bestParts then best=child bestParts=n end
  end
 end
 if best and bestParts>=30 and bestParts>=total*.65 then return best,bestParts,total end
 return asset,total,total
end

function Builder.build(load,sanitize,destination)
 local reports={}
 for _,spec in ipairs(specs) do
  local asset=load(spec.id)
  local map,rootParts,totalParts=chooseMapRoot(asset)
  if map~=asset then map.Parent=nil asset:Destroy() else map.Parent=nil end
  map.Name=spec.name
  map:SetAttribute("ImportedRootParts",rootParts)
  map:SetAttribute("ImportedTotalParts",totalParts)
  sanitize(map,true)
  map:ScaleTo(map:GetScale()*spec.scale)
  map:SetAttribute("RequestedScale",spec.scale)
  local cf,size=map:GetBoundingBox()
  map:PivotTo(map:GetPivot()+Vector3.new(2200-cf.X,40-(cf.Y-size.Y/2),-cf.Z))
  map.Parent=workspace
  cf,size=map:GetBoundingBox()
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances={map} params.RespectCanCollide=true
  local floors={} local lowest=math.huge local parts=0 local lightCount=0
  for _,p in ipairs(map:GetDescendants()) do
   if p:IsA("BasePart") then
    parts+=1 p.CanTouch=false
    if p.Size.Magnitude<5 or spec.heavy then p.CastShadow=false end
    if spec.heavy and p:IsA("MeshPart") then
     p.RenderFidelity=Enum.RenderFidelity.Performance
     p.CollisionFidelity=Enum.CollisionFidelity.Box
    end
    if p.CanCollide and p.Transparency<.98 and p.Size.X>=8 and p.Size.Z>=8 and p.CFrame.UpVector.Y>.95 and p.Size.Y<=math.max(12,math.min(p.Size.X,p.Size.Z)*.4) then
     local top=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0))
     table.insert(floors,{part=p,y=top.Y}) lowest=math.min(lowest,top.Y)
    end
   elseif p:IsA("Light") then lightCount+=1 p.Shadows=false p.Enabled=lightCount<=16 p.Brightness=math.min(p.Brightness,1.5)
   elseif p:IsA("Sound") then p.Playing=false
   elseif p:IsA("ParticleEmitter") then p.Rate=math.min(p.Rate,5)
   end
  end
  local partBudget=spec.maxParts or 5000
  assert(parts>30 and parts<=partBudget,"Map part budget exceeded: "..spec.name.." "..parts.." / "..partBudget)
  map:SetAttribute("PartBudget",partBudget)
  table.sort(floors,function(a,b) if a.y~=b.y then return a.y<b.y end return a.part.Size.X*a.part.Size.Z>b.part.Size.X*b.part.Size.Z end)
  local candidates={} local scans=0
  local directions={}
  for i=0,7 do local a=math.rad(i*45) table.insert(directions,Vector3.new(math.cos(a),0,math.sin(a))) end
  local function radialClear(g,radius)
   for _,dir in ipairs(directions) do
    for _,height in ipairs({1.6,3.2,4.8}) do
     if workspace:Raycast(g+Vector3.new(0,height,0),dir*radius,params) then return false end
    end
    local edge=g+dir*(radius*.82)
    local floorHit=workspace:Raycast(edge+Vector3.new(0,2,0),Vector3.new(0,-5,0),params)
    if not floorHit or floorHit.Normal.Y<.82 then return false end
   end
   return true
  end
  local footprintMargin=math.min(10,math.max(5,math.min(size.X,size.Z)*.025))
  local function insideFootprint(g,margin)
   local lp=cf:PointToObjectSpace(g)
   return math.abs(lp.X)<=size.X/2-margin and math.abs(lp.Z)<=size.Z/2-margin
  end
  local function candidate(pos)
   scans+=1
   local hit=workspace:Raycast(pos+Vector3.new(0,.5,0),Vector3.new(0,-4,0),params)
   if not hit or hit.Normal.Y<.92 then return end
   local g=hit.Position
   if not insideFootprint(g,footprintMargin) then return end
   if workspace:Raycast(g+Vector3.new(0,.25,0),Vector3.new(0,7.4,0),params) then return end
   if not radialClear(g,5.8) then return end
   local p=g+Vector3.new(0,3,0)
   for _,other in ipairs(candidates) do if (other-p).Magnitude<(spec.heavy and 7 or 10) then return end end
   table.insert(candidates,p)
  end
  for _,surface in ipairs(floors) do
   if surface.y<=lowest+32 and scans<1800 and #candidates<240 then
    local p=surface.part
    candidate(p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0)))
    for x=-p.Size.X/2+4,p.Size.X/2-4,(spec.heavy and 8 or 14) do
     for z=-p.Size.Z/2+4,p.Size.Z/2-4,(spec.heavy and 8 or 14) do
      if scans<1800 and #candidates<240 then candidate(p.CFrame:PointToWorldSpace(Vector3.new(x,p.Size.Y/2,z))) end
     end
    end
   end
  end
  assert(#candidates>=12,"Too few clear spawn positions in "..spec.name)
  table.sort(candidates,function(a,b)
   local sa=(Vector2.new(a.X-cf.X,a.Z-cf.Z)).Magnitude+(a.Y-lowest)*4
   local sb=(Vector2.new(b.X-cf.X,b.Z-cf.Z)).Magnitude+(b.Y-lowest)*4
   return sa<sb
  end)
  -- Sample points across the entire footprint instead of filling one corner of the map.
  local probes={candidates[1]} local used={[1]=true}
  while #probes<math.min(32,#candidates) do
   local chosen,best=nil,-1
   for i,p in ipairs(candidates) do if not used[i] then
    local nearest=math.huge for _,q in ipairs(probes) do nearest=math.min(nearest,(p-q).Magnitude) end
    if nearest>best then best=nearest chosen=i end
   end end
   if not chosen then break end used[chosen]=true table.insert(probes,candidates[chosen])
  end
  local selected={}
  for attempt=1,3 do
   local anchor=candidates[attempt] selected={anchor}
   for _,p in ipairs(probes) do if (p-anchor).Magnitude>4 and route(anchor,p) then table.insert(selected,p) end end
   if #selected>=12 then break end
  end
  assert(#selected>=9,"No connected playable region for "..spec.name)
  local start=selected[1] local far=nil local distance=0 local killerClearance=spec.killerClearance or 10
  local minimumKillerDistance=spec.minKillerDistance or math.clamp(math.min(size.X,size.Z)*.34,36,70)
  for _,p in ipairs(selected) do
   local d=(p-start).Magnitude
   local ground=p-Vector3.new(0,3,0)
   if d>distance and d>=minimumKillerDistance and insideFootprint(ground,footprintMargin+2) and radialClear(ground,killerClearance) and route(start,p) then far=p distance=d end
  end
  if not far then
   for _,p in ipairs(selected) do
    local d=(p-start).Magnitude
    local ground=p-Vector3.new(0,3,0)
    if d>distance and insideFootprint(ground,footprintMargin+2) and radialClear(ground,killerClearance) and route(start,p) then far=p distance=d end
   end
  end
  assert(far and distance>=math.min(24,minimumKillerDistance) and killerClearance>=5.8,"No safe pursuer spawn away from walls in "..spec.name)
  local points=Instance.new("Folder",map) points.Name="SafePoints"
  for i,p in ipairs(selected) do addPoint(points,i,p) end
  local arrivals=Instance.new("Folder",map) arrivals.Name="ArrivalSpawns"
  local arrivalsChosen={}
  local available={}
  for _,point in ipairs(candidates) do
   if (point-far).Magnitude>=math.max(18,math.min(36,distance*.45)) and route(start,point) then table.insert(available,point) end
   if #available>=24 then break end
  end
  while #arrivalsChosen<8 do
   local best,bestDistance=nil,-1
   for _,point in ipairs(available) do
    local nearest=(point-far).Magnitude
    for _,used in ipairs(arrivalsChosen) do nearest=math.min(nearest,(point-used).Magnitude) end
    if nearest>bestDistance then best=point bestDistance=nearest end
   end
   if not best or bestDistance<8 then break end
   table.insert(arrivalsChosen,best) addPoint(arrivals,#arrivalsChosen,best)
  end
  assert(#arrivalsChosen>=7,"Need seven separated survivor spawns in "..spec.name.." candidates="..#candidates.." connected="..#selected.." available="..#available.." picked="..#arrivalsChosen.." killerDistance="..distance)
  local objectiveSites=Instance.new("Folder",map) objectiveSites.Name="ObjectiveSites"
  local chosenSites={}
  local possible={}
  for _,point in ipairs(candidates) do
   local nearest=(point-far).Magnitude
   for _,used in ipairs(arrivalsChosen) do nearest=math.min(nearest,(point-used).Magnitude) end
   if nearest>=6 and route(start,point) then table.insert(possible,point) end
   if #possible>=20 then break end
  end
  while #chosenSites<11 do
   local best,bestDistance=nil,-1
   for _,point in ipairs(possible) do
    local nearest=(point-start).Magnitude
    for _,used in ipairs(chosenSites) do nearest=math.min(nearest,(point-used).Magnitude) end
    if nearest>bestDistance then best=point bestDistance=nearest end
   end
   if not best or bestDistance<8 then break end
   table.insert(chosenSites,best) addPoint(objectiveSites,#chosenSites,best-Vector3.new(0,3,0))
  end
  assert(#chosenSites>=9,"Need nine reachable objective sites in "..spec.name)
  map:SetAttribute("ObjectiveSitesValidated",true)
  map:SetAttribute("SpawnLayoutVersion",2)
  local toward=Vector3.new(cf.X-start.X,0,cf.Z-start.Z)
  if toward.Magnitude<1 then toward=Vector3.new(far.X-start.X,0,far.Z-start.Z) end
  toward=toward.Unit
  -- Spawn facing is data only. There is no entrance/door object in the arena.
  map:SetAttribute("SpawnFacing",toward)
  local bounds=Instance.new("Folder",map) bounds.Name="InvisibleBounds"
  local function barrier(name,partSize,localCF)
   local wall=Instance.new("Part")
   wall.Name=name wall.Size=partSize wall.CFrame=cf*localCF
   wall.Anchored=true wall.CanCollide=true wall.CanTouch=false wall.CanQuery=true
   wall.Transparency=1 wall.CastShadow=false wall.TopSurface=Enum.SurfaceType.Smooth wall.BottomSurface=Enum.SurfaceType.Smooth
   wall:SetAttribute("InvisibleBoundary",true) wall.Parent=bounds
   return wall
  end
  local wallThickness=6
  local wallHeight=math.max(64,size.Y+28)
  local wallY=(lowest-cf.Position.Y)+wallHeight/2-4
  barrier("LeftWall",Vector3.new(wallThickness,wallHeight,size.Z+wallThickness*2),CFrame.new(-size.X/2-wallThickness/2,wallY,0))
  barrier("RightWall",Vector3.new(wallThickness,wallHeight,size.Z+wallThickness*2),CFrame.new(size.X/2+wallThickness/2,wallY,0))
  barrier("FrontWall",Vector3.new(size.X+wallThickness*2,wallHeight,wallThickness),CFrame.new(0,wallY,-size.Z/2-wallThickness/2))
  barrier("BackWall",Vector3.new(size.X+wallThickness*2,wallHeight,wallThickness),CFrame.new(0,wallY,size.Z/2+wallThickness/2))
  local safety=barrier("SafetyFloor",Vector3.new(size.X+wallThickness*2,4,size.Z+wallThickness*2),CFrame.new(0,(lowest-cf.Position.Y)-7,0))
  safety:SetAttribute("SafetyFloor",true)
  map:SetAttribute("RecoveryY",lowest+1)

  local markers=Instance.new("Folder",map) markers.Name="RouteLanterns"
  for i=1,math.min(6,#selected) do
   local pos=selected[i]+Vector3.new(3,1,0)
   local post=smallPart(markers,"Lamp"..i,Vector3.new(.3,4,.3),CFrame.new(pos-Vector3.new(0,1.5,0)),Color3.fromRGB(47,43,43)) post.Material=Enum.Material.Metal
   local lamp=smallPart(markers,"Glow"..i,Vector3.new(.6,.8,.6),CFrame.new(pos+.5*Vector3.yAxis),Color3.fromRGB(196,142,101)) lamp.Material=Enum.Material.Neon
   local light=Instance.new("PointLight",lamp) light.Color=lamp.Color light.Brightness=.7 light.Range=17 light.Shadows=false
  end
  local count=0 for _,v in ipairs(map:GetDescendants()) do if v:IsA("BasePart") then count+=1 end end
  map:SetAttribute("KillerSpawn",far) map:SetAttribute("EntranceSpawn",start) map:SetAttribute("KillerSpawnClearance",killerClearance) map:SetAttribute("RequiredKillerClearance",killerClearance) map:SetAttribute("KillerSpawnDistance",distance)
  map:SetAttribute("KillerSpawnPathValidated",true)
  map:SetAttribute("SourceAssetId",spec.id) map:SetAttribute("DisplayName",spec.label)
  map:SetAttribute("FloorY",lowest) map:SetAttribute("VoidY",lowest-35) map:SetAttribute("PartCount",count)
  map:SetAttribute("Footprint",Vector3.new(size.X,0,size.Z)) map:SetAttribute("ValidatedPaths",#selected-1)
  map.Parent=destination
  table.insert(reports,{name=spec.name,label=spec.label,id=spec.id,scale=spec.scale,parts=count,objectiveSites=#chosenSites,connected=#selected,arrivals=#arrivals:GetChildren(),killerClearance=killerClearance,killerDistance=distance,invisibleBounds=#bounds:GetChildren(),width=size.X,depth=size.Z})
 end
 return reports
end
return Builder
