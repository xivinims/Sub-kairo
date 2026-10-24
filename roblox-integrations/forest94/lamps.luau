local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local Scene=require(runtime.Scene)local C=game:GetService("CollectionService")
 local raw=game:GetService("AssetService"):LoadAssetAsync(11324928349)
 local template=assert(raw:FindFirstChildOfClass("Model"),"Requested lamp model missing")
 for _,d in ipairs(template:GetDescendants())do if d:IsA("LuaSourceContainer")or d:IsA("Camera")then d:Destroy()end end
 local pole
 for _,d in ipairs(template:GetDescendants())do if d:IsA("MeshPart")and d.MeshId=="rbxassetid://11161434042"then pole=d end end
 assert(pole,"Requested lamp post mesh missing")
 local base=pole.Position-Vector3.yAxis*pole.Size.Y*.5
 template:PivotTo(template:GetPivot()-base)template.PrimaryPart=nil template.WorldPivot=CFrame.identity template:ScaleTo(template:GetScale()*.67)
 local folder=world.Amenities.Lanterns folder:ClearAllChildren()
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function ground(x,z)return workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)end
 local report={lamps=0,sourceAssetId=11324928349}
 local points={}
 for z=-260,280,45 do points[#points+1]=Vector2.new(Scene.pathX(z)+7,z)points[#points+1]=Vector2.new(145+30*math.sin(z/100)-7,z+9)end
 local lake=world:GetAttribute("CentralLake")for i=0,5 do local a=i*math.pi/3 points[#points+1]=Vector2.new(lake.X+math.cos(a)*88,lake.Z+math.sin(a)*66)end
 for _,bridge in ipairs(world.Amenities.WoodenBridges:GetChildren())do for _,key in ipairs({"DeckStart","DeckEnd"})do local p=bridge:GetAttribute(key)points[#points+1]=Vector2.new(p.X,p.Z+8)end end
 for _,point in ipairs(points)do local hit=ground(point.X,point.Y)
  if hit and hit.Position.Y>7.4 and hit.Normal.Y>.83 then
   local m=template:Clone()m.Name="CandleLampPost"m:SetAttribute("SourceAssetId",11324928349)m:SetAttribute("GroundPoint",hit.Position)m:PivotTo(CFrame.new(hit.Position-Vector3.yAxis*.2))m.Parent=folder m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   for _,p in ipairs(m:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanTouch=false p.CanCollide=p:IsA("MeshPart")p.CanQuery=p.CanCollide p.CastShadow=p:IsA("MeshPart")
    elseif p:IsA("Light")then p.Enabled=false p.Shadows=false p.Range=14 p.Brightness=1.1 p.Color=Color3.fromRGB(255,210,151)C:AddTag(p,"ForestNightLight")
    elseif p:IsA("Fire")then p.Size=.25 p.Heat=0 C:AddTag(p,"RuinVFX")end
   end
   report.lamps+=1
  end
 end
 raw:Destroy()assert(report.lamps>=18,"Insufficient grounded lamp posts")world:SetAttribute("CandleLampCount",report.lamps)world:SetAttribute("LampAssetId",11324928349)
 return report
end
return B
