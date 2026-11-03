-- Character integration. The imported Animate / Run / Wallrun sources are unchanged.
local Players = game:GetService('Players')
local CAS = game:GetService('ContextActionService')
local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild('Humanoid')
local function cameraReady()
 local camera = workspace.CurrentCamera
 if camera and player.Character == character then
  camera.CameraType = Enum.CameraType.Custom
  camera.CameraSubject = humanoid
 end
end
cameraReady()
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(cameraReady)
local function sprint(_, state)
 if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.End and state ~= Enum.UserInputState.Cancel then return Enum.ContextActionResult.Pass end
 if player.Character ~= character or humanoid.Health <= 0 then return Enum.ContextActionResult.Pass end
 local run = require(game.ReplicatedStorage.Modules.Run.RunClient)
 local running = state == Enum.UserInputState.Begin
 character:SetAttribute('state', running and 'running' or 'neutral')
 if running then run.begin(character) else run.stop(character) end
 return Enum.ContextActionResult.Sink
end
CAS:BindAction('R6Sprint', sprint, true, Enum.KeyCode.LeftShift)
CAS:SetTitle('R6Sprint', 'Correr')
CAS:SetPosition('R6Sprint', UDim2.new(1,-155,1,-175))
humanoid.Died:Once(function() CAS:UnbindAction('R6Sprint') end)
