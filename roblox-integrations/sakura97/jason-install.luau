assert(game.PlaceId==79738710219521 and game.GameId==9419478735,"Wrong place")
local SS=game:GetService("ServerStorage") local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService") local StarterPlayer=game:GetService("StarterPlayer") local SP=StarterPlayer.StarterPlayerScripts
StarterPlayer.DevCameraOcclusionMode=Enum.DevCameraOcclusionMode.Zoom
local AS=game:GetService("AssetService")
-- Remove legacy island build data. The Jason build only needs SurvivalAssets.
local legacyNature=SS:FindFirstChild("NatureTemplates")
if legacyNature then legacyNature:Destroy() end
local function replace(parent,name,class)
 local old=parent:FindFirstChild(name) if old then old:Destroy() end
 local obj=Instance.new(class) obj.Name=name obj.Parent=parent return obj
end
local function load(id)
 local last
 for attempt=1,3 do
  local ok,a=pcall(function() return AS:LoadAssetAsync(id) end)
  if ok and a then return a end last=a task.wait(attempt*2)
 end
 error("Cannot load exact asset "..id..": "..tostring(last))
end
local function sanitize(m,anchored)
 for _,v in ipairs(m:GetDescendants()) do
  if v:IsA("LuaSourceContainer") or v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then v:Destroy()
  elseif v:IsA("BasePart") then v.Anchored=anchored v.CanTouch=false end
 end
 for _,v in ipairs(m:GetDescendants()) do if v:IsA("SpawnLocation") then v.Enabled=false v.Transparency=1 v.CanCollide=false v.CanQuery=false end end
end
-- Fixed lobby snapshot supplied by the user as Violence_District.rbxlx.
-- The publisher uploads the script-free Lobby subtree as a private Model and injects
-- its immutable asset id here. Later releases preserve this exact visual snapshot.
local FIXED_LOBBY_ASSET_ID=__FIXED_LOBBY_ASSET_ID__
assert(type(FIXED_LOBBY_ASSET_ID)=="number" and FIXED_LOBBY_ASSET_ID>0,"Fixed lobby asset id missing")
local lobby=workspace:FindFirstChild("JediLibrary")
local needsFixedLobby=not lobby
 or lobby:GetAttribute("SourceAssetId")~=FIXED_LOBBY_ASSET_ID
 or lobby:GetAttribute("FixedLobbyRevision")~="violence-district-lobby-v1"

if needsFixedLobby then
 local asset=load(FIXED_LOBBY_ASSET_ID)
 local source=asset:FindFirstChild("Lobby",true)
 if not source and asset.Name=="Lobby" then source=asset end
 assert(source,"Fixed Violence District Lobby root missing from uploaded snapshot")

 local replacement=Instance.new("Model")
 replacement.Name="RequestedLobbyCandidate"
 for _,child in ipairs(source:GetChildren()) do child.Parent=replacement end
 asset:Destroy()
 sanitize(replacement,true)

 -- Preserve every internal transform from the supplied lobby. Only translate the
 -- entire snapshot as one rigid unit so it fits the Suvivers world near origin.
 replacement.Parent=workspace
 local beforeCF,beforeSize=replacement:GetBoundingBox()
 local shift=Vector3.new(-beforeCF.X,40-(beforeCF.Y-beforeSize.Y/2),-beforeCF.Z)
 replacement:PivotTo(replacement:GetPivot()+shift)

 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={replacement}
 params.RespectCanCollide=true

 -- Original Workspace SpawnLocation from Violence_District.rbxlx, translated by the
 -- exact same rigid shift as the lobby snapshot.
 local snapshotSpawn=Vector3.new(1970.8416748046875,734.043212890625,3812.6513671875)+shift
 local groundHit=workspace:Raycast(snapshotSpawn+Vector3.new(0,14,0),Vector3.new(0,-40,0),params)
 local ground=nil
 if groundHit and groundHit.Normal.Y>.82 and not workspace:Raycast(groundHit.Position+Vector3.new(0,.25,0),Vector3.new(0,7,0),params) then
  ground=groundHit.Position
 end

 -- Prefer an interior point just inside a real authored door. This keeps players
 -- inside the house near the entrance instead of dropping them in an arbitrary room.
 local lobbyCF,lobbySize=replacement:GetBoundingBox()
 local doorPart=nil local doorScore=math.huge
 local function doorText(obj)
  local names={string.lower(obj.Name)}
  local p=obj.Parent
  for _=1,4 do
   if not p or p==replacement then break end
   table.insert(names,string.lower(p.Name))
   p=p.Parent
  end
  return table.concat(names," ")
 end
 for _,part in ipairs(replacement:GetDescendants()) do
  if part:IsA("BasePart") then
   local text=doorText(part)
   if string.find(text,"door",1,true) or string.find(text,"entrance",1,true) then
    local d=(part.Position-snapshotSpawn).Magnitude
    if d<doorScore then doorScore=d doorPart=part end
   end
  end
 end
 if doorPart then
  local inward=Vector3.new(lobbyCF.Position.X-doorPart.Position.X,0,lobbyCF.Position.Z-doorPart.Position.Z)
  if inward.Magnitude<.1 then inward=Vector3.new(0,0,-1) else inward=inward.Unit end
  for _,distance in ipairs({5,7,9,11}) do
   local candidate=doorPart.Position+inward*distance
   local hit=workspace:Raycast(candidate+Vector3.new(0,10,0),Vector3.new(0,-24,0),params)
   if hit and hit.Normal.Y>.82 and not workspace:Raycast(hit.Position+Vector3.new(0,.25,0),Vector3.new(0,7,0),params) then
    ground=hit.Position
    replacement:SetAttribute("PreferredDoorPosition",doorPart.Position)
    replacement:SetAttribute("PreferredDoorSpawnDistance",distance)
    break
   end
  end
 end

 -- Fallback only if neither the authored door nor the original spawn point produced
 -- a safe interior floor. This never modifies the lobby itself.
 if not ground then
  local surfaces={}
  for _,part in ipairs(replacement:GetDescendants()) do
   if part:IsA("BasePart") and part.CanCollide and part.Transparency<.9 and part.CFrame.UpVector.Y>.94 and part.Size.X>=10 and part.Size.Z>=10 and part.Size.Y<=14 then
    table.insert(surfaces,part)
   end
  end
  table.sort(surfaces,function(x,y)
   local xd=(x.Position-snapshotSpawn).Magnitude
   local yd=(y.Position-snapshotSpawn).Magnitude
   return xd<yd
  end)
  for _,part in ipairs(surfaces) do
   local point=part.CFrame:PointToWorldSpace(Vector3.new(0,part.Size.Y/2,0))
   local hit=workspace:Raycast(point+Vector3.new(0,2,0),Vector3.new(0,-5,0),params)
   if hit and hit.Normal.Y>.85 and not workspace:Raycast(hit.Position+Vector3.new(0,.25,0),Vector3.new(0,7,0),params) then
    ground=hit.Position
    break
   end
  end
 end
 assert(ground,"Fixed Violence District lobby has no safe spawn floor after import")

 if lobby then lobby:Destroy() end
 lobby=replacement
 lobby.Name="JediLibrary"
 lobby:SetAttribute("SourceAssetId",FIXED_LOBBY_ASSET_ID)
 lobby:SetAttribute("FixedLobbyRevision","violence-district-lobby-v1")
 lobby:SetAttribute("FixedLobbySHA256","ec6fb99dec82f22eb24d23b885d1b980467cb91f20e2234a1a0fad3f7f4e43c2")
 lobby:SetAttribute("FixedLobbySourceFile","Violence_District.rbxlx")
 lobby:SetAttribute("FixedLobbyScriptsRemoved",1)
 lobby:SetAttribute("VerifiedSpawn",ground)
 lobby:SetAttribute("SnapshotSpawn",snapshotSpawn)

 -- The original SpawnLocation faces -X. Keep this as metadata used by the existing
 -- spawn-facing and guide placement code; no visible door geometry is added.
 local doorPosition=lobby:GetAttribute("PreferredDoorPosition")
 if typeof(doorPosition)=="Vector3" then
  lobby:SetAttribute("FormerDoorCFrame",CFrame.lookAt(doorPosition,ground))
 else
  lobby:SetAttribute("FormerDoorCFrame",CFrame.lookAt(ground+Vector3.new(-12,0,0),ground))
 end
end
-- Imported lobby meshes are visual first. Door/stair movement gets simple, predictable
-- collision so hollow meshes can never behave like invisible walls.
local house=assert(lobby:FindFirstChild("House"),"Authored lobby house missing")
local oldAccess=lobby:FindFirstChild("PassageColliders") if oldAccess then oldAccess:Destroy() end
local access=Instance.new("Folder",lobby) access.Name="PassageColliders"
local repairedFrames=0 local repairedMeshes=0 local removedBlockers=0 local openedDoorParts=0 local stairSteps=0
local repairParams=RaycastParams.new()
repairParams.FilterType=Enum.RaycastFilterType.Include
repairParams.FilterDescendantsInstances={lobby}
repairParams.RespectCanCollide=true

local function support(name,size,cf,kind)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Anchored=true
 p.Transparency=1 p.CanCollide=true p.CanTouch=false p.CanQuery=true p.CastShadow=false
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p:SetAttribute(kind or "PassageSupport",true) p.Parent=access return p
end

local function ancestryText(part)
 local names={string.lower(part.Name)}
 local parent=part.Parent
 for _=1,5 do
  if not parent or parent==house then break end
  table.insert(names,string.lower(parent.Name))
  parent=parent.Parent
 end
 return table.concat(names," ")
end

local function floorYAt(worldPoint,castTop,castDepth)
 local hit=workspace:Raycast(Vector3.new(worldPoint.X,castTop,worldPoint.Z),Vector3.new(0,-castDepth,0),repairParams)
 return hit and hit.Position.Y or nil
end

local function restoreAuthoredStair(part)
 local name=string.lower(part.Name)
 pcall(function() part.CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition end)
 part.CanCollide=true
 part.CanTouch=false
 part.CanQuery=true
 part:SetAttribute("VisualOnlyStair",nil)
 part:SetAttribute("WalkableReplacement",nil)
 if string.find(name,"house_foyer_stairs_lower",1,true) then
  part:SetAttribute("ClosedInteriorStair",true)
 else
  part:SetAttribute("AuthoredStairCollision",true)
 end
 repairedMeshes+=1
end

for _,part in ipairs(house:GetDescendants()) do
 if part:IsA("BasePart") then
  local name=string.lower(part.Name)
  local text=ancestryText(part)
  if part.Transparency>=.98 and not part:IsA("SpawnLocation") then
   part.CanCollide=false part.CanTouch=false part.CanQuery=false
   part:SetAttribute("InteriorBlockerDisabled",true) removedBlockers+=1
  elseif part:IsA("MeshPart") and (name=="double_door_frame" or name=="front_door_frame" or name=="shed_doorframe") then
   part.CanCollide=false part.CanTouch=false part:SetAttribute("OpenPassage",true)
   local width=part.Size.X local height=part.Size.Y local depth=part.Size.Z
   local opening=name=="front_door_frame" and math.min(8.1,width-1) or width-.9
   local clearHeight=math.min(7.65,height-.35)
   local post=math.max(.15,(width-opening)/2)
   support("DoorLeft",Vector3.new(post,height,depth),part.CFrame*CFrame.new(-(opening+post)/2,0,0))
   support("DoorRight",Vector3.new(post,height,depth),part.CFrame*CFrame.new((opening+post)/2,0,0))
   support("DoorLintel",Vector3.new(opening,math.max(.15,height-clearHeight),depth),part.CFrame*CFrame.new(0,clearHeight/2,0))
   part:SetAttribute("PassageWidth",opening) part:SetAttribute("PassageHeight",clearHeight)
   repairedFrames+=1 openedDoorParts+=1
  elseif string.find(text,"door",1,true) and not string.find(text,"floor",1,true) then
   part.CanCollide=false part.CanTouch=false
   part:SetAttribute("OpenPassage",true) openedDoorParts+=1
  elseif part:IsA("MeshPart") and (string.find(name,"stairs",1,true) or string.find(name,"side_stair",1,true) or name=="rail_stair") then
   restoreAuthoredStair(part)
  end
 end
end

-- Remove every invisible staircase support left by older repairs.
for _,part in ipairs(access:GetDescendants()) do
 if part:IsA("BasePart") and (part:GetAttribute("WalkableStairStep") or part:GetAttribute("UpperLandingBridge")) then
  part:Destroy()
 end
end
stairSteps=0

-- Upstairs is intentionally closed. Use the requested construction sign so the block
-- is visible and understandable instead of an invisible floor/wall.
local mainFoyer=nil
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") and string.find(string.lower(p.Name),"house_foyer_stairs_lower",1,true) then
  mainFoyer=p break
 end
end
local oldWarning=lobby:FindFirstChild("StairClosedSign")
if oldWarning then oldWarning:Destroy() end
if mainFoyer then
 local warningPackage=load(17143448214)
 local stairWarning=Instance.new("Model")
 stairWarning.Name="StairClosedSign"
 for _,child in ipairs(warningPackage:GetChildren()) do
  child:Clone().Parent=stairWarning
 end
 warningPackage:Destroy()
 for _,obj in ipairs(stairWarning:GetDescendants()) do
  if obj:IsA("LuaSourceContainer") or obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
   obj:Destroy()
  elseif obj:IsA("BasePart") then
   obj.Anchored=true obj.CanCollide=true obj.CanTouch=false obj.CanQuery=true
  end
 end
 local firstPart=assert(stairWarning:FindFirstChildWhichIsA("BasePart",true),"Construction sign asset has no BasePart")
 stairWarning.PrimaryPart=firstPart
 stairWarning.Parent=lobby
 local _,initialSize=stairWarning:GetBoundingBox()
 if initialSize.Y>.1 then
  pcall(function() stairWarning:ScaleTo(math.clamp(5.4/initialSize.Y,.35,2.5)) end)
 end
 local _,signSize=stairWarning:GetBoundingBox()
 local spawnHint=lobby:GetAttribute("VerifiedSpawn")
 local toward=typeof(spawnHint)=="Vector3" and Vector3.new(spawnHint.X-mainFoyer.Position.X,0,spawnHint.Z-mainFoyer.Position.Z) or -mainFoyer.CFrame.LookVector
 if toward.Magnitude<.1 then toward=-mainFoyer.CFrame.LookVector else toward=toward.Unit end
 local run=math.max(mainFoyer.Size.X,mainFoyer.Size.Z)
 local foot=mainFoyer.Position+toward*(run*.52+2.4)
 local rayParams=RaycastParams.new()
 rayParams.FilterType=Enum.RaycastFilterType.Include
 rayParams.FilterDescendantsInstances={lobby}
 rayParams.RespectCanCollide=true
 local hit=workspace:Raycast(foot+Vector3.new(0,24,0),Vector3.new(0,-60,0),rayParams)
 local floorY=hit and hit.Position.Y or (mainFoyer.Position.Y-mainFoyer.Size.Y/2)
 stairWarning:PivotTo(CFrame.lookAt(
  Vector3.new(foot.X,floorY+signSize.Y/2,foot.Z),
  Vector3.new(mainFoyer.Position.X,floorY+signSize.Y/2,mainFoyer.Position.Z)
 ))
 local label=Instance.new("BillboardGui")
 label.Name="NoUpstairsLabel"
 label.Adornee=firstPart
 label.Size=UDim2.fromOffset(170,52)
 label.StudsOffsetWorldSpace=Vector3.new(0,signSize.Y*.6,0)
 label.AlwaysOnTop=false
 label.MaxDistance=34
 label.Parent=stairWarning
 local text=Instance.new("TextLabel",label)
 text.Size=UDim2.fromScale(1,1)
 text.BackgroundColor3=Color3.fromRGB(12,12,12)
 text.BackgroundTransparency=.18
 text.BorderSizePixel=0
 text.Text="NÃO SUBA\nÁREA INTERDITADA"
 text.TextColor3=Color3.fromRGB(235,225,205)
 text.TextStrokeTransparency=.45
 text.TextScaled=true
 text.Font=Enum.Font.GothamBlack
 Instance.new("UICorner",text).CornerRadius=UDim.new(0,4)
 stairWarning:SetAttribute("SourceAssetId",17143448214)
 stairWarning:SetAttribute("BlocksUpperFloor",true)
end

lobby:SetAttribute("PassageRepairRevision",4)
lobby:SetAttribute("RepairedDoorFrames",repairedFrames)
lobby:SetAttribute("OpenedDoorParts",openedDoorParts)
lobby:SetAttribute("RepairedStairMeshes",repairedMeshes)
lobby:SetAttribute("WalkableStairSteps",0)
lobby:SetAttribute("ClearedFoyerRails",0)
lobby:SetAttribute("StairAccessClosed",true)
lobby:SetAttribute("StairWarningAssetId",17143448214)
lobby:SetAttribute("DisabledInteriorBlockers",removedBlockers)

local referenceCF=lobby:GetAttribute("FormerDoorCFrame")
if typeof(referenceCF)~="CFrame" then
 local legacy=lobby:FindFirstChild("Door") or lobby:FindFirstChild("OriginalLobbyDoor")
 referenceCF=legacy and legacy:GetPivot() or CFrame.new((lobby:GetAttribute("VerifiedSpawn") or Vector3.zero)+Vector3.new(12,8,0))
 lobby:SetAttribute("FormerDoorCFrame",referenceCF)
end
local original=referenceCF.Position
local rotation=referenceCF.Rotation
local lobbyParams=RaycastParams.new()
lobbyParams.FilterType=Enum.RaycastFilterType.Include
lobbyParams.FilterDescendantsInstances={lobby}
lobbyParams.RespectCanCollide=true
local verified=lobby:GetAttribute("VerifiedSpawn")
local floor
local doorForward=Vector3.new(rotation.LookVector.X,0,rotation.LookVector.Z)
if doorForward.Magnitude<.1 then doorForward=Vector3.new(1,0,0) else doorForward=doorForward.Unit end

-- Always prefer a safe point just INSIDE the authored doorway. FormerDoorCFrame points
-- from the door toward the previously verified interior floor, so its LookVector is the
-- inward direction. This is recalculated every publish instead of trusting an old spawn.
for _,distance in ipairs({4.5,6,7.5,9}) do
 local candidate=original+doorForward*distance
 local hit=workspace:Raycast(candidate+Vector3.new(0,9,0),Vector3.new(0,-22,0),lobbyParams)
 if hit and hit.Normal.Y>.85 and not workspace:Raycast(hit.Position+Vector3.new(0,.25,0),Vector3.new(0,7,0),lobbyParams) then
  floor=hit
  lobby:SetAttribute("LobbySpawnMode","InsideDoor")
  lobby:SetAttribute("LobbySpawnDoorDistance",(Vector3.new(hit.Position.X,original.Y,hit.Position.Z)-original).Magnitude)
  break
 end
end
if not floor and typeof(verified)=="Vector3" then
 floor=workspace:Raycast(verified+Vector3.new(0,10,0),Vector3.new(0,-24,0),lobbyParams)
 lobby:SetAttribute("LobbySpawnMode","VerifiedFallback")
end
if not floor then
 for _,candidate in ipairs({original-doorForward*12,original+doorForward*12,original-rotation.RightVector*10,original+rotation.RightVector*10}) do
  local hit=workspace:Raycast(candidate+Vector3.new(0,8,0),Vector3.new(0,-24,0),lobbyParams)
  if hit and hit.Normal.Y>.85 and not workspace:Raycast(hit.Position+Vector3.new(0,.25,0),Vector3.new(0,7,0),lobbyParams) then floor=hit lobby:SetAttribute("LobbySpawnMode","EmergencyFallback") break end
 end
end
assert(floor and floor.Normal.Y>.85,"Lobby safe spawn floor missing")
lobby:SetAttribute("VerifiedSpawn",floor.Position)
local spawn=assert(workspace:FindFirstChild("IslandSpawn"))
spawn.Size=Vector3.new(6,1,6)
local face=Vector3.new(original.X,floor.Position.Y,original.Z)
spawn.CFrame=CFrame.lookAt(floor.Position+Vector3.new(0,spawn.Size.Y/2+.08,0),face)
spawn.Enabled=true spawn.Neutral=true spawn.Transparency=1 spawn.CanCollide=false spawn.CanTouch=false spawn.CanQuery=false spawn.Duration=0
spawn.AllowTeamChangeOnTouch=false

-- The previous repair placed a green grass slab around Y=618, making the car,
-- garage and gate columns float. The authored exterior props meet the ground at ~625.03.
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,p in ipairs(house:GetDescendants()) do
 if p:IsA("BasePart") then
  minX=math.min(minX,p.Position.X-p.Size.X/2) maxX=math.max(maxX,p.Position.X+p.Size.X/2)
  minZ=math.min(minZ,p.Position.Z-p.Size.Z/2) maxZ=math.max(maxZ,p.Position.Z+p.Size.Z/2)
 end
end
local yardWidth=(maxX-minX)+260
local yardDepth=(maxZ-minZ)+260
local yardCenterX=(minX+maxX)/2
local yardCenterZ=(minZ+maxZ)/2
local authoredGroundY=625.031494140625

-- Remove the generated grass terrain from the older repair.
pcall(function()
 workspace.Terrain:FillBlock(
  CFrame.new(yardCenterX,615,yardCenterZ),
  Vector3.new(yardWidth+20,22,yardDepth+20),
  Enum.Material.Air
 )
end)

local oldGround=lobby:FindFirstChild("OutdoorGround")
if oldGround then oldGround:Destroy() end
local ground=Instance.new("Part")
ground.Name="OutdoorGround"
ground.Size=Vector3.new(yardWidth,4,yardDepth)
ground.CFrame=CFrame.new(yardCenterX,authoredGroundY-2,yardCenterZ)
ground.Anchored=true
ground.CanCollide=true ground.CanTouch=true ground.CanQuery=true
ground.Material=Enum.Material.Ground
ground.Color=Color3.fromRGB(78,72,64)
ground.TopSurface=Enum.SurfaceType.Smooth
ground.BottomSurface=Enum.SurfaceType.Smooth
ground:SetAttribute("PersistentOutdoorGround",true)
ground:SetAttribute("AuthoredHeightAligned",true)
ground.Parent=lobby
lobby:SetAttribute("OutdoorGroundReady",true)
lobby:SetAttribute("OutdoorGroundY",authoredGroundY)
lobby:SetAttribute("OutdoorGroundSize",ground.Size)
lobby:SetAttribute("OutdoorGroundMaterial","Ground")

local oldLobbyBounds=lobby:FindFirstChild("InvisibleBounds")
if oldLobbyBounds then oldLobbyBounds:Destroy() end
local lobbyBounds=Instance.new("Folder") lobbyBounds.Name="InvisibleBounds" lobbyBounds.Parent=lobby
local lobbyCF,lobbySize=lobby:GetBoundingBox()
local lobbyBottom=lobbyCF.Position.Y-lobbySize.Y/2
local function lobbyBarrier(name,size,localCF)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=lobbyCF*localCF
 p.Anchored=true p.CanCollide=true p.CanTouch=false p.CanQuery=true p.Transparency=1 p.CastShadow=false
 p:SetAttribute("InvisibleBoundary",true) p.Parent=lobbyBounds return p
end
local thick=6 local height=math.max(56,lobbySize.Y+24)
local localY=(lobbyBottom-lobbyCF.Position.Y)+height/2-4
lobbyBarrier("LeftWall",Vector3.new(thick,height,lobbySize.Z+thick*2),CFrame.new(-lobbySize.X/2-thick/2,localY,0))
lobbyBarrier("RightWall",Vector3.new(thick,height,lobbySize.Z+thick*2),CFrame.new(lobbySize.X/2+thick/2,localY,0))
lobbyBarrier("FrontWall",Vector3.new(lobbySize.X+thick*2,height,thick),CFrame.new(0,localY,-lobbySize.Z/2-thick/2))
lobbyBarrier("BackWall",Vector3.new(lobbySize.X+thick*2,height,thick),CFrame.new(0,localY,lobbySize.Z/2+thick/2))
local lobbySafety=lobbyBarrier("SafetyFloor",Vector3.new(lobbySize.X+thick*2,4,lobbySize.Z+thick*2),CFrame.new(0,(lobbyBottom-lobbyCF.Position.Y)-7,0))
lobbySafety:SetAttribute("SafetyFloor",true)
lobby:SetAttribute("InvisibleBoundsReady",true)

-- No lobby entry door remains. Keep only its old transform as metadata for spawn facing.
for _,name in ipairs({"Door","OriginalLobbyDoor"}) do
 local old=lobby:FindFirstChild(name)
 if old then old:Destroy() end
end

local oldVisual=workspace:FindFirstChild("SurviversLobbyDoorVisual")
if oldVisual then oldVisual:Destroy() end
local oldGate=workspace:FindFirstChild("LobbyJoinPortal")
if oldGate then oldGate:Destroy() end
lobby:SetAttribute("AutomaticRoundAdmission",true)

local runtime=assert(RS:FindFirstChild("SweanRuntime")) runtime:SetAttribute("Version",124) runtime:SetAttribute("PreservedLobby",true) runtime:SetAttribute("SurvivorRig","R6") runtime:SetAttribute("LobbySourceAssetId",FIXED_LOBBY_ASSET_ID) runtime:SetAttribute("FixedLobbyRevision","violence-district-lobby-v1")
runtime:SetAttribute("SpawnX",spawn.Position.X) runtime:SetAttribute("SpawnY",spawn.Position.Y) runtime:SetAttribute("SpawnZ",spawn.Position.Z)
workspace.StreamingEnabled=false
local storage=replace(SS,"SurvivalAssets","Folder")
local maps=Instance.new("Folder",storage) maps.Name="Maps"
local rigs=Instance.new("Folder",storage) rigs.Name="Killers"
local items=Instance.new("Folder",storage) items.Name="Items"
local net=replace(RS,"Survival","Folder")
replace(net,"Action","RemoteEvent") replace(net,"Update","RemoteEvent")
local config=replace(net,"Config","ModuleScript") config.Source=__CONFIG_SOURCE__
local settings=replace(net,"SettingsPanel","ModuleScript") settings.Source=__SETTINGS_SOURCE__
local bridge=replace(SSS,"SurvivalBridge","Folder")
for _,n in ipairs({"DeathRequest","DeathFinished","RoundEliminate","CancelDeath"}) do replace(bridge,n,"BindableEvent") end
local builder=replace(SSS,"MapBuilder","ModuleScript") builder.Source=__MAP_BUILDER_SOURCE__
local mapReports=require(builder).build(load,sanitize,maps)
local a
-- Keep original Jason body and all of its own animation clips; discard showcase and guest rigs.
a=load(125165599816440)
local source=assert(a:FindFirstChild("Jason",true),"Jason rig not found")
assert(source:IsA("Model") and source:FindFirstChildOfClass("Humanoid"),"Invalid Jason rig")
local victimRaw=Instance.new("Folder")
local function collectVictim(package,killerRoot,name)
 local holder=Instance.new("Folder") holder.Name=name holder.Parent=victimRaw
 for _,seq in ipairs(package:GetDescendants()) do
  if seq:IsA("KeyframeSequence") and not seq:IsDescendantOf(killerRoot) then
   local low=seq.Name:lower()
   if low:find("kill") or low:find("victim") or low:find("death") then seq:Clone().Parent=holder end
  end
 end
end
collectVictim(a,source,"Jason")
local rig=source:Clone() rig.Parent=nil a:Destroy() sanitize(rig,false)
rig.Name="Jason" rig:SetAttribute("SourceAssetId",125165599816440)
local root=assert(rig:FindFirstChild("HumanoidRootPart")) rig.PrimaryPart=root
local hum=rig:FindFirstChildOfClass("Humanoid")
-- Preserve the exact authored Jason body proportions and rig offsets from the source asset.
rig:SetAttribute("SourceRootSize",root.Size)
rig:SetAttribute("SourceHipHeight",hum.HipHeight)
rig:SetAttribute("SourcePivot",rig:GetPivot())
hum.RequiresNeck=false hum.BreakJointsOnDeath=false hum.MaxHealth=1000 hum.Health=1000 hum.WalkSpeed=11 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
-- Compact exact poses as JSON, avoiding tens of thousands of replicated Instances.
local function compact(folder,destination)
 for _,seq in ipairs(folder:GetDescendants()) do if seq:IsA("KeyframeSequence") then
  local frames=seq:GetKeyframes() table.sort(frames,function(x,y) return x.Time<y.Time end)
  local data={length=frames[#frames].Time,frames={}}
  for _,f in ipairs(frames) do
   local poses={}
   for _,p in ipairs(f:GetDescendants()) do
    if p:IsA("Pose") and p.Weight>0 then
     local components={p.CFrame:GetComponents()}
     for i,value in ipairs(components) do components[i]=math.round(value*100000)/100000 end
     poses[p.Name]={c=components,e=p.EasingStyle.Name,d=p.EasingDirection.Name,w=p.Weight}
    end
   end
   table.insert(data.frames,{time=f.Time,poses=poses})
  end
  local json=game:GetService("HttpService"):JSONEncode(data)
  local encoder=game:GetService("EncodingService")
  local packed=buffer.tostring(encoder:Base64Encode(encoder:CompressBuffer(buffer.fromstring(json),Enum.CompressionAlgorithm.Zstd,19)))
  local clip=Instance.new("Folder",destination) clip.Name=seq.Name clip:SetAttribute("Length",data.length) clip:SetAttribute("ChunkCount",math.ceil(#packed/100000))
  for offset=1,#packed,100000 do local value=Instance.new("StringValue",clip) value.Name=string.format("%04d",math.floor((offset-1)/100000)+1) value.Value=packed:sub(offset,offset+99999) end
 end end
 destination:SetAttribute("ClipCount",#destination:GetChildren())
end
local clips=Instance.new("Folder",rig) clips.Name="MotionClips"
local saves=assert(rig:FindFirstChild("AnimSaves")) compact(saves,clips) saves:Destroy()
rig.Parent=rigs
-- A tiny presentation copy keeps only the winning pose clip, not the full combat animation library.
local portrait=rig:Clone() portrait.Name="PresentationJason"
for _,clip in ipairs(portrait.MotionClips:GetChildren()) do if clip.Name~="Winning Screen" then clip:Destroy() end end
portrait.MotionClips:SetAttribute("ClipCount",#portrait.MotionClips:GetChildren())
assert(portrait.MotionClips:FindFirstChild("Winning Screen"),"Winning animation missing")
for _,p in ipairs(portrait:GetDescendants()) do
 if p:IsA("BasePart") then p.Anchored=p==portrait.PrimaryPart p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false end
end
portrait.Parent=net

-- Exact requested skins with explicit animation provenance and canonical playback slots.
local johnAsset=load(103232099547025)
local johnSource=assert(johnAsset:FindFirstChild("John",true),"John Doe rig missing")
local donor=Instance.new("Folder")
compact(johnSource,donor)
if not donor:FindFirstChild("Idle") then donor:Destroy() donor=Instance.new("Folder") compact(johnAsset,donor) end
local coolAsset=load(125287203669107)
local cool=Instance.new("Folder") compact(coolAsset,cool) coolAsset:Destroy()
local function slot(destination,name,source,original,id)
 local clip=assert(source:FindFirstChild(original),"Missing animation "..original):Clone()
 clip.Name=name clip:SetAttribute("OriginalClipName",original) clip:SetAttribute("SourceAssetId",id) clip.Parent=destination
end
-- Shared compressed motion libraries prevent the same animation payload from being embedded in every pursuer rig.
local motionLibraries=Instance.new("Folder",net) motionLibraries.Name="KillerMotionLibraries"
local defaultMotion=Instance.new("Folder",motionLibraries) defaultMotion.Name="Default"
for _,motion in ipairs({"Idle","Walk","Run"}) do slot(defaultMotion,"Jason "..motion,donor,motion,103232099547025) end
slot(defaultMotion,"Jason Slash",donor,"Slash",103232099547025)
slot(defaultMotion,"Jason_Kill",donor,"Kill",103232099547025)
slot(defaultMotion,"Jason Intro",donor,"JohnDoe Intro",103232099547025)
slot(defaultMotion,"Winning Screen",donor,"JohnDoe Outro",103232099547025)
defaultMotion:SetAttribute("ClipCount",#defaultMotion:GetChildren())

local coolMotion=Instance.new("Folder",motionLibraries) coolMotion.Name="Cool"
for _,motion in ipairs({"Idle","Walk","Run"}) do slot(coolMotion,"Jason "..motion,cool,"M4C00lkidd_"..motion,125287203669107) end
slot(coolMotion,"Jason Slash",donor,"Slash",103232099547025)
slot(coolMotion,"Jason_Kill",donor,"Kill",103232099547025)
slot(coolMotion,"Jason Intro",donor,"JohnDoe Intro",103232099547025)
slot(coolMotion,"Winning Screen",donor,"JohnDoe Outro",103232099547025)
coolMotion:SetAttribute("ClipCount",#coolMotion:GetChildren())

local function authoredMotionLibrary(asset,name,assetId)
 local library=Instance.new("Folder")
 library.Name=name
 local aliases={}
 local function canonical(raw)
  local n=string.lower(raw or "")
  if string.find(n,"idle",1,true) then return "Jason Idle" end
  if string.find(n,"walk",1,true) then return "Jason Walk" end
  if string.find(n,"run",1,true) or string.find(n,"sprint",1,true) then return "Jason Run" end
  if string.find(n,"strike",1,true) or string.find(n,"attack",1,true) or string.find(n,"slash",1,true) or string.find(n,"swing",1,true) then return "Jason Slash" end
  if string.find(n,"kill",1,true) or string.find(n,"execute",1,true) then return "Jason_Kill" end
  return nil
 end
 for _,obj in ipairs(asset:GetDescendants()) do
  if obj:IsA("KeyframeSequence") then
   local wanted=canonical(obj.Name)
   if wanted and not aliases[wanted] then
    local holder=Instance.new("Folder") local seq=obj:Clone() seq.Name=wanted seq.Parent=holder
    compact(holder,library) holder:Destroy()
    aliases[wanted]=true
   end
  elseif obj:IsA("Animation") and obj.AnimationId~="" then
   local wanted=canonical(obj.Name)
   if wanted and not aliases[wanted] then
    local ok,seq=pcall(function() return game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync(obj.AnimationId) end)
    if ok and seq then
     local holder=Instance.new("Folder") seq.Name=wanted seq.Parent=holder
     compact(holder,library) holder:Destroy()
     aliases[wanted]=true
    end
   end
  end
 end
 for _,wanted in ipairs({"Jason Idle","Jason Walk","Jason Run","Jason Slash","Jason_Kill"}) do
  if not library:FindFirstChild(wanted) then
   local fallback=defaultMotion:FindFirstChild(wanted) or defaultMotion:FindFirstChild(wanted=="Jason_Kill" and "Jason Slash" or wanted)
   if fallback then fallback:Clone().Parent=library end
  end
 end
 library:SetAttribute("ClipCount",#library:GetChildren())
 library:SetAttribute("SourceAssetId",assetId)
 library.Parent=motionLibraries
 return library.Name
end

local function findPursuerRig(asset,rootName)
 local function usable(model)
  return model and model:IsA("Model") and model:FindFirstChildWhichIsA("BasePart",true)
 end
 if rootName then
  local exact=asset:FindFirstChild(rootName,true)
  if usable(exact) then return exact end
 end
 local best=nil local bestScore=-math.huge
 local candidates={}
 if usable(asset) then table.insert(candidates,asset) end
 for _,obj in ipairs(asset:GetDescendants()) do if usable(obj) then table.insert(candidates,obj) end end
 for _,obj in ipairs(candidates) do
  local parts=0
  for _,d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then parts+=1 end end
  local score=parts
  if obj:FindFirstChildOfClass("Humanoid") then score+=200 end
  if obj:FindFirstChildOfClass("AnimationController") then score+=120 end
  if obj:FindFirstChild("HumanoidRootPart",true) then score+=80 end
  local n=string.lower(obj.Name)
  if string.find(n,"krampus",1,true) or string.find(n,"piggy",1,true) or string.find(n,"figure",1,true) then score+=60 end
  if score>bestScore then best=obj bestScore=score end
 end
 return best
end

local function ensurePursuerHumanoid(model)
 local h=model:FindFirstChildOfClass("Humanoid")
 if not h then
  local controller=model:FindFirstChildOfClass("AnimationController")
  if controller then controller:Destroy() end
  h=Instance.new("Humanoid") h.Name="Humanoid" h.Parent=model
 end
 local root=model:FindFirstChild("HumanoidRootPart")
 if not root then
  local torso=model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("LowerTorso") or model:FindFirstChildWhichIsA("BasePart",true)
  assert(torso and torso:IsA("BasePart"),model.Name.." has no usable root")
  root=Instance.new("Part") root.Name="HumanoidRootPart" root.Size=Vector3.new(2,2,1) root.Transparency=1 root.CanCollide=false root.CanTouch=false root.CanQuery=false root.Massless=true root.CFrame=torso.CFrame root.Parent=model
  local motor=Instance.new("Motor6D") motor.Name="RootJoint" motor.Part0=root motor.Part1=torso motor.Parent=root
 end
 model.PrimaryPart=root
 h.RequiresNeck=false h.BreakJointsOnDeath=false h.MaxHealth=1000 h.Health=1000 h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 return h,root
end

local function fallbackPursuerRig(name)
 local model=Instance.new("Model") model.Name=name
 local function part(n,size,color,cf,shape)
  local p=Instance.new("Part") p.Name=n p.Size=size p.Color=color p.Material=Enum.Material.SmoothPlastic
  if shape then p.Shape=shape end
  p.CFrame=cf p.CanCollide=false p.Massless=n~="HumanoidRootPart" p.Parent=model
  return p
 end
 local root=part("HumanoidRootPart",Vector3.new(2,2,1),Color3.new(),CFrame.new()) root.Transparency=1 root.Massless=false
 local pig=name=="Piggy"
 local skin=pig and Color3.fromRGB(244,166,176) or Color3.fromRGB(92,53,47)
 local torso=part("Torso",Vector3.new(2,2,1),pig and Color3.fromRGB(168,48,53) or Color3.fromRGB(55,43,39),CFrame.new(0,0,0))
 local head=part("Head",Vector3.new(2,1,1),skin,CFrame.new(0,1.5,0),Enum.PartType.Ball)
 local la=part("Left Arm",Vector3.new(1,2,1),skin,CFrame.new(-1.5,0,0))
 local ra=part("Right Arm",Vector3.new(1,2,1),skin,CFrame.new(1.5,0,0))
 local ll=part("Left Leg",Vector3.new(1,2,1),pig and Color3.fromRGB(34,34,37) or Color3.fromRGB(43,38,35),CFrame.new(-.5,-2,0))
 local rl=part("Right Leg",Vector3.new(1,2,1),pig and Color3.fromRGB(34,34,37) or Color3.fromRGB(43,38,35),CFrame.new(.5,-2,0))
 local function motor(n,p0,p1,c0,c1)
  local m=Instance.new("Motor6D") m.Name=n m.Part0=p0 m.Part1=p1 m.C0=c0 or CFrame.identity m.C1=c1 or CFrame.identity m.Parent=p0
 end
 motor("RootJoint",root,torso)
 motor("Neck",torso,head,CFrame.new(0,1,0),CFrame.new(0,-.5,0))
 motor("Left Shoulder",torso,la,CFrame.new(-1,0,0),CFrame.new(.5,0,0))
 motor("Right Shoulder",torso,ra,CFrame.new(1,0,0),CFrame.new(-.5,0,0))
 motor("Left Hip",torso,ll,CFrame.new(-.5,-1,0),CFrame.new(0,1,0))
 motor("Right Hip",torso,rl,CFrame.new(.5,-1,0),CFrame.new(0,1,0))
 if pig then
  local snout=part("Snout",Vector3.new(.72,.42,.45),Color3.fromRGB(231,137,151),head.CFrame*CFrame.new(0,-.05,-.72))
  local weld=Instance.new("WeldConstraint") weld.Part0=head weld.Part1=snout weld.Parent=snout
  for _,x in ipairs({-.55,.55}) do
   local ear=part("Ear",Vector3.new(.38,.55,.25),skin,head.CFrame*CFrame.new(x,.65,-.05))
   local ew=Instance.new("WeldConstraint") ew.Part0=head ew.Part1=ear ew.Parent=ear
  end
 else
  for _,x in ipairs({-.55,.55}) do
   local horn=part("Horn",Vector3.new(.25,.9,.25),Color3.fromRGB(45,37,31),head.CFrame*CFrame.new(x,.85,0))
   local hw=Instance.new("WeldConstraint") hw.Part0=head hw.Part1=horn hw.Parent=horn
  end
 end
 local h=Instance.new("Humanoid") h.RigType=Enum.HumanoidRigType.R6 h.RequiresNeck=false h.BreakJointsOnDeath=false h.Parent=model
 model.PrimaryPart=root
 return model
end

for _,spec in ipairs({
 {name="JohnDoe",id=103232099547025,root="John"},

 {name="Chucky",id=95580261594507,root="Chucky",cool=true},
 {name="Krampus",id=92081889778550,authored=true},
 {name="Piggy",id=8762062897,authored=true},
}) do
 local asset=spec.name=="JohnDoe" and johnAsset or load(spec.id)
 local source=findPursuerRig(asset,spec.root)
 if source then collectVictim(asset,source,spec.name) end
 local libraryName=nil
 if spec.authored then libraryName=authoredMotionLibrary(asset,spec.name,spec.id) end
 if spec.name=="Chucky" and source and not source:FindFirstChildOfClass("Humanoid") then
  for _,candidate in ipairs(source:GetDescendants()) do
   if candidate:IsA("Model") and candidate:FindFirstChildOfClass("Humanoid") then source=candidate break end
  end
 end
 local model=source and source:Clone() or fallbackPursuerRig(spec.name)
 if spec.name=="Chucky" then
  for _,nested in ipairs(model:GetDescendants()) do
   if nested:IsA("Model") and nested:FindFirstChildOfClass("Humanoid") then nested:Destroy() end
  end
 end
 sanitize(model,false) model.Name=spec.name
 for _,v in ipairs(model:GetDescendants()) do
  if v:IsA("KeyframeSequence") then v:Destroy() end
 end
 local h,root=ensurePursuerHumanoid(model)
 model:SetAttribute("SourceAssetId",spec.id) model:SetAttribute("SourceRootSize",root.Size) model:SetAttribute("SourceHipHeight",h.HipHeight)
 model:SetAttribute("MotionLibrary",libraryName or (spec.cool and "Cool" or "Default"))
 model.Parent=rigs
 if asset~=johnAsset then asset:Destroy() end
end
johnAsset:Destroy() donor:Destroy() cool:Destroy()

local oldPreviews=net:FindFirstChild("KillerPreviews")
if oldPreviews then oldPreviews:Destroy() end
local killerPreviews=Instance.new("Folder",net)
killerPreviews.Name="KillerPreviews"
for _,killer in ipairs(rigs:GetChildren()) do
 local preview=killer:Clone()
 preview.Name=killer.Name
 for _,obj in ipairs(preview:GetDescendants()) do
  if obj:IsA("LuaSourceContainer") or obj:IsA("Humanoid") or obj:IsA("AnimationController") or obj:IsA("KeyframeSequence") or obj:IsA("Animation") then
   obj:Destroy()
  elseif obj:IsA("BasePart") then
   obj.Anchored=true obj.CanCollide=false obj.CanTouch=false obj.CanQuery=false
  end
 end
 preview:SetAttribute("ShopPreview",true)
 preview.Parent=killerPreviews
end
killerPreviews:SetAttribute("Count",#killerPreviews:GetChildren())

-- Original victim tracks when present; authored paired reactions for packs without a victim rig.
local victimLibraries=Instance.new("Folder",net) victimLibraries.Name="VictimMotionLibraries"
local reactions={Jason={impact=.40,twist=-18,fall=82},JohnDoe={impact=.47,twist=25,fall=88},Chucky={impact=.32,twist=-30,fall=92},Krampus={impact=.62,twist=28,fall=93},Piggy={impact=.43,twist=-25,fall=86}}
for _,killer in ipairs(rigs:GetChildren()) do
 local motion=killer:FindFirstChild("MotionClips") or motionLibraries:FindFirstChild(killer:GetAttribute("MotionLibrary") or "Default")
 local execution=motion and (motion:FindFirstChild("Jason_Kill") or motion:FindFirstChild("Kill"))
 local duration=math.clamp(execution and execution:GetAttribute("Length") or 2.5,1.5,7)
 killer:SetAttribute("ExecutionLength",duration)
 killer:SetAttribute("KillerKind",killer.Name)
 local folder=Instance.new("Folder",victimLibraries) folder.Name=killer.Name
 local authored=victimRaw:FindFirstChild(killer.Name)
 if authored and #authored:GetChildren()>0 then
  local seq=authored:GetChildren()[1] seq.Name="VictimExecution"
  local only=Instance.new("Folder") seq.Parent=only compact(only,folder) only:Destroy()
  folder:SetAttribute("Provenance","Asset victim track")
 else
  local spec=reactions[killer.Name] or reactions.Jason
  local sequence=Instance.new("KeyframeSequence") sequence.Name="VictimExecution"
  for _,key in ipairs({{0,0,0},{.16,.2,0},{spec.impact-.06,.5,0},{spec.impact,1,0},{spec.impact+.10,.7,.08},{.88,.3,.9},{1,0,1}}) do
   local t,pulse,fall=key[1],key[2],key[3]
   local frame=Instance.new("Keyframe") frame.Time=t*duration frame.Parent=sequence
   local poses={
    Torso=CFrame.new(0,-1.5*fall,.25*fall)*CFrame.Angles(math.rad(6+spec.fall*fall+8*pulse),0,math.rad(spec.twist*pulse)),
    Head=CFrame.Angles(math.rad(-14*pulse+12*fall),0,math.rad(-spec.twist*pulse*.5)),
    ["Left Arm"]=CFrame.Angles(math.rad(35*pulse-15*fall),math.rad(-12*pulse),math.rad(-24*pulse-9*fall)),
    ["Right Arm"]=CFrame.Angles(math.rad(55*pulse-8*fall),math.rad(8*pulse),math.rad(30*pulse+18*fall)),
    ["Left Leg"]=CFrame.Angles(math.rad(-18*pulse+12*fall),0,math.rad(-10*fall)),
    ["Right Leg"]=CFrame.Angles(math.rad(12*pulse-16*fall),0,math.rad(12*fall)),
   }
   for name,cf in pairs(poses) do local pose=Instance.new("Pose") pose.Name=name pose.CFrame=cf pose.Weight=1 pose.EasingStyle=Enum.PoseEasingStyle.Cubic pose.EasingDirection=Enum.PoseEasingDirection.InOut pose.Parent=frame end
  end
  local only=Instance.new("Folder") sequence.Parent=only compact(only,folder) only:Destroy()
  folder:SetAttribute("Provenance","Authored paired R6 reaction")
 end
 folder:SetAttribute("Killer",killer.Name)
end
victimRaw:Destroy()


local flashlightAsset=load(4573262309)
local flashlightSource=flashlightAsset:FindFirstChildWhichIsA("Tool",true)
assert(flashlightSource,"LANTERNA asset 4573262309 contains no Tool")
local flashlight=flashlightSource:Clone()
flashlight.Name="Flashlight"
flashlight:SetAttribute("SourceAssetId",4573262309)
sanitize(flashlight,false)
local flashlightHandle=assert(flashlight:FindFirstChild("Handle"),"LANTERNA Tool has no Handle")
for _,p in ipairs(flashlight:GetDescendants()) do
 if p:IsA("BasePart") then p.Anchored=false p.CanCollide=false p.CanTouch=false p.Massless=true end
end
flashlight.Parent=items
flashlightAsset:Destroy()

local function storeObjectiveAsset(id,name)
 local asset=load(id)
 sanitize(asset,true)
 local source=nil
 if asset:IsA("Model") and asset:FindFirstChildWhichIsA("BasePart",true) then source=asset end
 if not source then
  for _,obj in ipairs(asset:GetDescendants()) do
   if obj:IsA("Model") and (obj:FindFirstChildWhichIsA("BasePart",true) or obj:FindFirstChildWhichIsA("MeshPart",true)) then source=obj break end
  end
 end
 if not source then
  local tool=asset:FindFirstChildWhichIsA("Tool",true)
  if tool then
   local model=Instance.new("Model")
   model.Name=name
   for _,child in ipairs(tool:GetChildren()) do
    if not child:IsA("LuaSourceContainer") then child:Clone().Parent=model end
   end
   source=model
  end
 end
 if not source then
  local part=asset:FindFirstChildWhichIsA("BasePart",true)
  if part then
   local model=Instance.new("Model")
   local copy=part:Clone() copy.Parent=model model.PrimaryPart=copy
   source=model
  end
 end
 assert(source,"Objective asset "..id.." has no usable world model")
 local template=source:Clone()
 template.Name=name
 sanitize(template,true)
 local primary=template.PrimaryPart or template:FindFirstChild("Handle",true) or template:FindFirstChildWhichIsA("BasePart",true)
 assert(primary and primary:IsA("BasePart"),"Objective asset "..id.." has no BasePart")
 template.PrimaryPart=primary
 for _,part in ipairs(template:GetDescendants()) do
  if part:IsA("BasePart") then
   part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=true
  end
 end
 template:SetAttribute("SourceAssetId",id)
 template.Parent=items
 asset:Destroy()
 return template
end
local computerTemplate=storeObjectiveAsset(4845271739,"ComputerTemplate")
local keyTemplate=storeObjectiveAsset(11471202845,"KeyTemplate")
local coin=storeObjectiveAsset(10737243803,"CoinDisplay") coin.Parent=net
local _,coinSize=coin:GetBoundingBox() if coinSize.Magnitude>5 then coin:ScaleTo(coin:GetScale()*3/coinSize.Magnitude) end

local inventoryAsset=load(73852738603629)
local inventoryGui=inventoryAsset:FindFirstChildWhichIsA("ScreenGui",true)
if inventoryGui then
 local copy=inventoryGui:Clone()
 for _,obj in ipairs(copy:GetDescendants()) do if obj:IsA("LuaSourceContainer") then obj:Destroy() end end
 copy.Name="InventoryTemplate"
 copy:SetAttribute("SourceAssetId",73852738603629)
 copy.Parent=net
else
 net:SetAttribute("InventoryAssetId",73852738603629)
end
inventoryAsset:Destroy()
local walkingAsset=load(137365042825200)
local walkingSound=walkingAsset:FindFirstChildWhichIsA("Sound",true)
if walkingSound then
 local copy=walkingSound:Clone()
 copy.Name="FootstepSound"
 copy:SetAttribute("SourceAssetId",137365042825200)
 copy.Parent=net
end
walkingAsset:Destroy()
net:SetAttribute("ComputerAssetId",4845271739)
net:SetAttribute("KeyAssetId",11471202845)
net:SetAttribute("InventoryAssetId",73852738603629)
net:SetAttribute("FootstepAssetId",137365042825200)

-- No automatic game music. Keep only explicit player-triggered audio and interface/SFX.
local media=RS:FindFirstChild("XNMedia")
if media then
 local oldVoidMusic=media:FindFirstChild("VoidMusic")
 if oldVoidMusic then oldVoidMusic:Destroy() end
end
for _,root in ipairs({game:GetService("SoundService"),workspace,RS}) do
 for _,obj in ipairs(root:GetDescendants()) do
  if obj:IsA("Sound") and (obj.Name=="LocalJasonTheme" or obj.Name=="JasonTheme" or obj.Name=="VoidMusic") then
   obj:Destroy()
  end
 end
end

local survivorAsset=load(127092032896760)
local survivor=Instance.new("Folder",net) survivor.Name="SurvivorClips" survivor:SetAttribute("SourceAssetId",127092032896760)
local survivorSaves=survivorAsset:FindFirstChild("AnimSaves",true) or survivorAsset
compact(survivorSaves,survivor) survivorAsset:Destroy()
assert((survivor:GetAttribute("ClipCount") or 0)>0,"Forsaken Survivor Animations contains no KeyframeSequence")

-- Extra survivor action animations supplied by the user.
-- These are compacted into the same custom playback format, so R6 retargeting and
-- blend logic stay consistent with the existing Forsaken survivor locomotion.
local actionIds={
 Parry=127096285501517,
 BreakPallet=112166042383605,
 CrouchWalk=126965695851149,
 InjuredCrouchWalk=135084204086504,
 Stun=123047897844134,
 Vault=83873880822918,
}
local actionClips=Instance.new("Folder",net) actionClips.Name="SurvivorActionClips"
local kfsp=game:GetService("KeyframeSequenceProvider")
local function importActionClip(name,id)
 local sequence=nil
 local ok,seq=pcall(function() return kfsp:GetKeyframeSequenceAsync("rbxassetid://"..id) end)
 if ok and seq then sequence=seq end
 if not sequence then
  local asset=load(id)
  local direct=asset:FindFirstChildWhichIsA("KeyframeSequence",true)
  if direct then sequence=direct:Clone() end
  if not sequence then
   local anim=asset:FindFirstChildWhichIsA("Animation",true)
   if anim and anim.AnimationId~="" then
    local ok2,seq2=pcall(function() return kfsp:GetKeyframeSequenceAsync(anim.AnimationId) end)
    if ok2 and seq2 then sequence=seq2 end
   end
  end
  asset:Destroy()
 end
 assert(sequence,"Could not import survivor action animation "..name.." ("..id..")")
 sequence.Name=name
 local holder=Instance.new("Folder")
 sequence.Parent=holder
 compact(holder,actionClips)
 holder:Destroy()
 actionClips:SetAttribute(name.."AssetId",id)
end
local importedActions={}
for _,name in ipairs({"Parry","BreakPallet","CrouchWalk","InjuredCrouchWalk","Stun","Vault"}) do
 actionClips:SetAttribute(name.."RequestedAssetId",actionIds[name])
 local ok,err=pcall(importActionClip,name,actionIds[name])
 if ok then
  importedActions[name]=true
 else
  actionClips:SetAttribute(name.."Unavailable",true)
  actionClips:SetAttribute(name.."UnavailableReason",tostring(err):sub(1,500))
  warn("Optional survivor animation unavailable: "..name.." ("..actionIds[name]..") "..tostring(err))
 end
end
local function fallbackActionClip(targetName,wantInjured)
 local candidates={}
 for _,clip in ipairs(survivor:GetChildren()) do
  if clip:IsA("Folder") then
   local low=string.lower(clip.Name)
   local score=0
   if string.find(low,"walk",1,true) or string.find(low,"move",1,true) then score+=100 end
   if string.find(low,"run",1,true) then score+=35 end
   if string.find(low,"idle",1,true) then score+=10 end
   local injuredName=string.find(low,"injur",1,true)~=nil or string.find(low,"hurt",1,true)~=nil
   if wantInjured==injuredName then score+=80 elseif wantInjured then score-=30 end
   table.insert(candidates,{clip=clip,score=score})
  end
 end
 table.sort(candidates,function(a,b) return a.score>b.score end)
 local picked=candidates[1] and candidates[1].clip
 assert(picked,"No survivor locomotion clip exists for crouch fallback")
 local clone=picked:Clone()
 clone.Name=targetName
 clone.Parent=actionClips
 actionClips:SetAttribute(targetName.."Fallback",true)
 actionClips:SetAttribute(targetName.."FallbackSource",picked.Name)
 actionClips:SetAttribute(targetName.."AssetId",survivor:GetAttribute("SourceAssetId"))
 importedActions[targetName]=true
end
if not importedActions.CrouchWalk then fallbackActionClip("CrouchWalk",false) end
if not importedActions.InjuredCrouchWalk then fallbackActionClip("InjuredCrouchWalk",true) end

local function fallbackStaticActionClip(targetName,wantInjured)
 local candidates={}
 for _,clip in ipairs(survivor:GetChildren()) do
  if clip:IsA("Folder") then
   local low=string.lower(clip.Name)
   local score=0
   if string.find(low,"idle",1,true) or string.find(low,"stand",1,true) then score+=120 end
   if string.find(low,"injur",1,true) or string.find(low,"hurt",1,true) then
    if wantInjured then score+=80 else score-=20 end
   elseif wantInjured then
    score-=10
   end
   if string.find(low,"walk",1,true) then score+=20 end
   if string.find(low,"run",1,true) then score+=5 end
   table.insert(candidates,{clip=clip,score=score})
  end
 end
 table.sort(candidates,function(a,b) return a.score>b.score end)
 local picked=candidates[1] and candidates[1].clip
 assert(picked,"No survivor clip exists for static action fallback")
 local clone=picked:Clone()
 clone.Name=targetName
 clone.Parent=actionClips
 actionClips:SetAttribute(targetName.."Fallback",true)
 actionClips:SetAttribute(targetName.."FallbackSource",picked.Name)
 actionClips:SetAttribute(targetName.."AssetId",survivor:GetAttribute("SourceAssetId"))
 importedActions[targetName]=true
end

if not importedActions.Stun then fallbackStaticActionClip("Stun",true) end
actionClips:SetAttribute("ClipCount",#actionClips:GetChildren())
actionClips:SetAttribute("RequestedClipCount",6)
actionClips:SetAttribute("RequiredClipCount",3)
assert(importedActions.CrouchWalk and importedActions.InjuredCrouchWalk and importedActions.Stun,"Required survivor action fallbacks are missing")
assert((actionClips:GetAttribute("ClipCount") or 0)>=3,"Required survivor action clips are missing")

local function scriptAt(parent,name,class,sourceCode) local s=replace(parent,name,class) s.Source=sourceCode return s end
scriptAt(SSS,"IslandServer","Script",__ISLAND_SERVER_SOURCE__)
scriptAt(SP,"VoidSequence","LocalScript",__VOID_SOURCE__)
scriptAt(SP,"ArenaAmbience","LocalScript",__AMBIENCE_SOURCE__)
scriptAt(SSS,"ProfileService","ModuleScript",__PROFILE_SOURCE__)
scriptAt(SSS,"RoundRules","ModuleScript",__RULES_SOURCE__)
scriptAt(SSS,"PursuerAI","ModuleScript",__AI_SOURCE__)
scriptAt(SSS,"KillerFactory","ModuleScript",__KILLER_FACTORY_SOURCE__)
scriptAt(SSS,"SurvivalServer","Script",__SURVIVAL_SERVER_SOURCE__)
scriptAt(SP,"SurvivalClient","LocalScript",__SURVIVAL_CLIENT_SOURCE__)
scriptAt(SP,"PursuerAnimation","LocalScript",__ANIMATION_SOURCE__)

local nametagService=SSS:FindFirstChild("NametagService")
if not nametagService then
 local nameAsset=load(123212555736117)
 local tag=assert(nameAsset:FindFirstChild("Nametag",true),"Nametag asset missing")
 nametagService=Instance.new("Script") nametagService.Name="NametagService"
 tag:Clone().Parent=nametagService nametagService.Parent=SSS
 nameAsset:Destroy()
end
nametagService.Source=__NAMETAG_SOURCE__
nametagService:SetAttribute("AssetId",123212555736117)

local friendPresence=SP:FindFirstChild("FriendPresence")
if not friendPresence then friendPresence=Instance.new("LocalScript") friendPresence.Name="FriendPresence" friendPresence.Parent=SP end
friendPresence.Source=__FRIENDS_SOURCE__

net:SetAttribute("Version",126) net:SetAttribute("MaxParticipants",8) net:SetAttribute("SurvivorRig","R6")
net:SetAttribute("MissionStage","Waiting") net:SetAttribute("ComputersDone",0) net:SetAttribute("ComputersRequired",3)
local light=game:GetService("Lighting")
-- Fixed environment copied from the supplied Violence_District.rbxlx.
light.ClockTime=5
light.Brightness=3
light.Ambient=Color3.fromRGB(78,102,108)
light.OutdoorAmbient=Color3.fromRGB(93,104,124)
light.ColorShift_Top=Color3.fromRGB(62,78,81)
light.ExposureCompensation=0
light.GlobalShadows=true
light.ShadowSoftness=.2
light.EnvironmentDiffuseScale=.222
light.EnvironmentSpecularScale=1
light.FogColor=Color3.fromRGB(192,192,192)
light.FogStart=0
light.FogEnd=100000
pcall(function() light.Technology=Enum.Technology.Future end)
for _,v in ipairs(light:GetChildren()) do
 if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("Atmosphere") then v:Destroy() end
end
local bloom=light:FindFirstChild("ViolenceDistrictBloom") or Instance.new("BloomEffect")
bloom.Name="ViolenceDistrictBloom" bloom.Intensity=1 bloom.Threshold=2 bloom.Size=24 bloom.Enabled=true bloom.Parent=light
return {maps=mapReports,mapParts=mapReports[1].parts,connectedPoints=mapReports[1].connected,jasonClips=#clips:GetChildren(),lobbyPreserved=true,pursuers=#rigs:GetChildren(),computerAsset=computerTemplate:GetAttribute("SourceAssetId"),keyAsset=keyTemplate:GetAttribute("SourceAssetId")}


