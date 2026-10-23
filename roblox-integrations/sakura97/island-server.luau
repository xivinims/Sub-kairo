local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local spawn=workspace:WaitForChild("IslandSpawn")
local event=RS:WaitForChild("SweanVoidEvent")
local runtime=RS:WaitForChild("SweanRuntime")
local threshold=runtime:GetAttribute("VoidThreshold")
local active={}
local function recover(player,record)
 if active[player]~=record then return end active[player]=nil
 local char=record.char local root=char:FindFirstChild("HumanoidRootPart") local hum=char:FindFirstChildOfClass("Humanoid")
 if char.Parent and root and player.Character==char then
  char:PivotTo(spawn.CFrame*CFrame.new(0,4,0))
  root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  root.Anchored=record.anchored
  if hum then hum.AutoRotate=record.autoRotate end
 end
 player:SetAttribute("VoidActive",false)
 if player.Parent then event:FireClient(player,"finish") end
end
event.OnServerEvent:Connect(function(player,action)
 local record=active[player]
 if action=="return" and record and os.clock()-record.started>=2 then recover(player,record) end
end)
local function hook(player)
 player.RespawnLocation=spawn
 player:SetAttribute("VoidActive",false)
 player.CharacterAdded:Connect(function()
  active[player]=nil player:SetAttribute("VoidActive",false)
  event:FireClient(player,"finish")
 end)
end
Players.PlayerAdded:Connect(hook)
Players.PlayerRemoving:Connect(function(p) active[p]=nil end)
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.1 then return end elapsed=0
 for _,player in ipairs(Players:GetPlayers()) do
  local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") local hum=char and char:FindFirstChildOfClass("Humanoid")
  if root and hum and hum.Health>0 and root.Position.Y<threshold and not active[player] then
   local record={started=os.clock(),char=char,anchored=root.Anchored,autoRotate=hum.AutoRotate}
   active[player]=record
   root.Anchored=true root.AssemblyLinearVelocity=Vector3.zero hum.AutoRotate=false
   player:SetAttribute("VoidActive",true)
   event:FireClient(player,"start")
   -- Server-owned timer: a missing client or a forged response cannot trap the player.
   task.delay(60,function() recover(player,record) end)
  end
 end
end)
