assert(game.PlaceId==79738710219521 and game.GameId==9419478735,"Wrong place")
local SS=game:GetService("ServerStorage") local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService") local SP=game:GetService("StarterPlayer").StarterPlayerScripts
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
-- User-requested exact replacement, performed once; later releases preserve this lobby.
local lobby=workspace:FindFirstChild("JediLibrary")
if not lobby or lobby:GetAttribute("SourceAssetId")~=1043225187 then
 local asset=load(1043225187)
 local replacement=assert(asset:FindFirstChild("Map [New]",true),"Requested Map-Lobby root missing")
 replacement.Parent=nil asset:Destroy() sanitize(replacement,true)
 local cf,size=replacement:GetBoundingBox()
 replacement:PivotTo(replacement:GetPivot()+Vector3.new(-cf.X,40-(cf.Y-size.Y/2),-cf.Z))
 replacement.Name="RequestedLobbyCandidate" replacement.Parent=workspace
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={replacement} params.RespectCanCollide=true
 local surfaces={}
 for _,part in ipairs(replacement:GetDescendants()) do
  if part:IsA("BasePart") and part.CanCollide and part.Transparency<.9 and part.CFrame.UpVector.Y>.98 and part.Size.X>=16 and part.Size.Z>=16 and part.Size.Y<=12 then table.insert(surfaces,part) end
 end
 table.sort(surfaces,function(x,y) return x.Size.X*x.Size.Z>y.Size.X*y.Size.Z end)
 local ground
 for _,part in ipairs(surfaces) do
  for _,offset in ipairs({Vector3.zero,Vector3.new(6,0,0),Vector3.new(-6,0,0),Vector3.new(0,0,6)}) do
   local point=part.CFrame:PointToWorldSpace(Vector3.new(0,part.Size.Y/2,0)+offset)
   local hit=workspace:Raycast(point+Vector3.new(0,1,0),Vector3.new(0,-3,0),params)
   if hit and hit.Normal.Y>.95 and not workspace:Raycast(hit.Position+Vector3.new(0,.2,0),Vector3.new(0,8,0),params) then
    local clear=true
    for _,direction in ipairs({Vector3.new(4,0,0),Vector3.new(-4,0,0),Vector3.new(0,0,4),Vector3.new(0,0,-4)}) do
     if workspace:Raycast(hit.Position+Vector3.new(0,2.5,0),direction,params) then clear=false end
    end
    if clear then ground=hit.Position break end
   end
  end
  if ground then break end
 end
 assert(ground,"Requested lobby has no verified clear spawn")
 if lobby then lobby:Destroy() end
 lobby=replacement lobby.Name="JediLibrary" lobby:SetAttribute("SourceAssetId",1043225187) lobby:SetAttribute("VerifiedSpawn",ground)
 local existing=lobby:FindFirstChild("Door")
 local reference=existing and existing:GetPivot() or CFrame.new(ground+Vector3.new(12,8,0))
 lobby:SetAttribute("FormerDoorCFrame",reference)
 if existing then existing:Destroy() end
end
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
if typeof(verified)=="Vector3" then
 floor=workspace:Raycast(verified+Vector3.new(0,10,0),Vector3.new(0,-24,0),lobbyParams)
end
if not floor then
 local forward=Vector3.new(rotation.LookVector.X,0,rotation.LookVector.Z)
 if forward.Magnitude<.1 then forward=Vector3.new(1,0,0) else forward=forward.Unit end
 for _,candidate in ipairs({original-forward*12,original+forward*12,original-rotation.RightVector*10,original+rotation.RightVector*10}) do
  local hit=workspace:Raycast(candidate+Vector3.new(0,8,0),Vector3.new(0,-24,0),lobbyParams)
  if hit and hit.Normal.Y>.85 and not workspace:Raycast(hit.Position+Vector3.new(0,.25,0),Vector3.new(0,7,0),lobbyParams) then floor=hit break end
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

local runtime=assert(RS:FindFirstChild("SweanRuntime")) runtime:SetAttribute("Version",124) runtime:SetAttribute("PreservedLobby",true) runtime:SetAttribute("SurvivorRig","R6") runtime:SetAttribute("LobbySourceAssetId",1043225187)
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
  local clip=Instance.new("Folder",destination) clip.Name=seq.Name clip:SetAttribute("ChunkCount",math.ceil(#packed/100000))
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

local noliAsset=load(140625681515398)
local noliClips=Instance.new("Folder") compact(assert(noliAsset:FindFirstChild("Noli",true)),noliClips)
local noliMotion=Instance.new("Folder",motionLibraries) noliMotion.Name="Noli"
for _,pair in ipairs({{"Jason Idle","Idle"},{"Jason Walk","Walk"},{"Jason Run","Run"},{"Jason Slash","m1"},{"Jason_Kill","Noli Kill"},{"Jason Intro","Noli Intro"},{"Winning Screen","Noli Outro"}}) do
 slot(noliMotion,pair[1],noliClips,pair[2],140625681515398)
end
noliMotion:SetAttribute("ClipCount",#noliMotion:GetChildren()) noliClips:Destroy() noliAsset:Destroy()
local freddyMotion=coolMotion:Clone() freddyMotion.Name="Animatronic" freddyMotion.Parent=motionLibraries
for _,item in ipairs({{"Jason Idle",101544755943444},{"Jason Walk",134168450460030},{"Jason Run",90846537286775}}) do
 local wrapper=load(item[2])
 local animation=assert(wrapper:FindFirstChildWhichIsA("Animation",true),"Animatronic package contains no animation: "..item[2])
 local sequence=game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync(animation.AnimationId)
 local holder=Instance.new("Folder") sequence.Name=item[1] sequence.Parent=holder
 local old=freddyMotion:FindFirstChild(item[1]) if old then old:Destroy() end
 compact(holder,freddyMotion)
 freddyMotion[item[1]]:SetAttribute("SourceAssetId",item[2])
 holder:Destroy() wrapper:Destroy()
end
freddyMotion:SetAttribute("ClipCount",#freddyMotion:GetChildren())
freddyMotion:SetAttribute("BundleId",251391123581565)

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
 if rootName then
  local exact=asset:FindFirstChild(rootName,true)
  if exact and exact:IsA("Model") and exact:FindFirstChildOfClass("Humanoid") then return exact end
 end
 for _,obj in ipairs(asset:GetDescendants()) do
  if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("LowerTorso")) then
   return obj
  end
 end
 return nil
end

for _,spec in ipairs({
 {name="JohnDoe",id=103232099547025,root="John"},

 {name="Chucky",id=95580261594507,root="Chucky",cool=true},
 {name="Jeff",id=15578797832,root="Jeff The Killer"},
 {name="Freddy",id=18663196733,root="FRDYClone",cool=true},
 {name="Krampus",id=92081889778550,authored=true},
 {name="Piggy",id=8762062897,authored=true},
}) do
 local asset=spec.name=="JohnDoe" and johnAsset or load(spec.id)
 local source=assert(findPursuerRig(asset,spec.root),"Missing usable rig for "..spec.name)
 local libraryName=nil
 if spec.authored then libraryName=authoredMotionLibrary(asset,spec.name,spec.id) end
 local model=source:Clone() sanitize(model,false) model.Name=spec.name
 for _,v in ipairs(model:GetDescendants()) do
  if v:IsA("KeyframeSequence") or (v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")) then v:Destroy() end
 end
 local h=assert(model:FindFirstChildOfClass("Humanoid"),spec.name.." missing Humanoid")
 local root=model:FindFirstChild("HumanoidRootPart")
 if not root then
  local torso=assert(model:FindFirstChild("Torso") or model:FindFirstChild("LowerTorso"),spec.name.." missing torso")
  root=Instance.new("Part") root.Name="HumanoidRootPart" root.Size=Vector3.new(2,2,1) root.Transparency=1 root.CanCollide=false root.CFrame=torso.CFrame root.Parent=model
  local motor=Instance.new("Motor6D",root) motor.Name="RootJoint" motor.Part0=root motor.Part1=torso
 end
 model.PrimaryPart=root h.RequiresNeck=false h.BreakJointsOnDeath=false h.MaxHealth=1000 h.Health=1000
 h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 model:SetAttribute("SourceAssetId",spec.id) model:SetAttribute("SourceRootSize",root.Size) model:SetAttribute("SourceHipHeight",h.HipHeight)
 model:SetAttribute("MotionLibrary",libraryName or (spec.name=="Jeff" and "Noli" or spec.name=="Freddy" and "Animatronic" or spec.cool and "Cool" or "Default"))
 model.Parent=rigs
 if asset~=johnAsset then asset:Destroy() end
end
johnAsset:Destroy() donor:Destroy() cool:Destroy()

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
 for _,obj in ipairs(asset:GetDescendants()) do
  if obj:IsA("Model") and (obj:FindFirstChildWhichIsA("BasePart",true) or obj:FindFirstChildWhichIsA("MeshPart",true)) then source=obj break end
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
 local template=source.Parent==nil and source or source:Clone()
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

net:SetAttribute("Version",125) net:SetAttribute("MaxParticipants",8) net:SetAttribute("SurvivorRig","R6")
net:SetAttribute("MissionStage","Waiting") net:SetAttribute("ComputersDone",0) net:SetAttribute("ComputersRequired",3)
local light=game:GetService("Lighting")
light.ClockTime=0
light.Brightness=1.9
light.Ambient=Color3.fromRGB(62,62,70)
light.OutdoorAmbient=Color3.fromRGB(80,84,94)
light.ExposureCompensation=.04
light.GlobalShadows=true
light.ShadowSoftness=.42
light.EnvironmentDiffuseScale=.34
light.EnvironmentSpecularScale=.72
local oldGrade=light:FindFirstChild("SurviversGrade")
if oldGrade then oldGrade:Destroy() end
-- ArenaAmbience creates adaptive post effects locally; no heavy global blur is baked into the place.
for _,v in ipairs(light:GetChildren()) do
 if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then v:Destroy() end
end
return {maps=mapReports,mapParts=mapReports[1].parts,connectedPoints=mapReports[1].connected,jasonClips=#clips:GetChildren(),lobbyPreserved=true,pursuers=#rigs:GetChildren(),computerAsset=computerTemplate:GetAttribute("SourceAssetId"),keyAsset=keyTemplate:GetAttribute("SourceAssetId")}


