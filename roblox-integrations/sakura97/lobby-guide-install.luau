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
local prompt=Instance.new("ProximityPrompt") prompt.Name="ProximityPrompt" prompt.ActionText="Conversar" prompt.ObjectText="Fill" prompt.MaxActivationDistance=8 prompt.RequiresLineOfSight=true prompt.Parent=npc
game:GetService("CollectionService"):AddTag(prompt,"NPCprompt")

local pending=SS:FindFirstChild("PendingLobbyGuide") if pending then pending:Destroy() end
local previousResources=RS:FindFirstChild("LobbyGuideResources") if previousResources then previousResources:Destroy() end
resources.Parent=RS
local lobby=assert(workspace:FindFirstChild("JediLibrary"))
for _,other in ipairs(workspace:GetChildren()) do if other.Name=="LobbyGuide" and other~=npc then other:Destroy() end end

-- Reception placement: prefer the actual front desk/counter already authored in the lobby.
-- Never depend on the old randomly-created GuideTable, because that could leave the guide
-- missing or far away from reception when the lobby layout changed.
local spawn=lobby:GetAttribute("VerifiedSpawn")
local origin=typeof(spawn)=="CFrame" and spawn.Position or spawn
if typeof(origin)~="Vector3" then origin=lobby:GetPivot().Position end
local door=lobby:GetAttribute("FormerDoorCFrame")
local entrance=typeof(door)=="CFrame" and door.Position or origin

local function ancestryText(part)
 local names={string.lower(part.Name)}
 local p=part.Parent
 for _=1,4 do
  if not p or p==lobby then break end
  table.insert(names,string.lower(p.Name))
  p=p.Parent
 end
 return table.concat(names," ")
end

local function explicitReceptionScore(part)
 if not part:IsA("BasePart") then return -math.huge end
 if math.abs(part.CFrame.UpVector.Y)<.82 then return -math.huge end
 local topArea=part.Size.X*part.Size.Z
 if topArea<5 or part.Size.Y>5 then return -math.huge end
 local text=ancestryText(part)
 local score=0
 if string.find(text,"reception",1,true) then score+=160 end
 if string.find(text,"frontdesk",1,true) or string.find(text,"front desk",1,true) then score+=150 end
 if string.find(text,"counter",1,true) then score+=120 end
 if string.find(text,"desk",1,true) then score+=105 end
 if string.find(text,"tabletop",1,true) then score+=75 end
 if string.find(text,"table",1,true) then score+=55 end
 if score==0 then return -math.huge end
 score+=math.min(topArea,80)*.2
 score-=math.min((part.Position-entrance).Magnitude,120)*.08
 return score
end

local receptionTop,bestScore
bestScore=-math.huge
for _,obj in ipairs(lobby:GetDescendants()) do
 if obj:IsA("BasePart") then
  local score=explicitReceptionScore(obj)
  if score>bestScore then bestScore=score receptionTop=obj end
 end
end

-- Some imported Roblox assets have useless names such as "Part". If that happens,
-- select a plausible horizontal counter surface near the entrance/spawn instead.
if not receptionTop then
 local best=-math.huge
 for _,part in ipairs(lobby:GetDescendants()) do
  if part:IsA("BasePart") and part.Transparency<1 and math.abs(part.CFrame.UpVector.Y)>.9 then
   local area=part.Size.X*part.Size.Z
   local topY=part.Position.Y+part.Size.Y/2
   local relativeHeight=topY-origin.Y
   if area>=12 and area<=180 and part.Size.Y<=3.5 and relativeHeight>=1.8 and relativeHeight<=5.2 then
    local distance=(Vector3.new(part.Position.X,origin.Y,part.Position.Z)-origin).Magnitude
    if distance<=65 then
     local score=80-math.abs(relativeHeight-3.1)*14-distance*.35+math.min(area,60)*.08
     if score>best then best=score receptionTop=part end
    end
   end
  end
 end
end

-- Final safety net: if the imported lobby genuinely has no usable counter, create a
-- deterministic reception desk instead of silently omitting Fill.
if not receptionTop then
 local ray=RaycastParams.new()
 ray.FilterType=Enum.RaycastFilterType.Include
 ray.FilterDescendantsInstances={lobby}
 ray.RespectCanCollide=true
 local groundHit
 for radius=10,34,6 do
  for a=0,7 do
   local point=origin+Vector3.new(math.cos(a*math.pi/4)*radius,12,math.sin(a*math.pi/4)*radius)
   local hit=workspace:Raycast(point,Vector3.new(0,-24,0),ray)
   if hit and hit.Normal.Y>.94 then groundHit=hit break end
  end
  if groundHit then break end
 end
 local floor=groundHit and groundHit.Position or origin
 local desk=Instance.new("Model") desk.Name="ReceptionDesk" desk.Parent=lobby
 local top=Instance.new("Part")
 top.Name="ReceptionCounter"
 top.Size=Vector3.new(10,.4,4)
 top.CFrame=CFrame.new(floor+Vector3.new(0,3.05,0))
 top.Anchored=true top.CanCollide=true top.Material=Enum.Material.Wood
 top.Color=Color3.fromRGB(55,40,34)
 top.TopSurface=Enum.SurfaceType.Smooth top.BottomSurface=Enum.SurfaceType.Smooth
 top.Parent=desk
 for _,x in ipairs({-4.35,4.35}) do
  for _,z in ipairs({-1.35,1.35}) do
   local leg=Instance.new("Part")
   leg.Name="Leg" leg.Size=Vector3.new(.45,2.85,.45)
   leg.CFrame=CFrame.new(floor+Vector3.new(x,1.425,z))
   leg.Anchored=true leg.CanCollide=true leg.Material=Enum.Material.Metal
   leg.Color=Color3.fromRGB(28,26,26) leg.Parent=desk
  end
 end
 receptionTop=top
end

-- Put Fill directly on the reception surface and face him toward the lobby entrance/spawn.
local face=Vector3.new(entrance.X,receptionTop.Position.Y,entrance.Z)
if (face-receptionTop.Position).Magnitude<.1 then face=Vector3.new(origin.X,receptionTop.Position.Y,origin.Z) end
if (face-receptionTop.Position).Magnitude<.1 then face=receptionTop.Position+Vector3.new(0,0,-1) end
npc:PivotTo(CFrame.lookAt(receptionTop.Position,face))
for _=1,3 do
 for _,motor in ipairs(npc:GetDescendants()) do
  if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.C1:Inverse() end
 end
end
local bounds,dimensions=npc:GetBoundingBox()
local bottom=bounds.Position.Y-dimensions.Y/2
local surfaceY=receptionTop.Position.Y+receptionTop.Size.Y/2
npc:PivotTo(npc:GetPivot()+Vector3.new(receptionTop.Position.X-bounds.Position.X,surfaceY-bottom+.02,receptionTop.Position.Z-bounds.Position.Z))
npc.Name="LobbyGuide"
npc:SetAttribute("DisplayName","Fill")
npc:SetAttribute("Placement","ReceptionTabletop")
npc:SetAttribute("ReceptionSurface",receptionTop:GetFullName())
local tableReference=Instance.new("ObjectValue") tableReference.Name="Tabletop" tableReference.Value=receptionTop tableReference.Parent=npc
local newBounds,newSize=npc:GetBoundingBox()
local gap=newBounds.Position.Y-newSize.Y/2-(receptionTop.Position.Y+receptionTop.Size.Y/2)
assert(math.abs(gap-.02)<.1,"Fill is not aligned with the reception tabletop")
local client=Instance.new("Script") client.Name="GuideInteraction" client.RunContext=Enum.RunContext.Client client.Source=__GUIDE_CLIENT_SOURCE__ client.Parent=npc
local newBounds,newSize=npc:GetBoundingBox()
local gap=newBounds.Position.Y-newSize.Y/2-(top.Position.Y+top.Size.Y/2)
assert(math.abs(gap-.02)<.08,"Guide does not touch tabletop")
assert(head.Transparency==1 and humanoid.RigType==Enum.HumanoidRigType.R6,"Headless/R6 validation failed")
local accessoryIds={}
for _,a in ipairs(applied:GetAccessories(true)) do table.insert(accessoryIds,a.AssetId) end
posePackage:Destroy() dialoguePackage:Destroy()
return {ok=true,staged=false,headless=true,rig="R6",appearanceVerified=true,userId=ownerId,shirt=description.Shirt,pants=description.Pants,accessoryIds=accessoryIds,tabletopGap=gap,tablePosition=tostring(receptionTop.Position),localGaze=true}
