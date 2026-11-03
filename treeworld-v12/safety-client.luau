local player=game.Players.LocalPlayer
local event=game.ReplicatedStorage:WaitForChild('LivingForest'):WaitForChild('SafetyEvent')
local locale=string.sub(player.LocaleId,1,2)
local gui=Instance.new('ScreenGui');gui.Name='ForestSafety';gui.ResetOnSpawn=false;gui.DisplayOrder=110;gui.Parent=player.PlayerGui
local network=Instance.new('Frame');network.Size=UDim2.fromOffset(96,28);network.Position=UDim2.new(1,-108,0,14);network.BackgroundColor3=Color3.fromRGB(22,33,28);network.BackgroundTransparency=.2;network.Parent=gui
Instance.new('UICorner',network).CornerRadius=UDim.new(0,8)
local label=Instance.new('TextLabel');label.BackgroundTransparency=1;label.Position=UDim2.fromOffset(30,0);label.Size=UDim2.new(1,-32,1,0);label.Font=Enum.Font.Gotham;label.TextSize=12;label.TextColor3=Color3.new(1,1,1);label.Text='…';label.Parent=network
local bars={};for i=1,3 do local b=Instance.new('Frame');b.Size=UDim2.fromOffset(4,4+i*4);b.Position=UDim2.fromOffset(6+(i-1)*7,23-b.Size.Y.Offset);b.BorderSizePixel=0;b.Parent=network;bars[i]=b end
local warning=Instance.new('TextLabel');warning.AnchorPoint=Vector2.new(.5,.5);warning.Position=UDim2.fromScale(.5,.43);warning.Size=UDim2.new(.85,0,0,145);warning.BackgroundColor3=Color3.fromRGB(37,32,23);warning.BackgroundTransparency=.05;warning.TextColor3=Color3.fromRGB(255,236,197);warning.Font=Enum.Font.GothamMedium;warning.TextSize=18;warning.TextWrapped=true;warning.Visible=false;warning.Parent=gui
Instance.new('UICorner',warning).CornerRadius=UDim.new(0,14)
local constraint=Instance.new('UISizeConstraint');constraint.MaxSize=Vector2.new(520,160);constraint.Parent=warning
local pad=Instance.new('UIPadding');pad.PaddingLeft=UDim.new(0,24);pad.PaddingRight=UDim.new(0,24);pad.Parent=warning
local messages={
 pt={move='Aviso de movimento\n\nDetectamos um deslocamento fora dos limites do jogo. Se estiver usando modificações de movimento, desative-as. A repetição pode encerrar esta sessão.',conduct='Aviso de convivência\n\nRespeite as outras pessoas e as regras do jogo. Evite repetir mensagens ou comportamentos que atrapalhem a experiência.'},
 en={move='Movement warning\n\nMovement exceeded the game limits. Disable movement modifications if you use them. Repeated violations may end this session.',conduct='Community warning\n\nRespect other players and the game rules. Avoid repeated messages or behavior that disrupts the experience.'},
 es={move='Aviso de movimiento\n\nEl desplazamiento superó los límites del juego. Desactiva las modificaciones de movimiento si las usas. La repetición puede cerrar esta sesión.',conduct='Aviso de convivencia\n\nRespeta a los demás y las reglas del juego. Evita mensajes repetidos o comportamientos que interrumpan la experiencia.'}}
local token=0
event.OnClientEvent:Connect(function(kind,data)
 if type(data)~='table' then return end
 if kind=='network'then
  local colors={green=Color3.fromRGB(125,213,149),yellow=Color3.fromRGB(244,197,84),red=Color3.fromRGB(233,109,104)}
  for _,b in ipairs(bars)do b.BackgroundColor3=colors[data.quality]or colors.yellow end
  label.Text=tostring(data.ms)..' ms'
 elseif kind=='warning'then token+=1;local mine=token;local words=messages[locale]or messages.en
  warning.Text=data.code=='conduct'and words.conduct or words.move;warning.Visible=true
  task.delay(8,function()if token==mine then warning.Visible=false end end)
 end
end)
