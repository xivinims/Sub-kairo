assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==83,"Published version changed")
local runtime=game.ReplicatedStorage.SerenaRuntime
local function source(parent,class,name,code)
 local old=parent:FindFirstChild(name)local s=Instance.new(class)s.Name=name s.Source=code
 if old then for _,child in ipairs(old:GetChildren())do child.Parent=s end old:Destroy()end s.Parent=parent return s
end
local function run(code)
 local m=Instance.new("ModuleScript")m.Name="Stage84"m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage
 local result=require(m)()m:Destroy()return result
end
local function factory(code)
 local m=Instance.new("ModuleScript")m.Name="Factory84"m.Source=code m.Parent=game.ServerStorage
 local result=require(m)m:Destroy()return result
end

local geometry=factory([========[local Builder={}
local Collection=game:GetService("CollectionService")
local function bounds(model)
 local lo=Vector3.new(math.huge,math.huge,math.huge)local hi=-lo
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(q)hi=hi:Max(q)
  end end end
 end end
 return lo,hi
end
local function stripped(asset)
 local count=0
 for _,d in ipairs(asset:GetDescendants())do
  if d:IsA("LuaSourceContainer")or d:IsA("Camera")or d:IsA("RemoteEvent")or d:IsA("RemoteFunction")or d:IsA("ObjectValue")then d:Destroy()count+=1 end
 end
 return count
end
local function part(parent,name,size,cf,material,color,collide,alpha)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Anchored=true
 p.Material=material or Enum.Material.Rock p.Color=color or Color3.fromRGB(157,166,160)
 p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.Transparency=alpha or 0
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local function normalize(model,origin)model:PivotTo(model:GetPivot()-origin)end
local function rayFor(model)
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={model}
 params.RespectCanCollide=true
 return function(x,z)
  return workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-260,0),params)
 end
end
local function parentRoot(asset,name)
 local m=asset:FindFirstChildOfClass("Model")assert(m,"Map model missing")m.Parent=nil asset:Destroy()m.Name=name return m
end
local function import(id)local m=game:GetService("AssetService"):LoadAssetAsync(id)local count=stripped(m)return m,count end
function Builder.install()
 assert(game.PlaceVersion==83,"World base changed")
 local old=workspace.IlhaSerena local boat=old.PraiaEPier.BarcoDePesca:Clone()
 local attributes=old:GetAttributes()old:Destroy()
 workspace.Terrain:Clear()
 workspace.Terrain:FillBlock(CFrame.new(0,-12,0),Vector3.new(1152,24,1152),Enum.Material.Water)
 workspace.Terrain:FillBlock(CFrame.new(1900,-12,1200),Vector3.new(768,24,768),Enum.Material.Water)
 local world=Instance.new("Model")world.Name="IlhaSerena"world.Parent=workspace
 for k,v in pairs(attributes)do world:SetAttribute(k,v)end
 world:SetAttribute("WorldLayout","ThreeCreatorIslands")world:SetAttribute("SeaLevel",0)
 world:SetAttribute("FountainWaterY",nil)world:SetAttribute("FountainOrigin",nil)
 local islands=Instance.new("Folder")islands.Name="Islands"islands.Parent=world
 local props=Instance.new("Folder")props.Name="Props"props.Parent=world
 local bridges=Instance.new("Folder")bridges.Name="TrilhasEMirante"bridges.Parent=world
 local ui=Instance.new("Folder")ui.Name="SerenaTemplates"ui.Parent=game.ReplicatedStorage
 local audit={assets={},stripped=0}
 local raw,c=import(13138901447)audit.stripped+=c local first=parentRoot(raw,"IlhaDoFarol")
 local raw,c=import(8143419396)audit.stripped+=c local second=parentRoot(raw,"IlhaVerde")
 local raw,c=import(139196111)audit.stripped+=c local secret=parentRoot(raw,"IlhaDoSol")
 local color=workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
 local function place(model,id,center,shore)
  for _,d in ipairs(model:GetDescendants())do
   if d:IsA("SpawnLocation")then d.Enabled=false d.Neutral=true d.Transparency=1 d.CanCollide=false d.CanQuery=false
   elseif d:IsA("BasePart")then
    d.Anchored=true d.CanTouch=false
    local tree=d:FindFirstAncestorWhichIsA("Model")local ancestor=d.Parent local foliage=false
    while ancestor and ancestor~=model do
     local n=ancestor.Name:lower()
     if n:find("tree",1,true)or n:find("bush",1,true)then foliage=true end
     ancestor=ancestor.Parent
    end
    local green=d.Material==Enum.Material.Grass or(d.Color.G>d.Color.R*1.3 and d.Color.G>d.Color.B*1.4)
    if foliage then
     d.CanCollide=false d.CanQuery=false
     if green then d:SetAttribute("SerenaRestCF",d.CFrame)Collection:AddTag(d,"SerenaWindFoliage")end
    else
     d.CanCollide=d.Transparency<.8 d.CanQuery=d.CanCollide
     if green or d.Material==Enum.Material.Grass then
      d:SetAttribute("SerenaGroundSurface",true)d:SetAttribute("SerenaGrassSurface",true)d.Color=color
     elseif d.Material==Enum.Material.Sand or d.Name=="Water"or(d.Color.R>.7 and d.Color.G>.5 and d.Color.B<.7 and d.Size.X*d.Size.Z>200)then
      d:SetAttribute("SerenaGroundSurface",true)d.Material=Enum.Material.Sand
     end
    end
    if id==139196111 then
     for _,m in ipairs(d:GetChildren())do if m:IsA("DataModelMesh")and math.max(m.Scale.X,m.Scale.Y,m.Scale.Z)>4 then m.Scale=Vector3.one end end
     if d.Name=="Water"then d.Material=Enum.Material.Sand d.CanCollide=true d.CanQuery=true end
    end
   end
  end
  local lo,hi=bounds(model)local origin=Vector3.new((lo.X+hi.X)/2,shore,(lo.Z+hi.Z)/2)
  normalize(model,origin)model:PivotTo(model:GetPivot()+center)
  model:SetAttribute("SourceAssetId",id)model:SetAttribute("IslandCenter",center)
  model:SetAttribute("ShoreAlignedY",.4)model:SetAttribute("HiddenIsland",id==139196111)
  model.Parent=islands
  for _,d in ipairs(model:GetDescendants())do if d:IsA("BasePart")and Collection:HasTag(d,"SerenaWindFoliage")then d:SetAttribute("SerenaRestCF",d.CFrame)end end
  lo,hi=bounds(model)audit.assets[#audit.assets+1]={id=id,name=model.Name,min={lo.X,lo.Y,lo.Z},max={hi.X,hi.Y,hi.Z}}
 end
 place(first,13138901447,Vector3.new(-140,.4,0),5.185140609741211)
 place(second,8143419396,Vector3.new(140,.4,0),7.45)
 place(secret,139196111,Vector3.new(1900,.4,1200),80.10281677246094)
 -- Mark movable scenery by real imported model, while protecting land and navigation.
 for _,island in ipairs(islands:GetChildren())do
  for _,m in ipairs(island:GetChildren())do if m:IsA("Model")then
   local n=m.Name:lower()
   if n:find("tree",1,true)or n:find("barrel",1,true)or n:find("bush",1,true)then
    m:SetAttribute("SerenaAdminMovable",true)Collection:AddTag(m,"SerenaAdminMovable")
    m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p.Color.G<p.Color.R*1.3 then p.CanQuery=true end end
   end
  end end
 end
 local hit1,hit2=rayFor(first),rayFor(second)
 local function edge(hit,from,to,step,z,maxY)
  local found
  for x=from,to,step do local h=hit(x,z or 0)if h and h.Position.Y>.15 and h.Position.Y<(maxY or 180) and h.Normal.Y>.55 then found=h.Position end end
  return found
 end
 local function clearSpan(l,r)
  local padA,padB=hit1(l.X-9,l.Z),hit2(r.X+9,r.Z)
  if not padA or not padB or padA.Position.Y<=.15 or padB.Position.Y<=.15 or padA.Position.Y>l.Y+.6 or padB.Position.Y>r.Y+.6 then return false end
  local samples=math.ceil((r-l).Magnitude/1.5)
  for i=0,samples do
   local t=i/samples local p=l:Lerp(r,t)+Vector3.new(0,15*4*t*(1-t),0)
   for _,dz in ipairs({-7,-5,0,5,7})do
    for _,hit in ipairs({hit1,hit2})do local ground=hit(p.X,p.Z+dz)
     if ground and ground.Position.Y>p.Y+.1 then return false end
    end
   end
  end
  return true
 end
 local a,b local best=math.huge
 for z=-76,76,2 do
  local l=edge(hit1,-220,-40,1,z,6)local r=edge(hit2,220,40,-1,z,6)
  if l and r then
   local lh,rh=hit1(l.X-5,z),hit2(r.X+5,z)
   if lh and rh and lh.Position.Y<7 and rh.Position.Y<7 and clearSpan(lh.Position,rh.Position)then
    local score=math.abs(lh.Position.Y-rh.Position.Y)+math.abs(z)*.01+(rh.Position.X-lh.Position.X)*.001
    if score<best then a,b=lh.Position,rh.Position best=score end
   end
  end
 end
 assert(a and b,"No aligned low shoreline for bridge")
 audit.bridgeEndpoints={{a.X,a.Y,a.Z},{b.X,b.Y,b.Z}}
 local bridge=Instance.new("Model")bridge.Name="PonteDePedra"bridge.Parent=bridges
 bridge:SetAttribute("BridgeCenter",(a+b)/2)bridge:SetAttribute("BridgeEndpointA",a)bridge:SetAttribute("BridgeEndpointB",b)
 bridge:SetAttribute("BridgeActivation","StandingOnMysticalStone")bridge:SetAttribute("AllStone",true)
 local length=b.X-a.X local width=13 local arch=math.min(15,length*.12)local segments=math.ceil(length/2.5)
 local function point(t)return a:Lerp(b,t)+Vector3.new(0,arch*4*t*(1-t),0)end
 local stone=Color3.fromRGB(164,172,163)local dark=Color3.fromRGB(108,125,116)
 local function visual(name,size,cf,delay)
  local p=part(bridge,name,size,cf,Enum.Material.Limestone,stone,false)
  p:SetAttribute("BridgeRestCF",cf)p:SetAttribute("BridgeAlpha",0)p:SetAttribute("BridgeRestSize",size)
  p:SetAttribute("BridgeRevealAt",delay or 0)return p
 end
 for i=0,segments-1 do
  local p,q=point(i/segments),point((i+1)/segments)local cf=CFrame.lookAt((p+q)/2,q)local size=Vector3.new(width,1,(q-p).Magnitude+.1)
  visual("BlocoDoArco",size,cf-cf.UpVector*.5,i*.025)
  local collider=part(bridge,"PisoFixo",size,cf-cf.UpVector*.5,Enum.Material.Limestone,stone,true,1)collider:SetAttribute("BridgeCollider",true)
  for _,side in ipairs({-1,1})do
   visual("ParapeitoDePedra",Vector3.new(.6,2.6,size.Z),cf*CFrame.new(side*(width/2-.3),1.2,0),i*.025+.04)
   local guard=part(bridge,"GuardaFixa",Vector3.new(.65,2.6,size.Z),cf*CFrame.new(side*(width/2-.3),1.2,0),Enum.Material.Limestone,stone,true,1)
   guard:SetAttribute("BridgeCollider",true)guard:SetAttribute("BridgeGuard",true)
   if i%3==0 then visual("PilarDoParapeito",Vector3.new(.9,3.1,.9),cf*CFrame.new(side*(width/2-.45),1.45,0),i*.025+.06)end
  end
 end
 for _,t in ipairs({.18,.82})do
  local p=point(t)
  for _,side in ipairs({-1,1})do
   local x=p+Vector3.new(0,0,side*(width/2+1))
   local tower=visual("TorreDePedra",Vector3.new(2.8,34,2.8),CFrame.new(x+Vector3.new(0,16,0)),segments*.025+.15)
   tower.Color=dark
   visual("CapitelDePedra",Vector3.new(4,1.2,4),CFrame.new(x+Vector3.new(0,33.7,0)),segments*.025+.3)
   local orb=visual("EsferaDePedra",Vector3.new(2.8,2.8,2.8),CFrame.new(x+Vector3.new(0,36,0)),segments*.025+.4)orb.Shape=Enum.PartType.Ball
  end
 end
 bridge:SetAttribute("AnimateConstruction",true)bridge:SetAttribute("ConstructionDuration",segments*.025+1.2)bridge:SetAttribute("DropHeight",12)
 Collection:AddTag(bridge,"SerenaSuspensionBridge")
 local lifecycle=require(game.ReplicatedStorage.SerenaRuntime.BridgeLifecycle)lifecycle.prepare(bridge)lifecycle.apply(bridge,lifecycle.new())
 -- Real mystical stones at both banks activate the stable stone arch.
 for index,p in ipairs({a,b})do
  local raw,c=import(110144096035671)audit.stripped+=c local pad=parentRoot(raw,"PedraMistica"..index)
  for _,d in ipairs(pad:GetDescendants())do if d:IsA("SpawnLocation")then d:Destroy()end end
  local lo,hi=bounds(pad)normalize(pad,Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2))
  pad:ScaleTo(.38)local side=index==1 and -9 or 9 local land=index==1 and first or second
  local ground=assert(rayFor(land)(p.X+side,p.Z),"Mystical stone has no bank")
  pad:PivotTo(CFrame.new(ground.Position-Vector3.new(0,.08,0)))pad:SetAttribute("SourceAssetId",110144096035671)
  pad:SetAttribute("BridgeActivator",true)pad.Parent=props
  for _,d in ipairs(pad:GetDescendants())do if d:IsA("BasePart")then d.Anchored=true d.CanCollide=d.Name=="Stone" d.CanQuery=d.CanCollide d.CanTouch=false end end
  Collection:AddTag(pad,"SerenaBridgeActivator")
 end
 -- Imported bench with genuine Seat instances, planted on native surface hits.
 local benchAsset,c=import(741384218)audit.stripped+=c
 local benchTemplate=Instance.new("Model")benchTemplate.Name="Banco"
 for _,child in ipairs(benchAsset:GetChildren())do child.Parent=benchTemplate end benchAsset:Destroy()
 local lo,hi=bounds(benchTemplate)normalize(benchTemplate,Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2))
 local benches=0
 for _,island in ipairs({first,second,secret})do
  local hit=rayFor(island)local center=island:GetAttribute("IslandCenter")
  for _,offset in ipairs({Vector3.new(-18,0,14),Vector3.new(18,0,-14)})do
   local h=hit(center.X+offset.X,center.Z+offset.Z)
   if h and h.Position.Y>.15 and h.Normal.Y>.7 then
    local m=benchTemplate:Clone()m.Name="Banco"..(benches+1)m:PivotTo(CFrame.new(h.Position-Vector3.new(0,.02,0))*CFrame.Angles(0,math.pi/2,0))
    m:SetAttribute("SourceAssetId",741384218)m:SetAttribute("SerenaAdminMovable",true)m.Parent=props Collection:AddTag(m,"SerenaAdminMovable")
    for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=p:IsA("Seat")p.CanCollide=true end end benches+=1
   end
  end
 end
 benchTemplate:Destroy()audit.benches=benches
 -- The real R6 showcase character belongs to the supplied dialogue package.
 local dialogueAsset,c=import(80608769509945)audit.stripped+=c local pack=dialogueAsset:FindFirstChild("Dialogue System")
 local npc=pack["Ungroup in Workspace"]:FindFirstChildOfClass("Model"):Clone()npc.Name="Viajante"
 for _,d in ipairs(npc:GetDescendants())do if d:IsA("ProximityPrompt")then d:Destroy()end end
 local gui=pack["Ungroup in StarterGui"]:FindFirstChildOfClass("ScreenGui"):Clone()gui.Name="SerenaDialogueTemplate"gui.Parent=ui
 local module=pack["Ungroup in ReplicatedStorage"]:FindFirstChild("DialogModule")
 local sounds=module and module:FindFirstChild("sounds")if sounds then sounds:Clone().Parent=ui end
 dialogueAsset:Destroy()
 local palm
 for _,m in ipairs(first:GetChildren())do if m:IsA("Model")and m.Name:lower():find("palm",1,true)then palm=m break end end
 assert(palm,"Coconut palm missing")
 local lo,hi=bounds(palm)local location=Vector3.new((lo.X+hi.X)/2+5,0,(lo.Z+hi.Z)/2)
 local floor=assert(hit1(location.X,location.Z),"NPC lacks dry ground")assert(floor.Position.Y>.15)
 local chair=part(props,"AssentoDoViajante",Vector3.new(2.2,.5,2.2),CFrame.new(floor.Position+Vector3.new(0,1.1,0)),Enum.Material.Wood,Color3.fromRGB(106,80,58))
 npc:PivotTo(CFrame.new(floor.Position+Vector3.new(0,3.1,0))*CFrame.Angles(0,math.pi/2,0))npc.Parent=world
 npc:SetAttribute("SourceAssetId",80608769509945)npc:SetAttribute("DoubleClickWindow",.7)
 local hum=npc:FindFirstChildOfClass("Humanoid")hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.AutoRotate=false hum.WalkSpeed=0
 for _,p in ipairs(npc:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=false p.CanTouch=false p.CanQuery=true end end
 npc.HumanoidRootPart.Anchored=true
 for _,name in ipairs({"Right Hip","Left Hip"})do local joint=npc.Torso:FindFirstChild(name)if joint then joint.C0=joint.C0*CFrame.Angles(-math.pi/2,0,0)end end
 for _,name in ipairs({"Right Shoulder","Left Shoulder"})do local joint=npc.Torso:FindFirstChild(name)if joint then joint.C0=joint.C0*CFrame.Angles(-.35,0,0)end end
 local billboard=npc.Head:FindFirstChild("gui")if billboard then
  billboard.MaxDistance=28 billboard.AlwaysOnTop=false
  if billboard:FindFirstChild("name")then billboard.name.Text="Viajante"end
  if billboard:FindFirstChild("arrow")then billboard.arrow.Text="Toque duas vezes"end
 end
 local click=Instance.new("ClickDetector")click.Name="ViajanteClick"click.MaxActivationDistance=12 click.Parent=npc
 world:SetAttribute("TraderPosition",floor.Position+Vector3.new(0,2,0))
 -- Keep functional boat/fishing contracts, at the new beach.
 local pier=Instance.new("Folder")pier.Name="PraiaEPier"pier.Parent=world
 local dock=Instance.new("Model")dock.Name="PierDeMadeira"dock.Parent=pier
 -- Find a genuine dry beach and extend the dock into clear water.
 local waterRay=RaycastParams.new()waterRay.FilterType=Enum.RaycastFilterType.Include waterRay.FilterDescendantsInstances={workspace.Terrain,islands}waterRay.RespectCanCollide=true
 local function seaHit(x,z)return workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-260,0),waterRay)end
 local function water(x,z)local h=seaHit(x,z)return h and h.Material==Enum.Material.Water end
 local shore local center=first:GetAttribute("IslandCenter")local lo=bounds(first)
 for z=lo.Z-5,center.Z-10,1 do
  local h=hit1(center.X-10,z)
  if h and h.Position.Y>.15 and h.Position.Y<2 and h.Normal.Y>.8 then
   local inner=hit1(center.X-10,z+4)
   if inner and inner.Position.Y>.15 and inner.Position.Y<2 and inner.Normal.Y>.8 then shore=inner.Position break end
  end
 end
 assert(shore,"No dry level beach for boarding")
 local deckPos=Vector3.new(shore.X,2.2,shore.Z-16)
 for _,dx in ipairs({-7,0,7})do for _,dz in ipairs({-10,0,10})do
  local h=seaHit(deckPos.X+dx,deckPos.Z+dz)
  assert(h and h.Position.Y<deckPos.Y-.6,"Dock intersects imported land")
 end end
 part(dock,"Deck",Vector3.new(14,.6,20),CFrame.new(deckPos-Vector3.new(0,.3,0)),Enum.Material.WoodPlanks,Color3.fromRGB(118,85,60))
 local rampStart=shore+Vector3.new(0,.08,0)local rampEnd=deckPos+Vector3.new(0,0,10)
 local rampCF=CFrame.lookAt((rampStart+rampEnd)/2,rampEnd)
 part(dock,"RampaDaPraia",Vector3.new(8,.6,(rampEnd-rampStart).Magnitude+.3),rampCF-rampCF.UpVector*.3,Enum.Material.WoodPlanks,Color3.fromRGB(135,100,68))
 for _,dx in ipairs({-6,6})do for _,dz in ipairs({-8,8})do
  part(dock,"PilarDoPier",Vector3.new(.6,4.5,.6),CFrame.new(deckPos+Vector3.new(dx,-1.9,dz)),Enum.Material.Wood,Color3.fromRGB(90,68,46))
 end end
 local rack=part(dock,"SuporteDasVaras",Vector3.new(.5,.5,.5),CFrame.new(npc.HumanoidRootPart.Position),Enum.Material.Wood,Color3.new(),false,1)
 local market=part(dock,"BalcaoDaPesca",Vector3.new(.5,.5,.5),CFrame.new(npc.HumanoidRootPart.Position),Enum.Material.Wood,Color3.new(),false,1)
 local prompt=Instance.new("ProximityPrompt")prompt.Name="SellPrompt"prompt.ActionText="Vender peixes"prompt.ObjectText="Peixaria"prompt.MaxActivationDistance=12 prompt.Enabled=false prompt.Parent=market
 local prompt=Instance.new("ProximityPrompt")prompt.Name="RodPrompt"prompt.Enabled=false prompt.Parent=rack
 local boatPoint=Vector3.new(deckPos.X+12,.9,deckPos.Z)
 assert(water(boatPoint.X,boatPoint.Z)and water(boatPoint.X-4,boatPoint.Z-7)and water(boatPoint.X+4,boatPoint.Z+7),"Boat bay overlaps land")
 boat:PivotTo(CFrame.new(boatPoint)*CFrame.Angles(0,math.pi,0))boat:SetAttribute("BoatHome",boat:GetPivot())boat.Parent=pier
 local boarding=part(dock,"Embarque",Vector3.new(1,1,1),CFrame.new(deckPos+Vector3.new(5,1,0)),Enum.Material.Wood,Color3.new(),false,1)
 local boardPrompt=Instance.new("ProximityPrompt")boardPrompt.Name="BoardPrompt"boardPrompt.ActionText="Entrar no barco"boardPrompt.ObjectText="Barco de pesca"boardPrompt.MaxActivationDistance=12 boardPrompt.Parent=boarding
 world:SetAttribute("DockExitCF",CFrame.new(shore+Vector3.new(0,3.3,0)))
 audit.dock={shore={shore.X,shore.Y,shore.Z},deck={deckPos.X,deckPos.Y,deckPos.Z},boat={boatPoint.X,boatPoint.Y,boatPoint.Z},rampGrade=math.abs(rampEnd.Y-rampStart.Y)/(Vector2.new(rampEnd.X-rampStart.X,rampEnd.Z-rampStart.Z).Magnitude)}
 -- Place independent spawn points on dry, clear surfaces. The secret island has no auto-spawn.
 local function spawnAt(island,x,z,name)
  local hit=assert(rayFor(island)(x,z),"Spawn lacks floor")assert(hit.Position.Y>.15)
  local cf=CFrame.new(hit.Position+Vector3.new(0,3.3,0))
  local marker=part(props,name,Vector3.new(1,1,1),cf,Enum.Material.SmoothPlastic,Color3.new(),false,1)
  marker:SetAttribute("SerenaNavigationProtected",true)return cf
 end
 local spawn=spawnAt(first,-170,22,"MainSpawn")
 local secretCenter=secret:GetAttribute("IslandCenter")local secretSpawn=spawnAt(secret,secretCenter.X+38,secretCenter.Z-30,"SecretSpawn")
 world:SetAttribute("MainSpawnCF",spawn)world:SetAttribute("SecretSpawnCF",secretSpawn)
 local marker=world.Props.SecretSpawn
 local back=Instance.new("ProximityPrompt")back.Name="ReturnPrompt"back.ActionText="Voltar às ilhas"back.ObjectText="Caminho de volta"back.MaxActivationDistance=12 back.Parent=marker
 local spawnLocation=Instance.new("SpawnLocation")spawnLocation.Name="IslandSpawn"spawnLocation.Size=Vector3.new(4,.2,4)
 spawnLocation.CFrame=spawn-Vector3.new(0,3.1,0)spawnLocation.Transparency=1 spawnLocation.Anchored=true spawnLocation.CanCollide=false
 spawnLocation.Neutral=true spawnLocation.Duration=0 spawnLocation.Parent=world
 -- A real, single-part store fishing rod. Unanchored and welded correctly for avatars.
 local rodAsset,c=import(11316383656)audit.stripped+=c local handle=rodAsset:FindFirstChildOfClass("UnionOperation")assert(handle,"Fishing rod handle missing")
 handle.Parent=nil rodAsset:Destroy()local tool=Instance.new("Tool")tool.Name="Vara de Pesca"tool.CanBeDropped=false tool.RequiresHandle=true
 handle.Name="Handle"handle.CFrame=CFrame.identity handle.Anchored=false handle.CanCollide=false handle.CanQuery=false handle.CanTouch=false handle.Massless=true handle.Parent=tool
 local tip=Instance.new("Attachment")tip.Name="LineTip"tip.Position=Vector3.new(0,0,-handle.Size.Z/2+.1)tip.Parent=handle
 tool.Grip=CFrame.new(0,-.15,-2.8)*CFrame.Angles(math.rad(-65),0,0)
 tool:SetAttribute("SourceAssetId",11316383656)tool:SetAttribute("SerenaItem","FishingRod")
 local old=game.ServerStorage.SerenaItems:FindFirstChild(tool.Name)if old then old:Destroy()end tool.Parent=game.ServerStorage.SerenaItems
 -- Preserve only the requested admin GUI skin; all imported execution paths are removed.
 local adminAsset,c=import(111176085924966)audit.stripped+=c local root=adminAsset:FindFirstChildOfClass("Folder")
 local skin=root.StarterGui.AdminPanelGui:Clone()skin.Name="SerenaAdminTemplate"skin.Enabled=false skin:SetAttribute("SourceAssetId",111176085924966)skin.Parent=ui
 adminAsset:Destroy()
 world:SetAttribute("AdminUserId",8344738123)world:SetAttribute("IslandCount",3)world:SetAttribute("PublicIslandCount",2)
 world:SetAttribute("HiddenIslandAssetId",139196111)world:SetAttribute("BridgeStoneAssetId",110144096035671)
 audit.trader={position={npc.HumanoidRootPart.Position.X,npc.HumanoidRootPart.Position.Y,npc.HumanoidRootPart.Position.Z},rig="R6",underCoconutPalm=true}
 audit.spawn={spawn:GetComponents()}audit.secretSpawn={secretSpawn:GetComponents()}
 return audit
end
return Builder
]========]).install()
local world=workspace.IlhaSerena

assert(world:GetAttribute("DockExitCF"),"Missing dry boat exit")

source(runtime,"ModuleScript","ItemRules",[========[local Rules={Price=30,RodPrice=20,StartingCoins=50,Award=10,AwardInterval=60,Duration=3,Cooldown=60}
local function finite(value,default)
 return type(value)=="number"and value==value and math.abs(value)<math.huge and value or default
end
function Rules.profile(data)
 data=type(data)=="table"and data or {}
 local credits={}
 if type(data.credits)=="table"then
  for _,id in ipairs(data.credits)do if type(id)=="string"and #id<=64 then table.insert(credits,id)end end
  while #credits>16 do table.remove(credits,1)end
 end
 return {version=3,coins=math.clamp(math.floor(finite(data.coins,Rules.StartingCoins)),0,1000000),
  apple=data.apple==true,rod=data.rod==true,nextAppleAt=math.max(0,finite(data.nextAppleAt,0)),credits=credits}
end
function Rules.apply(data,action,now,payload)
 local p=Rules.profile(data)
 if action=="BuyApple"then
  if p.apple then return p,false,"Você já tem esta maçã."end
  if p.coins<Rules.Price then return p,false,"Você precisa de 30 moedas."end
  p.coins-=Rules.Price p.apple=true return p,true,"Maçã comprada! Equipe na mochila e use."
 elseif action=="BuyRod"then
  if p.rod then return p,false,"Você já tem uma vara."end
  if p.coins<Rules.RodPrice then return p,false,"Você precisa de 20 moedas."end
  p.coins-=Rules.RodPrice p.rod=true return p,true,"Vara comprada! Equipe na mochila e pesque."
 elseif action=="UseApple"then
  if not p.apple then return p,false,"Compre a maçã primeiro."end
  if now<p.nextAppleAt then return p,false,"Aguarde "..math.ceil(p.nextAppleAt-now).." s para usar novamente."end
  p.nextAppleAt=now+Rules.Cooldown return p,true,"Invisível por 3 segundos."
 elseif action=="Award"then
  p.coins=math.min(1000000,p.coins+Rules.Award)return p,true,"+10 moedas por jogar na ilha."
 elseif action=="Credit"then
  if type(payload)~="table"or type(payload.id)~="string"or #payload.id<16 or #payload.id>64 then return p,false,"Crédito inválido."end
  local amount=finite(payload.amount,0)
  if amount<1 or amount>10000 or amount%1~=0 then return p,false,"Valor inválido."end
  for _,id in ipairs(p.credits)do if id==payload.id then return p,true,"Venda já registrada."end end
  p.coins=math.min(1000000,p.coins+amount)table.insert(p.credits,payload.id)
  while #p.credits>16 do table.remove(p.credits,1)end
  return p,true,"Venda registrada."
 end
 return p,false,"Ação inválida."
end
return Rules
]========])

source(runtime,"ModuleScript","TraderCore",[========[local Trader={DoubleClick=.7,Range=12,SessionSeconds=35}
function Trader.new(deps)
 local self={clicks={},sessions={},unlocked={},cooldowns={}}
 function self:tap(player)
  local now=deps.clock()
  if not deps.near(player,Trader.Range)then self.clicks[player]=nil self.sessions[player]=nil return false end
  local previous=self.clicks[player]
  if previous and now-previous>=.08 and now-previous<=Trader.DoubleClick then
   self.clicks[player]=nil self.unlocked[player]=true
   local nonce=deps.guid()self.sessions[player]={nonce=nonce,untilTime=now+Trader.SessionSeconds}
   deps.open(player,nonce)return true
  end
  self.clicks[player]=now return false
 end
 function self:choose(player,nonce,choice)
  local now=deps.clock()local session=self.sessions[player]
  if type(nonce)~="string"or not session or session.nonce~=nonce or now>session.untilTime or not deps.near(player,Trader.Range)then return false,"Converse com o viajante primeiro."end
  if self.cooldowns[player]and now-self.cooldowns[player]<.4 then return false,"Aguarde um instante."end self.cooldowns[player]=now
  if choice=="BuyApple"or choice=="BuyRod"then return deps.buy(player,choice)
  elseif choice=="SellFish"then return deps.sell(player)
  elseif choice=="Secret"and self.unlocked[player]then self.sessions[player]=nil return deps.teleport(player,"Secret")
  elseif choice=="Close"then self.sessions[player]=nil return true end
  return false,"Escolha indisponível."
 end
 function self:remove(player)self.clicks[player]=nil self.sessions[player]=nil self.unlocked[player]=nil self.cooldowns[player]=nil end
 return self
end
return Trader
]========])

source(runtime,"ModuleScript","BridgeGate",[========[local Gate={}
function Gate.onStone(model,root,humanoid)
 if not root or not humanoid or humanoid.Health<=0 then return false end
 local stone=model:FindFirstChild("Stone",true)if not stone then return false end
 local localPoint=stone.CFrame:PointToObjectSpace(root.Position)
 local feet=humanoid.RigType==Enum.HumanoidRigType.R6 and 3 or humanoid.HipHeight+root.Size.Y/2
 return math.abs(localPoint.X)<stone.Size.X*.46 and math.abs(localPoint.Z)<stone.Size.Z*.46
  and localPoint.Y-feet>=stone.Size.Y/2-.5 and localPoint.Y-feet<=stone.Size.Y/2+1.5
end
function Gate.onBridge(model,positions)
 local a,b=model:GetAttribute("BridgeEndpointA"),model:GetAttribute("BridgeEndpointB")
 for _,point in ipairs(positions)do
  if point.X>=a.X-22 and point.X<=b.X+22 and math.abs(point.Z-a.Z)<27 and point.Y>-.5 and point.Y<55 then return true end
 end
 return false
end
return Gate
]========])

source(runtime,"ModuleScript","AdminCore",[========[local Admin={UserId=8344738123}
local actions={Fly=true,FlyInput=true,Move=true,Undo=true,Bring=true,GoTo=true,Kick=true,Ban=true,Unban=true,Players=true}
local function vector(v)return typeof(v)=="Vector3"and v.X==v.X and v.Y==v.Y and v.Z==v.Z and v.Magnitude<10000 end
function Admin.allowed(p)return p and p.UserId==Admin.UserId end
function Admin.validFrame(cf)
 if typeof(cf)~="CFrame"then return false end
 for _,n in ipairs({cf:GetComponents()})do if n~=n or math.abs(n)>10000 then return false end end return true
end
function Admin.new(deps)
 local self={last={},history={}}
 function self:dispatch(p,action,data)
  if not Admin.allowed(p)then return false,"Sem permissão."end
  if not actions[action]or type(data)~="table"then return false,"Ação inválida."end
  local now=deps.clock()local interval=action=="FlyInput"and .045 or action=="Move"and .08 or .4
  local rateKey=action local previous=self.last[rateKey]
  if previous and now-previous<interval then return false,"Aguarde."end self.last[rateKey]=now
  if action=="Players"then return true,deps.roster()
  elseif action=="Fly"then if type(data.enabled)~="boolean"then return false,"Voo inválido."end return deps.fly(p,data.enabled)
  elseif action=="FlyInput"then if not vector(data.direction)or data.direction.Magnitude>1.01 then return false,"Direção inválida."end return deps.flyInput(p,data.direction)
  elseif action=="Move"then
   local target=data.target local cf=data.cf
   if not deps.movable(target)or not Admin.validFrame(cf)then return false,"Selecione um objeto do mapa."end
   local old=deps.pivot(target)if (old.Position-cf.Position).Magnitude>80 or cf.Y<-.5 or cf.Y>180 then return false,"Movimento fora do limite."end
   self.history[#self.history+1]={target=target,cf=old}if #self.history>40 then table.remove(self.history,1)end
   deps.move(target,cf)return true,"Objeto movido."
  elseif action=="Undo"then local record=table.remove(self.history)
   if not record or not deps.movable(record.target)then return false,"Nada para desfazer."end deps.move(record.target,record.cf)return true,"Movimento desfeito."
  elseif action=="Unban"then
   local id=tonumber(data.userId)if not id or id%1~=0 or id<=0 or id==Admin.UserId then return false,"ID inválido."end return deps.unban(id)
  else
   local id=tonumber(data.userId)if not id or id%1~=0 or id==Admin.UserId then return false,"Escolha outro jogador."end
   local target=deps.player(id)if not target then return false,"Jogador fora do servidor."end
   if action=="Bring"then return deps.teleport(target,p)
   elseif action=="GoTo"then return deps.teleport(p,target)
   elseif action=="Kick"then return deps.kick(target)
   elseif action=="Ban"then
    local hours=tonumber(data.hours)or 24
    if hours~=hours or hours<1 or hours>720 then return false,"Use de 1 a 720 horas."end
    return deps.ban(target,math.floor(hours*3600))
   end
  end
  return false,"Ação indisponível."
 end
 return self
end
return Admin
]========])

source(runtime,"ModuleScript","Dialogue",[========[-- Adapted from NPC Dialogue System 80608769509945; original NPC/UI artwork retained.
-- Uses UTF-8-safe grapheme reveal and releases response listeners on every close.
local Dialog={}Dialog.__index=Dialog
local Tween=game:GetService("TweenService")local Players=game:GetService("Players")
function Dialog.new(npc,gui)
 local self=setmetatable({npc=npc,gui=gui,connections={},generation=0},Dialog)
 local original=gui:WaitForChild("dialogResponses")
 if not original:IsA("ScrollingFrame")then
  local scroll=Instance.new("ScrollingFrame")scroll.Name=original.Name scroll.BackgroundTransparency=original.BackgroundTransparency scroll.BackgroundColor3=original.BackgroundColor3
  scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.CanvasSize=UDim2.new()scroll.ScrollBarThickness=4 scroll.ScrollBarImageColor3=Color3.fromRGB(162,197,174)
  scroll.ClipsDescendants=true scroll.BorderSizePixel=0 scroll.Parent=original.Parent
  for _,child in ipairs(original:GetChildren())do child.Parent=scroll end original:Destroy()original=scroll
 end
 self.list=original self.template=self.list:WaitForChild("template")
 self.template.Visible=false self.list.Visible=false
 self.list.AnchorPoint=Vector2.new(0,1)self.list.Position=UDim2.new(0,16,1,-88)
 self.list.Size=UDim2.fromOffset(340,244)
 for _,d in ipairs(self.list:GetChildren())do if d:IsA("UIListLayout")then d.Padding=UDim.new(0,6)end end
 self.text=npc.Head.gui.dialog
 self.event=Instance.new("BindableEvent")self.responded=self.event.Event
 return self
end
function Dialog:hideGui()
 self.generation+=1
 if self.tween then self.tween:Cancel()end
 for _,c in ipairs(self.connections)do c:Disconnect()end table.clear(self.connections)
 for _,b in ipairs(self.list:GetChildren())do if b:IsA("GuiButton")and b~=self.template then b:Destroy()end end
 self.list.Visible=false
 if self.text.Parent then self.text.Visible=false self.text.MaxVisibleGraphemes=-1 end
 local camera=workspace.CurrentCamera if camera then Tween:Create(camera,TweenInfo.new(.25),{FieldOfView=70}):Play()end
end
function Dialog:trigger(text,choices)
 self:hideGui()local generation=self.generation
 self.text.Text=text self.text.Visible=true self.text.TextTransparency=0 self.text.MaxVisibleGraphemes=0
 self.tween=Tween:Create(self.text,TweenInfo.new(math.min(2,utf8.len(text)*.025),Enum.EasingStyle.Linear),{MaxVisibleGraphemes=utf8.len(text)})self.tween:Play()
 self.list.Visible=true
 local camera=workspace.CurrentCamera
 if camera then
  self.list.Size=UDim2.fromOffset(math.min(360,math.max(160,camera.ViewportSize.X-32)),math.min(#choices*46,math.max(100,camera.ViewportSize.Y-124)))
  Tween:Create(camera,TweenInfo.new(.25),{FieldOfView=65}):Play()
 end
 for i,choice in ipairs(choices)do
  local b=self.template:Clone()b.Name="Choice_"..choice.id b.Visible=true b.Size=UDim2.new(1,0,0,40)b.LayoutOrder=i
  local label=b:FindFirstChild("text")if label then label.Text=choice.label label.TextScaled=false label.TextSize=14 label.RichText=false end
  b.Parent=self.list
  self.connections[#self.connections+1]=b.Activated:Connect(function()if self.generation==generation then self.event:Fire(choice.id)end end)
 end
end
function Dialog:Destroy()self:hideGui()self.event:Destroy()end
return Dialog
]========])

for _,name in ipairs({"SerenaShopService","SerenaFishingService"})do local old=game.ServerScriptService:FindFirstChild(name)if old then old:Destroy()end local f=Instance.new("BindableFunction")f.Name=name f.Parent=game.ServerScriptService end

for _,name in ipairs({"SerenaTrader","SerenaAdmin"})do local old=game.ReplicatedStorage:FindFirstChild(name)if old then old:Destroy()end local f=Instance.new("RemoteEvent")f.Name=name f.Parent=game.ReplicatedStorage end

source(game.ServerScriptService,"Script","SerenaBridgeServer",[========[local Players=game:GetService("Players")local RunService=game:GetService("RunService")
local runtime=game.ReplicatedStorage:WaitForChild("SerenaRuntime")local Bridge=require(runtime.BridgeLifecycle)local Gate=require(runtime.BridgeGate)
local world=workspace:WaitForChild("IlhaSerena")local model=world.TrilhasEMirante:WaitForChild("PonteDePedra")
local pads={world.Props.PedraMistica1,world.Props.PedraMistica2}local state=Bridge.new()Bridge.apply(model,state)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.15 then return end elapsed=0
 local trigger=false local positions={}
 for _,p in ipairs(Players:GetPlayers())do
  local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Health>0 and r then
   positions[#positions+1]=r.Position
   for _,pad in ipairs(pads)do if Gate.onStone(pad,r,h)then trigger=true end end
  end
 end
 local occupied=trigger or(state.visible and Gate.onBridge(model,positions))
 if Bridge.step(state,occupied,workspace:GetServerTimeNow())then Bridge.apply(model,state)end
end)
]========])

source(game.ServerScriptService,"Script","SerenaShopServer",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local DataStoreService=game:GetService("DataStoreService")
local Rules=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("ItemRules"))
local Effect=require(script.Parent:WaitForChild("SerenaInvisibility"))
local remote=RS:WaitForChild("SerenaShop")
local template=ServerStorage:WaitForChild("SerenaItems"):WaitForChild("Maçã da Névoa")
local store=DataStoreService:GetDataStore("SerenaItems_v1")
local profiles={} local temporary={} local busy={} local requestTimes={} local active={}
local function attributes(p,data)
 p:SetAttribute("SerenaCoins",data.coins) p:SetAttribute("SerenaAppleOwned",data.apple) p:SetAttribute("SerenaRodOwned",data.rod)
 p:SetAttribute("SerenaAppleReadyAt",data.nextAppleAt) p:SetAttribute("SerenaDataSaved",not temporary[p])
 p:SetAttribute("SerenaShopReady",true)
end
local function message(p,text,ok)
 if p.Parent then remote:FireClient(p,"Message",text,ok==true) end
end
local function transaction(p,action,payload)
 if not profiles[p] or busy[p] then return false,"Aguarde um instante." end
 busy[p]=true
 local now=workspace:GetServerTimeNow() local accepted=false local feedback=""
 local result
 if not temporary[p] then
  local ok,data=pcall(function()
   return store:UpdateAsync("u"..p.UserId,function(old)
    local nextData,succeeded,text=Rules.apply(old,action,now,payload)
    accepted=succeeded feedback=text return nextData
   end)
  end)
  if ok then result=Rules.profile(data)
  else
   -- Do not acknowledge a permanent purchase if saving failed.
   busy[p]=nil return false,"Não foi possível salvar agora. Tente novamente."
  end
 else result,accepted,feedback=Rules.apply(profiles[p],action,now,payload) end
 profiles[p]=result if p.Parent then attributes(p,result) end
 busy[p]=nil return accepted,feedback
end
-- Private server endpoint: clients cannot invoke BindableFunctions in ServerScriptService.
local currency=script.Parent:WaitForChild("SerenaCurrency")
currency.OnInvoke=function(p,amount,id)
 if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players then return false,"Jogador indisponível." end
 return transaction(p,"Credit",{amount=amount,id=id})
end
local useApple
local function ensureApple(p)
 if not profiles[p] or not profiles[p].apple then return nil end
 local backpack=p:FindFirstChildOfClass("Backpack") if not backpack then return nil end
 for _,container in ipairs({backpack,p.Character}) do
  if container then for _,d in ipairs(container:GetChildren()) do
   if d:IsA("Tool") and d:GetAttribute("SerenaItem")=="Apple" then return d end
  end end
 end
 local tool=template:Clone() tool.CanBeDropped=false tool.Parent=backpack
 tool.Activated:Connect(function()if p.Character and tool.Parent==p.Character then useApple(p) end end)
 return tool
end
local function ensureRod(p)
 if not profiles[p]or not profiles[p].rod then return nil end
 local backpack=p:FindFirstChildOfClass("Backpack")if not backpack then return nil end
 for _,container in pairs({backpack,p.Character})do if container then for _,t in ipairs(container:GetChildren())do if t:IsA("Tool")and t:GetAttribute("SerenaItem")=="FishingRod"then return t end end end end
 local rod=ServerStorage.SerenaItems["Vara de Pesca"]:Clone()rod.Parent=backpack return rod
end
local service=script.Parent:WaitForChild("SerenaShopService")
service.OnInvoke=function(p,action)
 if typeof(p)~="Instance"or not p:IsA("Player")or p.Parent~=Players or(action~="BuyApple"and action~="BuyRod")then return false,"Compra indisponível."end
 local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")local npc=workspace.IlhaSerena.Viajante
 if not r or(r.Position-npc.HumanoidRootPart.Position).Magnitude>14 then return false,"Converse com o viajante."end
 local ok,text=transaction(p,action)
 if action=="BuyApple"then ensureApple(p)else ensureRod(p)end return ok,text
end
useApple=function(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 or active[p] then return end
 local item=ensureApple(p) if not item then message(p,"Compre a maçã primeiro.",false) return end
 if item.Parent~=c then h:EquipTool(item) end
 local accepted,feedback=transaction(p,"UseApple")
 if not accepted then message(p,feedback,false) return end
 -- A respawn during DataStore I/O must never hide the replacement character.
 if not p.Parent or p.Character~=c or h.Health<=0 or not c.Parent then return end
 local restore=Effect.begin(c)
 active[p]={character=c,restore=restore}
 p:SetAttribute("SerenaInvisibleUntil",workspace:GetServerTimeNow()+Rules.Duration)
 message(p,feedback,true)
 task.delay(Rules.Duration,function()
  restore()
  if active[p] and active[p].character==c then active[p]=nil if p.Parent then p:SetAttribute("SerenaInvisibleUntil",0) end end
 end)
end
local function character(p,c)
 local effect=active[p]
 if effect then effect.restore() active[p]=nil p:SetAttribute("SerenaInvisibleUntil",0) end
 task.spawn(function()
  c:WaitForChild("Humanoid",10) p:WaitForChild("Backpack",10)
  if p.Character==c then ensureApple(p) ensureRod(p) end
 end)
end
local function added(p)
 p:SetAttribute("SerenaShopReady",false)
 p.CharacterAdded:Connect(function(c)character(p,c)end)
 local ok,data=pcall(function()
  return store:UpdateAsync("u"..p.UserId,function(old)return Rules.profile(old)end)
 end)
 if not p.Parent then return end
 profiles[p]=Rules.profile(ok and data or nil) temporary[p]=not ok
 attributes(p,profiles[p])
 if p.Character then character(p,p.Character) end
end
Players.PlayerAdded:Connect(function(p)task.spawn(added,p)end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
Players.PlayerRemoving:Connect(function(p)
 if active[p] then active[p].restore() end
 profiles[p]=nil temporary[p]=nil busy[p]=nil requestTimes[p]=nil active[p]=nil
end)
remote.OnServerEvent:Connect(function(p,action)
 if action~="BuyApple" and action~="UseApple" then return end
 local now=os.clock() if requestTimes[p] and now-requestTimes[p]<.35 then return end requestTimes[p]=now
 if action=="UseApple" then useApple(p) return end
 if not p:FindFirstChildOfClass("Backpack") then message(p,"Espere o personagem aparecer.",false) return end
 local accepted,feedback=service:Invoke(p,action)
 if accepted or (profiles[p] and profiles[p].apple) then ensureApple(p) ensureRod(p) end
 message(p,feedback,accepted)
end)
-- Rewards are generated by elapsed server time, never by a client claim.
task.spawn(function()
 local nextAward={}
 while true do
  local now=workspace:GetServerTimeNow()
  for _,p in ipairs(Players:GetPlayers()) do
   if profiles[p] then
    nextAward[p]=nextAward[p] or now+Rules.AwardInterval
    if now>=nextAward[p] and not busy[p] then
     nextAward[p]=now+Rules.AwardInterval
     task.spawn(function()local ok,text=transaction(p,"Award") if ok then message(p,text,true) end end)
    end
   end
  end
  for p in pairs(nextAward) do if not p.Parent then nextAward[p]=nil end end
  task.wait(1)
 end
end)
]========])

source(game.ServerScriptService,"Script","SerenaFishingServer",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Storage=game:GetService("ServerStorage")
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local core=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("FishingCore"))
local remote=RS:WaitForChild("SerenaFishing")local currency=script.Parent:WaitForChild("SerenaCurrency")
local items=Storage:WaitForChild("SerenaItems")local rodTemplate=items:WaitForChild("Vara de Pesca")local fishTemplate=items:WaitForChild("Carpa")
local world=workspace:WaitForChild("IlhaSerena")local pier=world:WaitForChild("PraiaEPier"):WaitForChild("PierDeMadeira")
local rodRack=pier:WaitForChild("SuporteDasVaras")local market=pier:WaitForChild("BalcaoDaPesca")
local fx=Instance.new("Folder")fx.Name="SerenaFishingFX"fx.Parent=workspace
local rng=Random.new()local requests={}
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain,world.Islands}ray.IgnoreWater=false
local function tool(p,attribute,value)
 local containers={p:FindFirstChildOfClass("Backpack"),p.Character}
 -- Avoid ipairs stopping at a temporarily absent backpack.
 for _,container in pairs(containers)do if container then for _,t in ipairs(container:GetChildren())do
  if t:IsA("Tool")and t:GetAttribute(attribute)==value then return t end
 end end end
end
local function character(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not r then return nil end
 local rod=tool(p,"SerenaItem","FishingRod")
 return {character=c,humanoid=h,root=r,rod=rod and rod.Parent==c and rod or nil}
end
local function giveRod(p,equip)
 local backpack=p:FindFirstChildOfClass("Backpack")local c=character(p)if not backpack or not c or not p:GetAttribute("SerenaRodOwned")then return nil end
 local t=tool(p,"SerenaItem","FishingRod")
 if not t then t=rodTemplate:Clone()t.Parent=backpack end
 if equip then c.humanoid:EquipTool(t)end return t
end
local function giveFish(p,record)
 if tool(p,"SerenaFishId",record.id)then return end
 local backpack=p:FindFirstChildOfClass("Backpack")if not backpack then return end
 local t=fishTemplate:Clone()t.Name=string.format("Carpa • %.2f kg",record.weight)t.CanBeDropped=false
 t:SetAttribute("SerenaFishId",record.id)t:SetAttribute("WeightKg",record.weight)t:SetAttribute("FishValue",record.value)
 t.Parent=backpack
end
local fishing=core.new({
 clock=function()return workspace:GetServerTimeNow()end,
 character=character,random=function(a,b)return rng:NextNumber(a,b)end,guid=function()return HttpService:GenerateGUID(false)end,
 send=function(p,event,data)if p.Parent then remote:FireClient(p,event,data)end end,
 nearRod=function(point)return (point-rodRack.Position).Magnitude<=16 end,
 nearMarket=function(point)return (point-market.Position).Magnitude<=16 end,
 giveRod=giveRod,giveFish=giveFish,
 takeFish=function(p,id)local t=tool(p,"SerenaFishId",id)if t then t:Destroy()end end,
 credit=function(p,amount,id)return currency:Invoke(p,amount,id)end,
 water=function(point)
  local hit=workspace:Raycast(Vector3.new(point.X,80,point.Z),Vector3.new(0,-180,0),ray)
  return hit and hit.Material==Enum.Material.Water and hit.Position or nil
 end,
 makeVisual=function(p,rod,water)
  local m=Instance.new("Model")m.Name="Boia_"..p.UserId m:SetAttribute("OwnerUserId",p.UserId)m:SetAttribute("WaterPosition",water)
  local ball=Instance.new("Part")ball.Name="Boia"ball.Shape=Enum.PartType.Ball ball.Size=Vector3.new(.52,.62,.52)ball.Color=Color3.fromRGB(245,97,70)
  ball.Material=Enum.Material.SmoothPlastic ball.Anchored=true ball.CanCollide=false ball.CanTouch=false ball.CanQuery=false
  local tip=rod:FindFirstChild("LineTip",true)local position=water+Vector3.new(0,.2,0)
  ball.CFrame=CFrame.new(tip and tip.WorldPosition or position)ball.Parent=m
  local a=Instance.new("Attachment")a.Parent=ball
  local beam=Instance.new("Beam")beam.Name="LinhaDaVara"beam.Attachment0=tip beam.Attachment1=a beam.Width0=.025 beam.Width1=.015
  beam.Color=ColorSequence.new(Color3.fromRGB(235,242,240))beam.Transparency=NumberSequence.new(.15)beam.FaceCamera=true beam.Segments=12 beam.CurveSize0=1 beam.CurveSize1=0 beam.Parent=ball
  m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=fx
  TweenService:Create(ball,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.new(position)}):Play()
  return m
 end,
 removeVisual=function(m)if m.Parent then m:Destroy()end end,
 biteVisual=function(m)
  m:SetAttribute("FishBiting",true)local ball=m:FindFirstChild("Boia")local water=m:GetAttribute("WaterPosition")
  if ball then ball.Color=Color3.fromRGB(66,222,208)TweenService:Create(ball,TweenInfo.new(.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,6,true),{CFrame=CFrame.new(water-Vector3.new(0,.17,0))}):Play()end
 end,
})
local function added(p)
 fishing:add(p)
 p.CharacterAdded:Connect(function(c)task.spawn(function()
  c:WaitForChild("Humanoid",10)p:WaitForChild("Backpack",10)
  if p.Parent and p.Character==c then fishing:respawn(p)end
 end)end)
end
Players.PlayerAdded:Connect(added)for _,p in ipairs(Players:GetPlayers())do added(p)end
Players.PlayerRemoving:Connect(function(p)fishing:remove(p)requests[p]=nil end)
local service=script.Parent:WaitForChild("SerenaFishingService")
service.OnInvoke=function(p,action)if p.Parent~=Players then return false,"Jogador indisponível."end if action=="Sell"then return fishing:sell(p)end return false,"Ação inválida."end
market:WaitForChild("SellPrompt").Triggered:Connect(function(p)fishing:sell(p)end)
remote.OnServerEvent:Connect(function(p,action,target)
 if type(action)~="string"then return end
 local now=os.clock()if requests[p]and now-requests[p]<.15 then return end requests[p]=now
 fishing:dispatch(p,action,target)
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)elapsed+=dt if elapsed>=.1 then elapsed=0 fishing:tick()end end)
script.Destroying:Connect(function()fx:Destroy()end)
]========])

source(game.ServerScriptService,"Script","SerenaBoatServer",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local core=require(RS:WaitForChild("SerenaRuntime"):WaitForChild("BoatController"))
local world=workspace:WaitForChild("IlhaSerena")
local boat=world:WaitForChild("PraiaEPier"):WaitForChild("BarcoDePesca")
local driver=boat:WaitForChild("DriverSeat")local passenger=boat:WaitForChild("PassengerSeat")
local remote=RS:WaitForChild("SerenaBoat")
local terrain=RaycastParams.new()terrain.FilterType=Enum.RaycastFilterType.Include terrain.FilterDescendantsInstances={workspace.Terrain,world.Islands}terrain.RespectCanCollide=true terrain.IgnoreWater=false
local obstacles=RaycastParams.new()obstacles.FilterType=Enum.RaycastFilterType.Exclude obstacles.RespectCanCollide=true obstacles.IgnoreWater=true
local function owner(seat)
 local h=seat.Occupant return h and h.Health>0 and Players:GetPlayerFromCharacter(h.Parent)or nil
end
local function surface(position)
 local hit=workspace:Raycast(Vector3.new(position.X,75,position.Z),Vector3.new(0,-170,0),terrain)
 return hit and hit.Material==Enum.Material.Water
end
local controller=core.new({
 clock=function()return workspace:GetServerTimeNow()end,
 driver=function()return owner(driver)end,passenger=function()return passenger.Occupant~=nil end,
 water=function(cf)
  for _,point in ipairs({Vector3.zero,Vector3.new(0,0,-5.6),Vector3.new(0,0,5.6),Vector3.new(-2.4,0,0),Vector3.new(2.4,0,0)})do
   if not surface(cf:PointToWorldSpace(point))then return false end
  end return true
 end,
 sweep=function(previous,nextCF)
  local exclude={boat}local effects=workspace:FindFirstChild("SerenaFishingFX")if effects then table.insert(exclude,effects)end
  for _,seat in ipairs({driver,passenger})do if seat.Occupant then table.insert(exclude,seat.Occupant.Parent)end end
  obstacles.FilterDescendantsInstances=exclude
  local displacement=nextCF.Position-previous.Position
  if displacement.Magnitude<.001 then return true end
  local hit=workspace:Blockcast(previous*CFrame.new(0,.2,0),Vector3.new(4.4,1.5,11),displacement,obstacles)
  return hit==nil
 end,
 move=function(cf,speed)
  local now=workspace:GetServerTimeNow()
  local bob=CFrame.new(0,math.sin(now*1.5)*.035,0)*CFrame.Angles(0,0,math.sin(now*1.1)*.008)
  boat:PivotTo(cf*bob)boat:SetAttribute("BoatSpeed",math.floor(math.abs(speed)*10+.5)/10)
 end,
},boat:GetAttribute("BoatHome"))
local requests={}
local function character(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not r then return end return c,h,r
end
local function board(p,seat)
 local c,h,r=character(p)if not c or seat.Occupant or h.SeatPart then return end
 if (r.Position-seat.Position).Magnitude>18 then return end
 h:UnequipTools()seat:Sit(h)
end
driver:WaitForChild("BoardPrompt").Triggered:Connect(function(p)board(p,driver)end)
passenger:WaitForChild("PassengerPrompt").Triggered:Connect(function(p)board(p,passenger)end)
local shorePrompt=world.PraiaEPier.PierDeMadeira:WaitForChild("Embarque"):WaitForChild("BoardPrompt")
shorePrompt.Triggered:Connect(function(p)
 if not driver.Occupant then board(p,driver)elseif not passenger.Occupant then board(p,passenger)end
end)
local function leave(p)
 local c,h=character(p)if not c or(h.SeatPart~=driver and h.SeatPart~=passenger)then return end
 local near=(boat:GetPivot().Position-boat:GetAttribute("BoatHome").Position).Magnitude<22
 h.Sit=false
 for _,seat in ipairs({driver,passenger})do
  local weld=seat:FindFirstChild("SeatWeld")if weld and weld.Part1 and weld.Part1:IsDescendantOf(c)then weld:Destroy()end
 end
 h:ChangeState(Enum.HumanoidStateType.Jumping)
 if near then task.delay(.15,function()
  if p.Character==c and h.Health>0 and not h.SeatPart then c:PivotTo(world:GetAttribute("DockExitCF")or world:GetAttribute("MainSpawnCF"))end
 end)end
end
remote.OnServerEvent:Connect(function(p,action,throttle,steer)
 local now=os.clock()if requests[p]and now-requests[p]<.07 then return end requests[p]=now
 if action=="Drive"then controller:drive(p,throttle,steer)
 elseif action=="Exit"then leave(p)end
end)
Players.PlayerRemoving:Connect(function(p)requests[p]=nil end)
RunService.Heartbeat:Connect(function(dt)controller:tick(dt)end)
for _,seat in ipairs({driver,passenger})do
 seat:GetPropertyChangedSignal("Occupant"):Connect(function()
  local p=owner(seat)if p then remote:FireClient(p,"Boarded",seat==driver)end
 end)
end
]========])

source(game.ServerScriptService,"Script","SerenaTraderServer",[========[local Players=game:GetService("Players")local Http=game:GetService("HttpService")
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
 open=function(p,nonce)p:SetAttribute("SerenaSecretDiscovered",true)remote:FireClient(p,"Open",{nonce=nonce,coins=p:GetAttribute("SerenaCoins")or 0})end,
 buy=function(p,choice)return shop:Invoke(p,choice)end,
 sell=function(p)return fishing:Invoke(p,"Sell")end,
 teleport=function(p,target)
  local c,r=character(p)if not c then return false,"Espere seu personagem."end
  local h=c:FindFirstChildOfClass("Humanoid")h.Sit=false
  c:PivotTo(world:GetAttribute(target=="Secret"and"SecretSpawnCF"or"MainSpawnCF"))
  r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
  return true,target=="Secret"and"Bem-vindo à ilha escondida."or"De volta às ilhas."
 end,
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
world.Props.SecretSpawn.ReturnPrompt.Triggered:Connect(function(p)
 local c,r=character(p)if not c or(r.Position-world.Props.SecretSpawn.Position).Magnitude>16 then return end
 c:FindFirstChildOfClass("Humanoid").Sit=false c:PivotTo(world:GetAttribute("MainSpawnCF"))r.AssemblyLinearVelocity=Vector3.zero
end)
Players.PlayerRemoving:Connect(function(p)trader:remove(p)rates[p]=nil end)
]========])

source(game.ServerScriptService,"Script","SerenaAdminServer",[========[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local world=workspace:WaitForChild("IlhaSerena")local Admin=require(RS.SerenaRuntime.AdminCore)
assert(Admin.UserId==world:GetAttribute("AdminUserId"),"Wrong admin identity")
local remote=RS:WaitForChild("SerenaAdmin")local flying={}
local function actor(p)
 local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not r then return nil end return c,h,r
end
local function stop(p)
 local state=flying[p]if not state then return end
 state.velocity:Destroy()state.orientation:Destroy()state.attachment:Destroy()
 if state.humanoid.Parent then state.humanoid.PlatformStand=state.platform state.humanoid.AutoRotate=state.rotate state.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end
 if state.root.Parent then state.root.AssemblyLinearVelocity=Vector3.zero end
 flying[p]=nil if p.Parent then p:SetAttribute("SerenaAdminFlying",false)end
end
local function movable(target)
 return typeof(target)=="Instance"and target:IsDescendantOf(world)and Collection:HasTag(target,"SerenaAdminMovable")
  and target:GetAttribute("SerenaAdminMovable")==true and not target:FindFirstChildOfClass("Humanoid")
end
local function pivot(target)return target:IsA("Model")and target:GetPivot()or target.CFrame end
local controller=Admin.new({
 clock=os.clock,
 roster=function()local list={}for _,p in ipairs(Players:GetPlayers())do list[#list+1]={id=p.UserId,name=p.Name,display=p.DisplayName}end return list end,
 player=function(id)return Players:GetPlayerByUserId(id)end,
 movable=movable,pivot=pivot,
 move=function(target,cf)
  if target:IsA("Model")then target:PivotTo(cf)else target.CFrame=cf end
  for _,d in ipairs(target:GetDescendants())do if d:IsA("BasePart")and Collection:HasTag(d,"SerenaWindFoliage")then d:SetAttribute("SerenaRestCF",d.CFrame)end end
 end,
 fly=function(p,enabled)
  if not enabled then stop(p)return true,"Voo desligado."end
  if flying[p]then return true,"Voo ativo."end
  local c,h,r=actor(p)if not c then return false,"Espere seu personagem."end
  h.Sit=false
  local a=Instance.new("Attachment")a.Name="AdminFlightAttachment"a.Parent=r
  local velocity=Instance.new("LinearVelocity")velocity.Name="AdminFlightVelocity"velocity.Attachment0=a velocity.RelativeTo=Enum.ActuatorRelativeTo.World velocity.MaxForce=math.huge velocity.VectorVelocity=Vector3.zero velocity.Parent=r
  local orientation=Instance.new("AlignOrientation")orientation.Name="AdminFlightOrientation"orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment orientation.Attachment0=a orientation.MaxTorque=math.huge orientation.Responsiveness=12 orientation.CFrame=r.CFrame orientation.Parent=r
  flying[p]={attachment=a,velocity=velocity,orientation=orientation,root=r,humanoid=h,platform=h.PlatformStand,rotate=h.AutoRotate,last=os.clock()}
  h.PlatformStand=true h.AutoRotate=false p:SetAttribute("SerenaAdminFlying",true)return true,"Voo ativo."
 end,
 flyInput=function(p,direction)
  local state=flying[p]if not state then return false,"Ative o voo."end state.last=os.clock()state.velocity.VectorVelocity=direction*42
  if direction.Magnitude>.05 then state.orientation.CFrame=CFrame.lookAt(Vector3.zero,Vector3.new(direction.X,0,direction.Z).Magnitude>.05 and Vector3.new(direction.X,0,direction.Z)or Vector3.new(0,0,-1))end
  return true
 end,
 teleport=function(from,to)
  local c,h,r=actor(from)local _,_,target=actor(to)if not c or not target then return false,"Personagem indisponível."end
  h.Sit=false c:PivotTo(target.CFrame*CFrame.new(4,0,0))r.AssemblyLinearVelocity=Vector3.zero return true,"Jogador teleportado."
 end,
 kick=function(target)target:Kick("Removido desta sessão pelo administrador.")return true,"Jogador removido."end,
 ban=function(target,duration)
  local ok=pcall(function()Players:BanAsync({UserIds={target.UserId},Duration=duration,DisplayReason="Suspensão aplicada pelo administrador da experiência.",PrivateReason="Admin panel, owner "..Admin.UserId,ExcludeAltAccounts=true,ApplyToUniverse=true})end)
  return ok,ok and"Suspensão aplicada."or"O Roblox não permitiu aplicar a suspensão agora."
 end,
 unban=function(id)local ok=pcall(function()Players:UnbanAsync({UserIds={id},ApplyToUniverse=true})end)return ok,ok and"Suspensão removida."or"Não foi possível remover agora."end,
})
remote.OnServerEvent:Connect(function(p,action,data)
 if not Admin.allowed(p)then return end
 local ok,result=controller:dispatch(p,action,data)
 if action~="FlyInput"then remote:FireClient(p,"Result",{ok=ok,action=action,value=result})end
end)
Run.Heartbeat:Connect(function()
 for p,state in pairs(flying)do
  if not p.Parent or not state.root.Parent or state.humanoid.Health<=0 or p.Character~=state.root.Parent then stop(p)
  elseif os.clock()-state.last>.5 then state.velocity.VectorVelocity=Vector3.zero end
 end
end)
Players.PlayerRemoving:Connect(stop)
Players.PlayerAdded:Connect(function(p)p.CharacterRemoving:Connect(function()stop(p)end)end)
for _,p in ipairs(Players:GetPlayers())do p.CharacterRemoving:Connect(function()stop(p)end)end
]========])

source(game.ServerScriptService,"Script","SerenaChatServer",[========[local Players=game:GetService("Players")local Chat=game:GetService("TextChatService")
local folder=Chat:FindFirstChild("TextChannels")
if not folder then folder=Instance.new("Folder")folder.Name="TextChannels"folder.Parent=Chat end
local channel=folder:FindFirstChild("RBXGeneral")
if not channel then channel=Instance.new("TextChannel")channel.Name="RBXGeneral"channel.Parent=folder end
pcall(function()Chat.ChatWindowConfiguration.Enabled=true Chat.ChatInputBarConfiguration.Enabled=true Chat.ChatInputBarConfiguration.TargetTextChannel=channel end)
local function add(player)pcall(function()channel:AddUserAsync(player.UserId)end)end
Players.PlayerAdded:Connect(add)for _,p in ipairs(Players:GetPlayers())do task.spawn(add,p)end
]========])

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaTraderClient",[========[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")local Run=game:GetService("RunService")
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
  d:trigger("Olá, viajante! Tenho itens e conheço um caminho que quase ninguém encontrou.",{
   {id="BuyApple",label="Maçã da Névoa · 30 moedas"},{id="BuyRod",label="Vara de pesca · 20 moedas"},
   {id="SellFish",label="Vender meus peixes"},{id="Secret",label="Conhecer o caminho escondido"},{id="Close",label="Até mais"},
  })
 elseif event=="Result"and dialogue then
  if data.choice=="Secret"and data.ok or data.choice=="Close"then close()
  elseif nonce then
   local suffix=" Você tem "..tostring(player:GetAttribute("SerenaCoins")or 0).." moedas."
   dialogue:trigger((data.text~=""and data.text or"Pronto!")..suffix,{{id="BuyApple",label="Comprar maçã"},{id="BuyRod",label="Comprar vara"},{id="SellFish",label="Vender peixes"},{id="Secret",label="Ir à ilha escondida"},{id="Close",label="Fechar"}})
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
]========])

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaAdminClient",[========[local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")local UIS=game:GetService("UserInputService")local Run=game:GetService("RunService")
local player=Players.LocalPlayer if player.UserId~=8344738123 then return end
local remote=RS:WaitForChild("SerenaAdmin")local Collection=game:GetService("CollectionService")
local skin=RS.SerenaTemplates.SerenaAdminTemplate:Clone()skin.Name="SerenaOwnerAdmin"skin.ResetOnSpawn=false skin.Enabled=true skin.DisplayOrder=60
local panel=skin:WaitForChild("AdminPanel")local button=skin:WaitForChild("AdminButton")
local originalAction=panel.Frames.GlobalMessage.SendButton:Clone()local originalBox=panel.Frames.GlobalMessage.MessageBox:Clone()
for _,d in ipairs(panel:GetChildren())do d:Destroy()end
panel.AnchorPoint=Vector2.new(0,0)panel.Position=UDim2.fromOffset(16,112)panel.Size=UDim2.fromOffset(330,450)panel.Visible=false
button.AnchorPoint=Vector2.new(0,0)button.Position=UDim2.fromOffset(16,64)button.Size=UDim2.fromOffset(44,40)button.Visible=true
skin.Parent=player:WaitForChild("PlayerGui")
local title=Instance.new("TextLabel")title.Size=UDim2.new(1,-60,0,36)title.Position=UDim2.fromOffset(14,8)title.BackgroundTransparency=1
title.Font=Enum.Font.GothamBold title.TextSize=17 title.TextColor3=Color3.fromRGB(232,246,235)title.Text="Admin · ch_ckz2n"title.TextXAlignment=Enum.TextXAlignment.Left title.Parent=panel
local close=Instance.new("TextButton")close.Size=UDim2.fromOffset(34,34)close.Position=UDim2.new(1,-42,0,7)close.Text="×"close.TextSize=25 close.BackgroundTransparency=1 close.TextColor3=title.TextColor3 close.Parent=panel
local list=Instance.new("ScrollingFrame")list.Name="AdminOptions"list.Position=UDim2.fromOffset(10,48)list.Size=UDim2.new(1,-20,1,-85)
list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=5 list.AutomaticCanvasSize=Enum.AutomaticSize.Y list.CanvasSize=UDim2.new()list.ClipsDescendants=true list.Parent=panel
local layout=Instance.new("UIListLayout")layout.Padding=UDim.new(0,7)layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=list
local status=Instance.new("TextLabel")status.Name="Status"status.Position=UDim2.new(0,12,1,-32)status.Size=UDim2.new(1,-24,0,26)
status.BackgroundTransparency=1 status.TextColor3=title.TextColor3 status.Font=Enum.Font.Gotham status.TextSize=11 status.TextWrapped=true status.Text="Só sua conta possui acesso."status.Parent=panel
local order=0 local controls={}local selectedUser local selectedObject local moving=false local axis=Vector3.zero
local function label(text)
 order+=1 local l=Instance.new("TextLabel")l.Size=UDim2.new(1,-8,0,26)l.BackgroundTransparency=1 l.Font=Enum.Font.GothamBold l.TextSize=13 l.TextColor3=title.TextColor3 l.Text=text l.LayoutOrder=order l.Parent=list
end
local function action(name,text,callback)
 order+=1 local b=originalAction:Clone()b.Name=name b.Size=UDim2.new(1,-8,0,38)b.LayoutOrder=order b.Visible=true b.Parent=list
 if b:FindFirstChild("TextLabel")then b.TextLabel.Text=text else b.Text=text end
 b.Activated:Connect(callback)controls[name]=b return b
end
local function box(name,placeholder)
 order+=1 local frame=originalBox:Clone()frame.Name=name frame.Size=UDim2.new(1,-8,0,48)frame.LayoutOrder=order frame.Parent=list
 local b=frame:FindFirstChildWhichIsA("TextBox",true)b.Text=""b.PlaceholderText=placeholder b.ClearTextOnFocus=false return b
end
button.Activated:Connect(function()panel.Visible=not panel.Visible if panel.Visible then remote:FireServer("Players",{})end end)
close.Activated:Connect(function()panel.Visible=false end)
label("AVISO NO CHAT")
local message=box("Message","Mensagem para o chat")
action("Announce","Enviar como Adm:",function()
 local text=message.Text:gsub("[%c]",""):sub(1,220)if text==""then return end
 local channel=game:GetService("TextChatService"):FindFirstChild("TextChannels")
 channel=channel and channel:FindFirstChild("RBXGeneral")
 if not channel then status.Text="O chat não está disponível nesta sessão."return end
 local ok=pcall(function()channel:SendAsync(text)end)
 status.Text=ok and"Mensagem enviada pelo chat Roblox."or"O Roblox não permitiu enviar esta mensagem."
end)
label("VOO")
action("Flight","Ativar / desligar voo",function()remote:FireServer("Fly",{enabled=not player:GetAttribute("SerenaAdminFlying")})end)
local heldUp=false local heldDown=false
local up=action("FlightUp","Subir · segure",function()end)local down=action("FlightDown","Descer · segure",function()end)
up.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then heldUp=true end end)
down.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then heldDown=true end end)
UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then heldUp=false heldDown=false end end)
label("MOVER OBJETOS")
action("SelectObject","Selecionar objeto no mapa",function()moving=not moving panel.Visible=false status.Text=moving and"Toque em um banco, árvore ou objeto."or"Seleção encerrada."end)
local highlight=Instance.new("Highlight")highlight.FillTransparency=.75 highlight.OutlineColor=Color3.fromRGB(111,228,190)highlight.Parent=workspace
local function change(delta,rotation)
 if not selectedObject or not selectedObject.Parent then status.Text="Selecione um objeto."return end
 local cf=selectedObject:IsA("Model")and selectedObject:GetPivot()or selectedObject.CFrame
 remote:FireServer("Move",{target=selectedObject,cf=rotation and cf*CFrame.Angles(0,math.rad(rotation),0)or cf+delta})
end
for _,row in ipairs({{"MoveLeft","←",Vector3.new(-2,0,0)},{"MoveRight","→",Vector3.new(2,0,0)},{"MoveFront","Frente",Vector3.new(0,0,-2)},{"MoveBack","Trás",Vector3.new(0,0,2)},{"MoveUp","Mais alto",Vector3.new(0,1,0)},{"MoveDown","Mais baixo",Vector3.new(0,-1,0)}})do action(row[1],row[2],function()change(row[3])end)end
action("Rotate","Girar 15°",function()change(Vector3.zero,15)end)
action("Undo","Desfazer movimento",function()remote:FireServer("Undo",{})end)
UIS.InputBegan:Connect(function(i,processed)
 if processed or not moving then return end
 if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
 local camera=workspace.CurrentCamera if not camera then return end local ray=camera:ScreenPointToRay(i.Position.X,i.Position.Y)
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={player.Character}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*350,params)local target=hit and hit.Instance
 while target and target~=workspace do if Collection:HasTag(target,"SerenaAdminMovable")then break end target=target.Parent end
 if target and target~=workspace then selectedObject=target highlight.Adornee=target moving=false panel.Visible=true status.Text="Selecionado: "..target.Name end
end)
label("JOGADORES")
local targetBox=box("Target","Nome exato de usuário / UserId")
local hours=box("Hours","Suspensão em horas · padrão 24")
local function targetId()
 local numeric=tonumber(targetBox.Text)if numeric then return numeric end
 for _,p in ipairs(Players:GetPlayers())do if p.Name:lower()==targetBox.Text:lower()then return p.UserId end end
 status.Text="Escolha o usuário exato."return nil
end
for _,row in ipairs({{"Bring","Trazer para perto de mim"},{"GoTo","Ir até o jogador"},{"Kick","Remover desta sessão"},{"Ban","Suspender jogador"},{"Unban","Remover suspensão"}})do
 action(row[1],row[2],function()local id=targetId()if id then remote:FireServer(row[1],{userId=id,hours=tonumber(hours.Text)or 24})end end)
end
remote.OnClientEvent:Connect(function(event,data)if event~="Result"then return end
 if data.action=="Players"and data.ok then local names={}for _,p in ipairs(data.value)do names[#names+1]=p.name end status.Text="Nesta sessão: "..table.concat(names,", ")
 else status.Text=type(data.value)=="string"and data.value or(data.ok and"Pronto."or"Não foi possível.")end
end)
local timer=0
Run.Heartbeat:Connect(function(dt)
 timer+=dt if timer<.1 then return end timer=0
 local camera=workspace.CurrentCamera if camera then panel.Size=UDim2.fromOffset(math.clamp(camera.ViewportSize.X-32,250,350),math.clamp(camera.ViewportSize.Y-150,180,500))end
 if player:GetAttribute("SerenaAdminFlying")then
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")
  local direction=h and h.MoveDirection or Vector3.zero
  local vertical=(heldUp or UIS:IsKeyDown(Enum.KeyCode.Space))and 1 or(heldDown or UIS:IsKeyDown(Enum.KeyCode.LeftControl))and -1 or 0
  direction+=Vector3.new(0,vertical,0)if direction.Magnitude>1 then direction=direction.Unit end
  remote:FireServer("FlyInput",{direction=direction})
 end
end)
originalAction:Destroy()originalBox:Destroy()
script.Destroying:Connect(function()highlight:Destroy()skin:Destroy()end)
]========])

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaAdminChat",[========[-- Chat transport stays in TextChatService: filtering and age/privacy rules are preserved.
local TextChat=game:GetService("TextChatService")local AdminId=8344738123
TextChat.OnIncomingMessage=function(message)
 if message.TextSource and message.TextSource.UserId==AdminId then
  local properties=Instance.new("TextChatMessageProperties")properties.PrefixText="<font color='#9bdad0'>Adm:</font>"return properties
 end
end
]========])

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaAmbienceClient",[========[local RunService=game:GetService("RunService")
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
 if d:IsA("PointLight") and not d:GetAttribute("AlwaysOn")then lamps[d]=true
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
]========])

source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","SerenaFishingClient",[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local world=workspace:WaitForChild("IlhaSerena")
local fishing=RS:WaitForChild("SerenaFishing")local boating=RS:WaitForChild("SerenaBoat")
local gui=Instance.new("ScreenGui")gui.Name="SerenaFishingUI"gui.ResetOnSpawn=false gui.IgnoreGuiInset=false gui.DisplayOrder=22 gui.Parent=player:WaitForChild("PlayerGui")
local function corners(o,r)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,r or 12)c.Parent=o end
local function text(parent,name,size,pos,label,bold)
 local t=Instance.new("TextLabel")t.Name=name t.Size=size t.Position=pos t.BackgroundTransparency=1 t.Text=label
 t.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham t.TextSize=bold and 13 or 12 t.TextColor3=Color3.fromRGB(224,235,230)t.TextWrapped=true t.Parent=parent return t
end
local function button(parent,name,label,size,pos)
 local b=Instance.new("TextButton")b.Name=name b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(53,104,95)b.TextColor3=Color3.fromRGB(243,255,248)
 b.Font=Enum.Font.GothamBold b.TextSize=13 b.Text=label b.AutoButtonColor=true b.Parent=parent corners(b,9)return b
end
local panel=Instance.new("Frame")panel.Name="FishingPanel"panel.AnchorPoint=Vector2.new(.5,1)panel.Position=UDim2.new(.5,0,1,-128)panel.Size=UDim2.fromOffset(284,118)
panel.BackgroundColor3=Color3.fromRGB(23,42,40)panel.BackgroundTransparency=.08 panel.Visible=false panel.Parent=gui corners(panel,14)
local stroke=Instance.new("UIStroke")stroke.Color=Color3.fromRGB(109,169,147)stroke.Transparency=.5 stroke.Thickness=1 stroke.Parent=panel
local title=text(panel,"Title",UDim2.new(1,-20,0,22),UDim2.fromOffset(10,6),"PESCARIA",true)
local status=text(panel,"Status",UDim2.new(1,-22,0,29),UDim2.fromOffset(11,27),"Compre uma vara com o viajante.",false)
local action=button(panel,"FishingAction","LANÇAR LINHA",UDim2.fromOffset(179,39),UDim2.fromOffset(10,62))
local cancel=button(panel,"FishingCancel","RECOLHER",UDim2.fromOffset(75,39),UDim2.fromOffset(199,62))cancel.TextSize=10 cancel.BackgroundColor3=Color3.fromRGB(54,65,62)
local sell=button(panel,"SellFish","VENDER",UDim2.fromOffset(75,39),UDim2.fromOffset(199,62))sell.TextSize=11
local bar=Instance.new("Frame")bar.Name="BiteProgress"bar.Position=UDim2.fromOffset(11,108)bar.Size=UDim2.new(1,-22,0,3)bar.BackgroundColor3=Color3.fromRGB(56,79,72)bar.BorderSizePixel=0 bar.Parent=panel corners(bar,2)
local fill=Instance.new("Frame")fill.Name="Fill"fill.Size=UDim2.fromScale(0,1)fill.BackgroundColor3=Color3.fromRGB(241,188,105)fill.BorderSizePixel=0 fill.Parent=bar corners(fill,2)
local boatPanel=Instance.new("Frame")boatPanel.Name="BoatPanel"boatPanel.AnchorPoint=Vector2.new(.5,1)boatPanel.Position=UDim2.new(.5,0,1,-128)boatPanel.Size=UDim2.fromOffset(284,115)
boatPanel.BackgroundColor3=Color3.fromRGB(23,42,40)boatPanel.BackgroundTransparency=.08 boatPanel.Visible=false boatPanel.Parent=gui corners(boatPanel,14)
local boatTitle=text(boatPanel,"BoatTitle",UDim2.new(1,-20,0,24),UDim2.fromOffset(10,4),"BARCO DE PESCA",true)
local boatHint=text(boatPanel,"BoatHint",UDim2.new(1,-20,0,23),UDim2.fromOffset(10,27),"WASD ou joystick • pule para sair",false)
local exit=button(boatPanel,"ExitBoat","SAIR",UDim2.fromOffset(54,38),UDim2.fromOffset(220,62))exit.TextSize=11
local controls={}
for i,row in ipairs({{"Left","◀"},{"Forward","▲"},{"Back","▼"},{"Right","▶"}})do
 local b=button(boatPanel,row[1],row[2],UDim2.fromOffset(44,38),UDim2.fromOffset(10+(i-1)*49,62))controls[row[1]]=b
end
local toast=Instance.new("Frame")toast.Name="FishingNotice"toast.AnchorPoint=Vector2.new(.5,1)toast.Position=UDim2.new(.5,0,1,-254)toast.Size=UDim2.fromOffset(284,46)
toast.BackgroundColor3=Color3.fromRGB(27,47,41)toast.Visible=false toast.Parent=gui corners(toast,11)
local toastText=text(toast,"NoticeText",UDim2.new(1,-20,1,-10),UDim2.fromOffset(10,5),"",false)
local state={phase="Idle",count=0,value=0,rod=false,deadline=0,maxFish=12}
local currentRod local activation local gripTween local originalGrip
local noticeId=0 local held={}local heldInputs={}
local function notice(message,ok)
 noticeId+=1 local id=noticeId toast.Visible=true toastText.Text=message
 toast.BackgroundColor3=ok and Color3.fromRGB(28,73,56)or Color3.fromRGB(78,56,39)
 task.delay(3.5,function()if noticeId==id then toast.Visible=false end end)
end
local function send(actionName,target)fishing:FireServer(actionName,target)end
local function aim(useMouse)
 local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")local camera=workspace.CurrentCamera
 if not root or not camera then return Vector3.zero end
 local ray
 if useMouse and not UIS.TouchEnabled then ray=player:GetMouse().UnitRay
 else ray=camera:ViewportPointToRay(camera.ViewportSize.X*.5,camera.ViewportSize.Y*.48)end
 local parameters=RaycastParams.new()parameters.FilterType=Enum.RaycastFilterType.Include parameters.FilterDescendantsInstances={workspace.Terrain,world:WaitForChild("Islands")}parameters.RespectCanCollide=true parameters.IgnoreWater=false
 local hit=workspace:Raycast(ray.Origin,ray.Direction*250,parameters)
 if hit and(hit.Position-root.Position).Magnitude<=42 then return hit.Position end
 local forward=camera.CFrame.LookVector*Vector3.new(1,0,1)
 if forward.Magnitude<.1 then forward=root.CFrame.LookVector*Vector3.new(1,0,1)end
 return root.Position+forward.Unit*25
end
local function castAnimation()
 local rod=currentRod if not rod then return end
 if gripTween then gripTween:Cancel()end
 originalGrip=originalGrip or rod.Grip
 gripTween=TweenService:Create(rod,TweenInfo.new(.18,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Grip=originalGrip*CFrame.Angles(math.rad(25),0,0)})gripTween:Play()
 task.delay(.22,function()
  if currentRod==rod and rod.Parent==player.Character then
   gripTween=TweenService:Create(rod,TweenInfo.new(.28,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Grip=originalGrip})gripTween:Play()
  end
 end)
end
local function act(useMouse)
 if not currentRod then
  if player:GetAttribute("SerenaRodOwned")then send("GetRod")else notice("Compre a vara com o viajante por 20 moedas.",false)end return
 end
 if state.phase=="Bite"then send("Reel")castAnimation()
 elseif state.phase=="Idle"then send("Cast",aim(useMouse))castAnimation()
 else send("Cancel")end
end
local function connectButton(b,fn)b.Activated:Connect(fn)end
connectButton(action,function()act(false)end)
connectButton(cancel,function()send("Cancel")end)
connectButton(sell,function()send("Sell")end)
connectButton(exit,function()boating:FireServer("Exit")end)
for name,b in pairs(controls)do
 b.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then held[name]=true heldInputs[input]=name end
 end)
end
UIS.InputEnded:Connect(function(input)local name=heldInputs[input]if name then heldInputs[input]=nil held[name]=nil end end)
local function resetRod()
 if activation then activation:Disconnect()activation=nil end
 if gripTween then gripTween:Cancel()gripTween=nil end
 if currentRod and currentRod.Parent and originalGrip then currentRod.Grip=originalGrip end
 currentRod=nil originalGrip=nil
end
fishing.OnClientEvent:Connect(function(event,data)
 if event=="State"then state=data
 elseif event=="Message"then notice(data.text,data.ok)
 elseif event=="Caught"then notice(string.format("Carpa • %.2f kg • %d moedas",data.weight,data.value),true)end
end)
boating.OnClientEvent:Connect(function(event,isDriver)
 if event=="Boarded"then notice(isDriver and "Use WASD, joystick ou as setas para navegar."or "Você pode equipar a vara e pescar aqui.",true)end
end)
local elapsed=0 local driveElapsed=0 local seatedPreviously=false
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt driveElapsed+=dt if elapsed<.1 then return end elapsed=0
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not root then panel.Visible=false boatPanel.Visible=false resetRod()return end
 local equipped
 for _,t in ipairs(c:GetChildren())do if t:IsA("Tool")and t:GetAttribute("SerenaItem")=="FishingRod"then equipped=t break end end
 if equipped~=currentRod then
  resetRod()currentRod=equipped
  if equipped then originalGrip=equipped.Grip activation=equipped.Activated:Connect(function()act(true)end)end
 end
 local near=(root.Position-world:GetAttribute("TraderPosition")).Magnitude<=16
 local seat=h.SeatPart local inBoat=seat and seat:GetAttribute("SerenaBoatSeat")==true
 local driving=inBoat and seat:IsA("VehicleSeat")
 panel.Visible=currentRod~=nil or(near and not inBoat and player:GetAttribute("SerenaRodOwned")==true)
 boatPanel.Visible=inBoat and not currentRod or false
 title.Text=string.format("PESCARIA  •  %d/%d  •  %d moedas",state.count or 0,state.maxFish or 12,state.value or 0)
 cancel.Visible=currentRod~=nil and state.phase~="Idle"sell.Visible=not cancel.Visible and near
 if not currentRod then
  action.Text="EQUIPAR VARA"status.Text="Sua vara está na mochila • venda os peixes com o viajante."
 elseif state.phase=="Waiting"then action.Text="RECOLHER LINHA"status.Text="Aguarde a boia afundar."
 elseif state.phase=="Bite"then action.Text="PUXAR AGORA!"status.Text="Fisgou! Puxe antes de o peixe escapar."
 else action.Text="LANÇAR LINHA"status.Text="Mire na água e lance a linha."end
 local bite=state.phase=="Bite"action.BackgroundColor3=bite and Color3.fromRGB(151,103,40)or Color3.fromRGB(53,104,95)
 fill.Size=UDim2.fromScale(bite and math.clamp((state.deadline-workspace:GetServerTimeNow())/3,0,1)or 0,1)
 for _,b in pairs(controls)do b.Visible=driving end
 boatTitle.Text=driving and "BARCO DE PESCA • CONDUTOR"or "BARCO DE PESCA • PASSAGEIRO"
 boatHint.Text=driving and "WASD, joystick ou setas • pule para sair"or "Equipe sua vara para pescar no barco."
 if not inBoat and seatedPreviously then table.clear(held)table.clear(heldInputs)end seatedPreviously=inBoat==true
 if driving and driveElapsed>=.1 then
  driveElapsed=0
  local throttle=held.Forward and 1 or(held.Back and -1 or seat.ThrottleFloat)
  local steer=held.Right and 1 or(held.Left and -1 or seat.SteerFloat)
  boating:FireServer("Drive",throttle,steer)
 end
end)
player.CharacterAdded:Connect(function()resetRod()table.clear(held)table.clear(heldInputs)send("Sync")end)
task.delay(2,function()send("Sync")end)
script.Destroying:Connect(function()resetRod()gui:Destroy()end)
]========])

local old=game.ServerScriptService:FindFirstChild("SerenaDoorServer")if old then old:Destroy()end

local grass=factory([========[local Grass={}
function Grass.install(world,runtime)
 local Codec=require(runtime.GrassCodec)local template=runtime.SkinnedGrassTemplates.GrassCard
 local mesh=template:FindFirstChildOfClass("MeshPart")local bones={}
 for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end
 table.sort(bones,function(a,b)return a.Name<b.Name end)assert(#bones==100)
 local old=runtime:FindFirstChild("GrassCoverage")if old then old:Destroy()end
 local coverage=Instance.new("Folder")coverage.Name="GrassCoverage"coverage.Parent=runtime
 local minimum,maximum,spacing=-256,2304,4
 for k,v in pairs({FormatVersion=2,Spacing=spacing,Min=minimum,Max=maximum,GridCount=(maximum-minimum)/spacing+1,
  BoneCount=100,SourceAssetId=87377915371959,NearRadiusTouch=48,NearRadiusDesktop=80,MaxActiveTouch=640,MaxActiveDesktop=1600})do coverage:SetAttribute(k,v)end
 local Http=game:GetService("HttpService")local batch={}local chunks=0 local count=0 local roots=0 local byIsland={}
 local function flush()
  if #batch==0 then return end chunks+=1 local child=Instance.new("StringValue")child.Name=string.format("Chunk%04d",chunks)
  child.Value=Http:JSONEncode(batch)child.Parent=coverage batch={}
 end
 for _,island in ipairs(world.Islands:GetChildren())do
  local groundParts={}local lo=Vector3.new(math.huge,math.huge,math.huge)local hi=-lo
  for _,p in ipairs(island:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("SerenaGroundSurface")then
   groundParts[#groundParts+1]=p
   for _,x in ipairs({-1,1})do for _,z in ipairs({-1,1})do local point=p.CFrame:PointToWorldSpace(Vector3.new(p.Size.X*x/2,0,p.Size.Z*z/2))lo=lo:Min(point)hi=hi:Max(point)end end
  end end
  assert(#groundParts>0,"Island ground mask missing")
  local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={island}ray.RespectCanCollide=true
  local function green(x,z)
   local h=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-260,0),ray)
   if h and h.Instance:GetAttribute("SerenaGrassSurface")and h.Position.Y>.15 and h.Normal.Y>.2 then return h.Position.Y end
  end
  local ix0,ix1=math.floor((lo.X-minimum)/4)-1,math.ceil((hi.X-minimum)/4)+1
  local iz0,iz1=math.floor((lo.Z-minimum)/4)-1,math.ceil((hi.Z-minimum)/4)+1
  local localCount,localRoots=0,0
  for ix=ix0,ix1 do for iz=iz0,iz1 do
   local x,z=minimum+ix*4,minimum+iz*4
   local central=green(x,z)local base=math.floor((central or 0)*100+.5)local heights={}local valid=0
   for i,b in ipairs(bones)do
    local y=green(x+b.CFrame.X,z+b.CFrame.Z)
    if y then heights[i]=math.floor(y*100+.5)-base valid+=1 else heights[i]=Codec.Invalid end
   end
   if valid>0 then count+=1 roots+=valid localCount+=1 localRoots+=valid
    batch[#batch+1]={ix,iz,base,Codec.encode(heights),valid}
    if #batch>=128 then flush()end
   end
  end if ix%8==0 then task.wait()end end
  byIsland[#byIsland+1]={name=island.Name,patches=localCount,roots=localRoots,bounds={lo.X,lo.Z,hi.X,hi.Z}}
  assert(localCount>5,"An island has no grass coverage")
 end
 flush()coverage:SetAttribute("PatchCount",count)coverage:SetAttribute("RootCount",roots)
 world:SetAttribute("GrassCoveragePatches",count)world:SetAttribute("GrassCoverageRoots",roots)world:SetAttribute("GrassSpacing",4)
 return{patches=count,greenRoots=roots,chunks=chunks,spacing=4,islands=byIsland}
end
return Grass
]========]).install(world,runtime)

local tests=run([========[local world=workspace.IlhaSerena local runtime=game.ReplicatedStorage.SerenaRuntime
local Collider=require(runtime.BridgeGate)local Bridge=require(runtime.BridgeLifecycle)
assert(#world.Islands:GetChildren()==3 and world:GetAttribute("PublicIslandCount")==2)
assert(not world:FindFirstChild("VilaCosteira")and not world:FindFirstChild("Bosque"),"Old island remains")
local a,b=world.TrilhasEMirante.PonteDePedra:GetAttribute("BridgeEndpointA"),world.TrilhasEMirante.PonteDePedra:GetAttribute("BridgeEndpointB")
assert(a.Y>.15 and b.Y>.15 and a.Y<7 and b.Y<7 and (a-b).Magnitude>100,"Bridge banks misaligned")
local bridge=world.TrilhasEMirante.PonteDePedra
for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")then assert(p.Material==Enum.Material.Limestone and not p.CanCollide,"Bridge is not initially hidden stone")end end
local fixed={}for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")then fixed[p]=p.CFrame end end
local state=Bridge.new()assert(Bridge.step(state,false,0)==nil)
local pad=world.Props.PedraMistica1 local stone=pad:FindFirstChild("Stone",true)
local root=Instance.new("Part")root.Size=Vector3.new(2,2,1)root.CFrame=stone.CFrame*CFrame.new(0,stone.Size.Y/2+3,0)
local humanoid={Health=100,RigType=Enum.HumanoidRigType.R6}
assert(Collider.onStone(pad,root,humanoid),"Standing on stone does not activate")
root.CFrame+=Vector3.new(20,0,0)assert(not Collider.onStone(pad,root,humanoid),"Nearby player triggers stone")
assert(Bridge.step(state,true,1)=="Show")Bridge.apply(bridge,state)
for p,cf in pairs(fixed)do assert(p.CanCollide and p.CFrame==cf,"Moving bridge floor")end
assert(Bridge.step(state,false,2)==nil and Bridge.step(state,false,61)==nil and Bridge.step(state,false,62)=="Hide")
Bridge.apply(bridge,state)assert(Bridge.step(state,true,63)=="Show")Bridge.apply(bridge,state)
for p,cf in pairs(fixed)do assert(p.CanCollide and p.CFrame==cf)end Bridge.apply(bridge,Bridge.new())root:Destroy()
local benchCount=0 local seated=0 local parts=0 local foreign=0
for _,p in ipairs(world:GetDescendants())do
 if p:IsA("BasePart")then parts+=1 if not p:IsDescendantOf(world.Viajante)then assert(p.Anchored,"Loose scenery")end if p:IsA("Seat")then seated+=1 end
 elseif p:IsA("LuaSourceContainer")then foreign+=1 end
end
for _,p in ipairs(world.Props:GetChildren())do if p:GetAttribute("SourceAssetId")==741384218 then benchCount+=1 end end
assert(benchCount==6 and seated>=12 and foreign==0,"Imported bench/scripts changed")
assert(world.Viajante:FindFirstChildOfClass("Humanoid").RigType==Enum.HumanoidRigType.R6 and world.Viajante.ViajanteClick.MaxActivationDistance==12)
assert((world:GetAttribute("SecretSpawnCF").Position-world:GetAttribute("MainSpawnCF").Position).Magnitude>1700,"Secret island visible beside main islands")
local rules=require(runtime.ItemRules)local p=rules.profile({coins=50,apple=false})
p=select(1,rules.apply(p,"BuyApple",0))p=select(1,rules.apply(p,"BuyRod",1))assert(p.apple and p.rod and p.coins==0,"NPC purchases incorrect")
local _,ok=rules.apply(p,"BuyRod",2)assert(not ok,"Duplicate rod charge")
local existing=rules.profile({version=2,coins=121,apple=true,credits={"1234567890123456"}})assert(existing.apple and existing.coins==121 and not existing.rod,"Save migration loses items")
local tool=game.ServerStorage.SerenaItems["Vara de Pesca"]
assert(tool:GetAttribute("SourceAssetId")==11316383656 and tool.Handle:IsA("UnionOperation")and tool.Handle.LineTip)
for _,p in ipairs(tool:GetDescendants())do if p:IsA("BasePart")then assert(not p.Anchored and p.Massless and not p.CanCollide,"Rod freezes avatar")end end
local Trader=require(runtime.TraderCore)local now=0 local near=true local open=0 local bought=0 local traveled=0 local player={}
local trader=Trader.new({clock=function()return now end,guid=function()return"valid-nonce"end,near=function()return near end,
 open=function()open+=1 end,buy=function()bought+=1 return true end,sell=function()return true end,teleport=function()traveled+=1 return true end})
assert(not trader:tap(player))now=.2 assert(trader:tap(player)and open==1)
assert(not trader:choose(player,"forged","Secret"))assert(trader:choose(player,"valid-nonce","BuyRod")and bought==1)
now=1 assert(trader:choose(player,"valid-nonce","Secret")and traveled==1)
now=2 assert(not trader:choose(player,"valid-nonce","Secret"),"Secret session can be replayed")
near=false now=3 assert(not trader:tap(player),"Far NPC click accepted")
local Admin=require(runtime.AdminCore)local owner={UserId=8344738123}local outsider={UserId=1}local mutations=0 local banned=0 local obj={}local target={UserId=2}
local controller=Admin.new({clock=function()return now end,roster=function()return{}end,player=function(id)return id==2 and target or nil end,
 movable=function(t)return t==obj end,pivot=function()return CFrame.new(0,2,0)end,move=function()mutations+=1 end,
 fly=function()mutations+=1 return true end,flyInput=function()mutations+=1 return true end,
 teleport=function()mutations+=1 return true end,kick=function()mutations+=1 return true end,
 ban=function()banned+=1 return true end,unban=function()banned+=1 return true end})
for _,action in ipairs({"Fly","Move","Bring","Ban","Kick","Unban"})do assert(not controller:dispatch(outsider,action,{}),"Non-owner admin command accepted")end
assert(mutations==0 and banned==0)
assert(controller:dispatch(owner,"Move",{target=obj,cf=CFrame.new(3,2,0)})and mutations==1)
now+=1 assert(controller:dispatch(owner,"Undo",{})and mutations==2)
now+=1 assert(not controller:dispatch(owner,"Move",{target={},cf=CFrame.new()}),"Protected scenery can move")
now+=1 assert(not controller:dispatch(owner,"Ban",{userId=8344738123}),"Owner can ban self")
now+=1 assert(controller:dispatch(owner,"Ban",{userId=2,hours=24})and banned==1)
now+=1 assert(not controller:dispatch(owner,"FlyInput",{direction=Vector3.new(0/0,0,0)}),"NaN flight input accepted")
return {threeRealIslands=true,oldIslandRemoved=true,shorelineBridgeAligned=true,stoneTriggerAnd60SecondGrace=true,
 bridgeStableFloor=true,benches=benchCount,seatCount=seated,parts=parts,foreignScripts=foreign,secretDoubleClick=true,
 privateSecretRoute=true,appleAndRodPersistentPurchases=true,realRodUnanchored=true,ownerOnlyAdmin=true,
 protectedMoveAndUndo=true,selfBanBlocked=true,adminIdentity=8344738123}
]========])

local clients=run([========[local fixture=Instance.new("Folder")fixture.Name="ClientQA84"fixture.Parent=game.ServerStorage
local GUI=Instance.new("Folder")GUI.Parent=fixture
local function signal()
 local s={callbacks={}}
 function s:Connect(fn)local record={live=true,fn=fn}self.callbacks[#self.callbacks+1]=record return{Disconnect=function()record.live=false end}end
 function s:Fire(...)for _,record in ipairs(self.callbacks)do if record.live then record.fn(...)end end end return s
end
local bindings={}local attrs={}local sent={}
local player={UserId=1,Character=nil}
function player:WaitForChild(name)assert(name=="PlayerGui")return GUI end
function player:GetAttribute(name)return attrs[name]end
local players={LocalPlayer=player}function players:GetPlayers()return{{UserId=1,Name="Guest",DisplayName="Guest"},{UserId=8344738123,Name="ch_ckz2n",DisplayName="Owner"}}end
local remote={OnClientEvent=signal()}function remote:FireServer(action,data)sent[#sent+1]={action=action,data=data}end
local RS={SerenaTemplates=game.ReplicatedStorage.SerenaTemplates}function RS:WaitForChild(name)assert(name=="SerenaAdmin")return remote end
local input={InputBegan=signal(),InputEnded=signal()}local space=false function input:IsKeyDown(key)return key==Enum.KeyCode.Space and space end
local run={Heartbeat=signal()}local fakeGame={}
function fakeGame:GetService(name)if name=="Players"then return players elseif name=="ReplicatedStorage"then return RS elseif name=="UserInputService"then return input elseif name=="RunService"then return run end return game:GetService(name)end
local mock={Destroying=signal()}
local source=game.StarterPlayer.StarterPlayerScripts.SerenaAdminClient.Source
source=source:gsub("b%.Activated:Connect%(callback%)","env.bind(b,callback)")
source=source:gsub("button%.Activated:Connect%(","env.bind(button,")
source=source:gsub("close%.Activated:Connect%(","env.bind(close,")
local m=Instance.new("ModuleScript")m.Parent=fixture m.Source="return function(env)\nlocal game=env.game local script=env.script\n"..source.."\nend"
local execute=require(m)
local function bind(b,fn)bindings[b]=fn return{Disconnect=function()bindings[b]=nil end}end
execute({game=fakeGame,script=mock,bind=bind})
assert(#GUI:GetChildren()==0,"Non-owner sees admin GUI")
player.UserId=8344738123
execute({game=fakeGame,script=mock,bind=bind})
local skin=GUI.SerenaOwnerAdmin assert(skin and bindings[skin.AdminButton])
bindings[skin.AdminButton]()assert(skin.AdminPanel.Visible and sent[#sent].action=="Players","Owner panel cannot open")
local list=skin.AdminPanel.AdminOptions
assert(list:IsA("ScrollingFrame")and list.AutomaticCanvasSize==Enum.AutomaticSize.Y and list.ClipsDescendants)
bindings[list.Flight]()assert(sent[#sent].action=="Fly"and sent[#sent].data.enabled,"Flight button missing")
attrs.SerenaAdminFlying=true space=true run.Heartbeat:Fire(.12)
assert(sent[#sent].action=="FlyInput"and sent[#sent].data.direction.Y==1,"Touch/keyboard flight cannot ascend")
bindings[list.Undo]()assert(sent[#sent].action=="Undo")
local target=list.Target:FindFirstChildWhichIsA("TextBox",true)target.Text="Guest"
bindings[list.Bring]()assert(sent[#sent].action=="Bring"and sent[#sent].data.userId==1,"Bring button targets wrong user")
bindings[list.Ban]()assert(sent[#sent].action=="Ban"and sent[#sent].data.hours==24,"Ban options incorrect")
mock.Destroying:Fire()
-- Native imported dialogue UI and real R6 NPC, preserving UTF-8 characters.
local gui=game.ReplicatedStorage.SerenaTemplates.SerenaDialogueTemplate:Clone()gui.Parent=GUI
local dialog=require(game.ReplicatedStorage.SerenaRuntime.Dialogue).new(workspace.IlhaSerena.Viajante,gui)
dialog:trigger("Olá, viajante! Maçã e pescaria.",{{id="BuyApple",label="Maçã · 30 moedas"},{id="Secret",label="Ilha escondida"}})
assert(dialog.list:IsA("ScrollingFrame")and dialog.list.AutomaticCanvasSize==Enum.AutomaticSize.Y and dialog.list.ClipsDescendants,"Dialogue choices must scroll on mobile")
assert(dialog.list.Visible and dialog.list.Choice_BuyApple and dialog.list.Choice_Secret,"Imported dialogue choices missing")
task.wait(.85)assert(dialog.text.MaxVisibleGraphemes==utf8.len(dialog.text.Text),"Portuguese dialogue reveal breaks accents")
dialog:hideGui()assert(not dialog.list.Visible and not dialog.list:FindFirstChild("Choice_Secret"),"Dialogue response listeners remain")
dialog:Destroy()gui:Destroy()
assert(game.StarterPlayer.StarterPlayerScripts.SerenaAdminClient.Source:find("channel:SendAsync(text)",1,true),"Announcement bypasses Roblox chat")
assert(game.StarterPlayer.StarterPlayerScripts.SerenaAdminChat.Source:find("message.TextSource.UserId==AdminId",1,true),"Admin chat prefix can be impersonated")
fixture:Destroy()
return {nonOwnerNoAdminGUI=true,actualOwnerAdminClient=true,scrollingAdminPanel=true,flightAndBringButtons=true,
 importedDialogueUI=true,portugueseGraphemes=true,dialogueCleanup=true,robloxChatTransport=true}
]========])

local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
 local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
end end end
local climate=require(runtime.Climate)local profile=climate.profile(12,0,1,0)profile.hour=12 climate.apply(game.Lighting,workspace.Terrain,profile)
world:SetAttribute("UpgradeVersion",84)
local navigation=run([========[local world=workspace.IlhaSerena
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={world.Islands,workspace.Terrain}ray.RespectCanCollide=true
local function ground(point)return workspace:Raycast(Vector3.new(point.X,180,point.Z),Vector3.new(0,-260,0),ray)end
local deck=world.PraiaEPier.PierDeMadeira.Deck
local below=ground(deck.Position)
local boat=world.PraiaEPier.BarcoDePesca local water=ground(boat:GetPivot().Position)
assert(water and water.Material==Enum.Material.Water,"Boat starts under land")
assert(below and below.Position.Y<deck.Position.Y-deck.Size.Y/2,"Pier buried")
local bp=world.PraiaEPier.PierDeMadeira.Embarque.Position assert((bp-boat:GetPivot().Position).Magnitude<12,"Boarding outside reach")
local exit=world:GetAttribute("DockExitCF").Position local exitHit=ground(exit)assert(exitHit and exitHit.Material~=Enum.Material.Water and math.abs(exit.Y-exitHit.Position.Y-3.3)<.05,"Boat exit unsafe")
local bridge=world.TrilhasEMirante.PonteDePedra local samples=0 local maxGrade=0
for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")and not p:GetAttribute("BridgeGuard")then
 local f=p.CFrame.LookVector local grade=math.abs(f.Y)/math.sqrt(f.X*f.X+f.Z*f.Z)maxGrade=math.max(maxGrade,grade) samples+=1
end end assert(maxGrade<.6,"Stone bridge too steep")
return{boatOnOpenWater=true,bridgeFloorSamples=samples,maxGrade=maxGrade,pierTop=deck.Position.Y+deck.Size.Y/2,underPier=below and below.Position.Y or nil,pierUnderMaterial=below and tostring(below.Material)or nil}]========])
local bridgeSurfaceAudit=run([========[local world=workspace.IlhaSerena local bridge=world.TrilhasEMirante.PonteDePedra
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={world.Islands}ray.RespectCanCollide=true
local bad={}local checked=0
for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")and not p:GetAttribute("BridgeGuard")then
 for _,x in ipairs({-5,0,5})do for _,z in ipairs({-p.Size.Z*.45,0,p.Size.Z*.45})do
  local pt=p.CFrame:PointToWorldSpace(Vector3.new(x,p.Size.Y/2,z))
  local h=workspace:Raycast(Vector3.new(pt.X,180,pt.Z),Vector3.new(0,-260,0),ray)checked+=1
  if h and h.Position.Y>pt.Y+.15 then bad[#bad+1]={bridge={pt.X,pt.Y,pt.Z},ground=h.Position.Y}end
 end end
end end
assert(#bad==0,"Bridge width intersects island")
return{checked=checked,blocked=#bad,examples={bad[1],bad[2],bad[3]},stoneY=world.Props.PedraMistica1:GetPivot().Position.Y}]========])
local coverageAudit=run([========[local runtime=game.ReplicatedStorage.SerenaRuntime local world=workspace.IlhaSerena
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template:FindFirstChildOfClass("MeshPart")local bones={}
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
local Codec=require(runtime.GrassCodec)local bins={}local minimum=runtime.GrassCoverage:GetAttribute("Min")local spacing=4 local total=0
local function key(x,z)return math.floor(x*2)..":"..math.floor(z*2)end
for _,chunk in ipairs(runtime.GrassCoverage:GetChildren())do if chunk:IsA("StringValue")then for _,cell in ipairs(game.HttpService:JSONDecode(chunk.Value))do
 local raw=Codec.decode(cell[4],#bones)
 for index,b in ipairs(bones)do local y=Codec.height(raw,index,cell[3])if y then
  local x,z=minimum+cell[1]*spacing+b.CFrame.X,minimum+cell[2]*spacing+b.CFrame.Z
  local k=key(x,z)bins[k]=bins[k]or{}table.insert(bins[k],Vector3.new(x,y,z))total+=1
 end end
end end end
local results={}local samples=0 local gaps=0 local maxDistance=0
for _,island in ipairs(world.Islands:GetChildren())do
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={island}params.RespectCanCollide=true
 local lo,hi=island:GetBoundingBox()local position=lo.Position local size=hi
 local tested=0 local missed=0 local farthest=0
 for x=math.floor(position.X-size.X/2)+1,position.X+size.X/2,2 do for z=math.floor(position.Z-size.Z/2)+1,position.Z+size.Z/2,2 do
  local h=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-260,0),params)
  if h and h.Instance:GetAttribute("SerenaGrassSurface")and h.Position.Y>.15 and h.Normal.Y>.55 then
   tested+=1 local nearest=math.huge
   for bx=math.floor(x*2)-2,math.floor(x*2)+2 do for bz=math.floor(z*2)-2,math.floor(z*2)+2 do
    for _,p in ipairs(bins[bx..":"..bz]or{})do local d=Vector2.new(p.X-x,p.Z-z).Magnitude if d<nearest then nearest=d end end
   end end
   if nearest>.9 then missed+=1 end farthest=math.max(farthest,nearest)
  end
 end end
 samples+=tested gaps+=missed maxDistance=math.max(maxDistance,farthest)results[#results+1]={name=island.Name,samples=tested,gaps=missed,maxRootDistance=farthest}
end
assert(gaps==0,"Grass coverage has interior gaps")
return{samples=samples,gaps=gaps,maxRootDistance=maxDistance,roots=total,islands=results}
]========])
local preflight=run([============[assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")
assert(game.PlaceVersion==83,"Expected source version 83")
local world=workspace:WaitForChild("IlhaSerena")local RS=game.ReplicatedStorage local runtime=RS.SerenaRuntime
assert(world:GetAttribute("UpgradeVersion")==84 and world:GetAttribute("WorldLayout")=="ThreeCreatorIslands")
assert(world:GetAttribute("PublicIslandCount")==2 and #world.Islands:GetChildren()==3)
local wanted={IlhaDoFarol=13138901447,IlhaVerde=8143419396,IlhaDoSol=139196111}local assets={}
for name,id in pairs(wanted)do local island=world.Islands:FindFirstChild(name)assert(island and island:GetAttribute("SourceAssetId")==id)
 assert(island:GetAttribute("ShoreAlignedY")==.4)assets[#assets+1]={name=name,id=id,hidden=island:GetAttribute("HiddenIsland")}
end
assert(not world:FindFirstChild("VilaCosteira")and not world:FindFirstChild("Bosque"))
local parts,foreign,seats,benches=0,0,0,0
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then parts+=1 if p:IsA("Seat")then seats+=1 end
 if not p:IsDescendantOf(world.Viajante)then assert(p.Anchored,"Loose scenery")end
 elseif p:IsA("LuaSourceContainer")then foreign+=1 end
end
for _,p in ipairs(world.Props:GetChildren())do if p:GetAttribute("SourceAssetId")==741384218 then benches+=1 end end
assert(foreign==0 and parts==6130 and benches==6 and seats>=12)
assert(world.Viajante:GetAttribute("SourceAssetId")==80608769509945 and world.Viajante.ViajanteClick.MaxActivationDistance==12)
assert(world.Viajante.Humanoid.RigType==Enum.HumanoidRigType.R6)
local secret=world:GetAttribute("SecretSpawnCF")assert((secret.Position-world:GetAttribute("MainSpawnCF").Position).Magnitude>1700)
local bridge=world.TrilhasEMirante.PonteDePedra assert(bridge:GetAttribute("AllStone")and bridge:GetAttribute("BridgeActivation")=="StandingOnMysticalStone")
local floors,visuals,guards=0,0,0
for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")then
 assert(p.Material==Enum.Material.Limestone and not p.CanCollide and p.Transparency==1,"Bridge saved in wrong initial state")
 if p:GetAttribute("BridgeCollider")then if p:GetAttribute("BridgeGuard")then guards+=1 else floors+=1 end else visuals+=1 assert(p:GetAttribute("BridgeRestCF")and p:GetAttribute("BridgeRevealAt"))end
end end assert(floors==102 and guards==204 and visuals>250)
for _,name in ipairs({"PedraMistica1","PedraMistica2"})do local pad=world.Props[name]assert(pad:GetAttribute("SourceAssetId")==110144096035671 and pad:GetAttribute("BridgeActivator"))end
local coverage=runtime.GrassCoverage assert(coverage:GetAttribute("PatchCount")==969 and coverage:GetAttribute("RootCount")==79892 and coverage:GetAttribute("Spacing")==4)
assert(coverage:GetAttribute("SourceAssetId")==87377915371959 and #coverage:GetChildren()==8)
assert(coverage:GetAttribute("NearRadiusTouch")==48 and coverage:GetAttribute("MaxActiveTouch")==640)
local color=workspace.Terrain:GetMaterialColor(Enum.Material.Grass)local mesh=runtime.SkinnedGrassTemplates.GrassCard:FindFirstChildOfClass("MeshPart")assert((Vector3.new(mesh.Color.R,mesh.Color.G,mesh.Color.B)-Vector3.new(color.R,color.G,color.B)).Magnitude<.01)
local Admin=require(runtime.AdminCore)assert(Admin.UserId==8344738123 and world:GetAttribute("AdminUserId")==8344738123)
assert(Admin.allowed({UserId=8344738123})and not Admin.allowed({UserId=1}))
assert(RS.SerenaTemplates.SerenaAdminTemplate:GetAttribute("SourceAssetId")==111176085924966)
assert(game.StarterPlayer.StarterPlayerScripts.SerenaAdminChat.Source:find("message.TextSource.UserId==AdminId",1,true))
assert(game.StarterPlayer.StarterPlayerScripts.SerenaAdminClient.Source:find("channel:SendAsync(text)",1,true))
local Rules=require(runtime.ItemRules)assert(Rules.Price==30 and Rules.RodPrice==20 and Rules.Duration==3 and Rules.Cooldown==60)
local rod=game.ServerStorage.SerenaItems["Vara de Pesca"]assert(rod:GetAttribute("SourceAssetId")==11316383656 and not rod.Handle.Anchored and not rod.Handle.CanCollide)
local fishClient=game.StarterPlayer.StarterPlayerScripts.SerenaFishingClient.Source
assert(fishClient:find('world:GetAttribute("TraderPosition")',1,true)and not fishClient:find("grátis",1,true))
assert(game.ServerScriptService.SerenaBoatServer.Source:find("workspace.Terrain,world.Islands",1,true)and not game.ServerScriptService.SerenaBoatServer.Source:find("Vector3.new(100",1,true))
local Personal=require(runtime.PersonalClimate)local hours={Dia=12,Noite=23,Anoitecer=18.3,Chuva=15.2}
for mode,hour in pairs(hours)do local h,wet,clear,selected=Personal.resolve(mode)assert(math.abs(h-hour)<.01 and selected==mode)
 local p=require(runtime.Climate).profile(h,wet,clear,0)assert(p.wind.Magnitude>.1)
end
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts})do for _,s in ipairs(parent:GetChildren())do if s:IsA("Script")or s:IsA("LocalScript")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage
 local ok,result=pcall(require,m)m:Destroy()assert(ok,s.Name..":"..tostring(result))compiled+=1
 for line in s.Source:gmatch("[^\n]+")do assert(not line:find("VilaCosteira",1,true)and not line:find("Bosque",1,true),"Runtime still waits for old island")end
end end end assert(compiled==20)
local function run(code)local m=Instance.new("ModuleScript")m.Source="return function()\n"..code.."\nend"m.Parent=game.ServerStorage local v=require(m)()m:Destroy()return v end
local navigation=run([========[local world=workspace.IlhaSerena
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={world.Islands,workspace.Terrain}ray.RespectCanCollide=true
local function ground(point)return workspace:Raycast(Vector3.new(point.X,180,point.Z),Vector3.new(0,-260,0),ray)end
local deck=world.PraiaEPier.PierDeMadeira.Deck
local below=ground(deck.Position)
local boat=world.PraiaEPier.BarcoDePesca local water=ground(boat:GetPivot().Position)
assert(water and water.Material==Enum.Material.Water,"Boat starts under land")
assert(below and below.Position.Y<deck.Position.Y-deck.Size.Y/2,"Pier buried")
local bp=world.PraiaEPier.PierDeMadeira.Embarque.Position assert((bp-boat:GetPivot().Position).Magnitude<12,"Boarding outside reach")
local exit=world:GetAttribute("DockExitCF").Position local exitHit=ground(exit)assert(exitHit and exitHit.Material~=Enum.Material.Water and math.abs(exit.Y-exitHit.Position.Y-3.3)<.05,"Boat exit unsafe")
local bridge=world.TrilhasEMirante.PonteDePedra local samples=0 local maxGrade=0
for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")and not p:GetAttribute("BridgeGuard")then
 local f=p.CFrame.LookVector local grade=math.abs(f.Y)/math.sqrt(f.X*f.X+f.Z*f.Z)maxGrade=math.max(maxGrade,grade) samples+=1
end end assert(maxGrade<.6,"Stone bridge too steep")
return{boatOnOpenWater=true,bridgeFloorSamples=samples,maxGrade=maxGrade,pierTop=deck.Position.Y+deck.Size.Y/2,underPier=below and below.Position.Y or nil,pierUnderMaterial=below and tostring(below.Material)or nil}]========])
local bridgeSurfaceAudit=run([========[local world=workspace.IlhaSerena local bridge=world.TrilhasEMirante.PonteDePedra
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={world.Islands}ray.RespectCanCollide=true
local bad={}local checked=0
for _,p in ipairs(bridge:GetChildren())do if p:IsA("BasePart")and p:GetAttribute("BridgeCollider")and not p:GetAttribute("BridgeGuard")then
 for _,x in ipairs({-5,0,5})do for _,z in ipairs({-p.Size.Z*.45,0,p.Size.Z*.45})do
  local pt=p.CFrame:PointToWorldSpace(Vector3.new(x,p.Size.Y/2,z))
  local h=workspace:Raycast(Vector3.new(pt.X,180,pt.Z),Vector3.new(0,-260,0),ray)checked+=1
  if h and h.Position.Y>pt.Y+.15 then bad[#bad+1]={bridge={pt.X,pt.Y,pt.Z},ground=h.Position.Y}end
 end end
end end
assert(#bad==0,"Bridge width intersects island")
return{checked=checked,blocked=#bad,examples={bad[1],bad[2],bad[3]},stoneY=world.Props.PedraMistica1:GetPivot().Position.Y}]========])
local coverageAudit=run([========[local runtime=game.ReplicatedStorage.SerenaRuntime local world=workspace.IlhaSerena
local template=runtime.SkinnedGrassTemplates.GrassCard local mesh=template:FindFirstChildOfClass("MeshPart")local bones={}
for _,b in ipairs(mesh:GetChildren())do if b:IsA("Bone")then bones[#bones+1]=b end end table.sort(bones,function(a,b)return a.Name<b.Name end)
local Codec=require(runtime.GrassCodec)local bins={}local minimum=runtime.GrassCoverage:GetAttribute("Min")local spacing=4 local total=0
local function key(x,z)return math.floor(x*2)..":"..math.floor(z*2)end
for _,chunk in ipairs(runtime.GrassCoverage:GetChildren())do if chunk:IsA("StringValue")then for _,cell in ipairs(game.HttpService:JSONDecode(chunk.Value))do
 local raw=Codec.decode(cell[4],#bones)
 for index,b in ipairs(bones)do local y=Codec.height(raw,index,cell[3])if y then
  local x,z=minimum+cell[1]*spacing+b.CFrame.X,minimum+cell[2]*spacing+b.CFrame.Z
  local k=key(x,z)bins[k]=bins[k]or{}table.insert(bins[k],Vector3.new(x,y,z))total+=1
 end end
end end end
local results={}local samples=0 local gaps=0 local maxDistance=0
for _,island in ipairs(world.Islands:GetChildren())do
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={island}params.RespectCanCollide=true
 local lo,hi=island:GetBoundingBox()local position=lo.Position local size=hi
 local tested=0 local missed=0 local farthest=0
 for x=math.floor(position.X-size.X/2)+1,position.X+size.X/2,2 do for z=math.floor(position.Z-size.Z/2)+1,position.Z+size.Z/2,2 do
  local h=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-260,0),params)
  if h and h.Instance:GetAttribute("SerenaGrassSurface")and h.Position.Y>.15 and h.Normal.Y>.55 then
   tested+=1 local nearest=math.huge
   for bx=math.floor(x*2)-2,math.floor(x*2)+2 do for bz=math.floor(z*2)-2,math.floor(z*2)+2 do
    for _,p in ipairs(bins[bx..":"..bz]or{})do local d=Vector2.new(p.X-x,p.Z-z).Magnitude if d<nearest then nearest=d end end
   end end
   if nearest>.9 then missed+=1 end farthest=math.max(farthest,nearest)
  end
 end end
 samples+=tested gaps+=missed maxDistance=math.max(maxDistance,farthest)results[#results+1]={name=island.Name,samples=tested,gaps=missed,maxRootDistance=farthest}
end
assert(gaps==0,"Grass coverage has interior gaps")
return{samples=samples,gaps=gaps,maxRootDistance=maxDistance,roots=total,islands=results}
]========])
return {ok=true,version=game.PlaceVersion,universe=game.GameId,place=game.PlaceId,assets=assets,
 oldIslandRemoved=true,parts=parts,foreignScripts=foreign,benches=benches,seats=seats,bridgeFloorSegments=floors,
 stoneTrigger=true,bridgeHiddenInitially=true,adminUserId=Admin.UserId,ownerOnly=true,compiledScripts=compiled,
 personalWeatherCount=4,windEveryMode=true,navigation=navigation,coverageAudit=coverageAudit,bridgeSurfaceAudit=bridgeSurfaceAudit,guardSegments=guards}]============])
game:GetService("AssetService"):SavePlaceAsync()
return {sourceVersion=game.PlaceVersion,published=true,geometry=geometry,grass=grass,tests=tests,clients=clients,compiledScripts=compiled,navigation=navigation,coverageAudit=coverageAudit,bridgeSurfaceAudit=bridgeSurfaceAudit}
