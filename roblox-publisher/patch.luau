
assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"wrong target")

local AS=game:GetService("AssetService")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local SSS=game:GetService("ServerScriptService")
local SG=game:GetService("StarterGui")
local SPS=game:GetService("StarterPlayer").StarterPlayerScripts
local Lighting=game:GetService("Lighting")

local LOGO="rbxassetid://127912605246110"
local PLAYER_BASE_SPEED=10
local PLAYER_MAX_SPEED=50
local BOT_SPEED=48.5

Players.CharacterAutoLoads=false

-- =========================================================
-- ALWAYS DAY
-- =========================================================
Lighting.ClockTime=13.5
Lighting.Brightness=2
Lighting.ExposureCompensation=.12
Lighting.EnvironmentDiffuseScale=1
Lighting.EnvironmentSpecularScale=1
Lighting.Ambient=Color3.fromRGB(125,125,135)
Lighting.OutdoorAmbient=Color3.fromRGB(145,145,155)
Lighting.GlobalShadows=true

local oldDay=SSS:FindFirstChild("NB_DaylightLock")
if oldDay then oldDay:Destroy() end
local day=Instance.new("Script")
day.Name="NB_DaylightLock"
day.Source=[==[
local Lighting=game:GetService("Lighting")
while true do
 Lighting.ClockTime=13.5
 Lighting.Brightness=2
 Lighting.ExposureCompensation=.12
 Lighting.EnvironmentDiffuseScale=1
 Lighting.EnvironmentSpecularScale=1
 Lighting.GlobalShadows=true
 task.wait(1)
end
]==]
day.Parent=SSS

-- =========================================================
-- ROUND SERVER
-- Avatar exists during intermission and is already on ActiveMap.
-- Bots spawn only when the round begins, from dedicated bot spawns.
-- =========================================================
local round=SSS:FindFirstChild("NextbotsRoundServer")
assert(round,"NextbotsRoundServer missing")
round.Source=[==[
local Players=game:GetService("Players")
local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads=false

local maps=SS:WaitForChild("NB_Maps")
local templates=SS:WaitForChild("NB_Templates")
local baseCharacter=SS:WaitForChild("NB_StarterCharacterBase")
local net=RS:WaitForChild("NB_Remotes")
local join=net:WaitForChild("JoinGame")
local roundState=net:WaitForChild("RoundState")
local menuState=net:WaitForChild("MenuState")

local INTERMISSION=25
local ROUND_TIME=120
local MAX_BOTS=6
local PLAYER_BASE_SPEED=10

local lastMap=nil
local currentMapName=nil
local currentMapCF=nil
local currentMapSize=nil
local roundActive=false

local displayNames={
 Map1_Evade="EVADE MAP",
 Map2_RocketArena="ROCKET ARENA",
 Map3_Halloween="HALLOWEEN",
 Map4_Crossroads="CROSSROADS"
}

local function availableMaps()
 local list={"Map1_Evade","Map2_RocketArena","Map4_Crossroads"}
 local h=maps:FindFirstChild("Map3_Halloween")
 if h and os.date("*t").month==10 then table.insert(list,"Map3_Halloween") end
 return list
end

local function chooseMap()
 local list=availableMaps()
 if #list>1 and lastMap then
  local filtered={}
  for _,name in ipairs(list) do
   if name~=lastMap then table.insert(filtered,name) end
  end
  if #filtered>0 then list=filtered end
 end
 local picked=list[math.random(1,#list)]
 lastMap=picked
 return picked
end

local function cleanupWorld()
 local m=workspace:FindFirstChild("ActiveMap")
 if m then m:Destroy() end
 local b=workspace:FindFirstChild("ActiveNextbots")
 if b then b:Destroy() end
 local c=workspace:FindFirstChild("MenuCameraAnchor")
 if c then c:Destroy() end
 currentMapCF=nil
 currentMapSize=nil
end

local function rayGround(map,world)
 local p=RaycastParams.new()
 p.FilterType=Enum.RaycastFilterType.Include
 p.FilterDescendantsInstances={map}
 p.IgnoreWater=false
 return workspace:Raycast(world,Vector3.new(0,-1600,0),p)
end

local function createMenuCamera(map)
 local cf,size=map:GetBoundingBox()
 local center=cf.Position
 local radius=math.max(size.X,size.Z)
 local probes={
  cf*CFrame.new(0,size.Y*.5+120,size.Z*.30),
  cf*CFrame.new(size.X*.22,size.Y*.5+120,size.Z*.22),
  cf*CFrame.new(-size.X*.22,size.Y*.5+120,size.Z*.22)
 }
 local ground=nil
 for _,pcf in ipairs(probes) do
  local r=rayGround(map,pcf.Position)
  if r then ground=r.Position break end
 end
 ground=ground or center

 local pos=ground+Vector3.new(radius*.18,math.max(24,size.Y*.22),radius*.30)
 local anchor=Instance.new("Part")
 anchor.Name="MenuCameraAnchor"
 anchor.Size=Vector3.new(1,1,1)
 anchor.Transparency=1
 anchor.Anchored=true
 anchor.CanCollide=false
 anchor.CanTouch=false
 anchor.CanQuery=false
 anchor.CFrame=CFrame.lookAt(pos,ground+Vector3.new(0,5,0))
 anchor.Parent=workspace
end

local function collectPlayerSpawns(map)
 local points={}
 local folder=map:FindFirstChild("SpawnPoints")
 if folder then
  for _,d in ipairs(folder:GetChildren()) do
   if d:IsA("BasePart") then table.insert(points,d) end
  end
 end
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("SpawnLocation") then table.insert(points,d) end
 end
 return points
end

local function safePlayerCF(map)
 local points=collectPlayerSpawns(map)
 for _=1,math.max(8,#points*2) do
  if #points>0 then
   local p=points[math.random(1,#points)]
   local r=rayGround(map,p.Position+Vector3.new(math.random(-3,3),100,math.random(-3,3)))
   if r then return CFrame.new(r.Position+Vector3.new(0,4,0)) end
  else
   break
  end
 end

 local cf,size=map:GetBoundingBox()
 local half=size*.5
 for _=1,30 do
  local localX=(math.random()*2-1)*math.max(3,half.X*.70)
  local localZ=(math.random()*2-1)*math.max(3,half.Z*.70)
  local top=(cf*CFrame.new(localX,half.Y+150,localZ)).Position
  local r=rayGround(map,top)
  if r then return CFrame.new(r.Position+Vector3.new(0,4,0)) end
 end

 local best=nil
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("BasePart") and d.CanCollide and d.Transparency<.98 then
   if not best or d.Size.X*d.Size.Z>best.Size.X*best.Size.Z then best=d end
  end
 end
 assert(best,"ActiveMap has no collidable player spawn surface")
 return CFrame.new(best.Position+best.CFrame.UpVector*(best.Size.Y*.5+4))
end

local function createBotSpawns(map)
 local old=map:FindFirstChild("NextbotSpawnPoints")
 if old then old:Destroy() end
 local folder=Instance.new("Folder")
 folder.Name="NextbotSpawnPoints"
 folder.Parent=map

 local cf,size=map:GetBoundingBox()
 local hx,hz=size.X*.43,size.Z*.43
 local offsets={
  Vector3.new(-hx,0,-hz),Vector3.new(0,0,-hz),Vector3.new(hx,0,-hz),
  Vector3.new(-hx,0,0),Vector3.new(hx,0,0),
  Vector3.new(-hx,0,hz),Vector3.new(0,0,hz),Vector3.new(hx,0,hz)
 }

 for _,off in ipairs(offsets) do
  local top=(cf*CFrame.new(off.X,size.Y*.5+160,off.Z)).Position
  local r=rayGround(map,top)
  if r then
   local p=Instance.new("Part")
   p.Name="NextbotSpawn"
   p.Size=Vector3.new(4,.5,4)
   p.Anchored=true
   p.CanCollide=false
   p.CanTouch=false
   p.CanQuery=false
   p.Transparency=1
   p.CFrame=CFrame.new(r.Position+Vector3.new(0,3,0))
   p.Parent=folder
  end
 end

 if #folder:GetChildren()==0 then
  local fallback=safePlayerCF(map)
  local p=Instance.new("Part")
  p.Name="NextbotSpawn"
  p.Size=Vector3.new(4,.5,4)
  p.Anchored=true
  p.CanCollide=false
  p.CanTouch=false
  p.CanQuery=false
  p.Transparency=1
  p.CFrame=fallback
  p.Parent=folder
 end
 return folder
end

local function loadMap(name)
 cleanupWorld()
 local src=maps:FindFirstChild(name)
 assert(src,"missing "..name)

 local map=src:Clone()
 map.Name="ActiveMap"
 map.Parent=workspace
 currentMapName=name
 currentMapCF,currentMapSize=map:GetBoundingBox()

 createBotSpawns(map)
 createMenuCamera(map)
 return map
end

local function copyUserAppearance(plr,char)
 local desc
 local ok=pcall(function()
  desc=Players:GetHumanoidDescriptionFromUserIdAsync(plr.UserId)
 end)
 if not ok or not desc then return end

 local temp
 local made=pcall(function()
  temp=Players:CreateHumanoidModelFromDescriptionAsync(
   desc,Enum.HumanoidRigType.R6,Enum.AssetTypeVerification.Always
  )
 end)
 if not made or not temp then return end

 for _,className in ipairs({"Shirt","Pants","ShirtGraphic","BodyColors"}) do
  local src=temp:FindFirstChildOfClass(className)
  local old=char:FindFirstChildOfClass(className)
  if old then old:Destroy() end
  if src then src:Clone().Parent=char end
 end

 local head=char:FindFirstChild("Head")
 local tempHead=temp:FindFirstChild("Head")
 if head and tempHead then
  local oldFace=head:FindFirstChildWhichIsA("Decal")
  if oldFace then oldFace:Destroy() end
  local face=tempHead:FindFirstChildWhichIsA("Decal")
  if face then face:Clone().Parent=head end
 end

 local hum=char:FindFirstChildOfClass("Humanoid")
 if hum then
  for _,obj in ipairs(temp:GetChildren()) do
   if obj:IsA("Accessory") then
    pcall(function() hum:AddAccessory(obj:Clone()) end)
   end
  end
 end
 temp:Destroy()
end

local function buildCharacter(plr,cf)
 local old=plr.Character
 if old and old.Parent then old:Destroy() end

 local char=baseCharacter:Clone()
 char.Name=plr.Name

 local hum=char:FindFirstChildOfClass("Humanoid")
 local root=char:FindFirstChild("HumanoidRootPart")
 assert(hum and root and hum.RigType==Enum.HumanoidRigType.R6,"Evade base invalid")

 hum.DisplayName=plr.DisplayName
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 hum.WalkSpeed=PLAYER_BASE_SPEED
 hum.JumpPower=50
 hum.UseJumpPower=true
 hum.AutoRotate=true

 for _,d in ipairs(char:GetDescendants()) do
  if d:IsA("LuaSourceContainer") then d:Destroy() end
 end

 char.PrimaryPart=root
 char.Parent=workspace
 copyUserAppearance(plr,char)
 plr.Character=char
 char:PivotTo(cf)
 return char
end

local function ensureOnMap(plr,map)
 local cf=safePlayerCF(map)
 local ch=plr.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if ch and hum and hum.Health>0 then
  ch:PivotTo(cf)
  hum.WalkSpeed=PLAYER_BASE_SPEED
  return ch
 end
 return buildCharacter(plr,cf)
end

local function isPhysicallyInsideMap(plr)
 if not currentMapCF or not currentMapSize then return false end
 local ch=plr.Character
 local root=ch and ch:FindFirstChild("HumanoidRootPart")
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 then return false end

 local p=currentMapCF:PointToObjectSpace(root.Position)
 local half=currentMapSize*.5
 local margin=18
 return math.abs(p.X)<=half.X+margin
  and math.abs(p.Z)<=half.Z+margin
  and p.Y>=-80
  and p.Y<=half.Y+120
end

local function attachDeath(plr,char)
 local hum=char:FindFirstChildOfClass("Humanoid")
 if not hum then return end
 hum.Died:Connect(function()
  if not plr.Parent then return end
  plr:SetAttribute("NBInMap",false)
  plr:SetAttribute("NBState","Dead")
  menuState:FireClient(plr,"Show","Dead")
  task.wait(1)
  if not plr.Parent then return end
  local map=workspace:FindFirstChild("ActiveMap")
  if map then
   buildCharacter(plr,safePlayerCF(map))
  end
  plr:SetAttribute("NBState","Menu")
  plr:SetAttribute("NBInMap",false)
 end)
end

local function joinRound(plr)
 local map=workspace:FindFirstChild("ActiveMap")
 if not map or not plr.Parent then return end
 local ch=ensureOnMap(plr,map)
 plr:SetAttribute("NBState","InRound")
 plr:SetAttribute("NBInMap",roundActive and isPhysicallyInsideMap(plr) or false)
 attachDeath(plr,ch)
 menuState:FireClient(plr,"InRound",displayNames[currentMapName] or currentMapName)
end

local function spawnBots(map)
 local src=templates:FindFirstChild("Nextbots")
 if not src then return end

 local old=workspace:FindFirstChild("ActiveNextbots")
 if old then old:Destroy() end
 local folder=Instance.new("Folder")
 folder.Name="ActiveNextbots"
 folder.Parent=workspace

 local spawnFolder=map:FindFirstChild("NextbotSpawnPoints")
 local spawnList=spawnFolder and spawnFolder:GetChildren() or {}
 local n=0

 for _,bot in ipairs(src:GetChildren()) do
  if bot:IsA("Model") and n<MAX_BOTS then
   n+=1
   local b=bot:Clone()
   b:SetAttribute("NBNextbot",true)
   b.Parent=folder

   local hum=b:FindFirstChildOfClass("Humanoid")
   if hum then hum.WalkSpeed=48.5 end

   for _,d in ipairs(b:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then d.Disabled=true end
    if d:IsA("BasePart") then
     d.CanCollide=false
     d.CanTouch=false
    elseif d:IsA("Sound") then
     d:SetAttribute("NBOriginalVolume",d.Volume)
     d.RollOffMaxDistance=100
    end
   end

   local p=spawnList[((n-1)%math.max(1,#spawnList))+1]
   if p and p:IsA("BasePart") then
    b:PivotTo(p.CFrame)
   else
    b:PivotTo(safePlayerCF(map))
   end
  end
 end
end

join.OnServerEvent:Connect(function(plr)
 local state=plr:GetAttribute("NBState")
 if state=="InRound" or state=="Queued" then return end

 if roundActive then
  joinRound(plr)
 else
  -- During intermission the avatar already remains physically in the map.
  -- JOIN GAME only marks the player to become targetable when the timer ends.
  plr:SetAttribute("NBState","Queued")
  plr:SetAttribute("NBInMap",false)
  menuState:FireClient(plr,"Queued",currentMapName)
 end
end)

local function initPlayer(plr)
 plr:SetAttribute("NBState","Menu")
 plr:SetAttribute("NBInMap",false)
 plr:SetAttribute("NBLevel",plr:GetAttribute("NBLevel") or 1)
 plr:SetAttribute("NBCoins",plr:GetAttribute("NBCoins") or 0)
 plr:SetAttribute("NBTokens",plr:GetAttribute("NBTokens") or 0)
 plr:SetAttribute("NBWins",plr:GetAttribute("NBWins") or 0)
 plr:SetAttribute("NBRevives",plr:GetAttribute("NBRevives") or 0)

 task.spawn(function()
  local map=workspace:FindFirstChild("ActiveMap") or workspace:WaitForChild("ActiveMap",15)
  if map and plr.Parent then ensureOnMap(plr,map) end
 end)
end

Players.PlayerAdded:Connect(initPlayer)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(initPlayer,p) end

task.spawn(function()
 while true do
  for _,p in ipairs(Players:GetPlayers()) do
   local targetable=roundActive
    and p:GetAttribute("NBState")=="InRound"
    and isPhysicallyInsideMap(p)
   p:SetAttribute("NBInMap",targetable)
  end
  task.wait(.25)
 end
end)

workspace:SetAttribute("NBRoundActive",false)
workspace:SetAttribute("NBIntermission",INTERMISSION)

task.spawn(function()
 while true do
  roundActive=false
  workspace:SetAttribute("NBRoundActive",false)

  local picked=chooseMap()
  local map=loadMap(picked)
  local pretty=displayNames[picked] or picked

  -- Everyone is already physically on the selected map for intermission.
  for _,p in ipairs(Players:GetPlayers()) do
   p:SetAttribute("NBInMap",false)
   p:SetAttribute("NBState","Menu")
   ensureOnMap(p,map)
   menuState:FireClient(p,"Show","Intermission")
  end

  for t=INTERMISSION,0,-1 do
   workspace:SetAttribute("NBIntermission",t)
   roundState:FireAllClients("Intermission",t,pretty)
   task.wait(1)
  end

  roundActive=true
  workspace:SetAttribute("NBRoundActive",true)
  spawnBots(map)

  for _,p in ipairs(Players:GetPlayers()) do
   if p:GetAttribute("NBState")=="Queued" then
    joinRound(p)
   else
    p:SetAttribute("NBInMap",false)
   end
  end

  for t=ROUND_TIME,0,-1 do
   if not workspace:FindFirstChild("ActiveMap") then break end
   roundState:FireAllClients("Round",t,pretty)
   task.wait(1)
  end

  roundActive=false
  workspace:SetAttribute("NBRoundActive",false)
  local bots=workspace:FindFirstChild("ActiveNextbots")
  if bots then bots:Destroy() end

  for _,p in ipairs(Players:GetPlayers()) do
   p:SetAttribute("NBInMap",false)
   p:SetAttribute("NBState","Menu")
   menuState:FireClient(p,"Show","RoundEnd")
  end
  task.wait(.5)
 end
end)
]==]

-- =========================================================
-- NEXTBOT DIRECTOR
-- Common bot speed = 98% of player's 36 max ~= 35.28.
-- =========================================================
local director=SSS:FindFirstChild("NextbotDirector")
assert(director,"NextbotDirector missing")
director.Source=[==[
local Players=game:GetService("Players")
local PathfindingService=game:GetService("PathfindingService")
local BOT_SPEED=48.5

local function nearestTarget(pos)
 local best=nil
 local bestDistance=nil

 for _,p in ipairs(Players:GetPlayers()) do
  if p:GetAttribute("NBInMap")==true and p:GetAttribute("NBState")=="InRound" then
   local ch=p.Character
   local hum=ch and ch:FindFirstChildOfClass("Humanoid")
   local root=ch and ch:FindFirstChild("HumanoidRootPart")
   if hum and root and hum.Health>0 then
    local d=(root.Position-pos).Magnitude
    if not bestDistance or d<bestDistance then
     best={player=p,hum=hum,root=root}
     bestDistance=d
    end
   end
  end
 end
 return best,bestDistance
end

while true do
 local folder=workspace:FindFirstChild("ActiveNextbots")
 if workspace:GetAttribute("NBRoundActive") and folder then
  for _,bot in ipairs(folder:GetChildren()) do
   if bot:IsA("Model") then
    local hum=bot:FindFirstChildOfClass("Humanoid")
    local root=bot:FindFirstChild("HumanoidRootPart")
     or bot.PrimaryPart
     or bot:FindFirstChildWhichIsA("BasePart",true)

    if root then
     local target,distance=nearestTarget(root.Position)
     if target then
      if hum then hum.WalkSpeed=BOT_SPEED end

      if distance and distance<4.2 then
       if target.player:GetAttribute("NBInMap")==true then
        target.hum.Health=0
       end
      elseif hum then
       local ok,path=pcall(function()
        local p=PathfindingService:CreatePath({
         AgentRadius=2,
         AgentHeight=5,
         AgentCanJump=true,
         WaypointSpacing=6
        })
        p:ComputeAsync(root.Position,target.root.Position)
        return p
       end)

       if ok and path and path.Status==Enum.PathStatus.Success then
        local points=path:GetWaypoints()
        local wp=points[math.min(2,#points)]
        if wp then
         if wp.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
         hum:MoveTo(wp.Position)
        end
       else
        hum:MoveTo(target.root.Position)
       end
      end
     elseif hum then
      hum:MoveTo(root.Position)
     end
    end
   end
  end
 end
 task.wait(.35)
end
]==]

-- =========================================================
-- EVADE-STYLE PLAYER ACCELERATION
-- =========================================================
local oldMove=SPS:FindFirstChild("NB_EvadeMovement")
if oldMove then oldMove:Destroy() end
local move=Instance.new("LocalScript")
move.Name="NB_EvadeMovement"
move.Source=[==[
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local BASE_SPEED=10
local MAX_SPEED=50
local ACCEL_TIME=10
local RUN_THRESHOLD=20
local RUN_ANIMATION="rbxassetid://10902697177"

local renderConn=nil
local runTrack=nil
local speed=BASE_SPEED
local moving=false

local function stopTrack()
 if runTrack then
  pcall(function()runTrack:Stop(.12)end)
  runTrack=nil
 end
end

local function setup(char)
 if renderConn then renderConn:Disconnect();renderConn=nil end
 stopTrack()

 local hum=char:WaitForChild("Humanoid",8)
 if not hum then return end
 local animator=hum:FindFirstChildOfClass("Animator") or Instance.new("Animator",hum)

 local anim=Instance.new("Animation")
 anim.AnimationId=RUN_ANIMATION
 local ok,track=pcall(function()return animator:LoadAnimation(anim)end)
 if ok then
  runTrack=track
  runTrack.Priority=Enum.AnimationPriority.Movement
  runTrack.Looped=true
 end

 speed=BASE_SPEED
 hum.WalkSpeed=BASE_SPEED
 local cam=workspace.CurrentCamera

 renderConn=RunService.RenderStepped:Connect(function(dt)
  if not char.Parent or hum.Health<=0 then return end

  local isMoving=hum.MoveDirection.Magnitude>.05
  if isMoving then
   speed=math.min(MAX_SPEED,speed+((MAX_SPEED-BASE_SPEED)/ACCEL_TIME)*dt)
  else
   speed=BASE_SPEED
  end
  hum.WalkSpeed=speed

  -- FOV behavior from the supplied evade movement asset: 70 idle -> 80 running.
  local targetFov=isMoving and 80 or 70
  cam.FieldOfView=cam.FieldOfView+(targetFov-cam.FieldOfView)*math.min(1,dt*7)

  if runTrack then
   if isMoving and speed>=RUN_THRESHOLD then
    if not runTrack.IsPlaying then runTrack:Play(.10) end
    -- Keep foot cadence synced with actual acceleration.
    runTrack:AdjustSpeed(math.clamp(1.15+(speed-RUN_THRESHOLD)/(MAX_SPEED-RUN_THRESHOLD)*.65,1.15,1.8))
   elseif runTrack.IsPlaying then
    runTrack:Stop(.10)
   end
  end

  moving=isMoving
 end)
end

player.CharacterAdded:Connect(setup)
if player.Character then task.spawn(setup,player.Character) end
]==]
move.Parent=SPS

-- Directional R6 keyframes remain active, but their playback speed now follows
-- the actual acceleration instead of playing at one fixed cadence.
local oldMotion=SPS:FindFirstChild("NB_R6MotionController")
if oldMotion then oldMotion:Destroy() end
local motion=Instance.new("LocalScript")
motion.Name="NB_R6MotionController"
motion.Source=[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local clips=RS:WaitForChild("NB_R6Animations")
local conn

local function flattenPose(p,map)
 if p:IsA("Pose") then map[p.Name]=p.CFrame end
 for _,c in ipairs(p:GetChildren()) do
  if c:IsA("Pose") then flattenPose(c,map) end
 end
end

local function bake(seq)
 local frames={}
 for _,kf in ipairs(seq:GetKeyframes()) do
  local poses={}
  for _,p in ipairs(kf:GetChildren()) do
   if p:IsA("Pose") then flattenPose(p,poses) end
  end
  table.insert(frames,{t=kf.Time,poses=poses})
 end
 table.sort(frames,function(a,b)return a.t<b.t end)
 local duration=(frames[#frames] and frames[#frames].t) or 1
 return {frames=frames,duration=math.max(duration,.05),looped=seq.Loop}
end

local baked={}
for _,seq in ipairs(clips:GetChildren()) do
 if seq:IsA("KeyframeSequence") then baked[seq.Name]=bake(seq) end
end

local function sample(clip,t)
 if not clip or #clip.frames==0 then return {} end
 local time=clip.looped and (t%clip.duration) or math.min(t,clip.duration)
 local a,b=clip.frames[1],clip.frames[#clip.frames]
 for i=1,#clip.frames-1 do
  if time>=clip.frames[i].t and time<=clip.frames[i+1].t then
   a,b=clip.frames[i],clip.frames[i+1]
   break
  end
 end
 local alpha=math.clamp((time-a.t)/math.max(.0001,b.t-a.t),0,1)
 local out={}
 for part,cf in pairs(a.poses) do out[part]=cf:Lerp(b.poses[part] or cf,alpha) end
 for part,cf in pairs(b.poses) do if not out[part] then out[part]=cf end end
 return out
end

local function setup(char)
 if conn then conn:Disconnect();conn=nil end
 local hum=char:WaitForChild("Humanoid",8)
 local root=char:WaitForChild("HumanoidRootPart",8)
 if not hum or not root or hum.RigType~=Enum.HumanoidRigType.R6 then return end

 local motors={}
 for _,d in ipairs(char:GetDescendants()) do
  if d:IsA("Motor6D") and d.Part1 then motors[d.Part1.Name]=d end
 end

 local current="idle"
 local started=os.clock()
 local transition=os.clock()
 local from={}

 local function desired()
  local st=hum:GetState()
  if st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall then
   return baked.jump and "jump" or "idle"
  end
  if hum.MoveDirection.Magnitude<.05 then return "idle" end

  local localDir=root.CFrame:VectorToObjectSpace(hum.MoveDirection)
  local x,z=localDir.X,localDir.Z
  if z<-.35 then
   if x<-.30 and baked.FLeft then return "FLeft" end
   if x>.30 and baked.FRight then return "FRight" end
   return baked.Forward and "Forward" or "forward"
  elseif z>.35 then
   return baked.back and "back" or "idle"
  elseif x<0 then
   return baked.left and "left" or "idle"
  else
   return baked.right and "right" or "idle"
  end
 end

 conn=RunService.RenderStepped:Connect(function()
  if not char.Parent or hum.Health<=0 then return end

  local nextName=desired()
  if not baked[nextName] then nextName="idle" end

  if nextName~=current then
   from={}
   for part,m in pairs(motors) do from[part]=m.Transform end
   current=nextName
   started=os.clock()
   transition=started
  end

  local isMove=current~="idle" and current~="jump"
  local playbackRate=isMove and math.clamp(hum.WalkSpeed/20,.75,2.25) or 1
  local poses=sample(baked[current],(os.clock()-started)*playbackRate)
  local alpha=math.clamp((os.clock()-transition)/.10,0,1)

  for part,m in pairs(motors) do
   m.Transform=(from[part] or m.Transform):Lerp(poses[part] or CFrame.new(),alpha)
  end
 end)
end

player.CharacterAdded:Connect(setup)
if player.Character then task.spawn(setup,player.Character) end
]==]
motion.Parent=SPS

-- old HUD conflicts with the rebuilt interface
local oldHud=SPS:FindFirstChild("NBReferenceHUDClient")
if oldHud then oldHud:Destroy() end

-- =========================================================
-- CLIENT NEXTBOT VISIBILITY
-- =========================================================
local oldVis=SPS:FindFirstChild("NB_NextbotVisibility")
if oldVis then oldVis:Destroy() end
local vis=Instance.new("LocalScript")
vis.Name="NB_NextbotVisibility"
vis.Source=[==[
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local originals=setmetatable({},{__mode="k"})

local function save(inst)
 if originals[inst]~=nil then return end
 if inst:IsA("BasePart") then
  originals[inst]={kind="part",value=inst.LocalTransparencyModifier}
 elseif inst:IsA("Decal") or inst:IsA("Texture") then
  originals[inst]={kind="transparency",value=inst.Transparency}
 elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui")
  or inst:IsA("ParticleEmitter") or inst:IsA("Trail")
  or inst:IsA("Beam") or inst:IsA("Light") then
  originals[inst]={kind="enabled",value=inst.Enabled}
 elseif inst:IsA("Sound") then
  originals[inst]={kind="volume",value=inst.Volume}
 end
end

local function apply(inst,inside)
 save(inst)
 local o=originals[inst]
 if not o then return end
 if o.kind=="part" then
  inst.LocalTransparencyModifier=inside and o.value or 1
 elseif o.kind=="transparency" then
  inst.Transparency=inside and o.value or 1
 elseif o.kind=="enabled" then
  inst.Enabled=inside and o.value or false
 elseif o.kind=="volume" then
  inst.Volume=inside and o.value or 0
 end
end

local function refresh()
 local inside=player:GetAttribute("NBInMap")==true
 local folder=workspace:FindFirstChild("ActiveNextbots")
 if not folder then return end
 for _,inst in ipairs(folder:GetDescendants()) do apply(inst,inside) end
end

workspace.ChildAdded:Connect(function(child)
 if child.Name=="ActiveNextbots" then
  child.DescendantAdded:Connect(function(inst)
   task.defer(function()apply(inst,player:GetAttribute("NBInMap")==true)end)
  end)
  task.defer(refresh)
 end
end)

player:GetAttributeChangedSignal("NBInMap"):Connect(refresh)
refresh()
]==]
vis.Parent=SPS

-- =========================================================
-- REBUILD UI FROM REFERENCES
-- =========================================================
local oldUI=SG:FindFirstChild("NextbotsBrasilUI")
if oldUI then oldUI:Destroy() end

local ui=Instance.new("ScreenGui")
ui.Name="NextbotsBrasilUI"
ui.IgnoreGuiInset=true
ui.ResetOnSpawn=false
ui.DisplayOrder=40
ui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ui.Parent=SG

local function corner(parent,r)
 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,r or 8)
 c.Parent=parent
 return c
end

local function stroke(parent,color,thick,trans)
 local s=Instance.new("UIStroke")
 s.Color=color or Color3.fromRGB(90,90,90)
 s.Thickness=thick or 2
 s.Transparency=trans or 0
 s.Parent=parent
 return s
end

local function label(parent,name,txt,pos,size,font,z)
 local t=Instance.new("TextLabel")
 t.Name=name
 t.BackgroundTransparency=1
 t.Position=pos
 t.Size=size
 t.Text=txt
 t.TextColor3=Color3.fromRGB(245,245,248)
 t.TextStrokeColor3=Color3.fromRGB(0,0,0)
 t.TextStrokeTransparency=.25
 t.TextScaled=true
 t.TextWrapped=true
 t.Font=font or Enum.Font.GothamBold
 t.ZIndex=z or 10
 t.Parent=parent
 return t
end

local function frame(parent,name,pos,size,color,trans,z,r)
 local f=Instance.new("Frame")
 f.Name=name
 f.Position=pos
 f.Size=size
 f.BackgroundColor3=color or Color3.fromRGB(10,10,12)
 f.BackgroundTransparency=trans or 0
 f.BorderSizePixel=0
 f.ZIndex=z or 5
 f.Parent=parent
 corner(f,r or 8)
 return f
end

local function textButton(parent,name,txt,pos,size,bg,border,z)
 local b=Instance.new("TextButton")
 b.Name=name
 b.Position=pos
 b.Size=size
 b.BackgroundColor3=bg or Color3.fromRGB(25,25,28)
 b.BackgroundTransparency=.10
 b.BorderSizePixel=0
 b.Text=txt
 b.TextColor3=Color3.fromRGB(245,245,245)
 b.TextStrokeTransparency=.20
 b.TextScaled=true
 b.TextWrapped=true
 b.Font=Enum.Font.GothamBlack
 b.AutoButtonColor=false
 b.ZIndex=z or 20
 b.Parent=parent
 corner(b,7)
 stroke(b,border or Color3.fromRGB(90,90,95),2,.08)
 return b
end

-- LOADING: exact logo + CARREGANDO below it
local loading=Instance.new("Frame")
loading.Name="Background"
loading.Size=UDim2.fromScale(1,1)
loading.BackgroundColor3=Color3.fromRGB(0,0,0)
loading.BorderSizePixel=0
loading.ZIndex=1000
loading.Parent=ui

local loadLogo=Instance.new("ImageLabel")
loadLogo.Name="ExactLogo_Loading"
loadLogo.AnchorPoint=Vector2.new(.5,.5)
loadLogo.Position=UDim2.fromScale(.5,.44)
loadLogo.Size=UDim2.fromScale(.48,.36)
loadLogo.BackgroundTransparency=1
loadLogo.Image=LOGO
loadLogo.ScaleType=Enum.ScaleType.Fit
loadLogo.ZIndex=1001
loadLogo.Parent=loading

local loadText=label(loading,"LoadingText","CARREGANDO...",UDim2.fromScale(.37,.66),UDim2.fromScale(.26,.055),Enum.Font.GothamBlack,1002)
loadText.TextColor3=Color3.fromRGB(235,235,240)

-- MAIN MENU
local menu=Instance.new("Frame")
menu.Name="MainMenu"
menu.Size=UDim2.fromScale(1,1)
menu.BackgroundTransparency=1
menu.Visible=false
menu.Parent=ui

local ver=label(menu,"MenuVersion","Versão: NEXTBOTS BRASIL",UDim2.fromScale(.42,.03),UDim2.fromScale(.16,.035),Enum.Font.Gotham,15)
ver.TextTransparency=.40

local status=textButton(ui,"RoundStatus","INTERMISSION\n0:25",UDim2.fromScale(.445,.105),UDim2.fromScale(.11,.085),Color3.fromRGB(10,18,30),Color3.fromRGB(58,74,98),45)
status.Visible=false

local logo=Instance.new("ImageLabel")
logo.Name="ExactLogo_Menu"
logo.AnchorPoint=Vector2.new(.5,.5)
logo.Position=UDim2.fromScale(.50,.34)
logo.Size=UDim2.fromScale(.31,.24)
logo.BackgroundTransparency=1
logo.Image=LOGO
logo.ScaleType=Enum.ScaleType.Fit
logo.ZIndex=25
logo.Parent=menu

local function card(name,x,txt,border,imageId)
 local b=Instance.new("TextButton")
 b.Name=name
 b.AnchorPoint=Vector2.new(.5,.5)
 b.Position=UDim2.fromScale(x,.60)
 b.Size=UDim2.fromScale(.155,.115)
 b.BackgroundColor3=Color3.fromRGB(10,10,12)
 b.BorderSizePixel=0
 b.Text=""
 b.ClipsDescendants=true
 b.AutoButtonColor=false
 b.ZIndex=25
 b.Parent=menu
 corner(b,7)
 stroke(b,border,3,.02)

 local art=Instance.new("ImageLabel")
 art.Name="CardArt"
 art.Size=UDim2.fromScale(1,1)
 art.BackgroundTransparency=1
 art.Image="rbxthumb://type=Asset&id="..imageId.."&w=420&h=420"
 art.ScaleType=Enum.ScaleType.Crop
 art.ZIndex=25
 art.Parent=b

 local shade=Instance.new("Frame")
 shade.Name="Shade"
 shade.AnchorPoint=Vector2.new(0,1)
 shade.Position=UDim2.fromScale(0,1)
 shade.Size=UDim2.fromScale(1,.31)
 shade.BackgroundColor3=Color3.fromRGB(0,0,0)
 shade.BackgroundTransparency=.18
 shade.BorderSizePixel=0
 shade.ZIndex=26
 shade.Parent=b

 local t=label(b,"CardText",txt,UDim2.fromScale(.03,.72),UDim2.fromScale(.94,.23),Enum.Font.GothamBlack,27)
 t.TextColor3=border
 return b
end

local shopBtn=card("ShopButton",.395,"LOJA",Color3.fromRGB(82,245,91),"8904355523")
local playBtn=card("PlayButton",.555,"ENTRAR NO JOGO",Color3.fromRGB(225,178,103),"11542091810")
local invBtn=card("InventoryButton",.715,"INVENTÁRIO",Color3.fromRGB(235,105,110),"13844097788")

-- LEFT STATS like reference
local left=Instance.new("Frame")
left.Name="ReferenceLeftHUD"
left.Position=UDim2.fromScale(.065,.135)
left.Size=UDim2.fromScale(.13,.29)
left.BackgroundTransparency=1
left.Parent=menu

local xp=frame(left,"XPBar",UDim2.fromScale(0,0),UDim2.fromScale(1,.07),Color3.fromRGB(93,128,210),0,20,4)
local xpFill=Instance.new("Frame")
xpFill.Name="Fill"
xpFill.Size=UDim2.fromScale(.62,1)
xpFill.BackgroundColor3=Color3.fromRGB(105,118,255)
xpFill.BorderSizePixel=0
xpFill.ZIndex=21
xpFill.Parent=xp
corner(xpFill,4)
label(left,"Level","NÍVEL 1",UDim2.fromScale(.01,.08),UDim2.fromScale(.68,.10),Enum.Font.GothamBlack,21)

local statRows={
 {"Stat1","◎","0",Color3.fromRGB(135,255,68)},
 {"Stat2","◆","0",Color3.fromRGB(245,245,245)},
 {"Stat3","♜","0",Color3.fromRGB(240,168,85)},
 {"Stat4","✦","0",Color3.fromRGB(255,220,60)}
}
for i,row in ipairs(statRows) do
 local f=frame(left,row[1],UDim2.fromScale(0,.20+(i-1)*.19),UDim2.fromScale(.72,.15),Color3.fromRGB(20,23,28),.15,20,5)
 local ic=label(f,"Icon",row[2],UDim2.fromScale(.02,.08),UDim2.fromScale(.24,.84),Enum.Font.GothamBlack,21)
 ic.TextColor3=row[4]
 local val=label(f,"Value",row[3],UDim2.fromScale(.28,.07),UDim2.fromScale(.62,.85),Enum.Font.GothamBlack,21)
 val.TextXAlignment=Enum.TextXAlignment.Left
end

-- RIGHT ACTION STACK
local right=Instance.new("Frame")
right.Name="ReferenceRightHUD"
right.Position=UDim2.fromScale(.865,.24)
right.Size=UDim2.fromScale(.09,.56)
right.BackgroundColor3=Color3.fromRGB(15,15,17)
right.BackgroundTransparency=.28
right.BorderSizePixel=0
right.Parent=menu
corner(right,8)

local actionData={
 {"BOOMBOX","▣\nCAIXA DE SOM",Color3.fromRGB(191,80,255)},
 {"SETTINGS","⚙\nCONFIGURAÇÕES",Color3.fromRGB(175,175,180)},
 {"LEADERBOARD","◉\nCLASSIFICAÇÃO",Color3.fromRGB(205,205,205)},
 {"DAILYMISSIONS","✓\nMISSÕES DIÁRIAS",Color3.fromRGB(235,235,235)},
 {"CODES","★\nCÓDIGOS",Color3.fromRGB(95,180,255)},
 {"CREDITS","●●●\nCRÉDITOS",Color3.fromRGB(215,195,120)},
 {"ROBUX","◇\nROBUX",Color3.fromRGB(75,220,90)}
}
for i,a in ipairs(actionData) do
 local b=textButton(right,a[1],a[2],UDim2.fromScale(.08,.02+(i-1)*.139),UDim2.fromScale(.84,.125),Color3.fromRGB(28,28,31),a[3],22)
 b.TextSize=10
 b.TextScaled=true
end

-- BOTTOM BUTTONS
local bottom=Instance.new("Frame")
bottom.Name="ReferenceBottomHUD"
bottom.Position=UDim2.fromScale(.34,.79)
bottom.Size=UDim2.fromScale(.36,.115)
bottom.BackgroundTransparency=1
bottom.Parent=menu
local b1=textButton(bottom,"Changelog","▤\nREGISTRO DE MUDANÇAS",UDim2.fromScale(0,0),UDim2.fromScale(.29,1),Color3.fromRGB(25,25,28),Color3.fromRGB(85,85,90),22)
local b2=textButton(bottom,"ModeBrowser","▰\nMODE BROWSER",UDim2.fromScale(.355,0),UDim2.fromScale(.29,1),Color3.fromRGB(25,25,28),Color3.fromRGB(86,113,170),22)
local b3=textButton(bottom,"Spectate","◉\nOBSERVAR",UDim2.fromScale(.71,0),UDim2.fromScale(.29,1),Color3.fromRGB(25,25,28),Color3.fromRGB(120,105,170),22)

-- SHOP ROOT: left-side panel from reference
local shopRoot=frame(ui,"ShopPanel",UDim2.fromScale(.075,.17),UDim2.fromScale(.28,.61),Color3.fromRGB(20,17,14),.18,100,8)
shopRoot.Visible=false
local header=frame(shopRoot,"Header",UDim2.fromScale(0,0),UDim2.fromScale(1,.12),Color3.fromRGB(65,43,23),.12,101,8)
label(header,"Title","LOJA",UDim2.fromScale(.05,.1),UDim2.fromScale(.9,.8),Enum.Font.GothamBlack,102)

local shopEntries={
 {"DailyShop","LOJA DIÁRIA  ▦",Color3.fromRGB(210,115,125)},
 {"Equipment","EQUIPAMENTO  🔧",Color3.fromRGB(110,145,230)},
 {"Character","PERSONAGEM  ●",Color3.fromRGB(205,120,130)},
 {"Emotes","EMOTES  ♪",Color3.fromRGB(210,190,115)},
 {"Robux","ROBUX  ◇",Color3.fromRGB(105,205,105)}
}
for i,e in ipairs(shopEntries) do
 local b=textButton(shopRoot,e[1],e[2],UDim2.fromScale(.06,.15+(i-1)*.14),UDim2.fromScale(.88,.115),Color3.fromRGB(20,20,22),e[3],103)
 b.TextXAlignment=Enum.TextXAlignment.Left
end
local shopExit=textButton(shopRoot,"Exit","SAÍDA",UDim2.fromScale(.27,.87),UDim2.fromScale(.46,.10),Color3.fromRGB(197,67,75),Color3.fromRGB(232,90,100),103)

-- DAILY SHOP CENTER
local daily=frame(ui,"DailyShopPanel",UDim2.fromScale(.255,.21),UDim2.fromScale(.49,.55),Color3.fromRGB(11,11,13),.10,110,8)
daily.Visible=false
local dailyHeader=frame(daily,"Header",UDim2.fromScale(0,0),UDim2.fromScale(1,.18),Color3.fromRGB(195,68,78),.0,111,8)
label(dailyHeader,"Title","LOJA DIÁRIA",UDim2.fromScale(.15,.12),UDim2.fromScale(.70,.76),Enum.Font.GothamBlack,112)
label(daily,"Timer","Atualiza em 05:42:27",UDim2.fromScale(.34,.18),UDim2.fromScale(.32,.06),Enum.Font.GothamBold,112)

local productNames={"GREEN BARRIER","BLUE FADED CAPE","DYSTOPIAN FLOODLIGHT","SNOW ANGEL"}
for i,n in ipairs(productNames) do
 local x=.03+(i-1)*.245
 local p=frame(daily,"Product"..i,UDim2.fromScale(x,.27),UDim2.fromScale(.22,.58),Color3.fromRGB(16,16,18),.02,112,7)
 stroke(p,Color3.fromRGB(42,42,45),2,.05)
 label(p,"Price",({"15","20","50","40"})[i],UDim2.fromScale(.06,.03),UDim2.fromScale(.34,.12),Enum.Font.GothamBlack,113)
 local thumb=Instance.new("ImageLabel")
 thumb.Position=UDim2.fromScale(.05,.14)
 thumb.Size=UDim2.fromScale(.90,.58)
 thumb.BackgroundColor3=Color3.fromRGB(32,32,35)
 thumb.BackgroundTransparency=.20
 thumb.Image="rbxthumb://type=Asset&id="..({"8904355523","11542091810","5036801877","13844097788"})[i].."&w=420&h=420"
 thumb.ScaleType=Enum.ScaleType.Crop
 thumb.ZIndex=113
 thumb.Parent=p
 corner(thumb,5)
 label(p,"Name",n,UDim2.fromScale(.03,.70),UDim2.fromScale(.94,.11),Enum.Font.GothamBlack,114)
 textButton(p,"View","VER",UDim2.fromScale(.10,.84),UDim2.fromScale(.80,.12),Color3.fromRGB(62,150,55),Color3.fromRGB(88,230,77),114)
end
local dailyBack=textButton(daily,"Back","Voltar",UDim2.fromScale(.40,.90),UDim2.fromScale(.20,.09),Color3.fromRGB(190,62,69),Color3.fromRGB(225,80,88),114)

-- INVENTORY: top tabs + player viewport + slots, like reference
local inv=Instance.new("Frame")
inv.Name="InventoryPanel"
inv.Size=UDim2.fromScale(1,1)
inv.BackgroundTransparency=1
inv.Visible=false
inv.ZIndex=100
inv.Parent=ui

local tabs=Instance.new("Frame")
tabs.Name="Tabs"
tabs.Position=UDim2.fromScale(.25,.14)
tabs.Size=UDim2.fromScale(.50,.08)
tabs.BackgroundTransparency=1
tabs.ZIndex=101
tabs.Parent=inv
local tabNames={"EQUIPAMENTO","PERSONAGEM","COSMÉTICA","EMOTES","MODIFICAR ITENS"}
for i,n in ipairs(tabNames) do
 local w=.19
 local x=(i-1)*.202
 textButton(tabs,"Tab"..i,n,UDim2.fromScale(x,0),UDim2.fromScale(w,1),Color3.fromRGB(25,25,27),i==1 and Color3.fromRGB(216,180,112) or Color3.fromRGB(95,95,100),102)
end

local viewport=Instance.new("ViewportFrame")
viewport.Name="AvatarViewport"
viewport.AnchorPoint=Vector2.new(.5,.5)
viewport.Position=UDim2.fromScale(.50,.52)
viewport.Size=UDim2.fromScale(.30,.57)
viewport.BackgroundTransparency=1
viewport.Ambient=Color3.fromRGB(255,255,255)
viewport.LightColor=Color3.fromRGB(255,255,255)
viewport.LightDirection=Vector3.new(-1,-1,-1)
viewport.ZIndex=101
viewport.Parent=inv

local function slot(parent,name,pos,txt)
 local s=textButton(parent,name,"＋",pos,UDim2.fromScale(.105,.13),Color3.fromRGB(35,35,38),Color3.fromRGB(105,105,110),102)
 label(s,"SlotLabel",txt,UDim2.fromScale(-.05,.80),UDim2.fromScale(1.10,.28),Enum.Font.GothamBold,103)
 return s
end
slot(inv,"Slot1",UDim2.fromScale(.12,.29),"Espaço de Luz")
slot(inv,"Slot2",UDim2.fromScale(.12,.49),"Slot de Utilidade")
slot(inv,"Slot3",UDim2.fromScale(.12,.69),"Slot de Energia")
slot(inv,"Slot4",UDim2.fromScale(.79,.27),"Slot Utilizável")
slot(inv,"Slot5",UDim2.fromScale(.79,.43),"Slot Utilizável")
slot(inv,"Slot6",UDim2.fromScale(.79,.59),"Slot Utilizável")
slot(inv,"Slot7",UDim2.fromScale(.79,.75),"Slot Utilizável")
local invExit=textButton(inv,"Exit","SAÍDA",UDim2.fromScale(.45,.86),UDim2.fromScale(.10,.07),Color3.fromRGB(190,62,69),Color3.fromRGB(225,80,88),103)

-- generic modal for right-side buttons
local modal=frame(ui,"UtilityModal",UDim2.fromScale(.34,.28),UDim2.fromScale(.32,.36),Color3.fromRGB(12,12,14),.06,200,10)
modal.Visible=false
local modalTitle=label(modal,"Title","",UDim2.fromScale(.08,.08),UDim2.fromScale(.75,.16),Enum.Font.GothamBlack,201)
local modalBody=label(modal,"Body","",UDim2.fromScale(.08,.28),UDim2.fromScale(.84,.50),Enum.Font.Gotham,201)
local modalClose=textButton(modal,"Close","VOLTAR",UDim2.fromScale(.34,.82),UDim2.fromScale(.32,.12),Color3.fromRGB(175,58,65),Color3.fromRGB(220,80,90),202)

-- camera button in round
local camBtn=textButton(ui,"CameraModeButton","3P",UDim2.fromScale(.875,.13),UDim2.fromScale(.07,.055),Color3.fromRGB(25,25,28),Color3.fromRGB(100,120,155),150)
camBtn.Visible=false

-- =========================================================
-- MENU CLIENT
-- =========================================================
local client=Instance.new("LocalScript")
client.Name="NextbotsMenuClient"
client.Source=[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")

local player=Players.LocalPlayer
local gui=script.Parent
local loading=gui:WaitForChild("Background")
local loadText=loading:WaitForChild("LoadingText")
local menu=gui:WaitForChild("MainMenu")
local status=gui:WaitForChild("RoundStatus")
local shopPanel=gui:WaitForChild("ShopPanel")
local daily=gui:WaitForChild("DailyShopPanel")
local inv=gui:WaitForChild("InventoryPanel")
local modal=gui:WaitForChild("UtilityModal")
local camBtn=gui:WaitForChild("CameraModeButton")

local net=RS:WaitForChild("NB_Remotes")
local join=net:WaitForChild("JoinGame")
local roundState=net:WaitForChild("RoundState")
local menuState=net:WaitForChild("MenuState")

local camera=workspace.CurrentCamera
local menuMode=true
local queued=false
local cameraMode="3P"

local function clock(n)
 n=math.max(0,math.floor(tonumber(n) or 0))
 return string.format("%d:%02d",math.floor(n/60),n%60)
end

local function setMenuCamera()
 menuMode=true
 camera.CameraType=Enum.CameraType.Scriptable
 camBtn.Visible=false
end

local function setGameCamera()
 menuMode=false
 local ch=player.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if cameraMode=="1P" then
  player.CameraMode=Enum.CameraMode.LockFirstPerson
  player.CameraMinZoomDistance=.5
  player.CameraMaxZoomDistance=.5
  camBtn.Text="1P"
 else
  player.CameraMode=Enum.CameraMode.Classic
  player.CameraMinZoomDistance=9
  player.CameraMaxZoomDistance=9
  camBtn.Text="3P"
 end
 if hum then camera.CameraSubject=hum end
 camera.CameraType=Enum.CameraType.Custom
 camBtn.Visible=true
end

RunService:BindToRenderStep("NB_MenuCamera",Enum.RenderPriority.Camera.Value+10,function()
 if menuMode then
  local a=workspace:FindFirstChild("MenuCameraAnchor")
  if a then
   camera.CameraType=Enum.CameraType.Scriptable
   camera.CFrame=a.CFrame
  end
 end
end)

RunService:BindToRenderStep("NB_FixedZoom",Enum.RenderPriority.Camera.Value+11,function()
 if not menuMode then
  if cameraMode=="1P" then
   player.CameraMode=Enum.CameraMode.LockFirstPerson
   player.CameraMinZoomDistance=.5
   player.CameraMaxZoomDistance=.5
  else
   player.CameraMode=Enum.CameraMode.Classic
   player.CameraMinZoomDistance=9
   player.CameraMaxZoomDistance=9
  end
 end
end)


local function animate(btn)
 local scale=btn:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",btn)
 btn.MouseEnter:Connect(function()
  TweenService:Create(scale,TweenInfo.new(.10),{Scale=1.035}):Play()
 end)
 btn.MouseLeave:Connect(function()
  TweenService:Create(scale,TweenInfo.new(.10),{Scale=1}):Play()
 end)
 btn.MouseButton1Down:Connect(function()
  TweenService:Create(scale,TweenInfo.new(.05),{Scale=.96}):Play()
 end)
 btn.MouseButton1Up:Connect(function()
  TweenService:Create(scale,TweenInfo.new(.08),{Scale=1.035}):Play()
 end)
end

for _,d in ipairs(gui:GetDescendants()) do
 if d:IsA("TextButton") then animate(d) end
end

local function hidePanels()
 shopPanel.Visible=false
 daily.Visible=false
 inv.Visible=false
 modal.Visible=false
end

local function showMenu()
 queued=false
 hidePanels()
 menu.Visible=true
 status.Visible=true
 setMenuCamera()
end

menu.ShopButton.MouseButton1Click:Connect(function()
 menu.Visible=false
 hidePanels()
 shopPanel.Visible=true
 setMenuCamera()
end)

shopPanel.Exit.MouseButton1Click:Connect(showMenu)
shopPanel.DailyShop.MouseButton1Click:Connect(function()
 shopPanel.Visible=false
 daily.Visible=true
end)
daily.Back.MouseButton1Click:Connect(function()
 daily.Visible=false
 shopPanel.Visible=true
end)

menu.InventoryButton.MouseButton1Click:Connect(function()
 menu.Visible=false
 hidePanels()
 inv.Visible=true
 setMenuCamera()

 local vf=inv:FindFirstChild("AvatarViewport")
 if vf then
  vf:ClearAllChildren()
  local char=player.Character
  if char then
   local world=Instance.new("WorldModel")
   world.Parent=vf
   char.Archivable=true
   local clone=char:Clone()
   for _,d in ipairs(clone:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then d:Destroy() end
   end
   clone:PivotTo(CFrame.new())
   clone.Parent=world
   local cam=Instance.new("Camera")
   cam.CFrame=CFrame.lookAt(Vector3.new(0,2.5,8),Vector3.new(0,2.5,0))
   cam.Parent=vf
   vf.CurrentCamera=cam
  end
 end
end)
inv.Exit.MouseButton1Click:Connect(showMenu)

menu.PlayButton.MouseButton1Click:Connect(function()
 if queued then return end
 queued=true
 hidePanels()
 menu.Visible=false
 status.Visible=true
 status.Text="INTERMISSION\nAGUARDANDO..."
 join:FireServer()
 setGameCamera()
end)

local info={
 BOOMBOX={"CAIXA DE SOM","Sistema de músicas e sons do jogador."},
 SETTINGS={"CONFIGURAÇÕES","Câmera: use o botão 3P/1P durante a rodada."},
 LEADERBOARD={"TABELA DE CLASSIFICAÇÃO","Classificação da partida e vitórias."},
 DAILYMISSIONS={"MISSÕES DIÁRIAS","Complete objetivos para ganhar recompensas."},
 CODES={"CÓDIGOS","Área para códigos promocionais."},
 CREDITS={"CRÉDITOS","NEXTBOTS BRASIL"},
 ROBUX={"ROBUX","Itens especiais e cosméticos."},
 Changelog={"REGISTRO DE MUDANÇAS","Atualizações recentes do NEXTBOTS BRASIL."},
 ModeBrowser={"MODE BROWSER","Modos disponíveis para futuras rodadas."},
 Spectate={"OBSERVAR","Disponível enquanto outros jogadores estiverem na rodada."}
}

for name,data in pairs(info) do
 local btn=menu:FindFirstChild(name,true)
 if btn and btn:IsA("TextButton") then
  btn.MouseButton1Click:Connect(function()
   modal.Title.Text=data[1]
   modal.Body.Text=data[2]
   modal.Visible=true
  end)
 end
end
modal.Close.MouseButton1Click:Connect(function()modal.Visible=false end)

local left=menu:WaitForChild("ReferenceLeftHUD")
local function updateStats()
 local level=player:GetAttribute("NBLevel") or 1
 left.Level.Text="NÍVEL "..level
 left.Stat1.Value.Text=tostring(player:GetAttribute("NBCoins") or 0)
 left.Stat2.Value.Text=tostring(player:GetAttribute("NBTokens") or 0)
 left.Stat3.Value.Text=tostring(player:GetAttribute("NBWins") or 0)
 left.Stat4.Value.Text=tostring(player:GetAttribute("NBRevives") or 0)
end
for _,a in ipairs({"NBLevel","NBCoins","NBTokens","NBWins","NBRevives"}) do
 player:GetAttributeChangedSignal(a):Connect(updateStats)
end
updateStats()

camBtn.MouseButton1Click:Connect(function()
 cameraMode=(cameraMode=="3P") and "1P" or "3P"
 setGameCamera()
end)
UserInputService.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.V and player:GetAttribute("NBState")=="InRound" then
  cameraMode=(cameraMode=="3P") and "1P" or "3P"
  setGameCamera()
 end
end)

menuState.OnClientEvent:Connect(function(mode)
 if mode=="InRound" then
  queued=false
  hidePanels()
  menu.Visible=false
  status.Visible=true
  setGameCamera()
 elseif mode=="Queued" then
  queued=true
  hidePanels()
  menu.Visible=false
  status.Visible=true
  setGameCamera()
 elseif mode=="Show" then
  showMenu()
 end
end)

roundState.OnClientEvent:Connect(function(kind,timeLeft,mapName)
 if kind=="Intermission" then
  status.Text="INTERMISSION\n"..clock(timeLeft)
  if player:GetAttribute("NBState")=="Menu" and not queued and not loading.Visible then
   menu.Visible=true
   setMenuCamera()
  end
 else
  status.Text=tostring(mapName or "ROUND").."\n"..clock(timeLeft)
 end
end)

player:GetAttributeChangedSignal("NBState"):Connect(function()
 local s=player:GetAttribute("NBState")
 if s=="Menu" or s=="Dead" then
  if not loading.Visible then showMenu() end
 elseif s=="Queued" or s=="InRound" then
  menu.Visible=false
  setGameCamera()
 end
end)

-- exact 3-second loading, exact logo + CARREGANDO...
loading.Visible=true
menu.Visible=false
status.Visible=false
hidePanels()
setMenuCamera()

task.spawn(function()
 local dots=0
 while loading.Visible do
  dots=(dots%3)+1
  loadText.Text="CARREGANDO"..string.rep(".",dots)
  task.wait(.35)
 end
end)

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(3)
loading.Visible=false
status.Visible=true
showMenu()
]==]
client.Parent=ui

AS:SavePlaceAsync()

return {
 ok=true,
 version=game.PlaceVersion,
 alwaysDay=Lighting.ClockTime,
 playerBaseSpeed=PLAYER_BASE_SPEED,
 playerMaxSpeed=PLAYER_MAX_SPEED,
 botSpeed=BOT_SPEED,
 fixedZoom=true,
 cameraButtonSafe=true,
 runAsset="12962987574",
 intermissionAvatarOnMap=true,
 botSpawnFolder=true,
 exactLogo=LOGO,
 uiRebuilt=true,
 loadingText="CARREGANDO..."
}
