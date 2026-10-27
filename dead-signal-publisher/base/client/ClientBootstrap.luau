local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local foundation = ReplicatedStorage:WaitForChild("DeadSignalFoundation")
local shared = foundation:WaitForChild("Shared")
local clientFolder = foundation:WaitForChild("Client")

local Config = require(shared:WaitForChild("GameConfig"))
local Protocol = require(shared:WaitForChild("RemoteProtocol"))
local InputController = require(clientFolder:WaitForChild("InputController"))
local ObjectiveController = require(clientFolder:WaitForChild("ObjectiveController"))
local DialogueController = require(clientFolder:WaitForChild("DialogueController"))
local WireController = require(clientFolder:WaitForChild("WireController"))
local ScreenEffectsController = require(clientFolder:WaitForChild("ScreenEffectsController"))

local remotes = foundation:WaitForChild(Protocol.Folder)

local gui = Instance.new("ScreenGui")
gui.Name = "DeadSignalFoundationGui"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")

local input = InputController.new(Config)
local objectives = ObjectiveController.new(gui)
local dialogue = DialogueController.new(gui)
local wirePreview = WireController.new(Config)
local screenEffects = ScreenEffectsController.new()

local function findTaggedAncestor(instance, tag)
    local current = instance
    while current and current ~= workspace do
        if CollectionService:HasTag(current, tag) then return current end
        current = current.Parent
    end
end

local function centerRaycast()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local x, y = mousePos.X, mousePos.Y
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        local viewport = camera.ViewportSize
        x, y = viewport.X * 0.5, viewport.Y * 0.5
    end

    local ray = camera:ViewportPointToRay(x, y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if player.Character then params.FilterDescendantsInstances = {player.Character} end
    return workspace:Raycast(ray.Origin, ray.Direction * 80, params)
end

local function endpointFromHit(instance)
    local endpoint = findTaggedAncestor(instance, "DeadSignalWireEndpoint")
    if not endpoint then return nil end
    return endpoint:GetAttribute("WireEndpointId") or endpoint.Name, endpoint
end

local function wireFromHit(instance)
    local wire = findTaggedAncestor(instance, "DeadSignalWire")
    if not wire then return nil end
    local model = wire:IsA("Model") and wire or wire:FindFirstAncestorOfClass("Model")
    if not model then return nil end
    return model:GetAttribute("WireId") or model.Name, model
end

local carriedWire

input.InteractRequested.Event:Connect(function()
    local hit = centerRaycast()
    if not hit then
        if carriedWire then
            remotes[Protocol.Events.WireAction]:FireServer("end")
        end
        return
    end

    local endpointId, endpoint = endpointFromHit(hit.Instance)
    if carriedWire and endpointId then
        remotes[Protocol.Events.WireAction]:FireServer("connect", carriedWire, endpointId)
        return
    end

    local wireId, wireModel = wireFromHit(hit.Instance)
    if wireId and not carriedWire then
        remotes[Protocol.Events.WireAction]:FireServer("begin", wireId)
        wirePreview:Begin(wireId, wireModel:GetPivot().Position)
        return
    end
end)

input.CancelRequested.Event:Connect(function()
    if carriedWire then remotes[Protocol.Events.WireAction]:FireServer("end") end
end)

remotes[Protocol.Events.WireState].OnClientEvent:Connect(function(kind, payload)
    if kind == "carry-start" then
        carriedWire = payload and payload.id
    elseif kind == "carry-end" then
        carriedWire = nil
        wirePreview:End()
    elseif kind == "rejected" then
        screenEffects:PulseDanger(0.35)
    elseif kind == "connected" and payload and payload.wire and carriedWire == payload.wire.id then
        carriedWire = payload.wire.id
        if payload.wire.endpointA and payload.wire.endpointB then
            remotes[Protocol.Events.WireAction]:FireServer("end")
        end
    end
end)

dialogue.AdvanceRequested.Event:Connect(function()
    remotes[Protocol.Events.DialogueAdvance]:FireServer()
end)

remotes[Protocol.Events.Dialogue].OnClientEvent:Connect(function(kind, payload)
    if kind == "line" then
        local ui=player.PlayerGui:FindFirstChild("DeadSignalFrontEnd")
        if ui and ui:GetAttribute("Subtitles")==false and payload.radio then
            dialogue:Hide()
            task.delay(4,function() remotes[Protocol.Events.DialogueAdvance]:FireServer() end)
        else dialogue:Show(payload) end
    elseif kind == "finished" then
        dialogue:Hide()
    end
end)

remotes[Protocol.Events.Objective].OnClientEvent:Connect(function(objectiveId, state)
    objectives:SetObjective(objectiveId, state == "complete")
end)

remotes[Protocol.Events.ScreenEffect].OnClientEvent:Connect(function(kind, strength)
    if kind == "danger" then
        screenEffects:PulseDanger(strength)
    elseif kind == "power-failure" then
        screenEffects:SetPowerFailure(strength == true)
    end
end)

task.spawn(function()
    local ok, state = pcall(function()
        return remotes[Protocol.Functions.GetGameState]:InvokeServer()
    end)
    if ok and state then
        objectives:SetChapter(state.chapter or "Dead Signal")
        local active
        for id, value in pairs(state.objectives or {}) do
            if value == "active" then active = id break end
        end
        objectives:SetObjective(active or "Explore o local.", false)
    end
end)

task.spawn(function()
    while true do
        task.wait(Config.Wires.UpdateRate)
        if carriedWire then
            local hit = centerRaycast()
            if hit then
                local endpointId, endpoint = endpointFromHit(hit.Instance)
                local position = hit.Position
                if endpoint then
                    position = endpoint:IsA("Attachment") and endpoint.WorldPosition or endpoint.Position
                end
                wirePreview:UpdateTarget(position, endpointId ~= nil)
            end
        end
    end
end)

input:Start()
require(clientFolder:WaitForChild("ChapterPresentation")).Start(gui,remotes,Protocol,input)
foundation:SetAttribute("ClientReady_" .. player.UserId, true)

