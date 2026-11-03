local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local SaveService = {}
SaveService.__index = SaveService

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = deepCopy(v) end
    return out
end

function SaveService.new(config)
    local self = setmetatable({}, SaveService)
    self.Config = config
    self.Store = DataStoreService:GetDataStore(config.Save.StoreName)
    self.Cache = {}
    self.Dirty = {}
    self.Loaded = {}
    self.Running = false
    return self
end

function SaveService:DefaultData()
    return {
        dataVersion = self.Config.DataVersion,
        chapter = self.Config.DefaultChapter,
        checkpoint = self.Config.DefaultCheckpoint,
        objectives = {},
        flags = {},
        inventory = {},
        settings = {
            subtitles = true,
            reducedMotion = false,
            cameraShake = 0.7,
            masterVolume = 1,
            sfxVolume = 0.85,
            dialogueVolume = 1,
        },
        stats = {
            deaths = 0,
            puzzlesSolved = 0,
            playSeconds = 0,
        },
    }
end

function SaveService:Normalize(data)
    local defaults = self:DefaultData()
    if type(data) ~= "table" then return defaults end

    for k, v in pairs(defaults) do
        if data[k] == nil then
            data[k] = deepCopy(v)
        elseif type(v) == "table" and type(data[k]) == "table" then
            for sk, sv in pairs(v) do
                if data[k][sk] == nil then data[k][sk] = deepCopy(sv) end
            end
        end
    end

    data.dataVersion = self.Config.DataVersion
    return data
end

function SaveService:_withRetry(callback)
    local lastError
    for attempt = 1, self.Config.Save.RetryCount do
        local ok, result = pcall(callback)
        if ok then return true, result end
        lastError = result
        task.wait(self.Config.Save.RetryDelay * attempt)
    end
    return false, lastError
end

function SaveService:Load(player)
    local userId = player.UserId
    if self.Loaded[userId] then return self.Cache[userId] end

    local key = "u_" .. userId
    local ok, result = self:_withRetry(function()
        return self.Store:GetAsync(key)
    end)

    local data = self:Normalize(ok and result or nil)
    self.Cache[userId] = data
    self.Loaded[userId] = true
    self.Dirty[userId] = false
    return data
end

function SaveService:Get(player)
    return self.Cache[player.UserId] or self:Load(player)
end

function SaveService:Mutate(player, callback)
    local data = self:Get(player)
    callback(data)
    self.Dirty[player.UserId] = true
    return data
end

function SaveService:Save(player, force)
    local userId = player.UserId
    if not self.Loaded[userId] then return true end
    if not force and not self.Dirty[userId] then return true end

    local snapshot = deepCopy(self.Cache[userId])
    local key = "u_" .. userId
    local ok, err = self:_withRetry(function()
        self.Store:UpdateAsync(key, function()
            return snapshot
        end)
    end)

    if ok then
        self.Dirty[userId] = false
        return true
    end

    warn("[DeadSignal SaveService] save failed", userId, err)
    return false
end

function SaveService:Forget(player)
    self.Cache[player.UserId] = nil
    self.Dirty[player.UserId] = nil
    self.Loaded[player.UserId] = nil
end

function SaveService:Start()
    if self.Running then return end
    self.Running = true

    task.spawn(function()
        while self.Running do
            task.wait(self.Config.Save.AutosaveSeconds)
            for _, player in ipairs(Players:GetPlayers()) do
                self:Save(player, false)
            end
        end
    end)
end

function SaveService:Stop()
    self.Running = false
end

return SaveService
