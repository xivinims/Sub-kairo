-- Runs automatically as a LocalScript INSIDE each R6 player character.
-- Reuses the Naruto R6 Animations placed in character.Animate by the upload.
-- Imported animation IDs and imported Lua sources are never rewritten.
local RunService = game:GetService("RunService")
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
    warn("[R6Motion] Unsupported rig: " .. humanoid.RigType.Name)
    return
end

local root = character:WaitForChild("HumanoidRootPart")
local animator = humanoid:WaitForChild("Animator", 10)
if not animator then
    warn("[R6Motion] Animator missing in " .. character.Name)
    return
end

local imported = character:WaitForChild("Animate", 10)
if imported and imported:IsA("LocalScript") then
    -- Keep the complete uploaded controller in the avatar for inspection,
    -- but prevent two different scripts from playing locomotion simultaneously.
    imported.Enabled = false
end

local sources = {
    idle = {"idle", "Animation1"},
    walk = {"walk", "WalkAnim"},
    run = {"run", "RunAnim"},
    jump = {"jump", "JumpAnim"},
    fall = {"fall", "FallAnim"},
    climb = {"climb", "ClimbAnim"},
    sit = {"sit", "SitAnim"},
}
-- These public R6 defaults are only used if an uploaded asset will not load.
local publicFallbacks = {
    idle = "180435571",
    walk = "180426354",
    run = "180426354",
    jump = "125750702",
    fall = "180436148",
    climb = "180436334",
    sit = "178130996",
}
local cache = {}
local function animationFor(mode, backup)
    if not backup and imported then
        local names = sources[mode]
        local folder = names and imported:FindFirstChild(names[1])
        local asset = folder and folder:FindFirstChild(names[2])
        if asset and asset:IsA("Animation") then
            return asset
        end
    end
    local id = publicFallbacks[mode]
    if not id then return nil end
    local asset = Instance.new("Animation")
    asset.Name = "R6PublicFallback_" .. mode
    asset.AnimationId = "rbxassetid://" .. id
    return asset
end

local function trackFor(mode, backup)
    local key = mode .. (backup and "_backup" or "_original")
    if cache[key] ~= nil then return cache[key] or nil end
    local asset = animationFor(mode, backup)
    if not asset then cache[key] = false; return nil end
    local ok, track = pcall(function() return animator:LoadAnimation(asset) end)
    if backup then asset:Destroy() end
    if not ok then
        warn("[R6Motion] LoadAnimation " .. key .. ": " .. tostring(track))
        cache[key] = false
        return nil
    end
    track.Priority = Enum.AnimationPriority.Movement
    track.Looped = mode ~= "jump" and mode ~= "fall"
    cache[key] = track
    return track
end

local playing, current, started, backupPlaying = nil, nil, 0, false
local procedural = false
local motors = {}
for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("Motor6D") then motors[part.Name] = part end
end
local function setMotor(name, rotation)
    local joint = motors[name]
    if joint and joint.Parent then joint.Transform = rotation end
end
local function clearProcedural()
    if not procedural then return end
    procedural = false
    for _, joint in pairs(motors) do
        if joint.Parent then joint.Transform = CFrame.identity end
    end
end
local function stopTrack()
    if playing then playing:Stop(0.12) end
    playing = nil
end
local function playMode(mode)
    if mode == current then return end
    stopTrack()
    clearProcedural()
    current = mode
    backupPlaying = false
    started = os.clock()
    if not mode then return end
    playing = trackFor(mode, false)
    if playing then playing:Play(0.14, 1, 1) end
end
local function switchToBackup()
    if backupPlaying or not current then return end
    backupPlaying = true
    stopTrack()
    started = os.clock()
    playing = trackFor(current, true)
    if playing then playing:Play(0.12, 1, 1) end
end

-- Last-resort motion if Roblox denies an animation asset. This prevents a
-- rigid/t-pose LOCAL character without forging new asset IDs or preview UI.
local elapsed = 0
local function pose(mode, dt)
    procedural = true
    elapsed += dt
    local t = elapsed
    local leftArm, rightArm, leftLeg, rightLeg = 0, 0, 0, 0
    local torso = 0
    if mode == "walk" or mode == "run" or mode == "climb" then
        local rate = mode == "run" and 13 or 8
        if mode == "climb" then rate = 6 end
        local swing = math.sin(t * rate) * (mode == "run" and 0.85 or 0.56)
        leftLeg, rightLeg = swing, -swing
        leftArm, rightArm = -swing * 0.75, swing * 0.75
        torso = mode == "run" and -0.12 or 0
    elseif mode == "jump" then
        leftArm, rightArm = -0.65, -0.65
        leftLeg, rightLeg = 0.2, 0.2
    elseif mode == "fall" then
        leftArm, rightArm = -0.45, -0.45
        leftLeg, rightLeg = -0.08, 0.08
    elseif mode == "sit" then
        leftLeg, rightLeg = 1.15, 1.15
    elseif mode == "idle" then
        leftArm, rightArm = 0.045 * math.sin(t * 2), -0.045 * math.sin(t * 2)
    end
    setMotor("Left Shoulder", CFrame.Angles(leftArm, 0, 0))
    setMotor("Right Shoulder", CFrame.Angles(rightArm, 0, 0))
    setMotor("Left Hip", CFrame.Angles(leftLeg, 0, 0))
    setMotor("Right Hip", CFrame.Angles(rightLeg, 0, 0))
    setMotor("RootJoint", CFrame.Angles(torso, 0, 0))
end

local function desiredMode()
    if humanoid.Health <= 0 then return nil end
    if character:GetAttribute("R6EmotePlaying") then return nil end
    local state = humanoid:GetState()
    if humanoid.Sit or state == Enum.HumanoidStateType.Seated then return "sit" end
    if state == Enum.HumanoidStateType.Swimming then return "walk" end
    if state == Enum.HumanoidStateType.Climbing then return "climb" end
    if state == Enum.HumanoidStateType.Jumping then return "jump" end
    if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.FallingDown then return "fall" end
    if humanoid.MoveDirection.Magnitude > 0.06 then
        if character:GetAttribute("state") == "running" or humanoid.WalkSpeed > 20 then return "run" end
        return "walk"
    end
    return "idle"
end

local heartbeat
heartbeat = RunService.PreSimulation:Connect(function(dt)
    if not character.Parent or humanoid.Health <= 0 then
        stopTrack()
        clearProcedural()
        heartbeat:Disconnect()
        return
    end
    local mode = desiredMode()
    playMode(mode)
    if not mode then
        clearProcedural()
        return
    end
    if playing and not playing.IsPlaying then playing:Play(0.12, 1, 1) end
    local speed = 1
    if mode == "walk" or mode == "run" then speed = math.clamp(humanoid.WalkSpeed / 16, 0.7, 2) end
    if playing then playing:AdjustSpeed(speed) end
    if (not playing or playing.Length <= 0) and not backupPlaying and os.clock() - started > 2.8 then
        switchToBackup()
    end
    if not playing or (playing.Length <= 0 and os.clock() - started > 2.8) then
        pose(mode, dt)
    else
        clearProcedural()
    end
end)
