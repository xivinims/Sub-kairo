local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("ArenaControl")
local rig=workspace:WaitForChild("Bramble")
local gui=Instance.new("ScreenGui"); gui.Name="BrambleTestControls"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame"); panel.AnchorPoint=Vector2.new(0.5,0); panel.Position=UDim2.new(0.5,0,0,12); panel.Size=UDim2.new(0.94,0,0,90); panel.BackgroundTransparency=1; panel.Parent=gui
local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(600,90); limit.Parent=panel
local status=Instance.new("TextLabel"); status.Size=UDim2.new(1,0,0,26); status.BackgroundColor3=Color3.fromRGB(20,23,26); status.BackgroundTransparency=0.2; status.TextColor3=Color3.fromRGB(240,240,240); status.Font=Enum.Font.Gotham; status.TextSize=14; status.Parent=panel
local labels={Idle="PARADO",Walk="ANDAR",Run="CORRER",Attack="AGARRAR"}
local buttons={}
for i,key in ipairs({"Idle","Walk","Run","Attack"}) do
    local b=Instance.new("TextButton"); b.Name=key; b.Text=labels[key]; b.Position=UDim2.new((i-1)*0.25,3,0,34); b.Size=UDim2.new(0.25,-6,0,48)
    b.BackgroundColor3=Color3.fromRGB(40,46,51); b.TextColor3=Color3.fromRGB(245,245,245); b.Font=Enum.Font.GothamMedium; b.TextSize=13; b.Modal=false; b.Parent=panel
    b.Activated:Connect(function() remote:FireServer(key) end); buttons[key]=b
end
local function update()
    local state=rig:GetAttribute("State") or "Idle"
    status.Text=player:GetAttribute("BrambleCaptured") and "AGARRADO" or "BRAMBLE · "..(labels[state] or state)
    for k,b in pairs(buttons) do b.BackgroundColor3=k==state and Color3.fromRGB(86,69,48) or Color3.fromRGB(40,46,51) end
end
rig:GetAttributeChangedSignal("State"):Connect(update)
player:GetAttributeChangedSignal("BrambleCaptured"):Connect(update)
UIS.InputBegan:Connect(function(input,processed)
    if processed then return end
    local key=({[Enum.KeyCode.One]="Idle",[Enum.KeyCode.Two]="Walk",[Enum.KeyCode.Three]="Run",[Enum.KeyCode.Four]="Attack"})[input.KeyCode]
    if key then remote:FireServer(key) end
end)
update()
