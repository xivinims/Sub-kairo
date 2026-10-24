local B={}
local C=game:GetService("CollectionService")
local function P(parent,name,size,cf,color,mat,collision)
 local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=mat or Enum.Material.Wood p.Anchored=true p.CanCollide=collision~=false p.CanQuery=p.CanCollide p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local function line(parent,name,a,b,width,color,mat,collision)return P(parent,name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)*.5,b),color,mat,collision)end
local WHITE=Color3.fromRGB(229,225,204)local BLUE=Color3.fromRGB(65,100,122)local WOOD=Color3.fromRGB(143,112,79)local DARK=Color3.fromRGB(85,86,72)
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime
 for _,obj in ipairs({world:FindFirstChild("OwnerNPC"),runtime:FindFirstChild("NPCController"),game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestNPCClient")})do if obj then obj:Destroy()end end
 local folder=Instance.new("Folder")folder.Name="RiversideGarden"folder.Parent=world.Amenities
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}rp.IgnoreWater=true
 local function ground(x,z)return assert(workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-300,0),rp)).Position end
 local house=Instance.new("Model")house.Name="WaterCottage"house.Parent=folder house:SetAttribute("Reference","White timber cottage with blue gable roof, dormers and a surrounding pier")
 local O=Vector3.new(40,10.5,135)house:SetAttribute("Origin",O)
 local function h(name,size,x,y,z,color,mat,col,rotation)return P(house,name,size,CFrame.new(O+Vector3.new(x,y,z))*(rotation or CFrame.identity),color or WHITE,mat,col)end
 local function support(x,z,top,parent)
  local g=ground(x,z)local p=P(parent,"GroundedPiling",Vector3.new(1.1,top-g.Y+.5,1.1),CFrame.new(x,(top+g.Y-.5)*.5,z),DARK,Enum.Material.Wood,true)p:SetAttribute("GroundPoint",g)return p
 end
 -- Continuous veranda, authored plank seams, pilings reach the actual riverbed.
 h("VerandaCollision",Vector3.new(40,.7,34),0,-.35,0,WOOD,Enum.Material.WoodPlanks,true)
 for x=-19.5,19.5,1.5 do h("VerandaPlank",Vector3.new(1.44,.12,34),x,.04,0,WOOD:Lerp(WHITE,(x+20)%4*.03),Enum.Material.Wood,false)end
 for _,x in ipairs({-18,-9,0,9,18})do for _,z in ipairs({-15,0,15})do support(O.X+x,O.Z+z,O.Y-.7,house)end end
 h("Floor",Vector3.new(28,.35,22),0,.2,0,WHITE,Enum.Material.WoodPlanks,true)
 -- Front doorway and windows are genuinely open, not a solid box behind glass.
 for _,side in ipairs({-1,1})do
  h("FrontDoorPier",Vector3.new(11,10,.5),side*8.5,5.4,-11,WHITE,Enum.Material.WoodPlanks,true)
  h("DoorFrame",Vector3.new(.3,9.5,.7),side*3,5,-11.2,BLUE,Enum.Material.Wood,true)
 end
 h("DoorLintel",Vector3.new(6,1,.6),0,10,-11,BLUE,Enum.Material.Wood,true)
 h("BackWall",Vector3.new(28,10,.5),0,5.4,11,WHITE,Enum.Material.WoodPlanks,true)
 for _,side in ipairs({-1,1})do
  h("WallSill",Vector3.new(.5,3,22),side*14,1.9,0,WHITE,Enum.Material.WoodPlanks,true)
  h("WallTop",Vector3.new(.5,2,22),side*14,9.4,0,WHITE,Enum.Material.WoodPlanks,true)
  for _,z in ipairs({-9,-3,3,9})do h("WallStud",Vector3.new(.6,5,1),side*14,5.9,z,BLUE,Enum.Material.Wood,true)end
  for _,z in ipairs({-6,0,6})do
   local glass=h("WindowGlass",Vector3.new(.08,4.6,4.8),side*14,5.9,z,Color3.fromRGB(166,212,211),Enum.Material.Glass,false)glass.Transparency=.58
   h("WindowMullion",Vector3.new(.35,4.8,.2),side*14,5.9,z,WHITE,Enum.Material.Wood,false)
   h("WindowCrossbar",Vector3.new(.35,.2,5),side*14,5.9,z,WHITE,Enum.Material.Wood,false)
   h("WindowFlowerBox",Vector3.new(1, .7,4.8),side*14.55,3.4,z,BLUE,Enum.Material.Wood,false)
   for j=-2,2 do local flower=h("Flower",Vector3.new(.35,.4,.35),side*14.55,4,z+j*.8,Color3.fromRGB(244,196,194),Enum.Material.SmoothPlastic,false)flower.Shape=Enum.PartType.Ball end
  end
 end
 for _,x in ipairs({-14,14})do for _,z in ipairs({-11,11})do h("TimberCorner",Vector3.new(.8,11,.8),x,5.5,z,BLUE,Enum.Material.Wood,true)end end
 h("TimberBelt",Vector3.new(29,.6,23),0,10.6,0,BLUE,Enum.Material.Wood,false)
 -- Two steep roof slopes; slim overlapping strips read as slate rather than a monolithic slab.
 for _,s in ipairs({-1,1})do
  local rot=CFrame.Angles(0,0,-s*math.rad(38))
  h("RoofCollision",Vector3.new(19,.55,25),s*7.2,16,0,BLUE,Enum.Material.Slate,true,rot)
  for z=-12,12,1.25 do h("RoofSlateStrip",Vector3.new(19,.16,1.2),s*7.2,16.4,z,BLUE:Lerp(WHITE,(z+12)%3*.035),Enum.Material.Slate,false,rot)end
 end
 h("RoofRidge",Vector3.new(.8,.6,26),0,21.8,0,BLUE,Enum.Material.Slate,false)
 for _,z in ipairs({-8,8})do
  h("DormerFace",Vector3.new(.5,4,5),-8,17,z,WHITE,Enum.Material.WoodPlanks,false)
  h("DormerWindow",Vector3.new(.1,2.6,3),-8.3,17,z,Color3.fromRGB(162,209,210),Enum.Material.Glass,false).Transparency=.35
  for _,s in ipairs({-1,1})do h("DormerRoof",Vector3.new(6,.4,3.4),-6.2,19.4,z+s*1.2,BLUE,Enum.Material.Slate,false,CFrame.Angles(s*math.rad(33),0,0))end
 end
 -- Wrap-around railing leaves a real opening for the incoming walkway.
 for x=-18,18,6 do for _,z in ipairs({-16,16})do h("VerandaPost",Vector3.new(.6,3.5,.6),x,1.75,z,WHITE,Enum.Material.Wood,true)end end
 for _,x in ipairs({-19,19})do for z=-12,12,6 do h("VerandaPost",Vector3.new(.6,3.5,.6),x,1.75,z,WHITE,Enum.Material.Wood,true)end end
 for _,z in ipairs({-16,16})do h("Handrail",Vector3.new(38,.35,.4),0,3.3,z,WHITE,Enum.Material.Wood,true)end
 for _,x in ipairs({-19,19})do for _,z in ipairs({-10.5,10.5})do h("Handrail",Vector3.new(.4,.35,11),x,3.3,z,WHITE,Enum.Material.Wood,true)end end
 local bulb=h("PorchLantern",Vector3.new(.6,.85,.6),0,8,-12.2,Color3.fromRGB(255,213,153),Enum.Material.Neon,false)
 local light=Instance.new("PointLight")light.Range=17 light.Color=bulb.Color light.Parent=bulb C:AddTag(light,"ForestNightLight")
 -- Compact furnished interior; no imported executable code.
 h("KitchenCounter",Vector3.new(10,3,3),6,1.9,8,BLUE,Enum.Material.Wood,true)
 h("KitchenTop",Vector3.new(10.3,.2,3.3),6,3.5,8,WHITE,Enum.Material.Marble,true)
 for _,x in ipairs({-9,-5})do h("CarvedShelf",Vector3.new(3,.2,1),x,6.5,10.5,WOOD,Enum.Material.Wood,false)end
 local tea=world.Amenities.ForestRuins.TeaCorner:Clone()tea.Name="CottageTeaCorner"tea:PivotTo(tea:GetPivot()+(O+Vector3.new(-4,.375,2)-tea.AntiqueTeaTable:GetPivot().Position))tea.Parent=house
 -- clone links must point at the cloned teapot.
 local prompt=assert(tea:FindFirstChild("ServeTea",true))C:AddTag(prompt,"TreeWorldTeaPrompt")
 for _,seat in ipairs(tea:GetDescendants())do if seat:IsA("Seat")then local link=seat:FindFirstChild("TeaPrompt")if link then link.Value=prompt end C:AddTag(seat,"RuinSeat")end end
 local walk=Instance.new("Model")walk.Name="LakesideBoardwalk"walk.Parent=folder
 local nodes={}local start=O+Vector3.new(-20,0,0)
 local bankX=O.X-24
 while ground(bankX,O.Z).Y<8.5 and bankX>-150 do bankX-=2 end
 local finish=ground(bankX,O.Z)+Vector3.new(0,.3,0)
 local N=math.ceil((finish-start).Magnitude/1.8)
 for i=0,N do local t=i/N local p=start:Lerp(finish,t)+Vector3.new(0,0,math.sin(t*math.pi)*6)nodes[#nodes+1]={p.X,p.Y,p.Z}end
 for i=1,N do
  local a,b=Vector3.new(unpack(nodes[i])),Vector3.new(unpack(nodes[i+1]))local cf=CFrame.lookAt((a+b)*.5,b)local len=(b-a).Magnitude+.06
  P(walk,"BoardwalkPlank",Vector3.new(6,.32,len),cf-CFrame.new().UpVector*.16,WOOD:Lerp(WHITE,(i%3)*.045),Enum.Material.Wood,true)
  for _,s in ipairs({-1,1})do
   if i%3==0 then P(walk,"CarvedPost",Vector3.new(.5,3,.5),cf*CFrame.new(s*2.8,1.5,0),DARK,Enum.Material.Wood,true)support(a.X+s*cf.RightVector.X*2.8,a.Z+s*cf.RightVector.Z*2.8,a.Y,walk)end
   P(walk,"Handrail",Vector3.new(.3,.3,len),cf*CFrame.new(s*2.8,2.8,0),WOOD,Enum.Material.Wood,true)
  end
 end
 walk:SetAttribute("WalkNodes",game:GetService("HttpService"):JSONEncode(nodes))
 -- Stepping stone crossing near the lower stream: bank endpoints are found on real terrain.
 local stones=Instance.new("Model")stones.Name="StreamSteppingStones"stones.Parent=folder
 local z=-18 local cx=require(runtime.Scene).riverX(z)local left,right=cx-4,cx+4
 while ground(left,z).Y<6.8 do left-=2 end while ground(right,z).Y<6.8 do right+=2 end
 local steps=math.ceil((right-left)/4)local a,b=ground(left,z),ground(right,z)
 for i=0,steps do local t=i/steps local x=left+(right-left)*t local y=math.max(6.85,a.Y*(1-t)+b.Y*t)
  local p=P(stones,"WalkStone",Vector3.new(4.7,1.4,5),CFrame.new(x,y-.7,z+math.sin(t*math.pi*2)*1.2)*CFrame.Angles(0,(i%3)*.2,0),Color3.fromRGB(177,196,187),Enum.Material.Slate,true)p:SetAttribute("WalkTop",y)
  local g=ground(p.Position.X,p.Position.Z)P(stones,"SubmergedStone",Vector3.new(3.3,y-g.Y+.2,3.6),CFrame.new(p.Position.X,(y+g.Y)*.5-.2,p.Position.Z),Color3.fromRGB(120,146,138),Enum.Material.Slate,false)
 end
 -- Stylized edges follow the ACTUAL land/water boundary, not an analytic estimate.
 local foam=Instance.new("Folder")foam.Name="AnimeRiverFoam"foam.Parent=folder
 local waterRay=RaycastParams.new()waterRay.FilterType=Enum.RaycastFilterType.Include waterRay.FilterDescendantsInstances={workspace.Terrain}
 local function wet(x,z)local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-260,0),waterRay)return hit and hit.Material==Enum.Material.Water end
 local foamCount=0
 for zz=-272,272,6 do local center=require(runtime.Scene).riverX(zz)
  for _,s in ipairs({-1,1})do
   local x=center local last=x
   for _=1,100 do if not wet(x,zz)then break end last=x x+=s*2 end
   for _=1,7 do local mid=(last+x)*.5 if wet(mid,zz)then last=mid else x=mid end end
   if wet(last,zz)then local p=P(foam,"ShoreFoam",Vector3.new(.6,.035,2.6),CFrame.new(last-s*.35,6.04,zz)*CFrame.Angles(0,math.sin(zz*.05)*.25,0),Color3.fromRGB(235,249,245),Enum.Material.SmoothPlastic,false)p.Transparency=.3 p.CastShadow=false foamCount+=1
    for k=1,2 do local bubble=P(foam,"FoamBubble",Vector3.new(.25,.035,.25),CFrame.new(last-s*(.7+k*.25),6.045,zz+k*.55),WHITE,Enum.Material.SmoothPlastic,false)bubble.Shape=Enum.PartType.Ball bubble.Transparency=.3 bubble.CastShadow=false end
   end
  end
 end
 for zz=-240,240,12 do local x=require(runtime.Scene).riverX(zz)if wet(x,zz)then
  local p=P(foam,"AngularWaterGlint",Vector3.new(1.8,.025,3.4),CFrame.new(x,6.03,zz)*CFrame.Angles(0,.45,0),Color3.fromRGB(180,233,230),Enum.Material.SmoothPlastic,false)p.Transparency=.75 p.CastShadow=false end
 end
 workspace.Terrain.WaterColor=Color3.fromRGB(67,160,182)workspace.Terrain.WaterTransparency=.32 workspace.Terrain.WaterReflectance=.08 workspace.Terrain.WaterWaveSize=.025 workspace.Terrain.WaterWaveSpeed=5
 world:SetAttribute("UpgradeVersion",91)world:SetAttribute("LanternCount",#C:GetTagged("ForestNightLight"))runtime:SetAttribute("WaterStyle","AnimeSoftBlue")
 return{removedOwnerNPC=true,cottage=true,boardwalkSegments=N,steppingStones=steps+1,foamEdges=foamCount}
end
return B
