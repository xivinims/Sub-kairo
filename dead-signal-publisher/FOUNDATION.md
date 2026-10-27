# Dead Signal Foundation

This branch contains the long-term game foundation. It is intentionally split into independent systems so maps, characters, chapters, puzzles and UI can be replaced without rewriting the whole game.

## Runtime layers

### Shared
- GameConfig: central tuning and IDs.
- RemoteProtocol: one canonical list of client/server messages.

### Server services
- SaveService: versioned player data, retry logic, autosave, UpdateAsync and shutdown save.
- ChapterService: chapter, objective and persistent story flags.
- CheckpointService: tagged checkpoints and respawn.
- PowerService: graph-based electrical network with sources, junctions, consumers, switches and overload detection.
- WireService: physical cable endpoints, compatibility, cable length, occupancy and live power links.
- DoorService: powered/locked doors with tweened state.
- InteractionService: server-authoritative ProximityPrompt actions.
- DialogueService: speakers, lines, choices and per-player sessions.
- EventDirector: queued/cooldown/priority horror events.
- NoiseService: reusable server-side noise events.
- StalkerService: Dormant / Observe / Patrol / Investigate / Search / Chase / Cooldown state machine.
- DebugService: diagnostics instead of silent failures.
- ServerBootstrap: scans CollectionService tags and wires every service together.

### Client controllers
- InputController: keyboard, gamepad and touch input.
- ObjectiveController: chapter/objective HUD.
- DialogueController: responsive dialogue panel.
- WireController: local cable preview.
- ScreenEffectsController: danger and blackout feedback.
- ClientBootstrap: remote wiring, aiming/raycast and controller startup.

## Map contract

Map builders should use tags + attributes, not edit scripts.

### Power node
Tag: `DeadSignalPowerNode`
Attributes:
- PowerNodeId (string)
- PowerNodeType = Source | Junction | Consumer | Switch
- Output (number, sources)
- Demand (number, consumers)
- Enabled (boolean)

### Wire endpoint
Tag: `DeadSignalWireEndpoint`
Attributes:
- WireEndpointId (string)
- PowerNodeId (string)
- Accepts = Any or cable type

### Wire model
Tag: `DeadSignalWire`
Attributes:
- WireId (string)
- MaxLength (number)
- WireColor (string/type)

### Door
Tag: `DeadSignalDoor`
Model requires a descendant BasePart named `DoorPanel`.
Attributes:
- DoorId
- PowerNodeId
- Locked
- OpenOffset (Vector3)
- OpenDuration
- AutoOpenWhenPowered

### Checkpoint
Tag: `DeadSignalCheckpoint`
BasePart attribute: `CheckpointId`.

### Interaction
Tag the ProximityPrompt with `DeadSignalInteraction`.
Attribute `ActionId` currently supports:
- Checkpoint
- ToggleDoor
- StartDialogue
- EmitNoise

### Stalker
Tag the NPC model `DeadSignalStalker`.
Tag path nodes `DeadSignalPatrolPoint`.

## Design rule

A chapter should be content, not new infrastructure. New rooms should mostly be assembled by placing models, tags and attributes. New chapters should not require cloning core scripts.
