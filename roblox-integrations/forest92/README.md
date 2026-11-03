# TreeWorld repair — version 92

Target: universe 9421311218, place 118064584465155. Incremental native build from published version 91, branch roblox-publisher.

## Corrections

- Replace custom SkinnedGrass rendering with Roblox Terrain decoration. No per-player grid of hundreds of 100-bone grass models. Native grass length 0.4; subtle global wind. Standard native voxel Grass material supplies the ground, and existing actual PBR wildflowers remain on soil.
- Ground visible placed trunk geometry directly with native mesh ray queries and embed the lower contacts 0.9 studs. Plants use placed geometry ray samples; flat alpha-card flowers without an underside use their placed bounds, with 0.18-stud burial. No stored source scale is treated as proof of grounding.
- Rebuild both stream bridges with visibly solid wooden planks, rails, carved posts and braces. All bridge parts are visible, queryable and collidable; no separate invisible deck. Match endpoints to real bank elevations and probe the walking width at both edges and the center. Repair the boardwalk's collision as well.
- Four tea tables are limited to 5.6 studs wide and less than four studs tall; imported carved chairs face their table. Clicking/tapping a cup gives an equipped cup with no text notification. Existing drinking pose remains, with cancellation/restore on unequip. No automatic cup-serving on sitting and no teapot proximity interaction.
- Move the three smaller ruins at least 160 studs apart from each other and the main courtyard. Remove the main courtyard's descending stair path; use a grassy sloped approach and a distinct old staircase climbing a hill to the distant mossy sanctuary.
- Remove lighting/mist selection. Apply mist as absolute values with a distance fade, preventing the previous per-frame accumulation. No tea notices or mood notices exist.
- Four campfires get grounded stone rings, split logs, charcoal and ash. Keep seven actual verified audio assets; forest and stream ambience are audible, footsteps reduced from volume 0.23 to 0.055. Nearby falling leaves use a maximum of 14 simple local pieces on phones instead of barely visible remote micro-leaves.
- Remove full-forest WindShake and reduce local fauna/effect radius and update rate. Native streaming uses a minimum radius of 64 and target radius of 128. Imported PBR meshes use Performance render fidelity; bloom is disabled.

## Native file publication

Terrain.Decoration, Terrain.GrassLength and streaming distances are editor-only properties. The previous protected setter attempts never enabled actual terrain grass. The build now uses the documented SerializationService to export native instances, preserves their binary model/terrain chunks, restores place service roots, modifies only the required native scalar property chunks, and uploads the resulting native binary place through Roblox's Place Publishing API. No API key is read or written to source/logs.

The exporter captures existing runtime, scripts, native terrain channels, models, lighting and GUI, plus service settings for camera, movement, gravity and rendering. The decoder validates LZ4 chunks, classes, root ownership, scalar types and the grass/streaming values before publishing. A fresh native session checks the saved scene again and reads actual serialized Terrain settings to prove Decoration=true and GrassLength=0.4.

## Verification and limits

Stage tests measure actual lower contacts, visible/solid bridge walking surfaces, bank alignment, compact table bounds, seat direction, direct cup serving to a real R6 test rig, stable fog after repeated updates, accessible sound assets, continuous river water and script compilation. Source cards with no underside are explicitly identified as bounding-box grounded plants.

Tests do not provide a rendered Roblox client screenshot, real-phone frame rate/memory measurements, or a guarantee of matching the photos exactly. Final leaf visibility, tea-sip hand contact, animation appearance and performance on a 3 GB phone still need actual client observation. The native file's shader and PBR objects are checked after upload; any upload/verification failure is reported rather than treating a staged file as published.
