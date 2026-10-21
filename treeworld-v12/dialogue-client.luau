local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Content=game:GetService('ContentProvider')
local player=Players.LocalPlayer
local runtime=RS:WaitForChild('LivingForest')
local D=require(runtime:WaitForChild('DialogueData'))
local voices=require(runtime:WaitForChild('VoiceManifest'))
local locale=D.locale(player.LocaleId);local text=D.Locales[locale]
local world=workspace:WaitForChild('OveryardPhotoWorld')
local screen=Instance.new('ScreenGui');screen.Name='CaioConversation';screen.ResetOnSpawn=false;screen.DisplayOrder=45;screen.Parent=player.PlayerGui
local choices=Instance.new('Frame');choices.BackgroundTransparency=1;choices.AnchorPoint=Vector2.new(.5,1);choices.Position=UDim2.fromScale(.5,.77);choices.Size=UDim2.new(.86,0,0,240);choices.Parent=screen
local size=Instance.new('UISizeConstraint');size.MaxSize=Vector2.new(510,260);size.Parent=choices
local layout=Instance.new('UIListLayout');layout.Padding=UDim.new(0,7);layout.VerticalAlignment=Enum.VerticalAlignment.Bottom;layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=choices
local overhead=Instance.new('BillboardGui');overhead.Name='CaioOverhead';overhead.Size=UDim2.fromOffset(340,120);overhead.StudsOffsetWorldSpace=Vector3.new(0,3,0);overhead.AlwaysOnTop=false;overhead.MaxDistance=35;overhead.Enabled=false;overhead.Parent=screen
local bubble=Instance.new('TextLabel');bubble.Size=UDim2.fromScale(1,1);bubble.BackgroundColor3=Color3.fromRGB(27,36,30);bubble.BackgroundTransparency=.16;bubble.TextColor3=Color3.fromRGB(247,242,225);bubble.TextSize=17;bubble.Font=Enum.Font.GothamMedium;bubble.TextWrapped=true;bubble.Text='';bubble.Parent=overhead
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,12);corner.Parent=bubble
local padding=Instance.new('UIPadding');padding.PaddingLeft=UDim.new(0,15);padding.PaddingRight=UDim.new(0,15);padding.PaddingTop=UDim.new(0,10);padding.PaddingBottom=UDim.new(0,10);padding.Parent=bubble
local npc,head,prompt;local joints={};local current='hello';local speaking=false;local active=false;local generation=0;local audio=nil;local cache={};local greeted=0;local started=0
local output=Instance.new('AudioDeviceOutput');output.Player=player;output.Parent=screen
local listener=Instance.new('AudioListener');listener.Parent=workspace.CurrentCamera
local listenerWire=Instance.new('Wire');listenerWire.SourceInstance=listener;listenerWire.TargetInstance=output;listenerWire.Parent=output
local emitter=Instance.new('AudioEmitter');pcall(function()emitter:SetDistanceAttenuation({[0]=1,[9]=1,[25]=0})end)
local function clearChoices()for _,p in ipairs(choices:GetChildren())do if p:IsA('GuiButton')then p:Destroy()end end end
local function stop()
 generation+=1;speaking=false;active=false;clearChoices();overhead.Enabled=false
 if audio then pcall(function()if audio:IsA('Sound')then audio:Stop()else audio:Pause()end end)end
end
local speak
local function button(label,id,order)
 local template=runtime:FindFirstChild('DialogueChoiceTemplate');local b
 if template and template:IsA('GuiButton')then b=template:Clone();for _,p in ipairs(b:GetDescendants())do if p:IsA('LuaSourceContainer')then p:Destroy()end end
 else b=Instance.new('TextButton')end
 b.Name='Choice_'..id;b.Visible=true;b.Size=UDim2.new(1,0,0,38);b.LayoutOrder=order;b.BackgroundTransparency=.1;b.BackgroundColor3=Color3.fromRGB(34,43,35)
 local labelObject=b:FindFirstChild('text');if not labelObject then labelObject=Instance.new('TextLabel');labelObject.Name='text';labelObject.Size=UDim2.new(1,-20,1,0);labelObject.Position=UDim2.fromOffset(10,0);labelObject.BackgroundTransparency=1;labelObject.Parent=b end
 if b:IsA('TextButton')then b.Text=''end
 labelObject.Text=label;labelObject.TextSize=15;labelObject.Font=Enum.Font.GothamMedium;labelObject.TextColor3=Color3.fromRGB(242,238,219);labelObject.TextWrapped=true;labelObject.RichText=false
 b.Parent=choices;b.Activated:Connect(function()if active and not speaking then speak(id)end end)
end
local function audioFor(id)
 if cache[id]then return cache[id]end
 if locale=='pt'and voices[id]then
  local s=Instance.new('Sound');s.Name='Caio_'..id;s.SoundId='rbxassetid://'..voices[id];s.Volume=.78;s.RollOffMinDistance=7;s.RollOffMaxDistance=25;s.Parent=head;cache[id]=s
  pcall(function()Content:PreloadAsync({s})end);return s
 end
 local t=Instance.new('AudioTextToSpeech');t.Name='Caio_'..id;t.VoiceId=D.Voices[locale];t.AutoLocalize=false;t.Text=text[id];t.Speed=.96;t.Volume=.85;t.Parent=head
 local wire=Instance.new('Wire');wire.SourceInstance=t;wire.TargetInstance=emitter;wire.Parent=t;cache[id]=t
 pcall(function()t:LoadAsync()end);return t
end
speak=function(id)
 if not npc or not npc.Parent then return end
 generation+=1;local token=generation;active=true;speaking=true;current=id;started=os.clock();clearChoices()
 if audio then pcall(function()if audio:IsA('Sound')then audio:Stop()else audio:Pause()end end)end
 overhead.Enabled=true;bubble.Text=text[id];bubble.MaxVisibleGraphemes=0
 local face=head:FindFirstChild('Expression');if face then face.Texture=D.Faces[D.Expressions[id]]end
 task.spawn(function()
  local source=audioFor(id);if generation~=token or not head.Parent then return end;audio=source
  local loaded=source.IsLoaded;local ended=false;local connection=source.Ended:Connect(function()ended=true end)
  if loaded then pcall(function()source.TimePosition=0;source:Play()end)end
  local length=source.TimeLength;local duration=loaded and math.max(2,length)or math.clamp(utf8.len(text[id])*.045,4,14)
  local begin=os.clock();local characters=utf8.len(text[id])or #text[id]
  repeat
   if generation~=token then connection:Disconnect();return end
   bubble.MaxVisibleGraphemes=math.floor(characters*math.clamp((os.clock()-begin)/(duration*.88),0,1));task.wait(.035)
  until (loaded and ended)or os.clock()-begin>duration+1.5
  connection:Disconnect();if generation~=token then return end
  bubble.MaxVisibleGraphemes=-1;speaking=false
  if id=='bye'then greeted=os.clock();task.delay(2,function()if generation==token then stop()end end)
  else for i,option in ipairs(D.Options[id])do button(text.choices[option],option,i)end end
 end)
end
local function attach(model)
 stop();for _,s in pairs(cache)do s:Destroy()end;cache={};joints={}
 npc=model;head=model.Head;prompt=model.HumanoidRootPart:FindFirstChild('TalkToCaio');overhead.Adornee=head;emitter.Parent=head
 for _,j in ipairs(model:GetDescendants())do if j:IsA('Motor6D')then joints[j]=j.C0 end end
 if prompt then prompt.ActionText=locale=='pt'and'Conversar'or locale=='es'and'Conversar'or'Talk';prompt.Triggered:Connect(function()if not active then speak('hello')end end)end
end
local scan=0
Run.Heartbeat:Connect(function(dt)
 scan+=dt;if scan<.25 then return end;scan=0
 local model=world:FindFirstChild('Caio');if model and model~=npc and model:FindFirstChild('Head')then attach(model)end
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 if not root or not npc or not npc.Parent then if active then stop()end;return end
 local distance=(root.Position-npc.HumanoidRootPart.Position).Magnitude
 if distance<11 and not active and os.clock()-greeted>75 then greeted=os.clock();speak('hello')end
 if distance>23 and active then greeted=os.clock();stop()end
 if workspace.CurrentCamera and listener.Parent~=workspace.CurrentCamera then listener.Parent=workspace.CurrentCamera end
end)
Run.PreSimulation:Connect(function()
 if not npc or not npc.Parent then return end
 local t=os.clock();local talk=speaking and 1 or 0;local age=t-started
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local yaw=0;if root and(root.Position-head.Position).Magnitude<22 then local p=npc.HumanoidRootPart.CFrame:PointToObjectSpace(root.Position);yaw=math.clamp(math.atan2(-p.X,-p.Z),-.65,.65)end
 for j,base in pairs(joints)do if j.Parent then
  if j.Name=='Neck'then j.C0=base*CFrame.Angles(math.sin(t*3)*.035*talk,yaw,math.sin(t*.7)*.025)
  elseif j.Name=='Right Shoulder'then
   local greet=active and current=='hello'and age<2.8 and math.sin(math.min(age,1)*math.pi/2)or 0
   local point=active and(current=='cliff'or current=='pond')and talk or 0
   j.C0=base*CFrame.Angles(-.20*talk-.65*point,0,-1.8*greet+math.sin(t*8)*.2*greet-.25*talk*math.sin(t*2))
  elseif j.Name=='Left Shoulder'then j.C0=base*CFrame.Angles(-.13*talk,0,.05+math.sin(t*1.7)*.06*talk)
  elseif j.Name=='RootJoint'then j.C0=base*CFrame.new(0,math.sin(t*1.6)*.025,0)*CFrame.Angles(0,0,math.sin(t*.55)*.018)end
 end end
end)
script.Destroying:Connect(function()stop();for j,base in pairs(joints)do if j.Parent then j.C0=base end end;for _,s in pairs(cache)do s:Destroy()end;emitter:Destroy();listener:Destroy();screen:Destroy()end)
