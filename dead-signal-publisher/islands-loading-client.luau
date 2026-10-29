while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
-- Real world/stream readiness, no fake progress bar or forced minimum delay.
local Players=game:GetService('Players');local RF=game:GetService('ReplicatedFirst')
local Tween=game:GetService('TweenService');local W=workspace
local player=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='IslandLoading';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=2000
local frame=Instance.new('Frame');frame.Size=UDim2.fromScale(1,1);frame.BackgroundColor3=Color3.fromRGB(8,12,20);frame.BorderSizePixel=0;frame.Parent=gui
local text=Instance.new('TextLabel');text.AnchorPoint=Vector2.new(.5,.5);text.Position=UDim2.fromScale(.5,.5);text.Size=UDim2.new(.85,0,0,70);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(210,220,235);text.Font=Enum.Font.Gotham;text.TextSize=18;text.TextWrapped=true;text.Text='Carregando o mundo…';text.Parent=frame
-- ReplicatedFirst can run before PlayerGui is present.
gui.Parent=player:WaitForChild('PlayerGui');RF:RemoveDefaultLoadingScreen()
local shown=true;local serial=0;local requested=false
local function show(message)
 serial+=1;shown=true;frame.Visible=true;frame.BackgroundTransparency=0;text.TextTransparency=0;text.Text=message
end
local function hide()
 if not shown then return end;shown=false;serial+=1;local ticket=serial
 Tween:Create(frame,TweenInfo.new(.35),{BackgroundTransparency=1}):Play();Tween:Create(text,TweenInfo.new(.3),{TextTransparency=1}):Play()
 task.delay(.36,function() if serial==ticket and not shown then frame.Visible=false end end)
end
player:GetAttributeChangedSignal('IslandTravelPending'):Connect(function() if player:GetAttribute('IslandTravelPending') then show('Carregando destino…');requested=false end end)
player.CharacterAdded:Connect(function() show('Preparando sua chegada…');requested=false end)
while gui.Parent do
 local errorText=W:GetAttribute('IslandWorldError')
 local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart')
 if errorText then if text.Text~='O mundo não carregou. Tenta reconectar.' then show('O mundo não carregou. Tenta reconectar.') end
 elseif W:GetAttribute('IslandWorldReady')~=true then
  if not shown then show('Carregando o mundo…') end
 elseif player:GetAttribute('IslandTravelPending') then
  if not shown then show('Carregando destino…') end
 elseif root then
  if not requested then requested=true;task.spawn(function() pcall(function() player:RequestStreamAroundAsync(root.Position,8) end) end) end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
  local islands=W:FindFirstChild('Islands');params.FilterDescendantsInstances=islands and {W.Terrain,islands} or {W.Terrain};params.IgnoreWater=true
  local floor=W:Raycast(root.Position+Vector3.new(0,1,0),Vector3.new(0,-18,0),params)
  if floor and not root.Anchored and not player.GameplayPaused then hide()
  elseif not shown and player.GameplayPaused then show('Carregando arredores…') end
 end
 task.wait(.2)
end
