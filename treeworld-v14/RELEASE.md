# Caio: requested avatar and click-only conversation

Uses body and skin from the user's current Roblox avatar (8344738123), with width 0.70, depth 0.70, height 0.90 and head scale 0.95. The original body package and height match that avatar; depth is reduced from 0.85. Only the NPC changes.

Exact resolved user links:

| Item | Catalog/bundle | Applied content |
| --- | --- | --- |
| Adventurous Hat | 18654587595 | Hat accessory |
| Thin Rimmed Low Glasses | 18557389382 | Face accessory |
| Messy Anime Boy Hair Rintaro Blonde | 124964364612906 | Hair accessory |
| Shy Blush Face | Bundle 135037177901605 | Dynamic head 107154176765760 |
| Fantasy Steampunk Adventurer shirt | 135542921435071 | Template 86335294756983 |
| Fantasy Steampunk Adventurer pants | 93944579042140 | Template 113082643230470 |
| Generic Standard Guy Man Manly Animation Pack | Bundle 230910224826976 | Idle catalog 99777856614604, clips 99053594862758 / 105182203934754 |
| Pride Lanyard (Gay) | 15591115363 | Waist accessory |
| Korblox right leg | 139607718 | R15 right leg |

The rig is assembled from native attachments, including all 15 R15 joints and four accessory welds. The new dynamic head remains intact; the old expression decal is removed with the old rig. Gaze follows nearby players smoothly within a forward attention cone. Natural blinks and subtle voice-driven jaw movement use FaceControls.

Only a direct click/tap on Caio begins a conversation. There is no proximity prompt or automatic welcome. Clicks are local-player and range checked; recent camera drags cannot trigger speech. A noninteractive hint appears within interaction range. The existing localized dialogue, seven recorded Portuguese voice lines, retry handling, report/feedback choices, and v13 backpack/camera fixes are retained.

Publication gate checks the actual assembled R15 rig, scales, exact clothing, dynamic head, accessory attachment alignment, ground contact, click-only configuration, both selected idle clips loading and all seven voice assets. Luau compilation runs locally. No live mobile visual/audio playtest is claimed.
