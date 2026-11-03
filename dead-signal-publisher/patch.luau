-- DEAD_SIGNAL_PUBLISHER
local BUILD_ID = "dead-signal-social-lobby-v1"
local UNIVERSE_ID = 9421311218
local PLACE_ID = 118064584465155
local LOBBY_ASSET_ID = 9398475440

assert(game.GameId == UNIVERSE_ID, "DEAD SIGNAL SAFETY: wrong universe")
assert(game.PlaceId == PLACE_ID, "DEAD SIGNAL SAFETY: wrong place")

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local Terrain = Workspace.Terrain

local function safeDestroyChildren(parent)
    for _, child in ipairs(parent:GetChildren()) do
        child:Destroy()
    end
end

for _, child in ipairs(Workspace:GetChildren()) do
    if child ~= Terrain and not child:IsA("Camera") then
        child:Destroy()
    end
end
Terrain:Clear()
safeDestroyChildren(ReplicatedStorage)
safeDestroyChildren(ServerScriptService)
safeDestroyChildren(StarterGui)
safeDestroyChildren(ReplicatedFirst)
safeDestroyChildren(StarterPlayer.StarterPlayerScripts)
safeDestroyChildren(StarterPlayer.StarterCharacterScripts)

Workspace.StreamingEnabled = true
pcall(function() Workspace.StreamingMinRadius = 96 end)
pcall(function() Workspace.StreamingTargetRadius = 320 end)
Workspace.GlobalWind = Vector3.new(3.5, 0, 1.2)

Lighting.ClockTime = 15.2
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(110, 120, 108)
Lighting.OutdoorAmbient = Color3.fromRGB(145, 153, 137)
Lighting.EnvironmentDiffuseScale = 0.55
Lighting.EnvironmentSpecularScale = 0.45
Lighting.ShadowSoftness = 0.28

safeDestroyChildren(Lighting)
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "LobbyAtmosphere"
atmosphere.Density = 0.24
atmosphere.Offset = 0.05
atmosphere.Color = Color3.fromRGB(220, 230, 214)
atmosphere.Decay = Color3.fromRGB(105, 126, 105)
atmosphere.Glare = 0.08
atmosphere.Haze = 1.1
atmosphere.Parent = Lighting

local color = Instance.new("ColorCorrectionEffect")
color.Name = "LobbyColor"
color.Brightness = 0.025
color.Contrast = 0.05
color.Saturation = 0.08
color.TintColor = Color3.fromRGB(255, 248, 229)
color.Parent = Lighting

local sun = Instance.new("SunRaysEffect")
sun.Name = "LobbySun"
sun.Intensity = 0.035
sun.Spread = 0.78
sun.Parent = Lighting

local world = Instance.new("Model")
world.Name = "DeadSignalLobby"
world:SetAttribute("BuildId", BUILD_ID)
world:SetAttribute("LobbySourceAsset", LOBBY_ASSET_ID)
world.Parent = Workspace

local leafAnchors = Instance.new("Folder")
leafAnchors.Name = "LeafAnchors"
leafAnchors.Parent = world

local function part(parent, name, size, cf, color3, material, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color3
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = collide ~= false
    p.CanTouch = false
    p.CanQuery = p.CanCollide
    p.Parent = parent
    return p
end

local function stripScripts(root)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored = true
            d.CanTouch = false
        end
    end
end

local function anchorAt(position)
    local a = part(leafAnchors, "LeafDropAnchor", Vector3.new(0.5, 0.5, 0.5), CFrame.new(position), Color3.new(1,1,1), Enum.Material.SmoothPlastic, false)
    a.Transparency = 1
    a.CanQuery = false
    return a
end

local imported = false
local importedResult
local ok, loaded = pcall(function()
    return AssetService:LoadAssetAsync(LOBBY_ASSET_ID)
end)

if ok and loaded then
    stripScripts(loaded)
    loaded.Name = "ImportedLobby"
    loaded.Parent = world
    local cf, size = loaded:GetBoundingBox()
    local bottom = cf.Position.Y - size.Y * 0.5
    loaded:PivotTo(loaded:GetPivot() + Vector3.new(-cf.Position.X, -bottom, -cf.Position.Z))
    imported = true
    importedResult = {size = {size.X, size.Y, size.Z}}

    local found = 0
    for _, d in ipairs(loaded:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = string.lower(d.Name)
            if (string.find(n, "tree", 1, true) or string.find(n, "leaf", 1, true) or string.find(n, "canopy", 1, true) or string.find(n, "foliage", 1, true))
                and d.Position.Y > 5 and found < 32 then
                found += 1
                anchorAt(d.Position + Vector3.new(0, math.max(2, d.Size.Y * 0.35), 0))
            end
        end
    end
end

local function makeTree(x, z, scale)
    local tree = Instance.new("Model")
    tree.Name = "LobbyTree"
    tree.Parent = world

    local trunkH = 8.5 * scale
    part(tree, "TreeTrunk", Vector3.new(1.5 * scale, trunkH, 1.5 * scale), CFrame.new(x, trunkH * 0.5, z),
        Color3.fromRGB(102, 74, 50), Enum.Material.Wood, true)

    local canopy = Instance.new("Part")
    canopy.Name = "TreeCanopy"
    canopy.Shape = Enum.PartType.Ball
    canopy.Size = Vector3.new(8 * scale, 6.5 * scale, 8 * scale)
    canopy.CFrame = CFrame.new(x, trunkH + 2.4 * scale, z)
    canopy.Color = Color3.fromRGB(92, 146, 74)
    canopy.Material = Enum.Material.Grass
    canopy.Anchored = true
    canopy.CanCollide = false
    canopy.CanTouch = false
    canopy.CanQuery = false
    canopy.Parent = tree

    anchorAt(Vector3.new(x, trunkH + 4.7 * scale, z))
end

if not imported then
    world:SetAttribute("UsedFallback", true)

    part(world, "LobbyGround", Vector3.new(260, 2, 260), CFrame.new(0, -1, 0),
        Color3.fromRGB(102, 139, 84), Enum.Material.Grass, true)

    part(world, "StonePlaza", Vector3.new(86, 1, 86), CFrame.new(0, 0.05, 0),
        Color3.fromRGB(156, 151, 139), Enum.Material.Slate, true)

    for i = -4, 4 do
        part(world, "PathStone", Vector3.new(8, 0.4, 7), CFrame.new(0, 0.35, 45 + i * 8),
            Color3.fromRGB(143, 140, 132), Enum.Material.Slate, true)
    end

    for i = 1, 16 do
        local angle = (i / 16) * math.pi * 2
        local radius = i % 2 == 0 and 82 or 102
        makeTree(math.cos(angle) * radius, math.sin(angle) * radius, 0.9 + (i % 3) * 0.08)
    end

    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local bench = Instance.new("Model")
        bench.Name = "LobbyBench"
        bench.Parent = world
        local x, z = math.cos(angle) * 48, math.sin(angle) * 48
        local facing = CFrame.lookAt(Vector3.new(x, 1.4, z), Vector3.new(0, 1.4, 0))
        part(bench, "SeatBack", Vector3.new(8, 2.6, 0.5), facing * CFrame.new(0, 1.2, 1.1),
            Color3.fromRGB(112, 77, 51), Enum.Material.Wood, true)
        local seat = Instance.new("Seat")
        seat.Name = "LobbySeat"
        seat.Size = Vector3.new(8, 0.5, 2.3)
        seat.CFrame = facing
        seat.Color = Color3.fromRGB(126, 86, 56)
        seat.Material = Enum.Material.Wood
        seat.Anchored = true
        seat.CanCollide = true
        seat.Parent = bench
    end
else
    world:SetAttribute("UsedFallback", false)

    -- Extra perimeter trees guarantee a correct leaf effect even if the imported model
    -- has unusual tree naming.
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2
        local radius = 105 + (i % 3) * 12
        makeTree(math.cos(angle) * radius, math.sin(angle) * radius, 0.82)
    end
end

-- Invisible safety floor prevents void spawns without changing the look of the imported lobby.
local safety = part(world, "SafetyFloor", Vector3.new(420, 2, 420), CFrame.new(0, -5, 0),
    Color3.fromRGB(80, 105, 72), Enum.Material.Grass, true)
safety.Transparency = imported and 1 or 0

local spawnY = 5
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {world}
local hit = Workspace:Raycast(Vector3.new(0, 180, 0), Vector3.new(0, -400, 0), rayParams)
if hit then spawnY = hit.Position.Y + 3.5 end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "LobbySpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(0, spawnY, 0)
spawn.Transparency = 1
spawn.Anchored = true
spawn.CanCollide = true
spawn.CanTouch = false
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = Workspace

local remotes = Instance.new("Folder")
remotes.Name = "DeadSignalRemotes"
remotes.Parent = ReplicatedStorage

local getSettings = Instance.new("RemoteFunction")
getSettings.Name = "GetSettings"
getSettings.Parent = remotes

local saveSettings = Instance.new("RemoteEvent")
saveSettings.Name = "SaveSettings"
saveSettings.Parent = remotes

local server = Instance.new("Script")
server.Name = "DeadSignalServer"
server.Source = __SERVER_SOURCE__
server:SetAttribute("BuildId", BUILD_ID)
server.Parent = ServerScriptService

local client = Instance.new("LocalScript")
client.Name = "DeadSignalClient"
client.Source = __CLIENT_SOURCE__
client:SetAttribute("BuildId", BUILD_ID)
client.Parent = StarterPlayer.StarterPlayerScripts

local loading = Instance.new("LocalScript")
loading.Name = "DeadSignalLoading"
loading.Source = __LOADING_SOURCE__
loading:SetAttribute("BuildId", BUILD_ID)
loading.Parent = ReplicatedFirst

StarterPlayer.CameraMode = Enum.CameraMode.Classic
StarterPlayer.CameraMinZoomDistance = 0.5
StarterPlayer.CameraMaxZoomDistance = 24
StarterPlayer.CharacterWalkSpeed = 16
StarterPlayer.CharacterJumpPower = 50

Workspace:SetAttribute("DeadSignalBuildId", BUILD_ID)
Workspace:SetAttribute("LobbyAssetId", LOBBY_ASSET_ID)
Workspace:SetAttribute("LobbyImported", imported)

assert(#leafAnchors:GetChildren() >= 8, "Not enough leaf anchors")
assert(spawn.Position.Y > -3, "Spawn is unsafe")
assert(ServerScriptService:FindFirstChild("DeadSignalServer"), "Server script missing")
assert(StarterPlayer.StarterPlayerScripts:FindFirstChild("DeadSignalClient"), "Client script missing")
assert(ReplicatedFirst:FindFirstChild("DeadSignalLoading"), "Loading script missing")

AssetService:SavePlaceAsync({PlaceId = game.PlaceId, SaveWithoutPublish = false})

return HttpService:JSONEncode({
    ok = true,
    published = true,
    build = BUILD_ID,
    universeId = game.GameId,
    placeId = game.PlaceId,
    sourceVersion = game.PlaceVersion,
    lobbyAssetId = LOBBY_ASSET_ID,
    importedLobby = imported,
    importInfo = importedResult,
    usedFallback = not imported,
    leafAnchors = #leafAnchors:GetChildren(),
    spawnY = spawn.Position.Y,
})
