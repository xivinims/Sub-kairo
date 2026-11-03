local WireService = {}
WireService.__index = WireService

function WireService.new(config, powerService)
    local self = setmetatable({}, WireService)
    self.Config = config
    self.PowerService = powerService
    self.Endpoints = {}
    self.Wires = {}
    self.PlayerCarry = {}
    self.Changed = Instance.new("BindableEvent")
    return self
end

function WireService:RegisterEndpoint(instance)
    assert(instance:IsA("BasePart") or instance:IsA("Attachment"), "Wire endpoint must be BasePart or Attachment")
    local id = instance:GetAttribute("WireEndpointId") or instance.Name
    local powerNodeId = instance:GetAttribute("PowerNodeId")
    assert(type(id) == "string" and id ~= "", "Wire endpoint id missing")
    assert(not self.Endpoints[id], "Duplicate wire endpoint id: " .. id)

    self.Endpoints[id] = {
        id = id,
        instance = instance,
        powerNodeId = powerNodeId,
        accepts = instance:GetAttribute("Accepts") or "Any",
        occupiedBy = nil,
    }
    return self.Endpoints[id]
end

function WireService:RegisterWire(model)
    local id = model:GetAttribute("WireId") or model.Name
    assert(not self.Wires[id], "Duplicate wire id: " .. id)
    self.Wires[id] = {
        id = id,
        model = model,
        endpointA = nil,
        endpointB = nil,
        carriedBy = nil,
        maxLength = tonumber(model:GetAttribute("MaxLength")) or self.Config.Wires.DefaultCableLength,
        color = model:GetAttribute("WireColor") or "Universal",
    }
    return self.Wires[id]
end

function WireService:_position(endpoint)
    if endpoint.instance:IsA("Attachment") then return endpoint.instance.WorldPosition end
    return endpoint.instance.Position
end

function WireService:CanConnect(wireId, endpointId)
    local wire = self.Wires[wireId]
    local endpoint = self.Endpoints[endpointId]
    if not wire or not endpoint then return false, "unknown" end
    if endpoint.occupiedBy and endpoint.occupiedBy ~= wireId then return false, "occupied" end

    local accepts = endpoint.accepts
    if accepts ~= "Any" and accepts ~= wire.color then return false, "type-mismatch" end

    local otherId = wire.endpointA or wire.endpointB
    if otherId then
        local other = self.Endpoints[otherId]
        if other and (self:_position(other) - self:_position(endpoint)).Magnitude > wire.maxLength then
            return false, "too-long"
        end
    end

    return true
end

function WireService:Connect(wireId, endpointId)
    local wire = assert(self.Wires[wireId], "Unknown wire")
    local endpoint = assert(self.Endpoints[endpointId], "Unknown endpoint")
    local ok, reason = self:CanConnect(wireId, endpointId)
    if not ok then return false, reason end

    if wire.endpointA == endpointId or wire.endpointB == endpointId then
        return true
    end

    if not wire.endpointA then
        wire.endpointA = endpointId
    elseif not wire.endpointB then
        wire.endpointB = endpointId
    else
        return false, "wire-full"
    end

    endpoint.occupiedBy = wireId

    if wire.endpointA and wire.endpointB then
        local a = self.Endpoints[wire.endpointA]
        local b = self.Endpoints[wire.endpointB]
        if a.powerNodeId and b.powerNodeId then
            self.PowerService:SetLink(a.powerNodeId, b.powerNodeId, true)
            self.PowerService:Recalculate()
        end
    end

    self.Changed:Fire("connect", wireId, endpointId)
    return true
end

function WireService:Disconnect(wireId, endpointId)
    local wire = assert(self.Wires[wireId], "Unknown wire")
    if wire.endpointA ~= endpointId and wire.endpointB ~= endpointId then return false end

    if wire.endpointA and wire.endpointB then
        local a = self.Endpoints[wire.endpointA]
        local b = self.Endpoints[wire.endpointB]
        if a and b and a.powerNodeId and b.powerNodeId then
            self.PowerService:SetLink(a.powerNodeId, b.powerNodeId, false)
        end
    end

    local endpoint = self.Endpoints[endpointId]
    if endpoint then endpoint.occupiedBy = nil end

    if wire.endpointA == endpointId then wire.endpointA = nil else wire.endpointB = nil end
    self.PowerService:Recalculate()
    self.Changed:Fire("disconnect", wireId, endpointId)
    return true
end

function WireService:BeginCarry(player, wireId)
    local wire = assert(self.Wires[wireId], "Unknown wire")
    if self.PlayerCarry[player] then return false, "already-carrying" end
    if wire.carriedBy and wire.carriedBy ~= player then return false, "wire-busy" end

    wire.carriedBy = player
    self.PlayerCarry[player] = wireId
    self.Changed:Fire("carry-start", wireId, player)
    return true
end

function WireService:EndCarry(player)
    local wireId = self.PlayerCarry[player]
    if not wireId then return false end
    local wire = self.Wires[wireId]
    if wire then wire.carriedBy = nil end
    self.PlayerCarry[player] = nil
    self.Changed:Fire("carry-end", wireId, player)
    return true
end

function WireService:GetState(wireId)
    local wire = self.Wires[wireId]
    if not wire then return nil end
    return {
        id = wire.id,
        endpointA = wire.endpointA,
        endpointB = wire.endpointB,
        carriedByUserId = wire.carriedBy and wire.carriedBy.UserId or nil,
        maxLength = wire.maxLength,
        color = wire.color,
    }
end

return WireService
