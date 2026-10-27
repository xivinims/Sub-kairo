local Protocol = {
    Folder = "DeadSignalGameRemotes",
    Events = {
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
