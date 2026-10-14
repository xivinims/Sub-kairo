assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==95,"Published base changed")
game:GetService("ServerStorage")
local function factory(code)local m=Instance.new("ModuleScript")m.Source=code m.Parent=game.ServerStorage local v=require(m)m:Destroy()return v end
local function run(code)return factory("return function()\n"..code.."\nend")()end
local function source(parent,class,name,code)local s=parent:FindFirstChild(name)or Instance.new(class)s.Name=name s.Source=code s.Parent=parent return s end
local runtime=game.ReplicatedStorage.ForestRuntime runtime:SetAttribute("GardenTestMode",true)runtime:SetAttribute("SeasonTestMode",true)runtime:SetAttribute("ForestTestMode",true)
source(runtime,"ModuleScript","Foliage",[============[local M={}
local Collection=game:GetService("CollectionService")
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
function M.place(template,parent,x,z,height,yaw)
 local g=ground(x,z)if not g or g.Position.Y<7.4 or g.Normal.Y<.72 then return end
 local m=template:Clone()local scale=height/template:GetAttribute("TemplateHeight")m:ScaleTo(template:GetScale()*scale)
 local rotation=CFrame.Angles(0,yaw,0)local y=g.Position.Y-1.15
 local points=template:GetAttribute("RootProfile")local values=game:GetService("HttpService"):JSONDecode(points)
 for _,p in ipairs(values)do local off=rotation:VectorToWorldSpace(Vector3.new(unpack(p))*scale)local hit=ground(x+off.X,z+off.Z)if not hit or hit.Position.Y<7 then m:Destroy()return end y=math.min(y,hit.Position.Y-off.Y-1.15)end
 m:PivotTo(CFrame.new(x,y,z)*rotation)m:SetAttribute("ActualRootPoint",Vector3.new(x,y,z))m:SetAttribute("FreshReferenceTree",true)m:SetAttribute("RootEmbedDepth",1.15)m.Parent=parent Collection:AddTag(m,"ForestTree")return m
end
function M.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)
 local removed=#world.Decor.Trees:GetChildren()world.Decor.Trees:ClearAllChildren()
 local folder=runtime:FindFirstChild("NativeTreeTemplates")if folder then folder:Destroy()end folder=Instance.new("Folder")folder.Name="NativeTreeTemplates"folder.Parent=runtime
 local raw=game:GetService("AssetService"):LoadAssetAsync(580221169)local forest=game:GetService("AssetService"):LoadAssetAsync(6432306802)
 local broad=assert(raw:FindFirstChildOfClass("Model"))local pine=forest["Forest Pack"]["RedwoodTree-Var01"]
 local templates={}
 for i,original in ipairs({broad,pine})do
  local model=original:Clone()model.Name=i==1 and"GreenBroadleaf"or"GreenPine"
  for _,d in ipairs(model:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Camera")or d:IsA("Constraint")or d:IsA("JointInstance")then d:Destroy()end end
  local trunk
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
   p.Anchored=true p.CanTouch=false p.CanCollide=false p.CanQuery=true
   if p.Name=="Bark"or p.Name=="Trunk"then trunk=p p.Name="Trunk"p.CanCollide=true
   elseif p.Name:lower():find("leaf",1,true)or p.Name:lower():find("leaves",1,true)then
    local color=p.Color:Lerp(Color3.fromRGB(96,155,64),.35)p.Color=color p:SetAttribute("SeasonBaseColor",color)p:SetAttribute("SeasonBaseTransparency",0)local a=p:FindFirstChildOfClass("SurfaceAppearance")if a then a.Color=color end
   end
  end end
  assert(trunk)model.Parent=workspace task.wait()
  local own=RaycastParams.new()own.FilterType=Enum.RaycastFilterType.Include own.FilterDescendantsInstances={trunk}
  local lo=trunk.Position-trunk.Size*.5 local hi=trunk.Position+trunk.Size*.5 local hits={}local minimum=math.huge
  for ix=0,30 do for iz=0,30 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/31 local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/31 local h=workspace:Raycast(Vector3.new(x,lo.Y-5,z),Vector3.yAxis*(trunk.Size.Y+10),own)if h then minimum=math.min(minimum,h.Position.Y)hits[#hits+1]=h.Position end end end
  local selected={}local center=Vector3.zero
  for _,p in ipairs(hits)do if p.Y<minimum+1.5 then selected[#selected+1]=p center+=p end end assert(#selected>0)center/= #selected
  local base=Vector3.new(center.X,minimum,center.Z)model:PivotTo(model:GetPivot()-base)
  local anchor=Instance.new("Part")anchor.Name="RootAnchor"anchor.Size=Vector3.one*.05 anchor.CFrame=CFrame.identity anchor.Transparency=1 anchor.Anchored=true anchor.CanCollide=false anchor.CanQuery=false anchor.CanTouch=false anchor.Parent=model model.PrimaryPart=anchor
  local profile={}
  for j=1,math.min(16,#selected)do local p=selected[math.floor(1+(j-1)*(#selected-1)/math.max(1,math.min(16,#selected)-1))]-base profile[#profile+1]={p.X,p.Y,p.Z}end
  model:SetAttribute("RootProfile",game:GetService("HttpService"):JSONEncode(profile))local _,size=model:GetBoundingBox()model:SetAttribute("TemplateHeight",size.Y)model:SetAttribute("SourceAssetId",i==1 and 580221169 or 6432306802)model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=p==trunk p.CastShadow=true if p:IsA("MeshPart")then p.RenderFidelity=Enum.RenderFidelity.Performance end end end
  model.Parent=folder templates[#templates+1]=model
 end
 raw:Destroy()forest:Destroy()
 local protected={}
 for _,m in ipairs({world.Amenities.ForestRuins,world.Amenities.RiversideGarden.WaterCottage})do local cf,size=m:GetBoundingBox()protected[#protected+1]={x=cf.X,z=cf.Z,r=math.max(size.X,size.Z)*.55+8}end
 for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do local p=m:GetAttribute("Origin")protected[#protected+1]={x=p.X,z=p.Z,r=36}end
 local rng=Random.new(96014)local placed={}local count=0
 for attempt=1,9000 do if count>=280 then break end local x,z=rng:NextNumber(-390,390),rng:NextNumber(-350,350)
  if Scene.pathDistance(x,z)<14 or math.abs(x-Scene.riverX(z))<Scene.riverWidth(z)+16 then continue end
  local lake=world:GetAttribute("CentralLake")if math.sqrt(((x-lake.X)/76)^2+((z-lake.Z)/52)^2)<1.15 then continue end
  local blocked=false for _,p in ipairs(protected)do if(Vector2.new(x-p.x,z-p.z)).Magnitude<p.r then blocked=true break end end
  for _,p in ipairs(placed)do if(p-Vector2.new(x,z)).Magnitude<18 then blocked=true break end end if blocked then continue end
  local index=count%4==0 and 2 or 1 local tree=M.place(templates[index],world.Decor.Trees,x,z,rng:NextNumber(index==1 and 23 or 28,index==1 and 36 or 45),rng:NextNumber(0,math.pi*2))
  if tree then count+=1 placed[#placed+1]=Vector2.new(x,z)end
  if attempt%100==0 then task.wait()end
 end
 local chunks=world.Decor:FindFirstChild("ActiveForestChunks")if chunks then chunks:Destroy()end chunks=Instance.new("Folder")chunks.Name="ActiveForestChunks"chunks.Parent=world.Decor
 world:SetAttribute("TreeCount",count)world:SetAttribute("PreviousTreesRemoved",removed)runtime:SetAttribute("ForestChunkSize",128)runtime:SetAttribute("ForestLiveChunkLimit",20)
 return{removedTrees=removed,newTrees=count,treeAssets={580221169,6432306802},chunkLimit=20}
end
function M.makeChunk(runtime,world,cx,cz)
 if math.abs(cx*128)<448 and math.abs(cz*128)<448 then return end
 local m=Instance.new("Model")m.Name="ForestChunk_"..cx.."_"..cz m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local rng=Random.new((cx*73856093+cz*19349663)%2147483647)local templates=runtime.NativeTreeTemplates local count=0
 for ix=0,2 do for iz=0,2 do local x,z=cx*128+20+ix*40+rng:NextNumber(-6,6),cz*128+20+iz*40+rng:NextNumber(-6,6)
  if math.abs(x)>1980 or math.abs(z)>1980 then continue end
  local template=(ix+iz)%4==0 and templates.GreenPine or templates.GreenBroadleaf
  if M.place(template,m,x,z,rng:NextNumber(24,40),rng:NextNumber(0,6.28))then count+=1 end
 end end
 if count==0 then m:Destroy()return end m:SetAttribute("TreeCount",count)m.Parent=world.Decor.ActiveForestChunks return m
end
function M.start(runtime,world)
 local active={}local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<1 then return end elapsed=0 if runtime:GetAttribute("ForestTestMode")then return end
  local wanted={}
  for _,player in ipairs(game.Players:GetPlayers())do local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")if r then local cx,cz=math.floor(r.Position.X/128),math.floor(r.Position.Z/128)
   for dx=-2,2 do for dz=-2,2 do local x,z=cx+dx,cz+dz if math.abs(x*128)>448 or math.abs(z*128)>448 then local k=x..":"..z wanted[k]={x=x,z=z,d=(Vector2.new(x*128+64-r.Position.X,z*128+64-r.Position.Z)).Magnitude}end end end
  end end
  local order={}for k,v in pairs(wanted)do v.k=k order[#order+1]=v end table.sort(order,function(a,b)return a.d<b.d end)while #order>20 do table.remove(order)end
  local keep={}for _,v in ipairs(order)do keep[v.k]=true end for k,m in pairs(active)do if not keep[k]then m:Destroy()active[k]=nil end end
  local added=0 for _,v in ipairs(order)do if not active[v.k]then local m=M.makeChunk(runtime,world,v.x,v.z)if m then active[v.k]=m added+=1 if added>=2 then break end end end end
 end)
end
return M
]============])
source(runtime,"ModuleScript","RiverReflection",[============[local M={}
function M.create(character,guiParent,worldParent)
 local patch=Instance.new("Part")patch.Name="LocalRiverReflection"patch.Size=Vector3.new(8,.02,12)patch.Transparency=1 patch.Anchored=true patch.CanCollide=false patch.CanQuery=false patch.CanTouch=false patch.CastShadow=false patch.Parent=worldParent
 local surface=Instance.new("SurfaceGui")surface.Name="RiverAvatarReflection"surface.Adornee=patch surface.Face=Enum.NormalId.Top surface.CanvasSize=Vector2.new(96,144)surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize surface.AlwaysOnTop=false surface.LightInfluence=0 surface.Enabled=false surface.Parent=guiParent
 local view=Instance.new("ViewportFrame")view.Size=UDim2.fromScale(1,1)view.BackgroundTransparency=1 view.ImageTransparency=.90 view.ImageColor3=Color3.fromRGB(136,175,185)view.Ambient=Color3.fromRGB(180,180,180)view.LightColor=Color3.fromRGB(180,180,180)view.Parent=surface
 local scene=Instance.new("WorldModel")scene.Parent=view local camera=Instance.new("Camera")camera.Parent=view view.CurrentCamera=camera
 local rig=Instance.new("Model")rig.Name="ReflectedAvatar"rig.Parent=scene
 local hum=Instance.new("Humanoid")hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.Parent=rig
 for _,d in ipairs(character:GetChildren())do if d:IsA("Shirt")or d:IsA("Pants")or d:IsA("ShirtGraphic")then d:Clone().Parent=rig end end
 local pairs={}local parts={}
 for _,p in ipairs(character:GetDescendants())do if p:IsA("BasePart")and p.Name~="HumanoidRootPart"and p.Transparency<.95 then parts[#parts+1]=p end end
 table.sort(parts,function(a,b)return(a.Parent==character and 0 or 1)<(b.Parent==character and 0 or 1)end)
 for i=1,math.min(32,#parts)do local p=parts[i]local copy=p:Clone()
  for _,d in ipairs(copy:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("JointInstance")or d:IsA("Constraint")or d:IsA("Sound")or d:IsA("ParticleEmitter")or d:IsA("WrapLayer")or d:IsA("Light")then d:Destroy()end end
  copy.Anchored=true copy.CanCollide=false copy.CanQuery=false copy.CanTouch=false copy.LocalTransparencyModifier=0 copy.Parent=rig pairs[#pairs+1]={source=p,copy=copy}
 end
 local self={surface=surface,view=view,patch=patch,camera=camera,pairs=pairs}
 function self.update(point,viewer)
  if viewer.Position.Y<point.Y+.8 then surface.Enabled=false return end
  patch.CFrame=CFrame.new(point+Vector3.yAxis*.018)surface.Enabled=true
  local eye=Vector3.new(viewer.Position.X,2*point.Y-viewer.Position.Y,viewer.Position.Z)
  camera.CFrame=CFrame.lookAt(eye,point,Vector3.zAxis)camera.FieldOfView=math.clamp(math.deg(2*math.atan(6/(eye-point).Magnitude)),20,90)
  for _,v in ipairs(pairs)do if v.source.Parent then v.copy.CFrame=v.source.CFrame v.copy.Transparency=v.source.Position.Y<point.Y-.4 and 1 or v.source.Transparency end end
 end
 function self.hide()surface.Enabled=false end
 function self.destroy()surface:Destroy()patch:Destroy()end
 return self
end
return M
]============])
source(runtime,"ModuleScript","MusicUI",[============[local M={}
local function create(class,parent,name)local obj=Instance.new(class)obj.Name=name obj.Parent=parent return obj end
local function round(obj)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,10)c.Parent=obj end
local function label(parent,name,text,height)
 local l=create("TextLabel",parent,name)l.Text=text l.Size=UDim2.new(1,0,0,height or 22)l.Font=Enum.Font.Gotham l.TextSize=13 l.TextColor3=Color3.fromRGB(240,240,240)l.BackgroundTransparency=1 l.TextWrapped=true l.TextXAlignment=Enum.TextXAlignment.Left return l
end
local function button(parent,name,text)
 local b=create("TextButton",parent,name)b.Size=UDim2.new(1,0,0,42)b.Text=text b.Font=Enum.Font.GothamMedium b.TextSize=13 b.BackgroundColor3=Color3.fromRGB(12,12,12)b.TextColor3=Color3.fromRGB(240,240,240)b.BorderSizePixel=0 b.BackgroundTransparency=.35 round(b)return b
end
function M.build(parent,tracks)
 local gui=create("ScreenGui",parent,"TreeWorldPersonalMusic")gui.ResetOnSpawn=false gui.DisplayOrder=25 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local open=button(gui,"Open","♫ Música")open.AnchorPoint=Vector2.new(1,0)open.Position=UDim2.new(1,-12,0,12)open.Size=UDim2.fromOffset(100,38)
 local panel=create("Frame",gui,"Panel")panel.AnchorPoint=Vector2.new(1,0)panel.Position=UDim2.new(1,-12,0,60)panel.Size=UDim2.new(.9,0,.72,0)panel.BackgroundColor3=Color3.fromRGB(12,12,12)panel.BackgroundTransparency=.22 panel.BorderSizePixel=0 panel.Visible=false round(panel)
 local limit=create("UISizeConstraint",panel,"SizeLimit")limit.MaxSize=Vector2.new(340,490)limit.MinSize=Vector2.new(210,150)
 local scroll=create("ScrollingFrame",panel,"Scroll")scroll.Size=UDim2.fromScale(1,1)scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=4 scroll.ScrollBarImageColor3=Color3.fromRGB(240,240,240)scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.CanvasSize=UDim2.new()scroll.ScrollingDirection=Enum.ScrollingDirection.Y
 local pad=create("UIPadding",scroll,"Padding")pad.PaddingTop=UDim.new(0,14)pad.PaddingBottom=UDim.new(0,14)pad.PaddingLeft=UDim.new(0,14)pad.PaddingRight=UDim.new(0,14)
 local layout=create("UIListLayout",scroll,"Layout")layout.Padding=UDim.new(0,8)layout.SortOrder=Enum.SortOrder.LayoutOrder
 local refs={gui=gui,open=open,panel=panel,tracks={}}local order=0
 local function add(obj)order+=1 obj.LayoutOrder=order return obj end
 add(label(scroll,"Title","Seu rádio",24)).Font=Enum.Font.GothamBold
 add(label(scroll,"Privacy","Só você ouve. A nametag mostra quando está ouvindo.",36))
 refs.status=add(label(scroll,"Status","Escolha uma música",36))
 for _,category in ipairs({"Em inglês","Natureza"})do add(label(scroll,"Category",category,24)).Font=Enum.Font.GothamBold
  for _,track in ipairs(tracks)do if track.category==category then local b=add(button(scroll,"Track",track.title))b:SetAttribute("AssetId",track.id)refs.tracks[#refs.tracks+1]={button=b,track=track}end end
 end
 add(label(scroll,"CustomTitle","Sua música · ID do Roblox",24))
 refs.input=add(create("TextBox",scroll,"AudioId"))refs.input.Size=UDim2.new(1,0,0,42)refs.input.PlaceholderText="Cole o ID de áudio"refs.input.Text=""refs.input.ClearTextOnFocus=false refs.input.Font=Enum.Font.Gotham refs.input.TextSize=14 refs.input.BackgroundColor3=Color3.fromRGB(12,12,12)refs.input.TextColor3=Color3.fromRGB(240,240,240)refs.input.BorderSizePixel=0 refs.input.BackgroundTransparency=.35 round(refs.input)
 refs.play=add(button(scroll,"PlayId","Ouvir meu ID"))refs.pause=add(button(scroll,"Pause","Pausar / continuar"))refs.stop=add(button(scroll,"Stop","Parar"))
 add(label(scroll,"VolumeTitle","Volume",22))refs.lower=add(button(scroll,"Quieter","Diminuir volume"))refs.louder=add(button(scroll,"Louder","Aumentar volume"))
 return refs
end
return M
]============])
local reports={}
reports.terrain=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local T=workspace.Terrain local Scene=require(runtime.Scene)
 local mask={}
 for _,m in ipairs({world.Amenities.ForestRuins,world.Amenities.WeatheredHillStair})do local cf,size=m:GetBoundingBox()mask[#mask+1]={x=cf.X,z=cf.Z,rx=size.X*.5+7,rz=size.Z*.5+7}end
 for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do local cf,size=m:GetBoundingBox()mask[#mask+1]={x=cf.X,z=cf.Z,rx=size.X*.5+7,rz=size.Z*.5+7}end
 for _,m in ipairs(world.Amenities.SeasonalDetails.Camps:GetChildren())do local p=m:GetAttribute("Centre")mask[#mask+1]={x=p.X,z=p.Z,rx=14,rz=14}end
 local function preserve(x,z)local w=0 for _,p in ipairs(mask)do local d=math.max(math.abs(x-p.x)-p.rx,math.abs(z-p.z)-p.rz)w=math.max(w,1-math.clamp(d/72,0,1))end return w end
 local chunks={}
 for bx=-512,384,128 do for bz=-512,384,128 do local reg=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))chunks[#chunks+1]={x=bx,z=bz,region=reg,data=T:ReadVoxelChannels(reg,4,{"SolidMaterial","SolidOccupancy","LiquidOccupancy"})}end end
 -- The extension is flat, compact native terrain; streamed scenery supplies detail only near people.
 T:FillBlock(CFrame.new(0,-6,0),Vector3.new(4096,52,4096),Enum.Material.Grass)
 local report={coreColumns=0,flattenedColumns=0,newLakes=0,extent=4096}
 for _,chunk in ipairs(chunks)do local d=chunk.data
  for ix=1,32 do for iz=1,32 do local x,z=chunk.x+(ix-.5)*4,chunk.z+(iz-.5)*4 local h=-64
   for iy=54,1,-1 do local o=d.SolidOccupancy[ix][iy][iz]if o>0 then h=-64+(iy-1)*4+o*4 break end end
   local old=h local w=preserve(x,z)
   if h>34 then h=h+(34+(h-34)*.12-h)*(1-w)report.flattenedColumns+=1 end
   local edge=math.clamp((math.max(math.abs(x),math.abs(z))-344)/164,0,1)edge=edge*edge*(3-2*edge)
   if edge>0 then h=h*(1-edge)+20*edge end
   for iy=1,54 do local low=-64+(iy-1)*4 local fill=math.clamp((h-low)/4,0,1)
    d.SolidOccupancy[ix][iy][iz]=fill
    if fill>0 then local oldMat=d.SolidMaterial[ix][iy][iz]
     if oldMat==Enum.Material.Sand then oldMat=Enum.Material.Ground end
     if oldMat==Enum.Material.Air or edge>.4 then oldMat=h-low<8 and(Scene.pathDistance(x,z)<4.8 and Enum.Material.Ground or Enum.Material.Grass)or Enum.Material.Ground end
     d.SolidMaterial[ix][iy][iz]=oldMat
    else d.SolidMaterial[ix][iy][iz]=Enum.Material.Air end
    if edge>0 then d.LiquidOccupancy[ix][iy][iz]=fill<1 and math.clamp((6-low)/4,0,1)or 0 end
   end report.coreColumns+=1
  end end
  T:WriteVoxelChannels(chunk.region,4,{SolidMaterial=d.SolidMaterial,SolidOccupancy=d.SolidOccupancy,LiquidOccupancy=d.LiquidOccupancy})task.wait()
 end
 local lakes={{900,650,110,74},{-960,-750,130,90},{760,-1000,96,80},{-1100,1000,145,86}}
 local descriptors={{27,6,-18,76,52},{39,6,157,61,62}}
 for _,l in ipairs(lakes)do local cx,cz,rx,rz=unpack(l)local reg=Region3.new(Vector3.new(cx-rx*1.3,-16,cz-rz*1.3),Vector3.new(cx+rx*1.3,40,cz+rz*1.3)):ExpandToGrid(4)local d=T:ReadVoxelChannels(reg,4,{"SolidMaterial","SolidOccupancy","LiquidOccupancy"})local lo=reg.CFrame.Position-reg.Size*.5
  for ix=1,d.Size.X do for iz=1,d.Size.Z do local x,z=lo.X+(ix-.5)*4,lo.Z+(iz-.5)*4 local r=math.sqrt(((x-cx)/rx)^2+((z-cz)/rz)^2)local a=math.clamp((r-.56)/.7,0,1)a=a*a*(3-2*a)local h=-1+21*a
   for iy=1,d.Size.Y do local low=lo.Y+(iy-1)*4 local fill=math.clamp((h-low)/4,0,1)d.SolidOccupancy[ix][iy][iz]=fill d.SolidMaterial[ix][iy][iz]=fill>0 and(h-low<5 and(h<8 and Enum.Material.Ground or Enum.Material.Grass)or Enum.Material.Ground)or Enum.Material.Air d.LiquidOccupancy[ix][iy][iz]=fill<1 and math.clamp((6-low)/4,0,1)or 0 end
  end end T:WriteVoxelChannels(reg,4,{SolidMaterial=d.SolidMaterial,SolidOccupancy=d.SolidOccupancy,LiquidOccupancy=d.LiquidOccupancy})descriptors[#descriptors+1]={cx,6,cz,rx,rz}report.newLakes+=1 task.wait()
 end
 T:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(107,154,67))T:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(114,91,66))T:SetMaterialColor(Enum.Material.Mud,Color3.fromRGB(96,79,62))
 world:SetAttribute("WorldExtent",4096)world:SetAttribute("TerrainOrganized",true)world:SetAttribute("PathMaterial","Ground")runtime:SetAttribute("LakeLocations",game:GetService("HttpService"):JSONEncode(descriptors))
 return report
end
return B
]============]).install()
reports.foliage=require(runtime.Foliage).install()
reports.bridges=factory([============[local B={}
local WOOD=Color3.fromRGB(147,115,76)local PALE=Color3.fromRGB(182,146,101)local DARK=Color3.fromRGB(92,69,48)
function B.install()
 local world=workspace.ForestWorld local Scene=require(game.ReplicatedStorage.ForestRuntime.Scene)
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,rp)).Position end
 local folder=world.Amenities.WoodenBridges folder:ClearAllChildren()
 local report={bridges=0,parts=0}
 local function part(parent,name,size,cf,color,material)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color or WOOD p.Material=material or Enum.Material.Wood p.Anchored=true p.CanCollide=true p.CanQuery=true p.CanTouch=false p.Transparency=0 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent report.parts+=1 return p
 end
 local function beam(parent,name,a,b,width,height,color)return part(parent,name,Vector3.new(width,height,(b-a).Magnitude+.03),CFrame.lookAt((a+b)*.5,b),color)end
 for index,z in ipairs({-108,176})do
  local cx=Scene.riverX(z)local xa,xb=cx-8,cx+8
  while ground(xa,z).Y<9 do xa-=2 end while ground(xb,z).Y<9 do xb+=2 end xa-=2 xb+=2
  local a,b=ground(xa,z),ground(xb,z)local W=11 local N=math.ceil((b-a).Magnitude/3.0)
  local m=Instance.new("Model")m.Name="WoodlandBridge"..index m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m:SetAttribute("DeckWidth",W)m:SetAttribute("ReferenceStyle","Wide carved woodland arch, longitudinal timber boards and scalloped support corbels")m.Parent=folder
  local function point(t)return a:Lerp(b,t)+Vector3.yAxis*(.08+2.4*math.sin(math.pi*t))end
  local nodes={}
  for i=0,N do local p=point(i/N)nodes[#nodes+1]={p.X,p.Y,p.Z}end
  for i=1,N do
   local aa,bb=point((i-1)/N),point(i/N)local cf=CFrame.lookAt((aa+bb)*.5,bb)local len=(bb-aa).Magnitude+.08
   for lane=0,7 do local x=-W*.5+(lane+.5)*W/8
    part(m,"SolidDeckPlank",Vector3.new(W/8+.012,.38,len),cf*CFrame.new(x,-.19,0),WOOD:Lerp(PALE,((lane+i)%5)*.09))
   end
   if i%3==1 then
    part(m,"UnderDeckCrossbeam",Vector3.new(W+1.3,.55,.7),cf*CFrame.new(0,-.66,0),DARK)
    for _,s in ipairs({-1,1})do
     local tip=cf:PointToWorldSpace(Vector3.new(s*(W/2+.45),-.65,0))
     for j=0,2 do part(m,"CarvedCorbel",Vector3.new(.64,.4,.75-j*.1),CFrame.new(tip+Vector3.new(0,-.4*j,j*.14))*cf.Rotation,WOOD:Lerp(PALE,j*.16))end
    end
   end
   for _,s in ipairs({-1,1})do
    part(m,"TimberHandrail",Vector3.new(.58,.32,len),cf*CFrame.new(s*(W/2-.25),2.65,0),PALE)
    part(m,"FramedLowerRail",Vector3.new(.28,.23,len),cf*CFrame.new(s*(W/2-.25),1.05,0),WOOD)
    beam(m,"ArchedFoundationTimber",aa+Vector3.new(0,-1.2,s*(W/2-.2)),bb+Vector3.new(0,-1.2,s*(W/2-.2)),.6,.85,DARK)
   end
  end
  local postCount=math.ceil((b-a).Magnitude/10)
  for i=0,postCount do local t=i/postCount local c=point(t)
   for _,s in ipairs({-1,1})do local pos=c+Vector3.zAxis*s*(W/2-.25)local g=ground(pos.X,pos.Z)local top=pos.Y+3.2 local base=g.Y-.45
    part(m,"GroundedCarvedPost",Vector3.new(1,top-base,1),CFrame.new(pos.X,(top+base)*.5,pos.Z),DARK)
    for _,h in ipairs({.75,2.42})do part(m,"CarvedPostCollar",Vector3.new(1.16,.16,1.16),CFrame.new(pos+Vector3.yAxis*h),WOOD)end
    part(m,"PostCapital",Vector3.new(1.34,.25,1.34),CFrame.new(pos+Vector3.yAxis*3.1),PALE)
    part(m,"PostCapFinial",Vector3.new(.68,.2,.68),CFrame.new(pos+Vector3.yAxis*3.32),WOOD)
   end
  end
  for _,endpoint in ipairs({a,b})do part(m,"BankApron",Vector3.new(2.6,.3,W),CFrame.new(endpoint-Vector3.yAxis*.08),WOOD)end
  m:SetAttribute("DeckStart",point(0))m:SetAttribute("DeckEnd",point(1))m:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))report.bridges+=1
 end
 return report
end
return B
]============]).install()
reports.water=factory([============[local B={}
local C=game:GetService("CollectionService")
local function P(parent,name,size,cf,color,mat,collide,class)
 local p=Instance.new(class or"Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=mat or Enum.Material.Slate p.Anchored=true p.CanCollide=collide==true p.CanQuery=collide==true p.CanTouch=false p.CastShadow=collide==true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
-- Two right triangular prisms form each authored polygon face. Their common edge is coplanar, never stacked.
local function triangle(parent,a,b,c,thickness,color,name)
 local ab,ac,bc=b-a,c-a,c-b local abd,acd,bcd=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
 if abd>acd and abd>bcd then c,a=a,c elseif acd>bcd and acd>abd then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit local back=bc.Unit local up=bc:Cross(right).Unit
 local height=math.abs(ab:Dot(up))local length1=math.abs(ab:Dot(back))local length2=math.abs(ac:Dot(back))
 if height<.001 or length1<.001 or length2<.001 then return end
 P(parent,name,Vector3.new(thickness,height,length1),CFrame.fromMatrix((a+b)*.5,right,up,back),color,Enum.Material.Slate,true,"WedgePart")
 P(parent,name,Vector3.new(thickness,height,length2),CFrame.fromMatrix((a+c)*.5,-right,up,-back),color,Enum.Material.Slate,true,"WedgePart")
end
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)local Terrain=workspace.Terrain
 local garden=world.Amenities.RiversideGarden
 for _,name in ipairs({"AnimeRiverFoam","StreamSteppingStones","CartoonWater"})do local old=garden:FindFirstChild(name)if old then old:Destroy()end end
 local waterRay=RaycastParams.new()waterRay.FilterType=Enum.RaycastFilterType.Include waterRay.FilterDescendantsInstances={Terrain}
 local groundRay=RaycastParams.new()groundRay.FilterType=Enum.RaycastFilterType.Include groundRay.FilterDescendantsInstances={Terrain}groundRay.IgnoreWater=true
 local function wet(x,z)local h=workspace:Raycast(Vector3.new(x,200,z),Vector3.yAxis*-300,waterRay)return h and h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.12 end
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,200,z),Vector3.yAxis*-300,groundRay)).Position end
 local report={stones=0,stoneFaces=0,removedWaterOverlays=true}
 Terrain.WaterColor=Color3.fromRGB(61,151,175)Terrain.WaterTransparency=.28 Terrain.WaterReflectance=.14 Terrain.WaterWaveSize=.035 Terrain.WaterWaveSpeed=4
 for _,d in ipairs(world:GetDescendants())do if d:IsA("ParticleEmitter")or d:IsA("Beam")or d:IsA("Trail")then d:Destroy()end end
 local client=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestWaterClient")if client then client:Destroy()end
 runtime:SetAttribute("WaterStyle","NativeBlueReflective")
 -- Pale irregular polygon slabs, separated by reachable hops, with fully visible stone sides to the bed.
 local stones=Instance.new("Model")stones.Name="StreamSteppingStones"stones.ModelStreamingMode=Enum.ModelStreamingMode.Atomic stones.Parent=garden
 local z=90 local cx=Scene.riverX(z)local xa,xb=cx-4,cx+4
 while ground(xa,z).Y<7.3 do xa-=2 end while ground(xb,z).Y<7.3 do xb+=2 end
 local a,b=ground(xa,z),ground(xb,z)local count=math.ceil((xb-xa)/6.6)local nodes={}
 local rng=Random.new(942090)
 for i=0,count do
  local t=i/count local x=xa+(xb-xa)*t local zz=z+math.sin(t*math.pi*2)*1.6 local y=math.max(7.25,a.Y*(1-t)+b.Y*t)
  local model=Instance.new("Model")model.Name="FacetedWalkStone"model.Parent=stones local center=Vector3.new(x,y-.035,zz)local points={}
  local angle=rng:NextNumber(-.2,.2)local rx,rz=3.0,3.1
  for k=0,5 do local an=k*math.pi*2/6+angle local jitter=rng:NextNumber(.92,1.08)points[k+1]=center+Vector3.new(math.cos(an)*rx*jitter,0,math.sin(an)*rz*jitter)end
  local bottom=math.min(ground(x,zz).Y-.3,5.1)
  for k=1,#points do local p,q=points[k],points[k%#points+1]
   triangle(model,center,p,q,.07,Color3.fromRGB(190+k%3*4,204+k%3*4,211+k%3*4),"PaleStoneTop")
   local lowP,lowQ=Vector3.new(p.X,bottom,p.Z),Vector3.new(q.X,bottom,q.Z)
   local color=Color3.fromRGB(102+k%3*9,127+k%3*9,144+k%3*9)
   triangle(model,p,lowP,q,.1,color,"FacetedStoneSide")triangle(model,q,lowP,lowQ,.1,color,"FacetedStoneSide")report.stoneFaces+=3
  end
  model:SetAttribute("WalkTop",y)model:SetAttribute("Centre",Vector3.new(x,y,zz))nodes[#nodes+1]={x,y,zz}report.stones+=1
 end
 stones:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))
 -- Replace the old scattered rock models with sparse, broad-faced rocks too.
 -- Keep gaps along the earth paths and bury the lower ring into the bank.
 local candidates={}
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do
  local name=m.Name:lower()
  if name:find("rock",1,true)or name:find("boulder",1,true)then
   local cf,size=m:GetBoundingBox()
   candidates[#candidates+1]={x=cf.X,z=cf.Z,size=size}
   m:Destroy()
  end
 end
 table.sort(candidates,function(a,b)if a.x==b.x then return a.z<b.z end return a.x<b.x end)
 local accents=0
 for i,old in ipairs(candidates)do
  if accents>=24 then break end
  local x,zz=old.x,old.z
  local h=ground(x,zz)
  if h.Y<7 or Scene.pathDistance(x,zz)<9 or i%3==0 then continue end
  local width=math.clamp(math.max(old.size.X,old.size.Z),4,9)
  local height=math.clamp(old.size.Y*.65,1.6,3.6)
  local model=Instance.new("Model")model.Name="PaleFacetedRock"model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  model:SetAttribute("ReferenceStyle","Irregular broad pale top with bevelled slate sides")model.Parent=world.Decor.RocksAndLogs
  local bottom=h.Y-.45 local upper,lower={},{}
  local center=Vector3.new(x,h.Y+height,zz)
  local rotation=rng:NextNumber(0,math.pi*2)
  for k=0,5 do
   local angle=rotation+k*math.pi/3 local spread=rng:NextNumber(.84,1.08)
   local dx,dz=math.cos(angle)*width*.48*spread,math.sin(angle)*width*.4*spread
   upper[k+1]=center+Vector3.new(dx*.83,0,dz*.83)
   lower[k+1]=Vector3.new(x+dx,bottom,zz+dz)
  end
  for k=1,6 do local j=k%6+1
   triangle(model,center,upper[k],upper[j],.08,Color3.fromRGB(180+k%3*5,190+k%3*5,194+k%3*5),"PaleStoneTop")
   local color=Color3.fromRGB(101+k%3*9,117+k%3*9,124+k%3*9)
   triangle(model,upper[k],lower[k],upper[j],.1,color,"FacetedStoneSide")
   triangle(model,upper[j],lower[k],lower[j],.1,color,"FacetedStoneSide")
  end
  accents+=1
 end
 report.accentRocks=accents report.oldAccentRocksRemoved=#candidates
 assert(accents>=12,"Too few well placed reference rocks")
 world:SetAttribute("CartoonWaterTiles",0)world:SetAttribute("ReferenceSteppingStones",report.stones)
 return report
end
return B
]============]).install()
reports.lamps=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)local C=game:GetService("CollectionService")
 local assetId=97893326625257
 local raw=game:GetService("AssetService"):LoadAssetAsync(assetId)
 local template=raw
 for _,d in ipairs(template:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Camera")then d:Destroy()end end
 template.PrimaryPart=nil
 local meshCount=0
 for _,d in ipairs(template:GetDescendants())do if d:IsA("MeshPart")then meshCount+=1 end end
 assert(meshCount>0,"The imported user FBX has no meshes")
 local cf,size=template:GetBoundingBox()
 assert(size.Y>size.X and size.Y>size.Z,"The FBX post is not upright")
 template:ScaleTo(template:GetScale()*10.5/size.Y)
 cf,size=template:GetBoundingBox()
 local base=Vector3.new(cf.X,cf.Y-size.Y*.5,cf.Z)
 template:PivotTo(template:GetPivot()-base)
 template.WorldPivot=CFrame.identity
 -- Keep the original FBX geometry, UVs and PBR materials. Only add a light.
 local mesh=assert(template:FindFirstChildWhichIsA("MeshPart",true))
 local attachment=Instance.new("Attachment")attachment.Name="LanternLightOrigin"
 attachment.CFrame=mesh.CFrame:ToObjectSpace(CFrame.new(-size.X*.28,size.Y*.62,0))attachment.Parent=mesh
 local light=Instance.new("PointLight")light.Name="WarmLanternLight"light.Enabled=false light.Shadows=false light.Range=14 light.Brightness=1.1 light.Color=Color3.fromRGB(255,210,151)light.Parent=attachment
 local folder=world.Amenities.Lanterns folder:ClearAllChildren()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
 local report={lamps=0,sourceAssetId=assetId,sourceFile="sei-la-sksksks.fbx",meshesPerLamp=meshCount,height=10.5}
 local points={}
 for z=-260,280,45 do points[#points+1]=Vector2.new(Scene.pathX(z)+7,z)points[#points+1]=Vector2.new(145+30*math.sin(z/100)-7,z+9)end
 local lake=world:GetAttribute("CentralLake")for i=0,5 do local a=i*math.pi/3 points[#points+1]=Vector2.new(lake.X+math.cos(a)*88,lake.Z+math.sin(a)*66)end
 for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do for _,key in ipairs({"DeckStart","DeckEnd"})do local p=bridge:GetAttribute(key)points[#points+1]=Vector2.new(p.X,p.Z+8)end end
 for _,point in ipairs(points)do local hit=ground(point.X,point.Y)
  if hit and hit.Position.Y>7.4 and hit.Normal.Y>.83 then
   local m=template:Clone()m.Name="GnarledLanternPost"m:SetAttribute("SourceAssetId",assetId)m:SetAttribute("SourceFBXSHA256","02d7d43c417d633c908243ad34ca44599936876ce0a2b32926b7dc14f1012688")m:SetAttribute("GroundPoint",hit.Position)m:PivotTo(CFrame.new(hit.Position-Vector3.yAxis*.25))m.Parent=folder m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=false p.CanCollide=p:IsA("MeshPart")p.CanQuery=p.CanCollide p.CastShadow=p:IsA("MeshPart")
    elseif p:IsA("Light")then p.Enabled=false p.Shadows=false p.Range=14 p.Brightness=1.1 p.Color=Color3.fromRGB(255,210,151)C:AddTag(p,"ForestNightLight")
    elseif p:IsA("Fire")or p:IsA("Smoke")or p:IsA("ParticleEmitter")then p:Destroy()end
   end
   report.lamps+=1
  end
 end
 raw:Destroy()assert(report.lamps>=18,"Insufficient grounded lamp posts")world:SetAttribute("CandleLampCount",report.lamps)world:SetAttribute("LampAssetId",assetId)
 return report
end
return B
]============]).install()
reports.roots=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 for _,name in ipairs({"ForestGrassClient"})do local old=game.StarterPlayer.StarterPlayerScripts:FindFirstChild(name)if old then old:Destroy()end end
 for _,name in ipairs({"SkinnedGrassTemplates","GrassSampler","GrassPriority"})do local old=runtime:FindFirstChild(name)if old then old:Destroy()end end
 local terrainRay=RaycastParams.new()terrainRay.FilterType=Enum.RaycastFilterType.Include terrainRay.FilterDescendantsInstances={workspace.Terrain}terrainRay.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-310,0),terrainRay)end
 local report={trees=0,plants=0,rootProbes=0,removedPlants=0,removedDecor=0}
 if runtime:FindFirstChild("ActualRootContacts")then runtime.ActualRootContacts:Destroy()end
 local probeFolder=Instance.new("Folder")probeFolder.Name="ActualRootContacts"probeFolder.Parent=runtime
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,p in ipairs(folder:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=true end end end
 task.wait(.15)
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do for _,m in ipairs(folder:GetChildren())do
  local tree=folder==world.Decor.Trees local parts={}local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")and p.Name~="TrunkCollision"and(tree and p.Name:lower():find("trunk",1,true)or not tree)then
   parts[#parts+1]=p p.CanQuery=true
   for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local point=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(point)hi=hi:Max(point)end end end
  end end
  local own=RaycastParams.new()own.FilterType=Enum.RaycastFilterType.Include own.FilterDescendantsInstances=parts
  local samples={}local minimum=math.huge
  -- Sample the actual placed mesh from below. Source scale attributes are not trusted.
  local n=tree and 13 or 5
  for ix=0,n-1 do for iz=0,n-1 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/n local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/n
   local h=workspace:Raycast(Vector3.new(x,lo.Y-3,z),Vector3.yAxis*(hi.Y-lo.Y+6),own)
   if h then minimum=math.min(minimum,h.Position.Y)samples[#samples+1]=h.Position end
  end end
  if tree and minimum>lo.Y+1 then
   for ix=0,30 do for iz=0,30 do local x=lo.X+(hi.X-lo.X)*(ix+.5)/31 local z=lo.Z+(hi.Z-lo.Z)*(iz+.5)/31
    local h=workspace:Raycast(Vector3.new(x,lo.Y-3,z),Vector3.yAxis*(hi.Y-lo.Y+6),own)if h then minimum=math.min(minimum,h.Position.Y)samples[#samples+1]=h.Position end
   end end
  end
  local contacts={}
  for _,v in ipairs(samples)do if v.Y<minimum+(tree and 2.2 or .3)then contacts[#contacts+1]=v end end
  if #contacts==0 and not tree then
   -- Flat alpha cards can have no underside for an upward ray; use the actual placed mesh bounds for these plants.
   contacts={Vector3.new((lo.X+hi.X)*.5,lo.Y,(lo.Z+hi.Z)*.5)}m:SetAttribute("GroundingMethod","PlacedMeshBounds")
  else m:SetAttribute("GroundingMethod","PlacedMeshRaycast")end
  assert(#contacts>0,"No real base geometry: "..m.Name)
  local shift=math.huge local center=Vector3.zero local depth=tree and 1.15 or .18
  for _,point in ipairs(contacts)do local h=assert(ground(point.X,point.Z),"No ground beneath visible root")shift=math.min(shift,h.Position.Y-point.Y-depth)center+=point end
  center/= #contacts m:PivotTo(m:GetPivot()+Vector3.yAxis*shift)
  local finalCenter=center+Vector3.yAxis*shift m:SetAttribute("ActualRootPoint",finalCenter)m:SetAttribute("RootEmbedDepth",depth)
  local entry=Instance.new("ObjectValue")entry.Name="RootContact"entry.Value=m entry:SetAttribute("CoordinateSpace","World")entry.Parent=probeFolder
  local cf=m:GetPivot()
  for i,point in ipairs(contacts)do local v=Instance.new("Vector3Value")v.Name=tostring(i)v.Value=point+Vector3.yAxis*shift v.Parent=entry report.rootProbes+=1 end
  if tree then
   C:AddTag(m,"ForestTree")report.trees+=1
   local trunk=m:FindFirstChild("TrunkCollision")if trunk then local h=assert(ground(finalCenter.X,finalCenter.Z))trunk.CFrame=CFrame.new(finalCenter.X,h.Position.Y+trunk.Size.X*.5-.15,finalCenter.Z)*CFrame.Angles(0,0,math.pi*.5)end
  else report.plants+=1 end
  for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")then p.RenderFidelity=Enum.RenderFidelity.Performance p.CastShadow=tree
   if not p.CanCollide then p.CanQuery=false end
   if p:GetAttribute("ForestRestCF")then p:SetAttribute("ForestRestCF",p.CFrame)end
  end end
 end end
 -- Dense leaf carpets and oversized broad weeds are removed; native grass supplies continuous cover.
 for _,m in ipairs(world.Decor.Plants:GetChildren())do
  if m.Name=="DenseLeafPatch"or m.Name=="CloverPatch"then m:Destroy()report.removedPlants+=1 end
 end
 for _,m in ipairs(world.Amenities.CutTrunks:GetChildren())do local cf,size=m:GetBoundingBox()local h=ground(cf.X,cf.Z)if h then m:PivotTo(m:GetPivot()+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end end
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do
  local pivot=m:GetPivot()local h=ground(pivot.X,pivot.Z)
  if h and h.Position.Y>6 then local cf,size=m:GetBoundingBox()m:PivotTo(pivot+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end
 end
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())runtime:SetAttribute("GrassRenderer","NativeTerrain")runtime:SetAttribute("GrassMotionEnabled",false)
 return report
end
return B
]============]).install()
reports.tea=factory([============[local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 local raw=game:GetService("AssetService"):LoadAssetAsync(10080695893)local set=assert(raw:FindFirstChild("Utah Teapot Set"))
 local cup=assert(set.Cup)local pot=assert(set.Teapot)local spoon=assert(set.Spoon)
 assert(cup.MeshId=="rbxassetid://10080681533"and pot.MeshId=="rbxassetid://10080686163")
 local report={tables=0,cups=0,teapots=0,sourceAssetId=10080695893}
 local corners={}
 for _,m in ipairs(world:GetDescendants())do if m:IsA("Model")and m:FindFirstChild("AntiqueTeaTable")then corners[#corners+1]=m end end
 local function put(src,parent,cf,scale,name)
  local p=src:Clone()p.Name=name or src.Name p.Size*=scale p.CFrame=cf p.Anchored=true p.CanCollide=false p.CanQuery=true p.CanTouch=false p.Color=Color3.fromRGB(238,238,231)p:SetAttribute("SourceAssetId",10080695893)p.Parent=parent return p
 end
 for _,corner in ipairs(corners)do
  for _,d in ipairs(corner:GetChildren())do if d.Name=="TeaCup"or d.Name=="Teapot"or d.Name=="SilverSpoon"or d.Name=="UtahSpoon"then d:Destroy()end end
  local top=assert(corner.AntiqueTeaTable:FindFirstChild("table",true))local y=top.Position.Y+top.Size.Y*.5+.04 local x,z=top.Position.X,top.Position.Z
  for i=0,3 do local a=i*math.pi*.5 local m=Instance.new("Model")m.Name="TeaCup"m:SetAttribute("SourceAssetId",10080695893)m.Parent=corner
   local scale=.82 local p=put(cup,m,CFrame.new(x+math.cos(a)*1.7,y+cup.Size.Y*scale*.5,z+math.sin(a)*1.7)*CFrame.Angles(0,-a,0),scale,"UtahCup")m.PrimaryPart=p
   local click=Instance.new("ClickDetector")click.Name="TakeCup"click.MaxActivationDistance=9 click.Parent=m C:AddTag(click,"TreeWorldCupClick")report.cups+=1
   put(spoon,corner,CFrame.new(x+math.cos(a)*1.7+math.sin(a)*.55,y+.055,z+math.sin(a)*1.7-math.cos(a)*.55)*CFrame.Angles(0,-a,0),.8,"UtahSpoon")
  end
  local m=Instance.new("Model")m.Name="Teapot"m:SetAttribute("SourceAssetId",10080695893)m.Parent=corner local scale=.66
  m.PrimaryPart=put(pot,m,CFrame.new(x,y+pot.Size.Y*scale*.5,z),scale,"UtahTeapot")report.teapots+=1 report.tables+=1
 end
 local old=runtime:FindFirstChild("TeaCupTool")if old then old:Destroy()end
 local tool=Instance.new("Tool")tool.Name="TeaCupTool"tool.CanBeDropped=false tool.RequiresHandle=true tool:SetAttribute("SourceAssetId",10080695893)tool.Grip=CFrame.new(0,-.08,-.08)
 local handle=put(cup,tool,CFrame.identity,.74,"Handle")handle.Anchored=false handle.CanQuery=false handle.Massless=true tool.Parent=runtime raw:Destroy()
 return report
end
return B
]============]).install()
reports.theme=factory([============[local B={}
function B.install()
 local runtime=game.ReplicatedStorage.ForestRuntime local world=workspace.ForestWorld local gui=game.StarterGui.TreeWorldMenu
 for _,d in ipairs(gui:GetDescendants())do
  if d:IsA("UIGradient")then d.Color=ColorSequence.new(Color3.new(1,1,1))end
  if d:IsA("UIStroke")then d.Color=Color3.fromRGB(210,210,210)end
  if d:IsA("GuiObject")then d.BackgroundColor3=Color3.fromRGB(8,8,8)d.BorderSizePixel=0
   if d:IsA("TextLabel")or d:IsA("TextButton")or d:IsA("TextBox")then d.TextColor3=Color3.fromRGB(245,245,245)end
   if d:IsA("ImageLabel")or d:IsA("ImageButton")then d.ImageColor3=Color3.fromRGB(230,230,230)d.ImageTransparency=1 end
  end
 end
 local loading=gui.Background loading.BackgroundTransparency=0 loading.GameTitle.Text="TreeWorld"loading.Description.Text="Explorar. Descansar."
 loading.Bar.BackgroundColor3=Color3.fromRGB(50,50,50)loading.Bar.LoadBar.BackgroundColor3=Color3.fromRGB(242,242,242)
 local menu=gui.MainMenu menu.BackgroundTransparency=.58 menu.PlayButton.BackgroundTransparency=.28
 local origin=world.Amenities.ForestRuins:GetAttribute("Origin")local focus=origin+Vector3.new(0,5,0)
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain,world.Decor.Trees}
 local cameraPosition
 for _,height in ipairs({14,20,26})do for _,z in ipairs({-12,-24,12,24})do
  local candidate=origin+Vector3.new(60,height,z)
  if not workspace:Raycast(candidate,focus-candidate,ray)then cameraPosition=candidate break end
 end if cameraPosition then break end end
 assert(cameraPosition,"No unobstructed side view of the ruin")
 runtime:SetAttribute("MenuCameraFocus",focus)runtime:SetAttribute("MenuCameraCF",CFrame.lookAt(cameraPosition,focus))runtime:SetAttribute("MenuCameraView","RuinSide")
 runtime:SetAttribute("MenuTheme","Monochrome")runtime:SetAttribute("MusicTheme","MonochromeTransparent")return{menuTheme="Monochrome",camera="RuinSide"}
end
return B
]============]).install()
workspace.ForestWorld:SetAttribute("UpgradeVersion",96)
source(game.ServerScriptService,"Script","ForestServer",[============[local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local runtime = game.ReplicatedStorage:WaitForChild("ForestRuntime")
local Visuals=require(runtime:WaitForChild("Visuals"))Visuals.apply()
local Cycle=require(runtime:WaitForChild("Cycle"))
runtime:SetAttribute("CycleEpoch",Cycle.epoch(workspace:GetServerTimeNow()))
runtime:SetAttribute("CycleSeconds",Cycle.Duration)
local world = workspace:WaitForChild("ForestWorld")
local spawn = world:WaitForChild("ForestSpawn")
local spawnCF = runtime:GetAttribute("MainSpawnCF")
require(runtime:WaitForChild("GardenWeather")).start(runtime,world)
require(runtime:WaitForChild("SeasonController")).start(runtime,world)
require(runtime:WaitForChild("RuinController")).start(runtime,world)
require(runtime:WaitForChild("MusicController")).start(runtime,world)
require(runtime:WaitForChild("Foliage")).start(runtime,world)
local Collection=game:GetService("CollectionService")
for _,seat in ipairs(world.Amenities.LogBenches:GetDescendants())do if seat:IsA("Seat")then
	local prompt=seat:FindFirstChild("SitPrompt")
	if prompt then prompt.Triggered:Connect(function(player)
		local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
		if h and h.Health>0 and r and not seat.Occupant and(r.Position-seat.Position).Magnitude<9 then seat:Sit(h)end
	end)end
end end
local function character(player, model)
	local humanoid = model:WaitForChild("Humanoid", 10) local root = model:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= model then return end
	root.Anchored = false humanoid.PlatformStand = false humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16 humanoid.UseJumpPower = true humanoid.JumpPower = 50
	if (root.Position - spawnCF.Position).Magnitude > 28 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero end
end
local function playerAdded(player)
	player.RespawnLocation = spawn
	player.CharacterAdded:Connect(function(model) character(player, model) end)
	if player.Character then task.spawn(character, player, player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt if elapsed < 1 then return end elapsed = 0
	local time = workspace:GetServerTimeNow()
	local clock=Cycle.clock(time,runtime:GetAttribute("CycleEpoch"))Visuals.clock(clock)
	for _,light in ipairs(Collection:GetTagged("ForestNightLight"))do light.Enabled=Cycle.night(clock)>.015 light.Brightness=Cycle.night(clock)*1.25 end
	local strength = 2.8 + math.sin(time * 0.047) * 0.25 + math.sin(time * 0.023) * 0.15
	workspace.GlobalWind = Vector3.new(strength, 0, strength * 0.267)
	for _, player in ipairs(Players:GetPlayers()) do
		local model = player.Character local root = model and model:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -100 then model:PivotTo(spawnCF) root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero end
	end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestGardenClient",[============[local Run=game:GetService("RunService")local Players=game:GetService("Players")local UIS=game:GetService("UserInputService")local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local world=workspace:WaitForChild("ForestWorld")
local localWorld=Instance.new("Folder")localWorld.Name="TreeWorldGardenEffects"localWorld.Parent=workspace
local rng=Random.new()local leaves={}local cap=UIS.TouchEnabled and 14 or 24
for i=1,cap do local p=Instance.new("Part")p.Name="FallingLeaf"p.Shape=Enum.PartType.Ball p.Size=Vector3.new(.23,.035,.43)p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=1 p.Parent=localWorld leaves[i]={part=p,birth=-100}end
local canopies={}local Collection=game:GetService("CollectionService")
local function tree(m)if m:IsA("Model")then canopies[m]=true end end
for _,m in ipairs(Collection:GetTagged("ForestTree"))do tree(m)end
Collection:GetInstanceAddedSignal("ForestTree"):Connect(tree)Collection:GetInstanceRemovedSignal("ForestTree"):Connect(function(m)canopies[m]=nil end)
local soundFolder=runtime:WaitForChild("GardenSounds")
local function sound(name,parent,volume)local s=soundFolder[name]:Clone()s.Parent=parent s.Volume=volume or s.Volume return s end
local birds=sound("Forest",game:GetService("SoundService"),.27)birds:Play()
local wind=sound("Wind",game:GetService("SoundService"),.12)wind:Play()
local river=sound("River",game:GetService("SoundService"),0)river:Play()
local rain=sound("Rain",game:GetService("SoundService"),0)rain:Play()
local foot local footChar local footTime=0
local rainRoot=Instance.new("Part")rainRoot.Name="LocalRainCeiling"rainRoot.Size=Vector3.new(35,.1,35)rainRoot.Anchored=true rainRoot.Transparency=1 rainRoot.CanCollide=false rainRoot.CanTouch=false rainRoot.CanQuery=false rainRoot.Parent=localWorld
local emitter=Instance.new("ParticleEmitter")emitter.Name="GentleRain"emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"emitter.Rate=0 emitter.Lifetime=NumberRange.new(.45,.65)emitter.Speed=NumberRange.new(32,40)emitter.EmissionDirection=Enum.NormalId.Bottom emitter.Size=NumberSequence.new(.045)emitter.Color=ColorSequence.new(Color3.fromRGB(191,224,228))emitter.Transparency=NumberSequence.new(.65)emitter.Acceleration=Vector3.new(4,-18,1)emitter.SpreadAngle=Vector2.new(4,4)emitter.Parent=rainRoot
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.RespectCanCollide=true
local scan,elapsed,spawnClock,leafIndex=0,0,0,0 local nearby={}
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt scan+=dt spawnClock+=dt if elapsed<1/18 then return end local step=elapsed elapsed=0
 local camera=workspace.CurrentCamera if not camera then return end local pos=camera.CFrame.Position local now=workspace:GetServerTimeNow()
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
 if scan>1.2 then
  scan=0 table.clear(nearby)
  for m in pairs(canopies)do if m.Parent then local p=m:GetAttribute("ActualRootPoint")or m:GetPivot().Position if(Vector2.new(p.X-pos.X,p.Z-pos.Z)).Magnitude<24 then nearby[#nearby+1]=p end end end
  if #nearby>8 then while #nearby>8 do table.remove(nearby)end end
  if root then
   ray.FilterDescendantsInstances={world.Amenities,workspace.Terrain,world.Decor}
   local roof=workspace:Raycast(root.Position+Vector3.yAxis*2,Vector3.yAxis*24,ray)
   local raining=runtime:GetAttribute("Raining")
   emitter.Rate=raining and not roof and(UIS.TouchEnabled and 65 or 100)or 0
   Tween:Create(rain,TweenInfo.new(1),{Volume=raining and(roof and .035 or .14)or 0}):Play()
   local riverX=require(runtime.Scene).riverX(root.Position.Z)local riverWidth=require(runtime.Scene).riverWidth(root.Position.Z)
   local proximity=math.clamp(1-(math.abs(root.Position.X-riverX)-riverWidth)/40,0,1)
   local lake=world:GetAttribute("CentralLake")
   if lake then local r=math.sqrt(((root.Position.X-lake.X)/76)^2+((root.Position.Z-lake.Z)/52)^2)proximity=math.max(proximity,math.clamp((1.35-r)*2,0,1))end
   if math.abs(root.Position.Z)>295 then proximity=0 end
   Tween:Create(river,TweenInfo.new(1),{Volume=.24*proximity}):Play()
  end
 end
 rainRoot.CFrame=CFrame.new((root and root.Position or pos)+Vector3.yAxis*18)
 if spawnClock>.45 and h and h:GetState()~=Enum.HumanoidStateType.Swimming and #nearby>0 and runtime:GetAttribute("SeasonName")~="Inverno"then
  spawnClock=0 leafIndex=leafIndex%cap+1 local e=leaves[leafIndex]local p=nearby[rng:NextInteger(1,#nearby)]
  local focus=root and root.Position or pos
  local x=math.clamp(p.X,focus.X-10,focus.X+10)+rng:NextNumber(-3,3)local z=math.clamp(p.Z,focus.Z-10,focus.Z+10)+rng:NextNumber(-3,3)
  e.start=Vector3.new(x,focus.Y+rng:NextNumber(6,9),z)e.birth=now e.phase=rng:NextNumber(0,6.28)e.life=6

  e.part.Color=runtime:GetAttribute("SeasonName")=="Outono"and Color3.fromRGB(181,134,66)or Color3.fromRGB(128,153,93)e.part.Transparency=.12
 end
 for _,e in ipairs(leaves)do local age=now-e.birth if age< (e.life or 0)then local drift=Vector3.new(age*.25+math.sin(age*1.6+e.phase)*.4,-age*1.35,math.cos(age*1.2+e.phase)*.3)
  e.part.CFrame=CFrame.new(e.start+drift)*CFrame.Angles(age*.7,e.phase+age*.9,.3*math.sin(age*2))e.part.Transparency=.12+.88*math.clamp((age-e.life+1.5)/1.5,0,1)
 else e.part.Transparency=1 end end
 if c~=footChar then if foot then foot:Destroy()end footChar=c foot=root and sound("GrassStep",root,.055)or nil if foot then foot.Looped=false end end
 if h and root and foot then
  local default=root:FindFirstChild("Running")if default then default.Volume=0 end
  local moving=h.MoveDirection.Magnitude>.1 and h.FloorMaterial~=Enum.Material.Air and h.Health>0 and not h.Sit and h:GetState()~=Enum.HumanoidStateType.Swimming
  local material=h.FloorMaterial local name=(material==Enum.Material.Wood or material==Enum.Material.WoodPlanks)and"WoodStep"or(material==Enum.Material.Grass or material==Enum.Material.LeafyGrass or material==Enum.Material.Ground or material==Enum.Material.Mud)and"GrassStep"or"StoneStep"
  local id=soundFolder[name].SoundId if foot.SoundId~=id then foot:Stop()foot.SoundId=id end foot.Looped=name~="GrassStep"
  foot.PlaybackSpeed=math.clamp(root.AssemblyLinearVelocity.Magnitude/14,.7,1.25)
  footTime+=step
  if moving then if foot.Looped then if not foot.IsPlaying then foot:Play()end elseif footTime>.42/foot.PlaybackSpeed then footTime=0 foot:Play()end elseif foot.IsPlaying then foot:Stop()end
 end
end)
]============])
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","ForestReflectionClient",[============[local player=game.Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local Mirror=require(runtime:WaitForChild("RiverReflection"))
local reflection local character local elapsed=0 local scan=0 local point
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
game:GetService("RunService").Heartbeat:Connect(function(dt)
 elapsed+=dt scan+=dt if elapsed<.125 then return end elapsed=0 local camera=workspace.CurrentCamera local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")
 if not camera or not root then if reflection then reflection.hide()end return end
 if c~=character then if reflection then reflection.destroy()end character=c reflection=Mirror.create(c,player:WaitForChild("PlayerGui"),workspace)scan=1 end
 if player:GetAttribute("TreeWorldMenuOpen")then reflection.hide()return end
 if scan>.5 then scan=0 point=nil
  for _,r in ipairs({0,3,6,10,14})do for k=0,7 do local a=k*math.pi/4 local x,z=root.Position.X+math.cos(a)*r,root.Position.Z+math.sin(a)*r
   local h=workspace:Raycast(Vector3.new(x,150,z),Vector3.yAxis*-250,ray)
   if h and h.Material==Enum.Material.Water then local safe=true
    for _,dx in ipairs({-4,4})do for _,dz in ipairs({-6,6})do local edge=workspace:Raycast(Vector3.new(x+dx,150,z+dz),Vector3.yAxis*-250,ray)if not edge or edge.Material~=Enum.Material.Water then safe=false end end end
    if safe then point=h.Position break end
   end
  end if point then break end end
 end
 if point then reflection.update(point,camera.CFrame)else reflection.hide()end
end)
script.Destroying:Connect(function()if reflection then reflection.destroy()end end)
]============])
run(game.ServerScriptService.ForestServer.Source)
reports.tests=run([============[local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
assert(world:GetAttribute("UpgradeVersion")==96)
local report={trees=0,plants=0,actualRootProbes=0,walkProbes=0,teaTables=0,teaCups=0,ruins=4,audio=0}
assert(not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestGrassClient")and not runtime:FindFirstChild("SkinnedGrassTemplates"),"Skeletal spike grass remains")
assert(runtime:GetAttribute("GrassRenderer")=="NativeTerrain")
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray))end
for _,entry in ipairs(runtime.ActualRootContacts:GetChildren())do local m=entry.Value if m and m:IsDescendantOf(world)then local cf=m:GetPivot()
 for _,point in ipairs(entry:GetChildren())do local p=entry:GetAttribute("CoordinateSpace")=="World"and point.Value or cf:PointToWorldSpace(point.Value)local h=ground(p.X,p.Z)assert(p.Y-h.Position.Y<-.12,"Visible root remains above the soil: "..m.Name)report.actualRootProbes+=1 end
 if m.Parent==world.Decor.Trees then report.trees+=1 else report.plants+=1 end end end
assert(report.trees>=250 and report.plants>700 and report.actualRootProbes>1000)
for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={bridge}rp.RespectCanCollide=true
 for _,p in ipairs(bridge:GetDescendants())do if p:IsA("BasePart")then assert(p.Transparency==0 and p.CanCollide and p.CanQuery,"Bridge has an invisible or non-solid part")end end
 local nodes=game:GetService("HttpService"):JSONDecode(bridge:GetAttribute("WalkNodes"))
 for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
  for _,t in ipairs({0,.5,.95})do local center=a:Lerp(b,t)
   for _,offset in ipairs({-4.4,-2,0,2,4.4})do local p=center+Vector3.zAxis*offset local hit=assert(workspace:Raycast(p+Vector3.yAxis*.65,Vector3.yAxis*-1.5,rp),"Bridge has a walking gap")assert(hit.Instance.Name=="SolidDeckPlank"or hit.Instance.Name=="BankApron")assert(math.abs(hit.Position.Y-center.Y)<.18,"Bridge collision disagrees with visible deck")report.walkProbes+=1 end
  end
 end
 for _,i in ipairs({1,#nodes})do local p=Vector3.new(unpack(nodes[i]))assert(math.abs(ground(p.X,p.Z).Position.Y-p.Y)<.2,"Bridge shifted off the bank")end
end
assert(not world.Amenities.ForestRuins:FindFirstChild("EntrancePath"))
local positions={world.Amenities.ForestRuins:GetAttribute("Origin")}
for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do positions[#positions+1]=m:GetAttribute("Origin")end
for i=1,#positions do for j=i+1,#positions do assert((Vector2.new(positions[i].X,positions[i].Z)-Vector2.new(positions[j].X,positions[j].Z)).Magnitude>160,"Ruins still overlap")end end
for _,click in ipairs(C:GetTagged("TreeWorldCupClick"))do if click:IsDescendantOf(world)then assert(click:IsA("ClickDetector")and click.MaxActivationDistance==9)report.teaCups+=1 end end
for _,m in ipairs(world:GetDescendants())do if m:IsA("Model")and m.Name=="AntiqueTeaTable"then local cf,size=m:GetBoundingBox()assert(size.X<6 and size.Z<6 and size.Y<4,"Tea table still enormous")report.teaTables+=1 end
 assert(m.Name~="MoodPrompt"and m.Name~="ServeTea","Old tea interaction or mood selection remains")
end assert(report.teaTables==4 and report.teaCups==16)
for _,seat in ipairs(C:GetTagged("RuinSeat"))do if seat:IsDescendantOf(world)and seat.Name=="TeaSeat"then
 local table=seat.Parent.Parent.AntiqueTeaTable local center=table:GetPivot().Position local direction=Vector3.new(center.X-seat.Position.X,0,center.Z-seat.Position.Z).Unit
 assert(seat.CFrame.LookVector:Dot(direction)>.95,"Compact tea chair faces away from table")
end end
local desc=Instance.new("HumanoidDescription")local actor=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R6)desc:Destroy()actor.Name="TeaTest"actor.Parent=workspace
local click=C:GetTagged("TreeWorldCupClick")[1]local cupPoint=click.Parent:GetPivot().Position actor:PivotTo(CFrame.new(cupPoint+Vector3.yAxis*2))actor.HumanoidRootPart.Anchored=true
local bag=Instance.new("Backpack")bag.Parent=game.ServerStorage local mock={Character=actor,Backpack=bag,UserId=1092}
function mock:FindFirstChildOfClass(name)if name=="Backpack"then return bag end end
local service=require(runtime.RuinController).start(runtime,world)
assert(service.serve(mock,click,false),"Direct cup click failed to serve")assert(actor:FindFirstChildOfClass("Tool"),"Clicked cup did not reach the hand")
actor:Destroy()bag:Destroy()report.directCupServe=true
assert(not runtime:FindFirstChild("RuinInteraction")and not game.StarterPlayer.StarterPlayerScripts.ForestRuinClient.Source:find('TextLabel',1,true))
local Mood=require(runtime.RuinMood)local origin=positions[1]for _=1,60 do Mood.apply(origin,origin,"Neblina",1)end
assert(game.Lighting.ForestAtmosphere.Density<.35 and game.Lighting.ForestAtmosphere.Haze<1.3,"Fog accumulates")Mood.apply(origin+Vector3.xAxis*200,origin,"Neblina",1)assert(math.abs(game.Lighting.ForestAtmosphere.Density-.24)<.001)
for _,s in ipairs(runtime.GardenSounds:GetChildren())do game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>0,"Missing forest audio")report.audio+=1 end
assert(game.StarterPlayer.StarterPlayerScripts.ForestGardenClient.Source:find('root,.055',1,true))
local water=RaycastParams.new()water.FilterType=Enum.RaycastFilterType.Include water.FilterDescendantsInstances={workspace.Terrain}
local Scene=require(runtime.Scene)for z=-288,288,8 do local h=assert(workspace:Raycast(Vector3.new(Scene.riverX(z),200,z),Vector3.yAxis*-300,water))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.1,"River altered by repairs")end
local compiled=0
for _,parent in ipairs({game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts,game.StarterGui.TreeWorldMenu})do for _,s in ipairs(parent:GetChildren())do if s:IsA("LuaSourceContainer")then
 local m=Instance.new("ModuleScript")m.Source="return function()\n"..s.Source.."\nend"m.Parent=game.ServerStorage local ok,v=pcall(require,m)m:Destroy()assert(ok,s:GetFullName()..": "..tostring(v))compiled+=1 end end end
for _,s in ipairs(runtime:GetDescendants())do if s:IsA("ModuleScript")then local ok,v=pcall(require,s)assert(ok,s:GetFullName()..": "..tostring(v))compiled+=1 end end
report.compiled=compiled report.noTeaPopups=true report.fogStable=true report.nativeGrassRequested=true report.parts=0 report.pbr=0
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then report.parts+=1 end if p:IsA("SurfaceAppearance")then report.pbr+=1 end assert(not p:IsA("LuaSourceContainer"))end
assert(report.parts<17000 and report.pbr>1400,"Forest loss or mobile geometry increase")
assert(world:GetAttribute("AnimalsEnabled")==false and not runtime:FindFirstChild("CuteAnimalTemplates") and not runtime:FindFirstChild("WildlifeTemplates"))
assert(not world:FindFirstChild("Wildlife") and not world.Amenities:FindFirstChild("CuteAnimalRoutes"))
assert(not game.StarterPlayer.StarterPlayerScripts.ForestGardenClient.Source:find("CuteAnimal",1,true))
local lake=assert(world:GetAttribute("CentralLake"))
local lakePoints=0
for dx=-48,48,12 do for dz=-24,24,12 do
 local h=assert(workspace:Raycast(Vector3.new(lake.X+dx,200,lake.Z+dz),Vector3.yAxis*-300,water))
 assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.12,"Central lake contains dry holes")lakePoints+=1
end end
local tiles=0
assert(not world.Amenities.RiversideGarden:FindFirstChild("CartoonWater")and not game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestWaterClient"))
assert(math.abs(workspace.Terrain.WaterReflectance-.14)<.001)
for _,d in ipairs(world:GetDescendants())do assert(not d:IsA("ParticleEmitter")and not d:IsA("Beam")and not d:IsA("Trail"),"Suspended water/tea particles remain")end
local lampCount=0
for _,m in ipairs(world.Amenities.Lanterns:GetChildren())do
 assert(m:GetAttribute("SourceAssetId")==97893326625257,"Incorrect lamp asset")
 assert(m:GetAttribute("SourceFBXSHA256")=="02d7d43c417d633c908243ad34ca44599936876ce0a2b32926b7dc14f1012688","The user's FBX was not used")
 local mesh=assert(m:FindFirstChildWhichIsA("MeshPart",true))
 assert(mesh.MeshId~="rbxassetid://11161434042","Old post mesh remains")
 local cf,size=m:GetBoundingBox()local bottom=cf.Y-size.Y*.5 local anchor=m:GetAttribute("GroundPoint")local g=ground(anchor.X,anchor.Z)
 assert(math.abs(size.Y-10.5)<.05,"Incorrect post scale or orientation")
 assert(bottom<g.Position.Y+.1 and bottom>g.Position.Y-1.5,"Lamp floats")
 local light=assert(m:FindFirstChild("WarmLanternLight",true))assert(light:IsA("PointLight")and C:HasTag(light,"ForestNightLight"))lampCount+=1
end
assert(lampCount>=18)
local stoneCount=0 local stoneProbes=0
for _,m in ipairs(world.Amenities.RiversideGarden.StreamSteppingStones:GetChildren())do
 local center=m:GetAttribute("Centre")local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={m}rp.RespectCanCollide=true
 for _,off in ipairs({Vector3.new(.3,0,.3),Vector3.new(-1.4,0,.4),Vector3.new(.4,0,-1.4)})do local h=assert(workspace:Raycast(center+off+Vector3.yAxis*1,Vector3.yAxis*-2,rp),"Faceted stone has missing walk surface")assert(h.Instance.Name=="PaleStoneTop"and math.abs(h.Position.Y-center.Y)<.08)stoneProbes+=1 end
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then assert(p.Transparency==0 and p.CanCollide,"Stone side invisible or not solid")end end
 stoneCount+=1
end
assert(stoneCount>5)
for _,p in ipairs(world:GetDescendants())do if p:IsA("BasePart")then
 for _,n in ipairs({p.CFrame:GetComponents()})do assert(n==n and math.abs(n)<5000,"Invalid world frame: "..p:GetFullName())end
end end
local stair=world.Amenities.WeatheredHillStair local _,stairSize=stair:GetBoundingBox()assert(stairSize.Y<100,"Malformed hill stair survives")
local flowers=0 for _,m in ipairs(world.Decor.Plants:GetChildren())do if m:GetAttribute("LakeFlower")then flowers+=1 local _,size=m:GetBoundingBox()assert(size.Y<1.3,"Lakeside flower too tall")end end assert(flowers>=40)
local Scene=require(runtime.Scene)
for _,m in ipairs(world.Amenities.CutTrunks:GetChildren())do local cf,size=m:GetBoundingBox()assert(Scene.pathDistance(cf.X,cf.Z)>=8+math.min(11,math.max(size.X,size.Z)*.5),"Stump blocks trail")end
report.lakeWaterProbes=lakePoints report.cartoonWaterTiles=tiles report.exactLampPosts=lampCount report.facetedStones=stoneCount report.stoneWalkProbes=stoneProbes report.lowLakeFlowers=flowers report.noAnimals=true report.finiteWorldGeometry=true
assert(world:GetAttribute("TerrainOrganized")==true)
local rocks=0 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do local n=m.Name:lower()if n:find("rock",1,true)or n:find("boulder",1,true)then
 assert(m.Name=="PaleFacetedRock"and m:FindFirstChild("PaleStoneTop")and m:FindFirstChild("FacetedStoneSide"),"An old rock model remains")
 local cf,size=m:GetBoundingBox()assert(cf.Y-size.Y*.5<ground(cf.X,cf.Z).Position.Y+.1,"Accent rock floats")
 rocks+=1 end end assert(rocks>=12 and rocks<=24,"Incorrect accent rock density")
local house=world.Amenities.RiversideGarden.WaterCottage assert(house:GetAttribute("RebuiltEntrance"))
local O=house:GetAttribute("Origin")local path=game:GetService("HttpService"):JSONDecode(house:GetAttribute("EntryPath"))
local collision=RaycastParams.new()collision.FilterType=Enum.RaycastFilterType.Include collision.FilterDescendantsInstances={house}collision.RespectCanCollide=true
local entryProbes=0
for i=1,#path-1 do local a,b=Vector3.new(unpack(path[i])),Vector3.new(unpack(path[i+1]))
 for _,offset in ipairs({-1.0,0,1.0})do for _,height in ipairs({1.0,2.6,4.4})do
  local start=a+Vector3.new(0,height,offset)local hit=workspace:Raycast(start,b-a,collision)assert(not hit,"Cottage entrance blocked: "..(hit and hit.Instance.Name or ""))entryProbes+=1
 end end
end
local boardwalk=world.Amenities.RiversideGarden.LakesideBoardwalk local nodes=game:GetService("HttpService"):JSONDecode(boardwalk:GetAttribute("WalkNodes"))
local walkwayRay=RaycastParams.new()walkwayRay.FilterType=Enum.RaycastFilterType.Include walkwayRay.FilterDescendantsInstances={boardwalk}walkwayRay.RespectCanCollide=true
local walkwayProbes=0
for i=1,#nodes-1 do local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))
 for _,t in ipairs({0,.5,.95})do for _,offset in ipairs({-2.1,0,2.1})do local p=a:Lerp(b,t)+Vector3.zAxis*offset local h=assert(workspace:Raycast(p+Vector3.yAxis*.65,Vector3.yAxis*-1.5,walkwayRay),"Cottage walkway has a hole")assert(h.Instance.Name=="BoardwalkPlank"or h.Instance.Name=="BankApron")assert(math.abs(h.Position.Y-p.Y)<.18)walkwayProbes+=1 end end
end
local cf,size=house.CottageTeaCorner.AntiqueTeaTable:GetBoundingBox()assert(math.abs(cf.Y-size.Y*.5-(O.Y+.31))<.06,"Cottage tea table sank into floor")
local Player=require(runtime.MusicPlayer)local Config=require(runtime.MusicConfig)
assert(Config.parse("123456")==123456 and Config.parse("rbxassetid://123456")==123456 and not Config.parse("-1") and not Config.parse("12.5") and not Config.parse("abc") and not Config.parse(string.rep("9",20)))
for _,track in ipairs(Config.Tracks)do local s=Instance.new("Sound")s.SoundId="rbxassetid://"..track.id s.Parent=game:GetService("SoundService")game:GetService("ContentProvider"):PreloadAsync({s})assert(s.IsLoaded and s.TimeLength>5,"Preset music unavailable: "..track.title)s:Destroy()end
local listeners={false,false}local a=Instance.new("Folder")a.Parent=game:GetService("SoundService")local b=Instance.new("Folder")b.Parent=game:GetService("SoundService")
local A=Player.new(a,function(state)listeners[1]=state end,function()end)local B=Player.new(b,function(state)listeners[2]=state end,function()end)
assert(A.play(Config.Tracks[1].id,"A")and B.play(Config.Tracks[4].id,"B"))assert(A.sound.Parent==a and B.sound.Parent==b and listeners[1]and listeners[2])
A.pause()assert(not listeners[1]and listeners[2]and not A.sound.IsPlaying and B.sound.IsPlaying)
A.stop()assert(B.sound.IsPlaying and listeners[2])B.stop()assert(not listeners[2])a:Destroy()b:Destroy()
local root=Instance.new("Folder")root.Parent=game.ServerStorage local UI=require(runtime.MusicUI).build(root,Config.Tracks)
assert(UI.panel.Scroll:IsA("ScrollingFrame")and UI.panel.Scroll.AutomaticCanvasSize==Enum.AutomaticSize.Y and UI.input:IsA("TextBox")and #UI.tracks==#Config.Tracks and not UI.panel.Visible)root:Destroy()
local radio=house.PersonalRadio assert(radio:GetAttribute("SourceAssetId")==15855506991)local meshes=0
for _,d in ipairs(radio:GetDescendants())do assert(not d:IsA("Sound")and not d:IsA("LuaSourceContainer"),"Shared original radio playback remains")if d:IsA("MeshPart")then meshes+=1 end end assert(meshes==8)
local service=require(runtime.MusicController).start(runtime,world)
local mock={Character=nil,attributes={}}function mock:SetAttribute(k,v)self.attributes[k]=v end
assert(not service.apply(mock,"123"))assert(service.apply(mock,true)and mock.attributes.ListeningToMusic==true)assert(service.apply(mock,false)and not mock.attributes.ListeningToMusic)
assert(runtime:GetAttribute("MusicPlayback")=="LocalOnly")assert(not game.ServerScriptService.ForestServer.Source:find("SoundId",1,true))
report.accentRocks=rocks report.cottageEntranceProbes=entryProbes report.cottageWalkwayProbes=walkwayProbes report.cottageTeaFloor=true report.radioMeshes=meshes report.musicPresets=#Config.Tracks report.personalPlaybackIsolation=true report.musicStatusValidation=true report.musicScrollUI=true
assert(world:GetAttribute("WorldExtent")==4096 and world:GetAttribute("PreviousTreesRemoved")==453)
for _,m in ipairs(world.Decor.Trees:GetChildren())do assert(m:GetAttribute("FreshReferenceTree")and(m:GetAttribute("SourceAssetId")==580221169 or m:GetAttribute("SourceAssetId")==6432306802),"Old tree model remains")end
for _,click in ipairs(C:GetTagged("TreeWorldCupClick"))do if click:IsDescendantOf(world)then local cup=click.Parent:FindFirstChild("UtahCup")assert(cup and cup.MeshId=="rbxassetid://10080681533")end end
assert(runtime.TeaCupTool.Handle:IsA("MeshPart")and runtime.TeaCupTool.Handle.MeshId=="rbxassetid://10080681533")
local extended=0 for _,v in ipairs({Vector2.new(1500,1200),Vector2.new(-1500,-1200),Vector2.new(1800,-1400),Vector2.new(-1700,1500)})do local h=ground(v.X,v.Y)assert(math.abs(h.Position.Y-20)<.15 and h.Normal.Y>.95)extended+=1 end
local lakes=game:GetService("HttpService"):JSONDecode(runtime:GetAttribute("LakeLocations"))for i=3,#lakes do local p=lakes[i]local h=assert(workspace:Raycast(Vector3.new(p[1],150,p[3]),Vector3.yAxis*-250,water))assert(h.Material==Enum.Material.Water and math.abs(h.Position.Y-6)<.15)end
local Foliage=require(runtime.Foliage)local chunk=assert(Foliage.makeChunk(runtime,world,10,6))local streamedTrees=chunk:GetAttribute("TreeCount")assert(streamedTrees>0 and streamedTrees<=9)
for _,m in ipairs(chunk:GetChildren())do local p=m:GetAttribute("ActualRootPoint")assert(p and p.Y<ground(p.X,p.Z).Position.Y-.5)end chunk:Destroy()
local Mirror=require(runtime.RiverReflection)local actor=Instance.new("Model")actor.Parent=game.ServerStorage local head=Instance.new("Part")head.Name="Head"head.Size=Vector3.one head.CFrame=CFrame.new(0,9,0)head.Parent=actor
local parent=Instance.new("Folder")parent.Parent=game.ServerStorage local reflection=Mirror.create(actor,parent,workspace)
assert(reflection.surface.CanvasSize==Vector2.new(96,144)and reflection.view.ImageTransparency>=.88 and #reflection.pairs<=32)
reflection.update(Vector3.new(0,6,0),CFrame.new(0,12,16))assert(reflection.surface.Enabled and math.abs(reflection.patch.Position.Y-6.018)<.001 and reflection.camera.CFrame.Position.Y==0)
reflection.hide()assert(not reflection.surface.Enabled)reflection.destroy()actor:Destroy()parent:Destroy()
local gui=game.StarterGui.TreeWorldMenu assert(gui.Background.BackgroundColor3==Color3.fromRGB(8,8,8)and gui.MainMenu.PlayButton.TextColor3==Color3.fromRGB(245,245,245))
assert(runtime:GetAttribute("MenuCameraView")=="RuinSide"and(runtime:GetAttribute("MenuCameraCF").Position-runtime:GetAttribute("MenuCameraFocus")).X>50)
local uiRoot=Instance.new("Folder")uiRoot.Parent=game.ServerStorage local ui=require(runtime.MusicUI).build(uiRoot,Config.Tracks)assert(ui.panel.BackgroundColor3==Color3.fromRGB(12,12,12)and ui.panel.BackgroundTransparency>0 and ui.open.TextColor3.R==ui.open.TextColor3.G and ui.open.TextColor3.G==ui.open.TextColor3.B)uiRoot:Destroy()
assert(world:GetAttribute("PathMaterial")=="Ground")
report.nativeUtahTea=true report.noSuspendedWaterEffects=true report.weakAvatarReflection=true report.reflectionResolution={96,144}report.extendedGroundProbes=extended report.newLakes=#lakes-2 report.streamedChunkTrees=streamedTrees report.oldTreesCleared=true report.monochromeMenu=true
return report
]============])
runtime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)runtime:SetAttribute("ForestTestMode",nil)
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,expectedVersion=96,reports=reports}
