# Whole-island coverage, asphalt loops and recovery audio

- Void background music: 110526913527016. Regeneration click plays 73292002268424 locally; sound survives death UI teardown and is removed by Debris.
- Decorative MysticalSpawn removed; invisible fixed spawn retained and grounded.
- Imported close ImageButtons replaced with rounded charcoal TextButtons with explicit border strokes.
- Road surface from ready-made Asphalt road 9709196113 adapted into two closed loops: near tree and largest fully grounded outer radius. Geometry follows island raycasts.
- Original grass mesh covers all suitable green island surfaces outside the road corridor. Smaller copies of the same grass finish road verges. Distant meshes retain the mesh's neutral shape without cloned Bone instances; nearby pooled replacements retain original wind and stepping simulation, capped at 96 mobile/240 desktop.
- FullIslandGrass is saved and replicated, streaming remains disabled. Loading preloads map/roads/full grass and waits for all saved patches plus the initial nearby animation pool before opening the menu.
- Engine tests cover road closure, ground checks, grass road clearance, full-island visibility through pool movement, mobile budget, scene lifecycle and asset loading. Visual bind-pose appearance and device memory/FPS require a live Roblox client; headless tests do not establish these.
