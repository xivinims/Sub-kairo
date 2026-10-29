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
