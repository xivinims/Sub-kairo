local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local player=Players.LocalPlayer
local Config=require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Campaign=require(RS.Shared.Campaign)
local remotes=RS:WaitForChild("BrambleRemotes")
local action,update=remotes:WaitForChild("Action"),remotes:WaitForChild("Update")
local Hands=require(script.Parent.Hands)
local camera=workspace.CurrentCamera
local assets=RS:WaitForChild("BrambleAssets",30)
if assets then local deadline=os.clock()+30;while not assets:GetAttribute("Ready") and os.clock()<deadline do task.wait(.1) end end
local hands=Hands.new(camera)
local gui=Instance.new("ScreenGui");gui.Name="BramblesSprout";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.Enabled=false;gui.Parent=player:WaitForChild("PlayerGui")
local root=Instance.new("Frame");root.Size=UDim2.fromOffset(1280,720);root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5);root.BackgroundTransparency=1;root.Parent=gui
local scale=Instance.new("UIScale");scale.Parent=root
local function resize() local size=camera.ViewportSize;scale.Scale=math.min(size.X/1280,size.Y/720) end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
local function frame(parent,name,pos,size,color,transparency)
 local f=Instance.new("Frame");f.Name=name;f.Position=UDim2.fromOffset(pos.X,pos.Y);f.Size=UDim2.fromOffset(size.X,size.Y);f.BorderSizePixel=0;f.BackgroundColor3=color or Color3.new(0,0,0);f.BackgroundTransparency=transparency or 0;f.Parent=parent;return f
end
local function label(parent,text,pos,size,fontSize)
 local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Position=UDim2.fromOffset(pos.X,pos.Y);t.Size=UDim2.fromOffset(size.X,size.Y);t.Text=text;t.TextColor3=Color3.fromRGB(230,230,216);t.Font=Enum.Font.Code;t.TextSize=fontSize or 22;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Top;t.TextWrapped=true;t.Parent=parent;return t
end
local function button(parent,text,pos,size,fn)
 local b=Instance.new("TextButton");b.Position=UDim2.fromOffset(pos.X,pos.Y);b.Size=UDim2.fromOffset(size.X,size.Y);b.BackgroundColor3=Color3.fromRGB(9,12,11);b.BackgroundTransparency=.3;b.BorderSizePixel=1;b.BorderColor3=Color3.fromRGB(112,119,111);b.TextColor3=Color3.fromRGB(228,232,218);b.Font=Enum.Font.Code;b.TextSize=21;b.Text=text;b.Parent=parent;b.Activated:Connect(fn);return b
end
local menu=frame(root,"Menu",Vector2.zero,Vector2.new(1280,720),Color3.new(0,0,0),.5)
local shade=frame(menu,"ReadingShade",Vector2.zero,Vector2.new(550,720),Color3.new(0,0,0),.12)
local chapter=label(menu,"BRAMBLE’S SPROUT / CAPÍTULO 1",Vector2.new(55,45),Vector2.new(600,35),24)
local heading=label(menu,"DEAD SIGNAL",Vector2.new(55,93),Vector2.new(680,70),45)
frame(menu,"Rule",Vector2.new(55,165),Vector2.new(460,1),Color3.fromRGB(109,117,109))
local description=label(menu,"Hora de podar.\nAs flores murcharam. O sinal continuou.",Vector2.new(55,195),Vector2.new(480,205),22)
local controls=frame(menu,"Buttons",Vector2.new(55,425),Vector2.new(405,280),nil,1)
local hud=frame(root,"HUD",Vector2.zero,Vector2.new(1280,720),nil,1);hud.Visible=false
local objective=label(hud,"",Vector2.new(24,25),Vector2.new(940,100),22)
local stamina=label(hud,"",Vector2.new(24,135),Vector2.new(460,35),18)
local prompt=label(hud,"",Vector2.new(220,470),Vector2.new(850,70),21);prompt.TextXAlignment=Enum.TextXAlignment.Center
local crosshair=label(hud,"·",Vector2.new(627,332),Vector2.new(28,35),30)
local status=label(menu,"Conectando ao servidor…",Vector2.new(55,685),Vector2.new(1050,30),16)
local cinema=frame(root,"Cinema",Vector2.zero,Vector2.new(1280,720),nil,1);cinema.Visible=false
frame(cinema,"TopBar",Vector2.zero,Vector2.new(1280,85));frame(cinema,"BottomBar",Vector2.new(0,610),Vector2.new(1280,110))
local caption=label(cinema,"",Vector2.new(95,635),Vector2.new(1090,75),24);caption.TextXAlignment=Enum.TextXAlignment.Center
local data={state=Campaign.new(),active=false,stamina=100,elapsed=0}
local mode="menu";local loaded=false;local sceneEpoch=0;local shotTween
local run=false;local crouch=false;local sensitivity=1;local volume=.75;local lowGraphics=false
local messageUntil=0;local message="";local function sound(id,loop,vol)
 if type(id)~="number" or id<=0 then return nil end
 local s=Instance.new("Sound");s.SoundId="rbxassetid://"..id;s.Looped=loop;s.Volume=vol or .4;s.Parent=SoundService;return s
end
local ambience=sound(Config.Assets.Ambient,true,.25);local pursuit=sound(Config.Assets.Pursuit,true,0);local voice
if ambience then ambience:Play() end;if pursuit then pursuit:Play() end
local function stopVoice() if voice then voice:Stop();voice:Destroy();voice=nil end end
local function playVoice(id) stopVoice();voice=sound(id,false,.9*volume);if voice then voice:Play() end end
local function clearButtons() for _,b in ipairs(controls:GetChildren()) do b:Destroy() end end
local function add(text,index,fn) return button(controls,text,Vector2.new(0,(index-1)*46),Vector2.new(330,39),fn) end
local function mouse(free) UIS.MouseBehavior=if free then Enum.MouseBehavior.Default else Enum.MouseBehavior.LockCenter;UIS.MouseIconEnabled=free end
local function gameplay()
 mode="playing";menu.Visible=false;hud.Visible=true;cinema.Visible=false;hands:setEnabled(true)
 camera.CameraType=Enum.CameraType.Custom;player.CameraMode=Enum.CameraMode.LockFirstPerson
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid");if h then camera.CameraSubject=h end;mouse(false)
end
local mainMenu
local function askNew()
 heading.Text="NOVO JOGO";description.Text="Isso substitui seu checkpoint atual. Começar de novo?";clearButtons()
 add("COMEÇAR",1,function() if loaded then action:FireServer("Start",false) end end);add("VOLTAR",2,mainMenu)
end
local function settings()
 heading.Text="CONFIGURAÇÕES";description.Text="Ajustes desta sessão. O progresso do capítulo é salvo pelo servidor.";clearButtons()
 add("VOLUME: "..math.floor(volume*100).."%",1,function() volume=(volume+.25)%1.25;if voice then voice.Volume=volume*.9 end;settings() end)
 add("SENSIBILIDADE: "..string.format("%.1f",sensitivity),2,function() sensitivity=if sensitivity>=1.5 then .5 else sensitivity+.25;UIS.MouseDeltaSensitivity=sensitivity;settings() end)
 add("GRÁFICOS: "..(if lowGraphics then "LEVE" else "NORMAL"),3,function() lowGraphics=not lowGraphics;Lighting.GlobalShadows=not lowGraphics;settings() end)
 add("VOLTAR",4,mainMenu)
end
mainMenu=function()
 mode="menu";menu.Visible=true;hud.Visible=false;cinema.Visible=false;hands:setEnabled(false);mouse(true)
 chapter.Text="BRAMBLE’S SPROUT / CAPÍTULO 1";heading.Text="DEAD SIGNAL";description.Text="Hora de podar.\nAs flores murcharam. O sinal continuou.\n\nVolte ao conservatório e corte o que não deveria crescer.";clearButtons()
 local cont=add(if data.dead then "RETOMAR CHECKPOINT" else "CONTINUAR",1,function()
  if not loaded or data.state.finished then return end
  if data.active==false and not data.dead and mode=="paused" then action:FireServer("Resume") else action:FireServer("Start",true) end
 end);cont.AutoButtonColor=loaded and not data.state.finished
 add("NOVO JOGO",2,askNew);add("CONFIGURAÇÕES",3,settings)
 add("CRÉDITOS",4,function() heading.Text="CRÉDITOS";description.Text="Aurivane Works\nBramble’s Sprout — Dead Signal\nPort nativo em Luau. Cenários e criatura provisória procedurais.\nVeja ASSETS.md para importações e créditos.";clearButtons();add("VOLTAR",1,mainMenu) end)
 add("SAIR",5,function() heading.Text="ENCERRAR SESSÃO?";description.Text="Seu último checkpoint continua salvo quando o armazenamento online está disponível.";clearButtons();add("SAIR DA EXPERIÊNCIA",1,function() action:FireServer("Quit") end);add("VOLTAR",2,mainMenu) end)
 camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(Vector3.new(-8,7,92),Vector3.new(6,7,67))
end
local function sceneDone()
 sceneEpoch+=1;if shotTween then shotTween:Cancel() end;stopVoice();cinema.Visible=false;action:FireServer("SceneDone")
end
button(cinema,"PULAR CENA ›",Vector2.new(1040,25),Vector2.new(190,45),sceneDone)
local function scene(payload,ending)
 sceneEpoch+=1;local token=sceneEpoch
 mode="cinema";menu.Visible=false;hud.Visible=false;cinema.Visible=true;hands:setEnabled(false);mouse(true);camera.CameraType=Enum.CameraType.Scriptable
 local sector=payload.state.sector;local o=payload.origin or Vector3.zero
 local lines=if ending then {"O ELEVADOR / 00:03","VOCÊ: Acabou. A antena está muda.","RÁDIO: Você não desligou o sinal. Você me levou com você."} else Config.Sectors[sector].Lines
 local shots={o+Vector3.new(10,8,-15),o+Vector3.new(-20,8,-100),o+Vector3.new(10,9,-220)}
 if sector==4 then shots={o+Vector3.new(-63,14,-15),o+Vector3.new(-15,14,-100),o+Vector3.new(50,14,-220)} end
 if ending then shots={o+Vector3.new(8,8,-240),o+Vector3.new(0,14,-235),o+Vector3.new(0,21,-240)} end
 if sector==1 and not ending then playVoice(Config.Assets.OpeningVoice) end
 for i=1,3 do
  if token~=sceneEpoch then return end
  caption.Text=lines[i]
  local key=(if ending then 7 else sector-1).."_"..(i-1)
  if (i>1 and sector~=1) or (ending and i>1) then playVoice(Config.Assets.Voices[key]) end
  camera.CFrame=CFrame.lookAt(shots[i],shots[i]+Vector3.new(0,-1,-20))
  local duration=if sector==1 and Config.Assets.OpeningVoice>0 and not ending then 11.3 else 4.8
  if voice then
   local deadline=os.clock()+3
   while not voice.IsLoaded and os.clock()<deadline do task.wait(.05);if token~=sceneEpoch then return end end
   if voice.IsLoaded then
    if sector==1 and not ending then duration=(voice.TimeLength+.5)/3 else duration=math.max(duration,voice.TimeLength+.4) end
   end
  end
  shotTween=TweenService:Create(camera,TweenInfo.new(duration,Enum.EasingStyle.Sine),{CFrame=camera.CFrame*CFrame.new(2,.3,-5)});shotTween:Play()
  local deadline=os.clock()+duration
  repeat task.wait(.05);if token~=sceneEpoch then return end until os.clock()>deadline
 end
 sceneDone()
end
local function targetAtCrosshair()
 local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character,hands.root}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*Config.MaxReach,params)
 local obj=hit and hit.Instance
 while obj and obj~=workspace do if obj:GetAttribute("TargetId") then return obj end;obj=obj.Parent end
 return nil
end
local function use(right)
 if mode~="playing" then return end
 local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 action:FireServer("FireHand",ray.Direction,right)
end
local lamp
local function movement() action:FireServer("Move",{run=run,crouch=crouch}) end
local function pause() if mode=="playing" then run=false;movement();action:FireServer("Pause") end end
button(hud,"Ⅱ",Vector2.new(1190,20),Vector2.new(65,55),pause)
if UIS.TouchEnabled then
 button(hud,"AZUL",Vector2.new(230,550),Vector2.new(145,95),function() use(false) end)
 button(hud,"VERMELHA",Vector2.new(1050,430),Vector2.new(170,95),function() use(true) end)
 button(hud,"CORRER",Vector2.new(230,450),Vector2.new(145,65),function() run=not run;movement() end)
 button(hud,"LUZ",Vector2.new(1100,360),Vector2.new(120,65),function() if lamp then lamp.Enabled=not lamp.Enabled end end)
 button(hud,"AGACHAR",Vector2.new(900,550),Vector2.new(150,65),function() crouch=not crouch;movement() end)
end
local function character(c)
 local head=c:WaitForChild("Head",10);if head then lamp=Instance.new("SpotLight");lamp.Face=Enum.NormalId.Front;lamp.Range=65;lamp.Angle=60;lamp.Brightness=2;lamp.Shadows=false;lamp.Parent=head end
end
player.CharacterAdded:Connect(character);if player.Character then task.spawn(character,player.Character) end
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.E or input.UserInputType==Enum.UserInputType.MouseButton1 then use(false)
 elseif input.KeyCode==Enum.KeyCode.Q or input.UserInputType==Enum.UserInputType.MouseButton2 then use(true)
 elseif input.KeyCode==Enum.KeyCode.LeftShift then run=true;movement()
 elseif input.KeyCode==Enum.KeyCode.C then crouch=not crouch;movement()
 elseif input.KeyCode==Enum.KeyCode.F and lamp then lamp.Enabled=not lamp.Enabled
 elseif input.KeyCode==Enum.KeyCode.P then pause() end
end)
UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.LeftShift then run=false;movement() end end)
local lastVisual=""
local function refreshWorld()
 local st=data.state
 local signature=game:GetService("HttpService"):JSONEncode(st)
 if signature==lastVisual then return end;lastVisual=signature
 local world=workspace:FindFirstChild("BrambleWorld");local index=world and world:FindFirstChild("TargetIndex");if not index then lastVisual="";return end
 for _,ref in ipairs(index:GetChildren()) do
  local target=ref.Value
  if target and target:GetAttribute("Sector")==st.sector then
   local id=target:GetAttribute("Action");local collected=st.flags[id] and (string.match(id,"^page") or string.match(id,"^seed") or string.match(id,"^cell") or string.match(id,"^fuse") or id=="card" or string.match(id,"^bloom"))
   target.LocalTransparencyModifier=if collected then 1 else 0
   for _,item in ipairs(target:GetDescendants()) do if item:IsA("BasePart") then item.LocalTransparencyModifier=if collected then 1 else 0 end end
   local pro=target:FindFirstChildOfClass("ProximityPrompt");if pro then pro.Enabled=false end
   local surface=target:FindFirstChildOfClass("SurfaceGui");local readout=surface and surface:FindFirstChild("Readout")
   local value=target:GetAttribute("Title")
   if string.match(id,"^digit[1234]$") then value=tostring(st.digits[tonumber(string.sub(id,-1))])
   elseif string.match(id,"^valve[1234]$") then value=if st.valves[tonumber(string.sub(id,-1))] then "ABERTA" else "FECHADA"
   elseif id=="pressure" then value=st.pressure.." BAR"
   elseif string.match(id,"^angle[123]$") then value=tostring(st.angles[tonumber(string.sub(id,-1))])
   elseif id=="exit" then value=if Campaign.complete(st) then "LIBERADO" else "BLOQUEADO" end
   if readout then readout.Text=value;surface.Enabled=not collected end
   if string.match(id,"^lamp[123456789]$") and target:FindFirstChild("Indicator") then target.Indicator.Color=if st.matrix[tonumber(string.sub(id,-1))] then Color3.fromRGB(240,190,50) else Color3.fromRGB(20,28,24) end
  end
 end
end
update.OnClientEvent:Connect(function(kind,payload)
 if kind=="Hand" then hands:launch(payload.point,payload.right);return end
 if kind=="HandHold" then hands:hold(payload.part,payload.right);return end
 if kind=="HandRelease" then hands:release(payload.right);return end
 if payload.state then data=payload;refreshWorld() end
 status.Text=payload.saveStatus or ""
 if payload.message then message=payload.message;messageUntil=os.clock()+4 end
 if kind=="Ready" then loaded=true;if mode=="menu" then mainMenu() end
 elseif kind=="Scene" or kind=="Ending" then task.spawn(scene,payload,kind=="Ending")
 elseif kind=="Dead" then mainMenu();heading.Text="ELE ENCONTROU VOCÊ";description.Text=payload.message or "Retome o checkpoint para tentar outra vez."
 elseif kind=="Won" then mainMenu();heading.Text="O SINAL NÃO MORREU";description.Text="FIM DO CAPÍTULO 1 / DEAD SIGNAL\nVocê saiu. A transmissão foi junto."
 elseif kind=="Paused" then mainMenu();mode="paused";heading.Text="PAUSADO";clearButtons();add("CONTINUAR",1,function() action:FireServer("Resume") end);add("CONFIGURAÇÕES",2,settings);add("MENU PRINCIPAL",3,mainMenu)
 elseif kind=="Document" then
  mode="reading";menu.Visible=true;hud.Visible=false;hands:setEnabled(false);mouse(true);heading.Text="PROTOCOLO";description.Text=payload.message or "";clearButtons();add("FECHAR",1,gameplay)
 elseif data.active and not data.scene and not data.dead and mode~="reading" and mode~="cinema" then gameplay()
 elseif data.active and not data.scene and mode=="cinema" then gameplay() end
end)
RunService.RenderStepped:Connect(function()
 if mode=="playing" then
  local info=Config.Sectors[data.state.sector]
  objective.Text="DEAD SIGNAL / "..info.Name.."\n"..info.Goal.."\n"..Campaign.progress(data.state)
  stamina.Text="FÔLEGO "..math.floor(data.stamina or 100).."%"
  local target=targetAtCrosshair();prompt.Text=if os.clock()<messageUntil then message else if target then target:GetAttribute("Title").."  •  E / AZUL   Q / VERMELHA" else ""
 end
 local danger=Campaign.danger(data.state) and mode=="playing"
 if ambience then ambience.Volume=volume*(if voice and voice.IsPlaying then .1 else .32) end
 if pursuit then pursuit.Volume=if danger then volume*.55 else 0 end
end)
while not player:GetAttribute("BrambleBootDone") do task.wait(.1) end
gui.Enabled=true;mainMenu();action:FireServer("Sync")
