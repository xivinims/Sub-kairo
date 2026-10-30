local W=workspace
while not W:GetAttribute('GameMode') do task.wait(.1) end
if W:GetAttribute('GameMode')~='Match' or W:GetAttribute('SelectedChapter')~=2 then return end
local map=W:WaitForChild('ChapterTwoWorld',20)
if not map then warn('[ChapterTwo] Map did not load');return end
local Players=game:GetService('Players')
local fragments=map:WaitForChild('MemoryFragments')
local generator=map:WaitForChild('GeneratorConsole'):FindFirstChild('RestartGenerator')
local exitDoor=map:WaitForChild('ExitDoor')
local exit=exitDoor:FindFirstChild('OpenExit')
local count=0
local powered=false
local complete=false
W:SetAttribute('ChapterTwoFragments',0)
W:SetAttribute('ChapterTwoGeneratorActive',false)
W:SetAttribute('ChapterTwoComplete',false)
local function objective()
 if complete then return 'SINAL RESTABELECIDO · CAPÍTULO CONCLUÍDO' end
 if not powered then
  if count<3 then return 'RECUPERE OS FRAGMENTOS DE MEMÓRIA · '..count..'/3' end
  return 'LEVE OS FRAGMENTOS AO GERADOR DA ESTUFA'
 end
 return 'ENCONTRE A PORTA DE EMERGÊNCIA E FUJA'
end
local function refresh()
 W:SetAttribute('ChapterTwoFragments',count)
 W:SetAttribute('ChapterTwoObjective',objective())
end
for _,fragment in ipairs(fragments:GetChildren()) do
 local prompt=fragment:FindFirstChild('RecoverMemory')
 if prompt then
  prompt.Triggered:Connect(function(player)
   if fragment:GetAttribute('Collected') or powered then return end
   fragment:SetAttribute('Collected',true)
   prompt.Enabled=false
   fragment.Transparency=1
   local light=fragment:FindFirstChildOfClass('PointLight')
   if light then light.Enabled=false end
   count=math.min(count+1,3)
   if count>=3 then generator.Enabled=true end
   refresh()
  end)
 end
end
generator.Triggered:Connect(function(player)
 if powered or count<3 then return end
 powered=true
 generator.Enabled=false
 W:SetAttribute('ChapterTwoGeneratorActive',true)
 exit.Enabled=true
 for _,light in ipairs(map:GetDescendants()) do
  if light:IsA('PointLight') then
   light.Color=Color3.fromRGB(173,203,148)
   light.Brightness=1.1
   light.Range=31
   light.Enabled=true
  end
 end
 refresh()
end)
exit.Triggered:Connect(function(player)
 if complete or not powered then return end
 complete=true;exit.Enabled=false
 exitDoor.CanCollide=false;exitDoor.Transparency=.42
 W:SetAttribute('ChapterTwoComplete',true)
 player:SetAttribute('ChapterTwoComplete',true)
 refresh()
end)
Players.PlayerAdded:Connect(function(player)
 if complete then player:SetAttribute('ChapterTwoComplete',true) end
end)
refresh()
task.spawn(function()
 local phase=0
 while W.Parent and not powered do
  phase+=1
  for _,light in ipairs(map:GetDescendants()) do
   if light:IsA('PointLight') and light.Parent and light.Parent.Name:find('Bulb') then
    light.Enabled=math.random()>0.23
   end
  end
  task.wait(math.random(2,5))
 end
end)
