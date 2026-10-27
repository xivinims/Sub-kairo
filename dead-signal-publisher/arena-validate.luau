local W=workspace
local RS=game:GetService("ReplicatedStorage")
local errors={}
local function check(ok,message) if not ok then table.insert(errors,message) end end
check(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
check(W:GetAttribute("DeadSignalBuildId")=="dead-signal-bramble-arena-v1","BuildId mismatch")
check(W:GetAttribute("ArenaOnly")==true,"Arena flag missing")
check(not W:FindFirstChild("SignalworksChapter01") and not W:FindFirstChild("MenuStage"),"Old chapter still present")
check(not RS:FindFirstChild("DeadSignalFoundation"),"Old foundation still active")
local rig=W:FindFirstChild("Bramble")
check(rig and rig.PrimaryPart~=nil,"Rig root missing")
local joints,parts,foreign=0,0,0
if rig then
 check(rig:GetAttribute("SourceAssetId")==115602504342753,"Wrong model")
 for _,d in ipairs(rig:GetDescendants()) do
  if d:IsA("Motor6D") then joints+=1; check(d.Part0~=nil and d.Part1~=nil,"Broken joint "..d.Name) end
  if d:IsA("BasePart") then parts+=1 end
  if d:IsA("LuaSourceContainer") then foreign+=1 end
 end
 check(joints>=30,"Incomplete articulated rig")
 check(foreign==0,"External code remained in model")
 check(#rig.PrimaryPart:GetConnectedParts(true)>=parts-1,"Detached geometry in imported rig")
end
check(W:FindFirstChild("CleanTestFloor")~=nil and W:FindFirstChild("ArenaSpawn")~=nil,"Floor or spawn missing")
check(game:GetService("ServerScriptService"):FindFirstChild("BrambleArenaServer")~=nil,"Server missing")
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("BrambleArenaClient")~=nil,"Client missing")
check(RS:FindFirstChild("ArenaControl")~=nil,"Controls missing")
local module=RS:FindFirstChild("ArenaAnimation")
check(module~=nil,"Animation module missing")
if module then
 local ok,animation=pcall(require,module)
 check(ok,"Animation module failed")
 if ok then
  for _,state in ipairs({"Idle","Walk","Run","Attack"}) do
   local pose=animation.Pose("RightShoulder",state,0.7)
   check(typeof(pose)=="CFrame" and pose.Position.Magnitude==pose.Position.Magnitude,"Invalid pose "..state)
  end
  check(animation.Pose("RightHip","Walk",0.3)~=animation.Pose("RightHip","Idle",0.3),"Walk pose equals idle")
  check(animation.Pose("RightHip","Run",0.3)~=animation.Pose("RightHip","Walk",0.3),"Run pose equals walk")
  check(animation.Pose("RightShoulder","Attack",0.8)~=animation.Pose("RightShoulder","Idle",0.8),"Attack pose equals idle")
 end
end
return {ok=#errors==0,errors=errors,build=W:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,assetId=rig and rig:GetAttribute("SourceAssetId"),joints=joints,parts=parts,externalScripts=foreign,arenaOnly=W:GetAttribute("ArenaOnly"),states={"Idle","Walk","Run","Attack"}}
