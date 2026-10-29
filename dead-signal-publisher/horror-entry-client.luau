local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Tween=game:GetService('TweenService')
local p=Players.LocalPlayer;local assets=RS:WaitForChild('CombatAssets',30);if not assets then return end
local template=assets:WaitForChild('HorrorEntrance',10);if not template then return end
local gui=template:Clone();gui.Enabled=true;gui.ResetOnSpawn=false;gui.Parent=p:WaitForChild('PlayerGui')
game:GetService('ReplicatedFirst'):RemoveDefaultLoadingScreen()
local blocker=Instance.new('TextButton');blocker.Name='InputBlocker';blocker.Text='';blocker.BackgroundTransparency=1;blocker.Size=UDim2.fromScale(1,1);blocker.ZIndex=0;blocker.Parent=gui
local logo=gui.LogoFrame;local warning=gui.WarningFrame;local background=gui.Background
logo.Visible=true;warning.Visible=false;background.BackgroundTransparency=0
logo.Logo.LogoText.TextTransparency=1
Tween:Create(logo.Logo.LogoText,TweenInfo.new(1),{TextTransparency=0}):Play()
task.wait(2.5)
Tween:Create(logo.Logo.LogoText,TweenInfo.new(.5),{TextTransparency=1}):Play();task.wait(.5)
logo.Visible=false;warning.Visible=true
warning.Click.Selectable=true;warning.Click.Active=true;warning.Click.Visible=true
local closed=false
warning.Click.Activated:Connect(function()
 if closed then return end;closed=true
 for _,v in ipairs(gui:GetDescendants()) do if v:IsA('TextLabel') or v:IsA('TextButton') then Tween:Create(v,TweenInfo.new(.35),{TextTransparency=1}):Play() end end
 Tween:Create(background,TweenInfo.new(.5),{BackgroundTransparency=1}):Play();task.wait(.5);gui:Destroy()
end)
