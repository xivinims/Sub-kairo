local Players=game:GetService('Players')
local M={}
function M.Build(def)
 local d=Instance.new('HumanoidDescription')
 d.Head=86498048;d.Face=def.male and 86487700 or 86487766
 d.Torso=def.male and 86500008 or 86499666;d.RightArm=def.male and 86500036 or 86499698;d.LeftArm=def.male and 86500054 or 86499716
 d.LeftLeg=def.male and 86500064 or 86499753;d.RightLeg=def.male and 86500078 or 86499793
 d.HairAccessory=tostring(def.hair);d.Shirt=def.shirt;d.Pants=def.pants
 d.HeightScale=def.height;d.WidthScale=def.width;d.DepthScale=.94;d.HeadScale=.98;d.BodyTypeScale=.7;d.ProportionScale=.3
 for _,key in ipairs({'HeadColor','TorsoColor','LeftArmColor','RightArmColor','LeftLegColor','RightLegColor'}) do d[key]=def.skin end
 local rig=Players:CreateHumanoidModelFromDescriptionAsync(d,Enum.HumanoidRigType.R15);d:Destroy()
 rig.Name=def.id;rig:SetAttribute('ResidentId',def.id);rig:SetAttribute('ResidentName',def.name);rig:SetAttribute('ResidentRole',def.role)
 for _,v in ipairs(rig:GetDescendants()) do
  if v:IsA('LuaSourceContainer') then v:Destroy() end
  if v:IsA('BasePart') then v.CanCollide=false;v.CanTouch=false;v.CanQuery=false end
 end
 local hum=assert(rig:FindFirstChildOfClass('Humanoid'));hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.WalkSpeed=5;hum.BreakJointsOnDeath=false
 local root=assert(rig:FindFirstChild('HumanoidRootPart'));root.Anchored=true
 assert(rig:FindFirstChildOfClass('Shirt') and rig:FindFirstChildOfClass('Pants'),'Incomplete clothes: '..def.id)
 assert(rig:FindFirstChildWhichIsA('Accessory'),'Missing hair: '..def.id)
 local face=rig.Head:FindFirstChildWhichIsA('Decal');assert(face and face.Texture~='','Missing face: '..def.id)
 local desc=hum:GetAppliedDescription();assert(desc.Torso>0 and desc.LeftArm>0 and desc.RightLeg>0,'Missing authored body');desc:Destroy()
 return rig
end

return M
