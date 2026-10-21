local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
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
screen:SetAttribute('InterfaceRevision','voice-touch-v13')
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
local npc,head,prompt,promptConnection
local joints={};local current='hello';local speaking=false;local active=false;local generation=0;local greeted=-100;local started=0
local function stop()
 generation+=1;speaking=false;active=false;choices.hide();Report.close();overhead.Enabled=false;status.Visible=false
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
  greeted=os.clock();task.delay(2,function() if generation==token then stop() end end)
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
 choices.hide();Report.close();voice:stop();overhead.Enabled=true;bubble.Text=text[id];bubble.MaxVisibleGraphemes=-1
 screen:SetAttribute('VoiceState','loading');status.Text=messages[locale][1];status.Visible=true
 local face=head:FindFirstChild('Expression');if face then face.Texture=D.Faces[D.Expressions[id]] end
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
 stop();if promptConnection then promptConnection:Disconnect() end
 joints={};npc=model;head=model.Head;prompt=model.HumanoidRootPart:FindFirstChild('TalkToCaio');overhead.Adornee=head
 for _,j in ipairs(model:GetDescendants()) do if j:IsA('Motor6D') then joints[j]=j.C0 end end
 if prompt then
  prompt.ActionText=locale=='pt' and 'Conversar' or locale=='es' and 'Conversar' or 'Talk'
  promptConnection=prompt.Triggered:Connect(function() if not active then speak('hello') end end)
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
 if distance<11 and not active and os.clock()-greeted>75 then greeted=os.clock();speak('hello') end
 if distance>23 and active then greeted=os.clock();stop() end
end)
local gazeYaw,gazePitch=0,0
local gestures=Run.PreSimulation:Connect(function(dt)
 if not npc or not npc.Parent or not head or not head.Parent or not npc:FindFirstChild('HumanoidRootPart') then return end
 local t=os.clock();local talk=speaking and 1 or 0;local age=t-started
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local yaw,pitch=0,0
 if root and(root.Position-head.Position).Magnitude<22 then
  local target=player.Character:FindFirstChild('Head')or root
  local p=npc.HumanoidRootPart.CFrame:VectorToObjectSpace(target.Position-head.Position)
  yaw=math.clamp(math.atan2(-p.X,-p.Z),-.7,.7);pitch=math.clamp(math.atan2(p.Y,Vector2.new(p.X,p.Z).Magnitude),-.3,.35)
 end
 local blend=1-math.exp(-math.min(dt,.1)*5);gazeYaw+=(yaw-gazeYaw)*blend;gazePitch+=(pitch-gazePitch)*blend

 for j,base in pairs(joints)do if j.Parent then
  if j.Name=='Neck'then j.C0=base*CFrame.Angles(-gazePitch+math.sin(t*3)*.035*talk,gazeYaw,math.sin(t*.7)*.025)
  elseif j.Name=='RightShoulder'then
   local greet=active and current=='hello'and age<2.8 and math.sin(math.min(age,1)*math.pi/2)or 0
   local point=active and(current=='cliff'or current=='pond')and talk or 0
   j.C0=base*CFrame.Angles(-.20*talk-.65*point,0,-1.8*greet+math.sin(t*8)*.2*greet-.25*talk*math.sin(t*2))
  elseif j.Name=='RightElbow'then j.C0=base*CFrame.Angles(-.65*talk,0,0)
  elseif j.Name=='LeftShoulder'then j.C0=base*CFrame.Angles(-.13*talk,0,.05+math.sin(t*1.7)*.06*talk)
  elseif j.Name=='Waist'then j.C0=base*CFrame.new(0,math.sin(t*1.6)*.025,0)*CFrame.Angles(0,0,math.sin(t*.55)*.018)end
 end end
end)
script.Destroying:Connect(function()
 stop();heartbeat:Disconnect();gestures:Disconnect();if promptConnection then promptConnection:Disconnect() end
 for j,base in pairs(joints) do if j.Parent then j.C0=base end end
 voice:destroy();screen:Destroy()
end)
