local Config = {}

Config.BuildId = "dead-signal-ch01-signalworks-v3"
Config.DataVersion = 1
Config.DefaultChapter = "Chapter01"
Config.DefaultCheckpoint = "CH01_START"

Config.Player = {
    WalkSpeed = 16,
    JumpPower = 50,
    MaxInteractionDistance = 11,
    WireCarryWalkSpeed = 13,
    RespawnDelay = 2.5,
}

Config.Wires = {
    MaxCarryDistance = 42,
    MaxConnectionDistance = 8,
    BreakDistance = 56,
    SnapRadius = 5,
    UpdateRate = 1 / 20,
    DefaultCableLength = 30,
    MaxActivePerPlayer = 1,
}

Config.Power = {
    DefaultVoltage = 100,
    TickRate = 0.2,
    OverloadGraceSeconds = 1.5,
}

Config.Events = {
    MinAmbientGap = 18,
    MaxAmbientGap = 42,
    StalkerCooldown = 55,
    MaxQueuedEvents = 12,
}

Config.Stalker = {
    ThinkRate = 0.18,
    SightRange = 72,
    HearingRange = 48,
    ChaseRange = 120,
    LoseSightGrace = 4.5,
    SearchDuration = 10,
    RepathInterval = 0.7,
    MoveSpeedPatrol = 8,
    MoveSpeedInvestigate = 11,
    MoveSpeedChase = 18,
}

Config.Save = {
    StoreName = "DeadSignal_PlayerData_v2",
    AutosaveSeconds = 45,
    RetryCount = 4,
    RetryDelay = 1.5,
}

Config.Chapters = {
    Chapter01 = {
        displayName = "Capítulo 1",
        order = 1,
        firstCheckpoint = "CH01_START",
        objectives = {
            "RestoreLobbyPower",
            "ReachMaintenance",
            "RepairMainCircuit",
        },
    },
}

Config.Debug = {
    Enabled = true,
    VerbosePower = false,
    VerboseWires = false,
    VerboseAI = false,
}

return table.freeze(Config)

