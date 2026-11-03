local Players=game:GetService("Players")local C=game:GetService("CollectionService")local Run=game:GetService("RunService")
local player=Players.LocalPlayer local effects={}
local old=player:WaitForChild("PlayerGui"):FindFirstChild("RuinTeaNotice")if old then old:Destroy()end
local function bind(v)if v:IsA("Beam")or v:IsA("ParticleEmitter")or v:IsA("Fire")then effects[v]=true end end
for _,v in ipairs(C:GetTagged("RuinVFX"))do bind(v)end
C:GetInstanceAddedSignal("RuinVFX"):Connect(bind)C:GetInstanceRemovedSignal("RuinVFX"):Connect(function(v)effects[v]=nil end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)elapsed+=dt if elapsed<.6 then return end elapsed=0
 local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")if not root then return end
 for v in pairs(effects)do if v.Parent then local parent=v.Parent local point=parent:IsA("Attachment")and parent.WorldPosition or parent:IsA("BasePart")and parent.Position
  if point then v.Enabled=(point-root.Position).Magnitude<55 end else effects[v]=nil end end
end)
