> Current release: PlaceVersion 211, run 40914351994. The restoration below supersedes older statements that weapons/original HUD are absent or that only a changing visitor exists.

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

## Original HUD and requested controls restoration — 211

All seven original Duvall ScreenGui templates are retained as data in ReplicatedStorage.MansionOriginalUI, preserving their authored layout, image assets and typography. HUD, Screenspace_Vignette and OnItemIndicator2 are enabled for gameplay; story/lore/blackout/countdown panels are preserved but are not forced on screen. The original MissionsLogicClient source is installed with a match-mode guard and a narrowly compatible DemoConfig enum module. The top mission text responds to exploration, knocking, peephole, lock and weapon-pickup events; its original counter receives room-visit progress from tagged source room parts. This does not restore Duvall's entire original campaign, corruption progression, every prop puzzle or all server scripts. Door/interaction integration remains adapted code rather than the source campaign engine.

Original HUD buttons are wired to local headlamp and server-validated grab/release of eligible small book/cup/vase props. The source item indicator reacts to nearby doors/grabbable props. First person is enforced, with touch/keyboard sprint, door lock and peephole actions. The peephole moves the camera toward the outside of the original front door and intensifies the original vignette; clicking again/P exits. The two front panels share a server-authoritative lock state that survives cell reactivation; open doors must close before locking. The unwanted in-match return-to-menu button is removed. Outside transitions tween a subtle black overlay, while door locks/peephole actions validate player proximity on the server. The original generic record interaction was removed.

Night is 00:00 with lower ambient/exposure/environment lighting, and 244 source-tree placements surround the mansion with clearance at the building footprint. Original authoring scale/room geometry remains unchanged.

Original ReplicatedStorage.Dreams.EmmaDream.Sepulchar from asset 13037825880 is sanitized and retained as OriginalForestMonster. Its mesh rig patrols the exterior with bounded server pathfinding, sight checks, last-seen searching, procedural gait and a locked-interior boundary. The changing door visitor remains a separate encounter, with its own knocking animation and alternate researched appearances. Thus there is one source forest creature plus one changing visitor; neither is a newly invented substitute for the source creature mesh. Animation/face-control scripts from the source game are not blindly executed.

M4A1 and Deagle source rigs/keyframes from 15864801103 are available as pickups inside the mansion. Native surface casts place the displayed weapon geometry; source FPS viewmodels and our server-validated fire-rate/ammo/reload/PvE hit logic are retained. Nearby pickup validation replaces the previous NPC armory selection gate. Weapons damage the source forest creature, not players or innocent residents. Original authored FPS keyframe data is used by the reviewed local playback adapter; arbitrary third-party loaders are excluded.

Engine/file validation confirms source assets, room/door/tree counts, supported arrival, restored UI/mission source, source creature identity, FPS sources, and removed return button. Version 211 was downloaded independently and servers restarted. No live-client UI/peephole/combat/pathfinding playthrough or measured phone FPS is asserted.
