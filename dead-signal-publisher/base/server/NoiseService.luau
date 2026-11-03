local NoiseService = {}
NoiseService.__index = NoiseService

function NoiseService.new()
    local self = setmetatable({}, NoiseService)
    self.Noise = Instance.new("BindableEvent")
    self.Recent = {}
    return self
end

function NoiseService:Emit(position, loudness, category, source)
    loudness = math.max(0, tonumber(loudness) or 0)
    local event = {
        position = position,
        loudness = loudness,
        category = category or "generic",
        source = source,
        time = os.clock(),
    }
    self.Recent[#self.Recent + 1] = event
    self.Noise:Fire(event)

    while #self.Recent > 30 do
        table.remove(self.Recent, 1)
    end

    return event
end

function NoiseService:GetRecent(maxAge)
    local out = {}
    local now = os.clock()
    for _, event in ipairs(self.Recent) do
        if now - event.time <= maxAge then out[#out + 1] = event end
    end
    return out
end

return NoiseService
