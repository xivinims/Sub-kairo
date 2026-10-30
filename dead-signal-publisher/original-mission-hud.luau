local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui')
local gui=Instance.new('ScreenGui');gui.Name='MissionTop';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=40;gui.Parent=pg
local text=Instance.new('TextLabel');text.Name='Objective';text.AnchorPoint=Vector2.new(.5,0);text.Position=UDim2.new(.5,0,0,12);text.Size=UDim2.new(.76,0,0,46);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(235,232,220);text.TextStrokeColor3=Color3.new(0,0,0);text.TextStrokeTransparency=.35;text.Font=Enum.Font.Garamond;text.TextSize=20;text.TextWrapped=true;text.Parent=gui
local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(720,70);limit.Parent=text
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
 if not first then task.delay(5,function() if token==generation and gui.Parent then text.Text='Missão: '..nextText end end) end
end
W:GetAttributeChangedSignal('OriginalMissionState'):Connect(refresh)
W:GetAttributeChangedSignal('OriginalMissionName'):Connect(function() task.defer(refresh) end)
refresh()

local function visibility() gui.Enabled=player:GetAttribute("ShowObjectives")~=false end
player:GetAttributeChangedSignal("ShowObjectives"):Connect(visibility);visibility()
