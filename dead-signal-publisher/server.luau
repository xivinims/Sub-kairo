local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("DeadSignalRemotes")
local getSettings = remotes:WaitForChild("GetSettings")
local saveSettings = remotes:WaitForChild("SaveSettings")
local spawnLocation = workspace:WaitForChild("LobbySpawn")
local store = DataStoreService:GetDataStore("DeadSignalLobbySettings_v1")

local DEFAULTS = {
    profileOnTap = true,
    showNames = true,
    uiMotion = true,
    leafFx = true,
    leafDensity = 0.7,
    sfxVolume = 0.8,
}

local cache = {}
local dirty = {}

local function sanitize(value)
    local out = {}
    out.profileOnTap = value.profileOnTap ~= false
    out.showNames = value.showNames ~= false
    out.uiMotion = value.uiMotion ~= false
    out.leafFx = value.leafFx ~= false
    out.leafDensity = math.clamp(tonumber(value.leafDensity) or DEFAULTS.leafDensity, 0.25, 1)
    out.sfxVolume = math.clamp(tonumber(value.sfxVolume) or DEFAULTS.sfxVolume, 0, 1)
    return out
end

local function cloneDefaults()
    return sanitize(DEFAULTS)
end

local function loadSettings(player)
    local key = "u_" .. player.UserId
    local data
    local ok = pcall(function()
        data = store:GetAsync(key)
    end)
    if not ok or type(data) ~= "table" then
        data = cloneDefaults()
    else
        data = sanitize(data)
    end
    cache[player.UserId] = data
    return data
end

local function saveUser(userId)
    if not dirty[userId] then return end
    local data = cache[userId]
    if type(data) ~= "table" then return end
    dirty[userId] = nil
    pcall(function()
        store:SetAsync("u_" .. userId, sanitize(data))
    end)
end

getSettings.OnServerInvoke = function(player)
    return cache[player.UserId] or loadSettings(player)
end

saveSettings.OnServerEvent:Connect(function(player, value)
    if type(value) ~= "table" then return end
    cache[player.UserId] = sanitize(value)
    dirty[player.UserId] = true
end)

local function setupCharacter(player, character)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not root or not humanoid then return end
    player.RespawnLocation = spawnLocation
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    humanoid.AutoRotate = true
    root.Anchored = false
    if root.Position.Y < -25 or (root.Position - spawnLocation.Position).Magnitude > 900 then
        character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 3, 0))
    end
end

local function playerAdded(player)
    task.spawn(loadSettings, player)
    player.RespawnLocation = spawnLocation
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)
    if player.Character then
        task.spawn(setupCharacter, player, player.Character)
    end
end

Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    playerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
    saveUser(player.UserId)
    cache[player.UserId] = nil
    dirty[player.UserId] = nil
end)

task.spawn(function()
    while true do
        task.wait(30)
        for userId in pairs(dirty) do
            saveUser(userId)
        end
    end
end)

pcall(function()
    local bubble = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
    if bubble then
        bubble.Enabled = true
    end
    local window = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    if window then
        window.Enabled = true
    end
end)

workspace:SetAttribute("SocialLobbyReady", true)
