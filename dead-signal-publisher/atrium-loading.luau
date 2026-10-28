local RF=game:GetService("ReplicatedFirst")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Content=game:GetService("ContentProvider")
local Tween=game:GetService("TweenService")
RF:RemoveDefaultLoadingScreen()
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="AurivaneLoading";gui.IgnoreGuiInset=true;gui.DisplayOrder=1000;gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.new(0,0,0);bg.BorderSizePixel=0;bg.Parent=gui
local logo=Instance.new("ImageLabel");logo.AnchorPoint=Vector2.new(.5,.5);logo.Position=UDim2.fromScale(.5,.44);logo.Size=UDim2.fromScale(.7,.7);logo.BackgroundTransparency=1;logo.ScaleType=Enum.ScaleType.Fit;logo.ImageTransparency=1;logo.Parent=bg
local title=Instance.new("TextLabel");title.Position=UDim2.fromScale(.15,.77);title.Size=UDim2.fromScale(.7,.06);title.BackgroundTransparency=1;title.Text="CARREGANDO O ÁTRIO";title.TextColor3=Color3.fromRGB(173,184,202);title.Font=Enum.Font.Code;title.TextSize=16;title.Parent=bg
local track=Instance.new("Frame");track.Position=UDim2.fromScale(.35,.86);track.Size=UDim2.fromScale(.3,.003);track.BackgroundColor3=Color3.fromRGB(40,43,49);track.BorderSizePixel=0;track.Parent=bg
local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(.1,1);fill.BorderSizePixel=0;fill.BackgroundColor3=Color3.fromRGB(255,90,23);fill.Parent=track
local start=os.clock()
while not RS:GetAttribute("AurivaneLogo") and os.clock()-start<20 do task.wait(.1) end
local id=RS:GetAttribute("AurivaneLogo")
if id then logo.Image=RS:GetAttribute("AurivaneLogoTexture") or "rbxassetid://"..tostring(id);task.spawn(function() pcall(function() Content:PreloadAsync({logo}) end) end) end
Tween:Create(logo,TweenInfo.new(.7),{ImageTransparency=0}):Play()
fill.Size=UDim2.fromScale(.3,1)
if not game:IsLoaded() then game.Loaded:Wait() end
fill.Size=UDim2.fromScale(.65,1)
while not player:GetAttribute("AtriumMenuReady") do
 if os.clock()-start>25 then title.Text="AGUARDANDO CONEXÃO…" end
 task.wait(.1)
end
fill.Size=UDim2.fromScale(1,1)
if os.clock()-start<1.5 then task.wait(1.5-(os.clock()-start)) end
Tween:Create(logo,TweenInfo.new(.5),{ImageTransparency=1}):Play();Tween:Create(bg,TweenInfo.new(.5),{BackgroundTransparency=1}):Play();title.Visible=false;track.Visible=false;task.wait(.55);gui:Destroy()
