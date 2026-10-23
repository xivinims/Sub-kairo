local AssetService=game:GetService("AssetService")
local Players=game:GetService("Players")
local Factory={}

local function load(id)
 local last
 for attempt=1,3 do
  local ok,a=pcall(function() return AssetService:LoadAssetAsync(id) end)
  if ok and a then return a end
  last=a
  task.wait(1)
 end
 error("Asset "..tostring(id)..": "..tostring(last))
end

local function sanitize(root)
 for _,d in ipairs(root:GetDescendants()) do
  if d:IsA("LuaSourceContainer") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then
   d:Destroy()
  elseif d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
   d:Destroy()
  elseif d:IsA("BasePart") then
   d.Anchored=false d.CanCollide=false d.CanTouch=false d.Massless=true
  end
 end
end

local function sequences(asset,sourceId,names,folder)
 for dest,sourceName in pairs(names) do
  local found=nil
  for _,d in ipairs(asset:GetDescendants()) do
   if d:IsA("KeyframeSequence") and d.Name==sourceName then found=d break end
  end
  assert(found,"Missing sequence "..sourceName)
  local seq=found:Clone()
  seq.Name=dest
  seq:SetAttribute("SourceAssetId",sourceId)
  seq.Parent=folder
 end
end

local function basicRig(id,name)
 local asset=load(id)
 sanitize(asset)
 local model
 if name=="Amanda" then
  model=asset:FindFirstChild("AmandaRIG",true)
 else
  local hum=asset:FindFirstChildWhichIsA("Humanoid",true)
  model=hum and hum.Parent
 end
 assert(model,"No rig for "..name)
 model.Parent=nil
 asset:Destroy()
 model.Name=name
 local root=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart")
 assert(root and root:IsA("BasePart"),"No root for "..name)
 root.Name="HumanoidRootPart"
 model.PrimaryPart=root
 local hum=model:FindFirstChildOfClass("Humanoid")
 if not hum then
  local ac=model:FindFirstChildOfClass("AnimationController")
  if ac then ac:Destroy() end
  hum=Instance.new("Humanoid")
  hum.RequiresNeck=false
  hum.HipHeight=3
  hum.Parent=model
 end
 hum.RequiresNeck=false
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 hum.BreakJointsOnDeath=false
 hum.MaxHealth=100000
 hum.Health=100000
 local _,sz=model:GetBoundingBox()
 if name=="Freddy" or name=="Figure" then
  model:ScaleTo(model:GetScale()*math.min(1,7/sz.Y))
 end
 for _,d in ipairs(model:GetDescendants()) do
  if d:IsA("BasePart") then d.Anchored=false d.CanCollide=false d.CanTouch=false d.Massless=true end
 end
 root.CanCollide=true
 root.Massless=false
 root.Transparency=1
 root.Size=Vector3.new(2,2,1.5)
 hum.HipHeight=2.4
 local clips=Instance.new("Folder")
 clips.Name="MotionClips"
 clips.Parent=model
 model:SetAttribute("SourceAssetId",id)
 return model,clips
end

local function makeFigure(spec)
 local model,clips=basicRig(spec.id,"Figure")
 local source=load(spec.id)
 local saves=source:FindFirstChild("AnimSaves",true)
 if saves then
  for _,d in ipairs(saves:GetChildren()) do
   if d:IsA("KeyframeSequence") then
    local copy=d:Clone()
    copy.Parent=clips
   end
  end
 end
 source:Destroy()
 local old=model:FindFirstChild("AnimSaves")
 if old then old:Destroy() end
 return model
end

local function makeScarlet(spec)
 local model=basicRig(spec.id,"Scarlat")
 local particles=load(72797028676916)
 local effects=Instance.new("Folder")
 effects.Name="SpellParticles"
 effects.Parent=model
 local count=0
 for _,d in ipairs(particles:GetDescendants()) do
  if d:IsA("ParticleEmitter") and count<4 and d.Texture~="" then
   local c=d:Clone()
   c.Rate=math.min(c.Rate,12)
   c.Lifetime=NumberRange.new(.2,.6)
   c.Enabled=false
   c.Parent=effects
   count+=1
  end
 end
 particles:Destroy()
 assert(count>0,"Scarlet particles missing")
 return model
end

local function makeFreddy(spec)
 local model,clips=basicRig(spec.id,"Freddy")
 local anim=load(140005809574272)
 sequences(anim,140005809574272,{Idle="Idle",Walk="Walk",Run="Run",Attack="Punch"},clips)
 local sourceRig=anim:FindFirstChild("c00lkidd",true)
 assert(sourceRig,"Animation source rig missing")
 for _,j in ipairs(sourceRig:GetDescendants()) do
  if j:IsA("Motor6D") and j.Part1 then clips:SetAttribute("Bind_"..j.Part1.Name:gsub(" ","_"),j.C0) end
 end
 anim:Destroy()
 local aliases={
  ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.024"]="Torso",
  ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.036"]="Head",
  ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.022"]="Left Arm",
  ["fsfsdfsdfsdf"]="Right Arm",
  ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.026"]="Left Leg",
  ["Meshes/Withered Freddy.fbx.test_Withered Freddy Suit.025"]="Right Leg",
 }
 for _,j in ipairs(model:GetDescendants()) do
  if j:IsA("Motor6D") and j.Part0 and j.Part1 and aliases[j.Part1.Name] then
   local alias=aliases[j.Part1.Name]
   j:SetAttribute("PoseAlias",alias)
   local rootToParent=j.Part0.CFrame.Rotation:Inverse()*model.PrimaryPart.CFrame.Rotation
   if alias=="Left Arm" or alias=="Right Arm" then
    local angle=alias=="Left Arm" and math.pi/2 or -math.pi/2
    j.C0=CFrame.new(j.C0.Position)*rootToParent*CFrame.Angles(0,0,angle)*rootToParent:Inverse()*j.C0.Rotation
   end
   local source=clips:GetAttribute("Bind_"..alias:gsub(" ","_"))
   assert(source,"Missing animation binding: "..alias)
   j:SetAttribute("RetargetBasis",j.C0.Rotation:Inverse()*rootToParent*source.Rotation)
  end
 end
 return model
end

local function makeAmanda(spec)
 local model,clips=basicRig(spec.id,"Amanda")
 local asset=load(spec.id)
 local save=asset:FindFirstChild("AnimSaves",true)
 if save then sequences(save,spec.id,{Attack="AtticJumpscare",Walk="Automatic Save"},clips) end
 asset:Destroy()
 local old=model:FindFirstChild("AnimSaves")
 if old then old:Destroy() end
 return model
end

local function makeWarrior(spec)
 local description=Instance.new("HumanoidDescription")
 local warrior=Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
 description:Destroy()
 warrior.Name="Guerreiro"
 local hum=assert(warrior:FindFirstChildOfClass("Humanoid"))
 local root=assert(warrior:FindFirstChild("HumanoidRootPart"))
 warrior.PrimaryPart=root
 hum.RequiresNeck=false
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 hum.BreakJointsOnDeath=false
 hum.MaxHealth=100000
 hum.Health=100000
 hum.HipHeight=2.4

 local applied=0
 local failed={}
 for _,id in ipairs(spec.items or {}) do
  local ok,asset=pcall(function() return load(id) end)
  if ok and asset then
   local count=0
   local head=warrior:FindFirstChild("Head")
   for _,d in ipairs(asset:GetDescendants()) do
    if d:IsA("Accessory") then
     hum:AddAccessory(d:Clone()) count+=1
    elseif d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors") or d:IsA("CharacterMesh") then
     local old=warrior:FindFirstChildOfClass(d.ClassName)
     if old then old:Destroy() end
     d:Clone().Parent=warrior
     count+=1
    elseif d:IsA("Decal") and head and (d.Name:lower()=="face" or id==206119001888066) then
     local old=head:FindFirstChild("face")
     if old then old:Destroy() end
     local face=d:Clone()
     face.Name="face"
     face.Parent=head
     count+=1
    end
   end
   asset:Destroy()
   if count>0 then applied+=1 else table.insert(failed,id) end
  else
   table.insert(failed,id)
  end
 end
 assert(applied>=6,"Too few Warrior avatar items loaded")
 for _,d in ipairs(warrior:GetDescendants()) do
  if d:IsA("LuaSourceContainer") then d:Destroy()
  elseif d:IsA("BasePart") then d.Anchored=false d.CanCollide=false d.CanTouch=false d.Massless=true end
 end
 local jointCount=0
 for _,d in ipairs(warrior:GetDescendants()) do if d:IsA("Motor6D") then jointCount+=1 end end
 if jointCount==0 then
  local function link(name,p0Name,p1Name)
   local p0=warrior:FindFirstChild(p0Name)
   local p1=warrior:FindFirstChild(p1Name)
   if not (p0 and p1 and p0:IsA("BasePart") and p1:IsA("BasePart")) then return end
   local m=Instance.new("Motor6D")
   m.Name=name m.Part0=p0 m.Part1=p1
   m.C0=p0.CFrame:ToObjectSpace(p1.CFrame) m.C1=CFrame.new()
   m.Parent=p0
   jointCount+=1
  end
  link("Root","HumanoidRootPart","LowerTorso")
  link("Waist","LowerTorso","UpperTorso")
  link("Neck","UpperTorso","Head")
  link("LeftShoulder","UpperTorso","LeftUpperArm")
  link("LeftElbow","LeftUpperArm","LeftLowerArm")
  link("LeftWrist","LeftLowerArm","LeftHand")
  link("RightShoulder","UpperTorso","RightUpperArm")
  link("RightElbow","RightUpperArm","RightLowerArm")
  link("RightWrist","RightLowerArm","RightHand")
  link("LeftHip","LowerTorso","LeftUpperLeg")
  link("LeftKnee","LeftUpperLeg","LeftLowerLeg")
  link("LeftAnkle","LeftLowerLeg","LeftFoot")
  link("RightHip","LowerTorso","RightUpperLeg")
  link("RightKnee","RightUpperLeg","RightLowerLeg")
  link("RightAnkle","RightLowerLeg","RightFoot")
 end
 assert(jointCount>0,"Warrior joint reconstruction failed")
 root.CanCollide=true
 root.Massless=false
 root.Transparency=1
 root.Size=Vector3.new(2,2,1.5)

 local clips=Instance.new("Folder")
 clips.Name="MotionClips"
 clips.Parent=warrior
 local jason=load(spec.animation)
 sequences(jason,spec.animation,{Idle="Jason Idle",Walk="Jason Walk",Run="Jason Run"},clips)
 jason:Destroy()
 local aliases={UpperTorso="Torso",Head="Head",LeftUpperArm="Left Arm",RightUpperArm="Right Arm",LeftUpperLeg="Left Leg",RightUpperLeg="Right Leg"}
 for _,j in ipairs(warrior:GetDescendants()) do
  if j:IsA("Motor6D") and j.Part1 and aliases[j.Part1.Name] then j:SetAttribute("PoseAlias",aliases[j.Part1.Name]) end
 end
 warrior:SetAttribute("AvatarItems",table.concat(spec.items,","))
 warrior:SetAttribute("AnimationAssetId",spec.animation)
 warrior:SetAttribute("AppliedItemCount",applied)
 warrior:SetAttribute("FailedItemCount",#failed)
 return warrior
end

function Factory.create(name,spec)
 if name=="Figure" then return makeFigure(spec)
 elseif name=="Scarlat" then return makeScarlet(spec)
 elseif name=="Freddy" then return makeFreddy(spec)
 elseif name=="Amanda" then return makeAmanda(spec)
 elseif name=="Guerreiro" then return makeWarrior(spec)
 end
 error("Unknown killer "..tostring(name))
end

return Factory
