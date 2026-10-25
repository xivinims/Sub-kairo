-- Validate the current R6 survivor, pursuers, bounded maps, UI cleanup and installed runtime sources.
assert(not game.ServerStorage:FindFirstChild("NatureTemplates"),"Legacy NatureTemplates must not remain in Jason build")
local assets=game.ServerStorage.SurvivalAssets local rig=assets.Killers.Jason local Http=game:GetService("HttpService")
local sourceRoot=assert(rig:GetAttribute("SourceRootSize"),"Missing original Jason root size")
local sourceHip=rig:GetAttribute("SourceHipHeight")
assert(rig.HumanoidRootPart.Size==sourceRoot,"Jason root was resized")
assert(math.abs(rig:FindFirstChildOfClass("Humanoid").HipHeight-sourceHip)<1e-5,"Jason HipHeight was changed")
local matched={} for _,j in ipairs(rig:GetDescendants()) do if j:IsA("Motor6D") and j.Part1 then matched[j.Part1.Name]=true end end
local clips=0 local frames=0 local jasonClipNames={}
for _,folder in ipairs(rig.MotionClips:GetChildren()) do table.insert(jasonClipNames,folder.Name)
 local chunks=folder:GetChildren() table.sort(chunks,function(a,b) return a.Name<b.Name end)
 local values={} for _,v in ipairs(chunks) do assert(#v.Value<200000) table.insert(values,v.Value) end
 local data=Http:JSONDecode(buffer.tostring(game:GetService("EncodingService"):DecompressBuffer(game:GetService("EncodingService"):Base64Decode(buffer.fromstring(table.concat(values))),Enum.CompressionAlgorithm.Zstd))) assert(data.length>0 and #data.frames>0)
 local previous=-1 local animatedJoints=0
 for _,f in ipairs(data.frames) do assert(f.time>=previous,"Unsorted original frames") previous=f.time
  for name,pose in pairs(f.poses) do
   local components=pose.c or pose
   assert(#components==12,"Invalid CFrame")
   if pose.c then assert(type(pose.e)=="string" and type(pose.d)=="string" and type(pose.w)=="number","Missing exact pose metadata") end
   if matched[name] then animatedJoints+=1 end
  end
 end
 assert(animatedJoints>0,"Clip has no matching rig joints") clips+=1 frames+=#data.frames
end
table.sort(jasonClipNames)
assert(clips==17,"Missing exact Jason animation sequences")
assert(rig.MotionClips:FindFirstChild("Jason Run"),"Jason Run clip missing")
assert(rig.MotionClips:FindFirstChild("Jason Intro"),"Original Jason source clip set changed unexpectedly")
local hasExecution=false
for _,n in ipairs(jasonClipNames) do local l=n:lower() if l:find("kill",1,true) or l:find("execution",1,true) or l:find("execute",1,true) or l:find("finisher",1,true) or l:find("fatal",1,true) then hasExecution=true break end end
local expectedMaps={
 DoomspireBrickbattle=109440846094241,
 JuggernautFightArena=137884561019081,
 PirateBayIsland=127398591748883,
 NaturalDisasterSurvival=92220535332787,
 RocketArena=112232657511704,
 PiggySewers=7757562864,
 PiggyMappleDonut=16440225099,
}
assert(rig:GetAttribute("SourceAssetId")==125165599816440)
for name,id in pairs(expectedMaps) do
 local map=assert(assets.Maps:FindFirstChild(name),"Missing requested map "..name)
 assert(map:GetAttribute("SourceAssetId")==id,"Wrong source asset for "..name)
end
assert(not assets.Maps:FindFirstChild("HorrorMap") and not assets.Maps:FindFirstChild("MilitaryBase") and not assets.Maps:FindFirstChild("AlpineFortress"),"Old arena templates returned")
assert(assets.Maps.RocketArena:GetAttribute("RequestedScale")==2,"RocketArena must be scaled 2x")
local formerDoorCF=assert(workspace.JediLibrary:GetAttribute("FormerDoorCFrame"),"Lobby facing reference missing")
assert(typeof(formerDoorCF)=="CFrame","Lobby facing reference must be a CFrame")
local verifiedSpawn=assert(workspace.JediLibrary:GetAttribute("VerifiedSpawn"),"Fixed lobby verified spawn missing")
assert(typeof(verifiedSpawn)=="Vector3","Fixed lobby verified spawn must be a Vector3")
local spawnPos=workspace.IslandSpawn.Position
assert((Vector3.new(spawnPos.X,verifiedSpawn.Y,spawnPos.Z)-verifiedSpawn).Magnitude<2.5,"Lobby spawn drifted away from fixed snapshot spawn")
assert(math.abs((spawnPos.Y-workspace.IslandSpawn.Size.Y/2)-verifiedSpawn.Y)<1,"Lobby spawn is not grounded on fixed snapshot floor")
assert(not workspace.JediLibrary:FindFirstChild("Door") and not workspace.JediLibrary:FindFirstChild("OriginalLobbyDoor"),"Lobby door geometry/marker returned")
assert(not workspace.StreamingEnabled)
local mapReport={}
for _,arena in ipairs(assets.Maps:GetChildren()) do
 local budget=arena:GetAttribute("PartBudget") or 5000
 assert(arena:GetAttribute("PartCount")<=budget+15 and arena:GetAttribute("PartCount")>30,"Part budget")
 assert(#arena.SafePoints:GetChildren()>=9 and #arena.ArrivalSpawns:GetChildren()>=2,"Map navigation validation")
 assert((arena:GetAttribute("EntranceSpawn")-arena:GetAttribute("KillerSpawn")).Magnitude>=30,"Separated spawns")
 assert((arena:GetAttribute("KillerSpawnDistance") or 0)>=30,"Killer spawn distance metadata missing")
 local requiredClearance=arena:GetAttribute("RequiredKillerClearance") or 10
 assert((arena:GetAttribute("KillerSpawnClearance") or 0)>=requiredClearance,"Pursuer spawn has insufficient wall clearance")
 assert(arena:GetAttribute("KillerSpawnPathValidated")==true,"Pursuer spawn is not path-connected")
 assert(#arena.ArrivalSpawns:GetChildren()>=7 and #arena.ObjectiveSites:GetChildren()>=9,"Per-map sites missing")
 for i,a in ipairs(arena.ArrivalSpawns:GetChildren()) do
  for j,b in ipairs(arena.ArrivalSpawns:GetChildren()) do if i~=j then assert((a.Value-b.Value).Magnitude>=7.9,"Overlapping arrivals: "..arena.Name) end end
 end
 local bounds=assert(arena:FindFirstChild("InvisibleBounds"),"Invisible arena bounds missing")
 assert(#bounds:GetChildren()>=5 and bounds:FindFirstChild("SafetyFloor"),"Arena must have four invisible walls plus safety floor")
 for _,wall in ipairs(bounds:GetChildren()) do assert(wall:IsA("BasePart") and wall.Transparency==1 and wall.CanCollide,"Invalid invisible safety boundary") end
 for _,obj in ipairs(arena:GetDescendants()) do assert(not obj:IsA("LuaSourceContainer"),"Imported script survived sanitization") end
 table.insert(mapReport,{name=arena.Name,parts=arena:GetAttribute("PartCount"),paths=arena:GetAttribute("ValidatedPaths"),objectives=#arena.ObjectiveSites:GetChildren(),arrivals=#arena.ArrivalSpawns:GetChildren(),bounds=#bounds:GetChildren()})
end
assert(#mapReport==7,"Expected seven requested arena templates")
local flashlight=assert(assets:FindFirstChild("Items") and assets.Items:FindFirstChild("Flashlight"),"Flashlight template missing")
assert(flashlight:IsA("Tool") and flashlight:GetAttribute("SourceAssetId")==4573262309,"Wrong flashlight asset")
assert(flashlight:FindFirstChild("Handle"),"Flashlight handle missing")
assert(not game.ReplicatedStorage.Survival:FindFirstChild("JasonTheme"),"Automatic Jason theme must stay removed")
local survivor=assert(game.ReplicatedStorage.Survival:FindFirstChild("SurvivorClips"),"Forsaken Survivor clips missing")
assert(survivor:GetAttribute("SourceAssetId")==127092032896760,"Wrong Forsaken survivor animation asset")
assert((survivor:GetAttribute("ClipCount") or 0)>0,"Forsaken survivor package has no clips")
assert(not game.ReplicatedStorage.Survival:FindFirstChild("CrouchClips"),"Removed crouch package returned")
local actions=assert(game.ReplicatedStorage.Survival:FindFirstChild("SurvivorActionClips"),"Survivor action clips missing")
assert((actions:GetAttribute("ClipCount") or 0)==6,"Survivor action clip count mismatch")
assert(actions:GetAttribute("ParryAssetId")==127096285501517,"Parry animation id mismatch")
assert(actions:GetAttribute("BreakPalletAssetId")==112166042383605,"Break pallet animation id mismatch")
assert(actions:GetAttribute("CrouchWalkAssetId")==126965695851149,"Crouch animation id mismatch")
assert(actions:GetAttribute("InjuredCrouchWalkAssetId")==135084204086504,"Injured crouch animation id mismatch")
assert(actions:GetAttribute("StunAssetId")==123047897844134,"Stun animation id mismatch")
assert(actions:GetAttribute("VaultAssetId")==83873880822918,"Vault animation id mismatch")
local survivorNames={} for _,v in ipairs(survivor:GetChildren()) do if v:IsA("Folder") then table.insert(survivorNames,v.Name) end end table.sort(survivorNames)
local function animationCompatibility(folder,names)
 local function norm(n) return tostring(n or ""):lower():gsub("[%s_%-%.]","") end
 local canonicalMotors={root=true,neck=true,leftshoulder=true,rightshoulder=true,lefthip=true,righthip=true}
 local poseToMotor={
  humanoidrootpart="root",rootpart="root",lowertorso="root",uppertorso="root",torso="root",
  head="neck",
  leftarm="leftshoulder",leftupperarm="leftshoulder",leftlowerarm="leftshoulder",lefthand="leftshoulder",
  rightarm="rightshoulder",rightupperarm="rightshoulder",rightlowerarm="rightshoulder",righthand="rightshoulder",
  leftleg="lefthip",leftupperleg="lefthip",leftlowerleg="lefthip",leftfoot="lefthip",
  rightleg="righthip",rightupperleg="righthip",rightlowerleg="righthip",rightfoot="righthip"
 }
 local report={}
 for _,clipName in ipairs(names) do
  local clipFolder=assert(folder:FindFirstChild(clipName),"Missing clip "..clipName)
  local chunks=clipFolder:GetChildren() table.sort(chunks,function(a,b) return a.Name<b.Name end)
  local packed={} for _,v in ipairs(chunks) do table.insert(packed,v.Value) end
  local decoded=Http:JSONDecode(buffer.tostring(game:GetService("EncodingService"):DecompressBuffer(game:GetService("EncodingService"):Base64Decode(buffer.fromstring(table.concat(packed))),Enum.CompressionAlgorithm.Zstd)))
  local motors={} local moving=false local poseNames={} local seen={}
  for _,frame in ipairs(decoded.frames) do
   for poseName,pose in pairs(frame.poses) do
    local n=norm(poseName)
    local motor=poseToMotor[n] or (canonicalMotors[n] and n or nil)
    if motor then motors[motor]=true end
    if not seen[poseName] then seen[poseName]=true table.insert(poseNames,poseName) end
    local v=pose.c or pose
    if #v==12 then
     local cf=CFrame.new(table.unpack(v))
     local rx,ry,rz=cf:ToOrientation()
     if cf.Position.Magnitude>.001 or math.abs(rx)>.001 or math.abs(ry)>.001 or math.abs(rz)>.001 then moving=true end
    end
   end
  end
  local count=0 for _ in pairs(motors) do count+=1 end
  table.sort(poseNames)
  assert(count>=4 and moving,clipName.." cannot drive/retarget to R6 motors; matched="..count.." poses="..table.concat(poseNames,","))
  if clipName=="Idle" then
   assert(motors.root and motors.neck and motors.leftshoulder and motors.rightshoulder and motors.lefthip and motors.righthip,"Idle misses R6 motors")
  end
  report[clipName]=count
 end
 return report
end
local survivorCompatibility=animationCompatibility(survivor,{"Idle","Walk","Run","InjuredIdle","InjuredWalk","InjuredRun"})
assert(game.ReplicatedStorage.SweanRuntime:GetAttribute("SurvivorRig")=="R6" and game.ReplicatedStorage.Survival:GetAttribute("SurvivorRig")=="R6","R6 survivor contract missing")
local islandSource=assert(game.ServerScriptService:FindFirstChild("IslandServer"),"Island server missing").Source
local voidSource=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("VoidSequence"),"Void client missing").Source
local survivalServerSource=assert(game.ServerScriptService:FindFirstChild("SurvivalServer"),"Survival server missing").Source
local survivalClientSource=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SurvivalClient"),"Survival client missing").Source
local pursuerAnimationSource=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("PursuerAnimation"),"Pursuer animation controller missing").Source
local ambienceSource=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ArenaAmbience"),"Arena ambience missing").Source
local loadingSource=assert(game.ReplicatedFirst:FindFirstChild("SweanLoadingController"),"Initial loading controller missing").Source
local nametagSource=assert(game.ServerScriptService:FindFirstChild("NametagService"),"Nametag service missing").Source
local friendSource=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("FriendPresence"),"Friend presence missing").Source
local killerFactorySource=assert(game.ServerScriptService:FindFirstChild("KillerFactory"),"Killer factory missing").Source
assert(not islandSource:find('begin(player,"void")',1,true),"Lobby void still triggers death presentation")
assert(islandSource:find('RoundStatus")~="eliminated"',1,true) or islandSource:find('RoundStatus")~=',1,true),"Server death presentation is not gated by elimination status")
assert(voidSource:find('local realDeath=mode=="spectate"',1,true),"Client death screen lacks real-death guard")
assert(voidSource:find('player:GetAttribute("InMenu")~=true',1,true),"Client death screen is not blocked in menu")
assert(survivalServerSource:find("safeRoundSpawnCF",1,true) and survivalServerSource:find("spawnGraceUntil",1,true),"Round spawn recovery guard missing")
assert(survivalServerSource:find("lastVictimUserId=lastKilledUserId",1,true),"Exact final victim is not sent to result scene")
assert(survivalServerSource:find("recoverFromFall",1,true),"Arena fall recovery missing")
assert(not survivalServerSource:find('FireClient(p,"jasonIntro"',1,true),"Removed killer intro is still sent by server")
assert(survivalServerSource:find('Instance.new("Model") visual.Name="EquippedFlashlight"',1,true),"Flashlight still uses Tool pose inside character")
assert(pursuerAnimationSource:find("pursuerStateName",1,true),"Per-killer locomotion clip resolver missing")
assert(pursuerAnimationSource:find('speed/(injured and 14 or 18)',1,true),"Survivor run animation is not velocity-synchronized")
assert(pursuerAnimationSource:find("SurvivorActionClips",1,true) and pursuerAnimationSource:find('"InjuredCrouchWalk"',1,true) and pursuerAnimationSource:find('"CrouchWalk"',1,true),"Dedicated crouch animation runtime missing")
assert(not pursuerAnimationSource:find("CrouchClips",1,true) and not pursuerAnimationSource:find("CinematicPursuer",1,true),"Removed animation branches returned")
assert(not survivalServerSource:find('action=="boost"',1,true),"Legacy boost server action returned")
assert(not survivalServerSource:find('action=="musicPlay"',1,true) and not survivalServerSource:find('action=="musicBuy"',1,true),"Legacy music server actions returned")
assert(not survivalServerSource:find('value=="slow"',1,true) and not survivalServerSource:find("introSceneData",1,true),"Legacy slow/intro server code returned")
assert(not survivalServerSource:find("ArenaEntrance",1,true),"Removed arena entrance marker logic returned")
assert(survivalServerSource:find("hookedCharacters=setmetatable",1,true),"Character death-hook deduplication missing")
assert(survivalServerSource:find("expectedCharacters",1,true) and survivalServerSource:find("expectedReplacement",1,true),"Expected R6 replacement can still be misread as a death/reset")
assert(survivalServerSource:find("local executionDuration=1.85",1,true),"Execution duration synchronization missing")
assert(survivalServerSource:find('p:SetAttribute("ExecutionDuration",executionDuration)',1,true),"Victim execution duration is not replicated")
assert(pursuerAnimationSource:find('p:GetAttribute("BeingExecuted")==true',1,true),"Execution pose does not override downed pose")
assert(pursuerAnimationSource:find('model:GetAttribute("ExecutionDuration")',1,true),"Pursuer execution clip is not synchronized to server duration")
assert(survivalClientSource:find("restoreResultCamera",1,true) and survivalClientSource:find("captureResultCamera",1,true),"Fullscreen result camera is not safely restored")
assert(pursuerAnimationSource:find("blendFrom",1,true) and pursuerAnimationSource:find("blendTime",1,true),"Run/walk/idle transitions are still hard-cut")
assert(pursuerAnimationSource:find("setDefaultAnimate(model,false)",1,true),"Custom and default survivor animations can still overlap")
assert(not survivalClientSource:find('fallen=base*CFrame.new(1.25,-1.45,-.55)',1,true),"Animated victory victim side-fall returned")
assert(survivalClientSource:find('loadingAvatar.Name="ArenaAvatar"',1,true),"Animated map loading avatar missing")
assert(survivalClientSource:find('GoodLuck","GOOD LUCK"',1,true),"Map Good Luck backdrop missing")
assert(not survivalClientSource:find("cancelJasonIntro",1,true) and not survivalClientSource:find("EntryFlash",1,true),"Dead killer intro/door client code returned")
assert(loadingSource:find('logo.Name="BrandTitle"',1,true),"Initial logo loading missing")
assert(not loadingSource:find("GOOD LUCK",1,true) and not loadingSource:find("LoadingAvatar",1,true),"GOOD LUCK/avatar leaked into initial game loading")
assert(not loadingSource:find('Name="Progress"',1,true),"Map-style progress UI leaked into initial game loading")
assert(survivalClientSource:find('loadingAvatar.Name="ArenaAvatar"',1,true) and survivalClientSource:find('"GOOD LUCK"',1,true),"Map loading lost avatar/GOOD LUCK presentation")
assert(ambienceSource:find("EnvironmentSpecularScale",1,true) and ambienceSource:find("WaterReflectance",1,true),"Reflection system missing")
local settingsSource=assert(game.ReplicatedStorage.Survival:FindFirstChild("SettingsPanel"),"Settings panel missing").Source
assert(settingsSource:find('key="CameraFOV"',1,true) and settingsSource:find('default=48',1,true),"Reference Camera FOV setting missing")
assert(settingsSource:find('key="VisualSaturation"',1,true) and settingsSource:find('default=-.65',1,true),"Reference saturation setting missing")
assert(settingsSource:find('key="VisualContrast"',1,true) and settingsSource:find('key="VisualExposure"',1,true) and settingsSource:find('key="VisualTime"',1,true),"Reference contrast/exposure/time settings missing")
assert(settingsSource:find('format="time"',1,true) and settingsSource:find('default=8.25',1,true),"08:15 time setting missing")
assert(ambienceSource:find('player:GetAttribute("VisualSaturation")',1,true) and ambienceSource:find('player:GetAttribute("VisualContrast")',1,true),"Visual grading settings are not applied")
assert(ambienceSource:find('player:GetAttribute("VisualExposure")',1,true) and ambienceSource:find('player:GetAttribute("VisualTime")',1,true),"Exposure/time settings are not applied")
assert(ambienceSource:find("SuviversArenaBloom",1,true) and ambienceSource:find("SuviversArenaDOF",1,true),"Adaptive post processing missing")
assert(voidSource:find('local media=RS:WaitForChild("XNMedia")',1,true),"Death UI media reference can be nil")
assert(not nametagSource:find("CantorBadge",1,true),"Obsolete Cantor badge returned")
assert(friendSource:find('FindFirstChild("SweanNametag")',1,true),"ShowNametags does not control normal nametags")
assert(killerFactorySource:find('humanoid.AutoRotate=true',1,true) and killerFactorySource:find('root.AssemblyLinearVelocity=Vector3.zero',1,true),"Pursuer spawn normalization missing")
assert(killerFactorySource:find('humanoid.WalkSpeed=spec and spec.speed',1,true),"Pursuer configured speed is not applied at factory creation")
assert(not survivalClientSource:find('Name="MusicButton"',1,true),"Gameplay music icon returned")
assert(survivalClientSource:find('roundMusic.Name="SuviversMatchMusic"',1,true),"Requested round soundtrack missing")
assert(survivalClientSource:find('roundMusic.SoundId="rbxassetid://108879410219148"',1,true),"Wrong round soundtrack asset")
assert(survivalClientSource:find('roundMusic.Volume=.35',1,true),"Round soundtrack volume is not the requested low level")
assert(survivalClientSource:find('and player:GetAttribute("InRound")==true',1,true) and survivalClientSource:find('and player:GetAttribute("Spectating")~=true',1,true),"Round soundtrack scope is too broad")
assert(survivalClientSource:find('PresentationState","Jason Idle"',1,true) and survivalClientSource:find('PresentationState","Jason Slash"',1,true) and survivalClientSource:find('PresentationFrozen",true',1,true),"Frozen idle/attack result poses missing")
assert(game.ReplicatedStorage.SweanRuntime:GetAttribute("LobbySourceAssetId")==workspace.JediLibrary:GetAttribute("SourceAssetId"),"Wrong fixed lobby source contract")
assert(game.ReplicatedStorage.SweanRuntime:GetAttribute("FixedLobbyRevision")=="violence-district-lobby-v1","Fixed lobby runtime revision missing")
assert(workspace.JediLibrary:GetAttribute("FixedLobbySHA256")=="ec6fb99dec82f22eb24d23b885d1b980467cb91f20e2234a1a0fad3f7f4e43c2","Fixed lobby hash contract missing")
assert(not workspace:FindFirstChild("LobbyJoinPortal"),"Lobby join portal returned")
assert(not workspace:FindFirstChild("SurviversLobbyDoorVisual"),"Lobby join door visual returned")
assert(not game.StarterGui.TomiaszMenu.MenuPrincipal:FindFirstChild("Shop"),"Shop button object returned")
assert(not game.StarterGui.TomiaszMenu.MenuPrincipal:FindFirstChild("Inventory"),"Inventory button object returned")
assert(not game.StarterGui.TomiaszMenu.Escenarios:FindFirstChild("MenuShop"),"Shop modal returned")
assert(not game.StarterGui.TomiaszMenu.Escenarios:FindFirstChild("MenuInventory"),"Inventory modal returned")
assert(not game.StarterGui.TomiaszMenu:FindFirstChild("ReturnToMenu"),"Return-to-menu object returned")
assert(workspace.JediLibrary:GetAttribute("AutomaticRoundAdmission")==true,"Lobby automatic admission contract missing")
local lobbyBounds=assert(workspace.JediLibrary:FindFirstChild("InvisibleBounds"),"Lobby invisible bounds missing")
assert(#lobbyBounds:GetChildren()>=5 and lobbyBounds:FindFirstChild("SafetyFloor"),"Lobby safety walls/floor missing")
local shared=assert(game.ReplicatedStorage.Survival:FindFirstChild("KillerMotionLibraries"),"Shared pursuer motion libraries missing")
assert(shared:FindFirstChild("Default") and shared.Default:GetAttribute("ClipCount")==7,"Default shared motion library invalid")
assert(shared:FindFirstChild("Cool") and shared.Cool:GetAttribute("ClipCount")==7,"Cool shared motion library invalid")
for _,name in ipairs({"Jason","JohnDoe","Jeff","Chucky","Freddy"}) do
 local k=assert(assets.Killers:FindFirstChild(name),name.." template missing")
 assert(k.PrimaryPart and k:FindFirstChildOfClass("Humanoid"),name.." missing root/humanoid")
 assert(k:GetAttribute("SourceAssetId"),name.." missing source id")
end
for _,name in ipairs({"JohnDoe","Jeff","Chucky","Freddy"}) do
 local k=assert(assets.Killers:FindFirstChild(name))
 assert(not k:FindFirstChild("MotionClips"),name.." still duplicates MotionClips")
 assert(shared:FindFirstChild(k:GetAttribute("MotionLibrary") or ""),name.." missing shared motion reference")
end
assert(game.ReplicatedStorage.Survival.PresentationJason.MotionClips:GetAttribute("ClipCount")==1,"Portrait must not replicate the full combat library")
assert(game.ServerScriptService.SurvivalBridge:FindFirstChild("CancelDeath"),"Death cancellation bridge missing")
assert(assets.Killers.Jeff:GetAttribute("MotionLibrary")=="Noli")
assert(shared.Noli["Jason_Kill"]:GetAttribute("SourceAssetId")==140625681515398)
assert(assets.Killers.Freddy:GetAttribute("MotionLibrary")=="Animatronic")
assert(shared.Animatronic["Jason Walk"]:GetAttribute("SourceAssetId")==134168450460030)
return {ok=true,safeRoundRespawn=true,characterHookDedup=true,exactFinalVictim=true,musicHudRemoved=true,fullScreenExecutionResult=true,deathScreenOnlyOnRealDeath=true,safePursuerSpawns=true,sharedPursuerMotionLibraries=true,survivorR6=true,crouchRuntime=true,fixedViolenceDistrictLobby=true,maps=mapReport,killerMotionClips=true,flashlight=true,survivorCompatibility=survivorCompatibility,originalClips=clips,originalFrames=frames,jasonClipNames=jasonClipNames,hasExecutionClip=hasExecution,legacyThemesRemoved=true,buckshotRoundMusic=true,lowVolumeRoundMusic=true,noLobbyJoinDoor=true,noLobbyDoorGeometry=true,automaticLobbyAdmission=true,invisibleArenaBounds=true,invisibleLobbyBounds=true,velocitySyncedRun=true,perKillerLocomotion=true,flashlightPoseSafe=true,rigPoseBindings=true,originalRigDimensions=true,poseMetadata=true,separatedSpawns=true,groundedLobbySpawn=true,wholeMapReplication=true,fallRecovery=true,forsakenSurvivor=true,injuredAnimations=true,survivorActionAnimations=true,crouchAnimation=true,injuredCrouchAnimation=true,mapAnimatedLoading=true,initialLogoOnly=true,smoothLocomotionBlend=true,r6ReplacementSafe=true,frozenResultPoses=true,synchronizedExecution=true,resultCameraRestored=true,adaptiveGraphics=true,referenceVisualSettings=true,requestedSevenMaps=true,rocketArena2x=true,pursuersNormalized=true,deathMediaSafe=true,deadSystemsRemoved=true,menuObjectsRemoved=true,nametagToggleFixed=true,survivorClipNames=survivorNames}
