# Island interaction and void return

Target remains universe 9419478735 / place 79738710219521; map stays 260 studs.

- StreamingEnabled is now false so complete island geometry is loaded. Original grass remains one mesh variant, pooled up to 96 near touch players or 240 on desktop. The original SkinnedGrass wind/collision module is retained, with pooling spatial-index maintenance and a zero-vector fix. Contacts use R6/R15 feet instead of hip position. Simulation uses GlobalWind.
- Wind Effects 11946229834 is cloned with all nested module dependencies (the previous installer copied only top-level Source, breaking Settings/Octree requires).
- Tree base sinks 2 studs into its ground (previously 0.55). Invisible canopy emitter drives 14 pooled, wind-drifted leaf shapes; no reliance on an unavailable leaf texture.
- Exact Mystical Spawn Point 110144096035671 is anchored and grounded; the sole enabled spawn is fixed just above its stone surface. Exact Player Nametags 123212555736117 billboard is used, with duplicate default humanoid names suppressed.
- Original Tomiasz menu moves left, loses its backing panel, gains denser responsive buttons, press feedback, scrolling settings for graphics, wind, grass interaction, leaves, nametags and menu sounds. Settings last through respawns in the session.
- Falling below the island starts a server-controlled 8.5-second return sequence: black backdrop, avatar in a WorldModel, swim-idle animation from the character when available and procedural floating fallback, three original Portuguese messages. Server freezes falling and returns to fixed spawn; client fails open after ten seconds and cleans up on respawn. No client requests can choose a teleport destination.

Validation: engine parses client/server source before publication; live DataModel checks verify assets, grounding, full-map setting, module dependencies, GUI structure and persisted place version. A runtime test exercises actual grass wind/foot bending and spatial reindexing. Responsive menu bounds checked at five viewports. These headless checks do not constitute visual device or FPS testing.
