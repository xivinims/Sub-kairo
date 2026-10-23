-- Validation retry: flashlight + R15 compatibility
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
assert(rig.MotionClips:FindFirstChild("Jason Run"),"Jason Run clip missing for intro cinematic")
assert(rig.MotionClips:FindFirstChild("Jason Intro"),"Jason Intro clip missing for intro cinematic")
local hasExecution=false
for _,n in ipairs(jasonClipNames) do local l=n:lower() if l:find("kill",1,true) or l:find("execution",1,true) or l:find("execute",1,true) or l:find("finisher",1,true) or l:find("fatal",1,true) then hasExecution=true break end end
local map=assets.Maps.HorrorMap
assert(map:GetAttribute("SourceAssetId")==79671648850902 and rig:GetAttribute("SourceAssetId")==125165599816440)
assert((map:GetAttribute("EntranceSpawn")-map:GetAttribute("KillerSpawn")).Magnitude>45)
assert(workspace.JediLibrary.Door:GetAttribute("HeldOpen"))
assert(workspace.IslandSpawn.Position.Y<workspace.JediLibrary.Door:GetAttribute("OriginalCenter").Y,"Lobby spawn still above door")
assert(not workspace.StreamingEnabled)
local flashlight=assert(assets:FindFirstChild("Items") and assets.Items:FindFirstChild("Flashlight"),"Flashlight template missing")
assert(flashlight:IsA("Tool") and flashlight:GetAttribute("SourceAssetId")==4573262309,"Wrong flashlight asset")
assert(flashlight:FindFirstChild("Handle"),"Flashlight handle missing")
local theme=assert(game.ReplicatedStorage.Survival:FindFirstChild("JasonTheme"),"Jason theme missing")
assert(theme:IsA("Sound") and theme:GetAttribute("SourceAssetId")==132120584214046,"Wrong Jason theme asset")
assert(theme.Looped and theme.Volume>0,"Jason theme must loop with audible volume")
local survivor=assert(game.ReplicatedStorage.Survival:FindFirstChild("SurvivorClips"),"Forsaken Survivor clips missing")
local crouch=assert(game.ReplicatedStorage.Survival:FindFirstChild("CrouchClips"),"Crouch clips missing")
assert(survivor:GetAttribute("SourceAssetId")==127092032896760,"Wrong Forsaken survivor animation asset")
assert(crouch:GetAttribute("SourceAssetId")==134326820545987,"Wrong crouch animation asset")
assert((survivor:GetAttribute("ClipCount") or 0)>0,"Forsaken survivor package has no clips")
assert((crouch:GetAttribute("ClipCount") or 0)>0,"Crouch package has no clips")
local survivorNames={} for _,v in ipairs(survivor:GetChildren()) do if v:IsA("Folder") then table.insert(survivorNames,v.Name) end end table.sort(survivorNames)
local crouchNames={} for _,v in ipairs(crouch:GetChildren()) do if v:IsA("Folder") then table.insert(crouchNames,v.Name) end end table.sort(crouchNames)
local function animationCompatibility(folder,names)
 local function norm(n) return tostring(n or ""):lower():gsub("[%s_%-%.]","") end
 local canonicalMotors={root=true,waist=true,neck=true,leftshoulder=true,rightshoulder=true,lefthip=true,righthip=true}
 local r6ToR15={
  humanoidrootpart="root",rootpart="root",torso="root",uppertorso="waist",
  head="neck",leftarm="leftshoulder",rightarm="rightshoulder",leftleg="lefthip",rightleg="righthip"
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
    local motor=r6ToR15[n] or (canonicalMotors[n] and n or nil)
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
  assert(count>=4 and moving,clipName.." cannot retarget to R15 motors; matched="..count.." poses="..table.concat(poseNames,","))
  if clipName=="Idle" then
   assert(motors.root and motors.neck and motors.leftshoulder and motors.rightshoulder,"Idle misses core R15 motors")
  end
  report[clipName]=count
 end
 return report
end
local survivorCompatibility=animationCompatibility(survivor,{"Idle","Walk","Run","InjuredIdle","InjuredWalk","InjuredRun"})
local crouchCompatibility=animationCompatibility(crouch,{"Crouch Idle","Crouch Walk"})
local portal=assert(workspace:FindFirstChild("LobbyJoinPortal"))
assert(portal:GetAttribute("DoorAdmission") and portal.Size.X>=14 and portal.Size.Z>=14,"Lobby admission volume is too small")
local oldDoor=workspace.JediLibrary.Door
assert(oldDoor:GetAttribute("VisualReplaced") and oldDoor:GetAttribute("HeldOpen"),"Old lobby door was not retired")
for _,p in ipairs(oldDoor:GetDescendants()) do if p:IsA("BasePart") then assert(p.Transparency==1 and not p.CanCollide,"Old stone/block door still visible or collidable") end end
local visualDoor=assert(workspace:FindFirstChild("SurviversLobbyDoorVisual"),"Open lobby door visual missing")
assert(visualDoor:GetAttribute("Open")==true and visualDoor:GetAttribute("OpenAngle")==78,"Lobby door is not authored open")
assert(visualDoor:FindFirstChild("LeftLeaf") and visualDoor.LeftLeaf:GetAttribute("OpenLeaf"),"Left open door leaf missing")
assert(visualDoor:FindFirstChild("RightLeaf") and visualDoor.RightLeaf:GetAttribute("OpenLeaf"),"Right open door leaf missing")
assert(visualDoor:FindFirstChild("GlowLeft") and visualDoor.GlowLeft:GetAttribute("LobbyGlowPart"),"Door glow trim missing")
return {ok=true,jasonIntroClips=true,flashlight=true,survivorCompatibility=survivorCompatibility,crouchCompatibility=crouchCompatibility,originalClips=clips,originalFrames=frames,jasonClipNames=jasonClipNames,hasExecutionClip=hasExecution,jasonTheme=true,openLobbyDoor=true,lobbyDoorGlow=true,rigPoseBindings=true,originalRigDimensions=true,poseMetadata=true,separatedSpawns=true,groundedLobbySpawn=true,wholeMapReplication=true,broadDoorAdmission=true,forsakenSurvivor=true,injuredAnimations=true,crouchFullSet=true,survivorClipNames=survivorNames,crouchClipNames=crouchNames}
