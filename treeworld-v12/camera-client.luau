-- The normal Roblox camera owns rotation, zoom and touch input. This script
-- repairs stale menu/respawn ownership; it never drives CFrame every frame.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local player=Players.LocalPlayer
local cameraConnections={};local controls=nil;local generation=0
local function humanoid()
 local char=player.Character
 return char and char:FindFirstChildOfClass('Humanoid'),char and char:FindFirstChild('HumanoidRootPart')
end
local function restore(reposition)
 local hum,root=humanoid();local camera=workspace.CurrentCamera
 if not camera or not hum or not root or hum.Health<=0 then return end
 local invalid=camera.CameraType~=Enum.CameraType.Custom or camera.CameraSubject~=hum
 if invalid then camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=hum end
 if player.CameraMode~=Enum.CameraMode.Classic then player.CameraMode=Enum.CameraMode.Classic end
 if player.CameraMaxZoomDistance<12 then player.CameraMaxZoomDistance=24 end
 if player.CameraMinZoomDistance>1 then player.CameraMinZoomDistance=.5 end
 if invalid then Input.MouseBehavior=Enum.MouseBehavior.Default;Input.MouseIconEnabled=true end
 if reposition and(camera.CFrame.Position-root.Position).Magnitude>80 then
  local target=root.Position+Vector3.new(0,2,0)
  camera.CFrame=CFrame.lookAt(target-root.CFrame.LookVector*12+Vector3.new(0,4,0),target)
 end
end
local repairing=false
local function repairSoon()
 if repairing then return end;repairing=true
 task.defer(function()restore(false);repairing=false end)
end
local function bindCamera()
 for _,connection in ipairs(cameraConnections)do connection:Disconnect()end;table.clear(cameraConnections)
 local camera=workspace.CurrentCamera;if not camera then return end
 table.insert(cameraConnections,camera:GetPropertyChangedSignal('CameraType'):Connect(repairSoon))
 table.insert(cameraConnections,camera:GetPropertyChangedSignal('CameraSubject'):Connect(repairSoon))
 restore(true)
end
local function spawned(char)
 generation+=1;local token=generation
 task.spawn(function()
  local hum=char:WaitForChild('Humanoid',20);local root=char:WaitForChild('HumanoidRootPart',20)
  if not hum or not root or token~=generation or player.Character~=char then return end
  player.CameraMode=Enum.CameraMode.Classic;player.CameraMinZoomDistance=.5;player.CameraMaxZoomDistance=24
  restore(true)
  if controls then controls:Enable()end
 end)
end
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(bindCamera)
player.CharacterAdded:Connect(spawned)
bindCamera();if player.Character then spawned(player.Character)end
task.spawn(function()
 local module=player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule',20)
 if module then local ok,result=pcall(require,module);if ok then controls=result:GetControls();controls:Enable();restore(true)end end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.75 then return end;elapsed=0
 local hum=humanoid();local camera=workspace.CurrentCamera
 if hum and hum.Health>0 and camera and(camera.CameraType~=Enum.CameraType.Custom or camera.CameraSubject~=hum)then restore(false)end
end)
