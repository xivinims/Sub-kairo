# Equipment behavior audit — 2026-11-03

Owner will supply thumbnails and art. Functional parity and exact models/audio are separate workstreams. None of the following has yet been playtested in Roblox.

| Item | Reference behavior | Candidate implementation | Remaining |
|---|---|---|---|
| Flashlight | Free, F/mobile toggle, directional illumination | Local camera-aligned SpotLight, replicated on/off state | Exact held model, grip, animations and upgrades; a procedural held light and shared beam are implemented |
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

Ownership, purchases, quantities and equipment slots are persisted by the shared ProfileService. Flashlight is free; there are no automatic test currency grants. Utilities consume once per round, while usables and baton charges consume per activation. A depleted utility can finish its current round. Level unlock requirements are not implemented.

Additional implemented effects: headlamp/NVG; radio position pings; baton stun and miss damage; cola with 1.5-second use delay, 6-second speed/acceleration effect and carry restriction; destructible 180-second barriers with placement limits. The military perk raises the placement limit to nine; medkit extends bleedout and increases crawling speed. Prices of cola and barrier follow the updated community references cited in REFERENCE-AUDIT.md. Durability, exact movement tuning and provisional models are not claimed identical to Evade.

Unit checks cover unsupported IDs, consumption once per round including the last unit, exhaustion, permanent lights, countdown bounds and pulse ordering. Real Roblox multiplayer, mobile, model/rig and collision tests remain required.
