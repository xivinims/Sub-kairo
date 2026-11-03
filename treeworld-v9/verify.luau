local Workspace=game:GetService("Workspace")
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(Workspace:GetAttribute("WorldCorrectionVersion")=="2026-10-19-house-grounding-forest-v8","Wrong correction version")
local world=assert(Workspace:FindFirstChild("ReferenceWorld"),"World missing")
local house=assert(world.House:FindFirstChild("JapaneseHouse"),"House missing")
local mesh=assert(house:FindFirstChildWhichIsA("MeshPart",true),"House mesh missing")
assert(not mesh.CanCollide and not mesh.CanQuery,"Old combined hull still blocks the house")
local visualMax=math.max(mesh.Size.X,mesh.Size.Y,mesh.Size.Z)
assert(math.abs(visualMax-42)<.05,"House was not reduced to 42 studs")
assert(#world.House:GetChildren()==1,"House count changed")
local terrainParams=RaycastParams.new()
terrainParams.FilterType=Enum.RaycastFilterType.Include
terrainParams.FilterDescendantsInstances={Workspace.Terrain}
local function terrainAt(x,z)
 local hit=Workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-500,0),terrainParams)
 assert(hit and hit.Material~=Enum.Material.Water,"Expected dry ground at "..x..","..z)
 return hit.Position.Y
end
local houseGround=terrainAt(mesh.Position.X,mesh.Position.Z)
local houseDelta=math.abs(mesh.Position.Y-mesh.Size.Y/2-houseGround)
assert(houseDelta<.2,"House floats or sinks")
local f=mesh.Size.X/48
local function geom(x,y,z)
 return mesh.CFrame*CFrame.new((x-24)*f,(y-24)*f,(z-42.551856995/2)*f)
end
local probe=Instance.new("Part")
probe.Name="_TemporaryClearanceProbe";probe.Anchored=true;probe.CanCollide=false;probe.CanTouch=false;probe.CanQuery=false;probe.Transparency=1;probe.Parent=Workspace
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Exclude;overlap.FilterDescendantsInstances={probe};overlap.RespectCanCollide=true
local ray=RaycastParams.new()
ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={probe};ray.RespectCanCollide=true
local checks=0
local function clearAt(pos,width,height)
 probe.Size=Vector3.new(width,height,width);probe.CFrame=CFrame.new(pos)
 local hits=Workspace:GetPartsInPart(probe,overlap)
 for _,p in ipairs(hits) do assert(not p.CanCollide,"Player clearance blocked by "..p:GetFullName().." at "..tostring(pos)) end
 checks+=1
end
local function supported(pos,expectedY)
 local h=Workspace:Raycast(Vector3.new(pos.X,expectedY+1.2,pos.Z),Vector3.new(0,-3,0),ray)
 assert(h and math.abs(h.Position.Y-expectedY)<.25,"No walkable support at "..tostring(pos))
 return h
end
local function walkHouse(x,z)
 local floor=geom(x,9.05,z).Position
 supported(floor,floor.Y)
 clearAt(floor+Vector3.new(0,2.8,0),3.1,5.3)
end
-- Entrance -> interior and both directions through the side doorway.
for z=8,30,2 do walkHouse(16,z) end
for z=23,32,.5 do walkHouse(31.8,z) end
for z=12,31,2 do walkHouse(43.75,z) end
for x=31.8,43.75,1 do walkHouse(x,31) end
-- Continuous collider sweep through the door, plus initial overlap above.
local doorFrom=geom(31.8,9.05,23).Position+Vector3.new(0,2.8,0)
local doorTo=geom(31.8,9.05,32).Position+Vector3.new(0,2.8,0)
assert(not Workspace:Blockcast(CFrame.new(doorFrom),Vector3.new(3.1,5.3,3.1),doorTo-doorFrom,ray),"Side doorway sweep blocked")
local frontFrom=geom(16,9.05,8).Position+Vector3.new(0,2.8,0)
local frontTo=geom(16,9.05,24).Position+Vector3.new(0,2.8,0)
assert(not Workspace:Blockcast(CFrame.new(frontFrom),Vector3.new(3.1,5.3,3.1),frontTo-frontFrom,ray),"Main entrance sweep blocked")
local steps={}
local sideSteps={}
for _,p in ipairs(house.EntryAccess:GetChildren()) do
 if p.Name=="EntryStep" then table.insert(steps,p) end
 if p.Name=="SideEntryStep" then table.insert(sideSteps,p) end
end
for _,flight in ipairs({steps,sideSteps}) do
 assert(#flight==11,"Stair flight incomplete")
 table.sort(flight,function(a,b)return a.Size.Y<b.Size.Y end)
 local previousTop=houseGround
 for _,p in ipairs(flight) do
  local top=p.Position.Y+p.Size.Y/2
  assert(top-previousTop<.85 and top>=previousTop,"Stair riser too large")
  supported(p.Position,top)
  clearAt(Vector3.new(p.Position.X,top+3.7,p.Position.Z),2.6,3.4)
  previousTop=top
 end
end
-- The original room boundaries remain solid after removing the mesh hull.
for _,n in ipairs({"InteriorFloor","BackWall","SideWallLeft","SideWallRight","SupportColumn"}) do
 local p=house.AuthoredCollision:FindFirstChild(n);assert(p and p.CanCollide,n.." collision missing")
end
local bridgeReports={}
for _,spec in ipairs({{world.MainBridge.PhotoWoodBridge,"DeckPlank",155,56,104},{world.DarkZone.AbyssBridgeZone,"DarkDeck",-850,114,210}}) do
 local m,deckName,z,endX,length=table.unpack(spec)
 local deck=m:FindFirstChild(deckName);assert(deck,"Deck missing")
 local top=deck.Position.Y+deck.Size.Y/2
 local function bankAt(x,zz)
  local h=Workspace:Raycast(Vector3.new(x,40,zz),Vector3.new(0,-100,0),ray)
  assert(h,"Bridge bank has no physical ground")
  return h.Position.Y
 end
 local left=bankAt(-endX,z);local right=bankAt(endX,z)
 assert(math.abs(top-left)<.4 and math.abs(top-right)<.4,"Bridge not level with both banks")
 assert(math.abs(top-terrainAt(-400,z))<.4,"Bridge not connected to normal map grade")
 assert(top>18 and top<25,"Bridge deck is above or below the normal ground")
 for x=-length/2,length/2,4 do
  for _,offset in ipairs({-3.5,0,3.5}) do
   supported(Vector3.new(x,top,z+offset),top)
   clearAt(Vector3.new(x,top+2.8,z+offset),3.1,5.3)
  end
 end
 if z==-850 then
  local grade=terrainAt(-400,z)
  for _,x in ipairs({-126,126}) do
   for zz=-970,-750,4 do
    assert(math.abs(bankAt(x,zz)-grade)<.4,"Dark bridge approach drops below normal ground")
    clearAt(Vector3.new(x,grade+2.8,zz),3.1,5.3)
   end
  end
 end
 local origin=Vector3.new(-length/2,top+2.8,z)
 assert(not Workspace:Blockcast(CFrame.new(origin),Vector3.new(3.1,5.3,3.1),Vector3.new(length,0,0),ray),"Bridge traverse obstructed")
 table.insert(bridgeReports,{name=m.Name,deck=top,leftBank=left,rightBank=right})
end
probe:Destroy()
local trees,shrubs=0,0
local sectors={}
local dryTreeChecks=0
for _,m in ipairs(world.Forest:GetDescendants()) do
 if m:IsA("Model") and string.match(m.Name,"^ForestTree_") then
  trees+=1
  local trunk=assert(m:FindFirstChild("Trunk"),"Tree trunk missing")
  local p=m:GetAttribute("GroundPosition")
  assert(p,"Tree lacks ground position")
  assert(math.abs(trunk.Position.Y-trunk.Size.Y/2-terrainAt(p.X,p.Z))<.3,"Tree floats or is over water")
  dryTreeChecks+=1
  local sx=math.clamp(math.floor((p.X+1320)/440),0,5)
  local sz=math.clamp(math.floor((p.Z+1320)/440),0,5)
  local key=sx..":"..sz;sectors[key]=(sectors[key] or 0)+1
 elseif m:IsA("Model") and string.match(m.Name,"^Understory_") then shrubs+=1 end
end
local minSector=math.huge
for x=0,5 do for z=0,5 do
 local n=sectors[x..":"..z] or 0;assert(n>=8,"Sparse/empty forest sector "..x..","..z);minSector=math.min(minSector,n)
end end
assert(trees>=720 and trees==Workspace:GetAttribute("TreeCount"),"Tree count incorrect")
assert(shrubs>=330,"Understory coverage too low")
assert(#world.GroundingRepair.ScatteredRuins:GetChildren()==8,"Scattered ruins missing")
local parts=0
for _,d in ipairs(world:GetDescendants()) do if d:IsA("BasePart") then parts+=1 end end
assert(parts<10000,"Mobile geometry budget exceeded")
assert(Workspace.StreamingEnabled,"Streaming was disabled")
-- This editor-only property is not exposed in every cloud execution build.
-- The patch never writes streaming settings; preserve the published settings.
local radiusReadable,radius=pcall(function() return Workspace.StreamingTargetRadius end)
if radiusReadable then assert(radius<=340,"Streaming radius changed") end
assert(#world.Torii:GetChildren()==1,"Expected one torii")
local stones=0
for _,p in ipairs(world.Path:GetChildren()) do if p.Name=="PathStone" then stones+=1 end end
assert(stones==12,"Sparse path stones changed")
assert(Workspace:GetAttribute("LoadingSeconds")==3,"Loading time changed")
assert(game:GetService("ReplicatedFirst"):FindFirstChild("MapLoadingScreen"),"Loading screen missing")
assert(game:GetService("ServerScriptService"):FindFirstChild("PortalServer"),"Portal behavior missing")
assert(world.Ruins:FindFirstChild("AncientWhiteRuins"),"Central ruins missing")
local report={ok=true,placeVersion=game.PlaceVersion,houseVisualMax=visualMax,houseGroundDelta=houseDelta,clearanceChecks=checks,entranceSweeps=2,bridges=bridgeReports,trees=trees,shrubs=shrubs,forestSectors=36,minTreesPerSector=minSector,dryTreeChecks=dryTreeChecks,scatteredRuins=8,parts=parts,streamingEnabled=Workspace.StreamingEnabled,streamingRadiusReadable=radiusReadable}

assert(Workspace:GetAttribute("ReferenceSceneVersion")=="2026-10-20-reference-scenes-v9","Wrong scene version")
local details=assert(world:FindFirstChild("ReferenceDetailPass"))
assert(details:FindFirstChild("ForestPond"),"Pond absent")
local meshGroups=Workspace:GetAttribute("NaturalMeshGroups")
assert(meshGroups and meshGroups>500,"Detailed vegetation absent")
local materials,occupancies=Workspace.Terrain:ReadVoxels(Region3.new(Vector3.new(348,12,216),Vector3.new(352,20,220)):ExpandToGrid(4),4)
local hasWater=false
for x=1,#materials do for y=1,#materials[x]do for z=1,#materials[x][y]do
 if materials[x][y][z]==Enum.Material.Water and occupancies[x][y][z]>0 then hasWater=true end
end end end
assert(hasWater,"Pond has no water")
assert(#world.DarkZone.Chain:GetChildren()==23,"Hollow chain missing")
for _,m in ipairs(world.DarkZone.Chain:GetChildren())do assert(#m:GetChildren()==4,"Chain has solid links")end
local photoTrees=0
for _,m in ipairs(details.ForestPond:GetChildren())do
 if string.match(m.Name,"^PondTree_")then photoTrees+=1 end
end
assert(photoTrees>=50,"Dense pond foliage missing")
assert(math.abs(house:GetPivot().Position.Z-500)<.1,"House is outside temple composition")
local first=game:GetService("ReplicatedFirst")
local view=assert(first:FindFirstChild("OveryardLoadingView"))
local loader=assert(first:FindFirstChild("MapLoadingScreen"))
assert(string.find(view.Source,"rbxassetid://77442764802726",1,true),"Approved transparent logo missing")
assert(string.find(view.Source,"logo.ImageTransparency=0",1,true),"Logo starts invisible")
assert(string.find(view.Source,"logo.IsLoaded",1,true),"Logo rendering not checked")
assert(string.find(loader.Source,"MAX_LOGO_WAIT=12",1,true),"Logo loading has no bounded wait")
assert(string.find(loader.Source,"MIN_SECONDS=3",1,true),"Minimum welcome duration changed")
assert(string.find(loader.Source,"Olá, ",1,true),"Greeting absent")
assert(string.find(loader.Source,"View.create",1,true)<string.find(loader.Source,"RemoveDefaultLoadingScreen",1,true),"Default loading removed before dark UI")
assert(Workspace:GetAttribute("LoadingLogoTransparent"),"Logo transparency regressed")
assert(first:FindFirstChild("OveryardUpdateMigrationClient"),"Update loading missing")
assert(game:GetService("ServerScriptService"):FindFirstChild("OveryardUpdateMigrationServer"),"Group update migration lost")
assert(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("ReferenceEnvironmentClient"),"Zone atmosphere missing")
assert(not game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("DarkZoneClient"),"Competing old atmosphere script")
report.naturalMeshGroups=meshGroups;report.pondTrees=photoTrees;report.logoAssetId=77442764802726
report.loadingWaitsForLogo=true;report.chainLinks=23
return report
