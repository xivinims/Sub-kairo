while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local Input=game:GetService('UserInputService');local Tween=game:GetService('TweenService')
local p=Players.LocalPlayer;local event=RS:WaitForChild('CombatEvent');local assets=RS:WaitForChild('CombatAssets')
local gui=Instance.new('ScreenGui');gui.Name='CombatHUD';gui.ResetOnSpawn=false;gui.Parent=p:WaitForChild('PlayerGui')
local function label(text,pos,size,parent)
 local o=Instance.new('TextLabel');o.BackgroundTransparency=1;o.TextColor3=Color3.fromRGB(230,230,215);o.Font=Enum.Font.Code;o.TextSize=16;o.Text=text;o.Position=pos;o.Size=size;o.Parent=parent;return o
end
local ammo=label('',UDim2.new(1,-180,1,-90),UDim2.fromOffset(160,32),gui)
local cross=label('+',UDim2.new(.5,-12,.5,-12),UDim2.fromOffset(24,24),gui);cross.Visible=false
local armory=Instance.new('Frame');armory.AnchorPoint=Vector2.new(.5,.5);armory.Position=UDim2.fromScale(.5,.5);armory.Size=UDim2.new(.8,0,0,290);armory.BackgroundColor3=Color3.fromRGB(10,12,12);armory.BackgroundTransparency=.08;armory.Visible=false;armory.Parent=gui
label('TOMÁS · ESCOLHA SEU EQUIPAMENTO',UDim2.fromOffset(16,12),UDim2.new(1,-32,0,36),armory)
local function button(text,pos,size,fn,parent)
 local b=Instance.new('TextButton');b.Text=text;b.Font=Enum.Font.Code;b.TextSize=15;b.TextColor3=Color3.new(1,1,1);b.BackgroundColor3=Color3.fromRGB(42,45,43);b.BackgroundTransparency=.2;b.Position=pos;b.Size=size;b.Parent=parent;b.Activated:Connect(fn);return b
end
local id,model,held,aiming,reloadUntil,localNext=nil,nil,false,false,0,0
local Motion=require(assets:WaitForChild('FPSMotion'));local motion
local recoil=0;local magazine=0;local tracks={};local originPivot
local function clear()
 held=false;motion=nil;if model then model:Destroy();model=nil end
 for _,track in pairs(tracks) do track:Stop() end;table.clear(tracks)
 cross.Visible=false;ammo.Text='';p.CameraMode=Enum.CameraMode.Classic
end
local function equip(name)
 clear();id=name;local template=assets.PlayerWeapons:FindFirstChild(name);if not template then return end
 model=template:Clone();model.Name='LocalWeaponViewmodel';originPivot=model:GetPivot();model.Parent=workspace.CurrentCamera
 local worldGun=p.Character and p.Character:FindFirstChild('EquippedWorldWeapon');if worldGun then for _,part in ipairs(worldGun:GetDescendants()) do if part:IsA('BasePart') then part.LocalTransparencyModifier=1 end end end
 for _,v in ipairs(model:GetDescendants()) do if v:IsA('BasePart') then v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.CastShadow=false end end
 local controller=model:FindFirstChildWhichIsA('AnimationController',true);local humanoid=model:FindFirstChildWhichIsA('Humanoid',true)
 local animator=(controller or humanoid) and (controller or humanoid):FindFirstChildOfClass('Animator')
 if animator then for _,animation in ipairs(model:GetDescendants()) do if animation:IsA('Animation') and animation.AnimationId~='' then
  local ok,track=pcall(function() return animator:LoadAnimation(animation) end)
  if ok then tracks[animation.Name:lower()]=track else warn('[WeaponAnimation] '..animation.Name..': '..tostring(track)) end
 end end end
 motion=Motion.new(model,function(name) local sounds=model and model:FindFirstChild('WeaponSounds');local sound=sounds and sounds:FindFirstChild(name,true);if sound and sound:IsA('Sound') then sound:Play() end end);motion:Play('equip');p.CameraMinZoomDistance=.5;p.CameraMode=Enum.CameraMode.LockFirstPerson;cross.Visible=true
end
local function play(kind)
 if model then local sounds=model:FindFirstChild('WeaponSounds');if sounds then for _,sound in ipairs(sounds:GetDescendants()) do if sound:IsA('Sound') and (sound.Name:lower():find(kind,1,true) or (kind=='fire' and sound.Name:lower():find('shoot',1,true))) then sound:Stop();sound:Play();break end end end end
 if motion then motion:Play(kind) end;for name,track in pairs(tracks) do if name:find(kind,1,true) then track:Play(.08);return end end end
local function fire()
 if not id or not model or armory.Visible or workspace:GetServerTimeNow()<reloadUntil then return end
 local now=os.clock();local cfg=assets.PlayerWeapons[id];if now<localNext or magazine<=0 then return end
 localNext=now+(cfg:GetAttribute('FireInterval') or .2)
 local camera=workspace.CurrentCamera;if not camera then return end
 magazine-=1;recoil=math.min(recoil+.09,.25);play('fire');event:FireServer('fire',camera.CFrame.Position,camera.CFrame.LookVector)
end
local function reload() if id then event:FireServer('reload');play('reload') end end
for i,template in ipairs(assets.PlayerWeapons:GetChildren()) do
 button(template.Name,UDim2.fromOffset(16,56+(i-1)*52),UDim2.new(1,-32,0,42),function() event:FireServer('select',template.Name);armory.Visible=false end,armory)
end
button('FECHAR',UDim2.new(1,-112,1,-44),UDim2.fromOffset(96,32),function() armory.Visible=false;p.CameraMinZoomDistance=.5;if model then p.CameraMode=Enum.CameraMode.LockFirstPerson end end,armory)
local shoot=button('ATIRAR',UDim2.new(1,-104,.48,0),UDim2.fromOffset(86,58),fire,gui)
shoot.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then held=true end end)
shoot.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then held=false end end)
local rb=button('RECARREGAR',UDim2.new(1,-210,.72,0),UDim2.fromOffset(135,44),reload,gui)
local ab=button('MIRAR',UDim2.new(1,-210,.48,0),UDim2.fromOffset(96,44),function() aiming=not aiming end,gui)
shoot.Visible=false;rb.Visible=false;ab.Visible=false
Input.InputBegan:Connect(function(i,processed)
 if processed then return end
 if i.UserInputType==Enum.UserInputType.MouseButton1 then held=true;fire()
 elseif i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=true
 elseif i.KeyCode==Enum.KeyCode.R then reload()
 elseif i.KeyCode==Enum.KeyCode.H then clear();id=nil end
end)
Input.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then held=false elseif i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false end end)
event.OnClientEvent:Connect(function(kind,a,b,c)
 if kind=='armory' then armory.Visible=true;p.CameraMode=Enum.CameraMode.Classic;p.CameraMinZoomDistance=6;Input.MouseBehavior=Enum.MouseBehavior.Default
 elseif kind=='state' then if id~=a or not model then equip(a) end;magazine=b;reloadUntil=c;ammo.Text=a..' · '..b;shoot.Visible=Input.TouchEnabled;rb.Visible=Input.TouchEnabled;ab.Visible=Input.TouchEnabled
 elseif kind=='clear' then clear();id=nil;shoot.Visible=false;rb.Visible=false;ab.Visible=false
 elseif kind=='hit' then cross.Text='×';task.delay(.15,function() cross.Text='+' end)
 elseif kind=='shot' or kind=='alienShot' then
  local camera=workspace.CurrentCamera;if not camera or (camera.CFrame.Position-a).Magnitude>400 then return end
  local delta=b-a;local flash=Instance.new('Part');flash.Anchored=true;flash.CanCollide=false;flash.CanQuery=false;flash.CanTouch=false;flash.CastShadow=false;flash.Material=Enum.Material.Neon;flash.Color=kind=='alienShot' and Color3.fromRGB(169,139,230) or Color3.fromRGB(255,221,156);flash.Size=Vector3.new(.04,.04,delta.Magnitude);flash.CFrame=CFrame.lookAt((a+b)/2,b);flash.Parent=workspace;game:GetService('Debris'):AddItem(flash,.07)
 end
end)
Run.RenderStepped:Connect(function(dt)
 if armory.Visible then Input.MouseBehavior=Enum.MouseBehavior.Default end
 if held then fire() end
 if not model then return end
 local camera=workspace.CurrentCamera;if not camera then return end
 recoil=math.max(0,recoil-dt*.6)
 local t=os.clock();local reloadOffset=workspace:GetServerTimeNow()<reloadUntil and .45 or 0
 local offset=CFrame.new(aiming and -.25 or 0,-reloadOffset,aiming and .25 or 0)*CFrame.Angles(recoil+reloadOffset,math.sin(t*1.2)*.004,math.sin(t*.8)*.006)
 model:PivotTo(camera.CFrame*offset*originPivot.Rotation)
 camera.CFrame*=CFrame.Angles(recoil*.08,0,0)
 camera.FieldOfView+=( (aiming and 52 or 65)-camera.FieldOfView)*math.min(1,dt*12)
end)
p.CharacterAdded:Connect(function() clear();id=nil end)

Run.PreSimulation:Connect(function(dt) if motion and model then motion:Step(dt) end end)
