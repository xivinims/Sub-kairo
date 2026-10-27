local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local build = workspace:GetAttribute("DeadSignalBuildId")
local foundation = ReplicatedStorage:FindFirstChild("DeadSignalFoundation")
local serverRoot = ServerScriptService:FindFirstChild("DeadSignalFoundation")
local test = workspace:FindFirstChild("FoundationTestLab")
local wire = workspace:FindFirstChild("FoundationTestLab") and workspace.FoundationTestLab:FindFirstChild("TestRedCable")
local door = workspace:FindFirstChild("FoundationTestLab") and workspace.FoundationTestLab:FindFirstChild("FoundationTestDoor")

local result = {
    ok = build == "dead-signal-foundation-test-v2"
        and foundation ~= nil
        and serverRoot ~= nil
        and test ~= nil
        and wire ~= nil
        and door ~= nil
        and #CollectionService:GetTagged("DeadSignalPowerNode") == 2
        and #CollectionService:GetTagged("DeadSignalWireEndpoint") == 2
        and #CollectionService:GetTagged("DeadSignalWire") == 1
        and #CollectionService:GetTagged("DeadSignalDoor") == 1
        and #CollectionService:GetTagged("DeadSignalCheckpoint") >= 1
        and StarterPlayer.StarterPlayerScripts:FindFirstChild("DeadSignalFoundationClient") ~= nil,
    version = game.PlaceVersion,
    build = build,
    foundation = foundation ~= nil,
    serverRoot = serverRoot ~= nil,
    clientBootstrap = StarterPlayer.StarterPlayerScripts:FindFirstChild("DeadSignalFoundationClient") ~= nil,
    powerNodes = #CollectionService:GetTagged("DeadSignalPowerNode"),
    endpoints = #CollectionService:GetTagged("DeadSignalWireEndpoint"),
    wires = #CollectionService:GetTagged("DeadSignalWire"),
    doors = #CollectionService:GetTagged("DeadSignalDoor"),
    checkpoints = #CollectionService:GetTagged("DeadSignalCheckpoint"),
}

return HttpService:JSONEncode(result)
