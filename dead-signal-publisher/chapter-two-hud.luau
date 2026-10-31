local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' or W:GetAttribute('SelectedChapter')~=2 then return end
local player=game:GetService('Players').LocalPlayer
local Tween=game:GetService('TweenService')
local gui=Instance.new('ScreenGui')
gui.Name='ChapterTwoHUD';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false
gui.DisplayOrder=55;gui.Parent=player:WaitForChild('PlayerGui')
local card=Instance.new('Frame')
card.Name='ObjectiveCard';card.Position=UDim2.new(0,22,0,12)
card.Size=UDim2.new(0,390,0,94);card.BackgroundColor3=Color3.fromRGB(6,12,10)
card.BackgroundTransparency=1;card.BorderSizePixel=0;card.Parent=gui
local camera=workspace.CurrentCamera
local function fitCard()
 local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
 card.Size=UDim2.new(0,math.min(390,math.max(230,viewport.X-44)),0,94)
end
fitCard()
if camera then camera:GetPropertyChangedSignal('ViewportSize'):Connect(fitCard) end
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,6);corner.Parent=card
local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(107,137,111);stroke.Transparency=1;stroke.Parent=card
local accent=Instance.new('Frame');accent.Name='EpisodeAccent';accent.Position=UDim2.new(0,0,0,8);accent.Size=UDim2.new(0,2,1,-16);accent.BackgroundColor3=Color3.fromRGB(115,162,122);accent.BackgroundTransparency=1;accent.BorderSizePixel=0;accent.Parent=card
local eyebrow=Instance.new('TextLabel')
eyebrow.Name='ChapterLabel';eyebrow.BackgroundTransparency=1
eyebrow.Position=UDim2.new(0,15,0,9);eyebrow.Size=UDim2.new(1,-30,0,20)
eyebrow.Text='STILL HERE  /  EPISÓDIO 02'
eyebrow.TextXAlignment=Enum.TextXAlignment.Left
eyebrow.Font=Enum.Font.RobotoCondensed;eyebrow.TextSize=12
eyebrow.TextColor3=Color3.fromRGB(155,181,157);eyebrow.TextTransparency=1;eyebrow.Parent=card
local objective=Instance.new('TextLabel')
objective.Name='Objective';objective.BackgroundTransparency=1
objective.Position=UDim2.new(0,15,0,33);objective.Size=UDim2.new(1,-30,0,42)
objective.TextWrapped=true;objective.TextXAlignment=Enum.TextXAlignment.Left
objective.TextYAlignment=Enum.TextYAlignment.Top
objective.Font=Enum.Font.RobotoCondensed;objective.TextSize=17
objective.TextColor3=Color3.fromRGB(232,233,222);objective.TextTransparency=1;objective.Parent=card
local count=Instance.new('TextLabel')
count.Name='FragmentCount';count.AnchorPoint=Vector2.new(1,0)
count.Position=UDim2.new(1,-15,0,8);count.Size=UDim2.new(0,80,0,20)
count.BackgroundTransparency=1;count.TextXAlignment=Enum.TextXAlignment.Right
count.Font=Enum.Font.RobotoCondensed;count.TextSize=12
count.TextColor3=Color3.fromRGB(173,193,171);count.TextTransparency=1;count.Parent=card
local function refresh()
 local found=math.clamp(tonumber(W:GetAttribute('ChapterTwoFragments')) or 0,0,3)
 objective.Text=W:GetAttribute('ChapterTwoObjective') or 'EXPLORE A ESTUFA E RECUPERE OS FRAGMENTOS'
 count.Text=string.format('%d / 3',found)
 if W:GetAttribute('ChapterTwoComplete') then
  objective.TextColor3=Color3.fromRGB(185,224,174)
  count.Text='CONCLUÍDO'
  Tween:Create(stroke,TweenInfo.new(.3),{Color=Color3.fromRGB(155,198,148)}):Play()
 else
  objective.TextColor3=Color3.fromRGB(232,233,222)
 end
end
W:GetAttributeChangedSignal('ChapterTwoFragments'):Connect(refresh)
W:GetAttributeChangedSignal('ChapterTwoObjective'):Connect(refresh)
W:GetAttributeChangedSignal('ChapterTwoComplete'):Connect(refresh)
refresh()
Tween:Create(card,TweenInfo.new(.38,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(0,22,0,20),BackgroundTransparency=.22}):Play()
Tween:Create(stroke,TweenInfo.new(.38,Enum.EasingStyle.Quad),{Transparency=.42}):Play()
Tween:Create(accent,TweenInfo.new(.38,Enum.EasingStyle.Quad),{BackgroundTransparency=0}):Play()
for _,label in ipairs({eyebrow,objective,count}) do Tween:Create(label,TweenInfo.new(.3,Enum.EasingStyle.Quad),{TextTransparency=0}):Play() end
