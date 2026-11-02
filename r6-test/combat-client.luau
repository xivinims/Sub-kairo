-- R6 combat animations, taken from the user's thirteen individual IDs.
-- AnimationTrack only if its asset loaded in this universe (Length>0).
-- Otherwise a short harmless local R6 joint gesture makes the input usable.
-- No hitbox, damage, network calls, weapons or permanent per-frame animation.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local localPlayer=Players.LocalPlayer
local char=script.Parent
local humanoid=char:WaitForChild("Humanoid")
if humanoid.RigType~=Enum.HumanoidRigType.R6 then return end
local animator=humanoid:WaitForChild("Animator",10)
if not animator then warn("[R6Combat] No Animator");return end
local library=char:WaitForChild("CombatAnimations",10)
if not library then warn("[R6Combat] Missing animation set");return end
local playerGui=localPlayer:WaitForChild("PlayerGui")
local originals={}
local joints={}
for _,part in ipairs(char:GetDescendants()) do
 if part:IsA("Motor6D") then joints[part.Name]=part;originals[part]=part.C0 end
end
local dead=false
local last=0
local combo=0
local lastComboTime=0
local special=0
local blocking=false
local activeTrack=nil
local poseTweens={}
local comboNames={"M1_1","M1_2","M1_3","M1_4"}
local specialNames={"Uppercut","Downslam","HeavyPunch","Barrage"}
local attackCooldown={Punch=.36,Kick=.65,Dodge=.8,Special=1.3}
local function restricted()
 if dead or humanoid.Health<=0 then return true end
 if localPlayer.Character~=char then return true end
 if char:GetAttribute("Climbing")==true then return true end
 local menuOpen=localPlayer:GetAttribute("R6MenuActive")
 if menuOpen==true then return true end
 local state=humanoid:GetState()
 return humanoid.Sit or state==Enum.HumanoidStateType.Seated
  or state==Enum.HumanoidStateType.Dead
end
local function clearPose()
 for _,tw in ipairs(poseTweens) do tw:Cancel() end
 table.clear(poseTweens)
 for joint,c0 in pairs(originals) do
  if joint.Parent and joint.C0~=c0 then
   local tween=Tween:Create(joint,TweenInfo.new(.13,Enum.EasingStyle.Sine),
    {C0=c0})
   table.insert(poseTweens,tween)
   tween:Play()
  end
 end
end
local function stopTrack()
 if activeTrack then
  activeTrack:Stop(.08)
  activeTrack:Destroy()
  activeTrack=nil
 end
end
local function tweenJoint(name,rotation)
 local joint=joints[name]
 if not joint or not joint.Parent then return end
 local goal=originals[joint]*rotation
 local tw=Tween:Create(joint,TweenInfo.new(.13,Enum.EasingStyle.Sine,
  Enum.EasingDirection.Out),{C0=goal})
 table.insert(poseTweens,tw)
 tw:Play()
end
local function fallbackGesture(action)
 -- The R6 animation IDs in Creator Store may belong to another creator,
 -- or may be R15. Do not label this as an original imported animation.
 clearPose()
 local left=action=="M1_2" or action=="M1_4" or action=="Kick_2"
 if action=="Block" then
  tweenJoint("Left Shoulder",CFrame.Angles(-1.1,0,-.3))
  tweenJoint("Right Shoulder",CFrame.Angles(-1.1,0,.3))
 elseif action:find("Kick",1,true) then
  tweenJoint(left and "Left Hip" or "Right Hip",CFrame.Angles(-.7,0,0))
  tweenJoint("Right Shoulder",CFrame.Angles(-.3,0,.4))
 elseif action:find("Dodge",1,true) then
  tweenJoint("RootJoint",CFrame.Angles(.27,0,left and -.2 or .2))
 else
  tweenJoint(left and "Left Shoulder" or "Right Shoulder",
   CFrame.Angles(-1.2,0,left and -.2 or .2))
  tweenJoint("Left Hip",CFrame.Angles(.12,0,0))
 end
 if action~="Block" then
  task.delay(.25,function()if not dead and not blocking then clearPose()end end)
 end
end
local function play(action)
 stopTrack()
 clearPose()
 local asset=library:FindFirstChild(action)
 if asset and asset:IsA("Animation") and asset.AnimationId~="" then
  local ok,track=pcall(function()return animator:LoadAnimation(asset)end)
  if ok and track then
   if track.Length<=0 then
    -- Some Roblox assets report zero until the engine finishes fetching.
    -- The server previously checked which IDs actually load; do not wait
    -- here or spin in a heartbeat on every punch.
    track:Destroy()
   else
    activeTrack=track
    track.Priority=Enum.AnimationPriority.Action
    track.Looped=action=="Block"
    track:Play(.08,1,1)
    return true
   end
  end
 end
 fallbackGesture(action)
 return false
end
local function punch()
 if restricted() or blocking then return end
 local now=os.clock()
 if now-last<attackCooldown.Punch then return end
 if now-lastComboTime>1.25 then combo=0 end
 combo=combo%4+1
 lastComboTime=now
 last=now
 play(comboNames[combo])
end
local function kick()
 if restricted() or blocking then return end
 local now=os.clock()
 if now-last<attackCooldown.Kick then return end
 last=now
 combo=0
 local index=char:GetAttribute("CombatKickAlternator")==1 and 2 or 1
 char:SetAttribute("CombatKickAlternator",index)
 play(index==1 and "Kick_1" or "Kick_2")
end
local function dodge()
 if restricted() or blocking then return end
 local now=os.clock()
 if now-last<attackCooldown.Dodge then return end
 last=now
 combo=0
 local backward=humanoid.MoveDirection:Dot(char.HumanoidRootPart.CFrame.LookVector)<-.25
 play(backward and "DodgeBack" or "DodgeFront")
end
local function specialAction()
 if restricted() or blocking then return end
 local now=os.clock()
 if now-last<attackCooldown.Special then return end
 last=now
 combo=0
 special=special%#specialNames+1
 play(specialNames[special])
end
local function block(toggle)
 if restricted() and toggle then return end
 if toggle==blocking then return end
 blocking=toggle
 char:SetAttribute("CombatBlocking",blocking)
 if blocking then
  stopTrack()
  play("Block")
 else
  stopTrack()
  clearPose()
 end
end
-- PC controls: mouse = four-punch combo; F = guard; Q dodge,
-- E kick and R = uppercut/downslam/heavy/barrage in rotation.
UIS.InputBegan:Connect(function(input,processed)
 if processed or restricted() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 then punch()
 elseif input.KeyCode==Enum.KeyCode.F then block(true)
 elseif input.KeyCode==Enum.KeyCode.Q then dodge()
 elseif input.KeyCode==Enum.KeyCode.E then kick()
 elseif input.KeyCode==Enum.KeyCode.R then specialAction() end
end)
UIS.InputEnded:Connect(function(input)
 if input.KeyCode==Enum.KeyCode.F then block(false) end
end)

-- Small circular touch buttons in the middle-right screen, not in the
-- top menu and not at the same coordinates as CHAKRA / BOOGIE / CORRER.
local gui=Instance.new("ScreenGui")
gui.Name="R6CombatHUD"
gui.ResetOnSpawn=true
gui.IgnoreGuiInset=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=19
gui.Enabled=UIS.TouchEnabled
gui.Parent=playerGui
local holder=Instance.new("Frame")
holder.Name="CombatActions"
holder.AnchorPoint=Vector2.new(1,.5)
holder.Position=UDim2.new(1,-12,.46,0)
holder.Size=UDim2.fromOffset(116,177)
holder.BackgroundTransparency=1
holder.Parent=gui
local scale=Instance.new("UIScale")
scale.Parent=holder
local function resize()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
 if vp then scale.Scale=math.clamp(math.min(vp.X/440,vp.Y/660),.65,1) end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
local function circle(name,textValue,x,y,callback)
 local button=Instance.new("TextButton")
 button.Name=name
 button.Text=textValue
 button.Size=UDim2.fromOffset(52,52)
 button.Position=UDim2.fromOffset(x,y)
 button.Font=Enum.Font.GothamSemibold
 button.TextSize=12
 button.TextColor3=Color3.fromRGB(233,244,255)
 button.BackgroundColor3=Color3.fromRGB(12,35,57)
 button.BackgroundTransparency=.14
 button.BorderSizePixel=0
 button.AutoButtonColor=true
 button.Parent=holder
 local rounding=Instance.new("UICorner")
 rounding.CornerRadius=UDim.new(1,0)
 rounding.Parent=button
 local border=Instance.new("UIStroke")
 border.Thickness=1.4
 border.Color=Color3.fromRGB(110,177,219)
 border.Transparency=.2
 border.Parent=button
 button.Activated:Connect(callback)
 return button
end
circle("Punch","SOCO",57,0,punch)
circle("Guard","DEF",0,0,function()block(not blocking)end)
circle("Dodge","ESQ",0,59,dodge)
circle("Kick","CHUTE",57,59,kick)
circle("Special","ESP.",57,118,specialAction)
local function cleanup()
 dead=true
 block(false)
 stopTrack()
 clearPose()
 if gui.Parent then gui:Destroy() end
end
humanoid.Died:Once(cleanup)
script.Destroying:Once(cleanup)
