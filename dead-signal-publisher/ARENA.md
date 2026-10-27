# Dead Signal — Bramble test arena

Active build: `dead-signal-bramble-arena-v1`, universe `9421311218`, place `118064584465155`, branch `dead-signal-publisher` only.

The chapter, menu, GrabPack and previous runtime are removed from the published place. The publisher now assembles only `arena-install`, `arena-animation`, `arena-server`, `arena-client` and `arena-validate`. Previous chapter source is inactive and retained for recoverability in Git.

One clean 160 × 160 floor, invisible edge boundaries, spawn and the selected `LiveEntityBramble` from asset `115602504342753`. SafeAssetImporter.Load strips the two external scripts before selecting the rig. External sounds and animation objects are removed. The actual mesh geometry and all 36 Motor6D joints are retained; only the Root is anchored. No third-party code runs.

Original procedural Motor6D animations cover Idle, Walk, Run and Attack. Walk follows a square route at 7 studs/s; Run pursues a living player at 24 studs/s. Attack approaches the requesting player, reaches with both arms, anchors and lifts the avatar in front of the torso, closes the fingers, holds and defeats the avatar after 2.4 seconds, then restores control flags and returns to idle. Resets/disconnects release captures; a 3-second cooldown prevents immediate repeated grabs. Arm targeting supplements the attack pose. These are custom test animations, not the original kit animation clips.

Four top-of-screen buttons support touch and mouse; PC shortcuts 1–4 match them. Idle is the default. Classic Roblox camera allows first-person or an external view for rig inspection. No saved chapter state is read or overwritten.

Validation checks the new build marker, correct asset provenance, old chapter absence, root, floor, spawn, client/server/control objects, connected geometry, at least 30 intact motors, no executable content inside the imported model, and distinct executable animation poses. Validation runs before SavePlaceAsync and again in a fresh execution session against the published version. This is engine validation, not a rendered client playtest.

## Requested map and capture revision 2

Active build `dead-signal-bramble-map-v2` replaces the blank test floor with the exact user-selected map `18509954401` (2,670 source BaseParts, zero source scripts in the audit). Imported with SafeAssetImporter before parenting, then external audio, animations, interactions and packages are removed. The main audited floor is translated to world zero without changing source orientation. Tall-clearance ground sampling and swept collision select connected spawn/creature points and patrol targets. The rig initially faces the spawn. Native touch-compatible power prompt sits beside the spawn.

Power starts off. Enabling the switch sends a bounded series of light pulses, then wakes the creature into patrol; nearby visible players trigger pursuit. Turning power off stops the creature and cancels a capture. Pathfinding is throttled to 1.2 seconds, direct routes and movement are swept against solid map geometry, and floor support is checked before each move. Nearby lights activate locally rather than lighting all distant map geometry.

The kit's Idle/Walk/Attack keyframe assets failed to load in the experience during the read-only probe. They are not used or claimed as working. Custom animation now uses deterministic forward kinematics and measured two-segment arm lengths rather than guessed dimensions/physics feedback. Capture has anticipation, contact, lift, grip and a short face close-up. Server holds the victim authoritatively, checks the drag path, restores collision/movement on cancellation/disconnect, and defeats the avatar at the end. Client camera/FOV/transparency restore on release, timeout and respawn.

Scare audio layers built-in Roblox uuhhh.mp3 and action_falling.mp3 with distortion/EQ; switch pulses use electronicpingshort.wav. No Poppy recordings or source-map sounds ship. Touch buttons allow mute and reduced camera/veil effects. First-person is locked outside the scare.

Prepublish validation additionally checks the imported map provenance/count/no code, first-person, physical switch reach, spawn support, a clear 16-stud creature lane, lighting, measured arm chains and actual hand-to-torso contact error below 0.9 studs. Engine checks are not a rendered client playthrough.
