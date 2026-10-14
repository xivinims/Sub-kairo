local Builder={}
local Collection=game:GetService("CollectionService")
function Builder.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime
 local Seasons=require(runtime.Seasons)local Scene=require(runtime.Scene)local terrain=workspace.Terrain
 local rng=Random.new(2024)local report={chunks=0,changedVoxels=0,camps=0,logSeats=0,lilies=0,seasonTrees={},seasonPlants={}}
 for _,s in ipairs(Seasons.Names)do report.seasonTrees[s]=0 report.seasonPlants[s]=0 end
 local materials={Primavera=Enum.Material.Grass,Verao=Enum.Material.Grass,Outono=Enum.Material.LeafyGrass,Inverno=Enum.Material.Snow}
 -- Only surface materials change. Solid and liquid occupancy, bank height and bridge landings stay intact.
 for bx=-512,384,128 do for bz=-512,384,128 do
  local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))
  local channels=terrain:ReadVoxelChannels(region,4,{"SolidMaterial"})local grid=channels.SolidMaterial
  for ix=1,32 do for iz=1,32 do
   local material=materials[Seasons.at(bx+(ix-.5)*4,bz+(iz-.5)*4)]
   for iy=1,54 do local previous=grid[ix][iy][iz]
    if previous==Enum.Material.Grass or previous==Enum.Material.LeafyGrass then grid[ix][iy][iz]=material report.changedVoxels+=1 end
   end
  end end
  terrain:WriteVoxelChannels(region,4,{SolidMaterial=grid})report.chunks+=1 task.wait()
 end end
 terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(104,154,58))
 terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(166,127,62))
 terrain:SetMaterialColor(Enum.Material.Snow,Color3.fromRGB(238,245,252))
 local palettes={Primavera={Color3.fromRGB(181,207,127),Color3.fromRGB(211,171,178),Color3.fromRGB(163,193,109)},Verao={Color3.fromRGB(80,126,64),Color3.fromRGB(102,150,74),Color3.fromRGB(71,113,60)},Outono={Color3.fromRGB(184,118,57),Color3.fromRGB(200,153,77),Color3.fromRGB(166,101,49)},Inverno={Color3.fromRGB(104,137,126),Color3.fromRGB(139,159,151),Color3.fromRGB(90,116,107)}}
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,model in ipairs(folder:GetChildren())do
  local p=model:GetPivot().Position local season=Seasons.at(p.X,p.Z)model:SetAttribute("Season",season)
  local counts=folder==world.Decor.Trees and report.seasonTrees or report.seasonPlants counts[season]+=1
  local palette=palettes[season]local color=palette[rng:NextInteger(1,#palette)]
  for _,leaf in ipairs(model:GetDescendants())do if leaf:IsA("MeshPart")then local name=leaf.Name:lower()
   if name:find("leaf",1,true)or name:find("leaves",1,true)or name:find("fern",1,true)then
    leaf.Color=color local appearance=leaf:FindFirstChildOfClass("SurfaceAppearance")if appearance then appearance.Color=color end
   end
  end end
 end end
 local root=Instance.new("Folder")root.Name="SeasonalDetails"root.Parent=world.Amenities
 local camps=Instance.new("Folder")camps.Name="Camps"camps.Parent=root
 local rivers=Instance.new("Folder")rivers.Name="RiverPlants"rivers.Parent=root
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),params)end
 local function part(parent,name,size,cf,color,material,collide)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.Wood
  p.Anchored=true p.CanCollide=collide==true p.CanQuery=p.CanCollide p.CanTouch=false p.Parent=parent return p
 end
 local function clear(x,z,r)
  for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do for _,model in ipairs(folder:GetChildren())do
   local p=model:GetPivot().Position if(Vector2.new(p.X-x,p.Z-z)).Magnitude<r then model:Destroy()end
  end end
 end
 local original=assert(world.Amenities.LogBenches:FindFirstChildOfClass("Model"))
 local function logBench(camp,position,centre)
  local rotation=CFrame.lookAt(Vector3.zero,Vector3.new(centre.X-position.X,0,centre.Z-position.Z)).Rotation
  local bench=original:Clone()bench.Name="CampLogBench"
  for _,d in ipairs(bench:GetDescendants())do if d:IsA("Seat")or d:IsA("ProximityPrompt")then d:Destroy()end end
  bench:ScaleTo(original:GetScale()*.68)bench.Parent=camp
  local _,size=bench:GetBoundingBox()local half=math.min(size.X*.5,3.5)
  local y=position.Y-.16
  for _,x in ipairs({-half,0,half})do local off=rotation:VectorToWorldSpace(Vector3.new(x,0,0))local h=assert(ground(position.X+off.X,position.Z+off.Z))y=math.min(y,h.Position.Y-.16)end
  bench:PivotTo(CFrame.new(position.X,y,position.Z)*rotation)
  for _,p in ipairs(bench:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=true p.CanQuery=true p.CanTouch=false end end
  local mesh=RaycastParams.new()mesh.FilterType=Enum.RaycastFilterType.Include mesh.FilterDescendantsInstances={bench}
  local h=assert(workspace:Raycast(Vector3.new(position.X,y+12,position.Z),Vector3.new(0,-16,0),mesh),"Camp bench has no native top")
  local seat=Instance.new("Seat")seat.Name="CampLogSeat"seat.Anchored=true seat.Size=Vector3.new(2,.15,1.5)seat.CFrame=CFrame.new(position.X,h.Position.Y+.04,position.Z)*rotation seat.Transparency=1 seat.CanCollide=false seat.CanQuery=false seat.CanTouch=false seat.Parent=bench
  local prompt=Instance.new("ProximityPrompt")prompt.Name="SitPrompt"prompt.ActionText="Sentar"prompt.ObjectText="Acampamento"prompt.MaxActivationDistance=7 prompt.HoldDuration=.2 prompt.RequiresLineOfSight=false prompt.Parent=seat
  Collection:AddTag(seat,"RuinSeat")report.logSeats+=1
 end
 local targets={Primavera=Vector2.new(225,-130),Verao=Vector2.new(160,70),Outono=Vector2.new(-290,40),Inverno=Vector2.new(-180,-260)}
 for _,season in ipairs(Seasons.Names)do
  local wanted=targets[season]local site
  for radius=0,144,8 do
   for k=0,15 do local a=k*math.pi/8 local x,z=wanted.X+math.cos(a)*radius,wanted.Y+math.sin(a)*radius
    local h=ground(x,z)
    if h and h.Position.Y>10 and h.Normal.Y>.93 and Seasons.at(x,z)==season and Scene.pathDistance(x,z)>12 and (Vector2.new(x+180,z-30)).Magnitude>62 and (Vector2.new(x-world.OwnerNPC:GetPivot().X,z-world.OwnerNPC:GetPivot().Z)).Magnitude>24 then
     local low,high=h.Position.Y,h.Position.Y local valid=true
     for n=0,7 do local b=n*math.pi/4 local bank=ground(x+math.cos(b)*9,z+math.sin(b)*9)
      if not bank or bank.Material==Enum.Material.Water then valid=false break end low=math.min(low,bank.Position.Y)high=math.max(high,bank.Position.Y)
     end
     if valid and high-low<1.8 then site=h.Position break end
    end
   end
   if site then break end
  end
  assert(site,"No supported camp location for "..season)clear(site.X,site.Z,12)
  local camp=Instance.new("Model")camp.Name=season camp.ModelStreamingMode=Enum.ModelStreamingMode.Atomic camp:SetAttribute("Centre",site)camp:SetAttribute("Season",season)camp.Parent=camps
  for i=0,11 do local angle=i*math.pi/6 local h=assert(ground(site.X+math.cos(angle)*1.9,site.Z+math.sin(angle)*1.9))
   local stone=part(camp,"FireRingStone",Vector3.new(.85,.65,.75),CFrame.new(h.Position+Vector3.new(0,.22,0))*CFrame.Angles(.1,angle,.1),Color3.fromRGB(108,108,101),Enum.Material.Slate,true)stone:SetAttribute("GroundPoint",h.Position)
  end
  for i=0,2 do local p=part(camp,"Firewood",Vector3.new(2.8,.4,.4),CFrame.new(site+Vector3.new(0,.28,0))*CFrame.Angles(0,i*math.pi/3,.12),Color3.fromRGB(88,60,43),Enum.Material.Wood,false)p.Shape=Enum.PartType.Cylinder end
  local core=part(camp,"FireCore",Vector3.new(.4,.4,.4),CFrame.new(site+Vector3.new(0,.3,0)),Color3.fromRGB(68,45,30),Enum.Material.Wood,false)
  local fire=Instance.new("Fire")fire.Name="Campfire"fire.Size=3.5 fire.Heat=4 fire.Color=Color3.fromRGB(255,175,86)fire.SecondaryColor=Color3.fromRGB(245,103,47)fire.Parent=core Collection:AddTag(fire,"RuinVFX")
  local light=Instance.new("PointLight")light.Color=Color3.fromRGB(255,190,116)light.Range=20 light.Brightness=0 light.Shadows=false light.Parent=core Collection:AddTag(light,"ForestNightLight")
  for i=0,3 do local a=i*math.pi*.5+.3 local h=assert(ground(site.X+math.cos(a)*6,site.Z+math.sin(a)*6))logBench(camp,h.Position,site)end
  report.camps+=1
 end
 for i=1,30 do
  local z=-260+(i-.5)*520/30 local x=Scene.riverX(z)+(i%2==0 and -1 or 1)*4
  if math.abs(z+108)<10 or math.abs(z-176)<12 then continue end
  local h=ground(x,z)if not h or h.Material~=Enum.Material.Water then continue end
  local d=rng:NextNumber(1.4,2.3)
  local pad=part(rivers,"LilyPad",Vector3.new(.055,d,d),CFrame.new(x,Scene.RiverY+.04,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(83,123,65),Enum.Material.SmoothPlastic,false)pad.Shape=Enum.PartType.Cylinder
  if i%3==0 then
   for p=0,5 do local a=p*math.pi/3 local petal=part(rivers,"LilyPetal",Vector3.new(.45,.13,.20),CFrame.new(x+math.cos(a)*.18,Scene.RiverY+.13,z+math.sin(a)*.18)*CFrame.Angles(0,-a,0),Color3.fromRGB(227,180,194),Enum.Material.SmoothPlastic,false)petal.Shape=Enum.PartType.Ball end
  end
  report.lilies+=1
 end
 for _,season in ipairs(Seasons.Names)do
  local trees,plants=0,0
  for _,m in ipairs(world.Decor.Trees:GetChildren())do if m:GetAttribute("Season")==season then trees+=1 end end
  for _,m in ipairs(world.Decor.Plants:GetChildren())do if m:GetAttribute("Season")==season then plants+=1 end end
  report.seasonTrees[season]=trees report.seasonPlants[season]=plants world:SetAttribute(season.."Trees",trees)
 end
 world.Amenities.ForestRuins:SetAttribute("AutumnTrees",report.seasonTrees.Outono)
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())world:SetAttribute("LanternCount",#Collection:GetTagged("ForestNightLight"))world:SetAttribute("SeasonCount",4)
 root:SetAttribute("CampCount",report.camps)root:SetAttribute("LogSeatCount",report.logSeats)root:SetAttribute("LilyCount",report.lilies)
 return report
end
return Builder
