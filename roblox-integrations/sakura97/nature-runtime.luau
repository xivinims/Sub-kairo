local Players=game:GetService("Players")
local SS=game:GetService("ServerStorage")
local CS=game:GetService("CollectionService")
local Terrain=workspace.Terrain
local T=SS:WaitForChild("NatureTemplates")
local Root=workspace:WaitForChild("NatureChunks")
local CHUNK,WORLD_HALF,RADIUS=512,135000,2
local loaded={}
local function collect(folder,words)
 local out={}
 for _,d in ipairs(folder:GetDescendants()) do
  if d:IsA("Model") or d:IsA("BasePart") then
   local n=d.Name:lower()
   for _,w in ipairs(words) do if n:find(w,1,true) and (d:IsA("BasePart") or d:FindFirstChildWhichIsA("BasePart",true)) then table.insert(out,d); break end end
  end
 end
 return out
end
local trees={}
for _,f in ipairs({T.PBR,T.HD}) do for _,x in ipairs(collect(f,{"tree","oak","pine","birch"})) do table.insert(trees,x) end end
local big=collect(T.BigTree,{"tree","model","part"})
if #big==0 then for _,x in ipairs(T.BigTree:GetChildren()) do table.insert(big,x) end end
local rocks=collect(T.Rocks,{"rock","stone","boulder"})
if #rocks==0 then for _,x in ipairs(T.Rocks:GetChildren()) do if x:IsA("Model") or x:IsA("BasePart") then table.insert(rocks,x) end end end
local flowers={}
for _,f in ipairs({T.PBR,T.HD}) do for _,x in ipairs(collect(f,{"flower","daisy","fern","plant"})) do table.insert(flowers,x) end end
local butterflies={}
for _,x in ipairs(T.Butterfly:GetChildren()) do if x:IsA("Model") or x:IsA("BasePart") then table.insert(butterflies,x) end end
local function clone(t)
 local x=t:Clone()
 for _,d in ipairs(x:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored=true; d.CanCollide=false; d.CanTouch=false; d.CanQuery=false end end
 if x:IsA("BasePart") then x.Anchored=true; x.CanCollide=false; x.CanTouch=false; x.CanQuery=false end
 return x
end
local function place(x,cf,scale)
 if x:IsA("Model") then
  if scale then pcall(function() x:ScaleTo(x:GetScale()*scale) end) end
  local ok,_,s=pcall(function() return x:GetBoundingBox() end)
  x:PivotTo(ok and cf*CFrame.new(0,s.Y*.5,0) or cf)
 elseif x:IsA("BasePart") then
  if scale then x.Size*=scale end
  x.CFrame=cf*CFrame.new(0,x.Size.Y*.5,0)
 end
end
local function h(x,z) return 5+math.noise(x/2300,z/2300,41)*5+math.noise(x/760,z/760,9)*2 end
local function river(x,z) return math.abs(x-(math.sin(z/3400)*720+math.sin(z/1100)*150))<34 or (math.abs(z-math.sin((x+2200)/4100)*950)<27 and math.abs(x)>1800) end
local lakes={{3200,-2600,280},{-4800,3600,390},{7800,5200,330},{-9200,-6300,420}}
local function lake(x,z)
 for _,l in ipairs(lakes) do local dx,dz=x-l[1],z-l[2]; if dx*dx+dz*dz<l[3]*l[3] then return true end end
 return false
end
local function leaf(tree)
 local canopy
 for _,d in ipairs(tree:GetDescendants()) do
  if d:IsA("MeshPart") then local n=d.Name:lower(); if n:find("leaf",1,true) or n:find("foliage",1,true) then if not canopy or d.Position.Y>canopy.Position.Y then canopy=d end end end
 end
 if not canopy or canopy.TextureID=="" then return end
 CS:AddTag(canopy,"WindShake"); canopy:SetAttribute("WindPower",.23); canopy:SetAttribute("WindSpeed",13)
 local p=Instance.new("ParticleEmitter"); p.Name="RealTreeLeafFall"; p.Texture=canopy.TextureID; p.Rate=.16; p.Lifetime=NumberRange.new(5,8); p.Speed=NumberRange.new(.4,1.4)
 p.Acceleration=Vector3.new(0,-2.1,0); p.Drag=1.2; p.WindAffectsDrag=true; p.Rotation=NumberRange.new(0,360); p.RotSpeed=NumberRange.new(-70,70)
 p.Size=NumberSequence.new(.2); p.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.88,.18),NumberSequenceKeypoint.new(1,1)}); p.SpreadAngle=Vector2.new(30,30); p.Parent=canopy
end
local function generate(cx,cz)
 if math.abs(cx*CHUNK)>WORLD_HALF or math.abs(cz*CHUNK)>WORLD_HALF then return end
 local k=cx..":"..cz; if loaded[k] then return end; loaded[k]=true
 local m=Instance.new("Model"); m.Name="Chunk_"..cx.."_"..cz; m.Parent=Root
 local rng=Random.new(math.abs((cx*73856093+cz*19349663+11017)%2147483647))
 local x0,z0=cx*CHUNK,cz*CHUNK; local y=h(x0,z0)
 Terrain:FillBlock(CFrame.new(x0,y-6,z0),Vector3.new(CHUNK+8,12,CHUNK+8),Enum.Material.Grass)
 for ix=-256,256,32 do for iz=-256,256,32 do
  local x,z=x0+ix,z0+iz
  if river(x,z) or lake(x,z) then
   local gy=h(x,z); local depth=lake(x,z) and 9 or 7
   Terrain:FillBlock(CFrame.new(x,gy-2,z),Vector3.new(36,depth+8,36),Enum.Material.Air)
   Terrain:FillBlock(CFrame.new(x,gy-depth-1,z),Vector3.new(36,3,36),Enum.Material.Sand)
   Terrain:FillBlock(CFrame.new(x,gy-depth*.48,z),Vector3.new(36,depth-3,36),Enum.Material.Water)
  end
 end end
 if (cx+cz)%7==0 then Terrain:FillBlock(CFrame.new(x0,y+.4,z0),Vector3.new(CHUNK,1.2,7),Enum.Material.Ground) end
 for i=1,rng:NextInteger(7,12) do
  local x,z=x0+rng:NextNumber(-225,225),z0+rng:NextNumber(-225,225)
  if not river(x,z) and not lake(x,z) then
   local useBig=#big>0 and rng:NextNumber()<.035; local list=useBig and big or trees
   if #list>0 then local q=clone(list[rng:NextInteger(1,#list)]); q.Name=useBig and "GiantTree" or "Tree"; q.Parent=m; place(q,CFrame.new(x,h(x,z),z)*CFrame.Angles(0,rng:NextNumber(0,6.283),0),useBig and rng:NextNumber(.8,1.08) or rng:NextNumber(.78,1.2)); leaf(q) end
  end
 end
 for i=1,rng:NextInteger(3,6) do if #rocks>0 then
  local x,z=x0+rng:NextNumber(-230,230),z0+rng:NextNumber(-230,230); local q=clone(rocks[rng:NextInteger(1,#rocks)]); q.Name="NaturePackRock"; q.Parent=m; place(q,CFrame.new(x,h(x,z)-.2,z)*CFrame.Angles(0,rng:NextNumber(0,6.283),0),rng:NextNumber(.55,1.25))
 end end
 if #flowers>0 and rng:NextNumber()<.72 then for c=1,rng:NextInteger(1,3) do
  local bx,bz=x0+rng:NextNumber(-200,200),z0+rng:NextNumber(-200,200)
  for j=1,rng:NextInteger(2,6) do local x,z=bx+rng:NextNumber(-7,7),bz+rng:NextNumber(-7,7); if not river(x,z) then local q=clone(flowers[rng:NextInteger(1,#flowers)]); q.Name="Wildflower"; q.Parent=m; place(q,CFrame.new(x,h(x,z),z)*CFrame.Angles(0,rng:NextNumber(0,6.283),0),rng:NextNumber(.7,1.05)) end end
 end end
 if #butterflies>0 and rng:NextNumber()<.16 then
  local q=clone(butterflies[rng:NextInteger(1,#butterflies)]); q.Name="Butterfly"; q.Parent=m
  local bx,bz=x0+rng:NextNumber(-170,170),z0+rng:NextNumber(-170,170); local by=h(bx,bz)+5; place(q,CFrame.new(bx,by,bz),.15)
  task.spawn(function() local t=rng:NextNumber(0,20); while q.Parent do t+=.05; local a=Vector3.new(bx+math.sin(t*.73)*12,by+math.sin(t*1.9)*1.6,bz+math.cos(t*.61)*10); local b=Vector3.new(bx+math.sin((t+.06)*.73)*12,by+math.sin((t+.06)*1.9)*1.6,bz+math.cos((t+.06)*.61)*10); if q:IsA("Model") then q:PivotTo(CFrame.lookAt(a,b)) else q.CFrame=CFrame.lookAt(a,b) end; task.wait(.05) end end)
 end
end
local function around(pos)
 local cx,cz=math.floor(pos.X/CHUNK+.5),math.floor(pos.Z/CHUNK+.5)
 for x=cx-RADIUS,cx+RADIUS do for z=cz-RADIUS,cz+RADIUS do generate(x,z) end end
 if math.max(math.abs(pos.X),math.abs(pos.Z))>WORLD_HALF-1800 then Terrain:FillBlock(CFrame.new(pos.X,-2,pos.Z),Vector3.new(2400,8,2400),Enum.Material.Water) end
end
local islands={{32000,27000,620},{-41000,35000,780},{52000,-46000,900},{-68000,-52000,720}}
for _,v in ipairs(islands) do Terrain:FillCylinder(CFrame.new(v[1],-5,v[2]),8,v[3]*1.18,Enum.Material.Water); Terrain:FillCylinder(CFrame.new(v[1],-1,v[2]),10,v[3],Enum.Material.Sand); Terrain:FillCylinder(CFrame.new(v[1],4,v[2]),10,v[3]*.88,Enum.Material.Grass) end
local spawn=workspace:WaitForChild("NatureSpawn")
local function hook(p)
 p.RespawnLocation=spawn
 p.CharacterAdded:Connect(function(c) local r=c:WaitForChild("HumanoidRootPart"); c:PivotTo(CFrame.new(0,h(0,0)+5,0)); while c.Parent do around(r.Position); if r.Position.Y<-450 then c:PivotTo(CFrame.new(0,h(0,0)+5,0)) end; task.wait(1.5) end end)
end
Players.PlayerAdded:Connect(hook); for _,p in ipairs(Players:GetPlayers()) do hook(p) end; around(Vector3.zero)
