local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)local C=game:GetService("CollectionService")
 local assetId=97893326625257
 local raw=game:GetService("AssetService"):LoadAssetAsync(assetId)
 local template=raw
 for _,d in ipairs(template:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Camera")then d:Destroy()end end
 template.PrimaryPart=nil
 local meshCount=0
 for _,d in ipairs(template:GetDescendants())do if d:IsA("MeshPart")then meshCount+=1 end end
 assert(meshCount>0,"The imported user FBX has no meshes")
 local cf,size=template:GetBoundingBox()
 assert(size.Y>size.X and size.Y>size.Z,"The FBX post is not upright")
 template:ScaleTo(template:GetScale()*10.5/size.Y)
 cf,size=template:GetBoundingBox()
 local base=Vector3.new(cf.X,cf.Y-size.Y*.5,cf.Z)
 template:PivotTo(template:GetPivot()-base)
 template.WorldPivot=CFrame.identity
 -- Keep the original FBX geometry, UVs and PBR materials. Only add a light.
 local mesh=assert(template:FindFirstChildWhichIsA("MeshPart",true))
 local attachment=Instance.new("Attachment")attachment.Name="LanternLightOrigin"
 attachment.CFrame=mesh.CFrame:ToObjectSpace(CFrame.new(-size.X*.28,size.Y*.62,0))attachment.Parent=mesh
 local light=Instance.new("PointLight")light.Name="WarmLanternLight"light.Enabled=false light.Shadows=false light.Range=14 light.Brightness=1.1 light.Color=Color3.fromRGB(255,210,151)light.Parent=attachment
 local folder=world.Amenities.Lanterns folder:ClearAllChildren()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
 local report={lamps=0,sourceAssetId=assetId,sourceFile="sei-la-sksksks.fbx",meshesPerLamp=meshCount,height=10.5}
 local points={}
 for z=-260,280,45 do points[#points+1]=Vector2.new(Scene.pathX(z)+7,z)points[#points+1]=Vector2.new(145+30*math.sin(z/100)-7,z+9)end
 local lake=world:GetAttribute("CentralLake")for i=0,5 do local a=i*math.pi/3 points[#points+1]=Vector2.new(lake.X+math.cos(a)*88,lake.Z+math.sin(a)*66)end
 for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do for _,key in ipairs({"DeckStart","DeckEnd"})do local p=bridge:GetAttribute(key)points[#points+1]=Vector2.new(p.X,p.Z+8)end end
 for _,point in ipairs(points)do local hit=ground(point.X,point.Y)
  if hit and hit.Position.Y>7.4 and hit.Normal.Y>.83 then
   local m=template:Clone()m.Name="GnarledLanternPost"m:SetAttribute("SourceAssetId",assetId)m:SetAttribute("SourceFBXSHA256","02d7d43c417d633c908243ad34ca44599936876ce0a2b32926b7dc14f1012688")m:SetAttribute("GroundPoint",hit.Position)m:PivotTo(CFrame.new(hit.Position-Vector3.yAxis*.25))m.Parent=folder m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=false p.CanCollide=p:IsA("MeshPart")p.CanQuery=p.CanCollide p.CastShadow=p:IsA("MeshPart")
    elseif p:IsA("Light")then p.Enabled=false p.Shadows=false p.Range=14 p.Brightness=1.1 p.Color=Color3.fromRGB(255,210,151)C:AddTag(p,"ForestNightLight")
    elseif p:IsA("Fire")or p:IsA("Smoke")or p:IsA("ParticleEmitter")then p:Destroy()end
   end
   report.lamps+=1
  end
 end
 raw:Destroy()assert(report.lamps>=18,"Insufficient grounded lamp posts")world:SetAttribute("CandleLampCount",report.lamps)world:SetAttribute("LampAssetId",assetId)
 return report
end
return B
