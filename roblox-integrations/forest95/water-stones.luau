local B={}
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
 local raw=game:GetService("AssetService"):LoadAssetAsync(6833503207)
 local surface=assert(raw:FindFirstChild("Water",true))assert(surface:IsA("MeshPart")and surface.MeshId=="rbxassetid://6833048037","Requested water model changed")
 local report={waterTiles=0,shoreFoam=0,stones=0,stoneFaces=0,waterAsset=6833503207}
 local water=Instance.new("Folder")water.Name="CartoonWater"water:SetAttribute("SourceAssetId",6833503207)water.Parent=garden
 Terrain.WaterColor=Color3.fromRGB(55,161,186)Terrain.WaterTransparency=.24 Terrain.WaterReflectance=.025 Terrain.WaterWaveSize=.015 Terrain.WaterWaveSpeed=3
 -- Keep native continuous swimming water. Import only one shallow visual layer from the requested model.
 for z=-294,294,12 do for x=-150,174,12 do
  local safe=true for _,dx in ipairs({-6,0,6})do for _,dz in ipairs({-6,0,6})do if not wet(x+dx,z+dz)then safe=false end end end
  if safe then
   local p=surface:Clone()p.Name="CartoonWaterSurface"p.Size=Vector3.new(12,.035,12)p.CFrame=CFrame.new(x,6.14,z)p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false p.Material=Enum.Material.SmoothPlastic p.Transparency=.91 p.Color=Terrain.WaterColor p:SetAttribute("SourceAssetId",6833503207)p:SetAttribute("WaterCentre",Vector3.new(x,6,z))
   for _,d in ipairs(p:GetDescendants())do if d:IsA("LuaSourceContainer")then d:Destroy()elseif d:IsA("Texture")then d.StudsPerTileU=14 d.StudsPerTileV=14 d.Transparency=.74 d.OffsetStudsU=x%14 d.OffsetStudsV=z%14 C:AddTag(d,"TreeWorldWaterTexture")end end
   p.Parent=water report.waterTiles+=1
  end
 end end
 local foam=Instance.new("Folder")foam.Name="ShoreFoam"foam.Parent=water
 for z=-274,274,8 do local center=Scene.riverX(z)
  if wet(center,z)then for _,side in ipairs({-1,1})do
   local inside,outside=center,center
   for _=1,80 do outside+=side*2 if not wet(outside,z)then break end inside=outside end
   for _=1,8 do local mid=(inside+outside)*.5 if wet(mid,z)then inside=mid else outside=mid end end
   local x=inside-side*.65
   if wet(x,z)then local strip=P(foam,"WaterlineFoam",Vector3.new(.32,.028,3.2),CFrame.new(x,6.075,z)*CFrame.Angles(0,.15*math.sin(z*.1),0),Color3.fromRGB(230,246,244),Enum.Material.SmoothPlastic,false)strip.Transparency=.38 report.shoreFoam+=1 end
  end end
 end
 raw:Destroy()runtime:SetAttribute("WaterStyle","CartoonWaterSingleLayer")runtime:SetAttribute("WaterAssetId",6833503207)
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
  for k=0,6 do local an=k*math.pi*2/7+angle local jitter=rng:NextNumber(.92,1.08)points[k+1]=center+Vector3.new(math.cos(an)*rx*jitter,0,math.sin(an)*rz*jitter)end
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
 -- A few large riverbank stones use the same polygon style without filling the walking route.
 world:SetAttribute("CartoonWaterTiles",report.waterTiles)world:SetAttribute("ReferenceSteppingStones",report.stones)
 return report
end
return B
