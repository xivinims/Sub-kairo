local DebugService = {}
DebugService.__index = DebugService

function DebugService.new(config)
    local self = setmetatable({}, DebugService)
    self.Config = config
    self.Errors = {}
    self.Warnings = {}
    return self
end

function DebugService:Warn(code, message, context)
    local item = {
        code = code,
        message = message,
        context = context,
        time = os.clock(),
    }
    self.Warnings[#self.Warnings + 1] = item
    warn("[DeadSignal][" .. tostring(code) .. "]", message)
    return item
end

function DebugService:Error(code, message, context)
    local item = {
        code = code,
        message = message,
        context = context,
        time = os.clock(),
    }
    self.Errors[#self.Errors + 1] = item
    warn("[DeadSignal ERROR][" .. tostring(code) .. "]", message)
    return item
end

function DebugService:Assert(condition, code, message, context)
    if condition then return true end
    self:Error(code, message, context)
    return false
end

function DebugService:Snapshot()
    return {
        errors = table.clone(self.Errors),
        warnings = table.clone(self.Warnings),
    }
end

return DebugService
