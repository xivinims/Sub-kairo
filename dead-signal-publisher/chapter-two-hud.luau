local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' or W:GetAttribute('SelectedChapter')~=2 then return end
local player=game:GetService('Players').LocalPlayer
local gui=Instance.new('ScreenGui')
gui.Name='ChapterTwoHUD';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false
gui.DisplayOrder=55;gui.Parent=player:WaitForChild('PlayerGui')
local card=Instance.new('Frame')
card.Name='ObjectiveCard';card.Position=UDim2.new(0,22,0,20)
card.Size=UDim2.new(0,390,0,94);card.BackgroundColor3=Color3.fromRGB(6,12,10)
card.BackgroundTransparency=.22;card.BorderSizePixel=0;card.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,6);corner.Parent=card
local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(107,137,111);stroke.Transparency=.42;stroke.Parent=card
local eyebrow=Instance.new('TextLabel')
eyebrow.Name='ChapterLabel';eyebrow.BackgroundTransparency=1
eyebrow.Position=UDim2.new(0,15,0,9);eyebrow.Size=UDim2.new(1,-30,0,20)
eyebrow.Text='STILL HERE  /  CAPÍTULO 02'
eyebrow.TextXAlignment=Enum.TextXAlignment.Left
eyebrow.Font=Enum.Font.RobotoCondensed;eyebrow.TextSize=12
eyebrow.TextColor3=Color3.fromRGB(155,181,157);eyebrow.Parent=card
local objective=Instance.new('TextLabel')
objective.Name='Objective';objective.BackgroundTransparency=1
objective.Position=UDim2.new(0,15,0,33);objective.Size=UDim2.new(1,-30,0,42)
objective.TextWrapped=true;objective.TextXAlignment=Enum.TextXAlignment.Left
objective.TextYAlignment=Enum.TextYAlignment.Top
objective.Font=Enum.Font.RobotoCondensed;objective.TextSize=17
objective.TextColor3=Color3.fromRGB(232,233,222);objective.Parent=card
local count=Instance.new('TextLabel')
count.Name='FragmentCount';count.AnchorPoint=Vector2.new(1,0)
count.Position=UDim2.new(1,-15,0,8);count.Size=UDim2.new(0,80,0,20)
count.BackgroundTransparency=1;count.TextXAlignment=Enum.TextXAlignment.Right
count.Font=Enum.Font.RobotoCondensed;count.TextSize=12
count.TextColor3=Color3.fromRGB(173,193,171);count.Parent=card
local function refresh()
 local found=math.clamp(tonumber(W:GetAttribute('ChapterTwoFragments')) or 0,0,3)
 objective.Text=W:GetAttribute('ChapterTwoObjective') or 'EXPLORE A ESTUFA E RECUPERE OS FRAGMENTOS'
 count.Text=string.format('%d / 3',found)
 if W:GetAttribute('ChapterTwoComplete') then
  objective.TextColor3=Color3.fromRGB(185,224,174)
  count.Text='CONCLUÍDO'
 else
  objective.TextColor3=Color3.fromRGB(232,233,222)
 end
end
W:GetAttributeChangedSignal('ChapterTwoFragments'):Connect(refresh)
W:GetAttributeChangedSignal('ChapterTwoObjective'):Connect(refresh)
W:GetAttributeChangedSignal('ChapterTwoComplete'):Connect(refresh)
refresh()
