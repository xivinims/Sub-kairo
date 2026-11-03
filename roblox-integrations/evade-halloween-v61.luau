assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"wrong target")
local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local SPS=game:GetService("StarterPlayer").StarterPlayerScripts
local AS=game:GetService("AssetService")
local IS=game:GetService("InsertService")
local evade=IS:LoadAsset(14026023204)
local nametags=IS:LoadAsset(92018365421220)
local studAsset=IS:LoadAsset(128071741625902)
local rig=assert(evade:FindFirstChild("StarterCharacter"),"Evade StarterCharacter missing"):Clone()
local saves=assert(rig:FindFirstChild("AnimSaves"),"original keyframes missing")
local clips=Instance.new("Folder") clips.Name="NB_R6Animations"
for _,seq in ipairs(saves:GetChildren()) do if seq:IsA("KeyframeSequence") then seq:Clone().Parent=clips end end
assert(#clips:GetChildren()==12,"expected all 12 original animations")
local hum=assert(rig:FindFirstChildOfClass("Humanoid"),"missing humanoid")
assert(hum.RigType==Enum.HumanoidRigType.R6,"wrong rig")
local motors={}
for _,d in ipairs(rig:GetDescendants()) do
 if d:IsA("Motor6D") and d.Part1 then motors[d.Part1.Name]=d end
end
for _,seq in ipairs(clips:GetChildren()) do
 assert(#seq:GetKeyframes()>0,"empty clip")
 for _,d in ipairs(seq:GetDescendants()) do if d:IsA("Pose") and d.Name~="HumanoidRootPart" then assert(motors[d.Name],"unmapped pose "..d.Name) end end
end
saves:Destroy()
for _,d in ipairs(rig:GetDescendants()) do
 if d:IsA("LuaSourceContainer") then d:Destroy()
 elseif d:IsA("BasePart") then
  d.Anchored=false
  if d.Name=="ArmRot" or d.Name=="TorsoRot" then d.CanCollide=false d.Massless=true end
 end
end
hum.RequiresNeck=false
rig.PrimaryPart=rig.HumanoidRootPart
rig.Name="NB_StarterCharacterBase" rig:SetAttribute("NBSourceAssetId","14026023204")
clips:SetAttribute("NBSourceAssetId","14026023204")
local originalTag=assert(nametags:FindFirstChild("Nametag",true),"original Nametag GUI missing")
assert(originalTag:IsA("BillboardGui") and originalTag:FindFirstChild("Username"),"invalid Nametag")

-- Compose the Halloween map from the exact models, with no resizing.
local oldMap=SS.NB_Maps:FindFirstChild("Map3_Halloween")
assert(oldMap and oldMap:FindFirstChild("HalloweenDecor"),"Halloween decoration source missing")
local decorSource=oldMap.HalloweenDecor
local map=Instance.new("Model") map.Name="Map3_Halloween"
map:SetAttribute("BaseAssetId","128071741625902")
map:SetAttribute("DecorationAssetId",oldMap:GetAttribute("DecorationAssetId") or "113280926555931")
map:SetAttribute("SeasonalOnly",true)
map:SetAttribute("NBLayoutVersion",2)
local base=Instance.new("Model") base.Name="StudBase" base.Parent=map
local decor=Instance.new("Model") decor.Name="HalloweenDecor" decor.Parent=map
local function worldBounds(obj)
 local min=Vector3.new(math.huge,math.huge,math.huge)
 local max=-min
 for _,p in ipairs(obj:GetDescendants()) do if p:IsA("BasePart") then
  for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
   local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)
   min=Vector3.new(math.min(min.X,v.X),math.min(min.Y,v.Y),math.min(min.Z,v.Z))
   max=Vector3.new(math.max(max.X,v.X),math.max(max.Y,v.Y),math.max(max.Z,v.Z))
  end end end
 end end
 assert(min.X<math.huge,"empty model")
 return (min+max)*.5,max-min
end
local placed={}
local function place(src,parent,x,z,yaw,y)
 assert(src,"missing scene model")
 local m=src:Clone()
 m:SetAttribute("NBOriginalModel",src.Name)
 for _,d in ipairs(m:GetDescendants()) do
  if d:IsA("LuaSourceContainer") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=true d.CanTouch=false end
 end
 local center,size=worldBounds(m)
 local transform=CFrame.new(x,(y or 0)+size.Y*.5,z)*CFrame.Angles(0,math.rad(yaw or 0),0)*CFrame.new(-center)
 m:PivotTo(transform*m:GetPivot())
 m.Parent=parent
 table.insert(placed,m)
 return m
end
local function part(name,size,pos,color,parent)
 local p=Instance.new("Part") p.Name=name p.Size=size p.Position=pos p.Color=color p.Anchored=true
 p.Material=Enum.Material.Plastic p.TopSurface=Enum.SurfaceType.Studs p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent return p
end
part("StudFloor",Vector3.new(300,2,300),Vector3.new(0,-1,0),Color3.fromRGB(64,62,72),map)
local paths=Instance.new("Folder") paths.Name="Walkways" paths.Parent=map
local pathColor=Color3.fromRGB(108,103,100)
part("CrossingNorthSouth",Vector3.new(14,.15,270),Vector3.new(0,.075,0),pathColor,paths)
part("CrossingEastWest",Vector3.new(270,.15,14),Vector3.new(0,.075,0),pathColor,paths)
for _,z in ipairs({-108,108}) do part("OuterWalkway",Vector3.new(230,.15,12),Vector3.new(0,.075,z),pathColor,paths) end
for _,x in ipairs({-108,108}) do part("OuterWalkway",Vector3.new(12,.15,204),Vector3.new(x,.075,0),pathColor,paths) end
local pack=studAsset:FindFirstChild("Stud pack V1")
assert(pack,"Stud pack V1 folder missing")
local function stud(name,x,z,yaw,y)return place(pack:FindFirstChild(name),base,x,z,yaw,y)end
stud("Shop",68,-62,0)
stud("Leaderboard",48,-78,0)
stud("Wall",78,-87,0)
stud("Wall",72,77,180)
local treeIndex=0
for _,z in ipairs({-132,132}) do for x=-132,132,22 do
 treeIndex+=1 stud(treeIndex%2==0 and "Tree1" or "Tree2",x,z,(treeIndex*47)%360)
end end
for _,x in ipairs({-132,132}) do for z=-88,88,44 do
 treeIndex+=1 stud(treeIndex%2==0 and "Tree1" or "Tree2",x,z,(treeIndex*47)%360)
end end
for i,p in ipairs({{-90,-22},{-23,-90},{23,-44},{90,-22},{-22,88},{90,24},{23,75},{-90,25}}) do
 stud(i%2==0 and "Tree1" or "Tree2",p[1],p[2],i*39)
 stud("Rock",p[1]+8,p[2]+5,i*31)
 stud(i%2==0 and "Grass1" or "Grass2",p[1]-6,p[2]+4,i*19)
end
stud("Flowers",61,-44,15)
local function prop(category,name,x,z,yaw,y)
 local folder=decorSource:FindFirstChild(category)
 return place(folder and folder:FindFirstChild(name),decor,x,z,yaw,y)
end
-- Northern ruins and graveyard; keep both cross paths clear.
prop("Architecture","Church 02",-78,-88,180)
prop("Architecture","Church 01",-43,-88,180)
prop("Architecture","Gate",-57,-37,0)
for i=1,4 do
 prop("Architecture","Fence 0"..i,-83+(i-1)*7,-37,0)
 prop("Architecture","Fence 0"..i,-42+(i-1)*7,-37,0)
end
for row=1,3 do for col=1,4 do
 local x=-83+(col-1)*13 local z=-70+(row-1)*11
 prop("Graveyard","Tombstone 0"..((col-1)%3+1),x,z,180)
 prop("Graveyard","Grave 0"..((row-1)%3+1),x,z+4,0)
end end
prop("Graveyard","Wooden Coffin",-33,-61,15)
prop("Graveyard","Shovel",-31,-68,35)
prop("Remains","Bones 03",-31,-56,10)
-- Witch market: original stall, furniture and small props on its table.
local tableModel=prop("Furniture","Table 02",67,-45,0)
local tc,ts=worldBounds(tableModel) local top=tc.Y+ts.Y*.5
prop("Furniture","Chair 01",76,-47,90)
prop("Witchcraft","Cauldron",59,-53,0)
prop("Witchcraft","Broom 01",78,-61,90)
prop("Witchcraft","Hat",70,-44,15,top)
prop("Witchcraft","Book 01",64,-45,0,top)
for i=1,5 do prop("Witchcraft",string.format("Potion %02d",i),62+i*1.4,-46,0,top) end
prop("Decorations","Pumpkin Garland",68,-54,0,8)
prop("Decorations","Flag 01",68,-69,0,10)
-- Pumpkin grove, with the same models and their original colors/proportions.
for row=1,4 do for col=1,5 do
 local x=-82+col*8 local z=42+row*9
 local n=(row+col-2)%5+1
 prop("Pumpkins",string.format("Pumpkin %02d",n),x,z,(row*41+col*29)%360)
end end
prop("Decorations","Scarecrow 01",-70,54,15)
prop("Decorations","Scarecrow 02",-43,87,-20)
prop("Furniture","Table 01",-82,82,0)
for i=1,5 do prop("Decorations",string.format("Candy %02d",i),-84+i*.65,82,15,3.14) end
-- Eastern ruins and a campfire clearing.
prop("Architecture","Church 01",38,86,0)
prop("Architecture","Wall 01",39,56,0)
prop("Architecture","Wall 02",78,42,90)
prop("Lighting","Fire",65,30,0)
prop("Furniture","Chair 02",65,38,0)
prop("Furniture","Chair 02",56,29,90)
prop("Nature","Wood 05",85,54,20)
for i,p in ipairs({{-32,-18},{32,-18},{-32,18},{32,18},{-18,-84},{18,-84},{-18,84},{18,84}}) do
 prop("Pumpkins",string.format("Jackolantern %02d",(i-1)%5+1),p[1],p[2],i*42)
 prop("Lighting","Lamp 01",p[1]+(p[1]>0 and 4 or -4),p[2],p[1]>0 and 90 or -90)
end
for i,p in ipairs({{-95,-91},{-93,95},{95,-94},{92,92},{40,29},{-37,32}}) do
 prop("Nature","Tree 0"..((i-1)%4+1),p[1],p[2],i*40)
 prop("Nature","Mushroom 0"..((i-1)%5+1),p[1]+3,p[2]+5,0)
end
local sp=Instance.new("Folder") sp.Name="SpawnPoints" sp.Parent=map
for i,p in ipairs({{0,-120},{0,120},{-120,0},{120,0},{0,-30},{0,30},{-30,0},{30,0}}) do
 local s=part("Spawn"..i,Vector3.new(2,1,2),Vector3.new(p[1],1,p[2]),Color3.new(1,1,1),sp)
 s.Transparency=1 s.CanCollide=false s.CanTouch=false s.CanQuery=false
end
local botSpawns=sp:Clone() botSpawns.Name="NBBotSpawns" botSpawns.Parent=map
-- Restrict bright effects to a small mobile-friendly budget.
local lights=0
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("Light") then lights+=1 d.Enabled=lights<=8 d.Shadows=false d.Range=math.min(d.Range,20)
 elseif d:IsA("ParticleEmitter") then d.Rate=math.min(d.Rate,6) end
end
assert(#sp:GetChildren()==8,"spawn validation")
for _,m in ipairs(placed) do
 local cf,sz=worldBounds(m)
 assert(math.abs(cf.X)+sz.X/2<150 and math.abs(cf.Z)+sz.Z/2<150,"model outside map: "..m.Name)
 assert(cf.Y-sz.Y*.5>=-.01,"floating placement failed")
end

local roundSource=[====[local Players=game:GetService("Players")
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

 local fallback=workspace:FindFirstChild("NB_LobbySpawn")
 if not fallback then
  fallback=Instance.new("Part")
  fallback.Name="NB_LobbySpawn"
  fallback.Size=Vector3.new(16,1,16)
  fallback.Anchored=true
  fallback.CanCollide=true
  fallback.Transparency=1
  fallback.CFrame=CFrame.new(0,10,-500)
  fallback.Parent=workspace
 end
 return fallback.CFrame+Vector3.new(0,4,0)
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

local function spawnCF(map)
 local points=spawnPoints(map)
 if #points==0 then
  local cf,size=map:GetBoundingBox()
  return CFrame.new(cf.Position+Vector3.new(0,size.Y*.5+8,0))
 end
 local p=points[math.random(1,#points)]
 return p.CFrame+Vector3.new(math.random(-4,4),p.Size.Y*.5+4,math.random(-4,4))
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
 if plr.Character~=char or not char.Parent then temp:Destroy() return end
 for _,obj in ipairs(char:GetChildren()) do if obj:IsA("Accessory") then obj:Destroy() end end

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
 local char=baseCharacter:Clone()
 char.Name=plr.Name
 local hum=char:FindFirstChildOfClass("Humanoid")
 local root=char:FindFirstChild("HumanoidRootPart")
 assert(hum and root and hum.RigType==Enum.HumanoidRigType.R6,"Evade base invalid")
 hum.DisplayName=plr.DisplayName
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 hum.WalkSpeed=26 hum.JumpPower=50 hum.UseJumpPower=true hum.AutoRotate=true
 hum.RequiresNeck=false
 for _,d in ipairs(char:GetDescendants()) do
  if d:IsA("LuaSourceContainer") then d:Destroy()
  elseif d:IsA("BasePart") then
   d.Anchored=false
   if d.Name=="ArmRot" or d.Name=="TorsoRot" then d.CanCollide=false d.Massless=true end
  end
 end
 char.PrimaryPart=root
 char:PivotTo(cf)
 char.Parent=workspace
 plr.Character=char
 pcall(function()root:SetNetworkOwner(plr)end)
 if old and old~=char then old:Destroy() end
 task.spawn(function()
  copyUserAppearance(plr,char)
 end)
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
 if char:GetAttribute("NBDeathBound") then return end
 char:SetAttribute("NBDeathBound",true)
 local hum=char:FindFirstChildOfClass("Humanoid")
 if not hum then return end

 hum.Died:Connect(function()
  if not plr.Parent then return end
  plr:SetAttribute("NBInMap",false)
  plr:SetAttribute("NBState","Dead")
  menuState:FireClient(plr,"Show","Dead")

  task.wait(1)
  if not plr.Parent or plr.Character~=char then return end
  local existingHum=char:FindFirstChildOfClass("Humanoid")
  if existingHum and existingHum.Health>0 then return end
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
    if d:IsA("BaseScript") then d.Enabled=false end
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
 plr.CharacterAdded:Connect(function(char)attachDeath(plr,char)end)
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
]====]
local clientSource=[====[-- Original keyframes from Creator Store asset 14026023204.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local localPlayer=Players.LocalPlayer
local clips=RS:WaitForChild("NB_R6Animations")
local baked={}
local actors={}
local function flatten(p,map)
 if p:IsA("Pose") then map[p.Name]={cf=p.CFrame,weight=p.Weight,style=p.EasingStyle.Name,direction=p.EasingDirection.Name} end
 for _,c in ipairs(p:GetChildren()) do if c:IsA("Pose") then flatten(c,map) end end
end
for _,seq in ipairs(clips:GetChildren()) do
 if seq:IsA("KeyframeSequence") then
  local frames={}
  for _,kf in ipairs(seq:GetKeyframes()) do
   local poses={} for _,p in ipairs(kf:GetChildren()) do flatten(p,poses) end
   table.insert(frames,{t=kf.Time,poses=poses})
  end
  table.sort(frames,function(a,b)return a.t<b.t end)
  if #frames>0 then baked[seq.Name]={frames=frames,duration=math.max(.01,frames[#frames].t),looped=seq.Loop} end
 end
end
local function eased(t,p)
 if not p or p.style=="Linear" then return t end
 if p.style=="Constant" then return p.direction=="In" and 1 or (t>=1 and 1 or 0) end
 local style=({Cubic=Enum.EasingStyle.Cubic,CubicV2=Enum.EasingStyle.Cubic,Bounce=Enum.EasingStyle.Bounce,Elastic=Enum.EasingStyle.Elastic})[p.style]
 if not style then return t end
 return TweenService:GetValue(t,style,Enum.EasingDirection[p.direction])
end
local function sample(clip,time,motors)
 local f=clip.frames
 local t=clip.looped and time%clip.duration or math.min(time,clip.duration)
 local lo,hi=1,#f
 while lo<hi do local mid=math.floor((lo+hi+1)/2) if f[mid].t<=t then lo=mid else hi=mid-1 end end
 local a,b=f[lo],f[math.min(lo+1,#f)]
 local alpha=a==b and 0 or math.clamp((t-a.t)/math.max(.00001,b.t-a.t),0,1)
 local poses={}
 for name in pairs(motors) do
  local p,q=a.poses[name],b.poses[name]
  if p or q then
   p=p or q q=q or p
   poses[name]=CFrame.identity:Lerp(p.cf:Lerp(q.cf,eased(alpha,p)),p.weight+(q.weight-p.weight)*alpha)
  else poses[name]=CFrame.identity end
 end
 return poses
end
local function setup(player,char)
 local hum=char:WaitForChild("Humanoid",10)
 local root=char:WaitForChild("HumanoidRootPart",10)
 if not hum or not root or player.Character~=char or not char:FindFirstChild("TorsoRot") then return end
 local motors={}
 for _,d in ipairs(char:GetDescendants()) do if d:IsA("Motor6D") and d.Part1 then motors[d.Part1.Name]=d end end
 actors[player]={char=char,hum=hum,root=root,motors=motors,current="",time=0,blend=0,from={}}
end
local connections={}
local function hook(p)
 connections[p]={
 p.CharacterAdded:Connect(function(c)task.spawn(setup,p,c)end),
 p.CharacterRemoving:Connect(function(c)if actors[p] and actors[p].char==c then actors[p]=nil end end)}
 if p.Character then task.spawn(setup,p,p.Character) end
end
Players.PlayerAdded:Connect(hook)
Players.PlayerRemoving:Connect(function(p)
 actors[p]=nil
 for _,c in ipairs(connections[p] or {}) do c:Disconnect() end
 connections[p]=nil
end)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
RunService.PreSimulation:Connect(function(dt)
 for p,a in pairs(actors) do
  if a.char.Parent and a.root.Parent and a.hum.Health>0 then
   local vel=a.root.AssemblyLinearVelocity*Vector3.new(1,0,1)
   local speed=vel.Magnitude
   local moving=p==localPlayer and a.hum.MoveDirection.Magnitude>.05 or speed>1.5
   local st=a.hum:GetState()
   local name="idle"
   if st==Enum.HumanoidStateType.Jumping or st==Enum.HumanoidStateType.Freefall then name="jump"
   elseif p:GetAttribute("NBSliding") then name="Slide"
   elseif p:GetAttribute("NBCrouching") then name=moving and "Crouch forward" or "Crouch idle"
   elseif moving then
    local dir=p==localPlayer and a.hum.MoveDirection or (speed>0 and vel.Unit or Vector3.zero)
    local d=a.root.CFrame:VectorToObjectSpace(dir)
    if d.Z<-.35 then name=speed>20 and "Forward" or "forward"
     if speed>20 and d.X<-.30 then name="FLeft" elseif speed>20 and d.X>.30 then name="FRight" end
    elseif d.Z>.35 then name="back" elseif d.X<0 then name="left" else name="right" end
   end
   if not baked[name] then name="idle" end
   if a.current~=name then
    a.from={} for n,m in pairs(a.motors) do a.from[n]=m.Transform end
    a.current=name a.time=0 a.blend=0
   end
   a.time+=dt a.blend=math.min(1,a.blend+dt/.12)
   local poses=sample(baked[name],a.time,a.motors)
   for n,m in pairs(a.motors) do if m.Parent then m.Transform=(a.from[n] or CFrame.identity):Lerp(poses[n],a.blend) end end
  end
 end
end)
local motion=RS:WaitForChild("NB_Remotes"):WaitForChild("Motion")
UIS.InputBegan:Connect(function(input,processed)
 if processed or UIS:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.C then motion:FireServer("Crouch")
 elseif input.KeyCode==Enum.KeyCode.LeftControl then motion:FireServer("Slide") end
end)
if UIS.TouchEnabled then
 local gui=Instance.new("ScreenGui")
 gui.Name="NBMovementButtons" gui.ResetOnSpawn=false gui.Parent=localPlayer:WaitForChild("PlayerGui")
 for i,item in ipairs({{"Crouch","AGACHAR"},{"Slide","DESLIZAR"}}) do
  local b=Instance.new("TextButton") b.Name=item[1] b.Text=item[2]
  b.AnchorPoint=Vector2.new(1,1) b.Position=UDim2.new(1,-24-(i-1)*90,1,-185)
  b.Size=UDim2.fromOffset(82,36) b.BackgroundColor3=Color3.fromRGB(24,27,35)
  b.BackgroundTransparency=.2 b.TextColor3=Color3.new(1,1,1) b.TextSize=11 b.Font=Enum.Font.GothamBold
  b.Parent=gui local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,9) corner.Parent=b
  b.Activated:Connect(function()motion:FireServer(item[1])end)
 end
 local function visible()gui.Enabled=localPlayer:GetAttribute("NBInMap")==true end
 localPlayer:GetAttributeChangedSignal("NBInMap"):Connect(visible) visible()
end]====]
local motionSource=[====[local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local remote=game.ReplicatedStorage.NB_Remotes:WaitForChild("Motion")
local last={} local slides={}
remote.OnServerEvent:Connect(function(p,action)
 if action~="Crouch" and action~="Slide" then return end
 local now=os.clock() if now-(last[p] or -10)<.25 then return end last[p]=now
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid") local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or not r or h.Health<=0 or not p:GetAttribute("NBInMap") then return end
 if action=="Crouch" then
  if slides[p] then return end
  local crouch=not p:GetAttribute("NBCrouching") p:SetAttribute("NBCrouching",crouch) h.WalkSpeed=crouch and 12 or 26
 elseif not slides[p] and h.FloorMaterial~=Enum.Material.Air and r.AssemblyLinearVelocity.Magnitude>16 and now-(p:GetAttribute("NBLastSlide") or -10)>2 then
  p:SetAttribute("NBLastSlide",now) p:SetAttribute("NBCrouching",false) p:SetAttribute("NBSliding",true)
  slides[p]={root=r,hum=h,untilTime=now+.65,direction=(r.AssemblyLinearVelocity*Vector3.new(1,0,1)).Unit}
  h.WalkSpeed=32
 end
end)
local function reset(p)
 slides[p]=nil p:SetAttribute("NBSliding",false) p:SetAttribute("NBCrouching",false)
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=26 end
end
local function hook(p)
 p.CharacterAdded:Connect(function()reset(p)end)
 p:GetAttributeChangedSignal("NBInMap"):Connect(function()if not p:GetAttribute("NBInMap") then reset(p) end end)
end
Players.PlayerAdded:Connect(hook) for _,p in ipairs(Players:GetPlayers()) do hook(p) end
Players.PlayerRemoving:Connect(function(p)slides[p]=nil last[p]=nil end)
RunService.Heartbeat:Connect(function()
 for p,s in pairs(slides) do
  if os.clock()>=s.untilTime or not s.root.Parent or s.hum.Health<=0 or not p:GetAttribute("NBInMap") then reset(p)
  else local v=s.root.AssemblyLinearVelocity s.root.AssemblyLinearVelocity=s.direction*32+Vector3.new(0,v.Y,0) end
 end
end)]====]
local tagSource=[====[local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local NametagBillboard = script:WaitForChild("Nametag")


local Config={
 ShowRobloxPlus=true,PlusIcon="",
 ShowVerifiedBadge=true,VerifiedIcon="",AdminVerified={},
 ShowCountryFlag=true,CountryStyle="FLAG",ShowTitles=true,Titles={}
}

local ActiveTags = {}
local CountryCache = {}
local CountryLoading = {}
local InitializedPlayers = {}


local function hexToColor3(hex)
	if type(hex) ~= "string" then
		return Color3.fromRGB(255, 255, 255)
	end

	hex = hex:gsub("#", "")

	if #hex ~= 6 then
		warn("[NametagsV2] Invalid HEX color: " .. tostring(hex))
		return Color3.fromRGB(255, 255, 255)
	end

	local red = tonumber(hex:sub(1, 2), 16)
	local green = tonumber(hex:sub(3, 4), 16)
	local blue = tonumber(hex:sub(5, 6), 16)

	if not red or not green or not blue then
		warn("[NametagsV2] Invalid HEX color: " .. tostring(hex))
		return Color3.fromRGB(255, 255, 255)
	end

	return Color3.fromRGB(red, green, blue)
end


local function countryCodeToFlag(countryCode)
	if type(countryCode) ~= "string" then
		return ""
	end

	countryCode = string.upper(countryCode)

	if #countryCode ~= 2 then
		return ""
	end

	local first = string.byte(countryCode, 1)
	local second = string.byte(countryCode, 2)

	if not first or not second then
		return ""
	end

	if first < 65 or first > 90 or second < 65 or second > 90 then
		return ""
	end

	local regionalIndicatorA = 0x1F1E6

	return utf8.char(
		regionalIndicatorA + (first - 65),
		regionalIndicatorA + (second - 65)
	)
end


local function formatCountry(countryCode)
	if not countryCode or countryCode == "" then
		return ""
	end

	if Config.CountryStyle == "CODE" then
		return "[" .. string.upper(countryCode) .. "]"
	end

	return countryCodeToFlag(countryCode)
end


local function isVerified(player)
	if player.HasVerifiedBadge then
		return true
	end

	if Config.AdminVerified[player.UserId] then
		return true
	end

	return false
end


local function getPlayerTitle(player)
	if not Config.ShowTitles then
		return nil
	end

	return Config.Titles[player.UserId]
end


local function updateNametag(player)
	local tag = ActiveTags[player]

	if not tag or not tag.Parent then
		return
	end

	local usernameLabel = tag:FindFirstChild("Username")
	local titleLabel = tag:FindFirstChild("Title")

	if not usernameLabel then
		return
	end

	local nameParts = {
		player.DisplayName
	}


	if Config.ShowRobloxPlus and player.HasRobloxSubscription then
		table.insert(nameParts, Config.PlusIcon)
	end


	if Config.ShowVerifiedBadge and isVerified(player) then
		table.insert(nameParts, Config.VerifiedIcon)
	end


	if Config.ShowCountryFlag then
		local countryCode = CountryCache[player.UserId]

		if countryCode and countryCode ~= "" then
			local countryDisplay = formatCountry(countryCode)

			if countryDisplay ~= "" then
				table.insert(nameParts, countryDisplay)
			end
		end
	end


	usernameLabel.Text = table.concat(nameParts, " ")


	if titleLabel then
		local titleData = getPlayerTitle(player)

		if titleData then
			titleLabel.Text = titleData.Text or ""
			titleLabel.TextColor3 = hexToColor3(titleData.Color or "#FFFFFF")
			titleLabel.Visible = true
		else
			titleLabel.Text = ""
			titleLabel.Visible = false
		end
	end
end


local function loadCountry(player)
	if not Config.ShowCountryFlag then
		return
	end

	local userId = player.UserId

	if CountryCache[userId] ~= nil then
		updateNametag(player)
		return
	end

	if CountryLoading[userId] then
		return
	end

	CountryLoading[userId] = true

	task.spawn(function()
		local success, countryCode = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(player)
		end)

		CountryLoading[userId] = nil

		if success and countryCode then
			CountryCache[userId] = countryCode
		else
			CountryCache[userId] = ""

			warn(
				"[NametagsV2] Could not load country for "
					.. player.Name
			)
		end

		updateNametag(player)
	end)
end


local function onCharacterAdded(player, character)
	local head = character:WaitForChild("Head", 10)

	if not head then
		warn("[NametagsV2] Could not find Head for " .. player.Name)
		return
	end

	local oldTag = head:FindFirstChild("CustomNametag")

	if oldTag then
		oldTag:Destroy()
	end

	local newTag = NametagBillboard:Clone()

	newTag.Name = "CustomNametag"
	newTag.Adornee = head
 newTag.Parent = head
 local hum=character:FindFirstChildOfClass("Humanoid")
 if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end

	ActiveTags[player] = newTag

	local usernameLabel = newTag:FindFirstChild("Username")

	if usernameLabel then
		usernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		usernameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	end

	updateNametag(player)
	loadCountry(player)
end


local function onPlayerAdded(player)
	if InitializedPlayers[player] then
		return
	end

	InitializedPlayers[player] = true

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	player:GetPropertyChangedSignal("HasRobloxSubscription"):Connect(function()
		updateNametag(player)
	end)

	player:GetPropertyChangedSignal("DisplayName"):Connect(function()
		updateNametag(player)
	end)

	player:GetPropertyChangedSignal("HasVerifiedBadge"):Connect(function()
		updateNametag(player)
	end)

	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end


Players.PlayerRemoving:Connect(function(player)
	ActiveTags[player] = nil
	InitializedPlayers[player] = nil

	CountryCache[player.UserId] = nil
	CountryLoading[player.UserId] = nil
end)


Players.PlayerAdded:Connect(onPlayerAdded)


for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end]====]
local compilation={}
for name,source in pairs({round=roundSource,animation=clientSource,motion=motionSource,nametags=tagSource}) do
 local check=Instance.new("ModuleScript") check.Name="NB_SyntaxCheck"
 check.Source="return function()\n"..source.."\nend"
 check.Parent=SS
 local ok,fn=pcall(require,check) check:Destroy()
 assert(ok and type(fn)=="function",name..": "..tostring(fn))
 compilation[name]="compiled"
end
local partCount=0 for _,d in ipairs(map:GetDescendants()) do if d:IsA("BasePart") then partCount+=1 end end
local result={ok=true,sourceVersion=game.PlaceVersion,animations=#clips:GetChildren(),models=#placed,mapParts=partCount,rigAnchored=rig.HumanoidRootPart.Anchored,compilation=compilation}

assert(game.PlaceVersion==60,"place changed since preparation; review required")
local backup=Instance.new("Folder")
backup.Name="NB_BackupBeforeAssets_"..tostring(game.PlaceVersion)
backup.Parent=SS
oldMap:Clone().Parent=backup
SS.NB_StarterCharacterBase:Clone().Parent=backup
RS.NB_R6Animations:Clone().Parent=backup
for _,s in ipairs({SSS.NextbotsRoundServer,SSS.NB_NametagService,SPS.NB_R6MotionController}) do
 local c=s:Clone() if c:IsA("BaseScript") then c.Enabled=false end c.Parent=backup
end
local function replace(parent,name,obj)
 local old=parent:FindFirstChild(name) if old then old:Destroy() end
 obj.Name=name obj.Parent=parent
end
replace(SS,"NB_StarterCharacterBase",rig)
replace(RS,"NB_R6Animations",clips)
replace(SS.NB_Maps,"Map3_Halloween",map)
SSS.NextbotsRoundServer.Source=roundSource
SPS.NB_R6MotionController.Source=clientSource
SSS.NB_NametagService.Source=tagSource
replace(SSS.NB_NametagService,"Nametag",originalTag:Clone())
SSS.NB_NametagService:SetAttribute("NBSourceAssetId","92018365421220")
local motion=RS.NB_Remotes:FindFirstChild("Motion")
if not motion then motion=Instance.new("RemoteEvent") motion.Name="Motion" motion.Parent=RS.NB_Remotes end
local server=SSS:FindFirstChild("NB_MotionService") or Instance.new("Script")
server.Name="NB_MotionService" server.Source=motionSource server.Parent=SSS
local retired={}
for _,name in ipairs({"RoundLoop","JoinHandler","NB_Server","NB_AIController"}) do
 local s=SSS:FindFirstChild(name)
 if s and s:IsA("BaseScript") then local copy=s:Clone() copy.Enabled=false copy.Parent=backup s.Enabled=false table.insert(retired,name) end
end
for _,name in ipairs({"NBClient","NB_Client"}) do
 local s=SPS:FindFirstChild(name)
 if s and s:IsA("BaseScript") then s.Enabled=false table.insert(retired,name) end
end
local commerce=SSS:FindFirstChild("NBServer")
if commerce then
 local copy=commerce:Clone() copy.Enabled=false copy.Parent=backup
 commerce.Source=[====[
local RS=game:GetService("ReplicatedStorage")
local SP=game:GetService("StarterPack")
local shared=RS:WaitForChild("NextbotsBrasil")
local shopRemote=shared:WaitForChild("ShopAction")
local inventoryRemote=shared:WaitForChild("InventoryAction")
shopRemote.OnServerEvent:Connect(function(player,action)
 if action~="GetCola" then return end
 local backpack=player:FindFirstChildOfClass("Backpack")
 if not backpack then return end
 if backpack:FindFirstChild("Cola") or (player.Character and player.Character:FindFirstChild("Cola")) then return end
 local source=SP:FindFirstChild("Cola")
 if source then source:Clone().Parent=backpack end
end)
inventoryRemote.OnServerEvent:Connect(function(player,action)
 if action=="EquipCola" then
  local backpack=player:FindFirstChildOfClass("Backpack")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  local tool=backpack and backpack:FindFirstChild("Cola")
  if hum and tool then hum:EquipTool(tool) end
 end
end)
]====]
 local check=Instance.new("ModuleScript") check.Source="return function()\n"..commerce.Source.."\nend" check.Parent=SS
 local ok,fn=pcall(require,check) check:Destroy() assert(ok and type(fn)=="function","commerce syntax")
end
local sourceFolder=SS:FindFirstChild("NB_SourceAssets") or Instance.new("Folder")
sourceFolder.Name="NB_SourceAssets" sourceFolder.Parent=SS
for id,asset in pairs({["14026023204"]=evade,["92018365421220"]=nametags,["128071741625902"]=studAsset}) do
 for _,d in ipairs(asset:GetDescendants()) do if d:IsA("BaseScript") then d.Enabled=false end end
 replace(sourceFolder,id,asset)
end
result.retiredConflictingScripts=retired
result.backup=backup.Name
AS:SavePlaceAsync()
result.saved=true
return result
