local TweenService = game:GetService("TweenService")

local DoorService = {}
DoorService.__index = DoorService

function DoorService.new(powerService)
    local self = setmetatable({}, DoorService)
    self.PowerService = powerService
    self.Doors = {}
    self.Changed = Instance.new("BindableEvent")
    return self
end

function DoorService:Register(model)
    local id = model:GetAttribute("DoorId") or model.Name
    local panel = assert(model:FindFirstChild("DoorPanel", true), "DoorPanel missing for " .. id)
    assert(panel:IsA("BasePart"), "DoorPanel must be BasePart")

    local openOffset = model:GetAttribute("OpenOffset")
    if typeof(openOffset) ~= "Vector3" then openOffset = Vector3.new(0, panel.Size.Y + 0.5, 0) end

    self.Doors[id] = {
        id = id,
        model = model,
        panel = panel,
        closedCFrame = panel.CFrame,
        openCFrame = panel.CFrame + openOffset,
        duration = tonumber(model:GetAttribute("OpenDuration")) or 0.7,
        powerNodeId = model:GetAttribute("PowerNodeId"),
        locked = model:GetAttribute("Locked") == true,
        open = false,
        busy = false,
    }
    return self.Doors[id]
end

function DoorService:CanOpen(id)
    local door = self.Doors[id]
    if not door then return false, "unknown" end
    if door.locked then return false, "locked" end
    if door.powerNodeId and not self.PowerService:IsEnergized(door.powerNodeId) then
        return false, "no-power"
    end
    return true
end

function DoorService:SetLocked(id, locked)
    local door = assert(self.Doors[id], "Unknown door")
    door.locked = locked == true
    door.model:SetAttribute("Locked", door.locked)
end

function DoorService:SetOpen(id, shouldOpen, instant)
    local door = assert(self.Doors[id], "Unknown door")
    if door.busy then return false, "busy" end

    if shouldOpen then
        local ok, reason = self:CanOpen(id)
        if not ok then return false, reason end
    end

    if door.open == shouldOpen then return true end
    door.busy = true

    local target = shouldOpen and door.openCFrame or door.closedCFrame
    if instant then
        door.panel.CFrame = target
    else
        local tween = TweenService:Create(door.panel, TweenInfo.new(door.duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            CFrame = target,
        })
        tween:Play()
        tween.Completed:Wait()
    end

    door.open = shouldOpen
    door.busy = false
    door.model:SetAttribute("Open", shouldOpen)
    self.Changed:Fire(id, shouldOpen)
    return true
end

return DoorService
