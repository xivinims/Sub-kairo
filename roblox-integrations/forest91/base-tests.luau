local world=assert(workspace.ForestWorld)local runtime=game.ReplicatedStorage.ForestRuntime
assert(world:GetAttribute("UpgradeVersion")==91 and world:GetAttribute("SeasonLayout")=="TemporalGlobal"and world:GetAttribute("GameName")=="TreeWorld")
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
assert(report.teaTables==4 and report.teaSeats==16)
assert(not world:FindFirstChild("OwnerNPC")and not runtime:FindFirstChild("NPCController")and not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestNPCClient"))
report.ownerNPCRemoved=true
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
