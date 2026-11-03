# Still Here residents and sea restoration

Catalog items were researched via public catalog references and verified directly through Roblox MarketplaceService:GetProductInfo in read-only action runs 40881972304 / 40882216178. Invalid guesses were rejected: 295623966 is a SolidModel, 16627494 an image, 86499840 a place. None is used as avatar appearance data.

| Resident | Location / identity | Hair | Shirt | Pants | Body |
| --- | --- | --- | --- | --- | --- |
| Tomás | City, dock repairer | 62234425 Brown Hair | 144076358 motorcycle shirt | 144076760 dark green jeans | Man, tall/broad |
| Helena | City, innkeeper | 62724852 Chestnut Bun | 144076436 striped denim jacket | 398633812 black jeans/shoes | Woman, shorter |
| Caio | City, courier | 16630147 Beautiful Hair | 607785314 ROBLOX Jacket | 398633812 black jeans/shoes | Man, slender |
| Irene | City, sky observer | 63690008 Pal Hair | 398633584 denim/white hoodie | 144076760 dark green jeans | Woman, tall/slender |
| Mara | Current forest, field researcher | 62724852 Chestnut Bun | 398633584 denim/white hoodie | 144076760 dark green jeans | Woman, medium build |
| Davi | Forest 1, traveler | 16630147 Beautiful Hair | 144076436 striped denim jacket | 398633812 black jeans/shoes | Man, medium build |

Every definition has a distinct skin palette, scale combination, name, role and authored dialogue. These are clothed Roblox R15 characters with catalog meshes, not photorealistic humans. They have idle breathing/neck/arm motion, proximity conversations and activation within 140 studs. They do not yet have walking routes, quests or shops. No unrelated user avatar is copied. No scripts bundled in accessories or humanoid generation are executed: all LuaSourceContainer descendants are removed.

Body components, validated by exact asset type: Man torso/right arm/left arm/left leg/right leg 86500008/86500036/86500054/86500064/86500078; Woman 86499666/86499698/86499716/86499753/86499793. Head 86498048. Faces 86487700 (Man) / 86487766 (Woman). The builder asserts clothing, accessory, face texture and applied body parts. Failed appearance construction is reported; no bald/undressed fallback NPC is spawned.

Ground placement uses the same function in preflight and runtime: warm selected chunks, cast for a dry level surface near the intended location, and reject overlap with collidable scenery using an avatar-sized probe. Prepared characters stay in ServerStorage when players are far away. Each client animates only nearby active rigs. Dialogues are fixed original text, displayed locally above the speaker.

## Native sea

The source city `Workspace.ocean` contains legacy granite sheets with visual water treatment. They were excluded from static geometry import, leaving no native water in the source terrain. The correction extracts only thin upper sheets named `a`, preserving authored transforms and footprints, and fills 16-stud deep native Water volumes beneath those surfaces after terrain initialization. Lower duplicate sheets and unrelated rising-water gameplay are excluded. The native verifier raycasts the restored sea with IgnoreWater=false and asserts Material.Water. Water uses moderate transparency, reflectance and native waves. Original water scripts are never imported.

No rendered client screenshot or phone FPS measurement is available. Engine construction/clearance checks cannot establish how a face texture or outfit looks on a particular client.
