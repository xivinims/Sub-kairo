## Original weapon recovery — verified version 220

Build `still-here-weapons-v5`, workflow 40984680051. Published and verified through exact-version Roblox execution, exact downloaded source comparison and restartServers. 377 unchanged original bodies, 14 marked compatibility files.

Original weapon equip no longer waits forever for animation lengths; after 3 seconds unavailable animations warn without blocking viewmodel/controls. Character-contained tools are registered and missed equip events reconciled. R15 torso/joint arrival is awaited. Original gun input uses a held trigger flag for touch auto/burst, fixes the sprint method call, cancels on focus/settings loss and blocks starting fire through settings. Original mobile button assets are placed in their own screen layer, away from JumpButton; Shoot, ADS, Reload, Sprint, equipped-only Crouch. Firemode remains on keyboard B.

Original M4A1 and Deagle world pickups are anchored until collected; proximity pickup validates life and distance. World supply replenishes after 30 seconds. Native verification now actually runs pickup spawning and confirms both prompts and supporting surface rays. No replacement shooting implementation introduced.

Executed regression: source gun callbacks with touch input and no pressed mouse; auto fire, semi-auto duplicate begin suppression, release/cancel, settings modal blocking, reload, aim toggle and unbind. Movement/settings tests passed again. Actual mobile rendering and full multiplayer combat remain untested; original animation asset availability depends on Roblox permissions and is not claimed resolved.

## Interface and stability — verified version 219

Build `still-here-interface-v4`, workflow 40982385309. Published, executed exact live version, downloaded and compared original sources, restarted servers. All 7 source missions and original weapon factory still verify. Original bodies: 378 unchanged; 13 explicitly marked compatibility files.

- R15 crouch restores standing height; unarmed crouch hidden/blocked; duplicate movement, forced-body visibility and R6 mouse tilt disabled. Camera effects ordered after Roblox camera; locomotion bob/FOV jump impulses removed. Jump height 7.2 and climbing enabled. Only audited SUV_Damaged wreck and its random rattles removed.
- Scrollable responsive main menu; Credits replaces Shop. Multiplayer side panel: local-lobby groups, private code entry, capacity 2–6 and optional friends-only admission.
- Shared side-panel preferences in menu and match: volume, brightness, FOV, mouse sensitivity, shadows, bloom, mission HUD and loading phrases. Save & Back writes validated settings to StillHerePreferences_v1. Cancel reverts the open panel's changes. Mouse sensitivity setting affects mouse, not native touch look.
- Immediate black loading cover in both modes; only corner Carregando… label. Match phrases appear rarely after 12 seconds, with no artificial loading extension. Source Starting Sequence disabled; source title/quote/credits visuals hidden. Original story transitions still exist.
- Mission text at top driven by replicated source state, including late join snapshots.

Tests executed: actual shipped movement methods in deterministic harness (20 crouch cycles, unarmed gate, 2–240 FPS interpolation, cinematic camera); settings malformed input, clamps, false booleans, write throttling, fresh-session read and simulated failed write. Native server validation passed on version 219. No rendered Roblox client is available here: mobile visual fit, touch interactions, multiplayer teleports and full campaign are not end-to-end playtested. Group list is for the current public lobby, not a cross-server directory.

## Menu reference update — version 217

Build `still-here-original-menu-v2`: title and borderless navigation on the right, muted serif typography, script-free original foyer in a ViewportFrame, dark edge gradients. Solo/group/shop remote actions remain unchanged. Decorative tags are removed before campaign initialization. Native verification and exact original-source comparison passed; servers restarted. Client-rendered appearance and touch interaction have not been visually tested; pixel-identical reproduction is not claimed.

# Original systems restoration

Published and independently verified: **PlaceVersion 216**, build `still-here-original-systems-v1`, run 40946132355. Old servers restarted. Engine checks: 390 original source containers visible to the runtime, seven mission roots, 22,670 content parts, 3,999 tagged content instances, original door setup, original FPS server library initialization, and original M4A1/Deagle factories. Downloaded-file comparison: 383 preserved original source bodies plus eight explicitly marked compatibility changes. The serialized file also retains one Studio analytics module outside the runtime bundle.

This release uses asset 7902470429 as the place base, retaining Workspace.Content, all original room hierarchy/tags/triggers, source ServerStorage.Corrupt rooms and props, ReplicatedFirst modules, event/mission/state controllers, seven source GUI templates, original character interaction scripts, audio and authored animation data. The previous flattened map and MansionRuntime/MansionUIClient/CombatRuntime/CombatClient controllers are absent.

Asset 15864801103 contributes ReplicatedStorage.Library, Game, Assets and Remotes, ServerStorage.Library, original Weapons/Other server scripts, MainHud, MobileButtons, GuiModule, client gameplay controllers and character scripts. The shooting range map is excluded. Original modules create the mansion pickups and handle equipping, aiming, recoil, viewmodel animation, reload and shooting. New touch proximity prompts only route pickup into the original tool workflow.

Original scripts carry OriginalAsset, OriginalPath and OriginalLength attributes. The serialized OriginalScriptManifest identifies each retained original source and any compatibility modification. Publication independently downloads the exact published place and compares preserved source bodies against the original source files.

Compatibility changes: match-mode startup guards; production configuration for this universe; use existing reserved match instead of starting another original lobby; R15 torso/shoulder names in FPS third-person attachment logic; idempotent collision registration; keep standard touch movement from being overwritten by a keyboard-only source script; respect original mansion cinematic camera ownership; avoid desktop-only missing touch-button setup. Original FPS R6 locomotion controller is retained disabled because mansion grabbing needs R15; weapon viewmodel animation controllers/data remain original.

Disabled demo entry points: source admin chat give command, automatic give-all-weapons on spawn, PvP round progression, give-weapon debug UI and shooting range intro. Their bodies remain archived in the place. The Duvall Studio SocialInteractions installer/package is excluded. No external numeric require or loadstring is accepted by the assembler.

Beyond the Dark sky effect remains. The public menu/session bridge remains separate from the original in-match GUI. No custom central sprint or return-to-menu button is installed.

Validation includes source compilation, original mission config references, original door-controller initialization in Roblox, GUI/runtime dependency checks, and source-body comparisons on the downloaded published file. A Roblox rendered client, multiuser session walkthrough, audio/animation permissions on each client, and complete original campaign playthrough are not available in this environment and must not be claimed as tested.

The requested new salt/visitor/breaker story and reference-based menu redesign are not part of this original-system restoration release.
