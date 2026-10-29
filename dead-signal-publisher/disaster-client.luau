while not workspace:GetAttribute('GameMode') do task.wait(.1) end
if workspace:GetAttribute('GameMode')~='Match' then return end
local Players=game:GetService('Players');local Run=game:GetService('RunService');local Tween=game:GetService('TweenService')
local p=Players.LocalPlayer;local W=workspace;local touch=game:GetService('UserInputService').TouchEnabled
local labels={Earthquake='TERREMOTO',AcidRain='CHUVA ÁCIDA',Tornado='TORNADO',Meteors='METEOROS',Gale='VENTANIA EXTREMA'}
local gui=Instance.new('ScreenGui');gui.Name='DisasterStatus';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=35;gui.Parent=p:WaitForChild('PlayerGui')
local text=Instance.new('TextLabel');text.AnchorPoint=Vector2.new(.5,0);text.Position=UDim2.new(.5,0,0,8);text.Size=UDim2.new(.65,0,0,62);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(255,226,193);text.TextStrokeTransparency=.35;text.Font=Enum.Font.Code;text.TextSize=touch and 13 or 17;text.TextWrapped=true;text.Parent=gui
local effects=Instance.new('Folder');effects.Name='LocalDisasterEffects';effects.Parent=W
local acid=Instance.new('ColorCorrectionEffect');acid.Name='DisasterAcidGrade';acid.Enabled=false;acid.TintColor=Color3.fromRGB(202,233,164);acid.Contrast=.12;acid.Parent=game:GetService('Lighting')
local function part(name,size,color,trans)
 local o=Instance.new('Part');o.Name=name;o.Size=size;o.Color=color;o.Transparency=trans or 0;o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false;o.Parent=effects;return o
end
local drops={};local funnel={};local clock=0
for i=1,(touch and 40 or 80) do local o=part('AcidRain',Vector3.new(.04,2,.04),Color3.fromRGB(177,218,100),1);table.insert(drops,{o=o,offset=Vector3.new(math.random(-30,30),math.random(-5,40),math.random(-30,30))}) end
for i=1,(touch and 12 or 20) do local o=part('VortexCloud',Vector3.new(1,1,1),Color3.fromRGB(60,67,73),1);o.Shape=Enum.PartType.Ball;table.insert(funnel,o) end
local function affected() return p:GetAttribute('IslandDestination')==W:GetAttribute('DisasterIsland') end
W:GetAttributeChangedSignal('MeteorCue'):Connect(function()
 if not affected() or W:GetAttribute('DisasterPhase')~='Active' then return end
 local target=W:GetAttribute('MeteorTarget');if typeof(target)~='Vector3' then return end
 local ball=part('Meteor',Vector3.new(5,5,5),Color3.fromRGB(255,124,48));ball.Shape=Enum.PartType.Ball;ball.Material=Enum.Material.Neon;ball.Position=target+Vector3.new(45,160,-30)
 local light=Instance.new('PointLight');light.Range=22;light.Brightness=2;light.Color=ball.Color;light.Parent=ball
 local warning=part('ImpactWarning',Vector3.new(20,.1,20),Color3.fromRGB(255,145,54),.65);warning.Material=Enum.Material.Neon;warning.Position=target+Vector3.new(0,.2,0)
 Tween:Create(ball,TweenInfo.new(2,Enum.EasingStyle.Linear),{Position=target}):Play()
 task.delay(2,function()
  warning:Destroy();light:Destroy();ball.Size=Vector3.new(8,8,8);Tween:Create(ball,TweenInfo.new(.55),{Size=Vector3.new(28,28,28),Transparency=1}):Play();task.delay(.6,function() ball:Destroy() end)
 end)
end)
Run:BindToRenderStep('DisasterCamera',Enum.RenderPriority.Camera.Value+1,function()
 if affected() and W:GetAttribute('DisasterPhase')=='Active' and W:GetAttribute('DisasterKind')=='Earthquake' then
  local c=W.CurrentCamera;if c and c.CameraType==Enum.CameraType.Custom then local t=os.clock();c.CFrame*=CFrame.Angles(math.noise(t*12)*.012,0,math.noise(t*14,4)*.009) end
 end
end)
Run.Heartbeat:Connect(function(dt)
 clock+=dt;if clock<1/20 then return end;local step=math.min(clock,.1);clock=0
 local phase=W:GetAttribute('DisasterPhase');local kind=W:GetAttribute('DisasterKind');local localEvent=affected();local active=phase=='Active' and localEvent
 local seconds=math.max(0,math.ceil((W:GetAttribute('DisasterEndsAt') or 0)-W:GetServerTimeNow()))
 if phase=='Warning' then text.Text=(labels[kind] or '')..' EM '..seconds..'s\nChame os moradores. Ainda dá para evacuar pelo mapa.'
 elseif phase=='Active' then text.Text=(labels[kind] or '')..' · '..seconds..'s\nTELEPORTE BLOQUEADO · '..(localEvent and 'Procure teto e ajude os moradores!' or 'Você está fora da área atingida.')
 elseif phase=='Recovery' then text.Text='DESASTRE ENCERRADO · NPCs resgatados: '..tostring(W:GetAttribute('DisasterSaved') or 0)
 else text.Text='' end
 acid.Enabled=active and kind=='AcidRain'
 local camera=W.CurrentCamera
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 local covered=false
 if root and active then local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={W.Islands[p:GetAttribute('IslandDestination')]};rp.RespectCanCollide=true;covered=W:Raycast(root.Position,Vector3.new(0,60,0),rp)~=nil end
 for _,d in ipairs(drops) do
  d.o.Transparency=acid.Enabled and not covered and .3 or 1
  if acid.Enabled and camera then d.offset+=Vector3.new(-10,-70,0)*step;if d.offset.Y< -8 then d.offset=Vector3.new(math.random(-30,30),40,math.random(-30,30)) end;d.o.Position=camera.CFrame.Position+d.offset end
 end
 local center=W:GetAttribute('DisasterCenter')
 for i,o in ipairs(funnel) do
  if active and kind=='Tornado' and typeof(center)=='Vector3' then
   local h=i/#funnel;local radius=3+h*28;local angle=os.clock()*3+i*2.4
   o.Transparency=.5;o.Size=Vector3.new(radius*1.4,8,radius*1.4);o.Position=center+Vector3.new(math.cos(angle)*radius*.4,h*110,math.sin(angle)*radius*.4)
  else o.Transparency=1 end
 end
end)
