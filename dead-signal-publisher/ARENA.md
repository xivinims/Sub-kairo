# Dead Signal — Bramble test arena

Active build: `dead-signal-bramble-arena-v1`, universe `9421311218`, place `118064584465155`, branch `dead-signal-publisher` only.

The chapter, menu, GrabPack and previous runtime are removed from the published place. The publisher now assembles only `arena-install`, `arena-animation`, `arena-server`, `arena-client` and `arena-validate`. Previous chapter source is inactive and retained for recoverability in Git.

One clean 160 × 160 floor, invisible edge boundaries, spawn and the selected `LiveEntityBramble` from asset `115602504342753`. SafeAssetImporter.Load strips the two external scripts before selecting the rig. External sounds and animation objects are removed. The actual mesh geometry and all 36 Motor6D joints are retained; only the Root is anchored. No third-party code runs.

Original procedural Motor6D animations cover Idle, Walk, Run and Attack. Walk follows a square route at 7 studs/s; Run pursues a living player at 24 studs/s. Attack approaches the requesting player, reaches with both arms, anchors and lifts the avatar in front of the torso, closes the fingers, holds and defeats the avatar after 2.4 seconds, then restores control flags and returns to idle. Resets/disconnects release captures; a 3-second cooldown prevents immediate repeated grabs. Arm targeting supplements the attack pose. These are custom test animations, not the original kit animation clips.

Four top-of-screen buttons support touch and mouse; PC shortcuts 1–4 match them. Idle is the default. Classic Roblox camera allows first-person or an external view for rig inspection. No saved chapter state is read or overwritten.

Validation checks the new build marker, correct asset provenance, old chapter absence, root, floor, spawn, client/server/control objects, connected geometry, at least 30 intact motors, no executable content inside the imported model, and distinct executable animation poses. Validation runs before SavePlaceAsync and again in a fresh execution session against the published version. This is engine validation, not a rendered client playtest.
