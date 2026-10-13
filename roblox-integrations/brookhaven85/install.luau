assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==84,"Published world changed")
local runtime=game.ReplicatedStorage.SerenaRuntime
local function source(parent,class,name,code)
 local old=parent:FindFirstChild(name)local s=Instance.new(class)s.Name=name s.Source=code
 if old then for _,child in ipairs(old:GetChildren())do child.Parent=s end old:Destroy()end s.Parent=parent return s
end
local function factory(code)
 local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v
end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local geometry=factory([============[local Builder={}
local Collection=game:GetService("CollectionService")
local Asset=game:GetService("AssetService")
local function clean(asset)
 local removed=0
 for _,d in ipairs(asset:GetDescendants())do
  if d:IsA("LuaSourceContainer")or d:IsA("Camera")or d:IsA("RemoteEvent")or d:IsA("RemoteFunction")or d:IsA("ObjectValue")then d:Destroy()removed+=1 end
 end return removed
end
local function bounds(model)
 local lo=Vector3.new(math.huge,math.huge,math.huge)local hi=-lo
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(q)hi=hi:Max(q)
  end end end
 end end return lo,hi
end
local function green(p)return p.Material==Enum.Material.Grass or(p.Color.G>p.Color.R*1.22 and p.Color.G>p.Color.B*1.12)end
local function foliage(p,city)
 local a=p.Parent
 while a and a~=city do local n=a.Name:lower()if n:find("tree",1,true)or n:find("bush",1,true)or n:find("flower",1,true)then return true end a=a.Parent end
 return false
end
local function part(parent,name,size,cf,material,color,alpha,collide)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.Material=material or Enum.Material.Plastic
 p.Color=color or Color3.fromRGB(110,145,103)p.Transparency=alpha or 0 p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.Parent=parent return p
end
local function groundRay(city)
 local r=RaycastParams.new()r.FilterType=Enum.RaycastFilterType.Include r.FilterDescendantsInstances={city,workspace.Terrain}r.RespectCanCollide=true
 return function(x,z)return workspace:Raycast(Vector3.new(x,450,z),Vector3.new(0,-700,0),r)end
end
local function normalize(m)
 local lo,hi=bounds(m)local origin=Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2)
 m:PivotTo(m:GetPivot()-origin)return hi-lo
end
function Builder.install()
 assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==84,"Wrong world base")
 local rawCity=Asset:LoadAssetAsync(115377891476033)
 local rawPack=Asset:LoadAssetAsync(128071741625902)
 local rawTags=Asset:LoadAssetAsync(92018365421220)
 local old=workspace.IlhaSerena local npc=old.Viajante:Clone()
 local removed=clean(rawCity)+clean(rawPack)
 -- Retain the exact nametag artwork before removing its default account settings.
 local tagTemplate=rawTags:FindFirstChild("Nametag",true):Clone()
 removed+=clean(rawTags)tagTemplate.Name="SerenaNametagTemplate"tagTemplate:SetAttribute("SourceAssetId",92018365421220)
 tagTemplate.MaxDistance=65 tagTemplate.AlwaysOnTop=false tagTemplate.StudsOffset=Vector3.new(0,2.6,0)
 tagTemplate.Size=UDim2.fromOffset(220,68)
 for _,label in ipairs(tagTemplate:GetDescendants())do if label:IsA("TextLabel")then label.Text=""label.RichText=false label.TextWrapped=true end end
 local oldTag=game.ReplicatedStorage.SerenaTemplates:FindFirstChild(tagTemplate.Name)if oldTag then oldTag:Destroy()end
 tagTemplate.Parent=game.ReplicatedStorage.SerenaTemplates rawTags:Destroy()
 local city=rawCity:FindFirstChildOfClass("Model")assert(city and #city:GetDescendants()>5000,"Brookhaven base is incomplete")
 city.Parent=nil rawCity:Destroy()city.Name="BrookhavenStudCity"
 local pack=rawPack:FindFirstChild("Stud pack V1")assert(pack,"Stud Pack missing")
 local shopTemplate=pack.Shop:Clone()shopTemplate.Name="LojaStud"
 local treeTemplates={pack.Tree1:Clone(),pack.Tree2:Clone()}local flowerTemplate=pack.Flowers:Clone()
 local rockTemplates={}for _,d in ipairs(pack:GetChildren())do if d:IsA("Model")and d.Name=="Rock"then rockTemplates[#rockTemplates+1]=d:Clone()end end
 local textureFolder=pack:FindFirstChild("Texture PLS Use")assert(textureFolder and textureFolder.Studs,"Stud material missing")
 local variants={}for _,v in ipairs(textureFolder:GetChildren())do if v:IsA("MaterialVariant")then
  local copy=v:Clone()copy.Name="SerenaStud_"..v.Name local existing=game.MaterialService:FindFirstChild(copy.Name)if existing then existing:Destroy()end
  copy.Parent=game.MaterialService variants[v.Name]=copy
 end end
 local lighting=pack:FindFirstChild("EXTRA Lighting")
 local sky=lighting:FindFirstChildOfClass("Sky"):Clone()sky.Name="SerenaStudSky"
 for _,d in ipairs(game.Lighting:GetChildren())do if d:IsA("Sky")then d:Destroy()end end sky.Parent=game.Lighting
 local names={Atmosphere="SerenaAtmosphere",BloomEffect="SerenaBloom",SunRaysEffect="SerenaSunRays",ColorCorrectionEffect="SerenaColor"}
 for class,name in pairs(names)do
  local existing=game.Lighting:FindFirstChild(name)
  if not existing then local original=lighting:FindFirstChildOfClass(class)local copy=original and original:Clone()or Instance.new(class)copy.Name=name copy.Parent=game.Lighting end
 end
 rawPack:Destroy()
 local attributes=old:GetAttributes()old:Destroy()workspace.Terrain:Clear()
 local world=Instance.new("Model")world.Name="IlhaSerena"world.Parent=workspace
 for k,v in pairs(attributes)do world:SetAttribute(k,v)end
 for _,name in ipairs({"HiddenIslandAssetId","IslandCount","PublicIslandCount","BridgeStoneAssetId","SecretSpawnCF","BoatHome","DockExitCF","FountainWaterY","FountainOrigin"})do world:SetAttribute(name,nil)end
 world:SetAttribute("WorldLayout","BrookhavenStudCity")world:SetAttribute("MapAssetId",115377891476033)world:SetAttribute("ThemeAssetId",128071741625902)
 world:SetAttribute("NametagAssetId",92018365421220)world:SetAttribute("UpgradeVersion",85)world:SetAttribute("WindAnimationScale",.9)
 world:SetAttribute("AdminUserId",8344738123)
 -- The established include-filter contract now contains only the new city.
 local geometry=Instance.new("Folder")geometry.Name="Islands"geometry.Parent=world
 local props=Instance.new("Folder")props.Name="Props"props.Parent=world
 city:PivotTo(city:GetPivot()-Vector3.new(0,33.3,0))city.Parent=geometry city:SetAttribute("SourceAssetId",115377891476033)
 local terrainVolumes=0 local groundCount=0 local themed=0 local seats=0 local doorCount=0
 local grassColor=workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
 for _,p in ipairs(city:GetDescendants())do
  if p:IsA("BasePart")then
   p.Anchored=true p.CanTouch=p:IsA("Seat")or p:IsA("VehicleSeat")
   if p.Name=="Water Block"then
    workspace.Terrain:FillBlock(p.CFrame,p.Size,Enum.Material.Water)terrainVolumes+=1 p:Destroy()
   elseif p:IsA("SpawnLocation")then p.Enabled=false p.Neutral=true p.Duration=0 p.Transparency=1 p.CanCollide=false p.CanQuery=false
   else
    local isFoliage=foliage(p,city)
    if isFoliage then p.CanCollide=false p.CanQuery=false
    elseif green(p)and p.Size.X*p.Size.Z>16 and(p.Parent==city or p.Material==Enum.Material.Grass)then
     p:SetAttribute("SerenaGrassSurface",true)p:SetAttribute("SerenaGroundSurface",true)p.Color=grassColor groundCount+=1
    end
    if p:IsA("Seat")or p:IsA("VehicleSeat")then seats+=1 end
    local retain=p.Material==Enum.Material.Glass or p.Material==Enum.Material.Neon or p.Material==Enum.Material.Water or p.Transparency>.2
    if not retain then
     local variant=variants.Studs p.Material=variant.BaseMaterial p.MaterialVariant=variant.Name
     if p:IsA("Part")then p.TopSurface=Enum.SurfaceType.Studs p.BottomSurface=Enum.SurfaceType.Smooth end
     p.CastShadow=true themed+=1 p:SetAttribute("SerenaStudThemed",true)
    end
   end
  elseif p:IsA("Light")then p.Shadows=true p:SetAttribute("SerenaStreetLight",true)
  elseif p:IsA("TextBox")then p.TextEditable=false p.ClearTextOnFocus=false end
 end
 -- Large natural tree meshes are replaced with the actual block-built pack trees.
 local ray=groundRay(city)local trees=0
 for _,m in ipairs(city:GetChildren())do if m:IsA("Model")and m.Name:lower():find("tree",1,true)then
  local cf,size=m:GetBoundingBox()
  if size.Y>10 then
   local h=ray(cf.X,cf.Z)
   if h and h.Material~=Enum.Material.Water and h.Normal.Y>.35 then
    trees+=1 local copy=treeTemplates[trees%2+1]:Clone()normalize(copy)
    copy:ScaleTo(math.clamp(size.Y/26,.8,1.8))copy:PivotTo(CFrame.new(h.Position-Vector3.new(0,.025,0))*CFrame.Angles(0,trees*2.4,0))
    copy.Name="ArvoreStud"..trees copy:SetAttribute("SourceAssetId",128071741625902)copy:SetAttribute("SerenaAdminMovable",true)
    copy.ModelStreamingMode=Enum.ModelStreamingMode.Atomic copy.Parent=props Collection:AddTag(copy,"SerenaAdminMovable")
    for _,p in ipairs(copy:GetDescendants())do if p:IsA("BasePart")then
     p.Anchored=true p.CanTouch=false p.CanCollide=false p.CanQuery=not green(p)
     if green(p)then p:SetAttribute("SerenaRestCF",p.CFrame)Collection:AddTag(p,"SerenaWindFoliage")end
    end end m:Destroy()
   end
  end
 end end
 for _,m in ipairs(city:GetChildren())do if m:IsA("Model")then
  local n=m.Name:lower()
  if n=="door"or n:find("hospitaldoors",1,true)or n:find("doorclassroom",1,true)or n=="firedoor"or n:find("meshdoor",1,true)then
   local panel local largest=0
   for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p.Transparency<1 then local volume=p.Size.X*p.Size.Y*p.Size.Z if volume>largest then panel=p largest=volume end end end
   if panel then
    local hinge=panel.CFrame*CFrame.new(-panel.Size.X/2,0,0)
    m:SetAttribute("DoorClosed",m:GetPivot())m:SetAttribute("DoorOpen",hinge*CFrame.Angles(0,math.rad(80),0)*hinge:ToObjectSpace(m:GetPivot()))
    m:SetAttribute("SerenaNavigationProtected",true)Collection:AddTag(m,"SerenaCityDoor")
    local prompt=Instance.new("ProximityPrompt")prompt.Name="CityDoorPrompt"prompt.ActionText="Abrir / fechar"prompt.ObjectText="Porta"prompt.MaxActivationDistance=9 prompt.RequiresLineOfSight=false prompt.Parent=panel doorCount+=1
   end
  end
 end end
 -- Use the original central square, with a safe spawn over its real floor.
 local spawnHit=assert(ray(16.7295,-31.9639),"Square spawn missing")assert(spawnHit.Material~=Enum.Material.Water)
 local spawnCF=CFrame.new(spawnHit.Position+Vector3.new(0,3.3,0))world:SetAttribute("MainSpawnCF",spawnCF)
 local spawn=Instance.new("SpawnLocation")spawn.Name="CitySpawn"spawn.Size=Vector3.new(6,.2,6)spawn.CFrame=CFrame.new(spawnHit.Position)
 spawn.Transparency=1 spawn.Anchored=true spawn.CanCollide=false spawn.CanQuery=false spawn.Neutral=true spawn.Duration=0 spawn.Parent=world
 local marker=part(props,"MainSpawn",Vector3.one,spawnCF,Enum.Material.Plastic,grassColor,1,false)
 marker:SetAttribute("SerenaNavigationProtected",true)
 local plazaPoint
 for radius=30,190,8 do
  for i=0,23 do
   local theta=i/24*math.pi*2 local x,z=spawnHit.Position.X+math.cos(theta)*radius,spawnHit.Position.Z+math.sin(theta)*radius
   local h=ray(x,z)
   if h and h.Instance:GetAttribute("SerenaGrassSurface")and h.Normal.Y>.97 and h.Position.Y<8 then
    local clear=true
    for _,dx in ipairs({-12,12})do for _,dz in ipairs({-12,12})do local q=ray(x+dx,z+dz)
     if not q or not q.Instance:GetAttribute("SerenaGrassSurface")or math.abs(q.Position.Y-h.Position.Y)>.25 then clear=false end
    end end
    if clear then plazaPoint=h.Position break end
   end
  end if plazaPoint then break end
 end
 assert(plazaPoint,"No clear pocket park for Stud shop")
 local platform=part(props,"PracaDaLojaStud",Vector3.new(24,.3,24),CFrame.new(plazaPoint-Vector3.new(0,.07,0)),variants.Studs.BaseMaterial,Color3.fromRGB(205,189,157))
 platform.MaterialVariant=variants.Studs.Name
 normalize(shopTemplate)shopTemplate:PivotTo(CFrame.new(plazaPoint+Vector3.new(0,.1,0)))shopTemplate:SetAttribute("SourceAssetId",128071741625902)
 shopTemplate:SetAttribute("SerenaNavigationProtected",true)shopTemplate.Parent=props
 for _,p in ipairs(shopTemplate:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=false if p.Transparency>.5 or p.Name=="TouchPart"then p.Transparency=1 p.CanCollide=false p.CanQuery=false end end end
 -- Retained inventory service gets a new shopkeeper in the city; secret-island routes are retired.
 npc.Name="Viajante"for _,name in ipairs({"Right Hip","Left Hip"})do local joint=npc.Torso:FindFirstChild(name)if joint then joint.C0=joint.C0*CFrame.Angles(math.pi/2,0,0)end end
 npc:PivotTo(CFrame.new(plazaPoint+Vector3.new(0,3.15,5.8))*CFrame.Angles(0,math.pi,0))npc.Parent=world
 if npc.Head:FindFirstChild("gui")then npc.Head.gui.name.Text="Loja Stud"npc.Head.gui.arrow.Text="Toque duas vezes"end
 world:SetAttribute("TraderPosition",npc.HumanoidRootPart.Position)
 local pier=Instance.new("Folder")pier.Name="PraiaEPier"pier.Parent=world local dock=Instance.new("Model")dock.Name="PierDeMadeira"dock.Parent=pier
 for _,name in ipairs({"SuporteDasVaras","BalcaoDaPesca"})do local p=part(dock,name,Vector3.one,npc.HumanoidRootPart.CFrame,Enum.Material.Plastic,grassColor,1,false)
  local prompt=Instance.new("ProximityPrompt")prompt.Name=name=="SuporteDasVaras"and"RodPrompt"or"SellPrompt"prompt.Enabled=false prompt.Parent=p
 end
 local gardens=0
 for _,p in ipairs(city:GetChildren())do if p:IsA("BasePart")and p:GetAttribute("SerenaGrassSurface")and p.Size.X>30 and p.Size.Z>30 and gardens<80 then
  local h=ray(p.Position.X,p.Position.Z)
  if h and h.Instance==p and h.Normal.Y>.9 then
   gardens+=1 local flower=flowerTemplate:Clone()normalize(flower)flower:PivotTo(CFrame.new(h.Position)*CFrame.Angles(0,gardens,0))flower.Name="FloresStud"..gardens flower:SetAttribute("SourceAssetId",128071741625902)flower.Parent=props
   for _,q in ipairs(flower:GetDescendants())do if q:IsA("BasePart")then q.Anchored=true q.CanCollide=false q.CanQuery=false q.CanTouch=false q:SetAttribute("SerenaRestCF",q.CFrame)Collection:AddTag(q,"SerenaWindFoliage")end end
  end
 end end
 for _,m in ipairs(treeTemplates)do m:Destroy()end flowerTemplate:Destroy()for _,m in ipairs(rockTemplates)do m:Destroy()end
 local lo,hi=bounds(city)world:SetAttribute("CityBoundsMin",lo)world:SetAttribute("CityBoundsMax",hi)
 return{map=115377891476033,theme=128071741625902,nametags=92018365421220,removedScripts=removed,terrainWaterVolumes=terrainVolumes,
  themedParts=themed,greenSurfaces=groundCount,studTrees=trees,flowerBeds=gardens,seats=seats,doors=doorCount,
  spawn={spawnCF.X,spawnCF.Y,spawnCF.Z},shop={plazaPoint.X,plazaPoint.Y,plazaPoint.Z},bounds={min={lo.X,lo.Y,lo.Z},max={hi.X,hi.Y,hi.Z}}}
end
return Builder
]============]).install()
local world=workspace.IlhaSerena
for _,name in ipairs({"SerenaBridgeServer","SerenaBoatServer"})do local s=game.ServerScriptService:FindFirstChild(name)if s then s:Destroy()end end
local old=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SerenaBridgeAnimation")if old then old:Destroy()end
source(runtime,"ModuleScript","GrassField",[============[-- Spatial bins cover every marked green surface, including mesh edges.
local Field={}Field.__index=Field
local function key(x,z)return x..":"..z end
function Field.new(coverage)
 assert(coverage:GetAttribute("FormatVersion")==3,"Wrong grass index")
 local self=setmetatable({spacing=coverage:GetAttribute("Spacing"),minimum=coverage:GetAttribute("Min"),
  gridCount=coverage:GetAttribute("GridCount"),binSize=coverage:GetAttribute("BinSize"),bins={},regionCount=0},Field)
 for _,chunk in ipairs(coverage:GetChildren())do if chunk:IsA("StringValue")then
  for _,r in ipairs(game.HttpService:JSONDecode(chunk.Value))do
   self.regionCount+=1
   for x=math.floor(r[1]/self.binSize),math.floor(r[3]/self.binSize)do
    for z=math.floor(r[2]/self.binSize),math.floor(r[4]/self.binSize)do
     local k=key(x,z)self.bins[k]=self.bins[k]or{}self.bins[k][#self.bins[k]+1]=r
    end
   end
  end
 end end
 assert(self.regionCount==coverage:GetAttribute("RegionCount"),"Missing grass regions")return self
end
function Field:get(ix,iz)
 if ix<0 or iz<0 or ix>=self.gridCount or iz>=self.gridCount then return nil end
 local x,z=self.minimum+ix*self.spacing,self.minimum+iz*self.spacing
 for _,r in ipairs(self.bins[key(math.floor(x/self.binSize),math.floor(z/self.binSize))]or{})do
  if x>=r[1]and x<=r[3]and z>=r[2]and z<=r[4]then
   return {ix=ix,iz=iz,key=ix*self.gridCount+iz+1,center=Vector3.new(x,r[5],z)}
  end
 end
end
function Field:around(point,radius)
 local ix,iz=math.floor((point.X-self.minimum)/self.spacing+.5),math.floor((point.Z-self.minimum)/self.spacing+.5)
 local steps=math.ceil(radius/self.spacing)+1 local cells={}
 for x=ix-steps,ix+steps do for z=iz-steps,iz+steps do local c=self:get(x,z)
  if c then local dx,dz=c.center.X-point.X,c.center.Z-point.Z if dx*dx+dz*dz<=radius*radius then cells[#cells+1]=c end end
 end end
 table.sort(cells,function(a,b)local ax,az=a.center.X-point.X,a.center.Z-point.Z local bx,bz=b.center.X-point.X,b.center.Z-point.Z return ax*ax+az*az<bx*bx+bz*bz end)
 return cells
end
return Field
]============])
source(runtime,"ModuleScript","GrassSampler",[============[-- Native surface tests keep individual roots off roads, roofs and water.
local Sampler={}
function Sampler.new(world)
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={world.Islands,world.Props,workspace.Terrain}params.RespectCanCollide=true
 local self={}
 function self:sample(cell,offsets)
  local heights={}local sum=0 local valid=0
  for i,offset in ipairs(offsets)do
   local x,z=cell.center.X+offset.X,cell.center.Z+offset.Z
   local hit=workspace:Raycast(Vector3.new(x,450,z),Vector3.new(0,-700,0),params)
   if hit and hit.Instance:GetAttribute("SerenaGrassSurface")and hit.Normal.Y>.2 then
    heights[i]=hit.Position.Y valid+=1 sum+=hit.Position.Y
   end
  end
  return heights,valid>0 and sum/valid or nil,valid
 end
 return self
end
return Sampler
]============])
source(runtime,"ModuleScript","NametagCore",[============[-- Requested Nametags+ artwork, with account identity supplied by Roblox.
local Tags={OwnerId=8344738123}
function Tags.decorate(tag,identity)
 local username=assert(tag:FindFirstChild("Username"))local title=assert(tag:FindFirstChild("Title"))
 local icons={}if identity.plus then icons[#icons+1]=""end if identity.verified then icons[#icons+1]=""end
 username.RichText=false username.Text=identity.displayName..(#icons>0 and" "..table.concat(icons," ")or"")
 username.TextColor3=Color3.fromRGB(249,246,237)username.TextStrokeColor3=Color3.fromRGB(30,36,33)
 title.RichText=false title.Visible=identity.userId==Tags.OwnerId title.Text=title.Visible and"Dono"or""
 title.TextColor3=Color3.fromRGB(246,199,100)
 return tag
end
return Tags
]============])
local skin=runtime.SkinnedGrass
local original=skin.Source
assert(original:find("local windIntensity = math.min(game.Workspace.GlobalWind.Magnitude, 20)",1,true),"Grass wind adapter changed")
skin.Source=original:gsub("local windIntensity = math.min%(game.Workspace.GlobalWind.Magnitude, 20%)","local windIntensity = math.min(game.Workspace.GlobalWind.Magnitude, 20) * (settingsTable.WindStrengthScale or 1)")
local module=runtime.Climate
module.Source=module.Source:gsub("grade.Contrast=.105","grade.Contrast=.14"):gsub("grade.Saturation=.16","grade.Saturation=.18"):gsub("bloom.Intensity=.19","bloom.Intensity=.22")
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaWindClient",[============[local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local UIS=game:GetService("UserInputService")
local effects=RS:WaitForChild("SerenaRuntime"):WaitForChild("WindEffects")
local WindLines=require(effects:WaitForChild("WindLines"))
local WindShake=require(effects:WaitForChild("WindShake"))
while not workspace.CurrentCamera do RunService.Heartbeat:Wait()end
local function tag(p)
 if p:IsA("BasePart")and p:IsDescendantOf(workspace)then
  local rest=p:GetAttribute("SerenaRestCF")or p.CFrame
  p.CFrame=rest p:SetAttribute("WindPower",p.Name=="Leaves"and .288 or .198)
  CollectionService:AddTag(p,"WindShake")
 end
end
for _,p in ipairs(CollectionService:GetTagged("SerenaWindFoliage"))do tag(p)end
CollectionService:GetInstanceAddedSignal("SerenaWindFoliage"):Connect(tag)
CollectionService:GetInstanceRemovedSignal("SerenaWindFoliage"):Connect(function(p)CollectionService:RemoveTag(p,"WindShake")end)
WindLines:Init({Direction=Vector3.new(1,0,.3).Unit,Speed=14,Lifetime=2,SpawnRate=UIS.TouchEnabled and 9 or 15})
WindShake:SetDefaultSettings({WindDirection=Vector3.new(1,0,.3).Unit,WindSpeed=14,WindPower=.315})WindShake:Init()
local floating={}
for _,p in ipairs(CollectionService:GetTagged("SerenaFloatingDetail"))do if p:IsA("BasePart")then floating[p]=p:GetAttribute("SerenaRestCF")or p.CFrame end end
CollectionService:GetInstanceAddedSignal("SerenaFloatingDetail"):Connect(function(p)if p:IsA("BasePart")then floating[p]=p:GetAttribute("SerenaRestCF")or p.CFrame end end)
CollectionService:GetInstanceRemovedSignal("SerenaFloatingDetail"):Connect(function(p)floating[p]=nil end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.35 then return end elapsed=0
 local wind=workspace.GlobalWind local speed=math.clamp(wind.Magnitude*1.5,8,32)local direction=wind.Magnitude>.01 and wind.Unit or Vector3.new(1,0,.3).Unit
 WindLines.Direction=direction WindLines.Speed=speed WindShake:SetDefaultSettings({WindDirection=direction,WindSpeed=speed,WindPower=(.28+math.min(wind.Magnitude,20)*.009)*.9})
 local now=workspace:GetServerTimeNow()
 for p,rest in pairs(floating)do if p.Parent then p.CFrame=rest+Vector3.new(0,math.sin(now*1.15+rest.X*.04)*.055,0)else floating[p]=nil end end
end)
script.Destroying:Connect(function()WindLines:Cleanup()WindShake:Cleanup()end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaGrassClient",[============[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")local UIS=game:GetService("UserInputService")
local runtime=RS:WaitForChild("SerenaRuntime")local player=Players.LocalPlayer local world=workspace:WaitForChild("IlhaSerena")
local Field=require(runtime:WaitForChild("GrassField"))local Skinned=require(runtime:WaitForChild("SkinnedGrass"))
local sampler=require(runtime:WaitForChild("GrassSampler")).new(world)
local coverage=runtime:WaitForChild("GrassCoverage")local field=Field.new(coverage)
local template=runtime.SkinnedGrassTemplates.GrassCard local templateMesh=template:FindFirstChildOfClass("MeshPart")local sourceBones={}local offsets={}
for _,b in ipairs(templateMesh:GetChildren())do if b:IsA("Bone")then sourceBones[#sourceBones+1]=b end end
table.sort(sourceBones,function(a,b)return a.Name<b.Name end)
for i,b in ipairs(sourceBones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)end
local visible=Instance.new("Folder")visible.Name="SerenaInteractiveGrass"visible.Parent=workspace
local storage=Instance.new("Folder")storage.Name="SerenaGrassLocalStorage"storage.Parent=RS
local touch=UIS.TouchEnabled local radius=coverage:GetAttribute(touch and"NearRadiusTouch"or"NearRadiusDesktop")
local maxActive=coverage:GetAttribute(touch and"MaxActiveTouch"or"MaxActiveDesktop")local keep=radius+6
local grass=Skinned.new({RenderDistanceEnabled=false,MeshStorage=storage,CollisionDistance=30,
 CollisionRadiusInner=1.2,CollisionRadiusOuter=3.2,CollisionAngle=68,CollisionReturnDelay=.08,
 CollisionReturnInfo=TweenInfo.new(.95,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
 WindDistanceInner=touch and 12 or 20,WindDistanceOuter=touch and 32 or 48,
 WindFramerateInner=1,WindFramerateOuter=.25,UseGlobalWind=true,WindStrengthScale=.9})
local active={}local empty={}local count=0 local queue={}local cursor=1 local refresh=1 local stepTime=0 local destroyed=false
local function rootOf(p)local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")if h and h.Health>0 and r then return r,h end end
local function add(cell)
 local heights,anchor,valid=sampler:sample(cell,offsets)
 if not anchor then empty[cell.key]=os.clock()+2 return end
 local model=template:Clone()model.Name="Grass"..cell.key model:PivotTo(CFrame.new(cell.center.X,anchor,cell.center.Z))model.Parent=visible
 local mesh=model:FindFirstChildOfClass("MeshPart")local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
 for i,b in ipairs(bones)do
  local original=b.WorldCFrame.Position local height=heights[i]
  local point=height and Vector3.new(original.X,height-.045,original.Z)or(original-Vector3.new(0,240,0))
  local offset=CFrame.new(b.WorldCFrame:VectorToObjectSpace(point-original))
  b:SetAttribute("SerenaTerrainOffset",offset)b:SetAttribute("SerenaGroundPoint",point)b:SetAttribute("SerenaGreenRoot",height~=nil)b.Transform=offset
 end
 grass:AddMeshes({model})active[cell.key]={model=model,cell=cell,roots=valid}count+=1
end
local function remove(key)local entry=active[key]if not entry then return end grass:RemoveMeshes({entry.model})entry.model:Destroy()active[key]=nil count-=1 end
local stream=world.DescendantAdded:Connect(function(p)if p:IsA("BasePart")then refresh=1 table.clear(empty)end end)
player:SetAttribute("SerenaGrassCoverageRegions",field.regionCount)player:SetAttribute("SerenaWholeMapGrassReady",true)
local heartbeat=Run.Heartbeat:Connect(function(dt)
 if destroyed then return end local root=rootOf(player)if not root then return end refresh+=dt
 if refresh>=.25 then
  refresh=0
  for k,entry in pairs(active)do local dx,dz=entry.cell.center.X-root.Position.X,entry.cell.center.Z-root.Position.Z if dx*dx+dz*dz>keep*keep then remove(k)end end
  queue={}cursor=1 local now=os.clock()
  for _,cell in ipairs(field:around(root.Position,radius))do if not active[cell.key]and(not empty[cell.key]or empty[cell.key]<now)then queue[#queue+1]=cell end end
  for k,t in pairs(empty)do if now>t+4 then empty[k]=nil end end
 end
 local started=os.clock()local budget=touch and 4 or 8
 for _=1,budget do
  local cell=queue[cursor]if not cell or count>=maxActive then break end cursor+=1
  if not active[cell.key]then add(cell)end
  if os.clock()-started>(touch and .003 or .005)then break end
 end
 player:SetAttribute("SerenaGrassLoadedPatches",count)player:SetAttribute("SerenaGrassNearbyReady",cursor>#queue)
end)
local rendered=Run.RenderStepped:Connect(function(dt)
 if destroyed then return end stepTime+=dt if stepTime<(touch and 1/24 or 1/30)then return end local step=math.min(stepTime,.1)stepTime=0
 local root=rootOf(player)if not root then return end local actors={}
 for _,p in ipairs(Players:GetPlayers())do local r,h=rootOf(p)if r and(r.Position-root.Position).Magnitude<30 then
  local feet=r.Position.Y-(h.RigType==Enum.HumanoidRigType.R6 and 3 or h.HipHeight+r.Size.Y/2)actors[#actors+1]=Vector3.new(r.Position.X,feet+.1,r.Position.Z)
 end end grass:Step(step,actors,root.Position)
end)
script.Destroying:Connect(function()destroyed=true heartbeat:Disconnect()rendered:Disconnect()stream:Disconnect()grass:Destroy()visible:Destroy()storage:Destroy()table.clear(active)table.clear(empty)end)
]============])
source(game.ServerScriptService,"Script","SerenaNametagServer",[============[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")
local Tags=require(RS.SerenaRuntime.NametagCore)local template=RS.SerenaTemplates.SerenaNametagTemplate
local records={}
local function flag(p,name)local ok,value=pcall(function()return p[name]end)return ok and value==true end
local function update(p)
 local record=records[p]local tag=record and record.tag if not tag or not tag.Parent then return end
 Tags.decorate(tag,{displayName=p.DisplayName,userId=p.UserId,plus=flag(p,"HasRobloxSubscription"),verified=flag(p,"HasVerifiedBadge")})
end
local function character(p,c)
 local head=c:WaitForChild("Head",10)local h=c:WaitForChild("Humanoid",10)
 if not head or not h or p.Character~=c or not records[p]then return end
 local old=head:FindFirstChild("CustomNametag")if old then old:Destroy()end
 local tag=template:Clone()tag.Name="CustomNametag"tag.Adornee=head tag.Parent=head
 tag.Enabled=not c:GetAttribute("SerenaInvisible")records[p].tag=tag
 h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None update(p)
end
local function added(p)
 if records[p]then return end local record={connections={}}records[p]=record
 record.connections[#record.connections+1]=p.CharacterAdded:Connect(function(c)task.spawn(character,p,c)end)
 for _,property in ipairs({"DisplayName","HasRobloxSubscription","HasVerifiedBadge"})do
  local ok,signal=pcall(function()return p:GetPropertyChangedSignal(property)end)
  if ok then record.connections[#record.connections+1]=signal:Connect(function()update(p)end)end
 end
 if p.Character then task.spawn(character,p,p.Character)end
end
Players.PlayerAdded:Connect(added)for _,p in ipairs(Players:GetPlayers())do added(p)end
Players.PlayerRemoving:Connect(function(p)local r=records[p]if r then for _,c in ipairs(r.connections)do c:Disconnect()end if r.tag then r.tag:Destroy()end end records[p]=nil end)
]============])
source(game.ServerScriptService,"Script","SerenaCityDoorServer",[============[local Players=game:GetService("Players")local Collection=game:GetService("CollectionService")local Tween=game:GetService("TweenService")
local states={}
local function near(point,radius)
 for _,p in ipairs(Players:GetPlayers())do local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")if r and(r.Position-point).Magnitude<radius then return true end end
 return false
end
local function animate(model,state,open)
 if state.busy then return end state.busy=true state.open=open
 local v=Instance.new("CFrameValue")v.Value=model:GetPivot()local connection=v.Changed:Connect(function(cf)if model.Parent then model:PivotTo(cf)end end)
 for part in pairs(state.collisions)do if part.Parent then part.CanCollide=false end end
 local tween=Tween:Create(v,TweenInfo.new(.45,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=model:GetAttribute(open and"DoorOpen"or"DoorClosed")})
 tween.Completed:Once(function()connection:Disconnect()v:Destroy()if not open then for p,collide in pairs(state.collisions)do if p.Parent then p.CanCollide=collide end end end state.busy=false end)
 tween:Play()
end
local function bind(model)
 if states[model]then return end local state={collisions={},busy=false,open=false}states[model]=state
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then state.collisions[p]=p.CanCollide end end
 local prompt=model:FindFirstChild("CityDoorPrompt",true)if not prompt then return end
 prompt.Triggered:Connect(function(p)
  local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if not model.Parent or not r or not h or h.Health<=0 or(r.Position-prompt.Parent.Position).Magnitude>12 then return end
  if state.open and near(model:GetAttribute("DoorClosed").Position,4)then return end
  animate(model,state,not state.open)
  if state.open then task.delay(6,function()
   while model.Parent and state.open and near(model:GetAttribute("DoorClosed").Position,5)do task.wait(1)end
   if model.Parent and state.open then animate(model,state,false)end
  end)end
 end)
end
for _,m in ipairs(Collection:GetTagged("SerenaCityDoor"))do bind(m)end
Collection:GetInstanceAddedSignal("SerenaCityDoor"):Connect(bind)
Collection:GetInstanceRemovedSignal("SerenaCityDoor"):Connect(function(m)states[m]=nil end)
]============])
source(game.ServerScriptService,"Script","SerenaAmbienceServer",[============[local Lighting=game:GetService("Lighting")local Players=game:GetService("Players")
local runtime=game:GetService("ReplicatedStorage"):WaitForChild("SerenaRuntime")
local Climate=require(runtime:WaitForChild("Climate"))local Personal=require(runtime:WaitForChild("PersonalClimate"))
local world=workspace:WaitForChild("IlhaSerena")local terrain=workspace.Terrain
world:SetAttribute("RenderingServerApplied",Climate.rendering(Lighting))
world:SetAttribute("EnvironmentMode","Dia")world:SetAttribute("ClimateModeCount",4)
for _,key in ipairs({"ClockStart","DayLength","WeatherChanged","PreviousWeather","Weather"})do world:SetAttribute(key,nil)end
local lamps={}local insects={}
local function light(d)
 if d:IsA("Light")and not d:GetAttribute("AlwaysOn")then lamps[d]=true
 elseif d:IsA("ParticleEmitter")and d.Name=="Vagalumes"then insects[d]=true end
end
for _,d in ipairs(world:GetDescendants())do light(d)end world.DescendantAdded:Connect(light)
Players.CharacterAutoLoads=true Players.RespawnTime=3
local function ready(c)
 local h=c:WaitForChild("Humanoid",10)
 if h then h.WalkSpeed=16 h.JumpPower=50 h.UseJumpPower=true h.PlatformStand=false h.AutoRotate=true end
end
local function bind(p)p.CharacterAdded:Connect(ready)if p.Character then task.spawn(ready,p.Character)end end
Players.PlayerAdded:Connect(bind)for _,p in ipairs(Players:GetPlayers())do bind(p)end
while true do
 local hour,rain,clear,key=Personal.resolve(world:GetAttribute("EnvironmentMode"))
 local profile=Climate.profile(hour,rain,clear,workspace:GetServerTimeNow())profile.hour=hour
 Climate.apply(Lighting,terrain,profile)world:SetAttribute("TimePhase",key)world:SetAttribute("RainIntensity",rain)
 local night=profile.sun<.23
 for lamp in pairs(lamps)do if lamp.Parent then lamp.Enabled=night else lamps[lamp]=nil end end
 for insect in pairs(insects)do if insect.Parent then insect.Enabled=night else insects[insect]=nil end end
 task.wait(.5)
end
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaAmbienceClient",[============[local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local Climate=require(game.ReplicatedStorage:WaitForChild("SerenaRuntime"):WaitForChild("Climate"))
local Personal=require(game.ReplicatedStorage.SerenaRuntime:WaitForChild("PersonalClimate"))
local world=workspace:WaitForChild("IlhaSerena")
local player=Players.LocalPlayer
player:SetAttribute("SerenaRenderingApplied",Climate.rendering(Lighting))
-- Local copies prevent server weather from overwriting a personal sky profile.
local copies={}
for _,name in ipairs({"SerenaAtmosphere","SerenaColor","SerenaBloom","SerenaSunRays"})do
 local original=Lighting:WaitForChild(name) local clone=original:Clone()
 table.insert(copies,{original=original,clone=clone,parent=Lighting,name=name})
 original.Name=name.."ServerProfile" original.Parent=nil clone.Name=name clone.Parent=Lighting
end
local originalClouds=workspace.Terrain:WaitForChild("SerenaClouds")local localClouds=originalClouds:Clone()
table.insert(copies,{original=originalClouds,clone=localClouds,parent=workspace.Terrain,name="SerenaClouds"})
originalClouds.Name="SerenaCloudsServerProfile"originalClouds.Parent=nil localClouds.Name="SerenaClouds"localClouds.Parent=workspace.Terrain
local lamps={}local insects={}
local function light(d)
 if d:IsA("Light") and not d:GetAttribute("AlwaysOn")then lamps[d]=true
 elseif d:IsA("ParticleEmitter")and d.Name=="Vagalumes"then insects[d]=true end
end
for _,d in ipairs(world:GetDescendants())do light(d)end
world.DescendantAdded:Connect(light)
local renderedHour,renderedRain,renderedClear
local rain=Instance.new("Folder") rain.Name="SerenaLocalRain" rain.Parent=workspace
local rng=Random.new() local drops={}
for i=1,(UserInputService.TouchEnabled and 60 or 110) do
 local p=Instance.new("Part") p.Name="Chuva" p.Size=Vector3.new(.025,1.55,.025) p.Material=Enum.Material.Glass p.Color=Color3.fromRGB(203,223,235)
 p.Transparency=1 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=rain
 drops[i]={part=p,x=rng:NextNumber(-25,25),y=rng:NextNumber(-9,27),z=rng:NextNumber(-25,25)}
end
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Exclude ray.IgnoreWater=true
local nextRoofCheck=0 local outside=true local climateTime=0
RunService.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera if not camera then return end
 local now=workspace:GetServerTimeNow()
 local intensity=0
 do
  local hour,wet,clear,mode=Personal.resolve(player:GetAttribute("SerenaEnvironmentChoice"))
  local ease=1-math.exp(-math.min(dt,.1)*4)
  renderedHour=renderedHour and (renderedHour+((hour-renderedHour+12)%24-12)*ease)%24 or hour
  renderedRain=renderedRain and renderedRain+(wet-renderedRain)*ease or wet
  renderedClear=renderedClear and renderedClear+(clear-renderedClear)*ease or clear
  intensity=renderedRain
  local profile=Climate.profile(renderedHour,renderedRain,renderedClear,now)profile.hour=renderedHour
  Climate.apply(Lighting,workspace.Terrain,profile)
  player:SetAttribute("SerenaAppliedHour",renderedHour)player:SetAttribute("SerenaAppliedRain",renderedRain)
  player:SetAttribute("SerenaAppliedMode",mode)player:SetAttribute("SerenaAppliedWind",profile.wind.Magnitude)
  local night=profile.sun<.23
  for lamp in pairs(lamps)do if lamp.Parent then lamp.Enabled=night else lamps[lamp]=nil end end
  for insect in pairs(insects)do if insect.Parent then insect.Enabled=night else insects[insect]=nil end end
 end
 if intensity>.015 and os.clock()>nextRoofCheck then
  nextRoofCheck=os.clock()+.35
  local filters={rain} if player.Character then table.insert(filters,player.Character) end
  ray.FilterDescendantsInstances=filters
  local head=player.Character and player.Character:FindFirstChild("Head")
  outside=not workspace:Raycast(head and head.Position or camera.CFrame.Position,Vector3.new(0,140,0),ray)
 end
 local wind=workspace.GlobalWind local slant=math.atan2(wind.X,57)
 for i,d in ipairs(drops) do
  if intensity>.015 and outside and i<=math.ceil(#drops*intensity) then
   d.y-=math.min(dt,.1)*57 d.x+=math.min(dt,.1)*wind.X*.45
   if d.y< -10 or d.x>29 then d.y=27 d.x=rng:NextNumber(-25,25) d.z=rng:NextNumber(-25,25) end
   d.part.CFrame=CFrame.new(camera.CFrame.Position+Vector3.new(d.x,d.y,d.z))*CFrame.Angles(0,0,-slant)
   d.part.Transparency=.48+(1-intensity)*.4
  elseif d.part.Transparency~=1 then d.part.Transparency=1 end
 end
end)
local function cameraFor(char)
 local hum=char:WaitForChild("Humanoid",10)
 if hum then local camera=workspace.CurrentCamera if camera then camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=hum camera.FieldOfView=70 end end
end
player.CharacterAdded:Connect(cameraFor)
if player.Character then task.spawn(cameraFor,player.Character) end
script.Destroying:Connect(function()
 rain:Destroy()
 for _,entry in ipairs(copies)do entry.clone:Destroy()entry.original.Name=entry.name entry.original.Parent=entry.parent end
end)
]============])
source(game.ServerScriptService,"Script","SerenaTraderServer",[============[local Players=game:GetService("Players")local Http=game:GetService("HttpService")
local world=workspace:WaitForChild("IlhaSerena")local npc=world:WaitForChild("Viajante")
local remote=game.ReplicatedStorage:WaitForChild("SerenaTrader")
local shop=game.ServerScriptService:WaitForChild("SerenaShopService")
local fishing=game.ServerScriptService:WaitForChild("SerenaFishingService")
local core=require(game.ReplicatedStorage.SerenaRuntime.TraderCore)
local function character(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 return c and h and h.Health>0 and r and c or nil,r
end
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Exclude
local trader=core.new({
 clock=function()return workspace:GetServerTimeNow()end,guid=function()return Http:GenerateGUID(false)end,
 near=function(p,range)
  local c,r=character(p)if not c or(r.Position-npc.HumanoidRootPart.Position).Magnitude>range then return false end
  ray.FilterDescendantsInstances={c,npc}
  local hit=workspace:Raycast(r.Position,npc.HumanoidRootPart.Position-r.Position,ray)
  return not hit
 end,
 open=function(p,nonce)remote:FireClient(p,"Open",{nonce=nonce,coins=p:GetAttribute("SerenaCoins")or 0})end,
 buy=function(p,choice)return shop:Invoke(p,choice)end,
 sell=function(p)return fishing:Invoke(p,"Sell")end,
 teleport=function()return false,"A cidade não usa mais o caminho das ilhas."end,
})
npc.ViajanteClick.MouseClick:Connect(function(p)trader:tap(p)end)
local rates={}
remote.OnServerEvent:Connect(function(p,action,nonce,choice)
 if type(action)~="string"then return end
 local now=os.clock()if rates[p]and now-rates[p]<.08 then return end rates[p]=now
 if action=="Tap"then trader:tap(p)
 elseif action=="Choose"then local ok,message=trader:choose(p,nonce,choice)remote:FireClient(p,"Result",{ok=ok,text=message or"",choice=choice})
 end
end)
Players.PlayerRemoving:Connect(function(p)trader:remove(p)rates[p]=nil end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaTraderClient",[============[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")local Run=game:GetService("RunService")
local player=Players.LocalPlayer local world=workspace:WaitForChild("IlhaSerena")local remote=RS:WaitForChild("SerenaTrader")
local Dialog=require(RS.SerenaRuntime:WaitForChild("Dialogue"))
local gui=RS.SerenaTemplates.SerenaDialogueTemplate:Clone()gui.Name="SerenaDialogue"gui.ResetOnSpawn=false gui.Parent=player:WaitForChild("PlayerGui")
local dialogue local response local nonce
local function close()if dialogue then dialogue:hideGui()end nonce=nil end
local function ready()
 local npc=world:FindFirstChild("Viajante")if not npc then return nil end
 if not dialogue or dialogue.npc~=npc then
  if response then response:Disconnect()end if dialogue then dialogue:Destroy()end
  dialogue=Dialog.new(npc,gui)
  response=dialogue.responded:Connect(function(choice)if nonce then remote:FireServer("Choose",nonce,choice)end end)
 end
 return dialogue
end
remote.OnClientEvent:Connect(function(event,data)
 if event=="Open"then
  local d=ready()if not d then return end nonce=data.nonce
  d:trigger("Olá, viajante! Bem-vindo à Loja Stud! Tenho maçãs e varas de pesca.",{
   {id="BuyApple",label="Maçã da Névoa · 30 moedas"},{id="BuyRod",label="Vara de pesca · 20 moedas"},
   {id="SellFish",label="Vender meus peixes"},{id="Close",label="Até mais"},
  })
 elseif event=="Result"and dialogue then
  if data.choice=="Close"then close()
  elseif nonce then
   local suffix=" Você tem "..tostring(player:GetAttribute("SerenaCoins")or 0).." moedas."
   dialogue:trigger((data.text~=""and data.text or"Pronto!")..suffix,{{id="BuyApple",label="Comprar maçã"},{id="BuyRod",label="Comprar vara"},{id="SellFish",label="Vender peixes"},{id="Close",label="Fechar"}})
  end
 end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.2 then return end elapsed=0
 local c=player.Character local r=c and c:FindFirstChild("HumanoidRootPart")
 if nonce and(not dialogue or not dialogue.npc.Parent or not r or(r.Position-dialogue.npc.HumanoidRootPart.Position).Magnitude>14)then close()end
end)
script.Destroying:Connect(function()if response then response:Disconnect()end if dialogue then dialogue:Destroy()end gui:Destroy()end)
]============])
local grass=factory([============[-- Full-city coverage without copying thousands of grass meshes into the server.
local Grass={}
function Grass.install(world,runtime)
 local old=runtime:FindFirstChild("GrassCoverage")if old then old:Destroy()end
 local folder=Instance.new("Folder")folder.Name="GrassCoverage"folder.Parent=runtime
 local settings={FormatVersion=3,Spacing=4,Min=-2048,Max=2048,GridCount=1025,BoneCount=100,SourceAssetId=87377915371959,
  NearRadiusTouch=48,NearRadiusDesktop=80,MaxActiveTouch=640,MaxActiveDesktop=1600,BinSize=32}
 for k,v in pairs(settings)do folder:SetAttribute(k,v)end
 local regions={}local batch={}local count=0 local chunks=0 local totalArea=0
 local function flush()
  if #batch==0 then return end chunks+=1 local value=Instance.new("StringValue")value.Name=string.format("Regions%03d",chunks)
  value.Value=game.HttpService:JSONEncode(batch)value.Parent=folder batch={}
 end
 for _,p in ipairs(world.Islands:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("SerenaGrassSurface")then
  local lo=Vector3.new(math.huge,math.huge,math.huge)local hi=-lo
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(q)hi=hi:Max(q)
  end end end
  local row={lo.X-2.26,lo.Z-2.26,hi.X+2.26,hi.Z+2.26,(lo.Y+hi.Y)/2}
  assert(row[1]>=settings.Min and row[3]<=settings.Max and row[2]>=settings.Min and row[4]<=settings.Max,"Grass surface beyond index")
  regions[#regions+1]=row batch[#batch+1]=row count+=1 totalArea+=(hi.X-lo.X)*(hi.Z-lo.Z)
  if #batch>=96 then flush()end
 end end flush()assert(count>20,"City green surface classification failed")
 folder:SetAttribute("RegionCount",count)folder:SetAttribute("ChunkCount",chunks)
 folder:SetAttribute("DenseRootConform",true)folder:SetAttribute("WindAnimationScale",.9)
 world:SetAttribute("GrassCoverageRegions",count)world:SetAttribute("GrassSpacing",4)
 return{regions=count,chunks=chunks,spacing=4,meshRootSpan=4.492,loading="Native per-root surface queries near each player",regionBoundsArea=totalArea}
end
return Grass
]============]).install(world,runtime)
local climate=require(runtime.Climate)
local rendered=climate.rendering(game.Lighting)
assert(rendered and game.Lighting.LightingStyle==Enum.LightingStyle.Realistic,"Realistic renderer not set")
local p=climate.profile(12,0,1,0)p.hour=12 climate.apply(game.Lighting,workspace.Terrain,p)
world:SetAttribute("RenderingServerApplied",rendered)
local tests=run([============[local world=workspace.IlhaSerena local runtime=game.ReplicatedStorage.SerenaRuntime local Collection=game:GetService("CollectionService")
assert(world:GetAttribute("MapAssetId")==115377891476033 and world:GetAttribute("ThemeAssetId")==128071741625902)
assert(not world.Islands:FindFirstChild("IlhaDoFarol")and not world:FindFirstChild("TrilhasEMirante")and not world:GetAttribute("SecretSpawnCF"),"Old archipelago remains")
local parts,theme,seats,foreign,green=0,0,0,0,0
for _,p in ipairs(world:GetDescendants())do
 if p:IsA("BasePart")then parts+=1 if not p:IsDescendantOf(world.Viajante)then assert(p.Anchored,"Loose city geometry")end
  if p:GetAttribute("SerenaStudThemed")then theme+=1 assert(p.MaterialVariant=="SerenaStud_Studs")end
  if p:IsA("Seat")or p:IsA("VehicleSeat")then seats+=1 end if p:GetAttribute("SerenaGrassSurface")then green+=1 end
 elseif p:IsA("LuaSourceContainer")then foreign+=1 end
end
assert(parts>7000 and theme>5000 and seats>200 and foreign==0 and green>20,"City/template imports incomplete")
assert(game.MaterialService.SerenaStud_Studs and game.MaterialService.SerenaStud_StudsSmall)
assert(game.Lighting.LightingStyle==Enum.LightingStyle.Realistic and game.Lighting.PrioritizeLightingQuality and game.Lighting.GlobalShadows)
assert(game.Lighting.SerenaStudSky and game.Lighting.SerenaColor.Enabled and game.Lighting.SerenaBloom.Enabled and game.Lighting.SerenaSunRays.Enabled)
local Field=require(runtime.GrassField)local field=Field.new(runtime.GrassCoverage)
assert(field.spacing==4 and runtime.GrassCoverage:GetAttribute("SourceAssetId")==87377915371959)
local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={world.Islands,world.Props,workspace.Terrain}params.RespectCanCollide=true
local function hit(x,z)return workspace:Raycast(Vector3.new(x,450,z),Vector3.new(0,-700,0),params)end
local spawn=world:GetAttribute("MainSpawnCF")local floor=assert(hit(spawn.X,spawn.Z))
assert(floor.Material~=Enum.Material.Water and math.abs(spawn.Y-floor.Position.Y-3.3)<.06,"City spawn blocked or submerged")
local min,max=world:GetAttribute("CityBoundsMin"),world:GetAttribute("CityBoundsMax")local greenSamples=0 local gaps=0
for x=math.floor(min.X/16)*16,max.X,16 do
 for z=math.floor(min.Z/16)*16,max.Z,16 do
  local h=hit(x,z)
  if h and h.Instance:GetAttribute("SerenaGrassSurface")and h.Normal.Y>.2 then
   greenSamples+=1 local ix,iz=math.floor((x-field.minimum)/4+.5),math.floor((z-field.minimum)/4+.5)
   if not field:get(ix,iz)then gaps+=1 end
  end
 end
 if math.floor(x)%256==0 then task.wait()end
end
assert(greenSamples>1000 and gaps==0,"Grass index leaves green city areas uncovered")
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template:FindFirstChildOfClass("MeshPart")local bones={}local offsets={}
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
assert(#bones==100)for i,b in ipairs(bones)do offsets[i]=template:GetPivot():PointToObjectSpace(b.WorldCFrame.Position)end
local sampler=require(runtime.GrassSampler).new(world)local tested=0 local validRoots=0 local rejectedRoadCells=0
for _,point in ipairs({Vector3.new(0,0,0),Vector3.new(-430,0,330),Vector3.new(500,0,450),Vector3.new(-1200,0,900)})do
 local candidates=field:around(point,40)local localCount=0
 for _,cell in ipairs(candidates)do
  local heights,anchor,valid=sampler:sample(cell,offsets)
  if anchor then
   tested+=1 localCount+=1 validRoots+=valid
   for i,y in pairs(heights)do local h=hit(cell.center.X+offsets[i].X,cell.center.Z+offsets[i].Z)
    assert(h and h.Instance:GetAttribute("SerenaGrassSurface")and math.abs(h.Position.Y-y)<.001,"Grass root floats or grows on road")
   end
  else rejectedRoadCells+=1 end
  if localCount>=8 then break end
 end
end
assert(tested>=12 and validRoots>800,"Dense grass roots unavailable around city")
local Tags=require(runtime.NametagCore)local tag=game.ReplicatedStorage.SerenaTemplates.SerenaNametagTemplate:Clone()
assert(tag:GetAttribute("SourceAssetId")==92018365421220 and not tag.AlwaysOnTop and tag.MaxDistance==65)
Tags.decorate(tag,{displayName="João",userId=1,plus=false,verified=false})
assert(tag.Username.Text=="João"and not tag.Title.Visible and not tag.Username.RichText)
Tags.decorate(tag,{displayName="ch_ckz2n",userId=8344738123,plus=false,verified=false})
assert(tag.Title.Text=="Dono"and tag.Title.Visible and not tag.Username.Text:find("",1,true),"Fake verified badge")tag:Destroy()
assert(world:GetAttribute("WindAnimationScale")==.9)
local Skinned=require(runtime.SkinnedGrass)local grass=Skinned.new({WindStrengthScale=.9})assert(grass.Settings.WindStrengthScale==.9)grass:Destroy()
assert(runtime.SkinnedGrass.Source:find("settingsTable.WindStrengthScale or 1",1,true))
local Admin=require(runtime.AdminCore)assert(Admin.allowed({UserId=8344738123})and not Admin.allowed({UserId=1}))
assert(not game.ServerScriptService:FindFirstChild("SerenaBridgeServer")and not game.ServerScriptService:FindFirstChild("SerenaBoatServer"))
assert(not game.StarterPlayer.StarterPlayerScripts.SerenaTraderClient.Source:find('id="Secret"',1,true))
local doors=0 for _,m in ipairs(Collection:GetTagged("SerenaCityDoor"))do if m:IsDescendantOf(world)then
 doors+=1 assert(m:GetAttribute("DoorClosed")and m:GetAttribute("DoorOpen")and m:FindFirstChild("CityDoorPrompt",true))
end end assert(doors>10)
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
 local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
end end end
return{parts=parts,themedParts=theme,seats=seats,foreignScripts=foreign,greenSurfaces=green,greenSamples=greenSamples,indexGaps=gaps,
 realGrassSampledCells=tested,validSampledRoots=validRoots,roadOrRoofCellsRejected=rejectedRoadCells,nametags=true,
 windStrengthScale=.9,ownerOnlyAdmin=true,cityDoors=doors,compiledScripts=compiled,realisticRendering=true,safeSpawn=true}
]============])
game:GetService("AssetService"):SavePlaceAsync()
return {published=true,sourceVersion=game.PlaceVersion,upgrade=85,geometry=geometry,grass=grass,tests=tests,lighting=tostring(game.Lighting.LightingStyle)}
