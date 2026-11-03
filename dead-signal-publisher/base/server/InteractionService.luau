local CollectionService = game:GetService("CollectionService")

local InteractionService = {}
InteractionService.__index = InteractionService

function InteractionService.new(config)
    local self = setmetatable({}, InteractionService)
    self.Config = config
    self.Actions = {}
    self.Prompts = {}
    self.Interacted = Instance.new("BindableEvent")
    return self
end

function InteractionService:RegisterAction(actionId, handler)
    assert(type(actionId) == "string" and actionId ~= "", "Action id required")
    assert(type(handler) == "function", "Interaction handler must be function")
    self.Actions[actionId] = handler
end

function InteractionService:_distanceValid(player, adornee)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local position
    if adornee:IsA("Attachment") then
        position = adornee.WorldPosition
    elseif adornee:IsA("BasePart") then
        position = adornee.Position
    elseif adornee:IsA("Model") then
        position = adornee:GetPivot().Position
    end
    if not position then return false end

    return (root.Position - position).Magnitude <= self.Config.Player.MaxInteractionDistance + 2
end

function InteractionService:RegisterPrompt(prompt)
    assert(prompt:IsA("ProximityPrompt"), "Expected ProximityPrompt")
    if self.Prompts[prompt] then return end

    local actionId = prompt:GetAttribute("ActionId")
    assert(type(actionId) == "string" and actionId ~= "", "Prompt ActionId missing")
    self.Prompts[prompt] = true

    prompt.MaxActivationDistance = math.min(prompt.MaxActivationDistance, self.Config.Player.MaxInteractionDistance)
    prompt.Triggered:Connect(function(player)
        if not self:_distanceValid(player, prompt.Parent) then return end
        local handler = self.Actions[actionId]
        if not handler then
            warn("[DeadSignal InteractionService] unknown action", actionId)
            return
        end

        local ok, result = pcall(handler, player, prompt)
        if not ok then
            warn("[DeadSignal InteractionService] action failed", actionId, result)
            return
        end
        self.Interacted:Fire(player, actionId, result)
    end)
end

function InteractionService:Scan()
    for _, prompt in ipairs(CollectionService:GetTagged("DeadSignalInteraction")) do
        if prompt:IsA("ProximityPrompt") then
            self:RegisterPrompt(prompt)
        end
    end
end

return InteractionService
