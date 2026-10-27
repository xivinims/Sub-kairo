local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local foundation = ReplicatedStorage:WaitForChild("DeadSignalFoundation")
local shared = foundation:WaitForChild("Shared")
local serverFolder = ServerScriptService:WaitForChild("DeadSignalFoundation")
local servicesFolder = serverFolder:WaitForChild("Services")

local Config = require(shared:WaitForChild("GameConfig"))
local Protocol = require(shared:WaitForChild("RemoteProtocol"))

local SaveService = require(servicesFolder:WaitForChild("SaveService"))
local ChapterService = require(servicesFolder:WaitForChild("ChapterService"))
local CheckpointService = require(servicesFolder:WaitForChild("CheckpointService"))
local PowerService = require(servicesFolder:WaitForChild("PowerService"))
local WireService = require(servicesFolder:WaitForChild("WireService"))
local DoorService = require(servicesFolder:WaitForChild("DoorService"))
local InteractionService = require(servicesFolder:WaitForChild("InteractionService"))
local DialogueService = require(servicesFolder:WaitForChild("DialogueService"))
local EventDirector = require(servicesFolder:WaitForChild("EventDirector"))
local StalkerService = require(servicesFolder:WaitForChild("StalkerService"))
local NoiseService = require(servicesFolder:WaitForChild("NoiseService"))
local DebugService = require(servicesFolder:WaitForChild("DebugService"))

local save = SaveService.new(Config)
local chapters = ChapterService.new(Config, save)
local checkpoints = CheckpointService.new(save)
local power = PowerService.new(Config)
local wires = WireService.new(Config, power)
local doors = DoorService.new(power)
local interactions = InteractionService.new(Config)
local dialogue = DialogueService.new()
local events = EventDirector.new(Config)
local stalker = StalkerService.new(Config)
local noise = NoiseService.new()
local debug = DebugService.new(Config)

local remotes = foundation:FindFirstChild(Protocol.Folder)
if remotes then remotes:Destroy() end
remotes = Instance.new("Folder")
remotes.Name = Protocol.Folder
remotes.Parent = foundation

local eventsByName = {}
for _, name in pairs(Protocol.Events) do
    local remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = remotes
    eventsByName[name] = remote
end

local functionsByName = {}
for _, name in pairs(Protocol.Functions) do
    local remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = remotes
    functionsByName[name] = remote
end

local function sortedTagged(tag)
    local list = CollectionService:GetTagged(tag)
    table.sort(list, function(a, b)
        return a:GetFullName() < b:GetFullName()
    end)
    return list
end

local function scanMap()
    for _, instance in ipairs(sortedTagged("DeadSignalPowerNode")) do
        local ok, err = pcall(function() power:RegisterNode(instance) end)
        if not ok then debug:Error("POWER_REGISTER", tostring(err), instance:GetFullName()) end
    end

    for _, instance in ipairs(sortedTagged("DeadSignalWireEndpoint")) do
        local ok, err = pcall(function() wires:RegisterEndpoint(instance) end)
        if not ok then debug:Error("WIRE_ENDPOINT_REGISTER", tostring(err), instance:GetFullName()) end
    end

    for _, instance in ipairs(sortedTagged("DeadSignalWire")) do
        local model = instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model")
        if model then
            local ok, err = pcall(function() wires:RegisterWire(model) end)
            if not ok then debug:Error("WIRE_REGISTER", tostring(err), model:GetFullName()) end
        end
    end

    for _, instance in ipairs(sortedTagged("DeadSignalDoor")) do
        local model = instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model")
        if model then
            local ok, err = pcall(function() doors:Register(model) end)
            if not ok then debug:Error("DOOR_REGISTER", tostring(err), model:GetFullName()) end
        end
    end

    checkpoints:Scan()
    interactions:Scan()

    local stalkers = sortedTagged("DeadSignalStalker")
    if #stalkers > 1 then
        debug:Warn("MULTIPLE_STALKERS", "Mais de um stalker marcado; usando o primeiro.")
    end
    if stalkers[1] and stalkers[1]:IsA("Model") then
        local ok, err = pcall(function()
            stalker:BindModel(stalkers[1])
            stalker:Deactivate()
        end)
        if not ok then debug:Error("STALKER_BIND", tostring(err), stalkers[1]:GetFullName()) end
    end

    local patrol = sortedTagged("DeadSignalPatrolPoint")
    stalker:SetPatrolPoints(patrol)

    local network = power:Recalculate()
    if network.overloaded then
        debug:Warn("INITIAL_OVERLOAD", "Rede elétrica começa sobrecarregada.", network)
    end
end

local function endpointPosition(endpoint)
    if endpoint.instance:IsA("Attachment") then
        return endpoint.instance.WorldPosition
    end
    return endpoint.instance.Position
end

local function playerRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function validatePlayerNearEndpoint(player, endpointId, extra)
    local endpoint = wires.Endpoints[endpointId]
    local root = playerRoot(player)
    if not endpoint or not root then return false end
    return (root.Position - endpointPosition(endpoint)).Magnitude <= (Config.Wires.MaxConnectionDistance + (extra or 0))
end

local wireRemote = eventsByName[Protocol.Events.WireAction]
wireRemote.OnServerEvent:Connect(function(player, action, a, b)
    if type(action) ~= "string" or not player:GetAttribute("DeadSignalPlaying") then return end
    if a ~= nil and type(a) ~= "string" then return end
    if b ~= nil and type(b) ~= "string" then return end

    if action == "begin" then
        local wire = wires.Wires[a]
        local root = playerRoot(player)
        if not wire or not root then return end
        local position = wire.model:GetPivot().Position
        if (root.Position - position).Magnitude > Config.Player.MaxInteractionDistance + 4 then return end

        local ok, reason = wires:BeginCarry(player, a)
        if ok then
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = Config.Player.WireCarryWalkSpeed end
            eventsByName[Protocol.Events.WireState]:FireClient(player, "carry-start", wires:GetState(a))
        else
            eventsByName[Protocol.Events.WireState]:FireClient(player, "rejected", {reason = reason})
        end

    elseif action == "connect" then
        local wireId = wires.PlayerCarry[player]
        if not wireId or wireId ~= a then return end
        if not validatePlayerNearEndpoint(player, b, 2) then
            eventsByName[Protocol.Events.WireState]:FireClient(player, "rejected", {reason = "too-far"})
            return
        end

        local ok, reason = wires:Connect(a, b)
        eventsByName[Protocol.Events.WireState]:FireAllClients(ok and "connected" or "rejected", {
            wire = wires:GetState(a),
            endpoint = b,
            reason = reason,
        })

    elseif action == "disconnect" then
        if not validatePlayerNearEndpoint(player, b, 2) then return end
        local wire = wires.Wires[a]
        local endpoint = wires.Endpoints[b]
        if not wire or not endpoint or endpoint.occupiedBy ~= a then return end
        if wire.carriedBy and wire.carriedBy ~= player then return end
        if wires:Disconnect(a, b) then
            eventsByName[Protocol.Events.WireState]:FireAllClients("disconnected", {
                wire = wires:GetState(a),
                endpoint = b,
            })
        end

    elseif action == "end" then
        local wireId = wires.PlayerCarry[player]
        wires:EndCarry(player)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = Config.Player.WalkSpeed end
        if wireId then
            eventsByName[Protocol.Events.WireState]:FireClient(player, "carry-end", wires:GetState(wireId))
        end
    end
end)

functionsByName[Protocol.Functions.GetWireState].OnServerInvoke = function(player, wireId)
    if type(wireId) ~= "string" then return nil end
    return wires:GetState(wireId)
end

functionsByName[Protocol.Functions.GetGameState].OnServerInvoke = function(player)
    return chapters:ExportState(player)
end

eventsByName[Protocol.Events.DialogueAdvance].OnServerEvent:Connect(function(player, choiceId)
    dialogue:Advance(player, choiceId)
end)

dialogue.LineRequested.Event:Connect(function(player, line)
    eventsByName[Protocol.Events.Dialogue]:FireClient(player, "line", line)
end)

dialogue.DialogueFinished.Event:Connect(function(player, dialogueId)
    eventsByName[Protocol.Events.Dialogue]:FireClient(player, "finished", dialogueId)
end)

chapters.ObjectiveChanged.Event:Connect(function(player, objectiveId, state)
    eventsByName[Protocol.Events.Objective]:FireClient(player, objectiveId, state)
end)

checkpoints.Changed.Event:Connect(function(player, id)
    eventsByName[Protocol.Events.Checkpoint]:FireClient(player, id)
end)

noise.Noise.Event:Connect(function(event)
    if not stalker.Enabled or not stalker.Root then return end
    local distance = (event.position - stalker.Root.Position).Magnitude
    local effectiveRange = Config.Stalker.HearingRange * math.max(0.1, event.loudness)
    if distance <= effectiveRange then
        stalker:Investigate(event.position)
    end
end)

power.NodeChanged.Event:Connect(function(nodeId, energized)
    for doorId, door in pairs(doors.Doors) do
        if door.powerNodeId == nodeId and door.model:GetAttribute("AutoOpenWhenPowered") == true then
            task.spawn(function()
                doors:SetOpen(doorId, energized)
            end)
        end
    end
end)

interactions:RegisterAction("Checkpoint", function(player, prompt)
    local parent = prompt.Parent
    local id = parent:GetAttribute("CheckpointId") or parent.Name
    local ok, checkpoint = pcall(function() return checkpoints:Set(player, id) end)
    return ok and checkpoint or nil
end)

interactions:RegisterAction("ToggleDoor", function(_, prompt)
    local model = prompt:FindFirstAncestorOfClass("Model")
    local id = model and (model:GetAttribute("DoorId") or model.Name)
    local door = id and doors.Doors[id]
    if not door then return false end
    return doors:SetOpen(id, not door.open)
end)

interactions:RegisterAction("StartDialogue", function(player, prompt)
    local id = prompt:GetAttribute("DialogueId")
    if not id then return false end
    return dialogue:Start(player, id)
end)

interactions:RegisterAction("EmitNoise", function(_, prompt)
    local parent = prompt.Parent
    local position = parent:IsA("Attachment") and parent.WorldPosition or parent.Position
    noise:Emit(position, tonumber(prompt:GetAttribute("Loudness")) or 1, "interaction", parent)
    return true
end)

events:Register("StalkerActivate", function(payload)
    stalker:Activate(payload.mode or "Patrol")
end)

events:Register("StalkerDeactivate", function()
    stalker:Deactivate()
end)

events:Register("PowerRecalculate", function()
    return power:Recalculate()
end)

local ChapterRuntime = require(servicesFolder:WaitForChild("ChapterRuntime"))
local chapterRuntime

local function onCharacter(player, character)
    task.wait()
    if chapterRuntime then chapterRuntime:Restore(player) end
    checkpoints:RespawnCharacter(player, character)
end

local function onPlayer(player)
    save:Load(player)
    while not chapterRuntime do task.wait() end
    chapterRuntime:Restore(player)
    player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)
    if player.Character then task.spawn(onCharacter, player, player.Character) end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end

Players.PlayerRemoving:Connect(function(player)
    wires:EndCarry(player)
    dialogue:Cancel(player)
    save:Save(player, true)
    save:Forget(player)
end)

scanMap()
chapterRuntime = ChapterRuntime.new({save=save,chapters=chapters,checkpoints=checkpoints,power=power,wires=wires,doors=doors,
    interactions=interactions,dialogue=dialogue,stalker=stalker,noise=noise,debug=debug,events=events,
    remotes=eventsByName,protocol=Protocol,config=Config})
chapterRuntime:Start()
save:Start()
events:Start()
stalker:Start()

game:BindToClose(function()
    save:Stop()
    events:Stop()
    stalker:Stop()
    for _, player in ipairs(Players:GetPlayers()) do
        save:Save(player, true)
    end
end)

serverFolder:SetAttribute("Ready", true)
serverFolder:SetAttribute("BuildId", Config.BuildId)

