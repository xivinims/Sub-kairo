local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local T=workspace.Terrain local Scene=require(runtime.Scene)
 local mask={}
 for _,m in ipairs({world.Amenities.ForestRuins,world.Amenities.WeatheredHillStair})do local cf,size=m:GetBoundingBox()mask[#mask+1]={x=cf.X,z=cf.Z,rx=size.X*.5+7,rz=size.Z*.5+7}end
 for _,m in ipairs(world.Amenities.ForestLandmarks:GetChildren())do local cf,size=m:GetBoundingBox()mask[#mask+1]={x=cf.X,z=cf.Z,rx=size.X*.5+7,rz=size.Z*.5+7}end
 for _,m in ipairs(world.Amenities.SeasonalDetails.Camps:GetChildren())do local p=m:GetAttribute("Centre")mask[#mask+1]={x=p.X,z=p.Z,rx=14,rz=14}end
 local function preserve(x,z)local w=0 for _,p in ipairs(mask)do local d=math.max(math.abs(x-p.x)-p.rx,math.abs(z-p.z)-p.rz)w=math.max(w,1-math.clamp(d/72,0,1))end return w end
 local chunks={}
 for bx=-512,384,128 do for bz=-512,384,128 do local reg=Region3.new(Vector3.new(bx,-64,bz),Vector3.new(bx+128,152,bz+128))chunks[#chunks+1]={x=bx,z=bz,region=reg,data=T:ReadVoxelChannels(reg,4,{"SolidMaterial","SolidOccupancy","LiquidOccupancy"})}end end
 -- The extension is flat, compact native terrain; streamed scenery supplies detail only near people.
 T:FillBlock(CFrame.new(0,-6,0),Vector3.new(4096,52,4096),Enum.Material.Grass)
 local report={coreColumns=0,flattenedColumns=0,newLakes=0,extent=4096}
 for _,chunk in ipairs(chunks)do local d=chunk.data
  for ix=1,32 do for iz=1,32 do local x,z=chunk.x+(ix-.5)*4,chunk.z+(iz-.5)*4 local h=-64
   for iy=54,1,-1 do local o=d.SolidOccupancy[ix][iy][iz]if o>0 then h=-64+(iy-1)*4+o*4 break end end
   local old=h local w=preserve(x,z)
   if h>34 then h=h+(34+(h-34)*.12-h)*(1-w)report.flattenedColumns+=1 end
   local edge=math.clamp((math.max(math.abs(x),math.abs(z))-344)/164,0,1)edge=edge*edge*(3-2*edge)
   if edge>0 then h=h*(1-edge)+22*edge end
   for iy=1,54 do local low=-64+(iy-1)*4 local fill=math.clamp((h-low)/4,0,1)
    d.SolidOccupancy[ix][iy][iz]=fill
    if fill>0 then local oldMat=d.SolidMaterial[ix][iy][iz]
     if oldMat==Enum.Material.Sand then oldMat=Enum.Material.Ground end
     if oldMat==Enum.Material.Air or edge>.4 then oldMat=h-low<8 and(Scene.pathDistance(x,z)<4.8 and Enum.Material.Ground or Enum.Material.Grass)or Enum.Material.Ground end
     d.SolidMaterial[ix][iy][iz]=oldMat
    else d.SolidMaterial[ix][iy][iz]=Enum.Material.Air end
    if edge>0 then d.LiquidOccupancy[ix][iy][iz]=fill<1 and math.clamp((6-low)/4,0,1)or 0 end
   end report.coreColumns+=1
  end end
  T:WriteVoxelChannels(chunk.region,4,{SolidMaterial=d.SolidMaterial,SolidOccupancy=d.SolidOccupancy,LiquidOccupancy=d.LiquidOccupancy})task.wait()
 end
 local lakes={{900,650,110,74},{-960,-750,130,90},{760,-1000,96,80},{-1100,1000,145,86}}
 local descriptors={{27,6,-18,76,52},{39,6,157,61,62}}
 for _,l in ipairs(lakes)do local cx,cz,rx,rz=unpack(l)local reg=Region3.new(Vector3.new(cx-rx*1.3,-16,cz-rz*1.3),Vector3.new(cx+rx*1.3,40,cz+rz*1.3)):ExpandToGrid(4)local d=T:ReadVoxelChannels(reg,4,{"SolidMaterial","SolidOccupancy","LiquidOccupancy"})local lo=reg.CFrame.Position-reg.Size*.5
  for ix=1,d.Size.X do for iz=1,d.Size.Z do local x,z=lo.X+(ix-.5)*4,lo.Z+(iz-.5)*4 local r=math.sqrt(((x-cx)/rx)^2+((z-cz)/rz)^2)local a=math.clamp((r-.56)/.7,0,1)a=a*a*(3-2*a)local h=-1+23*a
   for iy=1,d.Size.Y do local low=lo.Y+(iy-1)*4 local fill=math.clamp((h-low)/4,0,1)d.SolidOccupancy[ix][iy][iz]=fill d.SolidMaterial[ix][iy][iz]=fill>0 and(h-low<5 and(h<8 and Enum.Material.Ground or Enum.Material.Grass)or Enum.Material.Ground)or Enum.Material.Air d.LiquidOccupancy[ix][iy][iz]=fill<1 and math.clamp((6-low)/4,0,1)or 0 end
  end end T:WriteVoxelChannels(reg,4,{SolidMaterial=d.SolidMaterial,SolidOccupancy=d.SolidOccupancy,LiquidOccupancy=d.LiquidOccupancy})descriptors[#descriptors+1]={cx,6,cz,rx,rz}report.newLakes+=1 task.wait()
 end
 T:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(107,154,67))T:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(114,91,66))T:SetMaterialColor(Enum.Material.Mud,Color3.fromRGB(96,79,62))
 world:SetAttribute("WorldExtent",4096)world:SetAttribute("TerrainOrganized",true)world:SetAttribute("PathMaterial","Ground")runtime:SetAttribute("LakeLocations",game:GetService("HttpService"):JSONEncode(descriptors))
 return report
end
return B
