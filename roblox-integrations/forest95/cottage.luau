local B={}
local WHITE=Color3.fromRGB(235,235,215)local BLUE=Color3.fromRGB(67,105,123)local WOOD=Color3.fromRGB(153,119,80)local DARK=Color3.fromRGB(79,86,78)
function B.install()
 local world=workspace.ForestWorld local garden=world.Amenities.RiversideGarden local C=game:GetService("CollectionService")
 local old=garden.WaterCottage local tea=old:FindFirstChild("CottageTeaCorner")assert(tea)tea.Parent=nil local teaCF,teaSize=tea.AntiqueTeaTable:GetBoundingBox() local teaCenter=Vector3.new(teaCF.X,teaCF.Y-teaSize.Y*.5,teaCF.Z)
 old:Destroy()garden.LakesideBoardwalk:Destroy()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)).Position end
 local O=Vector3.new(40,10.8,135)local house=Instance.new("Model")house.Name="WaterCottage"house.ModelStreamingMode=Enum.ModelStreamingMode.Atomic house:SetAttribute("Origin",O)house:SetAttribute("RebuiltEntrance",true)house.Parent=garden
 local report={parts=0,walkwaySegments=0}
 local function P(parent,name,size,cf,col,mat,collide)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=col or WHITE p.Material=mat or Enum.Material.WoodPlanks p.Anchored=true p.CanCollide=collide~=false p.CanQuery=p.CanCollide p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent report.parts+=1 return p
 end
 local function h(name,size,x,y,z,col,mat,collide,rot)return P(house,name,size,CFrame.new(O+Vector3.new(x,y,z))*(rot or CFrame.identity),col,mat,collide)end
 -- Visible porch planks are the actual walking surface; no hidden box catches feet.
 for x=-13.5,13.5,1.5 do h("PorchPlank",Vector3.new(1.53,.4,24),x,-.2,0,WOOD)end
 for _,x in ipairs({-12,0,12})do for _,z in ipairs({-10,0,10})do local g=ground(O.X+x,O.Z+z)local top=O.Y-.4
  P(house,"GroundedPiling",Vector3.new(1.15,top-g.Y+.5,1.15),CFrame.new(O.X+x,(top+g.Y-.5)*.5,O.Z+z),DARK,Enum.Material.Wood,true)
 end end
 h("InteriorFloor",Vector3.new(21,.3,18),0,.15,0,WHITE)
 -- Main entrance faces the arriving boardwalk and opens directly to the room.
 for _,s in ipairs({-1,1})do h("WestWall",Vector3.new(.45,8.8,6.5),-10.5,4.7,s*5.75,WHITE)h("DoorFrame",Vector3.new(.8,8,.6),-10.65,4.2,s*2.3,BLUE,Enum.Material.Wood)end
 h("DoorLintel",Vector3.new(.7,1.2,5.2),-10.65,8.4,0,BLUE,Enum.Material.Wood)
 h("EastWall",Vector3.new(.45,8.8,18),10.5,4.7,0,WHITE)
 -- Front/back facades have framed real glass openings and solid low sills.
 for _,s in ipairs({-1,1})do
  h("FacadeSill",Vector3.new(21,2.4,.45),0,1.55,s*9,WHITE)
  h("FacadeLintel",Vector3.new(21,1.7,.45),0,8.35,s*9,WHITE)
  for _,x in ipairs({-9,-3,3,9})do h("WindowPier",Vector3.new(2.2,4.7,.5),x,5.1,s*9,WHITE)end
  for _,x in ipairs({-6,0,6})do local glass=h("WindowGlass",Vector3.new(3.8,4.4,.08),x,5.1,s*9,Color3.fromRGB(166,220,221),Enum.Material.Glass,false)glass.Transparency=.55
   h("WindowMullion",Vector3.new(.18,4.4,.3),x,5.1,s*9.1,BLUE,Enum.Material.Wood,false)h("WindowCrossbar",Vector3.new(3.8,.18,.3),x,5.1,s*9.1,BLUE,Enum.Material.Wood,false)
   h("FlowerBox",Vector3.new(4,.65,1),x,2.95,s*9.5,BLUE,Enum.Material.Wood)
  end
 end
 for _,x in ipairs({-10.5,10.5})do for _,z in ipairs({-9,9})do h("TimberCorner",Vector3.new(.75,9.5,.75),x,4.8,z,BLUE,Enum.Material.Wood)end end
 -- Roof slopes meet exactly at a shared ridge; end gables close the formerly exposed attic.
 local pitch=math.rad(32)local half=11.8 local ridge=9.6+half*math.tan(pitch)local slope=half/math.cos(pitch)
 for _,s in ipairs({-1,1})do h("RoofSlope",Vector3.new(slope,.4,21),s*half*.5,(ridge+9.6)*.5,0,BLUE,Enum.Material.Slate,true,CFrame.Angles(0,0,-s*pitch))end
 h("RoofRidge",Vector3.new(.5,.35,21.5),0,ridge+.15,0,BLUE,Enum.Material.Slate,true)
 for _,s in ipairs({-1,1})do for i=0,11 do local x=-10.5+(i+.5)*21/12 local height=(ridge-9.2)*(1-math.abs(x)/11.8)
  h("GableTimber",Vector3.new(21/12+.02,height,.4),x,9.2+height*.5,s*9,WHITE)
 end end
 for _,z in ipairs({-11.5,11.5})do for x=-12,12,4 do h("PorchPost",Vector3.new(.55,2.8,.55),x,1.4,z,WHITE,Enum.Material.Wood)end h("PorchHandrail",Vector3.new(27,.3,.45),0,2.7,z,WHITE,Enum.Material.Wood)end
 for _,x in ipairs({-13.7,13.7})do for _,z in ipairs({-8,8})do h("PorchHandrail",Vector3.new(.4,.3,6.5),x,2.7,z,WHITE,Enum.Material.Wood)end end
 local bulb=h("PorchLantern",Vector3.new(.5,.8,.5),-11.2,7.5,-3,Color3.fromRGB(255,209,141),Enum.Material.Neon,false)
 local light=Instance.new("PointLight")light.Color=bulb.Color light.Range=14 light.Shadows=false light.Parent=bulb C:AddTag(light,"ForestNightLight")
 h("KitchenCabinet",Vector3.new(6,2.7,2.5),7,1.65,6,BLUE)h("KitchenWorktop",Vector3.new(6.3,.25,2.8),7,3.1,6,WHITE,Enum.Material.Marble)
 h("RadioShelf",Vector3.new(3,.18,1.6),7,4.5,-6,WOOD,Enum.Material.Wood)
 tea:PivotTo(tea:GetPivot()+O+Vector3.new(2,.31,3)-teaCenter)tea.Parent=house
 local walk=Instance.new("Model")walk.Name="LakesideBoardwalk"walk.ModelStreamingMode=Enum.ModelStreamingMode.Atomic walk.Parent=garden
 local bankX=O.X-24 while ground(bankX,O.Z).Y<9 and bankX>-140 do bankX-=2 end
 local a=ground(bankX,O.Z)+Vector3.yAxis*.12 local b=O+Vector3.new(-14,0,0)local N=math.ceil((b-a).Magnitude/2)local nodes={}
 for i=0,N do local p=a:Lerp(b,i/N)nodes[#nodes+1]={p.X,p.Y,p.Z}end
 for i=1,N do local aa,bb=a:Lerp(b,(i-1)/N),a:Lerp(b,i/N)local cf=CFrame.lookAt((aa+bb)*.5,bb)local len=(bb-aa).Magnitude+.08
  P(walk,"BoardwalkPlank",Vector3.new(6,.32,len),cf*CFrame.new(0,-.16,0),WOOD,Enum.Material.Wood,true)
  for _,s in ipairs({-1,1})do P(walk,"BoardwalkRail",Vector3.new(.3,.3,len),cf*CFrame.new(s*2.85,2.4,0),WHITE,Enum.Material.Wood,true)
   if i%4==0 then local p=cf:PointToWorldSpace(Vector3.new(s*2.85,0,0))local g=ground(p.X,p.Z)local top=p.Y+2.7
    P(walk,"GroundedPost",Vector3.new(.6,top-g.Y+.3,.6),CFrame.new(p.X,(top+g.Y-.3)*.5,p.Z),DARK,Enum.Material.Wood,true)
   end
  end report.walkwaySegments+=1
 end
 P(walk,"BankApron",Vector3.new(2.5,.25,6),CFrame.new(a-Vector3.yAxis*.1),WOOD,Enum.Material.Wood,true)
 walk:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))house:SetAttribute("EntryPath",game:GetService("HttpService"):JSONEncode({{b.X,b.Y,b.Z},{O.X-10.5,O.Y+.3,O.Z},{O.X-5,O.Y+.3,O.Z}}))
 house:SetAttribute("RadioPosition",O+Vector3.new(7,4.61,-6))return report
end
return B
