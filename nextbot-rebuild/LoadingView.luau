local Tween=game:GetService('TweenService')
local M={}
local function new(class,parent,props)local v=Instance.new(class);for k,x in pairs(props)do v[k]=x end;v.Parent=parent;return v end
function M.Logo(parent,position,size)
 local frame=new('Frame',parent,{Name='ExactRunLogo',AnchorPoint=Vector2.new(.5,.5),Position=position,Size=size,BackgroundTransparency=1})
 local function letters(name,offset,color)
  return new('TextLabel',frame,{Name=name,Text='EXACT RUN',Font=Enum.Font.Bangers,TextScaled=true,TextColor3=color,TextStrokeColor3=Color3.fromRGB(10,13,25),TextStrokeTransparency=0,BackgroundTransparency=1,Position=UDim2.fromOffset(offset,offset),Size=UDim2.fromScale(1,1),Rotation=-3})
 end
 letters('Shadow',6,Color3.fromRGB(7,10,20))
 local title=letters('Wordmark',0,Color3.new(1,1,1))
 new('UIGradient',title,{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(85,255,184)),ColorSequenceKeypoint.new(.45,Color3.fromRGB(143,235,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(183,119,255))})})
 return frame
end
function M.Create(parent,name,order)
 local gui=new('ScreenGui',parent,{Name=name,DisplayOrder=order,IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
 pcall(function()gui.ScreenInsets=Enum.ScreenInsets.None;gui.ClipToDeviceSafeArea=false end)
 local cover=new('CanvasGroup',gui,{Name='Cover',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(9,12,24),BorderSizePixel=0,Active=true})
 local canvas=new('Frame',cover,{Name='Canvas',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1536,709),BackgroundTransparency=1})
 local scale=new('UIScale',canvas,{Scale=1})
 local function fit()scale.Scale=math.min(gui.AbsoluteSize.X/1536,gui.AbsoluteSize.Y/709)end
 fit();gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
 M.Logo(canvas,UDim2.fromOffset(768,325),UDim2.fromOffset(455,132))
 local status=new('TextLabel',canvas,{Name='Status',Text='',Position=UDim2.fromOffset(340,414),Size=UDim2.fromOffset(856,48),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=29,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=.1})
 local detail=new('TextLabel',canvas,{Name='Detail',Text='',Position=UDim2.fromOffset(340,462),Size=UDim2.fromOffset(856,32),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=17,TextColor3=Color3.fromRGB(210,213,222)})
 local tip=new('TextLabel',canvas,{Name='Tip',Text='Reanime seus colegas e sobrevivam juntos.',Position=UDim2.fromOffset(480,628),Size=UDim2.fromOffset(980,40),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamMedium,TextSize=20,TextColor3=Color3.fromRGB(218,228,234)})
 local track=new('Frame',cover,{Name='ProgressTrack',Position=UDim2.new(0,0,1,-6),Size=UDim2.new(1,0,0,6),BackgroundColor3=Color3.fromRGB(32,39,58),BorderSizePixel=0})
 local fill=new('Frame',track,{Name='Progress',Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(155,222,255),BorderSizePixel=0})
 local spinner=new('Frame',canvas,{Name='Spinner',Position=UDim2.fromOffset(65,610),Size=UDim2.fromOffset(29,29),BackgroundTransparency=1,Rotation=45})
 new('UIStroke',spinner,{Thickness=3,Color=Color3.fromRGB(151,231,255),Transparency=.1})
 local rotation=Tween:Create(spinner,TweenInfo.new(1.5,Enum.EasingStyle.Linear,Enum.EasingDirection.In,-1),{Rotation=405});rotation:Play()
 gui.Destroying:Connect(function()rotation:Cancel()end)
 local view={gui=gui,cover=cover,status=status,detail=detail,tip=tip,fill=fill}
 function view:Set(text,progress,subtext)status.Text=text;fill.Size=UDim2.fromScale(math.clamp(progress or 0,0,1),1);detail.Text=subtext or ''end
 function view:Retry(callback)
  local button=new('TextButton',canvas,{Name='Retry',Text='TENTAR NOVAMENTE',Position=UDim2.fromOffset(568,520),Size=UDim2.fromOffset(400,64),BackgroundColor3=Color3.fromRGB(53,89,115),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=22})
  new('UICorner',button,{CornerRadius=UDim.new(0,8)});button.Activated:Connect(function()button.Active=false;callback()end)
 end
 function view:Close()
  local fade=Tween:Create(cover,TweenInfo.new(.35),{GroupTransparency=1});fade:Play();fade.Completed:Wait();rotation:Cancel();gui:Destroy()
 end
 return view
end
return M
