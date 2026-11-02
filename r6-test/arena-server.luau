-- Integration only. Imported pack sources are not edited.
local Players=game:GetService('Players')
local Storage=game:GetService('ServerStorage')
local RunService=game:GetService('RunService')
local bots=workspace:WaitForChild('TrainingBots')
local function hook(bot)
 local hum=bot:WaitForChild('Humanoid');local home=bot:GetPivot();local index=bot:GetAttribute('BotIndex')
 assert(hum.RigType==Enum.HumanoidRigType.R6)
 hum.Died:Once(function()
  task.delay(5,function()
   bot:Destroy();local fresh=Storage.R6BotTemplate:Clone();fresh.Name='Bot '..index;fresh:SetAttribute('TrainingBot',true);fresh:SetAttribute('BotIndex',index)
   fresh.Humanoid.MaxHealth=100;fresh.Humanoid.Health=100;fresh.Humanoid.DisplayName='ALVO '..index;fresh.Humanoid.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOn
   fresh:PivotTo(home);fresh.Parent=bots;hook(fresh)
  end)
 end)
end
for _,bot in ipairs(bots:GetChildren()) do hook(bot) end
local function playerAdded(player)
 player.CharacterAdded:Connect(function(char)
  local hum=char:WaitForChild('Humanoid');assert(hum.RigType==Enum.HumanoidRigType.R6,'R6 required')
 end)
end
Players.PlayerAdded:Connect(playerAdded);for _,p in ipairs(Players:GetPlayers()) do playerAdded(p) end
-- The original bow moves anchored arrows using CFrame. A swept ray handles
-- stationary targets without relying on physics Touched events for teleports.
local arrows={}
workspace.Debris.ChildAdded:Connect(function(arrow)
 if not arrow:IsA('BasePart') then return end
 task.defer(function()
  if not arrow.Parent then return end
  arrow.CanTouch=false -- one collision authority; original source stays byte-identical
  local exclude={workspace.Debris}
  for _,p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(exclude,p.Character) end end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=exclude
  arrows[arrow]={position=arrow.Position,params=params,created=os.clock()}
 end)
end)
RunService.Heartbeat:Connect(function()
 for arrow,data in pairs(arrows) do
  if not arrow.Parent then arrows[arrow]=nil;continue end
  local delta=arrow.Position-data.position
  local hit=delta.Magnitude>0.001 and workspace:Raycast(data.position,delta,data.params)
  if hit then
   local model=hit.Instance:FindFirstAncestorOfClass('Model');local hum=model and model:FindFirstChildOfClass('Humanoid')
   if hum and model:GetAttribute('TrainingBot') and hum.Health>0 then hum:TakeDamage(15) end
   arrows[arrow]=nil;arrow:Destroy()
  elseif os.clock()-data.created>5.5 then arrows[arrow]=nil;arrow:Destroy()
  else data.position=arrow.Position end
 end
end)
