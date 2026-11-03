local W=workspace
local RS=game:GetService("ReplicatedStorage")
local Tags=game:GetService("CollectionService")
local errors={}
local function check(ok,message) if not ok then table.insert(errors,message) end end
check(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
check(W:GetAttribute("DeadSignalBuildId")=="dead-signal-runtime-quality-v4","Build mismatch")
check(W:GetAttribute("MapFocus")==true and W:GetAttribute("StalkerPaused")==true,"Map review mode not active")
check(not W:FindFirstChild("Bramble") and not W:FindFirstChild("BrambleWorld"),"Stalker/test world still active")
local map=W:FindFirstChild("PoppyTestMap")
local dressing=W:FindFirstChild("MapArchitectureAndProps")
check(map and map:GetAttribute("SourceAssetId")==18509954401,"Requested map missing")
local parts,importedParts,external,mirrored=0,0,0,0
for _,container in ipairs({map,dressing}) do
 if container then
  for _,p in ipairs(container:GetDescendants()) do
   if p:IsA("BasePart") then
    parts+=1
    if container==map then importedParts+=1 end
    local det=p.CFrame.RightVector:Cross(p.CFrame.UpVector):Dot(-p.CFrame.LookVector)
    if det<0.98 or det>1.02 then mirrored+=1 end
   elseif p:IsA("LuaSourceContainer") then external+=1 end
  end
 end
end
check(importedParts>=2600,"Source map truncated")
check(parts<4200,"Map part budget exceeded")
check(external==0,"External executable content in geometry")
check(mirrored==0,"Invalid/reflected physical transforms")
local root=game:GetService("ServerScriptService"):FindFirstChild("DeadSignalMap")
check(root and root:FindFirstChild("MapRuntime"),"Map server missing")
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("MapEnvironment")~=nil,"Map environment client missing")
check(#game:GetService("StarterGui"):GetChildren()==0,"Unexpected UI added in map pass")
local routes={}; local hubData={}; local doorCount=0; local switchCount=0
if root and dressing then
 local Power=require(root.PowerService); local Door=require(root.DoorService)
 local power=Power.new({Power={DefaultVoltage=100,OverloadGraceSeconds=1.5}})
 local doors=Door.new(power); local ids={}
 for _,node in ipairs(W.MapSectors:GetChildren()) do power:RegisterNode(node) end
 for _,id in ipairs({"RECEPTION","WORKSHOP","POWER","STORAGE","OBSERVATION","PARK"}) do
  power:SetLink(id.."_SUPPLY",id.."_LIGHTS",true)
 end
 power:Recalculate()
 for _,m in ipairs(Tags:GetTagged("DeadSignalMapDoor")) do
  local id=m:GetAttribute("DoorId")
  check(not ids[id],"Duplicate door "..tostring(id)); ids[id]=true; doors:Register(m); doorCount+=1
  local original=doors.Doors[id].panel.CFrame
  local ok=doors:SetOpen(id,true,true)
  check(ok and (doors.Doors[id].panel.Position-original.Position).Magnitude>0.8,"Door failed to open "..id)
 end
 -- Sweep a real avatar-sized volume through every opened pavilion entrance.
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.RespectCanCollide=true
 params.FilterDescendantsInstances={W.MapReviewMarkers,W.MapSectors,W.MapSpawn}
 for _,hub in ipairs(dressing:GetChildren()) do
  local id=hub:GetAttribute("SectorId")
  if id then
   local inside=W.MapReviewMarkers:FindFirstChild(id.."_Inside")
   local outside=W.MapReviewMarkers:FindFirstChild(id.."_Outside")
   check(inside~=nil and outside~=nil,"Missing route markers "..id)
   if inside and outside then
    local start=inside.Position+Vector3.new(0,3.1,0)
    local finish=outside.Position+Vector3.new(0,3.5,0)
    local hit=W:Blockcast(CFrame.new(start),Vector3.new(2.6,5.4,2.6),finish-start,params)
    routes[id]=not hit
    check(not hit,"Avatar entry blocked "..id.." by "..(hit and hit.Instance:GetFullName() or "unknown"))
    table.insert(hubData,{id=id,centre={inside.Position.X,inside.Position.Y,inside.Position.Z},entry={outside.Position.X,outside.Position.Y,outside.Position.Z},purpose=hub:GetAttribute("Purpose")})
   end
  end
 end
 for id,record in pairs(doors.Doors) do
  doors:SetOpen(id,false,true)
  check(record.panel.CFrame==record.closedCFrame,"Door failed to close "..id)
 end
 check(doorCount==6,"Expected 5 doors and one drawer")
 for _,control in ipairs(Tags:GetTagged("DeadSignalDoorControl")) do check(ids[control:GetAttribute("DoorId")],"Control references unknown door") end
 for _,control in ipairs(Tags:GetTagged("DeadSignalSectorSwitch")) do
  switchCount+=1
  local id=control:GetAttribute("SectorId")
  check(power:IsEnergized(id.."_LIGHTS"),"Sector initially unpowered "..id)
  power:SetEnabled(id.."_SUPPLY",false); power:Recalculate()
  check(not power:IsEnergized(id.."_LIGHTS"),"Sector switch did not disconnect "..id)
  power:SetEnabled(id.."_SUPPLY",true); power:Recalculate()
 end
 check(switchCount==6,"Expected six lighting controls")
 local spawn=W:FindFirstChild("MapSpawn")
 check(spawn~=nil,"Map spawn absent")
 if spawn then
  local groundParams=RaycastParams.new(); groundParams.FilterType=Enum.RaycastFilterType.Include; groundParams.FilterDescendantsInstances={map}; groundParams.RespectCanCollide=true
  check(W:Raycast(spawn.Position+Vector3.new(0,2,0),Vector3.new(0,-6,0),groundParams)~=nil,"Spawn unsupported")
 end
 -- Crates must stand on map ground, a floor, or an actual shelf, never float in the room.
 for _,p in ipairs(dressing:GetDescendants()) do
  if p:IsA("BasePart") and p.Name=="CrateBody" then
   local q=RaycastParams.new(); q.FilterType=Enum.RaycastFilterType.Exclude; q.FilterDescendantsInstances={p.Parent}; q.RespectCanCollide=true
   local bottom=p.Position-Vector3.new(0,p.Size.Y/2,0)
   check(W:Raycast(bottom+Vector3.new(0,0.06,0),Vector3.new(0,-0.2,0),q)~=nil,"Unsupported crate "..p:GetFullName())
  end
 end
end
local safety={}
if root then
 local Door=require(root.DoorService)
 local Guard=require(root.MapInteractionGuard)
 local test=Instance.new("Model");test.Name="DoorSafetyValidation";test.Parent=W
 test:SetAttribute("DoorId","SAFETY_VALIDATION");test:SetAttribute("OpenOffset",Vector3.new(7,0,0));test:SetAttribute("OpenDuration",0.3)
 local panel=Instance.new("Part");panel.Name="DoorPanel";panel.Anchored=true;panel.Size=Vector3.new(6,8,0.4);panel.CFrame=CFrame.new(10000,5,10000);panel.Parent=test
 local occupied=false
 local ds=Door.new({IsEnergized=function()return true end},{IsOccupied=function()return occupied end})
 local record=ds:Register(test)
 check(not pcall(function()ds:Register(test)end),"Duplicate door registration accepted")
 ds:SetOpen("SAFETY_VALIDATION",true,true)
 task.delay(0.05,function()occupied=true end)
 local closed,reason=ds:SetOpen("SAFETY_VALIDATION",false)
 safety.midCloseProtection=not closed and reason=="occupied" and record.open and record.state=="Waiting"
 check(safety.midCloseProtection,"Door did not reverse for player entering during close")
 ds:SetOpen("SAFETY_VALIDATION",true)
 task.wait(0.5)
 safety.cancelPendingClose=record.open and record.state=="Open"
 check(safety.cancelPendingClose,"Pending close was not cancelled by reopen request")
 occupied=false;ds:SetOpen("SAFETY_VALIDATION",false)
 safety.recovery=not record.open
 check(safety.recovery,"Door did not close after occupancy cleared")
 test:Destroy()
 local char=Instance.new("Model");char.Name="GuardValidation";char.Parent=W
 local hrp=Instance.new("Part");hrp.Name="HumanoidRootPart";hrp.Anchored=true;hrp.CFrame=CFrame.new(10000,5,10000);hrp.Parent=char
 local head=hrp:Clone();head.Name="Head";head.Parent=char
 local hum=Instance.new("Humanoid");hum.RequiresNeck=false;hum.Parent=char
 local control=Instance.new("Part");control.Anchored=true;control.CFrame=CFrame.new(10000,5,10004);control.Parent=char
 local prompt=Instance.new("ProximityPrompt");prompt.MaxActivationDistance=8;prompt.Parent=control
 local player={Character=char,UserId=-1400};local clocks={};local wall=false
 local world={Raycast=function()return wall and {Instance=control} or nil end}
 check(Guard.CanUse(player,prompt,10,clocks,world),"Guard rejected valid nearby interaction")
 check(not Guard.CanUse(player,prompt,10.1,clocks,world),"Interaction spam accepted")
 wall=true;check(not Guard.CanUse(player,prompt,11,clocks,world),"Interaction through wall accepted")
 wall=false;hrp.Position+=Vector3.new(50,0,0);check(not Guard.CanUse(player,prompt,12,clocks,world),"Out-of-range interaction accepted")
 hrp.Position=head.Position;prompt.Enabled=false;check(not Guard.CanUse(player,prompt,13,clocks,world),"Disabled interaction accepted")
 safety.interactionGuard=true;char:Destroy()
 local converted=game:GetService("ServerStorage"):FindFirstChild("SpringSourceConverted")
 check(converted and converted:FindFirstChild("MissDelightSource") and #converted.SourceAnimations:GetChildren()==5,"Converted source resources were not preserved")
 safety.convertedAssetsPreserved=converted~=nil
end
local lights=#Tags:GetTagged("DeadSignalMapLight")
check(lights>=20,"Lighting not distributed through map")
return {ok=#errors==0,errors=errors,build=W:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,mapAssetId=W:GetAttribute("MapSourceAssetId"),parts=parts,importedParts=importedParts,doors=doorCount,lightingControls=switchCount,lights=lights,externalScripts=external,invalidTransforms=mirrored,stalkerPaused=W:GetAttribute("StalkerPaused"),routes=routes,hubs=hubData,functionTests=safety,benchCount=W:GetAttribute("MapBenchCount")}
