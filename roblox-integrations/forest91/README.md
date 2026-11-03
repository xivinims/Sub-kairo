# TreeWorld — riverside garden, version 91

Incremental update of native published version 90 in universe 9421311218 / place 118064584465155, branch roblox-publisher.

## Player-facing changes

- Removes the owner-avatar NPC and its controller/client, preserving normal player characters.
- White timber water cottage with a blue gabled slate roof, dormers, open doorway, side windows, flower boxes, veranda, riverbed pilings, kitchen and an antique tea corner. Lake boardwalk and stepping stones add traversals alongside the two existing native arched wooden bridges.
- Softer anime-inspired blue native Terrain water, angular highlights and shoreline foam following measured water/land boundaries. Swimming and river continuity remain native.
- Tiny locally pooled falling leaves, seven verified sound assets for forest, wind, water, rain and material footsteps. Local effects have bounded budgets and proximity culling; grass remains static.
- Rabbits and foxes use the supplied Pack-animals asset 77173958514594. Sampled dry routes avoid collidable terrain, trees and scenery; local body-group gait and proximity culling avoid server AI cost.
- Rain starts 90 seconds after server startup, lasts 120 seconds, and repeats every 480 seconds. Players receive a pastel umbrella. Two active users within five studs share one visible canopy at the midpoint. R15 uses hand IK; R6 uses a raised-arm pose. Tools restore joints and remove holding constraints on unequip/destruction. Sharing never moves or anchors character roots.
- Four detailed antique tea settings with 16 chairs facing their tables, cake, strawberries, utensils and a garden parasol. Sip animation cleanup cancels obsolete grip/joint tweens and delayed callbacks.

## Validation scope

Stage and fresh published-place checks exercise actual imported native geometry, voxel channel preservation, grass coverage, foliage support points, walkway collision, audio loading, native seat weld orientation in R6/R15, umbrella midpoint convergence and unequip cleanup on two real rig models. Imported animal source scripts/joints are removed; the game uses its reviewed controller.

No Roblox client rendered screenshot, real multiplayer playtest, or 3 GB phone FPS/memory measurement is available. Reference photos guided the geometry and palette; visual equality and flawless animation are not claimed. IK construction and cleanup are tested, while final rendered hand contact, tea sipping and mobile rain/leaf appearance need client observation.

`stage.luau` executes without saving. `install.luau` saves only after all native tests pass. `verify.luau` starts a fresh version 91 execution session and reruns the checks. Re-running an installer against another place version is rejected.
