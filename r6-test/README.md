# R6 animation test

The private test place now starts directly on a clean grid floor with two wallrun walls. The old camera menu, bots, weapons, dialogue, lighting packs and fixed StarterCharacter are removed. Other projects in this repository are unchanged.

`avatar-server.luau` obtains each joining player’s HumanoidDescription and explicitly creates an R6 model. It retries avatar retrieval without substituting a fixed dummy. Death and reset recreate the player’s own avatar as R6. R15 body shapes and layered clothing cannot be reproduced on an R6 skeleton.

The original R6 Animate, sprint and wallrun scripts are preserved byte for byte. Their original dependencies and animation IDs are retained. Double-tap W or use the circular » button to sprint. Hold Roblox’s jump action beside a wall for wallrun.

The circular ▶ button (or M) opens the animation test list. The catalog includes 27 original Animation objects from Naruto, bow, sprint, wallrun and Boogie packs. Duplicate/default animations are retained as provided. These are previews; the bow and Boogie gameplay systems are not installed.

The existing 19 R6 KeyframeSequences are preserved unchanged, with a SHA-256 comparison over the complete original package. A separate local preview reader applies their original pose CFrames, weights, timing, and their Linear/Constant easing to Motor6Ds. It does not upload, replace, or rewrite the original sequences. These pose previews are visible locally only. Movement, jump, death, or Parar stops preview and restores Animate. Normal published Animation IDs load through Animator and remain subject to creator ownership/experience permissions; failed loads display a message.

`naruto-camera-original.luau` is the untouched PlayerScriptsLoader from the uploaded Naruto pack. It is also retained inactive under ServerStorage/Conflicts. Its camera override calls the legacy ApplyVRTransform method; no compatibility edits were made. Only its animation objects are included in the catalog. Full Naruto wall walking is inactive.

R15 Wall Climb and Swim are excluded. VirtualVogue and water castle are maps, so they are excluded from this clean animation test. Lantern is not an animation pack and is not installed.

Validation: `check.luau` compiles every script, verifies the original source hashes and complete emote package hash, checks that the fixed avatar/menu/bots/tools are absent, and requires the supported pose easing styles. `verify.luau` runs in Roblox’s native execution environment, checks imported data and floor collision, and creates an actual R6 model with the same API used by the server. These checks do not constitute a rendered phone/desktop playtest or prove access to third-party animation IDs.

The existing publication workflow backs up the current private place, requires an existing R6 test build, checks that its version did not change, publishes, verifies, and rolls back on failure. It does not change experience privacy.

Rebuild: unpack the bow model as ../upload/Bow.rbxm, keep the attached files under ../upload using their current (3)/(2) filenames, then run `lune run r6-test/clean-animation-build.luau` from the repository root. The prebuilt arena.rbxl is self-contained for CI.
