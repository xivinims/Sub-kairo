local function sequences(asset,sourceId,names,folder)
 for dest,sourceName in pairs(names) do
  local found=nil
  for _,d in ipairs(asset:GetDescendants()) do if d:IsA("KeyframeSequence") and d.Name==sourceName then found=d break end end
  assert(found,"Missing sequence "..sourceName)
  local seq=found:Clone() seq.Name=dest seq:SetAttribute("SourceAssetId",sourceId) seq.Parent=folder
 end
end
local function rig(id,name)
 local a=load(id) sanitize(a,false)
 local model
 if name=="Amanda" then model=a:FindFirstChild("AmandaRIG",true)
 else local h=a:FindFirstChildWhichIsA("Humanoid",true) model=h and h.Parent end
 assert(model,"No rig for "..name) model.Parent=nil a:Destroy() model.Name=name
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d:Destroy() end
 end
 local root=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart")
 assert(root and root:IsA("BasePart"),"No root for "..name)
 root.Name="HumanoidRootPart" model.PrimaryPart=root
 local hum=model:FindFirstChildOfClass("Humanoid")
 if not hum then
  local ac=model:FindFirstChildOfClass("AnimationController") if ac then ac:Destroy() end
  hum=Instance.new("Humanoid",model) hum.RequiresNeck=false hum.HipHeight=3
 end
 hum.RequiresNeck=false
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.BreakJointsOnDeath=false hum.MaxHealth=100000 hum.Health=100000
 local _,sz=model:GetBoundingBox()
 if name=="Freddy" or name=="Figure" then model:ScaleTo(model:GetScale()*math.min(1,7/sz.Y)) end
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA("BasePart") then d.CanCollide=false d.CanTouch=false d.Massless=true end
 end
 root.CanCollide=true root.Massless=false root.Transparency=1 root.Size=Vector3.new(2,2,1.5)
 hum.HipHeight=2.4
 local f=Instance.new("Folder",model) f.Name="MotionClips"
 if name=="Freddy" then
  local anim=load(140005809574272)
  sequences(anim,140005809574272,{Idle="Idle",Walk="Walk",Run="Run",Attack="Punch"},f)
  local sourceRig=anim:FindFirstChild("c00lkidd",true)
  assert(sourceRig,"Animation source rig missing")
  for _,j in ipairs(sourceRig:GetDescendants()) do if j:IsA("Motor6D") and j.Part1 then f:SetAttribute("Bind_"..j.Part1.Name:gsub(" ","_"),j.C0) end end
  anim:Destroy()
 elseif name=="Amanda" then
  local save=model:FindFirstChild("AnimSaves")
  if save then sequences(save,id,{Attack="AtticJumpscare",Walk="Automatic Save"},f) end
 elseif name=="Figure" then
  local saves=model:FindFirstChild("AnimSaves")
  if saves then for _,d in ipairs(saves:GetChildren()) do if d:IsA("KeyframeSequence") then local copy=d:Clone() copy.Parent=f end end end
 end
 local old=model:FindFirstChild("AnimSaves") if old then old:Destroy() end
 model:SetAttribute("SourceAssetId",id) model.Parent=rigs
 return model
end
local figure=rig(119558547298374,"Figure")
local scarlet=rig(12796108766,"Scarlat")
local freddy=rig(14897466681,"Freddy")
-- Rig topology verified from the original asset: pelvis, neck, upper limbs.
local aliases={
 ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.024"]="Torso",
 ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.036"]="Head",
 ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.022"]="Left Arm",
 ["fsfsdfsdfsdf"]="Right Arm",
 ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.026"]="Left Leg",
 ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.025"]="Right Leg",
}
for _,j in ipairs(freddy:GetDescendants()) do
 if j:IsA("Motor6D") and j.Part0 and j.Part1 and aliases[j.Part1.Name] then
  local alias=aliases[j.Part1.Name] j:SetAttribute("PoseAlias",alias)
  local rootToParent=j.Part0.CFrame.Rotation:Inverse()*freddy.PrimaryPart.CFrame.Rotation
  if alias=="Left Arm" or alias=="Right Arm" then
   local angle=alias=="Left Arm" and math.pi/2 or -math.pi/2
   j.C0=CFrame.new(j.C0.Position)*rootToParent*CFrame.Angles(0,0,angle)*rootToParent:Inverse()*j.C0.Rotation
  end
  local source=freddy.MotionClips:GetAttribute("Bind_"..alias:gsub(" ","_"))
  assert(source,"Missing animation binding: "..alias)
  j:SetAttribute("RetargetBasis",j.C0.Rotation:Inverse()*rootToParent*source.Rotation)
 end
end
local amanda=rig(9526505226,"Amanda")
local particles=load(72797028676916) sanitize(particles,false)
local effects=Instance.new("Folder",scarlet) effects.Name="SpellParticles"
local count=0
for _,d in ipairs(particles:GetDescendants()) do
 if d:IsA("ParticleEmitter") and count<4 and d.Texture~="" then
  local c=d:Clone() c.Rate=math.min(c.Rate,12) c.Lifetime=NumberRange.new(.2,.6) c.Enabled=false c.Parent=effects count+=1
 end
end
assert(count>0,"Scarlet particles missing") particles:Destroy()
-- Build the Warrior from the exact avatar item IDs supplied by the owner.
local warriorItems={109013223175977,131536373946103,108562010348687,78897239250220,10982591410,10982519012,206119001888066}
local description=Instance.new("HumanoidDescription")
local warrior=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
description:Destroy()
warrior.Name="Guerreiro"
local warriorHum=warrior:FindFirstChildOfClass("Humanoid")
local warriorRoot=warrior:FindFirstChild("HumanoidRootPart")
assert(warriorHum and warriorRoot,"Warrior base rig missing")
warrior.PrimaryPart=warriorRoot
warriorHum.RequiresNeck=false
warriorHum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
warriorHum.BreakJointsOnDeath=false
warriorHum.MaxHealth=100000 warriorHum.Health=100000 warriorHum.HipHeight=2.4

local function equipWarriorItem(id)
 local asset=load(id) sanitize(asset,false)
 local applied=0
 local head=warrior:FindFirstChild("Head")
 for _,d in ipairs(asset:GetDescendants()) do
  if d:IsA("Accessory") then
   warriorHum:AddAccessory(d:Clone()) applied+=1
  elseif d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors") or d:IsA("CharacterMesh") then
   local old=warrior:FindFirstChildOfClass(d.ClassName) if old then old:Destroy() end
   d:Clone().Parent=warrior applied+=1
  elseif d:IsA("Decal") and head and (d.Name:lower()=="face" or id==206119001888066) then
   local old=head:FindFirstChild("face") if old then old:Destroy() end
   local face=d:Clone() face.Name="face" face.Parent=head applied+=1
  end
 end
 asset:Destroy()
 assert(applied>0,"Warrior avatar item did not contain wearable data: "..id)
end
for _,id in ipairs(warriorItems) do equipWarriorItem(id) end

for _,d in ipairs(warrior:GetDescendants()) do
 if d:IsA("BasePart") then d.CanCollide=false d.CanTouch=false d.Massless=true end
end
warriorRoot.CanCollide=true warriorRoot.Massless=false warriorRoot.Transparency=1 warriorRoot.Size=Vector3.new(2,2,1.5)

local warriorClips=Instance.new("Folder",warrior) warriorClips.Name="MotionClips"
local jason=load(125165599816440)
sequences(jason,125165599816440,{Idle="Jason Idle",Walk="Jason Walk",Run="Jason Run"},warriorClips)
jason:Destroy()

-- Retarget the main R15 joints to the supplied Jason person animation pose names.
local warriorAliases={
 UpperTorso="Torso",Head="Head",
 LeftUpperArm="Left Arm",RightUpperArm="Right Arm",
 LeftUpperLeg="Left Leg",RightUpperLeg="Right Leg",
}
for _,j in ipairs(warrior:GetDescendants()) do
 if j:IsA("Motor6D") and j.Part1 and warriorAliases[j.Part1.Name] then
  j:SetAttribute("PoseAlias",warriorAliases[j.Part1.Name])
 end
end
warrior:SetAttribute("AvatarItems","109013223175977,131536373946103,108562010348687,78897239250220,10982591410,10982519012,206119001888066")
warrior:SetAttribute("AnimationAssetId",125165599816440)
warrior.Parent=rigs
for _,m in ipairs(maps:GetChildren()) do m:SetAttribute("DisplayName",m.Name) end
