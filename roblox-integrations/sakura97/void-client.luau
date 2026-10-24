local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local event=RS:WaitForChild("SweanVoidEvent")
local generation=0
local gui,connection,track,music=nil,nil,nil,nil
local controls=nil
local tweens={}
local function tween(object,duration,properties)
 local t=TweenService:Create(object,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),properties)
 tweens[#tweens+1]=t t:Play() return t
end
local function clean()
 generation+=1
 for _,t in ipairs(tweens) do t:Cancel() end table.clear(tweens)
 if connection then connection:Disconnect() connection=nil end
 if track then track:Stop() track:Destroy() track=nil end
 if music then music:Destroy() music=nil end
 if gui then gui:Destroy() gui=nil end
 if controls and not player:GetAttribute("InMenu") then controls:Enable() end
end
local function start(cause,mode)
 clean() local token=generation
 if token~=generation then return end
 -- No background music in death/spectator presentation.
 gui=Instance.new("ScreenGui") gui.Name="BeyondTheIsland" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Global gui.DisplayOrder=2000 gui:SetAttribute("Phase","messages") gui.Parent=player:WaitForChild("PlayerGui")
 local background=Instance.new("Frame") background.Name="Darkness" background.BorderSizePixel=0
 background.Size=UDim2.fromScale(1,1) background.BackgroundColor3=Color3.fromRGB(2,4,7) background.BackgroundTransparency=1
 background.ClipsDescendants=true background.Parent=gui
 tween(background,.5,{BackgroundTransparency=0})
 -- Texture-free, bounded effects: 14 translucent glow layers and 10 tiny bubbles.
 local atmosphere=Instance.new("Frame") atmosphere.Name="SubtleAtmosphere" atmosphere.Size=UDim2.fromScale(1,1)
 atmosphere.BackgroundTransparency=1 atmosphere.ZIndex=2 atmosphere.Parent=background
 local fade=Instance.new("NumberValue") fade.Value=1 fade.Parent=atmosphere
 local glow={}
 for i=1,14 do
  local circle=Instance.new("Frame") circle.Name="SoftLight" circle.AnchorPoint=Vector2.new(.5,.5)
  circle.Position=UDim2.fromScale(.5,.23) circle.Size=UDim2.fromScale(.04+i*.035,.04+i*.035)
  circle.BackgroundColor3=Color3.fromRGB(73,135,163) circle.BackgroundTransparency=.987 circle.BorderSizePixel=0 circle.ZIndex=2
  local ratio=Instance.new("UIAspectRatioConstraint") ratio.AspectRatio=1 ratio.DominantAxis=Enum.DominantAxis.Height ratio.Parent=circle
  local round=Instance.new("UICorner") round.CornerRadius=UDim.new(1,0) round.Parent=circle circle.Parent=atmosphere
  glow[#glow+1]=circle
 end
 local beam=Instance.new("Frame") beam.Name="FaintTopLight" beam.AnchorPoint=Vector2.new(.5,0)
 beam.Position=UDim2.fromScale(.5,0) beam.Size=UDim2.fromScale(.32,.85) beam.BackgroundColor3=Color3.fromRGB(65,125,155)
 beam.BackgroundTransparency=.97 beam.BorderSizePixel=0 beam.ZIndex=2 beam.Parent=atmosphere
 local gradient=Instance.new("UIGradient") gradient.Rotation=90
 gradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.7),NumberSequenceKeypoint.new(.3,.15),NumberSequenceKeypoint.new(1,1)}) gradient.Parent=beam
 local bubbles={}
 for i=1,10 do
  local bubble=Instance.new("Frame") bubble.Name="Bubble" bubble.BackgroundTransparency=1 bubble.AnchorPoint=Vector2.new(.5,.5)
  bubble.Size=UDim2.fromOffset(3+(i%4)*2,3+(i%4)*2) bubble.ZIndex=3 bubble.Parent=atmosphere
  local round=Instance.new("UICorner") round.CornerRadius=UDim.new(1,0) round.Parent=bubble
  local stroke=Instance.new("UIStroke") stroke.Color=Color3.fromRGB(121,181,204) stroke.Thickness=1 stroke.Transparency=.9 stroke.Parent=bubble
  bubbles[#bubbles+1]={frame=bubble,stroke=stroke,x=.18+((i*37)%65)/100,phase=i/10,speed=.015+(i%3)*.004}
 end
 local label=Instance.new("TextLabel") label.Name="DeathMessage" label.BackgroundTransparency=1
 label.TextColor3=Color3.fromRGB(185,214,223) label.TextTransparency=1 label.Font=Enum.Font.GothamMedium
 label.TextSize=24 label.TextScaled=true label.TextWrapped=true label.AnchorPoint=Vector2.new(.5,.5)
 label.Size=UDim2.fromScale(.88,.16) label.Position=UDim2.fromScale(.5,.46) label.Text="" label.ZIndex=5 label.Parent=background
 local limit=Instance.new("UITextSizeConstraint") limit.MinTextSize=16 limit.MaxTextSize=24 limit.Parent=label
 -- The viewport is ABOVE the text: opaque avatar pixels cover it, the rest stays transparent.
 local view=Instance.new("ViewportFrame") view.Name="PlayerSwimming" view.BackgroundTransparency=1 view.ZIndex=6
 view.Size=UDim2.fromScale(1,1.12) view.Position=UDim2.fromScale(0,.30)
 view.Ambient=Color3.fromRGB(46,57,69) view.LightColor=Color3.fromRGB(106,150,173)
 view.LightDirection=Vector3.new(-.25,-1,-.4) view.Parent=background
 local world=Instance.new("WorldModel") world.Parent=view
 local camera=Instance.new("Camera") camera.FieldOfView=42 camera.Parent=view view.CurrentCamera=camera
 local poseStep=function() end
 local bodyHeight=6
 local char=player.Character
 if char then
  local archivable=char.Archivable char.Archivable=true
  local clone=char:Clone() char.Archivable=archivable
  if clone then
   for _,d in ipairs(clone:GetDescendants()) do
    if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("Tool") then d:Destroy()
    elseif d:IsA("BasePart") then d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Anchored=false end
   end
   clone.Parent=world clone:PivotTo(CFrame.new(0,0,0))
   local root=clone:FindFirstChild("HumanoidRootPart") local hum=clone:FindFirstChildOfClass("Humanoid")
   if root then root.Anchored=true end
   if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
   local lowest,highest=math.huge,-math.huge
   for _,part in ipairs(clone:GetChildren()) do
    if part:IsA("BasePart") then lowest=math.min(lowest,part.Position.Y-part.Size.Y/2) highest=math.max(highest,part.Position.Y+part.Size.Y/2) end
   end
   bodyHeight=math.clamp(highest-lowest,3,16)
   camera.CFrame=CFrame.lookAt(Vector3.new(0,.5,bodyHeight*1.5),Vector3.new(0,.5,0))
   local animate=char:FindFirstChild("Animate")
   local swim=animate and (animate:FindFirstChild("swim") or animate:FindFirstChild("swimidle"))
   local animation=swim and swim:FindFirstChildWhichIsA("Animation",true)
   if hum and not animation and hum.RigType==Enum.HumanoidRigType.R15 then
    animation=Instance.new("Animation") animation.AnimationId="rbxassetid://507784897" animation.Parent=clone
   end
   if hum and animation then
    local animator=hum:FindFirstChildOfClass("Animator") or Instance.new("Animator",hum)
    local ok,t=pcall(function() return animator:LoadAnimation(animation) end)
    if ok then track=t track.Looped=true track.Priority=Enum.AnimationPriority.Action track:Play(.25,1,.55) end
   end
   local joints={}
   for _,d in ipairs(clone:GetDescendants()) do if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then joints[d]=d.Transform end end
   local t=0
   poseStep=function(dt)
    t+=dt if root then root.CFrame=CFrame.new(0,math.sin(t*1.4)*.18,0)*CFrame.Angles(math.rad(-7),0,0) end
    if not track or not track.IsPlaying or track.Length==0 then
     for motor,base in pairs(joints) do
      local name=motor.Name:lower()
      if name:find("shoulder") then
       local side=name:find("left") and -1 or 1
       motor.Transform=base*CFrame.Angles(math.sin(t*1.8)*.2,0,side*(.55+math.cos(t*1.8)*.12))
      elseif name:find("hip") then motor.Transform=base*CFrame.Angles(math.sin(t*1.8)*.12,0,0) end
     end
    end
   end
  end
 end
 local elapsed=0
 connection=RunService.RenderStepped:Connect(function(dt)
  if token~=generation then return end
  poseStep(dt) elapsed+=dt
  if atmosphere.Visible then
   local alpha=fade.Value
   for _,circle in ipairs(glow) do circle.BackgroundTransparency=1-.013*alpha end
   beam.BackgroundTransparency=1-.03*alpha
   for i,bubble in ipairs(bubbles) do
    local y=1.05-((bubble.phase+elapsed*bubble.speed)%1.15)
    bubble.frame.Position=UDim2.fromScale(bubble.x+math.sin(elapsed*.3+i)*.012,y)
    bubble.stroke.Transparency=1-.10*alpha*math.clamp(math.min(y,1-y)*5,0,1)
   end
  end
 end)
 local back=Instance.new("TextButton") back.Name="Regenerate" back.Text="Regenerar"
 back.AnchorPoint=Vector2.new(.5,.5) back.Position=UDim2.fromScale(.5,.84) back.Size=UDim2.fromOffset(184,48)
 back.BackgroundColor3=Color3.fromRGB(31,34,39) back.BackgroundTransparency=1 back.TextTransparency=1
 back.TextColor3=Color3.fromRGB(222,229,233) back.Font=Enum.Font.GothamMedium back.TextSize=18
 back.Visible=false back.Active=false back.ZIndex=8 back.Parent=background
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,14) corner.Parent=back
 local border=Instance.new("UIStroke") border.Color=Color3.fromRGB(111,133,145) border.Transparency=1 border.Parent=back
 local click=media.MenuClick:Clone() click.Parent=back
 local requested=false
 back.Activated:Connect(function()
  if requested or not back.Active or token~=generation then return end requested=true
  if player:GetAttribute("MenuSounds")~=false then click:Play() end
  back.Text="Regenerando…"
  local respawnSound=media.Regenerate:Clone() respawnSound.Name="RegenerationCue"
  respawnSound.Parent=game:GetService("SoundService") respawnSound:Play()
  game:GetService("Debris"):AddItem(respawnSound,20)
  event:FireServer("return")
  task.delay(3,function() if token==generation then requested=false back.Text="Regenerar" end end)
 end)
 local function show(text,last)
  if token~=generation then return false end
  label.Text=text label.TextTransparency=1 label.MaxVisibleGraphemes=0
  tween(label,.25,{TextTransparency=0})
  for i=1,utf8.len(text) or #text do
   if token~=generation then return false end label.MaxVisibleGraphemes=i task.wait(.045)
  end
  task.wait(1.5)
  if token~=generation then return false end
  if not last then tween(label,.3,{TextTransparency=1}) task.wait(.35) end
  return token==generation
 end
 task.spawn(function()
  task.wait(.7)
  local messages={"Cuidado"}
  for i,text in ipairs(messages) do if not show(text,true) then return end end
  gui:SetAttribute("Phase","transition")
  tween(label,1.4,{TextTransparency=1,Position=UDim2.fromScale(.5,.42)})
  tween(fade,1.6,{Value=0})
  tween(view,1.6,{Position=UDim2.fromScale(.18,.16),Size=UDim2.fromScale(.64,.58)})
  tween(camera,1.6,{CFrame=CFrame.lookAt(Vector3.new(0,.5,bodyHeight*1.8),Vector3.new(0,.5,0))})
  task.wait(1.65)
  if token~=generation then return end
  atmosphere.Visible=false label.Visible=false
  if mode=="spectate" then gui:SetAttribute("Phase","spectate") event:FireServer("return") return end
  gui:SetAttribute("Phase","regenerate")
  back.Text="Voltar" back.Visible=true back.Active=true
  tween(back,.35,{BackgroundTransparency=.28,TextTransparency=0}) tween(border,.35,{Transparency=.7})
  task.wait(2.5)
  if token==generation and not requested then requested=true event:FireServer("return") end
 end)
 task.delay(4.5,function() if token==generation then clean() end end)
 if controls then controls:Disable() end
end
local finishing=false
event.OnClientEvent:Connect(function(action,cause,mode)
 if action=="start" then finishing=false start(cause,mode)
 elseif action=="finish" and not finishing then
  finishing=true local token=generation
  if gui then
   for _,d in ipairs(gui:GetDescendants()) do
    if d:IsA("GuiObject") then tween(d,.4,{BackgroundTransparency=1}) end
    if d:IsA("TextLabel") or d:IsA("TextButton") then tween(d,.4,{TextTransparency=1})
    elseif d:IsA("ViewportFrame") then tween(d,.4,{ImageTransparency=1})
    elseif d:IsA("UIStroke") then tween(d,.4,{Transparency=1}) end
   end
  end
  if music then tween(music,.4,{Volume=0}) end
  task.delay(.45,function() if token==generation then clean() end finishing=false end)
 end
end)
player.CharacterAdded:Connect(function() clean() finishing=false end)
player:GetAttributeChangedSignal("Spectating"):Connect(function()
 if player:GetAttribute("Spectating") then clean() finishing=false end
end)
player:GetAttributeChangedSignal("InRound"):Connect(function()
 if player:GetAttribute("InRound")~=true then clean() finishing=false end
end)
task.spawn(function()
 local ps=player:WaitForChild("PlayerScripts",10) local pm=ps and ps:WaitForChild("PlayerModule",10)
 if pm then local ok,m=pcall(require,pm) if ok then controls=m:GetControls() if player:GetAttribute("VoidActive") then controls:Disable() end end end
end)


player:GetAttributeChangedSignal("MusicEnabled"):Connect(function()
 if music then if player:GetAttribute("MusicEnabled")==false then music:Pause() else music:Resume() end end
end)
