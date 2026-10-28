-- Environmental activation only. No menu, HUD, inventory or other UI is created by this pass.
local Tags=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local lights={}
for _,l in ipairs(Tags:GetTagged("DeadSignalMapLight")) do lights[l]=true end
Tags:GetInstanceAddedSignal("DeadSignalMapLight"):Connect(function(l) lights[l]=true end)
Tags:GetInstanceRemovedSignal("DeadSignalMapLight"):Connect(function(l) lights[l]=nil end)
local fans={}
local function addFan(model) fans[model]=model:GetPivot() end
for _,model in ipairs(Tags:GetTagged("DeadSignalMapFan")) do addFan(model) end
Tags:GetInstanceAddedSignal("DeadSignalMapFan"):Connect(addFan)
Tags:GetInstanceRemovedSignal("DeadSignalMapFan"):Connect(function(model) fans[model]=nil end)
local fanBudget=0
RunService.RenderStepped:Connect(function(dt)
 fanBudget+=dt; if fanBudget<0.05 then return end; fanBudget=0
 local camera=workspace.CurrentCamera; if not camera then return end
 for model,cf in pairs(fans) do
  if model.Parent and (cf.Position-camera.CFrame.Position).Magnitude<70 and workspace:GetAttribute("Sector_"..model:GetAttribute("SectorId"))~=false then
   model:PivotTo(cf*CFrame.Angles(0,0,workspace:GetServerTimeNow()*2.4))
  end
 end
end)
local budget=0
RunService.Heartbeat:Connect(function(dt)
 budget+=dt; if budget<0.3 then return end; budget=0
 local camera=workspace.CurrentCamera; if not camera then return end
 local nearby={}
 for l in pairs(lights) do
  local p=l.Parent
  if p then
   local position=p:IsA("Attachment") and p.WorldPosition or p:IsA("BasePart") and p.Position
   local distance=position and (position-camera.CFrame.Position).Magnitude or math.huge
   local sector=l:GetAttribute("SectorId") or "PARK"
   local on=workspace:GetAttribute("Sector_"..sector)
   l.Enabled=on~=false and distance<115
   l.Shadows=false
   if l.Enabled then table.insert(nearby,{light=l,distance=distance}) end
  end
 end
 table.sort(nearby,function(a,b) return a.distance<b.distance end)
 for i=1,math.min(4,#nearby) do nearby[i].light.Shadows=nearby[i].distance<35 end
end)
