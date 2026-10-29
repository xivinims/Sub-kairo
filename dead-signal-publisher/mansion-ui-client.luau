while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Input=game:GetService('UserInputService');local Tween=game:GetService('TweenService');local Run=game:GetService('RunService')
local p=Players.LocalPlayer;local pg=p:WaitForChild('PlayerGui');local event=RS:WaitForChild('MansionEvent')
for _,template in ipairs(RS:WaitForChild('MansionOriginalUI'):GetChildren()) do local old=pg:FindFirstChild(template.Name);if old then old:Destroy() end;template:Clone().Parent=pg end
local hud=pg:WaitForChild('HUD');hud.Enabled=true;local frame=hud:WaitForChild('Frame')
local lightOn=false;local held=false;local peeking=false;local restoreCF;local restoreFov
local function lamp()
 lightOn=not lightOn;local head=p.Character and p.Character:FindFirstChild('Head');if not head then return end
 local light=head:FindFirstChild('MansionHeadlamp') or Instance.new('SpotLight');light.Name='MansionHeadlamp';light.Range=45;light.Angle=65;light.Brightness=2.2;light.Color=Color3.fromRGB(236,228,205);light.Shadows=false;light.Face=Enum.NormalId.Front;light.Enabled=lightOn;light.Parent=head
end
frame.HeadlampButton.Activated:Connect(lamp)
local function grab()
 if held then event:FireServer('release');held=false;return end
 local camera=workspace.CurrentCamera;local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Islands.mansion}
 local hit=workspace:Raycast(camera.CFrame.Position,camera.CFrame.LookVector*9,rp)
 if hit and hit.Instance:GetAttribute('MansionGrabbable') then event:FireServer('grab',hit.Instance);held=true end
end
frame.GrabReleaseButton.Activated:Connect(grab)
local function actionButton(name,text,x,callback)
 local button=Instance.new('TextButton');button.Name=name;button.AnchorPoint=Vector2.new(1,1);button.Size=UDim2.fromOffset(100,42);button.Position=UDim2.new(1,-x,1,-110);button.Text=text;button.TextSize=12;button.Font=Enum.Font.Code;button.TextColor3=Color3.fromRGB(231,231,218);button.BackgroundColor3=Color3.fromRGB(18,22,24);button.BackgroundTransparency=.3;button.Parent=hud;button.Activated:Connect(callback);return button
end
local sprint=false;actionButton('Sprint','CORRER',20,function() sprint=not sprint;event:FireServer('sprint',sprint) end)
local lock=actionButton('DoorLock','TRANCAR',130,function() event:FireServer('lock') end)
local function lockLabel() lock.Text=workspace:GetAttribute('MansionDoorLocked')~=false and 'DESTRANCAR' or 'TRANCAR' end
workspace:GetAttributeChangedSignal('MansionDoorLocked'):Connect(lockLabel);lockLabel()
local peekButton
local function exitPeek()
 if not peeking then return end;peeking=false;Input.MouseBehavior=Enum.MouseBehavior.LockCenter;local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Custom;camera.FieldOfView=restoreFov or 68;local vignette=pg:FindFirstChild('Screenspace_Vignette');if vignette then local image=vignette:FindFirstChildWhichIsA('ImageLabel',true);if image then image.ImageTransparency=.45 end end
end
peekButton=actionButton('Peephole','OLHO MÁGICO',240,function() if peeking then exitPeek() else event:FireServer('peek') end end)
local fade=Instance.new('Frame');fade.Name='OutsideFade';fade.Size=UDim2.fromScale(1,1);fade.BackgroundColor3=Color3.new(0,0,0);fade.BackgroundTransparency=1;fade.BorderSizePixel=0;fade.ZIndex=0;fade.Active=false;fade.Parent=hud
local function outside()
 local alpha=p:GetAttribute('InsideMansion') and 1 or .88;Tween:Create(fade,TweenInfo.new(1.2,Enum.EasingStyle.Sine),{BackgroundTransparency=alpha}):Play()
end
p:GetAttributeChangedSignal('InsideMansion'):Connect(outside)
event.OnClientEvent:Connect(function(kind,value)
 if kind=='peek' and typeof(value)=='CFrame' then
  local camera=workspace.CurrentCamera;restoreCF=camera.CFrame;restoreFov=camera.FieldOfView;peeking=true;Input.MouseBehavior=Enum.MouseBehavior.Default;local vignette=pg:FindFirstChild('Screenspace_Vignette');if vignette then local image=vignette:FindFirstChildWhichIsA('ImageLabel',true);if image then image.ImageTransparency=0 end end;camera.CameraType=Enum.CameraType.Scriptable
  Tween:Create(camera,TweenInfo.new(.45,Enum.EasingStyle.Sine),{CFrame=value,FieldOfView=100}):Play()
 elseif kind=='objective' then local text=frame:FindFirstChild('MissionCounterText');if text then text.Text=value;text.Visible=true end end
end)
Input.InputBegan:Connect(function(i,processed)
 if processed then return end
 if i.KeyCode==Enum.KeyCode.LeftShift then sprint=true;event:FireServer('sprint',true)
 elseif i.KeyCode==Enum.KeyCode.F then lamp()
 elseif i.KeyCode==Enum.KeyCode.G then grab()
 elseif i.KeyCode==Enum.KeyCode.L then event:FireServer('lock')
 elseif i.KeyCode==Enum.KeyCode.P then if peeking then exitPeek() else event:FireServer('peek') end end
end)
Input.InputEnded:Connect(function(i) if i.KeyCode==Enum.KeyCode.LeftShift then sprint=false;event:FireServer('sprint',false) end end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.25 then return end;elapsed=0
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local entrance=workspace:GetAttribute('EntrancePosition')
 local near=root and entrance and (root.Position-entrance).Magnitude<13
 lock.Visible=near==true;peekButton.Visible=near==true
 if peeking and not near then exitPeek() end
end)
p.CharacterAdded:Connect(function() exitPeek();held=false;sprint=false end)
event:FireServer('missionState')
