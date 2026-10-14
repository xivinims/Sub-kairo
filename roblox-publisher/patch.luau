assert(game.GameId==9421311218 and game.PlaceId==118064584465155 and game.PlaceVersion==98,"Published base changed")
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
 local g=ground(x,z)if not g or g.Position.Y<7.4 or g.Normal.Y<.78 then return end
 local m=template:Clone()local scale=height/template:GetAttribute("TemplateHeight")m:ScaleTo(template:GetScale()*scale)
 local rotation=CFrame.Angles(0,yaw,0)local y=g.Position.Y-1.65
 local points=template:GetAttribute("RootProfile")local values=game:GetService("HttpService"):JSONDecode(points)
 for _,p in ipairs(values)do local off=rotation:VectorToWorldSpace(Vector3.new(unpack(p))*scale)local hit=ground(x+off.X,z+off.Z)if not hit or hit.Position.Y<7 then m:Destroy()return end y=math.min(y,hit.Position.Y-off.Y-1.65)end
 m:PivotTo(CFrame.new(x,y,z)*rotation)m:SetAttribute("ActualRootPoint",Vector3.new(x,y,z))m:SetAttribute("FreshReferenceTree",true)m:SetAttribute("RootEmbedDepth",1.65)
 -- Apply the current season before parenting; new chunks must not flash green
 -- while waiting for descendant signals to be delivered.
 local index=game.ReplicatedStorage.ForestRuntime:GetAttribute("SeasonIndex")or 1
 for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then
  local color=p:GetAttribute("SeasonBaseColor")
  if color then
   if index==2 then color=color:Lerp(Color3.fromRGB(64,122,53),.12)
   elseif index==3 then color=color:Lerp(Color3.fromRGB(191,134,63),.72)
   elseif index==4 then color=color:Lerp(Color3.fromRGB(144,165,153),.5)end
   p.Color=color local appearance=p:FindFirstChildOfClass("SurfaceAppearance")if appearance then appearance.Color=color end
  end
 end end
 m.Parent=parent Collection:AddTag(m,"ForestTree")return m
end
function M.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)
 local previousRemoved=world:GetAttribute("PreviousTreesRemoved")or 0 local removed=#world.Decor.Trees:GetChildren()world.Decor.Trees:ClearAllChildren()
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
 -- Extra visual variants keep the same proven root profiles/meshes but vary
 -- crown tone and proportions through placement height. They remain fully
 -- seasonal because SeasonBaseColor is stored per foliage part.
 local originals={templates[1],templates[2]}
 local specs={
  {source=1,name="BroadleafFresh",tint=Color3.fromRGB(112,170,76),mix=.16},
  {source=1,name="BroadleafDeep",tint=Color3.fromRGB(70,130,61),mix=.18},
  {source=1,name="BroadleafMeadow",tint=Color3.fromRGB(139,184,83),mix=.20},
  {source=1,name="BroadleafOld",tint=Color3.fromRGB(82,119,54),mix=.24},
  {source=2,name="PineFresh",tint=Color3.fromRGB(93,148,72),mix=.13},
  {source=2,name="PineDeep",tint=Color3.fromRGB(58,112,66),mix=.18},
  {source=2,name="PineSilver",tint=Color3.fromRGB(96,132,105),mix=.18},
  {source=2,name="PineYoung",tint=Color3.fromRGB(112,158,82),mix=.15},
 }
 for _,spec in ipairs(specs)do
  local clone=originals[spec.source]:Clone()clone.Name=spec.name clone:SetAttribute("TreeVariant",#templates+1)
  for _,p in ipairs(clone:GetDescendants())do if p:IsA("BasePart")and p:GetAttribute("SeasonBaseColor")then
   local base=p:GetAttribute("SeasonBaseColor"):Lerp(spec.tint,spec.mix)
   p:SetAttribute("SeasonBaseColor",base)p.Color=base
   local appearance=p:FindFirstChildOfClass("SurfaceAppearance")if appearance then appearance.Color=base end
  end end
  clone.Parent=folder templates[#templates+1]=clone
 end
 runtime:SetAttribute("NativeTreeVarietyCount",#templates)
 raw:Destroy()forest:Destroy()
 local protected={}
 local protectModels={world.Amenities.ForestRuins}
 local oldCottage=world.Amenities.RiversideGarden:FindFirstChild("WaterCottage")
 if oldCottage then protectModels[#protectModels+1]=oldCottage end
 local existingMansion=world.Amenities:FindFirstChild("RuinMansion")
 if existingMansion then protectModels[#protectModels+1]=existingMansion end
 for _,m in ipairs(protectModels)do local cf,size=m:GetBoundingBox()protected[#protected+1]={x=cf.X,z=cf.Z,r=math.max(size.X,size.Z)*.55+8}end
 for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do local p=m:GetAttribute("Origin")protected[#protected+1]={x=p.X,z=p.Z,r=36}end
 local rng=Random.new(96014)local placed={}local count=0
 for attempt=1,9000 do if count>=280 then break end local x,z=rng:NextNumber(-390,390),rng:NextNumber(-350,350)
  if Scene.pathDistance(x,z)<14 or math.abs(x-Scene.riverX(z))<Scene.riverWidth(z)+16 then continue end
  local lake=world:GetAttribute("CentralLake")if math.sqrt(((x-lake.X)/76)^2+((z-lake.Z)/52)^2)<1.15 then continue end
  local blocked=false for _,p in ipairs(protected)do if(Vector2.new(x-p.x,z-p.z)).Magnitude<p.r then blocked=true break end end
  for _,p in ipairs(placed)do if(p-Vector2.new(x,z)).Magnitude<18 then blocked=true break end end if blocked then continue end
  local index=rng:NextInteger(1,#templates)local template=templates[index]
  local pine=template:GetAttribute("SourceAssetId")==6432306802
  local tree=M.place(template,world.Decor.Trees,x,z,rng:NextNumber(pine and 28 or 18,pine and 58 or 46),rng:NextNumber(0,math.pi*2))
  if tree then count+=1 placed[#placed+1]=Vector2.new(x,z)end
  if attempt%100==0 then task.wait()end
 end
 local chunks=world.Decor:FindFirstChild("ActiveForestChunks")if chunks then chunks:Destroy()end chunks=Instance.new("Folder")chunks.Name="ActiveForestChunks"chunks.Parent=world.Decor
 world:SetAttribute("TreeCount",count)world:SetAttribute("PreviousTreesRemoved",math.max(previousRemoved,removed))runtime:SetAttribute("ForestChunkSize",128)runtime:SetAttribute("ForestLiveChunkLimit",36)runtime:SetAttribute("ForestChunkRadius",4)
 return{removedTrees=removed,newTrees=count,treeAssets={580221169,6432306802},chunkLimit=32,varieties=#templates}
end
function M.makeChunk(runtime,world,cx,cz)
 if math.abs(cx*128)<448 and math.abs(cz*128)<448 then return end
 local m=Instance.new("Model")m.Name="ForestChunk_"..cx.."_"..cz m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local rng=Random.new((cx*73856093+cz*19349663)%2147483647)local templates=runtime.NativeTreeTemplates local count=0
 for ix=0,2 do for iz=0,2 do local x,z=cx*128+20+ix*40+rng:NextNumber(-6,6),cz*128+20+iz*40+rng:NextNumber(-6,6)
  if math.abs(x)>1980 or math.abs(z)>1980 then continue end
  local choices=templates:GetChildren()local template=choices[rng:NextInteger(1,#choices)]
  local pine=template:GetAttribute("SourceAssetId")==6432306802
  if M.place(template,m,x,z,rng:NextNumber(pine and 28 or 18,pine and 56 or 45),rng:NextNumber(0,6.28))then count+=1 end
 end end
 if count==0 then m:Destroy()return end m:SetAttribute("TreeCount",count)m.Parent=world.Decor.ActiveForestChunks return m
end
function M.start(runtime,world)
 local active={}local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<1 then return end elapsed=0 if runtime:GetAttribute("ForestTestMode")then return end
  local wanted={}
  for _,player in ipairs(game.Players:GetPlayers())do local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")if r then local cx,cz=math.floor(r.Position.X/128),math.floor(r.Position.Z/128)
   for dx=-4,4 do for dz=-4,4 do local x,z=cx+dx,cz+dz if math.abs(x*128)>448 or math.abs(z*128)>448 then local k=x..":"..z wanted[k]={x=x,z=z,d=(Vector2.new(x*128+64-r.Position.X,z*128+64-r.Position.Z)).Magnitude}end end end
  end end
  local order={}for k,v in pairs(wanted)do v.k=k order[#order+1]=v end table.sort(order,function(a,b)return a.d<b.d end)while #order>36 do table.remove(order)end
  local keep={}for _,v in ipairs(order)do keep[v.k]=true end for k,m in pairs(active)do if not keep[k]then m:Destroy()active[k]=nil end end
  local added=0 for _,v in ipairs(order)do if not active[v.k]then local m=M.makeChunk(runtime,world,v.x,v.z)if m then active[v.k]=m added+=1 if added>=4 then break end end end end
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
local oldSeasons=runtime:FindFirstChild("Seasons")if oldSeasons then oldSeasons:Destroy()end
source(runtime,"ModuleScript","Seasons",[============[local S={}
S.Names={"Primavera","Verão","Outono","Inverno"}
S.Duration=1200
S.Transition=12
function S.index(now,epoch)
 return math.floor(math.max(0,now-epoch)/S.Duration)%4+1
end
return S
]============])
source(runtime,"ModuleScript","SeasonController",[============[local Controller={}
function Controller.start(runtime,world)
 local Seasons=require(runtime.Seasons)local Scene=require(runtime.Scene)local Terrain=workspace.Terrain
 local previousIndex=1 local busy=false local parts={}
 local function target(entry,index)
  local color=entry.base
  if index==1 and entry.accent then color=Color3.fromRGB(215,170,186)
  elseif index==2 then color=color:Lerp(Color3.fromRGB(64,122,53),.12)
  elseif index==3 then color=color:Lerp(Color3.fromRGB(191,134,63),entry.flower and .22 or .72)
  elseif index==4 then color=color:Lerp(Color3.fromRGB(144,165,153),.50)end
  local hidden=index==4 and entry.kind=="plants"or index==3 and entry.flower
  return color,hidden and 1 or entry.transparency
 end
 local function record(model,kind)
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
   local n=p.Name:lower()local vegetation=n:find("leaf",1,true)or n:find("leaves",1,true)or n:find("fern",1,true)or n:find("flower",1,true)or n:find("clover",1,true)
   if vegetation or kind=="plants"or p:GetAttribute("SeasonBaseColor")then
    local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
    local entry={part=p,appearance=appearance,base=p:GetAttribute("SeasonBaseColor")or p.Color,transparency=p:GetAttribute("SeasonBaseTransparency")or p.Transparency,kind=kind,flower=model.Name:lower():find("flower",1,true)~=nil,accent=model:GetAttribute("SpringBlossom")==true}
    parts[p]=entry
    local index=runtime:GetAttribute("SeasonIndex")or 1
    local color,transparency=target(entry,index)p.Color=color p.Transparency=transparency
    if appearance then appearance.Color=color end
   end
  end end
 end
 for _,m in ipairs(world.Decor.Trees:GetChildren())do record(m,"trees")end
 for _,m in ipairs(world.Decor.Plants:GetChildren())do record(m,"plants")end
 local streamed=world.Decor:WaitForChild("ActiveForestChunks")
 for _,chunk in ipairs(streamed:GetChildren())do record(chunk,"trees")end
 streamed.ChildAdded:Connect(function(chunk)record(chunk,"trees")end)
 streamed.DescendantRemoving:Connect(function(part)parts[part]=nil end)
 local function surface(index)
  local grass=index==1 and Color3.fromRGB(107,153,64)or index==2 and Color3.fromRGB(82,139,57)or index==3 and Color3.fromRGB(153,134,78)or Color3.fromRGB(176,183,176)
  local groundColor=index==1 and Color3.fromRGB(114,91,66)or index==2 and Color3.fromRGB(105,86,59)or index==3 and Color3.fromRGB(128,92,57)or Color3.fromRGB(116,108,96)
  local mudColor=index==1 and Color3.fromRGB(96,79,62)or index==2 and Color3.fromRGB(88,75,55)or index==3 and Color3.fromRGB(108,75,52)or Color3.fromRGB(101,94,87)
  Terrain:SetMaterialColor(Enum.Material.Grass,grass)Terrain:SetMaterialColor(Enum.Material.LeafyGrass,grass)
  Terrain:SetMaterialColor(Enum.Material.Ground,groundColor)Terrain:SetMaterialColor(Enum.Material.Mud,mudColor)
  Terrain:SetMaterialColor(Enum.Material.Snow,Color3.fromRGB(224,229,231))
  if index~=4 and previousIndex~=4 then return end
  local extent=(world:GetAttribute("WorldExtent")or 1024)*.5
  local batch=0
  for bx=-extent,extent-256,256 do for bz=-extent,extent-256,256 do
   local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+256,152,bz+256))
   if index==4 then
    Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.Snow)
    Terrain:ReplaceMaterial(region,4,Enum.Material.LeafyGrass,Enum.Material.Snow)
   else Terrain:ReplaceMaterial(region,4,Enum.Material.Snow,Enum.Material.Grass)end
   batch+=1 if batch%4==0 then task.wait()end
  end end
 end
 local function apply(index,instant)
  if busy then return false end busy=true local name=Seasons.Names[index]
  runtime:SetAttribute("SeasonName",name)runtime:SetAttribute("SeasonIndex",index)runtime:SetAttribute("SeasonChanging",true)
  local changes={}
  for _,entry in pairs(parts)do
   local p=entry.part
   if p.Parent then
    local color,transparency=target(entry,index)
    changes[#changes+1]={entry=entry,from=p.Color,to=color,fromTransparency=p.Transparency,toTransparency=transparency}
   end
  end
  -- Eighteen bounded updates avoid thousands of per-frame replicated server tweens on mobile.
  local frames=instant and 1 or 18
  for frame=1,frames do
   local t=instant and 1 or(frame-1)/(frames-1)local alpha=t*t*(3-2*t)
   for i,c in ipairs(changes)do local e=c.entry
    if e.part.Parent then local color=c.from:Lerp(c.to,alpha)e.part.Color=color e.part.Transparency=c.fromTransparency+(c.toTransparency-c.fromTransparency)*alpha
     if e.appearance and e.appearance.Parent then e.appearance.Color=color end
    end
    if i%250==0 then task.wait()end
   end
   if frame<frames then task.wait(Seasons.Transition/(frames-1))end
  end
  surface(index)
  runtime:SetAttribute("SeasonChanging",false)runtime:SetAttribute("SeasonRevision",(runtime:GetAttribute("SeasonRevision")or 0)+1)previousIndex=index busy=false return true
 end
 runtime:SetAttribute("SeasonEpoch",workspace:GetServerTimeNow())runtime:SetAttribute("SeasonSeconds",Seasons.Duration)
 -- Saved terrain is already spring; boot does not need to rewrite its geometry.
 runtime:SetAttribute("SeasonName","Primavera")runtime:SetAttribute("SeasonIndex",1)runtime:SetAttribute("SeasonRevision",0)runtime:SetAttribute("SeasonChanging",false)
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  if runtime:GetAttribute("SeasonTestMode")then return end
  elapsed+=dt if elapsed<2 then return end elapsed=0
  local index=Seasons.index(workspace:GetServerTimeNow(),runtime:GetAttribute("SeasonEpoch"))
  if not busy and index~=runtime:GetAttribute("SeasonIndex")then task.spawn(apply,index,false)end
 end)
 return{apply=apply,surface=surface}
end
return Controller
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
   if edge>0 then h=h*(1-edge)+22*edge end
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
  for ix=1,d.Size.X do for iz=1,d.Size.Z do local x,z=lo.X+(ix-.5)*4,lo.Z+(iz-.5)*4 local r=math.sqrt(((x-cx)/rx)^2+((z-cz)/rz)^2)local a=math.clamp((r-.56)/.7,0,1)a=a*a*(3-2*a)local h=-1+23*a
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
reports.water=factory([============[
local B={}
function B.install()
 local world=workspace.ForestWorld
 local runtime=game.ReplicatedStorage.ForestRuntime
 local Terrain=workspace.Terrain
 local garden=world.Amenities.RiversideGarden

 for _,name in ipairs({"AnimeRiverFoam","StreamSteppingStones","CartoonWater"})do
  local old=garden:FindFirstChild(name)
  if old then old:Destroy()end
 end

 local rocks=world.Decor:FindFirstChild("RocksAndLogs")
 if rocks then rocks:ClearAllChildren()end

 for _,d in ipairs(world:GetDescendants())do
  if d:IsA("ParticleEmitter")or d:IsA("Beam")or d:IsA("Trail")then
   d:Destroy()
  end
 end

 local oldClient=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestWaterClient")
 if oldClient then oldClient:Destroy()end

 Terrain.WaterColor=Color3.fromRGB(54,143,174)
 Terrain.WaterTransparency=.20
 Terrain.WaterReflectance=.20
 Terrain.WaterWaveSize=.05
 Terrain.WaterWaveSpeed=6

 runtime:SetAttribute("WaterStyle","NativeBlueReflective")
 runtime:SetAttribute("NoWaterParticles",true)
 runtime:SetAttribute("NoDecorativeWaterStones",true)
 world:SetAttribute("CartoonWaterTiles",0)
 world:SetAttribute("ReferenceSteppingStones",0)

 return{
  stones=0,
  accentRocks=0,
  stoneFaces=0,
  removedWaterOverlays=true,
  noDecorativeRocks=true,
  waterReflectance=Terrain.WaterReflectance
 }
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
 template:ScaleTo(template:GetScale()*8.8/size.Y)
 cf,size=template:GetBoundingBox()
 local base=Vector3.new(cf.X,cf.Y-size.Y*.5,cf.Z)
 template:PivotTo(template:GetPivot()-base)
 template.WorldPivot=CFrame.identity
 -- Keep the original FBX geometry, UVs and PBR materials. Only add a light.
 local mesh=assert(template:FindFirstChildWhichIsA("MeshPart",true))
 local attachment=Instance.new("Attachment")attachment.Name="LanternLightOrigin"
 attachment.CFrame=mesh.CFrame:ToObjectSpace(CFrame.new(-size.X*.28,size.Y*.62,0))attachment.Parent=mesh
 local light=Instance.new("PointLight")light.Name="WarmLanternLight"light.Enabled=false light.Shadows=true light.Range=18 light.Brightness=1.35 light.Color=Color3.fromRGB(255,210,151)light.Parent=attachment
 local folder=world.Amenities.Lanterns folder:ClearAllChildren()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
 local report={lamps=0,sourceAssetId=assetId,sourceFile="sei-la-sksksks.fbx",meshesPerLamp=meshCount,height=8.8}
 local points={}
 local side=1
 for z=-276,276,46 do
  points[#points+1]=Vector2.new(Scene.pathX(z)+side*7,z)
  side*=-1
 end
 local lake=world:GetAttribute("CentralLake")
 for i=0,3 do local a=i*math.pi*.5 points[#points+1]=Vector2.new(lake.X+math.cos(a)*91,lake.Z+math.sin(a)*69)end
 for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do
  for _,key in ipairs({"DeckStart","DeckEnd"})do local p=bridge:GetAttribute(key)points[#points+1]=Vector2.new(p.X,p.Z+7)end
 end
 for _,point in ipairs(points)do local hit=ground(point.X,point.Y)
  if hit and hit.Position.Y>7.4 and hit.Normal.Y>.76 then
   local m=template:Clone()m.Name="GnarledLanternPost"m:SetAttribute("SourceAssetId",assetId)m:SetAttribute("SourceFBXSHA256","02d7d43c417d633c908243ad34ca44599936876ce0a2b32926b7dc14f1012688")m:SetAttribute("GroundPoint",hit.Position)
   local tangent=Vector3.new(Scene.pathX(point.Y+6)-Scene.pathX(point.Y-6),0,12)
   if tangent.Magnitude<.1 then tangent=Vector3.zAxis end
   local base=hit.Position-Vector3.yAxis*.55
   m:PivotTo(CFrame.lookAt(base,base+tangent.Unit))m.Parent=folder m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=false p.CanCollide=p:IsA("MeshPart")p.CanQuery=p.CanCollide p.CastShadow=p:IsA("MeshPart")
    elseif p:IsA("Light")then p.Enabled=false p.Shadows=true p.Range=18 p.Brightness=1.35 p.Color=Color3.fromRGB(255,210,151)C:AddTag(p,"ForestNightLight")
    elseif p:IsA("Fire")or p:IsA("Smoke")or p:IsA("ParticleEmitter")then p:Destroy()end
   end
   report.lamps+=1
  end
 end
 raw:Destroy()assert(report.lamps>=14,"Insufficient grounded lamp posts")world:SetAttribute("CandleLampCount",report.lamps)world:SetAttribute("LampAssetId",assetId)
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
  local shift=math.huge local center=Vector3.zero local depth=tree and 1.55 or .18
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
 local cut=world.Amenities:FindFirstChild("CutTrunks")
 if cut then report.removedDecor+=#cut:GetChildren()cut:ClearAllChildren()end
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do
  local name=m.Name:lower()
  if name:find("log",1,true)or name:find("stump",1,true)or name:find("trunk",1,true)or name:find("fallen",1,true)then
   report.removedDecor+=1 m:Destroy()
  else
   local pivot=m:GetPivot()local h=ground(pivot.X,pivot.Z)
   if h and h.Position.Y>6 then local cf,size=m:GetBoundingBox()m:PivotTo(pivot+Vector3.yAxis*(h.Position.Y-(cf.Y-size.Y*.5)-.3))end
  end
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

reports.world97=factory([============[
local B={}
function B.install()
 local AS=game:GetService("AssetService")
 local Lighting=game:GetService("Lighting")
 local Terrain=workspace.Terrain
 local world=workspace.ForestWorld
 local runtime=game.ReplicatedStorage.ForestRuntime
 local Scene=require(runtime.Scene)
 local report={rocksRemoved=0,destroyedHouses=0,brokenBridges=0,posts=0,staleScriptsRemoved=0}

 -- STREAMING: large visual radius, while dynamic forest chunks still protect mobile memory.
 workspace.StreamingEnabled=true
 pcall(function()workspace.StreamingMinRadius=320 end)
 pcall(function()workspace.StreamingTargetRadius=896 end)
 runtime:SetAttribute("StreamingMinRadiusStuds",320)
 runtime:SetAttribute("StreamingTargetRadiusStuds",896)
 runtime:SetAttribute("StreamingPrefetchDistance",640)

 -- ANIMATION CLEANUP: TreeWorld uses the Roblox avatar Animate controller only.
 for _,container in ipairs({game.StarterPlayer.StarterPlayerScripts,game.StarterPlayer.StarterCharacterScripts})do
  for _,s in ipairs(container:GetChildren())do
   local n=s.Name:lower()
   if n:find("nextbot",1,true)or n:find("evade",1,true)or n=="nb_r6motioncontroller"or n=="nb_evadecharactercontroller"or n=="nb_evademovement"then
    s:Destroy()report.staleScriptsRemoved+=1
   end
  end
 end
 game.StarterPlayer.CharacterUseJumpPower=true
 runtime:SetAttribute("AnimationMode","RobloxDefault")

 -- NO DECORATIVE STONES / CUT LOGS.
 local garden=world.Amenities.RiversideGarden
 local stepping=garden:FindFirstChild("StreamSteppingStones")
 if stepping then
  report.rocksRemoved+=#stepping:GetDescendants()
  stepping:Destroy()
 end
 local rocks=world.Decor:FindFirstChild("RocksAndLogs")
 if rocks then report.rocksRemoved+=#rocks:GetDescendants()rocks:ClearAllChildren()end
 local cut=world.Amenities:FindFirstChild("CutTrunks")
 if cut then cut:ClearAllChildren()end

 -- Remove sand in terrain in bounded chunks: paths become Ground, landscape remains Grass.
 local extent=(world:GetAttribute("WorldExtent")or 4096)*.5
 for x=-extent,extent-512,512 do
  for z=-extent,extent-512,512 do
   local region=Region3.new(Vector3.new(x,-64,z),Vector3.new(x+512,152,z+512))
   Terrain:ReplaceMaterial(region,4,Enum.Material.Sand,Enum.Material.Ground)
  end
  task.wait()
 end
 Terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(108,84,60))
 Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(104,153,62))
 world:SetAttribute("PathMaterial","Ground")
 world:SetAttribute("DecorativeRocksRemoved",true)

 -- Remove riverside cottage/boardwalk, preserve its radio at the ruin.
 local cottage=garden:FindFirstChild("WaterCottage")
 if cottage then
  local radio=cottage:FindFirstChild("PersonalRadio")
  if radio then
   radio.Parent=world.Amenities.ForestRuins
   if radio:IsA("Model")then
    local origin=world.Amenities.ForestRuins:GetAttribute("Origin")
    radio:PivotTo(CFrame.new(origin+Vector3.new(8,1.2,-7))*CFrame.Angles(0,math.rad(-18),0))
   end
  end
  cottage:Destroy()
 end
 local boardwalk=garden:FindFirstChild("LakesideBoardwalk")
 if boardwalk then boardwalk:Destroy()end
 runtime:SetAttribute("RiversideCottageRemoved",true)

 -- Refill the old cottage clearing with trees instead of architecture.
 local Foliage=require(runtime.Foliage)
 local templates=runtime.NativeTreeTemplates:GetChildren()
 local cottageOrigin=Vector3.new(92,22,144)
 for i,offset in ipairs({
  Vector2.new(-28,-24),Vector2.new(26,-20),Vector2.new(-31,19),
  Vector2.new(32,24),Vector2.new(-12,32),Vector2.new(14,-34)
 })do
  local template=templates[(i-1)%#templates+1]
  Foliage.place(template,world.Decor.Trees,cottageOrigin.X+offset.X,cottageOrigin.Z+offset.Y,22+(i%3)*7,i*.83)
 end

 -- DESTROYED HOUSES from the requested Creator Store asset, far from main ruins.
 local destroyedFolder=world.Amenities:FindFirstChild("DestroyedHouses")
 if destroyedFolder then destroyedFolder:Destroy()end
 destroyedFolder=Instance.new("Folder")destroyedFolder.Name="DestroyedHouses"destroyedFolder.Parent=world.Amenities

 local raw=AS:LoadAssetAsync(17385388938)
 local original=raw:FindFirstChildWhichIsA("Model",true)
 assert(original,"Destroyed-house asset has no model")
 local template=original:Clone()
 for _,d in ipairs(template:GetDescendants())do
  if d:IsA("LuaSourceContainer")or d:IsA("Camera")or d:IsA("Sound")or d:IsA("ParticleEmitter")or d:IsA("Fire")or d:IsA("Smoke")then d:Destroy()
  elseif d:IsA("BasePart")then d.Anchored=true d.CanTouch=false d.CanQuery=true
  end
 end
 local cf,size=template:GetBoundingBox()
 local target=30
 local scale=target/math.max(size.X,size.Z)
 template:ScaleTo(template:GetScale()*math.clamp(scale,.25,2.5))
 cf,size=template:GetBoundingBox()
 local base=Vector3.new(cf.X,cf.Y-size.Y*.5,cf.Z)
 template:PivotTo(template:GetPivot()-base)

 local groundParams=RaycastParams.new()
 groundParams.FilterType=Enum.RaycastFilterType.Include
 groundParams.FilterDescendantsInstances={Terrain}
 groundParams.IgnoreWater=true
 local waterParams=RaycastParams.new()
 waterParams.FilterType=Enum.RaycastFilterType.Include
 waterParams.FilterDescendantsInstances={Terrain}
 local ruinOrigin=world.Amenities.ForestRuins:GetAttribute("Origin")
 local offsets={
  Vector2.new(620,520),Vector2.new(-720,560),Vector2.new(860,-510),
  Vector2.new(-820,-650),Vector2.new(1120,250),Vector2.new(-1050,180)
 }
 for i,o in ipairs(offsets)do
  local x,z=ruinOrigin.X+o.X,ruinOrigin.Z+o.Y
  if math.abs(x)<1850 and math.abs(z)<1850 and Scene.pathDistance(x,z)>35 and math.abs(x-Scene.riverX(z))>Scene.riverWidth(z)+45 then
   local waterHit=workspace:Raycast(Vector3.new(x,180,z),Vector3.yAxis*-260,waterParams)
   local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.yAxis*-260,groundParams)
   if hit and hit.Normal.Y>.88 and (not waterHit or waterHit.Material~=Enum.Material.Water) then
    local m=template:Clone()
    m.Name="AbandonedDestroyedHouse"
    m:SetAttribute("SourceAssetId",17385388938)
    m:SetAttribute("AbandonedYears",80+i*11)
    m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    m:PivotTo(CFrame.new(hit.Position-Vector3.yAxis*.18)*CFrame.Angles(0,math.rad((i*53)%360),0))
    m.Parent=destroyedFolder
    report.destroyedHouses+=1
   end
  end
 end
 raw:Destroy()template:Destroy()
 assert(report.destroyedHouses>=4,"Too few destroyed houses placed")

 -- OLD BROKEN BRIDGES: scenic, incomplete and visibly weathered.
 local oldBridges=world.Amenities:FindFirstChild("AbandonedBrokenBridges")
 if oldBridges then oldBridges:Destroy()end
 oldBridges=Instance.new("Folder")oldBridges.Name="AbandonedBrokenBridges"oldBridges.Parent=world.Amenities
 local lakes=game:GetService("HttpService"):JSONDecode(runtime:GetAttribute("LakeLocations"))
 for index=3,math.min(#lakes,5)do
  local lake=lakes[index]local cx,cy,cz,rx,rz=lake[1],lake[2],lake[3],lake[4],lake[5]
  local m=Instance.new("Model")m.Name="AncientBrokenBridge"..index m:SetAttribute("BrokenBridge",true)m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=oldBridges
  local angle=(index-3)*.7+.25
  local forward=Vector3.new(math.cos(angle),0,math.sin(angle))
  local right=Vector3.new(-forward.Z,0,forward.X)
  local start=Vector3.new(cx,cy+1.4,cz)-forward*18
  for j=-7,7 do
   if math.abs(j)<=2 or j==5 then continue end
   local p=start+forward*(j+7)*2.6
   local plank=Instance.new("Part")plank.Name="RottenPlank"plank.Size=Vector3.new(5.3,.28,2.35)
   plank.CFrame=CFrame.lookAt(p,p+forward)*CFrame.Angles(math.rad((j%3)*2),0,math.rad((j%2)*3))
   plank.Color=Color3.fromRGB(92+(j%3)*8,70+(j%2)*7,49)
   plank.Material=Enum.Material.WoodPlanks plank.Anchored=true plank.CanCollide=true plank.CanQuery=true plank.CanTouch=false plank.Parent=m
   if j%4==0 then
    local moss=Instance.new("Part")moss.Name="Moss"moss.Size=Vector3.new(2.2,.035,1.1)
    moss.CFrame=plank.CFrame*CFrame.new(0,.16,0)
    moss.Color=Color3.fromRGB(72,101,55)moss.Material=Enum.Material.Grass moss.Anchored=true moss.CanCollide=false moss.CanQuery=false moss.CanTouch=false moss.Parent=m
   end
  end
  for _,side in ipairs({-1,1})do
   local post=Instance.new("Part")post.Name="BrokenPost"post.Size=Vector3.new(.55,3.2,.55)
   post.CFrame=CFrame.new(start+right*side*2.7+Vector3.new(0,1.3,0))*CFrame.Angles(math.rad(side*7),0,math.rad(side*4))
   post.Color=Color3.fromRGB(74,54,38)post.Material=Enum.Material.Wood post.Anchored=true post.CanCollide=true post.Parent=m
  end
  report.brokenBridges+=1
 end

 -- Re-ground and normalize every lamp made from the user's FBX.
 local lampFolder=world.Amenities.Lanterns
 for i,m in ipairs(lampFolder:GetChildren())do
  local anchor=m:GetAttribute("GroundPoint")
  if anchor then
   local hit=workspace:Raycast(anchor+Vector3.yAxis*40,Vector3.yAxis*-80,groundParams)
   if hit then
    local cf,size=m:GetBoundingBox()
    if math.abs(size.Y-8.8)>.08 then m:ScaleTo(m:GetScale()*(8.8/size.Y))end
    local tangent=Vector3.new(Scene.pathX(hit.Position.Z+6)-Scene.pathX(hit.Position.Z-6),0,12)
    if tangent.Magnitude<.1 then tangent=Vector3.zAxis end
    m:PivotTo(CFrame.lookAt(hit.Position-Vector3.yAxis*.55,hit.Position-Vector3.yAxis*.55+tangent.Unit))
    m:SetAttribute("GroundPoint",hit.Position)
    report.posts+=1
   end
  end
 end

 -- ULTRA / SHADERS: server baseline.
 pcall(function()Lighting.Technology=Enum.Technology.Future end)
 Lighting.GlobalShadows=true
 Lighting.Brightness=2.15
 Lighting.EnvironmentDiffuseScale=1
 Lighting.EnvironmentSpecularScale=1
 Lighting.ShadowSoftness=.22

 local atmosphere=Lighting:FindFirstChild("ForestAtmosphere")or Instance.new("Atmosphere")
 atmosphere.Name="ForestAtmosphere"atmosphere.Density=.22 atmosphere.Offset=.04 atmosphere.Color=Color3.fromRGB(199,218,221)atmosphere.Decay=Color3.fromRGB(92,117,129)atmosphere.Glare=.18 atmosphere.Haze=1.05 atmosphere.Parent=Lighting
 local rays=Lighting:FindFirstChild("ForestSunRays")or Instance.new("SunRaysEffect")
 rays.Name="ForestSunRays"rays.Intensity=.09 rays.Spread=.72 rays.Enabled=true rays.Parent=Lighting
 local bloom=Lighting:FindFirstChild("ForestBloom")or Instance.new("BloomEffect")
 bloom.Name="ForestBloom"bloom.Intensity=.24 bloom.Size=28 bloom.Threshold=1.35 bloom.Enabled=true bloom.Parent=Lighting
 local color=Lighting:FindFirstChild("ForestColor")or Instance.new("ColorCorrectionEffect")
 color.Name="ForestColor"color.Brightness=.015 color.Contrast=.075 color.Saturation=.085 color.TintColor=Color3.fromRGB(245,252,247)color.Enabled=true color.Parent=Lighting
 local dof=Lighting:FindFirstChild("ForestDOF")or Instance.new("DepthOfFieldEffect")
 dof.Name="ForestDOF"dof.FarIntensity=.065 dof.FocusDistance=72 dof.InFocusRadius=48 dof.NearIntensity=.015 dof.Enabled=true dof.Parent=Lighting
 runtime:SetAttribute("GraphicsPreset","Ultra")

 Terrain.WaterColor=Color3.fromRGB(50,143,177)
 Terrain.WaterTransparency=.18
 Terrain.WaterReflectance=.22
 Terrain.WaterWaveSize=.055
 Terrain.WaterWaveSpeed=6.2

 report.waterReflectance=Terrain.WaterReflectance
 report.graphicsPreset="Ultra"
 -- Final grounding pass after every other installer has finished.
 local vegetationRay=RaycastParams.new()
 vegetationRay.FilterType=Enum.RaycastFilterType.Include
 vegetationRay.FilterDescendantsInstances={Terrain}
 vegetationRay.IgnoreWater=true
 local regrounded=0
 for _,folder in ipairs({world.Decor.Trees,world.Decor.Plants})do
  local treeFolder=folder==world.Decor.Trees
  for _,m in ipairs(folder:GetChildren())do
   if m:IsA("Model")then
    local p=m:GetAttribute("ActualRootPoint")
    local depth=treeFolder and 1.15 or .35
    if p then
     local hit=workspace:Raycast(Vector3.new(p.X,210,p.Z),Vector3.yAxis*-310,vegetationRay)
     if hit then
      local targetY=hit.Position.Y-depth
      local delta=targetY-p.Y
      if math.abs(delta)>.02 then m:PivotTo(m:GetPivot()+Vector3.yAxis*delta)end
      m:SetAttribute("ActualRootPoint",Vector3.new(p.X,targetY,p.Z))
      regrounded+=1
     end
    else
     local cf,size=m:GetBoundingBox()
     local hit=workspace:Raycast(Vector3.new(cf.X,210,cf.Z),Vector3.yAxis*-310,vegetationRay)
     if hit then
      local bottom=cf.Y-size.Y*.5
      local target=hit.Position.Y-(treeFolder and .75 or .18)
      m:PivotTo(m:GetPivot()+Vector3.yAxis*(target-bottom))
      m:SetAttribute("ActualRootPoint",Vector3.new(cf.X,target,cf.Z))
      regrounded+=1
     end
    end
   end
  end
 end
 report.regroundedVegetation=regrounded
 runtime:SetAttribute("VegetationRegrounded",regrounded)

 runtime:SetAttribute("DestroyedHouseCount",report.destroyedHouses)
 runtime:SetAttribute("BrokenBridgeCount",report.brokenBridges)
 runtime:SetAttribute("NoDecorativeRocks",true)
 return report
end
return B
]============]).install()


-- =========================================================
-- TREEWORLD 99: RUIN MANSION + RIVER DETAIL
-- =========================================================
reports.mansion=factory([============[
local B={}
function B.install()
 local AS=game:GetService("AssetService")
 local Terrain=workspace.Terrain
 local world=workspace.ForestWorld
 local runtime=game.ReplicatedStorage.ForestRuntime
 local Scene=require(runtime.Scene)
 local Foliage=require(runtime.Foliage)
 local ruin=world.Amenities.ForestRuins
 local origin=ruin:GetAttribute("Origin")or ruin:GetPivot().Position
 local ruinPivot=ruin:GetPivot()
 local report={
  seats=0,portraits=0,rooms=0,decor=0,ruinFragments=0,
  submergedPlantsRemoved=0,riverStones=0,ringTrees=0,externalAssets=0
 }

 local old=world.Amenities:FindFirstChild("RuinMansion")
 if old then old:Destroy()end

 local mansion=Instance.new("Model")
 mansion.Name="RuinMansion"
 mansion.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 mansion:SetAttribute("Style","AncientRichRuin")
 mansion:SetAttribute("Reference","ForestRuins")
 mansion.Parent=world.Amenities

 local terrainRay=RaycastParams.new()
 terrainRay.FilterType=Enum.RaycastFilterType.Include
 terrainRay.FilterDescendantsInstances={Terrain}
 terrainRay.IgnoreWater=true
 local hit=workspace:Raycast(Vector3.new(origin.X,220,origin.Z),Vector3.yAxis*-360,terrainRay)
 local groundY=hit and hit.Position.Y or origin.Y
 local basis=CFrame.new(origin.X,groundY,origin.Z)*ruinPivot.Rotation

 local stoneColor=Color3.fromRGB(172,169,154)
 local stoneMaterial=Enum.Material.Slate
 local woodColor=Color3.fromRGB(74,50,35)
 for _,p in ipairs(ruin:GetDescendants())do
  if p:IsA("BasePart")and p.Transparency<.8 and p.Size.Magnitude>5 then
   stoneColor=p.Color
   stoneMaterial=p.Material
   break
  end
 end

 local function part(parent,name,size,cf,color,material,collide,transparency)
  local p=Instance.new("Part")
  p.Name=name
  p.Size=size
  p.CFrame=basis*cf
  p.Color=color or stoneColor
  p.Material=material or stoneMaterial
  p.Anchored=true
  p.CanCollide=collide~=false
  p.CanTouch=true
  p.CanQuery=true
  p.Transparency=transparency or 0
  p.CastShadow=true
  p.Parent=parent
  return p
 end

 local function cylinder(parent,name,size,cf,color,material)
  local p=part(parent,name,size,cf,color,material,true,0)
  p.Shape=Enum.PartType.Cylinder
  return p
 end

 local function seat(parent,name,size,cf,color)
  local s=Instance.new("Seat")
  s.Name=name
  s.Size=size
  s.CFrame=basis*cf
  s.Color=color or woodColor
  s.Material=Enum.Material.Wood
  s.Anchored=true
  s.CanCollide=true
  s.CanTouch=true
  s.CanQuery=true
  s.Parent=parent
  report.seats+=1
  return s
 end

 local shell=Instance.new("Folder")shell.Name="Architecture"shell.Parent=mansion
 local interior=Instance.new("Folder")interior.Name="Interior"interior.Parent=mansion
 local decor=Instance.new("Folder")decor.Name="Decor"decor.Parent=mansion
 local portraits=Instance.new("Folder")portraits.Name="Portraits"portraits.Parent=mansion
 local eventFolder=Instance.new("Folder")eventFolder.Name="BreakEvent"eventFolder.Parent=mansion

 -- Foundation/floors.
 part(shell,"Foundation",Vector3.new(72,1.4,52),CFrame.new(0,.7,0),stoneColor,Enum.Material.Cobblestone,true)
 part(shell,"GroundFloor",Vector3.new(68,.55,48),CFrame.new(0,1.5,0),Color3.fromRGB(84,68,50),Enum.Material.WoodPlanks,true)
 part(shell,"UpperFloor",Vector3.new(68,.55,48),CFrame.new(0,14.3,0),Color3.fromRGB(81,64,47),Enum.Material.WoodPlanks,true)

 -- Exterior wall helpers with window gaps.
 local wallColor=stoneColor:Lerp(Color3.fromRGB(208,203,188),.16)
 local function wall(name,size,cf)
  return part(shell,name,size,cf,wallColor,stoneMaterial,true)
 end
 -- Front wall with large broken entrance.
 wall("FrontLeft",Vector3.new(29,12.5,1.3),CFrame.new(-21.5,7.7,-24.3))
 wall("FrontRight",Vector3.new(29,12.5,1.3),CFrame.new(21.5,7.7,-24.3))
 wall("FrontUpper",Vector3.new(14,4,1.3),CFrame.new(0,12,-24.3))
 wall("BackWall",Vector3.new(72,12.5,1.3),CFrame.new(0,7.7,24.3))
 wall("LeftWall",Vector3.new(1.3,12.5,50),CFrame.new(-35.3,7.7,0))
 wall("RightWall",Vector3.new(1.3,12.5,50),CFrame.new(35.3,7.7,0))

 -- Upper floor shell.
 wall("UpperFrontLeft",Vector3.new(30,12,1.2),CFrame.new(-20.5,20.5,-24.2))
 wall("UpperFrontRight",Vector3.new(30,12,1.2),CFrame.new(20.5,20.5,-24.2))
 wall("UpperFrontCenter",Vector3.new(10,6,1.2),CFrame.new(0,23.4,-24.2))
 wall("UpperBack",Vector3.new(72,12,1.2),CFrame.new(0,20.5,24.2))
 wall("UpperLeft",Vector3.new(1.2,12,50),CFrame.new(-35.2,20.5,0))
 wall("UpperRight",Vector3.new(1.2,12,50),CFrame.new(35.2,20.5,0))

 -- Roof: dark old slate with partial damage.
 local roofColor=Color3.fromRGB(58,55,54)
 part(shell,"RoofMain",Vector3.new(73,1.2,53),CFrame.new(0,27,0)*CFrame.Angles(math.rad(-2),0,0),roofColor,Enum.Material.Slate,true)
 part(shell,"RoofBrokenSection",Vector3.new(18,.8,16),CFrame.new(21,27.5,-9)*CFrame.Angles(math.rad(7),math.rad(2),math.rad(-4)),Color3.fromRGB(48,45,43),Enum.Material.Slate,true)

 -- Front columns and old stone porch.
 for _,x in ipairs({-28,-17,17,28})do
  cylinder(shell,"FacadeColumn",Vector3.new(1.8,11,1.8),CFrame.new(x,7,-26.4)*CFrame.Angles(0,0,math.pi/2),wallColor,stoneMaterial)
  part(shell,"ColumnCap",Vector3.new(3.2,.65,3.2),CFrame.new(x,12.55,-26.4),wallColor,stoneMaterial,true)
  part(shell,"ColumnFoot",Vector3.new(3.2,.65,3.2),CFrame.new(x,1.75,-26.4),wallColor,stoneMaterial,true)
 end
 for i=0,5 do
  part(shell,"PorchStep",Vector3.new(28+i*5,.55,3.3),CFrame.new(0,.25-i*.22,-28.2-i*1.9),stoneColor,Enum.Material.Cobblestone,true)
 end

 -- Broken double door.
 local doorLeft=part(shell,"BrokenDoorLeft",Vector3.new(4.1,9,.55),CFrame.new(-2.2,6.1,-24.9)*CFrame.Angles(0,math.rad(-22),math.rad(-4)),woodColor,Enum.Material.WoodPlanks,true)
 doorLeft:SetAttribute("BrokenDoor",true)
 local doorRight=part(shell,"BrokenDoorRight",Vector3.new(4.1,9,.55),CFrame.new(3.3,3.1,-20.4)*CFrame.Angles(math.rad(82),math.rad(8),math.rad(11)),woodColor,Enum.Material.WoodPlanks,true)
 doorRight:SetAttribute("BrokenDoor",true)

 -- Tall windows, dark glass with old stone frames.
 local function window(name,cf)
  local glass=part(shell,name,Vector3.new(7.2,7.8,.18),cf,Color3.fromRGB(92,110,108),Enum.Material.Glass,false,.48)
  glass.CastShadow=false
  local frameCF=cf
  part(shell,name.."Top",Vector3.new(8,.45,.55),frameCF*CFrame.new(0,4.05,0),wallColor,stoneMaterial,true)
  part(shell,name.."Bottom",Vector3.new(8,.45,.55),frameCF*CFrame.new(0,-4.05,0),wallColor,stoneMaterial,true)
  part(shell,name.."Left",Vector3.new(.45,8.5,.55),frameCF*CFrame.new(-3.85,0,0),wallColor,stoneMaterial,true)
  part(shell,name.."Right",Vector3.new(.45,8.5,.55),frameCF*CFrame.new(3.85,0,0),wallColor,stoneMaterial,true)
 end
 for _,x in ipairs({-25,-12,12,25})do window("FrontWindow"..x,CFrame.new(x,20.5,-24.85))end
 for _,x in ipairs({-25,-8,8,25})do window("BackWindow"..x,CFrame.new(x,20.5,24.85)*CFrame.Angles(0,math.pi,0))end

 -- Interior room walls and doors.
 wall("GroundDividerLeft",Vector3.new(1,11.5,19),CFrame.new(-14,7.4,12))
 wall("GroundDividerRight",Vector3.new(1,11.5,19),CFrame.new(14,7.4,12))
 wall("UpperDividerLeft",Vector3.new(1,11.2,25),CFrame.new(-14,20.3,8))
 wall("UpperDividerRight",Vector3.new(1,11.2,25),CFrame.new(14,20.3,8))
 report.rooms=8

 -- Grand staircase with landing and railing.
 for i=0,15 do
  local y=1.85+i*.78
  local z=-4+i*1.35
  part(interior,"GrandStep",Vector3.new(14,.65,1.45),CFrame.new(0,y,z),stoneColor:Lerp(Color3.fromRGB(205,199,182),.22),stoneMaterial,true)
 end
 part(interior,"UpperLanding",Vector3.new(18,.65,8),CFrame.new(0,14.65,19),stoneColor,stoneMaterial,true)
 for _,side in ipairs({-1,1})do
  for i=0,7 do
   local y=3+i*1.45 local z=-3+i*2.55
   cylinder(interior,"StairRailPost",Vector3.new(.38,2.6,.38),CFrame.new(side*7.2,y,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(82,62,44),Enum.Material.Wood)
  end
 end

 -- Rugs.
 part(decor,"GrandRug",Vector3.new(18,.08,11),CFrame.new(0,1.86,-11),Color3.fromRGB(96,26,30),Enum.Material.Fabric,false)
 part(decor,"LibraryRug",Vector3.new(15,.08,12),CFrame.new(-23,1.86,10),Color3.fromRGB(46,62,72),Enum.Material.Fabric,false)
 part(decor,"DiningRug",Vector3.new(17,.08,13),CFrame.new(23,1.86,10),Color3.fromRGB(91,67,38),Enum.Material.Fabric,false)

 -- Dining room.
 part(interior,"DiningTable",Vector3.new(14,.8,5.2),CFrame.new(23,4,9),Color3.fromRGB(89,55,34),Enum.Material.Wood,true)
 for _,z in ipairs({6.1,11.9})do
  for _,x in ipairs({18.5,21.5,24.5,27.5})do
   seat(interior,"DiningChair",Vector3.new(2.1,.55,2.1),CFrame.new(x,2.35,z),Color3.fromRGB(92,57,35))
   part(interior,"ChairBack",Vector3.new(2.1,3.2,.35),CFrame.new(x,3.8,z+(z<9 and -.85 or .85)),Color3.fromRGB(92,57,35),Enum.Material.Wood,true)
  end
 end

 -- Lounge seating / tables.
 for _,z in ipairs({-2.5,3.5})do
  for _,x in ipairs({-25,-21,-17})do
   seat(interior,"LoungeSeat",Vector3.new(3,.6,2.4),CFrame.new(x,2.35,z),Color3.fromRGB(68,55,48))
  end
  part(interior,"SofaBack",Vector3.new(11,3.6,.55),CFrame.new(-21,4,z+1.15),Color3.fromRGB(68,55,48),Enum.Material.Fabric,true)
 end
 part(interior,"CoffeeTable",Vector3.new(7,.55,3.5),CFrame.new(-21,2.5,.5),Color3.fromRGB(83,52,34),Enum.Material.Wood,true)

 -- Piano.
 part(interior,"OldPianoBody",Vector3.new(8,4.8,2.5),CFrame.new(22,4.2,-11),Color3.fromRGB(35,29,27),Enum.Material.Wood,true)
 part(interior,"PianoKeys",Vector3.new(7.2,.15,1.2),CFrame.new(22,4.65,-12.3),Color3.fromRGB(224,220,204),Enum.Material.SmoothPlastic,false)
 seat(interior,"PianoBench",Vector3.new(3,.55,1.6),CFrame.new(22,2.3,-15),Color3.fromRGB(54,39,31))

 -- Upper floor beds/benches/side tables.
 for _,x in ipairs({-24,24})do
  part(interior,"BedFrame",Vector3.new(11,1.1,7),CFrame.new(x,15.4,8),Color3.fromRGB(79,51,34),Enum.Material.Wood,true)
  part(interior,"Mattress",Vector3.new(10.3,.8,6.3),CFrame.new(x,16.25,8),Color3.fromRGB(207,198,178),Enum.Material.Fabric,true)
  part(interior,"Pillow",Vector3.new(3,.45,1.5),CFrame.new(x,16.8,10.1),Color3.fromRGB(226,221,208),Enum.Material.Fabric,false)
  seat(interior,"BedroomBench",Vector3.new(4,.55,2),CFrame.new(x,15.4,-1),Color3.fromRGB(86,56,39))
  part(interior,"SideTable",Vector3.new(2.5,2.2,2.5),CFrame.new(x+(x<0 and 7 or -7),15.55,8),Color3.fromRGB(85,53,34),Enum.Material.Wood,true)
 end

 -- Small decorative tables/vases/candles.
 for _,o in ipairs({
  Vector3.new(-29,2.4,-14),Vector3.new(29,2.4,-14),
  Vector3.new(-29,15.5,16),Vector3.new(29,15.5,16)
 })do
  part(decor,"SideConsole",Vector3.new(5,1.8,1.6),CFrame.new(o),Color3.fromRGB(84,52,34),Enum.Material.Wood,true)
  cylinder(decor,"Vase",Vector3.new(1.1,2.3,1.1),CFrame.new(o+Vector3.new(0,1.8,0))*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(69,91,96),Enum.Material.SmoothPlastic)
  report.decor+=2
 end

 -- Portrait frames. Images are filled at runtime from players currently in the server.
 local portraitPositions={
  {-24,7.2,23.55,math.pi},{-12,7.2,23.55,math.pi},{12,7.2,23.55,math.pi},{24,7.2,23.55,math.pi},
  {-24,20.1,23.55,math.pi},{-8,20.1,23.55,math.pi},{8,20.1,23.55,math.pi},{24,20.1,23.55,math.pi},
 }
 for i,v in ipairs(portraitPositions)do
  local frame=part(portraits,"PortraitFrame"..i,Vector3.new(6.2,7.5,.45),CFrame.new(v[1],v[2],v[3])*CFrame.Angles(0,v[4],0),Color3.fromRGB(98,70,39),Enum.Material.Wood,false)
  local inner=part(portraits,"PortraitCanvas"..i,Vector3.new(5.3,6.55,.12),CFrame.new(v[1],v[2],v[3]-.28)*CFrame.Angles(0,v[4],0),Color3.fromRGB(35,35,35),Enum.Material.SmoothPlastic,false)
  inner:SetAttribute("PortraitIndex",i)
  local gui=Instance.new("SurfaceGui")gui.Name="PortraitGui"gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(420,520)gui.LightInfluence=.15 gui.Parent=inner
  local image=Instance.new("ImageLabel")image.Name="PlayerImage"image.Size=UDim2.fromScale(1,.86)image.BackgroundColor3=Color3.fromRGB(20,20,20)image.BorderSizePixel=0 image.ScaleType=Enum.ScaleType.Crop image.Parent=gui
  local label=Instance.new("TextLabel")label.Name="PlayerName"label.Position=UDim2.fromScale(0,.86)label.Size=UDim2.fromScale(1,.14)label.BackgroundColor3=Color3.fromRGB(19,17,15)label.BackgroundTransparency=.08 label.TextColor3=Color3.fromRGB(235,226,210)label.Font=Enum.Font.Garamond label.TextScaled=true label.Text="Visitante"label.Parent=gui
  report.portraits+=1
 end

 -- Reuse actual ruin geometry as facade fragments so the mansion visually belongs to the ruins.
 local candidates={}
 for _,p in ipairs(ruin:GetDescendants())do if p:IsA("BasePart")and p.Transparency<.95 then candidates[#candidates+1]=p end end
 table.sort(candidates,function(a,b)return a.Size.Magnitude>b.Size.Magnitude end)
 local fragmentFolder=Instance.new("Folder")fragmentFolder.Name="SalvagedRuinFragments"fragmentFolder.Parent=mansion
 local fragmentOffsets={
  CFrame.new(-32,4,-22)*CFrame.Angles(0,.18,.08),
  CFrame.new(32,4,-21)*CFrame.Angles(0,-.2,-.05),
  CFrame.new(-34,3,19)*CFrame.Angles(0,.3,.1),
  CFrame.new(34,3,18)*CFrame.Angles(0,-.28,-.08),
  CFrame.new(-19,15,-24)*CFrame.Angles(0,.12,.04),
  CFrame.new(19,15,-24)*CFrame.Angles(0,-.12,-.04),
 }
 for i=1,math.min(#fragmentOffsets,#candidates)do
  local clone=candidates[i]:Clone()
  for _,d in ipairs(clone:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Constraint")or d:IsA("JointInstance")then d:Destroy()end end
  clone.Name="RuinFragment"..i
  clone.Anchored=true clone.CanTouch=false clone.CanQuery=true
  clone.CFrame=basis*fragmentOffsets[i]
  clone.Parent=fragmentFolder
  report.ruinFragments+=1
 end

 -- External decor: cleaned before use. Failure falls back to the procedural interior above.
 local function loadDecor(assetId,name,targetSpan,localCF)
  local ok,raw=pcall(function()return AS:LoadAssetAsync(assetId)end)
  if not ok or not raw then return nil end
  local found=raw:FindFirstChildWhichIsA("Model",true)or raw:FindFirstChildWhichIsA("BasePart",true)
  if not found then raw:Destroy()return nil end
  local model=Instance.new("Model")model.Name=name
  if found:IsA("Model")then
   for _,child in ipairs(found:GetChildren())do child:Clone().Parent=model end
  else found:Clone().Parent=model end
  for _,d in ipairs(model:GetDescendants())do
   if d:IsA("LuaSourceContainer")or d:IsA("Sound")or d:IsA("Fire")or d:IsA("Smoke")or d:IsA("ParticleEmitter")then d:Destroy()
   elseif d:IsA("BasePart")then d.Anchored=true d.CanTouch=false d.CanQuery=true if d:IsA("MeshPart")then d.RenderFidelity=Enum.RenderFidelity.Performance end end
  end
  model.Parent=decor
  local cf,size=model:GetBoundingBox()
  local scale=targetSpan/math.max(size.X,size.Y,size.Z)
  if scale==scale and scale>0 then model:ScaleTo(model:GetScale()*math.clamp(scale,.15,4))end
  model:PivotTo(basis*localCF)
  cf,size=model:GetBoundingBox()
  local targetY=(basis*localCF).Position.Y
  local bottom=cf.Y-size.Y*.5
  model:PivotTo(model:GetPivot()+Vector3.yAxis*(targetY-bottom))
  model:SetAttribute("SourceAssetId",assetId)
  raw:Destroy()
  report.externalAssets+=1
  return model
 end
 loadDecor(98956442023011,"AntiqueBookshelf",8,CFrame.new(-30,1.8,12))
 loadDecor(98956442023011,"AntiqueBookshelf2",8,CFrame.new(-30,1.8,4))
 loadDecor(6204470031,"StoneFireplace",10,CFrame.new(-1,1.8,23))
 local chandelier=loadDecor(4646397018,"GrandChandelier",8,CFrame.new(0,20.8,-7))
 if chandelier then
  for _,p in ipairs(chandelier:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=false end end
 end

 -- Safe visual break event: an old ceiling beam drops when a player approaches, never damages players.
 local beam=part(eventFolder,"FallingBeam",Vector3.new(12,.8,.8),CFrame.new(12,11,-7)*CFrame.Angles(0,0,math.rad(4)),Color3.fromRGB(72,50,34),Enum.Material.Wood,true)
 beam:SetAttribute("BreakAnimation",true)
 beam:SetAttribute("RestCF",beam.CFrame)
 local dust=Instance.new("ParticleEmitter")
 dust.Name="Dust"
 dust.Texture="rbxasset://textures/particles/smoke_main.dds"
 dust.Rate=0 dust.Lifetime=NumberRange.new(.45,.8)dust.Speed=NumberRange.new(1.5,3.2)
 dust.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,1.5)})
 dust.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(1,1)})
 dust.Color=ColorSequence.new(Color3.fromRGB(164,151,132))dust.Parent=beam
 local trigger=part(eventFolder,"BreakTrigger",Vector3.new(16,8,16),CFrame.new(12,5,-7),Color3.new(1,1,1),Enum.Material.SmoothPlastic,false,1)
 trigger.CanQuery=false trigger.CanTouch=false

 -- Extra seasonal forest volume around the ruin/mansion.
 local templates=runtime.NativeTreeTemplates:GetChildren()
 local contacts=runtime:FindFirstChild("ActualRootContacts")
 local rng=Random.new(99031)
 for i=1,42 do
  local angle=(i/42)*math.pi*2+rng:NextNumber(-.09,.09)
  local radius=62+(i%4)*13+rng:NextNumber(-5,5)
  local x=origin.X+math.cos(angle)*radius
  local z=origin.Z+math.sin(angle)*radius
  if Scene.pathDistance(x,z)>11 and math.abs(x-Scene.riverX(z))>Scene.riverWidth(z)+7 then
   local t=templates[(i-1)%#templates+1]
   local pine=t:GetAttribute("SourceAssetId")==6432306802
   local tree=Foliage.place(t,world.Decor.Trees,x,z,rng:NextNumber(pine and 30 or 20,pine and 57 or 47),angle+.4)
   if tree then
    report.ringTrees+=1
    if contacts then local ref=Instance.new("ObjectValue")ref.Name="RuinRingTree"ref.Value=tree ref.Parent=contacts end
   end
  end
 end

 -- Remove plants whose root is actually inside water. Keep stones in water.
 local waterRay=RaycastParams.new()
 waterRay.FilterType=Enum.RaycastFilterType.Include
 waterRay.FilterDescendantsInstances={Terrain}
 waterRay.IgnoreWater=false
 for _,m in ipairs(world.Decor.Plants:GetChildren())do
  if m:IsA("Model")then
   local p=m:GetAttribute("ActualRootPoint")or m:GetPivot().Position
   local wh=workspace:Raycast(Vector3.new(p.X,180,p.Z),Vector3.yAxis*-300,waterRay)
   if wh and wh.Material==Enum.Material.Water and p.Y<=wh.Position.Y+2.2 then
    m:Destroy()report.submergedPlantsRemoved+=1
   end
  end
 end

 -- Natural river stones only in water.
 local oldRiverStones=world.Decor:FindFirstChild("RiverStones")
 if oldRiverStones then oldRiverStones:Destroy()end
 local riverStones=Instance.new("Folder")riverStones.Name="RiverStones"riverStones.Parent=world.Decor
 local stoneRng=Random.new(99113)
 for z=-270,270,18 do
  local width=Scene.riverWidth(z)
  local x=Scene.riverX(z)+stoneRng:NextNumber(-width*.62,width*.62)
  local wh=workspace:Raycast(Vector3.new(x,170,z),Vector3.yAxis*-280,waterRay)
  if wh and wh.Material==Enum.Material.Water then
   local p=Instance.new("Part")
   p.Name="RiverStone"
   p.Shape=Enum.PartType.Ball
   p.Size=Vector3.new(stoneRng:NextNumber(2.8,6.5),stoneRng:NextNumber(1.2,2.5),stoneRng:NextNumber(2.8,6.2))
   p.CFrame=CFrame.new(wh.Position+Vector3.new(0,-p.Size.Y*.25,0))*CFrame.Angles(stoneRng:NextNumber(-.18,.18),stoneRng:NextNumber(0,6.28),stoneRng:NextNumber(-.12,.12))
   p.Color=Color3.fromRGB(stoneRng:NextInteger(92,122),stoneRng:NextInteger(101,126),stoneRng:NextInteger(105,132))
   p.Material=Enum.Material.Slate
   p.Anchored=true p.CanCollide=true p.CanTouch=true p.CanQuery=true p.CastShadow=true p.Parent=riverStones
   report.riverStones+=1
  end
 end

 Terrain.WaterColor=Color3.fromRGB(55,150,181)
 Terrain.WaterTransparency=.16
 Terrain.WaterReflectance=.24
 Terrain.WaterWaveSize=.052
 Terrain.WaterWaveSpeed=6.4

 mansion:SetAttribute("RoomCount",report.rooms)
 mansion:SetAttribute("SeatCount",report.seats)
 mansion:SetAttribute("PortraitCount",report.portraits)
 mansion:SetAttribute("RiverStoneCount",report.riverStones)
 mansion:SetAttribute("RuinTreeRingCount",report.ringTrees)
 mansion:SetAttribute("SubmergedPlantsRemoved",report.submergedPlantsRemoved)
 world:SetAttribute("RuinMansionAdded",true)
 runtime:SetAttribute("RuinMansionVersion",99)
 runtime:SetAttribute("RiverStoneCount",report.riverStones)
 runtime:SetAttribute("SubmergedPlantsRemoved",report.submergedPlantsRemoved)
 runtime:SetAttribute("RuinTreeRingCount",report.ringTrees)
 return report
end
return B
]============]).install()

source(game.ServerScriptService,"Script","RuinMansionController",[============[
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local world=workspace:WaitForChild("ForestWorld")
local mansion=world.Amenities:WaitForChild("RuinMansion")
local portraits=mansion:WaitForChild("Portraits")
local event=mansion:WaitForChild("BreakEvent")
local beam=event:WaitForChild("FallingBeam")
local trigger=event:WaitForChild("BreakTrigger")
local dust=beam:FindFirstChild("Dust")
local home=beam:GetAttribute("RestCF")or beam.CFrame

local function portraitFrames()
 local list={}
 for _,p in ipairs(portraits:GetChildren())do
  if p:IsA("BasePart")and p:GetAttribute("PortraitIndex")then list[#list+1]=p end
 end
 table.sort(list,function(a,b)return a:GetAttribute("PortraitIndex")<b:GetAttribute("PortraitIndex")end)
 return list
end

local function refreshPortraits()
 local players=Players:GetPlayers()
 for i,canvas in ipairs(portraitFrames())do
  local gui=canvas:FindFirstChild("PortraitGui")
  local image=gui and gui:FindFirstChild("PlayerImage")
  local name=gui and gui:FindFirstChild("PlayerName")
  if #players>0 then
   local p=players[(i-1)%#players+1]
   if image then image.Image="rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=420&h=420"end
   if name then name.Text=p.DisplayName end
  else
   if image then image.Image=""end
   if name then name.Text="Visitante"end
  end
 end
end
Players.PlayerAdded:Connect(function()task.defer(refreshPortraits)end)
Players.PlayerRemoving:Connect(function()task.defer(refreshPortraits)end)
refreshPortraits()

local broken=false
local cooldown=false
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.25 or broken or cooldown then return end elapsed=0
 for _,p in ipairs(Players:GetPlayers())do
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root and (root.Position-trigger.Position).Magnitude<11 then
   broken=true cooldown=true
   if dust then dust:Emit(18)end
   local fall=home*CFrame.new(0,-3.2,1.4)*CFrame.Angles(math.rad(18),0,math.rad(27))
   TweenService:Create(beam,TweenInfo.new(.7,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=fall}):Play()
   task.delay(18,function()
    TweenService:Create(beam,TweenInfo.new(1.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=home}):Play()
    task.wait(1.7)broken=false
    task.delay(35,function()cooldown=false end)
   end)
   break
  end
 end
end)
]============])

-- Replace weather with a predictable, lightweight rain system.
source(runtime,"ModuleScript","GardenWeather",[============[
local M={}
function M.start(runtime,world)
 if runtime:GetAttribute("WeatherLoopStarted")then return{setRain=function(v)runtime:SetAttribute("Raining",v)end}end
 runtime:SetAttribute("WeatherLoopStarted",true)
 local terrain=workspace.Terrain
 local clouds=terrain:FindFirstChildOfClass("Clouds")or Instance.new("Clouds")
 clouds.Name="ForestClouds"clouds.Cover=.28 clouds.Density=.34 clouds.Color=Color3.fromRGB(230,235,236)clouds.Parent=terrain
 local function setRain(on)
  runtime:SetAttribute("Raining",on)
  runtime:SetAttribute("WeatherName",on and"Chuva"or"Claro")
  clouds.Cover=on and .82 or .28
  clouds.Density=on and .72 or .34
  clouds.Color=on and Color3.fromRGB(165,177,183)or Color3.fromRGB(230,235,236)
 end
 setRain(false)
 task.spawn(function()
  local rng=Random.new()
  while runtime.Parent do
   task.wait(rng:NextInteger(210,390))
   if not runtime:GetAttribute("SeasonTestMode")then
    setRain(true)
    task.wait(rng:NextInteger(90,180))
    setRain(false)
   end
  end
 end)
 return{setRain=setRain}
end
return M
]============])

-- Replace visual controller so day/night continues with Ultra lighting.
source(runtime,"ModuleScript","Visuals",[============[
local M={}
local Lighting=game:GetService("Lighting")
function M.apply()
 pcall(function()Lighting.Technology=Enum.Technology.Future end)
 Lighting.GlobalShadows=true
 Lighting.Brightness=2.15
 Lighting.EnvironmentDiffuseScale=1
 Lighting.EnvironmentSpecularScale=1
 Lighting.ShadowSoftness=.22
end
function M.clock(clock)
 Lighting.ClockTime=clock
 local sun=math.clamp(math.sin((clock-6)/12*math.pi),0,1)
 Lighting.Brightness=.55+sun*1.75
 Lighting.OutdoorAmbient=Color3.fromRGB(92+math.floor(sun*48),101+math.floor(sun*46),112+math.floor(sun*42))
end
return M
]============])

-- Camera + Ultra controls, fixed at the top-right.
source(game.StarterPlayer.StarterPlayerScripts,"LocalScript","TreeWorldViewControls",[============[
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")

local old=pg:FindFirstChild("TreeWorldViewControls")
if old then old:Destroy()end
local gui=Instance.new("ScreenGui")gui.Name="TreeWorldViewControls"gui.ResetOnSpawn=false gui.IgnoreGuiInset=false gui.DisplayOrder=80 gui.Parent=pg

local function button(name,text,y)
 local b=Instance.new("TextButton")b.Name=name b.AnchorPoint=Vector2.new(1,0)b.Position=UDim2.new(1,-12,0,y)b.Size=UDim2.fromOffset(74,36)
 b.BackgroundColor3=Color3.fromRGB(10,10,12)b.BackgroundTransparency=.24 b.TextColor3=Color3.fromRGB(245,245,245)b.Text=text b.TextSize=13 b.Font=Enum.Font.GothamBold b.AutoButtonColor=true b.Parent=gui
 local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,10)c.Parent=b
 local s=Instance.new("UIStroke")s.Color=Color3.fromRGB(220,220,220)s.Transparency=.35 s.Thickness=1 s.Parent=b
 return b
end
local cameraButton=button("Camera","3P",10)
local ultraButton=button("Ultra","ULTRA",52)
local mode="3P"local ultra=true

local function applyCamera()
 if mode=="1P"then
  player.CameraMode=Enum.CameraMode.LockFirstPerson
  player.CameraMinZoomDistance=.5 player.CameraMaxZoomDistance=.5
 else
  player.CameraMode=Enum.CameraMode.Classic
  player.CameraMinZoomDistance=9 player.CameraMaxZoomDistance=9
  local ch=player.Character local h=ch and ch:FindFirstChildOfClass("Humanoid")
  if h and workspace.CurrentCamera then workspace.CurrentCamera.CameraType=Enum.CameraType.Custom workspace.CurrentCamera.CameraSubject=h end
 end
 cameraButton.Text=mode
end
cameraButton.MouseButton1Click:Connect(function()mode=mode=="3P"and"1P"or"3P"applyCamera()end)

local function setUltra(on)
 ultra=on ultraButton.Text=on and"ULTRA"or"ALTO"
 for _,name in ipairs({"ForestSunRays","ForestBloom","ForestColor","ForestDOF"})do
  local e=Lighting:FindFirstChild(name)if e and e:IsA("PostEffect")then e.Enabled=on end
 end
 local atmosphere=Lighting:FindFirstChild("ForestAtmosphere")
 if atmosphere then atmosphere.Density=on and .22 or .16 atmosphere.Haze=on and 1.05 or .55 end
 pcall(function()workspace.Terrain.Decoration=on end)
end
ultraButton.MouseButton1Click:Connect(function()setUltra(not ultra)end)

local function updateVisible()
 local menuOpen=player:GetAttribute("TreeWorldMenuOpen")==true
 local menu=pg:FindFirstChild("TreeWorldMenu")
 if menu then
  local bg=menu:FindFirstChild("Background")local main=menu:FindFirstChild("MainMenu")
  menuOpen=menuOpen or(bg and bg.Visible)or(main and main.Visible)
 end
 gui.Enabled=not menuOpen
end
player:GetAttributeChangedSignal("TreeWorldMenuOpen"):Connect(updateVisible)
player.CharacterAdded:Connect(function()task.wait(.2)applyCamera()updateVisible()end)
task.spawn(function()while gui.Parent do updateVisible()task.wait(.25)end end)
applyCamera()setUltra(true)updateVisible()
]============])

workspace.ForestWorld:SetAttribute("UpgradeVersion",99)
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
runtime:SetAttribute("StreamingPrefetchEnabled",true)
runtime:SetAttribute("StreamingPrefetchDistance",640)
local function startStreamingPrefetch(player)
 task.spawn(function()
  while player.Parent do
   local model=player.Character local root=model and model:FindFirstChild("HumanoidRootPart")
   if root then
    local velocity=root.AssemblyLinearVelocity
    local forward=velocity.Magnitude>3 and velocity.Unit or root.CFrame.LookVector
    local right=root.CFrame.RightVector
    local points={
     root.Position,
     root.Position+forward*640,
     root.Position+right*360,
     root.Position-right*360,
    }
    for _,point in ipairs(points)do
     pcall(function()player:RequestStreamAroundAsync(point,1.25)end)
     task.wait(.03)
    end
   end
   task.wait(2.5)
  end
 end)
end
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
Players.PlayerAdded:Connect(function(player)playerAdded(player)startStreamingPrefetch(player)end)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player)startStreamingPrefetch(player)end
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
 local seasonIndex=runtime:GetAttribute("SeasonIndex")or 1
 local leafInterval=seasonIndex==1 and .62 or seasonIndex==2 and .78 or seasonIndex==3 and .22 or math.huge
 if spawnClock>leafInterval and h and h:GetState()~=Enum.HumanoidStateType.Swimming and #nearby>0 and seasonIndex~=4 then
  spawnClock=0 leafIndex=leafIndex%cap+1 local e=leaves[leafIndex]local p=nearby[rng:NextInteger(1,#nearby)]
  local focus=root and root.Position or pos
  local x=math.clamp(p.X,focus.X-10,focus.X+10)+rng:NextNumber(-3,3)local z=math.clamp(p.Z,focus.Z-10,focus.Z+10)+rng:NextNumber(-3,3)
  e.start=Vector3.new(x,focus.Y+rng:NextNumber(6,9),z)e.birth=now e.phase=rng:NextNumber(0,6.28)e.life=seasonIndex==3 and 7 or 6
  if seasonIndex==1 then e.part.Color=Color3.fromRGB(132,164,91)
  elseif seasonIndex==2 then e.part.Color=Color3.fromRGB(88,132,68)
  else e.part.Color=Color3.fromRGB(rng:NextInteger(168,213),rng:NextInteger(91,145),rng:NextInteger(45,72))end
  e.part.Transparency=.12
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
reports.tests=run([============[
local world=workspace.ForestWorld
local runtime=game.ReplicatedStorage.ForestRuntime
local Lighting=game:GetService("Lighting")
local Terrain=workspace.Terrain
assert(world:GetAttribute("UpgradeVersion")==99)
assert(runtime:GetAttribute("NoDecorativeRocks")==true)
assert(runtime:GetAttribute("RiversideCottageRemoved")==true)
assert(runtime:GetAttribute("AnimationMode")=="RobloxDefault")
assert(runtime:GetAttribute("GraphicsPreset")=="Ultra")
assert(runtime:GetAttribute("StreamingMinRadiusStuds")==320)
assert(runtime:GetAttribute("StreamingTargetRadiusStuds")==896)
assert(runtime:GetAttribute("StreamingPrefetchDistance")==640)
assert(require(runtime.Seasons).Duration==1200)

local garden=world.Amenities.RiversideGarden
assert(not garden:FindFirstChild("WaterCottage"),"River cottage still exists")
assert(not garden:FindFirstChild("LakesideBoardwalk"),"Cottage boardwalk still exists")
assert(not garden:FindFirstChild("StreamSteppingStones"),"Stepping stones still exist")
assert(#world.Decor.RocksAndLogs:GetChildren()==0,"Decorative rocks/logs remain")
assert(#world.Amenities.CutTrunks:GetChildren()==0,"Cut trunks remain")

local houses=world.Amenities:FindFirstChild("DestroyedHouses")
assert(houses and #houses:GetChildren()>=4,"Destroyed houses missing")
for _,m in ipairs(houses:GetChildren())do
 assert(m:GetAttribute("SourceAssetId")==17385388938)
 local cf,size=m:GetBoundingBox()
 assert(size.Y>3 and size.X>3 and size.Z>3,"Destroyed house malformed")
end

local broken=world.Amenities:FindFirstChild("AbandonedBrokenBridges")
assert(broken and #broken:GetChildren()>=3,"Broken bridges missing")

local lamps=world.Amenities.Lanterns:GetChildren()
assert(#lamps>=12,"Too few lamp posts")
for _,m in ipairs(lamps)do
 assert(m:GetAttribute("SourceAssetId")==97893326625257)
 local cf,size=m:GetBoundingBox()
 assert(math.abs(size.Y-8.8)<.12,"Lamp height incorrect")
 local gp=m:GetAttribute("GroundPoint")assert(gp)
end

assert(Lighting:FindFirstChild("ForestSunRays")and Lighting.ForestSunRays.Enabled)
assert(Lighting:FindFirstChild("ForestBloom")and Lighting.ForestBloom.Enabled)
assert(Lighting:FindFirstChild("ForestColor")and Lighting.ForestColor.Enabled)
assert(Lighting:FindFirstChild("ForestDOF")and Lighting.ForestDOF.Enabled)
assert(Lighting:FindFirstChild("ForestAtmosphere"))
assert(Terrain.WaterReflectance>=.20 and Terrain.WaterTransparency<=.20)

assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("TreeWorldViewControls"))
for _,container in ipairs({game.StarterPlayer.StarterPlayerScripts,game.StarterPlayer.StarterCharacterScripts})do
 for _,s in ipairs(container:GetChildren())do
  local n=s.Name:lower()
  assert(not(n:find("nextbot",1,true)or n:find("evade",1,true)),"Old movement/animation controller remains: "..s.Name)
 end
end

assert((runtime:GetAttribute("NativeTreeVarietyCount")or 0)>=10)
assert(runtime:GetAttribute("ForestLiveChunkLimit")==36)
assert(runtime:GetAttribute("ForestChunkRadius")==4)
local contacts=runtime:FindFirstChild("ActualRootContacts")
assert(contacts and #contacts:GetChildren()>200,"Tree/root grounding probes missing")
for _,entry in ipairs(contacts:GetChildren())do
 local m=entry.Value
 if m and m.Parent then
  local p=m:GetAttribute("ActualRootPoint")
  if p then
   local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={Terrain}ray.IgnoreWater=true
   local hit=workspace:Raycast(Vector3.new(p.X,210,p.Z),Vector3.yAxis*-310,ray)
   assert(hit and p.Y<hit.Position.Y-.25,"Floating tree/plant remains: "..m.Name)
  end
 end
end


local mansion=assert(world.Amenities:FindFirstChild("RuinMansion"),"Ruin mansion missing")
assert(mansion.ModelStreamingMode==Enum.ModelStreamingMode.Atomic)
assert((mansion:GetAttribute("RoomCount")or 0)>=8)
assert((mansion:GetAttribute("SeatCount")or 0)>=10)
assert((mansion:GetAttribute("PortraitCount")or 0)>=8)
assert(mansion:FindFirstChild("BrokenDoorLeft",true)and mansion:FindFirstChild("BrokenDoorRight",true),"Broken entrance missing")
assert(mansion:FindFirstChild("GrandStep",true),"Grand staircase missing")
assert(mansion:FindFirstChild("FallingBeam",true),"Mansion break animation missing")
assert(game.ServerScriptService:FindFirstChild("RuinMansionController"),"Mansion runtime controller missing")
local riverStones=assert(world.Decor:FindFirstChild("RiverStones"),"River stones missing")
assert(#riverStones:GetChildren()>=20,"Too few water stones")
assert((runtime:GetAttribute("RuinTreeRingCount")or 0)>=20,"Ruin forest ring too sparse")
assert((runtime:GetAttribute("StreamingTargetRadiusStuds")or 0)==896)

local weather=require(runtime.GardenWeather).start(runtime,world)
weather.setRain(true)assert(runtime:GetAttribute("Raining")==true)
weather.setRain(false)assert(runtime:GetAttribute("Raining")==false)

local clicks=game:GetService("CollectionService"):GetTagged("TreeWorldCupClick")
local live=0 for _,c in ipairs(clicks)do if c:IsDescendantOf(world)then live+=1 end end
assert(live>=12,"Utah tea sets were lost")

return{
 ok=true,
 destroyedHouses=#houses:GetChildren(),
 brokenBridges=#broken:GetChildren(),
 lampPosts=#lamps,
 seasonSeconds=require(runtime.Seasons).Duration,
 waterReflectance=Terrain.WaterReflectance,
 streamingTarget=runtime:GetAttribute("StreamingTargetRadiusStuds"),
 graphics=runtime:GetAttribute("GraphicsPreset"),
 treeVarieties=runtime:GetAttribute("NativeTreeVarietyCount"),
 mansionRooms=mansion:GetAttribute("RoomCount"),
 mansionSeats=mansion:GetAttribute("SeatCount"),
 portraits=mansion:GetAttribute("PortraitCount"),
 riverStones=#riverStones:GetChildren(),
 ruinTrees=runtime:GetAttribute("RuinTreeRingCount"),
 noLandDecorativeRocks=true,
 noRiverHouse=true
}
]============])
runtime:SetAttribute("GardenTestMode",nil)runtime:SetAttribute("SeasonTestMode",nil)runtime:SetAttribute("ForestTestMode",nil)
game:GetService("AssetService"):SavePlaceAsync()
return{published=true,expectedVersion=99,baseVersion=98,reports=reports}
