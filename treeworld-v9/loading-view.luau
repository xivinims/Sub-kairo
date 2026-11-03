-- Shared normal/teleport loading UI; the approved alpha logo stays visible
-- while it loads. The text fallback disappears only after IsLoaded is true.
local Players=game:GetService("Players")
local ContentProvider=game:GetService("ContentProvider")
local TweenService=game:GetService("TweenService")
local M={}
local LOGO="rbxassetid://77442764802726"
function M.create(name,titleText,statusText,order)
 local gui=Instance.new("ScreenGui");gui.Name=name;gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false
 gui.DisplayOrder=order or 10000;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local bg=Instance.new("Frame");bg.Name="Background";bg.Size=UDim2.fromScale(1,1)
 bg.BorderSizePixel=0;bg.BackgroundColor3=Color3.fromRGB(17,23,21);bg.Parent=gui
 local stack=Instance.new("Frame");stack.Name="Content";stack.AnchorPoint=Vector2.new(.5,.5)
 stack.Position=UDim2.fromScale(.5,.49);stack.Size=UDim2.new(.84,0,.76,0);stack.BackgroundTransparency=1;stack.Parent=bg
 local cap=Instance.new("UISizeConstraint");cap.MaxSize=Vector2.new(760,480);cap.Parent=stack
 local logo=Instance.new("ImageLabel");logo.Name="OveryardLogo";logo.AnchorPoint=Vector2.new(.5,0)
 logo.Position=UDim2.fromScale(.5,.02);logo.Size=UDim2.fromScale(1,.57);logo.BackgroundTransparency=1
 logo.Image=LOGO;logo.ImageTransparency=0;logo.ScaleType=Enum.ScaleType.Fit;logo.ZIndex=3;logo.Parent=stack
 local function label(name,text,y,h,size,color)
  local p=Instance.new("TextLabel");p.Name=name;p.AnchorPoint=Vector2.new(.5,0);p.Position=UDim2.fromScale(.5,y)
  p.Size=UDim2.fromScale(.96,h);p.BackgroundTransparency=1;p.Font=Enum.Font.GothamMedium
  p.Text=text;p.TextSize=size;p.TextColor3=color;p.TextWrapped=true;p.ZIndex=3;p.Parent=stack;return p
 end
 local fallback=label("LogoFallback","OVERYARD",.2,.16,32,Color3.fromRGB(143,178,125))
 local title=label("Greeting",titleText,.62,.12,19,Color3.fromRGB(235,239,233))
 local status=label("LoadingStatus",statusText,.77,.12,14,Color3.fromRGB(172,186,172))
 local back=Instance.new("Frame");back.Name="ProgressBack";back.AnchorPoint=Vector2.new(.5,0)
 back.Position=UDim2.fromScale(.5,.94);back.Size=UDim2.new(.52,0,0,3);back.BorderSizePixel=0
 back.BackgroundColor3=Color3.fromRGB(51,63,54);back.Parent=stack
 local progress=Instance.new("Frame");progress.Name="Progress";progress.Size=UDim2.fromScale(0,1)
 progress.BorderSizePixel=0;progress.BackgroundColor3=Color3.fromRGB(112,162,92);progress.Parent=back
 for _,p in ipairs({back,progress})do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=p end
 gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
 local view={gui=gui,logo=logo,title=title,status=status,progress=progress,ready=false,visibleAt=nil}
 local function loaded()
  if logo.IsLoaded and gui.Parent then
   view.ready=true;view.visibleAt=view.visibleAt or os.clock();fallback.Visible=false
  end
 end
 local conn=logo:GetPropertyChangedSignal("IsLoaded"):Connect(loaded)
 gui.Destroying:Connect(function()conn:Disconnect()end)
 loaded()
 task.spawn(function()
  pcall(function()ContentProvider:PreloadAsync({logo})end)
  loaded()
 end)
 function view:setProgress(p)
  if progress.Parent then TweenService:Create(progress,TweenInfo.new(.14),{Size=UDim2.fromScale(math.clamp(p,0,1),1)}):Play()end
 end
 function view:close()
  if not gui.Parent then return end
  for _,p in ipairs(gui:GetDescendants())do
   if p:IsA("TextLabel")then TweenService:Create(p,TweenInfo.new(.25),{TextTransparency=1}):Play()
   elseif p:IsA("ImageLabel")then TweenService:Create(p,TweenInfo.new(.25),{ImageTransparency=1}):Play()
   elseif p:IsA("Frame")then TweenService:Create(p,TweenInfo.new(.3),{BackgroundTransparency=1}):Play()end
  end
  task.wait(.32);gui:Destroy()
 end
 return view
end
return M
