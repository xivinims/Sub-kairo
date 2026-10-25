-- Local-only gaze: no player can rotate the guide for another client.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local npc=workspace:WaitForChild("LobbyGuide",15)
if not npc then return end
local root=npc:WaitForChild("HumanoidRootPart")
local head=npc:WaitForChild("Head")
local torso=npc:WaitForChild("Torso")
local neck=torso:FindFirstChild("Neck")
local joint=root:FindFirstChild("RootJoint")
local neckBase=neck and neck.C0
local jointBase=joint and joint.C0
local prompt=npc:WaitForChild("ProximityPrompt")
local dialogTemplate=RS:WaitForChild("LobbyGuideResources"):WaitForChild("dialog")
local ui=dialogTemplate:Clone() ui.ResetOnSpawn=false ui.Parent=player:WaitForChild("PlayerGui")
local Dialog=require(RS.LobbyGuideResources.DialogModule)
local dialog=Dialog.new("Guardião",npc,prompt)
local greeting="Ei. Respira um pouco. Aqui no lobby você pode descansar. Quer que eu te explique como tudo funciona?"
dialog:addDialog(greeting,{"Como eu jogo?","E se eu for o perseguidor?","Só vim descansar."})
local replies={
 "Escolha um mapa na votação. Quando a partida começar, fique atento aos caminhos e cuide dos outros sobreviventes.",
 "Escolha seu personagem durante o intervalo. Se você for sorteado, vai controlar o perseguidor nessa partida.",
 "Tudo bem. Fica à vontade. Quando estiver pronto, a próxima partida estará esperando por você."
}
local voice,output,wire
pcall(function()
 voice=Instance.new("AudioTextToSpeech") voice.Name="GuidePortugueseVoice" voice.VoiceId="1001" voice.AutoLocalize=false voice.Volume=.3 voice.Speed=.92 voice.Pitch=.96 voice.Parent=ui
 output=Instance.new("AudioDeviceOutput") output.Player=player output.Parent=ui
 wire=Instance.new("Wire") wire.SourceInstance=voice wire.TargetInstance=output wire.Parent=ui
end)
local function speak(line)
 if voice then pcall(function() voice:Stop() voice.Text=line voice:Play() end) end
end
local busy=false
prompt.Triggered:Connect(function()
 if busy or player:GetAttribute("InRound") or player:GetAttribute("InMenu") then return end
 busy=true dialog:triggerDialog(player,1) speak(greeting)
end)
dialog.responded:Connect(function(choice)
 local reply=replies[choice]
 if reply then dialog:hideGui(reply) speak(reply) else dialog:hideGui() end
 task.delay(3,function() busy=false end)
end)
local connection
connection=Run.RenderStepped:Connect(function(dt)
 if not npc.Parent then connection:Disconnect() ui:Destroy() return end
 local character=player.Character
 local target=character and character:FindFirstChild("Head")
 local yaw,pitch,lean=0,0,0
 local close=target and (target.Position-head.Position).Magnitude<16 and not player:GetAttribute("InRound")
 if close then
  local delta=root.CFrame:VectorToObjectSpace(target.Position-head.Position)
  if delta.Z<0 then
   yaw=math.clamp(math.atan2(-delta.X,-delta.Z),-.38,.38)
   pitch=math.clamp(math.atan2(delta.Y,math.max(.1,Vector2.new(delta.X,delta.Z).Magnitude)),-.15,.15)
   lean=.035
  end
 end
 local alpha=1-math.exp(-dt*5)
 if neck then neck.C0=neck.C0:Lerp(neckBase*CFrame.Angles(pitch,0,yaw),alpha) end
 if joint then joint.C0=joint.C0:Lerp(jointBase*CFrame.Angles(lean,0,yaw*.12),alpha) end
 if busy and (not target or not close) then dialog:hideGui() busy=false if voice then pcall(function() voice:Stop() end) end end
end)
