-- Dead Signal | minimal Aurivane Works splash.
-- Only the actual creator logo is visible. No bars, messages or indefinite waits.
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local ContentProvider=game:GetService("ContentProvider")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="AurivaneLoading"
gui.IgnoreGuiInset=true
gui.DisplayOrder=1000
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")

local backdrop=Instance.new("Frame")
backdrop.Name="BlackBackground"
backdrop.Size=UDim2.fromScale(1,1)
backdrop.BackgroundColor3=Color3.new(0,0,0)
backdrop.BorderSizePixel=0
backdrop.Parent=gui

local logo=Instance.new("ImageLabel")
logo.Name="AurivaneWorksLogo"
logo.AnchorPoint=Vector2.new(.5,.5)
logo.Position=UDim2.fromScale(.5,.5)
logo.Size=UDim2.fromScale(.66,.52)
logo.BackgroundTransparency=1
logo.ScaleType=Enum.ScaleType.Fit
logo.ImageTransparency=1
logo.Parent=backdrop
local constraint=Instance.new("UIAspectRatioConstraint")
constraint.AspectRatio=1.9
constraint.AspectType=Enum.AspectType.FitWithinMaxSize
constraint.Parent=logo

-- The previously uploaded real Aurivane logo is a safe fallback if replication is late.
local function updateImage()
 local texture=ReplicatedStorage:GetAttribute("AurivaneLogoTexture")
 local id=ReplicatedStorage:GetAttribute("AurivaneLogo")
 if type(texture)=="string" and texture~="" then
  logo.Image=texture
 else
  logo.Image="rbxassetid://"..tostring(id or 94878559768864)
 end
end
updateImage()
local textureConnection=ReplicatedStorage:GetAttributeChangedSignal("AurivaneLogoTexture"):Connect(updateImage)
local idConnection=ReplicatedStorage:GetAttributeChangedSignal("AurivaneLogo"):Connect(updateImage)

-- Preloading is optional and never blocks the menu.
task.spawn(function()
 local ok,err=pcall(function() ContentProvider:PreloadAsync({logo}) end)
 if not ok then warn("[AurivaneLoading] Logo preload: "..tostring(err)) end
end)

local began=os.clock()
local intro=TweenService:Create(logo,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency=0})
intro:Play()

-- IMPORTANT: the previous loader blocked indefinitely while awaiting signals.
-- With a slow or broken client script it could remain on top of the game forever.
-- Wait for the actual menu, but always dismiss the overlay after a deadline.
local deadline=began+10
repeat
 task.wait(.08)
until player:GetAttribute("AtriumMenuReady")==true or os.clock()>=deadline

if not player:GetAttribute("AtriumMenuReady") then
 warn("[AurivaneLoading] Atrium menu did not acknowledge readiness within 10 seconds; removing splash to avoid a black-screen lock.")
end

local remaining=1.2-(os.clock()-began)
if remaining>0 then task.wait(remaining) end

local fadeInfo=TweenInfo.new(.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
TweenService:Create(logo,fadeInfo,{ImageTransparency=1}):Play()
local fade=TweenService:Create(backdrop,fadeInfo,{BackgroundTransparency=1})
fade:Play()
fade.Completed:Wait()
textureConnection:Disconnect()
idConnection:Disconnect()
gui:Destroy()
