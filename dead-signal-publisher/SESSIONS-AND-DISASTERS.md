# Still Here: public menu and reserved disaster sessions

## Server architecture

The same place ID is used in two server roles within universe 9421311218. Public servers are menu-only. Reserved servers initialize the playable maps. This is not a second universe or a newly created place. Geometry and destinations are stored under ServerStorage.MatchWorld in the published file; the saved public Workspace has no maps and an empty native voxel grid. CharacterAutoLoads is false until reserved-match initialization completes. All gameplay entry scripts wait for GameMode and return in Menu mode.

The public menu offers Solo, Multiplayer (groups), and Shop. A leader creates a private six-character group code, players in that public lobby join it, and only the leader starts. Group codes are local to a public lobby, not a global cross-server matchmaking service. Solo starts a reserved server for one member. Group starts reserve one server for the complete group. A MemoryStore allowlist authenticates each arrival, and the server rejects users outside the allowlist or above six participants. New ReservedServerId options are used where supported, with a legacy reserved-access-code fallback. Teleport failures are reported and the menu can retry.

The in-match MENU control returns to a public menu server; it and map travel are blocked during active disasters. Initial arrival and same-island void recovery remain available. No client teleport-data inventory values are trusted.

## Inventory

SessionProfile uses StillHereInventory_v1 DataStore with UpdateAsync. New profiles start with 30 virtual credits. Initial items: lantern (20), light trail (15), arrival highlight (10). Purchases are idempotent, server-priced, persisted, and applied on match character spawn. These are virtual-credit items, not Robux developer products. No real-money payment integration was added. Five credits are awarded per recorded NPC rescue when leaving a match/returning to menu. The job ID prevents duplicate reward application during shutdown and PlayerRemoving. Failed data operations are reported; purchases are not pretended successful.

## Disasters and rescue

Round cycle: 90-second calm, 25-second warning, 70-second active hazard, 15-second recovery. Five modes rotate: earthquake, acid rain, tornado, meteors, gale. One island containing a player is selected per round. Map and menu travel are blocked server-side during active hazards; warning-phase travel remains available.

A nearby NPC prompt toggles escort ownership. Another player cannot steal an owned follower. Nearby residents use server-owned R15 physics and bounded pathfinding to follow leaders or attempt covered city-door destinations. Doors open automatically near residents. Walking/running limb motion is local. Residents complain/shout using authored text bubbles; there is no voiced scream recording. If no roof is available in the forests, residents request rescue rather than pretending to have a house there.

Warning-phase escorts evacuate with their leader during permitted map travel. Arriving on an unaffected island or guiding an NPC under a roof awards a rescue once per round. Player departure/death releases followers. Injured NPCs retain at least five health and recover after the disaster; this build has no permanent NPC death or gore.

Acid rain damages uncovered bodies; roof rays respect collidable scenery and ignore foliage as shelter server-side. Tornado/gale apply bounded body impulses, and meteor impacts have a two-second visual warning before damage. Earthquakes shake the local camera and cause intermittent exposed damage. Hazard visuals are local with touch-device particle/part budgets.

City source doors are stored separately from most architecture. The importer identifies bounded building-sized spatial clusters around authored doors (37 groups); the wind can lift visible building pieces as an animated, non-colliding model and restore originals afterward. This is controlled visual destruction, not unconstrained physics on every complete house. The ground and full island are not unanchored. This was deliberately verified before retaining a published candidate: an initial missing-cluster build was rolled back by the exact-file check.

## Validation limits

Native engine checks construct six appearances, verify dry unobstructed NPC placements and four city roof candidates, exercise all five phase travel gates, and confirm native city water. Exact downloaded-file checks attest empty public Workspace, server-only maps, mode gating, UI/server sources, inventory code and destructible structure tags. Native Luau compilation runs during assembly.

These checks do not simulate six live clients, a complete TeleportService journey, MemoryStore/DataStore connectivity in a running public server, purchases by a real player, actual NPC path traversal, rendered visuals or phone FPS. A client session must still exercise those integrated flows; success of GitHub Actions is not described as proof that they were played.
