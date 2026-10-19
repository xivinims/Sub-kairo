local AssetService=game:GetService("AssetService")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong Roblox target")

local LOGO_ASSET_ID=__LOGO_ASSET_ID__
local sourceVersion=game.PlaceVersion

for _,child in ipairs(ReplicatedFirst:GetChildren()) do
	if child.Name=="MapLoadingScreen" then
		child:Destroy()
	end
end

local loader=Instance.new("LocalScript")
loader.Name="MapLoadingScreen"
loader.Source=[=[
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="MapLoadingScreen"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=10000
gui.Parent=player:WaitForChild("PlayerGui")

local bg=Instance.new("Frame")
bg.Name="Background"
bg.Size=UDim2.fromScale(1,1)
bg.BackgroundColor3=Color3.fromRGB(20,25,26)
bg.BorderSizePixel=0
bg.Parent=gui

local gradient=Instance.new("UIGradient")
gradient.Rotation=90
gradient.Color=ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.fromRGB(55,67,69)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(18,22,23))
})
gradient.Parent=bg

local logo=Instance.new("ImageLabel")
logo.Name="OveryardLogo"
logo.AnchorPoint=Vector2.new(.5,.5)
logo.Position=UDim2.fromScale(.5,.43)
logo.Size=UDim2.new(.68,0,.31,0)
logo.BackgroundTransparency=1
logo.Image="rbxassetid://__LOGO_ASSET_ID__"
logo.ScaleType=Enum.ScaleType.Fit
logo.Parent=bg

local aspect=Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio=16/9
aspect.AspectType=Enum.AspectType.ScaleWithParentSize
aspect.DominantAxis=Enum.DominantAxis.Width
aspect.Parent=logo

local label=Instance.new("TextLabel")
label.Name="LoadingLabel"
label.AnchorPoint=Vector2.new(.5,.5)
label.Position=UDim2.fromScale(.5,.64)
label.Size=UDim2.fromOffset(220,28)
label.BackgroundTransparency=1
label.Font=Enum.Font.GothamMedium
label.Text="Carregando mapa"
label.TextSize=16
label.TextColor3=Color3.fromRGB(225,229,227)
label.Parent=bg

local barBack=Instance.new("Frame")
barBack.Name="LoadingBarBack"
barBack.AnchorPoint=Vector2.new(.5,.5)
barBack.Position=UDim2.fromScale(.5,.705)
barBack.Size=UDim2.new(.42,0,0,8)
barBack.BackgroundColor3=Color3.fromRGB(57,64,64)
barBack.BackgroundTransparency=.2
barBack.BorderSizePixel=0
barBack.Parent=bg

local backCorner=Instance.new("UICorner")
backCorner.CornerRadius=UDim.new(1,0)
backCorner.Parent=barBack

local fill=Instance.new("Frame")
fill.Name="LoadingBar"
fill.AnchorPoint=Vector2.new(0,.5)
fill.Position=UDim2.fromScale(0,.5)
fill.Size=UDim2.fromScale(0,1)
fill.BackgroundColor3=Color3.fromRGB(92,158,96)
fill.BorderSizePixel=0
fill.Parent=barBack

local fillCorner=Instance.new("UICorner")
fillCorner.CornerRadius=UDim.new(1,0)
fillCorner.Parent=fill

local pct=Instance.new("TextLabel")
pct.Name="LoadingPercent"
pct.AnchorPoint=Vector2.new(.5,.5)
pct.Position=UDim2.fromScale(.5,.755)
pct.Size=UDim2.fromOffset(80,24)
pct.BackgroundTransparency=1
pct.Font=Enum.Font.Gotham
pct.Text="0%"
pct.TextSize=13
pct.TextColor3=Color3.fromRGB(170,182,180)
pct.Parent=bg

local duration=3
local started=os.clock()
local conn
conn=RunService.RenderStepped:Connect(function()
	local alpha=math.clamp((os.clock()-started)/duration,0,1)
	fill.Size=UDim2.fromScale(alpha,1)
	pct.Text=string.format("%d%%",math.floor(alpha*100+.5))
	if alpha>=1 and conn then
		conn:Disconnect()
		conn=nil
	end
end)

task.wait(duration)
if conn then conn:Disconnect() end
fill.Size=UDim2.fromScale(1,1)
pct.Text="100%"

for _,obj in ipairs({logo,label,pct}) do
	local info=TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
	if obj:IsA("ImageLabel") then
		TweenService:Create(obj,info,{ImageTransparency=1}):Play()
	else
		TweenService:Create(obj,info,{TextTransparency=1}):Play()
	end
end
TweenService:Create(fill,TweenInfo.new(.32),{BackgroundTransparency=1}):Play()
TweenService:Create(barBack,TweenInfo.new(.32),{BackgroundTransparency=1}):Play()
TweenService:Create(bg,TweenInfo.new(.42),{BackgroundTransparency=1}):Play()
task.wait(.45)
gui:Destroy()
]=]

loader.Source=string.gsub(loader.Source,"__LOGO_ASSET_ID__",tostring(LOGO_ASSET_ID))
loader.Parent=ReplicatedFirst

Workspace:SetAttribute("LoadingLogoAssetId",LOGO_ASSET_ID)
Workspace:SetAttribute("LoadingIndicator","ProgressBar")
Workspace:SetAttribute("LoadingSeconds",3)

AssetService:SavePlaceAsync()

return {
	ok=true,
	sourceVersion=sourceVersion,
	logoAssetId=LOGO_ASSET_ID,
	loadingSeconds=3,
	indicator="ProgressBar",
}
