local B={}
function B.install()
 local C=game:GetService("CollectionService")local camps=workspace.ForestWorld.Amenities.SeasonalDetails.Camps
 local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={workspace.Terrain}ray.IgnoreWater=true
 local function floor(x,z)return assert(workspace:Raycast(Vector3.new(x,210,z),Vector3.yAxis*-310,ray)).Position end
 local function part(parent,name,size,cf,col,mat,collide)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=col p.Material=mat p.Anchored=true p.CanCollide=collide p.CanTouch=false p.CanQuery=collide p.Parent=parent return p
 end
 local report={camps=0,stones=0}
 for _,camp in ipairs(camps:GetChildren())do local core=camp:FindFirstChild("FireCore",true)
  if core then local center=floor(core.Position.X,core.Position.Z)core.CFrame=CFrame.new(center+Vector3.yAxis*.25)
   for _,p in ipairs(camp:GetDescendants())do if p.Name=="FireRingStone"or p.Name=="Firewood"then p:Destroy()end end
   local char=part(camp,"CharredGround",Vector3.new(.03,4.5,4.5),CFrame.new(center+Vector3.yAxis*.025)*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(55,48,37),Enum.Material.Slate,false)char.Shape=Enum.PartType.Cylinder
   for i=0,11 do local a=i*math.pi/6 local gp=floor(center.X+math.cos(a)*2,center.Z+math.sin(a)*2)
    local p=part(camp,"GroundedFireStone",Vector3.new(.9,.6,.8),CFrame.new(gp+Vector3.yAxis*.18)*CFrame.Angles(.12,a,.1),Color3.fromRGB(116+(i%3)*6,114+(i%3)*6,104),Enum.Material.Slate,true)p:SetAttribute("GroundPoint",gp)report.stones+=1
   end
   for i=0,3 do local p=part(camp,"SplitFireLog",Vector3.new(2.8,.38,.42),CFrame.new(center+Vector3.yAxis*(.25+i*.075))*CFrame.Angles(0,i*math.pi/4,.08),Color3.fromRGB(91,68,46),Enum.Material.Wood,false)p.Shape=Enum.PartType.Cylinder end
   local fire=core:FindFirstChildOfClass("Fire")if fire then fire.Size=2.8 fire.Heat=4 C:AddTag(fire,"RuinVFX")end
   for i=0,7 do local a=i*math.pi/4 local gp=floor(center.X+math.cos(a)*2.8,center.Z+math.sin(a)*2.8)
    local ash=part(camp,"ScatteredAsh",Vector3.new(.25,.03,.2),CFrame.new(gp+Vector3.yAxis*.025),Color3.fromRGB(100,93,75),Enum.Material.Slate,false)
   end
   report.camps+=1
  end
 end
 return report
end
return B
