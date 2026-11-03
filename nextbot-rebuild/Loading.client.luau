local Players=game:GetService('Players');local Content=game:GetService('ContentProvider');local Tween=game:GetService('TweenService')
local p=Players.LocalPlayer;local gui=Instance.new('ScreenGui');gui.Name='Loading';gui.IgnoreGuiInset=true;gui.DisplayOrder=150;gui.ResetOnSpawn=false;gui.Parent=p:WaitForChild('PlayerGui')
local bg=Instance.new('Frame');bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromRGB(11,13,26);bg.Parent=gui
local function label(value,y,size)
 local l=Instance.new('TextLabel');l.Text=value;l.Position=UDim2.fromScale(.1,y);l.Size=UDim2.fromScale(.8,.12);l.BackgroundTransparency=1;l.TextColor3=Color3.new(1,1,1);l.Font=Enum.Font.GothamBold;l.TextSize=size;l.Parent=bg;return l
end
local title=label('EXACT RUN',.32,52);local gradient=Instance.new('UIGradient');gradient.Color=ColorSequence.new(Color3.fromRGB(98,235,201),Color3.fromRGB(181,131,248));gradient.Parent=title
label('CARREGANDO INTERFACE',.47,25);local tip=label('Reanime seus colegas para ganhar moedas e experiência.',.83,16);tip.TextWrapped=true
local bar=Instance.new('Frame');bar.Size=UDim2.fromScale(0,.009);bar.Position=UDim2.fromScale(0,.991);bar.BackgroundColor3=Color3.fromRGB(142,215,255);bar.BorderSizePixel=0;bar.Parent=bg
local package=game:GetService('ReplicatedStorage'):WaitForChild('NextbotReference',20)
local complete=false
if package then
 local assets={package:GetAttribute('MenuAtlas')or '', 'rbxassetid://1836009626'};local count=0
 task.spawn(function()pcall(function()Content:PreloadAsync(assets,function()count+=1;bar.Size=UDim2.fromScale(math.min(count/#assets,1),.009)end)end);complete=true end)
end
local started=os.clock();repeat task.wait(.1)until (complete and p.Character)or os.clock()-started>12
bar.Size=UDim2.fromScale(1,.009)
for _,v in ipairs(bg:GetChildren())do if v:IsA('TextLabel')then Tween:Create(v,TweenInfo.new(.35),{TextTransparency=1}):Play()end end
Tween:Create(bg,TweenInfo.new(.35),{BackgroundTransparency=1}):Play();task.wait(.4);gui:Destroy()
