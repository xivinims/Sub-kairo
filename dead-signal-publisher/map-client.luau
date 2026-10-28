-- Environmental activation only. No menu, HUD, inventory or other UI is created by this pass.
local Tags=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local lights={}
local function addLight(l)
 local p=l.Parent
 lights[l]={colour=p and p:IsA("BasePart") and p.Color or Color3.new(1,1,1)}
end
for _,l in ipairs(Tags:GetTagged("DeadSignalMapLight")) do addLight(l) end
Tags:GetInstanceAddedSignal("DeadSignalMapLight"):Connect(addLight)
Tags:GetInstanceRemovedSignal("DeadSignalMapLight"):Connect(function(l) lights[l]=nil end)
local fans={}
local function addFan(model) fans[model]={cf=model:GetPivot(),phase=0,speed=0} end
for _,model in ipairs(Tags:GetTagged("DeadSignalMapFan")) do addFan(model) end
Tags:GetInstanceAddedSignal("DeadSignalMapFan"):Connect(addFan)
Tags:GetInstanceRemovedSignal("DeadSignalMapFan"):Connect(function(model) fans[model]=nil end)
local fanBudget=0
RunService.RenderStepped:Connect(function(dt)
 fanBudget+=dt; if fanBudget<0.05 then return end; local step=fanBudget;fanBudget=0
 local camera=workspace.CurrentCamera; if not camera then return end
 for model,fan in pairs(fans) do
  if model.Parent and (fan.cf.Position-camera.CFrame.Position).Magnitude<70 then
   local on=workspace:GetAttribute("Sector_"..model:GetAttribute("SectorId"))==true
   fan.speed=fan.speed+((on and 2.4 or 0)-fan.speed)*(1-math.exp(-step*2.6))
   fan.phase=(fan.phase+fan.speed*math.min(step,0.1))%(math.pi*2)
   model:PivotTo(fan.cf*CFrame.Angles(0,0,fan.phase))
  end
 end
end)
local budget=0
RunService.Heartbeat:Connect(function(dt)
 budget+=dt; if budget<0.3 then return end; budget=0
 local camera=workspace.CurrentCamera; if not camera then return end
 local nearby={}
 for l,data in pairs(lights) do
  local p=l.Parent
  if p then
   local position=p:IsA("Attachment") and p.WorldPosition or p:IsA("BasePart") and p.Position
   local distance=position and (position-camera.CFrame.Position).Magnitude or math.huge
   local sector=l:GetAttribute("SectorId") or "PARK"
   local on=workspace:GetAttribute("Sector_"..sector)
   l.Enabled=on==true and distance<115
   if p:IsA("BasePart") and p.Name=="LightDiffuser" then
    p.Material=on==true and Enum.Material.Neon or Enum.Material.SmoothPlastic
    p.Color=on==true and data.colour or data.colour:Lerp(Color3.new(0,0,0),0.65)
   end
   l.Shadows=false
   if l.Enabled then table.insert(nearby,{light=l,distance=distance}) end
  end
 end
 table.sort(nearby,function(a,b) return a.distance<b.distance end)
 for i=1,math.min(4,#nearby) do nearby[i].light.Shadows=nearby[i].distance<35 end
end)
