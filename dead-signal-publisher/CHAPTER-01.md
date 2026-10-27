# Signalworks — Chapter 1 test build

Build: `dead-signal-ch01-grabpack-v6`. Target: universe 9421311218 / place 118064584465155.
Only branch `dead-signal-publisher` is used. Other game folders and branches are unchanged.

## Player route

Reception → atrium → induction → maintenance → accumulators → assembly → distribution → MARA archive → dark return → freight escape → discharge → sanctuary.

- Induction: connect the 28-stud cable between source and door terminals.
- Accumulators: take an individual cell, install it in the source dock, connect the 36-stud cable. The second cell can be stored at the lighting dock.
- Assembly: the environmental sign gives the relay order 2 / 1 / 3. It enables the source; connect its 32-stud cable to the production door.
- Distribution: connect the 26-stud cable to the bus. Enable the 50-U archive door. The 20-U lights may stay on. The 100-U generator cannot operate all loads.
- Archive: MARA latches the archive door open. Return to distribution, turn off door and lights; enable lift 70 + safety relay 30. This opens the return gate and enables the optional physical freight lift to the archive inspection deck.
- Escape: Threadbare observes before it pursues. Occlusion checks gate scripted repositioning. In the freight route, weave around alternating cargo islands, activate the emergency discharge and enter the sanctuary.
- Sanctuary: automatic checkpoint, terminal dialogue and end-of-test marker. Future descent is sealed.

Seven checkpoints restore solved circuits from persisted milestones. A carry lost to death/disconnect returns to its known location. New Game has an in-game confirmation and cannot reset another active session. Shared electrical state uses the furthest active progression; personal chapter/checkpoints/flags remain per-player.

## Implementation and limits

Geometry is original Part-based modular architecture: painted concrete, conduits, fixtures, CRT, cabinets, shelving, assembly lines, walkways, stairs, mascot and jointed original Threadbare rig. No external models or scripts are loaded in this build. SafeAssetImporter remains the required path for future selected imports.

Lighting uses sector fixtures and local emergency lights. Audio is provisional Roblox engine stock foley with a low-volume electrical bed, not a finished authored soundscape. Threadbare uses local procedural joint poses, not a final authored animation package. This build does not claim visual parity with a commercial game.

Mobile uses native proximity prompts (F on keyboard), existing E/USAR cable aiming, an explicit SOLTAR button, large menu buttons and touch dialogue. Settings: volume, reduced motion, shadows; values persist.

## Validation

`node dead-signal-publisher/publish.mjs --dry-run` assembles the exact install payload without contacting Roblox.
`python dead-signal-publisher/tests/check-syntax.py` parses the compatible Luau subset after assignment expansion; it does not replace engine execution.
`chapter-validate.luau` executes before publishing and again after reopening the latest place version. It checks IDs, tags, references, reachable cable lengths, checkpoints, script exclusion, rig, part budget and actual PowerService/WireService behavior against an isolated graph.

Publisher aborts on validation errors, saves/publishes once, reopens the place in a separate task, validates BuildId and objects, then requests restartServers. A green workflow alone is not publication evidence: inspect the returned Roblox version and verification JSON.

No interactive Roblox client is available in the container. Visual/mobile rendering and complete human playthrough must not be described as verified by structural tests.


## Visual revision 4

The previous primitive-only dressing is replaced by selected geometry from all ten approved visual asset IDs: floor 11961684378, passages 96103787859080, stations 9609111841, doors 8593730677, individual cells/sockets 16551049618, electrical props 16592756903, staircase flights 120661626985584, toy/block/cot props 16390129962 and 136978268470872, and four individual structural columns from 72028919182927. Selection is by exact audited object name. Reference-only map, GrabPack and Bramble creature remain excluded.

SafeAssetImporter.Select clones only BaseParts and approved visual descendants from detached source containers; all executable code, audio, animations, prompts and constraints from the source are discarded. Door visual leaves receive our own WeldConstraints to the original DoorPanel. Original stair treads remain invisible simplified collision geometry.

First-person is enforced in StarterPlayer and reapplied on play/respawn. Menus release mouse capture and disable movement; native touch camera stays available during gameplay. Settings use four tabs, scrolling rows, touch-sized +/- controls, defaults and server-validated persisted values. Sprint (22), crouch (8), walk (16) and cable carry (13) are server-authoritative. Flashlight is a local SpotLight. Graphics presets control local light activation distance and nearby light shadows. Mouse sensitivity is explicitly labelled as mouse-only.


## Scenic revision 5

Remove all Wayfinding objects from the final place, including room-title boards, lot labels, standalone node captions, sequence instruction board, route arrows and end-build placard. The tagged MARA surface is retained as CRT glass. Electrical units are engraved directly on the machine; the relay order is a repeating 2/1/3 lamp pattern rather than a hanging instruction sign. The build end is shown by the existing HUD.

Public rooms receive small coloured floor inserts over the supplied floor, finer texture tiling/grout, aged mural plaster, blue painted contours, a curved reception counter, yellow corridor arches, an indoor atrium garden, suspended scenic clouds and two original playhouse facades. Maintenance and escape rooms receive pale service walls with red stripes, damaged plaster at the edges and a suspended damaged fluorescent fitting. Central progression lanes and all puzzle positions remain unchanged.

The unavailable JPEG attachments were not opened; the scenic direction uses only the inline images visible in the conversation. This remains a technical engine validation, not a verified rendered playthrough.


## Revision 6 — GrabPack and collision correction

The user's latest instruction supersedes the former no-GrabPack rule. The game now includes sanitized hand/launcher geometry from 10468403169 with custom server-side ray validation, remote puzzle interactions, retraction, obstructed cart pulling and an eight-second two-hand power bridge. See REFERENCE-REVIEW.md for the reviewed references and exact audio limitations.

Static imported visual assets now have collision/query enabled and mesh collision fidelity appropriate to their role. Door leaves retain the DoorPanel proxy, stairs retain tread colliders, and portable cells retain the CellHandle proxy. The validator sweeps an avatar-sized box along the route and tests GrabPack charging/bridging/releasing in an isolated graph.

The front end follows the uploaded Chapter 3 composition: chapter/title/description at upper left, five outlined buttons below, original red-lit 3D creature stage at right. Credits and exit confirmation are functional. This does not claim a pixel-identical official menu or a rendered client playtest.
