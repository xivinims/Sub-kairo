local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local Collection=game:GetService('CollectionService')
local Run=game:GetService('RunService')
local Content=game:GetService('ContentProvider')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
local package=RS:WaitForChild('MysteryInterface')
local remote=RS:WaitForChild('MysteryUIAction')
local active={HUD=true,Screenspace_Vignette=true,OnItemIndicator2=true}
for name in pairs(active) do
 local prior=pg:FindFirstChild(name)
 if prior then prior:Destroy() end
 local screen=package:WaitForChild(name):Clone()
 screen.Enabled=name~='OnItemIndicator2';screen.ResetOnSpawn=false;screen.Parent=pg
end
local hud=pg:WaitForChild('HUD')
local frame=hud:WaitForChild('Frame')
local lamp=frame:WaitForChild('HeadlampButton')
local action=frame:WaitForChild('GrabReleaseButton')
local indicator=pg:WaitForChild('OnItemIndicator2')
local counter=frame:FindFirstChild('MissionCounterText')
if counter then counter.Visible=false end
lamp.Visible=true;lamp.Active=true;lamp.Selectable=true
action.Visible=true;action.Selectable=true
local function setLabel(button,text)
 local label=button:FindFirstChildWhichIsA('TextLabel',true)
 if label then label.Text=text end
end
setLabel(lamp,Input.TouchEnabled and 'Lanterna' or 'Lanterna (U)')
local target
local function available() return player:GetAttribute('InterfaceOpen')~=true and workspace:GetAttribute('WorldReady')==true end
local function useLamp() if available() then remote:FireServer('lamp') end end
local function interact() if available() and target then remote:FireServer('interact',target) end end
lamp.Activated:Connect(useLamp)
action.Activated:Connect(interact)
Input.InputBegan:Connect(function(input,processed)
 if processed or Input:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.U then useLamp()
 elseif input.KeyCode==Enum.KeyCode.P then interact() end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.12 then return end;elapsed=0
 target=nil
 local character=player.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 local camera=workspace.CurrentCamera
 local best=math.huge
 if root and camera and available() then
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character};params.RespectCanCollide=true
  for _,candidate in ipairs(Collection:GetTagged('StillHereInteractable')) do
   local host=candidate:FindFirstChild('Hitbox') or candidate.PrimaryPart
   if host and host:IsDescendantOf(workspace) then
    local distance=(host.Position-root.Position).Magnitude
    local screen,onScreen=camera:WorldToViewportPoint(host.Position)
    if distance<=8 and onScreen and screen.Z>0 then
     local hit=workspace:Raycast(root.Position,host.Position-root.Position,params)
     if not hit or hit.Instance:IsDescendantOf(candidate) then
      local score=(Vector2.new(screen.X,screen.Y)-camera.ViewportSize/2).Magnitude+distance*5
      if score<best then best=score;target=candidate end
     end
    end
   end
  end
 end
 action.Active=target~=nil;action.AutoButtonColor=target~=nil
 action.ImageTransparency=target and 0 or .55
 indicator.Enabled=target~=nil
 local label=target and (target:GetAttribute('IsOpen') and 'Fechar' or 'Abrir') or 'Interagir'
 setLabel(action,label..(Input.TouchEnabled and '' or ' (P)'))
end)
player.CameraMode=Enum.CameraMode.Classic
player.CameraMinZoomDistance=8
player.CameraMaxZoomDistance=18
if not game:IsLoaded() then game.Loaded:Wait() end
while not workspace:GetAttribute('WorldReady') do task.wait(.1) end
local character=player.Character or player.CharacterAdded:Wait()
local root=character:WaitForChild('HumanoidRootPart')
pcall(function() player:RequestStreamAroundAsync(root.Position,15) end)
pcall(function() Content:PreloadAsync({hud,indicator}) end)
player:SetAttribute('ArrivalReady',true)
