local Factory={}

function Factory.create(name,spec)
 local template=assert(game.ServerStorage.SurvivalAssets.Killers:FindFirstChild(name),"Unknown pursuer")
 local rig=template:Clone()
 rig.Name=name
 rig:SetAttribute("ActivePursuer",true)
 rig:SetAttribute("PursuerName",name)

 local humanoid=assert(rig:FindFirstChildOfClass("Humanoid"),name.." missing Humanoid")
 local root=rig:FindFirstChild("HumanoidRootPart") or rig.PrimaryPart
 assert(root and root:IsA("BasePart"),name.." missing HumanoidRootPart")
 rig.PrimaryPart=root

 humanoid.RequiresNeck=false
 humanoid.BreakJointsOnDeath=false
 humanoid.AutoRotate=true
 humanoid.PlatformStand=false
 humanoid.Sit=false
 humanoid.MaxHealth=1000
 humanoid.Health=humanoid.MaxHealth
 humanoid.WalkSpeed=spec and spec.speed or humanoid.WalkSpeed
 humanoid.JumpPower=50
 humanoid.JumpHeight=7.2

 for _,obj in ipairs(rig:GetDescendants()) do
  if obj:IsA("BasePart") then
   obj.Anchored=false
   obj.CanTouch=false
   obj.AssemblyLinearVelocity=Vector3.zero
   obj.AssemblyAngularVelocity=Vector3.zero
   if obj~=root and (obj:FindFirstAncestorOfClass("Accessory") or obj.Name=="Handle") then
    obj.CanCollide=false
    obj.Massless=true
   end
  elseif obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("BodyAngularVelocity") then
   obj:Destroy()
  elseif obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity") or obj:IsA("VectorForce") then
   obj.Enabled=false
  end
 end
 root.CanCollide=false
 root.Massless=false
 root.AssemblyLinearVelocity=Vector3.zero
 root.AssemblyAngularVelocity=Vector3.zero
 return rig
end

return Factory
