-- Two EXCLUSIVE R6 animation banks. This LocalScript lives inside each avatar.
-- "Padrao" = R6 original default movement; "Arquivos" = uploaded motions
-- plus any matching embedded KeyframeSequence. No preview/catalog buttons.
local RunService = game:GetService("RunService")
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
if humanoid.RigType ~= Enum.HumanoidRigType.R6 then return end
local animator = humanoid:WaitForChild("Animator", 10)
if not animator then warn("[R6] Animator ausente"); return end
local imported = character:WaitForChild("Animate", 10)
local library = character:WaitForChild("Animations", 10)
local uploaded = library and library:FindFirstChild("UploadedMotion")
local sequences = library and library:FindFirstChild("Emotes")

-- Only ONE locomotion controller is allowed. The uploaded scripts remain
-- preserved in the avatar, but the old Animate controller stays disabled.
if imported and imported:IsA("LocalScript") then imported.Disabled = true end
if character:GetAttribute("R6AnimationGroup") ~= "Arquivos" then
    character:SetAttribute("R6AnimationGroup", "Padrao")
end
character:SetAttribute("R6ActiveSource", "iniciando")

local positions = {
    idle = {"idle", "Animation1"}, walk = {"walk", "WalkAnim"},
    run = {"run", "RunAnim"}, jump = {"jump", "JumpAnim"},
    fall = {"fall", "FallAnim"}, climb = {"climb", "ClimbAnim"},
    sit = {"sit", "SitAnim"},
}
local defaults = {
    idle = 180435571, walk = 180426354, run = 180426354,
    jump = 125750702, fall = 180436148,
    climb = 180436334, sit = 178130996,
}
local keys = {
    idle = {"idle", "parado", "stand", "rest"},
    walk = {"walk", "andar", "walking"},
    run = {"sprint", "running", "run", "correr"},
    jump = {"jump", "pulo", "jumping"},
    fall = {"fall", "falling", "queda"},
    climb = {"climb", "escal", "climbing"},
    sit = {"sit", "sitting", "sentar"},
}
local function normalized(name)
    return string.lower(name):gsub("[^%a%d]", "")
end
local function matchScore(name, mode)
    local clean = normalized(name)
    if clean:find("r15", 1, true) then return 0 end
    -- Wallrun and wall climb are NOT regular running/climbing.
    if clean:find("wall", 1, true) then return 0 end
    local score = 0
    for _, pattern in ipairs(keys[mode] or {}) do
        local at = clean:find(pattern, 1, true)
        if at then
            score = math.max(score, at == 1 and 2 or 1)
        end
    end
    return score
end
local function uploadedAnimation(mode)
    if not uploaded then return nil end
    local best, score = nil, 0
    for _, candidate in ipairs(uploaded:GetDescendants()) do
        if candidate:IsA("Animation") then
            local found = matchScore(candidate.Name, mode)
            if found > score then best, score = candidate, found end
        end
    end
    return best
end
local function embeddedSequence(mode)
    if not sequences then return nil end
    local best, score = nil, 0
    for _, sequence in ipairs(sequences:GetChildren()) do
        if sequence:IsA("KeyframeSequence") then
            local found = matchScore(sequence.Name, mode)
            if found > score then best, score = sequence, found end
        end
    end
    return best
end
local function defaultAnimation(mode)
    local position = positions[mode]
    local container = imported and imported:FindFirstChild(position[1])
    local candidate = container and container:FindFirstChild(position[2])
    if candidate and candidate:IsA("Animation") then return candidate, false end
    local temp = Instance.new("Animation")
    temp.Name = "R6Default_" .. mode
    temp.AnimationId = "rbxassetid://" .. defaults[mode]
    return temp, true
end

local motors = {}
for _, motor in ipairs(character:GetDescendants()) do
    if motor:IsA("Motor6D") then motors[motor.Name] = motor end
end
local function resetMotors()
    for _, motor in pairs(motors) do
        if motor.Parent then motor.Transform = CFrame.identity end
    end
end
local currentTrack, currentSequence, currentMode, currentGroup
local sourceLabel, started, sequenceStart, sequenceTime = "", 0, 0, 0
local procedural = false
local elapsed = 0
local framesByJoint = {}
local sequenceDuration = 0

local function stopCurrent()
    if currentTrack then
        currentTrack:Stop(0)
        currentTrack:Destroy()
        currentTrack = nil
    end
    currentSequence = nil
    framesByJoint = {}
    sequenceDuration = 0
    procedural = false
    resetMotors()
end
local function playTrack(animation, label, temporary)
    if not animation then return false end
    local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
    if temporary then animation:Destroy() end
    if not ok then
        warn("[R6] AnimationId indisponível: " .. tostring(label) .. " " .. tostring(track))
        return false
    end
    track.Priority = Enum.AnimationPriority.Movement
    track.Looped = currentMode ~= "jump" and currentMode ~= "fall"
    currentTrack = track
    sourceLabel = label
    started = os.clock()
    track:Play(0.12, 1, 1)
    character:SetAttribute("R6ActiveSource", label)
    return true
end
local function useSequence(sequence)
    if not sequence then return false end
    local ok, keyframes = pcall(function() return sequence:GetKeyframes() end)
    if not ok or #keyframes == 0 then return false end
    table.sort(keyframes, function(a, b) return a.Time < b.Time end)
    local channels, length = {}, 0
    for _, frame in ipairs(keyframes) do
        length = math.max(length, frame.Time)
        for _, pose in ipairs(frame:GetDescendants()) do
            if pose:IsA("Pose") then
                channels[pose.Name] = channels[pose.Name] or {}
                table.insert(channels[pose.Name], {
                    time = frame.Time, cf = pose.CFrame,
                    weight = pose.Weight, ease = pose.EasingStyle,
                })
            end
        end
    end
    local usable = {}
    for _, motor in pairs(motors) do
        if motor.Part1 and channels[motor.Part1.Name] then
            usable[motor] = channels[motor.Part1.Name]
        end
    end
    if not next(usable) then return false end
    stopCurrent()
    currentSequence = sequence
    framesByJoint = usable
    sequenceDuration = length
    sequenceStart = os.clock()
    character:SetAttribute("R6ActiveSource", "keyframes:" .. sequence.Name)
    return true
end
local function startBase()
    local asset, temporary = defaultAnimation(currentMode)
    if not playTrack(asset, "padrao:" .. currentMode, temporary) then
        local fallback = Instance.new("Animation")
        fallback.AnimationId = "rbxassetid://" .. defaults[currentMode]
        playTrack(fallback, "publico:" .. currentMode, true)
    end
end
local function startMode(mode, group)
    stopCurrent() -- Always stop the former group BEFORE starting another.
    currentMode, currentGroup = mode, group
    sourceLabel = ""
    started = os.clock()
    if not mode then
        character:SetAttribute("R6ActiveSource", "emote-ou-morto")
        return
    end
    if group == "Arquivos" then
        local candidate = uploadedAnimation(mode)
        if candidate and playTrack(candidate, "arquivo:" .. candidate.Name, false) then return end
        if useSequence(embeddedSequence(mode)) then return end
    end
    startBase()
end
local function fallbackUnavailableTrack()
    if currentTrack and currentTrack.Length > 0 then return end
    if currentTrack and os.clock() - started < 2.5 then return end
    -- If a stored custom AnimationId returns Length=0, try the actual
    -- embedded KeyframeSequence next. Never claim an inaccessible ID played.
    if currentGroup == "Arquivos" and sourceLabel:sub(1, 8) == "arquivo:" then
        if useSequence(embeddedSequence(currentMode)) then return end
    end
    if sourceLabel:sub(1, 8) ~= "publico:" then
        stopCurrent()
        local fallback = Instance.new("Animation")
        fallback.AnimationId = "rbxassetid://" .. defaults[currentMode]
        if playTrack(fallback, "publico:" .. currentMode, true) then return end
    end
    -- Last resort only; this is not represented as an imported animation.
    if not currentTrack or os.clock() - started > 2.5 then
        if currentTrack then currentTrack:Stop(0); currentTrack:Destroy(); currentTrack = nil end
        procedural = true
        character:SetAttribute("R6ActiveSource", "emergencia")
    end
end
local function rawPose(dt)
    if not currentSequence then return end
    sequenceTime = os.clock() - sequenceStart
    local time = sequenceDuration > 0 and
        ((currentSequence.Loop or currentMode == "walk" or currentMode == "run" or currentMode == "idle" or currentMode == "climb") and sequenceTime % sequenceDuration or math.min(sequenceTime, sequenceDuration)) or 0
    for motor, samples in pairs(framesByJoint) do
        if motor.Parent then
            local left, right = samples[1], samples[1]
            for _, sample in ipairs(samples) do
                if sample.time <= time then left = sample
                else right = sample; break end
                right = sample
            end
            local span = right.time - left.time
            local alpha = span > 0 and math.clamp((time-left.time)/span, 0, 1) or 0
            if left.ease == Enum.PoseEasingStyle.Constant then alpha = 0 end
            local cf = left.cf:Lerp(right.cf, alpha)
            local weight = left.weight + (right.weight-left.weight)*alpha
            motor.Transform = CFrame.identity:Lerp(cf, weight)
        end
    end
end
local function emergencyPose(dt)
    elapsed += dt
    local t = elapsed
    local swing = math.sin(t * (currentMode == "run" and 12 or 7))
    local amplitude = currentMode == "run" and 0.8 or 0.5
    local arm, leg = 0, 0
    if currentMode == "walk" or currentMode == "run" or currentMode == "climb" then
        arm, leg = swing * amplitude * 0.7, swing * amplitude
    elseif currentMode == "jump" then arm, leg = -0.65, 0.2
    elseif currentMode == "fall" then arm, leg = -0.4, -0.1
    elseif currentMode == "sit" then leg = 1.1
    elseif currentMode == "idle" then arm = 0.04*math.sin(t*2) end
    local pairsToApply = {
        ["Left Shoulder"] = arm, ["Right Shoulder"] = -arm,
        ["Left Hip"] = -leg, ["Right Hip"] = leg,
    }
    for jointName, value in pairs(pairsToApply) do
        local joint = motors[jointName]
        if joint and joint.Parent then joint.Transform = CFrame.Angles(value, 0, 0) end
    end
end
local function desired()
    if humanoid.Health <= 0 or character:GetAttribute("R6EmotePlaying") then return nil end
    local state = humanoid:GetState()
    if humanoid.Sit or state == Enum.HumanoidStateType.Seated then return "sit" end
    if state == Enum.HumanoidStateType.Climbing then return "climb" end
    if state == Enum.HumanoidStateType.Jumping then return "jump" end
    if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.FallingDown then return "fall" end
    if state == Enum.HumanoidStateType.Swimming then return "walk" end
    if humanoid.MoveDirection.Magnitude > 0.06 then
        if character:GetAttribute("state") == "running" or humanoid.WalkSpeed > 20 then return "run" end
        return "walk"
    end
    return "idle"
end

local heartbeat
heartbeat = RunService.PreSimulation:Connect(function(dt)
    if not character.Parent or humanoid.Health <= 0 then
        stopCurrent()
        if heartbeat then heartbeat:Disconnect() end
        return
    end
    local mode = desired()
    local group = character:GetAttribute("R6AnimationGroup") == "Arquivos" and "Arquivos" or "Padrao"
    if mode ~= currentMode or group ~= currentGroup then
        startMode(mode, group)
    end
    if not mode then return end
    if currentSequence then rawPose(dt); return end
    if not procedural then fallbackUnavailableTrack() end
    if procedural then emergencyPose(dt)
    elseif currentTrack and currentTrack.Length > 0 then
        if not currentTrack.IsPlaying then currentTrack:Play(0.1) end
        if mode == "walk" or mode == "run" then
            currentTrack:AdjustSpeed(math.clamp(humanoid.WalkSpeed / 16, 0.7, 2))
        end
    end
end)
