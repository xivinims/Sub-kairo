# Original systems restoration

This release uses asset 7902470429 as the place base, retaining Workspace.Content, all original room hierarchy/tags/triggers, source ServerStorage.Corrupt rooms and props, ReplicatedFirst modules, event/mission/state controllers, seven source GUI templates, original character interaction scripts, audio and authored animation data. The previous flattened map and MansionRuntime/MansionUIClient/CombatRuntime/CombatClient controllers are absent.

Asset 15864801103 contributes ReplicatedStorage.Library, Game, Assets and Remotes, ServerStorage.Library, original Weapons/Other server scripts, MainHud, MobileButtons, GuiModule, client gameplay controllers and character scripts. The shooting range map is excluded. Original modules create the mansion pickups and handle equipping, aiming, recoil, viewmodel animation, reload and shooting. New touch proximity prompts only route pickup into the original tool workflow.

Original scripts carry OriginalAsset, OriginalPath and OriginalLength attributes. The serialized OriginalScriptManifest identifies each retained original source and any compatibility modification. Publication independently downloads the exact published place and compares preserved source bodies against the original source files.

Compatibility changes: match-mode startup guards; production configuration for this universe; use existing reserved match instead of starting another original lobby; R15 torso/shoulder names in FPS third-person attachment logic; idempotent collision registration; keep standard touch movement from being overwritten by a keyboard-only source script; respect original mansion cinematic camera ownership; avoid desktop-only missing touch-button setup. Original FPS R6 locomotion controller is retained disabled because mansion grabbing needs R15; weapon viewmodel animation controllers/data remain original.

Disabled demo entry points: source admin chat give command, automatic give-all-weapons on spawn, PvP round progression, give-weapon debug UI and shooting range intro. Their bodies remain archived in the place. The Duvall Studio SocialInteractions installer/package is excluded. No external numeric require or loadstring is accepted by the assembler.

Beyond the Dark sky effect remains. The public menu/session bridge remains separate from the original in-match GUI. No custom central sprint or return-to-menu button is installed.

Validation includes source compilation, original mission config references, original door-controller initialization in Roblox, GUI/runtime dependency checks, and source-body comparisons on the downloaded published file. A Roblox rendered client, multiuser session walkthrough, audio/animation permissions on each client, and complete original campaign playthrough are not available in this environment and must not be claimed as tested.

The requested new salt/visitor/breaker story and reference-based menu redesign are not part of this original-system restoration release.
