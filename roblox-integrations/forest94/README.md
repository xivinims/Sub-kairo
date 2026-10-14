# TreeWorld version 94 — central lake and woodland crossings

Universe 9421311218, place 118064584465155; upgrades published version 93.

The requested original model 11324928349 supplies 30 candle lamp posts with their original two meshes and textures, scaled together and buried 0.2 studs into actual terrain. Native night-light control now supports SurfaceLight as well as PointLight.

The requested original Cartoon Water model 6833503207 supplies the mesh and texture for 188 shallow, noncolliding visual tiles. Its four source layers are not repeated across the river. Every tile's centre, corners and edge centres are checked against actual native liquid. One continuous Terrain water volume remains available for swimming; its wave amplitude is 0.015. Texture motion is local, 10 Hz, with at most 32 nearby textures on touch devices. Thin shore foam follows measured waterlines; the old oversized glints and prior foam pieces are removed.

A central connected lake near (27, 6, -18) is carved through 1,118 native terrain columns, with sloped sandy shores. The downstream cottage lake and river remain. Two wide timber bridges have eight longitudinal plank lanes, a modest arch, carved posts, capitals and scalloped support corbels. Every bridge part is visible and solid. Ten irregular polygon stepping stones have pale tops and blue-grey faceted sides extending to the bed. A missing/invalid final frame of the hill staircase is repaired using a fixed nonzero direction.

114 additional native wildflower models form low shoreline clusters; existing wildflowers are reduced toward 0.9 stud height and regrounded. Standard Terrain decoration remains enabled at grass length 0.4. No skeletal grass grid is introduced.

453 trees and 1,443 plants are refitted after the terrain changes. Root contacts now include the lower 2.2 studs of real trunk geometry rather than only its lowest 0.75 studs; contact depth is 1.15 studs, stored in world coordinates. Twelve logs/stumps that intersect trails, crossings or the carved lake are removed. All animal templates, routes and wildlife anchors are removed, including client movement code. Existing forest audio, falling leaves, tea interactions, separated ruins, camping and weather remain.

Native staging passed: 7,723 root/plant contacts, 855 bridge walking samples, 45 central lake liquid samples, 30 stone top collision samples, 30 original lamp posts, seven loaded audio assets, 28 compiled scripts/modules and 3,074 PBR appearances. World geometry is 10,455 parts versus 10,485 before this update. Every saved world frame is checked for finite coordinates within bounds.

No actual client render, reference-image equality, phone FPS or memory measurement is available. Root checks use Roblox native mesh collision queries; alpha-card plants without an underside use their placed bounds. The requested alternate tree models were inspected but not substituted wholesale; the existing tree varieties are retained with corrected root support.
