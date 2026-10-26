-- Retains the exact requested pose and dialogue assets. Outfit IDs must be
-- verified against the user's references before enabling the guide in Workspace.
local AssetService=game:GetService("AssetService")
local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")
local PhysicsService=game:GetService("PhysicsService")
local posePackage=AssetService:LoadAssetAsync(92697245643515)
local dialoguePackage=AssetService:LoadAssetAsync(80608769509945)
local npc=assert(posePackage:FindFirstChild("Creator",true),"Pose rig missing"):Clone()
npc.Name="LobbyGuide"
for _,obj in ipairs(npc:GetDescendants()) do
 if obj:IsA("LuaSourceContainer") then obj:Destroy() end
end
local authored={}
for _,motor in ipairs(npc:GetDescendants()) do
 if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
  authored[motor.Name]=motor.Part0.CFrame:ToObjectSpace(motor.Part1.CFrame)*motor.C1
 end
end
local humanoid=assert(npc:FindFirstChildOfClass("Humanoid"))
local ownerId=8344738123
local OUTFIT_REVISION="2026-10-26-mafia-satchel-v1"
local REQUESTED_PANTS_ID=110421904136844
local REQUESTED_BAG_ID=97665507839365

-- Refresh from the owner's current avatar once for this requested revision, apply the
-- requested pants/bag, then freeze that exact appearance for later publishes.
local frozenTemplate=SS:FindFirstChild("FillFrozenAppearance")
if not frozenTemplate or frozenTemplate:GetAttribute("Revision")~=OUTFIT_REVISION then
 if frozenTemplate then frozenTemplate:Destroy() end
 frozenTemplate=game:GetService("Players"):GetHumanoidDescriptionFromUserIdAsync(ownerId)
 frozenTemplate.Name="FillFrozenAppearance"
 frozenTemplate.Pants=REQUESTED_PANTS_ID
 frozenTemplate:SetAttribute("Frozen",true)
 frozenTemplate:SetAttribute("SourceUserId",ownerId)
 frozenTemplate:SetAttribute("Revision",OUTFIT_REVISION)
 frozenTemplate:SetAttribute("RequestedPantsAssetId",REQUESTED_PANTS_ID)
 frozenTemplate:SetAttribute("RequestedBagAssetId",REQUESTED_BAG_ID)
 frozenTemplate.Parent=SS
end
assert(frozenTemplate:IsA("HumanoidDescription") and frozenTemplate:GetAttribute("Frozen")==true,"Frozen Fill appearance missing")

local description=frozenTemplate:Clone()
description.Pants=REQUESTED_PANTS_ID
-- If the live avatar already contains this exact satchel, remove that copy from the
-- description because the requested catalog asset is attached explicitly below.
pcall(function()
 local filtered={}
 for _,item in ipairs(description:GetAccessories(true)) do
  if item.AssetId~=REQUESTED_BAG_ID then table.insert(filtered,item) end
 end
 description:SetAccessories(filtered,true)
end)

-- Keep the user's clothing/colors/accessories while preserving the authored R6/headless body.
description.Head=0 description.Torso=0 description.LeftArm=0 description.RightArm=0 description.LeftLeg=0 description.RightLeg=0
npc.Parent=workspace
humanoid:ApplyDescriptionResetAsync(description)

local oldBag=npc:FindFirstChild("FillCrossbodySatchel",true)
if oldBag then oldBag:Destroy() end
local bagPackage=AssetService:LoadAssetAsync(REQUESTED_BAG_ID)
local bagSource=assert(bagPackage:FindFirstChildWhichIsA("Accessory",true),"Requested crossbody satchel is not an Accessory")
local bag=bagSource:Clone()
bag.Name="FillCrossbodySatchel"
for _,obj in ipairs(bag:GetDescendants()) do
 if obj:IsA("LuaSourceContainer") then
  obj:Destroy()
 elseif obj:IsA("BasePart") then
  obj.CanCollide=false obj.CanTouch=false obj.CanQuery=false obj.Massless=true
 end
end
humanoid:AddAccessory(bag)
bagPackage:Destroy()
assert(npc:FindFirstChild("FillCrossbodySatchel",true),"Requested crossbody satchel failed to attach")

for _,motor in ipairs(npc:GetDescendants()) do
 if motor:IsA("Motor6D") and authored[motor.Name] then
  motor.C0=authored[motor.Name]
  motor.Transform=CFrame.identity
 end
end

-- Applying an outfit must not reintroduce a default controller over the seated pose.
for _,obj in ipairs(npc:GetDescendants()) do
 if obj:IsA("LuaSourceContainer") then obj:Destroy()
 elseif obj:IsA("Motor6D") then obj.Enabled=true end
end

local applied=humanoid:GetAppliedDescription()
assert(applied.Shirt==description.Shirt and applied.Pants==REQUESTED_PANTS_ID,"Requested Fill clothes were not applied")
npc:SetAttribute("OutfitUserId",ownerId)
npc:SetAttribute("OutfitUsername","ch_ckz2n")
npc:SetAttribute("OutfitFrozen",true)
npc:SetAttribute("OutfitSource","FillFrozenAppearance")
npc:SetAttribute("OutfitRevision",OUTFIT_REVISION)
npc:SetAttribute("OutfitShirt",description.Shirt)
npc:SetAttribute("OutfitPants",REQUESTED_PANTS_ID)
npc:SetAttribute("CrossbodyBagAssetId",REQUESTED_BAG_ID)
npc:SetAttribute("AuthoredPosePreserved",true)

assert(humanoid.RigType==Enum.HumanoidRigType.R6,"Guide must retain R6 pose")
humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
humanoid.RequiresNeck=false
humanoid.AutoRotate=false
humanoid.EvaluateStateMachine=false
local root=assert(npc:FindFirstChild("HumanoidRootPart"))
npc.PrimaryPart=root
for _,obj in ipairs(npc:GetDescendants()) do
 if obj:IsA("BasePart") then
  obj.Anchored=obj==root
  obj.CanCollide=false
  obj.CanTouch=false
  obj.CanQuery=false
 end
end

local head=assert(npc:FindFirstChild("Head"))
head.Transparency=1
for _,obj in ipairs(head:GetDescendants()) do
 if obj:IsA("Decal") or obj:IsA("Texture") then obj:Destroy() end
end

npc:SetAttribute("PoseSourceAssetId",92697245643515)
npc:SetAttribute("DialogueSourceAssetId",80608769509945)
npc:SetAttribute("AppearanceVerified",true)

local module=assert(dialoguePackage:FindFirstChild("DialogModule",true)):Clone()
local source=module.Source
-- Preserve the user's FOV; the original package unconditionally sets 65/70.
source=source:gsub("tweenService:Create%(game.Workspace.CurrentCamera,[^\n]+", "-- Camera remains owned by the game's camera controller.")
-- Iterate complete Unicode graphemes so Portuguese accents are not split.
source=source:gsub('for i, letter in string.split%(dialog.text,""%) do','for first, last in utf8.graphemes(dialog.text) do\n local letter=string.sub(dialog.text,first,last)')
source=source:gsub('for i, letter in string.split%(exitQuip,""%) do','for first, last in utf8.graphemes(exitQuip) do\n local letter=string.sub(exitQuip,first,last)')
source=source:gsub('player.Character.PrimaryPart.Position','(player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position or Vector3.new(1e6,1e6,1e6))')
module.Source=source
local resources=Instance.new("Folder") resources.Name="LobbyGuideResources"
resources:SetAttribute("Language","en")
local survival=assert(RS:FindFirstChild("Survival"),"Survival runtime missing")
for i=1,6 do
 local id=tonumber(survival:GetAttribute("FillVoice"..i)) or 0
 assert(id>0,"Fill English voice asset "..i.." missing")
 resources:SetAttribute("Voice"..i,id)
end
npc:SetAttribute("VoiceLanguage","English")
module.Parent=resources
local dialogUI=assert(dialoguePackage:FindFirstChild("dialog",true)):Clone()
dialogUI.ResetOnSpawn=false dialogUI.IgnoreGuiInset=true dialogUI.Parent=resources
local example=assert(dialoguePackage:FindFirstChild("showcase npc",true))
local bubble=assert(example.Head:FindFirstChild("gui")):Clone() bubble.Parent=head
bubble.name.Text="Fill"
local prompt=Instance.new("ProximityPrompt") prompt.Name="ProximityPrompt" prompt.ActionText="Talk" prompt.ObjectText="Fill" prompt.MaxActivationDistance=14 prompt.RequiresLineOfSight=false prompt.Parent=npc
game:GetService("CollectionService"):AddTag(prompt,"NPCprompt")

local pending=SS:FindFirstChild("PendingLobbyGuide") if pending then pending:Destroy() end
local previousResources=RS:FindFirstChild("LobbyGuideResources") if previousResources then previousResources:Destroy() end
resources.Parent=RS
local lobby=assert(workspace:FindFirstChild("JediLibrary"))
for _,other in ipairs(workspace:GetChildren()) do
 if other.Name=="LobbyGuide" and other~=npc then other:Destroy() end
end
-- Remove the old generated table. It was never the lobby reception and was the reason
-- Fill kept appearing in the wrong place.
local legacyGuideTable=lobby:FindFirstChild("GuideTable")
if legacyGuideTable then legacyGuideTable:Destroy() end

local spawn=lobby:GetAttribute("ReceptionSearchOrigin") or lobby:GetAttribute("VerifiedSpawn")
lobby:SetAttribute("ReceptionSearchOrigin",spawn)
local origin=typeof(spawn)=="CFrame" and spawn.Position or spawn
assert(typeof(origin)=="Vector3","Verified lobby spawn missing")

-- Use an actual authored table from the lower lobby floor. The previous generated
-- stool could sit inside wall geometry because it was placed relative only to spawn.
local receptionPieces={}
local previousCounter=lobby:FindFirstChild("FillReceptionCounter")
if previousCounter then previousCounter:Destroy() end
local previousStool=lobby:FindFirstChild("FillGuideStool")
if previousStool then previousStool:Destroy() end

local function ancestryText(part)
 local names={string.lower(part.Name)}
 local p=part.Parent
 for _=1,5 do
  if not p or p==lobby then break end
  table.insert(names,string.lower(p.Name))
  p=p.Parent
 end
 return table.concat(names," ")
end

local receptionTop=nil
local bestDistance=math.huge
for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("BasePart") and part.CanCollide and part.Transparency<.98 then
  local text=ancestryText(part)
  local topY=part.Position.Y+part.Size.Y/2
  local flatDistance=(Vector3.new(part.Position.X,origin.Y,part.Position.Z)-origin).Magnitude
  local authoredConsole=part.Name=="Furniture_Console_A" and string.find(text,"console desk",1,true)
  local authoredTable=(string.find(text,"table",1,true) or string.find(text,"desk",1,true)) and part.Size.X>=4 and part.Size.Z>=1.8
  if (authoredConsole or authoredTable) and math.abs(topY-origin.Y)<=2.5 and flatDistance>=8 and flatDistance<=65 then
   local score=flatDistance+(authoredConsole and -20 or 0)
   if score<bestDistance then
    bestDistance=score
    receptionTop=part
   end
  end
 end
end
assert(receptionTop,"No authored lower-floor table found for Fill")

local towardSpawn=Vector3.new(origin.X-receptionTop.Position.X,0,origin.Z-receptionTop.Position.Z)
if towardSpawn.Magnitude<.1 then towardSpawn=Vector3.new(1,0,0) else towardSpawn=towardSpawn.Unit end
local receptionVisitor=Vector3.new(
 receptionTop.Position.X+towardSpawn.X*4.2,
 origin.Y,
 receptionTop.Position.Z+towardSpawn.Z*4.2
)
local receptionPathSteps=1
receptionPieces={receptionTop}
lobby:SetAttribute("FillAuthoredTable",receptionTop:GetFullName())
lobby:SetAttribute("FillTableTopY",receptionTop.Position.Y+receptionTop.Size.Y/2)

-- Face the lobby and move slightly toward the front edge so the authored seated legs
-- hang naturally over the counter instead of intersecting the desk.
local towardVisitors=Vector3.new(receptionVisitor.X-receptionTop.Position.X,0,receptionVisitor.Z-receptionTop.Position.Z)
if towardVisitors.Magnitude<.1 then towardVisitors=Vector3.new(1,0,0) else towardVisitors=towardVisitors.Unit end
local localFront=receptionTop.CFrame:VectorToObjectSpace(towardVisitors)
local seatLocal=Vector3.zero
if math.abs(localFront.X)>math.abs(localFront.Z) then
 seatLocal=Vector3.new(math.sign(localFront.X)*(receptionTop.Size.X/2-.7),0,0)
else
 seatLocal=Vector3.new(0,0,math.sign(localFront.Z)*(receptionTop.Size.Z/2-.7))
end
local seatWorld=receptionTop.CFrame:PointToWorldSpace(Vector3.new(seatLocal.X,receptionTop.Size.Y/2,seatLocal.Z))
local facePoint=seatWorld+towardVisitors*8

npc:PivotTo(CFrame.lookAt(seatWorld,facePoint))
for _=1,3 do
 for _,motor in ipairs(npc:GetDescendants()) do
  if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
   motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.C1:Inverse()
  end
 end
end

-- A seated R6 pose is aligned by the hip line (bottom of Torso), NOT by the model's
-- bounding-box bottom. This keeps the legs hanging below the tabletop and prevents Fill
-- from floating above it.
local torso=assert(npc:FindFirstChild("Torso"),"Fill R6 torso missing")
local hipLine=torso.Position.Y-torso.Size.Y/2
local topY=receptionTop.Position.Y+receptionTop.Size.Y/2
local shift=Vector3.new(seatWorld.X-torso.Position.X,topY+.025-hipLine,seatWorld.Z-torso.Position.Z)
npc:PivotTo(npc:GetPivot()+shift)

npc.Name="LobbyGuide"
npc:SetAttribute("DisplayName","Fill")
npc:SetAttribute("Placement","ReceptionTabletopSeated")
npc:SetAttribute("ReceptionSurface",receptionTop:GetFullName())
npc:SetAttribute("ReceptionPosition",torso.Position)
npc:SetAttribute("ReceptionPieceCount",#receptionPieces)
npc:SetAttribute("SeatedOnReception",true)
npc:SetAttribute("ReceptionAccessValidated",true)
npc:SetAttribute("ReceptionAccessMode","AuthoredTable")
npc:SetAttribute("GuideStation",receptionTop:GetFullName())
npc:SetAttribute("VerifiedVisitorPosition",receptionVisitor)
npc:SetAttribute("ReceptionAccessSteps",receptionPathSteps)
local tableReference=Instance.new("ObjectValue")
tableReference.Name="Tabletop"
tableReference.Value=receptionTop
tableReference.Parent=npc

-- Preserve the fixed lobby's verified player spawn near the authored house door.
-- Fill placement must never move the player spawn.
local preservedSpawn=lobby:GetAttribute("VerifiedSpawn")
assert(typeof(preservedSpawn)=="Vector3","Fixed lobby verified spawn missing")
npc:SetAttribute("LobbySpawnDistance",(preservedSpawn-seatWorld).Magnitude)
local seatedGap=(torso.Position.Y-torso.Size.Y/2)-topY
assert(math.abs(seatedGap-.025)<.08,"Fill is floating or clipping instead of sitting on reception tabletop")

-- Final collision normalization happens AFTER ApplyDescription, pose restoration and
-- tabletop placement. Humanoid character parts can re-enable collision while the rig is
-- settling; the published guide must remain purely visual and never block a doorway.
local ghostGroup="LobbyGuideGhost"
pcall(function() PhysicsService:RegisterCollisionGroup(ghostGroup) end)
for _,group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
 pcall(function() PhysicsService:CollisionGroupSetCollidable(ghostGroup,group.name,false) end)
end
pcall(function() PhysicsService:CollisionGroupSetCollidable(ghostGroup,ghostGroup,false) end)

local nonBlockingParts=0
for _,obj in ipairs(npc:GetDescendants()) do
 if obj:IsA("BasePart") then
  pcall(function() obj.CollisionGroup=ghostGroup end)
  obj.CanCollide=false
  obj.CanTouch=false
  obj.CanQuery=false
  obj.AssemblyLinearVelocity=Vector3.zero
  obj.AssemblyAngularVelocity=Vector3.zero
  if obj~=root then obj.Massless=true end
  nonBlockingParts+=1
 end
end
root.Anchored=true
npc:SetAttribute("NonBlockingGuide",true)
npc:SetAttribute("NonBlockingPartCount",nonBlockingParts)
npc:SetAttribute("CollisionGroup",ghostGroup)
for _,obj in ipairs(npc:GetDescendants()) do
 if obj:IsA("BasePart") then
  assert(obj.CollisionGroup==ghostGroup,"Fill ghost collision group missing on "..obj:GetFullName())
  assert(not obj.CanCollide and not obj.CanTouch and not obj.CanQuery,"Fill collision returned on "..obj:GetFullName())
 end
end

local guard=Instance.new("Script")
guard.Name="NonBlockingGuard"
guard.Source=[=[
local PhysicsService=game:GetService("PhysicsService")
local npc=script.Parent
local GROUP="LobbyGuideGhost"
pcall(function() PhysicsService:RegisterCollisionGroup(GROUP) end)

local locked=setmetatable({},{__mode="k"})
local function refreshGroups()
 for _,group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
  pcall(function() PhysicsService:CollisionGroupSetCollidable(GROUP,group.name,false) end)
 end
 pcall(function() PhysicsService:CollisionGroupSetCollidable(GROUP,GROUP,false) end)
end

local function lockPart(part)
 if not part:IsA("BasePart") then return end
 pcall(function() part.CollisionGroup=GROUP end)
 part.CanCollide=false
 part.CanTouch=false
 part.CanQuery=false
 if part.Name~="HumanoidRootPart" then part.Massless=true end
 if locked[part] then return end
 locked[part]=true
 part:GetPropertyChangedSignal("CanCollide"):Connect(function()
  if part.Parent and part.CanCollide then part.CanCollide=false end
 end)
 part:GetPropertyChangedSignal("CanTouch"):Connect(function()
  if part.Parent and part.CanTouch then part.CanTouch=false end
 end)
 part:GetPropertyChangedSignal("CanQuery"):Connect(function()
  if part.Parent and part.CanQuery then part.CanQuery=false end
 end)
end

refreshGroups()
for _,obj in ipairs(npc:GetDescendants()) do lockPart(obj) end
npc.DescendantAdded:Connect(function(obj) task.defer(lockPart,obj) end)

while npc.Parent do
 task.wait(5)
 refreshGroups()
 for _,obj in ipairs(npc:GetDescendants()) do lockPart(obj) end
end
]=]
guard.Parent=npc

local client=Instance.new("Script") client.Name="GuideInteraction" client.RunContext=Enum.RunContext.Client client.Source=__GUIDE_CLIENT_SOURCE__ client.Parent=npc
assert(head.Transparency==1 and humanoid.RigType==Enum.HumanoidRigType.R6,"Headless/R6 validation failed")
local accessoryIds={}
for _,a in ipairs(applied:GetAccessories(true)) do table.insert(accessoryIds,a.AssetId) end
posePackage:Destroy() dialoguePackage:Destroy()
return {ok=true,staged=false,headless=true,rig="R6",appearanceVerified=true,userId=ownerId,shirt=description.Shirt,pants=description.Pants,accessoryIds=accessoryIds,seatedGap=seatedGap,receptionPosition=tostring(torso.Position),tablePosition=tostring(receptionTop.Position),localGaze=true,voiceLanguage="English",uploadedVoice=true}

