# Converted SpringChunSam source resources

Source revision: `344abbe7eb26fcd6b3510858d749584f25f4cc67`.

Roblox place version **158** contains `ServerStorage.SpringSourceConverted`, build `dead-signal-source-port-assets-v1`. These are staged resources, not an activated replacement game.

- Miss Delight and weapon: model asset `98751037263074`; 3 parts, 124 bones and 2 motors, normalized to 9 studs high in the staged copy.
- Five original menu-button PNGs uploaded to the creator account, with references in SourceMenuImages. They contain Korean source labels; no functional menu was invented from them.
- Five native Animation assets: doorkick `95129109923210`, jumpscare `73053040272676`, reference pose `113277101943291`, smash `123865487538256`, walk `83841843276273`.

The conversion samples source FBX rotation channels at 24 FPS and remaps them to the imported weighted-bone hierarchy/bind orientation. Root motion and bone translation are excluded. This is not a lossless conversion of every source animation channel.

Native asset inspection verified all five keyframe sequences. Explicit Animator stepping in an isolated Roblox execution session moved **109 bones** for walk and **100 bones** for jumpscare, with track lengths 1.5 and 1.4583 seconds respectively. Explicit stepping is required for this headless check; initial automatic evaluation did not update bone transforms. This verifies native animation evaluation, not rendered quality, foot planting, or synchronization with gameplay.

No source scripts execute. Textures, external sounds and many level/scenery dependencies are still missing from the public repository. `MissingTextures=true` and `GamePortComplete=false` are recorded on the staged folder. The existing map and gameplay are not replaced. Server restart completed after verification.

`upload-spring.mjs` and `upload-animations.mjs` create assets and must not be rerun casually, since that would create duplicate assets. Reports preserve the actual creator-owned asset IDs and published place version. `verify-staged.mjs` performs a read-only animation test and server restart without saving another place version.
