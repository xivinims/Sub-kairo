-- Lightweight R6 NPC patrols in the actual test arena (not the menu).
-- Server-run Humanoid:MoveTo; no per-frame loops or pathfinder spam.
local Players=game:GetService("Players")
local folder=workspace:WaitForChild("NPCWanderers")
local originalSpawns={}
for _,model in ipairs(folder:GetChildren()) do
 if model:IsA("Model") then originalSpawns[model.Name]=model:GetPivot() end
end
local function animate(model)
 local hum=model:FindFirstChildOfClass("Humanoid")
 local root=model:FindFirstChild("HumanoidRootPart")
 if not hum or not root then return end
 local animator=hum:FindFirstChildOfClass("Animator") or Instance.new("Animator",hum)
 local function getTrack(id)
  local animation=Instance.new("Animation")
  animation.Name="R6NPCMotion"
  animation.AnimationId="rbxassetid://"..tostring(id)
  local ok,track=pcall(function()return animator:LoadAnimation(animation)end)
  animation:Destroy()
  if ok and track then
   track.Priority=Enum.AnimationPriority.Movement
   track.Looped=true
   return track
  end
 end
 local idle=getTrack(180435571)
 local walk=getTrack(180426354)
 if idle then idle:Play(0.1) end
 local moving=false
 hum.Running:Connect(function(speed)
  if hum.Health<=0 then return end
  local now=speed>1.1
  if now==moving then return end
  moving=now
  if now then
   if idle then idle:Stop(0.2) end
   if walk then walk:Play(0.2);walk:AdjustSpeed(0.92) end
  else
   if walk then walk:Stop(0.2) end
   if idle then idle:Play(0.2) end
  end
 end)
 return hum,root
end
local function wander(model)
 local hum,root=animate(model)
 if not hum then return end
 local origin=originalSpawns[model.Name] or model:GetPivot()
 local rng=Random.new(271828+(tonumber(model:GetAttribute("NPCIndex")) or 1)*37)
 task.spawn(function()
  while model.Parent==folder and hum.Health>0 do
   local offset=Vector3.new(rng:NextNumber(-24,24),0,rng:NextNumber(-26,26))
   local destination=origin.Position+offset
   destination=Vector3.new(math.clamp(destination.X,-91,91),origin.Position.Y,
       math.clamp(destination.Z,-86,86))
   hum:MoveTo(destination)
   local success=hum.MoveToFinished:Wait()
   if not success and root and root.Parent then hum.Jump=true end
   task.wait(rng:NextNumber(0.4,1.5))
  end
 end)
 hum.Died:Once(function()
  task.delay(3,function()
   if not folder.Parent then return end
   local fresh=model:Clone()
   fresh:PivotTo(origin)
   fresh.Parent=folder
   model:Destroy()
   wander(fresh)
  end)
 end)
end
for _,model in ipairs(folder:GetChildren()) do
 if model:IsA("Model") then wander(model) end
end
