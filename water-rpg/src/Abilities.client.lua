local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local Lighting=game:GetService('Lighting')
local p=Players.LocalPlayer
local Shared=RS:WaitForChild('WaterRPG');local Assets=Shared:WaitForChild('PlayerAssets');local Remote=Shared:WaitForChild('Ability')
local gui=Instance.new('ScreenGui');gui.Name='PlayerAbilities';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.Parent=p:WaitForChild('PlayerGui')
local controls
pcall(function() controls=require(p.PlayerScripts:WaitForChild('PlayerModule',10)):GetControls() end)
local function label(parent,text,size,pos)
 local x=Instance.new('TextLabel');x.Size=size;x.Position=pos;x.Text=text;x.Font=Enum.Font.Gotham;x.TextSize=12;x.TextColor3=Color3.fromRGB(235,241,239);x.BackgroundTransparency=1;x.Parent=parent;return x
end
local panel=Instance.new('Frame');panel.Size=UDim2.fromOffset(360,96);panel.Position=UDim2.new(.5,-180,1,-147);panel.BackgroundTransparency=1;panel.Parent=gui
local buttons={}
local function btn(key,title,x,y,callback)
 local b=Instance.new('TextButton');b.Name=key;b.Size=UDim2.fromOffset(112,40);b.Position=UDim2.fromOffset(x,y);b.BackgroundColor3=Color3.fromRGB(15,27,39);b.BackgroundTransparency=.18;b.TextColor3=Color3.fromRGB(235,241,239);b.Font=Enum.Font.GothamMedium;b.TextSize=12;b.Text=title;b.Parent=panel
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,9);corner.Parent=b
 local border=Instance.new('UIStroke');border.Color=Color3.fromRGB(148,175,193);border.Transparency=.5;border.Parent=b
 b.Activated:Connect(callback);buttons[key]=b;return b
end
btn('Lantern','LANTERNA · R',0,0,function() Remote:FireServer('Lantern') end)
btn('Bow','ARCO · 1',121,0,function() Remote:FireServer('Bow') end)
btn('Wall','PAREDES · B',242,0,function() Remote:FireServer('WallWalk') end)
btn('Aim','MIRAR',0,48,function() Remote:FireServer('Aim',not p:GetAttribute('BowAiming')) end)
local function shoot()
 local cam=workspace.CurrentCamera;local size=cam.ViewportSize;local ray=cam:ViewportPointToRay(size.X/2,size.Y/2)
 Remote:FireServer('Shoot',ray.Direction)
end
btn('Shoot','ATIRAR',121,48,shoot)
local target
btn('Swap','TROCAR · T',242,48,function() if target then Remote:FireServer('Swap',target) end end)
local track=Instance.new('Frame');track.Size=UDim2.fromOffset(220,5);track.Position=UDim2.new(.5,-110,1,-39);track.BackgroundColor3=Color3.fromRGB(30,39,40);track.BorderSizePixel=0;track.Parent=gui
local stamina=Instance.new('Frame');stamina.Size=UDim2.fromScale(1,1);stamina.BackgroundColor3=Color3.fromRGB(219,199,144);stamina.BorderSizePixel=0;stamina.Parent=track
local airLabel=label(gui,'',UDim2.fromOffset(230,22),UDim2.new(.5,-115,1,-66))
local hints=label(gui,'',UDim2.fromOffset(440,20),UDim2.new(.5,-220,1,-25))
local aimDot=label(gui,'+',UDim2.fromOffset(30,30),UDim2.new(.5,-15,.5,-15));aimDot.TextSize=25
local underwater=Instance.new('ColorCorrectionEffect');underwater.Name='SwimUnderwater';underwater.TintColor=Color3.fromRGB(153,210,224);underwater.Contrast=.08;underwater.Enabled=false;underwater.Parent=Lighting
local c,h,root,force,align,attachment
local activeMode='';local wallNormal=Vector3.yAxis;local wallMove=Vector3.zero;local lastRun=0;local wetAt=0
local animTracks={};local currentAnimation
local function stopAnimation()
 if currentAnimation and animTracks[currentAnimation] then animTracks[currentAnimation]:Stop(.15) end;currentAnimation=nil
end
local function playAnimation(name)
 if currentAnimation==name then return end;stopAnimation()
 local animator=h and h:FindFirstChildOfClass('Animator');local a=Assets:FindFirstChild('WallAnimations') and Assets.WallAnimations:FindFirstChild(name)
 if name=='ClapAnimation' then a=Assets:FindFirstChild('ClapAnimation') end
 if name:find('Bow') then a=Assets.BowAnimations:FindFirstChild(name) end
 if not animator or not a then return end
 if not animTracks[name] then local ok,v=pcall(function() return animator:LoadAnimation(a) end);if ok then animTracks[name]=v end end
 if animTracks[name] then animTracks[name]:Play(.18);currentAnimation=name end
end
local function clearWall()
 if force then force:Destroy();force=nil end
 if align then align:Destroy();align=nil end
 if attachment then attachment:Destroy();attachment=nil end
 if h and h.Parent then h.AutoRotate=true;h.PlatformStand=false end
 activeMode='';stopAnimation()
end
local function character(cNew)
 clearWall();c=cNew;h=c:WaitForChild('Humanoid',10);root=c:WaitForChild('HumanoidRootPart',10);animTracks={};currentAnimation=nil
end
p.CharacterAdded:Connect(character);if p.Character then task.spawn(character,p.Character) end
p.CharacterRemoving:Connect(function() clearWall();c=nil;h=nil;root=nil end)
local function wallHit()
 if not root then return end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={c,workspace:FindFirstChild('Residents')};ray.IgnoreWater=true
 for _,direction in ipairs({root.CFrame.LookVector,root.CFrame.RightVector,-root.CFrame.RightVector,-root.CFrame.LookVector}) do
  local hit=workspace:Raycast(root.Position,direction*4.5,ray)
  if hit and math.abs(hit.Normal.Y)<.35 and hit.Instance.CanCollide then return hit end
 end
end
local function startWall(mode)
 clearWall();activeMode=mode
 attachment=Instance.new('Attachment');attachment.Name='ParkourAttachment';attachment.Parent=root
 force=Instance.new('VectorForce');force.Attachment0=attachment;force.RelativeTo=Enum.ActuatorRelativeTo.World;force.ApplyAtCenterOfMass=true;force.Parent=root
 align=Instance.new('AlignOrientation');align.Attachment0=attachment;align.Mode=Enum.OrientationAlignmentMode.OneAttachment;align.MaxTorque=100000;align.Responsiveness=22;align.Parent=root
 h.AutoRotate=false
end
UIS.JumpRequest:Connect(function()
 if activeMode~='' and root then
  local impulse=wallNormal*30+Vector3.new(0,48,0)+wallMove*8;clearWall();root.AssemblyLinearVelocity=impulse;Remote:FireServer('EndWall');lastRun=os.clock()+.5
 end
end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or p:GetAttribute('InMenu') then return end
 if input.KeyCode==Enum.KeyCode.R then Remote:FireServer('Lantern')
 elseif input.KeyCode==Enum.KeyCode.One then Remote:FireServer('Bow')
 elseif input.KeyCode==Enum.KeyCode.B then Remote:FireServer('WallWalk')
 elseif input.KeyCode==Enum.KeyCode.T and target then Remote:FireServer('Swap',target)
 elseif input.UserInputType==Enum.UserInputType.MouseButton2 and p:GetAttribute('BowEquipped') then Remote:FireServer('Aim',true)
 elseif input.UserInputType==Enum.UserInputType.MouseButton1 and p:GetAttribute('BowEquipped') then shoot() end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton2 then Remote:FireServer('Aim',false) end end)
Shared.Feedback.OnClientEvent:Connect(function(kind)
 if kind=='BowShot' then playAnimation('Bow Aim Shot');task.delay(.3,function() if currentAnimation=='Bow Aim Shot' then stopAnimation() end end)
 elseif kind=='Swapped' then playAnimation('ClapAnimation') end
end)
local targetAt=0
Run.RenderStepped:Connect(function(dt)
 local now=os.clock();local cam=workspace.CurrentCamera
 local alive=c and c.Parent and root and root.Parent and h and h.Health>0 and not p:GetAttribute('InMenu')
 gui.Enabled=alive==true
 if not alive then if activeMode~='' then clearWall() end;underwater.Enabled=false;return end
 local staminaNow=p:GetAttribute('Stamina') or 100
 stamina.Size=UDim2.fromScale(staminaNow/100,1)
 local swimming=p:GetAttribute('Swimming');local submerged=p:GetAttribute('Underwater')
 underwater.Enabled=submerged==true
 airLabel.Text=submerged and ('FÔLEGO  '..(p:GetAttribute('Breath') or 60)..'s') or ''
 local bow=p:GetAttribute('BowEquipped');local aiming=p:GetAttribute('BowAiming')
 buttons.Aim.Visible=bow==true;buttons.Shoot.Visible=bow==true;aimDot.Visible=bow==true
 buttons.Lantern.Text=p:GetAttribute('LanternOn') and 'LANTERNA · ON' or 'LANTERNA · R'
 buttons.Wall.Text=p:GetAttribute('WallWalkEnabled') and 'PAREDES · ON' or 'PAREDES · B'
 local cd=math.max(0,math.ceil((p:GetAttribute('SwapReadyAt') or 0)-workspace:GetServerTimeNow()))
 buttons.Swap.Text=cd>0 and ('TROCAR · '..cd..'s') or 'TROCAR · T'
 hints.Text=swimming and 'Natação automática · pule para subir' or (p:GetAttribute('WallMode')~='' and 'Pule para se soltar da parede' or 'Corra e pule junto à parede para fazer wall run')
 local mode=p:GetAttribute('WallMode') or ''
 if mode~=activeMode then if mode~='' then startWall(mode) else clearWall() end end
 if activeMode~='' then
  local hit=wallHit()
  if not hit or swimming then clearWall();Remote:FireServer('EndWall')
  else
   wallNormal=hit.Normal
   local movement=controls and controls:GetMoveVector() or Vector3.zero
   local forward,right
   if activeMode=='Walk' then
    forward=(Vector3.yAxis-wallNormal*wallNormal.Y).Unit;right=forward:Cross(wallNormal).Unit
    wallMove=forward*(-movement.Z)+right*movement.X
    local face=wallMove.Magnitude>.1 and wallMove.Unit or forward
    align.CFrame=CFrame.lookAt(root.Position,root.Position+face,wallNormal)
    playAnimation('Wall Run Left')
   else
    forward=wallNormal:Cross(Vector3.yAxis)
    if forward:Dot(cam.CFrame.LookVector)<0 then forward=-forward end
    wallMove=forward;align.CFrame=CFrame.lookAt(root.Position,root.Position+forward,Vector3.yAxis)
    playAnimation('Wall Run Right')
   end
   local speed=activeMode=='Walk' and 15 or 26
   force.Force=Vector3.yAxis*root.AssemblyMass*workspace.Gravity-wallNormal*root.AssemblyMass*90
   root.AssemblyLinearVelocity=wallMove*speed-wallNormal*2
  end
 elseif p:GetAttribute('Sprinting') and h.FloorMaterial==Enum.Material.Air and not swimming and now-lastRun>.5 and not p:GetAttribute('WallWalkEnabled') then
  if wallHit() then lastRun=now;Remote:FireServer('WallRun') end
 elseif bow and aiming then playAnimation('Bow Aim Hold')
 elseif currentAnimation and currentAnimation~='Bow Aim Shot' then stopAnimation() end
 if swimming and h:GetState()~=Enum.HumanoidStateType.Swimming and now-wetAt>.5 then wetAt=now;h:ChangeState(Enum.HumanoidStateType.Swimming) end
 if now-targetAt>.2 then
  targetAt=now;target=nil;local best=.94
  local candidates={}
  for _,other in ipairs(Players:GetPlayers()) do if other~=p and other.Character and not other:GetAttribute('InMenu') then table.insert(candidates,other.Character) end end
  local training=workspace:FindFirstChild('TrainingTargets');if training then for _,m in ipairs(training:GetChildren()) do table.insert(candidates,m) end end
  for _,m in ipairs(candidates) do
   local r=m:FindFirstChild('HumanoidRootPart');local hh=m:FindFirstChildOfClass('Humanoid')
   if r and hh and hh.Health>0 then local delta=r.Position-cam.CFrame.Position;local score=delta.Unit:Dot(cam.CFrame.LookVector)
    if delta.Magnitude<65 and score>best then best=score;target=m end
   end
  end
 end
end)
