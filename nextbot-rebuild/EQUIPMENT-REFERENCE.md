# Equipment behavior audit — 2026-11-03

Owner will supply thumbnails and art. Functional parity and exact models/audio are separate workstreams. None of the following has yet been playtested in Roblox.

| Item | Reference behavior | Candidate implementation | Remaining |
|---|---|---|---|
| Flashlight | Free, F/mobile toggle, directional illumination | Local camera-aligned SpotLight, replicated on/off state | Exact held model, grip, animations, upgrades, shared beam |
| Compass | Nearest objective, otherwise north | NBObjective tags, camera-relative arrow, ignores completed objectives | Objective integration, exact model |
| Timer | Round countdown | Server deadline displayed bottom-right | Exact model and visual treatment |
| Radar | Pulse/beep accelerates as nextbot approaches | Distance-based visual pulse using tagged bots | Original sound; exact detection range not established |
| Decoy panel | Forward-moving replica, 5-second life, 15-second cooldown | Server clone, forward motion, nearest-target AI integration, expiry, owner cleanup | Exact hologram/model/animation; runtime collision tests |

Sources:
- https://evadewiki.org/wiki/compass/
- https://evadewiki.com/wiki/timer/
- https://evadewiki.org/wiki/radar/
- https://evadewiki.com/wiki/flashlight/
- https://evadewiki.org/wiki/decoy-panel/
- https://evadewiki.org/wiki/decoy-nextbot/
- https://create.roblox.com/docs/scripting/security/client-server-boundary

These are community behavior references, not official source code. Wiki prices conflict with screenshot prices; existing screenshot prices have not been silently changed. Light range 50, cone 65°, radar range 150 and pulse interpolation are implementation tuning, not verified original constants.

Ownership is server-controlled. Flashlight is free; Studio-only preview grants give three of each utility for testing. Session inventory and once-per-round consumption exist; persistence, purchase transactions, progression and level unlocks are not implemented. These items remain unavailable for purchase. Equipped utilities can be selected via the shop's EQUIPAR button when owned. No production inventory is fabricated.

Unit checks cover unsupported IDs, consumption once per round including the last unit, exhaustion, permanent lights, countdown bounds and pulse ordering. Real Roblox multiplayer, mobile, model/rig and collision tests remain required.
