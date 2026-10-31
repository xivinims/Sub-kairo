local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer
local remote=RS:WaitForChild('MysteryUIAction')
local function make(class,parent,props)
 local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local gui=make('ScreenGui',player:WaitForChild('PlayerGui'),{Name='HotelPianoControls',IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=1790,Enabled=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
make('Frame',gui,{Name='Shade',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(5,7,8),BackgroundTransparency=.56,BorderSizePixel=0})
local header=make('Frame',gui,{Size=UDim2.new(1,0,0,58),BackgroundColor3=Color3.fromRGB(8,10,10),BackgroundTransparency=.15,BorderSizePixel=0})
make('UIGradient',header,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.04),NumberSequenceKeypoint.new(1,1)})})
make('TextLabel',header,{Position=UDim2.fromOffset(25,7),Size=UDim2.new(.62,0,0,26),BackgroundTransparency=1,Text='PIANO  ·  SALA DE MÚSICA',Font=Enum.Font.RobotoCondensed,TextSize=20,TextColor3=Color3.fromRGB(239,226,201),TextXAlignment=Enum.TextXAlignment.Left})
make('TextLabel',header,{Position=UDim2.fromOffset(26,33),Size=UDim2.new(.7,0,0,16),BackgroundTransparency=1,Text='TOQUE AS TECLAS OU ESCOLHA UMA MELODIA DO HOTEL',Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(164,161,153),TextXAlignment=Enum.TextXAlignment.Left})
local exit=make('TextButton',header,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-24,0,12),Size=UDim2.fromOffset(110,34),BackgroundColor3=Color3.fromRGB(42,43,40),BorderSizePixel=0,Text='SAIR  ·  ESC',Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(225,216,197),AutoButtonColor=false});make('UICorner',exit,{CornerRadius=UDim.new(0,4)})
local panel=make('Frame',gui,{Name='PianoPanel',AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-18),Size=UDim2.new(.86,0,0,270),BackgroundColor3=Color3.fromRGB(13,15,15),BackgroundTransparency=.04,BorderSizePixel=0});make('UICorner',panel,{CornerRadius=UDim.new(0,7)});make('UIStroke',panel,{Color=Color3.fromRGB(184,162,125),Transparency=.74,Thickness=1});make('UIGradient',panel,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(29,30,28),Color3.fromRGB(9,11,11))})
local status=make('TextLabel',panel,{Position=UDim2.new(0,18,0,9),Size=UDim2.new(.40,0,0,32),BackgroundTransparency=1,Text='ESCOLHA UMA NOTA',Font=Enum.Font.RobotoCondensed,TextSize=12,TextColor3=Color3.fromRGB(204,197,182),TextXAlignment=Enum.TextXAlignment.Left})
local songRow=make('Frame',panel,{Position=UDim2.new(.40,0,0,8),Size=UDim2.new(.58,-12,0,34),BackgroundTransparency=1})
make('UIListLayout',songRow,{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
local songList={{'VALSA','VALSA'},{'CAIXA','CAIXINHA'},{'LUAR','LUAR'},{'MISTERIO','MISTÉRIO'}}
for order,item in ipairs(songList) do
 local b=make('TextButton',songRow,{Name='Song_'..item[1],LayoutOrder=order,Size=UDim2.new(.25,-5,1,0),BackgroundColor3=Color3.fromRGB(49,48,43),BackgroundTransparency=.08,BorderSizePixel=0,Text=item[2],Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(229,216,190),TextWrapped=true,AutoButtonColor=false});make('UICorner',b,{CornerRadius=UDim.new(0,4)})
 b.Activated:Connect(function() if gui.Enabled then status.Text='TOCANDO '..item[2];remote:FireServer('piano_song',{id=item[1]}) end end)
end
local keyboard=make('Frame',panel,{Name='Keyboard',Position=UDim2.new(0,16,0,52),Size=UDim2.new(1,-32,1,-66),BackgroundColor3=Color3.fromRGB(5,6,6),BorderSizePixel=0});make('UICorner',keyboard,{CornerRadius=UDim.new(0,4)})
local noteNames={'DÓ','DÓ♯','RÉ','RÉ♯','MI','FÁ','FÁ♯','SOL','SOL♯','LÁ','LÁ♯','SI','DÓ'}
local hotkeys={'A','W','S','E','D','F','T','G','Y','H','U','J','K'}
local whiteIndices={0,2,4,5,7,9,11,12};local blackIndices={1,3,6,8,10};local whiteKeys={}
local function animateBlack(button)
 button.BackgroundColor3=Color3.fromRGB(104,79,49);task.delay(.12,function() if button.Parent then button.BackgroundColor3=Color3.fromRGB(27,28,28) end end)
end
local function playNote(index,fromServer)
 if not fromServer and not gui.Enabled then return end
 status.Text='NOTA '..noteNames[index+1]..'  ·  '..hotkeys[index+1]
 local key=whiteKeys[index]
 if key then
  key.BackgroundColor3=Color3.fromRGB(197,177,138);task.delay(.12,function() if key.Parent then key.BackgroundColor3=key:GetAttribute('BaseColor') end end)
 else
  for _,child in ipairs(keyboard:GetChildren()) do if child.Name=='BlackKey'..index then animateBlack(child) end end
 end
 if not fromServer then remote:FireServer('piano_note',{index=index}) end
end
for order,index in ipairs(whiteIndices) do
 local b=make('TextButton',keyboard,{Name='WhiteKey'..index,Position=UDim2.new((order-1)/8,0,0,0),Size=UDim2.new(1/8,-1,1,0),BackgroundColor3=Color3.fromRGB(233,225,207),BorderSizePixel=0,Text='',AutoButtonColor=false,ZIndex=3});b:SetAttribute('BaseColor',b.BackgroundColor3)
 make('TextLabel',b,{Position=UDim2.new(0,0,1,-36),Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=noteNames[index+1]..'  '..hotkeys[index+1],Font=Enum.Font.RobotoCondensed,TextSize=10,TextColor3=Color3.fromRGB(89,84,72),ZIndex=4})
 whiteKeys[index]=b;b.Activated:Connect(function() playNote(index,false) end)
end
for _,index in ipairs(blackIndices) do
 local before=math.floor(index/2);local b=make('TextButton',keyboard,{Name='BlackKey'..index,Position=UDim2.new((before+.65)/8,0,0,0),Size=UDim2.new(.56/8,0,.62,0),BackgroundColor3=Color3.fromRGB(27,28,28),BorderSizePixel=0,Text=hotkeys[index+1],Font=Enum.Font.RobotoCondensed,TextSize=9,TextColor3=Color3.fromRGB(200,187,165),AutoButtonColor=false,ZIndex=5});make('UICorner',b,{CornerRadius=UDim.new(0,0)})
 b.Activated:Connect(function() playNote(index,false) end)
end
local controls;local camera;local savedCamera={};local anchor;local renderConnection;local cameraTween
local function setControls(enabled)
 if enabled then if controls then controls:Enable();controls=nil end else pcall(function() local module=require(player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'));controls=module:GetControls();controls:Disable() end) end
end
local function goal()
 camera=workspace.CurrentCamera;if not camera or not anchor then return nil end
 local h=camera.ViewportSize.Y>camera.ViewportSize.X and 18 or 13
 local center=anchor.Position+Vector3.new(0,.8,0)
 return CFrame.lookAt(center+Vector3.new(6,h,7),center,Vector3.yAxis)
end
local function open(data)
 anchor=data and data.surface;if typeof(anchor)~='Instance' or not anchor:IsA('BasePart') then return end
 camera=workspace.CurrentCamera
 if camera then
  savedCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView};camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=58
  local destination=goal();if destination then cameraTween=Tween:Create(camera,TweenInfo.new(.65,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{CFrame=destination});cameraTween:Play() end
 end
 gui.Enabled=true;status.Text='ESCOLHA UMA NOTA';player:SetAttribute('InterfaceOpen',true);setControls(false)
 renderConnection=Run.RenderStepped:Connect(function() local destination=goal();camera=workspace.CurrentCamera;if destination and camera and camera.CameraType==Enum.CameraType.Scriptable then camera.CFrame=camera.CFrame:Lerp(destination,.065) end end)
end
local function close()
 if cameraTween then cameraTween:Cancel();cameraTween=nil end;if renderConnection then renderConnection:Disconnect();renderConnection=nil end
 gui.Enabled=false;player:SetAttribute('InterfaceOpen',false);setControls(true);camera=workspace.CurrentCamera
 if camera then camera.CameraType=savedCamera.type or Enum.CameraType.Custom;camera.CameraSubject=savedCamera.subject or (player.Character and player.Character:FindFirstChildOfClass('Humanoid'));camera.FieldOfView=savedCamera.fov or player:GetAttribute('PreferredFOV') or 70 end
 table.clear(savedCamera);anchor=nil
end
local function fit()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720);local compact=v.X<760 or v.Y>v.X
 panel.Size=compact and UDim2.new(.98,0,0,270) or UDim2.new(.86,0,0,270);panel.Position=UDim2.new(.5,0,1,compact and -8 or -18)
end
fit();if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(fit) end
exit.Activated:Connect(function() remote:FireServer('piano_exit') end)
remote.OnClientEvent:Connect(function(action,data)
 if action=='piano_open' then open(data)
 elseif action=='piano_close' then close()
 elseif action=='piano_note_visual' then local index=tonumber(data and data.index);if index and index>=0 and index<=12 then playNote(index,true) end end
end)
local byKey={};for i,key in ipairs(hotkeys) do byKey[Enum.KeyCode[key]]=i-1 end
Input.InputBegan:Connect(function(input,processed)
 if processed or not gui.Enabled then return end
 local index=byKey[input.KeyCode]
 if index~=nil then playNote(index,false) elseif input.KeyCode==Enum.KeyCode.Escape then remote:FireServer('piano_exit') end
end)
