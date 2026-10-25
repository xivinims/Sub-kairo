-- Runs only on each viewer's client; gaze and dialogue never replicate.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local ContentProvider=game:GetService("ContentProvider")
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
local ui=resources.dialog:Clone()
ui.Name="GuideDialogue"
ui.ResetOnSpawn=false
ui.Parent=playerGui
local responses=ui:WaitForChild("dialogResponses")
local template=responses:WaitForChild("template")
template.Visible=false
local bubble=head:WaitForChild("gui")
local label=bubble:WaitForChild("dialog")
-- Keep the overhead dialogue compact. The original asset was huge on phones.
bubble.Size=UDim2.fromOffset(250,92)
bubble.StudsOffset=Vector3.new(0,2.45,0)
bubble.AlwaysOnTop=true
bubble.MaxDistance=22
bubble.LightInfluence=0
if bubble:IsA("BillboardGui") then bubble.ClipsDescendants=false end
local nameLabel=bubble:FindFirstChild("name")
if nameLabel and nameLabel:IsA("TextLabel") then
 nameLabel.TextSize=12
 nameLabel.TextScaled=false
 nameLabel.TextWrapped=false
 nameLabel.Size=UDim2.new(1,-18,0,22)
 nameLabel.Position=UDim2.fromOffset(9,4)
end
if label:IsA("TextLabel") then
 label.TextSize=11
 label.TextScaled=false
 label.TextWrapped=true
 label.TextXAlignment=Enum.TextXAlignment.Left
 label.TextYAlignment=Enum.TextYAlignment.Center
 label.AutomaticSize=Enum.AutomaticSize.None
 label.Size=UDim2.new(1,-20,0,58)
 label.Position=UDim2.fromOffset(10,26)
end
label.Visible=false

local greeting="Ah... hello. How are you? My name is Fill. I'm your guide around here. If you have a question, go ahead and ask. So... what do you want to know?"
local choices={
 "How does the game work?",
 "What if I'm the killer?",
 "What can I do here?",
 "Who are you?",
 "Nothing right now.",
}
local replies={
 "Alright. When the match begins, one player will be chosen as the killer. Everyone else will have to survive until the timer runs out. Sounds simple. It isn't. Use the map, pay attention to sounds, and don't stay in one place for too long. If someone needs your help... decide quickly.",
 "If you're chosen... then the hunt is yours. You'll be able to choose your character before the match begins. Each killer has their own style, animations, and different ways to attack. Find the survivors before time runs out. And don't let anyone escape.",
 "Here? This is the lobby. You can explore, check your profile, change your settings, or simply wait for the next match. You can also talk to me. I usually know what's going on around here. Usually.",
 "Still curious about me? Fill. That's the name you need to remember. I stay here to guide new players, explain a few things... and keep an eye on what happens. Let's just say I know this place very well.",
 "Alright. Enjoy the lobby. When you change your mind... you know where to find me.",
}

local generation=0
local active=false
local choosing=false
local connections={}
local buttons={}
local oldVoice=SoundService:FindFirstChild("FillVoice")
if oldVoice then oldVoice:Destroy() end
local voice=Instance.new("Sound")
voice.Name="FillVoice"
voice.Volume=.78
voice.Looped=false
voice.PlaybackSpeed=1
voice.RollOffMode=Enum.RollOffMode.InverseTapered
voice.Parent=SoundService

local voiceConnection=nil
local function stopVoice()
 if voiceConnection then voiceConnection:Disconnect() voiceConnection=nil end
 if voice.IsPlaying then voice:Stop() end
 voice.TimePosition=0
end
local function voiceId(index)
 local id=tonumber(resources:GetAttribute("Voice"..index)) or 0
 return id>0 and id or nil
end
local function speak(index,token,done)
 stopVoice()
 local id=voiceId(index)
 if not id then
  warn("Fill voice id missing for line "..tostring(index))
  task.defer(function() if token==generation and active then done() end end)
  return
 end
 voice.SoundId="rbxassetid://"..id
 local finished=false
 local function finish()
  if finished then return end
  finished=true
  if voiceConnection then voiceConnection:Disconnect() voiceConnection=nil end
  if token==generation and active then done() end
 end
 voiceConnection=voice.Ended:Connect(finish)

 -- Roblox may need a moment to resolve a newly-uploaded audio asset. Preloading from
 -- SoundService is much more reliable than calling :Play() from a ScreenGui.
 local preloadOk,preloadErr=pcall(function()
  ContentProvider:PreloadAsync({voice})
 end)
 if not preloadOk then warn("Fill voice preload failed for "..id..": "..tostring(preloadErr)) end

 local ok,err=pcall(function()
  voice.TimePosition=0
  voice:Play()
 end)
 if not ok then
  warn("Fill voice play failed for "..id..": "..tostring(err))
  finish()
  return
 end

 task.delay(1.25,function()
  if finished or token~=generation or not active then return end
  if not voice.IsPlaying and voice.TimeLength<=0 then
   warn("Fill voice asset did not become playable: "..tostring(id))
   finish()
  end
 end)
end

local function hideChoices()
 for _,b in ipairs(buttons) do b.Visible=false end
end
local function close()
 generation+=1
 active=false
 choosing=false
 stopVoice()
 hideChoices()
 label.Visible=false
 bubble.name.Visible=true
 bubble.arrow.Visible=true
 bubble.name.TextTransparency=0
 bubble.arrow.TextTransparency=0
end
local function showLine(line,token,voiceIndex,after)
 label.Visible=true
 label.Text=""
 label.TextTransparency=0
 label.UIStroke.Transparency=0
 label.MaxVisibleGraphemes=0
 label.Text=line
 local textDone=false
 local audioDone=false
 local completed=false
 local function maybeFinish()
  if completed or not textDone or not audioDone then return end
  if generation~=token or not active then return end
  completed=true
  label.MaxVisibleGraphemes=-1
  after()
 end
 speak(voiceIndex,token,function() audioDone=true maybeFinish() end)
 task.spawn(function()
  local count=0
  for _ in utf8.graphemes(line) do
   if generation~=token or not active then return end
   count+=1
   label.MaxVisibleGraphemes=count
   task.wait(.018)
  end
  textDone=true
  maybeFinish()
 end)
end
local function choose(index)
 if not active or not choosing or not replies[index] then return end
 choosing=false
 hideChoices()
 generation+=1
 local token=generation
 showLine(replies[index],token,index+1,function()
  task.delay(.45,function() if generation==token and active then close() end end)
 end)
end

for i,title in ipairs(choices) do
 local b=template:Clone()
 b.Name="Choice"..i
 b.Visible=false
 b.LayoutOrder=i
 b.Size=UDim2.new(1,0,0,40)
 b.Parent=responses
 b.text.Text=title
 b.text.TextSize=15
 b.text.TextWrapped=true
 b.text.RichText=false
 table.insert(buttons,b)
 table.insert(connections,b.Activated:Connect(function() choose(i) end))
end
responses.AnchorPoint=Vector2.new(.5,1)
responses.Position=UDim2.new(.5,0,1,-24)
responses.Size=UDim2.new(.82,0,0,226)
local limit=Instance.new("UISizeConstraint",responses)
limit.MaxSize=Vector2.new(500,226)
local layout=responses:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout",responses)
layout.Padding=UDim.new(0,5)
layout.SortOrder=Enum.SortOrder.LayoutOrder

table.insert(connections,prompt.Triggered:Connect(function()
 if active or player:GetAttribute("InRound") or player:GetAttribute("InMenu") then return end
 active=true
 generation+=1
 choosing=false
 local token=generation
 bubble.name.Visible=false
 bubble.arrow.Visible=false
 showLine(greeting,token,1,function()
  choosing=true
  for _,b in ipairs(buttons) do b.Visible=true end
 end)
end))
table.insert(connections,UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.Escape and active then close() return end
 local index=table.find({
  Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five
 },input.KeyCode)
 if index then choose(index) end
end))

local connection
connection=Run.RenderStepped:Connect(function(dt)
 if not npc.Parent then
  connection:Disconnect()
  for _,c in ipairs(connections) do c:Disconnect() end
  stopVoice()
  voice:Destroy()
  ui:Destroy()
  return
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
