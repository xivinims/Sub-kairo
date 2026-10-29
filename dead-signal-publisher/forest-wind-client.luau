-- Integrates audited WindShake / WindLines from user asset 11946229834.
-- Original modules: boatbomber and CloneTrooper1019; demo UI intentionally omitted.
local W=workspace
local UIS=game:GetService("UserInputService")
local Shake=require(script.WindShake)
local Lines=require(script.WindLines)
while not W.CurrentCamera do W:GetPropertyChangedSignal("CurrentCamera"):Wait() end
Shake:SetDefaultSettings({WindDirection=Vector3.new(1,0,.3),WindSpeed=10,WindPower=.28})
Shake:Init()
Lines:Init({Direction=Vector3.new(1,0,.3),Speed=9,Lifetime=1.4,SpawnRate=UIS.TouchEnabled and 1.5 or 3})
local function mount(p)
 if not p:IsA("BasePart") or p.Name=="TreeCollisionTrunk" then return end
 if p:GetAttribute("IslandWind") then Shake:AddObjectShake(p,{WindPower=.28});return end
 local model=p.Parent
 if not model or not model:IsA("Model") then return end
 local tree=model:GetAttribute("ForestSpecies")~=nil
 local flower=model:GetAttribute("FoliageType")=="Wildflower"
 if tree then
  local smallest=math.min(p.Size.X,p.Size.Y,p.Size.Z)
  local name=string.lower(p.Name)
  if smallest<3 and not string.find(name,"leaf") and not string.find(name,"foliage") then return end
 elseif flower then
  local index=tonumber(model.Name:match("(%d+)$")) or 0
  if index%6~=0 then return end
 else return end
 local root=model:FindFirstChild("TreeCollisionTrunk")
 if root then
  local base=Vector3.new(root.Position.X,root.Position.Y-root.Size.Y*.5,root.Position.Z)
  p.PivotOffset=p.CFrame:ToObjectSpace(CFrame.new(base))
 end
 Shake:AddObjectShake(p,{WindPower=tree and .12 or .3})
end
for _,p in ipairs(W:GetDescendants()) do mount(p) end
W.DescendantAdded:Connect(function(p) if p:IsA("BasePart") then task.defer(mount,p) end end)
W.DescendantRemoving:Connect(function(p) if Shake.ObjectMetadata[p] then Shake:RemoveObjectShake(p) end end)
local function windChanged()
 local wind=W.GlobalWind
 local speed=wind.Magnitude
 local direction=speed>.05 and wind.Unit or Vector3.new(1,0,0)
 Lines.Direction=direction;Lines.Speed=math.clamp(speed*1.5+4,6,20)
 Shake:UpdateAllObjectSettings({WindDirection=direction,WindSpeed=math.clamp(speed*2+4,6,24)})
end
W:GetPropertyChangedSignal("GlobalWind"):Connect(windChanged)
windChanged()
