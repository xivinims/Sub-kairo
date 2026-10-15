local B={}
function B.install()
 local runtime=game.ReplicatedStorage.ForestRuntime
 if runtime:FindFirstChild("CuteAnimalTemplates")then runtime.CuteAnimalTemplates:Destroy()end
 if workspace.ForestWorld.Amenities:FindFirstChild("CuteAnimalRoutes")then workspace.ForestWorld.Amenities.CuteAnimalRoutes:Destroy()end
 local raw=game:GetService("AssetService"):LoadAssetAsync(77173958514594)
 local templates=Instance.new("Folder")templates.Name="CuteAnimalTemplates"templates.Parent=game.ReplicatedStorage.ForestRuntime
 local routes=Instance.new("Folder")routes.Name="CuteAnimalRoutes"routes.Parent=workspace.ForestWorld.Amenities
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
 local function floor(x,z)local h=workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-300,0),rp)return h and h.Position.Y>8 and h.Normal.Y>.78 and h.Position or nil end
 for _,name in ipairs({"Conejo","Zorro"})do
  local m=assert(raw:FindFirstChild(name)):Clone()
  for _,d in ipairs(m:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Sound")or d:IsA("JointInstance")or d:IsA("Constraint")or d:IsA("Humanoid")or d:IsA("RemoteEvent")then d:Destroy()end end
  m:PivotTo(CFrame.identity)
  local delta=m.Head.Position-m.Torso.Position local forward=Vector3.new(delta.X,0,delta.Z)
  if forward.Magnitude>.1 then local rot=CFrame.lookAt(Vector3.zero,forward).Rotation:Inverse()for _,part in ipairs(m:GetDescendants())do if part:IsA("BasePart")then part.CFrame=rot*part.CFrame end end end
  local bottom=math.huge
  for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false bottom=math.min(bottom,p.Position.Y-(math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)*.5)end end
  m:PivotTo(m:GetPivot()-Vector3.yAxis*bottom)m.PrimaryPart=nil m.WorldPivot=CFrame.identity m:SetAttribute("SourceAssetId",77173958514594)m.Parent=templates
 end
 raw:Destroy()
 local count=0 local centers={{-145,-120},{-115,170},{105,-80},{110,0},{-230,90},{-120,-210}}
 local collision=RaycastParams.new()collision.FilterType=Enum.RaycastFilterType.Include collision.FilterDescendantsInstances={workspace.Terrain,workspace.ForestWorld.Decor,workspace.ForestWorld.Amenities}collision.RespectCanCollide=true collision.IgnoreWater=true
 for i,center in ipairs(centers)do
  local points={}
  for attempt=0,24 do
   points={}local shift=attempt*2.4 local cx=center[1]+math.cos(attempt*2.4)*shift local cz=center[2]+math.sin(attempt*2.4)*shift
   for j=0,31 do local a=j*math.pi*2/32 local p=floor(cx+math.cos(a)*9,cz+math.sin(a)*7)
    if not p then points={}break end points[#points+1]={p.X,p.Y+.03,p.Z}
   end
   if #points==32 then
    for j=1,32 do local a=Vector3.new(unpack(points[j]))local b=Vector3.new(unpack(points[j%32+1]))
     for _,height in ipairs({.6,1.2})do if workspace:Raycast(a+Vector3.yAxis*height,b-a,collision)then points={}break end end
     if #points==0 then break end
    end
   end
   if #points==32 then break end
  end
  if #points==32 then local r=Instance.new("StringValue")r.Name="AnimalRoute"r.Value=game:GetService("HttpService"):JSONEncode(points)r:SetAttribute("Species",i%2==0 and "Zorro"or"Conejo")r:SetAttribute("Speed",i%2==0 and 1.8 or 1.1)r:SetAttribute("Phase",i*7)r.Parent=routes count+=1 end
 end
 assert(count>=4,"Insufficient dry animal routes")return{animals=count,sourceAssetId=77173958514594}
end
return B
