-- Imported geometry is inspected and prepared in the publishing session, never in a live round.
local Builder={}
local PF=game:GetService("PathfindingService")
local specs={
 {name="HorrorMap",id=79671648850902,root="MAP THING",label="Bosque do Silêncio",scale=1.2},
 {name="MilitaryBase",id=13967333450,root="Map_MilitaryBase",label="Base Abandonada",scale=1.05},
 {name="AlpineFortress",id=8050959400,root="Evolution Evade map Alpine Fortress",label="Fortaleza da Névoa",scale=2},
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
function Builder.build(load,sanitize,destination)
 local reports={}
 for _,spec in ipairs(specs) do
  local asset=load(spec.id)
  local map=assert(asset:FindFirstChild(spec.root,true),"Missing geometry for "..spec.name)
  assert(map:IsA("Model"),"Map root must be a model")
  map.Parent=nil asset:Destroy() map.Name=spec.name sanitize(map,true)
  map:ScaleTo(map:GetScale()*spec.scale)
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
    if p.Size.Magnitude<5 then p.CastShadow=false end
    if p.CanCollide and p.Transparency<.98 and p.Size.X>=8 and p.Size.Z>=8 and p.CFrame.UpVector.Y>.95 and p.Size.Y<=math.max(12,math.min(p.Size.X,p.Size.Z)*.4) then
     local top=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0))
     table.insert(floors,{part=p,y=top.Y}) lowest=math.min(lowest,top.Y)
    end
   elseif p:IsA("Light") then lightCount+=1 p.Shadows=false p.Enabled=lightCount<=16 p.Brightness=math.min(p.Brightness,1.5)
   elseif p:IsA("Sound") then p.Playing=false
   elseif p:IsA("ParticleEmitter") then p.Rate=math.min(p.Rate,5)
   end
  end
  assert(parts>30 and parts<=3000,"Map part budget exceeded: "..spec.name.." "..parts)
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
   if workspace:Raycast(g+Vector3.new(0,.2,0),Vector3.new(0,5.8,0),params) then return end
   if not radialClear(g,4.5) then return end
   local p=g+Vector3.new(0,3,0)
   for _,other in ipairs(candidates) do if (other-p).Magnitude<8 then return end end
   table.insert(candidates,p)
  end
  for _,surface in ipairs(floors) do
   if surface.y<=lowest+32 and scans<1800 and #candidates<240 then
    local p=surface.part
    candidate(p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0)))
    for x=-p.Size.X/2+4,p.Size.X/2-4,14 do
     for z=-p.Size.Z/2+4,p.Size.Z/2-4,14 do
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
  local start=selected[1] local far=nil local distance=0 local killerClearance=8
  for _,p in ipairs(selected) do
   local d=(p-start).Magnitude
   local ground=p-Vector3.new(0,3,0)
   if d>distance and d>=60 and insideFootprint(ground,footprintMargin+2) and radialClear(ground,killerClearance) then far=p distance=d end
  end
  if not far then
   killerClearance=5.5
   for _,p in ipairs(selected) do
    local d=(p-start).Magnitude local ground=p-Vector3.new(0,3,0)
    if d>distance and d>=60 and radialClear(ground,killerClearance) then far=p distance=d end
   end
  end
  assert(far and distance>=60,"No safe pursuer spawn away from walls in "..spec.name)
  local points=Instance.new("Folder",map) points.Name="SafePoints"
  for i,p in ipairs(selected) do addPoint(points,i,p) end
  local arrivals=Instance.new("Folder",map) arrivals.Name="ArrivalSpawns" addPoint(arrivals,1,start)
  for _,p in ipairs(candidates) do
   if #arrivals:GetChildren()>=8 then break end
   if (p-start).Magnitude>=4 and (p-start).Magnitude<=40 and (p-far).Magnitude>50 and route(start,p) then addPoint(arrivals,#arrivals:GetChildren()+1,p) end
  end
  assert(#arrivals:GetChildren()>=2,"Arrival area too cramped")
  local toward=Vector3.new(cf.X-start.X,0,cf.Z-start.Z)
  if toward.Magnitude<1 then toward=Vector3.new(far.X-start.X,0,far.Z-start.Z) end
  toward=toward.Unit
  local entrance=Instance.new("Model",map) entrance.Name="ArenaEntrance"
  local doorCF=CFrame.lookAt(start-toward*5,start) entrance:SetAttribute("DoorCFrame",doorCF)
  for _,part in ipairs({{"Left",Vector3.new(-3.5,1,0),Vector3.new(1,8,1)},{"Right",Vector3.new(3.5,1,0),Vector3.new(1,8,1)},{"Top",Vector3.new(0,5,0),Vector3.new(8,1,1)}}) do
   local p=smallPart(entrance,part[1],part[3],doorCF*CFrame.new(part[2]),Color3.fromRGB(46,39,39)) p.Material=Enum.Material.Metal
  end
  local markers=Instance.new("Folder",map) markers.Name="RouteLanterns"
  for i=1,math.min(6,#selected) do
   local pos=selected[i]+Vector3.new(3,1,0)
   local post=smallPart(markers,"Lamp"..i,Vector3.new(.3,4,.3),CFrame.new(pos-Vector3.new(0,1.5,0)),Color3.fromRGB(47,43,43)) post.Material=Enum.Material.Metal
   local lamp=smallPart(markers,"Glow"..i,Vector3.new(.6,.8,.6),CFrame.new(pos+.5*Vector3.yAxis),Color3.fromRGB(196,142,101)) lamp.Material=Enum.Material.Neon
   local light=Instance.new("PointLight",lamp) light.Color=lamp.Color light.Brightness=.7 light.Range=17 light.Shadows=false
  end
  local sign=Instance.new("BillboardGui",entrance.Top) sign.Size=UDim2.fromOffset(240,42) sign.StudsOffset=Vector3.new(0,1,0) sign.MaxDistance=55
  local text=Instance.new("TextLabel",sign) text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Text=spec.label text.Font=Enum.Font.GothamMedium text.TextSize=16 text.TextColor3=Color3.fromRGB(231,212,205)
  local count=0 for _,v in ipairs(map:GetDescendants()) do if v:IsA("BasePart") then count+=1 end end
  map:SetAttribute("KillerSpawn",far) map:SetAttribute("EntranceSpawn",start) map:SetAttribute("KillerSpawnClearance",killerClearance)
  map:SetAttribute("SourceAssetId",spec.id) map:SetAttribute("DisplayName",spec.label)
  map:SetAttribute("FloorY",lowest) map:SetAttribute("VoidY",lowest-35) map:SetAttribute("PartCount",count)
  map:SetAttribute("Footprint",Vector3.new(size.X,0,size.Z)) map:SetAttribute("ValidatedPaths",#selected-1)
  map.Parent=destination
  table.insert(reports,{name=spec.name,id=spec.id,parts=count,connected=#selected,arrivals=#arrivals:GetChildren(),killerClearance=killerClearance,width=size.X,depth=size.Z})
 end
 return reports
end
return Builder
