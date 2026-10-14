local B={}
local WOOD=Color3.fromRGB(141,111,78)local DARK=Color3.fromRGB(85,72,54)
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)
 local folder=world.Amenities.WoodenBridges folder:ClearAllChildren()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.new(0,-310,0),ray)).Position end
 local report={bridges=0,planks=0}
 local function p(parent,name,size,cf,color,collide)
  local v=Instance.new("Part")v.Name=name v.Size=size v.CFrame=cf v.Anchored=true v.Color=color or WOOD v.Material=Enum.Material.Wood v.CanCollide=collide~=false v.CanQuery=true v.CanTouch=false v.Parent=parent return v
 end
 for index,zc in ipairs({-108,176})do
  local cx=Scene.riverX(zc)local xa,xb=cx-10,cx+10
  while ground(xa,zc).Y<8.8 do xa-=2 end while ground(xb,zc).Y<8.8 do xb+=2 end
  xa-=2 xb+=2 local a,b=ground(xa,zc),ground(xb,zc)
  local m=Instance.new("Model")m.Name="WoodlandBridge"..index m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=folder
  m:SetAttribute("ReferenceStyle","Arched timber bridge, solid planks, carved posts and braces")
  local N=math.ceil((b-a).Magnitude/1.3)local W=8 local nodes={}
  local function point(t)return a:Lerp(b,t)+Vector3.yAxis*(.08+3*math.sin(math.pi*t))end
  for i=0,N do local v=point(i/N)nodes[#nodes+1]={v.X,v.Y,v.Z}end
  for i=1,N do local aa,bb=point((i-1)/N),point(i/N)local cf=CFrame.lookAt((aa+bb)*.5,bb)local length=(bb-aa).Magnitude+.045
   p(m,"SolidDeckPlank",Vector3.new(W,.32,length),cf*CFrame.new(0,-.16,0),WOOD:Lerp(Color3.fromRGB(183,146,101),(i%4)*.055),true)report.planks+=1
   for _,s in ipairs({-1,1})do
    p(m,"TimberHandrail",Vector3.new(.32,.32,length),cf*CFrame.new(s*(W/2-.22),2.7,0),WOOD,true)
    p(m,"LowerRail",Vector3.new(.18,.18,length),cf*CFrame.new(s*(W/2-.22),1.15,0),DARK,true)
    if i%4==1 or i==N then
     local pos=cf:PointToWorldSpace(Vector3.new(s*(W/2-.22),0,0))local h=ground(pos.X,pos.Z)local height=pos.Y+2.9-h.Y+.3
     local post=p(m,"GroundedCarvedPost",Vector3.new(.7,height,.7),CFrame.new(pos.X,(pos.Y+2.9+h.Y-.3)*.5,pos.Z),DARK,true)post:SetAttribute("GroundPoint",h)
     p(m,"PostCap",Vector3.new(.92,.24,.92),CFrame.new(pos+Vector3.yAxis*3),WOOD,true)
     p(m,"CarvedBand",Vector3.new(.84,.16,.84),CFrame.new(pos+Vector3.yAxis*2.55),WOOD,true)
     if i>4 and i<N-3 then local lower=pos-Vector3.yAxis*1.2 local other=pos+cf.LookVector*2.7-Vector3.yAxis*.12
      p(m,"SupportBrace",Vector3.new(.42,.42,(other-lower).Magnitude),CFrame.lookAt((lower+other)*.5,other),DARK,true)
     end
    end
   end
  end
  for _,endpoint in ipairs({a,b})do p(m,"BankApron",Vector3.new(2.6,.25,W),CFrame.new(endpoint+Vector3.yAxis*-.06),WOOD,true)end
  m:SetAttribute("DeckStart",point(0))m:SetAttribute("DeckEnd",point(1))m:SetAttribute("DeckWidth",W)m:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))report.bridges+=1
 end
 local dock=world.Amenities.RiversideGarden.LakesideBoardwalk
 for _,v in ipairs(dock:GetDescendants())do if v:IsA("BasePart")then v.CanCollide=true v.CanQuery=true v.Transparency=0 end end
 return report
end
return B
