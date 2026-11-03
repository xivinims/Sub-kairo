local B={}
function B.install()
 local runtime=game.ReplicatedStorage.ForestRuntime
 local tool=Instance.new("Tool")tool.Name="Guarda-chuva"tool.RequiresHandle=false tool.CanBeDropped=false tool:SetAttribute("RainUmbrella",true)
 local function p(name,size,cf,color,shape)
  local part=Instance.new("Part")part.Name=name part.Size=size part.CFrame=cf part.Color=color part.Material=Enum.Material.SmoothPlastic part.Anchored=false part.Massless=true part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Parent=tool if shape then part.Shape=shape end return part
 end
 local handle=p("UmbrellaAnchor",Vector3.new(.2,.2,.2),CFrame.identity,Color3.fromRGB(232,209,198))handle.Transparency=1
 local shaft=p("UmbrellaShaft",Vector3.new(.09,3.2,.09),CFrame.new(0,1.6,0),Color3.fromRGB(231,218,205))
 -- Overlapping radial panels form a compact pastel domed canopy, with scalloped tips.
 for i=0,15 do local a=i*math.pi*2/16 local col=i%2==0 and Color3.fromRGB(218,176,190)or Color3.fromRGB(244,224,214)
  p("CanopyPanel",Vector3.new(1.04,.16,2.65),CFrame.new(math.cos(a)*1.3,2.95,math.sin(a)*1.3)*CFrame.Angles(0,-a+math.pi*.5,math.rad(0))*CFrame.Angles(math.rad(11),0,0),col)
  local edge=p("ScallopedEdge",Vector3.new(.42,.18,.42),CFrame.new(math.cos(a)*2.55,2.68,math.sin(a)*2.55),col,Enum.PartType.Ball)
 end
 p("CanopyCrown",Vector3.new(.55,.28,.55),CFrame.new(0,3.22,0),Color3.fromRGB(244,224,214),Enum.PartType.Ball)
 for _,d in ipairs(tool:GetChildren())do if d:IsA("BasePart")and d~=handle then local w=Instance.new("WeldConstraint")w.Part0=handle w.Part1=d w.Parent=d end end
 tool.Parent=runtime tool.Name="UmbrellaTool"
 return{umbrellaParts=35}
end
return B
