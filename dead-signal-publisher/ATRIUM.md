# Photo-directed overgrown atrium

Build: `dead-signal-overgrown-atrium-v2`. Only universe 9421311218 / place 118064584465155 on branch `dead-signal-publisher`.

Replaces the imported park and five service pavilions with original procedural geometry based on the three user-supplied atrium photographs. No chairs or NPCs are placed. Preserves inactive converted source assets in ServerStorage.

## Scene

116 × 196 stud footprint, broken pitched skylight, three elevated gallery levels, 132 half-stud stair treads across three flights, continuous rear landings and front returns. Tall front glazing, exposed pier substrate, teal floor inlays, masonry debris, hanging cables, four branching trees, hanging ivy, moss and low luminous flowers. Decorative parts do not obstruct the route. Cool ambient bounce, atmospheric haze, restrained bloom, sun rays and drifting dust use native Roblox effects. No arbitrary external shaders.

Two rear entrance doors use the existing DoorService including obstruction protection and server-side interaction guard. They open into small vestibules. Five progress markers support saved continuation. Initial spawn faces the central garden and stairs and is independent of the menu camera.

## Presentation

Cinematic scene camera with slow movement, left aligned outlined menu buttons, Continue, New Game confirmation, graphics and motion settings, field of view adjustment and credits. Mobile controls adapt to physical pixel size. Loading uses the actual supplied Aurivane Works logo uploaded to the experience creator. No original Poppy Playtime UI assets or audio are imported.

Server-side saved sessions use a separate `DeadSignalAtriumV1` data store. New Game resets only this scene's checkpoint. Existing chapter saves remain separate. Menu camera and first-person camera switch on entry/resume; an accessible menu button and M key reopen the menu.

## Verification and limitations

Publisher runs pre-save geometry, route, door and script-presence checks, saves the place, opens a fresh engine execution session to verify the persisted version and restarts servers. V2 adds actual pathfinding for the route through all gallery levels.

Headless engine checks do not establish rendered visual fidelity, touch usability, save-service behavior with a real player or frame rate on an iPhone. No client screenshot or full human playthrough has been captured. The result is an authored Roblox interpretation of the supplied scene, not an exact photorealistic reconstruction. Tree crowns and flowers use simple native geometry for portability; bespoke textured meshes would improve their appearance.
