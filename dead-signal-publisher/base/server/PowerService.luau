local PowerService = {}
PowerService.__index = PowerService

local VALID_ENDPOINT_TYPES = {
    Source = true,
    Junction = true,
    Consumer = true,
    Switch = true,
}

function PowerService.new(config)
    local self = setmetatable({}, PowerService)
    self.Config = config
    self.Nodes = {}
    self.Links = {}
    self.NodeChanged = Instance.new("BindableEvent")
    self.NetworkChanged = Instance.new("BindableEvent")
    self.LastTick = 0
    return self
end

function PowerService:RegisterNode(instance)
    local id = instance:GetAttribute("PowerNodeId") or instance.Name
    local nodeType = instance:GetAttribute("PowerNodeType") or "Junction"
    assert(VALID_ENDPOINT_TYPES[nodeType], "Invalid power node type: " .. tostring(nodeType))
    assert(not self.Nodes[id], "Duplicate power node id: " .. tostring(id))

    self.Nodes[id] = {
        id = id,
        instance = instance,
        type = nodeType,
        enabled = instance:GetAttribute("Enabled") ~= false,
        capacity = tonumber(instance:GetAttribute("Capacity")) or 100,
        demand = tonumber(instance:GetAttribute("Demand")) or 0,
        output = tonumber(instance:GetAttribute("Output")) or 0,
        energized = false,
        voltage = 0,
        overloadSince = nil,
    }
    return self.Nodes[id]
end

function PowerService:UnregisterNode(id)
    self.Nodes[id] = nil
    self.Links[id] = nil
    for from, destinations in pairs(self.Links) do
        destinations[id] = nil
        if next(destinations) == nil then self.Links[from] = nil end
    end
end

function PowerService:SetLink(a, b, connected)
    assert(self.Nodes[a] and self.Nodes[b], "Power link references unknown node")
    self.Links[a] = self.Links[a] or {}
    self.Links[b] = self.Links[b] or {}

    if connected then
        self.Links[a][b] = true
        self.Links[b][a] = true
    else
        self.Links[a][b] = nil
        self.Links[b][a] = nil
    end

    self.NetworkChanged:Fire(a, b, connected)
end

function PowerService:SetEnabled(id, enabled)
    local node = assert(self.Nodes[id], "Unknown power node")
    node.enabled = enabled == true
    node.instance:SetAttribute("Enabled", node.enabled)
end

function PowerService:_floodFromSource(sourceId, visited)
    local queue = {sourceId}
    visited[sourceId] = true
    local i = 1

    while queue[i] do
        local current = queue[i]
        i += 1
        for neighbor in pairs(self.Links[current] or {}) do
            local node = self.Nodes[neighbor]
            if node and node.enabled and not visited[neighbor] then
                visited[neighbor] = true
                queue[#queue + 1] = neighbor
            end
        end
    end
end

function PowerService:Recalculate()
    local energized = {}
    local totalOutput = 0

    for id, node in pairs(self.Nodes) do
        if node.type == "Source" and node.enabled and node.output > 0 then
            totalOutput += node.output
            self:_floodFromSource(id, energized)
        end
    end

    local totalDemand = 0
    for id, node in pairs(self.Nodes) do
        if energized[id] and node.type == "Consumer" and node.enabled then
            totalDemand += node.demand
        end
    end

    local loadRatio = totalOutput > 0 and (totalDemand / totalOutput) or math.huge
    local overloaded = loadRatio > 1.001

    for id, node in pairs(self.Nodes) do
        local before = node.energized
        node.energized = energized[id] == true and not overloaded
        node.voltage = node.energized and self.Config.Power.DefaultVoltage or 0

        node.instance:SetAttribute("Energized", node.energized)
        node.instance:SetAttribute("Voltage", node.voltage)

        if before ~= node.energized then
            self.NodeChanged:Fire(id, node.energized, node.voltage)
        end
    end

    return {
        totalOutput = totalOutput,
        totalDemand = totalDemand,
        loadRatio = loadRatio,
        overloaded = overloaded,
    }
end

function PowerService:IsEnergized(id)
    local node = self.Nodes[id]
    return node and node.energized or false
end

return PowerService
