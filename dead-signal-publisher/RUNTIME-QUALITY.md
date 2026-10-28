# Runtime quality revision 4

Build `dead-signal-runtime-quality-v4` improves the functions already deployed in the map; it does not claim to complete the Unreal game port or its missing visual assets.

- DoorService checks occupancy continuously during closing, cancels the closing tween and reopens if a player enters, then retries only while the close request remains current. Reopening cancels pending retries. Registration rejects duplicate IDs and zero travel; door state attributes and events distinguish Closed, Opening, Open, Closing and Waiting.
- Map controls disable during motion and provide a native prompt to keep an occupied doorway open. Both doors and sector controls now require a living nearby character, an enabled prompt, a server-side unobstructed ray and a per-control cooldown. Controls on opposite sides remain distinct.
- Fans accelerate and decelerate using elapsed time and retain their phase when sector power or distance activation changes. Unknown initial sector state no longer starts fans or lights. Diffusers stop emitting a neon appearance when their circuit is off. No new UI is created.
- Prepublish tests use a real animated temporary door with injected occupancy: entry after closing starts must reverse the door, reopening must cancel a pending retry, and closing must recover after the obstruction clears. Guard tests cover valid use, spam, a wall, distance and a disabled prompt. Existing real door route sweeps, power toggles, crate support and imported-geometry checks remain.
- The existing Miss Delight, five converted clips and menu images in ServerStorage.SpringSourceConverted must survive publication; the validator checks this. They remain staged conversion resources, not an active complete Unreal game.

The publisher verifies the saved place in a separate Roblox execution session before restarting old servers. Rendered visual quality and the missing Unreal scenery/textures are outside what these engine checks prove.
