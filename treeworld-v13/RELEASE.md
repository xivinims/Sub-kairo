# Caio voice and touch camera hotfix

The old dialogue left an invisible ScrollingFrame (86% screen width, 43% height) visible even when no conversation was open. Its scroll/input region interfered with touch camera movement. Choice containers now start hidden and inactive, become interactive only when actual choices are ready, and are hidden and cleared when speaking, leaving, or closing the dialogue.

The imported inventory skin is replaced with a 44px outlined backpack button and a compact panel. There is no permanent center/bottom hotbar or full-screen input catcher. Decorative fruit previews and labels do not consume input. The panel starts closed and closes on respawn; fruit data and small x2/x3 stack counts remain intact. Touch and B toggle the bag.

All seven Portuguese recordings were confirmed loadable in published place 120, with lengths of 8.86–10.87 seconds. They previously emitted from Caio's head and fell completely silent beyond 25 studs from the camera, even while the avatar was close enough to converse. Voice now plays privately under SoundService, independently of zoom; conversation range still uses the player's avatar and stops when the player leaves.

Voice preloads in the background. Pending loads can be cancelled; they cannot start speech after leaving the NPC. A bounded native speech fallback uses the same localized text and a direct device output. Optional speech APIs initialize lazily so errors cannot disable prerecorded Portuguese dialogue. Failed ordinary dialogue offers an explicit retry instead of silently pretending speech succeeded. Native synthesis requires a client and is not validated by server cloud execution.

Validation before saving and against the saved place executes the real GUI constructors in Roblox, checks closed/open input states, one 44px closed-bag hit target, nonmodal buttons, noninteractive previews, stack counts, seven successful recording loads, playback start/stop and cancellation. The patch asserts all 7,357 trees remain present. Luau files are compiled locally. These checks do not replace an audible/mobile playtest in the Roblox client.
