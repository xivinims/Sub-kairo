-- Preview player. Reads original animation objects without changing their data.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer
local gui = Instance.new('ScreenGui')
gui.Name = 'R6AnimationTest'; gui.ResetOnSpawn = false; gui.Parent = player:WaitForChild('PlayerGui')
local function button(text, parent)
 local b = Instance.new('TextButton'); b.Text = text; b.TextSize = 14; b.Font = Enum.Font.GothamMedium
 b.TextColor3 = Color3.new(1,1,1); b.BackgroundColor3 = Color3.fromRGB(44,48,56); b.BorderSizePixel = 0
 local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,12); c.Parent = b; b.Parent = parent; return b
end
local toggle = button('▶', gui); toggle.Size = UDim2.fromOffset(48,48); toggle.AnchorPoint = Vector2.new(1,0)
toggle.Position = UDim2.new(1,-18,0,65); toggle.UICorner.CornerRadius = UDim.new(1,0)
local panel = Instance.new('Frame'); panel.Name = 'Animations'; panel.Size = UDim2.new(0,270,.65,0)
panel.AnchorPoint = Vector2.new(1,0); panel.Position = UDim2.new(1,-18,0,120); panel.BackgroundColor3 = Color3.fromRGB(25,28,34)
panel.BorderSizePixel = 0; panel.Visible = false; panel.Parent = gui
Instance.new('UICorner',panel).CornerRadius = UDim.new(0,16)
local title = Instance.new('TextLabel'); title.Size = UDim2.new(1,-20,0,40); title.Position = UDim2.fromOffset(10,0)
title.BackgroundTransparency = 1; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamMedium; title.TextSize = 14
title.Text = 'Animações R6'; title.Parent = panel
local stopButton = button('Parar', panel); stopButton.Position = UDim2.new(0,10,1,-42); stopButton.Size = UDim2.new(1,-20,0,32)
local list = Instance.new('ScrollingFrame'); list.Position = UDim2.fromOffset(10,42); list.Size = UDim2.new(1,-20,1,-92)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 3; list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new(); list.Parent = panel
local layout = Instance.new('UIListLayout', list); layout.Padding = UDim.new(0,5)
local connection, track, activeCharacter, animate, oldAnimateEnabled
local savedMotors = {}
local function stop()
 if connection then connection:Disconnect(); connection = nil end
 if track then track:Stop(0); track:Destroy(); track = nil end
 for motor, transform in pairs(savedMotors) do if motor.Parent then motor.Transform = transform end end
 savedMotors = {}
 if animate and animate.Parent then animate.Enabled = oldAnimateEnabled end
 animate = nil; activeCharacter = nil; title.Text = 'Animações R6'
end
local function play(asset)
 stop()
 local char = player.Character; local hum = char and char:FindFirstChildOfClass('Humanoid')
 if not hum or hum.RigType ~= Enum.HumanoidRigType.R6 then title.Text = 'Aguardando avatar R6…'; return end
 activeCharacter = char
 animate = char:FindFirstChild('Animate')
 if animate then oldAnimateEnabled = animate.Enabled; animate.Enabled = false end
 local animator = hum:FindFirstChildOfClass('Animator')
 if not animator then stop(); return end
 for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop(0) end
 title.Text = asset.Name
 if asset:IsA('Animation') then
  local ok, result = pcall(animator.LoadAnimation, animator, asset)
  if not ok then stop(); title.Text = 'Falha: ID sem acesso ou incompatível'; warn(result); return end
  track = result; track.Priority = Enum.AnimationPriority.Action4; track.Looped = true; track:Play(.1)
  local selected = track
  task.delay(4, function() if track == selected and selected.Length == 0 then stop(); title.Text = 'ID indisponível para este jogo'; warn('Animation failed to load: '..asset:GetFullName()) end end)
 else
  local channels = {}; local duration = 0
  local frames = asset:GetKeyframes(); table.sort(frames,function(a,b) return a.Time < b.Time end)
  for _, frame in ipairs(frames) do
   duration = math.max(duration, frame.Time)
   for _, pose in ipairs(frame:GetDescendants()) do
    if pose:IsA('Pose') then
     channels[pose.Name] = channels[pose.Name] or {}
     table.insert(channels[pose.Name], {time=frame.Time, cf=pose.CFrame, weight=pose.Weight, style=pose.EasingStyle})
    end
   end
  end
  local motors = {}
  for _, motor in ipairs(char:GetDescendants()) do
   if motor:IsA('Motor6D') and motor.Part1 and channels[motor.Part1.Name] then
    motors[motor] = channels[motor.Part1.Name]; savedMotors[motor] = motor.Transform
   end
  end
  local started = os.clock()
  connection = RunService.PreSimulation:Connect(function()
   if not char.Parent or hum.Health <= 0 then stop(); return end
   local elapsed = os.clock()-started
   local t = duration > 0 and elapsed % duration or 0
   for motor, samples in pairs(motors) do
    local left = samples[1]; local right = left
    for _, sample in ipairs(samples) do
     if sample.time <= t then left = sample else right = sample; break end
     right = sample
    end
    local alpha = right.time > left.time and math.clamp((t-left.time)/(right.time-left.time),0,1) or 0
    if left.style == Enum.PoseEasingStyle.Constant then alpha = 0 end
    motor.Transform = CFrame.identity:Lerp(left.cf:Lerp(right.cf,alpha), left.weight+(right.weight-left.weight)*alpha)
   end
  end)
 end
end
local assets = {}
for _, root in ipairs({game.ReplicatedStorage:WaitForChild('R6AnimationCatalog'),game.ReplicatedStorage:WaitForChild('OriginalR6Emotes')}) do
 for _, asset in ipairs(root:GetDescendants()) do
  if asset:IsA('Animation') or asset:IsA('KeyframeSequence') then table.insert(assets,asset) end
 end
end
table.sort(assets,function(a,b) return a.Name < b.Name end)
for i, asset in ipairs(assets) do
 local b = button((asset:GetAttribute('SourcePack') and asset:GetAttribute('SourcePack')..' · ' or '')..asset.Name,list); b.Size = UDim2.new(1,-5,0,36); b.LayoutOrder = i
 b.Activated:Connect(function() play(asset) end)
end
stopButton.Activated:Connect(stop)
toggle.Activated:Connect(function() panel.Visible = not panel.Visible end)
UIS.InputBegan:Connect(function(input, processed)
 if processed then return end
 if input.KeyCode == Enum.KeyCode.M then panel.Visible = not panel.Visible end
end)
local function characterAdded(char)
 stop(); local hum = char:WaitForChild('Humanoid')
 workspace.CurrentCamera.CameraType = Enum.CameraType.Custom; workspace.CurrentCamera.CameraSubject = hum
 hum.Running:Connect(function(speed) if speed > .5 and activeCharacter == char then stop() end end)
 hum.Jumping:Connect(function(jumping) if jumping and activeCharacter == char then stop() end end)
 hum.Died:Connect(stop)
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then task.spawn(characterAdded,player.Character) end

local sprintButton = button('»',gui)
sprintButton.Size = UDim2.fromOffset(48,48); sprintButton.AnchorPoint = Vector2.new(1,1)
sprintButton.Position = UDim2.new(1,-92,1,-180); sprintButton.TextSize = 26
sprintButton.UICorner.CornerRadius = UDim.new(1,0)
sprintButton.Activated:Connect(function()
 stop()
 local char = player.Character
 if not char or not char:FindFirstChild('Run') then return end
 local run = require(game.ReplicatedStorage.Modules.Run.RunClient)
 if char:GetAttribute('state') == 'running' then
  char:SetAttribute('state','neutral'); run.stop(char)
 else
  char:SetAttribute('state','running'); run.begin(char)
 end
end)
