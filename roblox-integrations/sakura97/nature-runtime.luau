local Players=game:GetService("Players")
local SS=game:GetService("ServerStorage")
local CS=game:GetService("CollectionService")
local Terrain=workspace.Terrain

local T=SS:WaitForChild("NatureTemplates")
local Root=workspace:WaitForChild("NatureChunks")
local CHUNK,WORLD_HALF,RADIUS=512,135000,4
local loaded={}

local function matches(inst,words)
 local n=inst.Name:lower()
 for _,w in ipairs(words) do if n:find(w,1,true) then return true end end
 return false
end

local function rejected(inst,words)
 local n=inst.Name:lower()
 for _,w in ipairs(words or {}) do if n:find(w,1,true) then return true end end
 return false
end

local function collectRoots(folder,words,modelOnly,rejectWords)
 local out={}
 for _,d in ipairs(folder:GetDescendants()) do
  local usable=d:IsA("Model") or (not modelOnly and d:IsA("BasePart"))
  if usable and matches(d,words) and not rejected(d,rejectWords) then
   local nested=false
   local p=d.Parent
   while p and p~=folder do
    if (p:IsA("Model") or p:IsA("BasePart")) and matches(p,words) then nested=true break end
    p=p.Parent
   end
   if not nested then
    if d:IsA("BasePart") or d:FindFirstChildWhichIsA("BasePart",true) then table.insert(out,d) end
   end
  end
 end
 return out
end

-- Exact user-provided tree packs. Only complete tree roots are selected, never random branches or leaf fragments.
local trees={}
for _,f in ipairs({T.PBR,T.HD}) do
 for _,x in ipairs(collectRoots(f,{"tree","oak","pine","birch","willow","maple","redwood"},false,{"stump","log","branch","root"})) do
  table.insert(trees,x)
 end
end

local big=collectRoots(T.BigTree,{"large tree decorated","big tree","tree"},true,{"branch"})
if #big==0 then
 for _,d in ipairs(T.BigTree:GetDescendants()) do
  if d:IsA("Model") and d:FindFirstChildWhichIsA("BasePart",true) then table.insert(big,d); break end
 end
end

local rocks=collectRoots(T.Rocks,{"rock","stone","boulder"},false,{"tree","plant","flower"})
local flowers={}
for _,f in ipairs({T.PBR,T.HD}) do
 for _,x in ipairs(collectRoots(f,{"flower","daisy","sunflower","hydrangea","rose","crownbeard","kale","fern"},false,{"bed","brick","holder","furniture"})) do
  table.insert(flowers,x)
 end
end

local butterflies={}
for _,x in ipairs(T.Wildlife:GetChildren()) do
 if x:IsA("Model") and x.Name:find("Butterfly_FlightPath",1,true) then table.insert(butterflies,x) end
end
local officialLeafEmitter=T.LeafFX:FindFirstChildWhichIsA("ParticleEmitter",true)

assert(#trees>0,"no complete trees found in user nature packs")
assert(#big>0,"exact big tree missing")
assert(#rocks>0,"no rocks found in exact Nature Pack")
assert(#butterflies==2,"official flying butterfly templates missing")
assert(officialLeafEmitter,"official leaf particle template missing")

local function cloneStatic(t)
 local x=t:Clone()
 for _,d in ipairs(x:GetDescendants()) do
  if d:IsA("LuaSourceContainer") then d:Destroy()
  elseif d:IsA("BasePart") then
   d.Anchored=true; d.CanCollide=false; d.CanTouch=false; d.CanQuery=false
  end
 end
 if x:IsA("BasePart") then x.Anchored=true; x.CanCollide=false; x.CanTouch=false; x.CanQuery=false end
 return x
end

local function cloneButterfly(t)
 local x=t:Clone()
 for _,d in ipairs(x:GetDescendants()) do
  if d:IsA("BasePart") then
   d.Anchored=true; d.CanCollide=false; d.CanTouch=false; d.CanQuery=false
  elseif d:IsA("BaseScript") then
   d.Enabled=true
  end
 end
 return x
end

local function bounds(x)
 if x:IsA("Model") then
  local ok,cf,size=pcall(function() return x:GetBoundingBox() end)
  if ok then return cf,size end
 elseif x:IsA("BasePart") then
  return x.CFrame,x.Size
 end
 return CFrame.new(),Vector3.new(1,1,1)
end

local function place(x,cf,scale)
 if x:IsA("Model") then
  if scale then pcall(function() x:ScaleTo(x:GetScale()*scale) end) end
  local _,s=bounds(x)
  x:PivotTo(cf*CFrame.new(0,s.Y*.5,0))
 elseif x:IsA("BasePart") then
  if scale then x.Size*=scale end
  x.CFrame=cf*CFrame.new(0,x.Size.Y*.5,0)
 end
end

local function tagWind(tree)
 for _,d in ipairs(tree:GetDescendants()) do
  if d:IsA("BasePart") then
   local n=d.Name:lower()
   local c=d.Color
   local foliage=n:find("leaf",1,true) or n:find("leaves",1,true) or n:find("foliage",1,true) or n:find("canopy",1,true)
    or (c.G>c.R*1.12 and c.G>c.B*1.05 and d.Material~=Enum.Material.Wood and d.Material~=Enum.Material.WoodPlanks)
   if foliage then
    CS:AddTag(d,"WindShake")
    d:SetAttribute("WindPower",.24)
    d:SetAttribute("WindSpeed",13)
   end
  end
 end
end

-- Every placed tree receives the official Roblox Forest Pack falling-leaf emitter.
local function attachRealLeaves(tree,holder)
 if not officialLeafEmitter then return end
 local cf,size=bounds(tree)
 local volume=Instance.new("Part")
 volume.Name="RealLeafFallVolume"
 volume.Anchored=true
 volume.Transparency=1
 volume.CanCollide=false
 volume.CanTouch=false
 volume.CanQuery=false
 volume.Size=Vector3.new(math.clamp(size.X*.72,5,34),math.clamp(size.Y*.22,3,11),math.clamp(size.Z*.72,5,34))
 volume.CFrame=cf*CFrame.new(0,size.Y*.27,0)
 volume.Parent=holder
 local e=officialLeafEmitter:Clone()
 e.Name="RealTreeLeafFall"
 e.Rate=.12
 e.Lifetime=NumberRange.new(6,7)
 e.Speed=NumberRange.new(6,7)
 e.Acceleration=Vector3.new(0,-2,0)
 e.SpreadAngle=Vector2.new(20,20)
 e.Parent=volume
end

local function h(x,z)
 return 5+math.noise(x/2300,z/2300,41)*5+math.noise(x/760,z/760,9)*2
end

-- Broad but shallow Amazon-inspired water. Never deep trenches.
local function river(x,z)
 local primary=math.abs(x-(math.sin(z/3400)*720+math.sin(z/1100)*150))<72
 local branch=math.abs(z-math.sin((x+2200)/4100)*950)<48 and math.abs(x)>1800
 return primary or branch
end
local lakes={{3200,-2600,280},{-4800,3600,390},{7800,5200,330},{-9200,-6300,420}}
local function lake(x,z)
 for _,l in ipairs(lakes) do
  local dx,dz=x-l[1],z-l[2]
  if dx*dx+dz*dz<l[3]*l[3] then return true end
 end
 return false
end

local function generate(cx,cz)
 if math.abs(cx*CHUNK)>WORLD_HALF or math.abs(cz*CHUNK)>WORLD_HALF then return end
 local k=cx..":"..cz
 if loaded[k] then return end
 loaded[k]=true

 local m=Instance.new("Model")
 m.Name="Chunk_"..cx.."_"..cz
 m.Parent=Root

 local rng=Random.new(math.abs((cx*73856093+cz*19349663+11117)%2147483647))
 local x0,z0=cx*CHUNK,cz*CHUNK
 local y=h(x0,z0)
 Terrain:FillBlock(CFrame.new(x0,y-6,z0),Vector3.new(CHUNK+8,12,CHUNK+8),Enum.Material.Grass)

 for ix=-256,256,32 do
  for iz=-256,256,32 do
   local x,z=x0+ix,z0+iz
   if river(x,z) or lake(x,z) then
    local gy=h(x,z)
    local depth=lake(x,z) and 7 or 5
    Terrain:FillBlock(CFrame.new(x,gy-2,z),Vector3.new(36,depth+7,36),Enum.Material.Air)
    Terrain:FillBlock(CFrame.new(x,gy-depth-.5,z),Vector3.new(36,2.5,36),Enum.Material.Sand)
    Terrain:FillBlock(CFrame.new(x,gy-depth*.42,z),Vector3.new(36,math.max(2,depth-2.5),36),Enum.Material.Water)
   end
  end
 end

 if (cx+cz)%7==0 then
  Terrain:FillBlock(CFrame.new(x0,y+.4,z0),Vector3.new(CHUNK,1.2,7),Enum.Material.Ground)
 end

 for i=1,rng:NextInteger(8,13) do
  local x,z=x0+rng:NextNumber(-225,225),z0+rng:NextNumber(-225,225)
  if not river(x,z) and not lake(x,z) then
   local useBig=#big>0 and rng:NextNumber()<.05
   local list=useBig and big or trees
   local q=cloneStatic(list[rng:NextInteger(1,#list)])
   q.Name=useBig and "ExactBigTree" or "NaturePackTree"
   place(q,CFrame.new(x,h(x,z),z)*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0),useBig and rng:NextNumber(.9,1.08) or rng:NextNumber(.82,1.15))
   q.Parent=m
   tagWind(q)
   attachRealLeaves(q,m)
  end
 end

 for i=1,rng:NextInteger(3,6) do
  if #rocks>0 then
   local x,z=x0+rng:NextNumber(-230,230),z0+rng:NextNumber(-230,230)
   if not river(x,z) and not lake(x,z) then
    local q=cloneStatic(rocks[rng:NextInteger(1,#rocks)])
    q.Name="ExactNaturePackRock"
    place(q,CFrame.new(x,h(x,z)-.2,z)*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0),rng:NextNumber(.55,1.25))
    q.Parent=m
   end
  end
 end

 local flowerCenters={}
 if #flowers>0 and rng:NextNumber()<.72 then
  for c=1,rng:NextInteger(1,3) do
   local bx,bz=x0+rng:NextNumber(-200,200),z0+rng:NextNumber(-200,200)
   if not river(bx,bz) and not lake(bx,bz) then table.insert(flowerCenters,Vector3.new(bx,h(bx,bz),bz)) end
   for j=1,rng:NextInteger(2,6) do
    local x,z=bx+rng:NextNumber(-7,7),bz+rng:NextNumber(-7,7)
    if not river(x,z) and not lake(x,z) then
     local q=cloneStatic(flowers[rng:NextInteger(1,#flowers)])
     q.Name="Wildflower"
     place(q,CFrame.new(x,h(x,z),z)*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0),rng:NextNumber(.7,1.05))
     q.Parent=m
    end
   end
  end
 end

 -- Few real animated butterflies, and only around flower clearings.
 if #flowerCenters>0 and #butterflies>0 and rng:NextNumber()<.08 then
  local center=flowerCenters[rng:NextInteger(1,#flowerCenters)]
  local q=cloneButterfly(butterflies[rng:NextInteger(1,#butterflies)])
  q.Name="OfficialAnimatedButterfly"
  q:PivotTo(CFrame.new(center+Vector3.new(rng:NextNumber(-5,5),4+rng:NextNumber(0,2),rng:NextNumber(-5,5))))
  q.Parent=m
 end
end

local function around(pos)
 local cx,cz=math.floor(pos.X/CHUNK+.5),math.floor(pos.Z/CHUNK+.5)
 task.spawn(function()
  for ring=0,RADIUS do
   for x=cx-ring,cx+ring do
    for z=cz-ring,cz+ring do
     if ring==0 or math.abs(x-cx)==ring or math.abs(z-cz)==ring then generate(x,z) end
    end
   end
   task.wait(.03)
  end
 end)
 if math.max(math.abs(pos.X),math.abs(pos.Z))>WORLD_HALF-1800 then
  Terrain:FillBlock(CFrame.new(pos.X,-2,pos.Z),Vector3.new(2400,8,2400),Enum.Material.Water)
 end
end

-- Distant islands remain separated from the mainland.
local islands={{32000,27000,620},{-41000,35000,780},{52000,-46000,900},{-68000,-52000,720}}
for _,v in ipairs(islands) do
 Terrain:FillCylinder(CFrame.new(v[1],-5,v[2]),8,v[3]*1.18,Enum.Material.Water)
 Terrain:FillCylinder(CFrame.new(v[1],-1,v[2]),10,v[3],Enum.Material.Sand)
 Terrain:FillCylinder(CFrame.new(v[1],4,v[2]),10,v[3]*.88,Enum.Material.Grass)
end

local spawn=workspace:WaitForChild("NatureSpawn")
local function hook(p)
 p.RespawnLocation=spawn
 p.CharacterAdded:Connect(function(c)
  local r=c:WaitForChild("HumanoidRootPart")
  c:PivotTo(CFrame.new(0,h(0,0)+5,0))
  while c.Parent do
   around(r.Position)
   if r.Position.Y<-450 then c:PivotTo(CFrame.new(0,h(0,0)+5,0)) end
   task.wait(1.2)
  end
 end)
end
Players.PlayerAdded:Connect(hook)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
around(Vector3.zero)
