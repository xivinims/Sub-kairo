local Players=game:GetService("Players")local Collection=game:GetService("CollectionService")local Run=game:GetService("RunService")
local player=Players.LocalPlayer local runtime=game.ReplicatedStorage:WaitForChild("ForestRuntime")
local gui=Instance.new("ScreenGui")gui.Name="RuinTeaNotice"gui.ResetOnSpawn=false gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel")label.Name="Notice"label.AnchorPoint=Vector2.new(.5,0)label.Position=UDim2.new(.5,0,0,65)label.Size=UDim2.new(.88,0,0,48)label.BackgroundColor3=Color3.fromRGB(39,48,36)label.BackgroundTransparency=.10 label.TextColor3=Color3.fromRGB(240,231,211)label.TextSize=14 label.Font=Enum.Font.GothamMedium label.TextWrapped=true label.Visible=false label.Parent=gui
local limit=Instance.new("UISizeConstraint")limit.MaxSize=Vector2.new(430,80)limit.Parent=label
local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,12)corner.Parent=label
local untilTime=0
local remote=runtime:WaitForChild("RuinInteraction").OnClientEvent:Connect(function(text)if type(text)=="string"then label.Text=text label.Visible=true untilTime=os.clock()+4.5 end end)
local prompts={}
local function bind(prompt)
 if prompts[prompt]or not prompt:IsA("ProximityPrompt")then return end
 prompts[prompt]=prompt.Triggered:Connect(function(who)
  if who~=player then return end
  local current=player:GetAttribute("RuinLocalMood")or "Dourado"local nextMood=current=="Dourado"and "Neblina"or "Dourado"
  player:SetAttribute("RuinLocalMood",nextMood)label.Text=nextMood=="Neblina"and "Ruínas com neblina verde — somente para você."or "Luz dourada nas ruínas — somente para você."label.Visible=true untilTime=os.clock()+3.5
 end)
end
for _,prompt in ipairs(Collection:GetTagged("RuinMoodPrompt"))do bind(prompt)end
local added=Collection:GetInstanceAddedSignal("RuinMoodPrompt"):Connect(bind)
local removed=Collection:GetInstanceRemovedSignal("RuinMoodPrompt"):Connect(function(prompt)if prompts[prompt]then prompts[prompt]:Disconnect()prompts[prompt]=nil end end)
local effects={}
local function effect(instance)if instance:IsA("Beam")or instance:IsA("ParticleEmitter")or instance:IsA("Fire")then effects[instance]=true end end
for _,instance in ipairs(Collection:GetTagged("RuinVFX"))do effect(instance)end
local vfxAdd=Collection:GetInstanceAddedSignal("RuinVFX"):Connect(effect)
local vfxRemove=Collection:GetInstanceRemovedSignal("RuinVFX"):Connect(function(instance)effects[instance]=nil end)
local elapsed=0
local frame=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.4 then return end elapsed=0 if label.Visible and os.clock()>untilTime then label.Visible=false end
 local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")if not root then return end
 for instance in pairs(effects)do
  if instance.Parent and instance:IsDescendantOf(workspace)then
   local p=instance.Parent local point
   if p:IsA("Attachment")then point=p.WorldPosition elseif p:IsA("BasePart")then point=p.Position elseif instance:IsA("Beam")and instance.Attachment0 then point=instance.Attachment0.WorldPosition end
   if point then instance.Enabled=(point-root.Position).Magnitude<85 end
  end
 end
end)
script.Destroying:Connect(function()remote:Disconnect()frame:Disconnect()added:Disconnect()removed:Disconnect()vfxAdd:Disconnect()vfxRemove:Disconnect()for _,connection in pairs(prompts)do connection:Disconnect()end gui:Destroy()end)
