local Players=game:GetService('Players')
local RF=game:GetService('ReplicatedFirst')
local RS=game:GetService('ReplicatedStorage')
local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
local gui=Instance.new('ScreenGui')
gui.Name='StillHereLoading'
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.DisplayOrder=10000
gui.Parent=pg
local background=Instance.new('Frame')
background.Name='LoadingBackground'
background.Size=UDim2.fromScale(1,1)
background.BackgroundColor3=Color3.fromRGB(5,6,8)
background.BorderSizePixel=0
background.Parent=gui
local gradient=Instance.new('UIGradient')
gradient.Rotation=90
gradient.Color=ColorSequence.new(Color3.fromRGB(18,19,22),Color3.fromRGB(3,4,6))
gradient.Parent=background
local eyebrow=Instance.new('TextLabel')
eyebrow.Name='LoadingBrand'
eyebrow.Position=UDim2.new(0,28,0,28)
eyebrow.Size=UDim2.new(.8,0,0,22)
eyebrow.BackgroundTransparency=1
eyebrow.Text='STILL HERE'
eyebrow.TextXAlignment=Enum.TextXAlignment.Left
eyebrow.Font=Enum.Font.RobotoCondensed
eyebrow.TextSize=14
eyebrow.TextColor3=Color3.fromRGB(178,177,169)
eyebrow.Parent=background
local title=Instance.new('TextLabel')
title.Name='LoadingTitle'
title.AnchorPoint=Vector2.new(0,1)
title.Position=UDim2.new(0,28,1,-100)
title.Size=UDim2.new(.82,0,0,44)
title.BackgroundTransparency=1
title.Text='MISTÉRIO'
title.TextXAlignment=Enum.TextXAlignment.Left
title.Font=Enum.Font.RobotoCondensed
title.TextSize=30
title.TextColor3=Color3.fromRGB(237,231,219)
title.Parent=background
local caption=Instance.new('TextLabel')
caption.Name='LoadingCaption'
caption.AnchorPoint=Vector2.new(1,1)
caption.Position=UDim2.new(1,-28,1,-30)
caption.Size=UDim2.new(.65,0,0,28)
caption.BackgroundTransparency=1
caption.Text='Carregando o casarão…'
caption.TextXAlignment=Enum.TextXAlignment.Right
caption.Font=Enum.Font.Garamond
caption.TextSize=17
caption.TextColor3=Color3.fromRGB(204,202,193)
caption.Parent=background
local hint=caption:Clone()
hint.Name='LoadingHint'
hint.AnchorPoint=Vector2.new(0,1)
hint.Position=UDim2.new(0,28,1,-62)
hint.TextXAlignment=Enum.TextXAlignment.Left
hint.TextTransparency=1
hint.Text=''
hint.Parent=background
local track=Instance.new('Frame')
track.Name='LoadingProgressTrack'
track.Position=UDim2.new(.04,0,1,-10)
track.Size=UDim2.new(.92,0,0,2)
track.BackgroundColor3=Color3.fromRGB(112,109,102)
track.BackgroundTransparency=.52
track.BorderSizePixel=0
track.Parent=background
local fill=Instance.new('Frame')
fill.Name='LoadingProgress'
fill.Size=UDim2.fromScale(.28,1)
fill.BackgroundColor3=Color3.fromRGB(219,207,181)
fill.BorderSizePixel=0
fill.Parent=track
RF:RemoveDefaultLoadingScreen()
local settings=RS:WaitForChild('SessionInterface')
local ui=require(settings)
task.spawn(function()
 if not ui.Load() then warn('[Configurações] As preferências não carregaram; usando os padrões.') end
end)
local active=true
local hints={'Use E para interagir.','Explore os cômodos.','Aproxime-se das cadeiras para sentar.'}
task.spawn(function()
 while active do
  task.wait(10)
  if not active then return end
  if player:GetAttribute('LoadingHints')~=false then
   hint.Text=hints[math.random(1,#hints)]
   Tween:Create(hint,TweenInfo.new(1.2),{TextTransparency=.24}):Play()
   task.wait(4)
   if active then Tween:Create(hint,TweenInfo.new(1.2),{TextTransparency=1}):Play() end
  end
 end
end)
local progress=Tween:Create(fill,TweenInfo.new(1.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Position=UDim2.new(.72,0,0,0)})
progress:Play()
local started=os.clock()
while true do
 if workspace:GetAttribute('GameMode')=='Match' and player:GetAttribute('ArrivalReady') then break end
 if os.clock()-started>45 then caption.Text='Carregando… conexão lenta.' end
 task.wait(.1)
end
active=false
progress:Cancel()
Tween:Create(background,TweenInfo.new(.3),{BackgroundTransparency=1}):Play()
Tween:Create(eyebrow,TweenInfo.new(.2),{TextTransparency=1}):Play()
Tween:Create(title,TweenInfo.new(.2),{TextTransparency=1}):Play()
Tween:Create(caption,TweenInfo.new(.2),{TextTransparency=1}):Play()
Tween:Create(hint,TweenInfo.new(.2),{TextTransparency=1}):Play()
Tween:Create(fill,TweenInfo.new(.2),{BackgroundTransparency=1}):Play()
task.wait(.35)
gui:Destroy()
local controls=Instance.new('ScreenGui')
controls.Name='InGameSettings'
controls.ResetOnSpawn=false
controls.IgnoreGuiInset=false
controls.DisplayOrder=100
controls.Parent=pg
local button=ui.Button(controls,'⚙',ui.OpenSettings)
button.Name='SettingsButton'
button.AnchorPoint=Vector2.new(1,0)
button.Position=UDim2.new(1,-10,0,6)
button.Size=UDim2.fromOffset(44,44)
button.TextSize=27
button.TextXAlignment=Enum.TextXAlignment.Center
