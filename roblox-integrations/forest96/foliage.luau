local M={}
local Collection=game:GetService("CollectionService")
local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
function M.place(template,parent,x,z,height,yaw)
 local g=ground(x,z)if not g or g.Position.Y<7.4 or g.Normal.Y<.72 then return end
 local m=template:Clone()local scale=height/template:GetAttribute("TemplateHeight")m:ScaleTo(template:GetScale()*scale)
 local rotation=CFrame.Angles(0,yaw,0)local y=g.Position.Y-1.15
 local points=template:GetAttribute("RootProfile")local values=game:GetService("HttpService"):JSONDecode(points)
 for _,p in ipairs(values)do local off=rotation:VectorToWorldSpace(Vector3.new(unpack(p))*scale)local hit=ground(x+off.X,z+off.Z)if not hit or hit.Position.Y<7 then m:Destroy()return end y=math.min(y,hit.Position.Y-off.Y-1.15)end
 m:PivotTo(CFrame.new(x,y,z)*rotation)m:SetAttribute("ActualRootPoint",Vector3.new(x,y,z))m:SetAttribute("FreshReferenceTree",true)m:SetAttribute("RootEmbedDepth",1.15)
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
