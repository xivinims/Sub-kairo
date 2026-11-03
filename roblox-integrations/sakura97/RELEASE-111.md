# Compact island and Tomiasz menu

Target: universe 9419478735, place 79738710219521.

The 1,478-stud island is now 260 studs wide at its longest extent. The requested tree (4617134997) is grounded and scaled to 64 studs. Only the green Studio mesh from SkinnedGrass (87377915371959 / mesh 80159239673273) is used; the GrassCard variant is excluded. Spacing and origin come from measured bone roots, with overlap, raycast placement on green terrain and a recycled pool capped at 96 meshes on touch devices or 240 on desktop. Grass is populated as the player moves, not instantiated across the entire map simultaneously. Wind deformation is restricted to nearby patches.

Flat Shader 86563808574363 is imported as six Lighting objects. Blur, depth of field and sun rays default off on touch devices; color correction, sky and atmosphere remain. The quality button can enable the heavier effects.

After the map is saved and verified, the original Tomiasz menu 84828163072141 is installed, with responsive sizing, Portuguese buttons, camera positions adapted to this island, credits, a quality setting and return-to-menu. Original negative GUI dimensions are fixed. Loading preloads only the grass template and has a continue button and ten-second escape timer.

`publish.mjs` runs map publication then menu publication, serially. Each phase verifies before SavePlaceAsync and reopens the saved place to verify persistence. No API keys are stored in source. The previous automatic experience renaming has been removed.

Validation: Roblox Open Cloud assertions cover asset identity, map size, tree size/grounding, spawn grounding, single grass variant/bone count, grid planning, shader objects and menu structure. LocalScript syntax compilation is attempted when exposed by the cloud execution context. Open Cloud does not expose StreamingTargetRadius, so radius changes are best-effort and not claimed verified. Headless checks do not measure on-device FPS, visual appearance or real touch input; those require Roblox Player.
