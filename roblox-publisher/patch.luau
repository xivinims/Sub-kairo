assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"wrong target")

local AS=game:GetService("AssetService")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer").StarterPlayerScripts

-- Keep the custom Evade R6 base, but make sure every player has an avatar
-- even while they are outside the round/map.
Players.CharacterAutoLoads=false

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

local function getLobbyCF()
 local lobby=workspace:FindFirstChild("Lobby")
 local spawn=lobby and lobby:FindFirstChild("LobbySpawn")
 if spawn and spawn:IsA("BasePart") then
  return spawn.CFrame+Vector3.new(0,4,0)
 end

 -- Never use an invented world coordinate. Build a guaranteed-safe
 -- lobby pad relative to the currently loaded map so there is always floor.
 local map=workspace:FindFirstChild("ActiveMap")
 if not map then
  map=workspace:WaitForChild("ActiveMap",10)
 end

 local cf,size
 if map then
  cf,size=map:GetBoundingBox()
 else
  -- Last-resort: use an actual collidable Workspace part, never empty space.
  local best=nil
  for _,d in ipairs(workspace:GetDescendants()) do
   if d:IsA("BasePart") and d.CanCollide and d.Anchored
    and d.Name~="NB_LobbyPlatform" then
    if not best or d.Size.X*d.Size.Z>best.Size.X*best.Size.Z then best=d end
   end
  end
  if best then
   return best.CFrame+Vector3.new(0,best.Size.Y*.5+4,0)
  end
  error("No safe lobby surface exists")
 end

 local pad=workspace:FindFirstChild("NB_LobbyPlatform")
 if not pad then
  pad=Instance.new("Part")
  pad.Name="NB_LobbyPlatform"
  pad.Size=Vector3.new(44,2,44)
  pad.Anchored=true
  pad.CanCollide=true
  pad.CanTouch=true
  pad.CanQuery=true
  pad.Transparency=1
  pad.Parent=workspace
 end

 local half=size*.5
 -- Far enough outside ActiveMap bounds that NBInMap can never become true,
 -- but vertically aligned to the map instead of floating in the void.
 local padPos=cf.Position+cf.RightVector*(half.X+90)
 pad.CFrame=CFrame.new(padPos.X,cf.Position.Y+math.max(4,half.Y*.05),padPos.Z)

 return pad.CFrame+Vector3.new(0,pad.Size.Y*.5+4,0)
end

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
  list=filtered
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

local function createCamera(map)
 local cf,size=map:GetBoundingBox()
 local center=cf.Position
 local radius=math.max(size.X,size.Z)
 local pos=center+Vector3.new(radius*.34,math.max(24,size.Y*.28),radius*.42)

 local anchor=Instance.new("Part")
 anchor.Name="MenuCameraAnchor"
 anchor.Size=Vector3.new(1,1,1)
 anchor.Transparency=1
 anchor.Anchored=true
 anchor.CanCollide=false
 anchor.CanQuery=false
 anchor.CanTouch=false
 anchor.CFrame=CFrame.lookAt(pos,center+Vector3.new(0,math.max(2,size.Y*.08),0))
 anchor.Parent=workspace
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
 createCamera(map)
 return map
end

local function spawnPoints(map)
 local points={}
 local folder=map:FindFirstChild("SpawnPoints")
 if folder then
  for _,d in ipairs(folder:GetChildren()) do
   if d:IsA("BasePart") then table.insert(points,d) end
  end
 end
 if #points>0 then return points end

 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("SpawnLocation")
   or (d:IsA("BasePart") and string.find(string.lower(d.Name),"spawn",1,true)) then
   table.insert(points,d)
  end
 end
 if #points>0 then return points end

 local best=nil
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("BasePart") and d.CanCollide and d.Transparency<.95 then
   if not best or d.Size.X*d.Size.Z>best.Size.X*best.Size.Z then best=d end
  end
 end
 return best and {best} or {}
end

local function groundCF(map,origin)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map}
 params.IgnoreWater=false

 local result=workspace:Raycast(origin,Vector3.new(0,-1000,0),params)
 if result then
  return CFrame.new(result.Position+Vector3.new(0,4,0))
 end
 return nil
end

local function spawnCF(map)
 local points=spawnPoints(map)

 -- Explicit spawn points are only accepted if there is real map geometry below.
 if #points>0 then
  for _=1,math.min(12,#points*2) do
   local p=points[math.random(1,#points)]
   local x=p.Position.X+math.random(-3,3)
   local z=p.Position.Z+math.random(-3,3)
   local cf=groundCF(map,Vector3.new(x,p.Position.Y+80,z))
   if cf then return cf end
  end
 end

 -- No usable SpawnLocation: probe the actual map surface instead of using
 -- the bounding-box center, which may be empty/void.
 local cf,size=map:GetBoundingBox()
 local half=size*.5
 for _=1,28 do
  local lx=(math.random()*2-1)*math.max(2,half.X*.78)
  local lz=(math.random()*2-1)*math.max(2,half.Z*.78)
  local world=(cf*CFrame.new(lx,half.Y+120,lz)).Position
  local hit=groundCF(map,world)
  if hit then return hit end
 end

 -- Guaranteed final fallback: use the top of a real collidable map part.
 local best=nil
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("BasePart") and d.CanCollide and d.Transparency<.98 then
   if not best or d.Size.X*d.Size.Z>best.Size.X*best.Size.Z then best=d end
  end
 end
 assert(best,"ActiveMap has no safe collidable spawn surface")
 return best.CFrame+Vector3.new(0,best.Size.Y*.5+4,0)
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
   desc,
   Enum.HumanoidRigType.R6,
   Enum.AssetTypeVerification.Always
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
 hum.WalkSpeed=26
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

local function ensureLobbyCharacter(plr)
 local ch=plr.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if ch and hum and hum.Health>0 then
  ch:PivotTo(getLobbyCF())
  return ch
 end
 return buildCharacter(plr,getLobbyCF())
end

local function setOutside(plr,reason)
 plr:SetAttribute("NBInMap",false)
 plr:SetAttribute("NBState","Menu")

 local ch=plr.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if ch and hum and hum.Health>0 then
  ch:PivotTo(getLobbyCF())
 else
  ch=buildCharacter(plr,getLobbyCF())
 end

 menuState:FireClient(plr,"Show",reason or "Menu")
end

local function isInsideActiveMap(plr)
 if not currentMapCF or not currentMapSize then return false end
 local ch=plr.Character
 local root=ch and ch:FindFirstChild("HumanoidRootPart")
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 then return false end

 local p=currentMapCF:PointToObjectSpace(root.Position)
 local half=currentMapSize*.5
 local margin=20

 return math.abs(p.X)<=half.X+margin
  and math.abs(p.Z)<=half.Z+margin
  and p.Y>=-60
  and p.Y<=half.Y+100
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
  buildCharacter(plr,getLobbyCF())
  plr:SetAttribute("NBState","Menu")
  plr:SetAttribute("NBInMap",false)
 end)
end

local function enterMap(plr)
 if not plr.Parent then return end
 local map=workspace:FindFirstChild("ActiveMap")
 if not map then return end

 local ch=plr.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if not ch or not hum or hum.Health<=0 then
  ch=buildCharacter(plr,spawnCF(map))
 else
  ch:PivotTo(spawnCF(map))
 end

 plr:SetAttribute("NBState","InRound")
 plr:SetAttribute("NBInMap",true)
 attachDeath(plr,ch)
 menuState:FireClient(plr,"InRound",displayNames[currentMapName] or currentMapName)
end

local function spawnBots(map)
 local src=templates:FindFirstChild("Nextbots")
 if not src then return end

 local folder=Instance.new("Folder")
 folder.Name="ActiveNextbots"
 folder.Parent=workspace

 local cf,size=map:GetBoundingBox()
 local n=0

 for _,bot in ipairs(src:GetChildren()) do
  if bot:IsA("Model") and n<MAX_BOTS then
   n+=1
   local b=bot:Clone()
   b:SetAttribute("NBNextbot",true)
   b.Parent=folder

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

   b:PivotTo(CFrame.new(
    cf.Position.X+math.random(-math.max(20,math.floor(size.X*.30)),math.max(20,math.floor(size.X*.30))),
    cf.Position.Y+math.max(7,size.Y*.15),
    cf.Position.Z+math.random(-math.max(20,math.floor(size.Z*.30)),math.max(20,math.floor(size.Z*.30)))
   ))
  end
 end
end

join.OnServerEvent:Connect(function(plr)
 local state=plr:GetAttribute("NBState")
 if state=="InRound" or state=="Queued" then return end

 plr:SetAttribute("NBState","Queued")
 plr:SetAttribute("NBInMap",false)
 menuState:FireClient(plr,"Queued",currentMapName)

 if roundActive then
  task.spawn(enterMap,plr)
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

 task.defer(function()
  if plr.Parent then buildCharacter(plr,getLobbyCF()) end
 end)
end

Players.PlayerAdded:Connect(initPlayer)
for _,p in ipairs(Players:GetPlayers()) do
 task.spawn(initPlayer,p)
end

-- Physical map membership. This is the only thing that decides whether
-- a Nextbot can see/target the player.
task.spawn(function()
 while true do
  for _,p in ipairs(Players:GetPlayers()) do
   local inside=roundActive and isInsideActiveMap(p)
   p:SetAttribute("NBInMap",inside)
  end
  task.wait(.35)
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

  for _,p in ipairs(Players:GetPlayers()) do
   p:SetAttribute("NBInMap",false)
   if p:GetAttribute("NBState")=="InRound" or p:GetAttribute("NBState")=="Dead" then
    setOutside(p,"RoundEnd")
   else
    ensureLobbyCharacter(p)
   end
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
   if p:GetAttribute("NBState")=="Queued" then task.spawn(enterMap,p) end
  end

  for t=ROUND_TIME,0,-1 do
   if not workspace:FindFirstChild("ActiveMap") then break end
   roundState:FireAllClients("Round",t,pretty)
   task.wait(1)
  end

  roundActive=false
  workspace:SetAttribute("NBRoundActive",false)

  for _,p in ipairs(Players:GetPlayers()) do
   p:SetAttribute("NBInMap",false)
   if p:GetAttribute("NBState")=="InRound" or p:GetAttribute("NBState")=="Dead" then
    setOutside(p,"RoundEnd")
   else
    ensureLobbyCharacter(p)
   end
  end

  task.wait(.5)
 end
end)
]==]

local director=SSS:FindFirstChild("NextbotDirector")
assert(director,"NextbotDirector missing")

director.Source=[==[
local Players=game:GetService("Players")
local PathfindingService=game:GetService("PathfindingService")

local function nearestTarget(pos)
 local best=nil
 local bestDistance=nil

 for _,p in ipairs(Players:GetPlayers()) do
  if p:GetAttribute("NBInMap")==true then
   local ch=p.Character
   local hum=ch and ch:FindFirstChildOfClass("Humanoid")
   local root=ch and ch:FindFirstChild("HumanoidRootPart")

   if hum and root and hum.Health>0 then
    local distance=(root.Position-pos).Magnitude
    if not bestDistance or distance<bestDistance then
     best={player=p,hum=hum,root=root}
     bestDistance=distance
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
      if distance and distance<4.8 then
       if target.player:GetAttribute("NBInMap")==true then
        target.hum.Health=0
       end
      elseif hum then
       hum.WalkSpeed=30

       local ok,path=pcall(function()
        local p=PathfindingService:CreatePath({
         AgentRadius=2,
         AgentHeight=5,
         AgentCanJump=true,
         WaypointSpacing=7
        })
        p:ComputeAsync(root.Position,target.root.Position)
        return p
       end)

       if ok and path and path.Status==Enum.PathStatus.Success then
        local points=path:GetWaypoints()
        local waypoint=points[math.min(2,#points)]
        if waypoint then
         if waypoint.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
         hum:MoveTo(waypoint.Position)
        end
       else
        hum:MoveTo(target.root.Position)
       end
      end
     elseif hum then
      -- Nobody is physically inside ActiveMap: do not chase anybody.
      hum:MoveTo(root.Position)
     end
    end
   end
  end
 end

 task.wait(.45)
end
]==]

-- Client-local filter: if this player is outside ActiveMap,
-- all Nextbots are invisible and silent only for this client.
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

 for _,inst in ipairs(folder:GetDescendants()) do
  apply(inst,inside)
 end
end

local hooked=nil
local descendantConn=nil

local function hook(folder)
 if hooked==folder then
  refresh()
  return
 end

 hooked=folder
 if descendantConn then descendantConn:Disconnect() end

 descendantConn=folder.DescendantAdded:Connect(function(inst)
  task.defer(function()
   apply(inst,player:GetAttribute("NBInMap")==true)
  end)
 end)

 refresh()
end

workspace.ChildAdded:Connect(function(child)
 if child.Name=="ActiveNextbots" then task.defer(hook,child) end
end)

local current=workspace:FindFirstChild("ActiveNextbots")
if current then hook(current) end

player:GetAttributeChangedSignal("NBInMap"):Connect(refresh)
]==]
vis.Parent=SPS

AS:SavePlaceAsync()

return {
 ok=true,
 version=game.PlaceVersion,
 customR6Base=true,
 avatarAlwaysExists=true,
 targetRule="physical ActiveMap bounds",
 outsideCanSeeNextbots=false,
 outsideCanHearNextbots=false,
 outsideCanBeTargeted=false,
 visibilityClient=vis.Name
}
