local Players=game:GetService("Players")
local player=Players.LocalPlayer
local ui=script.Parent
-- No main menu. Players load directly into the fixed lobby.
player:SetAttribute("InMenu",false)
player:SetAttribute("MenuIntroPending",false)
if ui and ui:IsA("ScreenGui") then
 ui.Enabled=false
 ui:SetAttribute("MenuRemoved",true)
end
local camera=workspace.CurrentCamera
if camera then
 camera.CameraType=Enum.CameraType.Custom
 local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if hum then camera.CameraSubject=hum end
end
player.CharacterAdded:Connect(function(char)
 player:SetAttribute("InMenu",false)
 local hum=char:WaitForChild("Humanoid",8)
 local cam=workspace.CurrentCamera
 if hum and cam then cam.CameraType=Enum.CameraType.Custom cam.CameraSubject=hum end
end)