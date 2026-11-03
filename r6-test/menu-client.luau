local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local TS=game:GetService('TweenService');local Run=game:GetService('RunService');local UIS=game:GetService('UserInputService');local StarterGui=game:GetService('StarterGui')
local player=Players.LocalPlayer;local pg=player:WaitForChild('PlayerGui');local camera=workspace.CurrentCamera
local controls=require(player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule')):GetControls()
local gui=Instance.new('ScreenGui');gui.Name='DynamicR6Menu';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=100;gui.Parent=pg
local fade=Instance.new('Frame');fade.Size=UDim2.fromScale(1,1);fade.BackgroundColor3=Color3.fromRGB(10,14,19);fade.BorderSizePixel=0;fade.BackgroundTransparency=1;fade.ZIndex=20;fade.Parent=gui
local reopen=Instance.new('TextButton');reopen.Text='☰';reopen.TextSize=25;reopen.Size=UDim2.fromOffset(42,42);reopen.Position=UDim2.fromOffset(12,70);reopen.BackgroundColor3=Color3.fromRGB(24,36,42);reopen.TextColor3=Color3.new(1,1,1);reopen.Visible=false;reopen.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(1,0);corner.Parent=reopen
local stage=Instance.new('Model');stage.Name='LocalMenuStage';stage.Parent=workspace
local origin=Vector3.new(500,80,500)
local function part(name,size,cf,color)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=stage;return p
end
part('Platform',Vector3.new(70,1,48),CFrame.new(origin+Vector3.new(0,-4,0)),Color3.fromRGB(39,55,54))
part('Backdrop',Vector3.new(70,28,1),CFrame.new(origin+Vector3.new(0,9,-8)),Color3.fromRGB(18,30,32))
for i=-3,3 do local p=part('Pillar',Vector3.new(.12,22,.12),CFrame.new(origin+Vector3.new(i*9,7,-7)),Color3.fromRGB(139,179,153));p.Material=Enum.Material.Neon end
local rig=RS:WaitForChild('MenuR6Template'):Clone();rig.Name='R6Preview';rig.Parent=stage;rig:PivotTo(CFrame.new(origin+Vector3.new(3,-.5,0))*CFrame.Angles(0,math.rad(-15),0))
assert(rig.Humanoid.RigType==Enum.HumanoidRigType.R6)
for _,x in ipairs(rig:GetDescendants()) do if x:IsA('BasePart') then x.Anchored=true end end
rig.Humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
local pages={};local frames={};local cameraPose=Instance.new('CFrameValue');local active=false;local busy=false;local hidden={};local disabledBow
local function page(name,x)
 local p=part(name,Vector3.new(15,12,.1),CFrame.new(origin+Vector3.new(x,3,2)),Color3.fromRGB(17,26,32));p.Transparency=.08;p.CanQuery=true
 local surface=Instance.new('SurfaceGui');surface.Name=name;surface.Adornee=p;surface.Face=Enum.NormalId.Back;surface.CanvasSize=Vector2.new(750,600);surface.Active=true;surface.LightInfluence=0;surface.Parent=pg
 local f=Instance.new('Frame');f.Size=UDim2.fromScale(1,1);f.BackgroundTransparency=1;f.Parent=surface
 pages[name]=surface;frames[name]=f
 return f
end
local function text(parent,value,y,size,color)
 local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.new(1,-70,0,size*1.5);t.Position=UDim2.fromOffset(35,y);t.Text=value;t.TextXAlignment=Enum.TextXAlignment.Left;t.Font=Enum.Font.GothamBold;t.TextSize=size;t.TextColor3=color or Color3.fromRGB(237,241,230);t.Parent=parent;return t
end
local function button(parent,value,y,fn)
 local b=Instance.new('TextButton');b.Text='  '..value..'    ›';b.TextXAlignment=Enum.TextXAlignment.Left;b.Size=UDim2.new(1,-70,0,68);b.Position=UDim2.fromOffset(35,y);b.BackgroundColor3=Color3.fromRGB(39,57,60);b.BackgroundTransparency=.25;b.TextColor3=Color3.fromRGB(240,244,234);b.Font=Enum.Font.GothamMedium;b.TextSize=27;b.AutoButtonColor=false;b.Parent=parent
 local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,10);c.Parent=b
 b.MouseEnter:Connect(function() TS:Create(b,TweenInfo.new(.18),{BackgroundColor3=Color3.fromRGB(65,94,85)}):Play() end)
 b.MouseLeave:Connect(function() TS:Create(b,TweenInfo.new(.18),{BackgroundColor3=Color3.fromRGB(39,57,60)}):Play() end)
 b.Activated:Connect(function() if active and not busy then fn(b) end end);return b
end
local main=page('Main',-8);local settings=page('Settings',18);local help=page('Help',-34)
text(main,'ARENA',55,76);text(main,'R6  /  CAMPO DE TESTE',155,22,Color3.fromRGB(158,190,165))
text(main,'Treine. Explore. Teste seus poderes.',205,22)
local function target(name)
 local x=name=='Settings' and 18 or name=='Help' and -34 or -8
 -- Widen the camera for portrait screens so the complete panel remains visible.
 local aspect=math.max(.4,camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y));local distance=math.max(13,12/aspect)
 return CFrame.lookAt(origin+Vector3.new(x+3,4,2+distance),origin+Vector3.new(x,3,2))
end
local current='Main';local function route(name)
 current=name;busy=true
 for n,s in pairs(pages) do s.Enabled=active end
 local tween=TS:Create(cameraPose,TweenInfo.new(.85,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{Value=target(name)});tween:Play();tween.Completed:Once(function() busy=false end)
end
local function conceal(x)
 if x==gui or x:IsA('SurfaceGui') then return end
 if x:IsA('ScreenGui') and x.Enabled then hidden[x]=true;x.Enabled=false end
end
local function bowOff(char)
 local b=char:WaitForChild('BowClient',5);if active and b and not b.Disabled then b.Disabled=true;disabledBow=b end
end
local function enter()
 if active then return end;active=true;reopen.Visible=false;controls:Disable();UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true
 for _,x in ipairs(pg:GetChildren()) do conceal(x) end
 pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false);StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false) end)
 if player.Character then task.spawn(bowOff,player.Character) end
 camera.CameraType=Enum.CameraType.Scriptable;cameraPose.Value=target('Main');route('Main')
end
local function play()
 busy=true;TS:Create(fade,TweenInfo.new(.35),{BackgroundTransparency=0}):Play();task.wait(.4)
 active=false;for _,s in pairs(pages) do s.Enabled=false end
 for x in pairs(hidden) do if x.Parent then x.Enabled=true end end;table.clear(hidden)
 controls:Enable();if disabledBow and disabledBow.Parent then disabledBow.Disabled=false end;disabledBow=nil
 local char=player.Character or player.CharacterAdded:Wait();camera.CameraSubject=char:WaitForChild('Humanoid');camera.CameraType=Enum.CameraType.Custom
 pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,true);StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,true) end)
 TS:Create(fade,TweenInfo.new(.55),{BackgroundTransparency=1}):Play();reopen.Visible=true;busy=false
end
button(main,'JOGAR',285,play);button(main,'CONFIGURAÇÕES',365,function() route('Settings') end);button(main,'COMO JOGAR',445,function() route('Help') end)
text(settings,'CONFIGURAÇÕES',65,42);text(settings,'Ajustes para esta sessão',135,22)
local shadows=true;button(settings,'Sombras: ligadas',215,function(b) shadows=not shadows;game:GetService('Lighting').GlobalShadows=shadows;b.Text='  Sombras: '..(shadows and 'ligadas' or 'desligadas') end)
local effects=true;button(settings,'Efeitos: ligados',295,function(b) effects=not effects;for _,x in ipairs(game:GetService('Lighting'):GetChildren()) do if x:IsA('PostEffect') then x.Enabled=effects end end;b.Text='  Efeitos: '..(effects and 'ligados' or 'desligados') end)
button(settings,'VOLTAR',465,function() route('Main') end)
text(help,'COMO JOGAR',65,44)
text(help,'ARCO • mire pelo centro e toque em ARCO',165,23)
text(help,'LUZ • liga a lanterna',220,23)
text(help,'CORRER • usa a barra de energia',275,23)
text(help,'TROCAR • troca de lugar com um alvo',330,23)
text(help,'WALL RUN • pule perto da parede e segure',385,22)
button(help,'VOLTAR',480,function() route('Main') end)
pg.ChildAdded:Connect(function(x) if active then task.defer(function() conceal(x) end) end end)
player.CharacterAdded:Connect(function(char) if active then controls:Disable();task.spawn(bowOff,char) end end)
reopen.Activated:Connect(enter)
camera:GetPropertyChangedSignal('ViewportSize'):Connect(function() if active and not busy then cameraPose.Value=target(current) end end)
Run:BindToRenderStep('R6DynamicMenu',Enum.RenderPriority.Camera.Value+10,function()
 if not active then return end
 local t=os.clock();local dx,dy=0,0
 if not UIS.TouchEnabled then local m=UIS:GetMouseLocation();local s=camera.ViewportSize;dx=(m.X/math.max(1,s.X)-.5)*.35;dy=(m.Y/math.max(1,s.Y)-.5)*.2 end
 camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=cameraPose.Value*CFrame.new(dx,dy+math.sin(t*.65)*.06,0)
end)
enter()
