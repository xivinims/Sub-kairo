local AssetService=game:GetService("AssetService")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")

local LOGO_ID=138675502621883
local sourceVersion=game.PlaceVersion

local old=ReplicatedFirst:FindFirstChild("MapLoadingScreen")
if old then old:Destroy() end

local loader=Instance.new("LocalScript")
loader.Name="MapLoadingScreen"
loader.Source=[=[
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ContentProvider=game:GetService("ContentProvider")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local LOGO_ID=138675502621883
local PRIMARY="rbxassetid://"..LOGO_ID
local FALLBACK="rbxthumb://type=Asset&id="..LOGO_ID.."&w=768&h=432"

local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="MapLoadingScreen"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=10000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
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
logo.Position=UDim2.fromScale(.5,.40)
logo.Size=UDim2.new(.74,0,.34,0)
logo.BackgroundTransparency=1
logo.Image=PRIMARY
logo.ImageTransparency=0
logo.ImageColor3=Color3.new(1,1,1)
logo.ScaleType=Enum.ScaleType.Fit
logo.Visible=true
logo.ZIndex=3
logo.Parent=bg

local maxSize=Instance.new("UISizeConstraint")
maxSize.MaxSize=Vector2.new(900,360)
maxSize.MinSize=Vector2.new(240,96)
maxSize.Parent=logo

local label=Instance.new("TextLabel")
label.Name="LoadingLabel"
label.AnchorPoint=Vector2.new(.5,.5)
label.Position=UDim2.fromScale(.5,.625)
label.Size=UDim2.fromOffset(240,30)
label.BackgroundTransparency=1
label.Font=Enum.Font.GothamMedium
label.Text="Carregando mapa"
label.TextSize=16
label.TextColor3=Color3.fromRGB(225,229,227)
label.ZIndex=3
label.Parent=bg

local barBack=Instance.new("Frame")
barBack.Name="LoadingBarBack"
barBack.AnchorPoint=Vector2.new(.5,.5)
barBack.Position=UDim2.fromScale(.5,.69)
barBack.Size=UDim2.new(.42,0,0,8)
barBack.BackgroundColor3=Color3.fromRGB(57,64,64)
barBack.BackgroundTransparency=.18
barBack.BorderSizePixel=0
barBack.ZIndex=3
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
fill.ZIndex=4
fill.Parent=barBack

local fillCorner=Instance.new("UICorner")
fillCorner.CornerRadius=UDim.new(1,0)
fillCorner.Parent=fill

local pct=Instance.new("TextLabel")
pct.Name="LoadingPercent"
pct.AnchorPoint=Vector2.new(.5,.5)
pct.Position=UDim2.fromScale(.5,.74)
pct.Size=UDim2.fromOffset(90,24)
pct.BackgroundTransparency=1
pct.Font=Enum.Font.Gotham
pct.Text="0%"
pct.TextSize=13
pct.TextColor3=Color3.fromRGB(170,182,180)
pct.ZIndex=3
pct.Parent=bg

-- Give the logo time to arrive before the visible 3-second loading timer.
local preloadDone=false
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({logo})
	end)
	preloadDone=true
end)

local preloadStart=os.clock()
while not preloadDone and not logo.IsLoaded and os.clock()-preloadStart<2.75 do
	task.wait(.05)
end

-- Mobile/content fallback: use Roblox's generated asset thumbnail if direct image content is late.
if not logo.IsLoaded then
	logo.Image=FALLBACK
	local fallbackDone=false
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({logo})
		end)
		fallbackDone=true
	end)
	local fallbackStart=os.clock()
	while not fallbackDone and not logo.IsLoaded and os.clock()-fallbackStart<1.75 do
		task.wait(.05)
	end
end

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

local fade=TweenInfo.new(.34,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
TweenService:Create(logo,fade,{ImageTransparency=1}):Play()
TweenService:Create(label,fade,{TextTransparency=1}):Play()
TweenService:Create(pct,fade,{TextTransparency=1}):Play()
TweenService:Create(fill,fade,{BackgroundTransparency=1}):Play()
TweenService:Create(barBack,fade,{BackgroundTransparency=1}):Play()
TweenService:Create(bg,TweenInfo.new(.44),{BackgroundTransparency=1}):Play()
task.wait(.48)
gui:Destroy()
]=]
loader.Parent=ReplicatedFirst

Workspace:SetAttribute("LoadingLogoAssetId",LOGO_ID)
Workspace:SetAttribute("LoadingLogoPreload",true)
Workspace:SetAttribute("LoadingLogoFallback",true)
Workspace:SetAttribute("LoadingIndicator","ProgressBar")
Workspace:SetAttribute("LoadingSeconds",3)

AssetService:SavePlaceAsync()

return {
	ok=true,
	sourceVersion=sourceVersion,
	logoAssetId=LOGO_ID,
	preload=true,
	fallback=true,
}
