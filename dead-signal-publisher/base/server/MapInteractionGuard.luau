local Guard={}
function Guard.CanUse(player,prompt,clock,cooldowns,world)
 if not prompt or not prompt.Enabled or not prompt.Parent or not prompt.Parent:IsA("BasePart") then return false,"prompt" end
 local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 then return false,"character" end
 local target=prompt.Parent;local head=char:FindFirstChild("Head") or root
 if (root.Position-target.Position).Magnitude>math.min(prompt.MaxActivationDistance+1.5,10) then return false,"distance" end
 -- Exclude only the character and control's own housing. Walls and closed doors still block remote use.
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char,target};params.RespectCanCollide=true
 local delta=target.Position-head.Position
 if delta.Magnitude>0.01 and world:Raycast(head.Position,delta,params) then return false,"occluded" end
 local key=tostring(player.UserId)..":"..target:GetFullName()
 if clock-(cooldowns[key] or -math.huge)<0.45 then return false,"cooldown" end
 cooldowns[key]=clock;return true
end
return Guard
