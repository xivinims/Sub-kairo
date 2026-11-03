local Builder={}
function Builder.install()
 local world=workspace.ForestWorld local Collection=game:GetService("CollectionService")local folder=world.Amenities.WoodenBridges
 local endpoints={}for _,m in ipairs(folder:GetChildren())do endpoints[#endpoints+1]={a=m:GetAttribute("DeckStart"),b=m:GetAttribute("DeckEnd")}end
 local raw=game:GetService("AssetService"):LoadAssetAsync(117077041338395)local template=assert(raw:FindFirstChildOfClass("Model"))
 for _,d in ipairs(template:GetDescendants())do if d:IsA("LuaSourceContainer")then d:Destroy()end end
 template:PivotTo(CFrame.identity)
 local function bounds(model)
  local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
  for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5)lo=lo:Min(v)hi=hi:Max(v)end end end end end return lo,hi
 end
 local lo,hi=bounds(template)local sourceLength=hi.X-lo.X
 local mid=Vector3.new((lo.X+hi.X)*.5,0,(lo.Z+hi.Z)*.5)template:PivotTo(template:GetPivot()-mid)template.PrimaryPart=nil template.WorldPivot=CFrame.identity
 local params=RaycastParams.new()params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={workspace.Terrain}params.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),params)end
 for _,m in ipairs(folder:GetChildren())do m:Destroy()end
 local report={bridges=0,segments=0}
 for index,item in ipairs(endpoints)do
  local a,b=item.a,item.b
  local bankA,bankB=assert(ground(a.X,a.Z)),assert(ground(b.X,b.Z))
  a=Vector3.new(a.X,bankA.Position.Y+.10,a.Z)b=Vector3.new(b.X,bankB.Position.Y+.10,b.Z)
  local span=(Vector3.new(b.X-a.X,0,b.Z-a.Z)).Magnitude
  local model=Instance.new("Model")model.Name="ArchedWoodenBridge"..index model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model:SetAttribute("SourceAssetId",117077041338395)model.Parent=folder
  local visual=template:Clone()visual.Name="NativeBridge"visual:ScaleTo((b-a).Magnitude/(sourceLength-4.0))visual.Parent=model
  for _,p in ipairs(visual:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=false p.CanQuery=true p.CanTouch=false end end
  local scale=visual:GetScale()local edgeX=span*.5 local localRay=RaycastParams.new()localRay.FilterType=Enum.RaycastFilterType.Include localRay.FilterDescendantsInstances={visual}
  local sourceHit=assert(workspace:Raycast(Vector3.new(-edgeX+1,100,0),Vector3.new(0,-200,0),localRay),"Native bridge deck endpoint missing")
  local forward=(b-a).Unit local up=(Vector3.yAxis-forward*forward.Y).Unit
  local basis=CFrame.fromMatrix((a+b)*.5,forward,up)
  visual:PivotTo(basis*CFrame.new(0,-sourceHit.Position.Y+.10,0))task.wait()
  local nodes={}local count=64
  for i=0,count do
   local t=i/count local point=a:Lerp(b,t)
   local h=workspace:Raycast(point+Vector3.new(0,60,0),Vector3.new(0,-120,0),localRay)
   if not h then
    for _,offset in ipairs({-.25,.25,-.5,.5,-.9,.9})do
     h=workspace:Raycast(point+forward*offset+Vector3.new(0,60,0),Vector3.new(0,-120,0),localRay)if h then break end
    end
   end
   assert(h,"Native bridge has no plank at "..i)nodes[#nodes+1]=Vector3.new(point.X,h.Position.Y+.015,point.Z)
  end
  local width=math.clamp((hi.Z-lo.Z)*scale*.78,7,14)
  for i=1,#nodes-1 do local p,q=nodes[i],nodes[i+1]local cf=CFrame.lookAt((p+q)*.5,q)
   local collision=Instance.new("Part")collision.Name="WalkwayCollision"collision.Size=Vector3.new(width,.22,(q-p).Magnitude+.10)collision.CFrame=cf*CFrame.new(0,-.11,0)collision.Transparency=1 collision.Anchored=true collision.CanCollide=true collision.CanQuery=true collision.CanTouch=false collision.Parent=model report.segments+=1
  end
  for _,t in ipairs({.02,.28,.72,.98})do local point=nodes[math.floor(t*count)+1]
   for _,side in ipairs({-1,1})do
    local p=point+Vector3.new(0,0,side*(width*.5+.25))local bed=assert(ground(p.X,p.Z))local height=math.max(.5,p.Y-.35-bed.Position.Y+.3)
    local support=Instance.new("Part")support.Name="MasonrySupport"support.Size=Vector3.new(1.15,height,1.15)support.CFrame=CFrame.new(p.X,p.Y-.35-height*.5,p.Z)support.Material=Enum.Material.Slate support.Color=Color3.fromRGB(112,111,93)support.Anchored=true support.CanCollide=true support.CanTouch=false support:SetAttribute("GroundPoint",bed.Position)support.Parent=model
   end
  end
  model:SetAttribute("DeckStart",nodes[1])model:SetAttribute("DeckEnd",nodes[#nodes])model:SetAttribute("DeckWidth",width)
  local json={}for _,p in ipairs(nodes)do json[#json+1]={p.X,p.Y,p.Z}end model:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(json))
  report.bridges+=1
 end
 raw:Destroy()return report
end
return Builder
