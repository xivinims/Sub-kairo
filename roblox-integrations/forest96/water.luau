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
 local report={stones=0,stoneFaces=0,removedWaterOverlays=true}
 Terrain.WaterColor=Color3.fromRGB(61,151,175)Terrain.WaterTransparency=.28 Terrain.WaterReflectance=.14 Terrain.WaterWaveSize=.035 Terrain.WaterWaveSpeed=4
 for _,d in ipairs(world:GetDescendants())do if d:IsA("ParticleEmitter")or d:IsA("Beam")or d:IsA("Trail")then d:Destroy()end end
 local client=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ForestWaterClient")if client then client:Destroy()end
 runtime:SetAttribute("WaterStyle","NativeBlueReflective")
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
  for k=0,5 do local an=k*math.pi*2/6+angle local jitter=rng:NextNumber(.92,1.08)points[k+1]=center+Vector3.new(math.cos(an)*rx*jitter,0,math.sin(an)*rz*jitter)end
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
 -- Replace the old scattered rock models with sparse, broad-faced rocks too.
 -- Keep gaps along the earth paths and bury the lower ring into the bank.
 local candidates={}
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do
  local name=m.Name:lower()
  if name:find("rock",1,true)or name:find("boulder",1,true)then
   local cf,size=m:GetBoundingBox()
   candidates[#candidates+1]={x=cf.X,z=cf.Z,size=size}
   m:Destroy()
  end
 end
 table.sort(candidates,function(a,b)if a.x==b.x then return a.z<b.z end return a.x<b.x end)
 local accents=0
 for i,old in ipairs(candidates)do
  if accents>=24 then break end
  local x,zz=old.x,old.z
  local h=ground(x,zz)
  if h.Y<7 or Scene.pathDistance(x,zz)<9 or i%3==0 then continue end
  local width=math.clamp(math.max(old.size.X,old.size.Z),4,9)
  local height=math.clamp(old.size.Y*.65,1.6,3.6)
  local model=Instance.new("Model")model.Name="PaleFacetedRock"model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  model:SetAttribute("ReferenceStyle","Irregular broad pale top with bevelled slate sides")model.Parent=world.Decor.RocksAndLogs
  local bottom=h.Y-.45 local upper,lower={},{}
  local center=Vector3.new(x,h.Y+height,zz)
  local rotation=rng:NextNumber(0,math.pi*2)
  for k=0,5 do
   local angle=rotation+k*math.pi/3 local spread=rng:NextNumber(.84,1.08)
   local dx,dz=math.cos(angle)*width*.48*spread,math.sin(angle)*width*.4*spread
   upper[k+1]=center+Vector3.new(dx*.83,0,dz*.83)
   lower[k+1]=Vector3.new(x+dx,bottom,zz+dz)
  end
  for k=1,6 do local j=k%6+1
   triangle(model,center,upper[k],upper[j],.08,Color3.fromRGB(180+k%3*5,190+k%3*5,194+k%3*5),"PaleStoneTop")
   local color=Color3.fromRGB(101+k%3*9,117+k%3*9,124+k%3*9)
   triangle(model,upper[k],lower[k],upper[j],.1,color,"FacetedStoneSide")
   triangle(model,upper[j],lower[k],lower[j],.1,color,"FacetedStoneSide")
  end
  accents+=1
 end
 report.accentRocks=accents report.oldAccentRocksRemoved=#candidates
 assert(accents>=12,"Too few well placed reference rocks")
 world:SetAttribute("CartoonWaterTiles",0)world:SetAttribute("ReferenceSteppingStones",report.stones)
 return report
end
return B
