local Players=game:GetService("Players")local Run=game:GetService("RunService")local Tween=game:GetService("TweenService")local Starter=game:GetService("StarterGui")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local gui=script.Parent local loading=gui:WaitForChild("Background")local menu=gui:WaitForChild("MainMenu")local button=menu:WaitForChild("PlayButton")
local controls=require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()controls:Disable()
local blur=game.Lighting:WaitForChild("TreeWorldMenuBlur")blur.Enabled=true blur.Size=8
player:SetAttribute("TreeWorldMenuOpen",true)
loading.Visible=true menu.Visible=false
local originalCore={}for _,kind in ipairs({Enum.CoreGuiType.Backpack,Enum.CoreGuiType.Health,Enum.CoreGuiType.PlayerList})do
 pcall(function()originalCore[kind]=Starter:GetCoreGuiEnabled(kind)Starter:SetCoreGuiEnabled(kind,false)end)
end
local hidden={}local characterConnection=player.CharacterAdded:Connect(function(character)
 if player:GetAttribute("TreeWorldMenuOpen")then for _,p in ipairs(character:GetDescendants())do if p:IsA("BasePart")then hidden[p]=p.LocalTransparencyModifier p.LocalTransparencyModifier=1 end end end
end)
if player.Character then for _,p in ipairs(player.Character:GetDescendants())do if p:IsA("BasePart")then hidden[p]=p.LocalTransparencyModifier p.LocalTransparencyModifier=1 end end end
local camera=workspace.CurrentCamera
local saved={kind=camera.CameraType,field=camera.FieldOfView}
local opened=true local origin=runtime:GetAttribute("MenuCameraCF")local focus=runtime:GetAttribute("MenuCameraFocus")
local time=0
local connection=Run.RenderStepped:Connect(function(dt)
 if not opened then return end time+=dt local c=workspace.CurrentCamera if not c then return end
 c.CameraType=Enum.CameraType.Scriptable c.FieldOfView=58
 if origin and focus then local p=origin.Position+Vector3.new(math.sin(time*.045)*2,.3*math.sin(time*.07),0)c.CFrame=CFrame.lookAt(p,focus)c.Focus=CFrame.new(focus)end
end)
Tween:Create(loading.Bar.LoadBar,TweenInfo.new(3,Enum.EasingStyle.Sine),{Size=UDim2.fromScale(1,1)}):Play()
task.delay(3,function()if not opened then return end loading.Visible=false menu.Visible=true blur.Size=5 end)
local function enter()
 if not opened then return end opened=false player:SetAttribute("TreeWorldMenuOpen",false)
 connection:Disconnect()characterConnection:Disconnect()controls:Enable()
 for p,value in pairs(hidden)do if p.Parent then p.LocalTransparencyModifier=value end end table.clear(hidden)
 local c=workspace.CurrentCamera local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 c.CameraType=Enum.CameraType.Custom if h then c.CameraSubject=h end c.FieldOfView=saved.field
 blur.Enabled=false blur.Size=0 for kind,state in pairs(originalCore)do pcall(function()Starter:SetCoreGuiEnabled(kind,state)end)end
 gui.Enabled=false
end
button.Activated:Connect(enter)
script.Destroying:Connect(function()if opened then enter()end end)
