local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local L=game:GetService('Lighting')
local player=Players.LocalPlayer
local C=require(RS:WaitForChild('PhotoWorldConfig'))
local templates=RS:WaitForChild('PhotoGroundcover')
local terrain=workspace.Terrain
-- Atmosphere overrides legacy distance fog; the scene uses one fog system.
for _,effect in ipairs(L:GetChildren())do if effect:IsA('Atmosphere')then effect:Destroy()end end
local grade=L:WaitForChild('PhotoGrade')
local folder=Instance.new('Folder');folder.Name='LocalPhotoGroundcover';folder.Parent=workspace
local mobile=Input.TouchEnabled
local LIMIT=mobile and 220 or 300
local RADIUS=mobile and 82 or 104
local CELL=11
local patches={};local failed={}
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={terrain};ray.IgnoreWater=false
local lastCenter=nil
local lastBuild=0
local fading={};local bases={}
local function seed(x,z)return math.abs((x*73856093+z*19349663)%2147483647)end
local function create(name,x,z,scale,color,random)
 local result=workspace:Raycast(Vector3.new(x,150,z),Vector3.new(0,-200,0),ray)
 if not result or result.Material==Enum.Material.Water or result.Normal.Y<.82 then return nil end
 local p=templates[name]:Clone();p.Size*=scale
 local up=result.Normal;local right=Vector3.new(0,0,1):Cross(up).Unit
 local cf=CFrame.fromMatrix(result.Position-up*.15,right,up)
 p.CFrame=cf*CFrame.Angles(0,random:NextNumber(-math.pi,math.pi),0)*CFrame.new(0,p.Size.Y/2,0)
 p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 if color then p.Color=color end
 p.LocalTransparencyModifier=1;p.Parent=folder;fading[p]=os.clock();bases[p]=p.CFrame*CFrame.new(0,-p.Size.Y/2,0);return p
end
local function rebuild(pos)
 local gx,gz=math.floor(pos.X/CELL),math.floor(pos.Z/CELL)
 if lastCenter and lastCenter.X==gx and lastCenter.Y==gz and os.clock()-lastBuild<2 then return end
 lastCenter=Vector2.new(gx,gz);lastBuild=os.clock()
 local choices={};local steps=math.ceil(RADIUS/CELL)
 for dx=-steps,steps do for dz=-steps,steps do
  local ix,iz=gx+dx,gz+dz;local random=Random.new(seed(ix,iz));local x,z=ix*CELL+random:NextNumber(-2,2),iz*CELL+random:NextNumber(-2,2);local d=(x-pos.X)^2+(z-pos.Z)^2
  if d<RADIUS*RADIUS and math.abs(x)<C.Extent-20 and math.abs(z)<C.Extent-20 then table.insert(choices,{ix=ix,iz=iz,x=x,z=z,d=d,key=ix..':'..iz})end
 end end
 table.sort(choices,function(a,b)return a.d<b.d end)
 local desired={};local used=0
 for _,cell in ipairs(choices)do
  if used>=LIMIT then break end
  local h,mat,water,zone=C.surface(cell.x,cell.z)
  if not water and C.pathDistance(cell.x,cell.z)>-.65  then
   local edge=C.pathDistance(cell.x,cell.z)<8
   local count=not edge and (cell.ix+cell.iz)%2==0 and 2 or 1
   if used+count<=LIMIT then desired[cell.key]={cell=cell,zone=zone,count=count,edge=edge};used+=count end
  end
 end
 for key,items in pairs(patches)do if not desired[key]then for _,p in ipairs(items)do fading[p]=nil;bases[p]=nil;p:Destroy()end;patches[key]=nil end end
 local made=0
 for _,cell in ipairs(choices)do
  local data=desired[cell.key]
  if data and not patches[cell.key] and (not failed[cell.key]or os.clock()-failed[cell.key]>4)then
   local random=Random.new(seed(cell.ix,cell.iz));local zone=data.zone;local items={}
   local main=data.edge and 'SmallGrassTuft' or ((zone.id=='Golden' or zone.id=='Sakura')and 'TallGrassPatch' or (zone.id=='BlueAutumn' and 'AutumnLeafCarpet' or 'GrassPatch'))
   local scale=data.edge and random:NextNumber(.9,1.45) or random:NextNumber(.94,1.08)
   local p=create(main,cell.x,cell.z,scale,main~='AutumnLeafCarpet' and zone.grass or nil,random)
   if p then table.insert(items,p)end
   if data.count==2 then
    local extra=zone.id=='BlueAutumn' and 'FernRosette' or (zone.id=='Pond' and ((cell.ix%3==0) and 'WaterIris' or 'FernRosette') or (zone.id=='Sakura' and cell.ix%2==0 and 'LavenderFlowerPatch' or 'WhiteFlowerPatch'))
    local e=create(extra,cell.x+random:NextNumber(-2,2),cell.z+random:NextNumber(-2,2),extra=='FernRosette' and 1.4 or 1,nil,random)
    if e then table.insert(items,e)end
   end
   if #items>0 then patches[cell.key]=items else failed[cell.key]=os.clock()end
   made+=1;if made%8==0 then task.wait()end
  end
 end
 for key in pairs(failed)do if not desired[key]then failed[key]=nil end end
 workspace:SetAttribute('LocalGroundcoverCount',#folder:GetChildren())
end
local function palette(pos,dt)
 local weights={};local sum=0
 local outside=math.max(math.abs(pos.X),math.abs(pos.Z))>620
 local closest=math.huge
 for _,zone in ipairs(C.Zones)do closest=math.min(closest,(pos.X-zone.x)^2+(pos.Z-zone.z)^2)end
 for _,zone in ipairs(C.Zones)do
  local d=(pos.X-zone.x)^2+(pos.Z-zone.z)^2;local w=outside and (zone==C.zone(pos.X,pos.Z)and 1 or 0)or math.exp(-(d-closest)/19500)
  weights[zone]=w;sum+=w
 end
 local clock,fogStart,fogEnd,brightness,exposure,saturation=0,0,0,0,0,0
 local color,tint,grass,water=Vector3.zero,Vector3.zero,Vector3.zero,Vector3.zero
 for zone,w in pairs(weights)do
  w/=math.max(sum,.000001);clock+=zone.clock*w;fogStart+=zone.fogStart*w;fogEnd+=zone.fogEnd*w
  brightness+=zone.brightness*w;exposure+=zone.exposure*w;saturation+=(.065)*w
  color+=Vector3.new(zone.color.R,zone.color.G,zone.color.B)*w
  tint+=Vector3.new(zone.tint.R,zone.tint.G,zone.tint.B)*w
  grass+=Vector3.new(zone.grass.R,zone.grass.G,zone.grass.B)*w
  water+=Vector3.new(zone.water.R,zone.water.G,zone.water.B)*w
 end
 local a=1-math.exp(-dt*.65)
 L.ClockTime+=(clock-L.ClockTime)*a;L.FogStart+=(fogStart-L.FogStart)*a;L.FogEnd+=(fogEnd-L.FogEnd)*a
 L.FogColor=L.FogColor:Lerp(Color3.new(color.X,color.Y,color.Z),a)
 L.Brightness+=(brightness-L.Brightness)*a;L.ExposureCompensation+=(exposure-L.ExposureCompensation)*a
 grade.TintColor=grade.TintColor:Lerp(Color3.new(tint.X,tint.Y,tint.Z),a);grade.Saturation+=(saturation-grade.Saturation)*a
 terrain:SetMaterialColor(Enum.Material.Grass,Color3.new(grass.X,grass.Y,grass.Z))
 terrain.WaterColor=terrain.WaterColor:Lerp(Color3.new(water.X,water.Y,water.Z),a)
 for p,born in pairs(fading)do
  if not p.Parent then fading[p]=nil else
   local d=(Vector2.new(p.Position.X-pos.X,p.Position.Z-pos.Z)).Magnitude
   local distanceFade=math.clamp((d-(RADIUS-20))/20,0,1)
   p.LocalTransparencyModifier=math.max(1-math.clamp((os.clock()-born)/.65,0,1),distanceFade)
  end
 end
end
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.2 then return end
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 if root then palette(root.Position,elapsed)end;elapsed=0
end)
task.spawn(function()
 while script.Parent do
  local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  if root then rebuild(root.Position)end
  task.wait(.55)
 end
end)
player.CharacterAdded:Connect(function()lastCenter=nil end)

local swayTime=0
Run.Heartbeat:Connect(function(dt)
 swayTime+=dt;if swayTime<1/18 then return end;swayTime=0
 local t=os.clock()
 for p,base in pairs(bases)do
  if not p.Parent then bases[p]=nil else
   local phase=base.X*.08+base.Z*.06;local sway=(math.sin(t*1.2+phase)+math.sin(t*.62+phase)*.4)*.022
   p.CFrame=base*CFrame.Angles(sway*.35,0,sway)*CFrame.new(0,p.Size.Y/2,0)
  end
 end
end)
