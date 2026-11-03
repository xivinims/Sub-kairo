local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Terrain=workspace.Terrain local Scene=require(runtime.Scene)
 local protected={}
 for _,m in ipairs({world.Amenities.ForestRuins,world.Amenities.WeatheredHillStair})do local cf,size=m:GetBoundingBox()protected[#protected+1]={x=cf.X,z=cf.Z,rx=size.X*.5+8,rz=size.Z*.5+8}end
 for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do local cf,size=m:GetBoundingBox()protected[#protected+1]={x=cf.X,z=cf.Z,rx=size.X*.5+8,rz=size.Z*.5+8}end
 for _,m in ipairs(world.Amenities.SeasonalDetails.Camps:GetChildren())do local p=m:GetAttribute("Centre")protected[#protected+1]={x=p.X,z=p.Z,rx=14,rz=14}end
 for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do for _,key in ipairs({"DeckStart","DeckEnd"})do local p=bridge:GetAttribute(key)protected[#protected+1]={x=p.X,z=p.Z,rx=15,rz=15}end end
 local function preservation(x,z)
  local weight=0
  for _,s in ipairs(protected)do local d=math.max(math.abs(x-s.x)-s.rx,math.abs(z-s.z)-s.rz)weight=math.max(weight,1-math.clamp(d/16,0,1))end
  return weight
 end
 local heights={}local MIN,MAX=-512,512 local N=256 local report={smoothedColumns=0,palePathColumns=0,removedRocks=0,keptRocks=0,trimmedTrees=0}
 for bx=MIN,MAX-1,128 do for bz=MIN,MAX-1,128 do
  local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))local data=Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy"})
  for ix=1,32 do local gx=(bx-MIN)/4+ix heights[gx]=heights[gx]or{}
   for iz=1,32 do local gz=(bz-MIN)/4+iz local h=-64
    for iy=54,1,-1 do local fill=data.SolidOccupancy[ix][iy][iz]if fill>0 then h=-64+(iy-1)*4+fill*4 break end end heights[gx][gz]=h
   end
  end task.wait()
 end end
 for bx=MIN,MAX-1,128 do for bz=MIN,MAX-1,128 do
  local region=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))local data=Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","SolidMaterial","LiquidOccupancy"})
  for ix=1,32 do for iz=1,32 do
   local gx,gz=(bx-MIN)/4+ix,(bz-MIN)/4+iz local x,z=bx+(ix-.5)*4,bz+(iz-.5)*4 local h=heights[gx][gz]
   if h>7.6 and gx>4 and gx<N-4 and gz>4 and gz<N-4 then
    local sum,weight=0,0
    for dx=-3,3 do for dz=-3,3 do local sample=heights[gx+dx][gz+dz]if sample>7.4 then local w=1/(1+dx*dx+dz*dz)sum+=sample*w weight+=w end end end
    local smoothHeight=sum/weight local keep=preservation(x,z)local blend=.78*(1-keep)
    local path=Scene.pathDistance(x,z)local target=math.max(7.65,h+(smoothHeight-h)*blend)
    for iy=1,54 do local low=-64+(iy-1)*4 local fill=math.clamp((target-low)/4,0,1)
     data.SolidOccupancy[ix][iy][iz]=fill
     if fill>0 then
      if target-low<7 and keep<.9 then data.SolidMaterial[ix][iy][iz]=path<4.3 and Enum.Material.Sand or Enum.Material.Grass
      elseif data.SolidMaterial[ix][iy][iz]==Enum.Material.Air then data.SolidMaterial[ix][iy][iz]=Enum.Material.Ground end
     else data.SolidMaterial[ix][iy][iz]=Enum.Material.Air end
    end
    if blend>0 and math.abs(target-h)>.015 then report.smoothedColumns+=1 end
    if path<4.3 and keep<.9 then report.palePathColumns+=1 end
   end
  end end
  Terrain:WriteVoxelChannels(region,4,{SolidOccupancy=data.SolidOccupancy,SolidMaterial=data.SolidMaterial,LiquidOccupancy=data.LiquidOccupancy})task.wait()
 end end
 Terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(107,153,64))Terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(208,195,157))
 local lake=world:GetAttribute("CentralLake")local index=0
 for _,m in ipairs(world.Decor.RocksAndLogs:GetChildren())do local name=m.Name:lower()local rock=name:find("rock",1,true)or name:find("boulder",1,true)
  if rock then
   index+=1 local p=m:GetPivot().Position local near=Scene.pathDistance(p.X,p.Z)<12
   if near or index%3~=1 or report.keptRocks>=48 then m:Destroy()report.removedRocks+=1
   else report.keptRocks+=1 local _,size=m:GetBoundingBox()if math.max(size.X,size.Y,size.Z)>11 then m:ScaleTo(m:GetScale()*11/math.max(size.X,size.Y,size.Z))end end
  end
 end
 for _,m in ipairs(world.Decor.Trees:GetChildren())do
  local _,size=m:GetBoundingBox()if size.Y>68 then m:ScaleTo(m:GetScale()*68/size.Y)report.trimmedTrees+=1 end
  for _,p in ipairs(m:GetDescendants())do if p:IsA("MeshPart")and(p.Name:lower():find("leaf",1,true)or p.Name:lower():find("leaves",1,true))then
   local col=p.Color:Lerp(Color3.fromRGB(103,157,74),.28)p.Color=col p:SetAttribute("SeasonBaseColor",col)local a=p:FindFirstChildOfClass("SurfaceAppearance")if a then a.Color=col end
  end end
 end
 for _,m in ipairs(world.Decor.Plants:GetChildren())do if m.Name:find("FernTall",1,true)then local _,size=m:GetBoundingBox()if size.Y>2.2 then m:ScaleTo(m:GetScale()*2.2/size.Y)end end end
 world:SetAttribute("TerrainOrganized",true)world:SetAttribute("AccentRockCount",report.keptRocks)
 return report
end
return B
