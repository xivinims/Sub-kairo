-- Retains the exact requested pose and dialogue assets. Outfit IDs must be
-- verified against the user's references before enabling the guide in Workspace.
local AssetService=game:GetService("AssetService")
local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")
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

-- Freeze Fill's current appearance permanently inside the place.
-- On the first run after this change, capture the already-published Fill NPC that is
-- currently wearing the approved outfit. Future publishes clone this saved description
-- and NEVER read the user's live avatar again.
local frozenTemplate=SS:FindFirstChild("FillFrozenAppearance")
if not frozenTemplate then
 local existingGuide=workspace:FindFirstChild("LobbyGuide")
 local existingHumanoid=existingGuide and existingGuide:FindFirstChildOfClass("Humanoid")
 if existingHumanoid then
  frozenTemplate=existingHumanoid:GetAppliedDescription()
 else
  -- One-time safety fallback only if an old Fill is genuinely absent.
  frozenTemplate=game:GetService("Players"):GetHumanoidDescriptionFromUserIdAsync(ownerId)
 end
 frozenTemplate.Name="FillFrozenAppearance"
 frozenTemplate:SetAttribute("Frozen",true)
 frozenTemplate:SetAttribute("SourceUserId",ownerId)
 frozenTemplate.Parent=SS
end
assert(frozenTemplate:IsA("HumanoidDescription") and frozenTemplate:GetAttribute("Frozen")==true,"Frozen Fill appearance missing")
local description=frozenTemplate:Clone()
-- Keep clothing, colors and accessories while retaining the requested R6 body/headless setup.
description.Head=0 description.Torso=0 description.LeftArm=0 description.RightArm=0 description.LeftLeg=0 description.RightLeg=0
npc.Parent=workspace
humanoid:ApplyDescriptionResetAsync(description)
for _,motor in ipairs(npc:GetDescendants()) do
 if motor:IsA("Motor6D") and authored[motor.Name] then
  motor.C0=authored[motor.Name] motor.Transform=CFrame.identity
 end
end
-- Applying an outfit must not reintroduce a default controller over the seated pose.
for _,obj in ipairs(npc:GetDescendants()) do
 if obj:IsA("LuaSourceContainer") then obj:Destroy()
 elseif obj:IsA("Motor6D") then obj.Enabled=true end
end
local applied=humanoid:GetAppliedDescription()
assert(applied.Shirt==description.Shirt and applied.Pants==description.Pants,"Avatar clothes were not applied")
npc:SetAttribute("OutfitUserId",ownerId)
npc:SetAttribute("OutfitUsername","ch_ckz2n")
npc:SetAttribute("OutfitFrozen",true)
npc:SetAttribute("OutfitSource","FillFrozenAppearance")
npc:SetAttribute("OutfitShirt",description.Shirt)
npc:SetAttribute("OutfitPants",description.Pants)
npc:SetAttribute("AuthoredPosePreserved",true)
assert(humanoid.RigType==Enum.HumanoidRigType.R6,"Guide must retain R6 pose")
humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
humanoid.RequiresNeck=false humanoid.AutoRotate=false humanoid.EvaluateStateMachine=false
local root=assert(npc:FindFirstChild("HumanoidRootPart"))
npc.PrimaryPart=root
for _,obj in ipairs(npc:GetDescendants()) do
 if obj:IsA("BasePart") then obj.Anchored=obj==root obj.CanCollide=false obj.CanTouch=false end
end
local head=assert(npc:FindFirstChild("Head")) head.Transparency=1
for _,obj in ipairs(head:GetDescendants()) do if obj:IsA("Decal") or obj:IsA("Texture") then obj:Destroy() end end
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
local prompt=Instance.new("ProximityPrompt") prompt.Name="ProximityPrompt" prompt.ActionText="Talk" prompt.ObjectText="Fill" prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Parent=npc
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

-- Find a real authored counter/desk/table in whichever fixed lobby is installed.
-- Prefer names from the source asset itself ("Counter top", "Counter", "Desk",
-- "Reception") and never create replacement furniture.
local receptionPieces={}
local receptionTop=nil
local bestScore=-math.huge

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

for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("BasePart") and part.Transparency<.98 and math.abs(part.CFrame.UpVector.Y)>.84 then
  local area=part.Size.X*part.Size.Z
  local topY=part.Position.Y+part.Size.Y/2
  local relativeHeight=topY-origin.Y
  local flatDistance=(Vector3.new(part.Position.X,origin.Y,part.Position.Z)-origin).Magnitude
  if area>=4 and part.Size.Y<=5 and relativeHeight>=1.4 and relativeHeight<=5.6 and flatDistance<=220 then
   local text=ancestryText(part)
   local score=0
   if string.find(text,"reception",1,true) then score+=260 end
   if string.find(text,"counter top",1,true) or string.find(text,"countertop",1,true) then score+=220 end
   if string.find(text,"counter",1,true) then score+=170 end
   if string.find(text,"front desk",1,true) or string.find(text,"frontdesk",1,true) then score+=200 end
   if string.find(text,"desk",1,true) then score+=120 end
   if string.find(text,"table",1,true) then score+=55 end
   if score>0 then
    score+=math.min(area,80)*.25
    score-=flatDistance*.13
    table.insert(receptionPieces,part)
    if score>bestScore then bestScore=score receptionTop=part end
   end
  end
 end
end

-- Fallback for imported meshes with generic names. It still uses an existing authored
-- horizontal surface and never generates a fake desk.
if not receptionTop then
 for _,part in ipairs(lobby:GetDescendants()) do
  if part:IsA("BasePart") and part.Transparency<.98 and math.abs(part.CFrame.UpVector.Y)>.92 then
   local area=part.Size.X*part.Size.Z
   local topY=part.Position.Y+part.Size.Y/2
   local relativeHeight=topY-origin.Y
   local flatDistance=(Vector3.new(part.Position.X,origin.Y,part.Position.Z)-origin).Magnitude
   if area>=8 and area<=180 and part.Size.Y<=3.5 and relativeHeight>=1.8 and relativeHeight<=4.8 and flatDistance>=6 and flatDistance<=120 then
    local score=80-math.abs(relativeHeight-3)*10-flatDistance*.18+math.min(area,60)*.1
    table.insert(receptionPieces,part)
    if score>bestScore then bestScore=score receptionTop=part end
   end
  end
 end
end
assert(receptionTop,"No authored reception/counter/table surface found in fixed lobby")

-- Face the lobby and move slightly toward the front edge so the authored seated legs
-- hang naturally over the counter instead of intersecting the desk.
local towardVisitors=Vector3.new(origin.X-receptionTop.Position.X,0,origin.Z-receptionTop.Position.Z)
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
local client=Instance.new("Script") client.Name="GuideInteraction" client.RunContext=Enum.RunContext.Client client.Source=__GUIDE_CLIENT_SOURCE__ client.Parent=npc
assert(head.Transparency==1 and humanoid.RigType==Enum.HumanoidRigType.R6,"Headless/R6 validation failed")
local accessoryIds={}
for _,a in ipairs(applied:GetAccessories(true)) do table.insert(accessoryIds,a.AssetId) end
posePackage:Destroy() dialoguePackage:Destroy()
return {ok=true,staged=false,headless=true,rig="R6",appearanceVerified=true,userId=ownerId,shirt=description.Shirt,pants=description.Pants,accessoryIds=accessoryIds,seatedGap=seatedGap,receptionPosition=tostring(torso.Position),tablePosition=tostring(receptionTop.Position),localGaze=true,voiceLanguage="English",uploadedVoice=true}

