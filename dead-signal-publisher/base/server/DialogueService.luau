local DialogueService = {}
DialogueService.__index = DialogueService

function DialogueService.new()
    local self = setmetatable({}, DialogueService)
    self.Speakers = {}
    self.Dialogues = {}
    self.ActiveByPlayer = {}
    self.LineRequested = Instance.new("BindableEvent")
    self.DialogueFinished = Instance.new("BindableEvent")
    return self
end

function DialogueService:RegisterSpeaker(id, metadata)
    assert(type(id) == "string" and id ~= "", "Speaker id required")
    self.Speakers[id] = {
        id = id,
        displayName = metadata.displayName or id,
        portrait = metadata.portrait,
        voice = metadata.voice,
        color = metadata.color,
    }
end

function DialogueService:RegisterDialogue(id, definition)
    assert(type(id) == "string" and id ~= "", "Dialogue id required")
    assert(type(definition) == "table" and #definition > 0, "Dialogue must contain lines")
    self.Dialogues[id] = definition
end

function DialogueService:CanStart(player)
    return self.ActiveByPlayer[player] == nil
end

function DialogueService:Start(player, dialogueId, context)
    if not self:CanStart(player) then return false, "busy" end
    local definition = self.Dialogues[dialogueId]
    if not definition then return false, "unknown-dialogue" end

    local session = {
        id = dialogueId,
        index = 1,
        context = context or {},
        cancelled = false,
    }
    self.ActiveByPlayer[player] = session
    self:_emitCurrent(player, session)
    return true
end

function DialogueService:_emitCurrent(player, session)
    local line = self.Dialogues[session.id][session.index]
    if not line then
        self.ActiveByPlayer[player] = nil
        self.DialogueFinished:Fire(player, session.id)
        return
    end

    local speaker = self.Speakers[line.speaker]
    self.LineRequested:Fire(player, {
        dialogueId = session.id,
        index = session.index,
        speaker = speaker,
        text = line.text,
        duration = line.duration,
        choices = line.choices,
        emotion = line.emotion,
        radio = line.radio == true,
    })
end

function DialogueService:Advance(player, choiceId)
    local session = self.ActiveByPlayer[player]
    if not session then return false end
    local line = self.Dialogues[session.id][session.index]

    if line and line.choices and choiceId then
        local selected
        for _, choice in ipairs(line.choices) do
            if choice.id == choiceId then selected = choice break end
        end
        if not selected then return false, "invalid-choice" end
        if selected.next then
            session.index = selected.next
        else
            session.index += 1
        end
    else
        session.index += 1
    end

    self:_emitCurrent(player, session)
    return true
end

function DialogueService:Cancel(player)
    local session = self.ActiveByPlayer[player]
    if not session then return end
    self.ActiveByPlayer[player] = nil
    session.cancelled = true
end

return DialogueService
