local BUILD_ID = "dead-signal-ch01-signalworks-v3"
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

__CHAPTER_MAP__

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
Workspace:SetAttribute("FoundationTest", false)

serverBootstrap.Disabled = false

__PREPUBLISH_VALIDATE__
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

