assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==99,"Saved version mismatch")

local world=workspace:WaitForChild("ForestWorld")
local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain
local C=game:GetService("CollectionService")

assert(world:GetAttribute("UpgradeVersion")==99)
assert(runtime:GetAttribute("NoDecorativeRocks")==true)
assert(runtime:GetAttribute("RiversideCottageRemoved")==true)
assert(runtime:GetAttribute("AnimationMode")=="RobloxDefault")
assert(runtime:GetAttribute("GraphicsPreset")=="Ultra")
assert(runtime:GetAttribute("StreamingMinRadiusStuds")==320)
assert(runtime:GetAttribute("StreamingTargetRadiusStuds")==896)
assert(runtime:GetAttribute("StreamingPrefetchDistance")==640)
assert(require(runtime.Seasons).Duration==1200)

local garden=world.Amenities.RiversideGarden
assert(not garden:FindFirstChild("WaterCottage"),"River cottage still exists")
assert(not garden:FindFirstChild("LakesideBoardwalk"),"River cottage boardwalk still exists")
assert(not garden:FindFirstChild("StreamSteppingStones"),"Decorative stepping stones still exist")
assert(#world.Decor.RocksAndLogs:GetChildren()==0,"Decorative rocks/logs remain")
assert(#world.Amenities.CutTrunks:GetChildren()==0,"Cut trunks remain")

local houses=assert(world.Amenities:FindFirstChild("DestroyedHouses"),"DestroyedHouses folder missing")
assert(#houses:GetChildren()>=4,"Too few destroyed houses")
for _,m in ipairs(houses:GetChildren())do
 assert(m:GetAttribute("SourceAssetId")==17385388938,"Wrong destroyed-house asset")
 assert(m.ModelStreamingMode==Enum.ModelStreamingMode.Atomic)
 local _,size=m:GetBoundingBox()
 assert(size.X>3 and size.Y>3 and size.Z>3,"Destroyed house malformed")
end

local broken=assert(world.Amenities:FindFirstChild("AbandonedBrokenBridges"),"Broken bridge folder missing")
assert(#broken:GetChildren()>=3,"Too few broken bridges")
for _,m in ipairs(broken:GetChildren())do
 assert(m:GetAttribute("BrokenBridge")==true)
 assert(m:FindFirstChild("RottenPlank",true),"Broken bridge has no rotten planks")
end

local lamps=world.Amenities.Lanterns:GetChildren()
assert(#lamps>=12,"Too few lamp posts")
for _,m in ipairs(lamps)do
 assert(m:GetAttribute("SourceAssetId")==97893326625257,"Wrong lamp source")
 assert(m:GetAttribute("SourceFBXSHA256")=="02d7d43c417d633c908243ad34ca44599936876ce0a2b32926b7dc14f1012688","Wrong lamp FBX")
 local _,size=m:GetBoundingBox()
 assert(math.abs(size.Y-8.8)<.15,"Lamp scale incorrect")
 local gp=m:GetAttribute("GroundPoint")assert(gp,"Lamp has no ground point")
 local light=assert(m:FindFirstChild("WarmLanternLight",true),"Lamp has no light")
 assert(light:IsA("PointLight")and light.Range>=18 and light.Brightness>=1.3)
end

assert(Lighting:FindFirstChild("ForestAtmosphere"),"Atmosphere missing")
assert(Lighting:FindFirstChild("ForestSunRays")and Lighting.ForestSunRays.Enabled,"Sun rays missing")
assert(Lighting:FindFirstChild("ForestBloom")and Lighting.ForestBloom.Enabled,"Bloom missing")
assert(Lighting:FindFirstChild("ForestColor")and Lighting.ForestColor.Enabled,"Color correction missing")
assert(Lighting:FindFirstChild("ForestDOF")and Lighting.ForestDOF.Enabled,"DOF missing")
assert(Terrain.WaterReflectance>=.20 and Terrain.WaterTransparency<=.20,"Water quality settings missing")
assert(Terrain.WaterWaveSize>=.05 and Terrain.WaterWaveSpeed>=6,"Water motion settings missing")

local controls=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldViewControls"),"1P/3P control missing")
assert(controls.Source:find('CameraMode.LockFirstPerson',1,true),"First-person mode missing")
assert(controls.Source:find('CameraMaxZoomDistance=9',1,true),"Fixed third-person mode missing")
assert(controls.Source:find('ForestSunRays',1,true)and controls.Source:find('ULTRA',1,true),"Ultra control missing")

for _,container in ipairs({game.StarterPlayer.StarterPlayerScripts,game.StarterPlayer.StarterCharacterScripts})do
 for _,s in ipairs(container:GetChildren())do
  local n=s.Name:lower()
  assert(not(n:find("nextbot",1,true)or n:find("evade",1,true)),"Old animation/movement script remains: "..s.Name)
 end
end

assert((runtime:GetAttribute("NativeTreeVarietyCount")or 0)>=10,"Tree variety missing")
assert(runtime:GetAttribute("ForestLiveChunkLimit")==36)
assert(runtime:GetAttribute("ForestChunkRadius")==4)
assert(runtime:GetAttribute("SeasonSeconds")==1200)

local roots=assert(runtime:FindFirstChild("ActualRootContacts"),"Root probes missing")
assert(#roots:GetChildren()>200,"Too few root probes")
local terrainRay=RaycastParams.new()
terrainRay.FilterType=Enum.RaycastFilterType.Include
terrainRay.FilterDescendantsInstances={Terrain}
terrainRay.IgnoreWater=true
local grounded=0
for _,entry in ipairs(roots:GetChildren())do
 local m=entry.Value
 if m and m:IsDescendantOf(world)then
  local p=m:GetAttribute("ActualRootPoint")
  if p then
   local hit=workspace:Raycast(Vector3.new(p.X,210,p.Z),Vector3.yAxis*-310,terrainRay)
   assert(hit and p.Y<hit.Position.Y-.2,"Floating vegetation remains: "..m:GetFullName())
   grounded+=1
  end
 end
end
assert(grounded>200)

local liveTea=0
for _,click in ipairs(C:GetTagged("TreeWorldCupClick"))do
 if click:IsDescendantOf(world)then liveTea+=1 end
end
assert(liveTea>=12,"Utah tea sets missing")


local mansion=assert(world.Amenities:FindFirstChild("RuinMansion"),"Ruin mansion missing")
assert(mansion.ModelStreamingMode==Enum.ModelStreamingMode.Atomic,"Mansion must stream atomically")
assert((mansion:GetAttribute("RoomCount")or 0)>=8,"Mansion rooms missing")
assert((mansion:GetAttribute("SeatCount")or 0)>=10,"Mansion seating missing")
assert((mansion:GetAttribute("PortraitCount")or 0)>=8,"Player portraits missing")
assert(mansion:FindFirstChild("BrokenDoorLeft",true)and mansion:FindFirstChild("BrokenDoorRight",true),"Broken mansion door missing")
assert(mansion:FindFirstChild("GrandStep",true),"Grand staircase missing")
assert(mansion:FindFirstChild("FallingBeam",true),"Break-event beam missing")
local seatCount=0
for _,d in ipairs(mansion:GetDescendants())do
 if d:IsA("Seat")then seatCount+=1 end
 assert(not d:IsA("ProximityPrompt"),"Mansion seating should not require clicking")
end
assert(seatCount>=10,"Not enough touch seats")
local controller=assert(game.ServerScriptService:FindFirstChild("RuinMansionController"),"Mansion controller missing")
assert(controller.Source:find("AvatarHeadShot",1,true),"Live player portraits are not wired")
assert(controller.Source:find("FallingBeam",1,true),"Break animation controller missing")
local riverStones=assert(world.Decor:FindFirstChild("RiverStones"),"River stones folder missing")
assert(#riverStones:GetChildren()>=20,"Too few stones remain in water")
for _,p in ipairs(riverStones:GetChildren())do
 assert(p:IsA("BasePart")and p.Material==Enum.Material.Slate,"River stone malformed")
end
assert((runtime:GetAttribute("RuinTreeRingCount")or 0)>=20,"Not enough trees around ruins")
assert((runtime:GetAttribute("SubmergedPlantsRemoved")or 0)>=0)
assert(runtime:GetAttribute("RuinMansionVersion")==99)
assert(Terrain.WaterReflectance>=.23 and Terrain.WaterTransparency<=.17,"TreeWorld 99 river quality missing")

assert(runtime:GetAttribute("WeatherLoopStarted")==true,"Weather loop did not start")
assert(runtime:GetAttribute("WeatherName")=="Claro"or runtime:GetAttribute("WeatherName")=="Chuva")
local gardenClient=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestGardenClient"))
assert(gardenClient.Source:find("GentleRain",1,true),"Rain visual missing")
assert(gardenClient.Source:find("SeasonIndex",1,true),"Seasonal falling leaves missing")

assert(runtime:GetAttribute("MenuCameraView")=="RuinSide","Ruin-side menu camera lost")

return{
 ok=true,
 version=game.PlaceVersion,
 destroyedHouses=#houses:GetChildren(),
 brokenBridges=#broken:GetChildren(),
 lampPosts=#lamps,
 treeVarieties=runtime:GetAttribute("NativeTreeVarietyCount"),
 seasonSeconds=require(runtime.Seasons).Duration,
 streamingTarget=runtime:GetAttribute("StreamingTargetRadiusStuds"),
 waterReflectance=Terrain.WaterReflectance,
 mansionRooms=mansion:GetAttribute("RoomCount"),
 mansionSeats=seatCount,
 portraits=mansion:GetAttribute("PortraitCount"),
 riverStones=#riverStones:GetChildren(),
 ruinTrees=runtime:GetAttribute("RuinTreeRingCount"),
 ultra=true,
 noLandDecorativeRocks=true,
 noRiverHouse=true,
 groundedVegetation=grounded
}
