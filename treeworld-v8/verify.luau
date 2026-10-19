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
 local left=terrainAt(-endX,z);local right=terrainAt(endX,z)
 assert(math.abs(top-left)<.4 and math.abs(top-right)<.4,"Bridge not level with both banks")
 assert(math.abs(top-terrainAt(-endX-40,z))<.4,"Bridge bank is still a mountain")
 for x=-length/2,length/2,4 do
  for _,offset in ipairs({-3.5,0,3.5}) do
   supported(Vector3.new(x,top,z+offset),top)
   clearAt(Vector3.new(x,top+2.8,z+offset),3.1,5.3)
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
assert(trees==768 and trees==Workspace:GetAttribute("TreeCount"),"Tree count incorrect")
assert(shrubs>=340,"Understory coverage too low")
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
return {ok=true,placeVersion=game.PlaceVersion,houseVisualMax=visualMax,houseGroundDelta=houseDelta,clearanceChecks=checks,entranceSweeps=2,bridges=bridgeReports,trees=trees,shrubs=shrubs,forestSectors=36,minTreesPerSector=minSector,dryTreeChecks=dryTreeChecks,scatteredRuins=8,parts=parts,streamingEnabled=Workspace.StreamingEnabled,streamingRadiusReadable=radiusReadable}
