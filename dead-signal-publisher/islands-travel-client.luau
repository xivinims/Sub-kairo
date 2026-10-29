-- 🗺️ Minimal map glyph, left cinematic gradient and exactly three destinations.
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Tween=game:GetService('TweenService')
local Input=game:GetService('UserInputService');local GuiService=game:GetService('GuiService')
local p=Players.LocalPlayer;local remote=RS:WaitForChild('IslandTravel',20);if not remote then warn('IslandTravel unavailable');return end
local function make(class,props,parent)
 local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local old=p.PlayerGui:FindFirstChild('IslandMap');if old then old:Destroy() end
local gui=make('ScreenGui',{Name='IslandMap',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=30,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},p.PlayerGui)
local overlay=make('CanvasGroup',{Name='LeftGradient',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,GroupTransparency=1,Visible=false},gui)
local dismiss=make('TextButton',{Name='DismissArea',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text='',AutoButtonColor=false,Selectable=false},overlay)
local shade=make('Frame',{Name='Shade',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Active=false},dismiss)
make('UIGradient',{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.06),NumberSequenceKeypoint.new(.28,.13),NumberSequenceKeypoint.new(.58,.65),NumberSequenceKeypoint.new(.86,1),NumberSequenceKeypoint.new(1,1)})},shade)
local holder=make('Frame',{Name='Destinations',AnchorPoint=Vector2.new(0,.5),Position=UDim2.fromScale(.06,.56),Size=UDim2.new(.36,0,0,184),BackgroundTransparency=1},overlay)
make('UISizeConstraint',{MinSize=Vector2.new(210,184),MaxSize=Vector2.new(340,184)},holder)
local status=make('TextLabel',{Name='Status',Position=UDim2.new(0,0,1,8),Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Text='',Font=Enum.Font.Code,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextColor3=Color3.fromRGB(205,210,220),TextWrapped=true},holder)
local inset=GuiService:GetGuiInset()
local icon=make('TextButton',{Name='MapButton',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0,inset.Y+10),Size=UDim2.fromOffset(48,48),Text='',BackgroundTransparency=1,AutoButtonColor=false,ZIndex=10},gui)
local glyph=make('Frame',{Name='MapGlyph',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(27,25),BackgroundTransparency=1,ZIndex=11},icon)
local function line(x1,y1,x2,y2)
 local a,b=Vector2.new(x1,y1),Vector2.new(x2,y2);local d=b-a
 make('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2),Size=UDim2.fromOffset(d.Magnitude,1.5),Rotation=math.deg(math.atan2(d.Y,d.X)),BackgroundColor3=Color3.fromRGB(239,242,246),BorderSizePixel=0,ZIndex=11},glyph)
end
for _,s in ipairs({{0,4,9,0},{9,0,18,4},{18,4,27,0},{27,0,27,21},{27,21,18,25},{18,25,9,21},{9,21,0,25},{0,25,0,4},{9,0,9,21},{18,4,18,25}}) do line(unpack(s)) end
local open,busy=false,false;local serial=0;local transition;local firstButton
local buttons={};local strokes={}
local function setOpen(value)
 open=value
 if transition then transition:Cancel() end
 if open then overlay.Visible=true end
 transition=Tween:Create(overlay,TweenInfo.new(.24,Enum.EasingStyle.Sine),{GroupTransparency=open and 0 or 1});transition:Play()
 local expected=open
 transition.Completed:Once(function() if open==expected and not open then overlay.Visible=false end end)
 if Input.GamepadEnabled then GuiService.SelectedObject=open and firstButton or nil end
end
local function refresh()
 for id,b in pairs(buttons) do
  local selected=p:GetAttribute('IslandDestination')==id
  strokes[id].Transparency=selected and .08 or .5
  b.TextColor3=selected and Color3.new(1,1,1) or Color3.fromRGB(215,218,226)
 end
end
for i,entry in ipairs({{'city','CIDADE'},{'forest1','FLORESTA (1)'},{'forestCurrent','FLORESTA (ATUAL)'}}) do
 local id,text=entry[1],entry[2]
 local b=make('TextButton',{Name=id,Position=UDim2.fromOffset(0,(i-1)*58),Size=UDim2.new(1,0,0,48),Text=text,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Code,TextSize=17,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false},holder)
 make('UIPadding',{PaddingLeft=UDim.new(0,13)},b)
 strokes[id]=make('UIStroke',{Thickness=1,Color=Color3.fromRGB(228,233,241),Transparency=.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b);buttons[id]=b;firstButton=firstButton or b
 local function focus(active) Tween:Create(b,TweenInfo.new(.12),{BackgroundTransparency=active and .88 or 1}):Play() end
 b.MouseEnter:Connect(function() focus(true) end);b.MouseLeave:Connect(function() focus(false) end)
 b.SelectionGained:Connect(function() focus(true) end);b.SelectionLost:Connect(function() focus(false) end)
 b.Activated:Connect(function()
  if busy then return end
  busy=true;serial+=1;local request=serial;status.Text='Carregando destino…';remote:FireServer(id)
  task.delay(15,function() if busy and serial==request then busy=false;status.Text='Demorou para carregar. Tenta de novo.' end end)
 end)
end
p:GetAttributeChangedSignal('IslandDestination'):Connect(refresh);refresh()
local function readiness() icon.Visible=workspace:GetAttribute('IslandWorldReady')==true end
workspace:GetAttributeChangedSignal('IslandWorldReady'):Connect(readiness);readiness()
icon.Activated:Connect(function() setOpen(not open) end)
dismiss.Activated:Connect(function() setOpen(false) end)
Input.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.M and icon.Visible then setOpen(not open)
 elseif input.KeyCode==Enum.KeyCode.ButtonB and open then setOpen(false) end
end)
remote.OnClientEvent:Connect(function(ok,message)
 busy=false;serial+=1
 if ok then
  setOpen(false);status.Text='';refresh()
  local fx=p.PlayerScripts:FindFirstChild('ForestTravelFx');if fx then fx:Fire() end
 else status.Text=message end
end)
