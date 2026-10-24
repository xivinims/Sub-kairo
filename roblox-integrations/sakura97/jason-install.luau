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
-- Preserve the actual published lobby and all user edits. Never reload its asset.
local lobby=assert(workspace:FindFirstChild("JediLibrary"),"Existing lobby is required; abort rather than overwrite")
local door=assert(lobby:FindFirstChild("Door"),"Existing lobby door missing")
local original=door:GetAttribute("OriginalCenter")
if not original then
 local cf=door:GetBoundingBox()
 original=cf.Position
 door:SetAttribute("OriginalCenter",original)
end
local rotation=door:GetPivot().Rotation
local lobbyParams=RaycastParams.new()
lobbyParams.FilterType=Enum.RaycastFilterType.Include
lobbyParams.FilterDescendantsInstances={lobby}
lobbyParams.RespectCanCollide=true
local inside=original-Vector3.new(12,0,0)
local floor=assert(workspace:Raycast(inside,Vector3.new(0,-30,0),lobbyParams),"Lobby entry floor missing")
assert(floor.Normal.Y>.8,"Lobby spawn slope")
local spawn=assert(workspace:FindFirstChild("IslandSpawn"))
spawn.CFrame=CFrame.lookAt(floor.Position+Vector3.new(0,.2,0),Vector3.new(original.X,floor.Position.Y+.2,original.Z))
spawn.Enabled=true spawn.Neutral=true spawn.Transparency=1 spawn.CanCollide=false spawn.Duration=0

-- Retire the old broken door geometry. It stays in the lobby hierarchy for preservation,
-- but no old shutter/frame piece is allowed to block or visually fill the doorway.
for _,v in ipairs(door:GetDescendants()) do
 if v:IsA("BasePart") then
  v.CanCollide=false v.CanTouch=false v.CanQuery=false v.CastShadow=false v.Transparency=1
 elseif v:IsA("Decal") or v:IsA("Texture") then
  v.Transparency=1
 end
end
door:SetAttribute("HeldOpen",true)
door:SetAttribute("VisualReplaced",true)

local visual=replace(workspace,"SurviversLobbyDoorVisual","Model")
visual:SetAttribute("Open",true)
visual:SetAttribute("OpenAngle",78)
visual:SetAttribute("OriginalDoorCenter",original)

local centerCF=CFrame.new(original.X,floor.Position.Y+4.6,original.Z)*rotation
local function visualPart(name,size,cf,color,material,transparency)
 local p=Instance.new("Part")
 p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
 p.Color=color p.Material=material or Enum.Material.WoodPlanks p.Transparency=transparency or 0
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=visual
 return p
end

-- Dark frame, leaving a real empty opening.
local frameColor=Color3.fromRGB(36,30,32)
visualPart("FrameLeft",Vector3.new(.75,9.2,.75),centerCF*CFrame.new(0,0,-4.25),frameColor,Enum.Material.Metal)
visualPart("FrameRight",Vector3.new(.75,9.2,.75),centerCF*CFrame.new(0,0,4.25),frameColor,Enum.Material.Metal)
visualPart("FrameTop",Vector3.new(.75,.75,9.25),centerCF*CFrame.new(0,4.25,0),frameColor,Enum.Material.Metal)

-- Two actual door leaves, already swung open around their hinges.
local leafColor=Color3.fromRGB(67,35,36)
local angle=math.rad(78)
local left=visualPart("LeftLeaf",Vector3.new(.42,8.1,3.55),
 centerCF*CFrame.new(0,-.3,-3.9)*CFrame.Angles(0,angle,0)*CFrame.new(0,0,1.775),
 leafColor,Enum.Material.WoodPlanks)
local right=visualPart("RightLeaf",Vector3.new(.42,8.1,3.55),
 centerCF*CFrame.new(0,-.3,3.9)*CFrame.Angles(0,-angle,0)*CFrame.new(0,0,-1.775),
 leafColor,Enum.Material.WoodPlanks)
left:SetAttribute("OpenLeaf",true) right:SetAttribute("OpenLeaf",true)

-- Thin luminous trim for the entry pulse.
local glowColor=Color3.fromRGB(174,42,45)
for _,spec in ipairs({
 {"GlowLeft",Vector3.new(.16,8.1,.16),CFrame.new(0,-.25,-3.78)},
 {"GlowRight",Vector3.new(.16,8.1,.16),CFrame.new(0,-.25,3.78)},
 {"GlowTop",Vector3.new(.16,.16,7.7),CFrame.new(0,3.78,0)},
}) do
 local p=visualPart(spec[1],spec[2],centerCF*spec[3],glowColor,Enum.Material.Neon,.52)
 p:SetAttribute("LobbyGlowPart",true)
end
local glowCore=visualPart("GlowCore",Vector3.new(.2,.2,.2),centerCF*CFrame.new(0,1.2,0),glowColor,Enum.Material.Neon,1)
glowCore:SetAttribute("LobbyGlowPart",true)
local light=Instance.new("PointLight")
light.Name="EntryGlow" light.Color=glowColor light.Range=14 light.Brightness=.35 light.Shadows=false light.Parent=glowCore

local gate=replace(workspace,"LobbyJoinPortal","Part")
gate.Size=Vector3.new(14,12,14)
gate.CFrame=CFrame.new(original.X,floor.Position.Y+gate.Size.Y/2,original.Z)*rotation
gate.Anchored=true gate.CanCollide=false gate.CanTouch=false gate.CanQuery=false gate.Transparency=1
gate:SetAttribute("DoorAdmission",true)
gate:SetAttribute("VisualDoor","SurviversLobbyDoorVisual")
local sign=Instance.new("BillboardGui",gate)
sign.Name="EntrySign" sign.Size=UDim2.fromOffset(220,42) sign.StudsOffset=Vector3.new(0,5,0) sign.MaxDistance=55
local label=Instance.new("TextLabel",sign)
label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text="ENTRE PARA JOGAR"
label.TextColor3=Color3.fromRGB(225,208,208) label.Font=Enum.Font.GothamMedium label.TextSize=18

local runtime=assert(RS:FindFirstChild("SweanRuntime")) runtime:SetAttribute("Version",121) runtime:SetAttribute("PreservedLobby",true)
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
     poses[p.Name]={c={p.CFrame:GetComponents()},e=p.EasingStyle.Name,d=p.EasingDirection.Name,w=p.Weight}
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

local theme=Instance.new("Sound")
theme.Name="JasonTheme"
theme.SoundId="rbxassetid://132120584214046"
theme.Looped=true
theme.Playing=false
theme.Volume=.55
theme.RollOffMode=Enum.RollOffMode.Inverse
theme:SetAttribute("SourceAssetId",132120584214046)
theme.Parent=net

local survivorAsset=load(127092032896760)
local survivor=Instance.new("Folder",net) survivor.Name="SurvivorClips" survivor:SetAttribute("SourceAssetId",127092032896760)
local survivorSaves=survivorAsset:FindFirstChild("AnimSaves",true) or survivorAsset
compact(survivorSaves,survivor) survivorAsset:Destroy()
assert((survivor:GetAttribute("ClipCount") or 0)>0,"Forsaken Survivor Animations contains no KeyframeSequence")

local crouchAsset=load(134326820545987)
local crouch=Instance.new("Folder",net) crouch.Name="CrouchClips" crouch:SetAttribute("SourceAssetId",134326820545987)
local crouchSaves=crouchAsset:FindFirstChild("AnimSaves",true) or crouchAsset
compact(crouchSaves,crouch) crouchAsset:Destroy()
assert((crouch:GetAttribute("ClipCount") or 0)>0,"R15 Crouch Animation contains no KeyframeSequence")
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
net:SetAttribute("Version",121) net:SetAttribute("MaxParticipants",8)
local light=game:GetService("Lighting") light.ClockTime=0 light.Brightness=2 light.Ambient=Color3.fromRGB(65,63,72) light.OutdoorAmbient=Color3.fromRGB(82,84,96) light.ExposureCompensation=.1
local grade=replace(light,"SurviversGrade","ColorCorrectionEffect") grade.Contrast=.12 grade.Saturation=-.18 grade.TintColor=Color3.fromRGB(236,231,241)
-- Avoid expensive blur and depth-of-field on mobile.
for _,v in ipairs(light:GetChildren()) do if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then v:Destroy() end end
return {maps=mapReports,mapParts=mapReports[1].parts,connectedPoints=mapReports[1].connected,jasonClips=#clips:GetChildren(),lobbyPreserved=true}

