local W=game:GetService("Workspace")
local T=W.Terrain
local L=game:GetService("Lighting")
local A=game:GetService("AssetService")
for _,v in ipairs(W:GetChildren()) do if v~=T and not v:IsA("Camera") then v:Destroy() end end
T:Clear()
W.GlobalWind=Vector3.new(9,0,4)
T:FillBlock(CFrame.new(0,-18,0),Vector3.new(850,28,850),Enum.Material.Water)
T.WaterColor=Color3.fromRGB(64,104,108)
T.WaterTransparency=.3
T.WaterReflectance=.2
T.WaterWaveSize=.12
T.WaterWaveSpeed=7
local root=Instance.new("Folder",W) root.Name="SakuraIsland"
local trees=Instance.new("Folder",root) trees.Name="CherryTrees"
local stones=Instance.new("Folder",root) stones.Name="StonePath"
local flowers=Instance.new("Folder",root) flowers.Name="Flowers"
local grass=Instance.new("Folder",root) grass.Name="ReactiveGrass"
local function H(x,z)
 local r=math.sqrt((x/285)^2+(z/225)^2)
 return -3+math.clamp(1-r,0,1)*15+math.sin(x/70)*1.8+math.sin(z/88)*1.4
end
for x=-272,272,16 do for z=-216,216,16 do
 if math.sqrt((x/285)^2+(z/225)^2)<1 then T:FillBall(Vector3.new(x,H(x,z)-14,z),22,Enum.Material.Grass) end
end end
pcall(function() T.Decoration=true T.GrassLength=.75 end)
local function P(parent,n,size,cf,c,m)
 local p=Instance.new("Part") p.Name=n p.Size=size p.CFrame=cf p.Color=c p.Material=m or Enum.Material.SmoothPlastic
 p.Anchored=true p.Parent=parent return p
end
for i=1,50 do
 local z=-175+(i-1)*7.1 local x=-24+math.sin(i*.52)*13+math.sin(i*.19)*7
 local p=P(stones,"Stone",Vector3.new(6+(i%3),.5,3.7+(i%2)),CFrame.new(x,H(x,z)+1,z)*CFrame.Angles(0,math.rad(math.sin(i*.8)*25),0),Color3.fromRGB(112,105,98),Enum.Material.Slate)
end
local rng=Random.new(941947)
local placed={}
local function tree(x,z,s)
 local m=Instance.new("Model",trees) m.Name="CherryTree"
 local y=H(x,z) local trunk=P(m,"Trunk",Vector3.new(3*s,18*s,3*s),CFrame.new(x,y+9*s,z),Color3.fromRGB(100,63,43),Enum.Material.Wood)
 for j=1,8 do
  local a=j*math.pi/4+rng:NextNumber(-.25,.25)
  local cx=x+math.cos(a)*rng:NextNumber(5,10)*s local cz=z+math.sin(a)*rng:NextNumber(5,10)*s
  local cy=y+rng:NextNumber(15,24)*s
  local b=P(m,"Blossoms",Vector3.new(rng:NextNumber(9,14),rng:NextNumber(7,11),rng:NextNumber(9,14))*s,CFrame.new(cx,cy,cz),Color3.fromRGB(rng:NextInteger(224,244),rng:NextInteger(145,180),rng:NextInteger(174,204)))
  b.Shape=Enum.PartType.Ball b.CanCollide=false
 end
end
while #placed<27 do
 local x=rng:NextNumber(-230,230) local z=rng:NextNumber(-180,180)
 if math.sqrt((x/245)^2+(z/195)^2)<.9 and math.abs(x)<205 then
  local ok=true
  for _,q in ipairs(placed) do if (Vector2.new(x,z)-q).Magnitude<32 then ok=false end end
  if ok then table.insert(placed,Vector2.new(x,z)) tree(x,z,rng:NextNumber(.85,1.2)) end
 end
end
for i=1,360 do
 local x=rng:NextNumber(-245,245) local z=rng:NextNumber(-190,190)
 if math.sqrt((x/255)^2+(z/200)^2)<.93 then
  local y=H(x,z)+1
  local stem=P(flowers,"Stem",Vector3.new(.1,1,.1),CFrame.new(x,y,z),Color3.fromRGB(70,115,55)) stem.CanCollide=false
  local b=P(flowers,"Flower",Vector3.new(.55,.22,.55),CFrame.new(x,y+.55,z),i%4==0 and Color3.fromRGB(245,237,222) or Color3.fromRGB(224,187,205)) b.Shape=Enum.PartType.Ball b.CanCollide=false
 end
end
for i=1,500 do
 local x=rng:NextNumber(-105,105) local z=rng:NextNumber(-185,185)
 if math.sqrt((x/115)^2+(z/195)^2)<.98 then
  local y=H(x,z)+2
  local b=P(grass,"Blade",Vector3.new(.12,rng:NextNumber(2.5,4.5),.2),CFrame.new(x,y,z)*CFrame.Angles(0,rng:NextNumber(0,6.28),0),Color3.fromRGB(101,128,63),Enum.Material.Grass)
  b.CanCollide=false b:SetAttribute("Rest",b.CFrame)
 end
end
local spawn=Instance.new("SpawnLocation",root) spawn.Name="Spawn" spawn.Size=Vector3.new(7,.5,7) spawn.Transparency=1 spawn.CanCollide=false spawn.Anchored=true spawn.Position=Vector3.new(-24,H(-24,-165)+4,-165)
local s=Instance.new("Script",root) s.Name="ReactiveGrassController"
s.Source=[[
local R=game:GetService("RunService") local P=game:GetService("Players") local G=workspace.SakuraIsland.ReactiveGrass local t=0
R.Heartbeat:Connect(function(dt) t+=dt
 for _,b in ipairs(G:GetChildren()) do
  local r=b:GetAttribute("Rest") if typeof(r)=="CFrame" then
   local d=999
   for _,p in ipairs(P:GetPlayers()) do local q=p.Character and p.Character:FindFirstChild("HumanoidRootPart") if q then d=math.min(d,(Vector2.new(q.Position.X,q.Position.Z)-Vector2.new(r.Position.X,r.Position.Z)).Magnitude) end end
   local press=math.clamp((5-d)/5,0,1) local sway=math.sin(t*2+r.Position.X*.05+r.Position.Z*.04)*.07
   b.CFrame=b.CFrame:Lerp(r*CFrame.Angles(sway+press*.75,0,-.08),math.clamp(dt*(press>0 and 12 or 4),0,1))
  end
 end
end)
]]
root:SetAttribute("WindAssetId",11946229834)
L.ClockTime=18.2 L.Brightness=2.1
local at=Instance.new("Atmosphere",L) at.Density=.25 at.Color=Color3.fromRGB(226,191,182) at.Decay=Color3.fromRGB(124,95,104) at.Haze=1.1
A:SavePlaceAsync()
return{ok=true,trees=#trees:GetChildren(),stones=#stones:GetChildren(),flowers=#flowers:GetChildren(),grass=#grass:GetChildren(),placeId=game.PlaceId}
