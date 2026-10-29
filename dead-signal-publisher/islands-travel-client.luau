local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Tween=game:GetService('TweenService')
local p=Players.LocalPlayer;local remote=RS:WaitForChild('IslandTravel',20);if not remote then warn('IslandTravel unavailable');return end
local function make(class,props,parent)
 local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local old=p.PlayerGui:FindFirstChild('IslandMap');if old then old:Destroy() end
local gui=make('ScreenGui',{Name='IslandMap',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=30,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},p.PlayerGui)
local icon=make('TextButton',{Name='MapButton',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-16,0,12),Size=UDim2.fromOffset(52,52),Text='🗺️',TextSize=29,Font=Enum.Font.Gotham,BackgroundColor3=Color3.fromRGB(24,31,25),BackgroundTransparency=.18,TextColor3=Color3.new(1,1,1),AutoButtonColor=true},gui)
icon.Visible=workspace:GetAttribute('IslandWorldReady')==true
workspace:GetAttributeChangedSignal('IslandWorldReady'):Connect(function() icon.Visible=workspace:GetAttribute('IslandWorldReady')==true end)
make('UICorner',{CornerRadius=UDim.new(0,15)},icon);make('UIStroke',{Color=Color3.fromRGB(176,189,155),Transparency=.5},icon)
local panel=make('Frame',{Name='Destinations',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-16,0,74),Size=UDim2.fromOffset(258,246),BackgroundColor3=Color3.fromRGB(20,28,23),BackgroundTransparency=.08,Visible=false},gui)
make('UICorner',{CornerRadius=UDim.new(0,14)},panel);make('UIStroke',{Color=Color3.fromRGB(175,187,153),Transparency=.55},panel)
make('TextLabel',{Position=UDim2.fromOffset(16,10),Size=UDim2.new(1,-32,0,25),BackgroundTransparency=1,Text='EXPLORAR',TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(226,234,207)},panel)
local status=make('TextLabel',{Position=UDim2.fromOffset(12,216),Size=UDim2.new(1,-24,0,23),BackgroundTransparency=1,Text='Escolha onde aparecer.',Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.fromRGB(182,194,170),TextWrapped=true},panel)
local buttons={};local busy=false;local serial=0
for i,entry in ipairs({{'city','1. Cidade'},{'forest1','2. Floresta (1)'},{'forestCurrent','3. Floresta (atual)'}}) do
 local id,text=entry[1],entry[2]
 local b=make('TextButton',{Name=id,Position=UDim2.fromOffset(12,43+(i-1)*57),Size=UDim2.new(1,-24,0,49),Text=text,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamMedium,TextSize=15,TextColor3=Color3.fromRGB(235,240,225),BackgroundColor3=Color3.fromRGB(48,62,48),AutoButtonColor=true},panel)
 make('UICorner',{CornerRadius=UDim.new(0,9)},b);make('UIPadding',{PaddingLeft=UDim.new(0,14)},b);buttons[id]=b
 b.Activated:Connect(function()
  if busy then return end
  busy=true;serial+=1;local request=serial;status.Text='Carregando destino…';remote:FireServer(id)
  task.delay(12,function() if busy and serial==request then busy=false;status.Text='Demorou para carregar. Tenta de novo.' end end)
 end)
end
local function refresh()
 for id,b in pairs(buttons) do b.BackgroundColor3=p:GetAttribute('IslandDestination')==id and Color3.fromRGB(76,93,57) or Color3.fromRGB(48,62,48) end
end
p:GetAttributeChangedSignal('IslandDestination'):Connect(refresh);refresh()
icon.Activated:Connect(function()
 panel.Visible=not panel.Visible
 if panel.Visible then panel.Position=UDim2.new(1,-16,0,68);Tween:Create(panel,TweenInfo.new(.16),{Position=UDim2.new(1,-16,0,74)}):Play() end
end)
remote.OnClientEvent:Connect(function(ok,message)
 busy=false;serial+=1
 if ok then
  panel.Visible=false;status.Text='Escolha onde aparecer.';refresh()
  local fx=p.PlayerScripts:FindFirstChild('ForestTravelFx');if fx then fx:Fire() end
 else status.Text=message end
end)
