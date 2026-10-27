local Protocol = {
    Folder = "DeadSignalGameRemotes",
    Events = {
        ChapterAction = "ChapterAction",
        ChapterFeedback = "ChapterFeedback",
        Interaction = "Interaction",
        WireAction = "WireAction",
        WireState = "WireState",
        Objective = "Objective",
        Dialogue = "Dialogue",
        DialogueAdvance = "DialogueAdvance",
        Checkpoint = "Checkpoint",
        ScreenEffect = "ScreenEffect",
        Noise = "Noise",
    },
    Functions = {
        GetGameState = "GetGameState",
        GetWireState = "GetWireState",
    },
}

return table.freeze(Protocol)

