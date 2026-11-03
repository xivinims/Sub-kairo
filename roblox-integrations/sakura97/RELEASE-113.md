# XN-VOICE release 113

- Original uploaded XN-VOICE PNG: Image 89648072626653, unchanged source in branding/xn-voice.png. Roblox moderation applies.
- Calm translucent charcoal menu, rounded settings, separate top-right credits button, creator ch_ckz2n. Original Tomiasz menu asset retained; imported menu Roblox logo replaced. Native Roblox CoreGui remains available.
- Exact requested menu click, void music and friend join audio IDs. Local friendship queries and viewer-only markers; no notification for friends already present when joining.
- Manual Voltar in void, validated server recovery to the fixed spawn, duplicate request guard and 45-second server fallback. Music destroyed when sequence ends or character respawns.
- Grass uses the same exact original animated mesh. Tile overlap 1.28 -> 1.65 (~66% greater density per area); unchanged 96 mobile/240 desktop mesh budget. Ground raycasts no longer blocked by the canopy.
- Tree burial 2 -> 6 studs. Full map streaming remains disabled.
- Loading waits for initial replication, map/tree/spawn/grass/lighting content and initial grass allocation before opening menu. Map failures offer retry. Optional audio/logo failures cannot lock players out.
- Eight settings: quality, wind, grass interaction, leaves, nametags, menu clicks, void music, friend alerts.
- Map and menu now validated and saved in one atomic place publication.

Validation: Roblox engine syntax parsing, persisted instance assertions, actual grass wind/foot/pooling runtime tests. Headless validation cannot establish visual appearance, client audio playback, friendship with two accounts, or phone FPS. Those need a live Roblox client.
