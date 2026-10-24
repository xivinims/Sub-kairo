local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local player=Players.LocalPlayer
local playerGui=player:WaitForChild('PlayerGui')
local runtime=RS:WaitForChild('LivingForest')
local D=require(runtime:WaitForChild('DialogueData'))
local Voice=require(runtime:WaitForChild('CaioVoicePlayer'))
local UI=require(runtime:WaitForChild('ForestInterface'))
local Report=require(runtime:WaitForChild('ReportClient'))
local locale=D.locale(game:GetService('LocalizationService').RobloxLocaleId or player.LocaleId)
local text=D.Locales[locale]
local voice=Voice.new(player,locale,D,require(runtime:WaitForChild('VoiceManifest')))
voice:preload()
local world=workspace:WaitForChild('OveryardPhotoWorld')
local old=playerGui:FindFirstChild('CaioConversation');if old then old:Destroy() end
local screen=Instance.new('ScreenGui');screen.Name='CaioConversation';screen.ResetOnSpawn=false;screen.DisplayOrder=45;screen.Parent=playerGui
screen:SetAttribute('InterfaceRevision','slim-caio-v14')
local choices=UI.choices(screen)
local overhead=Instance.new('BillboardGui');overhead.Name='CaioOverhead';overhead.Size=UDim2.fromOffset(340,120)
overhead.StudsOffsetWorldSpace=Vector3.new(0,3,0);overhead.AlwaysOnTop=false;overhead.MaxDistance=55;overhead.Enabled=false;overhead.Active=false;overhead.Parent=screen
local bubble=Instance.new('TextLabel');bubble.Size=UDim2.fromScale(1,1);bubble.BackgroundColor3=Color3.fromRGB(27,36,30)
bubble.BackgroundTransparency=.16;bubble.TextColor3=Color3.fromRGB(247,242,225);bubble.TextSize=17;bubble.Font=Enum.Font.GothamMedium
bubble.TextWrapped=true;bubble.Text='';bubble.Active=false;bubble.Selectable=false;bubble.Parent=overhead
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,12);corner.Parent=bubble
local padding=Instance.new('UIPadding');padding.PaddingLeft=UDim.new(0,15);padding.PaddingRight=UDim.new(0,15);padding.PaddingTop=UDim.new(0,10);padding.PaddingBottom=UDim.new(0,10);padding.Parent=bubble
local status=Instance.new('TextLabel');status.Name='VoiceStatus';status.BackgroundTransparency=1;status.Active=false;status.Selectable=false
status.AnchorPoint=Vector2.new(.5,1);status.Position=UDim2.fromScale(.5,.91);status.Size=UDim2.new(.82,0,0,28)
status.TextColor3=Color3.fromRGB(244,237,214);status.TextStrokeTransparency=.4;status.TextSize=12;status.Font=Enum.Font.GothamMedium;status.TextWrapped=true;status.Visible=false;status.Parent=screen
local messages={
 pt={'Carregando a voz…','A voz não carregou. Toque em Ouvir novamente.'},
 en={'Loading voice…','Voice could not load. Tap Listen again.'},
 es={'Cargando la voz…','La voz no cargó. Toca Escuchar de nuevo.'},
 fr={'Chargement de la voix…','Voix indisponible. Appuie sur Réécouter.'},
 de={'Stimme wird geladen…','Stimme nicht geladen. Wähle Erneut anhören.'},
 it={'Caricamento della voce…','Voce non disponibile. Tocca Ascolta di nuovo.'},
 ja={'音声を読み込み中…','音声を読み込めませんでした。もう一度聞くを押してください。'},
 ko={'음성 불러오는 중…','음성을 불러오지 못했어요. 다시 듣기를 눌러 주세요.'},
 zh={'正在加载语音…','语音加载失败。请点击再听一遍。'},
 ar={'جارٍ تحميل الصوت…','تعذر تحميل الصوت. اضغط على استمع مجدداً.'},
 hi={'आवाज़ लोड हो रही है…','आवाज़ लोड नहीं हुई। फिर सुनें दबाएँ।'},
}
local npc,head,click,clickConnection,faceControls
local hint=Instance.new('BillboardGui');hint.Name='TalkHint';hint.Size=UDim2.fromOffset(220,30);hint.StudsOffsetWorldSpace=Vector3.new(0,2.2,0);hint.MaxDistance=45;hint.AlwaysOnTop=false;hint.Active=false;hint.Enabled=false;hint.Parent=screen
local hintLabel=Instance.new('TextLabel');hintLabel.Size=UDim2.fromScale(1,1);hintLabel.BackgroundTransparency=1;hintLabel.Active=false;hintLabel.Selectable=false;hintLabel.TextColor3=Color3.fromRGB(247,242,225);hintLabel.TextStrokeTransparency=.35;hintLabel.Font=Enum.Font.GothamMedium;hintLabel.TextSize=13;hintLabel.Parent=hint
local hints={pt='Caio · toque para conversar',en='Caio · tap to talk',es='Caio · toca para hablar',fr='Caio · touche pour parler',de='Caio · zum Reden antippen',it='Caio · tocca per parlare',ja='カイオ · タップして話す',ko='카이우 · 탭하여 대화',zh='卡约 · 点击交谈',ar='كايو · اضغط للتحدث',hi='कायो · बात करने के लिए टैप करें'}
hintLabel.Text=hints[locale]
local inputConnections={}
local touchStarts={};local lastDrag=-100;local mouseStart
local function bindInput(signal,callback) table.insert(inputConnections,signal:Connect(callback)) end
-- A camera drag that ends over the NPC must not become a conversation tap.
bindInput(Input.TouchStarted,function(input) touchStarts[input]=input.Position end)
bindInput(Input.TouchMoved,function(input) local start=touchStarts[input];if start and (input.Position-start).Magnitude>10 then lastDrag=os.clock() end end)
bindInput(Input.TouchEnded,function(input) touchStarts[input]=nil end)
bindInput(Input.InputBegan,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then mouseStart=Input:GetMouseLocation() end end)
bindInput(Input.InputChanged,function(input) if mouseStart and input.UserInputType==Enum.UserInputType.MouseMovement and (Input:GetMouseLocation()-mouseStart).Magnitude>10 then lastDrag=os.clock() end end)
bindInput(Input.InputEnded,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then mouseStart=nil end end)
local joints={};local current='hello';local speaking=false;local active=false;local generation=0;local started=0
local function stop()
 generation+=1;speaking=false;active=false;choices.hide();Report.close();overhead.Enabled=false;status.Visible=false;hint.Enabled=false
 voice:stop();screen:SetAttribute('VoiceState','idle')
end
local speak
local function button(label,id,order)
 choices.button('Choice_'..id,label,order,function()
  if not active or speaking then return end
  if id=='feedback' then
   task.spawn(function() pcall(function() game:GetService('SocialService'):PromptFeedbackSubmissionAsync() end) end)
  elseif id=='retry' then speak(current)
  else speak(id) end
 end)
end
local function finish(id,token,failed)
 speaking=false;bubble.MaxVisibleGraphemes=-1
 status.Visible=failed;status.Text=messages[locale][2]
 screen:SetAttribute('VoiceState',failed and 'unavailable' or 'finished')
 if id=='bye' and not failed then
  task.delay(2,function() if generation==token then stop() end end)
 elseif id=='report' then
  status.Visible=false;Report.open(screen,locale)
 else
  local options=D.Options[id] or {};local offset=failed and 1 or 0
  if failed then button(text.retry,'retry',1) end
  for i,option in ipairs(options) do button(text.choices[option],option,i+offset) end
  choices.show(#options+offset)
 end
end
speak=function(id)
 if not npc or not npc.Parent or not head or not head.Parent or not text[id] then return end
 generation+=1;local token=generation;active=true;speaking=false;current=id;started=os.clock()
 choices.hide();Report.close();voice:stop();hint.Enabled=false;overhead.Enabled=true;bubble.Text=text[id];bubble.MaxVisibleGraphemes=-1
 screen:SetAttribute('VoiceState','loading');status.Text=messages[locale][1];status.Visible=true
 local function stillCurrent() return generation==token and npc~=nil and npc.Parent~=nil and head~=nil and head.Parent~=nil end
 task.spawn(function()
  local ok,playback=pcall(function() return voice:play(id,stillCurrent) end)
  if not stillCurrent() then return end
  if not ok then warn('[Caio dialogue] '..tostring(playback));playback=nil end
  if not playback then finish(id,token,true);return end
  screen:SetAttribute('VoiceState','playing');screen:SetAttribute('VoiceSource',playback.kind)
  status.Visible=false;speaking=true;started=os.clock()
  local duration=math.max(1,playback.length);local begin=os.clock();local characters=utf8.len(text[id]) or #text[id]
  repeat
   if not stillCurrent() then return end
   bubble.MaxVisibleGraphemes=math.floor(characters*math.clamp((os.clock()-begin)/(duration*.88),0,1))
   task.wait(.035)
  until playback.ended or os.clock()-begin>duration+2
  if stillCurrent() then voice:stop();finish(id,token,false) end
 end)
end
local function attach(model)
 stop();if clickConnection then clickConnection:Disconnect() end
 joints={};npc=model;head=model.Head;click=model:FindFirstChild('TalkToCaio');overhead.Adornee=head;hint.Adornee=head
 faceControls=head:FindFirstChildOfClass('FaceControls')
 for _,j in ipairs(model:GetDescendants()) do if j:IsA('Motor6D') then joints[j]=j.C0 end end
 if click and click:IsA('ClickDetector') then
  clickConnection=click.MouseClick:Connect(function(who)
   if who~=player or active or os.clock()-lastDrag<.35 then return end
   local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
   local npcRoot=model:FindFirstChild('HumanoidRootPart')
   if root and npcRoot and (root.Position-npcRoot.Position).Magnitude<=14 then speak('hello') end
  end)
 end
end
local scan=0
local heartbeat=Run.Heartbeat:Connect(function(dt)
 scan+=dt;if scan<.25 then return end;scan=0
 local model=world:FindFirstChild('Caio')
 if model and model~=npc and model:FindFirstChild('Head') and model:FindFirstChild('HumanoidRootPart') then attach(model) end
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local npcRoot=npc and npc.Parent and npc:FindFirstChild('HumanoidRootPart')
 if not root or not npcRoot or not head or not head.Parent then if active then stop() end;return end
 local distance=(root.Position-npcRoot.Position).Magnitude
 hint.Enabled=distance<=14 and not active
 if distance>23 and active then stop() end
end)
local gazeYaw,gazePitch=0,0
local nextBlink=os.clock()+3.3;local blinkStart=-100;local jaw=0
local faceProperties={'LeftEyeClosed','RightEyeClosed','JawDrop','EyesLookLeft','EyesLookRight','EyesLookUp','EyesLookDown'}
local gestures=Run.PreSimulation:Connect(function(dt)
 if not npc or not npc.Parent or not head or not head.Parent or not npc:FindFirstChild('HumanoidRootPart') then return end
 local t=os.clock();local talk=speaking and 1 or 0;local age=t-started
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local yaw,pitch=0,0
 if root and(root.Position-head.Position).Magnitude<22 then
  local target=player.Character:FindFirstChild('Head')or root
  local p=npc.HumanoidRootPart.CFrame:VectorToObjectSpace(target.Position-head.Position)
  local angle=math.atan2(-p.X,-p.Z)
  if math.abs(angle)<1.65 then yaw=math.clamp(angle,-.72,.72);pitch=math.clamp(math.atan2(p.Y,Vector2.new(p.X,p.Z).Magnitude),-.3,.35) end
 end
 local blend=1-math.exp(-math.min(dt,.1)*4.2);gazeYaw+=(yaw-gazeYaw)*blend;gazePitch+=(pitch-gazePitch)*blend

 if faceControls and faceControls.Parent then
  if t>nextBlink then blinkStart=t;nextBlink=t+3.2+math.random()*3.1 end
  local ageBlink=t-blinkStart;local blink=ageBlink<.18 and math.sin(ageBlink/.18*math.pi)*.9 or 0
  faceControls.LeftEyeClosed=blink;faceControls.RightEyeClosed=blink
  faceControls.EyesLookLeft=math.max(0,gazeYaw)*.2;faceControls.EyesLookRight=math.max(0,-gazeYaw)*.2
  faceControls.EyesLookUp=math.max(0,gazePitch)*.25;faceControls.EyesLookDown=math.max(0,-gazePitch)*.25
  local mouth=0
  if speaking then
   local playback=voice.playback
   if playback and playback.source:IsA('Sound') then mouth=math.clamp(playback.source.PlaybackLoudness/850,0,.24)
   else mouth=(.07+.07*math.sin(t*13)) end
  end
  jaw+=(mouth-jaw)*(1-math.exp(-math.min(dt,.1)*18));faceControls.JawDrop=jaw
 end
 for j,base in pairs(joints)do if j.Parent then
  if j.Name=='Neck'then j.C0=base*CFrame.Angles(-gazePitch+math.sin(t*3)*.035*talk,gazeYaw,math.sin(t*.7)*.025)
  elseif j.Name=='RightShoulder'then
   local greet=speaking and current=='hello' and age<2.8 and math.sin(math.clamp(age/2.8,0,1)*math.pi) or 0
   local point=active and(current=='cliff'or current=='pond')and talk or 0
   j.C0=base*CFrame.Angles(-.20*talk-.65*point,0,-1.1*greet+math.sin(t*6)*.12*greet-.25*talk*math.sin(t*2))
  elseif j.Name=='RightElbow'then j.C0=base*CFrame.Angles(-.65*talk,0,0)
  elseif j.Name=='LeftShoulder'then j.C0=base*CFrame.Angles(-.13*talk,0,.05+math.sin(t*1.7)*.06*talk)
  elseif j.Name=='Waist'then j.C0=base*CFrame.new(0,math.sin(t*1.6)*.025,0)*CFrame.Angles(0,0,math.sin(t*.55)*.018)end
 end end
end)
script.Destroying:Connect(function()
 stop();heartbeat:Disconnect();gestures:Disconnect();if clickConnection then clickConnection:Disconnect() end
 for _,connection in ipairs(inputConnections) do connection:Disconnect() end
 if faceControls and faceControls.Parent then for _,property in ipairs(faceProperties) do faceControls[property]=0 end end
 for j,base in pairs(joints) do if j.Parent then j.C0=base end end
 voice:destroy();screen:Destroy()
end)
