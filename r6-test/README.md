# R6 test arena

Replaces the menu prototype with a 220×200 test floor, boundary walls, two wallrun walls, stairs, cover and six R6 targets. Each target has 100 HP and respawns after five seconds. The existing place is backed up before publishing, stays private, and is rolled back if native verification fails.

## Imported packages

- Bow: original server/client, PlayerModule, animation assets, models, Packet modules and sounds.
- Lantern: original server/client, model and networking modules.
- Sprint with stamina: original character scripts, stamina UI and modules. Script logic is generic Humanoid; external uploaded run animation permissions/rig still need visual validation.
- R6 Wall Run: original controller and all its dependencies; touch uses Roblox's jump button.
- Boogie Woogie: original server, tool and effect assets. Only R6 dummy is used. R15 demo rigs are excluded.
- Dialogue Kit V2.5: original screen UI, sound group, prompts and example dialogue.
- Luminos: original Studio plugin stored in ServerStorage/StudioPacks; its After Rain preset is applied to Lighting. Plugins do not execute as game scripts.
- WallWalk Naruto R6: original pack stored in ServerStorage/StudioPacks, inactive. Its legacy PlayerScriptsLoader calls removed camera methods, including ApplyVRTransform, absent from the supplied bow PlayerModule. Activating it together would break the camera. No source edits were made to hide this incompatibility.
- **Excluded completely:** FREE Swim System and Free Advanced R15 Wall Climb System (R15 animations/rigs).

Every imported source has an OriginalId and SHA-256 attribute. The exact original source is also archived for native byte-for-byte comparisons; build and check verify hashes. Generic R15 fallback code within the original Naruto Animate module remains intact but no R15 character or rig is installed.

## Integration code

`arena-server.luau` manages bot respawn and swept ray collision for the original bow's anchored, CFrame-driven arrows. This avoids depending on physics Touched events for stationary targets. It changes arrow CanTouch externally and applies the same 15 damage, without changing imported source.

`controls-client.luau` adds four circular actions above Roblox's jump button: shoot, lantern, sprint and swap. Buttons call the original packet/module/remote APIs. Swap chooses a visible bot closest to the crosshair. Desktop controls from the originals remain; R toggles both lantern and swap while the Boogie tool is equipped, so use the separate on-screen actions for isolated testing.

## Validation limits

Lune compiles all sources and checks the serialized file. Native verification checks no R15 rigs, unchanged imported sources, required geometry, a floor ray, seven 15-damage arrow hits, death and respawn. This does not substitute for a rendered desktop/mobile playtest. Imported animation/audio IDs remain unchanged; asset ownership permissions can restrict playback.

`build.luau` rebuilds from the exact user uploads in ../upload. The checked-in prebuilt place is self-contained. The GitHub workflow validates that place and backs up/publishes it using the existing Roblox credential. Raw upload files are not needed by CI.
