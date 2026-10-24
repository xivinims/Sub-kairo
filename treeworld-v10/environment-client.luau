local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local L=game:GetService('Lighting')
local player=Players.LocalPlayer
local C=require(RS:WaitForChild('PhotoWorldConfig'))
local templates=RS:WaitForChild('PhotoGroundcover')
local terrain=workspace.Terrain
local atmosphere=L:WaitForChild('PhotoAtmosphere')
local grade=L:WaitForChild('PhotoGrade')
local folder=Instance.new('Folder');folder.Name='LocalPhotoGroundcover';folder.Parent=workspace
local mobile=Input.TouchEnabled
local LIMIT=mobile and 190 or 280
local RADIUS=mobile and 78 or 105
local CELL=13
local patches={};local failed={}
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={terrain};ray.IgnoreWater=false
local lastCenter=nil
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
 p.Parent=folder;return p
end
local function rebuild(pos)
 local gx,gz=math.floor(pos.X/CELL),math.floor(pos.Z/CELL)
 if lastCenter and lastCenter.X==gx and lastCenter.Y==gz then return end
 lastCenter=Vector2.new(gx,gz)
 local choices={};local steps=math.ceil(RADIUS/CELL)
 for dx=-steps,steps do for dz=-steps,steps do
  local ix,iz=gx+dx,gz+dz;local x,z=ix*CELL,iz*CELL;local d=(x-pos.X)^2+(z-pos.Z)^2
  if d<RADIUS*RADIUS and math.abs(x)<620 and math.abs(z)<620 then table.insert(choices,{ix=ix,iz=iz,x=x,z=z,d=d,key=ix..':'..iz})end
 end end
 table.sort(choices,function(a,b)return a.d<b.d end)
 local desired={};local used=0
 for _,cell in ipairs(choices)do
  if used>=LIMIT then break end
  local h,mat,water,zone=C.surface(cell.x,cell.z)
  if not water and C.pathDistance(cell.x,cell.z)>6 and zone.id~='Monolith' then
   local count=(cell.ix+cell.iz)%3==0 and 2 or 1
   if used+count<=LIMIT then desired[cell.key]={cell=cell,zone=zone,count=count};used+=count end
  end
 end
 for key,items in pairs(patches)do if not desired[key]then for _,p in ipairs(items)do p:Destroy()end;patches[key]=nil end end
 local made=0
 for _,cell in ipairs(choices)do
  local data=desired[cell.key]
  if data and not patches[cell.key] and (not failed[cell.key]or os.clock()-failed[cell.key]>4)then
   local random=Random.new(seed(cell.ix,cell.iz));local zone=data.zone;local items={}
   local main=(zone.id=='Golden' or zone.id=='Sakura')and 'TallGrassPatch' or (zone.id=='BlueAutumn' and 'AutumnUnderstory' or 'GrassPatch')
   local scale=main=='AutumnUnderstory' and 2.7 or 1
   local p=create(main,cell.x,cell.z,scale,main~='AutumnUnderstory' and zone.grass or nil,random)
   if p then table.insert(items,p)end
   if data.count==2 then
    local extra=zone.id=='BlueAutumn' and 'FernRosette' or (zone.id=='Pond' and 'CloverPatch' or (zone.id=='Sakura' and cell.ix%2==0 and 'LavenderFlowerPatch' or 'WhiteFlowerPatch'))
    local e=create(extra,cell.x+random:NextNumber(-2,2),cell.z+random:NextNumber(-2,2),extra=='FernRosette' and 1.4 or 1,nil,random)
    if e then table.insert(items,e)end
   end
   if #items>0 then patches[cell.key]=items else failed[cell.key]=os.clock()end
   made+=1;if made%8==0 then task.wait()end
  end
 end
 workspace:SetAttribute('LocalGroundcoverCount',#folder:GetChildren())
end
local function palette(pos,dt)
 local weights={};local sum=0
 for _,zone in ipairs(C.Zones)do
  local d=math.sqrt((pos.X-zone.x)^2+(pos.Z-zone.z)^2)
  local w=math.exp(-d*d/19500);weights[zone]=w;sum+=w
 end
 local clock,density,haze=0,0,0;local color,tint,grass=Vector3.zero,Vector3.zero,Vector3.zero
 for zone,w in pairs(weights)do
  w/=math.max(sum,.000001);clock+=zone.clock*w;density+=zone.density*w;haze+=zone.haze*w
  color+=Vector3.new(zone.color.R,zone.color.G,zone.color.B)*w
  tint+=Vector3.new(zone.tint.R,zone.tint.G,zone.tint.B)*w
  grass+=Vector3.new(zone.grass.R,zone.grass.G,zone.grass.B)*w
 end
 local a=math.min(1,dt*.8)
 L.ClockTime+=(clock-L.ClockTime)*a
 atmosphere.Density+=(density-atmosphere.Density)*a;atmosphere.Haze+=(haze-atmosphere.Haze)*a
 atmosphere.Color=atmosphere.Color:Lerp(Color3.new(color.X,color.Y,color.Z),a)
 grade.TintColor=grade.TintColor:Lerp(Color3.new(tint.X,tint.Y,tint.Z),a)
 terrain:SetMaterialColor(Enum.Material.Grass,Color3.new(grass.X,grass.Y,grass.Z))
 local zone=C.zone(pos.X,pos.Z)
 grade.Saturation=zone.id=='Monolith' and -.2 or .07
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
