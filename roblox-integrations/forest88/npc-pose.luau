local Pose={}
local function turn(base,angles)return CFrame.new(base.Position)*angles*base.Rotation end
function Pose.seat(rig)
 local torso=rig:FindFirstChild("Torso")if not torso then return end
 for _,name in ipairs({"Right Hip","Left Hip"})do local joint=torso:FindFirstChild(name)if joint then joint.C0=turn(joint:GetAttribute("OriginalC0")or joint.C0,CFrame.Angles(math.rad(88),0,0))joint:SetAttribute("SeatedC0",joint.C0)end end
 for _,name in ipairs({"Right Shoulder","Left Shoulder"})do local joint=torso:FindFirstChild(name)if joint then joint.C0=turn(joint:GetAttribute("OriginalC0")or joint.C0,CFrame.Angles(math.rad(18),0,0))joint:SetAttribute("SeatedC0",joint.C0)end end
 local neck=torso:FindFirstChild("Neck")if neck then neck:SetAttribute("SeatedC0",neck:GetAttribute("OriginalC0")or neck.C0)end
end
function Pose.look(base,localTarget)
 local horizontal=math.sqrt(localTarget.X^2+localTarget.Z^2)
 local yaw=math.clamp(math.atan2(-localTarget.X,-localTarget.Z),math.rad(-55),math.rad(55))
 local pitch=math.clamp(math.atan2(localTarget.Y,horizontal),math.rad(-14),math.rad(18))
 return turn(base,CFrame.Angles(pitch,yaw,0))
end
function Pose.wave(base,age)
 if age<0 or age>3 then return base end
 local ease=math.min(age/.55,(3-age)/.6,1) ease=math.clamp(ease,0,1) ease=ease*ease*(3-2*ease)
 local swing=math.sin(math.max(0,age-.55)*math.pi*3)*math.rad(11)*ease
 return turn(base,CFrame.Angles(math.rad(-8)*ease,0,math.rad(145)*ease+swing))
end
return Pose
