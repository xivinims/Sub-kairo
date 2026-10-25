-- Runs only on each viewer's client; gaze and dialogue never replicate.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer
local npc=script.Parent
local root=npc:WaitForChild("HumanoidRootPart")
local head=npc:WaitForChild("Head")
local torso=npc:WaitForChild("Torso")
local neck=torso:FindFirstChild("Neck")
local joint=root:FindFirstChild("RootJoint")
local neckBase=neck and neck.C0
local jointBase=joint and joint.C0
local prompt=npc:WaitForChild("ProximityPrompt")
local resources=RS:WaitForChild("LobbyGuideResources")
local playerGui=player:WaitForChild("PlayerGui")
local old=playerGui:FindFirstChild("GuideDialogue")
if old then old:Destroy() end
local ui=resources.dialog:Clone() ui.Name="GuideDialogue" ui.ResetOnSpawn=false ui.Parent=player:WaitForChild("PlayerGui")
local responses=ui:WaitForChild("dialogResponses")
local template=responses:WaitForChild("template") template.Visible=false
local bubble=head:WaitForChild("gui")
local label=bubble:WaitForChild("dialog")
label.Visible=false
local greeting="Ei. Respira um pouco. Aqui no lobby você pode descansar. Quer que eu te explique como tudo funciona?"
local choices={"Como eu jogo?","E se eu for o perseguidor?","Só vim descansar."}
local replies={
 "Escolha um mapa na votação. Quando a partida começar, fique atento aos caminhos e cuide dos outros sobreviventes.",
 "Escolha seu personagem durante o intervalo. Se você for sorteado, vai controlar o perseguidor nessa partida.",
 "Tudo bem. Fica à vontade. Quando estiver pronto, a próxima partida estará esperando por você."
}
local generation=0 local active=false local choosing=false
local connections={} local buttons={}
local voice=Instance.new("AudioTextToSpeech") voice.Name="PortugueseVoice" voice.VoiceId="1001" voice.AutoLocalize=false voice.Volume=.34 voice.Speed=.90 voice.Pitch=.88 voice.Parent=ui
local output=Instance.new("AudioDeviceOutput") output.Player=player output.Parent=ui
local wire=Instance.new("Wire") wire.SourceInstance=voice wire.TargetInstance=output wire.Parent=ui
local function stopVoice() voice:Pause() voice.TimePosition=0 end
local function speak(line,token)
 task.spawn(function()
  local ok,err=pcall(function()
   stopVoice() voice.Text=line voice:LoadAsync()
   if token==generation and active then voice:Play() end
  end)
  if not ok then warn("Guide voice unavailable: "..tostring(err)) end
 end)
end
local function hideChoices() for _,b in ipairs(buttons) do b.Visible=false end end
local function close()
 generation+=1 active=false choosing=false stopVoice() hideChoices()
 label.Visible=false bubble.name.Visible=true bubble.arrow.Visible=true
 bubble.name.TextTransparency=0 bubble.arrow.TextTransparency=0
end
local function showLine(line,token,after)
 label.Visible=true label.Text="" label.TextTransparency=0 label.UIStroke.Transparency=0
 label.MaxVisibleGraphemes=0 label.Text=line
 speak(line,token)
 task.spawn(function()
  local count=0
  for _ in utf8.graphemes(line) do
   if generation~=token or not active then return end
   count+=1 label.MaxVisibleGraphemes=count task.wait(.025)
  end
  if generation==token and active then label.MaxVisibleGraphemes=-1 after() end
 end)
end
local function choose(index)
 if not active or not choosing or not replies[index] then return end
 choosing=false hideChoices() generation+=1
 local token=generation
 showLine(replies[index],token,function()
  task.delay(6,function() if generation==token then close() end end)
 end)
end
for i,title in ipairs(choices) do
 local b=template:Clone() b.Name="Choice"..i b.Visible=false b.LayoutOrder=i
 b.Size=UDim2.new(1,0,0,42) b.Parent=responses
 b.text.Text=title b.text.TextSize=16 b.text.TextWrapped=true b.text.RichText=false
 table.insert(buttons,b)
 table.insert(connections,b.Activated:Connect(function() choose(i) end))
end
-- Retain the provided response artwork, with compact mobile-safe spacing.
responses.AnchorPoint=Vector2.new(.5,1) responses.Position=UDim2.new(.5,0,1,-28) responses.Size=UDim2.new(.8,0,0,142)
local limit=Instance.new("UISizeConstraint",responses) limit.MaxSize=Vector2.new(480,142)
local layout=responses:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout",responses)
layout.Padding=UDim.new(0,6) layout.SortOrder=Enum.SortOrder.LayoutOrder
table.insert(connections,prompt.Triggered:Connect(function()
 if active or player:GetAttribute("InRound") or player:GetAttribute("InMenu") then return end
 active=true generation+=1 choosing=false local token=generation
 bubble.name.Visible=false bubble.arrow.Visible=false
 showLine(greeting,token,function() choosing=true for _,b in ipairs(buttons) do b.Visible=true end end)
end))
table.insert(connections,UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.Escape and active then close() return end
 local index=table.find({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three},input.KeyCode)
 if index then choose(index) end
end))
local connection
connection=Run.RenderStepped:Connect(function(dt)
 if not npc.Parent then
  connection:Disconnect() for _,c in ipairs(connections) do c:Disconnect() end
  ui:Destroy() return
 end
 local character=player.Character
 local target=character and character:FindFirstChild("Head")
 local yaw,pitch,lean=0,0,0
 local allowed=not player:GetAttribute("InRound") and not player:GetAttribute("InMenu")
 local distance=target and (target.Position-head.Position).Magnitude or math.huge
 local closeEnough=target and distance<16 and allowed
 prompt.Enabled=allowed and not active
 if closeEnough then
  local delta=root.CFrame:VectorToObjectSpace(target.Position-head.Position)
  if delta.Z<0 then
   yaw=math.clamp(math.atan2(-delta.X,-delta.Z),-.38,.38)
   pitch=math.clamp(math.atan2(delta.Y,math.max(.1,Vector2.new(delta.X,delta.Z).Magnitude)),-.15,.15)
   lean=.025
  end
 end
 local alpha=1-math.exp(-dt*5)
 if neck then neck.C0=neck.C0:Lerp(neckBase*CFrame.Angles(pitch,0,yaw),alpha) end
 if joint then joint.C0=joint.C0:Lerp(jointBase*CFrame.Angles(lean,0,yaw*.12),alpha) end
 if active and (not allowed or distance>12 or not target) then close() end
end)
