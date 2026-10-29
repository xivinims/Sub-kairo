# Still Here — native grass meadow

Exclusive universe 9421311218 / place 118064584465155 and branch dead-signal-publisher.

Published build: still-here-light-weather-v8, PlaceVersion 174. Streaming 64/192, native grass and audited wind/rain scripts were confirmed by fresh engine inspection and an independent download of that exact version. The downloaded published file was independently deserialized and checked: Terrain.Decoration=true, Terrain.GrassLength=0.85, zero geometry grass models. 99,490 old grass models were removed; 2,917 trees and 7,562 flower models remain. The file size fell from 23,101,448 bytes to 3,250,516 bytes.

The meadow has no roads, creek, props, menu, custom loading screen or storm system. Terrain materials were converted to Grass over the full 2,048 × 2,048 stud field. Native blades use Roblox terrain decoration, not imported grass geometry. Trees and flowers remain audited geometry selections.

The lighting now has a pale gold Atmosphere decay/color, lower haze and density, brighter ambient fill, reduced contrast, and a normal sky. This removes the former dark horizon treatment.

## Publishing

Terrain.Decoration and GrassLength are NotScriptable. The publisher first performs its normal source assembly, then native-grass.mjs downloads the place using the authorized Asset Delivery API, edits the serialized place with pinned Lune 0.11.1 (SHA-256 checked), verifies those two properties survive serialization, and uploads the edited binary using the official Place Publishing API. A bounded Luau pass converts terrain materials to Grass and saves it. Fresh engine validation confirms trees, flowers and zero grass models; a second download of that exact saved version confirms native terrain properties. Servers restart after these checks.

The downloader requires legacy-asset:manage. Native grass rendering also follows Roblox client graphics quality. No rendered client screenshot was available during this verification.

## Weather and loading pass (v8)

Build still-here-light-weather-v8 lowers StreamingTargetRadius from 1024 to 192, keeps StreamingMinRadius=64, uses Opportunistic eviction and PauseOutsideLoadedArea. These non-scriptable settings are written into the serialized place.

Wind comes from selected, audited modules of user asset 11946229834 (WindShake, WindLines and local dependencies), integrated without its demo GUI. Animation limits are 32 nearby objects on touch / 64 on desktop, within 96 studs, with 20 Hz movement. GlobalWind animates native terrain grass and clouds.

Rain is camera-local at 30 Hz with 90 streaks on touch / 180 on desktop, plus a short distant lightning bolt and thunder. The storm cycle starts roughly 22–30 seconds after a server starts, then alternates with clear periods. Storm colors remain pale grey; clear periods restore the brighter golden palette. Native Bloom, SunRays and ColorCorrection provide the requested graphics effects without an external shader injector.

## Altar and distant landmark expansion

`still-here-altar-botanical-v1` extends the existing forest without replacing its terrain, lighting, wind, or weather. The published version 176 was verified in the engine and downloaded back for serialized native grass/script verification.

- Altar Spawn 76722373571113: source has 37 meshes and no scripts. Removed all 28 text meshes, stock particle/decal decorations, and imported spawn behavior; retained nine architectural meshes. Only one neutral spawn remains, with a raycast-confirmed mesh floor and six studs of overhead clearance.
- Own client arrival animation: temporary occluded character highlight and a 32-segment expanding ring; no remote and no persistent effect. Own server creates distance-limited display name / username tags after each character spawn.
- Port Gloom 186677844 is a place, not an insertable model. Offline audit found 57,000+ parts and 230 scripts/local scripts. Only the complete `ShipWreck` selection (334 static parts, 380 total visual instances) is copied. Located 1,657 studs from arrival within the existing terrain; overlaps removed. The full port, NPCs, sounds and scripts are excluded.
- Roblox Realistic Forest Demo 5326950832: selected individual fern / flowering models only, placed as 154 small botanical groups and grounded individually with terrain raycasts. No grass meshes, demo terrain, scripts, interfaces, animals or weather are imported.
- Realistic Forest 88883160098456 was inspected but not imported: contains 564 workspace scripts, 37 modules, night club, shops and other unrelated content.
- `SafeAssetImporterFile.luau` is the offline companion to `base/server/SafeAssetImporter.luau`: explicit approved IDs and visual child whitelist, strips all runtime content before geometry reaches the destination DataModel. Lune deserializes source places without executing their code.
- Expansion sources are retained in `forest-expansion-*` and integrated into `publish.mjs` after native terrain repair. `asset-probe.trigger` can run expansion publish or a trusted client source patch. Verification checks the current Roblox PlaceVersion, native grass, exact client/server sources and the distant landmark, then restarts old servers.

Visual client appearance and phone FPS still require an actual Roblox client session; the engine/file checks do not substitute for a screenshot or FPS measurement.
