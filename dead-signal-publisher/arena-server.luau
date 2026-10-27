local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local rig=workspace:WaitForChild("Bramble")
local root=rig.PrimaryPart
local animation=require(RS.ArenaAnimation)
local remote=RS.ArenaControl
local driver=animation.new(rig)
local mode="Idle"
local elapsed=0
local heading=root.CFrame.Rotation
local baseY=root.Position.Y
local position=root.Position
local patrolIndex=1
local points={Vector3.new(-20,baseY,-18),Vector3.new(20,baseY,-18),Vector3.new(20,baseY,18),Vector3.new(-20,baseY,18)}
local cooldowns={}
local attack
local attackCooldown=0
local pendingTarget
local function state(name)
    if rig:GetAttribute("State")~=name then rig:SetAttribute("State",name); rig:SetAttribute("StateSince",workspace:GetServerTimeNow()) end
end
local function nearest()
    local best,distance=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        local char=p.Character
        local h=char and char:FindFirstChildOfClass("Humanoid")
        local r=char and char:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health>0 and not r.Anchored then
            local d=(r.Position-position).Magnitude
            if d<distance then best=p; distance=d end
        end
    end
    return best,distance
end
local function release(kill)
    if not attack then return end
    local record=attack; attack=nil
    if record.root.Parent then
        record.root.Anchored=record.anchored
        record.root.AssemblyLinearVelocity=Vector3.zero
        record.root.AssemblyAngularVelocity=Vector3.zero
    end
    if record.hum.Parent then
        record.hum.AutoRotate=record.autoRotate
        record.hum.WalkSpeed=record.speed
        record.hum.JumpPower=record.jump
        record.hum.JumpHeight=record.jumpHeight
        if kill then record.hum:TakeDamage(record.hum.MaxHealth) end
    end
    if record.player.Parent then record.player:SetAttribute("BrambleCaptured",false) end
    rig:SetAttribute("CapturedUserId",nil)
    attackCooldown=os.clock()+3
    mode="Idle"; state("Idle")
end
local function grab(player)
    if attack or os.clock()<attackCooldown then return end
    local char=player and player.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local r=char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not r or hum.Health<=0 or (r.Position-position).Magnitude>13 then return end
    attack={player=player,hum=hum,root=r,at=os.clock(),from=r.CFrame,anchored=r.Anchored,autoRotate=hum.AutoRotate,speed=hum.WalkSpeed,jump=hum.JumpPower,jumpHeight=hum.JumpHeight}
    hum.AutoRotate=false; hum.WalkSpeed=0; hum.JumpPower=0; hum.JumpHeight=0; r.Anchored=true
    player:SetAttribute("BrambleCaptured",true); rig:SetAttribute("CapturedUserId",player.UserId)
    state("Attack")
end
local function moveToward(target,speed,dt)
    local delta=Vector3.new(target.X-position.X,0,target.Z-position.Z)
    if delta.Magnitude<0.15 then return true end
    heading=heading:Lerp(CFrame.lookAt(Vector3.zero,delta.Unit).Rotation,1-math.exp(-dt*8))
    position+=delta.Unit*math.min(speed*dt,delta.Magnitude)
    position=Vector3.new(math.clamp(position.X,-60,60),baseY,math.clamp(position.Z,-60,60))
    rig:PivotTo(CFrame.new(position)*heading)
    return delta.Magnitude<1
end
remote.OnServerEvent:Connect(function(player,requested)
    if requested~="Idle" and requested~="Walk" and requested~="Run" and requested~="Attack" then return end
    if os.clock()-(cooldowns[player] or 0)<0.5 then return end
    cooldowns[player]=os.clock()
    local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not r or (r.Position-position).Magnitude>140 then return end
    release(false)
    if requested=="Attack" then pendingTarget=player; mode="AttackApproach"; state("Run")
    else pendingTarget=nil; mode=requested; state(requested) end
end)
Players.PlayerRemoving:Connect(function(p)
    cooldowns[p]=nil
    if attack and attack.player==p then release(false) end
    if pendingTarget==p then pendingTarget=nil; mode="Idle"; state("Idle") end
end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        if attack and attack.player==p then release(false) end
        local hum=char:WaitForChild("Humanoid")
        hum.WalkSpeed=18
    end)
end)
state("Idle")
animation.Step(driver,"Idle",0,0,true)
local budget=0
RunService.Heartbeat:Connect(function(dt)
    budget+=dt
    if budget<1/30 then return end
    dt=math.min(budget,0.12); budget=0; elapsed+=dt
    if attack then
        local t=os.clock()-attack.at
        if not attack.root.Parent or attack.hum.Health<=0 then release(false)
        else
            -- Both hands close around the torso; the avatar is raised, held, then defeated without gore.
            local hold=rig:GetPivot()*CFrame.new(0,0.7,-5.4)*CFrame.Angles(0,math.pi,0)
            attack.root.CFrame=attack.from:Lerp(hold,math.clamp((t-0.3)/0.7,0,1))
            animation.Step(driver,"Attack",t,dt)
            if t>=2.4 then release(true) end
        end
        return
    end
    if mode=="Walk" then
        state("Walk")
        if moveToward(points[patrolIndex],7,dt) then patrolIndex=patrolIndex%#points+1 end
    elseif mode=="Run" or mode=="AttackApproach" then
        local target=mode=="AttackApproach" and pendingTarget or nearest()
        local char=target and target.Character
        local r=char and char:FindFirstChild("HumanoidRootPart")
        local h=char and char:FindFirstChildOfClass("Humanoid")
        if r and h and h.Health>0 then
            state("Run")
            local distance=(Vector3.new(r.Position.X,baseY,r.Position.Z)-position).Magnitude
            if distance<7 then grab(target) else moveToward(r.Position,24,dt) end
        else mode="Idle"; state("Idle") end
    else state("Idle") end
    animation.Step(driver,rig:GetAttribute("State"),elapsed,dt)
end)
