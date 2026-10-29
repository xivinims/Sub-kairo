# Still Here — Duvall mansion and Orderly forest

Current target: universe 9421311218 / place 118064584465155; exclusive branch dead-signal-publisher. Current verified release: PlaceVersion 208, run 40910790192. Default publisher is publish.mjs → mansion-native-publish.mjs. Recovery file is pinned in release-state.json. Old islands/FPS/adventure publishers remain as historical code and are not the current entry point.

## Exact source selections

Asset 7902470429 supplies Workspace.Content.Interior (all 15 room sectors) and Workspace.Content.Exterior.House plus Exterior.Props. The assembled geometry contains 8,837 interior and 4,584 exterior parts (13,421 total). Source transforms, furniture meshes, visible textures and lighting data are retained. Invisible collidable architecture is retained; non-colliding invisible triggers, editor/target poses, source NPCs and all foreign code are excluded. No replacement mansion is constructed from generic blocks. This is the mansion's static geometry with our interactions, not the original game's full scripted story, corruption sequences, puzzles, grabs or every interactive prop.

Asset 13037825880 supplies ReplicatedStorage.Dreams.EmmaDream.Map.Realistic Tree, the authored two-mesh tree found in the forest reference. It is grounded in the native initializer around the mansion using deterministic placements and scaled to 60–95 studs. The verified scene has 109 placements. This reuses the original tree geometry and its visual identity; it is not an identical copy of the source game's forest layout. The prison, neighborhood, dream actors and source scripts are not imported. Where original native soil is absent, continuous native grass strips surround the mansion footprint without filling the basement void.

Asset 7208091524 retains the audited black-hole and skinned debris visuals, driven locally by our code. Camera-relative sky distance is now 900 studs with retained visual scale, making it appear farther away. The sky renderer remains independent of distant forest activation.

## Runtime and loading

Public servers keep the map in ServerStorage.MatchWorld and show only the existing menu. Authenticated reserved sessions restore it, paste the native mansion terrain, generate the source-tree placements, validate the original SpawnLocationHouse floor and avatar clearance, and release character loading. Solo/private groups and virtual-credit inventory remain in the same universe.

MansionCatalog stores static geometry in 64-stud cells, with large architectural spans kept as backdrops to prevent floors disappearing by center-distance unloading. The nearby mansion activates within about 150 studs; forest cells activate at 190 outside and 85 while inside the approximate house footprint. All players contribute desired cells, so outside players retain their surroundings. Roblox streaming remains enabled at min 64 / target 128. Close exterior scenery can remain visible through windows; distant forest is removed server-side. The black hole stays local and visible independently.

The exact published RBXL is downloaded and checked independently after native preflight/published-version checks, then old servers are restarted. A failed publication check restores the pinned known-good file. Headless native checks explicitly initialize the scene because server Scripts do not automatically run in that environment.

## One changing visitor

Only one TheFormerOwner rig exists at a time. Three researched/cached catalog appearance definitions alternate between visits; the previous body fades out before its replacement is created. It is an impostor associated with fictional former owner Amélia Duarte, whose death is revealed through a local record interaction at the entrance. It does not establish that the borrowed visible NPC is the historical homeowner.

After a 35–55 second interval, the visitor approaches the original front-door region, raises its right arm and performs three knock motions, then displays: “Oi, aqui é minha casa. O que vocês fazem aqui???” There is head movement and a procedural walking gait. Nearby clients see subtitles; no dubbed speech was generated. Source knock audio is selected only if an original Sound named for knocking is present. The creature can pursue/damage nearby players outside, probes scenery before moving, regrounds each step and does not chase through the protected interior.

Twenty-one original door panels are identified. Our proximity interaction swings them slowly; associated hardware follows by welded parts. Record/open prompts have separate vertical offsets. This does not prove every original Duvall scripted interaction is reproduced.

## Verification and limits

Native checks confirmed correct game IDs/build, all 15 sectors and source-part counts, source forest placements, supported unobstructed arrival, avatar creation for changing appearances, removed prior combat/adventure/disaster runtimes, safe static catalog and original sky data. Exact-file checks confirm code/source provenance, one Terrain, server-only map data and streaming settings. Server restart was confirmed for version 208.

No rendered Roblox client walkthrough, full door traversal, visitor encounter playback, live six-player teleport test or phone FPS measurement was obtained. The forest layout, creature gait, interactions and camera need client visual/play testing; these checks establish data and code structure, not a claim of perfect visual fidelity.
