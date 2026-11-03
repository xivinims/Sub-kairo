-- One clear "PEGAR" button for original FPS weapon pickups.
-- Uses Roblox's own proximity/line-of-sight events and a server-validated request.
while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players')
local PPS=game:GetService('ProximityPromptService')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
local request=RS:WaitForChild('PickupWeaponRequest')
local folder=workspace:WaitForChild('WeaponToolsRespawn')
local gui=Instance.new('ScreenGui')
gui.Name='WeaponPickupControls';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false
gui.DisplayOrder=130;gui.Parent=player:WaitForChild('PlayerGui')
local button=Instance.new('TextButton')
button.Name='Pegar';button.Text='PEGAR';button.Visible=false;button.AutoButtonColor=true
button.Font=Enum.Font.GothamBold;button.TextSize=22
button.BackgroundColor3=Color3.fromRGB(22,34,40);button.TextColor3=Color3.fromRGB(239,245,246)
button.BackgroundTransparency=.12;button.BorderSizePixel=0
button.Size=UDim2.fromOffset(116,54);button.AnchorPoint=Vector2.new(.5,.5)
button.Position=UDim2.new(1,-325,1,-185)
button.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,12);corner.Parent=button
local stroke=Instance.new('UIStroke');stroke.Thickness=1.3;stroke.Color=Color3.fromRGB(150,186,197);stroke.Transparency=.45;stroke.Parent=button
local weaponName=Instance.new('TextLabel')
weaponName.Name='WeaponName';weaponName.Size=UDim2.new(1,0,0,24)
weaponName.Position=UDim2.new(0,0,0,-25)
weaponName.BackgroundTransparency=1;weaponName.Font=Enum.Font.GothamMedium
weaponName.TextSize=13;weaponName.TextColor3=Color3.fromRGB(225,230,232)
weaponName.Text='';weaponName.Parent=button
local currentPrompt
local currentTool
local elapsed=0
local lastClick=0

local function layout()
 local v=gui.AbsoluteSize
 if v.X<650 then
  button.Size=UDim2.fromOffset(94,48)
  button.Position=UDim2.new(.5,0,1,-135)
 else
  button.Size=UDim2.fromOffset(116,54)
  button.Position=UDim2.new(1,-325,1,-185)
 end
end
layout();gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)

local function clear(prompt)
 if prompt and currentPrompt~=prompt then return end
 currentPrompt=nil;currentTool=nil;button.Visible=false
end

local function findTool(prompt)
 if prompt.Name~='OriginalWeaponPickup' then return nil end
 local tool=prompt:FindFirstAncestorOfClass('Tool')
 if not tool or tool.Parent~=folder then return nil end
 if not tool:FindFirstChild('Weapon') then return nil end
 return tool
end

local function valid()
 if not currentPrompt or not currentTool then return false end
 if not currentPrompt.Parent or not currentPrompt.Enabled or currentTool.Parent~=folder then return false end
 if player:GetAttribute('InterfaceOpen') then return false end
 local char=player.Character
 local root=char and char:FindFirstChild('HumanoidRootPart')
 local humanoid=char and char:FindFirstChildOfClass('Humanoid')
 if not root or not humanoid or humanoid.Health<=0 then return false end
 return (root.Position-currentPrompt.Parent.Position).Magnitude<=8.5
end

PPS.PromptShown:Connect(function(prompt)
 local tool=findTool(prompt)
 if not tool or player:GetAttribute('InterfaceOpen') then return end
 currentPrompt=prompt;currentTool=tool
 weaponName.Text=tool:GetAttribute('PickupName') or prompt.ObjectText
 button.Visible=valid()
end)
PPS.PromptHidden:Connect(function(prompt) clear(prompt) end)

button.Activated:Connect(function()
 if not valid() or os.clock()-lastClick<.28 then return end
 lastClick=os.clock()
 local tool=currentTool
 clear()
 request:FireServer(tool)
end)
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.10 then return end;elapsed=0
 if currentTool then
  if not valid() then clear() end
 end
end)
