local RS=game:GetService('ReplicatedStorage')
local runtime=RS.LivingForest
local world=workspace.OveryardPhotoWorld
local C=require(RS.PhotoWorldConfig)
local Insert=game:GetService('InsertService')
local V,CF=Vector3.new,CFrame.new
-- Keep the requested inventory's actual UI and slot design; replace its demo
-- tool controller with a replicated, authoritative fruit-stack adapter.
local raw=Insert:LoadAsset(73852738603629)
local gui=assert(raw:FindFirstChildWhichIsA('ScreenGui',true))
local controller=assert(gui:FindFirstChild('InventoryController'))
local template=assert(controller:FindFirstChild('toolButton')):Clone();template.Name='InventorySlotTemplate';template.Parent=runtime
gui.Parent=nil;raw:Destroy()
for _,p in ipairs(gui:GetDescendants())do if p:IsA('LuaSourceContainer')then p:Destroy()end end
gui.Name='Custom Inventory';gui:SetAttribute('SourceAssetId',73852738603629);gui.ResetOnSpawn=false
local old=game.StarterGui:FindFirstChild(gui.Name);if old then old:Destroy()end;gui.Parent=game.StarterGui
-- Keep the requested dialogue's response artwork, and build a real R15 rig.
raw=Insert:LoadAsset(74899630735614)
local dialogGui=raw:FindFirstChild('dialog',true)
if dialogGui then local response=dialogGui:FindFirstChild('template',true);if response then local copy=response:Clone();copy.Name='DialogueChoiceTemplate';copy.Parent=runtime end end
raw:Destroy()
local desc=Instance.new('HumanoidDescription');desc.RightLeg=139607718
local skin=Color3.fromRGB(210,169,129)
desc.HeadColor=skin;desc.LeftArmColor=skin;desc.RightArmColor=skin;desc.TorsoColor=Color3.fromRGB(27,71,39);desc.LeftLegColor=Color3.fromRGB(108,88,64);desc.RightLegColor=desc.LeftLegColor
local npc=game.Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15)
desc:Destroy();npc.Name='Caio'
for _,p in ipairs(npc:GetDescendants())do
 if p:IsA('LuaSourceContainer')or p:IsA('Shirt')or p:IsA('Pants')or p:IsA('ShirtGraphic')or p:IsA('Decal')or p:IsA('Motor6D')then p:Destroy()
 elseif p:IsA('BasePart')then p.Anchored=p.Name=='HumanoidRootPart';p.CanCollide=false;p.CanTouch=false;p.Massless=true end
end
-- Cloud-created R15 characters currently arrive with all R15 attachments but no
-- Motor6D joints. Build the canonical 15-joint chain directly from the paired
-- RigAttachments so animation and gaze offsets work exactly like a normal R15.
local function motor(name,p0Name,p1Name,attachmentName)
 local p0=assert(npc:FindFirstChild(p0Name),p0Name)
 local p1=assert(npc:FindFirstChild(p1Name),p1Name)
 local a0=assert(p0:FindFirstChild(attachmentName),p0Name..'.'..attachmentName)
 local a1=assert(p1:FindFirstChild(attachmentName),p1Name..'.'..attachmentName)
 -- Re-align Part1 from the attachment pair before joining it. This is important
 -- for the asymmetrical Korblox right leg, whose artist-intent attachment
 -- positions differ from the default R15 leg.
 p1.CFrame=p0.CFrame*a0.CFrame*a1.CFrame:Inverse()
 local m=Instance.new('Motor6D')
 m.Name=name;m.Part0=p0;m.Part1=p1;m.C0=a0.CFrame;m.C1=a1.CFrame;m.Parent=p0
 return m
end
motor('Root','HumanoidRootPart','LowerTorso','RootRigAttachment')
motor('Waist','LowerTorso','UpperTorso','WaistRigAttachment')
motor('Neck','UpperTorso','Head','NeckRigAttachment')
motor('LeftShoulder','UpperTorso','LeftUpperArm','LeftShoulderRigAttachment')
motor('LeftElbow','LeftUpperArm','LeftLowerArm','LeftElbowRigAttachment')
motor('LeftWrist','LeftLowerArm','LeftHand','LeftWristRigAttachment')
motor('RightShoulder','UpperTorso','RightUpperArm','RightShoulderRigAttachment')
motor('RightElbow','RightUpperArm','RightLowerArm','RightElbowRigAttachment')
motor('RightWrist','RightLowerArm','RightHand','RightWristRigAttachment')
motor('LeftHip','LowerTorso','LeftUpperLeg','LeftHipRigAttachment')
motor('LeftKnee','LeftUpperLeg','LeftLowerLeg','LeftKneeRigAttachment')
motor('LeftAnkle','LeftLowerLeg','LeftFoot','LeftAnkleRigAttachment')
motor('RightHip','LowerTorso','RightUpperLeg','RightHipRigAttachment')
motor('RightKnee','RightUpperLeg','RightLowerLeg','RightKneeRigAttachment')
motor('RightAnkle','RightLowerLeg','RightFoot','RightAnkleRigAttachment')
local shirt=Instance.new('Shirt');shirt.Name='ExactAdventurerShirt';shirt.ShirtTemplate='rbxassetid://134896954466438';shirt.Parent=npc
local pants=Instance.new('Pants');pants.Name='ExactAdventurerPants';pants.PantsTemplate='rbxassetid://139899689316791';pants.Parent=npc
local head=npc.Head;local root=npc.HumanoidRootPart;local hum=npc.Humanoid
local face=Instance.new('Decal');face.Name='Expression';face.Face=Enum.NormalId.Front;face.Texture=require(runtime.DialogueData).Faces.smile;face.Parent=head
npc.PrimaryPart=root;hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.WalkSpeed=0;hum.AutoRotate=false
-- Ground against the actual terrain and the actual lowest body point. Korblox
-- changes the right-leg proportions, so Humanoid.HipHeight alone can visibly
-- float the rig even when the root math looks valid.
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.Terrain}
local hit=workspace:Raycast(V(C.NPC.X,512,C.NPC.Z),V(0,-1024,0),params)
assert(hit,'Missing terrain below Caio')
local boxCF,boxSize=npc:GetBoundingBox()
local pivot=npc:GetPivot()
local bottom=boxCF.Position.Y-boxSize.Y/2
local pivotToBottom=pivot.Position.Y-bottom
npc:PivotTo(CF(C.NPC.X,hit.Position.Y+pivotToBottom+.08,C.NPC.Z)*CFrame.Angles(0,math.rad(135),0))
npc.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
local oldNPC=world:FindFirstChild('Caio');if oldNPC then oldNPC:Destroy()end;npc.Parent=world
if not hum:FindFirstChildOfClass('Animator')then Instance.new('Animator',hum)end
local idle=Instance.new('Animation');idle.Name='IdleAnimation';idle.AnimationId='rbxassetid://105149630069175';idle.Parent=npc
local idle2=Instance.new('Animation');idle2.Name='IdleVariation';idle2.AnimationId='rbxassetid://129461181849095';idle2.Parent=npc
-- Play the requested Roblox idle on the server so every client sees the same
-- natural base pose. Dialogue/head tracking only offsets Motor6D.C0 locally,
-- while Animator writes Transform, so both layers can coexist.
local idleServer=Instance.new('Script');idleServer.Name='CaioIdleServer'
idleServer.Source=[=[
local npc=script.Parent
local hum=npc:WaitForChild('Humanoid')
local animator=hum:FindFirstChildOfClass('Animator')or Instance.new('Animator',hum)
local main=npc:WaitForChild('IdleAnimation')
local variation=npc:WaitForChild('IdleVariation')
local current
local function play(anim,weight,fade)
 local ok,track=pcall(function()return animator:LoadAnimation(anim)end)
 if not ok or not track then return nil end
 track.Priority=Enum.AnimationPriority.Idle
 track.Looped=true
 pcall(function()track:Play(fade or .25,weight or 1,1)end)
 return track
end
current=play(main,1,.2)
task.spawn(function()
 while npc.Parent do
  task.wait(math.random(14,24))
  if not npc.Parent then break end
  local alt=play(variation,.55,.35)
  if alt then
   task.wait(math.random(3,5))
   pcall(function()alt:Stop(.45)end)
  end
 end
end)
]=]
idleServer.Parent=npc
npc:SetAttribute('IdleReferenceResolved',true);npc:SetAttribute('IdleCatalogAsset',82585639490423)
npc:SetAttribute('IdleReferenceURL','https://www.roblox.com/share?code=89e12c0c38433a4e9aa68451fda0c346&type=AvatarItemDetails')
npc:SetAttribute('ExactShirtImage',134896954466438);npc:SetAttribute('ExactPantsImage',139899689316791);npc:SetAttribute('RightLegAsset',139607718)
npc:SetAttribute('DialogueSourceAssetId',74899630735614);npc:SetAttribute('FacePackAssetId',6557969904);npc:SetAttribute('FeedbackAssetId',125374377423034)
local prompt=Instance.new('ProximityPrompt');prompt.Name='TalkToCaio';prompt.ActionText='Conversar';prompt.ObjectText='Caio';prompt.HoldDuration=0;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Parent=root
-- Quiet licensed Roblox ambience; these IDs were used and preloaded in v91.
local sounds=Instance.new('Folder');sounds.Name='Sounds';sounds.Parent=runtime
for name,id in pairs({Wind=9114518779,Forest=9116971475,River=9120552550})do
 local s=Instance.new('Sound');s.Name=name;s.SoundId='rbxassetid://'..id;s.Volume=.05;s.Looped=true;s.Parent=sounds
end
runtime:SetAttribute('WindAssetId',11946229834)
return {ok=true,npcParts=#npc:GetDescendants(),inventoryAsset=73852738603629,dialogueAsset=74899630735614}
