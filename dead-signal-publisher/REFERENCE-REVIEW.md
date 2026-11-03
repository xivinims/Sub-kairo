# Revision 6 — reference review and actual scope

Reviewed all seven attached JPEGs from scratch paths, including the Chapter 3 menu and GrabPack corridor. Searched Poppy Playtime and The Mimic environment references. This is a targeted reference pass; it is not a claim of viewing 1,000 photographs or performing 10–70 hours of work.

## Applied observations

- Uploaded menu: small chapter caption, quoted title, short description, horizontal rule, five thin outlined buttons on the left; a red-lit creature scene on the right. Implemented with a persistent original 3D stage and native Roblox ScreenGui, not the screenshot as a fake full-screen menu.
- Factory reception: primary colour inserts in worn cream tiles, a reception focal point, dark periphery and restrained pools of light. Existing supplied floor and authored reception composition are retained.
- Service corridor: long pale walls with a narrow red band, ceiling fixtures and sparse damage/debris at edges. Existing scenic pass is retained.
- The Mimic references: restrained lighting, readable silhouettes, warm/cool separation and texture contrast; no claim to have reproduced its maps.

## Structural fixes and controls

The previous importer deliberately disabled visual collision. Revision 6 assigns explicit collision roles. Static meshes now collide and answer raycasts; doors, stairs and portable cells use their existing named gameplay proxies. An avatar-sized Blockcast follows the chapter's full route before publication.

User changed the previous no-GrabPack requirement. Selected `HandL`, `HandL2`, `Gunl`, `Gunl2` from asset 10468403169 are extracted through SafeAssetImporter. Third-party scripts, animations, sounds, constraints and prompts are removed. New server-authoritative service implements a 42-stud ray, rate limiting, hit occlusion, remote interaction, limited cart pulling with obstruction casts, and an eight-second two-hand power bridge. The original chapter cable puzzles remain available. Mouse buttons / gamepad triggers / two separate touch buttons operate the hands; R retracts them.

## Audio status

No authenticated, usable original Poppy Playtime footstep recording was obtained. Do not describe the replacement material-aware stock Roblox footsteps as original Poppy audio. The model inspection found no audio in the selected GrabPack source. An original soundtrack/audio import remains pending verified files/asset permissions.

## Sources

- Official Chapter 1 screenshot gallery: https://www.nintendo.com/us/store/products/poppy-playtime-chapter-1-switch/
- Official Chapter 3 Steam gallery: https://store.steampowered.com/app/2555190/
- Roblox collision behaviour: https://create.roblox.com/docs/parts/meshes
- Roblox Blockcast: https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Blockcast
- Roblox audio assets and usage permissions: https://create.roblox.com/docs/audio/assets
- Mob fan-content terms: https://www.mobentertainment.com/fan-content

Engine validation is distinct from a rendered client playthrough. No pixel-perfect menu comparison, mobile playtest or finished commercial-game visual quality is claimed.


## Follow-up: hand pairing correction (not released)

User reported reversed GrabPack hands. The audited source places HandL2 at X=-140.253 and HandL at X=-136.088; the previous mapping assigned the right-side source mesh to the blue left viewmodel and the left-side source mesh to the red right viewmodel. Corrected the source pairing in grabpack-install.luau. No axis rotation is guessed from the report alone. This change needs rendered inspection before publication; server ray tests do not validate palm-facing direction or hand appearance.
