local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")

local world = workspace:FindFirstChild("DeadSignalLobby")
local spawn = workspace:FindFirstChild("LobbySpawn")
local anchors = world and world:FindFirstChild("LeafAnchors")
local remotes = ReplicatedStorage:FindFirstChild("DeadSignalRemotes")
local client = StarterPlayer.StarterPlayerScripts:FindFirstChild("DeadSignalClient")
local loading = ReplicatedFirst:FindFirstChild("DeadSignalLoading")
local server = ServerScriptService:FindFirstChild("DeadSignalServer")

local report = {
    ok = world ~= nil
        and spawn ~= nil
        and anchors ~= nil
        and #anchors:GetChildren() >= 8
        and remotes ~= nil
        and remotes:FindFirstChild("GetSettings") ~= nil
        and remotes:FindFirstChild("SaveSettings") ~= nil
        and client ~= nil
        and loading ~= nil
        and server ~= nil,
    version = game.PlaceVersion,
    build = workspace:GetAttribute("DeadSignalBuildId"),
    sourceAsset = world and world:GetAttribute("LobbySourceAsset") or nil,
    usedFallback = world and world:GetAttribute("UsedFallback") or nil,
    leafAnchors = anchors and #anchors:GetChildren() or 0,
    spawnY = spawn and spawn.Position.Y or nil,
    client = client ~= nil,
    loading = loading ~= nil,
    server = server ~= nil,
}

return HttpService:JSONEncode(report)
