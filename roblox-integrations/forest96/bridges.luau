local B={}
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
