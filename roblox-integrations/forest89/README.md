# Seasonal forest and tea ruins — version 89

Target: universe `9421311218`, place `118064584465155`. Incremental installation from saved version 88. The city remains removed.

The existing native Forest Pack meshes, root contact profiles, two wooden bridges, river at Y=6, skinned grass, Wind Effects, seated owner avatar and 16-minute day/night cycle are retained. The added courtyard uses an open six-arch stone arcade, eight columns, vines, broken roof, hanging native lanterns, stone seating, a four-seat tea table and a four-jet fountain. Spawn moves to a clear position on the courtyard floor. A stone stair path connects it to the existing forest trail.

`Seasons` assigns spring in the northeast, summer in the southeast, autumn in the southwest and winter in the northwest, with noisy boundaries. Only Grass/LeafyGrass voxel materials change; occupancy, liquid channels, bank heights and paths are retained. Winter has native Snow terrain, autumn has a warm LeafyGrass color; the existing grass sampler matches actual surface color and rejects snow. Native leaf textures and PBR appearances are retained and tinted by season. Local atmospheric changes blend across boundaries. Four small camps use the existing imported FallenTree geometry for 16 prompted seats and proximity-limited fire effects. Lily pads sit on the existing water plane and avoid bridges.

`Servir chá` gives the nearby player a welded, unanchored cup Tool. Distance and cooldown checks run on the server. Equipping/sipping does not change character root or joints. Seats use native Seat:Sit. The ruins' lighting/neblina prompt changes only that client's lighting near the courtyard; leaving restores the surrounding seasonal atmosphere.

## Files

- `ruins.luau`: courtyard builder; CFG includes Origin, Mood, Ruin, VineDensity, Seed.
- `season-world.luau`: material-only terrain integration, native foliage tints, grounded camps and river plants.
- `seasons.luau`: quadrant logic and local visual blending.
- `scene.luau`: existing grass field with winter candidate exclusion.
- `ruin-server.luau`, `ruin-client.luau`, `ruin-mood.luau`: interactions, local VFX and atmosphere.
- `server.luau`, `cycle-client.luau`: runtime integration.
- `tests.luau`, `forest-regressions.luau`: native geometry, grounding, water, grass, NPC and compilation checks.
- `stage.luau`: temporary execution without SavePlaceAsync.
- `install.luau`: validated installation followed by SavePlaceAsync.
- `verify.luau`: independent fresh-session verification of saved version 89.
- `assemble.py`: builds the three execution scripts; requires version-88 test sources in sibling forest88.

Native checks verify structure, collision and script compilation. They cannot establish how reference images compare pixel-for-pixel, or confirm graphics/FPS on the owner's 3GB phone. Particle/fire/beam effects are disabled locally beyond 85 studs; the inherited grass patch budgets remain bounded.
