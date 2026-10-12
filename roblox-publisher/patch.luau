
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
-- EXACT EVADE STARTERCHARACTER + ANIMATIONS
-- Everything here comes from asset 14026023204. No external run animation.
-- =========================================================
local STARTER_ASSET_ID=14026023204

local starterAsset=AS:LoadAssetAsync(STARTER_ASSET_ID)
local starter=starterAsset:FindFirstChild("StarterCharacter")
assert(starter and starter:IsA("Model"),"StarterCharacter missing from 14026023204")
local saves=starter:FindFirstChild("AnimSaves")
assert(saves,"AnimSaves missing from 14026023204")

local oldAnimFolder=RS:FindFirstChild("NB_R6Animations")
if oldAnimFolder then oldAnimFolder:Destroy() end
local animFolder=Instance.new("Folder")
animFolder.Name="NB_R6Animations"
animFolder:SetAttribute("SourceAssetId",tostring(STARTER_ASSET_ID))
animFolder.Parent=RS

local exactClipNames={
 "Forward","FLeft","FRight","idle",
 "back","forward","left","right","jump",
 "Slide","Crouch idle","Crouch forward"
}
for _,name in ipairs(exactClipNames) do
 local seq=saves:FindFirstChild(name)
 assert(seq and seq:IsA("KeyframeSequence"),"Missing clip "..name.." in StarterCharacter asset")
 local clone=seq:Clone()
 clone.Name=name
 clone.Parent=animFolder
end

local oldBase=SS:FindFirstChild("NB_StarterCharacterBase")
if oldBase then oldBase:Destroy() end
local baseCharacterAsset=starter:Clone()
baseCharacterAsset.Name="NB_StarterCharacterBase"
local baseSaves=baseCharacterAsset:FindFirstChild("AnimSaves")
if baseSaves then baseSaves:Destroy() end
for _,d in ipairs(baseCharacterAsset:GetDescendants()) do
 if d:IsA("LuaSourceContainer") then d:Destroy() end
end
local baseHum=baseCharacterAsset:FindFirstChildOfClass("Humanoid")
assert(baseHum and baseHum.RigType==Enum.HumanoidRigType.R6,"StarterCharacter is not R6")
baseHum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
baseCharacterAsset.Parent=SS
starterAsset:Destroy()

-- =========================================================
-- PERSISTENT GROUND-LEVEL SPAWN PREPROCESSOR
-- Build spawn points in ServerStorage once, then every round clones them.
-- We deliberately choose the lowest coherent playable floor band and reject
-- authored spawns that sit many studs above that band (roofs / upper decks).
-- =========================================================
local spawnAudit={}

local function mapInsideXZ(cf,size,pos,ratio)
 local lp=cf:PointToObjectSpace(pos)
 return math.abs(lp.X)<=size.X*ratio and math.abs(lp.Z)<=size.Z*ratio
end

local function newSpawn(folder,name,pos)
 local p=Instance.new("Part")
 p.Name=name
 p.Size=Vector3.new(3,.5,3)
 p.Anchored=true
 p.CanCollide=false
 p.CanTouch=false
 p.CanQuery=false
 p.Transparency=1
 p.CFrame=CFrame.new(pos)
 p.Parent=folder
 return p
end

local function topOf(part)
 return part.CFrame:PointToWorldSpace(Vector3.new(0,part.Size.Y*.5,0))
end

local function preprocessMapSpawns(map)
 local oldPlayers=map:FindFirstChild("NBPlayerSpawnPoints")
 if oldPlayers then oldPlayers:Destroy() end
 local oldBots=map:FindFirstChild("NextbotSpawnPoints")
 if oldBots then oldBots:Destroy() end

 local playerFolder=Instance.new("Folder")
 playerFolder.Name="NBPlayerSpawnPoints"
 playerFolder.Parent=map

 local botFolder=Instance.new("Folder")
 botFolder.Name="NextbotSpawnPoints"
 botFolder.Parent=map

 local cf,size=map:GetBoundingBox()
 local usedPlayers={}
 local floorBand=nil
 local source="floor-band"

 local function addPlayer(pos)
  if not mapInsideXZ(cf,size,pos,.46) then return false end
  for _,u in ipairs(usedPlayers) do
   local a=Vector3.new(u.X,0,u.Z)
   local b=Vector3.new(pos.X,0,pos.Z)
   if (a-b).Magnitude<7 then return false end
  end
  table.insert(usedPlayers,pos)
  newSpawn(playerFolder,"PlayerSpawn",pos+Vector3.new(0,3.4,0))
  return true
 end

 -- 1. Authored SpawnLocations: use ONLY their lowest vertical cluster.
 local authored={}
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("SpawnLocation") and mapInsideXZ(cf,size,d.Position,.48) then
   local lp=cf:PointToObjectSpace(d.Position)
   table.insert(authored,{part=d,localY=lp.Y})
  end
 end

 if #authored>0 then
  table.sort(authored,function(a,b)return a.localY<b.localY end)
  local lowest=authored[1].localY
  floorBand=lowest
  source="authored-low-band"

  for _,s in ipairs(authored) do
   -- The Map1_Evade inspection showed upper SpawnLocations +10 to +22 studs.
   -- Only keep the real ground cluster.
   if s.localY<=lowest+3.0 then
    local p=s.part
    local top=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y*.5,0))
    addPlayer(top)
   end
  end
 end

 -- 2. Find horizontal collidable floor surfaces.
 -- Include small floor tiles too: Rocket Arena uses a dense 4x4 tile grid.
 local surfaces={}
 for _,d in ipairs(map:GetDescendants()) do
  if d:IsA("BasePart")
   and not d:IsA("SpawnLocation")
   and d.CanCollide
   and d.Transparency<.98
   and d.CFrame.UpVector.Y>.84
   and d.Size.X*d.Size.Z>=12
   and mapInsideXZ(cf,size,d.Position,.48) then

   local top=topOf(d)
   local lp=cf:PointToObjectSpace(top)
   table.insert(surfaces,{
    part=d,
    top=top,
    localY=lp.Y,
    area=d.Size.X*d.Size.Z
   })
  end
 end

 table.sort(surfaces,function(a,b)
  if math.abs(a.localY-b.localY)>.1 then return a.localY<b.localY end
  return a.area>b.area
 end)

 if not floorBand then
  assert(#surfaces>0,"No horizontal floor surfaces in "..map.Name)

  -- Group surfaces into 0.5-stud vertical bands. A real floor is usually
  -- either one huge slab or many tiles at the exact same elevation.
  -- Cap per-part weight so one giant roof cannot beat a dense ground grid.
  local bands={}
  local maxScore=0

  for _,s in ipairs(surfaces) do
   local key=math.floor(s.localY*2+.5)/2
   local b=bands[key]
   if not b then
    b={y=key,score=0,count=0}
    bands[key]=b
   end
   b.count+=1
   b.score+=math.min(s.area,400)
   maxScore=math.max(maxScore,b.score)
  end

  local candidates={}
  for _,b in pairs(bands) do
   -- Keep meaningful structural bands, then choose the LOWEST one.
   if b.score>=math.max(120,maxScore*.20) or b.count>=8 then
    table.insert(candidates,b)
   end
  end
  table.sort(candidates,function(a,b)return a.y<b.y end)

  assert(#candidates>0,"No coherent floor band in "..map.Name)
  floorBand=candidates[1].y
 end

 -- If authored spawns did not provide enough points, sample only surfaces
 -- on the SAME low floor band.
 local patterns={
  Vector2.new(0,0),
  Vector2.new(-.24,-.24),Vector2.new(.24,-.24),
  Vector2.new(-.24,.24),Vector2.new(.24,.24),
  Vector2.new(-.28,0),Vector2.new(.28,0),
  Vector2.new(0,-.28),Vector2.new(0,.28)
 }

 if #playerFolder:GetChildren()<6 then
  for _,s in ipairs(surfaces) do
   if #playerFolder:GetChildren()>=12 then break end
   if math.abs(s.localY-floorBand)<=1.75 then
    local part=s.part
    for _,v in ipairs(patterns) do
     if #playerFolder:GetChildren()>=12 then break end
     local pos=part.CFrame:PointToWorldSpace(Vector3.new(
      part.Size.X*v.X,
      part.Size.Y*.5+.05,
      part.Size.Z*v.Y
     ))
     addPlayer(pos)
    end
   end
  end
 end

 assert(#playerFolder:GetChildren()>0,"No ground-level player spawns for "..map.Name)

 -- 3. Bot points use the SAME floor band, but choose the positions farthest
 -- from player spawns. Thus bots are inside the map and never on roofs.
 local centroid=Vector3.zero
 for _,p in ipairs(playerFolder:GetChildren()) do centroid+=p.Position end
 centroid/=math.max(1,#playerFolder:GetChildren())

 local botCandidates={}
 local botPatterns={
  Vector2.new(-.40,-.40),Vector2.new(0,-.42),Vector2.new(.40,-.40),
  Vector2.new(-.42,0),Vector2.new(.42,0),
  Vector2.new(-.40,.40),Vector2.new(0,.42),Vector2.new(.40,.40),
  Vector2.new(-.30,-.30),Vector2.new(.30,-.30),
  Vector2.new(-.30,.30),Vector2.new(.30,.30)
 }

 for _,s in ipairs(surfaces) do
  if math.abs(s.localY-floorBand)<=1.75 then
   local part=s.part
   for _,v in ipairs(botPatterns) do
    local pos=part.CFrame:PointToWorldSpace(Vector3.new(
     part.Size.X*v.X,
     part.Size.Y*.5+.05,
     part.Size.Z*v.Y
    ))
    if mapInsideXZ(cf,size,pos,.46) then
     local minPlayer=math.huge
     for _,pp in ipairs(playerFolder:GetChildren()) do
      local a=Vector3.new(pos.X,0,pos.Z)
      local b=Vector3.new(pp.Position.X,0,pp.Position.Z)
      minPlayer=math.min(minPlayer,(a-b).Magnitude)
     end
     table.insert(botCandidates,{pos=pos,minPlayer=minPlayer})
    end
   end
  end
 end

 table.sort(botCandidates,function(a,b)return a.minPlayer>b.minPlayer end)
 local botUsed={}
 for _,c in ipairs(botCandidates) do
  if #botFolder:GetChildren()>=8 then break end
  local separate=true
  for _,u in ipairs(botUsed) do
   if (Vector3.new(u.X,0,u.Z)-Vector3.new(c.pos.X,0,c.pos.Z)).Magnitude<14 then
    separate=false
    break
   end
  end
  if separate and c.minPlayer>=18 then
   table.insert(botUsed,c.pos)
   newSpawn(botFolder,"NextbotSpawn",c.pos+Vector3.new(0,3.0,0))
  end
 end

 if #botFolder:GetChildren()==0 and #botCandidates>0 then
  newSpawn(botFolder,"NextbotSpawn",botCandidates[1].pos+Vector3.new(0,3.0,0))
 end
 assert(#botFolder:GetChildren()>0,"No ground-level bot spawns for "..map.Name)

 playerFolder:SetAttribute("Validated",true)
 playerFolder:SetAttribute("FloorBandLocalY",floorBand)
 playerFolder:SetAttribute("Source",source)
 botFolder:SetAttribute("Validated",true)
 botFolder:SetAttribute("FloorBandLocalY",floorBand)

 local minPlayerY=math.huge
 local maxPlayerY=-math.huge
 for _,p in ipairs(playerFolder:GetChildren()) do
  local ly=cf:PointToObjectSpace(p.Position).Y
  minPlayerY=math.min(minPlayerY,ly)
  maxPlayerY=math.max(maxPlayerY,ly)
 end

 spawnAudit[map.Name]={
  playerCount=#playerFolder:GetChildren(),
  botCount=#botFolder:GetChildren(),
  floorBand=floorBand,
  playerMinLocalY=minPlayerY,
  playerMaxLocalY=maxPlayerY,
  source=source
 }
end

local mapsFolder=SS:WaitForChild("NB_Maps")
for _,map in ipairs(mapsFolder:GetChildren()) do
 if map:IsA("Model") then preprocessMapSpawns(map) end
end


-- In-game MENU button remote. Returning to menu never destroys the avatar.
local nbRemotes=RS:FindFirstChild("NB_Remotes")
assert(nbRemotes,"NB_Remotes missing")
local returnToMenuRemote=nbRemotes:FindFirstChild("ReturnToMenu")
if not returnToMenuRemote then
 returnToMenuRemote=Instance.new("RemoteEvent")
 returnToMenuRemote.Name="ReturnToMenu"
 returnToMenuRemote.Parent=nbRemotes
end

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
local net=RS:WaitForChild("NB_Remotes",15)
local join=net and net:FindFirstChild("JoinGame")
local roundState=net and net:FindFirstChild("RoundState")
local menuState=net and net:FindFirstChild("MenuState")
local returnToMenu=net and net:FindFirstChild("ReturnToMenu")

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

local rng=Random.new()

local function chooseMap()
 local list=availableMaps()
 assert(#list>0,"No maps available")
 local picked=list[rng:NextInteger(1,#list)]
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
 return workspace:Raycast(world,Vector3.new(0,-40,0),p)
end

local function clearAbove(map,groundPos,boxSize)
 local params=OverlapParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map}
 params.MaxParts=32

 local center=groundPos+Vector3.new(0,(boxSize.Y*.5)+.35,0)
 local hits=workspace:GetPartBoundsInBox(CFrame.new(center),boxSize,params)
 for _,part in ipairs(hits) do
  if part:IsA("BasePart")
   and part.CanCollide
   and part.Transparency<.98
   and part.Name~="PlayerSpawn"
   and part.Name~="NextbotSpawn" then
   return false
  end
 end
 return true
end

local function createPlayerSpawns(map)
 local folder=map:FindFirstChild("NBPlayerSpawnPoints")
 assert(
  folder and #folder:GetChildren()>0 and folder:GetAttribute("Validated")==true,
  "Persistent player spawns missing in "..map.Name
 )
 return folder
end

local function validatedPointCF(map,p)
 local hit=rayGround(map,p.Position+Vector3.new(0,6,0))
 if not hit or hit.Normal.Y<.55 then return nil end

 local vertical=p.Position.Y-hit.Position.Y
 if vertical<1.5 or vertical>10 then return nil end
 if not clearAbove(map,hit.Position,Vector3.new(3.8,5.8,3.8)) then return nil end

 return CFrame.new(hit.Position+Vector3.new(0,3.4,0))
end

local function safePlayerCF(map)
 local folder=createPlayerSpawns(map)
 local points=folder:GetChildren()
 assert(#points>0,"No persistent player spawns")

 -- Random start so players spread out, but only return a point that still
 -- has real floor immediately below and enough head/body clearance.
 local start=math.random(1,#points)
 for offset=0,#points-1 do
  local p=points[((start+offset-1)%#points)+1]
  local cf=validatedPointCF(map,p)
  if cf then return cf end
 end

 error("All persistent player spawns failed runtime floor validation")
end

local function lineClear(map,a,b)
 local delta=b-a
 if delta.Magnitude<2 then return false end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map}
 params.IgnoreWater=true
 local hit=workspace:Raycast(a,delta,params)
 if not hit then return true end
 return (hit.Position-a).Magnitude>=delta.Magnitude-1.5
end

local function cameraSpaceClear(map,pos)
 local params=OverlapParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map}
 params.MaxParts=16
 local hits=workspace:GetPartBoundsInBox(CFrame.new(pos),Vector3.new(2.4,3.2,2.4),params)
 for _,p in ipairs(hits) do
  if p:IsA("BasePart")
   and p.CanCollide
   and p.Transparency<.98
   and p.Name~="PlayerSpawn"
   and p.Name~="NextbotSpawn" then
   return false
  end
 end
 return true
end

local function createMenuCamera(map)
 local old=workspace:FindFirstChild("MenuCameraAnchor")
 if old then old:Destroy() end

 local cf,size=map:GetBoundingBox()
 local folder=createPlayerSpawns(map)
 local points=folder:GetChildren()
 local valid={}

 for _,p in ipairs(points) do
  local groundCF=validatedPointCF(map,p)
  if groundCF then table.insert(valid,groundCF.Position) end
 end
 local bestCF=nil
 if #valid==0 then
  -- Emergency fallback from persistent spawn parts without runtime ray validation.
  for _,p in ipairs(points) do
   if p:IsA("BasePart") then table.insert(valid,p.Position) end
  end
 end

 if #valid==0 then
  local cf,size=map:GetBoundingBox()
  table.insert(valid,cf.Position+Vector3.new(0,math.max(4,size.Y*.05),0))
 end
 local bestScore=-math.huge

 for i,a in ipairs(valid) do
  local camPos=a+Vector3.new(0,3.0,0)
  if cameraSpaceClear(map,camPos) then
   for j,b in ipairs(valid) do
    if i~=j then
     local target=b+Vector3.new(0,2.0,0)
     local dist=(target-camPos).Magnitude
     if dist>=10 and dist<=75 and lineClear(map,camPos,target) then
      if dist>bestScore then
       bestScore=dist
       bestCF=CFrame.lookAt(camPos,target)
      end
     end
    end
   end
  end
 end

 if not bestCF then
  local pos=valid[1]+Vector3.new(0,3.0,0)
  local target=pos+cf.LookVector*18+Vector3.new(0,-.5,0)
  bestCF=CFrame.lookAt(pos,target)
 end

 local lp=cf:PointToObjectSpace(bestCF.Position)
 if math.abs(lp.X)>size.X*.48 or math.abs(lp.Z)>size.Z*.48 then
  local pos=valid[1]+Vector3.new(0,3.0,0)
  local flatTarget=Vector3.new(cf.Position.X,pos.Y-1,cf.Position.Z)
  if (flatTarget-pos).Magnitude<8 then
   flatTarget=pos+cf.LookVector*18+Vector3.new(0,-1,0)
  end
  bestCF=CFrame.lookAt(pos,flatTarget)
 end

 -- Never allow a sky-facing menu camera.
 local look=bestCF.LookVector
 if look.Y>.02 then
  local pos=bestCF.Position
  local flat=Vector3.new(look.X,-.10,look.Z)
  if flat.Magnitude<.1 then flat=cf.LookVector+Vector3.new(0,-.10,0) end
  bestCF=CFrame.lookAt(pos,pos+flat.Unit*20)
 end

 local anchor=Instance.new("Part")
 anchor.Name="MenuCameraAnchor"
 anchor.Size=Vector3.new(1,1,1)
 anchor.Transparency=1
 anchor.Anchored=true
 anchor.CanCollide=false
 anchor.CanTouch=false
 anchor.CanQuery=false
 anchor.CFrame=bestCF
 anchor:SetAttribute("InsideActiveMap",true)
 anchor.Parent=workspace
end

local function createBotSpawns(map)
 local folder=map:FindFirstChild("NextbotSpawnPoints")
 assert(
  folder and #folder:GetChildren()>0 and folder:GetAttribute("Validated")==true,
  "Persistent bot spawns missing in "..map.Name
 )
 return folder
end

local function setBotSpawnMarkers(map,visible)
 local folder=map and map:FindFirstChild("NextbotSpawnPoints")
 if not folder then return end

 for _,p in ipairs(folder:GetChildren()) do
  if p:IsA("BasePart") then
   local billboard=p:FindFirstChild("NBSpawnMarker")
   if not billboard then
    billboard=Instance.new("BillboardGui")
    billboard.Name="NBSpawnMarker"
    billboard.Size=UDim2.fromOffset(52,62)
    billboard.StudsOffset=Vector3.new(0,4.2,0)
    billboard.AlwaysOnTop=true
    billboard.MaxDistance=260
    billboard.LightInfluence=0
    billboard.Parent=p

    local icon=Instance.new("TextLabel")
    icon.Name="Skull"
    icon.Size=UDim2.fromScale(1,.75)
    icon.BackgroundTransparency=1
    icon.Text="💀"
    icon.TextScaled=true
    icon.TextColor3=Color3.fromRGB(255,255,255)
    icon.TextStrokeColor3=Color3.fromRGB(0,0,0)
    icon.TextStrokeTransparency=.05
    icon.Font=Enum.Font.GothamBlack
    icon.Parent=billboard

    local tag=Instance.new("TextLabel")
    tag.Name="Tag"
    tag.Position=UDim2.fromScale(-.25,.73)
    tag.Size=UDim2.fromScale(1.5,.23)
    tag.BackgroundTransparency=1
    tag.Text="NEXTBOT"
    tag.TextScaled=true
    tag.TextColor3=Color3.fromRGB(240,75,75)
    tag.TextStrokeColor3=Color3.fromRGB(0,0,0)
    tag.TextStrokeTransparency=.05
    tag.Font=Enum.Font.GothamBlack
    tag.Parent=billboard
   end
   billboard.Enabled=visible
  end
 end
end

local function loadMap(name)
 local existing=workspace:FindFirstChild("ActiveMap")

 if existing and currentMapName==name then
  local bots=workspace:FindFirstChild("ActiveNextbots")
  if bots then bots:Destroy() end

  currentMapCF,currentMapSize=existing:GetBoundingBox()

  if not workspace:FindFirstChild("MenuCameraAnchor") then
   pcall(function()createMenuCamera(existing)end)
  end

  setBotSpawnMarkers(existing,true)
  return existing,false
 end

 cleanupWorld()

 local source=maps:FindFirstChild(name)
 if not source then
  for _,candidate in ipairs(maps:GetChildren()) do
   if candidate:IsA("Model") then source=candidate break end
  end
 end
 if not source then
  warn("NEXTBOTS BRASIL: no maps available")
  return nil,false
 end

 local map=source:Clone()
 map.Name="ActiveMap"
 map.Parent=workspace
 currentMapName=source.Name
 currentMapCF,currentMapSize=map:GetBoundingBox()

 pcall(function()createPlayerSpawns(map)end)
 pcall(function()createBotSpawns(map)end)
 local camOK=pcall(function()createMenuCamera(map)end)

 if not camOK or not workspace:FindFirstChild("MenuCameraAnchor") then
  local cf,size=map:GetBoundingBox()
  local base=cf.Position
  local pf=map:FindFirstChild("NBPlayerSpawnPoints")
  local first=pf and pf:FindFirstChildWhichIsA("BasePart")
  if first then base=first.Position end

  local anchor=Instance.new("Part")
  anchor.Name="MenuCameraAnchor"
  anchor.Size=Vector3.new(1,1,1)
  anchor.Transparency=1
  anchor.Anchored=true
  anchor.CanCollide=false
  anchor.CanTouch=false
  anchor.CanQuery=false
  local pos=base+Vector3.new(0,3.8,9)
  anchor.CFrame=CFrame.lookAt(pos,base+Vector3.new(0,1.8,0))
  anchor.Parent=workspace
 end

 setBotSpawnMarkers(map,true)
 return map,true
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
 hum.PlatformStand=false
 hum.Sit=false

 for _,d in ipairs(char:GetDescendants()) do
  if d:IsA("LuaSourceContainer") then
   d:Destroy()
  elseif d:IsA("BasePart") then
   d.Anchored=false
  end
 end
 root.Anchored=false
 root.CanCollide=false

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

 -- Do NOT teleport again if the player is already standing safely in the
 -- selected map from intermission. JOIN only changes participation state.
 local ch=plr.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if not ch or not hum or hum.Health<=0 or not isPhysicallyInsideMap(plr) then
  ch=ensureOnMap(plr,map)
 end

 plr:SetAttribute("NBState","InRound")
 plr:SetAttribute("NBInMap",roundActive and isPhysicallyInsideMap(plr) or false)
 attachDeath(plr,ch)
 menuState:FireClient(plr,"InRound",displayNames[currentMapName] or currentMapName)
end

local function spawnBots(map)
 setBotSpawnMarkers(map,false)

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
    if d:IsA("LuaSourceContainer") then
     d.Disabled=true
    elseif d:IsA("BasePart") then
     -- Several toolbox Nextbots arrive anchored. That was why some of them
     -- could "target" a player but never physically chase them.
     d.Anchored=false
     d.CanCollide=false
     d.CanTouch=true
     d.CanQuery=true
     pcall(function()d:SetNetworkOwner(nil)end)

     d.Touched:Connect(function(hit)
      local char=hit and hit:FindFirstAncestorOfClass("Model")
      local plr=char and Players:GetPlayerFromCharacter(char)
      if not plr then return end
      if plr:GetAttribute("NBState")~="InRound"
       or plr:GetAttribute("NBInMap")~=true then
       return
      end

      local targetHum=char:FindFirstChildOfClass("Humanoid")
      if targetHum and targetHum.Health>0 then
       targetHum.Health=0
      end
     end)
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

if returnToMenu then
 returnToMenu.OnServerEvent:Connect(function(plr)
  local state=plr:GetAttribute("NBState")
  if state~="InRound" and state~="Queued" then return end

  -- Same avatar, same map, just leave the targetable round state.
  plr:SetAttribute("NBInMap",false)
  plr:SetAttribute("NBState","Menu")
  menuState:FireClient(plr,"Show","PlayerMenu")
 end)
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
  local map=workspace:FindFirstChild("ActiveMap")

  for _,p in ipairs(Players:GetPlayers()) do
   local ch=p.Character
   local root=ch and ch:FindFirstChild("HumanoidRootPart")
   local hum=ch and ch:FindFirstChildOfClass("Humanoid")

   -- Last-resort safety: if physics ever throws a live character into void
   -- or far outside this map, put the SAME avatar back on a validated spawn.
   if map and currentMapCF and currentMapSize and root and hum and hum.Health>0 then
    local lp=currentMapCF:PointToObjectSpace(root.Position)
    local tooLow=lp.Y<-(currentMapSize.Y*.5+45)
    local tooFar=math.abs(lp.X)>currentMapSize.X*.62 or math.abs(lp.Z)>currentMapSize.Z*.62
    if tooLow or tooFar then
     ch:PivotTo(safePlayerCF(map))
     root.AssemblyLinearVelocity=Vector3.zero
     root.AssemblyAngularVelocity=Vector3.zero
    end
   end

   local targetable=roundActive
    and p:GetAttribute("NBState")=="InRound"
    and isPhysicallyInsideMap(p)
   p:SetAttribute("NBInMap",targetable)
  end

  task.wait(.20)
 end
end)

workspace:SetAttribute("NBRoundActive",false)
workspace:SetAttribute("NBIntermission",INTERMISSION)

task.spawn(function()
 while true do
  local ok,err=pcall(function()
     roundActive=false
     workspace:SetAttribute("NBRoundActive",false)
   
     local picked=chooseMap()
     local map,mapChanged=loadMap(picked)
     if not map then error("Could not prepare ActiveMap") end
     local pretty=displayNames[currentMapName] or currentMapName
   
     -- Everyone is already physically on the selected map for intermission.
     for _,p in ipairs(Players:GetPlayers()) do
      p:SetAttribute("NBInMap",false)
      p:SetAttribute("NBState","Menu")

      if mapChanged or not isPhysicallyInsideMap(p) then
       ensureOnMap(p,map)
      end

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

     local survivors={}
     for _,p in ipairs(Players:GetPlayers()) do
      local ch=p.Character
      local hum=ch and ch:FindFirstChildOfClass("Humanoid")
      if p:GetAttribute("NBState")=="InRound" and hum and hum.Health>0 then
       table.insert(survivors,p.DisplayName)
      end
     end
     roundState:FireAllClients("Results",survivors,ROUND_TIME,pretty)

     local bots=workspace:FindFirstChild("ActiveNextbots")
     if bots then bots:Destroy() end
     setBotSpawnMarkers(map,true)
   
     for _,p in ipairs(Players:GetPlayers()) do
      p:SetAttribute("NBInMap",false)
      p:SetAttribute("NBState","Menu")
      menuState:FireClient(p,"Show","RoundEnd")
     end
     task.wait(.5)
  end)

  if not ok then
   warn("NEXTBOTS BRASIL round loop recovered:",err)
   roundActive=false
   workspace:SetAttribute("NBRoundActive",false)
   task.wait(1)
  end
 end
end)
]==]

-- =========================================================
-- NEXTBOT DIRECTOR
-- Common bot speed stays just below the player maximum.
-- =========================================================
local director=SSS:FindFirstChild("NextbotDirector")
assert(director,"NextbotDirector missing")
director.Source=[==[
local Players=game:GetService("Players")
local PathfindingService=game:GetService("PathfindingService")

local BOT_SPEED=48.5
local PATH_REFRESH=.55
local THINK_RATE=.10
local HIT_DISTANCE=5.2

local memory=setmetatable({},{__mode="k"})

local function validTarget(p)
 if p:GetAttribute("NBState")~="InRound" or p:GetAttribute("NBInMap")~=true then
  return nil
 end

 local ch=p.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 local root=ch and ch:FindFirstChild("HumanoidRootPart")
 if not hum or not root or hum.Health<=0 then return nil end

 return {player=p,char=ch,hum=hum,root=root}
end

local function nearestTarget(pos)
 local best=nil
 local bestDistance=math.huge

 for _,p in ipairs(Players:GetPlayers()) do
  local t=validTarget(p)
  if t then
   local d=(t.root.Position-pos).Magnitude
   if d<bestDistance then
    best=t
    bestDistance=d
   end
  end
 end

 return best,bestDistance
end

local function botRoot(bot)
 return bot:FindFirstChild("HumanoidRootPart")
  or bot.PrimaryPart
  or bot:FindFirstChildWhichIsA("BasePart",true)
end

local function hasLineOfSight(bot,root,target)
 local delta=target.root.Position-root.Position
 if delta.Magnitude<1 then return true end

 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={bot,target.char,workspace:FindFirstChild("ActiveNextbots")}
 params.IgnoreWater=true

 return workspace:Raycast(root.Position,delta,params)==nil
end

local function predictedTarget(root)
 local v=root.AssemblyLinearVelocity
 return root.Position+Vector3.new(v.X,0,v.Z)*.12
end

local function modelContactDistance(bot,targetPos)
 local cf,size=bot:GetBoundingBox()
 local lp=cf:PointToObjectSpace(targetPos)
 local hx,hy,hz=size.X*.5,size.Y*.5,size.Z*.5
 local dx=math.max(math.abs(lp.X)-hx,0)
 local dy=math.max(math.abs(lp.Y)-hy,0)
 local dz=math.max(math.abs(lp.Z)-hz,0)
 return Vector3.new(dx,dy,dz).Magnitude
end

while true do
 local folder=workspace:FindFirstChild("ActiveNextbots")

 if workspace:GetAttribute("NBRoundActive") and folder then
  local now=os.clock()

  for _,bot in ipairs(folder:GetChildren()) do
   if bot:IsA("Model") then
    local root=botRoot(bot)
    local hum=bot:FindFirstChildOfClass("Humanoid")

    if root then
     root.Anchored=false
     pcall(function()root:SetNetworkOwner(nil)end)

     local target,distance=nearestTarget(root.Position)
     local mem=memory[bot]
     if not mem then
      mem={lastPath=0,lastMoveCheck=now,lastPos=root.Position}
      memory[bot]=mem
     end

     if target then
      -- Use model bounds, not only root-to-root distance. Large flat Nextbots
      -- now kill correctly when the player stands on/touches the image/model.
      local contactDistance=modelContactDistance(bot,target.root.Position)
      if contactDistance<=HIT_DISTANCE then
       local still=validTarget(target.player)
       if still then still.hum.Health=0 end
      elseif hum then
       hum.WalkSpeed=BOT_SPEED
       hum.AutoRotate=true

       if hasLineOfSight(bot,root,target) then
        hum:MoveTo(predictedTarget(target.root))
       elseif now-mem.lastPath>=PATH_REFRESH then
        mem.lastPath=now

        local ok,path=pcall(function()
         local p=PathfindingService:CreatePath({
          AgentRadius=2,
          AgentHeight=5,
          AgentCanJump=true,
          AgentCanClimb=true,
          WaypointSpacing=5
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
         hum:MoveTo(predictedTarget(target.root))
        end
       end

       if now-mem.lastMoveCheck>=1 then
        local moved=(root.Position-mem.lastPos).Magnitude
        if moved<.8 and distance>8 then
         hum.Jump=true
         hum:MoveTo(predictedTarget(target.root))
        end
        mem.lastPos=root.Position
        mem.lastMoveCheck=now
       end
      else
       -- Image/Part-only Nextbots have no Humanoid. Move the whole model at a
       -- fixed server-authoritative speed instead of leaving them frozen.
       local destination=predictedTarget(target.root)
       local delta=destination-root.Position
       if delta.Magnitude>.05 then
        local step=math.min(delta.Magnitude,BOT_SPEED*THINK_RATE)
        local nextPos=root.Position+delta.Unit*step
        local facing=CFrame.lookAt(nextPos,Vector3.new(destination.X,nextPos.Y,destination.Z))
        local currentPivot=bot:GetPivot()
        local rotation=currentPivot-currentPivot.Position
        if math.abs(delta.X)+math.abs(delta.Z)>.05 then
         rotation=facing-facing.Position
        end
        bot:PivotTo(CFrame.new(nextPos)*rotation)
       end
      end
     elseif hum then
      hum:MoveTo(root.Position)
     end
    end
   end
  end
 end

 task.wait(THINK_RATE)
end
]==]

-- =========================================================
-- EVADE-STYLE PLAYER ACCELERATION
-- =========================================================
local oldMove=SPS:FindFirstChild("NB_EvadeMovement")
if oldMove then oldMove:Destroy() end
local oldMotion=SPS:FindFirstChild("NB_R6MotionController")
if oldMotion then oldMotion:Destroy() end
local oldUnified=SPS:FindFirstChild("NB_EvadeCharacterController")
if oldUnified then oldUnified:Destroy() end

-- ONE controller owns WalkSpeed, FOV and every Motor6D.Transform.
-- It writes on PreSimulation, after Roblox animation evaluation, so no
-- Animate/Animator track can overwrite the Evade keyframes on the same frame.
local controller=Instance.new("LocalScript")
controller.Name="NB_EvadeCharacterController"
controller.Source=[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local clips=RS:WaitForChild("NB_R6Animations")
assert(clips:GetAttribute("SourceAssetId")=="14026023204","Wrong Evade animation source")

local BASE_SPEED=10
local MAX_SPEED=50
local ACCEL_TIME=10
local RUN_THRESHOLD=20

local frameConn=nil
local animPlayedConn=nil
local movingTime=0

local function flatten(p,map)
 if p:IsA("Pose") then
  map[p.Name]={
   cf=p.CFrame,
   style=p.EasingStyle,
   direction=p.EasingDirection
  }
 end
 for _,c in ipairs(p:GetChildren()) do
  if c:IsA("Pose") then flatten(c,map) end
 end
end

local function bake(name)
 local seq=clips:WaitForChild(name)
 local frames={}
 for _,kf in ipairs(seq:GetKeyframes()) do
  local poses={}
  for _,p in ipairs(kf:GetChildren()) do
   if p:IsA("Pose") then flatten(p,poses) end
  end
  table.insert(frames,{time=kf.Time,poses=poses})
 end
 table.sort(frames,function(a,b)return a.time<b.time end)
 assert(#frames>0,"Empty Evade clip "..name)
 return {
  frames=frames,
  duration=math.max(.05,frames[#frames].time),
  looped=seq.Loop
 }
end

-- All animation data comes directly from asset 14026023204.
local CLIPS={
 Idle=bake("idle"),
 Jump=bake("jump"),
 WalkForward=bake("forward"),
 WalkBack=bake("back"),
 WalkLeft=bake("left"),
 WalkRight=bake("right"),
 RunForward=bake("Forward"),
 RunLeft=bake("FLeft"),
 RunRight=bake("FRight")
}

local function ease(raw,aPose,bPose)
 local pose=bPose or aPose
 if not pose then return raw end
 local ok,value=pcall(
  TweenService.GetValue,
  TweenService,
  raw,
  pose.style or Enum.EasingStyle.Linear,
  pose.direction or Enum.EasingDirection.InOut
 )
 return ok and value or raw
end

local function sample(clip,t)
 local time=clip.looped and (t%clip.duration) or math.min(t,clip.duration)
 local a,b=clip.frames[1],clip.frames[#clip.frames]

 for i=1,#clip.frames-1 do
  local f1,f2=clip.frames[i],clip.frames[i+1]
  if time>=f1.time and time<=f2.time then
   a,b=f1,f2
   break
  end
 end

 local raw=math.clamp((time-a.time)/math.max(.0001,b.time-a.time),0,1)
 local out={}
 for key,av in pairs(a.poses) do
  local bv=b.poses[key] or av
  out[key]=av.cf:Lerp(bv.cf,ease(raw,av,bv))
 end
 for key,bv in pairs(b.poses) do
  if out[key]==nil then out[key]=bv.cf end
 end
 return out
end

local function setup(char)
 if frameConn then frameConn:Disconnect();frameConn=nil end
 if animPlayedConn then animPlayedConn:Disconnect();animPlayedConn=nil end

 local hum=char:WaitForChild("Humanoid",8)
 local root=char:WaitForChild("HumanoidRootPart",8)
 if not hum or not root or hum.RigType~=Enum.HumanoidRigType.R6 then return end

 -- Remove all default animation writers from this character.
 for _,d in ipairs(char:GetDescendants()) do
  if d:IsA("LocalScript") and d.Name=="Animate" then
   d.Disabled=true
   d:Destroy()
  end
 end

 local animator=hum:FindFirstChildOfClass("Animator")
 if animator then
  for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
   pcall(function()track:Stop(0)end)
  end
  animPlayedConn=animator.AnimationPlayed:Connect(function(track)
   -- Any late track from another script is stopped immediately.
   task.defer(function()
    if track and track.IsPlaying then
     pcall(function()track:Stop(0)end)
    end
   end)
  end)
 end

 local motors={}
 for _,d in ipairs(char:GetDescendants()) do
  if d:IsA("Motor6D") then table.insert(motors,d) end
 end

 movingTime=0
 hum.WalkSpeed=BASE_SPEED

 local state="Idle"
 local stateStart=os.clock()
 local blendStart=os.clock()
 local from=setmetatable({},{__mode="k"})

 local function chooseState()
  local hs=hum:GetState()
  if hs==Enum.HumanoidStateType.Jumping
   or hs==Enum.HumanoidStateType.Freefall then
   return "Jump"
  end

  if hum.MoveDirection.Magnitude<.05 then return "Idle" end

  local localDir=root.CFrame:VectorToObjectSpace(hum.MoveDirection)
  local x,z=localDir.X,localDir.Z
  local running=hum.WalkSpeed>=RUN_THRESHOLD

  if running then
   if z<-.20 then
    if x<-.28 then return "RunLeft" end
    if x>.28 then return "RunRight" end
    return "RunForward"
   end
   if z>.30 then return "WalkBack" end
   if x<0 then return "RunLeft" end
   return "RunRight"
  end

  if z<-.35 then return "WalkForward" end
  if z>.35 then return "WalkBack" end
  if x<0 then return "WalkLeft" end
  return "WalkRight"
 end

 local function changeState(nextState)
  if nextState==state then return end
  for _,m in ipairs(motors) do from[m]=m.Transform end
  state=nextState
  stateStart=os.clock()
  blendStart=stateStart
 end

 frameConn=RunService.PreSimulation:Connect(function(dt)
  if not char.Parent or hum.Health<=0 then return end

  local moving=hum.MoveDirection.Magnitude>.05
  if moving then
   movingTime=math.min(ACCEL_TIME,movingTime+dt)
  else
   movingTime=0
  end

  local t=math.clamp(movingTime/ACCEL_TIME,0,1)
  local accel=math.sin(t*math.pi*.5)
  hum.WalkSpeed=moving and (BASE_SPEED+(MAX_SPEED-BASE_SPEED)*accel) or BASE_SPEED

  local cam=workspace.CurrentCamera
  if cam then
   local targetFov=moving and (70+10*accel) or 70
   cam.FieldOfView=cam.FieldOfView+(targetFov-cam.FieldOfView)*math.min(1,dt*8)
  end

  changeState(chooseState())

  local clip=CLIPS[state] or CLIPS.Idle
  local rate=1
  if string.sub(state,1,3)=="Run" then
   local a=math.clamp((hum.WalkSpeed-RUN_THRESHOLD)/(MAX_SPEED-RUN_THRESHOLD),0,1)
   rate=.95+a*.35
  elseif string.sub(state,1,4)=="Walk" then
   rate=math.clamp(hum.WalkSpeed/12,.80,1.35)
  end

  local poses=sample(clip,(os.clock()-stateStart)*rate)
  local blend=math.clamp((os.clock()-blendStart)/.10,0,1)

  for _,m in ipairs(motors) do
   local key=m.Part1 and m.Part1.Name or m.Name
   local goal=poses[key] or poses[m.Name] or CFrame.new()

   -- The StarterCharacter jump contains root translation. Applied directly to
   -- RootJoint it can visually push the R6 torso/legs into the floor. Preserve
   -- the exact jump ROTATION but remove root translation.
   if state=="Jump" and (m.Name=="RootJoint" or key=="Torso") then
    goal=goal.Rotation
   end

   m.Transform=(from[m] or m.Transform):Lerp(goal,blend)
  end
 end)
end

player.CharacterAdded:Connect(setup)
if player.Character then task.spawn(setup,player.Character) end
]==]
controller.Parent=SPS

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
ui.Enabled=true
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
local loadLogoAspect=Instance.new("UIAspectRatioConstraint")
loadLogoAspect.AspectRatio=640/483
loadLogoAspect.DominantAxis=Enum.DominantAxis.Width
loadLogoAspect.Parent=loadLogo

local loadText=label(loading,"LoadingText","CARREGANDO...",UDim2.fromScale(.37,.66),UDim2.fromScale(.26,.055),Enum.Font.GothamBlack,1002)
loadText.TextColor3=Color3.fromRGB(235,235,240)

local loadStatus=label(loading,"LoadingStatus","PREPARANDO MAPA",UDim2.fromScale(.39,.715),UDim2.fromScale(.22,.028),Enum.Font.GothamBold,1002)
loadStatus.TextColor3=Color3.fromRGB(145,155,175)
loadStatus.TextTransparency=.10

local loadBar=frame(loading,"LoadingBar",UDim2.fromScale(.34,.765),UDim2.fromScale(.32,.014),Color3.fromRGB(32,35,42),0,1002,8)
local loadFill=Instance.new("Frame")
loadFill.Name="Fill"
loadFill.Size=UDim2.fromScale(0,1)
loadFill.BackgroundColor3=Color3.fromRGB(230,235,245)
loadFill.BorderSizePixel=0
loadFill.ZIndex=1003
loadFill.Parent=loadBar
corner(loadFill,8)

local loadingGradient=Instance.new("UIGradient")
loadingGradient.Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
 ColorSequenceKeypoint.new(1,Color3.fromRGB(120,170,255))
})
loadingGradient.Parent=loadFill

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
local logoAspect=Instance.new("UIAspectRatioConstraint")
logoAspect.AspectRatio=640/483
logoAspect.DominantAxis=Enum.DominantAxis.Width
logoAspect.Parent=logo

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
 local cardAspect=Instance.new("UIAspectRatioConstraint")
 cardAspect.AspectRatio=1.78
 cardAspect.DominantAxis=Enum.DominantAxis.Width
 cardAspect.Parent=b

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
local shopScene=frame(ui,"ShopScene",UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(18,22,28),.05,90,0)
shopScene.Visible=false

local shopSceneShade=Instance.new("UIGradient")
shopSceneShade.Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromRGB(17,20,25)),
 ColorSequenceKeypoint.new(.55,Color3.fromRGB(28,34,44)),
 ColorSequenceKeypoint.new(1,Color3.fromRGB(12,14,18))
})
shopSceneShade.Rotation=0
shopSceneShade.Parent=shopScene

local shopAvatar=Instance.new("ViewportFrame")
shopAvatar.Name="ShopAvatarViewport"
shopAvatar.Position=UDim2.fromScale(.48,.12)
shopAvatar.Size=UDim2.fromScale(.47,.74)
shopAvatar.BackgroundColor3=Color3.fromRGB(24,29,36)
shopAvatar.BackgroundTransparency=.05
shopAvatar.BorderSizePixel=0
shopAvatar.Ambient=Color3.fromRGB(220,225,235)
shopAvatar.LightColor=Color3.fromRGB(255,255,255)
shopAvatar.LightDirection=Vector3.new(-.7,-1,-.5)
shopAvatar.ZIndex=92
shopAvatar.Parent=shopScene
corner(shopAvatar,12)
stroke(shopAvatar,Color3.fromRGB(65,72,84),2,.25)

local shopAvatarTitle=label(shopScene,"AvatarTitle","SEU PERSONAGEM",UDim2.fromScale(.59,.06),UDim2.fromScale(.25,.045),Enum.Font.GothamBlack,93)
shopAvatarTitle.TextColor3=Color3.fromRGB(220,225,235)

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
inv.BackgroundColor3=Color3.fromRGB(22,24,29)
inv.BackgroundTransparency=.10
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

local results=frame(ui,"RoundResults",UDim2.fromScale(.19,.24),UDim2.fromScale(.62,.30),Color3.fromRGB(11,13,17),.04,230,10)
results.Visible=false
stroke(results,Color3.fromRGB(90,110,145),2,.15)

local resultsHeader=frame(results,"Header",UDim2.fromScale(0,0),UDim2.fromScale(1,.24),Color3.fromRGB(35,48,68),.02,231,10)
local resultsTitle=label(resultsHeader,"Title","RODADA FINALIZADA",UDim2.fromScale(.17,.08),UDim2.fromScale(.66,.70),Enum.Font.GothamBlack,232)

local resultsTime=label(results,"Time","TEMPO 2:00",UDim2.fromScale(.34,.25),UDim2.fromScale(.32,.10),Enum.Font.GothamBold,232)
resultsTime.TextColor3=Color3.fromRGB(180,195,220)

local survivorTitle=label(results,"SurvivorTitle","SOBREVIVENTES",UDim2.fromScale(.08,.39),UDim2.fromScale(.84,.10),Enum.Font.GothamBlack,232)
survivorTitle.TextColor3=Color3.fromRGB(115,235,140)

local survivorNames=label(results,"SurvivorNames","",UDim2.fromScale(.07,.50),UDim2.fromScale(.86,.18),Enum.Font.GothamBold,232)
survivorNames.TextColor3=Color3.fromRGB(240,240,245)

local resultsExit=textButton(results,"Exit","SAÍDA",UDim2.fromScale(.39,.78),UDim2.fromScale(.22,.13),Color3.fromRGB(185,60,68),Color3.fromRGB(230,85,95),233)


-- camera button in round
local camBtn=textButton(ui,"CameraModeButton","3P",UDim2.fromScale(.875,.13),UDim2.fromScale(.07,.055),Color3.fromRGB(25,25,28),Color3.fromRGB(100,120,155),150)
camBtn.Visible=false

local inGameActions=Instance.new("Frame")
inGameActions.Name="InGameActions"
inGameActions.Position=UDim2.fromScale(.875,.245)
inGameActions.Size=UDim2.fromScale(.095,.245)
inGameActions.BackgroundTransparency=1
inGameActions.ZIndex=145
inGameActions.Visible=false
inGameActions.Parent=ui

local gameMenuBtn=textButton(
 inGameActions,"MenuButton","☰\nMENU",
 UDim2.fromScale(0,0),UDim2.fromScale(1,.27),
 Color3.fromRGB(24,24,27),Color3.fromRGB(170,180,200),150
)
local gameEmotesBtn=textButton(
 inGameActions,"EmotesButton","♪\nEMOTES",
 UDim2.fromScale(0,.365),UDim2.fromScale(1,.27),
 Color3.fromRGB(24,24,27),Color3.fromRGB(225,190,105),150
)
local gameItemsBtn=textButton(
 inGameActions,"ItemsButton","▣\nITENS",
 UDim2.fromScale(0,.73),UDim2.fromScale(1,.27),
 Color3.fromRGB(24,24,27),Color3.fromRGB(105,165,235),150
)


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

local controls=nil
pcall(function()
 local PlayerModule=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
 controls=PlayerModule:GetControls()
end)

local function setControlsEnabled(enabled)
 if not controls then return end
 if enabled then controls:Enable() else controls:Disable() end
end
local loading=gui:WaitForChild("Background")
local loadText=loading:WaitForChild("LoadingText")
local menu=gui:WaitForChild("MainMenu")
local status=gui:WaitForChild("RoundStatus")
local shopScene=gui:WaitForChild("ShopScene")
local shopPanel=gui:WaitForChild("ShopPanel")
local shopAvatarViewport=shopScene:WaitForChild("ShopAvatarViewport")
local daily=gui:WaitForChild("DailyShopPanel")
local inv=gui:WaitForChild("InventoryPanel")
local modal=gui:WaitForChild("UtilityModal")
local results=gui:WaitForChild("RoundResults")
local camBtn=gui:WaitForChild("CameraModeButton")
local inGameActions=gui:WaitForChild("InGameActions")
local gameMenuBtn=inGameActions:WaitForChild("MenuButton")
local gameEmotesBtn=inGameActions:WaitForChild("EmotesButton")
local gameItemsBtn=inGameActions:WaitForChild("ItemsButton")

local net=RS:WaitForChild("NB_Remotes",15)
local join=net and net:FindFirstChild("JoinGame")
local roundState=net and net:FindFirstChild("RoundState")
local menuState=net and net:FindFirstChild("MenuState")
local returnToMenu=net and net:FindFirstChild("ReturnToMenu")

local camera=workspace.CurrentCamera
local menuMode=true
local queued=false
local cameraMode="3P"
local pendingInventory=false

local function clock(n)
 n=math.max(0,math.floor(tonumber(n) or 0))
 return string.format("%d:%02d",math.floor(n/60),n%60)
end

local function setMenuCamera()
 menuMode=true
 setControlsEnabled(false)
 camera.CameraType=Enum.CameraType.Scriptable
 camera.FieldOfView=70
 camBtn.Visible=false
 inGameActions.Visible=false
end

local function setFreeRoamMenu()
 menuMode=false
 setControlsEnabled(true)

 local ch=player.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if hum then camera.CameraSubject=hum end

 player.CameraMode=Enum.CameraMode.Classic
 player.CameraMinZoomDistance=9
 player.CameraMaxZoomDistance=9
 camera.CameraType=Enum.CameraType.Custom
 camera.FieldOfView=70

 camBtn.Visible=false
 inGameActions.Visible=false
end

local function setGameCamera()
 menuMode=false
 setControlsEnabled(true)
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
 inGameActions.Visible=true
end

RunService:BindToRenderStep("NB_MenuCamera",Enum.RenderPriority.Camera.Value+10,function()
 if not menuMode then return end

 camera.CameraType=Enum.CameraType.Scriptable
 camera.FieldOfView=70

 local baseCF=nil
 local a=workspace:FindFirstChild("MenuCameraAnchor")
 if a then
  baseCF=a.CFrame
 else
  local map=workspace:FindFirstChild("ActiveMap")
  local pf=map and map:FindFirstChild("NBPlayerSpawnPoints")
  local p=pf and pf:FindFirstChildWhichIsA("BasePart")
  if p then
   local pos=p.Position+Vector3.new(0,5,10)
   baseCF=CFrame.lookAt(pos,p.Position+Vector3.new(0,2,0))
  else
   local ch=player.Character
   local root=ch and ch:FindFirstChild("HumanoidRootPart")
   if root then
    local pos=root.Position+Vector3.new(0,5,10)
    baseCF=CFrame.lookAt(pos,root.Position+Vector3.new(0,2,0))
   else
    baseCF=CFrame.lookAt(Vector3.new(0,8,16),Vector3.new(0,3,0))
   end
  end
 end

 local t=os.clock()
 local drift=CFrame.new(math.sin(t*.32)*.08,math.sin(t*.27)*.03,0)
 camera.CFrame=baseCF*drift
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

local hidePanels

local function renderAvatar(viewport,withRoom)
 viewport:ClearAllChildren()

 local char=player.Character
 if not char then return end

 local world=Instance.new("WorldModel")
 world.Parent=viewport

 char.Archivable=true
 local clone=char:Clone()

 for _,d in ipairs(clone:GetDescendants()) do
  if d:IsA("LuaSourceContainer") then
   d:Destroy()
  elseif d:IsA("BasePart") then
   d.Anchored=true
   d.CanCollide=false
  end
 end

 clone:PivotTo(CFrame.new())
 clone.Parent=world

 local cf,size=clone:GetBoundingBox()
 local focus=cf.Position+Vector3.new(0,size.Y*.04,0)
 local distance=math.max(7,size.Y*1.45,size.X*2.1)

 if withRoom then
  local floor=Instance.new("Part")
  floor.Name="PreviewFloor"
  floor.Size=Vector3.new(18,.4,18)
  floor.Anchored=true
  floor.CanCollide=false
  floor.Material=Enum.Material.SmoothPlastic
  floor.Color=Color3.fromRGB(42,47,55)
  floor.Position=Vector3.new(0,-3.15,0)
  floor.Parent=world

  local back=Instance.new("Part")
  back.Name="PreviewBack"
  back.Size=Vector3.new(18,12,.35)
  back.Anchored=true
  back.CanCollide=false
  back.Material=Enum.Material.SmoothPlastic
  back.Color=Color3.fromRGB(30,35,43)
  back.Position=Vector3.new(0,2.6,4.2)
  back.Parent=world
 end

 local vcam=Instance.new("Camera")
 vcam.FieldOfView=34

 -- Roblox characters face -Z by default. Put camera on -Z to see the FRONT,
 -- not the back.
 vcam.CFrame=CFrame.lookAt(
  focus+Vector3.new(0,size.Y*.03,-distance),
  focus
 )
 vcam.Parent=viewport
 viewport.CurrentCamera=vcam
end

local function openInventoryScreen()
 hidePanels()
 menu.Visible=false
 shopScene.Visible=false
 inv.Visible=true
 setMenuCamera()
 renderAvatar(inv:FindFirstChild("AvatarViewport"),false)
end

hidePanels=function()
 shopScene.Visible=false
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
 setFreeRoamMenu()
end

menu.ShopButton.MouseButton1Click:Connect(function()
 menu.Visible=false
 hidePanels()
 shopScene.Visible=true
 shopPanel.Visible=true
 setMenuCamera()
 renderAvatar(shopAvatarViewport,true)
end)

shopPanel.Exit.MouseButton1Click:Connect(function()
 shopScene.Visible=false
 showMenu()
end)
shopPanel.DailyShop.MouseButton1Click:Connect(function()
 shopPanel.Visible=false
 shopScene.Visible=true
 daily.Visible=true
end)
daily.Back.MouseButton1Click:Connect(function()
 daily.Visible=false
 shopScene.Visible=true
 shopPanel.Visible=true
end)

menu.InventoryButton.MouseButton1Click:Connect(function()
 openInventoryScreen()
end)
inv.Exit.MouseButton1Click:Connect(function()
 inv.Visible=false
 showMenu()
end)

menu.PlayButton.MouseButton1Click:Connect(function()
 if queued then return end
 queued=true
 hidePanels()
 menu.Visible=false
 status.Visible=true
 status.Text="INTERMISSION\nAGUARDANDO..."
 if join then join:FireServer() end
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
results.Exit.MouseButton1Click:Connect(function()results.Visible=false end)

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

local dailyTimer=daily:FindFirstChild("Timer")
task.spawn(function()
 while gui.Parent do
  if dailyTimer then
   local utc=os.date("!*t")
   local remaining=(23-utc.hour)*3600+(59-utc.min)*60+(60-utc.sec)
   remaining=math.max(0,remaining)
   dailyTimer.Text=string.format(
    "Atualiza em %02d:%02d:%02d",
    math.floor(remaining/3600),
    math.floor((remaining%3600)/60),
    remaining%60
   )
  end
  task.wait(1)
 end
end)

gameMenuBtn.MouseButton1Click:Connect(function()
 if returnToMenu then
  returnToMenu:FireServer()
 else
  showMenu()
 end
end)

gameEmotesBtn.MouseButton1Click:Connect(function()
 modal.Title.Text="EMOTES"
 modal.Body.Text="Escolha seus emotes durante a partida."
 modal.Visible=true
end)

gameItemsBtn.MouseButton1Click:Connect(function()
 -- Never open the heavy inventory while the player is still targetable in a
 -- live round. Leave the round first, then open the equipment screen.
 pendingInventory=true
 inGameActions.Visible=false

 if returnToMenu then
  returnToMenu:FireServer()
 else
  pendingInventory=false
  showMenu()
  openInventoryScreen()
 end
end)

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

if menuState then menuState.OnClientEvent:Connect(function(mode)
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
  if pendingInventory then
   pendingInventory=false
   task.defer(openInventoryScreen)
  end
 end
end) end

if roundState then roundState.OnClientEvent:Connect(function(kind,a,b,c)
 if kind=="Intermission" then
  status.Text="INTERMISSION\n"..clock(a)
  if player:GetAttribute("NBState")=="Menu" and not queued and not loading.Visible then
   menu.Visible=true
   setFreeRoamMenu()
  end
 elseif kind=="Results" then
  local survivors=type(a)=="table" and a or {}
  local roundTime=tonumber(b) or 0
  local mapName=tostring(c or "MAPA")

  results.Time.Text=mapName.."   •   TEMPO "..clock(roundTime)

  if #survivors==0 then
   results.SurvivorNames.Text="Ninguém sobreviveu"
  else
   results.SurvivorNames.Text=table.concat(survivors,"   •   ")
  end

  results.Visible=true
 else
  status.Text=tostring(b or "ROUND").."\n"..clock(a)
 end
end) endd

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
setControlsEnabled(false)
menu.Visible=false
status.Visible=false
hidePanels()
setMenuCamera()

local loadingStarted=os.clock()
task.spawn(function()
 local dots=0
 while loading.Visible do
  dots=(dots%3)+1
  loadText.Text="CARREGANDO"..string.rep(".",dots)

  local bar=loading:FindFirstChild("LoadingBar")
  local fill=bar and bar:FindFirstChild("Fill")
  if fill then
   local p=math.clamp((os.clock()-loadingStarted)/3,0,1)
   fill.Size=UDim2.fromScale(p,1)
  end

  task.wait(.08)
 end
end)

if not game:IsLoaded() then game.Loaded:Wait() end
local remaining=3-(os.clock()-loadingStarted)
if remaining>0 then task.wait(remaining) end
loading.Visible=false
status.Visible=true
showMenu()
]==]
client.Parent=ui

-- =========================================================
-- PLAYERGUI BOOTSTRAP
-- Do not rely on StarterGui replication. Keep the finished UI as a template
-- in ReplicatedStorage and inject it into PlayerGui from StarterPlayerScripts.
-- =========================================================
local oldTemplate=RS:FindFirstChild("NB_UI_TEMPLATE")
if oldTemplate then oldTemplate:Destroy() end
ui.Name="NB_UI_TEMPLATE"
ui.Enabled=true
ui.Parent=RS

local oldBoot=SPS:FindFirstChild("NB_UIBootstrap")
if oldBoot then oldBoot:Destroy() end

local boot=Instance.new("LocalScript")
boot.Name="NB_UIBootstrap"
boot.Source=[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")

-- Emergency loader is generated locally, so it appears even if the menu
-- template or a Remote is late.
local emergency=Instance.new("ScreenGui")
emergency.Name="NB_EmergencyLoader"
emergency.IgnoreGuiInset=true
emergency.ResetOnSpawn=false
emergency.DisplayOrder=10000
emergency.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
emergency.Parent=pg

local bg=Instance.new("Frame")
bg.Size=UDim2.fromScale(1,1)
bg.BackgroundColor3=Color3.new(0,0,0)
bg.BorderSizePixel=0
bg.ZIndex=1
bg.Parent=emergency

local logo=Instance.new("ImageLabel")
logo.AnchorPoint=Vector2.new(.5,.5)
logo.Position=UDim2.fromScale(.5,.43)
logo.Size=UDim2.fromScale(.48,.34)
logo.BackgroundTransparency=1
logo.Image="rbxassetid://127912605246110"
logo.ScaleType=Enum.ScaleType.Fit
logo.ZIndex=2
logo.Parent=bg

local text=Instance.new("TextLabel")
text.AnchorPoint=Vector2.new(.5,.5)
text.Position=UDim2.fromScale(.5,.68)
text.Size=UDim2.fromScale(.30,.06)
text.BackgroundTransparency=1
text.Text="CARREGANDO..."
text.TextColor3=Color3.fromRGB(245,245,245)
text.TextStrokeTransparency=.25
text.TextScaled=true
text.Font=Enum.Font.GothamBlack
text.ZIndex=2
text.Parent=bg

local sub=Instance.new("TextLabel")
sub.AnchorPoint=Vector2.new(.5,.5)
sub.Position=UDim2.fromScale(.5,.73)
sub.Size=UDim2.fromScale(.28,.03)
sub.BackgroundTransparency=1
sub.Text="PREPARANDO MAPA"
sub.TextColor3=Color3.fromRGB(145,155,175)
sub.TextScaled=true
sub.Font=Enum.Font.GothamBold
sub.ZIndex=2
sub.Parent=bg

local bar=Instance.new("Frame")
bar.AnchorPoint=Vector2.new(.5,.5)
bar.Position=UDim2.fromScale(.5,.79)
bar.Size=UDim2.fromScale(.32,.014)
bar.BackgroundColor3=Color3.fromRGB(32,35,42)
bar.BorderSizePixel=0
bar.ZIndex=2
bar.Parent=bg
local bc=Instance.new("UICorner")
bc.CornerRadius=UDim.new(1,0)
bc.Parent=bar

local fill=Instance.new("Frame")
fill.Size=UDim2.fromScale(0,1)
fill.BackgroundColor3=Color3.fromRGB(225,235,255)
fill.BorderSizePixel=0
fill.ZIndex=3
fill.Parent=bar
local fc=Instance.new("UICorner")
fc.CornerRadius=UDim.new(1,0)
fc.Parent=fill

local started=os.clock()
local template=RS:WaitForChild("NB_UI_TEMPLATE",20)

local old=pg:FindFirstChild("NextbotsBrasilUI")
if old then old:Destroy() end

local gui=nil
if template then
 gui=template:Clone()
 gui.Name="NextbotsBrasilUI"
 gui.Enabled=true
 gui.Parent=pg
end

-- Keep exact loading visible for at least 3 seconds.
while os.clock()-started<3 do
 local elapsed=os.clock()-started
 local dots=(math.floor(elapsed*3)%3)+1
 text.Text="CARREGANDO"..string.rep(".",dots)
 fill.Size=UDim2.fromScale(math.clamp(elapsed/3,0,1),1)
 task.wait(.08)
end
fill.Size=UDim2.fromScale(1,1)

if gui then
 local ownLoading=gui:FindFirstChild("Background")
 if ownLoading then ownLoading.Visible=false end

 local menu=gui:FindFirstChild("MainMenu")
 local state=player:GetAttribute("NBState")
 if menu and state~="InRound" and state~="Queued" then
  menu.Visible=true
 end

 local status=gui:FindFirstChild("RoundStatus")
 if status then status.Visible=true end
end

emergency:Destroy()
]==]
boot.Parent=SPS


AS:SavePlaceAsync()

return {
 ok=true,
 version=game.PlaceVersion,
 alwaysDay=Lighting.ClockTime,
 playerBaseSpeed=PLAYER_BASE_SPEED,
 playerMaxSpeed=PLAYER_MAX_SPEED,
 botSpeed=BOT_SPEED,

 animationSourceAsset="14026023204",
 animationFolderSource=animFolder:GetAttribute("SourceAssetId"),
 runForwardFrames=#animFolder.Forward:GetKeyframes(),
 runLeftFrames=#animFolder.FLeft:GetKeyframes(),
 runRightFrames=#animFolder.FRight:GetKeyframes(),
 walkForwardFrames=#animFolder.forward:GetKeyframes(),
 jumpFrames=#animFolder.jump:GetKeyframes(),
 singleAnimationWriter=true,
 unifiedEvadeController=true,
 animationPhase="PreSimulation",
 stopsForeignAnimationTracks=true,

 persistentGroundSpawns=true,
 denseTileFloorDetection=true,
 rejectsUpperSpawnLocations=true,
 runtimeFloorValidation=true,
 spawnAudit=spawnAudit,

 fixedZoom=true,
 cameraButtonSafe=true,
 interiorMenuCameraLogic=true,
 spawnClearanceValidation=true,
 voidRescue=true,
 joinKeepsIntermissionPosition=true,
 botLineOfSightChase=true,
 botCachedPathfinding=true,
 botPartsForcedUnanchored=true,
 botTouchKills=true,
 nonHumanoidBotChase=true,
 jumpRootTranslationRemoved=true,
 roundResultsEvent=true,
 resultsPanel=true,
 shopSeparateScene=true,
 shopAvatarPreview=true,
 inventoryFrontFacingAvatar=true,
 itemsLeaveRoundBeforeOpen=true,
 improvedLoadingProgress=true,
 menuControlsLocked=true,
 menuCameraDrift=true,
 inventoryAutoFit=true,
 liveDailyTimer=true,
 intermissionAvatarOnMap=true,
 botSpawnFolder=true,
 exactLogo=LOGO,
 uiRebuilt=true,
 playerGuiBootstrap=true,
 emergencyLoader=true,
 menuCameraFallback=true,
 menuCameraNeverLooksUp=true,
 inGameMenuButton=true,
 inGameEmotesButton=true,
 inGameItemsButton=true,
 returnToMenuKeepsAvatar=true,
 intermissionFreeRoam=true,
 randomMapRepeatsAllowed=true,
 sameMapNoTeleport=true,
 botSpawnSkullMarkers=true,
 r6ForcedUnanchored=true,
 roundLoopRecovery=true,
 loadingText="CARREGANDO..."
}
