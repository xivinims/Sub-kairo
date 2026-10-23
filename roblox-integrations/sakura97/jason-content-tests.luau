local assets=game.ServerStorage.SurvivalAssets local rig=assets.Killers.Jason local Http=game:GetService("HttpService")
local matched={} for _,j in ipairs(rig:GetDescendants()) do if j:IsA("Motor6D") and j.Part1 then matched[j.Part1.Name]=true end end
local clips=0 local frames=0
for _,folder in ipairs(rig.MotionClips:GetChildren()) do
 local chunks=folder:GetChildren() table.sort(chunks,function(a,b) return a.Name<b.Name end)
 local values={} for _,v in ipairs(chunks) do assert(#v.Value<200000) table.insert(values,v.Value) end
 local data=Http:JSONDecode(table.concat(values)) assert(data.length>0 and #data.frames>0)
 local previous=-1 local animatedJoints=0
 for _,f in ipairs(data.frames) do assert(f.time>=previous,"Unsorted original frames") previous=f.time
  for name,components in pairs(f.poses) do assert(#components==12,"Invalid CFrame") if matched[name] then animatedJoints+=1 end end
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
return {ok=true,originalClips=clips,originalFrames=frames,rigPoseBindings=true,separatedSpawns=true,groundedLobbySpawn=true,wholeMapReplication=true}
