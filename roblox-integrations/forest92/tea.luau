local B={}
function B.install()
 local world=workspace.ForestWorld local runtime=game.ReplicatedStorage.ForestRuntime local C=game:GetService("CollectionService")
 local reference=world.Amenities.ForestRuins.TeaCorner
 local chairTemplate=assert(reference:FindFirstChild("AntiqueTeaChair")):Clone()
 local cupTemplate=assert(reference:FindFirstChild("TeaCup")):Clone()
 local potTemplate=assert(reference:FindFirstChild("Teapot")):Clone()
 local targets={}
 for _,p in ipairs(C:GetTagged("TreeWorldTeaPrompt"))do if p:IsDescendantOf(world)then local corner=p.Parent.Parent.Parent if corner:FindFirstChild("AntiqueTeaTable")then targets[#targets+1]=corner end end end
 local report={tables=0,seats=0,cups=0}
 local function P(parent,name,size,cf,col,mat)
  local p=Instance.new("Part")p.Name=name p.Size=size p.CFrame=cf p.Color=col p.Material=mat or Enum.Material.SmoothPlastic p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Parent=parent return p
 end
 local function bottom(model)local low=math.huge for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then local h=(math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)*.5 low=math.min(low,p.Position.Y-h)end end return low end
 local function tabletop(table)local p=assert(table:FindFirstChild("table",true))return p.Position.Y+(math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)*.5 end
 for _,old in ipairs(targets)do
  local native=old.AntiqueTeaTable:Clone()local base=old.AntiqueTeaTable:GetPivot().Position local parent=old.Parent local name=old.Name
  local _,size=native:GetBoundingBox()native:ScaleTo(native:GetScale()*5.6/math.max(size.X,size.Z))native:PivotTo(CFrame.new(base))native:PivotTo(native:GetPivot()+Vector3.yAxis*(base.Y-bottom(native)))
  local corner=Instance.new("Model")corner.Name=name corner.Parent=parent native.Name="AntiqueTeaTable"native.Parent=corner native:SetAttribute("CompactTable",true)
  local top=tabletop(native)
  -- Imported cloth and ornaments are kept in proportion to a normal seated avatar.
  for _,p in ipairs(native:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true p.CanCollide=p.Name=="table"p.CanQuery=p.CanCollide p.CanTouch=false end end
  for i=0,3 do local angle=i*math.pi*.5 local position=base+Vector3.new(math.cos(angle)*3.8,0,math.sin(angle)*3.8)
   local chair=chairTemplate:Clone()chair:PivotTo(CFrame.lookAt(position,Vector3.new(base.X,position.Y,base.Z)))chair:PivotTo(chair:GetPivot()+Vector3.yAxis*(base.Y-bottom(chair)))chair.Parent=corner
   local seat=assert(chair:FindFirstChild("TeaSeat",true))
   local link=seat:FindFirstChild("TeaPrompt")if link then link:Destroy()end
   seat.CanTouch=false seat.CanCollide=false seat.Transparency=1 C:AddTag(seat,"RuinSeat")
   local prompt=seat:FindFirstChild("SitPrompt")prompt.ActionText="Sentar"prompt.ObjectText="Cadeira"report.seats+=1
   local cup=cupTemplate:Clone()cup.Name="TeaCup"cup:PivotTo(CFrame.new(base.X+math.cos(angle)*1.7,top+.025,base.Z+math.sin(angle)*1.7)*CFrame.Angles(0,-angle,0))cup:PivotTo(cup:GetPivot()+Vector3.yAxis*(top+.035-bottom(cup)))cup.Parent=corner
   for _,p in ipairs(cup:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=true p.CanCollide=false p.CanTouch=false end end
   local click=Instance.new("ClickDetector")click.Name="TakeCup"click.MaxActivationDistance=9 click.Parent=cup C:AddTag(click,"TreeWorldCupClick")report.cups+=1
  end
  local pot=potTemplate:Clone()local oldPrompt=pot:FindFirstChild("ServeTea",true)if oldPrompt then oldPrompt:Destroy()end
  pot:PivotTo(CFrame.new(base.X,top,base.Z))pot:PivotTo(pot:GetPivot()+Vector3.yAxis*(top+.03-bottom(pot)))pot.Parent=corner
  for _,p in ipairs(pot:GetDescendants())do if p:IsA("BasePart")then p.CanQuery=false end end
  -- Two slim utensils and a small dessert plate; no enlarged props floating above the table.
  local plate=P(corner,"DessertPlate",Vector3.new(.07,.85,.85),CFrame.new(base.X,top+.06,base.Z-1.3)*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(233,220,194))plate.Shape=Enum.PartType.Cylinder
  for j=0,2 do local cookie=P(corner,"Cookie",Vector3.new(.06,.28,.28),CFrame.new(base.X+(j-1)*.2,top+.12,base.Z-1.3)*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(188,139,93))cookie.Shape=Enum.PartType.Cylinder end
  for _,s in ipairs({-1,1})do P(corner,"SilverSpoon",Vector3.new(.055,.025,.55),CFrame.new(base.X+s*1.6,top+.04,base.Z-.55),Color3.fromRGB(179,186,182),Enum.Material.Metal)end
  corner:SetAttribute("TeaTable",true)corner:SetAttribute("FloorY",base.Y)corner:SetAttribute("TableTopY",top)report.tables+=1 old:Destroy()
 end
 chairTemplate:Destroy()cupTemplate:Destroy()potTemplate:Destroy()
 local remote=runtime:FindFirstChild("RuinInteraction")if remote then remote:Destroy()end
 return report
end
return B
