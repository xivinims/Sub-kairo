local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' or W:GetAttribute('SelectedChapter')==2 then return end
local Players=game:GetService('Players');local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui')
local gui=Instance.new('ScreenGui');gui.Name='MissionTop';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=40;gui.Parent=pg
local panel=Instance.new('Frame');panel.Name='MissionObjectivePanel';panel.Position=UDim2.new(0,18,0,14);panel.Size=UDim2.new(.48,0,0,72);panel.BackgroundColor3=Color3.fromRGB(18,18,18);panel.BackgroundTransparency=.18;panel.BorderSizePixel=0;panel.Parent=gui
Instance.new('UICorner',panel).CornerRadius=UDim.new(0,4)
local limit=Instance.new('UISizeConstraint');limit.MinSize=Vector2.new(230,72);limit.MaxSize=Vector2.new(470,72);limit.Parent=panel
local edge=Instance.new('UIStroke');edge.Color=Color3.fromRGB(137,132,125);edge.Thickness=1;edge.Transparency=.78;edge.Parent=panel
local accent=Instance.new('Frame');accent.Name='ObjectiveAccent';accent.Position=UDim2.new(0,0,0,8);accent.Size=UDim2.new(0,2,1,-16);accent.BackgroundColor3=Color3.fromRGB(177,54,57);accent.BorderSizePixel=0;accent.Parent=panel
local eyebrow=Instance.new('TextLabel');eyebrow.Name='ChapterLabel';eyebrow.Position=UDim2.new(0,15,0,7);eyebrow.Size=UDim2.new(1,-24,0,16);eyebrow.BackgroundTransparency=1;eyebrow.Text='EPISÓDIO 1   /   OBJETIVO';eyebrow.TextColor3=Color3.fromRGB(171,166,158);eyebrow.Font=Enum.Font.RobotoCondensed;eyebrow.TextSize=10;eyebrow.TextXAlignment=Enum.TextXAlignment.Left;eyebrow.Parent=panel
local text=Instance.new('TextLabel');text.Name='Objective';text.Position=UDim2.new(0,15,0,25);text.Size=UDim2.new(1,-24,0,40);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(235,232,220);text.Font=Enum.Font.RobotoCondensed;text.TextSize=16;text.TextXAlignment=Enum.TextXAlignment.Left;text.TextYAlignment=Enum.TextYAlignment.Center;text.TextWrapped=true;text.Parent=panel
local textLimit=Instance.new('UITextSizeConstraint');textLimit.MinTextSize=12;textLimit.MaxTextSize=17;textLimit.Parent=text
local missions={OpenHouseDoor='Encontre a chave e abra a porta da mansão.',Son='Investigue o escritório e recupere a fotografia.',Mother='Encontre as peças e complete o manequim.',Father='Encontre os ingredientes e complete a receita.',Daughter='Encontre as peças e restaure a escultura.',Grandmother='Encontre as peças da estátua no solário.',Grandfather='Encontre as velas e complete o ritual.'}
local current;local generation=0;local fade
local function objective()
 local state=W:GetAttribute('OriginalMissionState');local name=W:GetAttribute('OriginalMissionName')
 if state==11 then return missions[name] or 'Explore o cômodo e resolva o enigma.' end
 if state==6 or state==17 then return 'Explore a mansão e procure os objetos da família.' end
 if state==7 then return 'Leia a lembrança encontrada.' end
 if state==15 then return 'Recolha o objeto restaurado.' end
 if state==16 then return 'Leve o objeto restaurado ao ritual no hall.' end
 if state==18 or state==19 or state==20 then return 'Prepare-se para o ritual final.' end
 if state==21 then return 'Encontre a saída da mansão.' end
 if state and state>=8 and state<=14 then return current or 'Investigue a mansão.' end
 return 'Explore os arredores e encontre a entrada da mansão.'
end
local function refresh()
 local nextText=objective();if nextText==current then return end
 local first=current==nil;current=nextText;generation+=1;local token=generation
 if fade then fade:Cancel() end
 text.Text=(first and 'Missão: ' or 'Nova missão: ')..nextText;text.TextTransparency=1
 fade=Tween:Create(text,TweenInfo.new(.45),{TextTransparency=0});fade:Play()
 Tween:Create(accent,TweenInfo.new(.24,Enum.EasingStyle.Quad),{BackgroundTransparency=.08}):Play()
 if not first then task.delay(5,function() if token==generation and gui.Parent then text.Text='Missão: '..nextText end end) end
end
W:GetAttributeChangedSignal('OriginalMissionState'):Connect(refresh)
W:GetAttributeChangedSignal('OriginalMissionName'):Connect(function() task.defer(refresh) end)
refresh()

local function visibility() gui.Enabled=player:GetAttribute("ShowObjectives")~=false end
player:GetAttributeChangedSignal("ShowObjectives"):Connect(visibility);visibility()
