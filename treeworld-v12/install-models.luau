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
desc:Destroy();npc.Name='Caio';npc.Humanoid:BuildRigFromAttachments()
for _,p in ipairs(npc:GetDescendants())do
 if p:IsA('LuaSourceContainer')or p:IsA('Shirt')or p:IsA('Pants')or p:IsA('ShirtGraphic')or p:IsA('Decal')then p:Destroy()
 elseif p:IsA('BasePart')then p.Anchored=p.Name=='HumanoidRootPart';p.CanCollide=false;p.CanTouch=false;p.Massless=true end
end
local shirt=Instance.new('Shirt');shirt.Name='ExactAdventurerShirt';shirt.ShirtTemplate='rbxassetid://134896954466438';shirt.Parent=npc
local pants=Instance.new('Pants');pants.Name='ExactAdventurerPants';pants.PantsTemplate='rbxassetid://139899689316791';pants.Parent=npc
local head=npc.Head;local root=npc.HumanoidRootPart;local hum=npc.Humanoid
local face=Instance.new('Decal');face.Name='Expression';face.Face=Enum.NormalId.Front;face.Texture=require(runtime.DialogueData).Faces.smile;face.Parent=head
npc.PrimaryPart=root;hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.WalkSpeed=0;hum.AutoRotate=false
npc:PivotTo(CF(C.NPC.X,C.surface(C.NPC.X,C.NPC.Z)+hum.HipHeight+root.Size.Y/2,C.NPC.Z)*CFrame.Angles(0,math.rad(135),0))
npc.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
local oldNPC=world:FindFirstChild('Caio');if oldNPC then oldNPC:Destroy()end;npc.Parent=world
if not hum:FindFirstChildOfClass('Animator')then Instance.new('Animator',hum)end
local idle=Instance.new('Animation');idle.Name='IdleAnimation';idle.AnimationId='rbxassetid://105149630069175';idle.Parent=npc
local idle2=Instance.new('Animation');idle2.Name='IdleVariation';idle2.AnimationId='rbxassetid://129461181849095';idle2.Parent=npc
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
