# R6 character motion

The test now runs the original uploaded Naruto R6 Animate controller inside each player character. Its supplied public R6 defaults handle idle, walk, jump, fall, climb and sit automatically. The controller, R6 module and sprint/wallrun sources are unchanged. There is no animation preview GUI or catalog controller.

The avatar server builds each player from their own HumanoidDescription as R6 and clones StarterCharacterScripts, including the animation controller and Animations folder, into that character. Original motion Animation objects and the 19 original KeyframeSequences are copied into character.Animations. The archive retains the complete original emote package for hash comparisons.

The native diagnostic on version 275 found that the custom idle, walk, sprint, wallrun and Naruto demo IDs loaded tracks with Length=0 after six seconds. The public R6 idle/walk/jump IDs supplied by the Naruto R6 module loaded successfully in the same session. This is why the prior custom movement configuration could leave the avatar unanimated. These custom objects and IDs are retained unchanged; they are not claimed to work without asset access. Full Naruto wall walking remains inactive due to the original legacy camera incompatibility.

Sprint and wallrun controllers are installed on the character. Sprint uses its original double-W action or Shift / the native touch Correr action. Its custom run animation and wallrun custom animations remain subject to the loading failure above; normal R6 locomotion is still active.

Raw emotes live in character.Animations.Emotes and can be requested with /r6 CatDance, /r6 Idle Sit, etc.; /r6 parar stops playback. A separate character-owned reader uses the exact poses, timing, easing and weights. It does not change the imported sequences. Raw pose playback is local only, and movement/jumping stops it. It does not replace automatic movement with a dance.

Validation checks the original source hashes, character-owned controllers, absence of the preview UI and R15 controller, and unchanged emote archive. Native verification creates a real R6 character, clones the exact character contents, and requires idle/walk/jump/fall/climb tracks to load with nonzero duration. It records walk playback and joint samples; this is not a rendered phone playtest.

Rebuild with lune run r6-test/apply-character-motion.luau. The older clean-animation-build and animation-test-client files are retired and not installed. Publication continues to back up the private experience and roll back if native checks fail.
