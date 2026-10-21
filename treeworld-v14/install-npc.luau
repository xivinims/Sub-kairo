local Players=game:GetService('Players')
local Insert=game:GetService('InsertService')
local world=workspace.OveryardPhotoWorld
local C=require(game.ReplicatedStorage.PhotoWorldConfig)
local base=Players:GetHumanoidDescriptionFromUserIdAsync(8344738123)
-- Preserve the user's actual body package, skin and height. Replace wardrobe,
-- head and right leg with the exact items from this request.
base:SetAccessories({},true)
base.Head=107154176765760;base.Face=0;base.RightLeg=139607718
base.WidthScale=.70;base.DepthScale=.70
base.HeightScale=.90;base.HeadScale=.95
base.Shirt=135542921435071;base.Pants=93944579042140;base.GraphicTShirt=0
base.HatAccessory='18654587595';base.HairAccessory='124964364612906'
base.FaceAccessory='18557389382';base.WaistAccessory='15591115363'
base.IdleAnimation=99777856614604;base.WalkAnimation=110378518344812;base.RunAnimation=85010090740014
base.JumpAnimation=78943541517934;base.FallAnimation=87470161319119;base.ClimbAnimation=71506166040222;base.SwimAnimation=137760782158375
local npc=Players:CreateHumanoidModelFromDescriptionAsync(base,Enum.HumanoidRigType.R15)
npc.Name='CaioNew';npc.Parent=world
local hum=assert(npc:FindFirstChildOfClass('Humanoid'))
hum:BuildRigFromAttachments()
local links={{'Root','HumanoidRootPart','LowerTorso','RootRigAttachment'},
 {'Waist','LowerTorso','UpperTorso','WaistRigAttachment'},{'Neck','UpperTorso','Head','NeckRigAttachment'}}
for _,side in ipairs({'Left','Right'}) do
 table.insert(links,{side..'Shoulder','UpperTorso',side..'UpperArm',side..'ShoulderRigAttachment'})
 table.insert(links,{side..'Elbow',side..'UpperArm',side..'LowerArm',side..'ElbowRigAttachment'})
 table.insert(links,{side..'Wrist',side..'LowerArm',side..'Hand',side..'WristRigAttachment'})
 table.insert(links,{side..'Hip','LowerTorso',side..'UpperLeg',side..'HipRigAttachment'})
 table.insert(links,{side..'Knee',side..'UpperLeg',side..'LowerLeg',side..'KneeRigAttachment'})
 table.insert(links,{side..'Ankle',side..'LowerLeg',side..'Foot',side..'AnkleRigAttachment'})
end
-- Cloud assembly can return unconnected body pieces. Resolve every joint from
-- rig attachments, then attach accessories after the body is assembled.
for _,link in ipairs(links) do
 local p0=assert(npc:FindFirstChild(link[2]));local p1=assert(npc:FindFirstChild(link[3]))
 local a0=assert(p0:FindFirstChild(link[4]));local a1=assert(p1:FindFirstChild(link[4]))
 local joint
 for _,j in ipairs(npc:GetDescendants()) do if j:IsA('Motor6D') and j.Part0==p0 and j.Part1==p1 then joint=j;break end end
 if not joint then joint=Instance.new('Motor6D');joint.Name=link[1];joint.Parent=p1 end
 joint.Part0=p0;joint.Part1=p1;joint.C0=a0.CFrame;joint.C1=a1.CFrame
 p1.CFrame=p0.CFrame*a0.CFrame*a1.CFrame:Inverse()
end
-- The fetched description handles native accessory scaling. Match each exact
-- item by source ID; the attachment mapping is also verified below.
local accessories={
 {id=18654587595,name='AdventurousHat',attachment='HatAttachment',kind=Enum.AccessoryType.Hat},
 {id=18557389382,name='ThinRimmedGlasses',attachment='FaceFrontAttachment',kind=Enum.AccessoryType.Face},
 {id=124964364612906,name='BlondeRintaroHair',attachment='HairAttachment',kind=Enum.AccessoryType.Hair},
 {id=15591115363,name='PrideLanyard',attachment='WaistFrontAttachment',kind=Enum.AccessoryType.Waist},
}
for _,spec in ipairs(accessories) do
 local accessory
 for _,p in ipairs(npc:GetChildren()) do
  if p:IsA('Accessory') and not p:GetAttribute('RequestedAssetId') then
   local handle=p:FindFirstChild('Handle')
   if handle and handle:FindFirstChild(spec.attachment) then accessory=p;break end
  end
 end
 assert(accessory,'Description omitted accessory '..spec.id)
 accessory.Name=spec.name;accessory.AccessoryType=spec.kind;accessory:SetAttribute('RequestedAssetId',spec.id)
 local handle=assert(accessory:FindFirstChild('Handle'));local from=assert(handle:FindFirstChild(spec.attachment))
 local to
 for _,part in ipairs(npc:GetChildren()) do if part:IsA('BasePart') then to=part:FindFirstChild(spec.attachment);if to then break end end end
 assert(to,'Body attachment missing: '..spec.attachment)
 for _,w in ipairs(handle:GetChildren()) do if w:IsA('JointInstance') then w:Destroy() end end
 handle.CFrame=to.Parent.CFrame*to.CFrame*from.CFrame:Inverse()
 local weld=Instance.new('Weld');weld.Name='AccessoryWeld';weld.Part0=handle;weld.Part1=to.Parent
 weld.C0=from.CFrame;weld.C1=to.CFrame;weld.Parent=handle
end
for _,p in ipairs(npc:GetDescendants()) do
 if p:IsA('LuaSourceContainer') then p:Destroy()
 elseif p:IsA('BasePart') then
  p.Anchored=p.Name=='HumanoidRootPart';p.CanCollide=false;p.CanTouch=false;p.CanQuery=p.Name~='HumanoidRootPart';p.Massless=true
 end
end
local shirt=assert(npc:FindFirstChildOfClass('Shirt'));shirt.Name='AdventurerShirt'
local pants=assert(npc:FindFirstChildOfClass('Pants'));pants.Name='AdventurerPants'
-- Canonical image IDs resolved from the exact catalog shirts, never guessed.
shirt.ShirtTemplate='rbxassetid://86335294756983';pants.PantsTemplate='rbxassetid://113082643230470'
assert(npc.Head:FindFirstChildOfClass('FaceControls'),'Dynamic shy head missing')
local root=npc.HumanoidRootPart
npc.PrimaryPart=root;hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.WalkSpeed=0;hum.AutoRotate=false
npc:PivotTo(CFrame.new(C.NPC.X,C.surface(C.NPC.X,C.NPC.Z)+hum.HipHeight+root.Size.Y/2,C.NPC.Z)*CFrame.Angles(0,math.rad(135),0))
npc.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
local snapshot=base:Clone();snapshot.Name='RequestedAppearance';snapshot.Parent=npc;base:Destroy()
if not hum:FindFirstChildOfClass('Animator') then Instance.new('Animator',hum) end
for name,id in pairs({IdleAnimation=99053594862758,IdleVariation=105182203934754}) do
 local animation=Instance.new('Animation');animation.Name=name;animation.AnimationId='rbxassetid://'..id;animation.Parent=npc
end
local click=Instance.new('ClickDetector');click.Name='TalkToCaio';click.MaxActivationDistance=14;click.Parent=npc
npc:SetAttribute('AppearanceRevision','slim-caio-v14');npc:SetAttribute('AvatarBaseUserId',8344738123)
npc:SetAttribute('RightLegAsset',139607718);npc:SetAttribute('HeadAsset',107154176765760)
npc:SetAttribute('ShirtAsset',135542921435071);npc:SetAttribute('PantsAsset',93944579042140)
npc:SetAttribute('AnimationBundle',230910224826976);npc:SetAttribute('IdleCatalogAsset',99777856614604)
npc:SetAttribute('ConversationStart','ClickOnly');npc:SetAttribute('IdleReferenceResolved',true)
local old=world:FindFirstChild('Caio');if old then old:Destroy() end
npc.Name='Caio'
return {baseUserId=8344738123,width=.7,depth=.7,height=.9,head=107154176765760,accessories=#accessories}
