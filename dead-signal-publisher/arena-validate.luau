local W=workspace
local RS=game:GetService("ReplicatedStorage")
local errors={}
local function check(ok,message) if not ok then table.insert(errors,message) end end
check(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
check(W:GetAttribute("DeadSignalBuildId")=="dead-signal-bramble-map-v2","BuildId mismatch")
local map=W:FindFirstChild("PoppyTestMap")
check(map and map:GetAttribute("SourceAssetId")==18509954401,"Requested test map absent")
check(not W:FindFirstChild("CleanTestFloor") and not W:FindFirstChild("SignalworksChapter01"),"Old map remains")
local mapParts,foreign,lights=0,0,0
if map then
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("BasePart") then mapParts+=1; check(d.Anchored,"Unanchored map geometry") end
  if d:IsA("LuaSourceContainer") then foreign+=1 end
 end
end
check(mapParts>=2000 and mapParts<4000,"Unexpected map geometry count")
for _,d in ipairs(W:GetDescendants()) do if d:IsA("Light") then lights+=1 end end
check(lights>=5,"Power lighting missing")
local rig=W:FindFirstChild("Bramble")
check(rig and rig.PrimaryPart~=nil,"Rig root missing")
local joints,parts=0,0
if rig then
 check(rig:GetAttribute("SourceAssetId")==115602504342753,"Wrong creature")
 for _,d in ipairs(rig:GetDescendants()) do
  if d:IsA("Motor6D") then joints+=1; check(d.Part0~=nil and d.Part1~=nil,"Broken joint "..d.Name) end
  if d:IsA("BasePart") then parts+=1 end
  if d:IsA("LuaSourceContainer") then foreign+=1 end
 end
 check(joints==36,"Incomplete articulated rig")
 check(#rig.PrimaryPart:GetConnectedParts(true)>=parts-1,"Detached rig geometry")
end
check(foreign==0,"Imported executable code remained")
local spawn=W:FindFirstChild("ArenaSpawn")
local nav=W:FindFirstChild("TestNavigation")
local switch=W:FindFirstChild("TestPowerSwitch")
check(spawn and nav and switch and switch:FindFirstChild("PowerPrompt"),"Spawn/navigation/switch missing")
check(W:GetAttribute("PowerOn")==false,"Creature should start dormant")
check(RS:FindFirstChild("BrambleScare")~=nil,"Scare synchronization missing")
check(game:GetService("ServerScriptService"):FindFirstChild("BrambleArenaServer")~=nil,"Server missing")
check(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("BrambleArenaClient")~=nil,"Client missing")
check(game:GetService("StarterPlayer").CameraMode==Enum.CameraMode.LockFirstPerson,"First person not enabled")
local route=false
if map and nav and spawn and switch then
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={map}; params.RespectCanCollide=true
 local a=nav.SpawnGround.Position; local b=nav.MonsterGround.Position
 route=not W:Blockcast(CFrame.new(a+Vector3.new(0,8.5,0)),Vector3.new(3.6,15,3.6),b-a,params)
 check(route,"Initial tall-creature route blocked")
 check((spawn.Position-switch.Position).Magnitude<9,"Power switch unreachable from spawn")
 local floor=W:Raycast(spawn.Position+Vector3.new(0,2,0),Vector3.new(0,-5,0),params)
 check(floor~=nil,"Spawn has no supporting map floor")
end
local module=RS:FindFirstChild("ArenaAnimation")
local gripErrors={}
if module and rig then
 local ok,animation=pcall(require,module); check(ok,"Animation module failed")
 if ok then
  local clone=rig:Clone(); clone.Parent=nil
  local driver=animation.new(clone)
  for _,state in ipairs({"Idle","Walk","Run","Attack"}) do animation.Step(driver,state,1.3,0.1,true) end
  for side,arm in pairs(driver.arms) do
   local sign=side=="Right" and 1 or -1
   local root=clone:GetPivot()
   local center=(root*animation.Hold(1.3)).Position+Vector3.new(0,0.6,0)
   local desired=center+root.RightVector*sign*1.15
   local finger=driver.byName[side.."Finger2"].joint
   local actual=(finger.Part0.CFrame*finger.C0).Position
   gripErrors[side]=(actual-desired).Magnitude
   check(gripErrors[side]<0.9,"Hand cannot reach captured torso: "..side.." error "..tostring(gripErrors[side]))
  end
  check(driver.arms.Left~=nil and driver.arms.Right~=nil,"Measured arm chain absent")
  clone:Destroy()
 end
else check(false,"Animation module missing") end
return {ok=#errors==0,errors=errors,build=W:GetAttribute("DeadSignalBuildId"),version=game.PlaceVersion,mapAssetId=W:GetAttribute("TestMapAssetId"),mapParts=mapParts,rigParts=parts,joints=joints,externalScripts=foreign,lights=lights,spawnRouteClear=route,gripErrors=gripErrors,firstPerson=game:GetService("StarterPlayer").CameraMode.Name}
