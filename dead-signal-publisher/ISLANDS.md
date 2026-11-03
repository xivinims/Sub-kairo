> Archived islands/adventure architecture. The current mansion build is documented in [MANSION.md](MANSION.md).

# Still Here — three islands and original Beyond the Dark sky effect

Target: universe `9421311218`, place `118064584465155`. Only branch `dead-signal-publisher` is used. The former generated meadow is removed. There is no chapter menu, GrabPack, stalker, or old loading screen.

## Destinations

| Map button | Source | Scope |
| --- | --- | --- |
| Cidade | Port Gloom 186677844 | Static city architecture and props; NPCs, scripts, UI, invisible barriers and grass models excluded |
| Floresta (1) | Roblox Realistic Forest Demo 5326950832 | Original static forest layout and native voxel terrain; scripts, flying animals, demo UI and distant tree cards excluded |
| Floresta (atual) | Realistic Forest 88883160098456 | Its `Workspace.Forest.Model` forest selection and terrain; unrelated night club, shops and roads from the full place excluded |

The maps retain source-relative transforms and are translated to independent islands with at least 4,096 studs between their geometric bounds. Ocean margins surround each terrain region. Each destination has one neutral SpawnLocation, a validated floor, and a precise character clearance probe. The current forest has the original audited altar. Altar placement searches for dry land and clears only overlapping vegetation.

The map icon opens the three requested buttons. The server accepts only fixed destination IDs, limits repeated requests, warms destination cells, requests streaming, and teleports the character after loading. Respawns retain the selected destination during that server session. Initial characters remain anchored until initialization and travel finish. Name tags and temporary arrival glow/ring remain enabled.

## Rendering and performance

Native terrain grass uses `Decoration=true`, `GrassLength=0.85`. Geometry grass is filtered. Native grass materials are restored near activated cells when required. Streaming is configured in the place file to 64 minimum / 128 target studs, with opportunistic stream-out and pause outside loaded areas.

Full scenery is stored in server-only `IslandGeometryCatalog` as 128-stud cells. The server activates nearby cells at 1 Hz, warms a small area at every spawn, and removes cells outside player areas. Very large floor/background parts remain in streamed `Backdrops` so walking on the edge of a large part does not unload the floor when its center is farther away. WindShake affects nearby vegetation only. Rain, thunder, lightning, and warm aerial perspective are retained.

Lighting asset 17835285085 is actually a full demo place with 202 source containers. Only its Sky, SunRaysEffect and BloomEffect are selected as visual data. The scenery and external code from that lighting asset are not imported.

## Original black hole

Asset 7208091524 is inspected offline. Only `Workspace.Skybox.BlackHole` and `Workspace.Skybox.DebrisField` are selected. The halo, singularity meshes, accretion beams, image flares, textures and original skinned debris geometry are retained. Foreign scripts, sounds, constraints and animation controllers are removed. Bone transforms are driven by our client code, without loading external animation scripts.

`SkyBlackHoleTemplate` is replicated as visual data. `SkyBlackHoleClient` clones it locally, scales it using the source observer distance, and keeps it roughly 450 studs away above the camera. The source viewing axis is preserved. Flares are occluded by world geometry. Debris motion and camera tracking run at 20 Hz with fewer animated bones and lower particle rates on touch devices. Sky parts have no collision, query, touch or cast shadow. No spacecraft or interior from Beyond the Dark is imported.

## Import safety and validation

`SafeAssetImporterFile.luau` is the offline geometry companion to the existing runtime importer. It uses an explicit asset allowlist and visual-child whitelist. `Terrain` must be excluded explicitly because it inherits BasePart. Only one Terrain may exist and it must be a direct Workspace child; the build rejects nested Terrain instances before serialization and after downloading the published file.

Native voxel grids are carried as passive TerrainRegion snapshots. Trusted `IslandInitializer` applies them once per live server, grounds arrivals, checks exact geometry with GetPartsInPart, removes snapshots, and sets `IslandWorldReady=true`. Runtime cells then activate normally. This avoids the internal SavePlaceAsync upload failure observed with the legacy imported scene.

`islands-native-publish.mjs` builds a safe RBXM bundle and sends it through Open Cloud binary input / SerializationService for native preflight validation. After preflight it publishes the complete RBXL. Headless Luau sessions do not automatically run server Scripts (`RunService:IsRunning()` is false), so the published-version verification explicitly runs the same initializer before checking maps, floors, spawns, remotes, client/server code, native sky geometry and rig scaling. The exact published file is downloaded and independently inspected with pinned Lune 0.11.1, then old servers are restarted. A failed publication check restores the known-good version recorded in `release-state.json`.

Current entry point is `publish.mjs`; `publisher-legacy.mjs` retains the former generated-meadow publisher for history. Do not run it for current releases. `release-state.json` pins the setup template, preflight baseline, and verified rollback file.

No rendered Roblox client screenshot or phone FPS measurement has been obtained. Headless geometry/file checks verify structure and clearance; they do not establish visual fidelity or measured client performance.

## Verified release

PlaceVersion 192 was published on 2026-10-29 by run 40824601864. Native published-version checks confirmed three separated destinations and spawns, original source geometry counts (city 46,716; forest 1 15,348; current forest 22,425), streaming target 128, native terrain grass, and lighting source 17835285085. Black hole source 7208091524 retained 61 parts, 27 beams and 162 bones with our client renderer. The exact published RBXL was downloaded and checked independently. Old servers were restarted successfully. No rendered-client visual or phone FPS claim is implied by these checks.

### Atmosphere correction — version 193

Run 40878130298 published and verified PlaceVersion 193, then restarted old servers. Persistent overcast replaces the clear inter-storm state. Dusk is baked into Lighting; cloud density and cool aerial perspective remain between showers. The trusted weather server is installed explicitly. Source ancestry is inspected before flattening for foliage classification (6,566 wind-tagged parts), with stronger bounded local wind. Safe visual imports now retain original Light and Attachment data (411 lights across all three source catalogs), no shadow casting, maximum range 32 and brightness 2.5. Source scripts remain excluded. Streaming stays 64/128. These checks confirm data and code presence, not a rendered appearance or phone FPS measurement. City traffic/NPC simulation is outside this correction.

### Night, doors and arrival loading — version 194

Run 40879661031 published PlaceVersion 194, verified the engine representation and exact downloaded file, and restarted old servers. Lighting is now 20:00, brightness 1.15, exposure -0.45 with cool readable ambient illumination, authored Port Gloom night sky texture data, native bloom/specular/color correction and persistent overcast. The original black hole now follows at 280 studs with an independently retained larger visual scale.

Read-only source audit found 37 legacy swing-door assemblies whose stripped weld/BodyPosition scripts previously left them anchored shut. Safe import identifies those assemblies structurally, preserves their hinge pivots and groups all parts in one spatial cell. Our server controller provides ProximityPrompt touch/keyboard interaction, tweened 100-degree opening, server proximity/alive validation and delayed closing while no player is nearby. 222 door parts were verified across 37 groups. 74 helper/hinge objects were removed; helpers are identified from an exact two-statement visibility/collision source pattern without executing it. Furniture and walls remain collision geometry. This does not establish that every facade has an authored accessible interior.

IslandLoadingClient starts in ReplicatedFirst and replaces the default loading screen after its own overlay is mounted. It observes actual world readiness, pending travel, client floor presence, anchor state and GameplayPaused; it uses no fictional percentage/minimum wait. Travel anchors and relocates the player before requesting destination streaming, with readiness overlay during arrival. Warm-cell cloning yields between cells, and native grass conversion is cached per server cell. Streaming remains 64/128.

The requested Wind Effects modules remain in use. Canopy power increased to 1.4 (the source module multiplies power by 0.1 before noise); weather wind is 12 normally/17 in storms, with increased wind-line frequency. Registration retries handle late streamed attributes; local attributes expose registered/active wind counts. Wind classification covers 6,566 source parts, but active animation remains bounded by the existing nearest-object budget. No rendered client, door walkthrough or phone FPS measurement was obtained.

### Cinematic map selector — version 195

Run 40880885747 published and verified PlaceVersion 195 and restarted old servers. The map button is a monochrome folded-map glyph drawn with native UI geometry, with a transparent 48px touch target at the top right. Opening it fades a full-screen gradient from dark on the left to transparent on the right, revealing only three outlined destination choices. Touch/keyboard/gamepad interaction, selected-destination styling, dismissal, server results and request timeouts remain supported. The existing map/travel remotes and spawns are unchanged.

Native post effects now use bloom 0.45/threshold 0.95/size 36, stronger weather-aware contrast, environmental specular and a subtle distance depth effect (near intensity zero). These are Roblox rendering effects, not an injected external shader. Exact-file checks attest UI source, visual revision and depth settings; client visual fidelity and frame rate have not been measured.

### Sea and resident identities — version 197

Run 40882837028 published PlaceVersion 197, constructed and validated all six catalog-dressed R15 appearances in the published-version engine, checked dry ground and avatar clearance with the same placement function used at runtime, asserted city native Water by raycast, downloaded and verified the exact file, and restarted old servers. Resident identities, catalog IDs, behavior and limitations are documented in [RESIDENTS.md](RESIDENTS.md). This verifies appearance construction and placement, not a rendered client walkthrough or frame rate.

### Reserved disaster sessions — version 201

Run 40885713028 published and verified PlaceVersion 201, downloaded and checked the exact file, and restarted old servers. Public Workspace has no maps; geometry and arrivals are held in ServerStorage.MatchWorld until reserved match initialization. Menu supports solo, private groups up to six and a virtual-credit inventory shop. Five disaster modes, NPC escorts/roof seeking, travel lockdown, controlled building destruction and return-to-menu flow are included. Engine checks confirmed four city roof candidates and exact-file checks confirmed 37 destructible spatial building groups. See [SESSIONS-AND-DISASTERS.md](SESSIONS-AND-DISASTERS.md) for behavior, economy, implementation boundaries and live-client validation gaps.

### Forest village adventure — version 205

Run 40897494886 published and verified PlaceVersion 205, downloaded and checked the exact file, and restarted old servers. AdventureForest provides a 6,144-square-stud bounded streamed extension, eight original tree templates with grounded-cover validation, four village building groups, eight named residents, the medicine/missing-child introduction, slow-walk controls, three UFO patrols and original procedural ground threats. Disaster runtime/UI are removed. The black hole, public menu and reserved sessions remain. See [ADVENTURE.md](ADVENTURE.md) for actual content, rendering/runtime boundaries and unverified client playthrough details.
