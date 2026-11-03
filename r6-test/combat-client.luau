-- R6 input and mobile GUI only; all actual moving poses come from
-- R6PoseController inside this very avatar. No competing Animator tracks.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local char=script.Parent
local hum=char:WaitForChild("Humanoid")
if hum.RigType~=Enum.HumanoidRigType.R6 then return end
local playerGui=player:WaitForChild("PlayerGui")
local combo=0
local special=0
local lastCombo=0
local previous={}
local blockActive=false
local dead=false
local comboMoves={"M1_1","M1_2","M1_3","M1_4"}
local specialMoves={"Uppercut","Downslam","HeavyPunch","Barrage"}
local function allowed()
 if dead or hum.Health<=0 or player.Character~=char then return false end
 if player:GetAttribute("R6MenuActive")==true or char:GetAttribute("Climbing")==true
  or char:GetAttribute("ChakraActive")==true or hum.Sit then return false end
 return true
end
local function act(name,category,interval)
 if not allowed() or blockActive then return end
 local now=os.clock()
 if previous[category] and now-previous[category]<interval then return end
 previous[category]=now
 char:SetAttribute("R6CombatAction",name)
 char:SetAttribute("R6CombatStarted",now)
end
local function punch()
 if not allowed() or blockActive then return end
 local now=os.clock()
 if now-lastCombo>1.4 then combo=0 end
 if previous.punch and now-previous.punch<.35 then return end
 combo=combo%4+1
 lastCombo=now
 act(comboMoves[combo],"punch",.35)
end
local function kick()
 local n=(char:GetAttribute("R6KickNext") or 0)%2+1
 char:SetAttribute("R6KickNext",n)
 act(n==1 and "Kick_1" or "Kick_2","kick",.66)
end
local function dodge()
 local root=char:FindFirstChild("HumanoidRootPart")
 local backwards=root and hum.MoveDirection:Dot(root.CFrame.LookVector)<-.25
 act(backwards and "DodgeBack" or "DodgeFront","dodge",.8)
end
local function specialAction()
 special=special%#specialMoves+1
 act(specialMoves[special],"special",1.1)
end
local function block(value)
 if value and not allowed() then return end
 if value==blockActive then return end
 blockActive=value
 char:SetAttribute("CombatBlocking",blockActive)
 if blockActive then
  char:SetAttribute("R6CombatAction","Block")
  char:SetAttribute("R6CombatStarted",os.clock())
 else
  char:SetAttribute("R6CombatAction","")
  char:SetAttribute("R6CombatStarted",0)
 end
end
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 then punch()
 elseif input.KeyCode==Enum.KeyCode.F then block(true)
 elseif input.KeyCode==Enum.KeyCode.Q then dodge()
 elseif input.KeyCode==Enum.KeyCode.E then kick()
 elseif input.KeyCode==Enum.KeyCode.R then specialAction() end
end)
UIS.InputEnded:Connect(function(input)
 if input.KeyCode==Enum.KeyCode.F then block(false) end
end)
-- Five small rounded buttons to complement existing native jump/camera UI.
local gui=Instance.new("ScreenGui")
gui.Name="R6CombatHUD"
gui.ResetOnSpawn=true
gui.IgnoreGuiInset=false
gui.DisplayOrder=17
gui.Enabled=UIS.TouchEnabled
gui.Parent=playerGui
local holder=Instance.new("Frame")
holder.AnchorPoint=Vector2.new(1,.5)
holder.Position=UDim2.new(1,-9,.45,0)
holder.Size=UDim2.fromOffset(113,174)
holder.BackgroundTransparency=1
holder.Parent=gui
local scale=Instance.new("UIScale")
scale.Parent=holder
local function resize()
 local camera=workspace.CurrentCamera
 if camera then
  local vp=camera.ViewportSize
  scale.Scale=math.clamp(math.min(vp.X/430,vp.Y/675),.62,1)
 end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
local function circle(name,caption,x,y,callback)
 local b=Instance.new("TextButton")
 b.Name=name
 b.Size=UDim2.fromOffset(52,52)
 b.Position=UDim2.fromOffset(x,y)
 b.Text=caption
 b.TextSize=12
 b.Font=Enum.Font.GothamSemibold
 b.TextColor3=Color3.fromRGB(235,243,255)
 b.BackgroundColor3=Color3.fromRGB(16,39,64)
 b.BackgroundTransparency=.12
 b.BorderSizePixel=0
 b.AutoButtonColor=true
 b.Parent=holder
 local corner=Instance.new("UICorner")
 corner.CornerRadius=UDim.new(1,0)
 corner.Parent=b
 local outline=Instance.new("UIStroke")
 outline.Thickness=1
 outline.Color=Color3.fromRGB(133,191,239)
 outline.Transparency=.12
 outline.Parent=b
 b.Activated:Connect(callback)
 return b
end
circle("Punch","SOCO",57,0,punch)
circle("Guard","DEF",0,0,function()block(not blockActive)end)
circle("Dodge","ESQ",0,59,dodge)
circle("Kick","CHUTE",57,59,kick)
circle("Special","ESP.",57,118,specialAction)
local function cleanup()
 dead=true
 blockActive=false
 char:SetAttribute("CombatBlocking",false)
 char:SetAttribute("R6CombatAction","")
 char:SetAttribute("R6CombatStarted",0)
 if gui.Parent then gui:Destroy() end
end
hum.Died:Once(cleanup)
script.Destroying:Once(cleanup)
