local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="SweanLoading" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=1000
local frame=Instance.new("Frame") frame.Size=UDim2.fromScale(1,1) frame.BackgroundColor3=Color3.fromRGB(22,31,25) frame.Parent=gui
local function text(value,y,size)
 local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.AnchorPoint=Vector2.new(.5,.5)
 label.Position=UDim2.fromScale(.5,y) label.Size=UDim2.new(.86,0,0,48)
 label.Font=Enum.Font.GothamMedium label.TextColor3=Color3.fromRGB(235,239,220) label.TextSize=size label.Text=value label.Parent=frame return label
end
text("Swean Island",.44,30)
local status=text("Preparando a ilha…",.54,15)
local skip=Instance.new("TextButton") skip.Text="Continuar" skip.Font=Enum.Font.GothamMedium skip.TextSize=16
skip.AnchorPoint=Vector2.new(.5,.5) skip.Position=UDim2.fromScale(.5,.67) skip.Size=UDim2.fromOffset(160,44)
skip.BackgroundColor3=Color3.fromRGB(55,73,52) skip.TextColor3=Color3.new(1,1,1) skip.Visible=false skip.Parent=frame
local finished=false
local function finish()
 if finished then return end finished=true
 player:SetAttribute("SweanLoadingDone",true)
 gui:Destroy()
end
skip.Activated:Connect(finish)
-- Fail-open timer exists before any yielding asset/player-GUI operation.
task.delay(10,finish)
task.delay(3,function() if not finished then skip.Visible=true end end)
local pg=player:WaitForChild("PlayerGui",8)
if not pg or finished then finish() return end
gui.Parent=pg
ReplicatedFirst:RemoveDefaultLoadingScreen()
local start=os.clock()
local loaded=false
task.spawn(function()
 local template=RS:WaitForChild("GrassWindTemplate",5)
 if template then pcall(function() game:GetService("ContentProvider"):PreloadAsync({template}) end) end
 loaded=true
end)
while not finished and os.clock()-start<8 and (not game:IsLoaded() or not loaded or os.clock()-start<1) do task.wait(.1) end
finish()
