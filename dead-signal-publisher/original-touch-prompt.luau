local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local ProximityPromptService=game:GetService('ProximityPromptService')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer
while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end

local gui=Instance.new('ScreenGui')
gui.Name='OriginalWeaponHoldPrompt';gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false;gui.DisplayOrder=90;gui.Parent=player:WaitForChild('PlayerGui')
local button=Instance.new('TextButton')
button.Name='HoldToInteract';button.AnchorPoint=Vector2.new(1,.5)
button.Position=UDim2.new(1,-26,1,-178);button.Size=UDim2.fromOffset(76,76)
button.BackgroundColor3=Color3.fromRGB(18,22,22);button.BackgroundTransparency=.12
button.BorderSizePixel=0;button.AutoButtonColor=false;button.Text='👌'
button.TextColor3=Color3.fromRGB(235,232,218);button.TextSize=39
button.Font=Enum.Font.GothamBold;button.Visible=false;button.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(1,0);corner.Parent=button
local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(202,195,169)
stroke.Transparency=.25;stroke.Thickness=1.5;stroke.Parent=button
local caption=Instance.new('TextLabel')
caption.Name='HoldCaption';caption.AnchorPoint=Vector2.new(.5,0)
caption.Position=UDim2.new(.5,0,1,5);caption.Size=UDim2.new(0,180,0,24)
caption.BackgroundTransparency=1;caption.Text='SEGURE PARA INTERAGIR'
caption.TextColor3=Color3.fromRGB(223,221,212);caption.TextSize=12
caption.Font=Enum.Font.RobotoCondensed;caption.Parent=button
local track=Instance.new('Frame')
track.Name='HoldTrack';track.AnchorPoint=Vector2.new(.5,1)
track.Position=UDim2.new(.5,0,1,-4);track.Size=UDim2.new(.72,0,0,3)
track.BackgroundColor3=Color3.fromRGB(69,72,70);track.BorderSizePixel=0;track.Parent=button
local fill=Instance.new('Frame')
fill.Name='HoldProgress';fill.Size=UDim2.fromScale(0,1)
fill.BackgroundColor3=Color3.fromRGB(181,62,62);fill.BorderSizePixel=0;fill.Parent=track

local activePrompt
local holding=false
local holdStarted=0
local holdDuration=.45
local inputConnection
local progressConnection
local function stopHold()
 if not holding then return end
 holding=false
 if activePrompt and activePrompt.Parent then
  pcall(function() activePrompt:InputHoldEnd() end)
 end
 if progressConnection then progressConnection:Disconnect();progressConnection=nil end
 fill.Size=UDim2.fromScale(0,1)
end
local function beginHold()
 if holding or not activePrompt or not activePrompt.Parent or not activePrompt.Enabled then return end
 holding=true;holdStarted=os.clock()
 pcall(function() activePrompt:InputHoldBegin() end)
 progressConnection=RunService.RenderStepped:Connect(function()
  local fraction=holdDuration<=0 and 1 or math.clamp((os.clock()-holdStarted)/holdDuration,0,1)
  fill.Size=UDim2.fromScale(fraction,1)
 end)
end
local function hidePrompt()
 stopHold()
 activePrompt=nil
 button.Visible=false
 if inputConnection then inputConnection:Disconnect();inputConnection=nil end
end
ProximityPromptService.PromptShown:Connect(function(prompt,inputType)
 hidePrompt()
 activePrompt=prompt
 pcall(function() prompt.Style=Enum.ProximityPromptStyle.Custom end)
 holdDuration=math.max(prompt.HoldDuration,.45)
 caption.Text=string.upper(prompt.ActionText~='' and prompt.ActionText or 'SEGURE PARA INTERAGIR')
 if inputType==Enum.ProximityPromptInputType.Touch then
  button.Visible=true
  button.Text='👌'
 elseif inputType==Enum.ProximityPromptInputType.Gamepad then
  button.Visible=true
  button.Text='X'
 elseif inputType==Enum.ProximityPromptInputType.Keyboard then
  button.Visible=true
  button.Text='E'
 end
 inputConnection=UIS.InputBegan:Connect(function(input,_processed)
  if not activePrompt then return end
  local keyboard=input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==activePrompt.KeyboardKeyCode
  local gamepad=input.UserInputType==Enum.UserInputType.Gamepad1 and input.KeyCode==activePrompt.GamepadKeyCode
  if keyboard or gamepad then beginHold() end
 end)
end)
ProximityPromptService.PromptHidden:Connect(function(prompt)
 if prompt==activePrompt then hidePrompt() end
end)
button.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then beginHold() end
end)
button.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then stopHold() end
end)
UIS.InputEnded:Connect(function(input)
 if not activePrompt then return end
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then stopHold();return end
 if input.KeyCode==activePrompt.KeyboardKeyCode or input.KeyCode==activePrompt.GamepadKeyCode then stopHold() end
end)
player:GetAttributeChangedSignal('InterfaceOpen'):Connect(function()
 if player:GetAttribute('InterfaceOpen') then hidePrompt() end
end)
