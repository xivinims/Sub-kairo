assert(not game.ServerStorage:FindFirstChild("NatureTemplates"),"Legacy NatureTemplates must not remain in Jason build")
local assets=game.ServerStorage.SurvivalAssets local rig=assets.Killers.Jason local Http=game:GetService("HttpService")
local sourceRoot=assert(rig:GetAttribute("SourceRootSize"),"Missing original Jason root size")
local sourceHip=rig:GetAttribute("SourceHipHeight")
assert(rig.HumanoidRootPart.Size==sourceRoot,"Jason root was resized")
assert(math.abs(rig:FindFirstChildOfClass("Humanoid").HipHeight-sourceHip)<1e-5,"Jason HipHeight was changed")
local matched={} for _,j in ipairs(rig:GetDescendants()) do if j:IsA("Motor6D") and j.Part1 then matched[j.Part1.Name]=true end end
local clips=0 local frames=0
for _,folder in ipairs(rig.MotionClips:GetChildren()) do
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
assert(clips==17,"Missing exact Jason animation sequences")
local map=assets.Maps.HorrorMap
assert(map:GetAttribute("SourceAssetId")==79671648850902 and rig:GetAttribute("SourceAssetId")==125165599816440)
assert((map:GetAttribute("EntranceSpawn")-map:GetAttribute("KillerSpawn")).Magnitude>45)
assert(workspace.JediLibrary.Door:GetAttribute("HeldOpen"))
assert(workspace.IslandSpawn.Position.Y<workspace.JediLibrary.Door:GetAttribute("OriginalCenter").Y,"Lobby spawn still above door")
assert(not workspace.StreamingEnabled)
local survivor=assert(game.ReplicatedStorage.Survival:FindFirstChild("SurvivorClips"),"Forsaken Survivor clips missing")
local crouch=assert(game.ReplicatedStorage.Survival:FindFirstChild("CrouchClips"),"Crouch clips missing")
assert(survivor:GetAttribute("SourceAssetId")==127092032896760,"Wrong Forsaken survivor animation asset")
assert(crouch:GetAttribute("SourceAssetId")==134326820545987,"Wrong crouch animation asset")
assert((survivor:GetAttribute("ClipCount") or 0)>0,"Forsaken survivor package has no clips")
assert((crouch:GetAttribute("ClipCount") or 0)>0,"Crouch package has no clips")
local survivorNames={} for _,v in ipairs(survivor:GetChildren()) do if v:IsA("Folder") then table.insert(survivorNames,v.Name) end end table.sort(survivorNames)
local crouchNames={} for _,v in ipairs(crouch:GetChildren()) do if v:IsA("Folder") then table.insert(crouchNames,v.Name) end end table.sort(crouchNames)
local portal=assert(workspace:FindFirstChild("LobbyJoinPortal"))
assert(portal:GetAttribute("DoorAdmission") and portal.Size.X>=14 and portal.Size.Z>=14,"Lobby admission volume is too small")
return {ok=true,originalClips=clips,originalFrames=frames,rigPoseBindings=true,originalRigDimensions=true,poseMetadata=true,separatedSpawns=true,groundedLobbySpawn=true,wholeMapReplication=true,broadDoorAdmission=true,forsakenSurvivor=true,crouchFullSet=true,survivorClipNames=survivorNames,crouchClipNames=crouchNames}
