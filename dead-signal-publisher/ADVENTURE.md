# Still Here — forest/village adventure prototype

The public menu and authenticated reserved solo/six-person sessions remain. Automatic disaster runtime and its UI are removed from this build; the old modules remain only for compatibility with existing escort/travel internals and tests. The original Beyond the Dark black-hole visuals stay in the sky.

## World

AdventureForest extends the current forest to a bounded 6,144 × 6,144 stud area. Terrain and tree cells are generated deterministically around loaded areas, not instantiated across the whole world on join. Original central source geometry/terrain remain; outer cells use native Grass over Rock, low rolling height variation, and density bands (4/11/19 tree placements per cell). The village has a 190-stud exclusion radius for new trees. Streaming remains 64/128.

Eight sanitized tree templates are selected from original source 5326950832. Scale/yaw vary; each generated tree's actual native bounding-box bottom is aligned with the terrain height. Trunks have collidable/queryable cover, with a simplified invisible trunk fallback only when the authored tree lacks a suitable trunk part. Native checks exercise a generated outer cell, grounded bounds and ray occlusion through cover. The mission supply position is separately warmed and checked for native terrain support.

The village is at (0,128,-1120), with four building groups reassembled from sanitized original city parts and retained door metadata. They are spatial building groups from the old port, not four newly hand-authored complete buildings. Original city and forest destinations remain available in the map selector. The main adventure takes place on forestCurrent, whose arrival is relocated to the village. Eight clothed R15 residents include children Lia and Nico; all appearances and dry placement were checked in the native engine.

## First mission chain

1. Speak to Helena.
2. Find medicine in a supply crate in the forest.
3. Deliver it to Helena.
4. Locate missing child Lia.
5. Escort Lia back inside the village radius.
6. Speak to Irene about the sky.

A server-authoritative mission event drives a text fade, displays “Nova missão” for five seconds, then changes to “Missão”. A modest HUD direction/distance hint helps locate objectives without world signboards. Mission milestones persist via the existing inventory DataStore; a reconnect during the escort step returns to finding Lia. Supply state is represented by the server mission stage, not a client-submitted inventory item. Adult dialogue remains independent; adults no longer automatically follow when a quest conversation is triggered. Lia's validated rescue interaction starts her escort, and returning her awards one rescue credit.

## Patrols and stealth

Three original procedural UFO models orbit far beyond the safe village radius. Persistent model streaming keeps the small sky ships visible beyond the terrain streaming radius. Search beams and actual server line-of-sight tests are separate from the static black hole. Detection depends on horizontal distance, physical movement speed, exposure and cover: slow walking avoids attention at moderate distance, while close exposure can still trigger detection. Touch has a FURTIVO toggle; PC uses LeftControl. Server walking speed is 5 while sneaking and 14 otherwise.

A tall narrow Watcher patrols on foot. Moving players in its view cone can be detected; very close players can be seen even while stationary. UFO detection can create medium-sized search aliens, bounded at seven total hunters. A short recognition delay precedes pursuit. Hunters use bounded path requests, collision probes, a last-seen search window, and slower patrol after losing sight. Trees and collidable scenery break sight. The village has a protected threat radius. Recently detected players cannot escape by map teleport for twelve seconds after the last sighting.

Creature models and gait/head animation are procedural prototypes, not finished skinned/art-directed monsters. UFO deployment currently creates a nearby hunter; it is not a finished cinematic landing/alien descent sequence. There is no full campaign beyond the introductory chain, no voiced NPC dialogue, and no claim of polished attack animation.

## Validation boundary

Headless native checks verify world data, grounded/generated tree bounds, cover raycasts, eight avatar constructions, resident ground clearance, village presence, mission supply floor and exact published script sources. They do not play the full mission chain, execute multi-client reserved-server teleports, measure NPC following quality or confirm the rendered composition/FPS on a phone. Full client playthrough remains unverified.
