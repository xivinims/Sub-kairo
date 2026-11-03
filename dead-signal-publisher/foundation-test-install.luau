local BUILD_ID = "dead-signal-foundation-test-v2"
local UNIVERSE_ID = 9421311218
local PLACE_ID = 118064584465155

assert(game.GameId == UNIVERSE_ID, "DEAD SIGNAL SAFETY: wrong universe")
assert(game.PlaceId == PLACE_ID, "DEAD SIGNAL SAFETY: wrong place")

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")

local function clear(parent)
    for _, child in ipairs(parent:GetChildren()) do
        child:Destroy()
    end
end

for _, child in ipairs(Workspace:GetChildren()) do
    if not child:IsA("Camera") and child ~= Workspace.Terrain then child:Destroy() end
end
Workspace.Terrain:Clear()
clear(ReplicatedStorage)
clear(ReplicatedFirst)
clear(ServerScriptService)
clear(StarterGui)
clear(StarterPlayer.StarterPlayerScripts)
clear(StarterPlayer.StarterCharacterScripts)
clear(Lighting)

Workspace.StreamingEnabled = true
pcall(function() Workspace.StreamingMinRadius = 96 end)
pcall(function() Workspace.StreamingTargetRadius = 256 end)
Workspace.GlobalWind = Vector3.zero

Lighting.ClockTime = 1.5
Lighting.Brightness = 1.25
Lighting.Ambient = Color3.fromRGB(44, 48, 50)
Lighting.OutdoorAmbient = Color3.fromRGB(42, 45, 48)
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.25
Lighting.ShadowSoftness = 0.35

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.22
atmosphere.Color = Color3.fromRGB(180, 191, 196)
atmosphere.Decay = Color3.fromRGB(42, 48, 54)
atmosphere.Haze = 1.4
atmosphere.Parent = Lighting

local color = Instance.new("ColorCorrectionEffect")
color.Brightness = -0.03
color.Contrast = 0.08
color.Saturation = -0.14
color.TintColor = Color3.fromRGB(226, 235, 238)
color.Parent = Lighting

local function part(parent, name, size, cf, color3, material, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color3
    p.Material = material or Enum.Material.Metal
    p.Anchored = true
    p.CanCollide = collide ~= false
    p.CanTouch = false
    p.CanQuery = true
    p.Parent = parent
    return p
end

local function addText(partObject, text, face, textColor)
    local gui = Instance.new("SurfaceGui")
    gui.Face = face or Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 34
    gui.AlwaysOnTop = false
    gui.Parent = partObject

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextWrapped = true
    label.TextScaled = true
    label.TextColor3 = textColor or Color3.fromRGB(235, 235, 224)
    label.Parent = gui
end

local test = Instance.new("Model")
test.Name = "FoundationTestLab"
test:SetAttribute("BuildId", BUILD_ID)
test.Parent = Workspace

part(test, "Floor", Vector3.new(120, 2, 84), CFrame.new(0, -1, 0), Color3.fromRGB(57, 60, 61), Enum.Material.Concrete, true)
part(test, "Ceiling", Vector3.new(120, 1, 84), CFrame.new(0, 16, 0), Color3.fromRGB(42, 45, 46), Enum.Material.Metal, true)
part(test, "BackWall", Vector3.new(120, 18, 2), CFrame.new(0, 8, -42), Color3.fromRGB(67, 70, 70), Enum.Material.Concrete, true)
part(test, "LeftWall", Vector3.new(2, 18, 84), CFrame.new(-60, 8, 0), Color3.fromRGB(67, 70, 70), Enum.Material.Concrete, true)
part(test, "RightWall", Vector3.new(2, 18, 84), CFrame.new(60, 8, 0), Color3.fromRGB(67, 70, 70), Enum.Material.Concrete, true)
part(test, "FrontWallA", Vector3.new(49, 18, 2), CFrame.new(-35.5, 8, 42), Color3.fromRGB(67, 70, 70), Enum.Material.Concrete, true)
part(test, "FrontWallB", Vector3.new(49, 18, 2), CFrame.new(35.5, 8, 42), Color3.fromRGB(67, 70, 70), Enum.Material.Concrete, true)

local successFloor = part(test, "SuccessZone", Vector3.new(20, 0.3, 12), CFrame.new(0, 0.15, 52), Color3.fromRGB(52, 91, 59), Enum.Material.SmoothPlastic, true)
addText(successFloor, "PORTA ENERGIZADA", Enum.NormalId.Top, Color3.fromRGB(212, 244, 216))

local checkpoint = part(test, "CH01_START", Vector3.new(8, 0.4, 8), CFrame.new(0, 0.2, -27), Color3.fromRGB(87, 116, 124), Enum.Material.Neon, false)
checkpoint.Transparency = 0.45
checkpoint:SetAttribute("CheckpointId", "CH01_START")
CollectionService:AddTag(checkpoint, "DeadSignalCheckpoint")

local spawn = Instance.new("SpawnLocation")
spawn.Name = "FoundationTestSpawn"
spawn.Size = Vector3.new(6, 1, 6)
spawn.CFrame = CFrame.new(0, 2.5, -27)
spawn.Transparency = 1
spawn.Anchored = true
spawn.CanCollide = false
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = Workspace

local instructionBoard = part(test, "Instructions", Vector3.new(30, 10, 1), CFrame.new(0, 7, -40.8), Color3.fromRGB(29, 32, 34), Enum.Material.Metal, true)
addText(instructionBoard, "BASE TESTÁVEL\n\n1. Aproxime-se do CABO VERMELHO\n2. Use E / botão USAR\n3. Conecte uma ponta em cada terminal\n4. A porta deve abrir quando o circuito fechar", Enum.NormalId.Front)

local sourcePedestal = part(test, "GeneratorBody", Vector3.new(8, 6, 6), CFrame.new(-26, 3, 6), Color3.fromRGB(39, 47, 48), Enum.Material.Metal, true)
local sourceNode = part(test, "SourceTerminal", Vector3.new(3.4, 3.4, 1.4), CFrame.new(-26, 5, 9.7), Color3.fromRGB(194, 153, 49), Enum.Material.Metal, true)
sourceNode:SetAttribute("PowerNodeId", "TEST_SOURCE")
sourceNode:SetAttribute("PowerNodeType", "Source")
sourceNode:SetAttribute("Output", 100)
sourceNode:SetAttribute("Enabled", true)
sourceNode:SetAttribute("WireEndpointId", "TEST_SOURCE_SOCKET")
sourceNode:SetAttribute("Accepts", "Universal")
CollectionService:AddTag(sourceNode, "DeadSignalPowerNode")
CollectionService:AddTag(sourceNode, "DeadSignalWireEndpoint")
addText(sourceNode, "FONTE", Enum.NormalId.Front)

local consumerPedestal = part(test, "DoorPowerBody", Vector3.new(8, 6, 6), CFrame.new(26, 3, 6), Color3.fromRGB(39, 47, 48), Enum.Material.Metal, true)
local consumerNode = part(test, "DoorTerminal", Vector3.new(3.4, 3.4, 1.4), CFrame.new(26, 5, 9.7), Color3.fromRGB(171, 79, 70), Enum.Material.Metal, true)
consumerNode:SetAttribute("PowerNodeId", "TEST_DOOR_POWER")
consumerNode:SetAttribute("PowerNodeType", "Consumer")
consumerNode:SetAttribute("Demand", 20)
consumerNode:SetAttribute("Enabled", true)
consumerNode:SetAttribute("WireEndpointId", "TEST_DOOR_SOCKET")
consumerNode:SetAttribute("Accepts", "Universal")
CollectionService:AddTag(consumerNode, "DeadSignalPowerNode")
CollectionService:AddTag(consumerNode, "DeadSignalWireEndpoint")
addText(consumerNode, "PORTA", Enum.NormalId.Front)

local wire = Instance.new("Model")
wire.Name = "TestRedCable"
wire:SetAttribute("WireId", "TEST_RED_CABLE")
wire:SetAttribute("MaxLength", 72)
wire:SetAttribute("WireColor", "Universal")
wire.Parent = test
CollectionService:AddTag(wire, "DeadSignalWire")

local cableCore = part(wire, "CableCore", Vector3.new(9, 0.8, 0.8), CFrame.new(0, 1.2, 7), Color3.fromRGB(161, 37, 42), Enum.Material.SmoothPlastic, true)
local cableEndA = part(wire, "CableGripA", Vector3.new(1.2, 1.2, 1.2), CFrame.new(-5, 1.2, 7), Color3.fromRGB(210, 65, 68), Enum.Material.Metal, true)
local cableEndB = part(wire, "CableGripB", Vector3.new(1.2, 1.2, 1.2), CFrame.new(5, 1.2, 7), Color3.fromRGB(210, 65, 68), Enum.Material.Metal, true)
wire.PrimaryPart = cableCore

local door = Instance.new("Model")
door.Name = "FoundationTestDoor"
door:SetAttribute("DoorId", "TEST_EXIT_DOOR")
door:SetAttribute("PowerNodeId", "TEST_DOOR_POWER")
door:SetAttribute("Locked", false)
door:SetAttribute("AutoOpenWhenPowered", true)
door:SetAttribute("OpenOffset", Vector3.new(0, 12, 0))
door:SetAttribute("OpenDuration", 0.8)
door.Parent = test
CollectionService:AddTag(door, "DeadSignalDoor")

part(door, "DoorFrameLeft", Vector3.new(3, 16, 3), CFrame.new(-8.5, 8, 41), Color3.fromRGB(35, 38, 39), Enum.Material.Metal, true)
part(door, "DoorFrameRight", Vector3.new(3, 16, 3), CFrame.new(8.5, 8, 41), Color3.fromRGB(35, 38, 39), Enum.Material.Metal, true)
part(door, "DoorHeader", Vector3.new(20, 3, 3), CFrame.new(0, 14.5, 41), Color3.fromRGB(35, 38, 39), Enum.Material.Metal, true)
local doorPanel = part(door, "DoorPanel", Vector3.new(14, 11, 1.5), CFrame.new(0, 5.5, 41), Color3.fromRGB(92, 103, 104), Enum.Material.Metal, true)
addText(doorPanel, "SEM ENERGIA", Enum.NormalId.Front, Color3.fromRGB(231, 131, 122))

for _, x in ipairs({-45,-15,15,45}) do
    local lamp = part(test, "CeilingLamp", Vector3.new(10, 0.5, 2), CFrame.new(x, 15.2, 0), Color3.fromRGB(197, 216, 215), Enum.Material.Neon, false)
    local light = Instance.new("SurfaceLight")
    light.Face = Enum.NormalId.Bottom
    light.Brightness = 1.1
    light.Range = 26
    light.Angle = 100
    light.Color = Color3.fromRGB(205, 222, 220)
    light.Parent = lamp
end

local foundation = Instance.new("Folder")
foundation.Name = "DeadSignalFoundation"
foundation:SetAttribute("BuildId", BUILD_ID)
foundation.Parent = ReplicatedStorage

local sharedFolder = Instance.new("Folder")
sharedFolder.Name = "Shared"
sharedFolder.Parent = foundation

local clientModules = Instance.new("Folder")
clientModules.Name = "Client"
clientModules.Parent = foundation

local serverRoot = Instance.new("Folder")
serverRoot.Name = "DeadSignalFoundation"
serverRoot:SetAttribute("BuildId", BUILD_ID)
serverRoot.Parent = ServerScriptService

local services = Instance.new("Folder")
services.Name = "Services"
services.Parent = serverRoot

local function module(parent, name, source)
    local m = Instance.new("ModuleScript")
    m.Name = name
    m.Source = source
    m.Parent = parent
    return m
end

__SHARED_MODULES__
__CLIENT_MODULES__
__SERVER_MODULES__

local serverBootstrap = Instance.new("Script")
serverBootstrap.Name = "ServerBootstrap"
serverBootstrap.Disabled = true
serverBootstrap.Source = __SERVER_BOOTSTRAP__
serverBootstrap.Parent = serverRoot

local clientBootstrap = Instance.new("LocalScript")
clientBootstrap.Name = "DeadSignalFoundationClient"
clientBootstrap.Source = __CLIENT_BOOTSTRAP__
clientBootstrap.Parent = StarterPlayer.StarterPlayerScripts

StarterPlayer.CameraMode = Enum.CameraMode.Classic
StarterPlayer.CameraMinZoomDistance = 0.5
StarterPlayer.CameraMaxZoomDistance = 18
StarterPlayer.CharacterWalkSpeed = 16
StarterPlayer.CharacterJumpPower = 50

Workspace:SetAttribute("DeadSignalBuildId", BUILD_ID)
Workspace:SetAttribute("FoundationTest", true)

serverBootstrap.Disabled = false

AssetService:SavePlaceAsync({PlaceId = game.PlaceId, SaveWithoutPublish = false})

return HttpService:JSONEncode({
    ok = true,
    published = true,
    build = BUILD_ID,
    sourceVersion = game.PlaceVersion,
    checkpointCount = #CollectionService:GetTagged("DeadSignalCheckpoint"),
    powerNodeCount = #CollectionService:GetTagged("DeadSignalPowerNode"),
    endpointCount = #CollectionService:GetTagged("DeadSignalWireEndpoint"),
    wireCount = #CollectionService:GetTagged("DeadSignalWire"),
    doorCount = #CollectionService:GetTagged("DeadSignalDoor"),
})
