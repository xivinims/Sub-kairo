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
local ownerId=game:GetService("Players"):GetUserIdFromNameAsync("ch_ckz2n")
assert(ownerId==8344738123,"Avatar username resolved to an unexpected account")
local description=game:GetService("Players"):GetHumanoidDescriptionFromUserIdAsync(ownerId)
-- Keep clothing, colors and accessories while retaining the requested R6 body.
description.Head=0 description.Torso=0 description.LeftArm=0 description.RightArm=0 description.LeftLeg=0 description.RightLeg=0
npc.Parent=workspace
humanoid:ApplyDescriptionResetAsync(description)
for _,motor in ipairs(npc:GetDescendants()) do
 if motor:IsA("Motor6D") and authored[motor.Name] then
  motor.C0=authored[motor.Name] motor.Transform=CFrame.identity
 end
end
local applied=humanoid:GetAppliedDescription()
assert(applied.Shirt==description.Shirt and applied.Pants==description.Pants,"Avatar clothes were not applied")
npc:SetAttribute("OutfitUserId",ownerId)
npc:SetAttribute("OutfitUsername","ch_ckz2n")
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
module.Parent=resources
local dialogUI=assert(dialoguePackage:FindFirstChild("dialog",true)):Clone()
dialogUI.ResetOnSpawn=false dialogUI.IgnoreGuiInset=true dialogUI.Parent=resources
local example=assert(dialoguePackage:FindFirstChild("showcase npc",true))
local bubble=assert(example.Head:FindFirstChild("gui")):Clone() bubble.Parent=head
bubble.name.Text="Fill"
local prompt=Instance.new("ProximityPrompt") prompt.Name="ProximityPrompt" prompt.ActionText="Conversar" prompt.ObjectText="Fill" prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=npc
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

local spawn=lobby:GetAttribute("VerifiedSpawn")
local origin=typeof(spawn)=="CFrame" and spawn.Position or spawn
assert(typeof(origin)=="Vector3","Verified lobby spawn missing")

-- The authored reception in JediLibrary is an L-shaped set of thin brown wooden
-- counter pieces far across the lobby from the spawn. Detect the cluster by its
-- real geometry/material rather than by unreliable imported object names ("Part").
local receptionPieces={}
for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("BasePart") and part.Transparency<.98 and part.Material==Enum.Material.Wood and math.abs(part.CFrame.UpVector.Y)>.88 then
  local area=part.Size.X*part.Size.Z
  local topY=part.Position.Y+part.Size.Y/2
  local relativeHeight=topY-origin.Y
  local flatDistance=(Vector3.new(part.Position.X,origin.Y,part.Position.Z)-origin).Magnitude
  local brown=math.abs(part.Color.R-105/255)<.08 and math.abs(part.Color.G-64/255)<.08 and math.abs(part.Color.B-40/255)<.08
  if brown and part.Size.Y<=.35 and area>=14 and relativeHeight>=1.8 and relativeHeight<=3.1 and flatDistance>=50 and flatDistance<=76 then
   table.insert(receptionPieces,part)
  end
 end
end
assert(#receptionPieces>=2,"Real lobby reception counter was not found")

local weighted=Vector3.zero
local weightTotal=0
local receptionTop=nil
local bestArea=-1
for _,part in ipairs(receptionPieces) do
 local area=part.Size.X*part.Size.Z
 weighted+=part.Position*area
 weightTotal+=area
 if area>bestArea then bestArea=area receptionTop=part end
end
local deskCenter=weighted/math.max(weightTotal,.001)
local towardVisitors=Vector3.new(origin.X-deskCenter.X,0,origin.Z-deskCenter.Z)
if towardVisitors.Magnitude<.1 then towardVisitors=Vector3.new(1,0,0) else towardVisitors=towardVisitors.Unit end
local behind=-towardVisitors
local side=Vector3.new(-behind.Z,0,behind.X)

-- Put Fill behind the actual reception, on its floor, facing the player approach.
-- Search several offsets so imported counter geometry can never trap him inside the desk.
local ray=RaycastParams.new()
ray.FilterType=Enum.RaycastFilterType.Include
ray.FilterDescendantsInstances={lobby}
ray.RespectCanCollide=true
local floorHit=nil
local standPosition=nil
for _,distance in ipairs({4.5,5.5,6.5,7.5,8.5}) do
 for _,sideOffset in ipairs({0,-2.5,2.5,-4,4}) do
  local flat=deskCenter+behind*distance+side*sideOffset
  local probe=Vector3.new(flat.X,origin.Y+1.6,flat.Z)
  local hit=workspace:Raycast(probe,Vector3.new(0,-5,0),ray)
  if hit and hit.Normal.Y>.82 and math.abs(hit.Position.Y-origin.Y)<1.25 then
   floorHit=hit
   standPosition=hit.Position
   break
  end
 end
 if standPosition then break end
end
assert(standPosition and floorHit,"No safe floor position behind the real reception counter")

local facePoint=Vector3.new(origin.X,standPosition.Y,origin.Z)
npc:PivotTo(CFrame.lookAt(standPosition,facePoint))
for _=1,3 do
 for _,motor in ipairs(npc:GetDescendants()) do
  if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
   motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.C1:Inverse()
  end
 end
end
local bounds,dimensions=npc:GetBoundingBox()
local bottom=bounds.Position.Y-dimensions.Y/2
npc:PivotTo(npc:GetPivot()+Vector3.new(
 standPosition.X-bounds.Position.X,
 standPosition.Y-bottom+.02,
 standPosition.Z-bounds.Position.Z
))

npc.Name="LobbyGuide"
npc:SetAttribute("DisplayName","Fill")
npc:SetAttribute("Placement","ReceptionDesk")
npc:SetAttribute("ReceptionSurface",receptionTop:GetFullName())
npc:SetAttribute("ReceptionPosition",standPosition)
npc:SetAttribute("ReceptionPieceCount",#receptionPieces)
local tableReference=Instance.new("ObjectValue")
tableReference.Name="Tabletop"
tableReference.Value=receptionTop
tableReference.Parent=npc

local placedBounds,placedSize=npc:GetBoundingBox()
local floorGap=placedBounds.Position.Y-placedSize.Y/2-standPosition.Y
assert(math.abs(floorGap-.02)<.1,"Fill is not grounded behind the reception")
local client=Instance.new("Script") client.Name="GuideInteraction" client.RunContext=Enum.RunContext.Client client.Source=__GUIDE_CLIENT_SOURCE__ client.Parent=npc
assert(head.Transparency==1 and humanoid.RigType==Enum.HumanoidRigType.R6,"Headless/R6 validation failed")
local accessoryIds={}
for _,a in ipairs(applied:GetAccessories(true)) do table.insert(accessoryIds,a.AssetId) end
posePackage:Destroy() dialoguePackage:Destroy()
return {ok=true,staged=false,headless=true,rig="R6",appearanceVerified=true,userId=ownerId,shirt=description.Shirt,pants=description.Pants,accessoryIds=accessoryIds,receptionFloorGap=floorGap,receptionPosition=tostring(standPosition),tablePosition=tostring(receptionTop.Position),localGaze=true}
