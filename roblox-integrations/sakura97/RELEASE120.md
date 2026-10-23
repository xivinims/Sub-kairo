# Survivers — Jason release 120

## Current scope
- Only Horror Map 79671648850902 and original Jason 125165599816440.
- Preserve the published JediLibrary lobby and its edits. Open original shutters, ground the lobby spawn near the entrance.
- Server-observed door admission, up to 8 participants; lobby players remain optional. 220 second rounds, 30 second intermission.
- When at least 8 eligible players have queued through the door, 1/3 chance of a player-controlled Jason. Only one killer controller. Restore avatar when the round ends.
- Local arena entrance door closes after entry; server prevents crossing back through it.
- Jason patrol, hearing, line-of-sight pursuit, last-seen search, blocked/stuck path recomputation, validated melee windup and cooldown.
- All 17 original Jason sequences retained as compact exact CFrame data. Locomotion and attack use original clips. Crouch Idle/Walk from 134326820545987.
- Exact uploaded SURVIVERS logo SHA-256: 286b7e57276a5d593b38c10c3a4cd41518d027c0e9346dfa6db3daf36521897e. Decal 136450401317962, resolved texture 99002027743613.
- Gray double-ring circular right-side mobile controls, transparent timers, menu icon below Roblox controls, rounded menus with muted red accents.
- Spectator camera filters dead/missing/Jason targets and restores the local character when leaving.

## Verification
Publisher validates Luau syntax, 30 connected ground points, exact assets, actual server controller through deterministic player/clock adapters, client HUD/spectator logic, player Jason role/combat/avatar cleanup, and actual AI perception/cooldown code before saving. It then reopens the published place to verify persistence.

Run the existing Actions workflow normally to validate and publish atomically. Set SURVIVERS_DRY_RUN=1 to validate without saving. The installer aborts if the existing lobby/door is missing rather than replacing user work.

## Limits
Automated headless engine tests are not a visual Roblox Player or physical mobile-device playtest. Final artwork framing, touch comfort and phone FPS require a live client review. Asset permission or moderation changes can affect future loads; imported arbitrary scripts never execute.
