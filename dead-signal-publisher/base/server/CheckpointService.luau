local CollectionService = game:GetService("CollectionService")

local CheckpointService = {}
CheckpointService.__index = CheckpointService

function CheckpointService.new(saveService)
    local self = setmetatable({}, CheckpointService)
    self.SaveService = saveService
    self.Checkpoints = {}
    self.Changed = Instance.new("BindableEvent")
    return self
end

function CheckpointService:Register(part)
    assert(part:IsA("BasePart"), "Checkpoint must be a BasePart")
    local id = part:GetAttribute("CheckpointId") or part.Name
    assert(type(id) == "string" and id ~= "", "Checkpoint id missing")
    self.Checkpoints[id] = part
    return id
end

function CheckpointService:Scan()
    table.clear(self.Checkpoints)
    for _, instance in ipairs(CollectionService:GetTagged("DeadSignalCheckpoint")) do
        if instance:IsA("BasePart") then
            self:Register(instance)
        end
    end
end

function CheckpointService:Get(id)
    return self.Checkpoints[id]
end

function CheckpointService:Set(player, id)
    local checkpoint = assert(self.Checkpoints[id], "Unknown checkpoint: " .. tostring(id))
    self.SaveService:Mutate(player, function(data)
        data.checkpoint = id
    end)
    self.Changed:Fire(player, id, checkpoint)
    return checkpoint
end

function CheckpointService:RespawnCharacter(player, character)
    local data = self.SaveService:Get(player)
    local checkpoint = self.Checkpoints[data.checkpoint]
    if not checkpoint then
        checkpoint = self.Checkpoints[next(self.Checkpoints)]
    end
    if not checkpoint or not character then return false end

    local root = character:WaitForChild("HumanoidRootPart", 8)
    if not root then return false end

    character:PivotTo(checkpoint.CFrame + Vector3.new(0, 3.5, 0))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

return CheckpointService
