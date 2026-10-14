# TreeWorld — global seasons and reference-based forest landmarks

Universe `9421311218`; place `118064584465155`; branch `roblox-publisher`. Incremental installer from saved version 89, targeting version 90.

The entire forest starts green in spring. One global season applies everywhere; seasons advance every ten minutes, with 35-second plant/leaf tint transitions in eighteen bounded steps. The terrain material changes in yielded chunks without changing solid/liquid occupancy or the river bank geometry. Autumn changes grass to warm LeafyGrass and reduces flowers; winter uses Snow and hides low plants/grass; spring restores them. There are no regional seasonal quadrants. Native Forest Pack textures and contact profiles remain in use.

Grass still uses the selected SkinnedGrass asset `87377915371959`, on the same overlapping root grid. The client places its bones directly onto sampled terrain and never runs wind/collision animation on the grass. Trees retain subtle wind using the supplied Wind Effects `11946229834`. Season updates avoid creating thousands of per-frame server color tweens. The original day/night cycle and reviewed native lighting preset `8490242417` are retained.

The main limestone arcade has fluted columns, vines, open arches and a broken roof. Additional sites are a mossy sanctuary with stairs and a circular portico, a weathered stone torii glade, and a broken watchtower with an imported armored skeleton. Each site uses dry terrain samples and retaining foundations. Tea patios and paths keep furniture on a floor. The two crossings now use a native arched wooden bridge with continuous curved collision fitted to its planks and masonry supports extending to the river bed.

The owner NPC is rebuilt from `GetHumanoidDescriptionFromUserIdAsync(8344738123)` using the current body, clothes, hair and layered accessories. The exact supplied share link resolves to Cat Bath catalog item `127049078545834`, containing animation `92824429927180`. It is validated on R15. Its lower torso is aligned to the cut trunk using the actual sampled animation pose; its root stays anchored. Passing/standing nearby triggers spatial Hi/Yay sounds with individual and global cooldowns. The dialogue UI, TalkPrompt, dialogue RemoteEvent and old R6 wave/neck overrides are removed so greetings preserve the emote.

Three tea tables use native tablecloth/book/candle geometry and twelve imported Victorian chairs with authored seats/backrests. Sitting gives the player a welded cup Tool. Activation lifts the drinking arm/cup gently; the seat, torso and legs remain controlled by the seat. Unequip/destruction cancels joint tweens and restores their original C0. Server distance checks and cooldowns protect the interaction.

The exact requested JeremyTheDev loading/menu UI is imported and named TreeWorld. Its script is adapted to three-second loading, touch-friendly Entrar button, separate fixed scenic camera and reliable control/core-UI restoration. ResetOnSpawn is false; the menu does not anchor or relocate player avatars. Imported scripts are inspected, then stripped before selected models are placed.

## Source assets and credits

| Asset | Role | Creator/source |
| --- | --- | --- |
| 6432306802 | PBR forest vegetation and native props | Roblox Forest Pack |
| 87377915371959 | Static grass geometry | Requested SkinnedGrass |
| 11946229834 | Subtle tree wind | Requested Wind Effects |
| 17216750157 | Loading screen and main menu GUI | Jeremy_TheDev |
| 127049078545834 / 92824429927180 | Cat Bath emote / underlying animation | Kursed Creations |
| 8474839527 | Victorian chair, five mesh parts | The_Spy5606 |
| 18831822897 | Tea table, cloth, book and candles | this_elonmust |
| 117077041338395 | Low Arched Bridge | lil_timmy0123 |
| 882493119 | Armored skeleton decoration | endro555 |

Assets were read through native LoadAssetAsync and public Creator Store metadata. No models or emotes were purchased. Scripts/audio in imported decoration packs are stripped. Existing requested voice samples are retained and checked for load/playback duration.

## Validation and limits

`stage.luau` executes without saving. `install.luau` saves only after native tests pass. `verify.luau` checks the saved version in a new execution session. Tests cover global season timing, actual phase material changes, unchanged liquid/solid channels, grass suppression in winter, bridge walk collision/landings, foundation contact, chair facing/floor placement, tea links, current R15 appearance, exact emote playback and trunk alignment, proximity greeting cooldowns, source compilation and inherited forest/grass/river regressions.

These checks do not provide a screenshot from a rendered Roblox client or measurements on the user's 3GB phone. Reference fidelity, full player sipping interaction and mobile FPS require a client playtest. The reference images guide geometry, color and composition; they are not presented as captured output of this build.
