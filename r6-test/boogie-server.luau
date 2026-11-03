-- Lightweight server-authoritative Boogie Woogie positional exchange.
-- Adapted from the user's BoogieWoogieV1(5).rbxl. The original Server
-- accepted arbitrary remote parts with no distance/cooldown; this validates
-- targets server-side to avoid teleport exploits or accidental map damage.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local remote=RS:WaitForChild("BoogieSwap")
local clapAnimation=RS:FindFirstChild("ClapAnimation")
local clapVFX=RS:FindFirstChild("ClapVFX")
local clapSound=RS:FindFirstChild("SwapSound")
local nextUse={}
local MAX_DISTANCE=65
local COOLDOWN=1.6
local function controlledTarget(player,target)
 if typeof(target)~="Instance" or not target:IsA("Model") then return nil end
 if not target:IsDescendantOf(workspace) then return nil end
 if target==player.Character then return nil end
 local isDummy=target==workspace:FindFirstChild("BoogieTestDummy")
  or (target.Parent==workspace:FindFirstChild("NPCWanderers")
   and target:GetAttribute("NPCWanderer")==true)
 local other=Players:GetPlayerFromCharacter(target)
 if not isDummy and (not other or other==player) then return nil end
 local targetHumanoid=target:FindFirstChildOfClass("Humanoid")
 local targetRoot=target:FindFirstChild("HumanoidRootPart")
 if not targetRoot or not targetHumanoid or targetHumanoid.Health<=0 then return nil end
 return targetRoot
end
local function playClap(character)
 if not clapAnimation or not clapAnimation:IsA("Animation") then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
 if not animator then return end
 local ok,track=pcall(function()return animator:LoadAnimation(clapAnimation)end)
 if ok and track then
  track.Priority=Enum.AnimationPriority.Action
  track.Looped=false
  track:Play(0.08,1,1.5)
  task.delay(0.45,function()
   if track then track:Stop(0.1);track:Destroy() end
  end)
 end
end
local function smallVFX(at)
 if not clapVFX or not clapVFX:IsA("BasePart") then return end
 local part=clapVFX:Clone()
 part.Anchored=true
 part.CanCollide=false
 part.CanTouch=false
 part.CanQuery=false
 part.CFrame=CFrame.new(at)
 part.Parent=workspace
 for _,emitter in ipairs(part:GetDescendants()) do
  if emitter:IsA("ParticleEmitter") then
   emitter.Enabled=false
   emitter:Emit(math.min(5,emitter:GetAttribute("EmitCount") or 3))
  end
 end
 Debris:AddItem(part,1.2)
end
local function sound(at)
 if not clapSound or not clapSound:IsA("Sound") then return end
 local part=Instance.new("Part")
 part.Name="BoogieSwapSound"
 part.Transparency=1
 part.Anchored=true
 part.CanCollide=false
 part.CanTouch=false
 part.CanQuery=false
 part.Size=Vector3.one*0.2
 part.Position=at
 part.Parent=workspace
 local sample=clapSound:Clone()
 sample.Parent=part
 sample:Play()
 Debris:AddItem(part,2)
end
remote.OnServerEvent:Connect(function(player,target)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local selfRoot=character and character:FindFirstChild("HumanoidRootPart")
 if not humanoid or humanoid.Health<=0 or not selfRoot then return end
 local targetRoot=controlledTarget(player,target)
 if not targetRoot then return end
 local distance=(selfRoot.Position-targetRoot.Position).Magnitude
 if distance>MAX_DISTANCE or distance<1 or selfRoot.Position.Y< -40 or targetRoot.Position.Y< -40 then return end
 local now=os.clock()
 if nextUse[player] and now<nextUse[player] then
  remote:FireClient(player,"cooldown")
  return
 end
 nextUse[player]=now+COOLDOWN
 local a=character:GetPivot()
 local b=target:GetPivot()
 -- The user's avatar and target change PLACES, not physical avatar identities.
 -- Both characters retain their existing R6 controllers and clothing.
 selfRoot.AssemblyLinearVelocity=Vector3.zero
 selfRoot.AssemblyAngularVelocity=Vector3.zero
 targetRoot.AssemblyLinearVelocity=Vector3.zero
 targetRoot.AssemblyAngularVelocity=Vector3.zero
 character:PivotTo(b)
 target:PivotTo(a)
 playClap(character)
 smallVFX(a.Position)
 smallVFX(b.Position)
 sound(a.Position)
 remote:FireClient(player,"ok")
end)
Players.PlayerRemoving:Connect(function(player)nextUse[player]=nil end)
