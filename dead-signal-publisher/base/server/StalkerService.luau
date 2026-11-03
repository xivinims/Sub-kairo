local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local StalkerService = {}
StalkerService.__index = StalkerService

local STATES = {
    Dormant = true,
    Observe = true,
    Patrol = true,
    Investigate = true,
    Search = true,
    Chase = true,
    Cooldown = true,
}

function StalkerService.new(config)
    local self = setmetatable({}, StalkerService)
    self.Config = config
    self.Model = nil
    self.Humanoid = nil
    self.Root = nil
    self.State = "Dormant"
    self.Target = nil
    self.LastSeenPosition = nil
    self.LastSeenAt = 0
    self.LastRepath = 0
    self.SearchStarted = 0
    self.Enabled = false
    self.PatrolPoints = {}
    self.PatrolIndex = 1
    self.StateChanged = Instance.new("BindableEvent")
    return self
end

function StalkerService:BindModel(model)
    self.Model = model
    self.Humanoid = assert(model:FindFirstChildOfClass("Humanoid"), "Stalker humanoid missing")
    self.Root = assert(model:FindFirstChild("HumanoidRootPart"), "Stalker root missing")
    self.Enabled = true
    pcall(function() self.Root:SetNetworkOwner(nil) end)
    self:SetState("Dormant")
end

function StalkerService:SetPatrolPoints(points)
    self.PatrolPoints = points or {}
    self.PatrolIndex = 1
end

function StalkerService:SetState(state)
    assert(STATES[state], "Invalid stalker state")
    if self.State == state then return end
    local old = self.State
    self.State = state

    if self.Humanoid then
        if state == "Patrol" then self.Humanoid.WalkSpeed = self.Config.Stalker.MoveSpeedPatrol end
        if state == "Investigate" or state == "Search" then self.Humanoid.WalkSpeed = self.Config.Stalker.MoveSpeedInvestigate end
        if state == "Chase" then self.Humanoid.WalkSpeed = self.Config.Stalker.MoveSpeedChase end
        if state == "Dormant" or state == "Observe" or state == "Cooldown" then self.Humanoid.WalkSpeed = 0 end
    end

    if state == "Search" then self.SearchStarted = os.clock() end
    self.StateChanged:Fire(old, state)
end

function StalkerService:_lineOfSight(targetRoot)
    if not self.Root or not targetRoot then return false end
    local delta = targetRoot.Position - self.Root.Position
    if delta.Magnitude > self.Config.Stalker.SightRange then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {self.Model}
    local hit = Workspace:Raycast(self.Root.Position + Vector3.new(0, 2, 0), targetRoot.Position - (self.Root.Position + Vector3.new(0, 2, 0)), params)
    return not hit or hit.Instance:IsDescendantOf(targetRoot.Parent)
end

function StalkerService:_nearestVisiblePlayer()
    local best, bestDistance
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if player:GetAttribute("DeadSignalPlaying") and not player:GetAttribute("DeadSignalPaused") and humanoid and humanoid.Health > 0 and root and self:_lineOfSight(root) then
            local distance = (root.Position - self.Root.Position).Magnitude
            if not bestDistance or distance < bestDistance then
                best, bestDistance = player, distance
            end
        end
    end
    return best, bestDistance
end

function StalkerService:_moveTo(position)
    if not self.Root or not self.Humanoid then return end
    if os.clock() - self.LastRepath < self.Config.Stalker.RepathInterval then return end
    self.LastRepath = os.clock()

    local path = PathfindingService:CreatePath({
        AgentRadius = 1.6,
        AgentHeight = 11,
        AgentCanJump = false,
        WaypointSpacing = 6,
    })

    local ok = pcall(function()
        path:ComputeAsync(self.Root.Position, position)
    end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        self.Humanoid:MoveTo(position)
        return
    end

    local waypoints = path:GetWaypoints()
    local nextWaypoint = waypoints[math.min(2, #waypoints)]
    if nextWaypoint then
        if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
            self.Humanoid.Jump = true
        end
        self.Humanoid:MoveTo(nextWaypoint.Position)
    end
end

function StalkerService:Activate(mode)
    if not self.Model then return false end
    self.Enabled = true
    self:SetState(mode or "Patrol")
    return true
end

function StalkerService:Deactivate()
    self.Target = nil
    self.Enabled = false
    self:SetState("Dormant")
end

function StalkerService:Investigate(position)
    if not self.Enabled or self.State == "Observe" or self.State == "Chase" then return end
    self.LastSeenPosition = position
    self:SetState("Investigate")
end

function StalkerService:Step()
    if not self.Enabled or not self.Model or not self.Root then return end

    if self.State == "Observe" or self.State == "Cooldown" or self.State == "Dormant" then return end
    local active=false
    for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute("DeadSignalPlaying") and not p:GetAttribute("DeadSignalPaused") then active=true; break end end
    if not active then if self.Humanoid then self.Humanoid:MoveTo(self.Root.Position) end; return end
    local visible = self:_nearestVisiblePlayer()
    if visible then
        self.Target = visible
        local targetRoot = visible.Character and visible.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            self.LastSeenPosition = targetRoot.Position
            self.LastSeenAt = os.clock()
            if (targetRoot.Position - self.Root.Position).Magnitude <= self.Config.Stalker.ChaseRange then
                self:SetState("Chase")
                self:_moveTo(targetRoot.Position)
                return
            end
        end
    end

    if self.State == "Chase" then
        if os.clock() - self.LastSeenAt > self.Config.Stalker.LoseSightGrace then
            self:SetState("Search")
        elseif self.LastSeenPosition then
            self:_moveTo(self.LastSeenPosition)
        end
    elseif self.State == "Investigate" then
        if self.LastSeenPosition then
            self:_moveTo(self.LastSeenPosition)
            if (self.Root.Position - self.LastSeenPosition).Magnitude < 5 then
                self:SetState("Search")
            end
        end
    elseif self.State == "Search" then
        if os.clock() - self.SearchStarted > self.Config.Stalker.SearchDuration then
            self.Target = nil
            self:SetState("Patrol")
        elseif self.LastSeenPosition then
            local offset = Vector3.new(math.sin(os.clock()) * 7, 0, math.cos(os.clock() * 0.7) * 7)
            self:_moveTo(self.LastSeenPosition + offset)
        end
    elseif self.State == "Patrol" and #self.PatrolPoints > 0 then
        local point = self.PatrolPoints[self.PatrolIndex]
        local position = point:IsA("BasePart") and point.Position or point
        self:_moveTo(position)
        if (self.Root.Position - position).Magnitude < 5 then
            self.PatrolIndex = self.PatrolIndex % #self.PatrolPoints + 1
        end
    end
end

function StalkerService:Start()
    if self._running then return end
    self._running = true
    task.spawn(function()
        while self._running do
            self:Step()
            task.wait(self.Config.Stalker.ThinkRate)
        end
    end)
end

function StalkerService:Stop()
    self._running = false
end

return StalkerService

