local EventDirector = {}
EventDirector.__index = EventDirector

function EventDirector.new(config)
    local self = setmetatable({}, EventDirector)
    self.Config = config
    self.Queue = {}
    self.Active = nil
    self.LastByCategory = {}
    self.EventStarted = Instance.new("BindableEvent")
    self.EventFinished = Instance.new("BindableEvent")
    self.Handlers = {}
    return self
end

function EventDirector:Register(eventId, handler)
    assert(type(eventId) == "string" and eventId ~= "", "Event id required")
    assert(type(handler) == "function", "Event handler must be function")
    self.Handlers[eventId] = handler
end

function EventDirector:CanRun(category, cooldown)
    local last = self.LastByCategory[category]
    if not last then return true end
    return os.clock() - last >= (cooldown or 0)
end

function EventDirector:QueueEvent(eventId, payload, options)
    options = options or {}
    assert(self.Handlers[eventId], "Unregistered event: " .. eventId)
    if #self.Queue >= self.Config.Events.MaxQueuedEvents then
        return false, "queue-full"
    end

    self.Queue[#self.Queue + 1] = {
        id = eventId,
        payload = payload or {},
        category = options.category or "generic",
        cooldown = options.cooldown or 0,
        priority = options.priority or 0,
        earliest = os.clock() + (options.delay or 0),
    }

    table.sort(self.Queue, function(a, b)
        if a.priority == b.priority then return a.earliest < b.earliest end
        return a.priority > b.priority
    end)
    return true
end

function EventDirector:_nextRunnable()
    local now = os.clock()
    for i, item in ipairs(self.Queue) do
        if now >= item.earliest and self:CanRun(item.category, item.cooldown) then
            table.remove(self.Queue, i)
            return item
        end
    end
end

function EventDirector:Step()
    if self.Active then return end
    local item = self:_nextRunnable()
    if not item then return end

    local handler = self.Handlers[item.id]
    self.Active = item
    self.LastByCategory[item.category] = os.clock()
    self.EventStarted:Fire(item.id, item.payload)

    task.spawn(function()
        local ok, result = pcall(handler, item.payload)
        if not ok then
            warn("[DeadSignal EventDirector] event failed", item.id, result)
        end
        self.EventFinished:Fire(item.id, ok, result)
        self.Active = nil
    end)
end

function EventDirector:Start()
    if self._running then return end
    self._running = true
    task.spawn(function()
        while self._running do
            self:Step()
            task.wait(0.15)
        end
    end)
end

function EventDirector:Stop()
    self._running = false
end

return EventDirector
