-- Original Motor6D animation driver for the inspected Bramble rig. No external animation permissions required.
local Animation={}
local function smooth(a,b,t) t=math.clamp(t,0,1); return a+(b-a)*t*t*(3-2*t) end
function Animation.Pose(name,state,t)
    local walk=state=="Walk" or state=="Run"
    local phase=t*(state=="Run" and 10.2 or 5.4)
    local stride=walk and math.sin(phase) or 0
    local breath=math.sin(t*1.7)
    local attack=state=="Attack"
    local reach=attack and smooth(0,1,t/0.45) or 0
    local close=attack and smooth(0,1,(t-0.55)/0.35) or 0
    local sway=walk and math.sin(phase*0.5)*0.04 or breath*0.012
    local x,y,z=0,0,0
    if name=="RightShoulder" then z=math.rad(-72+reach*48); x=-stride*0.18-reach*0.65
    elseif name=="LeftShoulder" then z=math.rad(72-reach*48); x=stride*0.18-reach*0.65
    elseif name=="RightUpperArm" then x=-stride*0.23-reach*0.25; z=-0.08
    elseif name=="LeftUpperArm" then x=stride*0.23-reach*0.25; z=0.08
    elseif name=="RightLowerArm" then z=-0.12-close*0.7
    elseif name=="LeftLowerArm" then z=0.12+close*0.7
    elseif name=="RightHip" then x=stride*(state=="Run" and 0.52 or 0.30)
    elseif name=="LeftHip" then x=-stride*(state=="Run" and 0.52 or 0.30)
    elseif name=="RightLowerLeg" then x=walk and math.max(0,-stride)*0.5 or 0.04
    elseif name=="LeftLowerLeg" then x=walk and math.max(0,stride)*0.5 or 0.04
    elseif name=="UpperTorso" then x=(state=="Run" and -0.14 or 0)+reach*0.12; z=sway
    elseif name=="Neck" then x=breath*0.025-reach*0.16; y=math.sin(t*0.7)*0.04
    elseif name=="LowerHead" then x=0.04+breath*0.018
    elseif name=="UpperHead" then x=-0.03-breath*0.014
    elseif name:find("Finger") or name:find("Thumb") then z=(name:find("Right") and -1 or 1)*close*0.55 end
    local offset=name=="LowerTorso" and Vector3.new(0,walk and math.cos(phase*2)*0.07 or breath*0.025,0) or Vector3.zero
    return CFrame.new(offset)*CFrame.Angles(x,y,z)
end
function Animation.new(rig)
    local joints={}
    for _,d in ipairs(rig:GetDescendants()) do
        if d:IsA("Motor6D") then table.insert(joints,{joint=d,base=d.C0,current=CFrame.new()}) end
    end
    return {joints=joints,rig=rig}
end
function Animation.Step(driver,state,t,dt,instant)
    local alpha=instant and 1 or 1-math.exp(-dt*12)
    for _,r in ipairs(driver.joints) do
        local pose=Animation.Pose(r.joint.Name,state,t)
        r.current=r.current:Lerp(pose,alpha)
        -- Rotate in the parent-part basis, preserving the source bind orientation.
        r.joint.C0=CFrame.new(r.base.Position)*r.current*r.base.Rotation
    end
    if state=="Attack" then Animation.Grip(driver,t,alpha) end
end
local function aim(joint,target,sign,alpha)
    if not joint or not joint.Part0 or not joint.Part1 then return end
    local origin=(joint.Part0.CFrame*joint.C0).Position
    local direction=target-origin
    if direction.Magnitude<0.01 then return end
    local current=joint.Part1.CFrame.RightVector*sign
    local desired=direction.Unit
    local cross=current:Cross(desired)
    local dot=math.clamp(current:Dot(desired),-1,1)
    local turn=cross.Magnitude>0.0001 and CFrame.fromAxisAngle(cross.Unit,math.acos(dot)) or CFrame.new()
    local rotation=turn*joint.Part1.CFrame.Rotation
    local localRotation=joint.Part0.CFrame.Rotation:Inverse()*rotation*joint.C1.Rotation
    local goal=CFrame.new(joint.C0.Position)*localRotation
    joint.C0=joint.C0:Lerp(goal,alpha)
end
function Animation.Grip(driver,t,alpha)
    if t<0.25 then return end
    local root=driver.rig:GetPivot()
    for _,side in ipairs({"Right","Left"}) do
        local upper,lower
        for _,r in ipairs(driver.joints) do
            if r.joint.Name==side.."UpperArm" then upper=r.joint end
            if r.joint.Name==side.."LowerArm" then lower=r.joint end
        end
        if upper and lower and upper.Part0 and lower.Part0 then
            local sign=side=="Right" and 1 or -1
            local wrist=(root*CFrame.new(sign*1.1,0.7,-5.4)).Position
            local shoulder=(upper.Part0.CFrame*upper.C0).Position
            local a=3.1; local b=3.0
            local delta=wrist-shoulder
            local distance=math.clamp(delta.Magnitude,0.1,a+b-0.02)
            local forward=delta.Unit
            local along=(a*a-b*b+distance*distance)/(2*distance)
            local down=Vector3.new(0,-1,0)
            local bend=(down-forward*down:Dot(forward)).Unit
            local elbow=shoulder+forward*along+bend*math.sqrt(math.max(0,a*a-along*along))
            aim(upper,elbow,sign,alpha)
            aim(lower,wrist,sign,alpha)
        end
    end
end
return Animation
