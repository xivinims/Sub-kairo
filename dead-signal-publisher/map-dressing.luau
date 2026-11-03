local V=Vector3.new
local C=Color3.fromRGB
local dressing=Instance.new("Model"); dressing.Name="MapArchitectureAndProps"; dressing.Parent=W
local sectors=Instance.new("Folder"); sectors.Name="MapSectors"; sectors.Parent=W
local nav=Instance.new("Folder"); nav.Name="MapReviewMarkers"; nav.Parent=W
local mapParams=RaycastParams.new(); mapParams.FilterType=Enum.RaycastFilterType.Include; mapParams.FilterDescendantsInstances={map}; mapParams.RespectCanCollide=true
local templates={}
local function visual(id,selection,name,targetHeight,cf,parent)
 local key=tostring(id)..selection
 if not templates[key] then templates[key]=Importer.Select(id,selection) end
 local m=templates[key]:Clone(); m.Name=name; m:PivotTo(CFrame.new())
 local _,size=m:GetBoundingBox(); m:ScaleTo(m:GetScale()*targetHeight/math.max(size.Y,0.001)); m:PivotTo(cf)
 for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false end end
 m.Parent=parent; return m
end
local function prompt(parent,action,object)
 local p=Instance.new("ProximityPrompt"); p.ActionText=action; p.ObjectText=object; p.KeyboardKeyCode=Enum.KeyCode.F; p.MaxActivationDistance=8; p.HoldDuration=0.15; p.RequiresLineOfSight=false; p.Parent=parent; return p
end
local function light(parent,cf,sector,warm)
 local housing=part(parent,"CeilingFixture",V(4,0.3,1.4),cf,C(44,52,51))
 local lens=part(parent,"LightDiffuser",V(3.6,0.08,1.1),cf*CFrame.new(0,-0.2,0),warm or C(222,210,171),Enum.Material.Neon,false)
 local l=Instance.new("PointLight"); l.Name="SectorLight"; l.Color=warm or C(238,221,182); l.Brightness=1.5; l.Range=27; l.Enabled=true; l.Shadows=false; l.Parent=lens
 l:SetAttribute("SectorId",sector); CollectionService:AddTag(l,"DeadSignalMapLight"); return l
end
local function marker(name,cf)
 local p=part(nav,name,V(0.2,0.2,0.2),cf,nil,nil,false); p.Transparency=1; return p
end
local function grounded(name,cf,size,color,material,parent)
 return part(parent or dressing,name,size,cf*CFrame.new(0,size.Y/2,0),color,material)
end
local function crate(parent,cf,size)
 local m=Instance.new("Model"); m.Name="GroundedShippingCrate"; m.Parent=parent
 grounded("CrateBody",cf,V(size,size,size),C(112,91,63),Enum.Material.WoodPlanks,m)
 for _,side in ipairs({-1,1}) do part(m,"CrateBinding",V(0.13,size+0.02,size+0.04),cf*CFrame.new(side*size*0.31,size/2,0),C(56,67,59),Enum.Material.Metal,false) end
 return m
end
local function bench(parent,cf)
 part(parent,"BenchSeat",V(6,0.3,1.8),cf*CFrame.new(0,1.8,0),C(117,93,62),Enum.Material.Wood)
 part(parent,"BenchBack",V(6,1.6,0.25),cf*CFrame.new(0,2.75,0.8),C(117,93,62),Enum.Material.Wood)
 for _,s in ipairs({-1,1}) do part(parent,"BenchFoot",V(0.3,1.7,1.6),cf*CFrame.new(s*2.3,0.85,0),C(44,60,54)) end
end
local function door(hub,id,label,localCF,size,offset)
 local m=Instance.new("Model"); m.Name=id; m.Parent=hub
 m:SetAttribute("DoorId",id); m:SetAttribute("OpenOffset",offset); m:SetAttribute("OpenDuration",0.85)
 m:SetAttribute("DoorKind","Sliding"); m:SetAttribute("Label",label); CollectionService:AddTag(m,"DeadSignalMapDoor")
 local panel=part(m,"DoorPanel",size,localCF,C(105,119,112))
 panel.Material=Enum.Material.Metal
 -- The audited supplied white-door geometry provides the visible leaf, retaining its proportions.
 if size.Y>2 then
  local leaf=visual(8593730677,"__ALL_STATIC__","AuditedDoorGeometry",size.Y-0.18,localCF*CFrame.new(0,0,0.3),m)
  local _,bounds=leaf:GetBoundingBox()
  if bounds.X>size.X-0.1 then leaf:ScaleTo(leaf:GetScale()*(size.X-0.1)/bounds.X); leaf:PivotTo(localCF*CFrame.new(0,0,0.3)) end
  for _,p in ipairs(leaf:GetDescendants()) do
   if p:IsA("BasePart") then p.Anchored=false; p.Massless=true; local weld=Instance.new("WeldConstraint"); weld.Part0=panel; weld.Part1=p; weld.Parent=p end
  end
 else
  local handle=part(m,"DrawerHandle",V(1.2,0.12,0.16),localCF*CFrame.new(0,0,0.19),C(156,153,118),nil,false)
  handle.Anchored=false; handle.Massless=true; local weld=Instance.new("WeldConstraint"); weld.Part0=panel; weld.Part1=handle; weld.Parent=handle
 end
 return m,panel
end
local hubs={}
local definitions={
 {id="RECEPTION",label="Recepção de serviço",target=V(0,0,230),colour=C(68,104,108),purpose="Reception"},
 {id="WORKSHOP",label="Oficina",target=V(-210,0,-30),colour=C(117,99,63),purpose="Workshop"},
 {id="POWER",label="Subestação",target=V(205,0,-30),colour=C(76,102,82),purpose="Power"},
 {id="STORAGE",label="Depósito",target=V(-180,0,-290),colour=C(113,75,63),purpose="Storage"},
 {id="OBSERVATION",label="Sala de observação",target=V(180,0,-290),colour=C(76,86,117),purpose="Observation"},
}
local bushes={}
for _,p in ipairs(map:GetDescendants()) do if p:IsA("BasePart") and p.Name=="Bush" then table.insert(bushes,p) end end
local function findSite(target)
 for _,radius in ipairs({0,16,32,48,64}) do
  for index=0,(radius==0 and 0 or 11) do
   local angle=index*math.pi/6; local p=target+V(math.cos(angle)*radius,0,math.sin(angle)*radius)
   local hit=W:Raycast(V(p.X,12,p.Z),V(0,-28,0),mapParams)
   if hit and hit.Normal.Y>0.94 and math.abs(hit.Position.Y)<5 then
    local position=hit.Position
    local facing=V(position.X,0,position.Z).Unit
    local cf=CFrame.lookAt(position,position+facing)
    local blocked=W:Blockcast(cf*CFrame.new(0,0.3,0),V(27,0.15,28),V(0,15,0),mapParams)
    for _,bush in ipairs(bushes) do
     local localPoint=cf:PointToObjectSpace(bush.Position)
     if math.abs(localPoint.X)<14+bush.Size.Magnitude*0.3 and math.abs(localPoint.Z)<14+bush.Size.Magnitude*0.3 and localPoint.Y-bush.Size.Y/2<14 and localPoint.Y+bush.Size.Y/2>0 then blocked=true; break end
    end
    local flat=true
    for _,corner in ipairs({V(-12,0,-11),V(12,0,-11),V(-12,0,11),V(12,0,11)}) do
     local v=cf:PointToWorldSpace(corner)
     local support=W:Raycast(v+V(0,3,0),V(0,-6,0),mapParams)
     if not support or math.abs(support.Position.Y-position.Y)>0.35 then flat=false end
    end
    local lane=W:Blockcast(cf*CFrame.new(0,3.5,0),V(2.6,5.4,2.6),cf:VectorToWorldSpace(V(0,0,21)),mapParams)
    if lane then blocked=true end
    for _,z in ipairs({14,17,20}) do
     local point=(cf*CFrame.new(0,0,z)).Position
     local support=W:Raycast(point+V(0,3,0),V(0,-6,0),mapParams)
     if not support or support.Normal.Y<0.85 or math.abs(support.Position.Y-position.Y)>0.35 then flat=false end
    end
    if not blocked and flat then return cf end
   end
  end
 end
 error("No safe pavilion footprint near "..tostring(target))
end
for _,def in ipairs(definitions) do
 local cf=findSite(def.target)
 local hub=Instance.new("Model"); hub.Name=def.id; hub.Parent=dressing; hub.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 hub:SetAttribute("SectorId",def.id); hub:SetAttribute("Purpose",def.purpose); hub:SetAttribute("Centre",cf.Position)
 table.insert(hubs,{model=hub,cf=cf,id=def.id})
 local function b(name,pos,size,color,material,collide) return part(hub,name,size,cf*CFrame.new(pos),color,material,collide) end
 local floor=b("Foundation",V(0,0.05,0),V(25,0.5,23),C(92,99,90),Enum.Material.Concrete)
 b("InteriorFloor",V(0,0.34,0),V(23.7,0.08,21.7),C(145,142,122),Enum.Material.Concrete)
 for _,side in ipairs({-1,1}) do
  -- Split side walls leave real glazing apertures rather than glass painted over a solid wall.
  b("SideWallBase",V(side*12,2.3,0),V(0.6,4,22),def.colour,Enum.Material.Brick)
  b("SideWallHeader",V(side*12,11.2,0),V(0.6,5.6,22),C(160,155,134),Enum.Material.Plaster)
  for _,z in ipairs({-8.5,0,8.5}) do b("WindowPier",V(side*12,6.5,z),V(0.6,4.4,5),C(160,155,134),Enum.Material.Plaster) end
  for _,z in ipairs({-4.25,4.25}) do
   local glass=b("InternalObservationGlass",V(side*12,6.4,z),V(0.16,4.05,3.4),C(119,145,142),Enum.Material.Glass)
   glass.Transparency=0.42; glass.Reflectance=0.07
   b("WindowSill",V(side*12,4.3,z),V(0.95,0.18,3.7),C(69,82,77))
  end
  b("Skirting",V(side*11.64,0.65,0),V(0.16,0.55,21.4),C(40,56,52))
  b("FrontWall",V(side*7.75,4.4,11),V(8.5,8.2,0.6),def.colour,Enum.Material.Brick)
  b("FrontPilaster",V(side*12.25,7,11.25),V(0.9,14.1,1),C(73,84,77))
 end
 b("RearWall",V(0,7,-11),V(24,13.4,0.6),C(160,155,134),Enum.Material.Plaster)
 b("FrontLintel",V(0,11.25,11),V(24,5.5,0.6),C(160,155,134),Enum.Material.Plaster)
 b("RoofSlab",V(0,14.2,0),V(26,0.5,24),C(59,72,70),Enum.Material.Metal)
 for _,z in ipairs({-8,0,8}) do b("RoofBeam",V(0,13.4,z),V(24,0.45,0.3),C(57,71,67)) end
 for _,side in ipairs({-1,1}) do
  b("RoofEdge",V(side*12.7,14.5,0),V(0.3,0.6,24),C(88,98,88))
 end
 -- Rail sits in front of masonry, allowing the door leaf to slide across its face without clipping it.
 b("DoorRail",V(3.4,8.85,11.65),V(13.2,0.22,0.3),C(48,60,56))
 local d,panel=door(hub,def.id.."_DOOR",def.label,cf*CFrame.new(0,4.45,11.7),V(6.4,8.2,0.38),cf.RightVector*7.1)
 for _,z in ipairs({10.25,12.15}) do
  local button=b("DoorControl",V(-4,3.6,z),V(0.75,0.95,0.3),C(144,128,67))
  button:SetAttribute("DoorId",d:GetAttribute("DoorId")); CollectionService:AddTag(button,"DeadSignalDoorControl"); prompt(button,"Abrir porta",def.label)
 end
 marker(def.id.."_Outside",cf*CFrame.new(0,0,17))
 marker(def.id.."_Inside",cf*CFrame.new(0,0.4,0))
 for _,z in ipairs({-5.5,5}) do light(hub,cf*CFrame.new(0,12.9,z),def.id) end
 local source=part(sectors,def.id.."_SUPPLY",V(0.1,0.1,0.1),cf,nil,nil,false)
 source.Transparency=1; source:SetAttribute("PowerNodeId",def.id.."_SUPPLY"); source:SetAttribute("PowerNodeType","Source"); source:SetAttribute("Output",100); source:SetAttribute("Enabled",true)
 local consumer=source:Clone(); consumer.Name=def.id.."_LIGHTS"; consumer:SetAttribute("PowerNodeId",def.id.."_LIGHTS"); consumer:SetAttribute("PowerNodeType","Consumer"); consumer:SetAttribute("Output",0); consumer:SetAttribute("Demand",35); consumer.Parent=sectors
 local switch=b("WallLightSwitch",V(-5.8,4,10.55),V(0.7,1.1,0.22),C(146,137,102))
 switch:SetAttribute("SectorId",def.id); CollectionService:AddTag(switch,"DeadSignalSectorSwitch"); prompt(switch,"Apagar luzes",def.label)
 local station=visual(9609111841,"__ALL_STATIC__","AuditedElectricalStation",4.6,cf*CFrame.new(8,4.2,-10.4),hub)
 -- Floor joints are flush and peripheral details do not obstruct the door-to-room circulation lane.
 for x=-8,8,4 do b("FloorJoint",V(x,0.39,0),V(0.025,0.01,21.3),C(80,85,74),nil,false) end
 for z=-8,8,4 do b("FloorJoint",V(0,0.39,z),V(23.3,0.01,0.025),C(80,85,74),nil,false) end
 if def.purpose=="Reception" or def.purpose=="Observation" then
  b("DeskTop",V(-6.6,3,-5.5),V(7,0.35,3.2),C(101,83,60),Enum.Material.Wood)
  for _,x in ipairs({-9.4,-3.8}) do b("DeskLeg",V(x,1.65,-5.5),V(0.3,2.7,2.8),C(45,63,56)) end
  b("CRTCase",V(-6.5,4.3,-5.5),V(2.2,2.1,1.8),C(48,57,53))
  local screen=b("CRTGlass",V(-6.5,4.3,-4.56),V(1.8,1.4,0.07),C(31,55,55),Enum.Material.Glass,false); screen.Reflectance=0.08
  b("DeskPaper",V(-8.5,3.2,-5.4),V(1.4,0.03,1.8),C(187,177,142),Enum.Material.SmoothPlastic,false)
  bench(hub,cf*CFrame.new(6,0.4,-6.8)*CFrame.Angles(0,math.pi/2,0))
  for i=1,3 do visual(16390129962,"SM_BoxLetters_"..({"A","B","C"})[i].."_MI_Box_Letters_"..({"A","B","C"})[i].."_0","AuthoredToyDisplay",1.2,cf*CFrame.new(-8+i*1.4,0.99,-8.6),hub) end
 elseif def.purpose=="Workshop" then
  b("WorkshopTop",V(-7,3,-5),V(7,0.4,4),C(106,87,58),Enum.Material.Wood)
  for _,x in ipairs({-9.7,-4.3}) do b("WorkshopLeg",V(x,1.65,-5),V(0.3,2.7,3.5),C(49,65,58)) end
  b("Toolbox",V(-7.8,3.7,-5),V(2.3,0.9,1.4),C(124,64,47))
  b("BenchMotor",V(-5.5,3.8,-5),V(1.6,1.2,1.3),C(70,85,78))
  for i=1,5 do b("HangingTool",V(-10.65,5.5,-8+i),V(0.18,1.5,0.5),C(133,137,111),Enum.Material.Metal,false) end
  local drawer,dp=door(hub,def.id.."_DRAWER","Gaveta de ferramentas",cf*CFrame.new(-7,2.4,-3.1),V(5.6,0.7,0.2),cf.LookVector*-1.1)
  local pr=prompt(dp,"Abrir gaveta","Ferramentas"); dp:SetAttribute("DoorId",drawer:GetAttribute("DoorId")); CollectionService:AddTag(dp,"DeadSignalDoorControl")
  crate(hub,cf*CFrame.new(8,0.4,-7),3)
 elseif def.purpose=="Power" then
  for _,x in ipairs({-7,7}) do
   b("TransformerFoot",V(x,0.7,-6),V(4.4,0.6,5),C(85,92,81),Enum.Material.Concrete)
   b("TransformerCabinet",V(x,3.3,-6),V(3.8,4.6,4.2),C(66,91,81))
   for z=-7,-5,0.7 do b("TransformerCoolingFin",V(x,3.3,z),V(4,3.8,0.12),C(44,66,58),Enum.Material.Metal,false) end
   b("TransformerInsulator",V(x,6.15,-6),V(1.3,1.1,1.3),C(135,127,93),Enum.Material.SmoothPlastic,false)
  end
  b("CableDuct",V(0,10.8,-10.5),V(20,0.6,0.4),C(57,70,59))
 else
  for _,x in ipairs({-7,7}) do
   for _,y in ipairs({1,4.2,7.4}) do b("StorageShelf",V(x,y,-7),V(7,0.22,4),C(72,86,78)) end
   for _,dx in ipairs({-3.2,3.2}) do b("StorageUpright",V(x+dx,4.2,-7),V(0.2,8,3.8),C(49,66,57)) end
   crate(hub,cf*CFrame.new(x-1.8,1.15,-7),2); crate(hub,cf*CFrame.new(x+1.2,4.35,-7),1.8)
  end
 end
 -- Visible vents, wiring and drain details explain how each room functions.
 b("VentFrame",V(8,10,-10.55),V(4,2,0.3),C(54,70,64))
 for y=9.3,10.7,0.28 do b("VentLouvre",V(8,y,-10.3),V(3.6,0.08,0.12),C(116,121,100),nil,false) end
 if def.purpose=="Workshop" or def.purpose=="Power" then
  local fan=Instance.new("Model"); fan.Name="VentilationRotor"; fan.Parent=hub
  local centre=cf*CFrame.new(8,10,-10.05)
  fan.WorldPivot=centre; fan:SetAttribute("SectorId",def.id); CollectionService:AddTag(fan,"DeadSignalMapFan")
  for index=0,2 do
   local rotation=CFrame.Angles(0,0,index*math.pi*2/3)
   part(fan,"FanBlade",V(1.15,0.25,0.10),centre*rotation*CFrame.new(0.65,0,0),C(96,109,99),Enum.Material.Metal,false)
  end
  part(fan,"RotorHub",V(0.3,0.3,0.2),centre,C(59,75,66),nil,false)
 end
 b("ConduitVertical",V(-10.8,6,-10.3),V(0.16,10.8,0.16),C(83,99,85),nil,false)
 b("CableTray",V(0,11.8,-9.8),V(22,0.22,0.7),C(48,67,58))
 b("DrainChannel",V(-10,0.4,0),V(0.8,0.03,18),C(43,57,51),Enum.Material.DiamondPlate,false)
 for _,x in ipairs({-9,9}) do
  local barrelWorld=(cf*CFrame.new(x,0,15.8)).Position
  local hit=W:Raycast(barrelWorld+V(0,4,0),V(0,-8,0),mapParams)
  if hit then
   local barrel=part(hub,"ServiceBarrel",V(3.2,2.7,2.7),CFrame.new(hit.Position+V(0,1.6,0))*cf.Rotation*CFrame.Angles(0,0,math.pi/2),C(88,101,83),Enum.Material.Metal)
   barrel.Shape=Enum.PartType.Cylinder
  end
  local crateWorld=(cf*CFrame.new(x,0,19.8)).Position
  local support=W:Raycast(crateWorld+V(0,4,0),V(0,-8,0),mapParams)
  if support then crate(hub,CFrame.new(support.Position)*cf.Rotation,2.3) end
 end
end
-- Park furnishings follow the actual walkable ground, rather than a uniform scatter over paths.
local occupied={}
local function surface(x,z)
 local hit=W:Raycast(V(x,12,z),V(0,-28,0),mapParams)
 if hit and hit.Normal.Y>0.9 and math.abs(hit.Position.Y)<5 then return hit.Position end
end
local parkProps=Instance.new("Model"); parkProps.Name="ParkFurnishings"; parkProps.Parent=dressing
for _,spec in ipairs({{-95,160},{95,160},{-150,120},{150,120},{-150,-140},{150,-140},{-100,-250},{100,-250},{-260,-210},{260,-210},{-240,140},{240,140}}) do
 local point=surface(spec[1],spec[2])
 if point then
  local cf=CFrame.lookAt(point,point+V(point.X,0,point.Z).Unit)
  local blocked=W:Blockcast(cf*CFrame.new(0,0.3,0),V(8,0.15,4),V(0,4,0),mapParams)
  if not blocked then bench(parkProps,cf); table.insert(occupied,point) end
 end
end
-- Warm fixtures on supported poles span all sectors; distance culling is client-side.
local parkLightPositions={V(0,0,180),V(0,0,-230),V(-180,0,150),V(180,0,150),V(-280,0,-190),V(280,0,-190),V(-180,0,-340),V(180,0,-340),V(0,0,-390),V(-300,0,50),V(300,0,50),V(0,0,320),V(-90,0,280),V(90,0,280)}
for _,target in ipairs(parkLightPositions) do
 local point=surface(target.X,target.Z)
 if point and not W:Blockcast(CFrame.new(point+V(0,0.3,0)),V(1,0.1,1),V(0,13,0),mapParams) then
  part(parkProps,"LightPoleFoot",V(1.2,0.45,1.2),CFrame.new(point+V(0,0.22,0)),C(79,89,78),Enum.Material.Concrete)
  part(parkProps,"LightPole",V(0.3,12,0.3),CFrame.new(point+V(0,6,0)),C(51,71,62))
  light(parkProps,CFrame.new(point+V(0,12,0)),"PARK",C(228,212,170))
 end
end
local parkSupply=part(sectors,"PARK_SUPPLY",V(0.1,0.1,0.1),CFrame.new(),nil,nil,false); parkSupply.Transparency=1
parkSupply:SetAttribute("PowerNodeId","PARK_SUPPLY"); parkSupply:SetAttribute("PowerNodeType","Source"); parkSupply:SetAttribute("Output",100)
local parkConsumer=parkSupply:Clone(); parkConsumer.Name="PARK_LIGHTS"; parkConsumer:SetAttribute("PowerNodeId","PARK_LIGHTS"); parkConsumer:SetAttribute("PowerNodeType","Consumer"); parkConsumer:SetAttribute("Output",0); parkConsumer:SetAttribute("Demand",60); parkConsumer.Parent=sectors
local reception=hubs[1]
local parkSwitch=part(reception.model,"ParkLightControl",V(0.85,1.1,0.22),reception.cf*CFrame.new(5.2,4,11.42),C(142,133,91))
parkSwitch:SetAttribute("SectorId","PARK"); CollectionService:AddTag(parkSwitch,"DeadSignalSectorSwitch"); prompt(parkSwitch,"Apagar luzes","Iluminação do parque")
local spawnGround=(reception.cf*CFrame.new(0,0,20)).Position
local spawn=Instance.new("SpawnLocation"); spawn.Name="MapSpawn"; spawn.Size=V(5,1,5); spawn.CFrame=CFrame.lookAt(spawnGround+V(0,0.5,0),reception.cf.Position+V(0,0.5,0)); spawn.Anchored=true; spawn.CanCollide=false; spawn.CanQuery=false; spawn.CanTouch=false; spawn.Transparency=1; spawn.Neutral=true; spawn.Duration=0; spawn.Parent=W
marker("SpawnGround",CFrame.new(spawnGround))
for _,template in pairs(templates) do template:Destroy() end
Importer.ClearSelectionCache(); importerModule:Destroy()
W:SetAttribute("MapHubCount",#hubs); W:SetAttribute("MapBenchCount",#occupied)
