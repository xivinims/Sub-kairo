local B={}
function B.install()
 local C=game:GetService("CollectionService")local world=workspace.ForestWorld local count=0
 local function part(parent,name,size,cf,col,mat,shape)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=col p.Material=mat or Enum.Material.SmoothPlastic p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=parent if shape then p.Shape=shape end return p
 end
 for _,prompt in ipairs(C:GetTagged("TreeWorldTeaPrompt"))do if prompt:IsDescendantOf(world)then
  local corner=prompt.Parent.Parent.Parent local table=corner:FindFirstChild("AntiqueTeaTable")
  if table then
   local surface=table:FindFirstChild("tablecover",true)or table:FindFirstChild("table",true)local top=surface.Position.Y+surface.Size.Y*.5 local center=table:GetPivot().Position
   for _,d in ipairs(table:GetDescendants())do if d:IsA("BasePart")then if d.Name=="tablecover"then d.Color=Color3.fromRGB(230,218,202)elseif d.Name=="table"then d.Color=Color3.fromRGB(172,139,108)end end end
   -- Scalloped ceramic cake stand and strawberries, plus individual silver utensils.
   local cf=CFrame.new(center.X+1.7,top+.06,center.Z+.85)
   part(corner,"CakePlate",Vector3.new(.1,1.1,1.1),cf*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(245,237,221),nil,Enum.PartType.Cylinder)
   local cake=part(corner,"StrawberryCake",Vector3.new(.72,.46,.82),cf*CFrame.new(0,.28,0),Color3.fromRGB(242,219,190))
   part(corner,"CakeCream",Vector3.new(.76,.12,.86),cf*CFrame.new(0,.54,0),Color3.fromRGB(250,244,226))
   for _,x in ipairs({-.18,.18})do part(corner,"Strawberry",Vector3.new(.22,.24,.22),cf*CFrame.new(x,.68,0),Color3.fromRGB(210,79,83),nil,Enum.PartType.Ball)end
   for _,s in ipairs({-1,1})do for j=1,2 do
    local u=CFrame.new(center.X+s*1.75,top+.045,center.Z+j*.42-1.5)
    part(corner,"SilverSpoonStem",Vector3.new(.06,.03,.48),u,Color3.fromRGB(195,200,198),Enum.Material.Metal)
    part(corner,"SilverSpoonBowl",Vector3.new(.18,.035,.25),u*CFrame.new(0,0,-.3),Color3.fromRGB(195,200,198),Enum.Material.Metal,Enum.PartType.Ball)
   end end
   -- The existing native carved chairs keep their authored backs and seats.
   for _,chair in ipairs(corner:GetChildren())do if chair.Name=="AntiqueTeaChair"then for _,p in ipairs(chair:GetDescendants())do if p:IsA("BasePart")and p.Transparency==0 then p.Color=p.Name:find("Cushion")and Color3.fromRGB(204,172,176)or Color3.fromRGB(170,138,105)end end end end
   -- One open-air parasol recalls the garden tea reference; indoor table remains uncovered.
   if not corner:IsDescendantOf(world.Amenities.RiversideGarden)and count==1 then
    local y=top+7
    part(corner,"GardenParasolPole",Vector3.new(.12,7,.12),CFrame.new(center.X,(top+y)*.5,center.Z),Color3.fromRGB(218,198,174),Enum.Material.Wood)
    for i=0,15 do local a=i*math.pi*2/16 local radial=Vector3.new(math.cos(a)*2,y- .4,math.sin(a)*2)
     part(corner,"GardenParasolPanel",Vector3.new(1.65,.12,4.2),CFrame.new(Vector3.new(center.X,0,center.Z)+radial)*CFrame.Angles(0,math.pi*.5-a,0)*CFrame.Angles(math.rad(11),0,0),i%2==0 and Color3.fromRGB(219,196,174)or Color3.fromRGB(233,216,191),Enum.Material.Fabric)
    end
   end
   count+=1
  end
 end end
 return{detailedTeaTables=count}
end
return B
