-- Original Motor6D animation driver for the inspected Bramble rig. No external animation permissions required.
local Animation={}
local function smooth(a,b,t) t=math.clamp(t,0,1); return a+(b-a)*t*t*(3-2*t) end
function Animation.Pose(name,state,t)
    local walk=state=="Walk" or state=="Run"
    local phase=t*(state=="Run" and 10.2 or 5.4)
    local stride=walk and math.sin(phase) or 0
    local breath=math.sin(t*1.7)
    local attack=state=="Attack"
    local reach=attack and smooth(0,1,(t-0.15)/0.5) or 0
    local close=attack and smooth(0,1,(t-0.75)/0.35) or 0
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
function Animation.Hold(t)
    local lift=smooth(-2.7,-0.9,(t-0.55)/0.65)
    local approach=smooth(-5.0,-3.8,(t-0.6)/0.75)
    return CFrame.new(0,lift,approach)*CFrame.Angles(0,math.pi,0)
end
local function solve(driver)
    local resolved={[driver.rig.PrimaryPart]=true}
    for _=1,10 do
        local changed=false
        for _,r in ipairs(driver.joints) do
            local j=r.joint
            if j.Part0 and j.Part1 and resolved[j.Part0] and not resolved[j.Part1] then
                j.Part1.CFrame=j.Part0.CFrame*j.C0*j.C1:Inverse()
                resolved[j.Part1]=true; changed=true
            end
        end
        if not changed then break end
    end
end
function Animation.new(rig)
    local joints={}; local byName={}
    for _,d in ipairs(rig:GetDescendants()) do
        if d:IsA("Motor6D") then
            local r={joint=d,base=d.C0,current=CFrame.new()}
            table.insert(joints,r); byName[d.Name]=r
        end
    end
    local driver={joints=joints,byName=byName,rig=rig,arms={}}
    for _,side in ipairs({"Right","Left"}) do
        local u=byName[side.."UpperArm"]; local l=byName[side.."LowerArm"]
        local finger=byName[side.."Finger2"]
        if u and l and finger then
            local shoulder=(u.joint.Part0.CFrame*u.base).Position
            local elbow=(l.joint.Part0.CFrame*l.base).Position
            local wrist=(finger.joint.Part0.CFrame*finger.base).Position
            driver.arms[side]={upper=u,lower=l,a=(elbow-shoulder).Magnitude,b=(wrist-elbow).Magnitude,
                upperAxis=u.joint.Part1.CFrame:VectorToObjectSpace((elbow-shoulder).Unit),
                lowerAxis=l.joint.Part1.CFrame:VectorToObjectSpace((wrist-elbow).Unit)}
        end
    end
    return driver
end
local function aim(record,target,axis)
    local joint=record.joint
    local origin=(joint.Part0.CFrame*joint.C0).Position
    local delta=target-origin
    if delta.Magnitude<0.001 then return end
    local current=joint.Part1.CFrame:VectorToWorldSpace(axis).Unit
    local desired=delta.Unit
    local cross=current:Cross(desired)
    local turn=CFrame.new()
    if cross.Magnitude>0.0001 then turn=CFrame.fromAxisAngle(cross.Unit,math.acos(math.clamp(current:Dot(desired),-1,1))) end
    local rotation=turn*joint.Part1.CFrame.Rotation
    joint.C0=CFrame.new(joint.C0.Position)*joint.Part0.CFrame.Rotation:Inverse()*rotation*joint.C1.Rotation
end
function Animation.Grip(driver,t)
    if t<0.28 then return end
    local root=driver.rig:GetPivot()
    local center=driver.gripCenter or (root*Animation.Hold(t)).Position+Vector3.new(0,0.6,0)
    for side,arm in pairs(driver.arms) do
        local sign=side=="Right" and 1 or -1
        local wrist=center+root.RightVector*sign*1.15
        local shoulder=(arm.upper.joint.Part0.CFrame*arm.upper.joint.C0).Position
        local delta=wrist-shoulder
        if delta.Magnitude>0.01 then
            local a,b=arm.a,arm.b
            local distance=math.clamp(delta.Magnitude,math.abs(a-b)+0.02,a+b-0.02)
            local forward=delta.Unit
            local along=(a*a-b*b+distance*distance)/(2*distance)
            local bendHint=-root.UpVector+root.RightVector*sign*0.25
            local bend=bendHint-forward*bendHint:Dot(forward)
            bend=bend.Magnitude>0.01 and bend.Unit or root.RightVector*sign
            local elbow=shoulder+forward*along+bend*math.sqrt(math.max(0,a*a-along*along))
            aim(arm.upper,elbow,arm.upperAxis); solve(driver)
            aim(arm.lower,wrist,arm.lowerAxis); solve(driver)
        end
    end
end
function Animation.Step(driver,state,t,dt,instant)
    local alpha=instant and 1 or 1-math.exp(-dt*14)
    for _,r in ipairs(driver.joints) do
        local pose=Animation.Pose(r.joint.Name,state,t)
        r.current=r.current:Lerp(pose,alpha)
        r.joint.C0=CFrame.new(r.base.Position)*r.current*r.base.Rotation
    end
    solve(driver)
    if state=="Attack" then Animation.Grip(driver,t) end
end
return Animation
