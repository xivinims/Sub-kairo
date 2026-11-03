# Nextbot recreation — implementation status

Target is the CURRENT Evade UI in the owner's IMG_2671–IMG_2690 screenshots. Requested timing: 90-second intermission, 180-second round. The timing values exist in Config; a new round runtime is NOT implemented in this package.

## Implemented candidate

- Native Roblox settings screen: audio/visual/game tabs, header, close/reset, scrolling sections, toggle controls, mouse/touch sliders, scaling from 1624×750 screenshots.
- Local material simplification with original material restoration, shadow control, FOV, named audio group volume.
- Validated preference remote, defaults, bounds, NaN/infinity rejection, autosave, conservative behavior after a failed DataStore read.
- Viewbob, running viewmodel, legacy camera and vignette preferences are exposed as attributes. They still require gameplay consumers and do not yet implement those effects.
- Standalone preview place. No live FPS replacement or Roblox publication occurs in this workflow.

## Exact match still missing

Main menu, shop, inventory, avatar inspection, loading screen, round queue, missions, event pass, leaderboard, spectating, mobile match HUD, Nextbot AI, downed/rescue/carry, progression, equipment and animation runtime remain to be implemented and tested together.

No visual verification inside Roblox has occurred. Fonts, gear glyph, gradients, transitions and underlying 3D scene are not yet certified identical. The preview floor is an inspection stage, not the requested map.

Catalog entries transcribe visible screenshot names/prices, not a complete Evade catalog. All catalog items remain unavailable in this preview; no animation or music IDs are invented. Items must only be enabled after their gameplay implementation and assets are validated.

## References and candidate assets

- Official current game / features: https://www.roblox.com/games/9872472334/Evade
- Public animation model previously used in this repository: https://create.roblox.com/store/asset/14026023204 — inspect actual keyframes before reuse; this does not prove identity to current Evade.
- Candidate Nextbot model: https://create.roblox.com/store/asset/11128061931/Evade-Nextbot — third-party model, not verified official.
- Candidate Rocket Arena map: https://create.roblox.com/store/asset/124805122537927/Rocket-Arena-Map-Evade-Kit-Obunga-Evade-Map — third-party model, not the screenshot backdrop.
- Catjam author identified in the screenshot as WizardMaster29; community corroboration: https://evadewiki.org/wiki/m3gan-x-evade-update/
- Community soundtrack index associates Catjam with Adele Roberts – Lose My Mind (edited), and Serious March with Ray Russell – Tense Emotion: https://evadewiki.org/wiki/soundtracks/ . These are research leads, NOT playable verified asset IDs or evidence of experience permissions.

The audit workflow downloads candidate models to a build artifact, enumerates scripts without executing them, records hashes, and compiles the standalone settings preview. Exact emote motions, associated accessories, playable music, textures and the requested map remain unresolved.
