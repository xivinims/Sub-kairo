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
bubble.name.Text="Guardião"
local prompt=Instance.new("ProximityPrompt") prompt.Name="ProximityPrompt" prompt.ActionText="Conversar" prompt.ObjectText="Guardião" prompt.MaxActivationDistance=8 prompt.RequiresLineOfSight=true prompt.Parent=npc
game:GetService("CollectionService"):AddTag(prompt,"NPCprompt")

local pending=SS:FindFirstChild("PendingLobbyGuide") if pending then pending:Destroy() end
local previousResources=RS:FindFirstChild("LobbyGuideResources") if previousResources then previousResources:Destroy() end
resources.Parent=RS
local lobby=assert(workspace:FindFirstChild("JediLibrary"))
local oldTable=lobby:FindFirstChild("GuideTable") if oldTable then oldTable:Destroy() end
for _,other in ipairs(workspace:GetChildren()) do if other.Name=="LobbyGuide" and other~=npc then other:Destroy() end end
-- Place a dedicated table on a verified clear floor, outside the spawn.
local spawn=lobby:GetAttribute("VerifiedSpawn")
local origin=typeof(spawn)=="CFrame" and spawn.Position or spawn
assert(typeof(origin)=="Vector3","Verified lobby spawn missing")
local box,size=npc:GetBoundingBox()
local width=math.max(8,size.X+1)
local depth=math.max(6,size.Z+1)
assert(width<=16 and depth<=16,"Avatar accessories exceed safe tabletop dimensions")
local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={lobby} ray.RespectCanCollide=true
local overlap=OverlapParams.new() overlap.FilterType=Enum.RaycastFilterType.Include overlap.FilterDescendantsInstances={lobby} overlap.RespectCanCollide=true
local ground
for radius=16,40,8 do
 for a=0,7 do
  local point=origin+Vector3.new(math.cos(a*math.pi/4)*radius,0,math.sin(a*math.pi/4)*radius)
  local hit=workspace:Raycast(point+Vector3.new(0,14,0),Vector3.new(0,-22,0),ray)
  if hit and hit.Normal.Y>.98 and math.abs(hit.Position.Y-origin.Y)<2 then
   local center=hit.Position+Vector3.new(0,5,0)
   local parts=workspace:GetPartBoundsInBox(CFrame.new(center),Vector3.new(width+2,9,depth+2),overlap)
   local clear=true for _,part in ipairs(parts) do if part.CanCollide and part.Transparency<1 then clear=false break end end
   if clear then
    local supported=true
    for _,corner in ipairs({Vector3.new(-width/2,0,-depth/2),Vector3.new(width/2,0,-depth/2),Vector3.new(-width/2,0,depth/2),Vector3.new(width/2,0,depth/2)}) do
     local support=workspace:Raycast(hit.Position+corner+Vector3.new(0,2,0),Vector3.new(0,-4,0),ray)
     if not support or math.abs(support.Position.Y-hit.Position.Y)>.12 then supported=false break end
    end
    if supported then ground=hit.Position break end
   end
  end
 end
 if ground then break end
end
assert(ground,"No clear supported location for NPC table; refusing floor/spawn fallback")
local tableModel=Instance.new("Model") tableModel.Name="GuideTable" tableModel.Parent=lobby
local function tablePart(name,dimensions,position,color,material)
 local part=Instance.new("Part") part.Name=name part.Size=dimensions part.CFrame=CFrame.new(position)
 part.Anchored=true part.CanCollide=true part.Material=material part.Color=color part.TopSurface=Enum.SurfaceType.Smooth part.BottomSurface=Enum.SurfaceType.Smooth part.Parent=tableModel return part
end
local top=tablePart("Tabletop",Vector3.new(width,.35,depth),ground+Vector3.new(0,3.15,0),Color3.fromRGB(55,40,34),Enum.Material.Wood)
for _,x in ipairs({-width/2+.5,width/2-.5}) do
 for _,z in ipairs({-depth/2+.5,depth/2-.5}) do tablePart("Leg",Vector3.new(.45,2.98,.45),ground+Vector3.new(x,1.49,z),Color3.fromRGB(28,26,26),Enum.Material.Metal) end
end
local toward=Vector3.new(origin.X,ground.Y,origin.Z)
npc:PivotTo(CFrame.lookAt(ground,toward))
-- Recompute the authored body's physical placement before bounding-box alignment.
for pass=1,3 do
 for _,motor in ipairs(npc:GetDescendants()) do
  if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.C1:Inverse() end
 end
end
local bounds,dimensions=npc:GetBoundingBox()
local bottom=bounds.Position.Y-dimensions.Y/2
npc:PivotTo(npc:GetPivot()+Vector3.new(ground.X-bounds.Position.X,top.Position.Y+top.Size.Y/2-bottom+.02,ground.Z-bounds.Position.Z))
npc:SetAttribute("Placement","TabletopOnly")
local tableReference=Instance.new("ObjectValue") tableReference.Name="Tabletop" tableReference.Value=top tableReference.Parent=npc
local client=Instance.new("Script") client.Name="GuideInteraction" client.RunContext=Enum.RunContext.Client client.Source=__GUIDE_CLIENT_SOURCE__ client.Parent=npc
local newBounds,newSize=npc:GetBoundingBox()
local gap=newBounds.Position.Y-newSize.Y/2-(top.Position.Y+top.Size.Y/2)
assert(math.abs(gap-.02)<.08,"Guide does not touch tabletop")
assert(head.Transparency==1 and humanoid.RigType==Enum.HumanoidRigType.R6,"Headless/R6 validation failed")
local accessoryIds={}
for _,a in ipairs(applied:GetAccessories(true)) do table.insert(accessoryIds,a.AssetId) end
posePackage:Destroy() dialoguePackage:Destroy()
return {ok=true,staged=false,headless=true,rig="R6",appearanceVerified=true,userId=ownerId,shirt=description.Shirt,pants=description.Pants,accessoryIds=accessoryIds,tabletopGap=gap,tablePosition=tostring(top.Position),localGaze=true}
