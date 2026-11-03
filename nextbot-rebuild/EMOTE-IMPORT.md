# User-supplied R6 pack integration

Original upload: 20+ R6 Emote Animations(1).rbxm. Stored byte-for-byte at assets/user-r6-emotes.rbxm.

Binary inspection found 19 KeyframeSequences, 4,453 keyframes and 33,690 poses; no Sound, Animation, Script, LocalScript or ModuleScript instances. The title's 20+ count does not match the actual sequence count.

The build copies all 19 sequences without modifying their keyframes, poses, easing or loop flags. IDs are stable slugs derived from their original names. Original model is kept as source, not inserted with its dummy into the map.

Catalog/shop integration and atomic DataStore purchase/equip logic are included. Provisional price: 250 internal coins each (chosen configuration, not an Evade price). No Robux transaction. Coins default to zero; earning/progression integration remains pending. Existing economy is not overwritten because NextbotEmotes_v1 is a separate store. Six equip slots are stored persistently. Selecting an inventory slot sets the slot used by EQUIPAR; clicking an equipped slot starts its emote.

R6 Pose playback uses Motor6D.Transform on each observing client, synchronized with server timestamps. Movement, jump, death, character replacement and nonloop clip completion cancel playback. This is a custom runtime preserving the source pose data, not Roblox Animator playback; exact easing/replication/streaming behavior needs in-engine validation. R15 playback is rejected.

Music: the file contains none. Jumpstyle is configured with Creator Store audio 1839246711 (https://create.roblox.com/store/asset/1839246711/Jumpstyle), a selected accompaniment, not a verified original Evade track. Playback permissions and beat alignment have not been verified. The other 18 sound IDs are unresolved rather than fabricated. Playback supports per-emote audio, spatial range, common start timestamp, loop and EmoteVolume settings group.

Tests: duplicate purchases, insufficient funds, invalid prices, slot bounds, unowned equip rejection, no mutation of input balance. File count and compilation asserted by build. The full game is not published or visually certified identical.
