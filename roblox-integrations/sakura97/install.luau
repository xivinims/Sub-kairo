-- XN [VOICE] v103 — Brookhaven faithful cleanup
assert(game.GameId==9419478735 and game.PlaceId==79738710219521,"Place errado")

local A=game:GetService("AssetService")
local CS=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local RS=game:GetService("ReplicatedStorage")
local RF=game:GetService("ReplicatedFirst")
local SP=game:GetService("StarterPlayer")
local SSS=game:GetService("ServerScriptService")
local SG=game:GetService("StarterGui")
local Terrain=workspace.Terrain

local MAP_ID=106476929993683
local WIND_ID=11946229834
local HALLOWEEN_ID=12489961338
local VERSION=103

local function load(id)
 local ok,x=pcall(A.LoadAssetAsync,A,id)
 assert(ok and x,"asset "..id.." failed: "..tostring(x))
 return x
end

local function clear(c) for _,x in ipairs(c:GetChildren()) do x:Destroy() end end

-- clean only our place build
for _,x in ipairs(workspace:GetChildren()) do
 if x~=Terrain and not x:IsA("Camera") then x:Destroy() end
end
Terrain:Clear()
clear(SSS); clear(RF); clear(SP.StarterPlayerScripts); clear(SG)
for _,x in ipairs(RS:GetChildren()) do
 if x.Name=="XNRuntime" or x.Name=="SweanRuntime" or x.Name=="SakuraRuntime" or x.Name=="ForestRuntime" then x:Destroy() end
end
clear(Lighting)

local rt=Instance.new("Folder")
rt.Name="XNRuntime"; rt.Parent=RS
rt:SetAttribute("Version",VERSION)
rt:SetAttribute("GameName","XN [VOICE]")
rt:SetAttribute("MapAssetId",MAP_ID)
rt:SetAttribute("Design","FaithfulBrookhavenCleanup")

pcall(function()
 workspace.StreamingEnabled=true
 workspace.StreamingMinRadius=96
 workspace.StreamingTargetRadius=360
end)
workspace.FallenPartsDestroyHeight=-700

-- Load exact map, preserve its original transform and visuals.
local asset=load(MAP_ID)
local source=asset:FindFirstChild("Brookhaven Map",true)
assert(source and source:IsA("Model"),"Brookhaven Map missing")
local map=source:Clone()
map.Name="BrookhavenMap"
map:SetAttribute("AssetId",MAP_ID)
map.Parent=workspace
asset:Destroy()

local originalSpawns={}
local namedSpawns={}
local roads={}
local flatFallback={}
local scriptsRemoved=0
local parts=0

for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("SpawnLocation") then
  table.insert(originalSpawns,d)
 end
 if d:IsA("LuaSourceContainer") then
  scriptsRemoved+=1
 elseif d:IsA("BasePart") then
  parts+=1
  local n=d.Name:lower()
  if not d:IsA("SpawnLocation") and (n:find("spawn",1,true) or n:find("lobby",1,true) or n:find("start",1,true)) then
   table.insert(namedSpawns,d)
  end
  if d.CFrame.UpVector.Y>.93 then
   if n:find("road",1,true) or n:find("street",1,true) or n:find("sidewalk",1,true) then table.insert(roads,d) end
   if d.Size.X*d.Size.Z>1500 then table.insert(flatFallback,d) end
  end
 end
end
assert(parts>13000,"Brookhaven incomplete: "..parts)

-- Remove all embedded free-model code; keep geometry exactly where it came from.
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("LuaSourceContainer") then
  d:Destroy()
 elseif d:IsA("BasePart") then
  d.Anchored=true
  d.CanTouch=false
  pcall(function() if d:IsA("MeshPart") then d.RenderFidelity=Enum.RenderFidelity.Automatic end end)
 end
end

-- Remove only invisible/interaction house-system markers, never reshape the hills/lots.
local removedHouseSystems=0
for _,d in ipairs(map:GetDescendants()) do
 local n=d.Name:lower()
 if n=="001_maphouseteleports" or n=="buyhouse" or n:find("housebutton",1,true) or n:find("plotofland",1,true) then
  removedHouseSystems+=1
  d:Destroy()
 end
end

-- Green ground: no extra geometry. Only give actual large green flat surfaces Grass material.
local green={}
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("BasePart") and d.CFrame.UpVector.Y>.90 and d.Size.X*d.Size.Z>260 then
  local c=d.Color
  local n=d.Name:lower()
  local parent=(d.Parent and d.Parent.Name or ""):lower()
  local greenish=(c.G>c.R*1.10 and c.G>c.B*1.05 and c.G>.18) or d.Material==Enum.Material.Grass
  local foliage=n:find("leaf",1,true) or n:find("bush",1,true) or parent:find("tree",1,true)
  if greenish and not foliage then
   d.Material=Enum.Material.Grass
   CS:AddTag(d,"XNGreenGround")
   table.insert(green,d)
  end
 end
end
assert(#green>=8,"green ground detection failed")

-- Subtle wind, foliage only.
workspace.GlobalWind=Vector3.new(11,0,3.5)
local windTagged=0
for _,d in ipairs(map:GetDescendants()) do
 if d:IsA("BasePart") then
  local n=d.Name:lower()
  local p=(d.Parent and d.Parent.Name or ""):lower()
  local gp=(d.Parent and d.Parent.Parent and d.Parent.Parent.Name or ""):lower()
  local foliage=n:find("leaf",1,true) or n:find("leaves",1,true) or n:find("bush",1,true)
   or p:find("tree",1,true) or gp:find("tree",1,true)
  if foliage and d.Material~=Enum.Material.Wood and d.Material~=Enum.Material.WoodPlanks and d.Size.X*d.Size.Z<1800 then
   CS:AddTag(d,"WindShake")
   d:SetAttribute("WindPower",.22)
   d:SetAttribute("WindSpeed",13)
   windTagged+=1
  end
 end
end
local wa=load(WIND_ID)
local wc=wa:FindFirstChild("WindController",true)
assert(wc and wc:IsA("LocalScript") and wc:FindFirstChild("WindLines") and wc:FindFirstChild("WindShake"),"wind asset invalid")
local wind=wc:Clone(); wind.Name="WindController"; wind:SetAttribute("AssetId",WIND_ID); wind.Parent=SP.StarterPlayerScripts
wa:Destroy()

-- Lighting remains bright and close to the original city look; Halloween is only a slight autumn tint.
Lighting.ClockTime=16.1
Lighting.Brightness=2.35
Lighting.ExposureCompensation=0
Lighting.Ambient=Color3.fromRGB(118,116,120)
Lighting.OutdoorAmbient=Color3.fromRGB(150,148,151)
Lighting.GlobalShadows=true
local at=Instance.new("Atmosphere"); at.Name="XNAtmosphere"; at.Density=.08; at.Offset=.05
at.Color=Color3.fromRGB(210,205,202); at.Decay=Color3.fromRGB(145,133,130); at.Haze=.35; at.Glare=.02; at.Parent=Lighting
local cc=Instance.new("ColorCorrectionEffect"); cc.Name="XNColor"; cc.Contrast=.035; cc.Saturation=-.025
cc.TintColor=Color3.fromRGB(255,244,237); cc.Parent=Lighting

-- Halloween, intentionally sparse. Pumpkins only, on actual green surfaces.
local ha=load(HALLOWEEN_ID)
local pumpkinTemplates={}
for _,d in ipairs(ha:GetDescendants()) do
 if d:IsA("BasePart") and d.Name=="Pumpkin" then
  local p=d:Clone(); p.Anchored=true; p.CanCollide=false; p.CanTouch=false; table.insert(pumpkinTemplates,p)
 end
end
ha:Destroy()
assert(#pumpkinTemplates>0,"pumpkin template missing")
local halloween=Instance.new("Folder"); halloween.Name="XN_Halloween"; halloween:SetAttribute("OnlyPumpkins",true); halloween.Parent=workspace
table.sort(green,function(a,b) return a.Size.X*a.Size.Z>b.Size.X*b.Size.Z end)
local rng=Random.new(10322)
local pumpkinCount=0
for cluster=1,math.min(6,#green) do
 local s=green[cluster]
 local folder=Instance.new("Folder"); folder.Name=string.format("PumpkinCluster_%02d",cluster); folder.Parent=halloween
 for j=1,3 do
  local p=pumpkinTemplates[((pumpkinCount)%#pumpkinTemplates)+1]:Clone()
  local lx=(j-2)*2.4
  local lz=(cluster%2==0 and 1.5 or -1.5)
  local localTop=Vector3.new(math.clamp(lx,-s.Size.X*.35,s.Size.X*.35),s.Size.Y*.5,math.clamp(lz,-s.Size.Z*.35,s.Size.Z*.35))
  local pos=s.CFrame:PointToWorldSpace(localTop)
  p.CFrame=CFrame.new(pos+Vector3.new(0,p.Size.Y*.45,0))*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0)
  p.Parent=folder
  pumpkinCount+=1
 end
end
for _,p in ipairs(pumpkinTemplates) do p:Destroy() end

-- Correct spawn selection: use original map intent first, never highest surface raycast.
local mapCF,mapSize=map:GetBoundingBox()
local chosen=nil
local sourceType=""
local sourceName=""

local function validPart(p)
 return p and p.Parent and p:IsA("BasePart")
end

if #originalSpawns>0 then
 table.sort(originalSpawns,function(a,b)
  local da=(Vector2.new(a.Position.X-mapCF.Position.X,a.Position.Z-mapCF.Position.Z)).Magnitude
  local db=(Vector2.new(b.Position.X-mapCF.Position.X,b.Position.Z-mapCF.Position.Z)).Magnitude
  return da<db
 end)
 chosen=originalSpawns[1]; sourceType="OriginalSpawnLocation"; sourceName=chosen.Name
elseif #namedSpawns>0 then
 table.sort(namedSpawns,function(a,b)
  local da=(Vector2.new(a.Position.X-mapCF.Position.X,a.Position.Z-mapCF.Position.Z)).Magnitude
  local db=(Vector2.new(b.Position.X-mapCF.Position.X,b.Position.Z-mapCF.Position.Z)).Magnitude
  return da<db
 end)
 chosen=namedSpawns[1]; sourceType="NamedSpawn"; sourceName=chosen.Name
elseif #roads>0 then
 table.sort(roads,function(a,b)
  local da=(Vector2.new(a.Position.X-mapCF.Position.X,a.Position.Z-mapCF.Position.Z)).Magnitude
  local db=(Vector2.new(b.Position.X-mapCF.Position.X,b.Position.Z-mapCF.Position.Z)).Magnitude
  return da<db
 end)
 chosen=roads[1]; sourceType="RoadFallback"; sourceName=chosen.Name
else
 table.sort(flatFallback,function(a,b)
  local da=(Vector2.new(a.Position.X-mapCF.Position.X,a.Position.Z-mapCF.Position.Z)).Magnitude
  local db=(Vector2.new(b.Position.X-mapCF.Position.X,b.Position.Z-mapCF.Position.Z)).Magnitude
  if math.abs(da-db)<1 then return a.Position.Y<b.Position.Y end
  return da<db
 end)
 chosen=flatFallback[1]; sourceType="FlatFallback"; sourceName=chosen and chosen.Name or ""
end
assert(validPart(chosen),"no reliable spawn source")

local spawn=Instance.new("SpawnLocation")
spawn.Name="XNSpawn"
spawn.Size=Vector3.new(8,.5,8)
spawn.Transparency=1
spawn.CanCollide=false
spawn.CanTouch=false
spawn.Anchored=true
spawn.Neutral=true
spawn.Enabled=true
spawn.Duration=0
spawn.CFrame=CFrame.new(chosen.Position+chosen.CFrame.UpVector*(chosen.Size.Y*.5+3.2))
spawn:SetAttribute("SourceType",sourceType)
spawn:SetAttribute("SourceName",sourceName)
spawn:SetAttribute("SourcePosition",chosen.Position)
spawn.Parent=workspace

rt:SetAttribute("ScriptsRemoved",scriptsRemoved)
rt:SetAttribute("MapParts",parts)
rt:SetAttribute("GreenGround",#green)
rt:SetAttribute("WindTagged",windTagged)
rt:SetAttribute("Pumpkins",pumpkinCount)
rt:SetAttribute("SpawnSourceType",sourceType)
rt:SetAttribute("SpawnSourceName",sourceName)
rt:SetAttribute("HouseSystemsRemoved",removedHouseSystems)

-- Clean fullscreen loading. Player camera remains Classic and freely rotatable.
local loader=Instance.new("LocalScript")
loader.Name="XNLoading"
loader.Source=[[
local RF=game:GetService("ReplicatedFirst")
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
RF:RemoveDefaultLoadingScreen()
local player=Players.LocalPlayer
player.CameraMode=Enum.CameraMode.Classic

local gui=Instance.new("ScreenGui")
gui.Name="XNLoading"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=10000

local bg=Instance.new("Frame")
bg.Size=UDim2.fromScale(1,1)
bg.BorderSizePixel=0
bg.BackgroundColor3=Color3.fromRGB(8,8,10)
bg.Parent=gui

local txt=Instance.new("TextLabel")
txt.AnchorPoint=Vector2.new(.5,.5)
txt.Position=UDim2.fromScale(.5,.5)
txt.Size=UDim2.new(.7,0,0,54)
txt.BackgroundTransparency=1
txt.Text="acessando…"
txt.TextColor3=Color3.fromRGB(240,240,244)
txt.TextSize=26
txt.Font=Enum.Font.BuilderSans
txt.Parent=bg

gui.Parent=player:WaitForChild("PlayerGui")

-- Short restrained glitch, not a flashing effect.
for i=1,10 do
 local dx=((i%3)-1)*2
 txt.Position=UDim2.new(.5,dx,.5,(i%2==0) and 1 or -1)
 txt.TextTransparency=(i==4 or i==8) and .18 or 0
 task.wait(.055)
end
txt.Position=UDim2.fromScale(.5,.5)
txt.TextTransparency=0

if not game:IsLoaded() then game.Loaded:Wait() end
local char=player.Character or player.CharacterAdded:Wait()
char:WaitForChild("HumanoidRootPart")

local oldMin,oldMax=player.CameraMinZoomDistance,player.CameraMaxZoomDistance
player.CameraMinZoomDistance=.5
player.CameraMaxZoomDistance=.55
task.wait(.12)
for z=.55,10,.52 do
 player.CameraMinZoomDistance=z
 player.CameraMaxZoomDistance=z+.08
 RunService.RenderStepped:Wait()
end
player.CameraMinZoomDistance=oldMin
player.CameraMaxZoomDistance=oldMax

TweenService:Create(txt,TweenInfo.new(.22),{TextTransparency=1}):Play()
local fade=TweenService:Create(bg,TweenInfo.new(.34),{BackgroundTransparency=1})
fade:Play(); fade.Completed:Wait()
gui:Destroy()
]]
loader.Parent=RF

local server=Instance.new("Script")
server.Name="XNServer"
server.Source=[[
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("XNSpawn")
local function protect(c)
 task.spawn(function()
  while c.Parent do
   local root=c:FindFirstChild("HumanoidRootPart")
   if root and root.Position.Y<workspace.FallenPartsDestroyHeight+40 then c:PivotTo(spawn.CFrame*CFrame.new(0,4,0)) end
   task.wait(.6)
  end
 end)
end
local function hook(p)
 p.RespawnLocation=spawn
 p.CharacterAdded:Connect(protect)
 if p.Character then protect(p.Character) end
end
Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
]]
server.Parent=SSS

return {
 version=VERSION,
 mapParts=parts,
 scriptsRemoved=scriptsRemoved,
 greenGround=#green,
 windTagged=windTagged,
 pumpkins=pumpkinCount,
 spawnSourceType=sourceType,
 spawnSourceName=sourceName
}
