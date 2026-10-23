local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local event=RS:WaitForChild("SweanVoidEvent")
local generation=0
local gui,connection,track=nil,nil,nil
local controls=nil
local function clean()
 generation+=1
 if connection then connection:Disconnect() connection=nil end
 if track then track:Stop() track=nil end
 if gui then gui:Destroy() gui=nil end
 if controls and not player:GetAttribute("InMenu") then controls:Enable() end
end
local function start()
 clean() local token=generation
 gui=Instance.new("ScreenGui") gui.Name="BeyondTheIsland" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=2000 gui.Parent=player:WaitForChild("PlayerGui")
 local background=Instance.new("Frame") background.Size=UDim2.fromScale(1,1) background.BackgroundColor3=Color3.fromRGB(3,4,8) background.BackgroundTransparency=1 background.Parent=gui
 TweenService:Create(background,TweenInfo.new(.45),{BackgroundTransparency=0}):Play()
 local view=Instance.new("ViewportFrame") view.BackgroundTransparency=1 view.Size=UDim2.fromScale(1,.76) view.Position=UDim2.fromScale(0,.04)
 view.Ambient=Color3.fromRGB(70,80,100) view.LightColor=Color3.fromRGB(145,174,210) view.LightDirection=Vector3.new(-1,-1,-1) view.Parent=background
 local world=Instance.new("WorldModel") world.Parent=view
 local camera=Instance.new("Camera") camera.FieldOfView=42 camera.Parent=view view.CurrentCamera=camera
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
   local _,size=clone:GetBoundingBox()
   camera.CFrame=CFrame.lookAt(Vector3.new(0,1,-math.max(10,size.Y*1.8)),Vector3.new(0,.3,0))
   local animate=char:FindFirstChild("Animate")
   local swim=animate and (animate:FindFirstChild("swimidle") or animate:FindFirstChild("swim"))
   local animation=swim and swim:FindFirstChildWhichIsA("Animation",true)
   if hum and animation then
    local animator=hum:FindFirstChildOfClass("Animator") or Instance.new("Animator",hum)
    local ok,t=pcall(function() return animator:LoadAnimation(animation) end)
    if ok then track=t track.Looped=true track:Play(.2) end
   end
   local joints={}
   for _,d in ipairs(clone:GetDescendants()) do if d:IsA("Motor6D") then joints[d]=d.Transform end end
   local t=0
   connection=RunService.RenderStepped:Connect(function(dt)
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
   end)
  end
 end
 local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.TextColor3=Color3.fromRGB(196,215,233)
 label.Font=Enum.Font.GothamMedium label.TextSize=22 label.TextWrapped=true label.Size=UDim2.fromScale(.86,.18) label.Position=UDim2.fromScale(.07,.77) label.Text="" label.Parent=background
 local function show(text)
  local length=utf8.len(text) or #text
  label.Text=text label.MaxVisibleGraphemes=0
  for i=1,length do if token~=generation then return false end label.MaxVisibleGraphemes=i task.wait(.035) end
  task.wait(.85) return token==generation
 end
 task.delay(10,function() if token==generation then clean() end end)
 task.spawn(function()
  task.wait(.65)
  if token~=generation then return end
  if not show("Você caiu além dos limites da ilha.") then return end
  if not show("Nem todo caminho continua depois da borda.") then return end
  show("Respire. A ilha está trazendo você de volta.")
 end)
 if controls then controls:Disable() end
end
event.OnClientEvent:Connect(function(action)
 if action=="start" then start()
 elseif action=="finish" then
  local token=generation
  if gui then
   local frame=gui:FindFirstChildWhichIsA("Frame")
   if frame then TweenService:Create(frame,TweenInfo.new(.35),{BackgroundTransparency=1}):Play() end
  end
  task.delay(.35,function() if token==generation then clean() end end)
 end
end)
player.CharacterAdded:Connect(clean)
task.spawn(function()
 local ps=player:WaitForChild("PlayerScripts",10) local pm=ps and ps:WaitForChild("PlayerModule",10)
 if pm then local ok,m=pcall(require,pm) if ok then controls=m:GetControls() end end
end)
