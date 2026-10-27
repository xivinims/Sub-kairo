# Dead Signal Asset Audit — 2026-10-27

Probe executed through Roblox Open Cloud without calling SavePlaceAsync. No place version was modified.

## Good candidates for direct/static use

### Floor — 11961684378
- Name: poppy playTime floor
- Creator: Nstudio_Games
- 1 Part
- 0 scripts
- Approx size: 20.49 × 1 × 20.65 studs
- Decision: safe lightweight modular floor reference.

### Door Frame — 96103787859080
- Name: poppy playtime door real
- Creator: MATEENIEVA2024
- 5 MeshParts
- 0 scripts
- Approx size: 4.89 × 22.34 × 19.00
- Decision: usable as static architecture after normalization.

### Power Station / Panel — 9609111841
- Name: poppy playtime
- Creator: sl6onh
- 1 MeshPart
- 0 scripts
- Approx size: 16.26 × 20.43 × 1.24
- Decision: excellent visual prop for our own PowerService.

### White Door — 8593730677
- Creator: santiloco1777
- 11 parts, 4 MeshParts, 3 Models
- 0 scripts
- Approx size: 4.18 × 6.46 × 0.84
- Decision: use geometry only; DoorService supplies all logic.

## Selective import only

### Batteries — 16551049618
- 18 Models, 8 MeshParts
- 0 scripts
- Bounding box is enormous: ~6869 × 2108 × 1794 studs
- This indicates the pack contains separated display pieces far apart.
- Decision: NEVER import the pack as one runtime object. Extract individual batteries/sockets, normalize pivots and scale, then discard the source container.

### Power-link puzzle props — 16592756903
- 4 Models, 9 MeshParts
- 0 scripts
- Approx size: 35.23 × 20.43 × 11.71
- Decision: selected visual pieces may be useful for our custom cable puzzle, but logic stays entirely custom.

### Stairs — 120661626985584
- 106 Models, 66 MeshParts
- 0 scripts
- Approx size: 12.41 × 13.16 × 13.07
- Decision: usable selectively. Consolidate/anchor geometry and avoid cloning dozens unnecessarily on mobile.

## Reference library only

### GrabPack — 10468403169
- Tool with 32 parts / 30 MeshParts
- 4 Scripts + 3 LocalScripts
- 2 constraints
- Decision: reference only. The game does NOT use a GrabPack. Our mechanic is physical cables and electrical endpoints.

### Chapter 4 idea kit — 72028919182927
- 573 parts / 492 MeshParts
- 259 Models
- 3743 Attachments
- 1 Humanoid
- 0 scripts
- Approx size: 379 × 136 × 284
- Decision: visual library only. Too large/complex to dump into runtime.

### Chapter 3 model kit — 16390129962
- 16 MeshParts
- 4 Models
- 0 scripts
- Approx size: 28 × 14 × 28
- Decision: reference/selective props only.

### Inspiration map — 10231610849
- 7960 parts / 660 MeshParts
- 1696 Models
- 54 Scripts
- 26 Animations
- 93 Attachments
- 3 ProximityPrompts
- 5 Sounds
- Approx size: 795 × 227 × 681
- Decision: NEVER import whole into Dead Signal. Use only for layout/scale inspiration. Our map will be original and built around our own systems.

### Bramble creature kit — 115602504342753
- Model: LiveEntityBramble
- 70 parts / 68 MeshParts
- 12 animations
- 16 sounds
- 2 Scripts + 1 LocalScript
- Creator metadata currently reports "Content Deleted"
- Approx size: 20.51 × 16.26 × 4.39
- Decision: reference only. Do not ship this entity or its scripts. Our stalker Threadbare gets an original rig, animations and sounds.

## Security rule

Every external model that enters the runtime goes through SafeAssetImporter. Third-party scripts are deleted before parenting to the game. Large kits are never imported wholesale.


### Map Items Kit — 136978268470872
- Name: Poppy Playtime Chapter 3 Kit Toy Factory Horror 2
- Creator metadata: Content Deleted - 158552482
- 16 parts / 16 MeshParts
- 4 Models
- 8 Scripts + 4 LocalScripts
- 4 Sounds
- 0 Animations
- 0 Humanoids
- Approx size: 28.13 × 13.76 × 28.12 studs
- Decision: selective-only. Never import the whole kit into runtime. Extract useful visual props individually, strip all scripts/local scripts, review sounds separately, then normalize pivots/anchoring before use.
