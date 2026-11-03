local Players=game:GetService("Players")local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local UIS=game:GetService("UserInputService")local player=Players.LocalPlayer
local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")local remote=runtime:WaitForChild("OwnerDialogue")
local Pose=require(runtime:WaitForChild("NPCPose"))
local npc,neck,shoulder,bubble,bubbleText=nil,nil,nil,nil,nil
local bubbleUntil=0 local panelOpen=false
local gui=Instance.new("ScreenGui")gui.Name="ForestConversation"gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")panel.Name="Dialogue"panel.AnchorPoint=Vector2.new(.5,1)
panel.Position=UDim2.fromScale(.5,.76)panel.Size=UDim2.new(.88,0,0,215)panel.BackgroundColor3=Color3.fromRGB(22,35,32)panel.BackgroundTransparency=.08 panel.Visible=false panel.Parent=gui
local limit=Instance.new("UISizeConstraint")limit.MaxSize=Vector2.new(440,215)limit.Parent=panel
local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,16)corner.Parent=panel
local stroke=Instance.new("UIStroke")stroke.Color=Color3.fromRGB(130,162,127)stroke.Transparency=.50 stroke.Parent=panel
local title=Instance.new("TextLabel")title.BackgroundTransparency=1 title.Position=UDim2.new(0,18,0,12)title.Size=UDim2.new(1,-65,0,22)title.Font=Enum.Font.GothamBold title.TextSize=17 title.TextColor3=Color3.fromRGB(226,235,218)title.TextXAlignment=Enum.TextXAlignment.Left title.Text="ch_ckz2n"title.Parent=panel
local close=Instance.new("TextButton")close.Name="Close"close.BackgroundTransparency=1 close.Position=UDim2.new(1,-46,0,5)close.Size=UDim2.fromOffset(40,40)close.Text="×"close.TextSize=28 close.Font=Enum.Font.Gotham close.TextColor3=Color3.fromRGB(225,235,224)close.Parent=panel
local message=Instance.new("TextLabel")message.BackgroundTransparency=1 message.Position=UDim2.new(0,18,0,43)message.Size=UDim2.new(1,-36,0,58)message.Font=Enum.Font.Gotham message.TextSize=15 message.TextColor3=Color3.fromRGB(215,228,214)message.TextWrapped=true message.TextXAlignment=Enum.TextXAlignment.Left message.TextYAlignment=Enum.TextYAlignment.Top message.Parent=panel
message.TextScaled=true local textLimit=Instance.new("UITextSizeConstraint")textLimit.MinTextSize=12 textLimit.MaxTextSize=15 textLimit.Parent=message
local options=Instance.new("ScrollingFrame")options.Name="Replies"options.BackgroundTransparency=1 options.BorderSizePixel=0 options.Position=UDim2.new(0,14,0,108)options.Size=UDim2.new(1,-28,0,94)options.CanvasSize=UDim2.new()options.AutomaticCanvasSize=Enum.AutomaticSize.Y options.ScrollBarThickness=3 options.ScrollBarImageColor3=Color3.fromRGB(151,178,144)options.Parent=panel
local layout=Instance.new("UIListLayout")layout.Padding=UDim.new(0,7)layout.Parent=options
local function hide()panelOpen=false panel.Visible=false end
close.Activated:Connect(hide)
for i,item in ipairs({{"hello","Olá! 😄"},{"forest","O que tem na floresta?"},{"bye","Até mais!"}})do
 local button=Instance.new("TextButton")button.Name=item[1]button.Size=UDim2.new(1,-5,0,38)button.LayoutOrder=i button.BackgroundColor3=Color3.fromRGB(46,66,49)button.AutoButtonColor=true button.Text=item[2]button.TextSize=14 button.Font=Enum.Font.GothamMedium button.TextColor3=Color3.fromRGB(226,239,218)button.Parent=options
 local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,9)c.Parent=button
 button.Activated:Connect(function()if panelOpen then remote:FireServer(item[1])if item[1]=="bye"then hide()end end end)
end
local function detach()
 if bubble then bubble:Destroy()end npc=nil neck=nil shoulder=nil bubble=nil bubbleText=nil hide()
end
local function attach(model)
 if npc==model then return end detach()
 local torso=model:FindFirstChild("Torso")local head=model:FindFirstChild("Head")if not torso or not head then return end
 npc=model neck=torso:FindFirstChild("Neck")shoulder=torso:FindFirstChild("Right Shoulder")
 Pose.seat(model)
 bubble=Instance.new("BillboardGui")bubble.Name="OwnerGreeting"bubble.Adornee=head bubble.Size=UDim2.fromOffset(180,48)bubble.StudsOffsetWorldSpace=Vector3.new(0,2.2,0)bubble.MaxDistance=28 bubble.AlwaysOnTop=false bubble.Enabled=false bubble.Parent=gui
 local bg=Instance.new("Frame")bg.Size=UDim2.fromScale(1,1)bg.BackgroundColor3=Color3.fromRGB(25,40,34)bg.BackgroundTransparency=.08 bg.Parent=bubble
 local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,13)c.Parent=bg
 bubbleText=Instance.new("TextLabel")bubbleText.BackgroundTransparency=1 bubbleText.Size=UDim2.new(1,-12,1,-6)bubbleText.Position=UDim2.fromOffset(6,3)bubbleText.Font=Enum.Font.GothamMedium bubbleText.TextSize=21 bubbleText.TextColor3=Color3.fromRGB(235,244,227)bubbleText.TextWrapped=true bubbleText.Parent=bg
end
for _,model in ipairs(Collection:GetTagged("ForestOwnerNPC"))do attach(model)end
local addConnection=Collection:GetInstanceAddedSignal("ForestOwnerNPC"):Connect(attach)
local removeConnection=Collection:GetInstanceRemovedSignal("ForestOwnerNPC"):Connect(function(model)if npc==model then detach()end end)
local remoteConnection=remote.OnClientEvent:Connect(function(kind,text)
 if type(kind)~="string"or type(text)~="string"then return end
 if kind=="close"then hide()elseif kind=="dialogue"then
  message.Text=text panelOpen=true panel.Visible=true options.CanvasPosition=Vector2.zero
 elseif kind=="reply"then message.Text=text end
 if bubbleText then bubbleText.Text=text bubbleUntil=os.clock()+(kind=="reply"and 5 or 3.8)bubble.Enabled=true end
end)
local connection=Run.RenderStepped:Connect(function(dt)
 if not npc or not npc.Parent then return end
 local torso=npc:FindFirstChild("Torso")if not torso then return end
 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
 local distance=root and(root.Position-torso.Position).Magnitude or math.huge
 if panelOpen and distance>19 then hide()end
 if bubble then bubble.Enabled=os.clock()<bubbleUntil and distance<28 end
 if distance>65 then return end
 local alpha=1-math.exp(-7*dt)
 if neck then
  local base=neck:GetAttribute("SeatedC0")or neck:GetAttribute("OriginalC0")or neck.C0
  local target=npc:GetAttribute("LookTarget")local goal=base
  if target then goal=Pose.look(base,torso.CFrame:PointToObjectSpace(target)-Vector3.new(0,1.5,0))end
  neck.C0=neck.C0:Lerp(goal,alpha)
 end
 if shoulder then
  local original=shoulder:GetAttribute("OriginalC0")or shoulder.C0
  local resting=shoulder:GetAttribute("SeatedC0")or original
  local start=npc:GetAttribute("WaveStarted")local age=start and workspace:GetServerTimeNow()-start or 4
  local goal=age>=0 and age<=3 and Pose.wave(original,age)or resting
  shoulder.C0=shoulder.C0:Lerp(goal,alpha)
 end
end)
local inputConnection=UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape then hide()end end)
script.Destroying:Connect(function()connection:Disconnect()remoteConnection:Disconnect()inputConnection:Disconnect()addConnection:Disconnect()removeConnection:Disconnect()detach()gui:Destroy()end)
