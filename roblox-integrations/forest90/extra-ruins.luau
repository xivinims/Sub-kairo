local Builder={}
local Collection=game:GetService("CollectionService")local STONE=Color3.fromRGB(156,163,141)local GREEN=Color3.fromRGB(64,100,46)
function Builder.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local rng=Random.new(9014)
 local folder=Instance.new("Folder")folder.Name="ForestLandmarks"folder.Parent=world.Amenities
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-340,0),ray)end
 local function p(parent,name,size,cf,color,material,collide)
  local v=Instance.new("Part")v.Name=name v.Size=size v.CFrame=cf v.Color=color or STONE v.Material=material or Enum.Material.Limestone v.Anchored=true v.CanCollide=collide~=false v.CanQuery=v.CanCollide v.CanTouch=false v.Parent=parent return v
 end
 local function line(parent,name,a,b,thickness,color,material)return p(parent,name,Vector3.new(thickness,thickness,(b-a).Magnitude+.02),CFrame.lookAt((a+b)*.5,b),color,material,false)end
 local function cylinder(parent,name,diameter,height,cf,color)
  local v=p(parent,name,Vector3.new(height,diameter,diameter),cf*CFrame.Angles(0,0,math.pi*.5),color,Enum.Material.Limestone,true)v.Shape=Enum.PartType.Cylinder return v
 end
 local function site(target,r)
  local best,score
  for radius=0,64,8 do for i=0,11 do
   local a=i*math.pi/6 local x,z=target.X+math.cos(a)*radius,target.Y+math.sin(a)*radius local centre=ground(x,z)
   if centre and centre.Material~=Enum.Material.Water and centre.Position.Y>10 then
    local lo,hi=centre.Position.Y,centre.Position.Y local valid=true
    for n=0,7 do local b=n*math.pi/4 local h=ground(x+math.cos(b)*r,z+math.sin(b)*r)if not h or h.Material==Enum.Material.Water then valid=false break end lo=math.min(lo,h.Position.Y)hi=math.max(hi,h.Position.Y)end
    local merit=hi-lo+radius*.02 if valid and hi-lo<5 and(not score or merit<score)then best=Vector3.new(x,hi+.35,z)score=merit end
   end
  end end return assert(best,"No dry supported landmark site")
 end
 local function platform(name,target,r)
  local origin=site(target,r)local model=Instance.new("Model")model.Name=name model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model:SetAttribute("Origin",origin)model.Parent=folder
  for _,group in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do for _,m in ipairs(group:GetChildren())do local point=m:GetPivot().Position if(Vector2.new(point.X-origin.X,point.Z-origin.Z)).Magnitude<r+9 then m:Destroy()end end end
  local cf=CFrame.new(origin)
  local floor=p(model,"LandmarkFloor",Vector3.new(r*2,.6,r*2),cf*CFrame.new(0,-.3,0),STONE,Enum.Material.Limestone,true)
  for x=-r+2,r-2,4 do for z=-r+2,r-2,4 do
   local h=assert(ground(origin.X+x,origin.Z+z))local height=math.max(.45,origin.Y-.6-h.Position.Y+.3)
   local base=p(model,"LandmarkFoundation",Vector3.new(4.1,height,4.1),cf*CFrame.new(x,-.6-height*.5,z),Color3.fromRGB(126,134,118),Enum.Material.Slate,true)base:SetAttribute("GroundPoint",h.Position)
  end end
  for _=1,12 do local x,z=rng:NextNumber(-r+1,r-1),rng:NextNumber(-r+1,r-1)p(model,"GroundMoss",Vector3.new(rng:NextNumber(.6,1.6),.025,rng:NextNumber(.5,1.4)),cf*CFrame.new(x,.015,z),GREEN,Enum.Material.Grass,false)end
  -- Steps run from the local ground to the platform, including every rise on a slope.
  local entry=ground(origin.X,origin.Z+r+10)local start=assert(entry).Position local count=math.max(6,math.ceil((origin.Y-start.Y)/.4))
  for i=1,count do local t=i/count local z=origin.Z+r+10*(1-t)local top=start.Y+(origin.Y-start.Y)*t local h=assert(ground(origin.X,z))
   local height=math.max(.35,top-h.Position.Y+.3)local step=p(model,"LandmarkStep",Vector3.new(7,height,10/count+.15),CFrame.new(origin.X,top-height*.5,z),STONE,Enum.Material.Limestone,true)step:SetAttribute("GroundPoint",h.Position)
  end
  return model,cf
 end
 local function ivy(parent,cf,height,radius)
  for i=0,27 do local a=i*.62 local b=(i+1)*.62 local y=i*height/28 local yy=(i+1)*height/28
   line(parent,"IvyVine",(cf*CFrame.new(math.cos(a)*radius,y,math.sin(a)*radius)).Position,(cf*CFrame.new(math.cos(b)*radius,yy,math.sin(b)*radius)).Position,.09,GREEN,Enum.Material.Grass)
   local leaf=p(parent,"IvyLeaf",Vector3.new(.6,.07,.3),cf*CFrame.new(math.cos(a)*(radius+.15),y,math.sin(a)*(radius+.15))*CFrame.Angles(.4,a,.1),GREEN,Enum.Material.Grass,false)leaf.Shape=Enum.PartType.Ball
  end
 end
 local function column(parent,cf,height)
  p(parent,"ColumnPlinth",Vector3.new(3,.5,3),cf*CFrame.new(0,.25,0))cylinder(parent,"ColumnShaft",1.7,height,cf*CFrame.new(0,.5+height*.5,0),STONE)
  for _,y in ipairs({.7,height+.5})do cylinder(parent,"ColumnMoulding",2.15,.3,cf*CFrame.new(0,y,0),Color3.fromRGB(183,186,161))end
  p(parent,"Capital",Vector3.new(2.9,.6,2.9),cf*CFrame.new(0,height+.9,0))ivy(parent,cf,.5+height,.93)
 end
 local mist,mc=platform("MossySanctuary",Vector2.new(-245,-45),14)
 mist:SetAttribute("ReferenceStyle","Mossy stairs and circular stone sanctuary")
 -- Two wrapped gateway columns frame a stairway to a circular, broken-roof sanctuary.
 for _,side in ipairs({-1,1})do column(mist,mc*CFrame.new(side*8,0,10),14)
  for z=-8,8,4 do p(mist,"BrokenSideWall",Vector3.new(1.5,rng:NextNumber(1.8,3.6),3.7),mc*CFrame.new(side*12,1.4,z),STONE,Enum.Material.Cobblestone,true)end
 end
 for i=0,7 do local a=i*math.pi/4 column(mist,mc*CFrame.new(math.cos(a)*7,0,math.sin(a)*7-3),8)
  if i~=2 and i~=3 then local pos=Vector3.new(math.cos(a)*7,9.8,math.sin(a)*7-3)p(mist,"BrokenCircularLintel",Vector3.new(5.9,.8,2.6),mc*CFrame.new(pos)*CFrame.Angles(0,-a+math.pi*.5,0))end
 end
 p(mist,"Altar",Vector3.new(5,1.2,3),mc*CFrame.new(0,.6,-6),Color3.fromRGB(185,189,164),Enum.Material.Marble,true)
 local torii,tc=platform("StoneToriiGlade",Vector2.new(230,-95),12)torii:SetAttribute("ReferenceStyle","Weathered stone torii and scattered stepping stones")
 for gate=0,2 do local z=-8+gate*7 local h=gate==1 and 12 or 9
  for _,side in ipairs({-1,1})do cylinder(torii,"ToriiPillar",1.35,h,tc*CFrame.new(side*6,h*.5,z),Color3.fromRGB(116,127,124))p(torii,"ToriiBase",Vector3.new(2.6,.4,2.6),tc*CFrame.new(side*6,.2,z),Color3.fromRGB(133,146,136))end
  p(torii,"ToriiLintel",Vector3.new(17,.8,1.1),tc*CFrame.new(0,h,z),Color3.fromRGB(132,143,137),Enum.Material.Slate,true)
  for _,side in ipairs({-1,1})do p(torii,"RaisedLintelEnd",Vector3.new(3.4,.8,1.1),tc*CFrame.new(side*9,h+.15,z)*CFrame.Angles(0,0,side*.12),Color3.fromRGB(132,143,137),Enum.Material.Slate,true)end
  p(torii,"ToriiTie",Vector3.new(14,.5,.9),tc*CFrame.new(0,h-2,z),Color3.fromRGB(110,124,113))
 end
 local tower,wc=platform("BrokenWatchtower",Vector2.new(-260,220),12)tower:SetAttribute("ReferenceStyle","Broken forest tower with an armored skeleton guardian")
 for _,side in ipairs({-1,1})do for _,z in ipairs({-8,8})do column(tower,wc*CFrame.new(side*8,0,z),10)end
  p(tower,"WeatheredWall",Vector3.new(1.6,8,18),wc*CFrame.new(side*10,4,0),Color3.fromRGB(137,145,129),Enum.Material.Cobblestone,true)
 end
 for _,z in ipairs({-9,9})do p(tower,"BrokenRoofBeam",Vector3.new(20,1,2),wc*CFrame.new(0,11.7,z),Color3.fromRGB(179,183,163))end
 p(tower,"CrumbledRearWall",Vector3.new(14,4.5,1.5),wc*CFrame.new(0,2.25,-10),Color3.fromRGB(134,140,128),Enum.Material.Cobblestone,true)
 local raw=game:GetService("AssetService"):LoadAssetAsync(882493119)local skeleton=assert(raw:FindFirstChildOfClass("Model")):Clone()
 for _,d in ipairs(skeleton:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Sound")or d:IsA("ProximityPrompt")then d:Destroy()elseif d:IsA("BasePart")then d.Anchored=true d.CanCollide=false d.CanQuery=false d.CanTouch=false end end
 skeleton:PivotTo(CFrame.identity)local cf,size=skeleton:GetBoundingBox()skeleton:PivotTo(skeleton:GetPivot()-Vector3.new(cf.X,cf.Y-size.Y*.5,cf.Z))skeleton.PrimaryPart=nil skeleton.WorldPivot=CFrame.identity
 skeleton.Name="ArmoredSkeleton"skeleton:SetAttribute("SourceAssetId",882493119)skeleton:PivotTo(wc*CFrame.new(0,0,-5))skeleton.Parent=tower raw:Destroy()
 -- Two additional tea corners reuse the authored furniture and working prompts.
 local tea=world.Amenities.ForestRuins.TeaCorner
 for _,info in ipairs({{mist,mc*CFrame.new(21,0,5)},{torii,tc*CFrame.new(20,0,2)}})do
  local patio=info[2]local position=patio.Position
  p(info[1],"PatioLink",Vector3.new(4,.6,7),patio*CFrame.new(-7,-.3,0),STONE,Enum.Material.Limestone,true)
  p(info[1],"TeaPatioFloor",Vector3.new(14,.6,14),patio*CFrame.new(0,-.3,0),STONE,Enum.Material.Limestone,true)
  for x=-5,5,5 do for z=-5,5,5 do local hit=assert(ground(position.X+x,position.Z+z))
   local height=math.max(.4,position.Y-.6-hit.Position.Y+.3)local foundation=p(info[1],"LandmarkFoundation",Vector3.new(5.1,height,5.1),patio*CFrame.new(x,-.6-height*.5,z),STONE,Enum.Material.Slate,true)foundation:SetAttribute("GroundPoint",hit.Position)
  end end
  for _,group in ipairs({world.Decor.Trees,world.Decor.Plants,world.Decor.RocksAndLogs})do for _,m in ipairs(group:GetChildren())do local point=m:GetPivot().Position if(Vector2.new(point.X-position.X,point.Z-position.Z)).Magnitude<11 then m:Destroy()end end end
  local corner=tea:Clone()corner.Name="TeaCorner"local originalTable=corner.AntiqueTeaTable
  local origin=originalTable:GetPivot()local delta=info[2]*origin:Inverse()
  corner:PivotTo(delta*corner:GetPivot())corner.Parent=info[1]
  local prompt=assert(corner:FindFirstChild("ServeTea",true))Collection:AddTag(prompt,"TreeWorldTeaPrompt")
  for _,d in ipairs(corner:GetDescendants())do if d:IsA("Seat")then local link=d:FindFirstChild("TeaPrompt")if link then link.Value=prompt end Collection:AddTag(d,"RuinSeat")end end
 end
 world:SetAttribute("TreeCount",#world.Decor.Trees:GetChildren())world:SetAttribute("PlantCount",#world.Decor.Plants:GetChildren())world:SetAttribute("RuinCount",4)
 return{ruins=4,additionalTeaTables=2,armoredSkeletons=1}
end
return Builder
