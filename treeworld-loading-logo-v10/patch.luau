local AssetService=game:GetService("AssetService")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Workspace=game:GetService("Workspace")

assert(game.GameId==9421311218 and game.PlaceId==118064584465155,"Wrong target")

local LOGO_ID=__LOGO_ASSET_ID__
local sourceVersion=game.PlaceVersion

local old=ReplicatedFirst:FindFirstChild("MapLoadingScreen")
if old then old:Destroy() end

local loader=Instance.new("LocalScript")
loader.Name="MapLoadingScreen"
loader.Source=[=[
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ContentProvider=game:GetService("ContentProvider")
local TweenService=game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player=Players.LocalPlayer
local LOGO_ID=__LOGO_ASSET_ID__
local LOGO="rbxassetid://"..LOGO_ID

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
bg.BackgroundColor3=Color3.fromRGB(17,21,22)
bg.BorderSizePixel=0
bg.Parent=gui

local grad=Instance.new("UIGradient")
grad.Rotation=90
grad.Color=ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.fromRGB(42,51,52)),
	ColorSequenceKeypoint.new(.55,Color3.fromRGB(25,30,31)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(14,17,18))
})
grad.Parent=bg

local logo=Instance.new("ImageLabel")
logo.Name="OveryardLogo"
logo.AnchorPoint=Vector2.new(.5,.5)
logo.Position=UDim2.fromScale(.5,.39)
logo.Size=UDim2.new(.76,0,.32,0)
logo.BackgroundTransparency=1
logo.Image=LOGO
logo.ImageTransparency=1
logo.ScaleType=Enum.ScaleType.Fit
logo.ZIndex=3
logo.Parent=bg

local max=Instance.new("UISizeConstraint")
max.MaxSize=Vector2.new(950,440)
max.MinSize=Vector2.new(250,115)
max.Parent=logo

local greeting=Instance.new("TextLabel")
greeting.Name="Greeting"
greeting.AnchorPoint=Vector2.new(.5,.5)
greeting.Position=UDim2.fromScale(.5,.625)
greeting.Size=UDim2.new(.86,0,0,34)
greeting.BackgroundTransparency=1
greeting.Font=Enum.Font.GothamMedium
greeting.Text="Olá, "..(player.DisplayName or player.Name)
greeting.TextSize=19
greeting.TextColor3=Color3.fromRGB(237,240,238)
greeting.ZIndex=3
greeting.Parent=bg

local status=Instance.new("TextLabel")
status.Name="LoadingStatus"
status.AnchorPoint=Vector2.new(.5,.5)
status.Position=UDim2.fromScale(.5,.675)
status.Size=UDim2.new(.88,0,0,26)
status.BackgroundTransparency=1
status.Font=Enum.Font.Gotham
status.Text="Seja bem-vindo"
status.TextSize=14
status.TextColor3=Color3.fromRGB(174,185,181)
status.ZIndex=3
status.Parent=bg

local lineBack=Instance.new("Frame")
lineBack.Name="ProgressBack"
lineBack.AnchorPoint=Vector2.new(.5,.5)
lineBack.Position=UDim2.fromScale(.5,.73)
lineBack.Size=UDim2.new(.34,0,0,3)
lineBack.BackgroundColor3=Color3.fromRGB(64,70,69)
lineBack.BackgroundTransparency=.35
lineBack.BorderSizePixel=0
lineBack.Parent=bg

local line=Instance.new("Frame")
line.Name="Progress"
line.Size=UDim2.fromScale(0,1)
line.BackgroundColor3=Color3.fromRGB(89,153,91)
line.BorderSizePixel=0
line.Parent=lineBack

local c1=Instance.new("UICorner");c1.CornerRadius=UDim.new(1,0);c1.Parent=lineBack
local c2=Instance.new("UICorner");c2.CornerRadius=UDim.new(1,0);c2.Parent=line

-- Start image fetch immediately; UI is already dark so no white flash.
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({logo})
	end)
	if logo.Parent then
		TweenService:Create(logo,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency=0}):Play()
	end
end)

local messages={
	{0.00,"Seja bem-vindo"},
	{0.85,"Preparando o mapa..."},
	{1.65,"Carregando ambiente..."},
	{2.35,"Quase pronto..."},
}

local duration=3
local started=os.clock()

for i,item in ipairs(messages) do
	task.delay(item[1],function()
		if not status.Parent then return end
		TweenService:Create(status,TweenInfo.new(.12),{TextTransparency=1}):Play()
		task.wait(.12)
		if status.Parent then
			status.Text=item[2]
			TweenService:Create(status,TweenInfo.new(.14),{TextTransparency=0}):Play()
		end
	end)
end

TweenService:Create(line,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(1,1)}):Play()

local elapsed=os.clock()-started
if elapsed<duration then task.wait(duration-elapsed) end
if not game:IsLoaded() then game.Loaded:Wait() end

local fade=TweenInfo.new(.34,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
TweenService:Create(logo,fade,{ImageTransparency=1}):Play()
TweenService:Create(greeting,fade,{TextTransparency=1}):Play()
TweenService:Create(status,fade,{TextTransparency=1}):Play()
TweenService:Create(line,fade,{BackgroundTransparency=1}):Play()
TweenService:Create(lineBack,fade,{BackgroundTransparency=1}):Play()
TweenService:Create(bg,TweenInfo.new(.44),{BackgroundTransparency=1}):Play()
task.wait(.48)
gui:Destroy()
]=]

loader.Source=string.gsub(loader.Source,"__LOGO_ASSET_ID__",tostring(LOGO_ID))
loader.Parent=ReplicatedFirst

local updateClient=ReplicatedFirst:FindFirstChild("OveryardUpdateMigrationClient")
if updateClient and updateClient:IsA("LocalScript") then
	updateClient.Source=string.gsub(updateClient.Source,"rbxassetid://%d+","rbxassetid://"..tostring(LOGO_ID),1)
end

Workspace:SetAttribute("LoadingLogoAssetId",LOGO_ID)
Workspace:SetAttribute("LoadingLogoTransparent",true)
Workspace:SetAttribute("LoadingLogoImmediatePreload",true)
Workspace:SetAttribute("LoadingGreetingSequence",true)
Workspace:SetAttribute("LoadingSeconds",3)

AssetService:SavePlaceAsync()

return {
	ok=true,
	sourceVersion=sourceVersion,
	logoAssetId=LOGO_ID,
	transparent=true,
	greeting=true,
}
